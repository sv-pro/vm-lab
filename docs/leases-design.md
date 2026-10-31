# Leases: guaranteed teardown for lab environments

Status: design, not implemented. Target repository: `vm-lab`.

## Goal

A lab environment (a Vagrant VM today, a cloud VM later) exists only while its
**lease** is valid. When the lease ends, the environment is destroyed, even if the
person who created it forgot it, closed the laptop lid, or the creating script crashed
half-way.

A lease is kept alive only by an explicit action of a human, or by a time slot the human
declared up front. Nothing automatic can keep an environment alive: not an open SSH
session, not a browser tab polling a page, not a busy CPU.

### Non-goals (v1)

- Guessing activity from CPU, network or TTY idle time. These signals produce false
  activity and are deferred (see [Later](#later)).
- Multi-user environments. One environment, one owner, one channel.
- Cost accounting and budgets. A cloud budget alarm stays a separate, last line of defence.

## Principles

1. **Default is death.** An environment without a valid lease is expired. A crash, a
   lost record or a silent channel leads to teardown, never to an immortal environment
   (fail-safe defaults).
2. **Only a human extends.** Every extension after the declared slot is a deliberate human
   action that a bot, a link scanner or a script cannot produce by accident.
3. **Timers live outside the environment.** The reaper runs on the host (Vagrant) or in
   the cloud scheduler (cloud). The environment only reports status; it holds no timer
   and cannot extend its own lease.
4. **One deleter.** Apart from an explicit `lab down`, only the reaper destroys
   environments, and it is idempotent: running it twice does no harm.

## The lease

```yaml
lease:
  slot: 2h             # guaranteed silent time from creation; 0 = start asking at once
  ping_every: 1h       # after a confirmation: silent time until the next question
  answer_within: 15m   # how long a question waits for an answer
  max_lifetime: 24h    # absolute cap; extendable only by an explicit `lab extend --beyond-cap`
  watch: null          # optional: a command whose exit ends the lease ("./train.sh")
  on_watch_exit: teardown   # teardown | ask
  channel: telegram    # where questions go
  collect: [./results] # copied out of the environment before destruction
```

Validation: `slot >= 0`, `ping_every > 0`, `answer_within > 0`,
`max_lifetime >= slot`. Durations are absolute timestamps once a lease is created
(UTC, reaper's clock).

**One mechanism, not two.** The declared slot and a confirmed question are the same thing:
a period of silence that ends at a known time. The slot is simply the first such period.
So the state machine has one silent state, not separate «slot» and «between pings» states.

## State machine

```
            create (lease record written first)
                         │
                         ▼
   ┌──────────── QUIET(until = created + slot) ◄─────────────┐
   │                     │                                    │
   │       now >= until  │                                    │ confirmed(d):
   │                     ▼                                    │ until = now + d
   │           PENDING(ping_id, answer_by = now + answer_within)
   │                     │
   │   no answer by      │  «tear down now»
   │   answer_by         │
   ▼                     ▼
 TEARDOWN ──► collect ──► destroy ──► verify gone ──► GONE
   ▲
   └── from any state: watch exited (on_watch_exit = teardown),
       now >= created + max_lifetime, `lab down`, lease record missing
```

| From | Event | Guard | To |
|---|---|---|---|
| (none) | `lab up` | lease record written | QUIET, `until = now + slot` (PENDING if `slot = 0`) |
| QUIET | tick | `now >= until` | PENDING, send question |
| QUIET | `lab extend d` | `until + d <= cap` | QUIET, `until += d` |
| PENDING | answer `extend d` | answer matches current `ping_id`, `now < answer_by` | QUIET, `until = now + d` |
| PENDING | answer `down` | matches `ping_id` | TEARDOWN |
| PENDING | tick | `now >= answer_by` | TEARDOWN |
| PENDING | answer for an older `ping_id` | — | ignored, logged |
| any live | watch exited | `on_watch_exit = teardown` | TEARDOWN, notify with exit code |
| any live | watch exited | `on_watch_exit = ask` | PENDING, question says «finished» |
| any live | tick | `now >= created + max_lifetime` | TEARDOWN, notify |
| any | `lab down` | — | TEARDOWN |

`d` defaults to `ping_every`; the question offers a few fixed choices
(«+1h», «+3h», «down now»), each capped by `max_lifetime`.

### Invariant (the guarantee)

> An environment is destroyed no later than
> `min(answer deadline, created + max_lifetime) + reaper_interval + destroy_time`,
> provided the reaper's scheduler is running.

Everything else in this document exists to keep that sentence true.

## The question

A question carries enough to decide without logging in:

- environment name, template, age, time until the cap;
- watched process: running / exited (code) / unknown, elapsed time, last 5 log lines;
- the choices, as buttons.

Unknown status (the in-VM agent is silent) does not block anything; it is shown as
«unknown» and the deadlines still apply.

## Decisions that keep the guarantee honest

### 1. A confirmation must be a human action

Links that extend a lease on GET are opened automatically by mail security scanners and by
chat link previews. The environment would extend itself without anyone looking: exactly
the false activity this design avoids.

- Answers come only as **button callbacks** (Telegram inline buttons) or the CLI
  (`lab extend`), never as a GET link.
- Each question has a **single-use `ping_id`**. An answer is accepted only for the
  current `ping_id` and only before `answer_by`. A late, repeated or replayed answer is
  ignored and logged.
- The callback is bound to the lease id and the owner's chat id.

### 2. A channel that cannot deliver means teardown

If a question cannot be delivered, retries continue until `answer_by`; then the normal
timeout applies and the environment is destroyed. This is harsh for a long job, and it
is chosen on purpose: the alternative (keep alive while the channel is down) makes the
channel a way to make environments immortal. A user who expects to be unreachable
declares a longer `slot` up front.

### 3. Results are collected before destruction

Teardown first copies `collect` paths out of the environment (to the host for Vagrant, to
object storage for the cloud), with its own time limit. If collection fails or times out,
teardown **still proceeds**, and the failure is reported. Losing results is bad; an
environment that cannot die because a copy hangs is worse.

### 4. The lease record is written before the environment exists

`lab up` writes the lease record first (an intent record), then creates the environment.
A crash in between leaves a lease with no environment, which the reaper closes. The
reverse order would leave an environment with no lease.

The reaper also scans the provider for environments carrying the `vm-lab` label that have
**no** lease record, and treats them as expired. Default is death.

## Components

| Component | Runs | Does | Does not |
|---|---|---|---|
| `lab` CLI | user's terminal | `up`, `run`, `extend`, `ls`, `down` | hold timers |
| Lease store | host: `~/.vm-lab/leases/<name>.json`; cloud: a small table plus a resource tag `vm-lab:lease` | the source of truth for deadlines | — |
| Reaper | host: systemd timer / cron, every minute; cloud: a small always-on control box (systemd timer), or EventBridge Scheduler / Cloud Scheduler | one pass: advance state machines, send questions, destroy | run on the user's laptop for cloud environments |
| Channel | Telegram bot (v1) | deliver questions, receive button callbacks | extend anything itself |
| In-VM agent | inside the environment | write watched-process status and log tail to the shared folder (`/vagrant/.lab/status.json`) | touch the lease |

The reaper is stateless between passes: everything it needs is in the lease store and the
provider. If it crashes, the scheduler starts the next pass.

**Cloud note.** For cloud environments the reaper must run in the cloud, not on a laptop:
a sleeping laptop would stop the timers while the VMs keep billing. The first deployment is a
small always-on server (2 vCPU, 4 GB) that runs only the control plane: lease store,
reaper, channel. It never hosts the environments themselves. Locally this does not
matter, because a sleeping host also suspends its Vagrant VMs.

## CLI

```bash
lab up demo --template docker --slot 2h --ping-every 30m --answer-within 10m
lab run job --template base --slot 2h --ping-every 1h -- ./train.sh   # sets watch
lab ls                       # name, state, until / answer_by, cap, watch status
lab extend demo 1h           # a human action, same as a button
lab down demo
lab reaper --once            # one pass; what cron / the scheduler calls
```

## Typical leases

| Situation | slot | ping_every | answer_within | watch |
|---|---|---|---|---|
| Live demo, «don't disturb me for 2 hours» | 2h | 30m | 10m | — |
| Long job, «tell me in 2 hours, ask if still running» | 2h | 1h | 15m | `./train.sh` |
| Exploration, ask from the start | 0 | 45m | 10m | — |

## Testing

All logic runs against fakes: a fake clock, a fake provider and a fake channel. No VM is
needed for the state machine.

- One test per row of the transition table.
- Stale, duplicate and replayed answers are ignored.
- Channel delivery failure ends in teardown at `answer_by`.
- Crash between lease write and VM creation: the reaper closes the lease.
- A labelled VM with no lease record is destroyed.
- Collection that hangs does not block destruction.
- Property test: random event sequences over a fake clock; no environment survives past
  the bound in [the invariant](#invariant-the-guarantee) plus one reaper interval.
- One end-to-end test with a real Vagrant VM and a short lease (minutes), run manually.

## Residual risks

- **The scheduler itself stops** (host cron disabled, cloud scheduler misconfigured). No
  design inside the reaper can fix that. For the cloud, a budget alarm is the last line.
- **Destroy fails at the provider.** The reaper retries every pass and reports; the
  environment is marked `TEARDOWN_FAILED` and shown first in `lab ls`.
- **The owner's chat account is compromised.** Whoever holds it can extend up to the cap.
  The cap bounds the damage.
- **Clock skew** between the reaper and the provider. All deadlines use the reaper's
  clock only.

## Later

- Activity signals (TTY input, requests through a single proxy, CPU) may **trigger an
  early question**. They never extend a lease. They rank, they do not decide.
- A cloud provider behind the same `up / ls / extend / down` interface.
- Self-destruct as a second layer in the cloud: the VM schedules its own shutdown at the
  cap, with «delete on shutdown» set at the provider.
