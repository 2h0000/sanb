@echo off
echo Building local-only APK (no Firebase)...
echo.

REM Clean previous build
echo Cleaning previous build...
if exist build rmdir /s /q build
if exist android\app\build rmdir /s /q android\app\build

REM Get dependencies
echo Getting dependencies...
call flutter pub get

REM Build APK
echo Building APK...
call flutter build apk --release --android-skip-build-dependency-validation

echo.
if exist build\app\outputs\flutter-apk\app-release.apk (
    echo Build successful!
    echo APK location: build\app\outputs\flutter-apk\app-release.apk
    dir build\app\outputs\flutter-apk\app-release.apk
) else (
    echo Build failed or APK not found!
)

pause
