# 如何发布 SANB APK 到 GitHub

## 方式 1：通过 GitHub Releases（推荐）

### 步骤：

1. **确保代码已推送到 GitHub**
   ```bash
   git add .
   git commit -m "Release v1.0.2 - Remove account section"
   git push origin main
   ```

2. **创建 Release**
   - 访问你的 GitHub 仓库
   - 点击右侧的 "Releases"
   - 点击 "Create a new release"

3. **填写 Release 信息**
   - **Tag version**: `v1.0.2`
   - **Release title**: `SANB v1.0.2`
   - **Description**: 
     ```
     ## SANB v1.0.2
     
     ### 更新内容
     - 修复 vault 设置界面重复显示问题
     - 移除账户信息和登出按钮（完全离线版本）
     
     ### 下载
     下载 `app-release.apk` 并安装到 Android 设备
     
     ### 系统要求
     - Android 5.0 或更高版本
     ```

4. **上传 APK**
   - 在 "Attach binaries" 区域
   - 拖拽或选择文件：`build/app/outputs/flutter-apk/app-release.apk`
   - 建议重命名为：`SANB-v1.0.2.apk`

5. **发布**
   - 勾选 "Set as the latest release"
   - 点击 "Publish release"

### 用户下载方式：
用户访问：`https://github.com/你的用户名/仓库名/releases`
直接下载 APK 文件

---

## 方式 2：直接提交到仓库（不推荐）

APK 文件很大（57MB），会让仓库变得臃肿。

如果一定要这样做：

1. **创建 releases 文件夹**
   ```bash
   mkdir releases
   ```

2. **复制 APK**
   ```bash
   copy build\app\outputs\flutter-apk\app-release.apk releases\SANB-v1.0.2.apk
   ```

3. **提交**
   ```bash
   git add releases/SANB-v1.0.2.apk
   git commit -m "Add APK v1.0.2"
   git push
   ```

**注意**：GitHub 单个文件限制 100MB，但不建议直接提交二进制文件。

---

## 推荐的 .gitignore 配置

确保你的 `.gitignore` 包含：

```gitignore
# Build outputs
build/
*.apk
*.aab
*.ipa

# 但如果你想提交 APK，可以在 releases 文件夹中例外
!releases/*.apk
```

---

## 自动化发布（进阶）

可以使用 GitHub Actions 自动构建和发布：

创建 `.github/workflows/release.yml`：

```yaml
name: Release APK

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: softprops/action-gh-release@v1
        with:
          files: build/app/outputs/flutter-apk/app-release.apk
```

使用方法：
```bash
git tag v1.0.2
git push origin v1.0.2
```

GitHub Actions 会自动构建并发布 APK。
