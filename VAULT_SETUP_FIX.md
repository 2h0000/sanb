# Vault 设置界面重复显示问题修复

## 问题描述
在第一次设置完 master password 后，返回到 notes 界面，再次点击 vault 按钮会再次进入 "Set Up Master Password" 界面，而不是 "Unlock" 界面。只有关闭应用重新打开才会显示正确的 unlock 界面。

## 问题原因
`vaultNeedsSetupProvider` 是一个 `FutureProvider`，它会缓存查询结果。当第一次设置密码后：
1. Provider 的缓存值仍然是 `true`（需要设置）
2. 虽然密钥已经保存到安全存储，但 provider 没有刷新
3. 再次访问时，provider 返回缓存的旧值，导致显示设置界面

## 解决方案
在 `vault_unlock_screen.dart` 的 `_handleSetup()` 方法中，设置完成后添加：
```dart
// Invalidate the setup check so it refreshes next time
ref.invalidate(vaultNeedsSetupProvider);
```

这会使 provider 的缓存失效，下次访问时会重新查询安全存储，返回正确的状态。

## 修改文件
- `lib/features/vault/presentation/vault_unlock_screen.dart`

## 测试步骤
1. 首次打开应用，点击 vault 按钮
2. 设置 master password
3. 返回 notes 界面
4. 再次点击 vault 按钮
5. 应该显示 "Unlock Vault" 界面，而不是 "Set Up Master Password" 界面

## 构建版本
已生成新的 APK：`build/app/outputs/flutter-apk/app-release.apk`
