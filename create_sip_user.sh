#!/bin/bash

echo "==========================="
echo " Create New SIP Account    "
echo "==========================="

read -p "Extension Number (e.g., 1001): " EXT
read -p "Caller ID Name: " NAME
read -sp "Password: " SECRET
echo ""

# SIP কনফিগে যোগ করুন
echo "
[$EXT]
type=friend
secret=$SECRET
host=dynamic
context=internal
callerid=\"$NAME\" <$EXT>
nat=yes
qualify=yes
directmedia=no" | sudo tee -a /etc/asterisk/sip.conf > /dev/null

# এক্সটেনশন ডায়ালপ্ল্যানে যোগ করুন
echo "exten => $EXT,1,Dial(SIP/$EXT,30)" | sudo tee -a /etc/asterisk/extensions.conf > /dev/null

# Asterisk রিলোড
sudo asterisk -rx "sip reload"
sudo asterisk -rx "dialplan reload"

echo ""
echo "=========================================="
echo "✅ SIP Account Created Successfully!"
echo "=========================================="
echo "Extension: $EXT"
echo "Password : $SECRET"
echo "SIP Server: $(curl -s ifconfig.me)"
echo "Port     : 5060"
echo "=========================================="
