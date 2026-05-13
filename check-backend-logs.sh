#!/bin/bash

# Check backend logs on EC2 instance

echo "=========================================="
echo "Checking Backend Logs"
echo "=========================================="
echo ""

ssh -i "C:/Users/devel/Downloads/ElectionAtlas.pem" ubuntu@13.60.216.136 << 'EOF'
  echo "Checking PM2 logs (last 100 lines)..."
  echo "=========================================="
  pm2 logs eatlas-backend --lines 100 --nostream
  echo ""
  echo "=========================================="
  echo ""
  
  echo "Checking if backend process is running..."
  ps aux | grep node
  echo ""
  
  echo "Checking if port 5000 is listening..."
  netstat -tlnp | grep 5000 || echo "Port 5000 not listening"
  echo ""
  
  echo "Checking .env file..."
  cat ~/eatlas/backend/.env
  echo ""
  
  echo "Checking if MongoDB connection is working..."
  curl -I https://cluster0.8ehw8jn.mongodb.net/ 2>&1 | head -5
  echo ""
  
  echo "Trying to start backend manually..."
  cd ~/eatlas/backend
  npm start 2>&1 | head -50
EOF

echo ""
echo "Log check completed!"
