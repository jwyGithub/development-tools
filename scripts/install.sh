#!/usr/bin/env bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 版本信息
DEFAULT_VERSION="0.1.1"
REPO_URL="https://github.com/jwyGithub/development-tools"
TOOLS_DIR="${HOME}/.development-tools"
BIN_DIR="${TOOLS_DIR}/bin"
TOOLS=("ziper" "giter")

# 获取最新版本
get_latest_version() {
    local tool=$1
    local tag_prefix=""
    
    case "$tool" in
        "ziper") tag_prefix="zip-v" ;;
        "giter") tag_prefix="git-v" ;;
        *) echo -e "${RED}未知的工具: ${tool}${NC}" >&2 && exit 1 ;;
    esac
    
    echo -e "${BLUE}正在获取 ${tool} 的最新版本...${NC}" >&2
    
    # 尝试从GitHub API获取最新版本
    local latest_version=""
    if command -v curl &> /dev/null; then
        latest_version=$(curl -s "https://api.github.com/repos/jwyGithub/development-tools/releases" | 
                         grep -o "\"tag_name\": \"$tag_prefix[0-9.]*\"" | 
                         head -n 1 | 
                         sed -E "s/\"tag_name\": \"$tag_prefix([0-9.]*)\"/\1/")
    fi
    
    # 如果无法获取最新版本，使用默认版本
    if [ -z "$latest_version" ]; then
        echo -e "${YELLOW}无法获取最新版本，使用默认版本 ${DEFAULT_VERSION}${NC}" >&2
        echo "$DEFAULT_VERSION"
    else
        echo -e "${GREEN}找到最新版本: ${latest_version}${NC}" >&2
        echo "$latest_version"
    fi
}

# 检测是否为交互式终端
is_interactive() {
    [ -t 0 ] && [ -t 1 ]
}

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
    
    # 构建下载 URL 和 tag 名称
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
    
    # 删除旧的符号链接（如果存在）
    if [ -L "${BIN_DIR}/${tool}" ]; then
        rm -f "${BIN_DIR}/${tool}"
    fi
    
    # 创建新的符号链接
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
    
    # 获取最新版本
    local version=$(get_latest_version "$tool")
    
    # 创建必要的目录
    mkdir -p "$BIN_DIR"
    
    # 下载并安装工具
    download_tool "$tool" "$version" "$arch" "$os_suffix"
    echo -e "${GREEN}${tool} ${version} 安装成功！${NC}"
}

# 卸载工具
uninstall_tool() {
    local tool=$1
    
    # 查找工具的所有版本
    local tool_paths=("${BIN_DIR}/${tool}" "${BIN_DIR}/${tool}-"*)
    
    local found=false
    for path in "${tool_paths[@]}"; do
        if [ -f "$path" ] || [ -L "$path" ]; then
            rm -f "$path"
            found=true
        fi
    done
    
    if [ "$found" = true ]; then
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

# 安装所有工具（非交互式模式）
install_all_tools() {
    echo -e "${BLUE}正在安装所有工具...${NC}"
    for tool in "${TOOLS[@]}"; do
        install_tool "$tool"
    done
    configure_path "$(detect_shell_config)"
    echo -e "${GREEN}所有工具安装完成！${NC}"
    echo -e "${YELLOW}请重新打开终端或运行 'source $(detect_shell_config)' 以使环境变量生效${NC}"
}

# 非交互式安装指定工具
install_specific_tools() {
    local tools_to_install=("$@")
    
    if [ ${#tools_to_install[@]} -eq 0 ]; then
        echo -e "${RED}错误：未指定要安装的工具${NC}"
        echo -e "${YELLOW}可用的工具: ${TOOLS[*]}${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}正在安装指定的工具...${NC}"
    for tool in "${tools_to_install[@]}"; do
        # 检查工具是否在支持的列表中
        if [[ " ${TOOLS[*]} " == *" $tool "* ]]; then
            install_tool "$tool"
        else
            echo -e "${RED}错误：不支持的工具 '$tool'${NC}"
            echo -e "${YELLOW}可用的工具: ${TOOLS[*]}${NC}"
            exit 1
        fi
    done
    
    configure_path "$(detect_shell_config)"
    echo -e "${GREEN}指定的工具安装完成！${NC}"
    echo -e "${YELLOW}请重新打开终端或运行 'source $(detect_shell_config)' 以使环境变量生效${NC}"
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
    # 检查是否为交互式终端
    if is_interactive; then
        # 交互式模式
        while true; do
            show_menu
            echo
        done
    else
        # 非交互式模式（通过管道执行）
        # 检查是否有命令行参数
        if [ $# -gt 0 ]; then
            install_specific_tools "$@"
        else
            # 提示用户需要指定工具
            echo -e "${YELLOW}请指定要安装的工具${NC}"
            echo -e "${YELLOW}可用的工具: ${TOOLS[*]}${NC}"
            echo -e "${YELLOW}示例: curl -fsSL URL | bash -s -- ziper${NC}"
            exit 1
        fi
    fi
}

# 如果脚本是通过管道执行的，则传递所有参数给main函数
# 或者如果脚本是直接执行的（不是被source的）
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if ! is_interactive; then
        main "$@"
    else
        main
    fi
fi
