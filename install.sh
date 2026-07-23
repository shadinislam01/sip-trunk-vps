#!/bin/bash

echo "============================="
echo " SIP Trunk VPS Setup Script  "
echo "============================="

# সিস্টেম আপডেট
echo "[1/6] Updating system..."
sudo apt update && sudo apt upgrade -y

# প্রয়োজনীয় প্যাকেজ ইন্সটল
echo "[2/6] Installing required packages..."
sudo apt install -y asterisk ufw net-tools

# ব্যাকআপ অরিজিনাল কনফিগ
echo "[3/6] Backing up original configs..."
sudo cp /etc/asterisk/sip.conf /etc/asterisk/sip.conf.backup
sudo cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup

# কপি কনফিগ ফাইল
echo "[4/6] Copying configuration files..."
sudo cp configs/sip.conf /etc/asterisk/sip.conf
sudo cp configs/extensions.conf /etc/asterisk/extensions.conf

# ফায়ারওয়াল সেটআপ
echo "[5/6] Setting up firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 5060/udp
sudo ufw allow 5060/tcp
sudo ufw allow 10000:20000/udp
sudo ufw --force enable

# Asterisk রিস্টার্ট
echo "[6/6] Restarting Asterisk..."
sudo systemctl enable asterisk
sudo systemctl restart asterisk

echo ""
echo "✅ Setup Complete!"
echo "Asterisk Status:"
sudo systemctl status asterisk --no-pager
