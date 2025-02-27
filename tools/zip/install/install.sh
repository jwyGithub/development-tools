#!/bin/bash

# 检测操作系统和架构
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# 将 x86_64 映射为 amd64
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
fi

# 获取最新版本
VERSION=$(curl -s https://api.github.com/repos/jwyGithub/development-tools/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

# 如果没有找到版本，使用默认版本
if [ -z "$VERSION" ]; then
    VERSION="v0.1.0"
fi

# 构建下载 URL
BINARY_NAME="ziper-${OS}-${ARCH}"
DOWNLOAD_URL="https://github.com/jwyGithub/development-tools/releases/download/${VERSION}/${BINARY_NAME}"

echo "正在下载 Ziper ${VERSION} (${OS}-${ARCH})..."

# 创建临时目录
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# 下载二进制文件
if ! curl -sL "$DOWNLOAD_URL" -o ziper; then
    echo "下载失败！"
    exit 1
fi

# 添加执行权限
chmod +x ziper

# 确定安装目录
if [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
fi

# 移动二进制文件到安装目录
mv ziper "$INSTALL_DIR/"

# 清理临时目录
cd && rm -rf "$TMP_DIR"

echo "Ziper 已成功安装到 $INSTALL_DIR/ziper"

# 检查 PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "请将 $INSTALL_DIR 添加到您的 PATH 环境变量中"
    if [ "$INSTALL_DIR" = "$HOME/.local/bin" ]; then
        echo "您可以将以下行添加到 ~/.bashrc 或 ~/.zshrc 中："
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
fi

echo "安装完成！使用 'ziper --help' 查看使用说明" 
