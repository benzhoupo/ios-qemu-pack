#!/bin/bash

# iOS QEMU 懒人包启动脚本

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# 设置日志文件
LOG_FILE="$BASE_DIR/logs/qemu.log"
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
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
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
    echo -e "${RED}[错误]${NC} $1"
    log "错误: $1"
    exit 1
}

# 加载配置文件
load_config() {
    CONFIG_FILE="$BASE_DIR/config/user/qemu.conf"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        error "配置文件不存在: $CONFIG_FILE"
    fi
    
    info "加载配置文件: $CONFIG_FILE"
    
    # 设置默认值
    CPU_MODEL="max"
    MEMORY_SIZE="1G"
    ACCEL_OPTIONS="tcg,thread=multi"
    DISPLAY_TYPE="sdl"
    ADDITIONAL_OPTIONS=""
    
    # 读取配置文件
    while IFS='=' read -r key value; do
        # 忽略注释和空行
        [[ $key =~ ^#.*$ || -z $key ]] && continue
        
        # 去除空格
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        case "$key" in
            CPU_MODEL)
                CPU_MODEL="$value"
                ;;
            MEMORY_SIZE)
                MEMORY_SIZE="$value"
                ;;
            ACCEL_OPTIONS)
                ACCEL_OPTIONS="$value"
                ;;
            DISPLAY_TYPE)
                DISPLAY_TYPE="$value"
                ;;
            SDL_WINDOW_SIZE)
                SDL_WINDOW_SIZE="$value"
                ;;
            SDL_WINDOW_POS)
                SDL_WINDOW_POS="$value"
                ;;
            AUDIO_DRIVER)
                AUDIO_DRIVER="$value"
                ;;
            USB_REDIRECT)
                USB_REDIRECT="$value"
                ;;
            NETWORK_ENABLE)
                NETWORK_ENABLE="$value"
                ;;
            DEBUG_LOG)
                DEBUG_LOG="$value"
                ;;
            PERF_STATS)
                PERF_STATS="$value"
                ;;
            ADDITIONAL_OPTIONS)
                ADDITIONAL_OPTIONS="$value"
                ;;
            KVM_ENABLE)
                KVM_ENABLE="$value"
                ;;
            HAXM_ENABLE)
                HAXM_ENABLE="$value"
                ;;
            HVF_ENABLE)
                HVF_ENABLE="$value"
                ;;
            WHPX_ENABLE)
                WHPX_ENABLE="$value"
                ;;
            MIGRATION_ENABLE)
                MIGRATION_ENABLE="$value"
                ;;
            SNAPSHOT_ENABLE)
                SNAPSHOT_ENABLE="$value"
                ;;
            REMOTE_DISPLAY)
                REMOTE_DISPLAY="$value"
                ;;
            REMOTE_DISPLAY_PORT)
                REMOTE_DISPLAY_PORT="$value"
                ;;
            SHARED_FOLDER)
                SHARED_FOLDER="$value"
                ;;
            SHARED_FOLDER_PATH)
                SHARED_FOLDER_PATH="$value"
                ;;
        esac
    done < "$CONFIG_FILE"
    
    info "配置加载完成"
    info "CPU模型: $CPU_MODEL"
    info "内存大小: $MEMORY_SIZE"
    info "加速选项: $ACCEL_OPTIONS"
    info "显示类型: $DISPLAY_TYPE"
}

# 检查必要文件
check_files() {
    info "检查必要文件..."
    
    # 检查QEMU可执行文件
    QEMU_BIN="$BASE_DIR/qemu-ipod/build/qemu-system-arm"
    if [ ! -f "$QEMU_BIN" ]; then
        error "QEMU可执行文件不存在: $QEMU_BIN"
    fi
    
    # 检查固件文件
    BOOTROM="$BASE_DIR/firmware/bootrom_s5l8900"
    if [ ! -f "$BOOTROM" ]; then
        error "bootrom文件不存在: $BOOTROM"
    fi
    
    IBOOT="$BASE_DIR/firmware/iboot.bin"
    if [ ! -f "$IBOOT" ]; then
        error "iboot文件不存在: $IBOOT"
    fi
    
    # 检查镜像文件
    NOR="$BASE_DIR/images/nor.bin"
    if [ ! -f "$NOR" ]; then
        error "NOR闪存镜像不存在: $NOR"
    fi
    
    # 检查NAND目录
    NAND_DIR="$BASE_DIR/images/nand"
    if [ ! -d "$NAND_DIR" ]; then
        error "NAND目录不存在: $NAND_DIR"
    fi
    
    # 检查NAND目录是否为空
    if [ -z "$(ls -A "$NAND_DIR")" ]; then
        warning "NAND目录为空: $NAND_DIR"
    fi
    
    success "所有必要文件检查通过"
}

# 构建QEMU命令行
build_command() {
    info "构建QEMU命令行..."
    
    # 基本命令
    CMD="$QEMU_BIN"
    
    # 机器类型
    CMD="$CMD -machine iPod-Touch"
    
    # CPU模型
    CMD="$CMD -cpu $CPU_MODEL"
    
    # 内存大小
    CMD="$CMD -m $MEMORY_SIZE"
    
    # 加速选项
    CMD="$CMD -accel $ACCEL_OPTIONS"
    
    # 显示类型
    CMD="$CMD -display $DISPLAY_TYPE"
    
    # SDL窗口大小
    if [ -n "$SDL_WINDOW_SIZE" ]; then
        CMD="$CMD -sdl-window-size $SDL_WINDOW_SIZE"
    fi
    
    # SDL窗口位置
    if [ -n "$SDL_WINDOW_POS" ]; then
        CMD="$CMD -sdl-window-pos $SDL_WINDOW_POS"
    fi
    
    # 音频驱动
    if [ -n "$AUDIO_DRIVER" ]; then
        CMD="$CMD -audio-driver $AUDIO_DRIVER"
    fi
    
    # 固件文件
    CMD="$CMD -bios $BOOTROM"
    CMD="$CMD -kernel $IBOOT"
    
    # NOR闪存
    CMD="$CMD -drive file=$NOR,format=raw,if=pflash,index=0"
    
    # NAND闪存
    CMD="$CMD -drive file=fat:rw:$NAND_DIR,format=raw,if=mtd"
    
    # USB重定向
    if [ "$USB_REDIRECT" = "1" ]; then
        CMD="$CMD -usb -device usb-host"
    fi
    
    # 网络
    if [ "$NETWORK_ENABLE" = "1" ]; then
        CMD="$CMD -netdev user,id=net0 -device usb-net,netdev=net0"
    fi
    
    # 调试日志
    if [ "$DEBUG_LOG" = "1" ]; then
        CMD="$CMD -d unimp,guest_errors -D $BASE_DIR/logs/qemu_debug.log"
    fi
    
    # 性能统计
    if [ "$PERF_STATS" = "1" ]; then
        CMD="$CMD -icount shift=0,align=off,sleep=on -rtc clock=vm"
    fi
    
    # KVM加速
    if [ "$KVM_ENABLE" = "1" ]; then
        CMD="$CMD -enable-kvm"
    fi
    
    # HAXM加速
    if [ "$HAXM_ENABLE" = "1" ]; then
        CMD="$CMD -accel hax"
    fi
    
    # HVF加速
    if [ "$HVF_ENABLE" = "1" ]; then
        CMD="$CMD -accel hvf"
    fi
    
    # WHPX加速
    if [ "$WHPX_ENABLE" = "1" ]; then
        CMD="$CMD -accel whpx"
    fi
    
    # 实时迁移
    if [ "$MIGRATION_ENABLE" = "1" ]; then
        CMD="$CMD -incoming tcp:0:4444"
    fi
    
    # 快照
    if [ "$SNAPSHOT_ENABLE" = "1" ]; then
        CMD="$CMD -snapshot"
    fi
    
    # 远程显示
    if [ "$REMOTE_DISPLAY" = "1" ]; then
        CMD="$CMD -vnc :$REMOTE_DISPLAY_PORT"
    fi
    
    # 共享文件夹
    if [ "$SHARED_FOLDER" = "1" ] && [ -n "$SHARED_FOLDER_PATH" ]; then
        CMD="$CMD -fsdev local,id=fsdev0,path=$SHARED_FOLDER_PATH,security_model=none -device virtio-9p-device,fsdev=fsdev0,mount_tag=host_share"
    fi
    
    # 额外选项
    if [ -n "$ADDITIONAL_OPTIONS" ]; then
        CMD="$CMD $ADDITIONAL_OPTIONS"
    fi
    
    info "QEMU命令行构建完成"
}

# 启动QEMU
start_qemu() {
    info "启动QEMU模拟器..."
    log "执行命令: $CMD"
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 执行命令
    eval "$CMD"
    
    # 检查退出状态
    EXIT_CODE=$?
    
    # 记录结束时间
    END_TIME=$(date +%s)
    RUNTIME=$((END_TIME - START_TIME))
    MINUTES=$((RUNTIME / 60))
    SECONDS=$((RUNTIME % 60))
    
    if [ $EXIT_CODE -eq 0 ]; then
        success "QEMU模拟器正常退出"
        log "运行时间: ${MINUTES}分${SECONDS}秒"
    else
        warning "QEMU模拟器异常退出，退出代码: $EXIT_CODE"
        log "运行时间: ${MINUTES}分${SECONDS}秒"
        log "查看日志文件获取更多信息: $LOG_FILE"
    fi
}

# 主函数
main() {
    echo "iOS QEMU 懒人包启动脚本"
    echo "======================="
    echo ""
    
    # 记录开始时间
    log "开始启动QEMU模拟器..."
    
    # 加载配置
    load_config
    
    # 检查文件
    check_files
    
    # 构建命令
    build_command
    
    # 启动QEMU
    start_qemu
    
    return $EXIT_CODE
}

# 运行主函数
main "$@"
exit $?