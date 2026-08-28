[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$OutputPath,

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$resolvedOutput = if ([IO.Path]::IsPathRooted($OutputPath)) {
  [IO.Path]::GetFullPath($OutputPath)
} else {
  [IO.Path]::GetFullPath((Join-Path $root $OutputPath))
}
if (-not $resolvedOutput.StartsWith(
    $prefix,
    [StringComparison]::OrdinalIgnoreCase
  )) {
  throw 'Shop source manifest escaped the repository.'
}

$tracked = @(& git -C $root ls-files)
if ($LASTEXITCODE -ne 0 -or $tracked.Count -eq 0) {
  throw 'Shop source manifest tracked-file inventory failed.'
}

$exactBuildControls = @(
  'config/buy-premium-motion-policy.json',
  'docs/quality/BUY-PREMIUM-MOTION-SURFACE-COVERAGE-20260802.md',
  'docs/quality/UAW-PRIMARY-SHOP-V2-PROTECTED-CANDIDATE-GATE-20260828.md',
  'docs/quality/UAW-PRIMARY-SHOP-V2-R61-5-CURSOR-REVIEW-BUILD-20260828.md',
  'scripts/build-buy-device-review.ps1',
  'scripts/check-android-plugin-manifest-namespace-readiness.ps1',
  'scripts/check-android-release-kotlin-plugin-readiness.ps1',
  'scripts/check-android-release-resource-integrity.ps1',
  'scripts/check-apk-production-plugin-integrity.ps1',
  'scripts/check-apk-regression-gate-state.ps1',
  'scripts/check-brand-integrity.ps1',
  'scripts/check-buy-premium-motion-policy-state.ps1',
  'scripts/check-buy-protected-baseline.ps1',
  'scripts/check-social-protected-baseline.ps1',
  'scripts/invoke-flutter-with-clean-support.ps1',
  'scripts/new-shop-v2-r61-5-source-manifest.ps1',
  'scripts/release-artifact-path-guard.ps1',
  'scripts/test-cursor-ui-review-build-profile.ps1',
  'scripts/test-public-auth-sideload-build-controls.ps1',
  'scripts/test-release-artifact-path-containment.ps1',
  'scripts/test-release-production-plugin-integrity.ps1'
)

$selected = @(
  $tracked | Where-Object {
    $owner = ([string]$_).Replace('\', '/')
    (
      $owner -match '^apps/mobile/lib/.+\.dart$' -or
      $owner -match '^apps/mobile/test/.+\.dart$' -or
      $owner -match '^apps/mobile/integration_test/.+\.dart$' -or
      $owner -match '^apps/mobile/test_driver/.+\.dart$' -or
      $owner -match '^apps/mobile/packages/.+\.(?:dart|yaml|kt|kts|java|xml)$' -or
      $owner -match '^apps/mobile/android/.+\.(?:kt|kts|java|xml|properties|gradle)$' -or
      $owner -cin @('apps/mobile/pubspec.yaml', 'apps/mobile/pubspec.lock') -or
      $exactBuildControls -ccontains $owner
    ) -and
    $owner -notmatch '(?i)/(?:build|\.gradle|\.dart_tool|node_modules)/'
  }
  | ForEach-Object { ([string]$_).Replace('\', '/') }
  | Sort-Object -Unique
)
if ($selected.Count -lt 100) {
  throw "Shop source manifest inventory is unexpectedly small: $($selected.Count)"
}
foreach ($required in $exactBuildControls) {
  if ($selected -cnotcontains $required) {
    throw "Shop source manifest omitted required build control: $required"
  }
}

$lines = @()
foreach ($owner in $selected) {
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $owner))
  if (-not $resolved.StartsWith(
      $prefix,
      [StringComparison]::OrdinalIgnoreCase
    ) -or -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "Shop source manifest owner is missing or escaped: $owner"
  }
  $hash = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
  $lines += "$hash  $owner"
}

$parent = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
  New-Item -ItemType Directory -Path $parent | Out-Null
}
[IO.File]::WriteAllLines(
  $resolvedOutput,
  $lines,
  [Text.UTF8Encoding]::new($false)
)
Write-Output (
  'SHOP_SOURCE_MANIFEST_CREATED ' +
  "files=$($lines.Count); path=$resolvedOutput"
)
