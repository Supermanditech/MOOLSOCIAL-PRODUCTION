[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$OutputPath,

  [string]$PredecessorManifestPath = (
    'artifacts/quality/' +
    'uaw-c34p-fix5-public-auth-sideload-preflight-r60-80-20260821-01/' +
    'source-aggregate-manifest.txt'
  ),

  [string]$RepositoryRoot,

  [ValidateSet(
    'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR',
    'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR'
  )]
  [string]$CandidateId =
    'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
)
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$resolvedOutput = [IO.Path]::GetFullPath((Join-Path $root $OutputPath))
$resolvedPredecessor = [IO.Path]::GetFullPath(
  (Join-Path $root $PredecessorManifestPath)
)

function Assert-ManifestInput([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "FIX8 successor build-input manifest rejected: $Message"
  }
}

function Resolve-RepositoryFile([string]$RelativePath) {
  $candidate = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-ManifestInput `
    ($candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) `
    "owner escaped repository: $RelativePath"
  Assert-ManifestInput `
    (Test-Path -LiteralPath $candidate -PathType Leaf) `
    "owner is missing: $RelativePath"
  return $candidate
}

Assert-ManifestInput `
  ($resolvedOutput.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) `
  'output escaped repository.'
Assert-ManifestInput `
  (-not (Test-Path -LiteralPath $resolvedOutput)) `
  'output already exists; overwrite is forbidden.'
Assert-ManifestInput `
  ($resolvedPredecessor.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) `
  'predecessor manifest escaped repository.'
Assert-ManifestInput `
  (Test-Path -LiteralPath $resolvedPredecessor -PathType Leaf) `
  'predecessor manifest is missing.'

$owners = [System.Collections.Generic.HashSet[string]]::new(
  [StringComparer]::Ordinal
)

function Add-Owner([string]$RelativePath) {
  $normalized = $RelativePath.Replace('\', '/').TrimStart('/')
  Assert-ManifestInput `
    (-not [string]::IsNullOrWhiteSpace($normalized)) `
    'blank owner path.'
  Assert-ManifestInput `
    (-not [IO.Path]::IsPathRooted($normalized) -and
      -not $normalized.Contains('..', [StringComparison]::Ordinal)) `
    "non-canonical owner: $normalized"
  $resolved = Resolve-RepositoryFile $normalized
  $item = Get-Item -LiteralPath $resolved -Force
  Assert-ManifestInput `
    (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) `
    "reparse-point owner is forbidden: $normalized"
  [void]$owners.Add($normalized)
}

function Add-Tree([string]$RelativeRoot, [string]$Filter = '*') {
  $resolvedTree = [IO.Path]::GetFullPath((Join-Path $root $RelativeRoot))
  Assert-ManifestInput `
    ($resolvedTree.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) `
    "tree escaped repository: $RelativeRoot"
  Assert-ManifestInput `
    (Test-Path -LiteralPath $resolvedTree -PathType Container) `
    "tree is missing: $RelativeRoot"
  foreach ($file in Get-ChildItem -LiteralPath $resolvedTree -File -Recurse -Force -Filter $Filter) {
    $relative = $file.FullName.Substring($rootPrefix.Length).Replace('\', '/')
    Add-Owner $relative
  }
}

# Complete current Dart/runtime and declared asset closure.
Add-Tree 'apps/mobile/lib'
Add-Tree 'apps/mobile/assets'
foreach ($relative in @(
  'apps/mobile/pubspec.yaml',
  'apps/mobile/pubspec.lock',
  'apps/mobile/.metadata',
  'apps/mobile/.flutter-plugins-dependencies',
  'apps/mobile/.dart_tool/package_config.json',
  'apps/mobile/.dart_tool/package_graph.json',
  'apps/mobile/analysis_options.yaml'
)) {
  Add-Owner $relative
}

# Resolve every repository-local package from the live package graph.
$packageConfigPath = Resolve-RepositoryFile 'apps/mobile/.dart_tool/package_config.json'
$packageConfig = Get-Content -Raw -LiteralPath $packageConfigPath | ConvertFrom-Json
$packageConfigUri = [uri]::new($packageConfigPath)
$localPackages = @()
foreach ($package in @($packageConfig.packages)) {
  $packageRoot = [IO.Path]::GetFullPath(
    [uri]::new($packageConfigUri, [string]$package.rootUri).LocalPath
  ).TrimEnd([char[]]@(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
  ))
  if ($packageRoot.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    $relativePackage = $packageRoot.Substring($rootPrefix.Length).Replace('\', '/')
    if ($relativePackage -cne 'apps/mobile') {
      $localPackages += $relativePackage
      Add-Tree $relativePackage
    }
  }
}
Assert-ManifestInput `
  (@($localPackages | Sort-Object -Unique).Count -eq 1 -and
    @($localPackages | Sort-Object -Unique)[0] -ceq
      'apps/mobile/packages/youtube_embedded_player_private_dev') `
  'repository-local package graph changed from the one qualified package.'

# Complete Android release owner closure; machine-local signing and SDK files
# are intentionally supplied by the secure build session and never inventoried.
foreach ($relativeTree in @(
  'apps/mobile/android/app/src/main',
  'apps/mobile/android/app/src/debug',
  'apps/mobile/android/app/src/profile',
  'apps/mobile/android/gradle/wrapper'
)) {
  Add-Tree $relativeTree
}
foreach ($relative in @(
  'apps/mobile/android/.gitignore',
  'apps/mobile/android/app/build.gradle.kts',
  'apps/mobile/android/app/google-services.json',
  'apps/mobile/android/build.gradle.kts',
  'apps/mobile/android/gradle.properties',
  'apps/mobile/android/gradlew',
  'apps/mobile/android/gradlew.bat',
  'apps/mobile/android/settings.gradle.kts'
)) {
  Add-Owner $relative
}
foreach ($optional in @(
  'apps/mobile/android/app/proguard-rules.pro',
  'apps/mobile/android/app/lint.xml'
)) {
  if (Test-Path -LiteralPath (Join-Path $root $optional) -PathType Leaf) {
    Add-Owner $optional
  }
}

# Qualification source: all executable Dart tests, the complete backend auth
# source/test tree and exact build-control owners used by this candidate.
foreach ($testTree in @(
  'apps/mobile/test',
  'apps/mobile/integration_test',
  'apps/mobile/test_driver'
)) {
  Add-Tree $testTree '*.dart'
}
Add-Tree 'backend/functions/src/auth' '*.ts'
foreach ($relative in @(
  'backend/functions/src/index.ts',
  'backend/functions/package.json',
  'backend/functions/package-lock.json',
  'backend/functions/tsconfig.json',
  'scripts/build-buy-device-review.ps1',
  'scripts/check-aab-production-plugin-integrity.ps1',
  'scripts/check-android-plugin-manifest-namespace-readiness.ps1',
  'scripts/check-android-release-kotlin-plugin-readiness.ps1',
  'scripts/check-android-release-resource-integrity.ps1',
  'scripts/check-apk-production-plugin-integrity.ps1',
  'scripts/check-apk-regression-gate-state.ps1',
  'scripts/check-approved-ui-locks.ps1',
  'scripts/check-buy-premium-motion-policy-state.ps1',
  'scripts/check-codex-development-regression-memory.ps1',
  'scripts/check-codex-subagent-coordination-policy.ps1',
  'scripts/check-full-social-founder-dev-readiness.ps1',
  'scripts/check-google-android-identity-bridge-readiness.ps1',
  'scripts/check-google-android-oauth-signing-readiness.ps1',
  'scripts/check-mvp-delivery-discipline-lock.ps1',
  'scripts/check-mvp-scope-gate-state.ps1',
  'scripts/check-uaw-c34p-fix5-all-eight-public-auth-live-provider-readiness.ps1',
  'scripts/check-uaw-c34p-fix11-google-sign-in-forensic-readiness.ps1',
  'scripts/invoke-play-internal-aab-build-c30t.ps1',
  'scripts/invoke-fix11-local-signer-preflight.ps1',
  'scripts/invoke-fix11-local-successor-build.ps1',
  'scripts/new-fix8-r60-81-build-input-manifest.ps1',
  'scripts/prepare-moolsocial-sideload-build-environment.ps1',
  'scripts/refresh-moolsocial-upload-signing-environment.ps1',
  'scripts/release-artifact-path-guard.ps1',
  'scripts/test-release-artifact-path-containment.ps1',
  'scripts/test-release-production-plugin-integrity.ps1',
  'scripts/test-google-android-identity-bridge-readiness.ps1',
  'scripts/test-google-android-oauth-signing-readiness.ps1',
  'scripts/test-public-auth-sideload-build-controls.ps1'
)) {
  Add-Owner $relative
}

$predecessorPaths = [System.Collections.Generic.HashSet[string]]::new(
  [StringComparer]::Ordinal
)
foreach ($line in Get-Content -LiteralPath $resolvedPredecessor) {
  Assert-ManifestInput `
    ($line -cmatch '^([0-9A-F]{64})  ([^\r\n]+)$') `
    'predecessor manifest contains a malformed row.'
  [void]$predecessorPaths.Add($Matches[2])
}
$predecessorRuntime = @($predecessorPaths | Where-Object {
  $_ -match '^apps/mobile/(lib|assets|packages|android)/' -or
  $_ -cin @('apps/mobile/pubspec.yaml', 'apps/mobile/pubspec.lock')
})
$unmappedPredecessorRuntime = @($predecessorRuntime | Where-Object {
  -not $owners.Contains($_) -and
  (Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf)
})
Assert-ManifestInput `
  ($unmappedPredecessorRuntime.Count -eq 0) `
  'one or more live predecessor runtime owners were omitted.'

$ownerArray = [string[]]@($owners)
[Array]::Sort($ownerArray, [StringComparer]::Ordinal)
$manifestLines = [System.Collections.Generic.List[string]]::new()
foreach ($relative in $ownerArray) {
  $resolved = Resolve-RepositoryFile $relative
  $sha256 = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
  $manifestLines.Add("$sha256  $relative")
}

$outputDirectory = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
  [void](New-Item -ItemType Directory -Path $outputDirectory)
}
$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText(
  $resolvedOutput,
  (($manifestLines -join "`n") + "`n"),
  $utf8NoBom
)
$manifestSha256 = (
  Get-FileHash -LiteralPath $resolvedOutput -Algorithm SHA256
).Hash
$successorOnly = @($ownerArray | Where-Object {
  -not $predecessorPaths.Contains($_)
})

[pscustomobject]@{
  state = if ($CandidateId -ceq
    'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR') {
    'FIX11_GOOGLE_ONLY_SUCCESSOR_BUILD_INPUT_MANIFEST_SEALED'
  } else {
    'FIX8_SUCCESSOR_BUILD_INPUT_MANIFEST_SEALED'
  }
  fileCount = $ownerArray.Count
  sha256 = $manifestSha256
  predecessorManifestRows = $predecessorPaths.Count
  predecessorRuntimeRows = $predecessorRuntime.Count
  unmappedLivePredecessorRuntimeRows = $unmappedPredecessorRuntime.Count
  successorOnlyRows = $successorOnly.Count
  localRepositoryPackages = @($localPackages | Sort-Object -Unique).Count
} | ConvertTo-Json -Compress
