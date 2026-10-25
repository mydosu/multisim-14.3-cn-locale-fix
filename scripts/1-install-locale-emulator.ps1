<#
.SYNOPSIS
    下载并配置 Locale Emulator Plus，用于让 Multisim 以 en-US 区域运行。
.DESCRIPTION
    原版 xupefei/Locale-Emulator 的发布包缺 LECommonLibrary.dll，LEProc 会崩。
    这里用维护中的 julixian/LocaleEmulatorPlus。
.PARAMETER Dest
    安装目录，默认 D:\Tools\LocaleEmulatorPlus
#>
param(
    [string]$Dest = "D:\Tools\LocaleEmulatorPlus"
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$api = "https://api.github.com/repos/julixian/LocaleEmulatorPlus/releases/latest"
# GitHub 直连不通时走镜像
$mirrors = @("", "https://gh-proxy.com/", "https://ghproxy.net/")

Write-Host "获取最新版本信息..."
$release = $null
foreach ($m in $mirrors) {
    try {
        $release = Invoke-RestMethod -Uri ($m + $api) -Headers @{ "User-Agent" = "powershell" } -TimeoutSec 25
        if ($release.assets) { break }
    } catch {
        Write-Host ("  失败: " + ($(if ($m) { $m } else { "直连" })))
        $release = $null
    }
}
if (-not $release) { throw "无法获取 release 信息，请手动下载 https://github.com/julixian/LocaleEmulatorPlus/releases" }

$asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
if (-not $asset) { throw "该 release 里没有 zip 资源" }
Write-Host ("版本 " + $release.tag_name + " -> " + $asset.name)

New-Item -ItemType Directory -Path $Dest -Force | Out-Null
$zip = Join-Path $Dest "LocaleEmulatorPlus.zip"

$ok = $false
foreach ($m in $mirrors) {
    try {
        Write-Host ("下载中: " + ($(if ($m) { $m } else { "直连" })))
        Invoke-WebRequest -Uri ($m + $asset.browser_download_url) -OutFile $zip -UseBasicParsing -TimeoutSec 240
        $ok = $true
        break
    } catch {
        Write-Host "  下载失败，换下一个源"
    }
}
if (-not $ok) { throw "下载失败，请手动下载后解压到 $Dest" }

Expand-Archive -LiteralPath $zip -DestinationPath $Dest -Force
$inner = Join-Path $Dest "LocaleEmulatorPlus"
if (-not (Test-Path $inner)) { throw "解压后找不到 LocaleEmulatorPlus 目录" }

# 写全局 profile：只放一个 en-US，LEProc 取第一个
$xml = @'
<?xml version="1.0" encoding="utf-8"?>
<LEConfig>
  <Profiles>
    <Profile Name="English (United States)" Guid="3f2a9c11-7b4d-4a2e-9e8f-1c5d6b7a8e90" MainMenu="true">
      <Parameter></Parameter>
      <Location>en-US</Location>
      <Timezone>China Standard Time</Timezone>
      <RunAsAdmin>false</RunAsAdmin>
      <RedirectRegistry>true</RedirectRegistry>
      <IsAdvancedRedirection>false</IsAdvancedRedirection>
      <RunWithSuspend>false</RunWithSuspend>
    </Profile>
  </Profiles>
</LEConfig>
'@
$xml | Out-File -FilePath (Join-Path $inner "LEPConfig.xml") -Encoding UTF8

Write-Host ""
Write-Host "完成，安装目录: $inner"
Get-ChildItem $inner -File | Select-Object Name, Length | Format-Table -AutoSize
Write-Host "下一步: .\2-link-start-menu.ps1 -LeDir `"$inner`""
