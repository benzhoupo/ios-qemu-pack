#!/bin/bash

# iOS QEMU 懒人包安装脚本

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"

# 设置日志文件
LOG_FILE="$BASE_DIR/logs/setup.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 日志函数
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

success() {
    echo -e "${GREEN}[成功]${NC} $1"
    log "成功: $1"
}

warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
    log "警告: $1"
}

error() {
    echo -e "${RED}[错误]${NC} $1" >&2
    log "错误: $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "未找到命令: $1"
        return 1
    fi
    return 0
}

# 检查系统
check_system() {
    info "检查系统环境..."
    
    # 检查操作系统
    OS=$(uname -s)
    log "操作系统: $OS"
    
    # 检查架构
    ARCH=$(uname -m)
    log "系统架构: $ARCH"
    
    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "arm64" ]; then
        error "不支持的系统架构: $ARCH。需要x86_64或arm64架构。"
        return 1
    fi
    
    # 检查必要的命令
    REQUIRED_COMMANDS=("git" "make" "gcc" "python3" "pip3" "pkg-config")
    MISSING_COMMANDS=0
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! check_command "$cmd"; then
            MISSING_COMMANDS=$((MISSING_COMMANDS+1))
        fi
    done
    
    if [ $MISSING_COMMANDS -gt 0 ]; then
        error "缺少必要的命令。请安装所需的依赖后重试。"
        
        if [ "$OS" = "Linux" ]; then
            if command -v apt-get &> /dev/null; then
                info "尝试运行: sudo apt-get update && sudo apt-get install git make gcc python3 python3-pip pkg-config libsdl2-dev"
            elif command -v dnf &> /dev/null; then
                info "尝试运行: sudo dnf install git make gcc python3 python3-pip pkgconfig SDL2-devel"
            elif command -v pacman &> /dev/null; then
                info "尝试运行: sudo pacman -S git make gcc python python-pip pkgconf sdl2"
            fi
        elif [ "$OS" = "Darwin" ]; then
            info "尝试运行: brew install git python pkg-config sdl2"
        fi
        
        return 1
    fi
    
    # 检查Python版本
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    log "Python版本: $PYTHON_VERSION"
    
    if [ $PYTHON_MAJOR -lt 3 ] || ([ $PYTHON_MAJOR -eq 3 ] && [ $PYTHON_MINOR -lt 6 ]); then
        error "Python版本过低。需要Python 3.6或更高版本，当前: $PYTHON_VERSION"
        return 1
    fi
    
    # 检查SDL2
    if ! pkg-config --exists sdl2; then
        error "未找到SDL2。请安装SDL2开发库后重试。"
        
        if [ "$OS" = "Linux" ]; then
            if command -v apt-get &> /dev/null; then
                info "尝试运行: sudo apt-get install libsdl2-dev"
            elif command -v dnf &> /dev/null; then
                info "尝试运行: sudo dnf install SDL2-devel"
            elif command -v pacman &> /dev/null; then
                info "尝试运行: sudo pacman -S sdl2"
            fi
        elif [ "$OS" = "Darwin" ]; then
            info "尝试运行: brew install sdl2"
        fi
        
        return 1
    fi
    
    success "系统环境检查通过"
    return 0
}

# 初始化目录结构
init_directories() {
    info "初始化目录结构..."
    
    # 确保脚本可执行
    chmod +x "$BASE_DIR/scripts/init-directories.sh"
    
    # 运行目录初始化脚本
    "$BASE_DIR/scripts/init-directories.sh"
    
    if [ $? -ne 0 ]; then
        error "目录初始化失败"
        return 1
    fi
    
    success "目录结构初始化完成"
    return 0
}

# 安装Python依赖
install_python_deps() {
    info "安装Python依赖..."
    
    # 安装meson和ninja
    pip3 install --user meson ninja
    
    if [ $? -ne 0 ]; then
        error "安装Python依赖失败"
        return 1
    fi
    
    success "Python依赖安装完成"
    return 0
}

# 克隆QEMU仓库
clone_qemu() {
    info "克隆QEMU仓库..."
    
    if [ -d "$BASE_DIR/qemu-ipod" ]; then
        info "QEMU仓库已存在，检查更新..."
        
        # 进入仓库目录
        cd "$BASE_DIR/qemu-ipod"
        
        # 检查是否是git仓库
        if [ -d ".git" ]; then
            # 获取远程更新
            git fetch
            
            # 检查是否有更新
            LOCAL=$(git rev-parse HEAD)
            REMOTE=$(git rev-parse @{u})
            
            if [ "$LOCAL" != "$REMOTE" ]; then
                info "发现更新，正在更新QEMU仓库..."
                git pull
                
                if [ $? -ne 0 ]; then
                    error "更新QEMU仓库失败"
                    return 1
                fi
                
                # 标记需要重新编译
                NEED_REBUILD=1
            else
                info "QEMU仓库已是最新版本"
            fi
        else
            warning "现有QEMU目录不是git仓库，将重新克隆"
            rm -rf "$BASE_DIR/qemu-ipod"
            
            # 克隆仓库
            git clone https://github.com/devos50/qemu-ipod.git "$BASE_DIR/qemu-ipod"
            
            if [ $? -ne 0 ]; then
                error "克隆QEMU仓库失败"
                return 1
            fi
            
            # 标记需要重新编译
            NEED_REBUILD=1
        fi
    else
        # 克隆仓库
        git clone https://github.com/devos50/qemu-ipod.git "$BASE_DIR/qemu-ipod"
        
        if [ $? -ne 0 ]; then
            error "克隆QEMU仓库失败"
            return 1
        fi
        
        # 标记需要重新编译
        NEED_REBUILD=1
    fi
    
    success "QEMU仓库准备完成"
    return 0
}

# 编译QEMU
build_qemu() {
    info "编译QEMU..."
    
    # 检查是否需要重新编译
    if [ -f "$BASE_DIR/qemu-ipod/build/qemu-system-arm" ] && [ "$NEED_REBUILD" != "1" ]; then
        info "QEMU已编译，跳过编译步骤"
        return 0
    fi
    
    # 创建构建目录
    mkdir -p "$BASE_DIR/qemu-ipod/build"
    cd "$BASE_DIR/qemu-ipod/build"
    
    # 配置构建
    ../configure --target-list=arm-softmmu --enable-sdl --disable-werror
    
    if [ $? -ne 0 ]; then
        error "QEMU配置失败"
        return 1
    fi
    
    # 编译
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)
    
    if [ $? -ne 0 ]; then
        error "QEMU编译失败"
        return 1
    fi
    
    success "QEMU编译完成"
    return 0
}

# 下载固件文件
download_firmware() {
    info "下载固件文件..."
    
    # 检查固件文件是否已存在
    if [ -f "$BASE_DIR/firmware/bootrom_s5l8900" ] && [ -f "$BASE_DIR/firmware/iboot.bin" ]; then
        info "固件文件已存在，跳过下载"
        return 0
    fi
    
    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    
    # 下载固件文件
    info "从GitHub下载固件文件..."
    
    # 使用curl下载
    curl -L -o "$TMP_DIR/firmware.zip" "https://github.com/devos50/qemu-ipod-files/archive/refs/heads/master.zip"
    
    if [ $? -ne 0 ]; then
        error "下载固件文件失败"
        rm -rf "$TMP_DIR"
        return 1
    fi
    
    # 解压文件
    unzip -q "$TMP_DIR/firmware.zip" -d "$TMP_DIR"
    
    if [ $? -ne 0 ]; then
        error "解压固件文件失败"
        rm -rf "$TMP_DIR"
        return 1
    fi
    
    # 复制固件文件
    cp "$TMP_DIR/qemu-ipod-files-master/bootrom_s5l8900" "$BASE_DIR/firmware/"
    cp "$TMP_DIR/qemu-ipod-files-master/iboot.bin" "$BASE_DIR/firmware/"
    
    # 复制镜像文件
    cp "$TMP_DIR/qemu-ipod-files-master/nor.bin" "$BASE_DIR/images/"
    
    # 复制NAND目录
    cp -r "$TMP_DIR/qemu-ipod-files-master/nand/"* "$BASE_DIR/images/nand/"
    
    # 清理临时文件
    rm -rf "$TMP_DIR"
    
    # 检查文件是否已复制
    if [ ! -f "$BASE_DIR/firmware/bootrom_s5l8900" ] || [ ! -f "$BASE_DIR/firmware/iboot.bin" ]; then
        error "固件文件复制失败"
        return 1
    fi
    
    success "固件文件下载完成"
    return 0
}

# 设置权限
set_permissions() {
    info "设置文件权限..."
    
    # 设置脚本可执行权限
    chmod +x "$BASE_DIR/scripts/"*.sh
    chmod +x "$BASE_DIR/setup.sh"
    
    success "文件权限设置完成"
    return 0
}

# 运行测试
run_test() {
    info "运行安装测试..."
    
    # 确保测试脚本可执行
    chmod +x "$BASE_DIR/scripts/test-installation.sh"
    
    # 运行测试脚本
    "$BASE_DIR/scripts/test-installation.sh"
    
    if [ $? -ne 0 ]; then
        error "安装测试失败"
        return 1
    fi
    
    success "安装测试通过"
    return 0
}

# 主函数
main() {
    echo "iOS QEMU 懒人包安装脚本"
    echo "======================="
    echo ""
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 初始化变量
    NEED_REBUILD=0
    
    # 检查系统
    check_system
    if [ $? -ne 0 ]; then
        error "系统检查失败，安装中止"
        exit 1
    fi
    
    # 初始化目录结构
    init_directories
    if [ $? -ne 0 ]; then
        error "目录初始化失败，安装中止"
        exit 1
    fi
    
    # 安装Python依赖
    install_python_deps
    if [ $? -ne 0 ]; then
        error "安装Python依赖失败，安装中止"
        exit 1
    fi
    
    # 克隆QEMU仓库
    clone_qemu
    if [ $? -ne 0 ]; then
        error "克隆QEMU仓库失败，安装中止"
        exit 1
    fi
    
    # 编译QEMU
    build_qemu
    if [ $? -ne 0 ]; then
        error "编译QEMU失败，安装中止"
        exit 1
    fi
    
    # 下载固件文件
    download_firmware
    if [ $? -ne 0 ]; then
        error "下载固件文件失败，安装中止"
        exit 1
    fi
    
    # 设置权限
    set_permissions
    if [ $? -ne 0 ]; then
        error "设置权限失败，安装中止"
        exit 1
    fi
    
    # 运行测试
    run_test
    if [ $? -ne 0 ]; then
        warning "安装测试失败，但安装过程可能已完成。请检查日志文件了解详情。"
    fi
    
    # 计算运行时间
    END_TIME=$(date +%s)
    RUNTIME=$((END_TIME - START_TIME))
    MINUTES=$((RUNTIME / 60))
    SECONDS=$((RUNTIME % 60))
    
    echo ""
    echo "======================="
    echo "安装完成！"
    echo "总用时: ${MINUTES}分${SECONDS}秒"
    echo ""
    echo "现在你可以运行以下命令启动模拟器："
    echo "  ./scripts/start-qemu.sh"
    echo ""
    echo "查看快速入门指南获取更多信息："
    echo "  less QUICKSTART.md"
    echo "======================="
    
    log "安装完成，总用时: ${MINUTES}分${SECONDS}秒"
    return 0
}

# 运行主函数
main "$@"
exit $?