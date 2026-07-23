#!/bin/bash

clear

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}"
echo "╔══════════════════════════════════════════╗"
echo "║     🗑️  SIP TRUNK VPS UNINSTALLER       ║"
echo "║     Complete Removal Tool               ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Root user দিয়ে রান করুন: sudo bash uninstall.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  এই প্রক্রিয়া সব SIP কনফিগারেশন ডিলিট করবে!${NC}"
echo -e "${YELLOW}⚠️  সব SIP অ্যাকাউন্ট ডিলিট হবে!${NC}"
echo ""
read -p "আপনি কি নিশ্চিত? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${GREEN}✅ আনইনস্টল বাতিল করা হয়েছে${NC}"
    exit 0
fi

echo ""
echo -e "${RED}[1/7] Asterisk বন্ধ করা হচ্ছে...${NC}"
systemctl stop asterisk > /dev/null 2>&1
killall -9 asterisk > /dev/null 2>&1
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

echo -e "${RED}[2/7] Asterisk রিমুভ করা হচ্ছে...${NC}"
apt remove --purge -y asterisk asterisk-core-sounds-en > /dev/null 2>&1
apt autoremove -y > /dev/null 2>&1
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

echo -e "${RED}[3/7] কনফিগারেশন ফাইল ডিলিট...${NC}"
rm -rf /etc/asterisk/ > /dev/null 2>&1
rm -rf /var/lib/asterisk/ > /dev/null 2>&1
rm -rf /var/log/asterisk/ > /dev/null 2>&1
rm -rf /var/spool/asterisk/ > /dev/null 2>&1
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

echo -e "${RED}[4/7] ম্যানেজমেন্ট কমান্ড ডিলিট...${NC}"
rm -f /usr/local/bin/sip-add
rm -f /usr/local/bin/sip-list
rm -f /usr/local/bin/sip-del
rm -f /usr/local/bin/sip-pass
rm -f /usr/local/bin/sip-status
rm -f /usr/local/bin/sip-restart
rm -f /usr/local/bin/sip-help
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

echo -e "${RED}[5/7] ক্রেডেনশিয়াল ফাইল ডিলিট...${NC}"
rm -f /root/sip-credentials.txt
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

echo -e "${RED}[6/7] ফায়ারওয়াল রিসেট...${NC}"
ufw --force reset > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

echo -e "${RED}[7/7] ক্লিনআপ সম্পন্ন...${NC}"
apt autoremove -y > /dev/null 2>&1
apt clean > /dev/null 2>&1
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║     ✅ আনইনস্টল সম্পন্ন!                ║"
echo "║     SIP সার্ভার সম্পূর্ণ ডিলিট হয়েছে    ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}পুনরায় ইন্সটল করতে:${NC}"
echo -e "  ${GREEN}sudo bash install.sh${NC}"
echo ""
