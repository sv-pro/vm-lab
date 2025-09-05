#!/bin/bash

# Simplest DNS monitoring - just watch the DNS container logs
# No eBPF complexity, works on any system

echo "🔍 DNS Container Monitor - Watching hybrid-dns container logs"
echo "This shows actual DNS queries processed by dnsmasq"
echo "Press Ctrl+C to stop"
echo ""

if ! docker ps --format "{{.Names}}" | grep -q "^hybrid-dns$"; then
    echo "❌ hybrid-dns container not running"
    echo "Start with: make hybrid-enable-dns"
    exit 1
fi

echo "📊 Real-time DNS queries:"
echo "----------------------------------------"

# Follow DNS container logs with colored output
docker logs -f hybrid-dns 2>&1 | while read line; do
    if echo "$line" | grep -q "query"; then
        echo "🔍 QUERY:  $line"
    elif echo "$line" | grep -q "reply"; then  
        echo "✅ REPLY:  $line"
    elif echo "$line" | grep -q "config"; then
        echo "⚙️ CONFIG: $line"
    else
        echo "📝 LOG:    $line"
    fi
done