# Quick Deployment Guide - Eatlas to EC2

## Current Status
- **Instance IP**: 13.60.216.136
- **Instance ID**: i-042c125486445c062
- **Region**: eu-north-1
- **OS**: Ubuntu 22.04
- **Backend Status**: Fixed (District model import case sensitivity issue resolved)

## What Was Fixed
The backend was crashing due to a case sensitivity issue in the District model import:
- **Problem**: `require('../models/District')` but file is `district.js` (lowercase)
- **Solution**: Changed import to `require('../models/district')`
- **Status**: ✓ Fixed and pushed to GitHub

## Deployment Methods

### Method 1: Using AWS Systems Manager Session Manager (Recommended - No SSH Keys)

**Prerequisites:**
- AWS CLI installed and configured
- IAM permissions for SSM (Systems Manager)

**Steps:**

1. **Run the deployment script:**
   ```powershell
   .\deploy-to-ec2-ssm.ps1
   ```

2. **Or manually via AWS Console:**
   - Go to AWS EC2 Console
   - Select instance `i-042c125486445c062`
   - Click "Connect" → "Session Manager" tab
   - Click "Connect"
   - Run these commands:
     ```bash
     cd ~/eatlas
     git pull origin main
     cd backend
     npm install
     pm2 restart eatlas-backend
     sleep 3
     pm2 status
     curl http://localhost:5000/api/health
     ```

### Method 2: Using SSH (Requires PEM Key Permissions Fixed)

**Prerequisites:**
- PEM key file with correct permissions (600)
- SSH access enabled

**Steps:**

1. **Fix PEM permissions (Windows):**
   ```powershell
   # Run as Administrator
   icacls "C:\Users\devel\Downloads\ElectionAtlas.pem" /inheritance:r /grant:r "%USERNAME%:F"
   ```

2. **Deploy via SSH:**
   ```bash
   ssh -i "C:/Users/devel/Downloads/ElectionAtlas.pem" ubuntu@13.60.216.136
   ```

3. **On the instance:**
   ```bash
   cd ~/eatlas
   git pull origin main
   cd backend
   npm install
   pm2 restart eatlas-backend
   ```

### Method 3: Using EC2 Instance Connect (Browser Terminal)

**Steps:**

1. Go to AWS EC2 Console
2. Select instance `i-042c125486445c062`
3. Click "Connect" → "EC2 Instance Connect" tab
4. Click "Connect"
5. Run deployment commands:
   ```bash
   cd ~/eatlas
   git pull origin main
   cd backend
   npm install
   pm2 restart eatlas-backend
   sleep 3
   pm2 status
   curl http://localhost:5000/api/health
   ```

## Verification Steps

After deployment, verify everything is working:

```bash
# Check backend status
pm2 status

# Test backend health
curl http://localhost:5000/api/health

# Test frontend
curl http://localhost/

# View backend logs
pm2 logs eatlas-backend

# View Nginx logs
sudo tail -f /var/log/nginx/error.log
```

## Access Application

- **Frontend**: http://13.60.216.136
- **Backend API**: http://13.60.216.136:5000/api
- **Health Check**: http://13.60.216.136:5000/api/health

## Troubleshooting

### Backend keeps crashing (137 restarts)
1. Check logs: `pm2 logs eatlas-backend`
2. Look for MODULE_NOT_FOUND errors
3. Verify all model imports have correct case sensitivity
4. Restart: `pm2 restart eatlas-backend`

### Cannot connect to MongoDB
1. Check `.env` file: `cat ~/eatlas/backend/.env`
2. Verify MongoDB URI is correct
3. Test connection: `curl https://cluster0.8ehw8jn.mongodb.net/`

### Nginx 500 error
1. Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`
2. Verify backend is running: `pm2 status`
3. Test backend directly: `curl http://localhost:5000/api/health`

### Git pull fails
1. Check git status: `git status`
2. Stash changes if needed: `git stash`
3. Try pull again: `git pull origin main`

## Cost Information

**AWS Free Tier (12 months):**
- EC2 t3.micro: FREE
- Data transfer (100GB/month): FREE
- Total monthly cost: **$0** (within free tier)

**After free tier:**
- EC2 t3.micro: ~$8-10/month
- Data transfer: ~$0.09/GB (after 100GB)
- MongoDB Atlas: ~$0 (512MB free tier)
- **Estimated total: $10-15/month**

## Next Steps

1. ✓ Deploy the fix to EC2
2. ✓ Verify backend is running
3. ✓ Test API endpoints
4. ✓ Test frontend
5. Set up monitoring (CloudWatch)
6. Set up auto-scaling (optional)
7. Set up SSL certificate (Let's Encrypt)

## Support

For issues or questions:
1. Check logs: `pm2 logs eatlas-backend`
2. Review deployment guide
3. Check AWS documentation
4. Review GitHub repository: https://github.com/hbagde424/Eatlas.git
