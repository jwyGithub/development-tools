# Giter

一个 Git 仓库管理工具，提供更直观的分支和标签管理功能。使用 Rust 语言开发，提供跨平台支持。

## 主要功能

- **分支管理**：以表格或列表形式显示分支信息
- **标签管理**：以表格或列表形式显示标签信息
- **筛选功能**：支持筛选本地和远程分支
- **代理支持**：支持设置 HTTP 代理，解决网络问题

## 安装方法

### 从预编译二进制文件安装

1. 访问 [Releases](https://github.com/yourusername/development-tools/releases) 页面
2. 下载适合你操作系统和架构的 giter 二进制文件
3. 将下载的文件放置在系统 PATH 环境变量包含的目录中

### 从源码构建

确保你已安装 [Rust](https://www.rust-lang.org/tools/install) 和 Cargo。

```bash
# 克隆仓库
git clone https://github.com/yourusername/development-tools.git
cd development-tools/package/git

# 构建
cargo build --release

# 二进制文件将位于 target/release/giter
```

## 使用说明

### 分支管理

```bash
# 查看当前目录的分支信息（默认以表格形式显示）
giter branch

# 查看指定目录的分支信息
giter branch -p /path/to/repo

# 以列表形式显示分支
giter branch --list
giter branch -l

# 以表格形式显示分支（默认）
giter branch --table
giter branch -t

# 只显示本地分支
giter branch --local

# 只显示远程分支
giter branch --remote
```

### 标签管理

```bash
# 查看标签（默认以表格形式显示）
giter tag

# 以列表形式显示标签
giter tag --list
giter tag -l

# 以表格形式显示标签（默认）
giter tag --table
giter tag -t
```

### 代理设置

如果你需要通过代理访问远程仓库，可以使用 `--proxy` 选项：

```bash
# 使用代理
giter --proxy=http://127.0.0.1:7890 branch

# 使用代理查看标签
giter --proxy=http://127.0.0.1:7890 tag
```

## 输出示例

### 分支表格显示

```
+---------------+---------------+----------------------------------+
| 分支名称      | 类型          | 最后提交                         |
+---------------+---------------+----------------------------------+
| main          | 本地/远程     | 更新 README.md (2 分钟前)        |
| feature/login | 本地          | 添加登录功能 (2 天前)            |
| dev           | 远程          | 修复 bug #123 (5 小时前)         |
+---------------+---------------+----------------------------------+
```

### 标签表格显示

```
+---------------+----------------------------------+------------------+
| 标签名称      | 提交 ID                          | 描述             |
+---------------+----------------------------------+------------------+
| v1.0.0        | a1b2c3d4e5f6g7h8i9j0            | 首次发布         |
| v1.1.0        | b2c3d4e5f6g7h8i9j0k1            | 添加新功能       |
+---------------+----------------------------------+------------------+
```

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](../../LICENSE) 文件。 
