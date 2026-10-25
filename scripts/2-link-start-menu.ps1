<#
.SYNOPSIS
    把开始菜单里的 Multisim 14.3 快捷方式改成经 LEPProc 启动（en-US 区域）。
.DESCRIPTION
    原快捷方式备份为 Multisim 14.3.lnk.orig，用 9-rollback.ps1 可还原。
.PARAMETER LeDir
    LocaleEmulatorPlus 所在目录（含 LEPProc_x86.exe）
.PARAMETER CdDir
    Circuit Design Suite 14.3 安装目录
#>
param(
    [string]$LeDir = "D:\Tools\LocaleEmulatorPlus\LocaleEmulatorPlus",
    [string]$CdDir = "C:\Program Files (x86)\National Instruments\Circuit Design Suite 14.3"
)

$ErrorActionPreference = 'Stop'

$lnk = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\National Instruments\Circuit Design Suite 14.3\Multisim 14.3.lnk"
if (-not (Test-Path $lnk)) { throw "找不到快捷方式: $lnk" }

$leproc = Join-Path $LeDir "LEPProc_x86.exe"
$exe    = Join-Path $CdDir "multisim.exe"
if (-not (Test-Path $leproc)) { throw "找不到 LEPProc_x86.exe，请先运行 1-install-locale-emulator.ps1" }
if (-not (Test-Path $exe))    { throw "找不到 multisim.exe: $exe" }

$bak = $lnk + ".orig"
if (-not (Test-Path $bak)) {
    Copy-Item -LiteralPath $lnk -Destination $bak -Force
    Write-Host "原快捷方式已备份: $bak"
} else {
    Write-Host "备份已存在，不覆盖: $bak"
}

$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnk)
$sc.TargetPath        = $leproc
$sc.Arguments         = '"' + $exe + '"'
$sc.WorkingDirectory  = $CdDir
$sc.IconLocation      = $exe + ",0"
$sc.Description       = "NI Multisim 14.3 (via Locale Emulator, en-US)"
$sc.Save()

$chk = $ws.CreateShortcut($lnk)
Write-Host ""
Write-Host "已修改: $lnk"
Write-Host ("  Target: " + $chk.TargetPath)
Write-Host ("  Args  : " + $chk.Arguments)
Write-Host ""
Write-Host "现在从开始菜单点 Multisim 14.3 即可。"
Write-Host "注意：直接双击 multisim.exe 不会经过 LE，仍会走中文区域。"
