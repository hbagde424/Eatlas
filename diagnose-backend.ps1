# Diagnose backend issues on EC2 instance

param(
    [string]$InstanceId = "i-042c125486445c062",
    [string]$Region = "eu-north-1"
)

Write-Host "=========================================="
Write-Host "Diagnosing Backend Issues"
Write-Host "=========================================="
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
} catch {
    Write-Host "ERROR: AWS CLI is not installed or not in PATH"
    exit 1
}

Write-Host "Sending diagnostic commands to EC2 instance..."
Write-Host ""

# Diagnostic commands
$diagnosticCommands = @"
echo '=========================================='
echo 'BACKEND DIAGNOSTIC REPORT'
echo '=========================================='
echo ''

echo '1. Checking PM2 status...'
pm2 status
echo ''

echo '2. Checking PM2 logs (last 100 lines)...'
pm2 logs eatlas-backend --lines 100 --nostream 2>&1 | tail -100
echo ''

echo '3. Checking if Node.js is installed...'
node --version
npm --version
echo ''

echo '4. Checking if backend directory exists...'
ls -la ~/eatlas/backend/ | head -20
echo ''

echo '5. Checking .env file...'
cat ~/eatlas/backend/.env
echo ''

echo '6. Checking if node_modules exists...'
ls -la ~/eatlas/backend/node_modules/ | head -10
echo ''

echo '7. Checking if package.json exists...'
cat ~/eatlas/backend/package.json | head -30
echo ''

echo '8. Trying to start backend manually (will timeout after 5 seconds)...'
cd ~/eatlas/backend
timeout 5 npm start 2>&1 || true
echo ''

echo '9. Checking system resources...'
free -h
df -h
echo ''

echo '10. Checking if MongoDB connection works...'
curl -I https://cluster0.8ehw8jn.mongodb.net/ 2>&1 | head -5
echo ''

echo '=========================================='
echo 'END OF DIAGNOSTIC REPORT'
echo '=========================================='
"@

try {
    # Send command to EC2 instance via Systems Manager
    $response = aws ssm send-command `
        --instance-ids $InstanceId `
        --document-name "AWS-RunShellScript" `
        --parameters "commands=$($diagnosticCommands -split "`n")" `
        --region $Region `
        --output json

    $commandId = $response | ConvertFrom-Json | Select-Object -ExpandProperty Command | Select-Object -ExpandProperty CommandId
    
    Write-Host "Command sent successfully!"
    Write-Host "Command ID: $commandId"
    Write-Host ""
    Write-Host "Waiting for command to complete (this may take a minute)..."
    Write-Host ""
    
    # Wait for command to complete
    $maxAttempts = 60
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
    Write-Host "Diagnostic Output:"
    Write-Host "=========================================="
    Write-Host $commandStatus.StandardOutputContent
    
    if ($commandStatus.StandardErrorContent) {
        Write-Host ""
        Write-Host "Errors/Warnings:"
        Write-Host $commandStatus.StandardErrorContent
    }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Diagnostic completed!"
    Write-Host "=========================================="
    
} catch {
    Write-Host "ERROR: Failed to run diagnostics"
    Write-Host $_.Exception.Message
    exit 1
}
