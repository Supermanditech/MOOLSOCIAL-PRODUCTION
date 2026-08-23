[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$InventoryOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$dependenciesPath = Join-Path $root 'apps\mobile\.flutter-plugins-dependencies'
$pubspecPath = Join-Path $root 'apps\mobile\pubspec.yaml'

function Assert-KotlinPluginReadiness([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Android release Kotlin plugin readiness rejected: $Message"
  }
}

foreach ($required in @($dependenciesPath, $pubspecPath)) {
  Assert-KotlinPluginReadiness (
    Test-Path -LiteralPath $required -PathType Leaf
  ) "required dependency owner is missing: $required"
}

try {
  $dependencies = Get-Content -LiteralPath $dependenciesPath -Raw |
    ConvertFrom-Json -Depth 100
} catch {
  throw 'Android release Kotlin plugin readiness rejected: .flutter-plugins-dependencies is invalid JSON.'
}

$directDevDependencies = @()
$insideDevDependencies = $false
foreach ($line in @(Get-Content -LiteralPath $pubspecPath)) {
  if ($line -cmatch '^dev_dependencies:\s*$') {
    $insideDevDependencies = $true
    continue
  }
  if ($insideDevDependencies -and $line -cmatch '^\S') {
    break
  }
  if ($insideDevDependencies -and $line -cmatch '^  ([A-Za-z0-9_]+):') {
    $directDevDependencies += [string]$Matches[1]
  }
}

$resolvedAndroidPlugins = @($dependencies.plugins.android)
$releaseAndroidPlugins = @(
  $resolvedAndroidPlugins |
    Where-Object { $directDevDependencies -cnotcontains [string]$_.name } |
    Sort-Object -Property name
)
Assert-KotlinPluginReadiness ($releaseAndroidPlugins.Count -gt 0) `
  'no release Android plugins were resolved.'

$legacyKotlinPlugins = @()
foreach ($plugin in $releaseAndroidPlugins) {
  $pluginName = [string]$plugin.name
  $pluginRoot = [IO.Path]::GetFullPath([string]$plugin.path)
  $gradleOwners = @(
    (Join-Path $pluginRoot 'android\build.gradle'),
    (Join-Path $pluginRoot 'android\build.gradle.kts')
  )
  $usesLegacyKotlinPlugin = $false
  foreach ($gradleOwner in $gradleOwners) {
    if (-not (Test-Path -LiteralPath $gradleOwner -PathType Leaf)) {
      continue
    }
    $source = Get-Content -LiteralPath $gradleOwner -Raw
    if ($source -cmatch '(?m)apply\s+plugin\s*:\s*[''"]kotlin-android[''"]' -or
        $source -cmatch '(?m)id\s*[( ]\s*[''"]kotlin-android[''"]' -or
        $source -cmatch '(?m)id\s*[( ]\s*[''"]org[.]jetbrains[.]kotlin[.]android[''"]' -or
        $source -cmatch '(?m)kotlin\s*[(]\s*[''"]android[''"]\s*[)]') {
      $usesLegacyKotlinPlugin = $true
      break
    }
  }
  if ($usesLegacyKotlinPlugin) {
    $legacyKotlinPlugins += $pluginName
  }
}

$summary = (
  'releaseAndroidPlugins={0}; directDevPluginsSkipped={1}; legacyKgpPlugins={2}; plugins={3}' -f
    $releaseAndroidPlugins.Count,
    ($resolvedAndroidPlugins.Count - $releaseAndroidPlugins.Count),
    $legacyKotlinPlugins.Count,
    ($legacyKotlinPlugins -join ',')
)

if ($InventoryOnly) {
  Write-Output "Android release Kotlin plugin inventory: $summary"
  return
}

$reviewedLegacyKotlinPlugins = @(
  'firebase_app_check',
  'mobile_scanner',
  'speech_to_text'
)
$actualLegacyKotlinPlugins = @($legacyKotlinPlugins | Sort-Object)
$expectedLegacyKotlinPlugins = @($reviewedLegacyKotlinPlugins | Sort-Object)
$baselineMatches = (
  $releaseAndroidPlugins.Count -eq 19 -and
  ($resolvedAndroidPlugins.Count - $releaseAndroidPlugins.Count) -eq 1 -and
  $actualLegacyKotlinPlugins.Count -eq $expectedLegacyKotlinPlugins.Count -and
  ($actualLegacyKotlinPlugins -join '|') -ceq
    ($expectedLegacyKotlinPlugins -join '|')
)
Assert-KotlinPluginReadiness $baselineMatches (
  "$summary. Reviewed dependency baseline changed; upgrade or override " +
  'repository dependencies for Built-in Kotlin and never patch the machine Pub cache.'
)

Write-Output (
  'Android release Kotlin plugin readiness passed: ' +
  "$summary; reviewedPinnedWarnings=$($legacyKotlinPlugins.Count)."
)
