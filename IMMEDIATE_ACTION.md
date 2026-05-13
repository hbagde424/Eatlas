# 🚨 IMMEDIATE ACTION REQUIRED

## Issue Found
Backend is not running because `.env` file is pointing to **localhost MongoDB** instead of **MongoDB Atlas**.

## Quick Fix (Choose One)

### ✅ EASIEST - Run PowerShell Script (Windows)
```powershell
.\fix-mongodb-connection.ps1
```

### ✅ EASY - Run Batch Script (Windows)
```cmd
fix-mongodb-connection.bat
```

### ✅ MANUAL - AWS Console (Browser)
1. Go to AWS EC2 Dashboard
2. Select instance `i-042c125486445c062`
3. Click "Connect" → "Session Manager" → "Connect"
4. Copy and paste these commands:

```bash
cd ~/eatlas/backend && cp .env .env.backup && sed -i 's|MONGO_URI=mongodb://localhost:27017/electionAT|MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT|g' .env && pm2 restart eatlas-backend && sleep 3 && pm2 status && curl http://localhost:5000/api/health
```

## What This Does
1. ✅ Backs up current `.env` file
2. ✅ Updates MongoDB URI to use MongoDB Atlas
3. ✅ Restarts backend with PM2
4. ✅ Tests backend health

## Expected Result
- Backend starts successfully
- Frontend loads without 500 error
- API endpoints respond

## Test After Fix
- Frontend: http://13.60.216.136
- Backend API: http://13.60.216.136:5000/api
- Health Check: http://13.60.216.136:5000/api/health

## Detailed Guide
See: `FIX_MONGODB_CONNECTION.md`

---

**Status**: 🔴 Backend Down → 🟢 Backend Up (after fix)
