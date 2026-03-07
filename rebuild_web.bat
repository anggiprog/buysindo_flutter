@echo off
REM ========================================
REM Buysindo Flutter Web Build & Deploy
REM ========================================
REM This script will:
REM 1. Clean the project
REM 2. Build web version (production)
REM 3. Deploy to XAMPP C:\xampp\htdocs\buysindo\public\app

setlocal enabledelayedexpansion

cd /d E:\projek_flutter\buysindo\buysindo_app

echo.
echo ========================================
echo Buysindo Flutter Web Build ^& Deploy
echo ========================================
echo.
echo Project: E:\projek_flutter\buysindo\buysindo_app
echo Deploy to: C:\xampp\htdocs\buysindo\public\app
echo.
echo Build started at: %date% %time%
echo.

REM Step 1: Clean
echo [1/3] Cleaning previous build...
call flutter clean
if errorlevel 1 (
    echo ERROR: Clean failed!
    goto :error
)

REM Step 2: Get dependencies
echo.
echo [2/3] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Pub get failed!
    goto :error
)

REM Step 3: Build web
echo.
echo [3/3] Building web version (this may take 4-5 minutes)...
echo Please wait...
call flutter build web --release --no-tree-shake-icons
if errorlevel 1 (
    echo ERROR: Build failed!
    goto :error
)

REM Step 4: Deploy
echo.
echo [4/5] Deploying to XAMPP...
xcopy "build\web" "C:\xampp\htdocs\buysindo\public\app" /E /I /Y
if errorlevel 1 (
    echo ERROR: Deployment failed!
    goto :error
)

REM Step 5: Verify
echo.
echo [5/5] Verifying deployment...
if not exist "C:\xampp\htdocs\buysindo\public\app\index.html" (
    echo ERROR: index.html not found in deployment directory!
    goto :error
)

echo.
echo ========================================
echo SUCCESS!
echo ========================================
echo.
echo Web build deployed to:
echo C:\xampp\htdocs\buysindo\public\app
echo.
echo Build completed at: %date% %time%
echo.
echo Next steps:
echo 1. Start XAMPP (Apache + MySQL)
echo 2. Open browser: http://localhost/buysindo/public/app
echo 3. Test all features
echo 4. Check for console errors (F12)
echo.
pause
exit /b 0

:error
echo.
echo ========================================
echo BUILD FAILED!
echo ========================================
echo.
echo Check error messages above.
echo.
pause
exit /b 1
