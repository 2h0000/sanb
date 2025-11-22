# Secure Advanced Notebook (SANB)

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## 🇬🇧 English

A secure, offline-first encrypted notebook application with end-to-end encryption, built with Flutter.

### ✨ Features

#### ✅ Currently Available
- 📝 **Note Management**: Create, edit, delete, and organize notes
- 🔐 **Password Vault**: Securely store passwords and credentials with AES-256-GCM encryption
- 🔒 **Zero-Knowledge Architecture**: Your master password never leaves your device
- 📱 **Fully Offline**: Complete functionality without internet connection
- 🌓 **Dark Mode**: Beautiful light and dark themes
- 🔍 **Search**: Full-text search across all notes
- 💾 **Local Storage**: SQLite database with encryption
- 🔑 **Secure Key Storage**: Uses device keychain for key management

#### 🚧 Planned Features (Not Yet Implemented)
- ☁️ **Cloud Sync**: Automatic synchronization across devices using Firebase *(Coming Soon)*
- 📄 **Markdown Rendering**: Rich text preview for Markdown content *(Coming Soon)*
- 🌍 **Multi-language**: i18n support for multiple languages *(Coming Soon)*
- 📤 **Export/Import**: Backup and restore functionality *(Coming Soon)*

### 🔒 Security

- **Encryption**: AES-256-GCM for data encryption
- **Key Derivation**: PBKDF2-HMAC-SHA256 with 210,000 iterations
- **Secure Storage**: flutter_secure_storage for key management
- **Zero-Knowledge**: Master password is never transmitted or stored
- **Offline-First**: All data stays on your device

### 🏗️ Architecture

The app follows a clean architecture pattern:

- **Presentation Layer**: UI components and state management (Riverpod)
- **Application Layer**: Use cases and business logic
- **Domain Layer**: Entities and repository interfaces
- **Data Layer**: Local database (Drift + SQLite)
- **Core Layer**: Cryptography, utilities, and error handling

### 📦 Installation

#### For Users
Download the latest APK from [Releases](https://github.com/2h0000/sanb/releases)

**System Requirements**:
- Android 5.0 (API 21) or higher
- ~60MB storage space

#### For Developers

**Prerequisites**:
- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher

**Setup**:
```bash
# Clone the repository
git clone https://github.com/2h0000/sanb.git
cd sanb

# Install dependencies
flutter pub get

# Generate code (for Drift and Riverpod)
dart run build_runner build

# Run the app
flutter run
```

### 📚 Documentation

- 📖 [Full Documentation](./docs/) - Complete project documentation
- 🚀 [Setup Guide](./docs/setup/SETUP.md) - Getting started
- 🔨 [Build Guide](./docs/build/BUILD_RELEASE_GUIDE.md) - Building releases
- 💻 [Development Docs](./docs/development/) - Architecture and development

### 🛠️ Development

**Code Generation**:
```bash
dart run build_runner watch
```

**Testing**:
```bash
flutter test
```

**Building Release**:
```bash
# Windows
scripts\build\build_release.bat

# Linux/Mac
./scripts/build/build_release.sh
```

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<a name="中文"></a>
## 🇨🇳 中文

一个安全的、离线优先的加密笔记应用，采用端到端加密技术，使用 Flutter 构建。

### ✨ 功能特性

#### ✅ 当前已实现
- 📝 **笔记管理**：创建、编辑、删除和组织笔记
- 🔐 **密码保险库**：使用 AES-256-GCM 加密安全存储密码和凭证
- 🔒 **零知识架构**：主密码永不离开您的设备
- 📱 **完全离线**：无需网络连接即可完整使用
- 🌓 **深色模式**：精美的浅色和深色主题
- 🔍 **搜索功能**：全文搜索所有笔记
- 💾 **本地存储**：加密的 SQLite 数据库
- 🔑 **安全密钥存储**：使用设备钥匙串管理密钥

#### 🚧 计划中的功能（尚未实现）
- ☁️ **云同步**：使用 Firebase 跨设备自动同步 *（即将推出）*
- 📄 **Markdown 渲染**：Markdown 内容的富文本预览 *（即将推出）*
- 🌍 **多语言**：支持多语言国际化 *（即将推出）*
- 📤 **导出/导入**：备份和恢复功能 *（即将推出）*

### 🔒 安全性

- **加密算法**：AES-256-GCM 数据加密
- **密钥派生**：PBKDF2-HMAC-SHA256，210,000 次迭代
- **安全存储**：使用 flutter_secure_storage 管理密钥
- **零知识架构**：主密码永不传输或存储
- **离线优先**：所有数据保存在您的设备上

### 🏗️ 架构设计

应用采用清晰的分层架构：

- **表现层**：UI 组件和状态管理（Riverpod）
- **应用层**：用例和业务逻辑
- **领域层**：实体和仓储接口
- **数据层**：本地数据库（Drift + SQLite）
- **核心层**：加密、工具和错误处理

### 📦 安装使用

#### 普通用户
从 [Releases](https://github.com/2h0000/sanb/releases) 下载最新的 APK 文件

**系统要求**：
- Android 5.0（API 21）或更高版本
- 约 60MB 存储空间

#### 开发者

**前置要求**：
- Flutter SDK 3.0 或更高版本
- Dart SDK 3.0 或更高版本

**设置步骤**：
```bash
# 克隆仓库
git clone https://github.com/2h0000/sanb.git
cd sanb

# 安装依赖
flutter pub get

# 生成代码（Drift 和 Riverpod）
dart run build_runner build

# 运行应用
flutter run
```

### 📚 文档

- 📖 [完整文档](./docs/) - 完整的项目文档
- 🚀 [设置指南](./docs/setup/SETUP.md) - 快速开始
- 🔨 [构建指南](./docs/build/BUILD_RELEASE_GUIDE.md) - 构建发布版本
- 💻 [开发文档](./docs/development/) - 架构和开发指南

### 🛠️ 开发

**代码生成**：
```bash
dart run build_runner watch
```

**测试**：
```bash
flutter test
```

**构建发布版本**：
```bash
# Windows
scripts\build\build_release.bat

# Linux/Mac
./scripts/build/build_release.sh
```

### 📂 项目结构

```
├── lib/                    # 源代码
│   ├── app/               # 应用配置、路由、主题
│   ├── core/              # 核心工具和加密
│   ├── data/              # 数据层（本地数据库）
│   ├── domain/            # 领域层（实体、仓储）
│   └── features/          # 功能模块（笔记、保险库、设置）
├── docs/                   # 文档
├── scripts/                # 实用脚本
├── firebase/               # Firebase 配置（未来使用）
├── assets/                 # 应用资源
├── android/                # Android 平台代码
└── test/                   # 测试
```

### 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

### 📮 联系方式

- GitHub Issues: [https://github.com/2h0000/sanb/issues](https://github.com/2h0000/sanb/issues)
- 邮箱：2238770576@qq.com
  
---

## 🌟 Star History

如果这个项目对你有帮助，请给个 Star ⭐

If you find this project helpful, please give it a star ⭐
