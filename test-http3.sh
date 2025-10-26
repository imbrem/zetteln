#!/bin/bash

echo "Testing HTTP/3 support..."
echo ""

# Check if UDP 8443 is listening
echo "1. Checking if UDP port 8443 is open:"
netstat -uln 2>/dev/null | grep 8443 || ss -uln 2>/dev/null | grep 8443 || echo "  netstat/ss not available, but container should be listening"

echo ""
echo "2. Check Caddy logs for HTTP/3:"
docker logs zetteln-caddy 2>&1 | grep -i "http/3\|h3\|quic" | tail -5

echo ""
echo "3. To test HTTP/3 from browser:"
echo "  - Open https://localhost:8443 in Chrome/Edge"
echo "  - Open DevTools (F12) → Network tab"
echo "  - Look for 'Protocol' column (right-click headers to enable it)"
echo "  - Should show 'h3' or 'http/3' for HTTP/3 connections"
echo ""
echo "4. Or use curl (if built with HTTP/3 support):"
echo "  curl -I --http3-only https://localhost:8443 2>&1 | head -5"
