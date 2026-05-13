@echo off
REM Eatlas EC2 Connection Tool - Using AWS Systems Manager
REM No PEM file issues!

setlocal enabledelayedexpansion

set INSTANCE_ID=i-042c125486445c062
set REGION=eu-north-1

echo.
echo ========================================
echo   Eatlas EC2 Connection Tool
echo ========================================
echo.

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI not installed!
    echo.
    echo Please install AWS CLI:
    echo   1. Download: https://aws.amazon.com/cli/
    echo   2. Or use: choco install awscli
    echo.
    pause
    exit /b 1
)

echo [1] Connect to EC2 (Session Manager)
echo [2] Deploy Application
echo [3] View Backend Logs
echo [4] Restart Backend
echo [5] Update Application
echo [6] Check Application Status
echo [7] Exit
echo.

set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto connect
if "%choice%"=="2" goto deploy
if "%choice%"=="3" goto logs
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto update
if "%choice%"=="6" goto status
if "%choice%"=="7" goto end

echo Invalid choice. Please try again.
pause
goto start

:connect
echo.
echo Connecting to EC2 instance...
echo Instance ID: %INSTANCE_ID%
echo Region: %REGION%
echo.
aws ssm start-session --target %INSTANCE_ID% --region %REGION%
goto end

:deploy
echo.
echo Deploying application to EC2...
echo.
aws ssm start-session --target %INSTANCE_ID% --region %REGION% --document-name "AWS-StartInteractiveCommand" --parameters command="cd ~/eatlas && git pull origin main && cd frontend && npm install && npm run build && cd ../backend && npm install && pm2 restart eatlas-backend && sudo systemctl reload nginx && echo 'Deployment completed!'"
echo.
pause
goto end

:logs
echo.
echo Fetching backend logs...
echo.
aws ssm start-session --target %INSTANCE_ID% --region %REGION% --document-name "AWS-StartInteractiveCommand" --parameters command="pm2 logs eatlas-backend --lines 50"
echo.
pause
goto end

:restart
echo.
echo Restarting backend...
echo.
aws ssm start-session --target %INSTANCE_ID% --region %REGION% --document-name "AWS-StartInteractiveCommand" --parameters command="pm2 restart eatlas-backend && echo 'Backend restarted!'"
echo.
pause
goto end

:update
echo.
echo Updating application...
echo.
aws ssm start-session --target %INSTANCE_ID% --region %REGION% --document-name "AWS-StartInteractiveCommand" --parameters command="cd ~/eatlas && git pull origin main && cd frontend && npm install && npm run build && cd ../backend && npm install && pm2 restart eatlas-backend && sudo systemctl reload nginx && echo 'Application updated!'"
echo.
pause
goto end

:status
echo.
echo Checking application status...
echo.
aws ssm start-session --target %INSTANCE_ID% --region %REGION% --document-name "AWS-StartInteractiveCommand" --parameters command="pm2 status && echo '' && echo 'Frontend:' && curl -s http://localhost/ | head -20 && echo '' && echo 'Backend:' && curl -s http://localhost:5000/api/health"
echo.
pause
goto end

:end
echo.
echo Goodbye!
echo.
exit /b 0
