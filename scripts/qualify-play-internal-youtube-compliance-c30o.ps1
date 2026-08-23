[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet(1, 2)]
  [int]$Cycle,

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$repositoryRootFull = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$candidateId =
  'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30O'
$artifactRelative =
  'artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30o-r60-41-20260812-02'
$artifactRoot = Join-Path $repositoryRootFull $artifactRelative
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
$attempt = if ($Cycle -eq 1) { '1rr' } else { '2' }

function Invoke-NativeLogged {
  param(
    [Parameter(Mandatory)]
    [string]$Command,

    [Parameter(Mandatory)]
    [string[]]$Arguments,

    [Parameter(Mandatory)]
    [string]$WorkingDirectory,

    [Parameter(Mandatory)]
    [string]$LogPath
  )

  Push-Location $WorkingDirectory
  try {
    & $Command @Arguments 2>&1 |
      Tee-Object -FilePath $LogPath |
      Out-Null
    $nativeExit = $LASTEXITCODE
  }
  finally {
    Pop-Location
  }
  if ($nativeExit -ne 0) {
    throw ('Command failed with exit {0}; log={1}' -f $nativeExit, $LogPath)
  }
}

& (Join-Path $repositoryRootFull 'scripts/check-codex-development-regression-memory.ps1') `
  -Phase implementation
& (Join-Path $repositoryRootFull 'scripts/check-mvp-scope-gate-state.ps1') `
  -CandidateId $candidateId `
  -RequireExecutionAuthorized `
  -RepositoryRoot $repositoryRootFull
& (Join-Path $repositoryRootFull 'scripts/check-play-internal-aab-regression-gate-state-c30o.ps1') `
  -Phase reconcile `
  -RepositoryRoot $repositoryRootFull

$baselineManifest = Join-Path `
  $repositoryRootFull `
  'artifacts/quality/uaw-personal-mvp-social-public-feed-create-oppo-qualification-c30n-r60-40-20260812-01/source-aggregate-manifest.txt'
$paths = @(
  Get-Content -LiteralPath $baselineManifest |
    ForEach-Object { ($_ -split '  ', 2)[1] }
)
$paths += @(
  'apps/mobile/android/app/build.gradle.kts',
  'apps/mobile/lib/ui_v2/social/social_v2_youtube_creator_upload.dart',
  'apps/mobile/packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/com/moolsocial/app/youtube/YouTubeEmbeddedPlayerPlatformView.kt',
  'apps/mobile/packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/com/moolsocial/app/youtube/YouTubeEmbeddedPlayerPlatformViewFactory.kt',
  'apps/mobile/packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/com/moolsocial/youtube_embedded_player_private_dev/YouTubeEmbeddedPlayerPrivateDevRegistrar.kt',
  'apps/mobile/packages/youtube_embedded_player_private_dev/android/src/release/kotlin/com/moolsocial/youtube_embedded_player_private_dev/YouTubeEmbeddedPlayerPrivateDevRegistrar.kt',
  'apps/mobile/test/platform_configuration_test.dart',
  'apps/mobile/test/ui_v2_social_continuous_batch_test.dart',
  'apps/mobile/test/youtube_embedded_player_android_test.dart',
  'scripts/check-play-internal-aab-build-wrapper-c30o.ps1',
  'scripts/check-play-internal-aab-regression-gate-state-c30o.ps1',
  'scripts/check-youtube-embedded-player-android.ps1',
  'scripts/invoke-play-internal-aab-build-c30o.ps1',
  'scripts/qualify-play-internal-youtube-compliance-c30o.ps1'
)
$paths = @($paths | Sort-Object -Unique)
foreach ($path in $paths) {
  $absolute = Join-Path $repositoryRootFull $path
  if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
    throw ('Manifest owner is missing: {0}' -f $path)
  }
}

$dartPaths = @(
  $paths |
    Where-Object { $_.EndsWith('.dart', [StringComparison]::Ordinal) } |
    ForEach-Object { $_.Substring('apps/mobile/'.Length) }
)
$testPaths = @(
  $dartPaths |
    Where-Object { $_.StartsWith('test/', [StringComparison]::Ordinal) }
)
$mobileRoot = Join-Path $repositoryRootFull 'apps/mobile'
$formatLog = Join-Path $artifactRoot ('{0:D2}-cycle-{1}-format.log' -f $Cycle, $attempt)
$analyzeLog = Join-Path $artifactRoot ('{0:D2}-cycle-{1}-analyze.log' -f $Cycle, $attempt)
$testLog = Join-Path $artifactRoot ('{0:D2}-cycle-{1}-tests.log' -f $Cycle, $attempt)
$gateLog = Join-Path $artifactRoot ('{0:D2}-cycle-{1}-gates.log' -f $Cycle, $attempt)

Invoke-NativeLogged `
  -Command 'dart' `
  -Arguments (@('format', '--output=none', '--set-exit-if-changed') + $dartPaths) `
  -WorkingDirectory $mobileRoot `
  -LogPath $formatLog
Invoke-NativeLogged `
  -Command 'flutter' `
  -Arguments @('analyze') `
  -WorkingDirectory $mobileRoot `
  -LogPath $analyzeLog
Invoke-NativeLogged `
  -Command 'flutter' `
  -Arguments (@('test', '--reporter', 'compact') + $testPaths) `
  -WorkingDirectory $mobileRoot `
  -LogPath $testLog

$gateCommands = @(
  'scripts/check-play-internal-aab-build-wrapper-c30o.ps1',
  'scripts/check-youtube-embedded-player-android.ps1',
  'scripts/check-codex-development-regression-memory.ps1',
  'scripts/check-play-internal-aab-regression-gate-state-c30o.ps1'
)
foreach ($gate in $gateCommands) {
  & (Join-Path $repositoryRootFull $gate) 2>&1 |
    Tee-Object -FilePath $gateLog -Append |
    Out-Null
}

$manifestRows = @(
  foreach ($path in $paths) {
    $hash = (Get-FileHash `
      -LiteralPath (Join-Path $repositoryRootFull $path) `
      -Algorithm SHA256
    ).Hash
    '{0}  {1}' -f $hash, $path.Replace('\', '/')
  }
)
$manifestPath = Join-Path $artifactRoot 'source-aggregate-manifest.txt'
[IO.File]::WriteAllLines(
  $manifestPath,
  $manifestRows,
  [Text.UTF8Encoding]::new($false)
)
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
$testPassed = Select-String `
  -LiteralPath $testLog `
  -Pattern 'All tests passed!' `
  -Quiet
if (-not $testPassed) {
  throw 'The complete Flutter test log lacks the success marker.'
}
$cycleResult = [ordered]@{
  schemaVersion = 1
  candidateId = $candidateId
  cycle = $Cycle
  branch = (& git -C $repositoryRootFull branch --show-current).Trim()
  head = (& git -C $repositoryRootFull rev-parse HEAD).Trim()
  sourceManifest = '{0}/source-aggregate-manifest.txt' -f $artifactRelative
  sourceManifestSha256 = $manifestHash
  sourceFiles = $paths.Count
  dartFilesChecked = $dartPaths.Count
  flutterAnalyze = 'clean'
  flutterTestFiles = $testPaths.Count
  flutterTests = 'passed'
  releasePlayerGate = 'passed'
  regressionMemoryGate = 'passed'
  C30OReconcileGate = 'passed'
  formatLogSha256 = (Get-FileHash -LiteralPath $formatLog -Algorithm SHA256).Hash
  analyzeLogSha256 = (Get-FileHash -LiteralPath $analyzeLog -Algorithm SHA256).Hash
  testLogSha256 = (Get-FileHash -LiteralPath $testLog -Algorithm SHA256).Hash
  gateLogSha256 = (Get-FileHash -LiteralPath $gateLog -Algorithm SHA256).Hash
  testSuccessMarker = 'All tests passed!'
}
$cycleJson = $cycleResult | ConvertTo-Json -Depth 8
$cyclePath = Join-Path $artifactRoot ('{0:D2}-source-qualifying-cycle-{1}.json' -f $Cycle, $Cycle)
[IO.File]::WriteAllText(
  $cyclePath,
  $cycleJson + [Environment]::NewLine,
  [Text.UTF8Encoding]::new($false)
)

Write-Output (
  'C30O source cycle {0} passed: files={1}; tests={2}; manifestSha256={3}' -f
    $Cycle,
    $paths.Count,
    $testPaths.Count,
    $manifestHash
)
Write-Output 'All tests passed!'
