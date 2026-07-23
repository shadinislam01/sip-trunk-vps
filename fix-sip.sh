#!/bin/bash

# Quick SIP Fix Script

echo "🔧 Quick SIP Fix Tool"
echo ""

# Fix 1: Restart Asterisk
echo "[1/5] Restarting Asterisk..."
systemctl restart asterisk
sleep 2
echo "✅ Done"

# Fix 2: Open Firewall Ports
echo "[2/5] Opening Firewall Ports..."
ufw allow 5060/udp > /dev/null 2>&1
ufw allow 5060/tcp > /dev/null 2>&1
ufw allow 10000:20000/udp > /dev/null 2>&1
echo "✅ Done"

# Fix 3: Reload SIP Module
echo "[3/5] Reloading SIP Configuration..."
asterisk -rx "module reload chan_sip.so" > /dev/null 2>&1
asterisk -rx "sip reload" > /dev/null 2>&1
echo "✅ Done"

# Fix 4: Clear Stale Peers
echo "[4/5] Cleaning stale peers..."
asterisk -rx "sip prune realtime all" > /dev/null 2>&1
echo "✅ Done"

# Fix 5: Restart Networking
echo "[5/5] Restarting network..."
systemctl restart networking > /dev/null 2>&1
echo "✅ Done"

echo ""
echo "✅ All fixes applied!"
echo ""
echo "Check SIP status: sudo asterisk -rx 'sip show peers'"
