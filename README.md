# Development Tools

这个仓库包含了一系列用于提高开发效率的命令行工具，使用 Rust 语言开发，提供跨平台支持。

## 工具列表

### [Giter](package/git/README.md)

一个 Git 仓库管理工具，提供更直观的分支和标签管理功能。

**主要功能：**
- 以表格或列表形式显示分支信息
- 以表格或列表形式显示标签信息
- 支持筛选本地和远程分支
- 支持代理设置，解决网络问题

[查看详细文档](package/git/README.md)

### [Ziper](package/zip/README.md)

一个快速的文件压缩工具，提供简单易用的命令行界面。

**主要功能：**
- 将文件或目录压缩为 ZIP 格式
- 支持指定输出文件名和路径
- 支持使用 glob 模式忽略特定文件或目录
- 支持静默模式和详细模式

[查看详细文档](package/zip/README.md)

## 安装方法

### Linux 和 macOS 安装

我们提供了一个便捷的安装脚本，有两种使用方式：

#### 方式一：通过管道执行脚本

通过管道执行脚本，可以选择安装特定的工具：

```bash
# 安装单个工具（例如只安装 ziper）
curl -fsSL https://raw.githubusercontent.com/jwyGithub/development-tools/refs/heads/main/scripts/install.sh | bash -s -- ziper

# 安装多个工具（例如同时安装 ziper 和 giter）
curl -fsSL https://raw.githubusercontent.com/jwyGithub/development-tools/refs/heads/main/scripts/install.sh | bash -s -- ziper giter

# 使用 wget 安装
wget -qO- https://raw.githubusercontent.com/jwyGithub/development-tools/refs/heads/main/scripts/install.sh | bash -s -- ziper
```

#### 方式二：交互式安装

下载脚本后交互式选择要安装的工具：

```bash
# 下载并执行脚本
curl -fsSL https://raw.githubusercontent.com/jwyGithub/development-tools/refs/heads/main/scripts/install.sh -o install.sh
chmod +x install.sh
./install.sh

# 或者直接克隆仓库并执行脚本
git clone https://github.com/jwyGithub/development-tools.git
cd development-tools
bash scripts/install.sh
```

### Windows 安装

我们为 Windows 用户提供了 PowerShell 安装脚本，同样支持两种安装方式：

#### 方式一：通过管道执行脚本

使用 PowerShell 执行以下命令，可自动安装工具：

```powershell
# 安装所有工具
iwr -useb https://raw.githubusercontent.com/jwyGithub/development-tools/refs/heads/main/scripts/install.ps1 | pwsh -Command -

# 安装特定工具（例如只安装 ziper）
iwr -useb https://raw.githubusercontent.com/jwyGithub/development-tools/refs/heads/main/scripts/install.ps1 | pwsh -Command - ziper

# 安装多个工具
iwr -useb https://raw.githubusercontent.com/jwyGithub/development-tools/refs/heads/main/scripts/install.ps1 | pwsh -Command - ziper giter
```

#### 方式二：交互式安装

下载脚本后交互式选择要安装的工具：

```powershell
# 下载并执行脚本
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jwyGithub/development-tools/refs/heads/main/scripts/install.ps1 -OutFile install.ps1
.\install.ps1

# 或者直接克隆仓库并执行脚本
git clone https://github.com/jwyGithub/development-tools.git
cd development-tools
.\scripts\install.ps1
```

安装脚本特性：
- 自动检测系统架构和操作系统
- 自动获取最新版本
- 下载适合你系统的二进制文件
- 配置环境变量
- 支持安装、升级和卸载工具

### 从预编译二进制文件安装

1. 访问 [Releases](https://github.com/jwyGithub/development-tools/releases) 页面
2. 下载适合你操作系统和架构的二进制文件
3. 将下载的文件放置在系统 PATH 环境变量包含的目录中

### 从源码构建

确保你已安装 [Rust](https://www.rust-lang.org/tools/install) 和 Cargo。

```bash
# 克隆仓库
git clone https://github.com/jwyGithub/development-tools.git
cd development-tools

# 构建 Giter
cd package/git
cargo build --release
# 二进制文件将位于 target/release/giter

# 构建 Ziper
cd ../zip
cargo build --release
# 二进制文件将位于 target/release/ziper
```

## 贡献指南

欢迎贡献代码、报告问题或提出新功能建议！

1. Fork 这个仓库
2. 创建你的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交你的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启一个 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](LICENSE) 文件。 
