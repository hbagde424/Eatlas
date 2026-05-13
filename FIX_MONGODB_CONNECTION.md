# Fix MongoDB Connection Issue

## Problem
The backend is not connecting to MongoDB because the `.env` file is pointing to **localhost** instead of **MongoDB Atlas**.

**Current (Wrong):**
```
MONGO_URI=mongodb://localhost:27017/electionAT
```

**Should be (Correct):**
```
MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT
```

## Solution

### Option 1: Automated Fix (Recommended - Windows)

**Using PowerShell:**
```powershell
.\fix-mongodb-connection.ps1
```

**Using Batch:**
```cmd
fix-mongodb-connection.bat
```

### Option 2: Manual Fix via AWS Console

1. Go to AWS EC2 Dashboard
2. Select instance `i-042c125486445c062`
3. Click "Connect" → "Session Manager" → "Connect"
4. Run these commands:

```bash
cd ~/eatlas/backend

# Backup current .env
cp .env .env.backup

# Update MongoDB URI
sed -i 's|MONGO_URI=mongodb://localhost:27017/electionAT|MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT|g' .env

# Verify the change
cat .env

# Restart backend
pm2 restart eatlas-backend

# Wait for backend to start
sleep 3

# Check status
pm2 status

# Test health endpoint
curl http://localhost:5000/api/health
```

### Option 3: Manual Fix via SSH

```bash
ssh -i "C:/Users/devel/Downloads/ElectionAtlas.pem" ubuntu@13.60.216.136

cd ~/eatlas/backend
cp .env .env.backup
sed -i 's|MONGO_URI=mongodb://localhost:27017/electionAT|MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT|g' .env
pm2 restart eatlas-backend
sleep 3
pm2 status
curl http://localhost:5000/api/health
```

## Verification

After applying the fix, verify everything is working:

```bash
# Check backend status
pm2 status

# Test backend health
curl http://localhost:5000/api/health

# Test API endpoint
curl http://localhost:5000/api/districts

# Check logs
pm2 logs eatlas-backend
```

## Expected Results

✅ **Backend should now:**
- Start successfully
- Connect to MongoDB Atlas
- Respond to health check: `http://13.60.216.136:5000/api/health`
- Respond to API endpoints: `http://13.60.216.136:5000/api/districts`

✅ **Frontend should now:**
- Load without 500 error: `http://13.60.216.136`
- Display the application

## Troubleshooting

### Backend still not starting
```bash
# Check logs for errors
pm2 logs eatlas-backend

# Check if MongoDB connection is working
curl https://cluster0.8ehw8jn.mongodb.net/

# Verify .env file was updated
cat ~/eatlas/backend/.env | grep MONGO_URI
```

### MongoDB connection timeout
- Verify MongoDB Atlas cluster is running
- Check network security groups allow outbound connections
- Verify MongoDB URI is correct

### Port 5000 still not responding
```bash
# Check if backend process is running
ps aux | grep node

# Check if port 5000 is listening
netstat -tlnp | grep 5000

# Restart backend
pm2 restart eatlas-backend
```

## Files Modified

- `backend/.env` - Updated MONGO_URI to use MongoDB Atlas

## Backup

A backup of the original `.env` file is created as `.env.backup` on the EC2 instance.

To restore:
```bash
cd ~/eatlas/backend
cp .env.backup .env
pm2 restart eatlas-backend
```

## Next Steps

1. ✅ Apply the MongoDB connection fix
2. ✅ Verify backend is running
3. ✅ Test API endpoints
4. ✅ Test frontend
5. Monitor application logs
6. Set up SSL certificate (optional)
7. Configure monitoring (optional)

## Support

For issues:
1. Check logs: `pm2 logs eatlas-backend`
2. Verify MongoDB URI: `cat ~/eatlas/backend/.env | grep MONGO_URI`
3. Test MongoDB connection: `curl https://cluster0.8ehw8jn.mongodb.net/`
4. Review AWS documentation
