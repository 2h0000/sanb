# 项目目录结构

## 项目信息
- **项目名称**: Secure Advanced Notebook
- **描述**: 跨平台端到端加密笔记应用
- **版本**: 1.0.2+3
- **Flutter SDK**: >=3.0.0 <4.0.0

## 目录结构

```
encrypted_notebook/
│
├── .dart_tool/                          # Dart 工具生成的文件
│   ├── flutter_build/                   # Flutter 构建缓存
│   ├── package_config.json              # 包配置
│   ├── package_graph.json               # 包依赖图
│   └── version                          # 版本信息
│
├── .github/                             # GitHub 配置
│   └── workflows/                       # CI/CD 工作流
│       └── build.yml                    # 构建工作流配置
│
├── .idea/                               # IntelliJ IDEA 配置
│   ├── libraries/                       # 库配置
│   ├── runConfigurations/               # 运行配置
│   ├── modules.xml                      # 模块配置
│   └── workspace.xml                    # 工作区配置
│
├── .kiro/                               # Kiro AI 助手配置
│   └── specs/                           # 规格文档
│       └── encrypted-notebook-app/      # 应用规格
│
├── .vscode/                             # VS Code 配置
│   └── settings.json                    # 编辑器设置
│
├── android/                             # Android 平台代码
│   ├── .gradle/                         # Gradle 缓存
│   ├── .kotlin/                         # Kotlin 编译缓存
│   ├── app/                             # Android 应用模块
│   │   ├── src/                         # 源代码
│   │   ├── build.gradle                 # 应用构建配置
│   │   ├── google-services.json         # Firebase 配置
│   │   └── proguard-rules.pro           # ProGuard 混淆规则
│   ├── gradle/                          # Gradle wrapper
│   │   └── wrapper/                     # Gradle wrapper 文件
│   ├── build.gradle                     # 项目构建配置
│   ├── gradle.properties                # Gradle 属性
│   ├── gradlew                          # Gradle wrapper (Unix)
│   ├── gradlew.bat                      # Gradle wrapper (Windows)
│   ├── key.properties.template          # 签名密钥模板
│   ├── local.properties                 # 本地配置
│   └── settings.gradle                  # Gradle 设置
│
├── assets/                              # 资源文件
│   ├── icon/                            # 应用图标
│   │   ├── app_icon.png                 # 主图标
│   │   ├── app_icon_foreground.png      # 前景图标
│   │   ├── generate_icons.py            # 图标生成脚本
│   │   ├── generate_placeholder.html    # 占位符生成器
│   │   ├── icon_generator.dart          # Dart 图标生成器
│   │   └── README.md                    # 图标说明文档
│   └── splash/                          # 启动屏幕
│       ├── splash_icon.png              # 启动图标
│       └── README.md                    # 启动屏幕说明
│
├── build/                               # 构建输出目录
│   ├── .cxx/                            # C++ 构建缓存
│   ├── app/                             # 应用构建输出
│   │   ├── generated/                   # 生成的代码
│   │   ├── intermediates/               # 中间文件
│   │   ├── kotlin/                      # Kotlin 编译输出
│   │   ├── outputs/                     # 最终输出
│   │   └── tmp/                         # 临时文件
│   ├── connectivity_plus/               # 网络连接插件构建
│   ├── file_picker/                     # 文件选择器插件构建
│   ├── flutter_native_splash/           # 启动屏幕插件构建
│   ├── flutter_plugin_android_lifecycle/ # 生命周期插件构建
│   ├── flutter_secure_storage/          # 安全存储插件构建
│   ├── native_assets/                   # 原生资源
│   ├── path_provider_android/           # 路径提供者插件构建
│   ├── share_plus/                      # 分享插件构建
│   └── sqlite3_flutter_libs/            # SQLite 库构建
│
├── ios/                                 # iOS 平台代码
│   ├── Flutter/                         # Flutter iOS 配置
│   │   ├── ephemeral/                   # 临时文件
│   │   ├── flutter_export_environment.sh # 环境变量导出
│   │   └── Generated.xcconfig           # 生成的配置
│   ├── Runner/                          # iOS 应用
│   │   ├── GeneratedPluginRegistrant.h  # 插件注册头文件
│   │   ├── GeneratedPluginRegistrant.m  # 插件注册实现
│   │   └── Info.plist                   # 应用信息配置
│   └── SIGNING_SETUP.md                 # 签名设置说明
│
├── lib/                                 # Dart 源代码（主要应用代码）
│   ├── app/                             # 应用层
│   │   ├── l10n/                        # 国际化资源
│   │   ├── app.dart                     # 应用入口
│   │   ├── providers.dart               # 全局 Provider
│   │   ├── providers_dev.dart           # 开发环境 Provider
│   │   ├── PROVIDERS_README.md          # Provider 说明文档
│   │   ├── router.dart                  # 路由配置
│   │   ├── router_dev.dart              # 开发环境路由
│   │   ├── ROUTER_IMPLEMENTATION.md     # 路由实现说明
│   │   ├── theme.dart                   # 主题配置
│   │   ├── theme_providers.dart         # 主题 Provider
│   │   ├── THEME_AND_I18N_README.md     # 主题和国际化说明
│   │   ├── THEME_VISUAL_GUIDE.md        # 主题视觉指南
│   │   └── TASK_13_IMPLEMENTATION_SUMMARY.md # 任务实现总结
│   │
│   ├── core/                            # 核心功能
│   │   ├── crypto/                      # 加密功能
│   │   ├── network/                     # 网络功能
│   │   ├── security/                    # 安全功能
│   │   └── utils/                       # 工具类
│   │
│   ├── data/                            # 数据层
│   │   ├── export/                      # 导出功能
│   │   ├── import/                      # 导入功能
│   │   ├── local/                       # 本地数据存储
│   │   ├── remote/                      # 远程数据访问
│   │   └── sync/                        # 数据同步
│   │
│   ├── domain/                          # 领域层
│   │   ├── entities/                    # 实体类
│   │   └── repositories/                # 仓储接口
│   │
│   ├── features/                        # 功能模块
│   │   ├── auth/                        # 认证功能
│   │   ├── notes/                       # 笔记功能
│   │   ├── settings/                    # 设置功能
│   │   └── vault/                       # 保险库功能
│   │
│   ├── firebase_options.dart            # Firebase 配置
│   ├── main.dart                        # 生产环境入口
│   └── main_dev.dart                    # 开发环境入口
│
├── test/                                # 测试代码
│   ├── core/                            # 核心功能测试
│   │   ├── crypto/                      # 加密测试
│   │   └── utils/                       # 工具类测试
│   ├── data/                            # 数据层测试
│   │   ├── export/                      # 导出测试
│   │   ├── import/                      # 导入测试
│   │   ├── local/                       # 本地存储测试
│   │   └── sync/                        # 同步测试
│   ├── domain/                          # 领域层测试
│   │   └── entities/                    # 实体测试
│   ├── features/                        # 功能模块测试
│   │   ├── notes/                       # 笔记测试
│   │   └── vault/                       # 保险库测试
│   ├── integration/                     # 集成测试
│   │   ├── notes_flow_integration_test.dart        # 笔记流程测试
│   │   ├── offline_flow_integration_test.dart      # 离线流程测试
│   │   ├── offline_flow_integration_test.mocks.dart # 离线测试 Mock
│   │   ├── sync_flow_integration_test.dart         # 同步流程测试
│   │   ├── sync_flow_integration_test.mocks.dart   # 同步测试 Mock
│   │   └── vault_flow_integration_test.dart        # 保险库流程测试
│   └── widget_test.dart                 # Widget 测试
│
├── windows/                             # Windows 平台代码
│   ├── flutter/                         # Flutter Windows 配置
│   │   ├── ephemeral/                   # 临时文件
│   │   ├── CMakeLists.txt               # CMake 配置
│   │   ├── generated_plugin_registrant.cc  # 插件注册实现
│   │   ├── generated_plugin_registrant.h   # 插件注册头文件
│   │   └── generated_plugins.cmake      # 生成的插件配置
│   ├── runner/                          # Windows 应用
│   │   ├── resources/                   # 资源文件
│   │   ├── CMakeLists.txt               # CMake 配置
│   │   ├── flutter_window.cpp           # Flutter 窗口实现
│   │   ├── flutter_window.h             # Flutter 窗口头文件
│   │   ├── main.cpp                     # 主入口
│   │   ├── resource.h                   # 资源头文件
│   │   ├── runner.exe.manifest          # 应用清单
│   │   ├── Runner.rc                    # 资源脚本
│   │   ├── utils.cpp                    # 工具实现
│   │   ├── utils.h                      # 工具头文件
│   │   ├── win32_window.cpp             # Win32 窗口实现
│   │   └── win32_window.h               # Win32 窗口头文件
│   ├── .gitignore                       # Git 忽略配置
│   └── CMakeLists.txt                   # 主 CMake 配置
│
├── .flutter-plugins-dependencies        # Flutter 插件依赖
├── .gitignore                           # Git 忽略配置
├── .metadata                            # Flutter 元数据
├── analysis_options.yaml                # Dart 分析选项
├── build.yaml                           # 构建配置
├── encrypted_notebook.iml               # IntelliJ 模块配置
├── pubspec.yaml                         # Dart 包配置
├── pubspec.lock                         # 依赖锁定文件
│
├── build_local.bat                      # 本地构建脚本 (Windows)
├── build_release.bat                    # 发布构建脚本 (Windows)
├── build_release.sh                     # 发布构建脚本 (Unix)
├── setup_icons.bat                      # 图标设置脚本 (Windows)
├── setup_icons.sh                       # 图标设置脚本 (Unix)
├── update_version.bat                   # 版本更新脚本 (Windows)
├── update_version.sh                    # 版本更新脚本 (Unix)
│
├── firestore.rules                      # Firestore 安全规则
├── storage.rules                        # Firebase Storage 规则
│
├── SANB-v1.0.2.apk                      # 已构建的 APK 文件
│
└── 文档文件/                            # 项目文档
    ├── README.md                        # 项目说明
    ├── SETUP.md                         # 设置指南
    ├── PROJECT_STRUCTURE.md             # 项目结构说明
    ├── BUILD_RELEASE_GUIDE.md           # 发布构建指南
    ├── DEPLOYMENT_SUMMARY.md            # 部署总结
    ├── FIREBASE_SETUP.md                # Firebase 设置
    ├── GITHUB_RELEASE_GUIDE.md          # GitHub 发布指南
    ├── ICON_SPLASH_SETUP.md             # 图标和启动屏幕设置
    ├── LOCAL_BUILD_STATUS.md            # 本地构建状态
    ├── NAVIGATION_FIXES.md              # 导航修复说明
    ├── PACKAGE_NAME_CHANGE.md           # 包名更改说明
    ├── QUICK_RELEASE_GUIDE.md           # 快速发布指南
    ├── QUICK_START_ICONS.md             # 图标快速开始
    ├── RELEASE_CHECKLIST.md             # 发布检查清单
    ├── TESTING_GUIDE.md                 # 测试指南
    ├── TEST_STATUS_REPORT.md            # 测试状态报告
    ├── VAULT_SETUP_FIX.md               # 保险库设置修复
    ├── TASK_21_PERFORMANCE_OPTIMIZATION_SUMMARY.md  # 性能优化总结
    ├── TASK_22_THEME_I18N_SUMMARY.md    # 主题和国际化总结
    └── TASK_25_ICON_SPLASH_IMPLEMENTATION.md  # 图标和启动屏幕实现
```

## 架构说明

### 分层架构
项目采用清晰的分层架构：

1. **表现层 (Presentation Layer)** - `lib/features/`
   - 各功能模块的 UI 组件和页面
   - 使用 Riverpod 进行状态管理

2. **领域层 (Domain Layer)** - `lib/domain/`
   - 业务实体和仓储接口
   - 与具体实现无关的业务逻辑

3. **数据层 (Data Layer)** - `lib/data/`
   - 数据源实现（本地、远程）
   - 数据同步、导入导出功能

4. **核心层 (Core Layer)** - `lib/core/`
   - 加密、网络、安全等基础功能
   - 通用工具类

### 主要功能模块

#### 1. 认证 (Auth)
- 用户登录、注册
- 密码管理
- 生物识别认证

#### 2. 笔记 (Notes)
- 笔记创建、编辑、删除
- 端到端加密
- 富文本编辑

#### 3. 保险库 (Vault)
- 多保险库管理
- 保险库加密
- 访问控制

#### 4. 设置 (Settings)
- 应用配置
- 主题切换
- 语言设置

### 技术栈

#### 核心依赖
- **状态管理**: flutter_riverpod ^2.4.9
- **路由**: go_router ^13.0.0
- **本地数据库**: drift ^2.14.0, sqlite3_flutter_libs ^0.5.18
- **加密**: cryptography ^2.7.0, flutter_secure_storage ^9.0.0
- **国际化**: flutter_localizations, intl ^0.20.2

#### 工具依赖
- **文件操作**: file_picker ^8.0.0, path_provider ^2.1.1
- **分享**: share_plus ^7.2.1
- **网络检测**: connectivity_plus ^5.0.2
- **UUID**: uuid ^4.2.2

#### 开发工具
- **代码生成**: build_runner ^2.4.7, riverpod_generator ^2.3.9
- **测试**: mockito ^5.4.4
- **图标和启动屏幕**: flutter_launcher_icons ^0.13.1, flutter_native_splash ^2.3.8

### 平台支持
- ✅ Android
- ✅ iOS
- ✅ Windows
- 🔄 Web (待支持)
- 🔄 macOS (待支持)
- 🔄 Linux (待支持)

## 构建和部署

### 本地构建
```bash
# Windows
build_local.bat

# Unix/Linux/macOS
./build_release.sh
```

### 发布构建
```bash
# Windows
build_release.bat

# Unix/Linux/macOS
./build_release.sh
```

### 版本更新
```bash
# Windows
update_version.bat

# Unix/Linux/macOS
./update_version.sh
```

## 测试

项目包含完整的测试套件：
- 单元测试 (Unit Tests)
- Widget 测试 (Widget Tests)
- 集成测试 (Integration Tests)

详见 `TESTING_GUIDE.md` 和 `TEST_STATUS_REPORT.md`

## 文档

项目包含详细的文档，涵盖：
- 设置和配置
- 构建和部署
- 功能实现
- 测试指南
- 发布流程

所有文档均位于项目根目录，以 `.md` 结尾。

---

**最后更新**: 2024-11-22
**项目版本**: 1.0.2+3
