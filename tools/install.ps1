<#
.SYNOPSIS
  XFSKILL installer: backup the installed version, copy files, patch allegro.ilinit.

.DESCRIPTION
  One command installs or upgrades XFSKILL:
    1. read the source VERSION
    2. if an older install exists, back it up to <Target>\_backup\<ver>_<timestamp>
    3. copy the payload (main.il, core, modules, forms, config, VERSION, CHANGELOG.md, tools, references)
    4. write an idempotent marker block into allegro.ilinit
  Rollback restores a backup directory and rewrites the marker block:
    powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Rollback 0.1.0_20261010_083000

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\install.ps1
  powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Silent
  powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Target D:/XFSKILL -IlInit C:/home/pcbenv/allegro.ilinit
#>
[CmdletBinding()]
param(
  [string]$Target = "",
  [string]$IlInit = "",
  [string]$Rollback = "",
  [switch]$Silent
)

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$markerBegin = '; >>> XFSKILL BEGIN (managed by install.ps1) >>>'
$markerEnd = '; <<< XFSKILL END <<<'
$payloadDirs = @('core', 'modules', 'forms', 'config', 'tools', 'references')
$payloadFiles = @('main.il', 'VERSION', 'CHANGELOG.md')

function Write-Step([string]$Message) {
  if (-not $Silent) { Write-Host $Message }
}

function Resolve-IlInitPath {
  param([string]$configured)
  if ($configured -ne "") { return $configured }
  $homeDir = $env:HOME
  if ([string]::IsNullOrEmpty($homeDir)) { $homeDir = $env:USERPROFILE }
  return (Join-Path $homeDir "pcbenv\allegro.ilinit")
}

function Read-IlInit([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return "" }
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    return ([System.Text.UTF8Encoding]::new($false)).GetString($bytes, 3, $bytes.Length - 3)
  }
  return ([System.Text.Encoding]::Default).GetString($bytes)
}

function Write-IlInit([string]$Path, [string]$Content) {
  $directory = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::Default)
}

function Update-IlInitBlock([string]$Path, [string]$Root) {
  $forwardRoot = $Root -replace '\\', '/'
  $block = @(
    $markerBegin
    "setq(XFSKILL_ROOT `"$forwardRoot`")"
    'load(strcat(XFSKILL_ROOT "/main.il"))'
    $markerEnd
  ) -join "`r`n"
  $content = Read-IlInit $Path
  $pattern = '(?s)' + [regex]::Escape($markerBegin) + '.*?' + [regex]::Escape($markerEnd)
  if ($content -match $pattern) {
    $content = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $block })
  } else {
    if ($content -ne "" -and -not $content.EndsWith("`n")) { $content += "`r`n" }
    $content += $block + "`r`n"
  }
  Write-IlInit $Path $content
  Write-Step ("ilinit marker updated: " + $Path)
}

function Copy-Payload([string]$From, [string]$To) {
  foreach ($dir in $payloadDirs) {
    $source = Join-Path $From $dir
    if (Test-Path -LiteralPath $source) {
      robocopy $source (Join-Path $To $dir) /E /NFL /NDL /NJH /NJS /NP | Out-Null
      if ($LASTEXITCODE -ge 8) { throw ("robocopy failed for " + $dir) }
    }
  }
  foreach ($file in $payloadFiles) {
    $source = Join-Path $From $file
    if (Test-Path -LiteralPath $source) {
      Copy-Item -LiteralPath $source -Destination (Join-Path $To $file) -Force
    }
  }
}

function Get-InstalledVersion([string]$Root) {
  $versionFile = Join-Path $Root 'VERSION'
  if (-not (Test-Path -LiteralPath $versionFile)) { return "" }
  return ([System.IO.File]::ReadAllText($versionFile)).Trim()
}

function Backup-Installed([string]$Root, [string]$Version) {
  if (-not (Test-Path -LiteralPath $Root)) { return "" }
  if ([string]::IsNullOrEmpty($Version)) { return "" }
  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $backupRoot = Join-Path $Root '_backup'
  if (-not (Test-Path -LiteralPath $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
  }
  $backupDir = Join-Path $backupRoot ("{0}_{1}" -f $Version, $stamp)
  New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
  robocopy $Root $backupDir /E /XD _backup /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy backup failed" }
  Write-Step ("backed up version " + $Version + " -> " + $backupDir)
  return (Split-Path -Leaf $backupDir)
}

function Invoke-Install {
  $installedVersion = Get-InstalledVersion $Target
  $sourceVersion = Get-InstalledVersion $sourceRoot
  if ([string]::IsNullOrEmpty($sourceVersion)) { throw "source VERSION is missing" }

  if (-not (Test-Path -LiteralPath $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
  }
  if ($installedVersion -eq $sourceVersion) {
    Write-Step ("reinstall version " + $sourceVersion)
  } else {
    if ($installedVersion -ne "") {
      Backup-Installed -Root $Target -Version $installedVersion | Out-Null
    }
    Write-Step ("upgrading " + $(if ($installedVersion) { $installedVersion } else { 'none' }) + " -> " + $sourceVersion)
  }

  Copy-Payload -From $sourceRoot -To $Target
  Update-IlInitBlock -Path (Resolve-IlInitPath $IlInit) -Root $Target
  Write-Step ("XFSKILL " + $sourceVersion + " installed to " + $Target)
}

function Invoke-Rollback([string]$BackupName) {
  $backupDir = Join-Path (Join-Path $Target '_backup') $BackupName
  if (-not (Test-Path -LiteralPath $backupDir)) { throw ("backup not found: " + $backupDir) }
  Backup-Installed -Root $Target -Version (Get-InstalledVersion $Target) | Out-Null
  robocopy $backupDir $Target /E /XD _backup /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy restore failed" }
  Update-IlInitBlock -Path (Resolve-IlInitPath $IlInit) -Root $Target
  Write-Step ("rolled back to " + (Get-InstalledVersion $Target))
}

try {
  if ([string]::IsNullOrEmpty($Target)) {
    $Target = Join-Path $env:LOCALAPPDATA 'XFSKILL'
  }
  if ($Rollback -ne "") {
    Invoke-Rollback $Rollback
  } else {
    Invoke-Install
  }
  if ($Silent) { exit 0 }
  exit 0
} catch {
  Write-Host ("XFSKILL install failed: " + $_.Exception.Message)
  exit 1
}
