#!/bin/bash

##############################################
# Sunny Sioux Care - Fully Automated Installer
# Version: 1.0 (Zero Questions)
##############################################

set -e  # Stop on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "============================================="
echo "    Sunny Sioux Care - Full Auto Install"
echo "    Version 1.0 (Zero Questions)"
echo "============================================="
echo -e "${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Run as root (sudo bash install-complete.sh)${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Running as root${NC}"

# Pre-configured values - NO QUESTIONS!
DOMAIN="sunnysiouxcare.com"
EMAIL="info@sunnysiouxcare.com"
MONGO_URL="mongodb://localhost:27017"
DB_NAME="sunnysiouxcare"
PAYPAL_CLIENT_ID="AZt9GrVjcdkpNicpgd45onNoltmXr81q9YnYQu55cL-zevpfsPP-n3TkN7oBwO3L9hMPfEOenMMDduqg"
PAYPAL_SECRET="ENGgk6krA1WJFu3KRRiIMCa67W7pk9lkuZvW2kM6EBwb5-2x9-_kUYyi_Nm9SSTjAHlzn3GRP9_zfP9x"

echo ""
echo -e "${GREEN}Installing with pre-configured settings:${NC}"
echo "  Domain: ${DOMAIN}"
echo "  Email: ${EMAIL}"
echo "  Database: Local MongoDB"
echo "  PayPal: Configured"
echo ""
echo -e "${YELLOW}Starting in 3 seconds...${NC}"
sleep 3

# Start installation
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  Starting installation...${NC}"
echo -e "${GREEN}=============================================${NC}"

# 1. Create SWAP
echo ""
echo -e "${YELLOW}[1/11] Creating SWAP (2GB additional memory)...${NC}"
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo -e "${GREEN}[OK] SWAP created${NC}"
else
    echo -e "${GREEN}[OK] SWAP already exists${NC}"
fi

# 2. Update system
echo ""
echo -e "${YELLOW}[2/11] Updating system...${NC}"
apt update -qq
DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq
echo -e "${GREEN}[OK] System updated${NC}"

# 3. Install base packages
echo ""
echo -e "${YELLOW}[3/11] Installing base packages...${NC}"
apt install -y -qq curl wget git nano ufw nginx software-properties-common gnupg
echo -e "${GREEN}[OK] Base packages installed${NC}"

# 4. Configure Firewall
echo ""
echo -e "${YELLOW}[4/11] Configuring Firewall...${NC}"
ufw --force reset
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo -e "${GREEN}[OK] Firewall configured${NC}"

# 5. Install MongoDB
echo ""
echo -e "${YELLOW}[5/11] Installing MongoDB...${NC}"
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor > /dev/null 2>&1
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null
apt update -qq
apt install -y -qq mongodb-org
systemctl start mongod
systemctl enable mongod
echo -e "${GREEN}[OK] MongoDB installed and started${NC}"

# 6. Install Python 3.11
echo ""
echo -e "${YELLOW}[6/11] Installing Python 3.11...${NC}"
apt install -y -qq python3.11 python3.11-venv python3-pip
echo -e "${GREEN}[OK] Python 3.11 installed${NC}"

# 7. Install Node.js, Yarn and PM2
echo ""
echo -e "${YELLOW}[7/11] Installing Node.js 18, Yarn and PM2...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt install -y -qq nodejs
npm install -g pm2 yarn > /dev/null 2>&1
echo -e "${GREEN}[OK] Node.js, Yarn and PM2 installed${NC}"

# 8. Clone project
echo ""
echo -e "${YELLOW}[8/11] Cloning project from GitHub...${NC}"
cd /var/www
if [ -d "sunny-sioux-care" ]; then
    rm -rf sunny-sioux-care
fi
git clone https://github.com/mrolivershea-cyber/sunny-sioux-care.git > /dev/null 2>&1
cd sunny-sioux-care
echo -e "${GREEN}[OK] Project cloned${NC}"

# 9. Configure Backend
echo ""
echo -e "${YELLOW}[9/11] Configuring Backend...${NC}"
cd /var/www/sunny-sioux-care/backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --quiet --upgrade pip > /dev/null 2>&1
pip install --quiet -r requirements.txt > /dev/null 2>&1

# Create .env file
cat > .env << EOF
MONGO_URL="${MONGO_URL}"
DB_NAME="${DB_NAME}"
CORS_ORIGINS="https://${DOMAIN},https://www.${DOMAIN}"
PAYPAL_CLIENT_ID="${PAYPAL_CLIENT_ID}"
PAYPAL_CLIENT_SECRET="${PAYPAL_SECRET}"
PAYPAL_MODE="live"
EMAIL_ENABLED="false"
SMTP_HOST="mail.${DOMAIN}"
SMTP_PORT="587"
SMTP_USER="info@${DOMAIN}"
SMTP_PASSWORD=""
FROM_EMAIL="noreply@${DOMAIN}"
ADMIN_EMAIL="info@${DOMAIN}"
EOF

# Create PM2 ecosystem
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'sunnysiouxcare-backend',
    script: 'venv/bin/uvicorn',
    args: 'server:app --host 0.0.0.0 --port 8001',
    cwd: '/var/www/sunny-sioux-care/backend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '300M',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
EOF

echo -e "${GREEN}[OK] Backend configured${NC}"

# 10. Build Frontend
echo ""
echo -e "${YELLOW}[10/11] Building Frontend...${NC}"
cd /var/www/sunny-sioux-care/frontend

# Create .env for frontend
cat > .env << EOF
REACT_APP_BACKEND_URL=https://${DOMAIN}
EOF

# Install dependencies with memory optimization
export NODE_OPTIONS="--max_old_space_size=512"
npm install --production --no-optional > /dev/null 2>&1 || {
    echo -e "${YELLOW}[WARNING] npm install failed, trying yarn...${NC}"
    yarn install --production --ignore-optional > /dev/null 2>&1
}

# Build
echo -e "${YELLOW}   Build may take 2-3 minutes...${NC}"
npm run build > /dev/null 2>&1 || yarn build > /dev/null 2>&1 || {
    echo -e "${RED}[ERROR] Frontend build failed${NC}"
    echo -e "${YELLOW}[INFO] You can build locally and upload${NC}"
}

if [ -d "build" ]; then
    echo -e "${GREEN}[OK] Frontend built${NC}"
else
    echo -e "${YELLOW}[WARNING] Frontend not built (insufficient memory)${NC}"
    echo -e "${YELLOW}[INFO] Build locally: yarn build, then upload to /var/www/sunny-sioux-care/frontend/build${NC}"
fi

# 11. Configure Nginx
echo ""
echo -e "${YELLOW}[11/11] Configuring Nginx...${NC}"

cat > /etc/nginx/sites-available/sunnysiouxcare << EOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    root /var/www/sunny-sioux-care/frontend/build;
    index index.html;

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # React Router
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Gzip
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/json;
}
EOF

# Activate site
ln -sf /etc/nginx/sites-available/sunnysiouxcare /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Check configuration
nginx -t
systemctl reload nginx

echo -e "${GREEN}[OK] Nginx configured${NC}"

# Start Backend
echo ""
echo -e "${YELLOW}Starting Backend...${NC}"
cd /var/www/sunny-sioux-care/backend
pm2 start ecosystem.config.js
pm2 save
pm2 startup | tail -1 | bash

echo -e "${GREEN}[OK] Backend started${NC}"

# SSL certificate
echo ""
echo -e "${YELLOW}Installing SSL certificate...${NC}"
apt install -y -qq certbot python3-certbot-nginx
certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email ${EMAIL} --redirect

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] SSL certificate installed${NC}"
else
    echo -e "${YELLOW}[WARNING] SSL certificate not installed (DNS may not be updated yet)${NC}"
    echo -e "${YELLOW}[INFO] Run later: certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}${NC}"
fi

# Final
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "${BLUE}Your website:${NC} https://${DOMAIN}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  pm2 status              - backend status"
echo "  pm2 logs                - backend logs"
echo "  pm2 restart all         - restart backend"
echo "  systemctl status nginx  - nginx status"
echo "  systemctl status mongod - mongodb status"
echo "  certbot renew           - renew SSL"
echo ""
echo -e "${YELLOW}Check:${NC}"
echo "  1. Open: https://${DOMAIN}"
echo "  2. Check pricing plans and payment"
echo "  3. Check contact form"
echo "  4. Check donate button"
echo ""
echo -e "${GREEN}Done!${NC}"
