<#
.SYNOPSIS
    把中文语言包逐条合并进 English 目录，让 Multisim 在 en-US 区域下仍显示中文界面。
.DESCRIPTION
    不能整文件覆盖：中文包比英文包少一批 ID，直接覆盖会让程序把 ID 名当文本显示
    （界面上出现 IDS_PROPPAGE_xxx 这种）。
    这里以英文原包为底，按 ID 替换，中文没有的 ID 保留英文。
.PARAMETER StringFiles
    stringfiles 目录
#>
param(
    [string]$StringFiles = "C:\Program Files (x86)\National Instruments\Circuit Design Suite 14.3\stringfiles"
)

$ErrorActionPreference = 'Stop'

if (Get-Process multisim -ErrorAction SilentlyContinue) { throw "请先完全关闭 Multisim" }

$en  = Join-Path $StringFiles "English"
$cn  = Join-Path $StringFiles "Chinese-simplified"
$bak = Join-Path $StringFiles "English.orig-en"

if (-not (Test-Path $en)) { throw "找不到 $en" }
if (-not (Test-Path $cn)) { throw "找不到 $cn（没有中文语言包？）" }

if (-not (Test-Path $bak)) {
    Copy-Item $en $bak -Recurse -Force
    Write-Host "原英文包已备份: $bak"
} else {
    Write-Host "英文包备份已存在，复用它作为基底: $bak"
}

$enc = New-Object System.Text.UnicodeEncoding($false, $true)   # UTF-16LE + BOM
$files = 0
$repl  = 0

foreach ($f in (Get-ChildItem $bak -File)) {
    $enText = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($f.FullName))

    $map = @{}
    $cnPath = Join-Path $cn $f.Name
    if (Test-Path -LiteralPath $cnPath) {
        $cnText = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($cnPath))
        foreach ($line in ($cnText -split "`r`n")) {
            $i = $line.IndexOf('=>')
            if ($i -gt 0) { $map[$line.Substring(0, $i)] = $line }
        }
    }

    $n = 0
    $outLines = foreach ($line in ($enText -split "`r`n")) {
        $i = $line.IndexOf('=>')
        if ($i -gt 0) {
            $id = $line.Substring(0, $i)
            if ($map.ContainsKey($id)) { $n++; $map[$id] } else { $line }
        } else { $line }
    }

    [IO.File]::WriteAllText((Join-Path $en $f.Name), ($outLines -join "`r`n"), $enc)
    $files++
    $repl += $n
}

Write-Host ""
Write-Host "合并完成: 文件=$files  替换词条=$repl"

$bad = 0
Get-ChildItem $en -File -Filter *.ewstr | ForEach-Object {
    $t = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($_.FullName))
    $bad += ([regex]::Matches($t, '=>\s*IDS_')).Count
}
Write-Host "仍有 '=>IDS_' 的行数: $bad  (应为 0)"

$cjk = 0
Get-ChildItem $en -File -Filter *.ewstr | ForEach-Object {
    $t = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($_.FullName))
    $cjk += ([regex]::Matches($t, '[\u4e00-\u9fff]')).Count
}
Write-Host "English 目录汉字总数: $cjk"
Write-Host ""
Write-Host "说明：汉化包对 14.3.0 覆盖不全（尤其 asysdll 的仿真分析对话框），"
Write-Host "那部分会显示英文原文，这是汉化包自身的限制。"
