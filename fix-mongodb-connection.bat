@echo off
REM Fix MongoDB connection on EC2 instance using AWS Systems Manager
REM This script updates the .env file to use MongoDB Atlas instead of localhost

setlocal enabledelayedexpansion

set INSTANCE_ID=i-042c125486445c062
set REGION=eu-north-1

echo.
echo ==========================================
echo Fixing MongoDB Connection on EC2
echo ==========================================
echo.
echo Instance ID: %INSTANCE_ID%
echo Region: %REGION%
echo.

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI is not installed or not in PATH
    echo Please install AWS CLI from: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

echo AWS CLI found. Proceeding with fix...
echo.

REM Send fix command to EC2 instance
echo Sending fix command to EC2 instance...
echo.

aws ssm send-command ^
    --instance-ids %INSTANCE_ID% ^
    --document-name "AWS-RunShellScript" ^
    --parameters "commands=cd ~/eatlas/backend,cp .env .env.backup,sed -i 's|MONGO_URI=mongodb://localhost:27017/electionAT|MONGO_URI=mongodb+srv://developer:Hh1q2w3e4r5t6y7u8i9o0p@cluster0.8ehw8jn.mongodb.net/electionAT|g' .env,pm2 restart eatlas-backend,sleep 3,pm2 status,curl http://localhost:5000/api/health" ^
    --region %REGION% ^
    --output json > fix_response.json

REM Extract command ID from response
for /f "tokens=*" %%A in ('powershell -Command "(Get-Content fix_response.json | ConvertFrom-Json).Command.CommandId"') do set COMMAND_ID=%%A

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
    --output json > fix_status.json

for /f "tokens=*" %%A in ('powershell -Command "(Get-Content fix_status.json | ConvertFrom-Json).Status"') do set STATUS=%%A

echo [%ATTEMPT%/%MAX_ATTEMPTS%] Status: %STATUS%

if "%STATUS%"=="Success" goto success
if "%STATUS%"=="Failed" goto failed
if "%STATUS%"=="InProgress" goto wait_loop

goto wait_loop

:success
echo.
echo ==========================================
echo MongoDB Connection Fixed!
echo ==========================================
echo.
echo Command Output:
echo.
powershell -Command "(Get-Content fix_status.json | ConvertFrom-Json).StandardOutputContent"
echo.
echo Testing application...
echo Frontend: http://13.60.216.136
echo Backend API: http://13.60.216.136:5000/api
echo Health Check: http://13.60.216.136:5000/api/health
echo.
pause
exit /b 0

:failed
echo.
echo ==========================================
echo Fix Failed!
echo ==========================================
echo.
echo Command Output:
echo.
powershell -Command "(Get-Content fix_status.json | ConvertFrom-Json).StandardOutputContent"
echo.
echo Error Output:
echo.
powershell -Command "(Get-Content fix_status.json | ConvertFrom-Json).StandardErrorContent"
echo.
pause
exit /b 1

:timeout
echo.
echo ==========================================
echo Fix Timeout!
echo ==========================================
echo.
echo Command is still running. Check AWS Console for status.
echo Command ID: %COMMAND_ID%
echo Instance ID: %INSTANCE_ID%
echo.
pause
exit /b 1
