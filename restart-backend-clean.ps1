# Clean restart of backend on EC2 instance

param(
    [string]$InstanceId = "i-042c125486445c062",
    [string]$Region = "eu-north-1"
)

Write-Host "=========================================="
Write-Host "Clean Backend Restart"
Write-Host "=========================================="
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
} catch {
    Write-Host "ERROR: AWS CLI is not installed or not in PATH"
    exit 1
}

Write-Host "Sending restart commands to EC2 instance..."
Write-Host ""

# Restart commands
$restartCommands = @"
echo 'Stopping all PM2 processes...'
pm2 kill
sleep 2

echo 'Clearing PM2 logs...'
pm2 flush

echo 'Checking if processes are stopped...'
ps aux | grep node | grep -v grep || echo 'No Node processes running'

echo ''
echo 'Navigating to backend directory...'
cd ~/eatlas/backend

echo ''
echo 'Checking .env file...'
cat .env

echo ''
echo 'Installing dependencies...'
npm install

echo ''
echo 'Starting backend with PM2...'
pm2 start npm --name eatlas-backend -- start

echo ''
echo 'Waiting 5 seconds for backend to start...'
sleep 5

echo ''
echo 'Checking PM2 status...'
pm2 status

echo ''
echo 'Checking PM2 logs...'
pm2 logs eatlas-backend --lines 50 --nostream

echo ''
echo 'Testing backend health endpoint...'
curl -v http://localhost:5000/api/health 2>&1 | head -20

echo ''
echo 'Testing API endpoint...'
curl -s http://localhost:5000/api/districts | head -c 200

echo ''
echo 'Checking if port 5000 is listening...'
netstat -tlnp | grep 5000 || echo 'Port 5000 not listening'
"@

try {
    # Send command to EC2 instance via Systems Manager
    $response = aws ssm send-command `
        --instance-ids $InstanceId `
        --document-name "AWS-RunShellScript" `
        --parameters "commands=$($restartCommands -split "`n")" `
        --region $Region `
        --output json

    $commandId = $response | ConvertFrom-Json | Select-Object -ExpandProperty Command | Select-Object -ExpandProperty CommandId
    
    Write-Host "Command sent successfully!"
    Write-Host "Command ID: $commandId"
    Write-Host ""
    Write-Host "Waiting for command to complete (this may take 2-3 minutes)..."
    Write-Host ""
    
    # Wait for command to complete
    $maxAttempts = 90
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
    Write-Host "Restart Output:"
    Write-Host "=========================================="
    Write-Host $commandStatus.StandardOutputContent
    
    if ($commandStatus.StandardErrorContent) {
        Write-Host ""
        Write-Host "Errors/Warnings:"
        Write-Host $commandStatus.StandardErrorContent
    }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Restart completed!"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "Testing application URLs..."
    Write-Host "Frontend: http://13.60.216.136"
    Write-Host "Backend API: http://13.60.216.136:5000/api"
    Write-Host "Health Check: http://13.60.216.136:5000/api/health"
    
} catch {
    Write-Host "ERROR: Failed to restart backend"
    Write-Host $_.Exception.Message
    exit 1
}
