#!/bin/bash
# Build Release Script for macOS/Linux
# Secure Advanced Notebook App

set -e  # Exit on error

echo "========================================"
echo "Secure Advanced Notebook - Release Build"
echo "========================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    exit 1
fi

echo "[1/6] Cleaning previous builds..."
flutter clean
echo ""

echo "[2/6] Getting dependencies..."
flutter pub get
echo ""

echo "[3/6] Running code generation..."
dart run build_runner build --delete-conflicting-outputs
echo ""

echo "[4/6] Building Android APK..."
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
echo "✓ Android APK built successfully!"
echo "Location: build/app/outputs/flutter-apk/app-release.apk"
echo ""

echo "[5/6] Building Android App Bundle (AAB)..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
echo "✓ Android AAB built successfully!"
echo "Location: build/app/outputs/bundle/release/app-release.aab"
echo ""

# Check if running on macOS for iOS build
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "[6/6] Building iOS IPA..."
    flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols
    echo "✓ iOS IPA built successfully!"
    echo "Location: build/ios/ipa/encrypted_notebook.ipa"
    echo ""
else
    echo "[6/6] Skipping iOS build (macOS required)"
    echo ""
fi

echo "========================================"
echo "Build completed successfully!"
echo "========================================"
echo ""
echo "Output files:"
echo "- APK: build/app/outputs/flutter-apk/app-release.apk"
echo "- AAB: build/app/outputs/bundle/release/app-release.aab"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "- IPA: build/ios/ipa/encrypted_notebook.ipa"
fi
echo ""
echo "Next steps:"
echo "1. Test the APK on a real device"
echo "2. Upload AAB to Google Play Console"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "3. Upload IPA to App Store Connect"
fi
echo ""
