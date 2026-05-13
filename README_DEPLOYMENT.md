# Eatlas - Deployment Documentation

## 🎯 Project Overview

**Eatlas** is a full-stack election management system with:
- **Frontend:** React + Vite (TypeScript)
- **Backend:** Node.js + Express
- **Database:** MongoDB Atlas
- **Hosting:** AWS EC2

## 📊 Current Setup

```
┌─────────────────────────────────────────────────────────┐
│                    AWS EC2 Instance                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────┐         ┌──────────────────┐      │
│  │  React Frontend  │         │  Node.js Backend │      │
│  │  (Nginx)         │◄────────│  (PM2)           │      │
│  └──────────────────┘         └──────────────────┘      │
│           │                            │                 │
│           └────────────────┬───────────┘                 │
│                            │                             │
│                    ┌───────▼────────┐                    │
│                    │  MongoDB Atlas  │                    │
│                    │  (Cloud DB)     │                    │
│                    └────────────────┘                    │
│                                                           │
│  IP: 13.60.216.136                                       │
│  Region: eu-north-1                                      │
│  Instance Type: t3.micro                                 │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Quick Deployment

### For Windows Users
```powershell
# 1. Open PowerShell in project root
# 2. Run deployment script
.\deploy.bat

# 3. Select option [2] Deploy Application
# 4. Wait for completion
# 5. Open browser: http://13.60.216.136
```

### For Mac/Linux Users
```bash
# 1. Make script executable
chmod +x deploy.sh

# 2. Run deployment
./deploy.sh

# 3. Wait for completion
# 4. Open browser: http://13.60.216.136
```

## 📋 Deployment Files

| File | Purpose |
|------|---------|
| `QUICK_START_EC2.md` | ⭐ Start here - Quick deployment guide |
| `EC2_DEPLOYMENT_GUIDE.md` | Detailed step-by-step guide |
| `AWS_DEPLOYMENT_GUIDE.md` | AWS Elastic Beanstalk alternative |
| `DEPLOYMENT_CHECKLIST.md` | Pre/post deployment checklist |
| `deploy.sh` | Automated deployment script (Mac/Linux) |
| `deploy.bat` | Automated deployment script (Windows) |

## 🔑 Credentials & Configuration

### MongoDB
```
URI: mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT
Database: electionAT
```

### EC2 Instance
```
IP Address: 13.60.216.136
PEM File: C:\Users\devel\Downloads\ElectionAtlas.pem
SSH User: ec2-user
Region: eu-north-1
```

### Environment Variables
```
MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT
JWT_SECRET=your-secret-key (change this!)
NODE_ENV=production
PORT=5000
CLOUDINARY_CLOUD_NAME=dpaui8plb
CLOUDINARY_API_KEY=873488488411495
CLOUDINARY_API_SECRET=your-secret
```

## 🌐 Access Points

| Service | URL |
|---------|-----|
| Frontend | http://13.60.216.136 |
| Backend API | http://13.60.216.136:5000/api |
| Health Check | http://13.60.216.136:5000/api/health |

## 📦 Project Structure

```
Eatlas/
├── backend/
│   ├── config/          # Database & configuration
│   ├── controllers/     # API controllers
│   ├── models/          # MongoDB models
│   ├── routes/          # API routes
│   ├── middlewares/     # Express middlewares
│   ├── utils/           # Utility functions
│   ├── server.js        # Entry point
│   └── package.json
│
├── frontend/
│   ├── src/
│   │   ├── components/  # React components
│   │   ├── pages/       # Page components
│   │   ├── hooks/       # Custom hooks
│   │   ├── utils/       # Utility functions
│   │   └── App.jsx      # Main app
│   ├── dist/            # Build output
│   └── package.json
│
├── .ebextensions/       # Elastic Beanstalk config
├── deploy.sh            # Linux/Mac deployment
├── deploy.bat           # Windows deployment
└── README_DEPLOYMENT.md # This file
```

## 🛠️ Common Tasks

### Connect to EC2
```powershell
ssh -i C:\Users\devel\Downloads\ElectionAtlas.pem ec2-user@13.60.216.136
```

### View Backend Logs
```bash
pm2 logs eatlas-backend
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

### Check Application Status
```bash
pm2 status
pm2 monit
```

## 🔒 Security Checklist

- [ ] Change JWT_SECRET to a strong random value
- [ ] Update Cloudinary credentials
- [ ] Update Mapbox API key
- [ ] Update Google Maps API key
- [ ] Setup SSL certificate (Let's Encrypt)
- [ ] Configure firewall rules
- [ ] Enable MongoDB IP whitelist
- [ ] Setup regular backups
- [ ] Monitor application logs
- [ ] Setup error alerts

## 📈 Performance Optimization

### Frontend
- ✅ Gzip compression enabled
- ✅ Browser caching configured (1 day)
- ✅ Static assets minified
- ⏳ CDN integration (optional)

### Backend
- ✅ Connection pooling configured
- ✅ Request logging enabled
- ✅ Error handling implemented
- ⏳ Rate limiting (optional)

### Database
- ✅ MongoDB Atlas free tier
- ⏳ Index optimization needed
- ⏳ Query optimization needed

## 💰 Cost Estimation

### 🎉 AWS Free Tier (12 months): **$0**

| Service | Free Tier | Your Usage | Cost |
|---------|-----------|-----------|------|
| EC2 t3.micro | 750 hrs/month | ✅ Your instance | $0 |
| Data Transfer | 100 GB/month | ✅ ~5-10 GB | $0 |
| MongoDB Atlas | 512 MB | ✅ ~100-200 MB | $0 |
| **Total (12 months)** | | | **$0** |

### After 12 months: ~$9/month
- EC2: ~$8/month
- Data transfer: ~$1/month
- MongoDB: $0 (free tier)

## 🐛 Troubleshooting

### Backend not connecting to MongoDB
```bash
# SSH into EC2
ssh -i ElectionAtlas.pem ec2-user@13.60.216.136

# Check logs
pm2 logs eatlas-backend

# Test connection
node -e "require('mongoose').connect('mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT').then(() => console.log('✓')).catch(e => console.log('✗', e.message))"
```

### Frontend not loading
```bash
# Check if dist folder exists
ls -la ~/eatlas/frontend/dist

# Check nginx config
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### Port already in use
```bash
# Find process using port 5000
sudo lsof -i :5000

# Kill process
sudo kill -9 <PID>
```

## 📚 Documentation

- **[QUICK_START_EC2.md](./QUICK_START_EC2.md)** - Start here!
- **[EC2_DEPLOYMENT_GUIDE.md](./EC2_DEPLOYMENT_GUIDE.md)** - Detailed guide
- **[AWS_DEPLOYMENT_GUIDE.md](./AWS_DEPLOYMENT_GUIDE.md)** - Elastic Beanstalk
- **[DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)** - Checklist

## 🔗 Useful Links

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [MongoDB Atlas Documentation](https://docs.mongodb.com/atlas/)
- [Node.js Documentation](https://nodejs.org/docs/)
- [React Documentation](https://react.dev/)
- [Express.js Documentation](https://expressjs.com/)

## 👥 Team

- **Project:** Eatlas - Election Management System
- **Repository:** https://github.com/hbagde424/Eatlas
- **Deployment:** AWS EC2 (eu-north-1)

## 📞 Support

For deployment issues:
1. Check `QUICK_START_EC2.md` troubleshooting section
2. Review application logs: `pm2 logs eatlas-backend`
3. Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`
4. Verify MongoDB connection
5. Check EC2 security groups

## 🎉 Next Steps

1. ✅ Deploy application using `deploy.bat` or `deploy.sh`
2. ⏳ Update Cloudinary credentials
3. ⏳ Update Mapbox token
4. ⏳ Setup custom domain
5. ⏳ Setup SSL certificate
6. ⏳ Configure monitoring
7. ⏳ Setup automated backups

---

**Last Updated:** May 2026
**Status:** Ready for Deployment ✅
