#!/bin/bash

# Eatlas EC2 Deployment Script
# This script pulls the latest changes from GitHub and restarts the backend

INSTANCE_IP="13.60.216.136"
INSTANCE_USER="ubuntu"
REMOTE_DIR="~/eatlas"

echo "=========================================="
echo "Eatlas EC2 Deployment Script"
echo "=========================================="
echo ""
echo "Instance: $INSTANCE_IP"
echo "User: $INSTANCE_USER"
echo "Remote Directory: $REMOTE_DIR"
echo ""

# SSH into the instance and run deployment commands
ssh -i "C:/Users/devel/Downloads/ElectionAtlas.pem" $INSTANCE_USER@$INSTANCE_IP << 'EOF'
  echo "Connecting to EC2 instance..."
  echo ""
  
  # Navigate to project directory
  cd ~/eatlas
  
  echo "Pulling latest changes from GitHub..."
  git pull origin main
  
  echo ""
  echo "Installing backend dependencies (if needed)..."
  cd backend
  npm install
  
  echo ""
  echo "Restarting backend with PM2..."
  pm2 restart eatlas-backend
  
  echo ""
  echo "Checking backend status..."
  pm2 status
  
  echo ""
  echo "Waiting 3 seconds for backend to start..."
  sleep 3
  
  echo ""
  echo "Testing backend health endpoint..."
  curl http://localhost:5000/api/health
  
  echo ""
  echo "Testing frontend..."
  curl http://localhost/
  
  echo ""
  echo "=========================================="
  echo "Deployment Complete!"
  echo "=========================================="
  echo "Application URL: http://$INSTANCE_IP"
  echo "Backend API: http://$INSTANCE_IP:5000/api"
EOF

echo ""
echo "Deployment script completed!"
