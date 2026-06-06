#Requires -Version 5.1
<#
.SYNOPSIS
批量应用启动管理脚本
.DESCRIPTION
根据 INI 配置文件中的应用列表，智能按 CPU 使用率调度启动。
配置文件仅需 [Logging] 和 [Applications] 两个段落。

CPU 感知策略：
  - 滑动窗口平均（最近 3 次采样）平滑瞬时尖峰
  - 根据 CPU 负载等级自适应等待：低→快速启动，高→耐心等待
  - CPU 阈值可通过 INI [Logging] 下的 CPUThreshold 配置（默认 50%）
  - 也可通过环境变量 BATCHSTART_CPU_THRESHOLD 覆盖
  - 单个应用最长等待 120 秒后强制启动（安全阀）
.PARAMETER ConfigFile
指定 INI 配置文件路径，默认当前目录下的 apps.ini
.PARAMETER Help
显示帮助信息
.EXAMPLE
.\BatchStart.ps1
使用默认配置文件
.EXAMPLE
.\BatchStart.ps1 -ConfigFile "D:\Config\apps.ini"
使用指定配置文件
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

if ($Help)
{
    Get-Help $MyInvocation.MyCommand.Definition -Full
    exit 0
}

# 设置默认配置文件路径
if (-not $ConfigFile)
{
    $ConfigFile = Join-Path -Path $ScriptDir -ChildPath "apps.ini"
    if (-not (Test-Path -Path $ConfigFile -PathType Leaf))
    {
        $parentDir = Split-Path -Path $ScriptDir -Parent
        $candidate = Join-Path -Path $parentDir -ChildPath "apps.ini"
        if (Test-Path -Path $candidate -PathType Leaf) { $ConfigFile = $candidate }
    }
}

# 检查配置文件是否存在
if (-not (Test-Path -Path $ConfigFile -PathType Leaf))
{
    Write-Host "❌ 配置文件 '$ConfigFile' 不存在!" -ForegroundColor Red
    exit 1
}

# ── 全局状态 ───────────────────────────────────────────────────
$Global:Apps      = @()    # 有序数组 [PSCustomObject]@{Name; Path}
$Global:LogConfig = @{ WriteLog2Log = $false; LogFilePath = "$ScriptDir\BatchStart.log"; CPUThreshold = 50 }

# ── 常量 ───────────────────────────────────────────────────────
$CPU_SAMPLES       = 3     # 滑动窗口采样数
$BREATH_SECONDS    = 3     # 每次启动后的呼吸间隔（秒）
$MAX_WAIT_PER_APP  = 120   # 单个应用最长等待（秒）

# 颜色与俏皮元素
$Colors = @{
    Success   = "Green"
    Error     = "Red"
    Warning   = "Yellow"
    Info      = "Gray"
    Status    = "Magenta"
    IsRunning = "Cyan"
}
$PlayColors = @("Red","Green","Yellow","Blue","Magenta","Cyan")
$PlayEmojis = @("✨","🚀","🛠️","💫","🎯","😺","🌟","🔥","🍀","🎈","🥳")

# ── 俏皮输出辅助 ───────────────────────────────────────────────

function Get-RandomEmoji
{
    param([int]$Count = 1)
    $out = for ($i = 0; $i -lt $Count; $i++) { Get-Random -InputObject $PlayEmojis }
    return ($out -join '')
}

function Write-Playful
{
    param([Parameter(Mandatory = $true)][string]$Message, [string]$Level = "INFO")
    $emoji = Get-RandomEmoji -Count 1
    $color = Get-Random -InputObject $PlayColors
    $timestamp = Get-Date -Format "yyyy-MM-dd"
    Write-Host "[$timestamp]" -NoNewline -ForegroundColor DarkGray
    Write-Host " $emoji $Message" -ForegroundColor $color
}

function Write-Rainbow
{
    param([Parameter(Mandatory = $true)][string]$Text)
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
    Write-Rainbow -Text "=== BatchStart ==="
    Write-Playful -Message "批量应用启动管理 — 智能 CPU 调度模式" -Level "INFO"
}

# ── 日志函数 ───────────────────────────────────────────────────

function Write-Log
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("INFO","SUCCESS","WARNING","ERROR","ISRUN")]
        [string]$Level,
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$AppName = "",
        [switch]$LogOnly
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry  = "[$timestamp] [$Level]"
    if ($AppName) { $logEntry += " [$AppName]" }
    $logEntry += " $Message"

    # 写入日志文件
    if ($Global:LogConfig.WriteLog2Log)
    {
        Add-Content -Path $Global:LogConfig.LogFilePath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    }

    # 控制台输出
    if (-not $LogOnly)
    {
        $emoji = "ℹ️"
        $color = $Colors.Info
        switch ($Level)
        {
            "INFO"    { $color = $Colors.Info;      $emoji = "ℹ️" }
            "SUCCESS" { $color = $Colors.Success;   $emoji = "✅" }
            "WARNING" { $color = $Colors.Warning;   $emoji = "⚠️" }
            "ERROR"   { $color = $Colors.Error;     $emoji = "❌" }
            "ISRUN"   { $color = $Colors.IsRunning; $emoji = "🚂" }
        }

        $tag  = Get-Date -Format "yyyy-MM-dd"
        $text = if ($AppName) { "$emoji [$AppName] $Message" } else { "$emoji $Message" }
        Write-Host "[$tag] $text" -ForegroundColor $color
    }
}

# ── INI 解析（仅 [Logging] + [Applications]，兼容旧 [app] 段） ─

function Read-Config
{
    param([Parameter(Mandatory = $true)][string]$Path)

    $currentSection = $null
    $lines = Get-Content -Path $Path -Encoding UTF8 | Where-Object {
        $_ -notmatch '^\s*$' -and $_ -notmatch '^\s*[;#]'
    }

    foreach ($line in $lines)
    {
        if ($line -match '^\s*\[(\w+)\]\s*$')
        {
            $currentSection = $matches[1]
            continue
        }
        if (-not $currentSection -or $line -notmatch '^\s*(\w+)\s*=\s*(.*)\s*$') { continue }

        $key   = $matches[1]
        $value = $matches[2]

        if ($currentSection -eq "Applications" -or $currentSection -eq "app")
        {
            $Global:Apps += [PSCustomObject]@{ Name = $key; Path = $value }
        }
        elseif ($currentSection -eq "Logging")
        {
            if ($key -eq "WriteLog2Log")  { $Global:LogConfig.WriteLog2Log = ($value -eq 'true') }
            elseif ($key -eq "LogFilePath")
            {
                $p = $value
                if (-not [System.IO.Path]::IsPathRooted($p)) { $p = Join-Path -Path $ScriptDir -ChildPath $p }
                $Global:LogConfig.LogFilePath = $p
            }
            elseif ($key -eq "CPUThreshold")
            {
                $v = [double]$value
                if ($v -ge 0 -and $v -le 100) { $Global:LogConfig.CPUThreshold = $v }
            }
        }
    }

    # 环境变量覆盖
    $envThreshold = [Environment]::GetEnvironmentVariable("BATCHSTART_CPU_THRESHOLD")
    if ($envThreshold -and $envThreshold -match '^\d+$')
    {
        $v = [int]$envThreshold
        if ($v -ge 1 -and $v -le 100) { $Global:LogConfig.CPUThreshold = $v }
    }

    if ($Global:Apps.Count -eq 0) { throw "配置文件中没有定义任何应用！" }
}

# ── 路径工具 ──────────────────────────────────────────────────

function Get-ExePathOnly
{
    param([string]$AppPath)
    $t = $AppPath.Trim()
    if ($t -match '^"(.*?)"') { return $matches[1].Trim() }
    if ($t -match '^(.+?\.exe)') { return $matches[1].Trim() }
    return $t
}

function Split-ExeAndArgs
{
    param([Parameter(Mandatory = $true)][string]$AppPath)
    $t = $AppPath.Trim()
    if ($t -match '^"(.*?)"')
    {
        $exe  = $matches[1]
        $args = if ($t -match '^".*?"\s+(.*)$') { $matches[1] } else { "" }
    }
    elseif ($t -match '^(.+?\.exe)(.*)$')
    {
        $exe  = $matches[1]
        $args = $matches[2].Trim()
    }
    else { $exe = $t; $args = "" }

    if (-not (Test-Path -Path $exe -PathType Leaf)) { throw "可执行文件不存在: $exe" }
    $ext = [System.IO.Path]::GetExtension($exe)
    if ($ext -ne '.exe') { throw "不支持的文件类型: $ext，仅支持 .exe 文件" }

    return @{ ExecutablePath = $exe; Arguments = $args }
}

# ── 进程检查 ──────────────────────────────────────────────────

function Test-AppRunning
{
    param([string]$AppPath)
    $exeName = [System.IO.Path]::GetFileNameWithoutExtension((Get-ExePathOnly -AppPath $AppPath))
    $procs = Get-Process -Name $exeName -ErrorAction SilentlyContinue
    foreach ($p in $procs)
    {
        if ($p.Path -and (Split-Path -Leaf $p.Path) -eq "$exeName.exe") { return $true }
    }
    return $false
}

# ── CPU 感知：滑动窗口平均 ───────────────────────────────────

$cpuHistory = @()

function Get-CpuSmoothed
{
    $current = (Get-CimInstance -ClassName Win32_Processor |
        Measure-Object -Property LoadPercentage -Average).Average
    $script:cpuHistory += $current
    if ($script:cpuHistory.Count -gt $CPU_SAMPLES) {
        $script:cpuHistory = $script:cpuHistory[-$CPU_SAMPLES..-1]
    }
    return [math]::Round(($script:cpuHistory | Measure-Object -Average).Average, 1)
}

# ── 智能应用启动 ──────────────────────────────────────────────

function Start-OneApp
{
    param([string]$AppName, [string]$AppPath)

    # 已运行 → 跳过
    if (Test-AppRunning -AppPath $AppPath)
    {
        Write-Log -Level "ISRUN" -Message "⏏️ 应用已在运行，跳过启动" -AppName $AppName
        return $true
    }

    $cpuThreshold = $Global:LogConfig.CPUThreshold
    $waitStart = Get-Date

    # CPU 感知等待循环
    while ($true)
    {
        $cpu     = Get-CpuSmoothed
        $elapsed = (Get-Date) - $waitStart

        # 超时安全阀
        if ($elapsed.TotalSeconds -ge $MAX_WAIT_PER_APP)
        {
            Write-Log -Level "WARNING" -Message "⏰ 超过最大等待时间 ${MAX_WAIT_PER_APP}s，强制启动" -AppName $AppName
            break
        }

        # CPU 低于阈值 → 启动
        if ($cpu -le $cpuThreshold)
        {
            Write-Log -Level "INFO" -Message "💻 CPU 使用率 ${cpu}% ≤ 阈值 ${cpuThreshold}%，可以启动" -AppName $AppName
            break
        }

        # 自适应等待：负载越高等越久
        if ($cpu -gt 80)       { $sleepSec = 30 }
        elseif ($cpu -gt 60)   { $sleepSec = 15 }
        else                   { $sleepSec = 5 }

        Write-Log -Level "INFO" -Message "⏳ 等待 CPU 降低... 当前 ${cpu}% > ${cpuThreshold}%，等待 ${sleepSec}s（已等 $([math]::Round($elapsed.TotalSeconds,1))s）" -AppName $AppName
        Start-Sleep -Seconds $sleepSec
    }

    # 执行启动
    try
    {
        $exeInfo = Split-ExeAndArgs -AppPath $AppPath
        Write-Log -Level "INFO" -Message "⏩ 正在启动: $($exeInfo.ExecutablePath)" -AppName $AppName

        if ($exeInfo.Arguments) {
            $proc = Start-Process -FilePath $exeInfo.ExecutablePath -ArgumentList $exeInfo.Arguments -PassThru -ErrorAction Stop
        } else {
            $proc = Start-Process -FilePath $exeInfo.ExecutablePath -PassThru -ErrorAction Stop
        }

        # 短暂验证进程是否存活
        Start-Sleep -Seconds 1
        $alive = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
        if ($alive -and -not $alive.HasExited)
        {
            Write-Log -Level "SUCCESS" -Message "✅ 应用启动成功! (PID $($proc.Id))" -AppName $AppName
            return $true
        }
        else
        {
            Write-Log -Level "ERROR" -Message "❌ 应用启动后立即退出!" -AppName $AppName
            return $false
        }
    }
    catch
    {
        Write-Log -Level "ERROR" -Message "❌ 应用启动失败: $($_.Exception.Message)" -AppName $AppName
        if ($_.ScriptStackTrace) { Write-Log -Level "ERROR" -Message "错误堆栈: $($_.ScriptStackTrace)" -AppName $AppName -LogOnly }
        return $false
    }
}

# ── 主启动循环 ────────────────────────────────────────────────

function Start-Applications
{
    $appCount   = $Global:Apps.Count
    $cpuThreshold = $Global:LogConfig.CPUThreshold
    $launched = 0; $skipped = 0; $failed = 0

    Write-Log -Level "INFO" -Message "📋 共 $appCount 个应用待启动 · CPU 阈值: ${cpuThreshold}%"

    for ($i = 0; $i -lt $appCount; $i++)
    {
        $app      = $Global:Apps[$i]
        $appName  = $app.Name
        $appPath  = $app.Path

        Write-Host ""
        Write-Log -Level "INFO" -Message "📱 $($i+1)/${appCount}"
        Write-Log -Level "INFO" -Message "📁 路径: $appPath"
        Write-Log -Level "INFO" -Message "🚦 按顺序启动: $($i+1)/${appCount} -> $appName"

        $ok = Start-OneApp -AppName $appName -AppPath $appPath

        if ($ok) {
            if ((Test-AppRunning -AppPath $appPath)) { $skipped++ } else { $launched++ }
        } else {
            $failed++
            Write-Log -Level "ERROR" -Message "🤣 应用启动失败，继续下一个" -AppName $appName
        }

        # 呼吸间隔（最后一个不用等）
        if ($i -lt $appCount - 1)
        {
            Write-Log -Level "INFO" -Message "💨 等待 ${BREATH_SECONDS}s 让系统喘口气..."
            Start-Sleep -Seconds $BREATH_SECONDS
        }
    }

    Write-Host ""
    Write-Log -Level "SUCCESS" -Message "🎉 脚本执行完成！已启动 $launched / 跳过 $skipped / 失败 $failed"
}

# ── 入口 ──────────────────────────────────────────────────────

function Main
{
    try
    {
        Show-Banner
        Write-Playful -Message "使用配置: $ConfigFile — 出发！" -Level "INFO"

        Read-Config -Path $ConfigFile
        Start-Applications

        Write-Host "`n按任意键退出..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch
    {
        Write-Log -Level "ERROR" -Message "❌ 脚本执行出错：$($_.Exception.Message)"
        if ($_.ScriptStackTrace) { Write-Log -Level "ERROR" -Message "错误堆栈: $($_.ScriptStackTrace)" }
        if ($_.Exception.InnerException) { Write-Log -Level "ERROR" -Message "内部异常: $($_.Exception.InnerException.Message)" }
        exit 1
    }
}

# 调用主函数
Main
