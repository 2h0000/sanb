#!/bin/bash

echo "========================================"
echo "Encrypted Notebook - Icon Setup Script"
echo "========================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not found in PATH"
    echo "Please install Flutter or add it to your PATH"
    echo "Visit: https://flutter.dev/docs/get-started/install"
    echo ""
    exit 1
fi

echo "Step 1: Installing dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get dependencies"
    exit 1
fi
echo "✓ Dependencies installed"
echo ""

echo "Step 2: Generating app icons..."
flutter pub run flutter_launcher_icons
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to generate app icons"
    exit 1
fi
echo "✓ App icons generated"
echo ""

echo "Step 3: Generating splash screen..."
flutter pub run flutter_native_splash:create
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to generate splash screen"
    exit 1
fi
echo "✓ Splash screen generated"
echo ""

echo "========================================"
echo "SUCCESS! Icons and splash screen are ready"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Run: flutter run"
echo "  2. Check the app icon on your device/emulator"
echo "  3. Observe the splash screen when launching"
echo ""
echo "Note: You may need to uninstall and reinstall the app"
echo "      to see the new icon on some devices."
echo ""
