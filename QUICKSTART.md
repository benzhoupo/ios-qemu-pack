# iOS QEMU 懒人包 - 快速入门指南

这个快速入门指南将帮助你快速设置和运行iOS QEMU模拟器。如果需要更详细的信息，请参考[完整指南](GUIDE.md)。

## 目录

1. [系统要求](#系统要求)
2. [安装步骤](#安装步骤)
3. [快速启动](#快速启动)
4. [基本操作](#基本操作)
5. [常见问题](#常见问题)

## 系统要求

### Windows
- Windows 10/11 64位
- 至少4GB RAM（推荐8GB或更多）
- 10GB可用磁盘空间
- MSYS2环境
- Python 3.6+
- Git

### Linux/macOS
- 64位操作系统
- 至少4GB RAM（推荐8GB或更多）
- 10GB可用磁盘空间
- Python 3.6+
- Git
- SDL2库

## 安装步骤

### Windows用户

1. 安装MSYS2
   ```powershell
   # 下载并运行MSYS2安装程序
   # 从 https://www.msys2.org 下载
   ```

2. 安装必要的包
   ```bash
   # 在MSYS2终端中运行
   pacman -Syu
   pacman -S mingw-w64-x86_64-gcc python git make
   pacman -S mingw-w64-x86_64-SDL2
   ```

3. 运行安装脚本
   ```cmd
   setup.bat
   ```

### Linux用户

1. 安装依赖
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install git python3 python3-pip build-essential libsdl2-dev

   # Fedora
   sudo dnf install git python3 python3-pip gcc make SDL2-devel

   # Arch Linux
   sudo pacman -S git python python-pip base-devel sdl2
   ```

2. 运行安装脚本
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

### macOS用户

1. 安装Homebrew（如果尚未安装）
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. 安装依赖
   ```bash
   brew install python git sdl2
   ```

3. 运行安装脚本
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

## 快速启动

### Windows
```cmd
scripts\start-qemu.bat
```

### Linux/macOS
```bash
./scripts/start-qemu.sh
```

## 基本操作

### 模拟器控制
- **开/关机**: P键
- **Home键**: H键
- **退出**: Ctrl+C
- **鼠标**: 用于模拟触摸操作
- **键盘**: 用于特殊功能和调试

### 触摸屏操作
- **点击**: 鼠标左键点击
- **滑动**: 按住鼠标左键拖动
- **多点触控**: 暂不支持

### 快捷键
- **Ctrl+Alt+G**: 释放鼠标捕获
- **Ctrl+Alt+F**: 切换全屏
- **Ctrl+Alt+U**: 切换USB重定向

## 常见问题

### 1. 模拟器无法启动

**症状**: 运行启动脚本后没有反应或报错

**解决方案**:
1. 检查是否所有依赖都已正确安装
   ```bash
   # Windows
   scripts\check-environment.bat

   # Linux/macOS
   ./scripts/check-environment.sh
   ```
2. 检查日志文件（位于logs目录）
3. 确保所有必要文件都存在

### 2. 黑屏

**症状**: 模拟器启动但显示黑屏

**解决方案**:
1. 按P键（电源键）
2. 等待约30秒
3. 如果仍然黑屏，尝试重启模拟器

### 3. 触摸屏不响应

**症状**: 鼠标点击没有反应

**解决方案**:
1. 按Ctrl+Alt+G释放鼠标捕获
2. 重新点击模拟器窗口
3. 如果问题持续，重启模拟器

### 4. 性能问题

**症状**: 模拟器运行缓慢或卡顿

**解决方案**:
1. 检查系统资源使用情况
2. 关闭其他占用资源的程序
3. 在配置文件中调整设置：
   ```bash
   # 编辑 config/user/qemu.conf
   CPU_MODEL=max
   MEMORY_SIZE=2G
   ACCEL_OPTIONS=tcg,thread=multi
   ```

### 5. 找不到固件文件

**症状**: 启动时报错找不到固件文件

**解决方案**:
1. 检查firmware目录是否包含所需文件
2. 重新运行安装脚本
3. 如果问题持续，手动下载固件文件

## 下一步

- 阅读[完整指南](GUIDE.md)了解更多高级功能
- 查看配置文件了解可自定义的选项
- 加入社区获取支持和更新

## 获取帮助

如果你遇到本指南未涵盖的问题：

1. 检查日志文件（位于logs目录）
2. 查看[完整指南](GUIDE.md)
3. 提交问题到项目仓库
4. 在社区论坛寻求帮助

---

现在你已经掌握了基本的使用方法。如需了解更多高级功能和详细信息，请参考[完整指南](GUIDE.md)。