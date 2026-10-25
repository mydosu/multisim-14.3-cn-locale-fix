<#
.SYNOPSIS
    还原快捷方式和语言包。
.DESCRIPTION
    恢复开始菜单快捷方式、用 English.orig-en 覆盖 English。
    不会删除 Locale Emulator Plus 目录（要删请手动）。
#>
param(
    [string]$StringFiles = "C:\Program Files (x86)\National Instruments\Circuit Design Suite 14.3\stringfiles"
)

$ErrorActionPreference = 'Stop'

if (Get-Process multisim -ErrorAction SilentlyContinue) { throw "请先完全关闭 Multisim" }

# 1. 快捷方式
$lnk = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\National Instruments\Circuit Design Suite 14.3\Multisim 14.3.lnk"
$bak = $lnk + ".orig"
if (Test-Path $bak) {
    Copy-Item -LiteralPath $bak -Destination $lnk -Force
    Write-Host "已恢复原快捷方式"
} else {
    Write-Host "没有快捷方式备份，跳过"
}

# 2. 语言包
$en   = Join-Path $StringFiles "English"
$orig = Join-Path $StringFiles "English.orig-en"
if (Test-Path $orig) {
    if (Test-Path $en) { Remove-Item $en -Recurse -Force }
    Copy-Item $orig $en -Recurse -Force
    Write-Host "已恢复英文语言包"
} else {
    Write-Host "没有语言包备份，跳过"
}

Write-Host ""
Write-Host "回滚完成。想彻底移除 Locale Emulator Plus，手动删除它的安装目录即可。"
