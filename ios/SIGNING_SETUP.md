# iOS 签名配置指南

本文档详细说明如何为 Encrypted Notebook 应用配置 iOS 签名。

## 前提条件

1. **Apple Developer 账号**
   - 注册 [Apple Developer Program](https://developer.apple.com/programs/)
   - 年费：$99 USD
   - 审核时间：1-2 个工作日

2. **开发环境**
   - macOS 系统
   - Xcode 14.0 或更高版本
   - CocoaPods（Flutter 会自动安装）

## 配置步骤

### 1. 创建 App ID

1. 登录 [Apple Developer Console](https://developer.apple.com/account/)
2. 进入 **Certificates, Identifiers & Profiles**
3. 选择 **Identifiers** > 点击 **+** 按钮
4. 选择 **App IDs** > 点击 **Continue**
5. 填写信息：
   - **Description**: `Encrypted Notebook`
   - **Bundle ID**: `com.example.encryptedNotebook` (Explicit)
   - **Capabilities**: 根据需要启用
     - ✅ Push Notifications（如果需要推送）
     - ✅ iCloud（如果需要 iCloud 同步）
     - ✅ Background Modes（如果需要后台运行）
6. 点击 **Continue** > **Register**

### 2. 创建开发证书（Development Certificate）

#### 2.1 生成证书签名请求（CSR）

在 Mac 上：
1. 打开 **Keychain Access**（钥匙串访问）
2. 菜单栏：**Keychain Access** > **Certificate Assistant** > **Request a Certificate from a Certificate Authority**
3. 填写信息：
   - **User Email Address**: 你的邮箱
   - **Common Name**: 你的名字
   - **CA Email Address**: 留空
   - **Request is**: 选择 **Saved to disk**
4. 点击 **Continue**，保存 `CertificateSigningRequest.certSigningRequest` 文件

#### 2.2 在 Apple Developer Console 创建证书

1. 进入 **Certificates** > 点击 **+** 按钮
2. 选择 **iOS App Development** > 点击 **Continue**
3. 上传刚才生成的 CSR 文件
4. 点击 **Continue** > **Download**
5. 双击下载的证书文件，安装到 Keychain

### 3. 创建发布证书（Distribution Certificate）

重复上述步骤，但在第 2 步选择 **iOS Distribution** 而不是 **iOS App Development**。

### 4. 注册测试设备（可选，用于开发）

1. 进入 **Devices** > 点击 **+** 按钮
2. 填写设备信息：
   - **Device Name**: 设备名称（如 "My iPhone"）
   - **Device ID (UDID)**: 设备的 UDID
3. 点击 **Continue** > **Register**

**获取 UDID 的方法：**
- 连接设备到 Mac
- 打开 Xcode > Window > Devices and Simulators
- 选择设备，复制 **Identifier**

### 5. 创建 Provisioning Profile

#### 5.1 开发 Provisioning Profile

1. 进入 **Profiles** > 点击 **+** 按钮
2. 选择 **iOS App Development** > 点击 **Continue**
3. 选择刚才创建的 App ID > 点击 **Continue**
4. 选择开发证书 > 点击 **Continue**
5. 选择测试设备 > 点击 **Continue**
6. 输入 Profile Name（如 "Encrypted Notebook Dev"）
7. 点击 **Generate** > **Download**
8. 双击下载的 `.mobileprovision` 文件安装

#### 5.2 发布 Provisioning Profile

1. 进入 **Profiles** > 点击 **+** 按钮
2. 选择 **App Store** > 点击 **Continue**
3. 选择 App ID > 点击 **Continue**
4. 选择发布证书 > 点击 **Continue**
5. 输入 Profile Name（如 "Encrypted Notebook AppStore"）
6. 点击 **Generate** > **Download**
7. 双击安装

### 6. 在 Xcode 中配置签名

#### 6.1 打开项目

```bash
cd ios
open Runner.xcworkspace
```

⚠️ **注意**：必须打开 `.xcworkspace` 文件，而不是 `.xcodeproj`！

#### 6.2 配置 Signing & Capabilities

1. 在 Xcode 左侧选择 **Runner** 项目
2. 选择 **Runner** target
3. 选择 **Signing & Capabilities** 标签

**自动签名（推荐）：**
- ✅ 勾选 **Automatically manage signing**
- **Team**: 选择你的开发团队
- **Bundle Identifier**: `com.example.encryptedNotebook`
- Xcode 会自动处理证书和 Provisioning Profile

**手动签名（高级）：**
- ❌ 取消勾选 **Automatically manage signing**
- **Provisioning Profile**: 选择对应的 Profile
- **Signing Certificate**: 选择对应的证书

#### 6.3 配置 Release 签名

1. 在 **Signing & Capabilities** 中
2. 切换到 **Release** 配置（顶部下拉菜单）
3. 配置与 Debug 相同的签名设置

### 7. 配置 Info.plist

确保 `ios/Runner/Info.plist` 包含必要的权限说明：

```xml
<!-- 如果使用相机 -->
<key>NSCameraUsageDescription</key>
<string>需要访问相机以扫描二维码</string>

<!-- 如果使用相册 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择图片</string>

<!-- 如果使用文件系统 -->
<key>NSDocumentsFolderUsageDescription</key>
<string>需要访问文件以导入导出数据</string>

<!-- 如果使用 Face ID / Touch ID -->
<key>NSFaceIDUsageDescription</key>
<string>使用 Face ID 快速解锁应用</string>
```

### 8. 构建和测试

#### 8.1 开发构建

```bash
# 在项目根目录
flutter build ios --debug

# 或在 Xcode 中
# 选择真机设备 > Product > Run
```

#### 8.2 发布构建

```bash
# 构建 IPA
flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols

# 输出位置
# build/ios/ipa/encrypted_notebook.ipa
```

#### 8.3 使用 Xcode Archive

```bash
# 打开 Xcode
open ios/Runner.xcworkspace

# 在 Xcode 中：
# 1. 选择 Generic iOS Device（或 Any iOS Device）
# 2. Product > Archive
# 3. 等待构建完成
# 4. Window > Organizer
# 5. 选择刚才的 Archive
# 6. 点击 Distribute App
```

### 9. 上传到 App Store Connect

#### 9.1 创建应用

1. 登录 [App Store Connect](https://appstoreconnect.apple.com/)
2. 点击 **My Apps** > **+** > **New App**
3. 填写信息：
   - **Platform**: iOS
   - **Name**: Encrypted Notebook
   - **Primary Language**: Chinese (Simplified) 或 English
   - **Bundle ID**: 选择 `com.example.encryptedNotebook`
   - **SKU**: `encrypted-notebook-001`（唯一标识符）
4. 点击 **Create**

#### 9.2 上传构建

**方法 1：使用 Xcode Organizer**
1. Window > Organizer
2. 选择 Archive
3. 点击 **Distribute App**
4. 选择 **App Store Connect**
5. 选择 **Upload**
6. 按照向导完成上传

**方法 2：使用 Transporter**
1. 从 Mac App Store 下载 **Transporter**
2. 打开 Transporter
3. 拖入 IPA 文件
4. 点击 **Deliver**

**方法 3：使用命令行**
```bash
xcrun altool --upload-app --type ios --file build/ios/ipa/encrypted_notebook.ipa --username YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD
```

#### 9.3 填写应用信息

在 App Store Connect 中：
1. **App Information**
   - 类别、隐私政策 URL 等
2. **Pricing and Availability**
   - 定价、发布地区
3. **App Privacy**
   - 数据收集说明
4. **Version Information**
   - 版本号、更新说明
   - 截图（必需）
   - 应用描述
5. **Build**
   - 选择刚才上传的构建
6. **Submit for Review**

### 10. TestFlight 测试（可选）

1. 在 App Store Connect 中选择应用
2. 进入 **TestFlight** 标签
3. 选择构建
4. 添加测试人员（内部或外部）
5. 测试人员会收到邮件邀请

### 11. 常见问题

#### 问题 1：签名失败

**错误信息**：`Signing for "Runner" requires a development team`

**解决方法**：
1. 在 Xcode 中选择 Team
2. 或在 `ios/Runner.xcodeproj/project.pbxproj` 中手动设置 `DEVELOPMENT_TEAM`

#### 问题 2：Provisioning Profile 不匹配

**错误信息**：`No profiles for 'com.example.encryptedNotebook' were found`

**解决方法**：
1. 检查 Bundle ID 是否正确
2. 重新下载 Provisioning Profile
3. 在 Xcode 中刷新：Preferences > Accounts > Download Manual Profiles

#### 问题 3：证书过期

**解决方法**：
1. 在 Apple Developer Console 撤销旧证书
2. 创建新证书
3. 更新 Provisioning Profile

#### 问题 4：构建失败

**错误信息**：`CocoaPods not installed`

**解决方法**：
```bash
sudo gem install cocoapods
cd ios
pod install
```

### 12. 自动化签名（CI/CD）

#### 12.1 使用 Fastlane

```bash
# 安装 Fastlane
sudo gem install fastlane

# 初始化
cd ios
fastlane init

# 配置 Fastfile
# 添加自动签名和上传逻辑
```

#### 12.2 使用 Match

```bash
# 初始化 Match（证书管理）
fastlane match init

# 生成证书
fastlane match development
fastlane match appstore
```

### 13. 安全建议

1. **保护私钥**
   - 不要将证书和私钥提交到版本控制
   - 使用 Keychain 安全存储
   - 定期备份到安全位置

2. **使用 App-Specific Password**
   - 在 appleid.apple.com 生成
   - 用于自动化上传

3. **启用双因素认证**
   - 保护 Apple ID 安全

### 14. 参考资源

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Fastlane Documentation](https://docs.fastlane.tools/)

---

## 快速检查清单

- [ ] Apple Developer 账号已激活
- [ ] App ID 已创建
- [ ] 开发证书已安装
- [ ] 发布证书已安装
- [ ] Provisioning Profile 已安装
- [ ] Xcode 签名配置正确
- [ ] Info.plist 权限说明完整
- [ ] 构建成功
- [ ] TestFlight 测试通过
- [ ] App Store Connect 信息完整
- [ ] 提交审核

---

**提示**：首次配置可能比较复杂，建议先使用自动签名，熟悉流程后再考虑手动签名。
