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
    echo -e "${RED}❌ Root user দিয়ে রান করুন: sudo bash install.sh${NC}"
    exit 1
fi

# Get VPS IP
VPS_IP=$(curl -s ifconfig.me)

# Generate credentials
EXT_NUM="1001"
SIP_PASS=$(openssl rand -base64 12 | tr -d "=+/")

echo -e "${YELLOW}🚀 SIP সার্ভার সেটআপ শুরু হচ্ছে...${NC}"
echo ""

# Update System
echo -e "${BLUE}[1/6] সিস্টেম আপডেট হচ্ছে...${NC}"
apt update -y > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

# Install Asterisk
echo -e "${BLUE}[2/6] Asterisk ইনস্টল হচ্ছে...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y asterisk ufw curl openssl > /dev/null 2>&1
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

# Configure SIP
echo -e "${BLUE}[3/6] SIP কনফিগার হচ্ছে...${NC}"
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
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

# Configure Dialplan
echo -e "${BLUE}[4/6] ডায়ালপ্ল্যান সেটআপ হচ্ছে...${NC}"
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
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

# Firewall
echo -e "${BLUE}[5/6] ফায়ারওয়াল কনফিগার হচ্ছে...${NC}"
ufw --force reset > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw allow 5060/udp > /dev/null 2>&1
ufw allow 5060/tcp > /dev/null 2>&1
ufw allow 10000:20000/udp > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

# Start Asterisk
echo -e "${BLUE}[6/6] Asterisk শুরু হচ্ছে...${NC}"
systemctl enable asterisk > /dev/null 2>&1
systemctl restart asterisk > /dev/null 2>&1
sleep 2
echo -e "${GREEN}✅ সম্পন্ন!${NC}"

# Create Management Commands
cat > /usr/local/bin/sip-add << 'CMDEOF'
#!/bin/bash
read -p "এক্সটেনশন নাম্বার: " ext
read -p "নাম: " name
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
echo "✅ SIP অ্যাকাউন্ট তৈরি হয়েছে!"
echo "এক্সটেনশন: $ext | পাসওয়ার্ড: $pass | সার্ভার: $(curl -s ifconfig.me)"
CMDEOF

cat > /usr/local/bin/sip-list << 'CMDEOF'
#!/bin/bash
echo "📋 SIP এক্সটেনশনসমূহ:"
grep "^\[" /etc/asterisk/sip.conf | grep -v "general" | tr -d "[]"
echo ""
asterisk -rx "sip show peers" 2>/dev/null
CMDEOF

cat > /usr/local/bin/sip-del << 'CMDEOF'
#!/bin/bash
[ -z "$1" ] && echo "ব্যবহার: sip-del এক্সটেনশন" && exit 1
sed -i "/^\[$1\]/,/^$/d" /etc/asterisk/sip.conf
sed -i "/exten => $1,/d" /etc/asterisk/extensions.conf
asterisk -rx "sip reload" > /dev/null 2>&1
echo "✅ এক্সটেনশন $1 ডিলিট হয়েছে"
CMDEOF

cat > /usr/local/bin/sip-pass << 'CMDEOF'
#!/bin/bash
[ -z "$1" ] && echo "ব্যবহার: sip-pass এক্সটেনশন" && exit 1
grep -A 10 "^\[$1\]" /etc/asterisk/sip.conf | grep "secret" | cut -d= -f2
CMDEOF

cat > /usr/local/bin/sip-help << 'CMDEOF'
#!/bin/bash
echo "🔧 SIP কমান্ড:"
echo "  sip-add       - নতুন অ্যাকাউন্ট"
echo "  sip-list      - সব অ্যাকাউন্ট"
echo "  sip-del EXT   - অ্যাকাউন্ট ডিলিট"
echo "  sip-pass EXT  - পাসওয়ার্ড দেখুন"
echo "  sip-help      - হেল্প"
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
echo "║     ✅ SIP সার্ভার রেডি!                 ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}📡 আপনার SIP অ্যাকাউন্ট:${NC}"
echo -e "  ${CYAN}সার্ভার IP :${NC} ${GREEN}${VPS_IP}${NC}"
echo -e "  ${CYAN}পোর্ট      :${NC} ${GREEN}5060${NC}"
echo -e "  ${CYAN}এক্সটেনশন :${NC} ${GREEN}${EXT_NUM}${NC}"
echo -e "  ${CYAN}পাসওয়ার্ড :${NC} ${GREEN}${SIP_PASS}${NC}"
echo ""
echo -e "${YELLOW}📱 SIP ক্লায়েন্ট সেটিংস:${NC}"
echo -e "  Username : ${EXT_NUM}"
echo -e "  Password : ${SIP_PASS}"
echo -e "  Domain   : ${VPS_IP}"
echo ""
echo -e "${YELLOW}🔧 কমান্ড:${NC}"
echo -e "  ${GREEN}sip-add${NC}    - নতুন SIP অ্যাকাউন্ট"
echo -e "  ${GREEN}sip-list${NC}   - অ্যাকাউন্ট লিস্ট"
echo -e "  ${GREEN}sip-pass 1001${NC} - পাসওয়ার্ড দেখুন"
echo ""
echo -e "${RED}⚠️  পাসওয়ার্ড /root/sip-credentials.txt তে সেভ করা আছে${NC}"
echo ""
