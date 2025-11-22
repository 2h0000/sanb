# 构建与发布准备指南

本文档提供了加密笔记本应用的完整构建和发布准备流程。

## 目录

1. [Firebase 生产环境配置](#1-firebase-生产环境配置)
2. [代码混淆配置](#2-代码混淆配置)
3. [Android 签名配置](#3-android-签名配置)
4. [iOS 证书配置](#4-ios-证书配置)
5. [生成发布构建](#5-生成发布构建)
6. [发布前检查清单](#6-发布前检查清单)

---

## 1. Firebase 生产环境配置

### 1.1 安装 FlutterFire CLI

```bash
# 安装 FlutterFire CLI
dart pub global activate flutterfire_cli

# 验证安装
flutterfire --version
```

### 1.2 配置 Firebase 项目

```bash
# 登录 Firebase
firebase login

# 配置项目（会自动生成 firebase_options.dart）
flutterfire configure
```

**配置步骤：**
1. 选择或创建 Firebase 项目
2. 选择要支持的平台（Android, iOS）
3. 输入 Android 包名：`com.example.encrypted_notebook`
4. 输入 iOS Bundle ID：`com.example.encryptedNotebook`
5. 确认生成配置文件

### 1.3 启用 Firebase 服务

在 [Firebase Console](https://console.firebase.google.com/) 中：

1. **Authentication**
   - 启用 Email/Password 认证
   - 配置授权域名

2. **Firestore Database**
   - 创建数据库（生产模式）
   - 部署安全规则（见 `firestore.rules`）

3. **Storage**
   - 启用 Cloud Storage
   - 部署安全规则（见 `storage.rules`）

4. **Crashlytics**
   - 启用 Crashlytics
   - 配置符号上传

### 1.4 部署安全规则

```bash
# 安装 Firebase CLI
npm install -g firebase-tools

# 初始化 Firebase 项目
firebase init

# 部署 Firestore 规则
firebase deploy --only firestore:rules

# 部署 Storage 规则
firebase deploy --only storage:rules
```

---

## 2. 代码混淆配置

### 2.1 Android 混淆

Android 混淆已在 `android/app/build.gradle` 中配置：

```gradle
buildTypes {
    release {
        // 启用混淆
        minifyEnabled true
        // 启用资源压缩
        shrinkResources true
        // 使用 ProGuard 规则
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        
        signingConfig signingConfigs.release
    }
}
```

### 2.2 ProGuard 规则

已创建 `android/app/proguard-rules.pro` 文件，包含：
- Firebase 相关规则
- Drift 数据库规则
- Cryptography 库规则
- Flutter 相关规则

### 2.3 Dart 代码混淆

Flutter 默认在 release 模式下启用 Dart 代码混淆。可以通过以下参数控制：

```bash
# 构建时启用混淆（默认）
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols

# 构建时禁用混淆（不推荐）
flutter build apk --no-obfuscate
```

---

## 3. Android 签名配置

### 3.1 生成 Keystore

```bash
# 使用 keytool 生成密钥库
keytool -genkey -v -keystore ~/encrypted-notebook-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias encrypted-notebook

# 或使用 Android Studio：
# Build > Generate Signed Bundle / APK > Create new...
```

**重要信息记录：**
- Keystore 路径：`~/encrypted-notebook-release.jks`
- Keystore 密码：`[记录在安全位置]`
- Key alias：`encrypted-notebook`
- Key 密码：`[记录在安全位置]`

⚠️ **警告：** 请妥善保管 keystore 文件和密码！丢失后将无法更新应用！

### 3.2 配置签名

1. 创建 `android/key.properties` 文件（已添加到 .gitignore）：

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=encrypted-notebook
storeFile=C:/path/to/encrypted-notebook-release.jks
```

2. 签名配置已在 `android/app/build.gradle` 中设置

### 3.3 验证签名

```bash
# 构建签名的 APK
flutter build apk --release

# 验证签名
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. iOS 证书配置

### 4.1 Apple Developer 账号

1. 注册 [Apple Developer Program](https://developer.apple.com/programs/)（需要年费 $99）
2. 登录 [Apple Developer Console](https://developer.apple.com/account/)

### 4.2 创建 App ID

1. 进入 Certificates, Identifiers & Profiles
2. 创建新的 App ID
   - Description: `Encrypted Notebook`
   - Bundle ID: `com.example.encryptedNotebook`（Explicit）
   - Capabilities: 启用需要的功能（如 Push Notifications）

### 4.3 创建证书

**开发证书（Development）：**
```bash
# 在 Mac 上生成证书签名请求（CSR）
# Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority
```

**发布证书（Distribution）：**
1. 在 Apple Developer Console 创建 iOS Distribution 证书
2. 上传 CSR 文件
3. 下载证书并双击安装到 Keychain

### 4.4 创建 Provisioning Profile

1. 在 Apple Developer Console 创建 Provisioning Profile
2. 选择 App ID 和证书
3. 下载并双击安装

### 4.5 Xcode 配置

```bash
# 打开 iOS 项目
open ios/Runner.xcworkspace
```

在 Xcode 中：
1. 选择 Runner target
2. Signing & Capabilities
   - Team: 选择你的开发团队
   - Bundle Identifier: `com.example.encryptedNotebook`
   - Automatically manage signing: 勾选（推荐）

### 4.6 配置文档

已创建 `ios/SIGNING_SETUP.md` 详细说明 iOS 签名配置步骤。

---

## 5. 生成发布构建

### 5.1 Android 构建

#### APK（单个文件，适合直接分发）

```bash
# 构建 release APK
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# 输出位置
# build/app/outputs/flutter-apk/app-release.apk
```

#### AAB（Android App Bundle，适合 Google Play）

```bash
# 构建 release AAB
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# 输出位置
# build/app/outputs/bundle/release/app-release.aab
```

#### 分架构 APK（减小文件大小）

```bash
# 构建分架构 APK
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols

# 输出位置（会生成多个 APK）
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### 5.2 iOS 构建

#### IPA（用于 App Store 或 TestFlight）

```bash
# 构建 release IPA
flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols

# 输出位置
# build/ios/ipa/encrypted_notebook.ipa
```

#### 使用 Xcode Archive

```bash
# 打开 Xcode
open ios/Runner.xcworkspace

# 在 Xcode 中：
# 1. 选择 Generic iOS Device
# 2. Product > Archive
# 3. 等待构建完成
# 4. Window > Organizer
# 5. 选择 Archive > Distribute App
```

### 5.3 构建脚本

已创建便捷构建脚本：

**Windows:**
```bash
# 运行构建脚本
.\build_release.bat
```

**macOS/Linux:**
```bash
# 添加执行权限
chmod +x build_release.sh

# 运行构建脚本
./build_release.sh
```

---

## 6. 发布前检查清单

### 6.1 代码检查

- [ ] 所有测试通过
- [ ] 代码已提交到版本控制
- [ ] 移除所有调试代码和 print 语句
- [ ] 更新版本号（pubspec.yaml）
- [ ] 更新 CHANGELOG.md

### 6.2 配置检查

- [ ] Firebase 生产环境已配置
- [ ] 安全规则已部署
- [ ] API 密钥已配置
- [ ] 混淆已启用
- [ ] 签名配置正确

### 6.3 功能检查

- [ ] 笔记创建、编辑、删除功能正常
- [ ] 密码库加密解密正常
- [ ] 云端同步功能正常
- [ ] 离线模式正常
- [ ] 导入导出功能正常
- [ ] 认证功能正常

### 6.4 性能检查

- [ ] 应用启动时间 < 3 秒
- [ ] 列表滚动流畅（60 FPS）
- [ ] 内存使用合理
- [ ] 电池消耗正常

### 6.5 安全检查

- [ ] 主密码不会被记录
- [ ] 敏感数据已加密
- [ ] 网络传输使用 HTTPS
- [ ] 截屏保护已启用（Android）
- [ ] 剪贴板自动清除正常

### 6.6 UI/UX 检查

- [ ] 所有屏幕尺寸适配正常
- [ ] 深色/浅色主题正常
- [ ] 错误提示友好
- [ ] 加载状态显示正常
- [ ] 无 UI 闪烁或卡顿

### 6.7 法律合规

- [ ] 隐私政策已准备
- [ ] 服务条款已准备
- [ ] 开源许可证已声明
- [ ] 应用描述和截图已准备

---

## 7. 发布渠道

### 7.1 Google Play Store

1. 创建 [Google Play Console](https://play.google.com/console) 账号
2. 创建新应用
3. 填写应用信息
4. 上传 AAB 文件
5. 填写内容分级问卷
6. 设置定价和分发
7. 提交审核

### 7.2 Apple App Store

1. 在 [App Store Connect](https://appstoreconnect.apple.com/) 创建应用
2. 填写应用信息
3. 使用 Xcode 或 Transporter 上传 IPA
4. 填写审核信息
5. 提交审核

### 7.3 其他渠道

- **直接分发 APK**：通过网站或其他渠道分发
- **企业分发**：使用 Apple Enterprise Program
- **测试分发**：使用 TestFlight (iOS) 或 Firebase App Distribution

---

## 8. 持续集成/持续部署（CI/CD）

### 8.1 GitHub Actions

已创建 `.github/workflows/build.yml` 配置文件，支持：
- 自动运行测试
- 自动构建 APK/AAB
- 自动构建 IPA（需要 macOS runner）
- 自动上传到 Firebase App Distribution

### 8.2 Fastlane

可选：使用 Fastlane 自动化发布流程

```bash
# 安装 Fastlane
gem install fastlane

# 初始化
cd android && fastlane init
cd ../ios && fastlane init
```

---

## 9. 故障排查

### 9.1 常见问题

**问题：构建失败，提示签名错误**
- 检查 key.properties 文件路径是否正确
- 检查密码是否正确
- 检查 keystore 文件是否存在

**问题：iOS 构建失败，提示证书错误**
- 检查证书是否过期
- 检查 Provisioning Profile 是否匹配
- 尝试在 Xcode 中手动签名

**问题：应用崩溃**
- 检查 Crashlytics 日志
- 使用 `flutter build apk --release --verbose` 查看详细日志
- 检查混淆规则是否正确

### 9.2 调试 Release 构建

```bash
# 构建 profile 模式（保留调试信息）
flutter build apk --profile

# 连接设备并查看日志
flutter logs
```

---

## 10. 版本管理

### 10.1 版本号规范

使用语义化版本：`MAJOR.MINOR.PATCH+BUILD`

```yaml
# pubspec.yaml
version: 1.0.0+1
#        ↑   ↑
#        |   └─ Build number (递增)
#        └───── Version name
```

### 10.2 更新版本

```bash
# 更新版本号
# 编辑 pubspec.yaml
version: 1.0.1+2

# 或使用脚本
# Windows: update_version.bat 1.0.1 2
# macOS/Linux: ./update_version.sh 1.0.1 2
```

---

## 11. 资源

- [Flutter 官方文档 - 发布 Android 应用](https://docs.flutter.dev/deployment/android)
- [Flutter 官方文档 - 发布 iOS 应用](https://docs.flutter.dev/deployment/ios)
- [Firebase 文档](https://firebase.google.com/docs)
- [Google Play Console 帮助](https://support.google.com/googleplay/android-developer)
- [App Store Connect 帮助](https://developer.apple.com/help/app-store-connect/)

---

## 总结

本指南涵盖了从配置到发布的完整流程。请按照步骤操作，并在发布前完成所有检查清单项目。

**重要提醒：**
- 妥善保管 keystore 和证书
- 定期备份签名文件
- 在生产环境中使用独立的 Firebase 项目
- 启用所有安全功能
- 进行充分测试

祝发布顺利！🚀
