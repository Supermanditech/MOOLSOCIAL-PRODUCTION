[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$ApkPath,
  [Parameter(Mandatory)]
  [string]$CandidateId,
  [string]$RepositoryRoot,
  [string]$ApkAnalyzerPath,
  [string]$ProguardFolderPath,
  [switch]$RequireMappingAware,
  [string]$ExpectedApplicationId = 'com.moolsocial.app',
  [switch]$AllowDebugTestPlugin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
$pathGuard = Join-Path $PSScriptRoot 'release-artifact-path-guard.ps1'
. $pathGuard
$apk = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $ApkPath `
  -Label 'APK integrity artifact'
if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) {
  throw 'APK integrity gate rejected: APK is missing.'
}
if ([string]::IsNullOrWhiteSpace($CandidateId)) {
  throw 'APK integrity gate rejected: candidate identity is blank.'
}

if (-not $ApkAnalyzerPath) {
  $sdkRoot = $env:ANDROID_SDK_ROOT
  if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
    $sdkRoot = $env:ANDROID_HOME
  }
  if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
    $propertiesPath = Join-Path $root 'apps\mobile\android\local.properties'
    if (Test-Path -LiteralPath $propertiesPath -PathType Leaf) {
      $sdkLine = Get-Content -LiteralPath $propertiesPath |
        Where-Object { $_.StartsWith('sdk.dir=') } |
        Select-Object -First 1
      if ($sdkLine) {
        $sdkRoot = $sdkLine.Substring('sdk.dir='.Length).
          Replace('\:', ':').Replace('\\', '\')
      }
    }
  }
  if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
    throw 'APK integrity gate rejected: Android SDK is unresolved.'
  }
  $candidates = @(
    (Join-Path $sdkRoot 'cmdline-tools\latest\bin\apkanalyzer.bat'),
    (Join-Path $sdkRoot 'cmdline-tools\bin\apkanalyzer.bat')
  )
  $resolvedApkAnalyzers = @($candidates | Where-Object {
    Test-Path -LiteralPath $_ -PathType Leaf
  } | Select-Object -First 1)
  if ($resolvedApkAnalyzers.Count -ne 1) {
    throw 'APK integrity gate rejected: apkanalyzer is unavailable.'
  }
  $ApkAnalyzerPath = $resolvedApkAnalyzers[0]
}

$mappingAware = $false
$packageArguments = @('dex', 'packages', '--defined-only')
if (-not [string]::IsNullOrWhiteSpace($ProguardFolderPath)) {
  $proguardFolder = Resolve-ReleaseArtifactRepositoryDescendant `
    -RepositoryRoot $root `
    -Path $ProguardFolderPath `
    -Label 'APK integrity Proguard folder'
  if (-not (Test-Path -LiteralPath $proguardFolder -PathType Container)) {
    throw 'APK integrity gate rejected: Proguard folder is missing.'
  }
  $mappingPath = Join-Path $proguardFolder 'mapping.txt'
  $seedsPath = Join-Path $proguardFolder 'seeds.txt'
  $usagesPath = Join-Path $proguardFolder 'usage.txt'
  foreach ($requiredMappingOwner in @($mappingPath, $seedsPath, $usagesPath)) {
    if (-not (Test-Path -LiteralPath $requiredMappingOwner -PathType Leaf)) {
      throw 'APK integrity gate rejected: required Proguard owner is missing.'
    }
  }
  $apkTime = (Get-Item -LiteralPath $apk).LastWriteTimeUtc
  $oldestMappingTime = @(
    $mappingPath,
    $seedsPath,
    $usagesPath
  ) | ForEach-Object { (Get-Item -LiteralPath $_).LastWriteTimeUtc } |
    Sort-Object | Select-Object -First 1
  if (($apkTime - $oldestMappingTime).TotalMinutes -gt 10 -or
      $oldestMappingTime -gt $apkTime.AddMinutes(1)) {
    throw 'APK integrity gate rejected: Proguard owners are stale for this APK.'
  }
  $packageArguments += @(
    '--proguard-mappings', $mappingPath,
    '--proguard-seeds', $seedsPath,
    '--proguard-usages', $usagesPath
  )
  $mappingAware = $true
} elseif ($RequireMappingAware) {
  throw 'APK integrity gate rejected: mapping-aware inspection is required.'
}
$packageArguments += $apk

$packageOutput = @(& $ApkAnalyzerPath @packageArguments 2>&1)
$packageExit = $LASTEXITCODE
if ($packageExit -ne 0) {
  throw 'APK integrity gate rejected: dex package inspection failed.'
}
$packageText = $packageOutput -join "`n"
$required = @(
  'io.flutter.plugins.GeneratedPluginRegistrant',
  'io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin',
  'dev.fluttercommunity.plus.share.SharePlusPlugin',
  'com.moolsocial.app.MainActivity'
)
foreach ($className in $required) {
  if (-not $packageText.Contains($className)) {
    throw "APK integrity gate rejected: required class is missing: $className"
  }
}
if (-not $AllowDebugTestPlugin) {
  foreach ($forbidden in @(
    'dev.flutter.plugins.integration_test.IntegrationTestPlugin',
    'dev.flutter.plugins.integration_test'
  )) {
    if ($packageText.Contains($forbidden)) {
      throw "APK integrity gate rejected: test-only class is present: $forbidden"
    }
  }
}

$applicationIdOutput = @(& $ApkAnalyzerPath manifest application-id $apk 2>&1)
$applicationIdExit = $LASTEXITCODE
if ($applicationIdExit -ne 0) {
  throw 'APK integrity gate rejected: manifest identity inspection failed.'
}
$applicationIdCandidates = @(
  $applicationIdOutput | ForEach-Object { ([string]$_).Trim() } |
    Where-Object {
      $_ -cmatch '^[A-Za-z][A-Za-z0-9_]*(?:[.][A-Za-z0-9_]+)+$'
    } | Select-Object -Unique
)
if ($applicationIdCandidates.Count -ne 1) {
  throw 'APK integrity gate rejected: manifest identity output is ambiguous.'
}
$applicationId = [string]$applicationIdCandidates[0]
if ($applicationId -cne $ExpectedApplicationId) {
  throw 'APK integrity gate rejected: package identity changed.'
}
$integrationTestState = if ($AllowDebugTestPlugin) {
  'allowed_debug_only'
} else {
  'absent'
}

Write-Output (
  'APK production plugin integrity passed: ' +
  "candidate=$CandidateId; package=$applicationId; " +
  "mappingAware=$($mappingAware.ToString().ToLowerInvariant()); " +
  "registrant=true; firebaseCore=true; sharePlus=true; integrationTest=$integrationTestState."
)
