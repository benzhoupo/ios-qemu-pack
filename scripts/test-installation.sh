#!/bin/bash

# iOS QEMU 懒人包安装测试脚本

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# 设置日志文件
LOG_FILE="$BASE_DIR/logs/test.log"
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
TESTS=0

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
    TESTS=$((TESTS+1))
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

# 测试目录结构
test_directories() {
    info "测试目录结构..."
    
    # 检查必要的目录
    REQUIRED_DIRS=(
        "$BASE_DIR/firmware"
        "$BASE_DIR/images"
        "$BASE_DIR/images/nand"
        "$BASE_DIR/logs"
        "$BASE_DIR/tools"
        "$BASE_DIR/config"
        "$BASE_DIR/config/user"
        "$BASE_DIR/backups"
        "$BASE_DIR/qemu-ipod"
        "$BASE_DIR/qemu-ipod/build"
    )
    
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            success "目录存在: $(basename "$dir")"
        else
            error "目录不存在: $(basename "$dir")"
        fi
    done
}

# 测试QEMU编译
test_qemu_build() {
    info "测试QEMU编译..."
    
    # 检查QEMU可执行文件
    if [ -f "$BASE_DIR/qemu-ipod/build/qemu-system-arm" ]; then
        # 检查文件权限
        if [ -x "$BASE_DIR/qemu-ipod/build/qemu-system-arm" ]; then
            success "QEMU可执行文件存在且具有执行权限"
            
            # 检查版本
            QEMU_VERSION=$("$BASE_DIR/qemu-ipod/build/qemu-system-arm" --version | head -n1)
            log "QEMU版本: $QEMU_VERSION"
            
            # 检查是否支持iPod-Touch机器类型
            if "$BASE_DIR/qemu-ipod/build/qemu-system-arm" -machine help | grep -q "iPod-Touch"; then
                success "QEMU支持iPod-Touch机器类型"
            else
                error "QEMU不支持iPod-Touch机器类型"
            fi
        else
            error "QEMU可执行文件存在但没有执行权限"
        fi
    else
        error "QEMU可执行文件不存在"
    fi
}

# 测试固件文件
test_firmware() {
    info "测试固件文件..."
    
    # 检查必要的固件文件
    if [ -f "$BASE_DIR/firmware/bootrom_s5l8900" ]; then
        success "bootrom文件存在"
        
        # 检查文件大小
        BOOTROM_SIZE=$(stat -c%s "$BASE_DIR/firmware/bootrom_s5l8900" 2>/dev/null || stat -f%z "$BASE_DIR/firmware/bootrom_s5l8900")
        if [ "$BOOTROM_SIZE" -gt 0 ]; then
            log "bootrom文件大小: $BOOTROM_SIZE 字节"
        else
            warning "bootrom文件大小为0"
        fi
    else
        error "bootrom文件不存在"
    fi
    
    if [ -f "$BASE_DIR/firmware/iboot.bin" ]; then
        success "iboot文件存在"
        
        # 检查文件大小
        IBOOT_SIZE=$(stat -c%s "$BASE_DIR/firmware/iboot.bin" 2>/dev/null || stat -f%z "$BASE_DIR/firmware/iboot.bin")
        if [ "$IBOOT_SIZE" -gt 0 ]; then
            log "iboot文件大小: $IBOOT_SIZE 字节"
        else
            warning "iboot文件大小为0"
        fi
    else
        error "iboot文件不存在"
    fi
}

# 测试镜像文件
test_images() {
    info "测试镜像文件..."
    
    # 检查NOR闪存镜像
    if [ -f "$BASE_DIR/images/nor.bin" ]; then
        success "NOR闪存镜像存在"
        
        # 检查文件大小
        NOR_SIZE=$(stat -c%s "$BASE_DIR/images/nor.bin" 2>/dev/null || stat -f%z "$BASE_DIR/images/nor.bin")
        if [ "$NOR_SIZE" -gt 0 ]; then
            log "NOR闪存镜像大小: $NOR_SIZE 字节"
        else
            warning "NOR闪存镜像大小为0"
        fi
    else
        error "NOR闪存镜像不存在"
    fi
    
    # 检查NAND目录
    if [ -d "$BASE_DIR/images/nand" ]; then
        # 检查NAND目录中的文件
        NAND_FILES=$(find "$BASE_DIR/images/nand" -type f | wc -l)
        if [ "$NAND_FILES" -gt 0 ]; then
            success "NAND目录包含 $NAND_FILES 个文件"
        else
            warning "NAND目录为空"
        fi
    else
        error "NAND目录不存在"
    fi
}

# 测试配置文件
test_config() {
    info "测试配置文件..."
    
    # 检查用户配置文件
    if [ -f "$BASE_DIR/config/user/qemu.conf" ]; then
        success "用户配置文件存在"
        
        # 检查配置文件内容
        if grep -q "CPU_MODEL" "$BASE_DIR/config/user/qemu.conf"; then
            log "配置文件包含CPU_MODEL设置"
        else
            warning "配置文件缺少CPU_MODEL设置"
        fi
    else
        error "用户配置文件不存在"
    fi
}

# 测试脚本权限
test_scripts() {
    info "测试脚本权限..."
    
    # 检查脚本文件
    SCRIPT_FILES=(
        "$BASE_DIR/scripts/init-directories.sh"
        "$BASE_DIR/scripts/check-environment.sh"
        "$BASE_DIR/scripts/start-qemu.sh"
        "$BASE_DIR/scripts/test-installation.sh"
        "$BASE_DIR/setup.sh"
    )
    
    for script in "${SCRIPT_FILES[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                success "脚本文件具有执行权限: $(basename "$script")"
            else
                warning "脚本文件缺少执行权限: $(basename "$script")"
                chmod +x "$script"
                log "已添加执行权限: $(basename "$script")"
            fi
        else
            error "脚本文件不存在: $(basename "$script")"
        fi
    done
}

# 测试SDL2
test_sdl2() {
    info "测试SDL2..."
    
    # 检查SDL2库
    if pkg-config --exists sdl2; then
        SDL_VERSION=$(pkg-config --modversion sdl2)
        success "找到SDL2库，版本: $SDL_VERSION"
    else
        error "未找到SDL2库"
    fi
}

# 主函数
main() {
    echo "iOS QEMU 懒人包安装测试"
    echo "======================="
    echo ""
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 运行测试
    test_directories
    test_qemu_build
    test_firmware
    test_images
    test_config
    test_scripts
    test_sdl2
    
    # 计算运行时间
    END_TIME=$(date +%s)
    RUNTIME=$((END_TIME - START_TIME))
    
    echo ""
    echo "======================="
    echo "测试摘要:"
    echo "通过: $TESTS"
    echo "警告: $WARNINGS"
    echo "失败: $ERRORS"
    echo "总用时: ${RUNTIME}秒"
    echo ""
    
    log "测试完成，通过: $TESTS，警告: $WARNINGS，失败: $ERRORS，总用时: ${RUNTIME}秒"
    
    if [ $ERRORS -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo -e "${GREEN}所有测试通过！${NC}"
            log "所有测试通过"
            return 0
        else
            echo -e "${YELLOW}测试完成，但有 $WARNINGS 个警告。${NC}"
            log "测试完成，有 $WARNINGS 个警告"
            return 0
        fi
    else
        echo -e "${RED}测试失败，发现 $ERRORS 个错误。${NC}"
        log "测试失败，发现 $ERRORS 个错误"
        return 1
    fi
}

# 运行主函数
main "$@"
exit $?