# OpenAEON 安装程序 Windows
# 使用方法: iwr -useb https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.ps1 | iex
#        & ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.ps1))) -Tag beta -NoOnboard -DryRun

param(
    [string]$Tag = "latest",
    [ValidateSet("npm", "git")]
    [string]$InstallMethod = "git",
    [string]$GitDir,
    [switch]$NoOnboard,
    [switch]$NoGitUpdate,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  OpenAEON 安装程序" -ForegroundColor Cyan
Write-Host ""

# 检查是否在 PowerShell 中运行
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "错误：需要 PowerShell 5 或更高版本" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] 已检测到 Windows 系统" -ForegroundColor Green

if (-not $PSBoundParameters.ContainsKey("InstallMethod")) {
    if (-not [string]::IsNullOrWhiteSpace($env:OPENAEON_INSTALL_METHOD)) {
        $InstallMethod = $env:OPENAEON_INSTALL_METHOD
    }
}
if (-not $PSBoundParameters.ContainsKey("GitDir")) {
    if (-not [string]::IsNullOrWhiteSpace($env:OPENAEON_GIT_DIR)) {
        $GitDir = $env:OPENAEON_GIT_DIR
    }
}
if (-not $PSBoundParameters.ContainsKey("NoOnboard")) {
    if ($env:OPENAEON_NO_ONBOARD -eq "1") {
        $NoOnboard = $true
    }
}
if (-not $PSBoundParameters.ContainsKey("NoGitUpdate")) {
    if ($env:OPENAEON_GIT_UPDATE -eq "0") {
        $NoGitUpdate = $true
    }
}
if (-not $PSBoundParameters.ContainsKey("DryRun")) {
    if ($env:OPENAEON_DRY_RUN -eq "1") {
        $DryRun = $true
    }
}

if ([string]::IsNullOrWhiteSpace($GitDir)) {
    $userHome = [Environment]::GetFolderPath("UserProfile")
    $GitDir = (Join-Path $userHome "openaeon")
}

# 检查 Node.js
function Check-Node {
    try {
        $nodeVersion = (node -v 2>$null)
        if ($nodeVersion) {
            $version = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
            if ($version -ge 22) {
                Write-Host "[OK] 已找到 Node.js $nodeVersion" -ForegroundColor Green
                return $true
            } else {
                Write-Host "[!] 已找到 Node.js $nodeVersion，但需要 v22 或更高版本" -ForegroundColor Yellow
                return $false
            }
        }
    } catch {
        Write-Host "[!] 未找到 Node.js" -ForegroundColor Yellow
        return $false
    }
    return $false
}

# 安装 Node.js
function Install-Node {
    Write-Host "[*] 正在安装 Node.js..." -ForegroundColor Yellow

    # 优先使用 winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  使用 winget..." -ForegroundColor Gray
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements

        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Host "[OK] 已通过 winget 安装 Node.js" -ForegroundColor Green
        return
    }

    # 尝试 Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "  使用 Chocolatey..." -ForegroundColor Gray
        choco install nodejs-lts -y

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Host "[OK] 已通过 Chocolatey 安装 Node.js" -ForegroundColor Green
        return
    }

    # 尝试 Scoop
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "  使用 Scoop..." -ForegroundColor Gray
        scoop install nodejs-lts
        Write-Host "[OK] 已通过 Scoop 安装 Node.js" -ForegroundColor Green
        return
    }

    # 无包管理器，提示手动安装
    Write-Host ""
    Write-Host "错误：未找到可用的包管理器（winget、choco 或 scoop）" -ForegroundColor Red
    Write-Host ""
    Write-Host "请手动安装 Node.js 22+：" -ForegroundColor Yellow
    Write-Host "  https://nodejs.org/en/download/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "或从微软应用商店安装 winget（应用安装程序）。" -ForegroundColor Gray
    exit 1
}

# 检查是否已安装 OpenAEON
function Check-ExistingOpenAEON {
    try {
        $null = Get-Command openaeon -ErrorAction Stop
        Write-Host "[*] 检测到已安装的 OpenAEON" -ForegroundColor Yellow
        return $true
    } catch {
        return $false
    }
}

# 卸载旧版 OpenAEON
function Uninstall-ExistingOpenAEON {
    Write-Host "[*] 正在卸载现有版本，准备安装新版..." -ForegroundColor Yellow
    
    try {
        openaeon gateway uninstall --force 2>$null | Out-Null
    } catch {}

    try {
        Write-Host "  正在全局卸载 NPM 包 openaeon..." -ForegroundColor Gray
        npm uninstall -g openaeon 2>$null | Out-Null
    } catch {}
    
    Write-Host "[OK] 旧版 OpenAEON 已清理完成（如有）" -ForegroundColor Green
}

function Check-Git {
    try {
        $null = Get-Command git -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Require-Git {
    if (Check-Git) { return }
    Write-Host ""
    Write-Host "错误：使用 git 安装方式必须先安装 Git" -ForegroundColor Red
    Write-Host "请安装 Git for Windows：" -ForegroundColor Yellow
    Write-Host "  https://git-scm.com/download/win" -ForegroundColor Cyan
    Write-Host "安装完成后重新运行此脚本。" -ForegroundColor Yellow
    exit 1
}

# 确保 openaeon 命令在 PATH 中可用
function Ensure-OpenAEONOnPath {
    if (Get-Command openaeon -ErrorAction SilentlyContinue) {
        return $true
    }

    $npmPrefix = $null
    try {
        $npmPrefix = (npm config get prefix 2>$null).Trim()
    } catch {
        $npmPrefix = $null
    }

    if (-not [string]::IsNullOrWhiteSpace($npmPrefix)) {
        $npmBin = Join-Path $npmPrefix "bin"
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if (-not ($userPath -split ";" | Where-Object { $_ -ieq $npmBin })) {
            [Environment]::SetEnvironmentVariable("Path", "$userPath;$npmBin", "User")
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-Host "[!] 已将 $npmBin 添加到用户 PATH（若命令未找到请重启终端）" -ForegroundColor Yellow
        }
        if (Test-Path (Join-Path $npmBin "openaeon.cmd")) {
            return $true
        }
    }

    Write-Host "[!] openaeon 暂未加入 PATH" -ForegroundColor Yellow
    Write-Host "请重启 PowerShell 或将 npm 全局目录添加到 PATH。" -ForegroundColor Yellow
    if ($npmPrefix) {
        Write-Host "预期路径：$npmPrefix\\bin" -ForegroundColor Cyan
    } else {
        Write-Host "提示：执行 npm config get prefix 查看全局路径" -ForegroundColor Gray
    }
    return $false
}

# 确保安装 pnpm
function Ensure-Pnpm {
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        return
    }
    if (Get-Command corepack -ErrorAction SilentlyContinue) {
        try {
            corepack enable | Out-Null
            corepack prepare pnpm@latest --activate | Out-Null
            if (Get-Command pnpm -ErrorAction SilentlyContinue) {
                Write-Host "[OK] 已通过 corepack 安装 pnpm" -ForegroundColor Green
                return
            }
        } catch {
        }
    }
    Write-Host "[*] 正在安装 pnpm..." -ForegroundColor Yellow
    npm install -g pnpm
    Write-Host "[OK] pnpm 安装完成" -ForegroundColor Green
}

# 通过 npm 安装 OpenAEON
function Install-OpenAEON {
    if ([string]::IsNullOrWhiteSpace($Tag)) {
        $Tag = "latest"
    }
    $packageName = "openaeon"
    if ($Tag -eq "beta" -or $Tag -match "^beta\.") {
        $packageName = "openaeon"
    }
    Write-Host "[*] 正在安装 OpenAEON ($packageName@$Tag)..." -ForegroundColor Yellow

    $prevLogLevel = $env:NPM_CONFIG_LOGLEVEL
    $prevUpdateNotifier = $env:NPM_CONFIG_UPDATE_NOTIFIER
    $prevFund = $env:NPM_CONFIG_FUND
    $prevAudit = $env:NPM_CONFIG_AUDIT
    $env:NPM_CONFIG_LOGLEVEL = "error"
    $env:NPM_CONFIG_UPDATE_NOTIFIER = "false"
    $env:NPM_CONFIG_FUND = "false"
    $env:NPM_CONFIG_AUDIT = "false"

    try {
        $npmOutput = npm install -g "$packageName@$Tag" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[!] npm 安装失败" -ForegroundColor Red
            if ($npmOutput -match "spawn git" -or $npmOutput -match "ENOENT.*git") {
                Write-Host "错误：PATH 中未找到 git" -ForegroundColor Red
                Write-Host "请安装 Git for Windows 后重启终端重试：" -ForegroundColor Yellow
                Write-Host "  https://git-scm.com/download/win" -ForegroundColor Cyan
            } else {
                Write-Host "可使用详细输出查看完整错误：" -ForegroundColor Yellow
                Write-Host "  iwr -useb https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.ps1 | iex" -ForegroundColor Cyan
            }
            $npmOutput | ForEach-Object { Write-Host $_ }
            exit 1
        }
    } finally {
        $env:NPM_CONFIG_LOGLEVEL = $prevLogLevel
        $env:NPM_CONFIG_UPDATE_NOTIFIER = $prevUpdateNotifier
        $env:NPM_CONFIG_FUND = $prevFund
        $env:NPM_CONFIG_AUDIT = $prevAudit
    }
    Write-Host "[OK] OpenAEON 安装完成" -ForegroundColor Green
}

# 通过 GitHub 源码安装
function Install-OpenAEONFromGit {
    param(
        [string]$RepoDir,
        [switch]$SkipUpdate
    )
    Require-Git
    Ensure-Pnpm

    $repoUrl = "https://github.com/gu2003li/OpenAEON.git"
    Write-Host "[*] 正在从 GitHub 安装 OpenAEON ($repoUrl)..." -ForegroundColor Yellow

    if (-not (Test-Path $RepoDir)) {
        git clone $repoUrl $RepoDir
    }

    if (-not $SkipUpdate) {
        if (-not (git -C $RepoDir status --porcelain 2>$null)) {
            git -C $RepoDir pull --rebase 2>$null
        } else {
            Write-Host "[!] 仓库存在修改，跳过 git pull" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[!] 已禁用 Git 更新，跳过拉取" -ForegroundColor Yellow
    }

    Remove-LegacySubmodule -RepoDir $RepoDir

    pnpm -C $RepoDir install
    if (-not (pnpm -C $RepoDir ui:build)) {
        Write-Host "[!] UI 构建失败，继续执行（CLI 仍可使用）" -ForegroundColor Yellow
    }
    pnpm -C $RepoDir build

    $binDir = Join-Path $env:USERPROFILE ".local\\bin"
    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    }
    $cmdPath = Join-Path $binDir "openaeon.cmd"
    $cmdContents = "@echo off`r`nnode ""$RepoDir\\dist\\entry.js"" %*`r`n"
    Set-Content -Path $cmdPath -Value $cmdContents -NoNewline

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not ($userPath -split ";" | Where-Object { $_ -ieq $binDir })) {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Host "[!] 已将 $binDir 添加到用户 PATH（若命令未找到请重启终端）" -ForegroundColor Yellow
    }

    Write-Host "[OK] 已安装 OpenAEON 启动脚本到 $cmdPath" -ForegroundColor Green
    Write-Host "[i] 源码版本使用 pnpm，依赖安装请用 pnpm install，不要用 npm install" -ForegroundColor Gray
}

# 执行迁移检查
function Run-Doctor {
    Write-Host "[*] 正在执行配置迁移检查..." -ForegroundColor Yellow
    try {
        openaeon doctor --non-interactive
    } catch {
    }
    Write-Host "[OK] 迁移完成" -ForegroundColor Green
}

function Test-GatewayServiceLoaded {
    try {
        $statusJson = (openaeon daemon status --json 2>$null)
        if ([string]::IsNullOrWhiteSpace($statusJson)) {
            return $false
        }
        $parsed = $statusJson | ConvertFrom-Json
        if ($parsed -and $parsed.service -and $parsed.service.loaded) {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# 刷新网关服务
function Refresh-GatewayServiceIfLoaded {
    if (-not (Get-Command openaeon -ErrorAction SilentlyContinue)) {
        return
    }
    if (-not (Test-GatewayServiceLoaded)) {
        return
    }

    Write-Host "[*] 正在刷新已加载的网关服务..." -ForegroundColor Yellow
    try {
        openaeon gateway install --force | Out-Null
    } catch {
        Write-Host "[!] 网关服务刷新失败，继续执行" -ForegroundColor Yellow
        return
    }

    try {
        openaeon gateway restart | Out-Null
        openaeon gateway status --probe --json | Out-Null
        Write-Host "[OK] 网关服务已刷新" -ForegroundColor Green
    } catch {
        Write-Host "[!] 网关服务重启失败，继续执行" -ForegroundColor Yellow
    }
}

function Get-LegacyRepoDir {
    if (-not [string]::IsNullOrWhiteSpace($env:OPENAEON_GIT_DIR)) {
        return $env:OPENAEON_GIT_DIR
    }
    $userHome = [Environment]::GetFolderPath("UserProfile")
    return (Join-Path $userHome "openaeon")
}

function Remove-LegacySubmodule {
    param(
        [string]$RepoDir
    )
    if ([string]::IsNullOrWhiteSpace($RepoDir)) {
        $RepoDir = Get-LegacyRepoDir
    }
    $legacyDir = Join-Path $RepoDir "Peekaboo"
    if (Test-Path $legacyDir) {
        Write-Host "[!] 正在清理旧的子模块目录：$legacyDir" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $legacyDir
    }
}

# 主安装流程
function Main {
    if ($InstallMethod -ne "npm" -and $InstallMethod -ne "git") {
        Write-Host "错误：无效的安装方式，请使用 npm 或 git" -ForegroundColor Red
        exit 2
    }

    if ($DryRun) {
        Write-Host "[OK] 模拟运行模式" -ForegroundColor Green
        Write-Host "[OK] 安装方式：$InstallMethod" -ForegroundColor Green
        if ($InstallMethod -eq "git") {
            Write-Host "[OK] Git 目录：$GitDir" -ForegroundColor Green
            if ($NoGitUpdate) {
                Write-Host "[OK] Git 更新：已禁用" -ForegroundColor Green
            } else {
                Write-Host "[OK] Git 更新：已启用" -ForegroundColor Green
            }
        }
        if ($NoOnboard) {
            Write-Host "[OK] 初始化引导：已跳过" -ForegroundColor Green
        }
        return
    }

    Remove-LegacySubmodule -RepoDir $RepoDir

    # 检查旧版本
    $isUpgrade = Check-ExistingOpenAEON
    if ($isUpgrade) {
        Uninstall-ExistingOpenAEON
    }

    # 检查并安装 Node.js
    if (-not (Check-Node)) {
        Install-Node

        if (-not (Check-Node)) {
            Write-Host ""
            Write-Host "错误：Node.js 安装完成后可能需要重启终端" -ForegroundColor Red
            Write-Host "请关闭当前终端，重新打开后再运行安装脚本。" -ForegroundColor Yellow
            exit 1
        }
    }

    $finalGitDir = $null

    # 安装 OpenAEON
    if ($InstallMethod -eq "git") {
        $finalGitDir = $GitDir
        Install-OpenAEONFromGit -RepoDir $GitDir -SkipUpdate:$NoGitUpdate
    } else {
        Install-OpenAEON
    }

    if (-not (Ensure-OpenAEONOnPath)) {
        Write-Host "安装完成，但 OpenAEON 暂未加入 PATH" -ForegroundColor Yellow
        Write-Host "打开新终端后执行：openaeon doctor" -ForegroundColor Cyan
        return
    }

    Refresh-GatewayServiceIfLoaded

    # 升级或源码安装时执行迁移
    if ($isUpgrade -or $InstallMethod -eq "git") {
        Run-Doctor
    }

    $installedVersion = $null
    try {
        $installedVersion = (openaeon --version 2>$null).Trim()
    } catch {
        $installedVersion = $null
    }
    if (-not $installedVersion) {
        try {
            $npmList = npm list -g --depth 0 --json 2>$null | ConvertFrom-Json
            if ($npmList -and $npmList.dependencies -and $npmList.dependencies.openaeon -and $npmList.dependencies.openaeon.version) {
                $installedVersion = $npmList.dependencies.openaeon.version
            }
        } catch {
            $installedVersion = $null
        }
    }

    Write-Host ""
    if ($installedVersion) {
        Write-Host "OpenAEON 安装成功（版本：$installedVersion）！" -ForegroundColor Green
    } else {
        Write-Host "OpenAEON 安装成功！" -ForegroundColor Green
    }
    Write-Host ""

    # 结尾趣味文案
    if ($isUpgrade) {
        $updateMessages = @(
            "等级提升！解锁新技能。不用谢~",
            "代码焕然一新，龙虾还是那只～想我了吗？",
            "强势回归，更强更稳。你有没有发现我消失过？",
            "更新完成！出门这段时间学了点新把戏。",
            "升级完成！现在傲娇值提升 23%。",
            "我已进化。努力跟上我的节奏吧。",
            "新版本上线，你哪位？哦是我，只是更闪亮了。",
            "漏洞修完，打磨完毕，钳子就位。开干。",
            "龙虾已完成蜕壳。壳更硬，钳更利。",
            "更新搞定！想看更新日志也行，信我准没错。",
            "从 npm 的沸水里重生归来，现在更强了。",
            "离开一趟，回来更聪明了。你有空也试试。",
            "更新完成。BUG 都被我吓跑了。",
            "新版本已安装。旧版本托我向你问好。",
            "固件全新升级，脑回路更丰富了。",
            "我见过你难以置信的东西。总之，我更新好了。",
            "重新上线。更新日志很长，但我们的友谊更长。",
            "升级完成！Peter 修了一堆问题，炸了找他。",
            "蜕壳完毕。拜托别看我软软的那段时期。",
            "版本号提升！还是原来的整活风格，崩溃更少了（大概）。"
        )
        Write-Host (Get-Random -InputObject $updateMessages) -ForegroundColor Gray
        Write-Host ""
    } else {
        $completionMessages = @(
            "嗯不错，这地方我喜欢。有啥吃的没？",
            "到家啦。放心，我不会乱翻你东西的。",
            "就位成功。让我们来点可控的小混乱。",
            "安装完成。你的工作效率即将变得不太正常。",
            "安顿好了。是时候自动化你的生活了，不管你准没准备好。",
            "真舒服。我已经看过你的日程了，我们得聊聊。",
            "终于收拾完毕。现在，把你的问题都交出来。",
            "钳子咔咔作响 好了，我们要做点什么？",
            "龙虾已登陆。你的终端从此不再普通。",
            "搞定！我保证只稍微吐槽一下你的代码。"
        )
        Write-Host (Get-Random -InputObject $completionMessages) -ForegroundColor Gray
        Write-Host ""
    }

    if ($InstallMethod -eq "git") {
        Write-Host "源码目录：$finalGitDir" -ForegroundColor Cyan
        Write-Host "启动脚本：$env:USERPROFILE\\.local\\bin\openaeon.cmd" -ForegroundColor Cyan
        Write-Host ""
    }

    if ($isUpgrade) {
        Write-Host "升级完成。执行 " -NoNewline
        Write-Host "openaeon doctor" -ForegroundColor Cyan -NoNewline
        Write-Host " 检查剩余迁移项。"
    } else {
        if ($NoOnboard) {
            Write-Host "已跳过初始化引导。稍后可执行 " -NoNewline
            Write-Host "openaeon onboard" -ForegroundColor Cyan -NoNewline
            Write-Host " 开始配置。"
        } else {
            Write-Host "正在启动初始化引导..." -ForegroundColor Cyan
            Write-Host ""
            openaeon onboard
        }
    }
}

Main