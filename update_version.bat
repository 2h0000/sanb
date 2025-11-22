@echo off
REM Version Update Script for Windows
REM Usage: update_version.bat <version_name> <build_number>
REM Example: update_version.bat 1.0.1 2

if "%~1"=="" (
    echo Usage: update_version.bat ^<version_name^> ^<build_number^>
    echo Example: update_version.bat 1.0.1 2
    exit /b 1
)

if "%~2"=="" (
    echo Usage: update_version.bat ^<version_name^> ^<build_number^>
    echo Example: update_version.bat 1.0.1 2
    exit /b 1
)

set VERSION_NAME=%~1
set BUILD_NUMBER=%~2

echo Updating version to %VERSION_NAME%+%BUILD_NUMBER%...

REM Update pubspec.yaml
powershell -Command "(Get-Content pubspec.yaml) -replace 'version: .*', 'version: %VERSION_NAME%+%BUILD_NUMBER%' | Set-Content pubspec.yaml"

echo Version updated successfully!
echo.
echo Next steps:
echo 1. Commit the changes: git add pubspec.yaml
echo 2. Create a tag: git tag v%VERSION_NAME%
echo 3. Push: git push origin main --tags
echo.
