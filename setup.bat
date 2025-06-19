@echo off
REM iOS QEMU 懒人包安装脚本 (Windows版)

REM 设置路径
set "SCRIPT_DIR=%~dp0"
set "BASE_DIR=%SCRIPT_DIR%"
set "LOG_FILE=%BASE_DIR%logs\setup.log"

REM 创建日志目录
if not exist "%BASE_DIR%logs" mkdir "%BASE_DIR%logs"

REM 记录开始时间
set START_TIME=%TIME%

REM 初始化变量
set NEED_REBUILD=0
set ERRORS=0
set WARNINGS=0

echo iOS QEMU 懒人包安装脚本
echo =======================
echo.

REM 记录开始时间
echo %date% %time% - 开始安装... > "%LOG_FILE%"

REM 检查系统
echo 检查系统环境...
echo %date% %time% - 检查系统环境... >> "%LOG_FILE%"

REM 检查Windows版本
powershell -command "& {$os = Get-WmiObject -Class Win32_OperatingSystem; Write-Output $os.Caption; Write-Output $os.Version}" > "%TEMP%\os_info.txt"
set /p OS_NAME=<"%TEMP%\os_info.txt"
echo 操作系统: %OS_NAME%
echo %date% %time% - 操作系统: %OS_NAME% >> "%LOG_FILE%"

REM 检查系统架构
powershell -command "& {$arch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture; Write-Output $arch}" > "%TEMP%\arch_info.txt"
set /p ARCH=<"%TEMP%\arch_info.txt"
echo 系统架构: %ARCH%
echo %date% %time% - 系统架构: %ARCH% >> "%LOG_FILE%"

if not "%ARCH%"=="64-bit" (
    echo 错误: 不支持的系统架构: %ARCH%。需要64位系统。
    echo %date% %time% - 错误: 不支持的系统架构: %ARCH% >> "%LOG_FILE%"
    exit /b 1
)

REM 检查MSYS2
echo 检查MSYS2...
echo %date% %time% - 检查MSYS2... >> "%LOG_FILE%"

where msys2 >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo MSYS2已安装
) else (
    if exist "C:\msys64\mingw64\bin" (
        echo MSYS2已安装但未添加到PATH
        echo 添加MSYS2到系统PATH...
        setx PATH "%PATH%;C:\msys64\mingw64\bin"
        set "PATH=%PATH%;C:\msys64\mingw64\bin"
    ) else (
        echo 错误: 未找到MSYS2。请从 https://www.msys2.org 下载并安装MSYS2
        echo %date% %time% - 错误: 未找到MSYS2 >> "%LOG_FILE%"
        exit /b 1
    )
)

REM 检查Git
echo 检查Git...
echo %date% %time% - 检查Git... >> "%LOG_FILE%"

where git >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%i in ('git --version') do set GIT_VERSION=%%i
    echo Git已安装: %GIT_VERSION%
    echo %date% %time% - Git版本: %GIT_VERSION% >> "%LOG_FILE%"
) else (
    echo 错误: 未找到Git。请安装Git后重试。
    echo %date% %time% - 错误: 未找到Git >> "%LOG_FILE%"
    exit /b 1
)

REM 检查Python
echo 检查Python...
echo %date% %time% - 检查Python... >> "%LOG_FILE%"

where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
    echo Python已安装: %PYTHON_VERSION%
    echo %date% %time% - Python版本: %PYTHON_VERSION% >> "%LOG_FILE%"
) else (
    echo 错误: 未找到Python。请安装Python 3.6或更高版本。
    echo %date% %time% - 错误: 未找到Python >> "%LOG_FILE%"
    exit /b 1
)

REM 初始化目录结构
echo 初始化目录结构...
echo %date% %time% - 初始化目录结构... >> "%LOG_FILE%"

call scripts\init-directories.bat
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 目录初始化失败
    echo %date% %time% - 错误: 目录初始化失败 >> "%LOG_FILE%"
    exit /b 1
)

REM 安装Python依赖
echo 安装Python依赖...
echo %date% %time% - 安装Python依赖... >> "%LOG_FILE%"

pip install --user meson ninja
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 安装Python依赖失败
    echo %date% %time% - 错误: 安装Python依赖失败 >> "%LOG_FILE%"
    exit /b 1
)

REM 克隆QEMU仓库
echo 克隆QEMU仓库...
echo %date% %time% - 克隆QEMU仓库... >> "%LOG_FILE%"

if exist "%BASE_DIR%qemu-ipod" (
    echo QEMU仓库已存在，检查更新...
    cd "%BASE_DIR%qemu-ipod"
    
    if exist ".git" (
        git fetch
        git rev-parse HEAD > "%TEMP%\local_rev.txt"
        git rev-parse @{u} > "%TEMP%\remote_rev.txt"
        fc "%TEMP%\local_rev.txt" "%TEMP%\remote_rev.txt" >nul
        if %ERRORLEVEL% NEQ 0 (
            echo 发现更新，正在更新QEMU仓库...
            git pull
            if %ERRORLEVEL% NEQ 0 (
                echo 错误: 更新QEMU仓库失败
                echo %date% %time% - 错误: 更新QEMU仓库失败 >> "%LOG_FILE%"
                exit /b 1
            )
            set NEED_REBUILD=1
        ) else (
            echo QEMU仓库已是最新版本
        )
    ) else (
        echo 警告: 现有QEMU目录不是git仓库，将重新克隆
        cd "%BASE_DIR%"
        rmdir /s /q "%BASE_DIR%qemu-ipod"
        git clone https://github.com/devos50/qemu-ipod.git "%BASE_DIR%qemu-ipod"
        if %ERRORLEVEL% NEQ 0 (
            echo 错误: 克隆QEMU仓库失败
            echo %date% %time% - 错误: 克隆QEMU仓库失败 >> "%LOG_FILE%"
            exit /b 1
        )
        set NEED_REBUILD=1
    )
) else (
    git clone https://github.com/devos50/qemu-ipod.git "%BASE_DIR%qemu-ipod"
    if %ERRORLEVEL% NEQ 0 (
        echo 错误: 克隆QEMU仓库失败
        echo %date% %time% - 错误: 克隆QEMU仓库失败 >> "%LOG_FILE%"
        exit /b 1
    )
    set NEED_REBUILD=1
)

REM 编译QEMU
echo 编译QEMU...
echo %date% %time% - 编译QEMU... >> "%LOG_FILE%"

if exist "%BASE_DIR%qemu-ipod\build\qemu-system-arm.exe" (
    if "%NEED_REBUILD%"=="0" (
        echo QEMU已编译，跳过编译步骤
        goto :download_firmware
    )
)

mkdir "%BASE_DIR%qemu-ipod\build" 2>nul
cd "%BASE_DIR%qemu-ipod\build"

REM 使用MSYS2的shell执行配置和编译
C:\msys64\usr\bin\bash.exe -lc "cd '%BASE_DIR%qemu-ipod' && ./configure --target-list=arm-softmmu --enable-sdl --disable-werror && make -j%NUMBER_OF_PROCESSORS%"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: QEMU编译失败
    echo %date% %time% - 错误: QEMU编译失败 >> "%LOG_FILE%"
    exit /b 1
)

:download_firmware
REM 下载固件文件
echo 下载固件文件...
echo %date% %time% - 下载固件文件... >> "%LOG_FILE%"

if exist "%BASE_DIR%firmware\bootrom_s5l8900" (
    if exist "%BASE_DIR%firmware\iboot.bin" (
        echo 固件文件已存在，跳过下载
        goto :run_test
    )
)

REM 创建临时目录
set "TMP_DIR=%TEMP%\qemu-ipod-files"
mkdir "%TMP_DIR%" 2>nul

REM 下载固件文件
powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/devos50/qemu-ipod-files/archive/refs/heads/master.zip' -OutFile '%TMP_DIR%\firmware.zip'}"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 下载固件文件失败
    echo %date% %time% - 错误: 下载固件文件失败 >> "%LOG_FILE%"
    rmdir /s /q "%TMP_DIR%" 2>nul
    exit /b 1
)

REM 解压文件
powershell -Command "& {Expand-Archive -Path '%TMP_DIR%\firmware.zip' -DestinationPath '%TMP_DIR%' -Force}"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 解压固件文件失败
    echo %date% %time% - 错误: 解压固件文件失败 >> "%LOG_FILE%"
    rmdir /s /q "%TMP_DIR%" 2>nul
    exit /b 1
)

REM 复制文件
copy "%TMP_DIR%\qemu-ipod-files-master\bootrom_s5l8900" "%BASE_DIR%firmware\" >nul
copy "%TMP_DIR%\qemu-ipod-files-master\iboot.bin" "%BASE_DIR%firmware\" >nul
copy "%TMP_DIR%\qemu-ipod-files-master\nor.bin" "%BASE_DIR%images\" >nul
xcopy /E /I /Y "%TMP_DIR%\qemu-ipod-files-master\nand\*" "%BASE_DIR%images\nand\" >nul

REM 清理临时文件
rmdir /s /q "%TMP_DIR%" 2>nul

:run_test
REM 运行测试
echo 运行安装测试...
echo %date% %time% - 运行安装测试... >> "%LOG_FILE%"

call scripts\test-installation.bat
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 安装测试失败，但安装过程可能已完成。请检查日志文件了解详情。
    echo %date% %time% - 警告: 安装测试失败 >> "%LOG_FILE%"
    set /a WARNINGS+=1
)

REM 计算运行时间
set END_TIME=%TIME%
for /f "tokens=1-4 delims=:.," %%a in ("%START_TIME%") do set /a "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
for /f "tokens=1-4 delims=:.," %%a in ("%END_TIME%") do set /a "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
set /a elapsed=end-start
set /a hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100

echo.
echo =======================
echo 安装完成！
echo 总用时: %mm%分%ss%秒
echo.
echo 现在你可以运行以下命令启动模拟器：
echo   scripts\start-qemu.bat
echo.
echo 查看快速入门指南获取更多信息：
echo   type QUICKSTART.md
echo =======================

echo %date% %time% - 安装完成，总用时: %mm%分%ss%秒 >> "%LOG_FILE%"

if %ERRORS% GTR 0 (
    exit /b 1
) else (
    exit /b 0
)