@echo off
REM iOS QEMU 懒人包目录初始化脚本 (Windows版)

REM 设置路径
set "SCRIPT_DIR=%~dp0"
set "BASE_DIR=%SCRIPT_DIR%.."
set "LOG_FILE=%BASE_DIR%\logs\init.log"

REM 创建日志目录
if not exist "%BASE_DIR%\logs" mkdir "%BASE_DIR%\logs"

REM 记录开始时间
echo %date% %time% - 开始初始化目录结构... > "%LOG_FILE%"

REM 创建必要的目录
call :create_dir "%BASE_DIR%\firmware"    REM 存放固件文件
call :create_dir "%BASE_DIR%\images"      REM 存放镜像文件
call :create_dir "%BASE_DIR%\images\nand" REM 存放NAND镜像
call :create_dir "%BASE_DIR%\logs"        REM 存放日志文件
call :create_dir "%BASE_DIR%\tools"       REM 存放工具脚本
call :create_dir "%BASE_DIR%\config"      REM 存放配置文件
call :create_dir "%BASE_DIR%\config\user" REM 存放用户配置
call :create_dir "%BASE_DIR%\backups"     REM 存放备份文件

REM 创建默认配置文件
if not exist "%BASE_DIR%\config\user\qemu.conf" (
    REM 如果配置文件不存在，创建一个默认的
    echo # iOS QEMU 懒人包配置文件 > "%BASE_DIR%\config\user\qemu.conf"
    echo # 此文件包含QEMU模拟器的配置选项 >> "%BASE_DIR%\config\user\qemu.conf"
    echo. >> "%BASE_DIR%\config\user\qemu.conf"
    echo # CPU配置 >> "%BASE_DIR%\config\user\qemu.conf"
    echo CPU_MODEL=max >> "%BASE_DIR%\config\user\qemu.conf"
    echo. >> "%BASE_DIR%\config\user\qemu.conf"
    echo # 内存大小 >> "%BASE_DIR%\config\user\qemu.conf"
    echo MEMORY_SIZE=1G >> "%BASE_DIR%\config\user\qemu.conf"
    echo. >> "%BASE_DIR%\config\user\qemu.conf"
    echo # 加速选项 >> "%BASE_DIR%\config\user\qemu.conf"
    echo ACCEL_OPTIONS=tcg,thread=multi >> "%BASE_DIR%\config\user\qemu.conf"
    echo. >> "%BASE_DIR%\config\user\qemu.conf"
    echo # 显示类型 >> "%BASE_DIR%\config\user\qemu.conf"
    echo DISPLAY_TYPE=sdl >> "%BASE_DIR%\config\user\qemu.conf"
    echo. >> "%BASE_DIR%\config\user\qemu.conf"
    echo # 额外的QEMU命令行选项 >> "%BASE_DIR%\config\user\qemu.conf"
    echo ADDITIONAL_OPTIONS= >> "%BASE_DIR%\config\user\qemu.conf"
    
    echo %date% %time% - 创建默认配置文件: config\user\qemu.conf >> "%LOG_FILE%"
) else (
    echo %date% %time% - 配置文件已存在: config\user\qemu.conf >> "%LOG_FILE%"
)

echo %date% %time% - 目录结构初始化完成 >> "%LOG_FILE%"
exit /b 0

:create_dir
if not exist "%~1" (
    mkdir "%~1"
    echo %date% %time% - 创建目录: %~1 >> "%LOG_FILE%"
) else (
    echo %date% %time% - 目录已存在: %~1 >> "%LOG_FILE%"
)
exit /b 0