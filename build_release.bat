@echo off
REM Build Release Script for Windows
REM Secure Advanced Notebook App

echo ========================================
echo Secure Advanced Notebook - Release Build
echo ========================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo Error: Flutter is not installed or not in PATH
    exit /b 1
)

echo [1/5] Cleaning previous builds...
call flutter clean
echo.

echo [2/5] Getting dependencies...
call flutter pub get
echo.

echo [3/5] Running code generation...
call dart run build_runner build --delete-conflicting-outputs
echo.

echo [4/5] Building Android APK...
call flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
if errorlevel 1 (
    echo Error: Android APK build failed
    exit /b 1
)
echo Android APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-release.apk
echo.

echo [5/5] Building Android App Bundle (AAB)...
call flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
if errorlevel 1 (
    echo Error: Android AAB build failed
    exit /b 1
)
echo Android AAB built successfully!
echo Location: build\app\outputs\bundle\release\app-release.aab
echo.

echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo Output files:
echo - APK: build\app\outputs\flutter-apk\app-release.apk
echo - AAB: build\app\outputs\bundle\release\app-release.aab
echo.
echo Next steps:
echo 1. Test the APK on a real device
echo 2. Upload AAB to Google Play Console
echo.

pause
