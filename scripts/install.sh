#!/usr/bin/env bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 版本信息
VERSION="0.1.0"
REPO_URL="https://github.com/jwyGithub/development-tools"
TOOLS_DIR="${HOME}/.development-tools"
BIN_DIR="${TOOLS_DIR}/bin"
TOOLS=("ziper" "giter")

# 检测系统架构
detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  echo "x86_64" ;;
        aarch64) echo "aarch64" ;;
        arm64)   echo "aarch64" ;;
        *)       echo "不支持的架构: $arch" && exit 1 ;;
    esac
}

# 检测操作系统
detect_os() {
    local os
    os=$(uname -s)
    case "$os" in
        Darwin)  echo "apple-darwin" ;;
        Linux)   echo "unknown-linux-gnu" ;;
        *)       echo "不支持的操作系统: $os" && exit 1 ;;
    esac
}

# 检测 shell 配置文件
detect_shell_config() {
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
    
    case "$shell_name" in
        "zsh")
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
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.profile"
            fi
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# 下载工具
download_tool() {
    local tool=$1
    local version=$2
    local arch=$3
    local os_suffix=$4
    local target="${arch}-${os_suffix}"
    local binary_name="${tool}-${version}-${target}"
    
    # 修正下载 URL 格式：使用 zip-v0.1.0 格式的 tag
    local tag_name=""
    case "$tool" in
        "ziper") tag_name="zip-v${version}" ;;
        "giter") tag_name="git-v${version}" ;;
        *) echo -e "${RED}未知的工具: ${tool}${NC}" && exit 1 ;;
    esac
    
    local url="${REPO_URL}/releases/download/${tag_name}/${binary_name}"
    local download_path="${BIN_DIR}/${tool}-${version}"
    
    echo -e "${BLUE}下载 ${tool} ${version} for ${target}...${NC}"
    echo -e "${BLUE}下载 URL: ${url}${NC}"
    
    # 使用临时文件进行下载
    local temp_file=$(mktemp)
    if ! curl -L -f -o "$temp_file" "$url"; then
        rm -f "$temp_file"
        echo -e "${RED}下载失败：无法访问 $url${NC}"
        exit 1
    fi
    
    # 检查文件是否为二进制文件
    if ! file "$temp_file" | grep -q "executable" && ! file "$temp_file" | grep -q "binary"; then
        rm -f "$temp_file"
        echo -e "${RED}下载的文件不是有效的可执行文件${NC}"
        exit 1
    fi
    
    # 移动到最终位置
    mv "$temp_file" "$download_path"
    chmod +x "$download_path"
    
    # 创建或更新符号链接
    ln -sf "$download_path" "${BIN_DIR}/${tool}"
    
    # 验证安装
    if ! "${BIN_DIR}/${tool}" --version >/dev/null 2>&1; then
        echo -e "${RED}安装验证失败：工具无法正常执行${NC}"
        rm -f "$download_path" "${BIN_DIR}/${tool}"
        exit 1
    fi
}

# 配置环境变量
configure_path() {
    local config_file=$1
    local tools_profile="${TOOLS_DIR}/tools.sh"
    
    # 创建工具的环境配置文件
    cat > "$tools_profile" << EOF
# Development Tools 环境配置
export DEVELOPMENT_TOOLS_DIR="${TOOLS_DIR}"
export PATH="\${PATH}:${BIN_DIR}"
EOF
    
    # 在 shell 配置文件中添加对工具配置文件的引用
    local tools_source="[ -s \"$tools_profile\" ] && \\. \"$tools_profile\""
    if ! grep -q "Development Tools" "$config_file"; then
        echo -e "\n# Development Tools" >> "$config_file"
        echo "$tools_source" >> "$config_file"
        echo -e "${GREEN}已添加环境变量配置到 ${config_file}${NC}"
    fi
}

# 安装工具
install_tool() {
    local tool=$1
    local arch=$(detect_arch)
    local os_suffix=$(detect_os)
    
    # 创建必要的目录
    mkdir -p "$BIN_DIR"
    
    # 下载并安装工具
    download_tool "$tool" "$VERSION" "$arch" "$os_suffix"
    echo -e "${GREEN}${tool} 安装成功！${NC}"
}

# 卸载工具
uninstall_tool() {
    local tool=$1
    local tool_path="${BIN_DIR}/${tool}"
    local version_path="${BIN_DIR}/${tool}-${VERSION}"
    
    if [ -f "$tool_path" ] || [ -f "$version_path" ]; then
        rm -f "$tool_path" "$version_path"
        echo -e "${GREEN}${tool} 卸载成功！${NC}"
    else
        echo -e "${YELLOW}${tool} 未安装${NC}"
    fi
}

# 升级工具
upgrade_tool() {
    local tool=$1
    echo -e "${BLUE}升级 ${tool}...${NC}"
    uninstall_tool "$tool"
    install_tool "$tool"
}

# 主菜单
show_menu() {
    echo -e "${BLUE}Development Tools 安装脚本${NC}"
    echo "1) 安装工具"
    echo "2) 升级工具"
    echo "3) 卸载工具"
    echo "4) 退出"
    echo
    read -rp "请选择操作 [1-4]: " choice
    
    case $choice in
        1)
            echo -e "\n选择要安装的工具："
            echo "1) ziper"
            echo "2) giter"
            echo "3) 全部"
            read -rp "请选择 [1-3]: " tool_choice
            case $tool_choice in
                1) install_tool "ziper" ;;
                2) install_tool "giter" ;;
                3)
                    for tool in "${TOOLS[@]}"; do
                        install_tool "$tool"
                    done
                    ;;
                *) echo -e "${RED}无效的选择${NC}" ;;
            esac
            configure_path "$(detect_shell_config)"
            ;;
        2)
            echo -e "\n选择要升级的工具："
            echo "1) ziper"
            echo "2) giter"
            echo "3) 全部"
            read -rp "请选择 [1-3]: " tool_choice
            case $tool_choice in
                1) upgrade_tool "ziper" ;;
                2) upgrade_tool "giter" ;;
                3)
                    for tool in "${TOOLS[@]}"; do
                        upgrade_tool "$tool"
                    done
                    ;;
                *) echo -e "${RED}无效的选择${NC}" ;;
            esac
            ;;
        3)
            echo -e "\n选择要卸载的工具："
            echo "1) ziper"
            echo "2) giter"
            echo "3) 全部"
            read -rp "请选择 [1-3]: " tool_choice
            case $tool_choice in
                1) uninstall_tool "ziper" ;;
                2) uninstall_tool "giter" ;;
                3)
                    for tool in "${TOOLS[@]}"; do
                        uninstall_tool "$tool"
                    done
                    ;;
                *) echo -e "${RED}无效的选择${NC}" ;;
            esac
            ;;
        4)
            echo -e "${GREEN}感谢使用！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            ;;
    esac
}

# 主程序
main() {
    while true; do
        show_menu
        echo
    done
}

main
