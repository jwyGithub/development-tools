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
    # 获取用户的默认 shell
    local user_shell
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        user_shell=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
    else
        # Linux 和其他系统
        user_shell=$(getent passwd $USER | cut -d: -f7)
    fi
    
    # 如果无法获取默认 shell，则使用 $SHELL 环境变量
    if [ -z "$user_shell" ]; then
        user_shell="$SHELL"
    fi
    
    local shell_name=$(basename "$user_shell")
    echo "检测用户默认 shell: $shell_name" >&2
    
    case "$shell_name" in
        "zsh")
            # 按优先级检查 zsh 配置文件
            if [ -f "$HOME/.zshrc" ]; then
                echo "$HOME/.zshrc"
            elif [ -f "$HOME/.zprofile" ]; then
                echo "$HOME/.zprofile"
            elif [ -f "$HOME/.zshenv" ]; then
                echo "$HOME/.zshenv"
            else
                echo "$HOME/.profile"
            fi
            ;;
        "bash")
            # 按优先级检查 bash 配置文件
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.profile"
            fi
            ;;
        *)
            # 如果是其他 shell，使用通用的 .profile
            echo "$HOME/.profile"
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
    INSTALL_DIR="$HOME/.ziper"
    mkdir -p "$INSTALL_DIR/bin"
    mv ziper "$INSTALL_DIR/bin/"
    INSTALL_PATH="$INSTALL_DIR/bin/ziper"
    
    # 创建环境加载脚本
    cat > "$INSTALL_DIR/ziper.sh" << 'EOF'
# ziper
export ZIPER_DIR="$HOME/.ziper"
export PATH="$ZIPER_DIR/bin:$PATH"
EOF
    
    # 获取对应的 shell 配置文件
    SHELL_RC=$(get_shell_rc)
    
    if [ -n "$SHELL_RC" ]; then
        # 清理旧的配置
        sed -i.bak -e '/# ziper/d' \
                  -e '/\.ziper\/ziper\.sh/d' \
                  "$SHELL_RC"
        rm -f "${SHELL_RC}.bak"
        
        # 添加新的配置
        echo "[ -s \"\$HOME/.ziper/ziper.sh\" ] && . \"\$HOME/.ziper/ziper.sh\" # ziper" >> "$SHELL_RC"
        
        echo "已添加环境配置到 $SHELL_RC（将在下次登录时生效）"
        echo "要立即生效，请运行: source $SHELL_RC"
    else
        echo "警告：无法确定 shell 配置文件，请手动将以下内容添加到您的 shell 配置文件中："
        echo "[ -s \"\$HOME/.ziper/ziper.sh\" ] && . \"\$HOME/.ziper/ziper.sh\""
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
    # 检查 ziper 目录是否存在
    if [ ! -d "$HOME/.ziper" ]; then
        echo "未找到 Ziper 安装"
        exit 1
    fi
    
    echo "找到 Ziper 安装位置: $HOME/.ziper"
    
    # 删除 ziper 目录
    rm -rf "$HOME/.ziper"
    
    # 清理配置
    SHELL_RC=$(get_shell_rc)
    if [ -n "$SHELL_RC" ]; then
        sed -i.bak -e '/# ziper/d' \
                  -e '/\.ziper\/ziper\.sh/d' \
                  "$SHELL_RC"
        rm -f "${SHELL_RC}.bak"
        echo "已从 $SHELL_RC 中移除配置"
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
