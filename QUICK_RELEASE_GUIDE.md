# 快速发布指南

这是一个快速参考指南，帮助你在 5 分钟内了解如何构建和发布应用。

## 🚀 5 分钟快速开始

### 第一次发布？

1. **配置 Firebase**（10 分钟）
   ```bash
   flutterfire configure
   ```
   选择项目 → 选择平台 → 完成

2. **生成 Android 签名**（5 分钟）
   ```bash
   keytool -genkey -v -keystore ~/encrypted-notebook-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias encrypted-notebook
   ```
   
   复制 `android/key.properties.template` 到 `android/key.properties` 并填写信息

3. **构建**（2 分钟）
   ```bash
   # Windows
   .\build_release.bat
   
   # macOS/Linux
   ./build_release.sh
   ```

4. **测试**（5 分钟）
   - 在真机上安装 APK
   - 测试核心功能
   - 检查是否有崩溃

5. **上传**（10 分钟）
   - Google Play: 上传 AAB 到 Play Console
   - App Store: 使用 Xcode 上传 IPA

## 📦 构建命令速查

### Android

```bash
# APK（直接安装）
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# AAB（Google Play）
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# 分架构 APK（更小）
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
```

### iOS（仅 macOS）

```bash
# IPA（App Store）
flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols

# 或使用 Xcode
open ios/Runner.xcworkspace
# Product > Archive
```

## 🔑 关键文件位置

### 输出文件
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- IPA: `build/ios/ipa/encrypted_notebook.ipa`

### 配置文件
- Android 签名: `android/key.properties`
- Android Keystore: `~/encrypted-notebook-release.jks`
- Firebase: `lib/firebase_options.dart`
- ProGuard: `android/app/proguard-rules.pro`

## ✅ 发布前必查

```
□ 所有测试通过
□ 版本号已更新
□ Firebase 已配置
□ 签名配置正确
□ 在真机上测试过
□ 应用图标正常
□ 启动画面正常
```

## 🔧 常用命令

```bash
# 清理构建
flutter clean

# 获取依赖
flutter pub get

# 代码生成
dart run build_runner build --delete-conflicting-outputs

# 分析代码
flutter analyze

# 运行测试
flutter test

# 更新版本
# Windows: update_version.bat 1.0.1 2
# macOS/Linux: ./update_version.sh 1.0.1 2
```

## 🐛 快速故障排查

### 构建失败

**签名错误**
```bash
# 检查文件
ls android/key.properties
ls ~/encrypted-notebook-release.jks
```

**依赖错误**
```bash
flutter clean
flutter pub get
```

### 运行时崩溃

**混淆问题**
```bash
# 使用 profile 模式测试
flutter build apk --profile
```

**Firebase 错误**
```bash
# 重新配置
flutterfire configure
```

## 📱 应用商店链接

- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Firebase Console](https://console.firebase.google.com/)

## 📚 详细文档

需要更多信息？查看：

- **完整指南**: [BUILD_RELEASE_GUIDE.md](BUILD_RELEASE_GUIDE.md)
- **Firebase 配置**: [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- **iOS 签名**: [ios/SIGNING_SETUP.md](ios/SIGNING_SETUP.md)
- **检查清单**: [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
- **部署总结**: [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)

## 💡 专业提示

1. **首次发布**：先发布到内部测试（TestFlight / 内部测试轨道）
2. **版本管理**：使用语义化版本（1.0.0+1）
3. **备份签名**：立即备份 keystore 和证书！
4. **监控崩溃**：发布后密切关注 Crashlytics
5. **用户反馈**：准备好快速响应用户问题

## 🎯 发布流程

```
1. 更新版本号
   ↓
2. 运行测试
   ↓
3. 构建 release
   ↓
4. 真机测试
   ↓
5. 上传到商店
   ↓
6. 提交审核
   ↓
7. 监控反馈
```

## ⚡ 紧急修复流程

```bash
# 1. 修复 bug
# 2. 更新版本（patch）
./update_version.sh 1.0.1 2

# 3. 快速构建
flutter build appbundle --release

# 4. 上传到商店（紧急审核）
```

---

**记住**：第一次可能需要更多时间，但之后每次发布只需要几分钟！

需要帮助？查看详细文档或联系团队。

祝发布顺利！🚀
