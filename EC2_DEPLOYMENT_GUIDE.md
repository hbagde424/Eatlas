# EC2 Deployment Guide - Eatlas Project

## Instance Details
- **Public IP:** 13.60.216.136
- **Instance ID:** i-042c125486445c062
- **Instance Type:** t3.micro
- **Region:** eu-north-1
- **PEM File:** ElectionAtlas.pem

## Step 1: Connect to EC2 Instance

### Windows (PowerShell)
```powershell
# Navigate to PEM file location
cd C:\Users\devel\Downloads

# Fix PEM file permissions (important!)
icacls ElectionAtlas.pem /inheritance:r /grant:r "$env:USERNAME`:(F)"

# Connect via SSH
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136
```

### Mac/Linux
```bash
chmod 400 ElectionAtlas.pem
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136
```

## Step 2: Setup EC2 Instance

Once connected to EC2, run these commands:

```bash
# Update system
sudo yum update -y

# Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Install Git
sudo yum install -y git

# Install PM2 (process manager)
sudo npm install -g pm2

# Install Nginx (reverse proxy)
sudo yum install -y nginx

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Create app directory
mkdir -p ~/eatlas
cd ~/eatlas
```

## Step 3: Clone Repository

```bash
cd ~/eatlas
git clone https://github.com/hbagde424/Eatlas.git .
```

## Step 4: Setup Backend

```bash
cd ~/eatlas/backend

# Install dependencies
npm install

# Create .env file
cat > .env << EOF
MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRE=30d
NODE_ENV=production
PORT=5000
CLOUDINARY_CLOUD_NAME=dpaui8plb
CLOUDINARY_API_KEY=873488488411495
CLOUDINARY_API_SECRET=your-cloudinary-secret
CLOUDINARY_UPLOAD_PRESET=your_upload_preset_name
EOF

# Test backend
npm start
# Press Ctrl+C to stop
```

## Step 5: Setup Frontend

```bash
cd ~/eatlas/frontend

# Install dependencies
npm install

# Create .env.production
cat > .env.production << EOF
VITE_APP_VERSION=v9.2.2
VITE_APP_API_URL=http://13.60.216.136:5000/api
VITE_APP_MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
VITE_APP_GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_KEY
EOF

# Build frontend
npm run build

# Output will be in dist/ folder
```

## Step 6: Configure Nginx

```bash
# Backup original nginx config
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Create new nginx config
sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
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

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    # Upstream backend
    upstream backend {
        server 127.0.0.1:5000;
    }

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;

        # Frontend static files
        location / {
            root /home/ec2-user/eatlas/frontend/dist;
            try_files $uri $uri/ /index.html;
            expires 1d;
            add_header Cache-Control "public, immutable";
        }

        # API proxy
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
            
            # Timeouts for file uploads
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Test nginx config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

## Step 7: Start Backend with PM2

```bash
cd ~/eatlas/backend

# Start backend
pm2 start server.js --name "eatlas-backend"

# Save PM2 config
pm2 save

# Setup PM2 to start on boot
pm2 startup
# Copy and run the command it outputs

# Check status
pm2 status
pm2 logs eatlas-backend
```

## Step 8: Verify Deployment

```bash
# Check if backend is running
curl http://localhost:5000/api/health

# Check if frontend is served
curl http://localhost/

# Check nginx status
sudo systemctl status nginx

# Check PM2 status
pm2 status
```

## Step 9: Access Application

Open browser and go to:
```
http://13.60.216.136
```

## Monitoring & Logs

### View Backend Logs
```bash
pm2 logs eatlas-backend
pm2 logs eatlas-backend --lines 100
```

### View Nginx Logs
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Monitor System Resources
```bash
pm2 monit
```

## Troubleshooting

### Backend not connecting to MongoDB
```bash
# SSH into EC2
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136

# Check logs
pm2 logs eatlas-backend

# Test MongoDB connection
cd ~/eatlas/backend
node -e "require('mongoose').connect('mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT').then(() => console.log('Connected!')).catch(e => console.log('Error:', e.message))"
```

### Nginx not serving frontend
```bash
# Check if dist folder exists
ls -la ~/eatlas/frontend/dist

# Check nginx config
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### Port 5000 already in use
```bash
# Find process using port 5000
sudo lsof -i :5000

# Kill process
sudo kill -9 <PID>
```

## Update Application

To update the application with new code:

```bash
# SSH into EC2
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136

# Pull latest code
cd ~/eatlas
git pull origin main

# Rebuild frontend
cd frontend
npm install
npm run build

# Restart backend
cd ../backend
npm install
pm2 restart eatlas-backend

# Reload nginx
sudo systemctl reload nginx
```

## Security Hardening

### 1. Setup SSL Certificate (Let's Encrypt)
```bash
sudo yum install -y certbot python3-certbot-nginx

# Get certificate (requires domain name)
sudo certbot certonly --nginx -d yourdomain.com

# Auto-renew
sudo systemctl enable certbot-renew.timer
```

### 2. Setup Firewall
```bash
# Allow SSH
sudo firewall-cmd --permanent --add-service=ssh

# Allow HTTP
sudo firewall-cmd --permanent --add-service=http

# Allow HTTPS
sudo firewall-cmd --permanent --add-service=https

# Reload firewall
sudo firewall-cmd --reload
```

### 3. Disable Root Login
```bash
sudo sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Backup Strategy

### Backup MongoDB
```bash
# Create backup directory
mkdir -p ~/backups

# Backup MongoDB (requires mongodump)
# Or use MongoDB Atlas automated backups
```

### Backup Application Code
```bash
# Code is already in git, just push regularly
cd ~/eatlas
git push origin main
```

## Performance Optimization

### Enable Caching
Already configured in nginx.conf with:
- Gzip compression
- Browser caching (1 day for static files)
- Proxy caching for API responses

### Monitor Performance
```bash
# Check CPU/Memory
top

# Check disk usage
df -h

# Check network
netstat -an | grep ESTABLISHED | wc -l
```

## Cost Estimation

| Service | Cost/Month |
|---------|-----------|
| EC2 t3.micro | ~$8 |
| Data transfer | ~$1 |
| MongoDB Atlas | $0-50 |
| **Total** | **~$10-60** |

## Useful Commands

```bash
# SSH into EC2
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136

# Copy file to EC2
scp -i ElectionAtlas.pem file.txt ec2-user@13.60.216.136:~/

# Copy file from EC2
scp -i ElectionAtlas.pem ec2-user@13.60.216.136:~/file.txt .

# Check disk space
df -h

# Check memory
free -h

# Restart services
sudo systemctl restart nginx
pm2 restart eatlas-backend
```

## Next Steps

1. ✅ Connect to EC2
2. ✅ Setup Node.js and dependencies
3. ✅ Clone repository
4. ✅ Configure backend and frontend
5. ✅ Setup Nginx
6. ✅ Start backend with PM2
7. ✅ Test application
8. ⏳ Setup SSL certificate
9. ⏳ Setup monitoring
10. ⏳ Setup backups
