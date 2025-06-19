# iOS QEMU 懒人包使用指南

## 目录

1. [系统要求](#系统要求)
2. [安装步骤](#安装步骤)
3. [基本使用](#基本使用)
4. [配置说明](#配置说明)
5. [高级功能](#高级功能)
6. [故障排除](#故障排除)
7. [常见问题](#常见问题)

## 系统要求

### Windows
- Windows 10 64位或更高版本
- 4GB以上内存
- 10GB以上可用磁盘空间
- MSYS2环境
- Python 3.6或更高版本
- Git

### Linux
- 现代Linux发行版（Ubuntu 20.04+, Fedora 34+等）
- 4GB以上内存
- 10GB以上可用磁盘空间
- Python 3.6或更高版本
- Git
- 开发工具（gcc, make等）

### macOS
- macOS 10.15或更高版本
- 4GB以上内存
- 10GB以上可用磁盘空间
- Xcode命令行工具
- Python 3.6或更高版本
- Git
- Homebrew（推荐）

## 安装步骤

### Windows安装

1. 安装MSYS2
   ```powershell
   # 从 https://www.msys2.org 下载并安装MSYS2
   # 安装完成后，打开MSYS2 MINGW64终端
   pacman -Syu
   pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-make mingw-w64-x86_64-SDL2
   ```

2. 安装Python
   ```powershell
   # 从 https://www.python.org 下载并安装Python 3
   # 确保在安装时勾选"Add Python to PATH"
   ```

3. 安装Git
   ```powershell
   # 从 https://git-scm.com 下载并安装Git
   ```

4. 运行安装脚本
   ```powershell
   .\setup.bat
   ```

### Linux安装

1. 安装依赖
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install git python3 python3-pip gcc make libsdl2-dev

   # Fedora
   sudo dnf install git python3 python3-pip gcc make SDL2-devel

   # Arch Linux
   sudo pacman -S git python python-pip gcc make sdl2
   ```

2. 运行安装脚本
   ```bash
   ./setup.sh
   ```

### macOS安装

1. 安装依赖
   ```bash
   # 安装Homebrew（如果尚未安装）
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # 安装依赖
   brew install python3 git sdl2
   ```

2. 运行安装脚本
   ```bash
   ./setup.sh
   ```

## 基本使用

### 启动模拟器

Windows:
```powershell
.\scripts\start-qemu.bat
```

Linux/macOS:
```bash
./scripts/start-qemu.sh
```

### 测试安装

Windows:
```powershell
.\scripts\test-installation.bat
```

Linux/macOS:
```bash
./scripts/test-installation.sh
```

### 检查环境

Windows:
```powershell
.\scripts\check-environment.bat
```

Linux/macOS:
```bash
./scripts/check-environment.sh
```

## 配置说明

配置文件位于 `config/user/qemu.conf`，包含以下主要设置：

### 基本设置
- `CPU_MODEL`: CPU模型（max或cortex-a8）
- `MEMORY_SIZE`: 内存大小（如1G）
- `DISPLAY_TYPE`: 显示类型（sdl、gtk等）
- `AUDIO_DRIVER`: 音频驱动

### 性能设置
- `ACCEL_OPTIONS`: 加速选项
- `KVM_ENABLE`: KVM加速（仅Linux）
- `HAXM_ENABLE`: HAXM加速（仅Windows/macOS）
- `HVF_ENABLE`: HVF加速（仅macOS）
- `WHPX_ENABLE`: WHPX加速（仅Windows）

### 网络设置
- `NETWORK_ENABLE`: 启用网络
- `USB_REDIRECT`: USB重定向

### 调试设置
- `DEBUG_LOG`: 调试日志
- `PERF_STATS`: 性能统计

## 高级功能

### 远程显示
1. 启用VNC支持：
   ```conf
   REMOTE_DISPLAY=1
   REMOTE_DISPLAY_PORT=5900
   ```

2. 使用VNC客户端连接：
   ```
   localhost:5900
   ```

### 共享文件夹
1. 配置共享文件夹：
   ```conf
   SHARED_FOLDER=1
   SHARED_FOLDER_PATH=/path/to/shared/folder
   ```

### 快照功能
1. 启用快照：
   ```conf
   SNAPSHOT_ENABLE=1
   ```

2. 使用快照：
   - 创建快照：Ctrl+Alt+2，然后输入 `savevm name`
   - 加载快照：Ctrl+Alt+2，然后输入 `loadvm name`

### 实时迁移
1. 启用迁移：
   ```conf
   MIGRATION_ENABLE=1
   ```

2. 执行迁移：
   ```bash
   # 在目标机器上
   nc -l 4444

   # 在源机器上
   Ctrl+Alt+2
   migrate tcp:destination:4444
   ```

## 故障排除

### 常见错误

1. QEMU启动失败
   - 检查固件文件是否存在
   - 检查配置文件是否正确
   - 查看日志文件（logs/qemu.log）

2. SDL显示问题
   - 确保SDL2正确安装
   - 尝试其他显示类型（gtk、cocoa等）

3. 音频问题
   - 检查音频驱动配置
   - 确保系统音频正常工作

4. 性能问题
   - 启用适当的加速选项
   - 调整内存大小
   - 检查CPU使用率

### 日志文件
- QEMU日志：`logs/qemu.log`
- 调试日志：`logs/qemu_debug.log`
- 环境检查日志：`logs/environment.log`
- 安装测试日志：`logs/test.log`

## 常见问题

Q: 为什么模拟器启动很慢？  
A: 可能是因为未启用硬件加速。尝试启用适合你系统的加速选项（KVM/HAXM/HVF/WHPX）。

Q: 如何提高模拟器性能？  
A: 
- 增加内存大小
- 启用硬件加速
- 使用多线程TCG
- 关闭不必要的调试选项

Q: 如何保存模拟器状态？  
A: 使用快照功能（SNAPSHOT_ENABLE=1），然后使用QEMU监视器命令保存和加载状态。

Q: 模拟器无法访问网络？  
A: 
- 确保NETWORK_ENABLE=1
- 检查防火墙设置
- 尝试不同的网络配置

Q: 如何访问模拟器中的文件？  
A: 使用共享文件夹功能，设置SHARED_FOLDER=1并配置SHARED_FOLDER_PATH。

Q: 如何调试问题？  
A: 
1. 启用调试日志（DEBUG_LOG=1）
2. 查看相关日志文件
3. 使用QEMU监视器（Ctrl+Alt+2）
4. 检查系统日志

如果遇到其他问题，请查看日志文件或在GitHub上提交issue。