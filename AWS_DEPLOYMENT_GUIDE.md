# AWS Deployment Guide - Eatlas Project

## Architecture Overview
```
┌─────────────────────────────────────────────────────────┐
│                    AWS Cloud                             │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────┐         ┌──────────────────┐      │
│  │  CloudFront CDN  │         │  Elastic Beanstalk│      │
│  │  (Frontend)      │         │  (Backend API)   │      │
│  └──────────────────┘         └──────────────────┘      │
│           │                            │                 │
│           └────────────────┬───────────┘                 │
│                            │                             │
│                    ┌───────▼────────┐                    │
│                    │  MongoDB Atlas  │                    │
│                    │  (Database)     │                    │
│                    └────────────────┘                    │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Step 1: Prepare MongoDB Atlas

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a free cluster
3. Create a database user with password
4. Get connection string: `mongodb+srv://username:password@cluster.mongodb.net/electionAT`
5. Whitelist AWS IP ranges or use `0.0.0.0/0` (for testing only)

## Step 2: Setup AWS Elastic Beanstalk (Backend)

### 2.1 Install AWS CLI
```bash
# Windows
choco install awscli

# Or download from: https://aws.amazon.com/cli/
```

### 2.2 Configure AWS Credentials
```bash
aws configure
# Enter:
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: ap-south-1 (or your region)
# Default output format: json
```

### 2.3 Install EB CLI
```bash
pip install awsebcli
```

### 2.4 Initialize Elastic Beanstalk
```bash
# From project root
eb init -p "Node.js 20 running on 64bit Amazon Linux 2" eatlas-backend --region ap-south-1
```

### 2.5 Create Environment
```bash
eb create eatlas-prod --instance-type t3.micro --envvars MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/electionAT,JWT_SECRET=your-secret-key,NODE_ENV=production
```

### 2.6 Set Environment Variables
```bash
eb setenv \
  MONGO_URI="mongodb+srv://username:password@cluster.mongodb.net/electionAT" \
  JWT_SECRET="your-jwt-secret-key" \
  CLOUDINARY_CLOUD_NAME="your-cloudinary-name" \
  CLOUDINARY_API_KEY="your-api-key" \
  CLOUDINARY_API_SECRET="your-api-secret" \
  NODE_ENV="production"
```

### 2.7 Deploy Backend
```bash
eb deploy
```

### 2.8 Get Backend URL
```bash
eb open
# This will open your backend URL in browser
# Save this URL: https://eatlas-prod.elasticbeanstalk.com
```

## Step 3: Build & Deploy Frontend

### 3.1 Update Frontend API URL
Edit `frontend/.env.production`:
```env
VITE_APP_API_URL=https://eatlas-prod.elasticbeanstalk.com/api
VITE_APP_MAPBOX_ACCESS_TOKEN=your-mapbox-token
VITE_APP_GOOGLE_MAPS_API_KEY=your-google-maps-key
```

### 3.2 Build Frontend
```bash
cd frontend
npm install
npm run build
```

### 3.3 Deploy to S3 + CloudFront

#### Option A: Using AWS Console
1. Create S3 bucket: `eatlas-frontend-prod`
2. Enable static website hosting
3. Upload `frontend/dist` contents
4. Create CloudFront distribution pointing to S3
5. Enable CORS on S3 bucket

#### Option B: Using AWS CLI
```bash
# Create S3 bucket
aws s3 mb s3://eatlas-frontend-prod --region ap-south-1

# Upload build files
aws s3 sync frontend/dist s3://eatlas-frontend-prod --delete

# Create CloudFront distribution (use AWS Console for this)
```

## Step 4: Configure CORS on Backend

Update `backend/app.js`:
```javascript
const cors = require('cors');

app.use(cors({
  origin: [
    'https://eatlas-frontend-prod.s3.amazonaws.com',
    'https://d123456.cloudfront.net', // Your CloudFront URL
    'http://localhost:3000' // For local development
  ],
  credentials: true
}));
```

## Step 5: Setup Custom Domain (Optional)

### 5.1 Register Domain
- Use Route 53 or external registrar

### 5.2 Point to CloudFront
- In Route 53, create A record pointing to CloudFront distribution
- Or update nameservers at your registrar

## Step 6: Monitor & Logs

### View Backend Logs
```bash
eb logs
```

### SSH into Instance
```bash
eb ssh
```

### Monitor Performance
```bash
eb health
```

## Step 7: CI/CD Pipeline (Optional)

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deploy Backend
        run: |
          pip install awsebcli
          eb deploy
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      
      - name: Build & Deploy Frontend
        run: |
          cd frontend
          npm install
          npm run build
          aws s3 sync dist s3://eatlas-frontend-prod --delete
```

## Troubleshooting

### Backend not connecting to MongoDB
```bash
# Check logs
eb logs

# Verify connection string
eb printenv
```

### Frontend CORS errors
- Check backend CORS configuration
- Verify CloudFront URL in CORS whitelist

### Large file upload issues
- Increase Elastic Beanstalk instance size
- Configure nginx timeout in `.ebextensions/nginx.config`

## Cost Estimation (Monthly)

| Service | Tier | Cost |
|---------|------|------|
| Elastic Beanstalk | t3.micro | $10-15 |
| MongoDB Atlas | Free/Shared | $0-50 |
| S3 | Standard | $1-5 |
| CloudFront | Data transfer | $0.085/GB |
| **Total** | | **$15-70** |

## Security Checklist

- [ ] Enable HTTPS/SSL certificate (AWS Certificate Manager)
- [ ] Setup WAF (Web Application Firewall)
- [ ] Enable VPC security groups
- [ ] Rotate JWT secret regularly
- [ ] Use AWS Secrets Manager for sensitive data
- [ ] Enable CloudTrail for audit logs
- [ ] Setup CloudWatch alarms

## Next Steps

1. Test backend API: `curl https://eatlas-prod.elasticbeanstalk.com/api/health`
2. Test frontend: Visit CloudFront URL
3. Setup monitoring & alerts
4. Configure auto-scaling
5. Setup backup strategy for MongoDB
