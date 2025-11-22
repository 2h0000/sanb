@echo off
echo ========================================
echo Encrypted Notebook - Icon Setup Script
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not found in PATH
    echo Please install Flutter or add it to your PATH
    echo Visit: https://flutter.dev/docs/get-started/install
    echo.
    pause
    exit /b 1
)

echo Step 1: Installing dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)
echo ✓ Dependencies installed
echo.

echo Step 2: Generating app icons...
call flutter pub run flutter_launcher_icons
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to generate app icons
    pause
    exit /b 1
)
echo ✓ App icons generated
echo.

echo Step 3: Generating splash screen...
call flutter pub run flutter_native_splash:create
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to generate splash screen
    pause
    exit /b 1
)
echo ✓ Splash screen generated
echo.

echo ========================================
echo SUCCESS! Icons and splash screen are ready
echo ========================================
echo.
echo Next steps:
echo   1. Run: flutter run
echo   2. Check the app icon on your device/emulator
echo   3. Observe the splash screen when launching
echo.
echo Note: You may need to uninstall and reinstall the app
echo       to see the new icon on some devices.
echo.
pause
