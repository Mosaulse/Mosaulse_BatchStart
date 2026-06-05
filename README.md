# BatchStart - 批量应用启动管理工具

🚀 一个功能强大的 PowerShell 批量应用启动管理工具

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)

[功能特性](#功能特性) • [快速开始](#快速开始) • [配置指南](#配置指南) • [使用方法](#使用方法) • [常见问题](#常见问题)


---

## 📖 项目简介

BatchStart 是一个智能化的 PowerShell 脚本工具,用于根据 INI 配置文件批量启动和管理 Windows 应用程序。它具备智能启动控制、CPU 使用率监控、自动化执行和完善的日志记录功能,让您的应用启动过程更加高效和可控。

### 🎯 适用场景

- **日常开发工作**:一键启动开发所需的所有工具(IDE、数据库、浏览器、测试工具等)
- **开机自动化**:配置后开机自动启动常用软件,避免手动逐个打开
- **环境切换**:为不同项目创建不同的配置文件,快速切换工作环境
- **性能优化**:智能控制启动节奏,避免系统资源过载

---

## ✨ 功能特性

### 🚀 核心功能

| 功能         | 描述                               | 优势                     |
| ------------ | ---------------------------------- | ------------------------ |
| **顺序启动** | 严格按照配置文件定义的顺序启动应用 | 确保依赖应用先启动       |
| **智能控制** | 基于 CPU 使用率动态调整启动时机    | 避免系统过载,提升稳定性  |
| **重启策略** | 支持跳过或强制重启已运行的应用     | 灵活应对不同需求         |
| **参数支持** | 支持启动带命令行参数的应用程序     | 满足复杂启动需求         |
| **超时保护** | 应用启动超时自动记录错误并继续     | 不会因单个应用失败而中断 |

### ⚙️ 配置能力

| 特性           | 说明                                    |
| -------------- | --------------------------------------- |
| **可配置间隔** | 自定义应用启动间隔时间,适应不同硬件配置 |
| **CPU 阈值**   | 设置 CPU 使用率阈值,智能控制启动节奏    |
| **日志记录**   | 支持控制台彩色输出和文件日志记录        |
| **批量配置**   | 通过 INI 文件轻松管理所有应用配置       |

### 🎨 用户体验

| 特性           | 说明                               |
| -------------- | ---------------------------------- |
| **彩色输出**   | 使用表情符号和颜色编码提升视觉体验 |
| **实时监控**   | 实时显示 CPU 使用率和应用启动状态  |
| **Web 编辑器** | 提供直观的图形界面管理应用配置     |
| **本地存储**   | 配置自动保存到浏览器本地存储       |

---

## 💻 系统要求

| 组件           | 最低要求               | 推荐版本                                |
| -------------- | ---------------------- | --------------------------------------- |
| **操作系统**   | Windows 7/8/10/11      | Windows 10/11                           |
| **PowerShell** | 5.1 或更高版本         | 5.1+ 或 PowerShell 7+                   |
| **浏览器**     | 支持现代 Web 标准      | Chrome, Edge, Firefox (用于 Web 编辑器) |
| **权限**       | 需要启动目标应用的权限 | 管理员权限(可选,用于某些应用)           |

### 检查系统环境

```powershell
# 检查 PowerShell 版本
$PSVersionTable.PSVersion

# 检查执行策略
Get-ExecutionPolicy
```

---

## 🚀 快速开始

### 第一步:获取项目

**方式 1:下载压缩包**
1. 访问项目页面下载 ZIP 压缩包
2. 解压到任意目录(如 `D:\BatchStart`)

**方式 2:Git 克隆**
```bash
git clone https://github.com/yourusername/BatchStart.git
cd BatchStart
```

### 第二步:配置应用列表

编辑 `apps.ini` 文件,添加您需要启动的应用程序:

```ini
[app]
; 基本格式:应用名称=可执行文件路径
微信=D:\Programs\Tencent\Weixin\Weixin.exe
记事本=C:\Windows\System32\notepad.exe

; 带参数的应用(使用引号包裹路径)
Unity="D:\Unity\Unity 2022.3.62f1\Editor\Unity.exe" -projectPath "D:\Projects\MyProject"
VSCode="C:\Program Files\Microsoft VS Code\Code.exe" "D:\Projects\MyProject"

[setting]
WriteLog2Log=false
CPUThreshold=50
MinInterval=1
```

### 第三步:运行脚本

**方式 1:双击运行**(推荐)
- 直接双击 `BatchStart.bat` 文件

**方式 2:PowerShell 运行**
```powershell
cd BatchStart
.\BatchStart.ps1
```

### 第四步:验证结果

脚本运行后会显示彩色输出,每个应用的启动状态都会实时显示:
- ✅ 绿色:启动成功
- ⚠️ 黄色:警告信息
- ❌ 红色:错误信息
- 🔄 青色:应用已运行

---

## 📚 配置指南

### 配置文件结构

`apps.ini` 文件包含两个主要区块:`[app]` 和 `[setting]`。

```ini
[app]
; 应用配置区块
应用名称1=路径 参数1 参数2 ...
应用名称2=路径 参数1 参数2 ...

[setting]
; 全局设置区块
参数名1=值1
参数名2=值2
```

---

### 📱 [app] 区块 - 应用程序配置

#### 配置格式

```
应用名称=可执行文件路径 参数1 参数2 ...
```

**规则说明**:
- **应用名称**:自定义标识符,用于日志输出和识别
- **路径分隔**:应用将按照在配置文件中出现的顺序启动
- **参数支持**:路径后可跟随命令行参数,用空格分隔
- **引号处理**:包含空格的路径必须用双引号包裹

#### 配置示例

**示例 1:单个可执行文件**
```ini
[app]
记事本=C:\Windows\System32\notepad.exe
微信=D:\Programs\Tencent\Weixin\Weixin.exe
```

**示例 2:带空格的路径**
```ini
[app]
VSCode="C:\Program Files\Microsoft VS Code\Code.exe"
Unity="D:\Unity\Unity 2022.3.62f1\Editor\Unity.exe"
```

**示例 3:带参数的应用**
```ini
[app]
UnityProject="D:\Unity\Unity 2022.3.62f1\Editor\Unity.exe" -projectPath "D:\Projects\MyProject"
VSCode="C:\Program Files\Microsoft VS Code\Code.exe" "D:\Projects\MyProject"
```

**示例 4:多个参数**
```ini
[app]
MyApp="C:\My App\app.exe" -arg1 "value with spaces" -arg2 value2
```

**示例 5:混合配置**
```ini
[app]
; 系统工具
Everything=D:\Scoop\apps\everything\current\everything.exe
Rainmeter=D:\Scoop\apps\Rainmeter\current\Rainmeter.exe

; 开发工具
VSCode="C:\Program Files\Microsoft VS Code\Code.exe"
Unity="D:\Unity\Unity 2022.3.62f1\Editor\Unity.exe" -projectPath "D:\Projects\MyGame"

; 浏览器
Chrome="C:\Program Files\Google\Chrome\Application\chrome.exe" --incognito
```

#### 路径处理规则

以下情况**必须使用双引号**:
- 路径包含空格: `"D:\Program Files\VS Code\Code.exe"`
- 路径包含特殊字符: `"D:\Path&Value\app.exe"`
- 参数值包含空格: `-projectPath "D:\My Projects\Project1"`

以下情况**不需要引号**:
- 无空格路径: `D:\app.exe`
- 命令行参数: `-projectPath`
- 简单参数值: `-arg1 value1`

---

### ⚙️ [setting] 区块 - 全局设置

#### 完整参数列表

| 参数名                    | 类型         | 默认值           | 说明                    |
| ------------------------- | ------------ | ---------------- | ----------------------- |
| `WriteLog2Log`            | 布尔值       | `false`          | 是否将日志写入文件      |
| `CPUThreshold`            | 数字 (0-100) | `50`             | CPU 使用率阈值(%)       |
| `MinInterval`             | 数字 (秒)    | `1`              | 应用启动的最小间隔时间  |
| `LogFilePath`             | 字符串       | `BatchStart.log` | 日志文件保存路径        |
| `MaxWaitTime`             | 数字 (秒)    | `10`             | 等待 CPU 降低的最大时间 |
| `StartTimeout`            | 数字 (秒)    | `3`              | 应用启动超时时间        |
| `AppAlreadyRunningAction` | 字符串       | `Skip`           | 已运行应用的处理方式    |

---

#### 详细参数说明

##### 1. WriteLog2Log - 日志文件开关

| 值      | 说明             |
| ------- | ---------------- |
| `true`  | 启用日志文件记录 |
| `false` | 禁用日志文件记录 |

**使用场景**:
- 调试问题时启用,便于排查启动失败原因
- 日常使用可关闭,减少磁盘 I/O

**示例**:
```ini
WriteLog2Log=true   # 启用日志
WriteLog2Log=false  # 禁用日志
```

---

##### 2. CPUThreshold - CPU 使用率阈值

| 范围    | 推荐场景                |
| ------- | ----------------------- |
| `30-40` | 低配置电脑,启动大型应用 |
| `40-50` | 普通配置(默认值)        |
| `50-60` | 中高配置电脑            |
| `60-70` | 高性能电脑              |

**工作原理**:
- 脚本会实时监控 CPU 使用率
- 只有当 CPU 使用率低于此值时才启动下一个应用
- 如果超过阈值,会等待 1 秒后重新检查

**示例**:
```ini
# 低配置电脑
CPUThreshold=30

# 普通配置
CPUThreshold=50

# 高性能电脑
CPUThreshold=70
```

---

##### 3. MinInterval - 最小启动间隔

| 值    | 适用场景        |
| ----- | --------------- |
| `0-1` | 启动轻量级应用  |
| `1-2` | 默认值,通用场景 |
| `2-5` | 启动大型应用    |

**作用**: 确保两个应用启动之间有基本的时间间隔

**示例**:
```ini
# 快速启动小工具
MinInterval=0

# 默认间隔
MinInterval=1

# 给大型应用更多准备时间
MinInterval=3
```

---

##### 4. LogFilePath - 日志文件路径

**格式**:
- 相对路径: `BatchStart.log`(保存在脚本所在目录)
- 绝对路径: `D:\Logs\BatchStart.log`
- 自定义名称: `app-start-2024.log`

**示例**:
```ini
# 默认位置
LogFilePath=BatchStart.log

# 自定义目录
LogFilePath=D:\Logs\BatchStart.log

# 带日期的日志
LogFilePath=logs\BatchStart-$(Get-Date -Format 'yyyy-MM-dd').log
```

---

##### 5. MaxWaitTime - 最大等待时间

| 值      | 说明             |
| ------- | ---------------- |
| `5-10`  | 快速启动(默认值) |
| `10-30` | 给系统更多时间   |
| `30-60` | 启动大型应用场景 |

**工作原理**:
- 脚本等待 CPU 降低的最大时间
- 超过此时间后,即使 CPU 仍高于阈值也会强制启动应用

**示例**:
```ini
# 快速启动,不等待
MaxWaitTime=5

# 默认值
MaxWaitTime=10

# 给系统充足时间
MaxWaitTime=30
```

---

##### 6. StartTimeout - 应用启动超时时间

| 值      | 适用场景               |
| ------- | ---------------------- |
| `3-5`   | 轻量级应用             |
| `5-10`  | 默认值                 |
| `10-20` | 大型应用(如 Unity,IDE) |

**作用**: 判断应用是否成功启动的超时时间

**示例**:
```ini
# 快速应用
StartTimeout=3

# 默认值
StartTimeout=10

# 大型应用
StartTimeout=20
```

---

##### 7. AppAlreadyRunningAction - 已运行应用处理方式

| 值        | 说明                      | 使用场景             |
| --------- | ------------------------- | -------------------- |
| `Skip`    | 跳过启动,不重复打开(默认) | 日常使用             |
| `Restart` | 强制关闭后重新启动        | 需要确保应用最新状态 |

**示例**:
```ini
# 跳过已运行的应用(推荐)
AppAlreadyRunningAction=Skip

# 强制重启
AppAlreadyRunningAction=Restart
```

---

#### 完整配置示例

```ini
[app]
; === 系统工具 ===
Everything="D:\Scoop\apps\everything\current\everything.exe"
Rainmeter="D:\Scoop\apps\Rainmeter\current\Rainmeter.exe"
AutoDarkMode="D:\Scoop\apps\autodarkmode\current\AutoDarkModeApp.exe"

; === 开发工具 ===
VSCode="C:\Program Files\Microsoft VS Code\Code.exe" "E:\Documents\Projects\MyToys"
Unity="D:\Program\Unity\UEditor\Unity 6000.0.58f2\Editor\Unity.exe" -projectPath "E:\Documents\Projects\MyToys\LL001_Uinty_Project"

; === 日常应用 ===
微信=D:\Programs\Tencent\Weixin\Weixin.exe
Chrome="C:\Program Files\Google\Chrome\Application\chrome.exe"

[setting]
; === 日志设置 ===
WriteLog2Log=false
LogFilePath=BatchStart.log

; === 性能设置 ===
CPUThreshold=50
MinInterval=1
MaxWaitTime=10

; === 超时设置 ===
StartTimeout=3

; === 应用状态处理 ===
AppAlreadyRunningAction=Skip
```

---

## 🔧 使用方法

### 基本用法

```powershell
# 使用默认配置文件(当前目录下的 apps.ini)
.\BatchStart.ps1

# 指定自定义配置文件
.\BatchStart.ps1 -ConfigFile "D:\Config\my-apps.ini"

# 显示帮助信息
.\BatchStart.ps1 -Help
```

### 命令行参数

| 参数          | 简写 | 说明                  | 示例                               |
| ------------- | ---- | --------------------- | ---------------------------------- |
| `-ConfigFile` | 无   | 指定 INI 配置文件路径 | `-ConfigFile "D:\Config\apps.ini"` |
| `-Help`       | `-?` | 显示详细帮助信息      | `-Help`                            |

### 高级用法

#### 1. 使用不同配置文件

为不同场景创建不同配置文件:

```powershell
# 工作环境配置
.\BatchStart.ps1 -ConfigFile "apps-work.ini"

# 游戏环境配置
.\BatchStart.ps1 -ConfigFile "apps-game.ini"

# 开发环境配置
.\BatchStart.ps1 -ConfigFile "apps-dev.ini"
```

#### 2. 结合批处理脚本

创建多个启动脚本:

```batch
@echo off
REM 启动工作环境
cd /d D:\BatchStart
powershell.exe -ExecutionPolicy Bypass -File "BatchStart.ps1" -ConfigFile "apps-work.ini"
```

---

## 🌐 Web 配置编辑器

BatchStart 提供了一个直观的 Web 配置编辑器,让您可以通过图形界面轻松管理应用配置。

### 功能特点

- 📱 **可视化管理** - 直观添加、删除和编辑应用
- 🎨 **实时预览** - 实时查看生成的 INI 配置文件
- 🔄 **主题切换** - 支持浅色/深色模式
- 💾 **本地存储** - 自动保存配置到浏览器本地存储
- 📤 **导入/导出** - 支持导入/导出配置文件(JSON 格式)
- 💻 **直接保存** - 使用现代浏览器 API 直接保存到 `apps.ini` 文件
- 🔍 **智能路径处理** - 自动为带空格的路径添加引号

### 启动方式

**方式一:双击启动器**
```batch
双击 ConfighEditor/Start-ConfigEditor.bat
```

**方式二:直接打开 HTML 文件**
```
双击 ConfighEditor/config-editor.html
```

### 操作指南

#### 添加应用

1. 点击 **"+ 添加应用"** 按钮
2. 输入应用名称
3. 添加参数(可执行文件路径、命令行参数等)
4. 根据需要添加多个参数

#### 保存配置

1. 点击 **"💾 保存到 apps.ini"** 按钮
2. 现代浏览器会弹出文件保存对话框
3. 选择覆盖项目目录中的 `apps.ini` 文件
4. 配置会同时保存到浏览器本地存储

#### 导入/导出备份

- **导出备份**:点击 **"📤 导出备份"** 将当前配置导出为 JSON 格式
- **导入备份**:点击 **"📥 导入备份"** 恢复之前的配置备份

### Web 编辑器常见问题

**Q: 导入后路径被截断怎么办?**

确保你的 `apps.ini` 文件中的路径已经正确使用双引号包裹:
```ini
# 正确
Code="D:\Programs\Microsoft VS Code\Code.exe" "D:\Documents\Projects\project"

# 错误
Code=D:\Programs\Microsoft VS Code\Code.exe D:\Documents\Projects\project
```

**Q: 为什么有些参数没有加引号?**

系统会智能判断,只有包含空格、特殊字符或符合 Windows 路径格式的参数才会加引号。纯命令行参数(如 `-projectPath`)不会加引号。

**Q: 如何验证配置是否正确?**

查看界面底部的 **"实时配置预览"** 面板,它会显示生成的完整配置内容。

**Q: 配置会丢失吗?**

不会。编辑器会自动保存配置到浏览器的本地存储,即使关闭浏览器也能恢复。

---

## 📝 日志系统

### 控制台输出

使用彩色编码和表情符号提供直观的状态反馈:

| 级别    | 表情 | 颜色 | 说明       |
| ------- | ---- | ---- | ---------- |
| INFO    | ℹ️    | 灰色 | 一般信息   |
| SUCCESS | ✅    | 绿色 | 操作成功   |
| WARNING | ⚠️    | 黄色 | 警告信息   |
| ERROR   | ❌    | 红色 | 错误信息   |
| ISRUN   | 🔄    | 青色 | 应用已运行 |

**特殊标记**:
- 🚀 脚本启动
- ⚙️ 配置文件加载
- 📋 应用信息
- 📁 路径信息
- 🚦 启动进度
- 💻 CPU 状态
- ⏳ 等待状态
- 🎉 执行完成

### 日志文件

当 `WriteLog2Log=true` 时,日志会写入指定的文件。

**日志格式**:
```
[2024-12-04 10:00:00] [INFO] 批量应用启动管理脚本已启动...
[2024-12-04 10:00:01] [INFO] [微信] 正在启动应用: D:\Programs\Weixin\Weixin.exe
[2024-12-04 10:00:02] [SUCCESS] [微信] 应用启动成功!
[2024-12-04 10:00:05] [INFO] [Chrome] CPU使用率 45% 低于阈值 50%,可以启动应用
```

**查看日志**:
```powershell
# 实时查看日志
Get-Content BatchStart.log -Wait

# 查看错误日志
Select-String -Path BatchStart.log -Pattern "ERROR"

# 查看今天的日志
Select-String -Path BatchStart.log -Pattern (Get-Date -Format 'yyyy-MM-dd')
```

---

## 📂 项目结构

```
BatchStart/
├── BatchStart/                             # 核心脚本目录
│   ├── BatchStart.ps1                      # 主脚本文件
│   ├── BatchStart.bat                      # 批处理启动器
│   ├── apps_template.text                  # 配置模板
│   └── BatchStart_template.bat.text        # 备份启动器
├── ConfighEditor/                          # Web 配置编辑器
│   ├── config-editor.html                  # 配置编辑器主页面
│   ├── config-editor.js                    # 配置编辑器核心逻辑
│   ├── style.css                           # 配置编辑器样式
│   └── Start-ConfigEditor.bat              # 编辑器启动器
├── apps.ini                                # 应用配置文件
├── BatchStart.bat                          # 项目根目录启动器
└── README.md                               # 项目说明文档
```

---

## ❓ 常见问题

### 安装与权限问题

**Q1: 脚本无法执行,提示"无法加载,因为在此系统上禁止运行脚本"**

这是 PowerShell 的执行策略限制。

**解决方法**:
```powershell
# 以管理员身份运行 PowerShell,然后执行:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**说明**: 这个命令将当前用户的执行策略设置为 `RemoteSigned`,允许运行本地脚本和经过签名的外部脚本。

---

**Q2: 如何确认执行策略已生效?**

```powershell
# 查看当前执行策略
Get-ExecutionPolicy -List

# 输出示例:
# MachinePolicy
#   UserPolicy
#      Process
#  CurrentUser    RemoteSigned  <-- 当前用户的策略
# LocalMachine
```

---

### 配置与路径问题

**Q3: 应用启动失败,提示"路径不存在"**

**检查清单**:
1. 路径是否正确
2. 路径中是否包含特殊字符,如有请使用引号包裹
3. 是否有访问该路径的权限
4. 应用是否已经安装

**验证方法**:
```powershell
# 测试路径是否存在
Test-Path "D:\Programs\VS Code\Code.exe"

# 查看文件属性
Get-Item "D:\Programs\VS Code\Code.exe"
```

---

**Q4: 路径包含空格如何处理?**

**正确做法**:
```ini
# 使用双引号包裹
VSCode="C:\Program Files\Microsoft VS Code\Code.exe"

# 带参数也要引号
Unity="D:\Unity\Unity 2022.3.62f1\Editor\Unity.exe" -projectPath "D:\My Projects\Project1"
```

**错误做法**:
```ini
# 不加引号会导致解析错误
VSCode=C:\Program Files\Microsoft VS Code\Code.exe
```

---

**Q5: 如何调整应用启动顺序?**

直接在 `apps.ini` 的 `[app]` 区块中调整应用的顺序即可:

```ini
[app]
# 应用1(会最先启动)
微信=D:\Programs\Weixin\Weixin.exe

# 应用2
VSCode=C:\Program Files\VS Code\Code.exe

# 应用3(会最后启动)
Chrome=C:\Program Files\Chrome\chrome.exe
```

脚本会严格按照配置文件中的顺序启动应用。

---

### 性能与配置问题

**Q6: CPU 阈值设置多少合适?**

**推荐配置**:

| 电脑配置 | CPU 阈值 | 启动间隔 |
| -------- | -------- | -------- |
| 低配置   | 30-40    | 2-3 秒   |
| 普通配置 | 40-50    | 1-2 秒   |
| 高配置   | 50-60    | 1 秒     |
| 超高配置 | 60-70    | 0-1 秒   |

**调整建议**:
- 启动大型应用(如 Unity,IDE):降低阈值到 30-40,增加间隔到 2-3 秒
- 启动小型工具:提高阈值到 50-60,减少间隔到 1 秒或更低
- 观察实际效果,根据需要微调

---

**Q7: 脚本运行太慢,如何优化?**

**优化策略**:

1. **提高 CPU 阈值**:
```ini
CPUThreshold=70  # 提高到 70,减少等待时间
```

2. **减少启动间隔**:
```ini
MinInterval=0  # 设为 0,快速连续启动
```

3. **缩短等待时间**:
```ini
MaxWaitTime=5  # 从默认的 10 秒缩短到 5 秒
```

4. **使用 Skip 模式**:
```ini
AppAlreadyRunningAction=Skip  # 跳过已运行的应用
```

---

**Q8: 某些应用启动失败,但其他应用正常**

**可能原因**:
1. 应用需要管理员权限
2. 应用路径不正确
3. 应用需要特定的环境变量
4. 启动超时时间不够

**解决方法**:
1. **检查应用路径**:
```powershell
Test-Path "D:\Path\To\YourApp.exe"
```

2. **增加启动超时**:
```ini
StartTimeout=15  # 从默认的 3 秒增加到 15 秒
```

3. **手动测试启动**:
```powershell
Start-Process "D:\Path\To\YourApp.exe"
```

4. **查看详细日志**:
```ini
WriteLog2Log=true  # 启用日志,查看详细错误信息
```

---

### 自动化与集成问题

**Q9: 如何让脚本开机自动运行?**

**方法 1:使用任务计划程序**

1. 打开"任务计划程序"
2. 创建基本任务
3. 触发器选择"计算机启动时"或"用户登录时"
4. 操作选择"启动程序"
5. 程序填写: `powershell.exe`
6. 参数填写:
```powershell
-ExecutionPolicy Bypass -WindowStyle Hidden -File "D:\Path\To\BatchStart\BatchStart.ps1"
```

**方法 2:添加到启动文件夹**

1. 创建快捷方式,目标为:
```powershell
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "D:\Path\To\BatchStart\BatchStart.ps1"
```

2. 将快捷方式放到启动文件夹:
```powershell
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
```

**说明**:
- `-WindowStyle Hidden`:启动时隐藏 PowerShell 窗口
- 如需查看输出,可改为 `-WindowStyle Normal`

---

**Q10: 如何为不同项目创建不同的启动配置?**

**方法 1:创建多个配置文件**

```
BatchStart/
├── apps-work.ini      # 工作环境配置
├── apps-dev.ini       # 开发环境配置
├── apps-game.ini      # 游戏环境配置
└── apps-personal.ini  # 个人环境配置
```

**方法 2:创建启动脚本**

```batch
@echo off
REM 启动工作环境
powershell.exe -ExecutionPolicy Bypass -File "BatchStart.ps1" -ConfigFile "apps-work.ini"
```

为每个环境创建一个批处理文件,方便快速启动。

---

### Web 编辑器问题

**Q11: Web 编辑器可以直接打开 HTML 文件吗?**

可以。编辑器支持直接打开 `config-editor.html` 文件使用,无需任何 HTTP 服务器。文件会自动保存到浏览器本地存储,下次打开时自动加载配置。

**Q12: 保存时提示"配置已下载"怎么办?**

这表示你的浏览器不支持直接写入文件,配置已下载到默认下载文件夹。

**解决方法**:
1. 在下载文件夹找到 `apps.ini` 文件
2. 手动将下载的文件替换项目目录中的原文件

---

### 日志与调试问题

**Q13: 如何查看详细的启动日志?**

**方法 1:启用日志文件**
```ini
[setting]
WriteLog2Log=true
LogFilePath=BatchStart.log
```

**方法 2:使用 PowerShell 管道**
```powershell
.\BatchStart.ps1 | Tee-Object -FilePath "output.log"
```

**方法 3:查看日志文件**
```powershell
# 实时查看日志
Get-Content BatchStart.log -Wait

# 查看错误
Select-String -Path BatchStart.log -Pattern "ERROR" -Context 2

# 查看今天的日志
Select-String -Path BatchStart.log -Pattern (Get-Date -Format 'yyyy-MM-dd')
```

---

**Q14: 脚本运行出错,如何调试?**

**调试步骤**:

1. **启用详细日志**:
```ini
[setting]
WriteLog2Log=true
LogFilePath=debug.log
```

2. **查看日志文件**:
```powershell
Get-Content debug.log | Select-String "ERROR" -Context 2
```

3. **验证配置文件**:
```powershell
# 检查配置文件语法
Get-Content apps.ini | Select-String "^\["
```

4. **手动测试应用启动**:
```powershell
Start-Process "D:\Path\To\YourApp.exe"
```

5. **查看 PowerShell 错误**:
```powershell
$Error[0] | Select-Object *
```

---

**Q15: 如何排除特定应用的启动问题?**

**步骤**:

1. **注释掉其他应用,只保留有问题的应用**:
```ini
[app]
; 微信=D:\Programs\Weixin\Weixin.exe
; VSCode=C:\Program Files\VS Code\Code.exe

# 只测试这个应用
Unity="D:\Unity\Unity.exe" -projectPath "D:\Projects\MyProject"
```

2. **观察输出日志**,查找错误信息

3. **手动验证路径**:
```powershell
Test-Path "D:\Unity\Unity.exe"
Get-Item "D:\Unity\Unity.exe"
```

4. **手动启动应用**:
```powershell
Start-Process "D:\Unity\Unity.exe" -ArgumentList "-projectPath `"D:\Projects\MyProject`""
```

---

## 📖 功能详解

### 1. 智能启动控制

脚本会实时监控系统 CPU 使用率,只有当 CPU 使用率低于设定阈值时才启动下一个应用,避免系统过载。

**工作流程**:
1. 检查当前 CPU 使用率
2. 如果低于阈值,立即启动应用
3. 如果高于阈值,等待 1 秒后重新检查
4. 如果等待时间超过 `MaxWaitTime`,强制启动应用

**示例输出**:
```
💻 CPU使用率 45% 低于阈值 50%,可以启动应用
⏳ 等待CPU使用率降低... 当前: 65%, 阈值: 50%, 已等待: 2.5s
💻 CPU使用率 48% 低于阈值 50%,可以启动应用
```

---

### 2. 应用状态检查

启动前会检查应用是否已在运行,根据 `AppAlreadyRunningAction` 配置决定:

**Skip 模式**(跳过):
```
🔄 [微信] 应用已在运行,跳过启动
```

**Restart 模式**(强制重启):
```
⚠️ [微信] 应用已在运行,正在重启...
✅ [微信] 应用启动成功!
```

---

### 3. 启动超时保护

每个应用启动后会等待 `StartTimeout` 秒,确认应用成功启动。如果应用在超时时间内退出或无法启动,会记录错误并继续启动下一个应用。

**正常启动**:
```
✅ [VSCode] 应用启动成功!
```

**启动失败**:
```
❌ [VSCode] 应用启动后立即退出!
⏩ [VSCode] 应用启动失败,继续启动下一个应用
```

---

### 4. 参数支持

支持启动带命令行参数的应用程序:

**格式 1:使用引号包裹可执行文件路径**
```ini
Unity="D:\Unity\Editor\Unity.exe" -projectPath "D:\Projects\MyProject"
```

**格式 2:路径和参数用空格分隔**
```ini
Code="D:\VSCode\Code.exe" "D:\Projects\MyProject"
```

**格式 3:多个参数**
```ini
MyApp="C:\My App\app.exe" -arg1 "value with spaces" -arg2 value2
```

---

<div align="right">

**[⬆ 回到顶部](#batchstart---批量应用启动管理工具)**

Made with ❤️ by BatchStart Contributors

</div>

