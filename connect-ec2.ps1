# Eatlas EC2 Connection Tool - PowerShell Version
# No PEM file issues!

param(
    [string]$Action = "menu"
)

$InstanceId = "i-042c125486445c062"
$Region = "eu-north-1"
$EC2_IP = "13.60.216.136"

function Show-Menu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Eatlas EC2 Connection Tool" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] Connect to EC2 (Interactive Terminal)" -ForegroundColor Green
    Write-Host "[2] Deploy Application" -ForegroundColor Green
    Write-Host "[3] View Backend Logs" -ForegroundColor Green
    Write-Host "[4] Restart Backend" -ForegroundColor Green
    Write-Host "[5] Update Application" -ForegroundColor Green
    Write-Host "[6] Check Application Status" -ForegroundColor Green
    Write-Host "[7] View Nginx Logs" -ForegroundColor Green
    Write-Host "[8] Exit" -ForegroundColor Red
    Write-Host ""
}

function Test-AwsCli {
    try {
        $null = aws --version 2>$null
        return $true
    }
    catch {
        return $false
    }
}

function Connect-EC2 {
    Write-Host ""
    Write-Host "Connecting to EC2 instance..." -ForegroundColor Yellow
    Write-Host "Instance ID: $InstanceId" -ForegroundColor Gray
    Write-Host "Region: $Region" -ForegroundColor Gray
    Write-Host ""
    
    aws ssm start-session --target $InstanceId --region $Region
}

function Deploy-Application {
    Write-Host ""
    Write-Host "Deploying application to EC2..." -ForegroundColor Yellow
    Write-Host ""
    
    $command = @"
cd ~/eatlas && `
git pull origin main && `
cd frontend && `
npm install && `
npm run build && `
cd ../backend && `
npm install && `
pm2 restart eatlas-backend && `
sudo systemctl reload nginx && `
echo 'Deployment completed!' && `
pm2 status
"@
    
    aws ssm start-session --target $InstanceId --region $Region --document-name "AWS-StartInteractiveCommand" --parameters "command=$command"
}

function View-Logs {
    Write-Host ""
    Write-Host "Fetching backend logs..." -ForegroundColor Yellow
    Write-Host ""
    
    $command = "pm2 logs eatlas-backend --lines 50"
    aws ssm start-session --target $InstanceId --region $Region --document-name "AWS-StartInteractiveCommand" --parameters "command=$command"
}

function Restart-Backend {
    Write-Host ""
    Write-Host "Restarting backend..." -ForegroundColor Yellow
    Write-Host ""
    
    $command = "pm2 restart eatlas-backend && sleep 2 && pm2 status"
    aws ssm start-session --target $InstanceId --region $Region --document-name "AWS-StartInteractiveCommand" --parameters "command=$command"
}

function Update-Application {
    Write-Host ""
    Write-Host "Updating application..." -ForegroundColor Yellow
    Write-Host ""
    
    $command = @"
cd ~/eatlas && `
git pull origin main && `
cd frontend && `
npm install && `
npm run build && `
cd ../backend && `
npm install && `
pm2 restart eatlas-backend && `
sudo systemctl reload nginx && `
echo 'Application updated!' && `
pm2 status
"@
    
    aws ssm start-session --target $InstanceId --region $Region --document-name "AWS-StartInteractiveCommand" --parameters "command=$command"
}

function Check-Status {
    Write-Host ""
    Write-Host "Checking application status..." -ForegroundColor Yellow
    Write-Host ""
    
    $command = @"
echo '=== PM2 Status ===' && `
pm2 status && `
echo '' && `
echo '=== Frontend ===' && `
curl -s http://localhost/ | head -5 && `
echo '' && `
echo '=== Backend Health ===' && `
curl -s http://localhost:5000/api/health && `
echo ''
"@
    
    aws ssm start-session --target $InstanceId --region $Region --document-name "AWS-StartInteractiveCommand" --parameters "command=$command"
}

function View-NginxLogs {
    Write-Host ""
    Write-Host "Fetching Nginx logs..." -ForegroundColor Yellow
    Write-Host ""
    
    $command = "sudo tail -f /var/log/nginx/access.log"
    aws ssm start-session --target $InstanceId --region $Region --document-name "AWS-StartInteractiveCommand" --parameters "command=$command"
}

# Main execution
if (-not (Test-AwsCli)) {
    Write-Host ""
    Write-Host "ERROR: AWS CLI not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install AWS CLI:" -ForegroundColor Yellow
    Write-Host "  1. Download: https://aws.amazon.com/cli/" -ForegroundColor Gray
    Write-Host "  2. Or use: choco install awscli" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

if ($Action -eq "menu") {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Enter your choice (1-8)"
        
        switch ($choice) {
            "1" { Connect-EC2 }
            "2" { Deploy-Application }
            "3" { View-Logs }
            "4" { Restart-Backend }
            "5" { Update-Application }
            "6" { Check-Status }
            "7" { View-NginxLogs }
            "8" { 
                Write-Host ""
                Write-Host "Goodbye!" -ForegroundColor Cyan
                Write-Host ""
                exit 0
            }
            default { 
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
}
else {
    switch ($Action) {
        "connect" { Connect-EC2 }
        "deploy" { Deploy-Application }
        "logs" { View-Logs }
        "restart" { Restart-Backend }
        "update" { Update-Application }
        "status" { Check-Status }
        "nginx" { View-NginxLogs }
        default { Show-Menu }
    }
}
