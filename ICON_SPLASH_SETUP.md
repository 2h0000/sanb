# App Icon and Splash Screen Setup Guide

This guide explains how to set up the app icon and splash screen for the Encrypted Notebook application.

## Overview

The app uses:
- **flutter_launcher_icons** - For generating app icons across all platforms
- **flutter_native_splash** - For generating splash screens

## Quick Setup (Using Placeholder Icons)

### Step 1: Generate Placeholder Icons

We've provided an HTML-based icon generator for quick placeholder creation:

1. Open `assets/icon/generate_placeholder.html` in a web browser
2. Download all three generated images:
   - `app_icon.png` (1024x1024) - Main app icon
   - `app_icon_foreground.png` (1024x1024) - Foreground for Android adaptive icon
   - `splash_icon.png` (512x512) - Splash screen icon
3. Save them in the `assets/icon/` and `assets/splash/` directories respectively

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Generate Icons

```bash
flutter pub run flutter_launcher_icons
```

This will generate:
- Android icons (mipmap folders with various densities)
- iOS icons (Assets.xcassets)
- Adaptive icons for Android 8.0+

### Step 4: Generate Splash Screen

```bash
flutter pub run flutter_native_splash:create
```

This will generate:
- Android splash screen (including Android 12+ support)
- iOS splash screen (LaunchScreen.storyboard)

### Step 5: Verify

Run the app to see the new icon and splash screen:

```bash
flutter run
```

## Design Specifications

### App Icon Design

**Theme**: Secure note-taking
- **Primary Symbol**: Book/Notebook (representing notes)
- **Secondary Symbol**: Lock (representing encryption/security)
- **Background Color**: #1A1A2E (Dark blue-gray)
- **Foreground Color**: #FFFFFF (White)
- **Accent Color**: #4CAF50 (Green for the lock badge)

**Dimensions**:
- Main icon: 1024x1024 px
- Foreground (adaptive): 1024x1024 px
- Safe area for adaptive icon: Center 768x768 px

### Splash Screen Design

**Theme**: Minimal and fast-loading
- **Background Color**: #1A1A2E (matches app theme)
- **Icon**: Simplified version of app icon
- **Dimensions**: 512x512 px (centered)

## Professional Icon Design (Recommended for Production)

For a production release, consider:

1. **Hire a Designer**: Professional icon design ensures:
   - Unique branding
   - Platform-specific optimizations
   - Scalability across all sizes
   - Consistency with app theme

2. **Design Tools**:
   - Adobe Illustrator
   - Figma
   - Sketch
   - Affinity Designer

3. **Icon Design Guidelines**:
   - Follow [Material Design Icon Guidelines](https://material.io/design/iconography)
   - Follow [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
   - Test at multiple sizes (16px to 1024px)
   - Ensure good contrast and visibility
   - Avoid text in icons (doesn't scale well)

## Configuration Details

### pubspec.yaml Configuration

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#1A1A2E"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  remove_alpha_ios: true

flutter_native_splash:
  color: "#1A1A2E"
  image: "assets/splash/splash_icon.png"
  android_12:
    color: "#1A1A2E"
    image: "assets/splash/splash_icon.png"
  ios: true
  android: true
```

### Android Adaptive Icons

Android 8.0+ uses adaptive icons with two layers:
- **Background**: Solid color (#1A1A2E)
- **Foreground**: Transparent PNG with icon elements

The system can mask and animate these layers.

### Android 12+ Splash Screen

Android 12 introduced a new splash screen API:
- Centered icon (max 240dp diameter)
- Solid background color
- System-controlled animation

Our configuration supports both legacy and Android 12+ splash screens.

## Troubleshooting

### Icons Not Updating

1. Clean the build:
   ```bash
   flutter clean
   flutter pub get
   ```

2. Regenerate icons:
   ```bash
   flutter pub run flutter_launcher_icons
   flutter pub run flutter_native_splash:create
   ```

3. Rebuild the app:
   ```bash
   flutter run
   ```

### iOS Icon Issues

- Ensure `remove_alpha_ios: true` is set (iOS doesn't support transparency in icons)
- Check that the icon is exactly 1024x1024 px
- Verify the image is in PNG format

### Android Adaptive Icon Issues

- Ensure foreground image has transparent background
- Keep important elements in the center 768x768 px safe area
- Test on different Android launchers (some crop differently)

## File Structure

```
assets/
├── icon/
│   ├── app_icon.png                    # Main app icon (1024x1024)
│   ├── app_icon_foreground.png         # Adaptive icon foreground (1024x1024)
│   ├── generate_placeholder.html       # Icon generator tool
│   ├── icon_generator.dart             # Flutter-based generator
│   └── README.md                       # Icon documentation
└── splash/
    ├── splash_icon.png                 # Splash screen icon (512x512)
    └── README.md                       # Splash documentation
```

## Platform-Specific Locations

After generation, icons will be placed in:

### Android
```
android/app/src/main/res/
├── mipmap-hdpi/
├── mipmap-mdpi/
├── mipmap-xhdpi/
├── mipmap-xxhdpi/
├── mipmap-xxxhdpi/
└── drawable/
```

### iOS
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

## Next Steps

1. ✅ Generate placeholder icons using the HTML tool
2. ✅ Run icon generation commands
3. ✅ Test on both Android and iOS devices/emulators
4. 🎨 (Optional) Commission professional icon design
5. 🚀 Update icons before production release

## Resources

- [flutter_launcher_icons Documentation](https://pub.dev/packages/flutter_launcher_icons)
- [flutter_native_splash Documentation](https://pub.dev/packages/flutter_native_splash)
- [Material Design Icons](https://material.io/design/iconography)
- [Apple Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
