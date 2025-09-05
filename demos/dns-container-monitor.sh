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

# Follow DNS logs from the actual log file inside container
docker exec hybrid-dns tail -f /var/log/dnsmasq.log 2>/dev/null | while read line; do
    if echo "$line" | grep -q "query\[A\]"; then
        echo "🔍 QUERY:  $line"
    elif echo "$line" | grep -q "query\[AAAA\]"; then
        echo "🔍 IPv6:   $line" 
    elif echo "$line" | grep -q "/etc/hosts"; then  
        echo "✅ REPLY:  $line"
    elif echo "$line" | grep -q "cached"; then
        echo "⚡ CACHE:  $line"
    elif echo "$line" | grep -q "config"; then
        echo "⚙️ CONFIG: $line"
    else
        echo "📝 LOG:    $line"
    fi
done