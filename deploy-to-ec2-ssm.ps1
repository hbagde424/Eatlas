# Eatlas EC2 Deployment Script using AWS Systems Manager Session Manager
# This script pulls the latest changes from GitHub and restarts the backend
# No SSH keys required - uses AWS IAM permissions

param(
    [string]$InstanceId = "i-042c125486445c062",
    [string]$Region = "eu-north-1"
)

Write-Host "=========================================="
Write-Host "Eatlas EC2 Deployment Script (SSM)"
Write-Host "=========================================="
Write-Host ""
Write-Host "Instance ID: $InstanceId"
Write-Host "Region: $Region"
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
    Write-Host "AWS CLI found: $awsVersion"
} catch {
    Write-Host "ERROR: AWS CLI is not installed or not in PATH"
    Write-Host "Please install AWS CLI from: https://aws.amazon.com/cli/"
    exit 1
}

# Deployment commands to run on EC2
$deploymentCommands = @"
#!/bin/bash
set -e

echo "=========================================="
echo "Starting Eatlas Deployment"
echo "=========================================="
echo ""

# Navigate to project directory
cd ~/eatlas

echo "Step 1: Pulling latest changes from GitHub..."
git pull origin main
echo "✓ Git pull completed"
echo ""

# Install backend dependencies
echo "Step 2: Installing backend dependencies..."
cd backend
npm install
echo "✓ Dependencies installed"
echo ""

# Restart backend
echo "Step 3: Restarting backend with PM2..."
pm2 restart eatlas-backend
echo "✓ Backend restarted"
echo ""

# Wait for backend to start
echo "Step 4: Waiting for backend to start..."
sleep 3

# Check backend status
echo "Step 5: Checking backend status..."
pm2 status
echo ""

# Test health endpoint
echo "Step 6: Testing backend health endpoint..."
HEALTH_RESPONSE=\$(curl -s http://localhost:5000/api/health)
echo "Health Response: \$HEALTH_RESPONSE"
echo ""

# Test frontend
echo "Step 7: Testing frontend..."
FRONTEND_RESPONSE=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
echo "Frontend HTTP Status: \$FRONTEND_RESPONSE"
echo ""

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "Application URL: http://13.60.216.136"
echo "Backend API: http://13.60.216.136:5000/api"
echo "=========================================="
"@

# Save deployment script to temp file
$tempScript = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.sh'
Set-Content -Path $tempScript -Value $deploymentCommands

Write-Host "Uploading deployment script to EC2..."
Write-Host ""

try {
    # Send command to EC2 instance via Systems Manager
    $response = aws ssm send-command `
        --instance-ids $InstanceId `
        --document-name "AWS-RunShellScript" `
        --parameters 'commands=@("cd ~/eatlas && git pull origin main && cd backend && npm install && pm2 restart eatlas-backend && sleep 3 && pm2 status && curl http://localhost:5000/api/health && curl http://localhost/")' `
        --region $Region `
        --output json

    $commandId = $response | ConvertFrom-Json | Select-Object -ExpandProperty Command | Select-Object -ExpandProperty CommandId
    
    Write-Host "Command sent successfully!"
    Write-Host "Command ID: $commandId"
    Write-Host ""
    Write-Host "Waiting for command to complete..."
    Write-Host ""
    
    # Wait for command to complete
    $maxAttempts = 30
    $attempt = 0
    $completed = $false
    
    while ($attempt -lt $maxAttempts -and -not $completed) {
        Start-Sleep -Seconds 2
        $attempt++
        
        $commandStatus = aws ssm get-command-invocation `
            --command-id $commandId `
            --instance-id $InstanceId `
            --region $Region `
            --output json | ConvertFrom-Json
        
        $status = $commandStatus.Status
        Write-Host "[$attempt/$maxAttempts] Status: $status"
        
        if ($status -eq "Success" -or $status -eq "Failed") {
            $completed = $true
        }
    }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Command Output:"
    Write-Host "=========================================="
    Write-Host $commandStatus.StandardOutputContent
    
    if ($commandStatus.StandardErrorContent) {
        Write-Host ""
        Write-Host "Errors:"
        Write-Host $commandStatus.StandardErrorContent
    }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Deployment Complete!"
    Write-Host "=========================================="
    Write-Host "Application URL: http://13.60.216.136"
    Write-Host "Backend API: http://13.60.216.136:5000/api"
    Write-Host "=========================================="
    
} catch {
    Write-Host "ERROR: Failed to execute deployment command"
    Write-Host $_.Exception.Message
    exit 1
} finally {
    # Clean up temp file
    if (Test-Path $tempScript) {
        Remove-Item $tempScript -Force
    }
}
