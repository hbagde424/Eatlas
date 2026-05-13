#!/bin/bash

# Fix MongoDB connection on EC2 instance
# This script updates the .env file to use MongoDB Atlas instead of localhost

echo "=========================================="
echo "Fixing MongoDB Connection on EC2"
echo "=========================================="
echo ""

# SSH into the instance and update .env
ssh -i "C:/Users/devel/Downloads/ElectionAtlas.pem" ubuntu@13.60.216.136 << 'EOF'
  echo "Connecting to EC2 instance..."
  echo ""
  
  # Navigate to backend directory
  cd ~/eatlas/backend
  
  echo "Current .env file:"
  echo "===================="
  cat .env
  echo ""
  echo "===================="
  echo ""
  
  # Backup current .env
  cp .env .env.backup
  echo "✓ Backup created: .env.backup"
  echo ""
  
  # Update MongoDB URI to use Atlas
  echo "Updating MongoDB URI to use Atlas..."
  sed -i 's|MONGO_URI=mongodb://localhost:27017/electionAT|MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT|g' .env
  
  echo "Updated .env file:"
  echo "===================="
  cat .env
  echo ""
  echo "===================="
  echo ""
  
  # Restart backend
  echo "Restarting backend with PM2..."
  pm2 restart eatlas-backend
  
  echo ""
  echo "Waiting 3 seconds for backend to start..."
  sleep 3
  
  echo ""
  echo "Checking backend status..."
  pm2 status
  
  echo ""
  echo "Testing backend health endpoint..."
  curl http://localhost:5000/api/health
  
  echo ""
  echo "=========================================="
  echo "MongoDB Connection Fixed!"
  echo "=========================================="
EOF

echo ""
echo "Fix script completed!"
