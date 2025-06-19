#!/bin/bash

# iOS QEMU 懒人包环境检查脚本

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# 设置日志文件
LOG_FILE="$BASE_DIR/logs/environment.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 初始化计数器
ERRORS=0
WARNINGS=0
PASSED=0

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

success() {
    echo -e "${GREEN}[通过]${NC} $1"
    log "通过: $1"
    PASSED=$((PASSED+1))
}

warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
    log "警告: $1"
    WARNINGS=$((WARNINGS+1))
}

error() {
    echo -e "${RED}[失败]${NC} $1"
    log "失败: $1"
    ERRORS=$((ERRORS+1))
}

# 检查命令是否存在
check_command() {
    if command -v "$1" &> /dev/null; then
        success "找到命令: $1 $(command -v "$1")"
        return 0
    else
        error "未找到命令: $1"
        return 1
    fi
}

# 检查Python版本
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d' ' -f2 | cut -d'.' -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d' ' -f2 | cut -d'.' -f2)
        
        success "找到Python: $PYTHON_VERSION"
        
        if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 6 ]); then
            warning "Python版本过低。推荐Python 3.6或更高版本。"
        fi
        
        # 检查pip
        if command -v pip3 &> /dev/null; then
            PIP_VERSION=$(pip3 --version 2>&1)
            success "找到pip: $PIP_VERSION"
            
            # 检查必要的Python包
            if pip3 show meson &> /dev/null; then
                MESON_VERSION=$(pip3 show meson | grep Version | cut -d' ' -f2)
                success "找到meson: $MESON_VERSION"
            else
                warning "未找到meson包。可能需要运行: pip3 install meson"
            fi
            
            if pip3 show ninja &> /dev/null; then
                NINJA_VERSION=$(pip3 show ninja | grep Version | cut -d' ' -f2)
                success "找到ninja: $NINJA_VERSION"
            else
                warning "未找到ninja包。可能需要运行: pip3 install ninja"
            fi
        else
            error "未找到pip3。请安装pip。"
        fi
    else
        error "未找到Python 3。请安装Python 3.6或更高版本。"
    fi
}

# 检查系统信息
check_system() {
    # 检查操作系统
    OS=$(uname -s)
    OS_VERSION=$(uname -r)
    success "操作系统: $OS $OS_VERSION"
    
    # 检查架构
    ARCH=$(uname -m)
    success "系统架构: $ARCH"
    
    # 检查内存
    if [ "$OS" = "Linux" ]; then
        MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
        success "系统内存: $MEM_TOTAL"
    elif [ "$OS" = "Darwin" ]; then
        MEM_TOTAL=$(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')
        success "系统内存: $MEM_TOTAL"
    fi
    
    # 检查磁盘空间
    DISK_FREE=$(df -h . | tail -1 | awk '{print $4}')
    success "可用磁盘空间: $DISK_FREE"
    
    # 检查CPU
    if [ "$OS" = "Linux" ]; then
        CPU_INFO=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^[ \t]*//')
        CPU_CORES=$(grep -c processor /proc/cpuinfo)
    elif [ "$OS" = "Darwin" ]; then
        CPU_INFO=$(sysctl -n machdep.cpu.brand_string)
        CPU_CORES=$(sysctl -n hw.ncpu)
    else
        CPU_INFO="未知"
        CPU_CORES="未知"
    fi
    success "CPU: $CPU_INFO ($CPU_CORES 核)"
}

# 检查SDL2
check_sdl2() {
    if pkg-config --exists sdl2; then
        SDL_VERSION=$(pkg-config --modversion sdl2)
        success "找到SDL2库: $SDL_VERSION"
        
        # 检查SDL2开发文件
        if [ -d "$(pkg-config --variable=includedir sdl2)/SDL2" ]; then
            success "找到SDL2开发文件"
        else
            warning "未找到SDL2开发文件。可能需要安装SDL2开发包。"
        fi
    else
        error "未找到SDL2库。请安装SDL2。"
        
        # 提供安装建议
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
    fi
}

# 检查编译工具
check_build_tools() {
    # 检查GCC/Clang
    if command -v gcc &> /dev/null; then
        GCC_VERSION=$(gcc --version | head -1)
        success "找到GCC: $GCC_VERSION"
    elif command -v clang &> /dev/null; then
        CLANG_VERSION=$(clang --version | head -1)
        success "找到Clang: $CLANG_VERSION"
    else
        error "未找到GCC或Clang。请安装编译器。"
    fi
    
    # 检查Make
    if command -v make &> /dev/null; then
        MAKE_VERSION=$(make --version | head -1)
        success "找到Make: $MAKE_VERSION"
    else
        error "未找到Make。请安装Make。"
    fi
    
    # 检查pkg-config
    if command -v pkg-config &> /dev/null; then
        PKG_CONFIG_VERSION=$(pkg-config --version)
        success "找到pkg-config: $PKG_CONFIG_VERSION"
    else
        error "未找到pkg-config。请安装pkg-config。"
    fi
}

# 检查QEMU依赖
check_qemu_deps() {
    # 检查常见的QEMU依赖
    DEPS=("zlib" "glib-2.0" "pixman-1")
    
    for dep in "${DEPS[@]}"; do
        if pkg-config --exists "$dep"; then
            DEP_VERSION=$(pkg-config --modversion "$dep")
            success "找到依赖: $dep $DEP_VERSION"
        else
            warning "未找到依赖: $dep"
        fi
    done
}

# 检查网络连接
check_network() {
    # 检查GitHub连接
    if ping -c 1 github.com &> /dev/null; then
        success "可以连接到GitHub"
    else
        warning "无法连接到GitHub。可能会影响下载固件和源码。"
    fi
}

# 主函数
main() {
    echo "iOS QEMU 懒人包环境检查"
    echo "======================="
    echo ""
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 运行检查
    info "检查系统信息..."
    check_system
    
    echo ""
    info "检查必要命令..."
    check_command "git"
    check_command "curl"
    check_command "unzip"
    
    echo ""
    info "检查Python环境..."
    check_python
    
    echo ""
    info "检查编译工具..."
    check_build_tools
    
    echo ""
    info "检查SDL2库..."
    check_sdl2
    
    echo ""
    info "检查QEMU依赖..."
    check_qemu_deps
    
    echo ""
    info "检查网络连接..."
    check_network
    
    # 计算运行时间
    END_TIME=$(date +%s)
    RUNTIME=$((END_TIME - START_TIME))
    
    echo ""
    echo "======================="
    echo "检查摘要:"
    echo "通过: $PASSED"
    echo "警告: $WARNINGS"
    echo "失败: $ERRORS"
    echo "总用时: ${RUNTIME}秒"
    echo ""
    
    log "检查完成，通过: $PASSED，警告: $WARNINGS，失败: $ERRORS，总用时: ${RUNTIME}秒"
    
    if [ $ERRORS -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo -e "${GREEN}环境检查通过！系统满足所有要求。${NC}"
            log "环境检查通过！系统满足所有要求。"
            return 0
        else
            echo -e "${YELLOW}环境检查通过，但有 $WARNINGS 个警告。可能需要安装一些可选组件。${NC}"
            log "环境检查通过，但有 $WARNINGS 个警告。"
            return 0
        fi
    else
        echo -e "${RED}环境检查失败，发现 $ERRORS 个错误。请解决这些问题后重试。${NC}"
        log "环境检查失败，发现 $ERRORS 个错误。"
        return 1
    fi
}

# 运行主函数
main "$@"
exit $?