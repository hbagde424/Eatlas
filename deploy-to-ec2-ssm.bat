@echo off
REM Eatlas EC2 Deployment Script using AWS Systems Manager Session Manager
REM This script pulls the latest changes from GitHub and restarts the backend
REM No SSH keys required - uses AWS IAM permissions

setlocal enabledelayedexpansion

set INSTANCE_ID=i-042c125486445c062
set REGION=eu-north-1
set INSTANCE_IP=13.60.216.136

echo.
echo ==========================================
echo Eatlas EC2 Deployment Script (SSM)
echo ==========================================
echo.
echo Instance ID: %INSTANCE_ID%
echo Region: %REGION%
echo Instance IP: %INSTANCE_IP%
echo.

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI is not installed or not in PATH
    echo Please install AWS CLI from: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

echo AWS CLI found. Proceeding with deployment...
echo.

REM Send deployment command to EC2 instance
echo Sending deployment command to EC2 instance...
echo.

aws ssm send-command ^
    --instance-ids %INSTANCE_ID% ^
    --document-name "AWS-RunShellScript" ^
    --parameters "commands=cd ~/eatlas && git pull origin main && cd backend && npm install && pm2 restart eatlas-backend && sleep 3 && pm2 status && curl http://localhost:5000/api/health" ^
    --region %REGION% ^
    --output json > deployment_response.json

REM Extract command ID from response
for /f "tokens=*" %%A in ('powershell -Command "(Get-Content deployment_response.json | ConvertFrom-Json).Command.CommandId"') do set COMMAND_ID=%%A

echo Command sent successfully!
echo Command ID: %COMMAND_ID%
echo.
echo Waiting for command to complete...
echo.

REM Wait for command to complete (max 60 seconds)
set /a ATTEMPT=0
set /a MAX_ATTEMPTS=30

:wait_loop
if %ATTEMPT% geq %MAX_ATTEMPTS% goto timeout

timeout /t 2 /nobreak >nul

set /a ATTEMPT=%ATTEMPT%+1

REM Check command status
aws ssm get-command-invocation ^
    --command-id %COMMAND_ID% ^
    --instance-id %INSTANCE_ID% ^
    --region %REGION% ^
    --output json > command_status.json

for /f "tokens=*" %%A in ('powershell -Command "(Get-Content command_status.json | ConvertFrom-Json).Status"') do set STATUS=%%A

echo [%ATTEMPT%/%MAX_ATTEMPTS%] Status: %STATUS%

if "%STATUS%"=="Success" goto success
if "%STATUS%"=="Failed" goto failed
if "%STATUS%"=="InProgress" goto wait_loop

goto wait_loop

:success
echo.
echo ==========================================
echo Deployment Successful!
echo ==========================================
echo.
echo Command Output:
echo.
powershell -Command "(Get-Content command_status.json | ConvertFrom-Json).StandardOutputContent"
echo.
echo Application URL: http://%INSTANCE_IP%
echo Backend API: http://%INSTANCE_IP%:5000/api
echo.
pause
exit /b 0

:failed
echo.
echo ==========================================
echo Deployment Failed!
echo ==========================================
echo.
echo Command Output:
echo.
powershell -Command "(Get-Content command_status.json | ConvertFrom-Json).StandardOutputContent"
echo.
echo Error Output:
echo.
powershell -Command "(Get-Content command_status.json | ConvertFrom-Json).StandardErrorContent"
echo.
pause
exit /b 1

:timeout
echo.
echo ==========================================
echo Deployment Timeout!
echo ==========================================
echo.
echo Command is still running. Check AWS Console for status.
echo Command ID: %COMMAND_ID%
echo Instance ID: %INSTANCE_ID%
echo.
pause
exit /b 1
