# App Icon Assets

This directory contains the app icon assets for the Encrypted Notebook application.

## Required Files

- `app_icon.png` - Main app icon (1024x1024 px recommended)
- `app_icon_foreground.png` - Foreground layer for Android adaptive icon (1024x1024 px)

## Design Guidelines

The app icon should represent:
- Security (lock, shield)
- Note-taking (notebook, document)
- Clean, professional appearance
- Good visibility at small sizes

## Current Placeholder

The current placeholder is a simple design that should be replaced with a professionally designed icon before release.

## Colors

- Background: #1A1A2E (Dark blue-gray)
- Foreground: #FFFFFF (White) with accent colors

## Generation

After updating the icon files, run:
```bash
flutter pub run flutter_launcher_icons
```
