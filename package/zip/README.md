# Ziper

一个快速的文件压缩工具，提供简单易用的命令行界面。使用 Rust 语言开发，提供跨平台支持。

## 主要功能

- **文件压缩**：将文件或目录压缩为 ZIP 格式
- **灵活输出**：可指定输出文件名和路径
- **忽略模式**：支持使用 glob 模式忽略特定文件或目录
- **日志级别**：支持静默模式和详细模式

## 安装方法

### 从预编译二进制文件安装

1. 访问 [Releases](https://github.com/yourusername/development-tools/releases) 页面
2. 下载适合你操作系统和架构的 ziper 二进制文件
3. 将下载的文件放置在系统 PATH 环境变量包含的目录中

### 从源码构建

确保你已安装 [Rust](https://www.rust-lang.org/tools/install) 和 Cargo。

```bash
# 克隆仓库
git clone https://github.com/yourusername/development-tools.git
cd development-tools/package/zip

# 构建
cargo build --release

# 二进制文件将位于 target/release/ziper
```

## 使用说明

### 基本用法

```bash
# 基本用法：压缩目录为 [目录名].zip
ziper dist

# 指定输出文件
ziper dist output.zip

# 指定输出目录和文件名
ziper dist path/to/output.zip
```

### 使用忽略模式

你可以使用 `--ignore` 或 `-i` 选项指定要忽略的文件或目录模式，多个模式用逗号分隔：

```bash
# 忽略特定模式
ziper dist --ignore "node_modules,.git,*.zip"

# 使用短选项
ziper dist -i "node_modules,.git,*.zip"
```

### 控制输出详细程度

```bash
# 静默模式 - 不显示输出
ziper dist -q
ziper dist --quiet

# 详细模式 - 显示详细输出
ziper dist -v
ziper dist --verbose
```

### 查看帮助信息

```bash
# 显示帮助信息
ziper --help
```

## 示例输出

在正常模式下，ziper 会显示正在添加的文件：

```
Adding: dist/index.html
Adding: dist/css/style.css
Adding: dist/js/main.js
```

在详细模式下，会显示更多信息，包括忽略的文件：

```
[INFO] Adding: dist/index.html
[INFO] Ignoring: dist/node_modules/package.json
[INFO] Adding: dist/css/style.css
[WARN] Failed to access path: Permission denied
[INFO] Adding: dist/js/main.js
```

## 支持的忽略模式

ziper 使用 glob 模式来忽略文件和目录。以下是一些常用的模式示例：

- `node_modules` - 忽略所有名为 node_modules 的目录或文件
- `*.zip` - 忽略所有 .zip 文件
- `.git` - 忽略所有名为 .git 的目录或文件
- `dist/*.log` - 忽略 dist 目录下的所有 .log 文件

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](../../LICENSE) 文件。 
