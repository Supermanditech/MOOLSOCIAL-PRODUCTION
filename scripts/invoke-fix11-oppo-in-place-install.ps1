[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'FIX11 OPPO in-place install requires PowerShell 7.'
}

$repositoryRoot = [IO.Path]::GetFullPath(
  (Split-Path -Parent $PSScriptRoot)
).TrimEnd([char[]]@(
  [IO.Path]::DirectorySeparatorChar,
  [IO.Path]::AltDirectorySeparatorChar
))
$statePath = Join-Path $repositoryRoot 'config\apk-regression-gate-state.json'
$apkPath = Join-Path $repositoryRoot (
  'artifacts\quality\' +
  'uaw-c34p-fix11-google-sign-in-oppo-successor-r60-85-20260823-03\' +
  'uaw-c34p-fix11-google-sign-in-oppo-forensic-repair-' +
  'device-review-release.apk'
)
$expectedApkSha256 =
  'D777CDF166A156912ED30E494B526B0C56A2487D58B8449AE2FD3B9F317C287D'

function Assert-Fix11Install([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "FIX11 OPPO in-place install rejected: $Message"
  }
}

$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
Assert-Fix11Install ($state.machineState -ceq
  'r60_85_install_attempt_1_in_progress_authority_consumed_no_retry') `
  'install journal is not at the reserved attempt-1 state.'
Assert-Fix11Install ($state.buildAuthorization -ceq
  'consumed_no_second_build') 'build authorization is not consumed.'
Assert-Fix11Install (
  -not [bool]$state.fix11SuccessorPreflight.buildAuthorized -and
  -not [bool]$state.fix11SuccessorPreflight.installAuthorized -and
  [bool]$state.fix11SuccessorPreflight.signedApkCreated
) 'FIX11 build/install authority facts changed.'
Assert-Fix11Install (
  [int]$state.buildResult.buildCount -eq 1 -and
  [int]$state.installResult.installCount -eq 1 -and
  [bool]$state.installResult.installAuthorizationConsumed
) 'build or install action count changed.'
Assert-Fix11Install (
  Test-Path -LiteralPath $apkPath -PathType Leaf
) 'qualified APK is missing.'
Assert-Fix11Install (
  (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash -ceq
    $expectedApkSha256
) 'qualified APK hash changed.'

$deviceLines = @(& adb devices 2>$null)
$authorizedDevices = @($deviceLines | Select-Object -Skip 1 | Where-Object {
  $_ -match '\tdevice(?:\s|$)'
})
$unauthorizedOrOffline = @($deviceLines | Select-Object -Skip 1 | Where-Object {
  $_ -match '\t(?:unauthorized|offline)(?:\s|$)'
})
Assert-Fix11Install (
  $authorizedDevices.Count -eq 1 -and $unauthorizedOrOffline.Count -eq 0
) 'exactly one authorized online Android device is required.'

$preInstallPackage = [string]::Join(
  [Environment]::NewLine,
  @(& adb shell dumpsys package com.moolsocial.app 2>$null)
)
Assert-Fix11Install (
  $preInstallPackage -match '(?m)^\s*versionName=1\.0\.0-r60\.84\s*$' -and
  $preInstallPackage -match '(?m)^\s*versionCode=2026082184(?:\s|$)'
) 'pre-install MoolSocial version is not exact r60.84.'

$installOutput = @(& adb install -r $apkPath 2>&1)
$installExitCode = $LASTEXITCODE
$successMarkerCount = @($installOutput | Where-Object {
  [string]$_ -ceq 'Success'
}).Count
$failureCodes = @($installOutput | ForEach-Object {
  if ([string]$_ -match '(?i)Failure\s*\[([A-Z0-9_]+)') {
    $Matches[1].ToUpperInvariant()
  }
} | Sort-Object -Unique)

if (
  $installExitCode -ne 0 -or
  $successMarkerCount -ne 1 -or
  $failureCodes.Count -ne 0
) {
  $sanitizedFailure = if ($failureCodes.Count -eq 0) {
    'UNCLASSIFIED_ADB_INSTALL_FAILURE'
  } else {
    $failureCodes -join ','
  }
  throw "FIX11_OPPO_IN_PLACE_INSTALL_FAILED: $sanitizedFailure"
}

Write-Output 'FIX11_OPPO_IN_PLACE_INSTALL_PASSED'
