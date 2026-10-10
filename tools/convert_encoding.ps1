<#
.SYNOPSIS
  XFSKILL source encoding converter between UTF-8 (editing) and GBK (runtime).

.DESCRIPTION
  Allegro reads .il/.cfg files with the Windows ANSI code page (GBK/CP936 on a
  Chinese Windows host). The repository therefore stores those files in GBK.
  Editors and AI agents usually work in UTF-8, so the workflow is:
      edit in UTF-8  ->  tools/convert_encoding.ps1 -To gbk  ->  smoke test
  The script refuses to touch a file whose source encoding does not decode
  strictly, so a double conversion can never silently corrupt a source file.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\convert_encoding.ps1 -To gbk
  powershell -ExecutionPolicy Bypass -File tools\convert_encoding.ps1 -To utf8
#>
[CmdletBinding()]
param(
  [ValidateSet('gbk', 'utf8')]
  [string]$To = 'gbk',

  [string]$Root = ""
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrEmpty($Root)) { $Root = Split-Path -Parent $PSScriptRoot }

$gbkStrict = [System.Text.Encoding]::GetEncoding(
  936,
  [System.Text.EncoderExceptionFallback]::new(),
  [System.Text.DecoderExceptionFallback]::new()
)
$utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)
$utf8Write = [System.Text.UTF8Encoding]::new($false)

$files = Get-ChildItem -Path $Root -Recurse -Include '*.il', '*.cfg' -File |
  Where-Object { $_.FullName -notmatch '\\_backup\\' }

$converted = 0
$skipped = 0

foreach ($file in $files) {
  $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
  if ($To -eq 'gbk') {
    try {
      $text = $utf8Strict.GetString($bytes)
    } catch {
      Write-Warning ("skip, source is not UTF-8: " + $file.FullName)
      $skipped++
      continue
    }
    $text = $text -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($file.FullName, $text, $gbkStrict)
  } else {
    try {
      $text = $gbkStrict.GetString($bytes)
    } catch {
      Write-Warning ("skip, source is not GBK: " + $file.FullName)
      $skipped++
      continue
    }
    [System.IO.File]::WriteAllText($file.FullName, $text, $utf8Write)
  }
  Write-Host ("converted {0} -> {1}" -f $file.FullName.Substring($Root.Length + 1), $To)
  $converted++
}

Write-Host ("encoding task done, converted={0} skipped={1}" -f $converted, $skipped)
