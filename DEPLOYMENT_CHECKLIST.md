# AWS Deployment Checklist - Eatlas

## Pre-Deployment (Local Testing)

- [ ] All environment variables set in `.env` files
- [ ] Backend runs locally: `cd backend && npm run dev`
- [ ] Frontend runs locally: `cd frontend && npm start`
- [ ] API endpoints tested with Postman/Insomnia
- [ ] Database connection working
- [ ] No console errors or warnings
- [ ] Git repository up to date

## AWS Account Setup

- [ ] AWS Account created
- [ ] AWS CLI installed and configured
- [ ] EB CLI installed
- [ ] IAM user with appropriate permissions created
- [ ] AWS credentials configured locally

## MongoDB Atlas Setup

- [ ] MongoDB Atlas account created
- [ ] Cluster created (free tier)
- [ ] Database user created with strong password
- [ ] Connection string obtained
- [ ] IP whitelist configured (or 0.0.0.0/0 for testing)
- [ ] Test connection from local machine

## Backend Deployment (Elastic Beanstalk)

- [ ] EB initialized: `eb init`
- [ ] Environment created: `eb create`
- [ ] Environment variables set:
  - [ ] MONGO_URI
  - [ ] JWT_SECRET
  - [ ] CLOUDINARY_CLOUD_NAME
  - [ ] CLOUDINARY_API_KEY
  - [ ] CLOUDINARY_API_SECRET
  - [ ] NODE_ENV=production
- [ ] Backend deployed: `eb deploy`
- [ ] Backend URL obtained
- [ ] Health check passed: `eb health`
- [ ] API endpoint tested: `curl https://[backend-url]/api/health`

## Frontend Deployment

- [ ] Update `.env.production` with backend API URL
- [ ] Frontend built: `npm run build`
- [ ] Build output verified in `dist/` folder
- [ ] S3 bucket created
- [ ] Build files uploaded to S3
- [ ] S3 static website hosting enabled
- [ ] CloudFront distribution created
- [ ] CloudFront URL obtained
- [ ] Frontend accessible via CloudFront

## CORS & Security

- [ ] Backend CORS configured for frontend URL
- [ ] HTTPS enabled on both frontend and backend
- [ ] SSL certificate installed (AWS Certificate Manager)
- [ ] Security headers configured
- [ ] CORS headers verified in browser DevTools

## Testing

- [ ] Frontend loads without errors
- [ ] API calls work from frontend
- [ ] Authentication flow tested
- [ ] File uploads working (Cloudinary)
- [ ] Maps loading correctly
- [ ] Database operations working
- [ ] Error handling tested

## Monitoring & Logging

- [ ] CloudWatch logs configured
- [ ] Alarms set for:
  - [ ] High CPU usage
  - [ ] High memory usage
  - [ ] Application errors
- [ ] Log retention configured
- [ ] Dashboard created for monitoring

## Domain & DNS (Optional)

- [ ] Domain registered (Route 53 or external)
- [ ] DNS records configured
- [ ] SSL certificate for custom domain
- [ ] Domain pointing to CloudFront

## Backup & Disaster Recovery

- [ ] MongoDB backup enabled
- [ ] S3 versioning enabled
- [ ] Disaster recovery plan documented
- [ ] Rollback procedure tested

## Performance Optimization

- [ ] Frontend assets minified
- [ ] Images optimized
- [ ] CloudFront caching configured
- [ ] Database indexes created
- [ ] API response times acceptable

## Documentation

- [ ] Deployment steps documented
- [ ] Environment variables documented
- [ ] API documentation updated
- [ ] Troubleshooting guide created
- [ ] Team trained on deployment process

## Post-Deployment

- [ ] Monitor application for 24 hours
- [ ] Check error logs regularly
- [ ] Verify all features working
- [ ] Get user feedback
- [ ] Plan for scaling if needed

---

## Quick Commands Reference

```bash
# Initialize EB
eb init -p "Node.js 20 running on 64bit Amazon Linux 2" eatlas-backend --region ap-south-1

# Create environment
eb create eatlas-prod --instance-type t3.micro

# Set environment variables
eb setenv MONGO_URI="..." JWT_SECRET="..." NODE_ENV="production"

# Deploy
eb deploy

# View logs
eb logs

# Check health
eb health

# SSH into instance
eb ssh

# Terminate environment
eb terminate eatlas-prod
```

## Estimated Timeline

| Task | Time |
|------|------|
| AWS Account Setup | 15 min |
| MongoDB Atlas Setup | 10 min |
| EB Initialization | 5 min |
| Backend Deployment | 10 min |
| Frontend Build | 5 min |
| S3 & CloudFront Setup | 15 min |
| Testing & Verification | 20 min |
| **Total** | **80 min** |

## Support & Resources

- [AWS Elastic Beanstalk Docs](https://docs.aws.amazon.com/elasticbeanstalk/)
- [MongoDB Atlas Docs](https://docs.mongodb.com/atlas/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [EB CLI Reference](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html)
