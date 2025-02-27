#!/bin/bash

# 帮助信息
show_help() {
    echo "Ziper 安装工具"
    echo
    echo "用法："
    echo "  install.sh [选项]"
    echo
    echo "选项："
    echo "  --upgrade    升级到最新版本"
    echo "  --remove     卸载 Ziper"
    echo "  --help       显示此帮助信息"
}

# 获取当前版本
get_current_version() {
    if command -v ziper >/dev/null 2>&1; then
        ziper --version | cut -d' ' -f2
    else
        echo "未安装"
    fi
}

# 检测操作系统和架构
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# 将 x86_64 映射为 amd64
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
fi

# 获取最新版本
get_latest_version() {
    VERSION=$(curl -s https://api.github.com/repos/jwyGithub/development-tools/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$VERSION" ]; then
        VERSION="v0.1.0"
    fi
    echo "$VERSION"
}

# 获取用户的默认 shell 配置文件
get_shell_rc() {
    # 检测当前 shell
    local current_shell
    if [ -n "$ZSH_VERSION" ]; then
        current_shell="zsh"
    elif [ -n "$BASH_VERSION" ]; then
        current_shell="bash"
    else
        # 尝试从 /etc/passwd 获取默认 shell
        current_shell=$(basename "$(grep "^$USER:" /etc/passwd | cut -d: -f7)")
    fi

    # 根据 shell 类型返回对应的配置文件
    case "$current_shell" in
        "zsh")
            if [ -f "$HOME/.zshrc" ]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.zprofile"
            fi
            ;;
        "bash")
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        *)
            # 如果无法确定 shell 类型，返回空
            echo ""
            ;;
    esac
}

# 下载并安装
install_or_upgrade() {
    local FORCE=$1
    local CURRENT_VERSION=$(get_current_version)
    local LATEST_VERSION=$(get_latest_version)
    
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ "$FORCE" != "true" ]; then
        echo "已经是最新版本 ($LATEST_VERSION)"
        exit 0
    fi
    
    # 构建下载 URL
    BINARY_NAME="ziper-${OS}-${ARCH}"
    DOWNLOAD_URL="https://github.com/jwyGithub/development-tools/releases/download/${LATEST_VERSION}/${BINARY_NAME}"
    
    echo "正在下载 Ziper ${LATEST_VERSION} (${OS}-${ARCH})..."
    
    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    # 下载二进制文件
    if ! curl -sL "$DOWNLOAD_URL" -o ziper; then
        echo "下载失败！"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # 添加执行权限
    chmod +x ziper
    
    # 确定安装目录
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        echo "使用 sudo 安装到系统目录..."
        sudo mv ziper /usr/local/bin/
        INSTALL_PATH="/usr/local/bin/ziper"
    else
        INSTALL_DIR="/usr/local/bin"
        if [ -w "$INSTALL_DIR" ]; then
            mv ziper "$INSTALL_DIR/"
            INSTALL_PATH="$INSTALL_DIR/ziper"
        else
            INSTALL_DIR="$HOME/.local/bin"
            mkdir -p "$INSTALL_DIR"
            mv ziper "$INSTALL_DIR/"
            INSTALL_PATH="$INSTALL_DIR/ziper"
            
            if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
                # 获取对应的 shell 配置文件
                SHELL_RC=$(get_shell_rc)
                
                if [ -n "$SHELL_RC" ]; then
                    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
                    echo "已将 $INSTALL_DIR 添加到 PATH（将在下次登录时生效）"
                    echo "要立即生效，请运行: source $SHELL_RC"
                else
                    echo "警告：无法确定 shell 配置文件，请手动将 $INSTALL_DIR 添加到 PATH 中"
                fi
            fi
        fi
    fi
    
    # 清理临时目录
    cd && rm -rf "$TMP_DIR"
    
    if [ "$FORCE" = "true" ]; then
        echo "Ziper 已成功安装到 $INSTALL_PATH"
    else
        echo "Ziper 已成功升级到 $LATEST_VERSION"
    fi
    echo "使用 'ziper --help' 查看使用说明"
}

# 卸载函数
remove_ziper() {
    # 查找 ziper 安装位置
    ZIPER_PATH=$(command -v ziper)
    
    if [ -z "$ZIPER_PATH" ]; then
        echo "未找到 Ziper 安装"
        exit 1
    fi
    
    echo "找到 Ziper 安装位置: $ZIPER_PATH"
    
    # 删除二进制文件
    if [ -w "$(dirname "$ZIPER_PATH")" ]; then
        rm -f "$ZIPER_PATH"
    else
        sudo rm -f "$ZIPER_PATH"
    fi
    
    # 清理 PATH（如果在 .local/bin）
    if [[ "$ZIPER_PATH" == "$HOME/.local/bin/ziper" ]]; then
        # 获取对应的 shell 配置文件
        SHELL_RC=$(get_shell_rc)
        if [ -n "$SHELL_RC" ]; then
            sed -i.bak "/export PATH=\".*\/.local\/bin:\\\$PATH\"/d" "$SHELL_RC"
            rm -f "${SHELL_RC}.bak"
            echo "已从 $SHELL_RC 中移除 PATH 配置"
        fi
    fi
    
    echo "Ziper 已成功卸载"
}

# 主逻辑
case "$1" in
    --upgrade)
        install_or_upgrade "false"
        ;;
    --remove)
        remove_ziper
        ;;
    --help)
        show_help
        ;;
    "")
        install_or_upgrade "true"
        ;;
    *)
        echo "未知选项: $1"
        show_help
        exit 1
        ;;
esac 
