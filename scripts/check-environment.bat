@echo off
setlocal enabledelayedexpansion

REM iOS QEMU 懒人包环境检查脚本 (Windows版)

REM 设置路径
set "SCRIPT_DIR=%~dp0"
set "BASE_DIR=%SCRIPT_DIR%.."
set "LOG_FILE=%BASE_DIR%\logs\environment.log"

REM 创建日志目录
if not exist "%BASE_DIR%\logs" mkdir "%BASE_DIR%\logs"

REM 初始化计数器
set ERRORS=0
set WARNINGS=0
set PASSED=0

REM 记录开始时间
echo %date% %time% - 开始环境检查... > "%LOG_FILE%"

echo iOS QEMU 懒人包环境检查
echo =======================
echo.

REM 检查系统信息
echo 检查系统信息...
echo %date% %time% - 检查系统信息... >> "%LOG_FILE%"

REM 检查Windows版本
powershell -command "& {$os = Get-WmiObject -Class Win32_OperatingSystem; Write-Output $os.Caption; Write-Output $os.Version}" > "%TEMP%\os_info.txt"
set /p OS_NAME=<"%TEMP%\os_info.txt"
call :success "操作系统: %OS_NAME%"

REM 检查系统架构
powershell -command "& {$arch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture; Write-Output $arch}" > "%TEMP%\arch_info.txt"
set /p ARCH=<"%TEMP%\arch_info.txt"
call :success "系统架构: %ARCH%"

REM 检查CPU信息
powershell -command "& {$cpu = Get-WmiObject -Class Win32_Processor; Write-Output $cpu.Name; Write-Output $cpu.NumberOfCores}" > "%TEMP%\cpu_info.txt"
set /p CPU_INFO=<"%TEMP%\cpu_info.txt"
call :success "CPU: %CPU_INFO%"

REM 检查内存
powershell -command "& {$mem = Get-WmiObject -Class Win32_ComputerSystem; Write-Output ([math]::Round($mem.TotalPhysicalMemory / 1GB, 2)) }" > "%TEMP%\mem_info.txt"
set /p MEM_TOTAL=<"%TEMP%\mem_info.txt"
call :success "系统内存: %MEM_TOTAL% GB"

REM 检查磁盘空间
powershell -command "& {$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter \"DeviceID='%~d0'\"; Write-Output ([math]::Round($disk.FreeSpace / 1GB, 2))}" > "%TEMP%\disk_info.txt"
set /p DISK_FREE=<"%TEMP%\disk_info.txt"
call :success "可用磁盘空间: %DISK_FREE% GB"

echo.
echo 检查必要命令...
echo %date% %time% - 检查必要命令... >> "%LOG_FILE%"

REM 检查Git
where git >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%i in ('git --version') do set GIT_VERSION=%%i
    call :success "找到Git: !GIT_VERSION!"
) else (
    call :error "未找到Git。请安装Git后重试。"
)

REM 检查curl
where curl >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%i in ('curl --version ^| findstr /B curl') do set CURL_VERSION=%%i
    call :success "找到curl: !CURL_VERSION!"
) else (
    call :warning "未找到curl。某些下载功能可能不可用。"
)

REM 检查Python环境
echo.
echo 检查Python环境...
echo %date% %time% - 检查Python环境... >> "%LOG_FILE%"

where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    call :success "找到Python: !PYTHON_VERSION!"
    
    REM 检查Python版本是否满足要求
    echo !PYTHON_VERSION! | findstr /C:"Python 3" >nul
    if %ERRORLEVEL% NEQ 0 (
        call :warning "Python版本可能过低。推荐Python 3.6或更高版本。"
    )
    
    REM 检查pip
    where pip >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        for /f "tokens=*" %%i in ('pip --version') do set PIP_VERSION=%%i
        call :success "找到pip: !PIP_VERSION!"
        
        REM 检查必要的Python包
        pip show meson >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            for /f "tokens=2" %%i in ('pip show meson ^| findstr Version') do set MESON_VERSION=%%i
            call :success "找到meson: !MESON_VERSION!"
        ) else (
            call :warning "未找到meson包。可能需要运行: pip install meson"
        )
        
        pip show ninja >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            for /f "tokens=2" %%i in ('pip show ninja ^| findstr Version') do set NINJA_VERSION=%%i
            call :success "找到ninja: !NINJA_VERSION!"
        ) else (
            call :warning "未找到ninja包。可能需要运行: pip install ninja"
        )
    ) else (
        call :error "未找到pip。请安装pip。"
    )
) else (
    call :error "未找到Python。请安装Python 3.6或更高版本。"
)

REM 检查MSYS2
echo.
echo 检查MSYS2...
echo %date% %time% - 检查MSYS2... >> "%LOG_FILE%"

if exist "C:\msys64\mingw64\bin" (
    call :success "找到MSYS2安装"
    
    REM 检查MSYS2是否在PATH中
    echo %PATH% | findstr /C:"msys64" >nul
    if %ERRORLEVEL% EQU 0 (
        call :success "MSYS2已添加到PATH"
    ) else (
        call :warning "MSYS2未添加到PATH。可能需要将C:\msys64\mingw64\bin添加到系统PATH。"
    )
    
    REM 检查GCC
    if exist "C:\msys64\mingw64\bin\gcc.exe" (
        for /f "tokens=*" %%i in ('"C:\msys64\mingw64\bin\gcc.exe" --version ^| findstr /B gcc') do set GCC_VERSION=%%i
        call :success "找到GCC: !GCC_VERSION!"
    ) else (
        call :error "未找到GCC。请在MSYS2中安装gcc。"
    )
    
    REM 检查Make
    if exist "C:\msys64\mingw64\bin\make.exe" (
        for /f "tokens=*" %%i in ('"C:\msys64\mingw64\bin\make.exe" --version ^| findstr /B GNU') do set MAKE_VERSION=%%i
        call :success "找到Make: !MAKE_VERSION!"
    ) else (
        call :error "未找到Make。请在MSYS2中安装make。"
    )
    
    REM 检查pkg-config
    if exist "C:\msys64\mingw64\bin\pkg-config.exe" (
        for /f "tokens=*" %%i in ('"C:\msys64\mingw64\bin\pkg-config.exe" --version') do set PKG_CONFIG_VERSION=%%i
        call :success "找到pkg-config: !PKG_CONFIG_VERSION!"
    ) else (
        call :error "未找到pkg-config。请在MSYS2中安装pkg-config。"
    )
) else (
    call :error "未找到MSYS2。请从 https://www.msys2.org 下载并安装MSYS2。"
)

REM 检查SDL2
echo.
echo 检查SDL2库...
echo %date% %time% - 检查SDL2库... >> "%LOG_FILE%"

if exist "C:\msys64\mingw64\bin\SDL2.dll" (
    call :success "找到SDL2库"
) else (
    where SDL2.dll >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        call :success "找到SDL2库"
    ) else (
        call :error "未找到SDL2库。请在MSYS2中安装SDL2。"
        echo 提示: 在MSYS2中运行 'pacman -S mingw-w64-x86_64-SDL2' >> "%LOG_FILE%"
    )
)

REM 检查网络连接
echo.
echo 检查网络连接...
echo %date% %time% - 检查网络连接... >> "%LOG_FILE%"

ping -n 1 github.com >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    call :success "可以连接到GitHub"
) else (
    call :warning "无法连接到GitHub。可能会影响下载固件和源码。"
)

REM 显示检查结果
echo.
echo =======================
echo 检查摘要:
echo 通过: %PASSED%
echo 警告: %WARNINGS%
echo 失败: %ERRORS%
echo.

echo %date% %time% - 检查完成，通过: %PASSED%，警告: %WARNINGS%，失败: %ERRORS% >> "%LOG_FILE%"

if %ERRORS% EQU 0 (
    if %WARNINGS% EQU 0 (
        echo [92m环境检查通过！系统满足所有要求。[0m
        echo %date% %time% - 环境检查通过！系统满足所有要求。 >> "%LOG_FILE%"
        exit /b 0
    ) else (
        echo [93m环境检查通过，但有 %WARNINGS% 个警告。可能需要安装一些可选组件。[0m
        echo %date% %time% - 环境检查通过，但有 %WARNINGS% 个警告。 >> "%LOG_FILE%"
        exit /b 0
    )
) else (
    echo [91m环境检查失败，发现 %ERRORS% 个错误。请解决这些问题后重试。[0m
    echo %date% %time% - 环境检查失败，发现 %ERRORS% 个错误。 >> "%LOG_FILE%"
    exit /b 1
)

:success
echo [92m✓[0m %~1
echo %date% %time% - 通过: %~1 >> "%LOG_FILE%"
set /a PASSED+=1
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