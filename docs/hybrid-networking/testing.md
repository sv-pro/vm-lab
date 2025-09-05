Step-by-Step Testing

  1. Create a test VM with hybrid networking:
  ```
  make hybrid-base NAME=test-vm
  ```

  2. Create a test container:
  ```
  docker run -d --name test-container --network hybrid-net --ip 10.0.1.50 nginx:alpine
  ```

  3. Test VM → Container communication:
  # SSH into the VM
  ```
  make ssh NAME=test-vm
  ```

  # From inside the VM, test connectivity
  ```
  ping 10.0.1.50                           # IP connectivity
  ping test-container.hybrid.local          # DNS resolution
  curl http://test-container.hybrid.local   # HTTP service test
  ```
  4. Test Container → VM communication:
  # Get VM IP and test from container
  ```
  docker exec test-container ping 10.0.1.200  # or whatever IP the VM got
  docker exec test-container ping test-vm.hybrid.local
  ```
  Advanced Testing

  Monitor network traffic in real-time:
  ```
  make hybrid-monitor
  ```

  Run comprehensive diagnostics:
  ```
  make hybrid-debug
  ```

  View DNS logs:
  ```
  make hybrid-logs
  ```
