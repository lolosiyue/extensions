param(
    [switch]$Check,
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$targetDir = Join-Path $repoRoot 'extensions'
$configPath = Join-Path $repoRoot 'stylua.toml'

if (-not (Test-Path $targetDir)) {
    throw "Target folder not found: $targetDir"
}

if (-not (Test-Path $configPath)) {
    throw "Config file not found: $configPath"
}

$stylua = $null
try {
    $cmd = Get-Command stylua -ErrorAction Stop
    $stylua = $cmd.Source
} catch {
    $cargoStylua = Join-Path $env:USERPROFILE '.cargo\bin\stylua.exe'
    $vscodeStylua = Join-Path $env:APPDATA 'Code\\User\\globalStorage\\johnnymorganz.stylua\\stylua.exe'
    if (Test-Path $cargoStylua) {
        $stylua = $cargoStylua
    } elseif (Test-Path $vscodeStylua) {
        $stylua = $vscodeStylua
    }
}

if (-not $stylua) {
    Write-Host 'stylua not found.' -ForegroundColor Yellow
    Write-Host 'Install one of the following, then re-run this task:' -ForegroundColor Yellow
    Write-Host '  winget install --id JohnnyMorganz.Stylua -e'
    Write-Host '  cargo install stylua'
    exit 1
}

$baseArgs = @('--config-path', $configPath)
if ($Check) {
    $baseArgs += '--check'
}

Write-Host "Using stylua: $stylua"
Write-Host "Target folder: $targetDir"

$luaFiles = Get-ChildItem -Path $targetDir -Recurse -File -Filter '*.lua' | Sort-Object FullName
$okCount = 0
$failList = @()

foreach ($file in $luaFiles) {
    $runArgs = @()
    $runArgs += $baseArgs
    $runArgs += $file.FullName

    $quotedArgs = ($runArgs | ForEach-Object {
        if ($_ -match '\s') { '"' + $_ + '"' } else { $_ }
    }) -join ' '

    $proc = Start-Process -FilePath $stylua -ArgumentList $quotedArgs -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        $okCount += 1
    } else {
        $failList += $file.FullName
    }
}

Write-Host ("Processed {0} file(s): ok={1}, failed={2}" -f $luaFiles.Count, $okCount, $failList.Count)
if ($failList.Count -gt 0) {
    Write-Host 'Failed files:' -ForegroundColor Yellow
    $failList | ForEach-Object { Write-Host (" - {0}" -f $_) }
}

if ($Check) {
    if ($failList.Count -gt 0) {
        exit 1
    }
    exit 0
}

if ($Strict -and $failList.Count -gt 0) {
    exit 1
}
exit 0
