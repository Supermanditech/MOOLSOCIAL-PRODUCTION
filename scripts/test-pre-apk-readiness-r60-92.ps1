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

Write-Output 'R60.92 pre-APK gate self-test passed: live=1; negative=4.'
