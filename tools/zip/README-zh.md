# Ziper 压缩工具

使用 Rust 编写的快速压缩工具。

## 功能特性
- 快速压缩文件和目录
- 支持使用 glob 语法的忽略模式
- 自动创建输出目录
- 跨平台兼容
- 灵活的命令行界面
- 支持静默和详细输出模式

## 安装

### 快速安装

#### Unix系统 (macOS, Linux)
```bash
curl -sSL https://raw.githubusercontent.com/jwyGithub/development-tools/main/tools/zip/install/install.sh | bash
```

#### Windows系统 (PowerShell)
```powershell
irm https://raw.githubusercontent.com/jwyGithub/development-tools/main/tools/zip/install/install.ps1 | iex
```

### 从源码手动安装
```bash
# 克隆仓库
git clone https://github.com/jwyGithub/development-tools.git
cd development-tools/tools/zip

# 构建项目
cargo build --release

# 可选：全局安装
sudo cp target/release/ziper /usr/local/bin/  # Unix系统
# 或将可执行文件复制到 PATH 环境变量包含的目录中（Windows系统）
```

## 使用方法

```bash
# 基本用法 - 将目录压缩为 [目录名].zip
ziper dist

# 指定输出文件名
ziper dist output.zip

# 指定输出目录和文件名
ziper dist path/to/output.zip

# 忽略特定模式（支持glob语法）
ziper dist --ignore "node_modules,.git,*.zip,*.tar"

# 静默模式（不显示输出）
ziper dist -q

# 详细模式（显示详细输出）
ziper dist -v
```

### 命令行选项

```
用法：ziper [选项] <源路径> [输出路径]

参数：
  <源路径>   要压缩的源文件或目录
  [输出路径] 输出的zip文件路径（可选，默认为源名称加.zip后缀）

选项：
  -i, --ignore <模式>  要忽略的模式（逗号分隔）
  -q, --quiet         静默模式
  -v, --verbose      详细输出模式
  -h, --help        显示帮助
  -V, --version     显示版本
```

### 忽略模式
`--ignore` 选项接受逗号分隔的 glob 模式：
- `node_modules` - 忽略 node_modules 目录
- `.git` - 忽略 .git 目录
- `*.zip` - 忽略所有 zip 文件
- `*.tar` - 忽略所有 tar 文件

这些模式会应用于目录树中任何深度的文件和目录。

### 输出路径
- 如果未指定输出路径，在当前目录创建 `[源名称].zip`
- 如果指定了输出路径，在指定位置创建文件
- 自动创建输出路径中不存在的目录

## 开发

### 环境要求
- Rust 1.70 或更高版本
- Cargo (Rust 的包管理器)

### 从源码构建
```bash
cargo build        # 调试构建
cargo build --release  # 发布构建
```

### 运行测试
```bash
cargo test        # 运行所有测试
cargo test -- --nocapture  # 运行测试并显示输出
```

## 许可证
本项目采用 MIT 许可证 - 详见 [LICENSE](../../../LICENSE) 文件。 
