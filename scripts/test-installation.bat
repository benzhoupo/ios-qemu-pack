@echo off
REM iOS QEMU 懒人包安装测试脚本 (Windows版)

REM 设置路径
set "SCRIPT_DIR=%~dp0"
set "BASE_DIR=%SCRIPT_DIR%.."
set "LOG_FILE=%BASE_DIR%\logs\test.log"

REM 创建日志目录
if not exist "%BASE_DIR%\logs" mkdir "%BASE_DIR%\logs"

REM 初始化计数器
set ERRORS=0
set WARNINGS=0
set TESTS=0

REM 记录开始时间
echo %date% %time% - 开始安装测试... > "%LOG_FILE%"

echo iOS QEMU 懒人包安装测试
echo =======================
echo.

REM 测试目录结构
echo 测试目录结构...
echo %date% %time% - 测试目录结构... >> "%LOG_FILE%"

REM 检查必要的目录
set "DIRS=firmware images images\nand logs tools config config\user backups qemu-ipod qemu-ipod\build"
for %%d in (%DIRS%) do (
    if exist "%BASE_DIR%\%%d" (
        call :success "目录存在: %%d"
    ) else (
        call :error "目录不存在: %%d"
    )
)

REM 测试QEMU编译
echo 测试QEMU编译...
echo %date% %time% - 测试QEMU编译... >> "%LOG_FILE%"

if exist "%BASE_DIR%\qemu-ipod\build\qemu-system-arm.exe" (
    call :success "QEMU可执行文件存在"
    
    REM 检查QEMU版本
    "%BASE_DIR%\qemu-ipod\build\qemu-system-arm.exe" --version > "%TEMP%\qemu_version.txt" 2>&1
    if %ERRORLEVEL% EQU 0 (
        set /p QEMU_VERSION=<"%TEMP%\qemu_version.txt"
        echo %date% %time% - QEMU版本: %QEMU_VERSION% >> "%LOG_FILE%"
        
        REM 检查iPod-Touch机器类型支持
        "%BASE_DIR%\qemu-ipod\build\qemu-system-arm.exe" -machine help > "%TEMP%\qemu_machines.txt" 2>&1
        findstr /C:"iPod-Touch" "%TEMP%\qemu_machines.txt" >nul
        if %ERRORLEVEL% EQU 0 (
            call :success "QEMU支持iPod-Touch机器类型"
        ) else (
            call :error "QEMU不支持iPod-Touch机器类型"
        )
    ) else (
        call :error "无法获取QEMU版本信息"
    )
) else (
    call :error "QEMU可执行文件不存在"
)

REM 测试固件文件
echo 测试固件文件...
echo %date% %time% - 测试固件文件... >> "%LOG_FILE%"

if exist "%BASE_DIR%\firmware\bootrom_s5l8900" (
    call :success "bootrom文件存在"
    
    REM 检查文件大小
    for %%A in ("%BASE_DIR%\firmware\bootrom_s5l8900") do set BOOTROM_SIZE=%%~zA
    if !BOOTROM_SIZE! GTR 0 (
        echo %date% %time% - bootrom文件大小: !BOOTROM_SIZE! 字节 >> "%LOG_FILE%"
    ) else (
        call :warning "bootrom文件大小为0"
    )
) else (
    call :error "bootrom文件不存在"
)

if exist "%BASE_DIR%\firmware\iboot.bin" (
    call :success "iboot文件存在"
    
    REM 检查文件大小
    for %%A in ("%BASE_DIR%\firmware\iboot.bin") do set IBOOT_SIZE=%%~zA
    if !IBOOT_SIZE! GTR 0 (
        echo %date% %time% - iboot文件大小: !IBOOT_SIZE! 字节 >> "%LOG_FILE%"
    ) else (
        call :warning "iboot文件大小为0"
    )
) else (
    call :error "iboot文件不存在"
)

REM 测试镜像文件
echo 测试镜像文件...
echo %date% %time% - 测试镜像文件... >> "%LOG_FILE%"

if exist "%BASE_DIR%\images\nor.bin" (
    call :success "NOR闪存镜像存在"
    
    REM 检查文件大小
    for %%A in ("%BASE_DIR%\images\nor.bin") do set NOR_SIZE=%%~zA
    if !NOR_SIZE! GTR 0 (
        echo %date% %time% - NOR闪存镜像大小: !NOR_SIZE! 字节 >> "%LOG_FILE%"
    ) else (
        call :warning "NOR闪存镜像大小为0"
    )
) else (
    call :error "NOR闪存镜像不存在"
)

if exist "%BASE_DIR%\images\nand" (
    REM 检查NAND目录中的文件数量
    dir /b /a-d "%BASE_DIR%\images\nand\*" 2>nul | find /v /c "" > "%TEMP%\nand_files.txt"
    set /p NAND_FILES=<"%TEMP%\nand_files.txt"
    if !NAND_FILES! GTR 0 (
        call :success "NAND目录包含 !NAND_FILES! 个文件"
    ) else (
        call :warning "NAND目录为空"
    )
) else (
    call :error "NAND目录不存在"
)

REM 测试配置文件
echo 测试配置文件...
echo %date% %time% - 测试配置文件... >> "%LOG_FILE%"

if exist "%BASE_DIR%\config\user\qemu.conf" (
    call :success "用户配置文件存在"
    
    REM 检查配置文件内容
    findstr /C:"CPU_MODEL" "%BASE_DIR%\config\user\qemu.conf" >nul
    if %ERRORLEVEL% EQU 0 (
        echo %date% %time% - 配置文件包含CPU_MODEL设置 >> "%LOG_FILE%"
    ) else (
        call :warning "配置文件缺少CPU_MODEL设置"
    )
) else (
    call :error "用户配置文件不存在"
)

REM 测试脚本文件
echo 测试脚本文件...
echo %date% %time% - 测试脚本文件... >> "%LOG_FILE%"

set "SCRIPTS=init-directories.bat check-environment.bat start-qemu.bat test-installation.bat"
for %%s in (%SCRIPTS%) do (
    if exist "%BASE_DIR%\scripts\%%s" (
        call :success "脚本文件存在: %%s"
    ) else (
        call :error "脚本文件不存在: %%s"
    )
)

REM 测试SDL2
echo 测试SDL2...
echo %date% %time% - 测试SDL2... >> "%LOG_FILE%"

if exist "C:\msys64\mingw64\bin\SDL2.dll" (
    call :success "找到SDL2库"
) else (
    where SDL2.dll >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        call :success "找到SDL2库"
    ) else (
        call :error "未找到SDL2库"
    )
)

REM 显示测试结果
echo.
echo =======================
echo 测试摘要:
echo 通过: %TESTS%
echo 警告: %WARNINGS%
echo 失败: %ERRORS%
echo.

echo %date% %time% - 测试完成，通过: %TESTS%，警告: %WARNINGS%，失败: %ERRORS% >> "%LOG_FILE%"

if %ERRORS% EQU 0 (
    if %WARNINGS% EQU 0 (
        echo [92m所有测试通过！[0m
        echo %date% %time% - 所有测试通过 >> "%LOG_FILE%"
        exit /b 0
    ) else (
        echo [93m测试完成，但有 %WARNINGS% 个警告。[0m
        echo %date% %time% - 测试完成，有 %WARNINGS% 个警告 >> "%LOG_FILE%"
        exit /b 0
    )
) else (
    echo [91m测试失败，发现 %ERRORS% 个错误。[0m
    echo %date% %time% - 测试失败，发现 %ERRORS% 个错误 >> "%LOG_FILE%"
    exit /b 1
)

:success
echo [92m✓[0m %~1
echo %date% %time% - 通过: %~1 >> "%LOG_FILE%"
set /a TESTS+=1
goto :eof

:warning
echo [93m![0m %~1
echo %date% %time% - 警告: %~1 >> "%LOG_FILE%"
set /a WARNINGS+=1
goto :eof

:error
echo [91m×[0m %~1
echo %date% %time% - 失败: %~1 >> "%LOG_FILE%"
set /a ERRORS+=1
goto :eof