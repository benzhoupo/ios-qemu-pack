@echo off
setlocal enabledelayedexpansion

REM iOS QEMU 懒人包启动脚本 (Windows版)

REM 设置路径
set "SCRIPT_DIR=%~dp0"
set "BASE_DIR=%SCRIPT_DIR%.."
set "LOG_FILE=%BASE_DIR%\logs\qemu.log"

REM 创建日志目录
if not exist "%BASE_DIR%\logs" mkdir "%BASE_DIR%\logs"

REM 记录开始时间
set START_TIME=%TIME%
echo %date% %time% - 开始启动QEMU模拟器... > "%LOG_FILE%"

echo iOS QEMU 懒人包启动脚本
echo =======================
echo.

REM 加载配置文件
call :info "加载配置文件..."
set "CONFIG_FILE=%BASE_DIR%\config\user\qemu.conf"

if not exist "%CONFIG_FILE%" (
    call :error "配置文件不存在: %CONFIG_FILE%"
    exit /b 1
)

REM 设置默认值
set "CPU_MODEL=max"
set "MEMORY_SIZE=1G"
set "ACCEL_OPTIONS=tcg,thread=multi"
set "DISPLAY_TYPE=sdl"
set "ADDITIONAL_OPTIONS="

REM 读取配置文件
for /f "tokens=1,2 delims==" %%a in (%CONFIG_FILE%) do (
    set "key=%%a"
    set "value=%%b"
    
    REM 忽略注释和空行
    echo !key! | findstr /r "^#" >nul
    if !ERRORLEVEL! NEQ 0 (
        if not "!key!"=="" (
            REM 去除空格
            set "key=!key: =!"
            set "value=!value: =!"
            
            if "!key!"=="CPU_MODEL" set "CPU_MODEL=!value!"
            if "!key!"=="MEMORY_SIZE" set "MEMORY_SIZE=!value!"
            if "!key!"=="ACCEL_OPTIONS" set "ACCEL_OPTIONS=!value!"
            if "!key!"=="DISPLAY_TYPE" set "DISPLAY_TYPE=!value!"
            if "!key!"=="SDL_WINDOW_SIZE" set "SDL_WINDOW_SIZE=!value!"
            if "!key!"=="SDL_WINDOW_POS" set "SDL_WINDOW_POS=!value!"
            if "!key!"=="AUDIO_DRIVER" set "AUDIO_DRIVER=!value!"
            if "!key!"=="USB_REDIRECT" set "USB_REDIRECT=!value!"
            if "!key!"=="NETWORK_ENABLE" set "NETWORK_ENABLE=!value!"
            if "!key!"=="DEBUG_LOG" set "DEBUG_LOG=!value!"
            if "!key!"=="PERF_STATS" set "PERF_STATS=!value!"
            if "!key!"=="ADDITIONAL_OPTIONS" set "ADDITIONAL_OPTIONS=!value!"
            if "!key!"=="KVM_ENABLE" set "KVM_ENABLE=!value!"
            if "!key!"=="HAXM_ENABLE" set "HAXM_ENABLE=!value!"
            if "!key!"=="HVF_ENABLE" set "HVF_ENABLE=!value!"
            if "!key!"=="WHPX_ENABLE" set "WHPX_ENABLE=!value!"
            if "!key!"=="MIGRATION_ENABLE" set "MIGRATION_ENABLE=!value!"
            if "!key!"=="SNAPSHOT_ENABLE" set "SNAPSHOT_ENABLE=!value!"
            if "!key!"=="REMOTE_DISPLAY" set "REMOTE_DISPLAY=!value!"
            if "!key!"=="REMOTE_DISPLAY_PORT" set "REMOTE_DISPLAY_PORT=!value!"
            if "!key!"=="SHARED_FOLDER" set "SHARED_FOLDER=!value!"
            if "!key!"=="SHARED_FOLDER_PATH" set "SHARED_FOLDER_PATH=!value!"
        )
    )
)

call :info "配置加载完成"
call :info "CPU模型: %CPU_MODEL%"
call :info "内存大小: %MEMORY_SIZE%"
call :info "加速选项: %ACCEL_OPTIONS%"
call :info "显示类型: %DISPLAY_TYPE%"

REM 检查必要文件
call :info "检查必要文件..."

REM 检查QEMU可执行文件
set "QEMU_BIN=%BASE_DIR%\qemu-ipod\build\qemu-system-arm.exe"
if not exist "%QEMU_BIN%" (
    call :error "QEMU可执行文件不存在: %QEMU_BIN%"
    exit /b 1
)

REM 检查固件文件
set "BOOTROM=%BASE_DIR%\firmware\bootrom_s5l8900"
if not exist "%BOOTROM%" (
    call :error "bootrom文件不存在: %BOOTROM%"
    exit /b 1
)

set "IBOOT=%BASE_DIR%\firmware\iboot.bin"
if not exist "%IBOOT%" (
    call :error "iboot文件不存在: %IBOOT%"
    exit /b 1
)

REM 检查镜像文件
set "NOR=%BASE_DIR%\images\nor.bin"
if not exist "%NOR%" (
    call :error "NOR闪存镜像不存在: %NOR%"
    exit /b 1
)

REM 检查NAND目录
set "NAND_DIR=%BASE_DIR%\images\nand"
if not exist "%NAND_DIR%" (
    call :error "NAND目录不存在: %NAND_DIR%"
    exit /b 1
)

REM 检查NAND目录是否为空
dir /b "%NAND_DIR%\*" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :warning "NAND目录为空: %NAND_DIR%"
)

call :success "所有必要文件检查通过"

REM 构建QEMU命令行
call :info "构建QEMU命令行..."

REM 基本命令
set "CMD=%QEMU_BIN%"

REM 机器类型
set "CMD=%CMD% -machine iPod-Touch"

REM CPU模型
set "CMD=%CMD% -cpu %CPU_MODEL%"

REM 内存大小
set "CMD=%CMD% -m %MEMORY_SIZE%"

REM 加速选项
set "CMD=%CMD% -accel %ACCEL_OPTIONS%"

REM 显示类型
set "CMD=%CMD% -display %DISPLAY_TYPE%"

REM SDL窗口大小
if defined SDL_WINDOW_SIZE (
    set "CMD=%CMD% -sdl-window-size %SDL_WINDOW_SIZE%"
)

REM SDL窗口位置
if defined SDL_WINDOW_POS (
    set "CMD=%CMD% -sdl-window-pos %SDL_WINDOW_POS%"
)

REM 音频驱动
if defined AUDIO_DRIVER (
    set "CMD=%CMD% -audio-driver %AUDIO_DRIVER%"
)

REM 固件文件
set "CMD=%CMD% -bios %BOOTROM%"
set "CMD=%CMD% -kernel %IBOOT%"

REM NOR闪存
set "CMD=%CMD% -drive file=%NOR%,format=raw,if=pflash,index=0"

REM NAND闪存
set "CMD=%CMD% -drive file=fat:rw:%NAND_DIR%,format=raw,if=mtd"

REM USB重定向
if "%USB_REDIRECT%"=="1" (
    set "CMD=%CMD% -usb -device usb-host"
)

REM 网络
if "%NETWORK_ENABLE%"=="1" (
    set "CMD=%CMD% -netdev user,id=net0 -device usb-net,netdev=net0"
)

REM 调试日志
if "%DEBUG_LOG%"=="1" (
    set "CMD=%CMD% -d unimp,guest_errors -D %BASE_DIR%\logs\qemu_debug.log"
)

REM 性能统计
if "%PERF_STATS%"=="1" (
    set "CMD=%CMD% -icount shift=0,align=off,sleep=on -rtc clock=vm"
)

REM HAXM加速
if "%HAXM_ENABLE%"=="1" (
    set "CMD=%CMD% -accel hax"
)

REM WHPX加速
if "%WHPX_ENABLE%"=="1" (
    set "CMD=%CMD% -accel whpx"
)

REM 实时迁移
if "%MIGRATION_ENABLE%"=="1" (
    set "CMD=%CMD% -incoming tcp:0:4444"
)

REM 快照
if "%SNAPSHOT_ENABLE%"=="1" (
    set "CMD=%CMD% -snapshot"
)

REM 远程显示
if "%REMOTE_DISPLAY%"=="1" (
    set "CMD=%CMD% -vnc :%REMOTE_DISPLAY_PORT%"
)

REM 共享文件夹
if "%SHARED_FOLDER%"=="1" (
    if defined SHARED_FOLDER_PATH (
        set "CMD=%CMD% -fsdev local,id=fsdev0,path=%SHARED_FOLDER_PATH%,security_model=none -device virtio-9p-device,fsdev=fsdev0,mount_tag=host_share"
    )
)

REM 额外选项
if defined ADDITIONAL_OPTIONS (
    set "CMD=%CMD% %ADDITIONAL_OPTIONS%"
)

call :info "QEMU命令行构建完成"

REM 启动QEMU
call :info "启动QEMU模拟器..."
echo %date% %time% - 执行命令: %CMD% >> "%LOG_FILE%"

REM 执行命令
%CMD%

REM 检查退出状态
set EXIT_CODE=%ERRORLEVEL%

REM 计算运行时间
set END_TIME=%TIME%
for /f "tokens=1-4 delims=:.," %%a in ("%START_TIME%") do set /a "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
for /f "tokens=1-4 delims=:.," %%a in ("%END_TIME%") do set /a "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
set /a elapsed=end-start
set /a hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100

if %EXIT_CODE% EQU 0 (
    call :success "QEMU模拟器正常退出"
    echo %date% %time% - 运行时间: %mm%分%ss%秒 >> "%LOG_FILE%"
) else (
    call :warning "QEMU模拟器异常退出，退出代码: %EXIT_CODE%"
    echo %date% %time% - 运行时间: %mm%分%ss%秒 >> "%LOG_FILE%"
    echo %date% %time% - 查看日志文件获取更多信息: %LOG_FILE% >> "%LOG_FILE%"
)

exit /b %EXIT_CODE%

:info
echo [94m[INFO][0m %~1
echo %date% %time% - INFO: %~1 >> "%LOG_FILE%"
goto :eof

:success
echo [92m[成功][0m %~1
echo %date% %time% - 成功: %~1 >> "%LOG_FILE%"
goto :eof

:warning
echo [93m[警告][0m %~1
echo %date% %time% - 警告: %~1 >> "%LOG_FILE%"
goto :eof

:error
echo [91m[错误][0m %~1
echo %date% %time% - 错误: %~1 >> "%LOG_FILE%"
goto :eof