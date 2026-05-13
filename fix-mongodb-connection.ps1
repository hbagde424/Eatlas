# Fix MongoDB connection on EC2 instance using AWS Systems Manager
# This script updates the .env file to use MongoDB Atlas instead of localhost

param(
    [string]$InstanceId = "i-042c125486445c062",
    [string]$Region = "eu-north-1"
)

Write-Host "=========================================="
Write-Host "Fixing MongoDB Connection on EC2"
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

Write-Host ""
Write-Host "Sending fix command to EC2 instance..."
Write-Host ""

# Commands to fix MongoDB connection
$fixCommands = @"
cd ~/eatlas/backend
echo 'Current .env file:'
cat .env
echo ''
cp .env .env.backup
echo 'Backup created: .env.backup'
echo ''
echo 'Updating MongoDB URI to use Atlas...'
sed -i 's|MONGO_URI=mongodb://localhost:27017/electionAT|MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT|g' .env
echo 'Updated .env file:'
cat .env
echo ''
echo 'Restarting backend with PM2...'
pm2 restart eatlas-backend
sleep 3
echo 'Backend status:'
pm2 status
echo ''
echo 'Testing backend health endpoint...'
curl http://localhost:5000/api/health
echo ''
echo 'Testing API endpoint...'
curl http://localhost:5000/api/districts
"@

try {
    # Send command to EC2 instance via Systems Manager
    $response = aws ssm send-command `
        --instance-ids $InstanceId `
        --document-name "AWS-RunShellScript" `
        --parameters "commands=$($fixCommands -split "`n" | ConvertTo-Json -AsArray)" `
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
    Write-Host "MongoDB Connection Fixed!"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "Testing application..."
    Write-Host "Frontend: http://13.60.216.136"
    Write-Host "Backend API: http://13.60.216.136:5000/api"
    Write-Host "Health Check: http://13.60.216.136:5000/api/health"
    
} catch {
    Write-Host "ERROR: Failed to execute fix command"
    Write-Host $_.Exception.Message
    exit 1
}
