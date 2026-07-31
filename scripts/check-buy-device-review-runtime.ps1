[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$Serial,

  [Parameter(Mandatory)]
  [ValidatePattern('^BUY-[A-Z0-9][A-Z0-9.-]+$')]
  [string]$CandidateId,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$EvidenceLog
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = [IO.Path]::GetFullPath(
  (Split-Path -Parent $PSScriptRoot)
)
$evidencePath = [IO.Path]::GetFullPath($EvidenceLog)
if (-not $evidencePath.StartsWith(
    $repositoryRoot,
    [StringComparison]::OrdinalIgnoreCase
  )) {
  throw 'Runtime evidence must stay inside the production repository.'
}

$escapedSerial = [regex]::Escape($Serial)
$deviceLine = adb devices | Select-String -Pattern "^$escapedSerial\s+device$"
if (-not $deviceLine) {
  throw "ADB device is not ready: $Serial"
}

adb -s $Serial logcat -c
if ($LASTEXITCODE -ne 0) {
  throw 'Unable to clear device logcat.'
}
adb -s $Serial shell am force-stop com.moolsocial.app
if ($LASTEXITCODE -ne 0) {
  throw 'Unable to stop the installed MoolSocial package.'
}
adb -s $Serial shell am start -W -n com.moolsocial.app/.MainActivity | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw 'Unable to start the installed MoolSocial package.'
}

$deadline = [DateTimeOffset]::Now.AddSeconds(30)
$runtimeLog = ''
$candidateMarker = "MOOLSOCIAL_CANDIDATE id=$CandidateId "
$readyPattern = (
  'MOOLSOCIAL_STARTUP stage=ready .*' +
  'setupComplete=true .*authenticated=true'
)
while ([DateTimeOffset]::Now -lt $deadline) {
  Start-Sleep -Milliseconds 500
  $runtimeLog = (adb -s $Serial logcat -d -v time | Out-String)
  if (
    $runtimeLog.Contains($candidateMarker) -and
    $runtimeLog -match $readyPattern
  ) {
    break
  }
}

$evidenceDirectory = Split-Path -Parent $evidencePath
if (-not (Test-Path -LiteralPath $evidenceDirectory -PathType Container)) {
  New-Item -ItemType Directory -Path $evidenceDirectory | Out-Null
}
$runtimeLog | Set-Content -LiteralPath $evidencePath -Encoding utf8

if (-not $runtimeLog.Contains($candidateMarker)) {
  throw "Installed runtime did not expose candidate marker $CandidateId."
}
if ($runtimeLog -notmatch $readyPattern) {
  throw 'Installed device-review runtime did not reach ready authenticated state.'
}

Write-Output (
  "Buy device-review runtime passed: candidate $CandidateId; " +
  'ready authenticated state.'
)
