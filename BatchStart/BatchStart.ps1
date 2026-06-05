#Requires -Version 5.1
<#
.SYNOPSIS
批量应用启动管理脚本
.DESCRIPTION
根据指定的INI配置文件中定义的应用路径，实现应用程序的批量启动管理
具备智能启动控制、自动化执行和日志记录功能
.PARAMETER ConfigFile
指定INI配置文件路径，默认使用当前目录下的apps.ini
.PARAMETER Help
显示帮助信息
.EXAMPLE
.\BatchStart.ps1
使用默认配置文件启动脚本
.EXAMPLE
.\BatchStart.ps1 -ConfigFile "D:\Config\apps.ini"
使用指定配置文件启动脚本
.EXAMPLE
.\BatchStart.ps1 -Help
显示帮助信息
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0, HelpMessage = "指定INI配置文件路径")]
    [string]$ConfigFile,

    [Parameter(Mandatory = $false, HelpMessage = "显示帮助信息")]
    [switch]$Help
)

# 获取脚本所在目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 设置默认配置文件路径
if (-not $ConfigFile)
{
    # 首先在脚本所在目录查找
    $ConfigFile = Join-Path -Path $ScriptDir -ChildPath "apps.ini"

    # 如果找不到,尝试在父目录查找(支持从项目根目录启动)
    if (-not (Test-Path -Path $ConfigFile -PathType Leaf))
    {
        $parentDir = Split-Path -Path $ScriptDir -Parent
        $ConfigFileInParent = Join-Path -Path $parentDir -ChildPath "apps.ini"

        if (Test-Path -Path $ConfigFileInParent -PathType Leaf)
        {
            $ConfigFile = $ConfigFileInParent
        }
    }
}

# 显示帮助信息
if ($Help)
{
    Get-Help $MyInvocation.MyCommand.Definition -Full
    exit 0
}

# 检查配置文件是否存在
if (-not (Test-Path -Path $ConfigFile -PathType Leaf))
{
    Write-Log -Level "ERROR" -Message "❌ 配置文件 '$ConfigFile' 不存在!"
    exit 1
}

# 定义全局变量
$Global:Config = @{}
$Global:Apps = @()  # 有序数组，保存应用名称和路径
$Global:Settings = @{}

# 默认配置值
$DefaultSettings = @{
    WriteLog2Log            = $false
    CPUThreshold            = 50
    MinInterval             = 2
    LogFilePath             = "$ScriptDir\BatchStart.log"
    MaxWaitTime             = 60
    StartTimeout            = 10
    AppAlreadyRunningAction = "Skip"  # Skip or Restart
}

# 颜色配置
$Colors = @{
    Success   = "Green"
    Error     = "Red"
    Warning   = "Yellow"
    Info      = "Gray"
    Status    = "Magenta"
    IsRunning = "Cyan"
}

# 俏皮输出配置与辅助函数
$PlayColors = @("Red", "Green", "Yellow", "Blue", "Magenta", "Cyan")
$PlayEmojis = @("✨", "🚀", "🛠️", "💫", "🎯", "😺", "🌟", "🔥", "🍀", "🎈", "🥳")

function Get-RandomEmoji
{
    param(
        [int]$Count = 1
    )
    $out = for ($i = 0; $i -lt $Count; $i++)
    { Get-Random -InputObject $PlayEmojis
    }
    return ($out -join '')
}

function Write-Playful
{
    param(
        [Parameter(Mandatory = $true)] [string]$Message,
        [string]$Level = "INFO"
    )

    $emoji = Get-RandomEmoji -Count 1
    $color = Get-Random -InputObject $PlayColors

    $timestamp = Get-Date -Format "yyyy-MM-dd"
    $consoleOutput = "[$timestamp] $emoji $Message"

    $prefix = "[$timestamp]"
    $text = "$emoji $Message"

    Write-Host $prefix -NoNewline -ForegroundColor DarkGray
    Write-Host " $text" -ForegroundColor $color
}

function Write-Rainbow
{
    param(
        [Parameter(Mandatory = $true)] [string]$Text
    )
    $colors = $PlayColors
    $i = 0
    foreach ($ch in $Text.ToCharArray())
    {
        $c = $colors[$i % $colors.Count]
        Write-Host -NoNewline $ch -ForegroundColor $c
        $i++
    }
    Write-Host ""
}

function Show-Banner
{
    $title = "BatchStart"
    $subtitle = "批量应用启动管理"
    Write-Rainbow -Text "=== $title ==="
    Write-Playful -Message "$subtitle — 准备就绪！" -Level "INFO"
}

# 主函数入口
function Main
{
    try
    {
        Show-Banner
        Write-Playful -Message "使用配置: $ConfigFile — 出发！" -Level "INFO"

        # 解析INI配置文件
        ConvertFrom-IniFile -Path $ConfigFile

        # 验证配置
        Validate-Config

        # 执行应用启动
        Start-Applications

        Write-Host "`n"
        Write-Log -Level "SUCCESS" -Message "🎉 脚本执行完成!"

        # 添加暂停功能
        Write-Host "`n"
        Write-Host "按任意键继续..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch
    {
        Write-Log -Level "ERROR" -Message "❌ 脚本执行出错：$($_.Exception.Message)"

        # 输出详细错误堆栈信息用于调试
        $errorDetails = $_.ScriptStackTrace
        if ($errorDetails)
        {
            Write-Log -Level "ERROR" -Message "错误堆栈: $errorDetails"
        }

        # 输出更详细的异常信息
        if ($_.Exception.InnerException)
        {
            Write-Log -Level "ERROR" -Message "内部异常: $($_.Exception.InnerException.Message)"
        }

        exit 1
    }
}

# 实现INI文件解析功能
function ConvertFrom-IniFile
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $currentSection = $null
    $lines = Get-Content -Path $Path -Encoding UTF8 | Where-Object {
        # 过滤掉空行和注释行（以;或#开头）
        $_ -notmatch '^\s*$' -and $_ -notmatch '^\s*[;#]'
    }

    foreach ($line in $lines)
    {
        # 检查是否是区块头 [section]
        if ($line -match '^\s*\[(\w+)\]\s*$')
        {
            $currentSection = $matches[1]
            if (-not $Global:Config.ContainsKey($currentSection))
            {
                $Global:Config[$currentSection] = @{}
            }
        } elseif ($currentSection -and $line -match '^\s*(\w+)\s*=\s*(.*)\s*$')
        {
            # 解析键值对
            $key = $matches[1]
            $value = $matches[2]
            $Global:Config[$currentSection][$key] = $value

            # 直接将app节的应用添加到有序数组，确保顺序与配置文件一致
            if ($currentSection -eq "app")
            {
                $Global:Apps += [PSCustomObject]@{'Name' = $key; 'Path' = $value }
            }
        }
    }

    # 分离设置
    if ($Global:Config.ContainsKey("setting"))
    {
        $Global:Settings = $Global:Config["setting"]
    }

    # 合并默认设置
    foreach ($key in $DefaultSettings.Keys)
    {
        if (-not $Global:Settings.ContainsKey($key))
        {
            $Global:Settings[$key] = $DefaultSettings[$key]
        }
        # 如果用户设置了相对路径，转换为绝对路径
        elseif ($key -eq "LogFilePath")
        {
            $logPath = $Global:Settings[$key]
            if (-not [System.IO.Path]::IsPathRooted($logPath))
            {
                $Global:Settings[$key] = Join-Path -Path $ScriptDir -ChildPath $logPath
            }
        }
    }

    # 转换数值类型
    $NumericKeys = @("CPUThreshold", "MinInterval", "MaxWaitTime", "StartTimeout")
    foreach ($key in $NumericKeys)
    {
        if ($Global:Settings.ContainsKey($key))
        {
            $Global:Settings[$key] = [double]$Global:Settings[$key]
        }
    }

    # 转换布尔类型
    if ($Global:Settings.ContainsKey("WriteLog2Log"))
    {
        $Global:Settings["WriteLog2Log"] = [bool]::Parse($Global:Settings["WriteLog2Log"])
    }
}

# 配置验证模块
function Validate-Config
{
    # 检查是否有应用配置
    if ($Global:Apps.Count -eq 0)
    {
        throw "配置文件中没有定义应用程序列表！"
    }

    # 验证应用程序路径
    foreach ($app in $Global:Apps)
    {
        $appName = $app.Name
        $appPath = $app.Path

        # 解析应用路径，只提取可执行文件部分用于验证
        $executablePath = Get-ExecutablePath -AppPath $appPath

        if (-not (Test-Path -Path $executablePath -PathType Leaf))
        {
            Write-Log -Level "WARNING" -Message "应用 '$appName' 的路径 '$appPath' 不存在!"
        }
    }

    # 验证已运行应用程序的处理方式
    $validActions = @("Skip", "Restart")
    if (-not $validActions.Contains($Global:Settings["AppAlreadyRunningAction"]))
    {
        Write-Log -Level "WARNING" -Message "无效的已运行应用处理方式 '$($Global:Settings["AppAlreadyRunningAction"]) , 使用默认值 'Skip'!"
        $Global:Settings["AppAlreadyRunningAction"] = "Skip"
    }

    # 验证CPU阈值范围
    if ($Global:Settings["CPUThreshold"] -lt 0 -or $Global:Settings["CPUThreshold"] -gt 100)
    {
        Write-Log -Level "WARNING" -Message "无效的CPU阈值 '$($Global:Settings["CPUThreshold"]) , 使用默认值 50!"
        $Global:Settings["CPUThreshold"] = 50
    }
}

# 路径解析辅助函数
function Get-ExecutablePath
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppPath
    )

    $appPathOnly = $AppPath.Trim()
    if ($appPathOnly -match '^"(.*?)"')
    {
        return $matches[1].Trim()
    }

    # 匹配最后一个 .exe 后的所有内容（参数部分）
    if ($appPathOnly -match '^(.+?\.exe)(.*)$')
    {
        return $matches[1].Trim()
    }

    return $appPathOnly
}

# 路径和参数解析函数
function Get-ExeAndArgs
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppPath
    )

    $appPathOnly = $AppPath.Trim()
    $executablePath = ""
    $arguments = ""

    if ($appPathOnly -match '^"(.*?)"')
    {
        $executablePath = $matches[1]
        if ($AppPath -match '^".*?"\s+(.*)$')
        {
            $arguments = $matches[1]
        }
    }
    elseif ($appPathOnly -match '^(.+?\.exe)(.*)$')
    {
        $executablePath = $matches[1]
        $arguments = $matches[2].Trim()
    }
    else
    {
        $executablePath = $appPathOnly
    }

    # 验证可执行文件存在
    if (-not (Test-Path -Path $executablePath -PathType Leaf))
    {
        throw "可执行文件不存在: $executablePath"
    }

    # 验证文件扩展名为 .exe
    $extension = [System.IO.Path]::GetExtension($executablePath)
    if ($extension -ne '.exe')
    {
        throw "不支持的文件类型: $extension，仅支持 .exe 文件"
    }

    return @{
        ExecutablePath = $executablePath
        Arguments = $arguments
    }
}

# 应用状态检查模块
function Check-AppStatus
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppPath
    )

    # 解析应用路径，只提取可执行文件部分
    $appPathOnly = Get-ExecutablePath -AppPath $AppPath

    # 获取进程名
    $processName = [System.IO.Path]::GetFileNameWithoutExtension($appPathOnly)

    # 检查进程是否存在，并验证路径匹配
    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
    foreach ($process in $processes)
    {
        if ($process.Path -and (Split-Path -Leaf $process.Path) -eq (Split-Path -Leaf $appPathOnly))
        {
            return $true
        }
    }

    return $false
}

# CPU使用率监控模块
function Get-CPUUsage
{
    # 获取当前CPU使用率（取最近2秒的平均值）
    $cpuUsage = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
    return $cpuUsage
}

# 日志记录模块
function Write-Log
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "ISRUN")]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$AppName = "",

        [switch]$LogOnly
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level]"

    if ($AppName)
    {
        $logEntry += " [$AppName]"
    }

    $logEntry += " $Message"

    # 写入日志文件
    if ($Global:Settings["WriteLog2Log"])
    {
        Add-Content -Path $Global:Settings["LogFilePath"] -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    }

    # 控制台输出
    if (-not $LogOnly)
    {
        $emoji = ""
        $prefix = "[$Level]"
        $color = $Colors.Info
        switch ($Level)
        {
            "INFO"
            { $color = $Colors.Info; $emoji = "ℹ️ "
            }
            "SUCCESS"
            { $color = $Colors.Success; $emoji = "✅ "
            }
            "WARNING"
            { $color = $Colors.Warning; $emoji = "⚠️ "
            }
            "ERROR"
            { $color = $Colors.Error; $emoji = "❌ "
            }
            "ISRUN"
            { $color = $Colors.IsRunning; $emoji = "🚂 "
            }
        }

        $timestamp = Get-Date -Format "yyyy-MM-dd"

        $consoleOutput = "[$timestamp] $emoji $Message"
        if ($AppName)
        {
            $consoleOutput = "[$timestamp] $emoji [$AppName] $Message"
        }

        Write-Host $consoleOutput -ForegroundColor $color
    }
}

# 应用启动模块
function Start-Application
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [Parameter(Mandatory = $true)]
        [string]$AppPath
    )

    # 检查应用是否已运行
    $isRunning = Check-AppStatus -AppPath $AppPath

    if ($isRunning)
    {
        if ($Global:Settings["AppAlreadyRunningAction"] -eq "Skip")
        {
            Write-Log -Level "ISRUN" -Message "⏏️ 应用已在运行，跳过启动" -AppName $AppName
            return $true
        } else
        {
            Write-Log -Level "WARNING" -Message "⏯ 应用已在运行，正在重启..." -AppName $AppName
            # 强制关闭应用
            # 获取进程名时，只使用路径部分，不包含参数
            $appPathOnly = $AppPath.Trim()
            $appPathOnly = Get-ExecutablePath -AppPath $appPathOnly
            $processName = [System.IO.Path]::GetFileNameWithoutExtension($appPathOnly)
            Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }
    }

    try
    {
        Write-Log -Level "INFO" -Message "⏩ 正在启动应用: $AppPath" -AppName $AppName

        # 解析应用路径和参数
        $exeInfo = Get-ExeAndArgs -AppPath $AppPath
        $executablePath = $exeInfo.ExecutablePath
        $arguments = $exeInfo.Arguments

        # 启动应用程序
        if ($arguments)
        {
            $process = Start-Process -FilePath $executablePath -ArgumentList $arguments -PassThru -ErrorAction Stop
        } else
        {
            $process = Start-Process -FilePath $executablePath -PassThru -ErrorAction Stop
        }

        # 等待应用程序启动（带启动超时）
        $startTime = Get-Date
        $timeout = $Global:Settings["StartTimeout"]

        while ((Get-Date) -lt $startTime.AddSeconds($timeout))
        {
            # 检查进程是否正常运行（更可靠的方式）
            $runningProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue

            if ($null -eq $runningProcess)
            {
                if ($process.HasExited)
                {
                    Write-Log -Level "ERROR" -Message "❌ 应用启动后立即退出!" -AppName $AppName
                }
                else
                {
                    Write-Log -Level "ERROR" -Message "❌ 应用进程不存在!" -AppName $AppName
                }
                return $false
            }

            Write-Log -Level "SUCCESS" -Message "✅ 应用启动成功!" -AppName $AppName
            return $true
        }

        Write-Log -Level "ERROR" -Message "⌛️ 应用启动超时!" -AppName $AppName
        return $false
    } catch
    {
        Write-Log -Level "ERROR" -Message "❌ 应用启动失败: $($_.Exception.Message)" -AppName $AppName

        # 输出详细错误堆栈信息用于调试
        $errorDetails = $_.ScriptStackTrace
        if ($errorDetails)
        {
            Write-Log -Level "ERROR" -Message "错误堆栈: $errorDetails" -AppName $AppName
        }

        return $false
    }
}

# 应用启动控制模块
function Start-Applications
{
    $appCount = $Global:Apps.Count
    $currentIndex = 0

    foreach ($app in $Global:Apps)
    {
        $currentIndex++
        $appName = $app.Name
        $appPath = $app.Path

        Write-Host "`n"
        Write-Log -Level "INFO" -Message "📱 ${currentIndex}/${appCount}"
        Write-Log -Level "INFO" -Message "📁 路径: $appPath"
        Write-Log -Level "INFO" -Message "🚦 按顺序启动应用: ${currentIndex}/${appCount} -> $appName"

        # 智能启动控制：等待CPU使用率低于阈值
        $waitStartTime = Get-Date
        $maxWaitTime = $Global:Settings["MaxWaitTime"]
        $cpuThreshold = $Global:Settings["CPUThreshold"]

        while ($true)
        {
            $cpuUsage = Get-CPUUsage
            $elapsedTime = (Get-Date) - $waitStartTime

            # 检查是否超过最大等待时间
            if ($elapsedTime.TotalSeconds -ge $maxWaitTime)
            {
                Write-Log -Level "WARNING" -Message "↪️ 超过最大等待时间，强制启动应用" -AppName $appName
                break
            }

            # 检查CPU使用率是否低于阈值
            if ($cpuUsage -le $cpuThreshold)
            {
                Write-Log -Level "INFO" -Message "💻 CPU使用率 $cpuUsage% 低于阈值 $cpuThreshold%，可以启动应用" -AppName $appName
                break
            }

            # 显示等待状态
            Write-Log -Level "INFO" -Message "⏳ 等待CPU使用率降低... 当前: $cpuUsage%, 阈值: $cpuThreshold%, 已等待: $([math]::Round($elapsedTime.TotalSeconds, 1))s" -AppName $appName

            Start-Sleep -Seconds 1
        }

        # 执行应用启动，检查启动结果
        $startResult = Start-Application -AppName $appName -AppPath $appPath

        if (-not $startResult)
        {
            Write-Log -Level "ERROR" -Message "🤣 应用启动失败，继续启动下一个应用" -AppName $appName
        }

        # 应用程序启动间隔（最后一个应用除外）
        if ($currentIndex -lt $appCount)
        {
            $minInterval = $Global:Settings["MinInterval"]
            Write-Log -Level "INFO" -Message "⏳ 等待 $minInterval 秒后启动下一个应用..." -AppName $appName
            Start-Sleep -Seconds $minInterval
        }
    }
}

# 调用主函数
Main
