#!/bin/bash

# Eatlas EC2 Deployment Script
# This script automates the entire deployment process

set -e  # Exit on error

echo "🚀 Starting Eatlas Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MONGO_URI="mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT"
JWT_SECRET="${JWT_SECRET:-your-super-secret-jwt-key-change-this}"
NODE_ENV="production"
PORT=5000
APP_DIR="$HOME/eatlas"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Step 1: Update system
print_info "Step 1: Updating system packages..."
sudo yum update -y > /dev/null 2>&1
print_status "System updated"

# Step 2: Install Node.js
print_info "Step 2: Installing Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - > /dev/null 2>&1
    sudo yum install -y nodejs > /dev/null 2>&1
    print_status "Node.js installed: $(node --version)"
else
    print_status "Node.js already installed: $(node --version)"
fi

# Step 3: Install Git
print_info "Step 3: Installing Git..."
if ! command -v git &> /dev/null; then
    sudo yum install -y git > /dev/null 2>&1
    print_status "Git installed"
else
    print_status "Git already installed"
fi

# Step 4: Install PM2
print_info "Step 4: Installing PM2..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2 > /dev/null 2>&1
    print_status "PM2 installed"
else
    print_status "PM2 already installed"
fi

# Step 5: Install Nginx
print_info "Step 5: Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo yum install -y nginx > /dev/null 2>&1
    sudo systemctl start nginx
    sudo systemctl enable nginx
    print_status "Nginx installed and started"
else
    print_status "Nginx already installed"
fi

# Step 6: Clone/Update repository
print_info "Step 6: Setting up application repository..."
if [ ! -d "$APP_DIR" ]; then
    mkdir -p "$APP_DIR"
    cd "$APP_DIR"
    git clone https://github.com/hbagde424/Eatlas.git . > /dev/null 2>&1
    print_status "Repository cloned"
else
    cd "$APP_DIR"
    git pull origin main > /dev/null 2>&1
    print_status "Repository updated"
fi

# Step 7: Setup Backend
print_info "Step 7: Setting up backend..."
cd "$APP_DIR/backend"

# Create .env file
cat > .env << EOF
MONGO_URI=$MONGO_URI
JWT_SECRET=$JWT_SECRET
JWT_EXPIRE=30d
NODE_ENV=$NODE_ENV
PORT=$PORT
CLOUDINARY_CLOUD_NAME=dpaui8plb
CLOUDINARY_API_KEY=873488488411495
CLOUDINARY_API_SECRET=your-cloudinary-secret
CLOUDINARY_UPLOAD_PRESET=your_upload_preset_name
EOF

# Install dependencies
npm install > /dev/null 2>&1
print_status "Backend dependencies installed"

# Step 8: Setup Frontend
print_info "Step 8: Setting up frontend..."
cd "$APP_DIR/frontend"

# Create .env.production
cat > .env.production << EOF
VITE_APP_VERSION=v9.2.2
VITE_APP_API_URL=http://$(hostname -I | awk '{print $1}'):$PORT/api
VITE_APP_MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
VITE_APP_GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_KEY
EOF

# Install dependencies
npm install > /dev/null 2>&1
print_status "Frontend dependencies installed"

# Build frontend
npm run build > /dev/null 2>&1
print_status "Frontend built successfully"

# Step 9: Configure Nginx
print_info "Step 9: Configuring Nginx..."
sudo tee /etc/nginx/nginx.conf > /dev/null << 'NGINX_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    upstream backend {
        server 127.0.0.1:5000;
    }

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;

        location / {
            root /home/ec2-user/eatlas/frontend/dist;
            try_files $uri $uri/ /index.html;
            expires 1d;
            add_header Cache-Control "public, immutable";
        }

        location /api/ {
            proxy_pass http://backend/api/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
NGINX_EOF

sudo nginx -t > /dev/null 2>&1
sudo systemctl reload nginx
print_status "Nginx configured and reloaded"

# Step 10: Start Backend with PM2
print_info "Step 10: Starting backend with PM2..."
cd "$APP_DIR/backend"

# Stop existing process if running
pm2 delete eatlas-backend 2>/dev/null || true

# Start new process
pm2 start server.js --name "eatlas-backend" > /dev/null 2>&1
pm2 save > /dev/null 2>&1

# Setup PM2 to start on boot
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user --hp /home/ec2-user > /dev/null 2>&1

print_status "Backend started with PM2"

# Step 11: Verify deployment
print_info "Step 11: Verifying deployment..."
sleep 2

# Check backend
if curl -s http://localhost:5000/api/health > /dev/null; then
    print_status "Backend is running"
else
    print_error "Backend health check failed"
fi

# Check frontend
if curl -s http://localhost/ > /dev/null; then
    print_status "Frontend is running"
else
    print_error "Frontend health check failed"
fi

# Get IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo ""
echo "📍 Application URL: http://$IP_ADDRESS"
echo "📍 API URL: http://$IP_ADDRESS:$PORT/api"
echo ""
echo "📊 Useful Commands:"
echo "   - View logs: pm2 logs eatlas-backend"
echo "   - Monitor: pm2 monit"
echo "   - Restart: pm2 restart eatlas-backend"
echo "   - Stop: pm2 stop eatlas-backend"
echo ""
echo "🔧 Next Steps:"
echo "   1. Update Cloudinary credentials in backend/.env"
echo "   2. Update Mapbox token in frontend/.env.production"
echo "   3. Setup SSL certificate with Let's Encrypt"
echo "   4. Configure custom domain"
echo ""
