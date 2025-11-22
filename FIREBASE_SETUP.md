# Firebase 生产环境配置指南

本文档详细说明如何为 Encrypted Notebook 应用配置 Firebase 生产环境。

## 前提条件

- Google 账号
- Flutter 开发环境
- FlutterFire CLI

## 1. 安装工具

### 1.1 安装 Firebase CLI

```bash
# 使用 npm 安装
npm install -g firebase-tools

# 验证安装
firebase --version
```

### 1.2 安装 FlutterFire CLI

```bash
# 安装
dart pub global activate flutterfire_cli

# 验证安装
flutterfire --version
```

## 2. 创建 Firebase 项目

### 2.1 在 Firebase Console 创建项目

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 点击 **添加项目**
3. 输入项目名称：`encrypted-notebook-prod`
4. 选择是否启用 Google Analytics（推荐启用）
5. 选择 Analytics 账号或创建新账号
6. 点击 **创建项目**

### 2.2 配置项目设置

1. 进入项目设置（齿轮图标）
2. 在 **常规** 标签中：
   - 设置项目公开名称
   - 设置支持邮箱
   - 选择默认 GCP 资源位置（建议：`asia-east1` 或 `asia-northeast1`）

## 3. 添加应用

### 3.1 添加 Android 应用

1. 在 Firebase Console 点击 **添加应用** > **Android**
2. 填写信息：
   - **Android 包名**: `com.example.encrypted_notebook`
   - **应用昵称**: `Encrypted Notebook Android`
   - **调试签名证书 SHA-1**: （可选，用于 Google 登录）
3. 点击 **注册应用**
4. 下载 `google-services.json`
5. 将文件放到 `android/app/` 目录

### 3.2 添加 iOS 应用

1. 在 Firebase Console 点击 **添加应用** > **iOS**
2. 填写信息：
   - **iOS 捆绑包 ID**: `com.example.encryptedNotebook`
   - **应用昵称**: `Encrypted Notebook iOS`
3. 点击 **注册应用**
4. 下载 `GoogleService-Info.plist`
5. 在 Xcode 中将文件添加到 `ios/Runner/` 目录

### 3.3 使用 FlutterFire CLI 自动配置

```bash
# 登录 Firebase
firebase login

# 配置项目（会自动生成 firebase_options.dart）
flutterfire configure

# 选择项目
# 选择平台（Android, iOS）
# 确认配置
```

这会自动：
- 创建或更新 `lib/firebase_options.dart`
- 下载配置文件到正确位置
- 配置 iOS 和 Android 项目

## 4. 启用 Firebase 服务

### 4.1 Authentication

1. 在 Firebase Console 进入 **Authentication**
2. 点击 **开始使用**
3. 选择 **登录方法** 标签
4. 启用 **电子邮件/密码**
   - 点击 **电子邮件/密码**
   - 启用开关
   - 点击 **保存**
5. 配置授权域名
   - 在 **设置** 标签中
   - 添加你的域名（如果有）

### 4.2 Firestore Database

1. 在 Firebase Console 进入 **Firestore Database**
2. 点击 **创建数据库**
3. 选择 **生产模式**
4. 选择位置（建议：`asia-east1` 或 `asia-northeast1`）
5. 点击 **启用**

#### 部署安全规则

```bash
# 初始化 Firebase 项目
firebase init firestore

# 选择项目
# 使用默认文件名（firestore.rules, firestore.indexes.json）

# 部署规则
firebase deploy --only firestore:rules
```

`firestore.rules` 内容：
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能访问自己的数据
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 拒绝所有其他访问
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 4.3 Cloud Storage

1. 在 Firebase Console 进入 **Storage**
2. 点击 **开始使用**
3. 选择 **生产模式**
4. 选择位置（与 Firestore 相同）
5. 点击 **完成**

#### 部署安全规则

```bash
# 初始化 Storage
firebase init storage

# 部署规则
firebase deploy --only storage
```

`storage.rules` 内容：
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 用户只能访问自己的文件
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 拒绝所有其他访问
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 4.4 Crashlytics

1. 在 Firebase Console 进入 **Crashlytics**
2. 点击 **启用 Crashlytics**
3. 按照指示完成设置

#### Android 配置

在 `android/app/build.gradle` 中添加：
```gradle
plugins {
    id 'com.google.firebase.crashlytics'
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-crashlytics'
}
```

在 `android/build.gradle` 中添加：
```gradle
buildscript {
    dependencies {
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'
    }
}
```

#### iOS 配置

在 `ios/Podfile` 中添加：
```ruby
pod 'Firebase/Crashlytics'
```

然后运行：
```bash
cd ios
pod install
```

## 5. 配置配额和限制

### 5.1 Firestore 配额

1. 进入 **Firestore Database** > **使用情况**
2. 查看当前配额
3. 根据需要升级到 Blaze 计划（按使用付费）

**免费配额（Spark 计划）**：
- 存储：1 GB
- 读取：50,000 次/天
- 写入：20,000 次/天
- 删除：20,000 次/天

### 5.2 Storage 配额

**免费配额（Spark 计划）**：
- 存储：5 GB
- 下载：1 GB/天
- 上传：无限制

### 5.3 Authentication 配额

**免费配额**：
- 电子邮件/密码：无限制
- 短信验证：10 次/天（Spark）

## 6. 安全配置

### 6.1 启用 App Check

1. 在 Firebase Console 进入 **App Check**
2. 点击 **开始使用**
3. 为 Android 配置 Play Integrity
4. 为 iOS 配置 App Attest
5. 启用强制执行

### 6.2 配置 API 密钥限制

1. 进入 [Google Cloud Console](https://console.cloud.google.com/)
2. 选择项目
3. 进入 **API 和服务** > **凭据**
4. 编辑 API 密钥
5. 添加应用限制：
   - Android：添加包名和 SHA-1
   - iOS：添加 Bundle ID
6. 限制 API 访问：
   - 只启用需要的 API

### 6.3 启用审核日志

1. 进入 **IAM 和管理** > **审核日志**
2. 启用需要的日志类型
3. 配置日志保留期限

## 7. 监控和告警

### 7.1 配置性能监控

1. 在 Firebase Console 进入 **Performance**
2. 点击 **开始使用**
3. 按照指示完成设置

### 7.2 配置告警

1. 进入 **Alerts**
2. 创建告警规则：
   - Crashlytics 崩溃率 > 1%
   - 性能下降 > 20%
   - 配额使用 > 80%

### 7.3 配置 Analytics

1. 进入 **Analytics**
2. 配置事件跟踪
3. 创建自定义报告

## 8. 备份和恢复

### 8.1 Firestore 备份

```bash
# 导出数据
gcloud firestore export gs://[BUCKET_NAME]

# 导入数据
gcloud firestore import gs://[BUCKET_NAME]/[EXPORT_FOLDER]
```

### 8.2 自动备份

1. 在 Google Cloud Console 创建 Cloud Scheduler 任务
2. 配置定期导出 Firestore 数据
3. 设置保留策略

## 9. 成本优化

### 9.1 Firestore 优化

- 使用索引优化查询
- 避免不必要的读取
- 使用缓存减少读取
- 批量操作减少写入

### 9.2 Storage 优化

- 压缩文件
- 使用 CDN
- 设置缓存策略
- 定期清理未使用的文件

### 9.3 监控成本

1. 进入 **使用情况和结算**
2. 查看每日成本
3. 设置预算告警

## 10. 测试配置

### 10.1 测试 Authentication

```dart
// 测试注册
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: 'test@example.com',
  password: 'password123',
);

// 测试登录
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'test@example.com',
  password: 'password123',
);
```

### 10.2 测试 Firestore

```dart
// 测试写入
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('notes')
    .add({'title': 'Test', 'content': 'Test content'});

// 测试读取
final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('notes')
    .get();
```

### 10.3 测试 Storage

```dart
// 测试上传
final ref = FirebaseStorage.instance.ref('users/$userId/test.txt');
await ref.putString('Test content');

// 测试下载
final url = await ref.getDownloadURL();
```

## 11. 故障排查

### 问题 1：配置文件未找到

**错误**：`google-services.json not found`

**解决**：
1. 确认文件在 `android/app/` 目录
2. 运行 `flutter clean`
3. 重新构建

### 问题 2：权限被拒绝

**错误**：`Permission denied`

**解决**：
1. 检查安全规则
2. 确认用户已登录
3. 检查 UID 匹配

### 问题 3：配额超限

**错误**：`Quota exceeded`

**解决**：
1. 升级到 Blaze 计划
2. 优化查询
3. 使用缓存

## 12. 检查清单

- [ ] Firebase 项目已创建
- [ ] Android 应用已添加
- [ ] iOS 应用已添加
- [ ] `firebase_options.dart` 已生成
- [ ] Authentication 已启用
- [ ] Firestore 已创建
- [ ] Firestore 安全规则已部署
- [ ] Storage 已启用
- [ ] Storage 安全规则已部署
- [ ] Crashlytics 已配置
- [ ] App Check 已启用
- [ ] API 密钥已限制
- [ ] 监控已配置
- [ ] 告警已设置
- [ ] 备份策略已制定
- [ ] 成本监控已启用
- [ ] 测试已通过

## 参考资源

- [Firebase 文档](https://firebase.google.com/docs)
- [FlutterFire 文档](https://firebase.flutter.dev/)
- [Firebase 定价](https://firebase.google.com/pricing)
- [Firebase 配额和限制](https://firebase.google.com/docs/firestore/quotas)

---

配置完成后，你的 Firebase 生产环境就准备好了！🎉
