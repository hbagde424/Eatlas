# Fix PEM File Permissions - Windows

## Problem
```
Bad permissions. Try removing permissions for user: Acer_123\CodexSandboxUsers
WARNING: UNPROTECTED PRIVATE KEY FILE!
Permissions for 'C:/Users/devel/Downloads/ElectionAtlas.pem' are too open.
```

## Solution 1: Use AWS Systems Manager (Recommended - No PEM needed!)

### Step 1: Install AWS CLI
```powershell
# Option A: Using Chocolatey
choco install awscli

# Option B: Download from
https://aws.amazon.com/cli/
```

### Step 2: Configure AWS Credentials
```powershell
aws configure

# Enter:
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: eu-north-1
# Default output: json
```

### Step 3: Connect to EC2 (No PEM needed!)
```powershell
aws ssm start-session --target i-042c125486445c062 --region eu-north-1
```

### Step 4: You're Connected!
```bash
# Now run commands directly
cd ~/eatlas
git pull origin main
cd frontend && npm run build
cd ../backend
pm2 restart eatlas-backend
```

---

## Solution 2: Fix PEM File Permissions (If you want to use SSH)

### Method A: PowerShell (Recommended)

```powershell
# Step 1: Set the PEM file path
$pemFile = "C:\Users\devel\Downloads\ElectionAtlas.pem"

# Step 2: Remove all permissions
icacls $pemFile /inheritance:r

# Step 3: Grant only to current user
icacls $pemFile /grant:r "$env:USERNAME`:(F)"

# Step 4: Verify permissions
icacls $pemFile

# Step 5: Try SSH
ssh -i $pemFile ec2-user@13.60.216.136
```

### Method B: Command Prompt

```cmd
cd C:\Users\devel\Downloads

REM Remove all permissions
icacls ElectionAtlas.pem /inheritance:r

REM Grant to current user
icacls ElectionAtlas.pem /grant:r "%USERNAME%:(F)"

REM Verify
icacls ElectionAtlas.pem

REM Try SSH
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136
```

### Method C: Complete Reset

```powershell
# If above doesn't work, try complete reset:

$pemFile = "C:\Users\devel\Downloads\ElectionAtlas.pem"

# Remove all permissions completely
icacls $pemFile /inheritance:r /remove "*S-1-5-21-1314348407-85244533-2553286295-1005"

# Grant only to SYSTEM and current user
icacls $pemFile /grant:r "SYSTEM:(F)"
icacls $pemFile /grant:r "$env:USERNAME`:(F)"

# Verify
icacls $pemFile

# Try SSH
ssh -i $pemFile ec2-user@13.60.216.136
```

---

## Solution 3: Use PuTTY (GUI Alternative)

### Step 1: Download PuTTY
```
https://www.putty.org/
```

### Step 2: Convert PEM to PPK
```
1. Download PuTTYgen
2. Open PuTTYgen
3. Click "Load" → Select ElectionAtlas.pem
4. Click "Save private key" → Save as ElectionAtlas.ppk
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

## Solution 4: Use AWS EC2 Instance Connect (Browser)

### Easiest Method - No Setup Needed!

```
1. Go to: https://console.aws.amazon.com/ec2/
2. Click "Instances"
3. Select: i-042c125486445c062
4. Click "Connect" button
5. Select "EC2 Instance Connect" tab
6. Click "Connect"
7. Browser terminal opens!
```

---

## Recommended: Use Session Manager

### Why Session Manager?
- ✅ No PEM file issues
- ✅ No SSH key problems
- ✅ Built-in AWS security
- ✅ Works on Windows/Mac/Linux
- ✅ No additional tools needed

### Quick Setup:
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

---

## Troubleshooting

### Still getting permission errors?

```powershell
# Check current permissions
icacls "C:\Users\devel\Downloads\ElectionAtlas.pem"

# Remove all permissions
icacls "C:\Users\devel\Downloads\ElectionAtlas.pem" /inheritance:r

# Grant to current user only
icacls "C:\Users\devel\Downloads\ElectionAtlas.pem" /grant:r "$env:USERNAME`:(F)"

# Verify
icacls "C:\Users\devel\Downloads\ElectionAtlas.pem"
```

### SSH still not working?

```powershell
# Try with verbose output
ssh -v -i "C:\Users\devel\Downloads\ElectionAtlas.pem" ec2-user@13.60.216.136

# Check if SSH is installed
ssh -V

# If not installed, install OpenSSH:
# Settings → Apps → Optional features → Add feature → OpenSSH Client
```

### AWS CLI not found?

```powershell
# Install AWS CLI
choco install awscli

# Or download from:
https://aws.amazon.com/cli/

# Verify installation
aws --version
```

---

## Quick Reference

| Method | Difficulty | Setup Time | Best For |
|--------|-----------|-----------|----------|
| Session Manager | Easy | 5 min | ⭐ Recommended |
| EC2 Instance Connect | Very Easy | 0 min | Quick access |
| PuTTY | Medium | 10 min | GUI users |
| SSH + Fixed PEM | Hard | 15 min | CLI users |

---

## Next Steps

### Option 1: Use Session Manager (Recommended)
```powershell
choco install awscli
aws configure
aws ssm start-session --target i-042c125486445c062 --region eu-north-1
```

### Option 2: Use EC2 Instance Connect
```
1. Go to AWS Console
2. Select EC2 instance
3. Click "Connect"
```

### Option 3: Fix PEM and Use SSH
```powershell
icacls "C:\Users\devel\Downloads\ElectionAtlas.pem" /inheritance:r /grant:r "$env:USERNAME`:(F)"
ssh -i "C:\Users\devel\Downloads\ElectionAtlas.pem" ec2-user@13.60.216.136
```

---

## Commands Once Connected

```bash
# Check status
pm2 status
pm2 logs eatlas-backend

# Deploy
cd ~/eatlas
git pull origin main
cd frontend && npm install && npm run build
cd ../backend && npm install
pm2 restart eatlas-backend
sudo systemctl reload nginx

# Verify
curl http://localhost/
curl http://localhost:5000/api/health
```

---

**Recommendation:** Use **Session Manager** - it's the easiest and most reliable! 🚀
