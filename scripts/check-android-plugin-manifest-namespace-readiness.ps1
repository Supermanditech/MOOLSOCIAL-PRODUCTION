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

function Assert-ManifestNamespaceReadiness([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Android plugin manifest namespace readiness rejected: $Message"
  }
}

Assert-ManifestNamespaceReadiness (
  Test-Path -LiteralPath $dependenciesPath -PathType Leaf
) 'apps/mobile/.flutter-plugins-dependencies is missing; resolve dependencies before release preflight.'
Assert-ManifestNamespaceReadiness (
  Test-Path -LiteralPath $pubspecPath -PathType Leaf
) 'apps/mobile/pubspec.yaml is missing.'

try {
  $dependencies = Get-Content -LiteralPath $dependenciesPath -Raw |
    ConvertFrom-Json -Depth 100
} catch {
  throw 'Android plugin manifest namespace readiness rejected: .flutter-plugins-dependencies is invalid JSON.'
}

$resolvedAndroidPlugins = @($dependencies.plugins.android)
Assert-ManifestNamespaceReadiness ($resolvedAndroidPlugins.Count -gt 0) `
  'no resolved Android plugins were recorded.'

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

$androidPlugins = @(
  $resolvedAndroidPlugins |
    Where-Object { $directDevDependencies -cnotcontains [string]$_.name }
)
Assert-ManifestNamespaceReadiness ($androidPlugins.Count -gt 0) `
  'no release Android plugins remained after excluding direct dev_dependencies.'

$manifestCount = 0
$obsolete = @()
foreach ($plugin in @($androidPlugins | Sort-Object -Property name)) {
  $pluginName = [string]$plugin.name
  $pluginRoot = [IO.Path]::GetFullPath([string]$plugin.path)
  $manifestPath = Join-Path $pluginRoot 'android\src\main\AndroidManifest.xml'
  if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    continue
  }

  $manifestCount++
  try {
    [xml]$manifest = Get-Content -LiteralPath $manifestPath -Raw
  } catch {
    throw "Android plugin manifest namespace readiness rejected: resolved plugin manifest is invalid XML: $pluginName"
  }

  $packageName = [string]$manifest.DocumentElement.GetAttribute('package')
  if (-not [string]::IsNullOrWhiteSpace($packageName)) {
    $obsolete += [pscustomobject]@{
      plugin = $pluginName
      packageName = $packageName
    }
  }
}

$obsoleteNames = @($obsolete | ForEach-Object { [string]$_.plugin })
$summary = (
  'releaseAndroidPlugins={0}; directDevPluginsSkipped={1}; manifests={2}; obsoletePackageAttributes={3}; plugins={4}' -f
    $androidPlugins.Count,
    ($resolvedAndroidPlugins.Count - $androidPlugins.Count),
    $manifestCount,
    $obsolete.Count,
    ($obsoleteNames -join ',')
)

if ($InventoryOnly) {
  Write-Output "Android plugin manifest namespace inventory: $summary"
  return
}

$reviewedObsoletePackagePlugins = @(
  'firebase_app_check',
  'firebase_auth',
  'firebase_core',
  'firebase_crashlytics',
  'flutter_facebook_auth',
  'flutter_plugin_android_lifecycle',
  'google_sign_in_android',
  'image_picker_android',
  'jni',
  'jni_flutter',
  'permission_handler_android',
  'share_plus',
  'shared_preferences_android',
  'url_launcher_android',
  'video_player_android'
)
$actualObsoletePackagePlugins = @($obsoleteNames | Sort-Object)
$expectedObsoletePackagePlugins = @(
  $reviewedObsoletePackagePlugins | Sort-Object
)
$baselineMatches = (
  $androidPlugins.Count -eq 20 -and
  ($resolvedAndroidPlugins.Count - $androidPlugins.Count) -eq 1 -and
  $manifestCount -eq 18 -and
  $actualObsoletePackagePlugins.Count -eq
    $expectedObsoletePackagePlugins.Count -and
  ($actualObsoletePackagePlugins -join '|') -ceq
    ($expectedObsoletePackagePlugins -join '|')
)
Assert-ManifestNamespaceReadiness $baselineMatches (
  "$summary. Reviewed dependency baseline changed; upgrade or override " +
  'repository dependencies and never patch the machine Pub cache.'
)

Write-Output (
  'Android plugin manifest namespace readiness passed: ' +
  "$summary; reviewedPinnedWarnings=$($obsolete.Count)."
)
