@echo off
REM Eatlas EC2 Deployment Script for Windows
REM This script helps deploy to EC2 instance

setlocal enabledelayedexpansion

set EC2_IP=13.60.216.136
set PEM_FILE=C:\Users\devel\Downloads\ElectionAtlas.pem
set EC2_USER=ec2-user

echo.
echo ========================================
echo   Eatlas EC2 Deployment Helper
echo ========================================
echo.

REM Check if PEM file exists
if not exist "%PEM_FILE%" (
    echo ERROR: PEM file not found at %PEM_FILE%
    echo Please ensure ElectionAtlas.pem is in C:\Users\devel\Downloads\
    pause
    exit /b 1
)

echo [1] Connect to EC2 (SSH)
echo [2] Deploy Application
echo [3] View Backend Logs
echo [4] Restart Backend
echo [5] Update Application
echo [6] Exit
echo.

set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto connect
if "%choice%"=="2" goto deploy
if "%choice%"=="3" goto logs
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto update
if "%choice%"=="6" goto end

echo Invalid choice. Please try again.
pause
goto start

:connect
echo.
echo Connecting to EC2 instance...
echo IP: %EC2_IP%
echo.
ssh -i "%PEM_FILE%" %EC2_USER%@%EC2_IP%
goto end

:deploy
echo.
echo Deploying application to EC2...
echo.

REM Copy deploy script to EC2
echo Uploading deployment script...
scp -i "%PEM_FILE%" deploy.sh %EC2_USER%@%EC2_IP%:~/deploy.sh

REM Execute deployment script
echo Running deployment script on EC2...
ssh -i "%PEM_FILE%" %EC2_USER%@%EC2_IP% "chmod +x ~/deploy.sh && ~/deploy.sh"

echo.
echo Deployment completed!
echo Application URL: http://%EC2_IP%
echo.
pause
goto end

:logs
echo.
echo Fetching backend logs...
echo.
ssh -i "%PEM_FILE%" %EC2_USER%@%EC2_IP% "pm2 logs eatlas-backend --lines 50"
pause
goto end

:restart
echo.
echo Restarting backend...
echo.
ssh -i "%PEM_FILE%" %EC2_USER%@%EC2_IP% "pm2 restart eatlas-backend"
echo Backend restarted!
echo.
pause
goto end

:update
echo.
echo Updating application...
echo.
ssh -i "%PEM_FILE%" %EC2_USER%@%EC2_IP% "cd ~/eatlas && git pull origin main && cd frontend && npm install && npm run build && cd ../backend && npm install && pm2 restart eatlas-backend && sudo systemctl reload nginx"
echo.
echo Application updated!
echo.
pause
goto end

:end
echo.
echo Goodbye!
echo.
exit /b 0
