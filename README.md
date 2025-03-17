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

### 从预编译二进制文件安装

1. 访问 [Releases](https://github.com/yourusername/development-tools/releases) 页面
2. 下载适合你操作系统和架构的二进制文件
3. 将下载的文件放置在系统 PATH 环境变量包含的目录中

### 从源码构建

确保你已安装 [Rust](https://www.rust-lang.org/tools/install) 和 Cargo。

```bash
# 克隆仓库
git clone https://github.com/yourusername/development-tools.git
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
