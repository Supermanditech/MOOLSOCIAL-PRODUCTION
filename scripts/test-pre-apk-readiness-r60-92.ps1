[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$gate = Join-Path $root 'scripts\check-pre-apk-readiness-r60-92.ps1'
$liveState = Join-Path $root 'config\pre-apk-readiness-r60-92.json'

function Assert-Test([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "R60.92 pre-APK gate self-test failed: $Message" }
}

function Write-Utf8Json($Value, [string]$Path) {
  $json = $Value | ConvertTo-Json -Depth 30
  [IO.File]::WriteAllText($Path, $json + "`n", [Text.UTF8Encoding]::new($false))
}

function Assert-Rejected(
  [scriptblock]$Mutate,
  [string]$Label,
  [string]$FixtureState,
  [string]$FixtureRoot
) {
  $state = Get-Content -Raw -LiteralPath $liveState | ConvertFrom-Json
  & $Mutate $state
  Write-Utf8Json $state $FixtureState
  $runtimeManifest = Join-Path $FixtureRoot (
    'config\runtime\moolsocial-production-runtime-tickets-20260825.json'
  )
  $identityRecord = [ordered]@{
    candidateId = [string]$state.candidate.id
    versionName = [string]$state.candidate.versionName
    versionCode = [string]$state.candidate.versionCode
  }
  Write-Utf8Json $identityRecord $runtimeManifest
  $rejected = $false
  try {
    & $gate -RepositoryRoot $FixtureRoot -StatePath $FixtureState `
      -Phase CandidateReservation | Out-Null
  } catch {
    $rejected = $true
  }
  Assert-Test $rejected "$Label was accepted."
}

Assert-Test (Test-Path -LiteralPath $gate -PathType Leaf) 'gate is missing.'
Assert-Test (Test-Path -LiteralPath $liveState -PathType Leaf) 'live state is missing.'

& $gate -RepositoryRoot $root -StatePath $liveState `
  -Phase CandidateReservation | Out-Null

$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
  [char[]]@('\', '/')
)
$fixtureRoot = Join-Path $temporaryBase (
  'moolsocial-preapk-gate-' + [Guid]::NewGuid().ToString('N')
)
$fixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
Assert-Test (
  $fixtureRoot.StartsWith(
    $temporaryBase + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  ) -and
  [IO.Path]::GetFileName($fixtureRoot).StartsWith(
    'moolsocial-preapk-gate-',
    [StringComparison]::Ordinal
  )
) 'fixture root escaped the exact temporary namespace.'

try {
  New-Item -ItemType Directory -Path (
    Join-Path $fixtureRoot 'config\runtime'
  ) -Force | Out-Null
  Copy-Item -LiteralPath (
    Join-Path $root 'config\social-runtime-deployment-map-r60-92.json'
  ) -Destination (
    Join-Path $fixtureRoot 'config\social-runtime-deployment-map-r60-92.json'
  )
  Copy-Item -LiteralPath (
    Join-Path $root 'config\social-runtime-deployment-execution-r60-92.json'
  ) -Destination (
    Join-Path $fixtureRoot `
      'config\social-runtime-deployment-execution-r60-92.json'
  )
  New-Item -ItemType Directory -Path (
    Join-Path $fixtureRoot (
      'artifacts\quality\uaw-r60-92-social-runtime-consolidated-apk-20260826-01'
    )
  ) -Force | Out-Null
  $fixtureState = Join-Path $fixtureRoot 'config\pre-apk-readiness-r60-92.json'

  Assert-Rejected -Label 'non-monotonic versionCode' `
    -FixtureState $fixtureState -FixtureRoot $fixtureRoot -Mutate {
      param($state)
      $state.candidate.versionCode = $state.predecessor.versionCode
    }
  Assert-Rejected -Label 'premature build authority' `
    -FixtureState $fixtureState -FixtureRoot $fixtureRoot -Mutate {
      param($state)
      $state.authority.buildAuthorized = $true
    }
  Assert-Rejected -Label 'premature postbuild pass' `
    -FixtureState $fixtureState -FixtureRoot $fixtureRoot -Mutate {
      param($state)
      $state.postBuildGates[0].state = 'passed'
    }
  Assert-Rejected -Label 'package identity drift' `
    -FixtureState $fixtureState -FixtureRoot $fixtureRoot -Mutate {
      param($state)
      $state.candidate.packageName = 'com.example.moolsocial'
    }
  Assert-Rejected -Label 'Social deployment map hash drift' `
    -FixtureState $fixtureState -FixtureRoot $fixtureRoot -Mutate {
      param($state)
      $state.socialDeployment.mapSha256 = ('B' * 64)
    }

  $readyState = Get-Content -Raw -LiteralPath $liveState | ConvertFrom-Json
  $readyState.state = 'preauthorization_ready'
  $readyState.candidate.finalIntegrationHead = '1111111111111111111111111111111111111111'
  $readyState.integrationGate.state = 'passed'
  $readyState.sourceSeal.state = 'passed'
  $readyState.sourceSeal.manifestPath = 'artifacts/quality/source-manifest.txt'
  $readyState.sourceSeal.manifestSha256 = ('A' * 64)
  $readyState.sourceSeal.fileCount = 1
  $readyState.sourceSeal.cycle1 = 'passed'
  $readyState.sourceSeal.cycle2 = 'passed'
  $readyState.runtimeConfiguration.state = 'passed_sanitized_binding'
  $readyState.runtimeConfiguration.exactNonSecretDefinesBound = $true
  $readyState.runtimeConfiguration.requiredPrivateDefineNamesBoundWithoutValues = $true
  $readyState.runtimeConfiguration.mixedClientServerContractPrevented = $true
  $readyState.dependencyGate.state = 'passed'
  $readyState.dependencyGate.wrapperQualified = $true
  $readyState.dependencyGate.postBuildPluginIntegrityQualified = $true
  $readyState.socialDeployment.state = 'passed_deploy_map_held'
  foreach ($gateState in @($readyState.preBuildGates)) {
    $gateState.state = 'passed'
  }
  $readyState.blockers = @('one_build_authority_founder_held')
  Write-Utf8Json $readyState $fixtureState
  Write-Utf8Json ([ordered]@{
      candidateId = [string]$readyState.candidate.id
      versionName = [string]$readyState.candidate.versionName
      versionCode = [string]$readyState.candidate.versionCode
    }) (Join-Path $fixtureRoot (
      'config\runtime\moolsocial-production-runtime-tickets-20260825.json'
    ))
  & $gate -RepositoryRoot $fixtureRoot -StatePath $fixtureState `
    -Phase PreauthorizationReady | Out-Null

  $readyState.state = 'one_build_authorized'
  $readyState.authority.buildAuthorized = $true
  $readyState.blockers = @()
  Write-Utf8Json $readyState $fixtureState
  & $gate -RepositoryRoot $fixtureRoot -StatePath $fixtureState `
    -Phase BuildAuthorized | Out-Null

  $readyState.preBuildGates[0].state = 'pending'
  Write-Utf8Json $readyState $fixtureState
  $buildWithoutReadinessRejected = $false
  try {
    & $gate -RepositoryRoot $fixtureRoot -StatePath $fixtureState `
      -Phase BuildAuthorized | Out-Null
  } catch {
    $buildWithoutReadinessRejected = $true
  }
  Assert-Test $buildWithoutReadinessRejected `
    'BuildAuthorized accepted one pending pre-build gate.'
} finally {
  if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    Assert-Test (
      $resolvedFixture.StartsWith(
        $temporaryBase + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      ) -and
      [IO.Path]::GetFileName($resolvedFixture).StartsWith(
        'moolsocial-preapk-gate-',
        [StringComparison]::Ordinal
      )
    ) 'fixture cleanup target changed.'
    Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
  }
}

Write-Output (
  'R60.92 pre-APK gate self-test passed: ' +
  'live=1; preauthorization=1; buildAuthorization=1; negative=6.'
)
