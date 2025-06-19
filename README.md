# iOS QEMU 懒人包 (未经测试)

<p align="center">
  <img src="https://via.placeholder.com/200x200?text=iOS+QEMU" alt="iOS QEMU 懒人包" width="200"/>
</p>

<p align="center">
  <strong>在PC上模拟运行iOS设备的一站式解决方案</strong>
</p>

<p align="center">
  <a href="#功能特点">功能特点</a> •
  <a href="#快速开始">快速开始</a> •
  <a href="#系统要求">系统要求</a> •
  <a href="#安装指南">安装指南</a> •
  <a href="#使用说明">使用说明</a> •
  <a href="#常见问题">常见问题</a> •
  <a href="#贡献指南">贡献指南</a> •
  <a href="#许可证">许可证</a>
</p>

## 项目介绍

iOS QEMU 懒人包是一个集成工具集，旨在简化在PC上模拟运行iOS设备的过程。通过预配置的QEMU环境和自动化脚本，用户可以轻松地在Windows、Linux和macOS上模拟运行iOS设备，无需深入了解底层技术细节。

本项目适合iOS开发者、安全研究人员、怀旧游戏爱好者以及对iOS系统感兴趣的技术爱好者。

## 功能特点

- **跨平台支持**：兼容Windows、Linux和macOS
- **一键式安装**：自动化安装脚本，简化环境配置
- **用户友好界面**：简单的命令行界面，易于操作
- **预配置环境**：预先配置的QEMU参数，优化性能
- **多版本支持**：支持多种iOS版本的模拟
- **硬件加速**：支持KVM、HAXM、HVF和WHPX等硬件加速技术
- **网络支持**：模拟网络连接，支持网络应用测试
- **共享文件夹**：主机与模拟器之间的文件共享
- **快照功能**：保存和恢复模拟器状态
- **远程显示**：通过VNC远程访问模拟器
- **详细文档**：完整的安装和使用指南

## 快速开始

### Windows

```powershell
# 克隆仓库
git clone https://github.com/yourusername/ios-qemu-pack.git
cd ios-qemu-pack

# 运行安装脚本
.\setup.bat

# 启动模拟器
.\scripts\start-qemu.bat
```

### Linux/macOS

```bash
# 克隆仓库
git clone https://github.com/yourusername/ios-qemu-pack.git
cd ios-qemu-pack

# 运行安装脚本
chmod +x setup.sh
./setup.sh

# 启动模拟器
./scripts/start-qemu.sh
```

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

## 安装指南

详细的安装说明请参阅[快速入门指南](QUICKSTART.md)和[详细使用指南](GUIDE.md)。

## 使用说明

### 基本命令

```bash
# 检查环境
./scripts/check-environment.sh  # Linux/macOS
.\scripts\check-environment.bat  # Windows

# 测试安装
./scripts/test-installation.sh  # Linux/macOS
.\scripts\test-installation.bat  # Windows

# 启动模拟器
./scripts/start-qemu.sh  # Linux/macOS
.\scripts\start-qemu.bat  # Windows
```

### 配置

编辑 `config/user/qemu.conf` 文件以自定义模拟器设置：

```conf
# CPU配置
CPU_MODEL=max

# 内存大小
MEMORY_SIZE=1G

# 加速选项
ACCEL_OPTIONS=tcg,thread=multi

# 显示类型
DISPLAY_TYPE=sdl
```

更多配置选项请参阅[详细使用指南](GUIDE.md)。

## 目录结构

```
ios-qemu-pack/
├── backups/           # 备份文件目录
├── config/            # 配置文件目录
│   └── user/          # 用户配置
├── firmware/          # 固件文件
├── images/            # 镜像文件
│   └── nand/          # NAND镜像
├── logs/              # 日志文件
├── qemu-ipod/         # QEMU源码
│   └── build/         # 编译后的QEMU
├── scripts/           # 脚本文件
├── tools/             # 工具脚本
├── GUIDE.md           # 详细使用指南
├── QUICKSTART.md      # 快速入门指南
├── README.md          # 项目说明
├── setup.bat          # Windows安装脚本
└── setup.sh           # Linux/macOS安装脚本
```

## 常见问题

**Q: 模拟器启动失败，提示缺少固件文件**  
A: 请确保已正确安装并配置固件文件。运行测试脚本检查安装状态：`./scripts/test-installation.sh`

**Q: 模拟器性能很差**  
A: 尝试启用硬件加速。编辑配置文件，根据你的系统启用相应的加速选项（KVM/HAXM/HVF/WHPX）。

**Q: 如何获取iOS固件？**  
A: 由于法律原因，本项目不提供iOS固件文件。请参考[详细使用指南](GUIDE.md)中的相关说明。

更多常见问题请参阅[详细使用指南](GUIDE.md)的常见问题部分。

## 贡献指南

我们欢迎并感谢任何形式的贡献！如果你想为项目做出贡献，请遵循以下步骤：

1. Fork本仓库
2. 创建你的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交你的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启一个Pull Request

### 贡献领域

- 改进文档
- 修复bug
- 添加新功能
- 优化性能
- 支持更多iOS版本

## 许可证

本项目采用MIT许可证 - 详情请参阅[LICENSE](LICENSE)文件。

## 致谢

- [QEMU项目](https://www.qemu.org/)
- 所有为本项目做出贡献的开发者
- 开源社区的支持和鼓励

---

<p align="center">
  如果你觉得这个项目有用，请考虑给它一个星标 ⭐️
</p>