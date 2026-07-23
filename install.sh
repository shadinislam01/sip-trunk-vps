#!/bin/bash

clear

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║      🌐 SIP TRUNK VPS INSTALLER         ║"
echo "║      One Click SIP Server Setup         ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run as root: sudo bash install.sh${NC}"
    exit 1
fi

# Get VPS IP
VPS_IP=$(curl -s ifconfig.me)

# Generate credentials
EXT_NUM="1001"
SIP_PASS=$(openssl rand -base64 12 | tr -d "=+/")

echo -e "${YELLOW}🚀 Starting SIP Server Setup...${NC}"
echo ""

# Update System
echo -e "${BLUE}[1/6] Updating System...${NC}"
apt update -y > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1
echo -e "${GREEN}✅ Done!${NC}"

# Install Asterisk
echo -e "${BLUE}[2/6] Installing Asterisk...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y asterisk ufw curl openssl > /dev/null 2>&1
echo -e "${GREEN}✅ Done!${NC}"

# Configure SIP
echo -e "${BLUE}[3/6] Configuring SIP...${NC}"
cat > /etc/asterisk/sip.conf << EOF
[general]
context=public
bindport=5060
bindaddr=0.0.0.0
tcpenable=yes
tcpbindaddr=0.0.0.0
transport=udp,tcp
nat=force_rport,comedia
externip=${VPS_IP}
localnet=192.168.0.0/255.255.0.0
language=en
allowguest=no
alwaysauthreject=yes

[${EXT_NUM}]
type=friend
secret=${SIP_PASS}
host=dynamic
context=internal
callerid="SIP User" <${EXT_NUM}>
nat=yes
qualify=yes
directmedia=no
dtmfmode=rfc2833
disallow=all
allow=ulaw
allow=alaw
EOF
echo -e "${GREEN}✅ Done!${NC}"

# Configure Dialplan
echo -e "${BLUE}[4/6] Setting up Dialplan...${NC}"
cat > /etc/asterisk/extensions.conf << EOF
[general]
static=yes
writeprotect=no

[internal]
exten => ${EXT_NUM},1,Dial(SIP/${EXT_NUM},30)
exten => _X.,1,NoOp(Incoming call)
same => n,Hangup()

[public]
exten => _X.,1,NoOp(Public call)
same => n,Hangup()
EOF
echo -e "${GREEN}✅ Done!${NC}"

# Firewall
echo -e "${BLUE}[5/6] Configuring Firewall...${NC}"
ufw --force reset > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw allow 5060/udp > /dev/null 2>&1
ufw allow 5060/tcp > /dev/null 2>&1
ufw allow 10000:20000/udp > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
echo -e "${GREEN}✅ Done!${NC}"

# Start Asterisk
echo -e "${BLUE}[6/6] Starting Asterisk...${NC}"
systemctl enable asterisk > /dev/null 2>&1
systemctl restart asterisk > /dev/null 2>&1
sleep 2
echo -e "${GREEN}✅ Done!${NC}"

# Create Management Commands
cat > /usr/local/bin/sip-add << 'CMDEOF'
#!/bin/bash
read -p "Extension Number: " ext
read -p "Caller Name: " name
pass=$(openssl rand -base64 8 | tr -d "=+/")
cat >> /etc/asterisk/sip.conf << EOF
[$ext]
type=friend
secret=$pass
host=dynamic
context=internal
callerid="$name" <$ext>
nat=yes
qualify=yes
directmedia=no
EOF
echo "exten => $ext,1,Dial(SIP/$ext,30)" >> /etc/asterisk/extensions.conf
asterisk -rx "sip reload" > /dev/null 2>&1
echo "✅ SIP Account Created Successfully!"
echo "Extension: $ext | Password: $pass | Server: $(curl -s ifconfig.me)"
CMDEOF

cat > /usr/local/bin/sip-list << 'CMDEOF'
#!/bin/bash
echo "📋 SIP Extensions:"
grep "^\[" /etc/asterisk/sip.conf | grep -v "general" | tr -d "[]"
echo ""
asterisk -rx "sip show peers" 2>/dev/null
CMDEOF

cat > /usr/local/bin/sip-del << 'CMDEOF'
#!/bin/bash
[ -z "$1" ] && echo "Usage: sip-del EXTENSION" && exit 1
sed -i "/^\[$1\]/,/^$/d" /etc/asterisk/sip.conf
sed -i "/exten => $1,/d" /etc/asterisk/extensions.conf
asterisk -rx "sip reload" > /dev/null 2>&1
echo "✅ Extension $1 deleted successfully"
CMDEOF

cat > /usr/local/bin/sip-pass << 'CMDEOF'
#!/bin/bash
[ -z "$1" ] && echo "Usage: sip-pass EXTENSION" && exit 1
grep -A 10 "^\[$1\]" /etc/asterisk/sip.conf | grep "secret" | cut -d= -f2
CMDEOF

cat > /usr/local/bin/sip-help << 'CMDEOF'
#!/bin/bash
echo "🔧 SIP Management Commands:"
echo "  sip-add       - Create new account"
echo "  sip-list      - List all accounts"
echo "  sip-del EXT   - Delete account"
echo "  sip-pass EXT  - Show password"
echo "  sip-help      - Show this help"
CMDEOF

chmod +x /usr/local/bin/sip-{add,list,del,pass,help}

# Save credentials
cat > /root/sip-credentials.txt << EOF
══════════════════════════════
  SIP SERVER CREDENTIALS
══════════════════════════════
Server IP : ${VPS_IP}
Port      : 5060
Extension : ${EXT_NUM}
Password  : ${SIP_PASS}
══════════════════════════════
EOF

# Final Output
clear
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║     ✅ SIP SERVER IS READY!              ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}📡 Your SIP Account:${NC}"
echo -e "  ${CYAN}Server IP  :${NC} ${GREEN}${VPS_IP}${NC}"
echo -e "  ${CYAN}Port       :${NC} ${GREEN}5060${NC}"
echo -e "  ${CYAN}Extension  :${NC} ${GREEN}${EXT_NUM}${NC}"
echo -e "  ${CYAN}Password   :${NC} ${GREEN}${SIP_PASS}${NC}"
echo ""
echo -e "${YELLOW}📱 SIP Client Settings:${NC}"
echo -e "  Username : ${EXT_NUM}"
echo -e "  Password : ${SIP_PASS}"
echo -e "  Domain   : ${VPS_IP}"
echo ""
echo -e "${YELLOW}🔧 Quick Commands:${NC}"
echo -e "  ${GREEN}sip-add${NC}    - Create new SIP account"
echo -e "  ${GREEN}sip-list${NC}   - View all accounts"
echo -e "  ${GREEN}sip-pass 1001${NC} - View password"
echo ""
echo -e "${RED}⚠️  Credentials saved to /root/sip-credentials.txt${NC}"
echo ""
