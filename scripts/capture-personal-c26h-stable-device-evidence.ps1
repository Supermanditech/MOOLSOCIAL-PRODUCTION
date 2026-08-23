[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[A-Za-z0-9._-]+$')]
  [string]$Serial,

  [Parameter(Mandatory = $true)]
  [string]$EvidenceDirectory,

  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[A-Za-z0-9._-]+$')]
  [string]$Stem,

  [string]$RequiredSemantic = 'Open MoolSocial main menu'
)

$ErrorActionPreference = 'Stop'
$package = 'com.moolsocial.app'
$activity = 'com.moolsocial.app/.MainActivity'
$adb = (Get-Command adb -ErrorAction Stop).Source
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
if (-not (Test-Path -LiteralPath $evidenceRoot -PathType Container)) {
  throw "Evidence directory does not exist: $evidenceRoot"
}

$pngPath = Join-Path $evidenceRoot "$Stem.png"
$xmlPath = Join-Path $evidenceRoot "$Stem.xml"
$readyOnePath = Join-Path $evidenceRoot "$Stem-ready-1.xml"
$readyTwoPath = Join-Path $evidenceRoot "$Stem-ready-2.xml"
foreach ($path in @($pngPath, $xmlPath, $readyOnePath, $readyTwoPath)) {
  if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite evidence: $path" }
}

function Invoke-AdbText {
  param([Parameter(Mandatory = $true)][string[]]$Arguments)
  $output = & $adb -s $Serial @Arguments 2>&1
  if ($LASTEXITCODE -ne 0) { throw "adb failed: $($Arguments -join ' ')`n$output" }
  return ($output -join "`n")
}

function Save-UiDump {
  param(
    [Parameter(Mandatory = $true)][string]$Step,
    [Parameter(Mandatory = $true)][string]$Destination
  )
  $remote = "/sdcard/Download/codex-c26h-$Stem-$Step.xml"
  try {
    $dump = Invoke-AdbText -Arguments @('shell', 'uiautomator', 'dump', $remote)
    if ($dump -notmatch 'UI hierchary dumped to|UI hierarchy dumped to') {
      throw "UI dump did not report success: $dump"
    }
    $pull = Invoke-AdbText -Arguments @('pull', $remote, $Destination)
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
      throw "UI dump was not pulled: $pull"
    }
  } finally {
    & $adb -s $Serial shell rm -f $remote *> $null
  }
}

function Assert-ReadyDump {
  param([Parameter(Mandatory = $true)][string]$Path)
  $xml = Get-Content -Raw -LiteralPath $Path
  if ($xml -notmatch [regex]::Escape($RequiredSemantic)) {
    throw "Required native navigation semantic is absent: $RequiredSemantic"
  }
  if ($xml -match 'Opening your MoolSocial space') {
    throw 'Splash/loading content remains visible; screenshot capture rejected.'
  }
  if ($xml -notmatch 'package="com\.moolsocial\.app"') {
    throw 'The stable UI dump is not owned by the production package.'
  }
}

function Test-ProductionActivityForeground {
  param([Parameter(Mandatory = $true)][string]$ActivityDump)
  $exactActivity = [regex]::Escape($activity)
  return $ActivityDump -match "(?:mResumedActivity|topResumedActivity|ResumedActivity).*${exactActivity}"
}

$resumed = Invoke-AdbText -Arguments @('shell', 'dumpsys', 'activity', 'activities')
if (-not (Test-ProductionActivityForeground -ActivityDump $resumed)) {
  throw 'MoolSocial MainActivity is not the resumed foreground activity.'
}

Save-UiDump -Step 'ready-1' -Destination $readyOnePath
Assert-ReadyDump -Path $readyOnePath
Start-Sleep -Milliseconds 700
Save-UiDump -Step 'ready-2' -Destination $readyTwoPath
Assert-ReadyDump -Path $readyTwoPath

$remotePng = "/sdcard/Download/codex-c26h-$Stem.png"
try {
  [void](Invoke-AdbText -Arguments @('shell', 'screencap', '-p', $remotePng))
  [void](Invoke-AdbText -Arguments @('pull', $remotePng, $pngPath))
} finally {
  & $adb -s $Serial shell rm -f $remotePng *> $null
}
if (-not (Test-Path -LiteralPath $pngPath -PathType Leaf) -or (Get-Item -LiteralPath $pngPath).Length -lt 1024) {
  throw 'Screenshot capture is missing or implausibly small.'
}

Save-UiDump -Step 'post' -Destination $xmlPath
Assert-ReadyDump -Path $xmlPath
$resumedAfter = Invoke-AdbText -Arguments @('shell', 'dumpsys', 'activity', 'activities')
if (-not (Test-ProductionActivityForeground -ActivityDump $resumedAfter)) {
  throw 'MoolSocial ceased to be foreground during evidence capture.'
}

$sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $pngPath).Hash
Write-Output "Stable device evidence captured: stem=$Stem; screenshotSha256=$sha"
