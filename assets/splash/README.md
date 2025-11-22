# Splash Screen Assets

This directory contains the splash screen assets for the Encrypted Notebook application.

## Required Files

- `splash_icon.png` - Splash screen icon (512x512 px recommended)

## Design Guidelines

The splash screen should:
- Match the app icon design
- Be simple and load quickly
- Work well on both light and dark backgrounds
- Be centered on a solid color background

## Background Color

- Color: #1A1A2E (Dark blue-gray)

## Generation

After updating the splash icon, run:
```bash
flutter pub run flutter_native_splash:create
```

## Platform Support

- Android (including Android 12+ with splash screen API)
- iOS
