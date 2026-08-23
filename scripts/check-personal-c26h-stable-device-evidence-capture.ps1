[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$owner = Join-Path $root 'scripts\capture-personal-c26h-stable-device-evidence.ps1'
if (-not (Test-Path -LiteralPath $owner -PathType Leaf)) { throw 'Stable C26H evidence-capture owner is missing.' }
$source = Get-Content -Raw -LiteralPath $owner
foreach ($token in @(
  "mResumedActivity|topResumedActivity|ResumedActivity",
  "Open MoolSocial main menu",
  "Opening your MoolSocial space",
  "ready-1",
  "ready-2",
  "Start-Sleep -Milliseconds 700",
  "screencap",
  "Save-UiDump -Step 'post'",
  "Refusing to overwrite evidence"
)) {
  if (-not $source.Contains($token)) { throw "Stable capture invariant is missing: $token" }
}
if (($source | Select-String -Pattern 'Assert-ReadyDump -Path' -AllMatches).Matches.Count -lt 3) {
  throw 'Stable capture must validate two pre-capture dumps and one post-capture dump.'
}
if (($source | Select-String -Pattern 'Test-ProductionActivityForeground -ActivityDump' -AllMatches).Matches.Count -lt 2) {
  throw 'Stable capture must verify production foreground ownership before and after capture.'
}
Write-Output 'C26H stable device-evidence capture gate passed.'
