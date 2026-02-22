# SerialPortAssistant

SerialPortAssistant 是一个基于 Qt 6 的跨平台串口调试助手。它提供了一个直观的图形界面，便于在 Linux、Windows 和 macOS 上与串口设备进行通信和调试。

## 特性

- 支持常见串口参数配置（波特率、数据位、校验位、停止位等）。
- 发送与接收数据的实时显示和日志记录。
- 通过 Qt QML 构建现代化用户界面。
- 可打包为 AppImage 或其他平台格式。

## 项目结构

```
CMakeLists.txt           # 顶层 CMake 构建脚本
main.cpp                 # 应用程序入口
serialhandler.h/.cpp    # 串口操作封装类
Main.qml                 # QML 用户界面
images.qrc               # 资源文件（图标等）
build/                   # 编译输出和生成的二进制
```

## 构建和运行

```bash
# 进入项目目录
cd /home/rmer/Project/QT_Project/SerialPortAssistant

# 创建构建目录并切换
mkdir -p build && cd build

# 使用 CMake 生成构建文件
cmake ..

# 编译项目
cmake --build .

# 运行应用
./appSerialPortAssistant
```

> 在 Linux 上也可使用生成的 AppImage `SerialPortAssistant-x86_64.AppImage` 直接运行。

## 依赖

- Qt 6 (Qt Quick / QML 模块)
- CMake 3.16+

这份 README 既是为你自己留底，也可以作为 GitHub 项目的说明文档。它涵盖了从环境配置到解决你遇到的那些“坑”的完整过程。

---

## SerialPortAssistant - Linux 打包指南 (AppImage)

本项目基于 **Qt 6.10.2** 开发，使用 `linuxdeploy` 工具将程序及其所有依赖（包括 QML 模块和串口驱动）封装为单个 `.AppImage` 可执行文件。

---

##  准备工作

在开始打包之前，请确保系统中已安装以下工具：

* **Qt 6.10.2**: 包含 `gcc_64` 编译链。
* **linuxdeploy**: [下载地址](https://github.com/linuxdeploy/linuxdeploy/releases)（需下载 `x86_64.AppImage` 版本并赋予执行权限）。
* **linuxdeploy-plugin-qt**: 用于自动处理 Qt 依赖。

---

##  核心打包步骤

由于 Qt 6 的 QML 部署较为复杂，且默认会扫描到不必要的数据库驱动，请严格按照以下流程操作。

### 1. 修改源码以支持文件对话框

为了使“导出数据”按钮正常弹出 `FileDialog`，必须在代码中引入 `QtWidgets`：

* **项目文件 (.pro)**: 添加 `QT += widgets`
* **main.cpp**: 将 `QGuiApplication` 更改为 `QApplication`。


### 3. 自动化打包脚本

在生成的 Release 目录下执行以下命令。该脚本已解决 QML 路径识别、SQL 依赖报错及多线程压缩优化。

* 路径根据自己的进行调整
```bash
# 1. 设置 Qt 环境变量
export QMAKE="/home/rmer/Qt/6.10.2/gcc_64/bin/qmake"
export LD_LIBRARY_PATH="/home/rmer/Qt/6.10.2/gcc_64/lib:$LD_LIBRARY_PATH"


# 3. 避坑指南：排除报错的 Oracle 驱动，指定 QML 源码路径
export BLACKLIST_QT_PLUGINS="libqsqloci"
export QML_SOURCES_PATHS="/home/rmer/Project/QT_Project/SerialPortAssistant"

# 4. 运行打包工具
rm -rf AppDir
./linuxdeploy-x86_64.AppImage \
  --executable appSerialPortAssistant \
  --appdir AppDir \
  --plugin qt \
  --output appimage \
  --desktop-file final.desktop \
  --icon-file icon.png

```

---

## ⚠️ 常见问题排查 (FAQ)

### Q1: 运行 AppImage 提示 `module "QtQuick" is not installed`

**原因**: `linuxdeploy` 未能识别到 QML 依赖。
**解决**: 检查 `QML_SOURCES_PATHS` 是否指向了包含 `.qml` 文件的文件夹，并确保执行打包时终端没有路径解析报错。

### Q2: “导出数据”按钮点击无反应

**原因**: 缺少原生文件对话框实现。
**解决**: 确认 `main.cpp` 使用的是 `QApplication` 而非 `QGuiApplication`，并检查 `AppDir/usr/lib` 下是否存在 `libQt6Widgets.so`。

### Q3: 无法打开串口 (Permission Denied)

**原因**: 当前用户没有访问 `/dev/ttyUSB0` 或 `/dev/ttyS0` 的权限。

## 贡献

欢迎通过提交 issue 或 pull request 来改进本项目。