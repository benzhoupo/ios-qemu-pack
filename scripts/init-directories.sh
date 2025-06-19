#!/bin/bash

# iOS QEMU 懒人包目录初始化脚本

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# 设置日志文件
LOG_FILE="$BASE_DIR/logs/init.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 创建目录函数
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        log "创建目录: $1"
    else
        log "目录已存在: $1"
    fi
}

# 主函数
main() {
    log "开始初始化目录结构..."
    
    # 创建必要的目录
    create_dir "$BASE_DIR/firmware"    # 存放固件文件
    create_dir "$BASE_DIR/images"      # 存放镜像文件
    create_dir "$BASE_DIR/images/nand" # 存放NAND镜像
    create_dir "$BASE_DIR/logs"        # 存放日志文件
    create_dir "$BASE_DIR/tools"       # 存放工具脚本
    create_dir "$BASE_DIR/config"      # 存放配置文件
    create_dir "$BASE_DIR/config/user" # 存放用户配置
    create_dir "$BASE_DIR/backups"     # 存放备份文件
    
    # 创建默认配置文件
    if [ ! -f "$BASE_DIR/config/user/qemu.conf" ]; then
        # 如果配置文件不存在，创建一个默认的
        cat > "$BASE_DIR/config/user/qemu.conf" << EOF
# iOS QEMU 懒人包配置文件
# 此文件包含QEMU模拟器的配置选项

# CPU配置
CPU_MODEL=max

# 内存大小
MEMORY_SIZE=1G

# 加速选项
ACCEL_OPTIONS=tcg,thread=multi

# 显示类型
DISPLAY_TYPE=sdl

# 额外的QEMU命令行选项
ADDITIONAL_OPTIONS=
EOF
        log "创建默认配置文件: config/user/qemu.conf"
    else
        log "配置文件已存在: config/user/qemu.conf"
    fi
    
    log "目录结构初始化完成"
    return 0
}

# 运行主函数
main "$@"
exit $?