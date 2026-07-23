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
    echo -e "${RED}❌ Please run as root: sudo bash uninstall.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  This will delete ALL SIP configurations!${NC}"
echo -e "${YELLOW}⚠️  ALL SIP accounts will be deleted!${NC}"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${GREEN}✅ Uninstall cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${RED}[1/7] Stopping Asterisk...${NC}"
systemctl stop asterisk > /dev/null 2>&1
killall -9 asterisk > /dev/null 2>&1
echo -e "${GREEN}✅ Done!${NC}"

echo -e "${RED}[2/7] Removing Asterisk...${NC}"
apt remove --purge -y asterisk asterisk-core-sounds-en > /dev/null 2>&1
apt autoremove -y > /dev/null 2>&1
echo -e "${GREEN}✅ Done!${NC}"

echo -e "${RED}[3/7] Deleting configuration files...${NC}"
rm -rf /etc/asterisk/ > /dev/null 2>&1
rm -rf /var/lib/asterisk/ > /dev/null 2>&1
rm -rf /var/log/asterisk/ > /dev/null 2>&1
rm -rf /var/spool/asterisk/ > /dev/null 2>&1
echo -e "${GREEN}✅ Done!${NC}"

echo -e "${RED}[4/7] Removing management commands...${NC}"
rm -f /usr/local/bin/sip-add
rm -f /usr/local/bin/sip-list
rm -f /usr/local/bin/sip-del
rm -f /usr/local/bin/sip-pass
rm -f /usr/local/bin/sip-status
rm -f /usr/local/bin/sip-restart
rm -f /usr/local/bin/sip-help
echo -e "${GREEN}✅ Done!${NC}"

echo -e "${RED}[5/7] Deleting credential files...${NC}"
rm -f /root/sip-credentials.txt
echo -e "${GREEN}✅ Done!${NC}"

echo -e "${RED}[6/7] Resetting firewall...${NC}"
ufw --force reset > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
echo -e "${GREEN}✅ Done!${NC}"

echo -e "${RED}[7/7] Cleanup complete...${NC}"
apt autoremove -y > /dev/null 2>&1
apt clean > /dev/null 2>&1
echo -e "${GREEN}✅ Done!${NC}"

echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║     ✅ Uninstall Complete!               ║"
echo "║     SIP Server fully removed             ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}To reinstall:${NC}"
echo -e "  ${GREEN}sudo bash install.sh${NC}"
echo ""
