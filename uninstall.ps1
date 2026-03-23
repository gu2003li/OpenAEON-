# OpenAEON Windows 卸载脚本
# 使用方法: iwr -useb https://raw.githubusercontent.com/gu2003li/OpenAEON/main/uninstall.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  🦞 OpenAEON 卸载程序" -ForegroundColor Cyan
Write-Host ""

# 1. 停止并卸载网关服务
try {
    if (Get-Command openaeon -ErrorAction SilentlyContinue) {
        Write-Host "[*] 正在停止并卸载 OpenAEON 网关服务..." -ForegroundColor Yellow
        openaeon gateway stop 2>$null | Out-Null
        openaeon gateway uninstall --force 2>$null | Out-Null
        Write-Host "[OK] 网关服务已移除" -ForegroundColor Green
    }
}
catch {
    Write-Host "[!] 网关服务卸载失败，继续执行..." -ForegroundColor Gray
}

# 2. 卸载全局 NPM 包
try {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "[*] 正在移除全局 openaeon 包..." -ForegroundColor Yellow
        npm uninstall -g openaeon 2>$null | Out-Null
        Write-Host "[OK] NPM 包已卸载" -ForegroundColor Green
    }
}
catch {
    Write-Host "[!] NPM 包卸载失败，继续执行..." -ForegroundColor Gray
}

# 3. 移除本地启动脚本
$userHome = [Environment]::GetFolderPath("UserProfile")
$cmdPath = Join-Path $userHome ".local\bin\openaeon.cmd"
if (Test-Path $cmdPath) {
    Write-Host "[*] 正在移除本地启动脚本: $cmdPath..." -ForegroundColor Yellow
    Remove-Item -Force $cmdPath
    Write-Host "[OK] 启动脚本已移除" -ForegroundColor Green
}

# 4. 配置文件与数据（默认不自动删除）
$configPath = Join-Path $userHome ".openaeon.json"
$dataDir = Join-Path $userHome ".openaeon"

Write-Host ""
Write-Host "[!] 配置文件与会话数据不会被自动删除。" -ForegroundColor Yellow
Write-Host "如需彻底清除所有数据，请手动删除以下内容:" -ForegroundColor Gray
Write-Host "  $configPath"
Write-Host "  $dataDir"
Write-Host "  $(Join-Path $userHome ".clawdbot")"
Write-Host "  $(Join-Path $userHome ".moltbot")"
Write-Host ""

Write-Host "[OK] OpenAEON 已成功卸载。清理完成！🎯" -ForegroundColor Green