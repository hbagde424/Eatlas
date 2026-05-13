# Quick Start - EC2 Deployment

## Your Setup
- **EC2 IP:** 13.60.216.136
- **PEM File:** C:\Users\devel\Downloads\ElectionAtlas.pem
- **MongoDB:** mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT
- **Region:** eu-north-1

## Option 1: Automated Deployment (Recommended)

### Windows Users
```powershell
# Run the batch script
.\deploy.bat

# Select option [2] Deploy Application
# Script will automatically:
# - Upload deployment script
# - Install Node.js, PM2, Nginx
# - Clone repository
# - Build frontend
# - Start backend
# - Configure everything
```

### Mac/Linux Users
```bash
# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh

# Or SSH and run directly:
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136
chmod +x ~/deploy.sh
~/deploy.sh
```

## Option 2: Manual Deployment (Step by Step)

### Step 1: Connect to EC2
```powershell
# Windows PowerShell
cd C:\Users\devel\Downloads
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136
```

### Step 2: Setup System
```bash
# Update system
sudo yum update -y

# Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Install PM2 and Nginx
sudo npm install -g pm2
sudo yum install -y nginx git

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Step 3: Clone & Setup Application
```bash
# Create app directory
mkdir -p ~/eatlas
cd ~/eatlas

# Clone repository
git clone https://github.com/hbagde424/Eatlas.git .

# Setup backend
cd backend
npm install

# Create .env file
cat > .env << 'EOF'
MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT
JWT_SECRET=your-super-secret-key-change-this
JWT_EXPIRE=30d
NODE_ENV=production
PORT=5000
CLOUDINARY_CLOUD_NAME=dpaui8plb
CLOUDINARY_API_KEY=873488488411495
CLOUDINARY_API_SECRET=your-secret
CLOUDINARY_UPLOAD_PRESET=your_preset
EOF

# Setup frontend
cd ../frontend
npm install
npm run build
```

### Step 4: Configure Nginx
```bash
# Copy nginx config from EC2_DEPLOYMENT_GUIDE.md
# Or use this quick command:
sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events { worker_connections 1024; }

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    
    upstream backend { server 127.0.0.1:5000; }
    
    server {
        listen 80;
        server_name _;
        
        location / {
            root /home/ec2-user/eatlas/frontend/dist;
            try_files $uri $uri/ /index.html;
        }
        
        location /api/ {
            proxy_pass http://backend/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
EOF

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### Step 5: Start Backend
```bash
cd ~/eatlas/backend

# Start with PM2
pm2 start server.js --name "eatlas-backend"

# Save PM2 config
pm2 save

# Setup auto-start on reboot
pm2 startup
# Copy and run the command it outputs
```

### Step 6: Verify
```bash
# Check backend
curl http://localhost:5000/api/health

# Check frontend
curl http://localhost/

# Check PM2
pm2 status
```

## Access Your Application

Open browser and go to:
```
http://13.60.216.136
```

## Common Tasks

### View Logs
```bash
# Backend logs
pm2 logs eatlas-backend

# Nginx logs
sudo tail -f /var/log/nginx/access.log
```

### Restart Backend
```bash
pm2 restart eatlas-backend
```

### Update Application
```bash
cd ~/eatlas
git pull origin main
cd frontend && npm install && npm run build
cd ../backend && npm install
pm2 restart eatlas-backend
sudo systemctl reload nginx
```

### Stop Application
```bash
pm2 stop eatlas-backend
sudo systemctl stop nginx
```

### Start Application
```bash
pm2 start eatlas-backend
sudo systemctl start nginx
```

## Troubleshooting

### Can't connect to EC2
```powershell
# Check PEM file permissions (Windows)
icacls C:\Users\devel\Downloads\ElectionAtlas.pem /inheritance:r /grant:r "$env:USERNAME`:(F)"

# Try connecting again
ssh -i C:\Users\devel\Downloads\ElectionAtlas.pem ec2-user@13.60.216.136
```

### Backend not running
```bash
# Check logs
pm2 logs eatlas-backend

# Check if port 5000 is in use
sudo lsof -i :5000

# Restart
pm2 restart eatlas-backend
```

### MongoDB connection error
```bash
# Test connection
node -e "require('mongoose').connect('mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT').then(() => console.log('✓ Connected')).catch(e => console.log('✗ Error:', e.message))"
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

## Security Tips

### 1. Change JWT Secret
Edit `backend/.env`:
```bash
JWT_SECRET=your-new-super-secret-key-min-32-chars
```

### 2. Update Cloudinary Credentials
Get from: https://cloudinary.com/console

### 3. Setup SSL Certificate
```bash
sudo yum install -y certbot python3-certbot-nginx
sudo certbot certonly --nginx -d yourdomain.com
```

### 4. Firewall Rules
```bash
# Allow SSH, HTTP, HTTPS only
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## Performance Monitoring

### Check System Resources
```bash
# CPU and Memory
top

# Disk usage
df -h

# Network connections
netstat -an | grep ESTABLISHED | wc -l
```

### Monitor Application
```bash
# Real-time monitoring
pm2 monit

# Check application status
pm2 status
```

## Backup & Recovery

### Backup Database
```bash
# MongoDB Atlas has automatic backups
# Access at: https://cloud.mongodb.com/
```

### Backup Application Code
```bash
# Code is in git, just push regularly
cd ~/eatlas
git push origin main
```

## Next Steps

1. ✅ Deploy application
2. ⏳ Update Cloudinary credentials
3. ⏳ Update Mapbox token
4. ⏳ Setup custom domain
5. ⏳ Setup SSL certificate
6. ⏳ Configure monitoring
7. ⏳ Setup backups

## Support

For detailed information, see:
- `EC2_DEPLOYMENT_GUIDE.md` - Complete guide
- `AWS_DEPLOYMENT_GUIDE.md` - AWS-specific setup
- `DEPLOYMENT_CHECKLIST.md` - Pre/post deployment checklist

## Quick Reference

| Command | Purpose |
|---------|---------|
| `ssh -i ElectionAtlas.pem ec2-user@13.60.216.136` | Connect to EC2 |
| `pm2 logs eatlas-backend` | View backend logs |
| `pm2 restart eatlas-backend` | Restart backend |
| `sudo systemctl reload nginx` | Reload Nginx |
| `curl http://localhost:5000/api/health` | Test backend |
| `curl http://localhost/` | Test frontend |

---

**Ready to deploy?** Run `.\deploy.bat` (Windows) or `./deploy.sh` (Mac/Linux)
