# EC2 Connection Guide - Multiple Methods

## Problem: PEM File Permissions Issue

Windows mein SSH key permissions issue ho raha hai. Koi baat nahi, multiple ways hain connect karne ke liye!

## Method 1: AWS Systems Manager Session Manager (Recommended)

### Advantages:
- ✅ No PEM file needed
- ✅ No SSH key issues
- ✅ Built-in AWS security
- ✅ Easiest method

### Steps:

#### Step 1: Install AWS CLI
```powershell
# Download from: https://aws.amazon.com/cli/
# Or use Chocolatey:
choco install awscli
```

#### Step 2: Configure AWS Credentials
```powershell
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: eu-north-1
# Default output: json
```

#### Step 3: Connect to EC2
```powershell
# Connect using Session Manager
aws ssm start-session --target i-042c125486445c062 --region eu-north-1
```

#### Step 4: You're Connected!
```bash
# Now you can run commands directly
whoami
pwd
ls -la
```

---

## Method 2: Fix PEM File Permissions (Advanced)

### For Windows PowerShell:

```powershell
# Step 1: Set correct permissions
$pemFile = "C:\Users\devel\Downloads\ElectionAtlas.pem"

# Remove all permissions
icacls $pemFile /inheritance:r

# Grant only to current user
icacls $pemFile /grant:r "$env:USERNAME`:(F)"

# Verify
icacls $pemFile

# Step 2: Try SSH again
ssh -i $pemFile ec2-user@13.60.216.136
```

### For Windows Command Prompt:

```cmd
# Navigate to PEM file
cd C:\Users\devel\Downloads

# Fix permissions
icacls ElectionAtlas.pem /inheritance:r /grant:r "%USERNAME%:(F)"

# Try SSH
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136
```

---

## Method 3: Use PuTTY (GUI Tool)

### Step 1: Download PuTTY
```
https://www.putty.org/
```

### Step 2: Convert PEM to PPK
```
1. Open PuTTYgen
2. Click "Load" → Select ElectionAtlas.pem
3. Click "Save private key" → Save as ElectionAtlas.ppk
```

### Step 3: Connect with PuTTY
```
1. Open PuTTY
2. Host: 13.60.216.136
3. Port: 22
4. Connection → SSH → Auth → Private key file: ElectionAtlas.ppk
5. Click "Open"
6. Login as: ec2-user
```

---

## Method 4: AWS EC2 Instance Connect (Browser)

### Step 1: Go to AWS Console
```
https://console.aws.amazon.com/ec2/
```

### Step 2: Select Instance
```
1. Click "Instances"
2. Select: i-042c125486445c062
3. Click "Connect" button
```

### Step 3: Use EC2 Instance Connect
```
1. Select "EC2 Instance Connect" tab
2. Click "Connect"
3. Browser-based terminal opens!
```

---

## Recommended: Use Session Manager

### Complete Setup:

```powershell
# 1. Install AWS CLI
choco install awscli

# 2. Configure credentials
aws configure
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: eu-north-1

# 3. Connect to EC2
aws ssm start-session --target i-042c125486445c062 --region eu-north-1

# 4. Now you're in EC2!
# Run deployment commands:
cd ~/eatlas
git pull origin main
cd frontend && npm install && npm run build
cd ../backend && npm install
pm2 restart eatlas-backend
sudo systemctl reload nginx
```

---

## Quick Deployment via Session Manager

```powershell
# 1. Connect
aws ssm start-session --target i-042c125486445c062 --region eu-north-1

# 2. Run deployment
cd ~/eatlas
git pull origin main
cd frontend
npm install
npm run build
cd ../backend
npm install
pm2 restart eatlas-backend
sudo systemctl reload nginx

# 3. Check status
pm2 status
curl http://localhost/
```

---

## Troubleshooting

### Session Manager not working?
```powershell
# Check if instance has IAM role
aws ec2 describe-instances --instance-ids i-042c125486445c062 --region eu-north-1

# Check if SSM agent is running
# (It should be on Amazon Linux 2)
```

### Still PEM permission issues?
```powershell
# Delete and re-download PEM file from AWS Console
# Then set permissions again:
icacls "C:\Users\devel\Downloads\ElectionAtlas.pem" /inheritance:r /grant:r "$env:USERNAME`:(F)"
```

### Can't find AWS Access Key?
```
1. Go to: https://console.aws.amazon.com/iam/
2. Click "Users"
3. Select your user
4. Click "Security credentials"
5. Click "Create access key"
6. Copy Access Key ID and Secret Access Key
```

---

## Recommended Connection Methods (Priority)

1. **✅ AWS Systems Manager Session Manager** - Easiest, no PEM issues
2. **✅ AWS EC2 Instance Connect** - Browser-based, no setup
3. **⚠️ PuTTY** - GUI tool, requires PPK conversion
4. **⚠️ SSH with PEM** - Command line, permission issues on Windows

---

## Next Steps

### Option A: Use Session Manager (Recommended)
```powershell
# 1. Install AWS CLI
choco install awscli

# 2. Configure
aws configure

# 3. Connect
aws ssm start-session --target i-042c125486445c062 --region eu-north-1

# 4. Deploy
cd ~/eatlas && git pull origin main && cd frontend && npm run build && cd ../backend && pm2 restart eatlas-backend
```

### Option B: Use EC2 Instance Connect (Easiest)
```
1. Go to AWS Console
2. Select EC2 instance
3. Click "Connect"
4. Use browser terminal
```

### Option C: Fix PEM and Use SSH
```powershell
# Fix permissions
icacls "C:\Users\devel\Downloads\ElectionAtlas.pem" /inheritance:r /grant:r "$env:USERNAME`:(F)"

# Connect
ssh -i "C:\Users\devel\Downloads\ElectionAtlas.pem" ec2-user@13.60.216.136
```

---

## Commands Once Connected

```bash
# Check application status
pm2 status
pm2 logs eatlas-backend

# Update application
cd ~/eatlas
git pull origin main
cd frontend && npm install && npm run build
cd ../backend && npm install
pm2 restart eatlas-backend
sudo systemctl reload nginx

# Check if running
curl http://localhost/
curl http://localhost:5000/api/health

# View logs
pm2 logs eatlas-backend --lines 50
sudo tail -f /var/log/nginx/access.log
```

---

## Summary

| Method | Difficulty | Setup Time | Pros | Cons |
|--------|-----------|-----------|------|------|
| Session Manager | Easy | 5 min | No PEM issues | Need AWS CLI |
| EC2 Instance Connect | Very Easy | 0 min | Browser-based | Limited features |
| PuTTY | Medium | 10 min | GUI | Need conversion |
| SSH + PEM | Hard | 15 min | Standard | Permission issues |

**Recommendation:** Use **Session Manager** or **EC2 Instance Connect** 🚀
