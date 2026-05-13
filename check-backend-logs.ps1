# Check backend logs on EC2 instance using AWS Systems Manager

param(
    [string]$InstanceId = "i-042c125486445c062",
    [string]$Region = "eu-north-1"
)

Write-Host "=========================================="
Write-Host "Checking Backend Logs"
Write-Host "=========================================="
Write-Host ""
Write-Host "Instance ID: $InstanceId"
Write-Host "Region: $Region"
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
} catch {
    Write-Host "ERROR: AWS CLI is not installed or not in PATH"
    exit 1
}

Write-Host "Sending log check command to EC2 instance..."
Write-Host ""

# Commands to check logs
$logCommands = @"
echo 'Checking PM2 logs (last 50 lines)...'
pm2 logs eatlas-backend --lines 50 --nostream
echo ''
echo 'Checking PM2 status...'
pm2 status
echo ''
echo 'Checking if backend process is running...'
ps aux | grep node | grep -v grep
echo ''
echo 'Checking if port 5000 is listening...'
netstat -tlnp | grep 5000 || echo 'Port 5000 not listening'
echo ''
echo 'Checking .env file...'
cat ~/eatlas/backend/.env
echo ''
echo 'Checking Node.js version...'
node --version
echo ''
echo 'Checking npm version...'
npm --version
"@

try {
    # Send command to EC2 instance via Systems Manager
    $response = aws ssm send-command `
        --instance-ids $InstanceId `
        --document-name "AWS-RunShellScript" `
        --parameters "commands=$($logCommands -split "`n")" `
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
    Write-Host "Backend Logs:"
    Write-Host "=========================================="
    Write-Host $commandStatus.StandardOutputContent
    
    if ($commandStatus.StandardErrorContent) {
        Write-Host ""
        Write-Host "Errors:"
        Write-Host $commandStatus.StandardErrorContent
    }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Log check completed!"
    Write-Host "=========================================="
    
} catch {
    Write-Host "ERROR: Failed to check logs"
    Write-Host $_.Exception.Message
    exit 1
}
