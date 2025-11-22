# 测试指南

## 已修复的问题

### ✅ "User not authenticated" 错误已修复
- 修改了 `LocalAuthService`，确保在应用启动时自动创建本地用户
- 修改了 `currentUserProvider`，直接从服务获取用户而不是等待 Stream
- 现在保险箱功能可以正常使用

## 新构建的 APK

**位置：** `build\app\outputs\flutter-apk\app-release.apk`
**大小：** 57.2 MB
**构建时间：** 2025/11/22 09:10

## 在模拟器中测试

### 1. 启动模拟器
```bash
flutter emulators --launch Medium_Phone_API_36.1
```

### 2. 安装 APK
```bash
flutter install -d emulator-5554 build\app\outputs\flutter-apk\app-release.apk
```

### 3. 打开应用
在模拟器中找到 "Encrypted Notebook" 应用图标并点击打开

## 测试清单

### 基本功能测试
- [ ] 应用启动正常，直接进入笔记列表
- [ ] 可以创建新笔记
- [ ] 可以编辑笔记
- [ ] 可以删除笔记
- [ ] 笔记列表正常显示

### 保险箱功能测试
- [ ] 点击底部导航的"保险箱"图标
- [ ] 首次使用显示"Set up master password"界面
- [ ] 输入主密码（至少8个字符）
- [ ] 点击"Set up vault"按钮
- [ ] **应该成功设置**（不再显示"User not authenticated"）
- [ ] 成功后进入保险箱列表界面
- [ ] 可以添加保险箱项目
- [ ] 可以查看保险箱项目详情
- [ ] 可以编辑保险箱项目
- [ ] 可以删除保险箱项目

### 保险箱解锁测试
- [ ] 关闭应用
- [ ] 重新打开应用
- [ ] 进入保险箱
- [ ] 显示"Unlock vault"界面
- [ ] 输入之前设置的主密码
- [ ] 点击"Unlock"按钮
- [ ] 成功解锁并显示保险箱项目列表

### 设置功能测试
- [ ] 点击底部导航的"设置"图标
- [ ] 可以切换主题（亮色/暗色/跟随系统）
- [ ] 可以导出数据
- [ ] 显示应用信息（版本号、用户ID等）

### 数据持久化测试
- [ ] 创建几条笔记
- [ ] 创建几个保险箱项目
- [ ] 完全关闭应用
- [ ] 重新打开应用
- [ ] 验证笔记和保险箱数据都还在

## 常见问题

### Q: 模拟器启动很慢怎么办？
A: 第一次启动模拟器需要较长时间（1-3分钟），请耐心等待。

### Q: 如何查看应用日志？
A: 使用命令：
```bash
flutter logs -d emulator-5554
```

### Q: 如何卸载应用？
A: 在模拟器中长按应用图标，拖到"卸载"或使用命令：
```bash
flutter uninstall -d emulator-5554
```

### Q: 如何重新安装最新版本？
A: 先卸载旧版本，然后重新安装：
```bash
flutter uninstall -d emulator-5554
flutter install -d emulator-5554 build\app\outputs\flutter-apk\app-release.apk
```

## 在真机上测试

### 1. 将 APK 传输到手机
- 通过 USB 数据线连接电脑和手机
- 将 `build\app\outputs\flutter-apk\app-release.apk` 复制到手机
- 或通过微信/QQ等工具发送到手机

### 2. 安装 APK
- 在手机上打开文件管理器
- 找到 APK 文件
- 点击安装
- 如果提示"未知来源"，需要在设置中允许安装未知来源应用

### 3. 测试
- 按照上面的测试清单进行测试
- 特别注意保险箱功能是否正常工作

## 发现问题后的处理

如果发现任何问题：

1. **记录问题详情**
   - 具体操作步骤
   - 预期结果
   - 实际结果
   - 错误信息（如果有）

2. **查看日志**
   ```bash
   flutter logs -d emulator-5554
   ```

3. **报告问题**
   - 描述问题
   - 提供复现步骤
   - 附上日志信息

## 下一步

测试完成后，如果一切正常：
1. 可以将 APK 安装到你的手机上日常使用
2. 所有数据都保存在本地，不会上传到云端
3. 定期备份数据（使用设置中的"导出数据"功能）
