[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$ticketId =
  'UAW-C34J-R60-74-RELEASE-LIFECYCLE-ATOMIC-PARITY-PLAY-OPPO-ACCEPTANCE'
$transitionRelative = 'scripts/invoke-release-lifecycle-transition-c34j.ps1'
$transitionPath = Join-Path $root $transitionRelative

function Assert-C34JFixture {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) { throw "C34J lifecycle fixture rejected: $Message" }
}

Assert-C34JFixture -Condition (
  Test-Path -LiteralPath $transitionPath -PathType Leaf
) -Message 'transition owner is missing.'
$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
  $transitionPath, [ref]$null, [ref]$parseErrors
)
Assert-C34JFixture -Condition (@($parseErrors).Count -eq 0) `
  -Message 'transition owner does not parse.'
$transitionSource = Get-Content -Raw -LiteralPath $transitionPath
foreach ($forbidden in @(
  'firebase login:list --json', 'Authorization: Bearer',
  ('-----BEGIN' + ' PRIVATE KEY-----'), 'adb install', 'pm clear', 'uninstall'
)) {
  Assert-C34JFixture -Condition (
    $transitionSource.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -lt 0
  ) -Message "transition owner contains forbidden action: $forbidden"
}

$fixtureRootRelative =
  'tmp/c34j-lifecycle-fixtures-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
$fixtureRoot = Join-Path $root $fixtureRootRelative
[void](New-Item -ItemType Directory -Path $fixtureRoot)

function Write-FixtureJson {
  param([object]$Value, [string]$Path)
  [IO.File]::WriteAllText(
    $Path,
    (($Value | ConvertTo-Json -Depth 40) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
  )
}

function New-C34JFixture {
  param([Parameter(Mandatory)][string]$Name)
  $directoryRelative = "$fixtureRootRelative/$Name"
  $directory = Join-Path $root $directoryRelative
  [void](New-Item -ItemType Directory -Path $directory)
  $stateRelative = "$directoryRelative/state.json"
  $aggregateRelative = "$directoryRelative/aggregate.json"
  $statePath = Join-Path $root $stateRelative
  $aggregatePath = Join-Path $root $aggregateRelative
  $initial =
    'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required'
  $state = [ordered]@{
    schemaVersion = 1
    contractId = 'MOOLSOCIAL-C34J-R60-74-RELEASE-LIFECYCLE-STATE-FIXTURE'
    ticketId = $ticketId
    aggregateStatePath = $aggregateRelative
    machineState = $initial
    buildAuthorization = 'available_once'
    uploadAuthorization = 'held_postbuild_qualification'
    installAuthorization = 'held_postupload_qualification'
    deviceAuthorization = 'held_postinstall_journey_qualification'
    candidate = [ordered]@{
      id = $ticketId
      disposition = $initial
      artifactReusable = $false
    }
    authority = [ordered]@{
      founderHiddenInputEntryAuthorized = $true
    }
    founderAuthorization = [ordered]@{
      hiddenFounderInputsEntered = $false
    }
    runtimeConfiguration = [ordered]@{
      secretDefineFileQualifiedByFounder = $false
      googleServicesFileQualifiedByFounder = $false
      googleServerClientIdQualifiedByFounder = $false
    }
    releaseAuthorities = [ordered]@{
      build = 'available_once'
      uploadAndInternalActivation = 'held_postbuild_qualification'
      inPlaceOppoPlayUpdate = 'held_postupload_qualification'
      postinstallAcceptance = 'held_postinstall_journey_qualification'
    }
    actionCounts = [ordered]@{
      build = 0
      upload = 0
      install = 0
      deviceAcceptance = 0
    }
    buildResult = [ordered]@{
      state = 'not_started'
      buildCount = 0
      wrapperInvocationCount = 0
      configOnlyCount = 0
      artifactPath = $null
      artifactSha256 = $null
      artifactBytes = 0
      uploadSignerSha256 = $null
      packageVersionManifestProved = $false
      googleAppIdResourceProved = $false
      crashlyticsBuildIdResourceProved = $false
      splitAndArm64PayloadProved = $false
      mergedReleaseManifestProved = $false
      provenance = $null
    }
    playResult = [ordered]@{
      uploadCount = 0
      internalActivationCount = 0
      evidencePath = $null
    }
    installResult = [ordered]@{
      installCount = 0
      coldStartEvidencePath = $null
      journeyEvidencePath = $null
      acceptanceSucceeded = $false
    }
    rejection = $null
  }
  $aggregate = [ordered]@{
    schemaVersion = 1
    contractId = 'MOOLSOCIAL-C34J-R60-74-RELEASE-LIFECYCLE-AGGREGATE-FIXTURE'
    ticketId = $ticketId
    machineState = $initial
    candidate = [ordered]@{
      id = $ticketId
      buildCount = 0
      uploadCount = 0
      installCount = 0
      deviceAcceptanceCount = 0
      aabSha256 = $null
      disposition = $initial
      artifactReusable = $false
    }
    releaseAuthorities = [ordered]@{
      build = 'available_once'
      uploadAndInternalActivation = 'held_postbuild_qualification'
      inPlaceOppoPlayUpdate = 'held_postupload_qualification'
      postinstallAcceptance = 'held_postinstall_journey_qualification'
    }
    actionCounts = [ordered]@{
      build = 0
      upload = 0
      install = 0
      deviceAcceptance = 0
    }
    rejection = $null
  }
  Write-FixtureJson -Value $state -Path $statePath
  Write-FixtureJson -Value $aggregate -Path $aggregatePath
  return [pscustomobject]@{
    stateRelative = $stateRelative
    aggregateRelative = $aggregateRelative
    statePath = $statePath
    aggregatePath = $aggregatePath
  }
}

function Invoke-C34JFixtureTransition {
  param(
    [Parameter(Mandatory)][object]$Fixture,
    [Parameter(Mandatory)][string]$Transition,
    [hashtable]$Additional = @{}
  )
  $parameters = @{
    Transition = $Transition
    StatePath = [string]$Fixture.stateRelative
    FixtureMode = $true
    RepositoryRoot = $root
  }
  foreach ($key in $Additional.Keys) { $parameters[$key] = $Additional[$key] }
  & $transitionPath @parameters | Out-Null
}

function Get-C34JFixtureState {
  param([Parameter(Mandatory)][object]$Fixture)
  return [pscustomobject]@{
    state = Get-Content -Raw -LiteralPath $Fixture.statePath | ConvertFrom-Json
    aggregate = Get-Content -Raw -LiteralPath $Fixture.aggregatePath | ConvertFrom-Json
  }
}

function Get-C34JFixtureHashes {
  param([Parameter(Mandatory)][object]$Fixture)
  return (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $Fixture.statePath).Hash + ':' +
    (Get-FileHash -Algorithm SHA256 -LiteralPath $Fixture.aggregatePath).Hash
  )
}

function Assert-C34JExpectedRejection {
  param(
    [Parameter(Mandatory)][object]$Fixture,
    [Parameter(Mandatory)][scriptblock]$Action,
    [Parameter(Mandatory)][string]$Label
  )
  $before = Get-C34JFixtureHashes -Fixture $Fixture
  $rejected = $false
  try { & $Action } catch { $rejected = $true }
  $after = Get-C34JFixtureHashes -Fixture $Fixture
  Assert-C34JFixture -Condition ($rejected -and $after -ceq $before) `
    -Message "$Label did not fail before both target files changed."
}

try {
  $positive = New-C34JFixture -Name 'positive-all-phases'
  Invoke-C34JFixtureTransition -Fixture $positive -Transition 'founder-inputs-validated'
  Invoke-C34JFixtureTransition -Fixture $positive -Transition 'build-start'
  $afterStart = Get-C34JFixtureState -Fixture $positive
  Assert-C34JFixture -Condition (
    [string]$afterStart.state.releaseAuthorities.build -ceq 'consumed' -and
    [string]$afterStart.aggregate.releaseAuthorities.build -ceq 'consumed' -and
    [int]$afterStart.state.actionCounts.build -eq 1 -and
    [int]$afterStart.aggregate.candidate.buildCount -eq 1 -and
    -not [bool]$afterStart.state.authority.founderHiddenInputEntryAuthorized
  ) -Message 'build-start did not consume every detailed and aggregate mirror.'
  Invoke-C34JFixtureTransition -Fixture $positive -Transition 'build-succeeded' `
    -Additional @{
      ArtifactPath = 'tmp/c34j-fixture.aab'
      ArtifactSha256 = ('A' * 64)
      ArtifactBytes = 94797571
      UploadSignerSha256 = ('B' * 64)
      ArtifactProvenance = 'tmp/c34j-fixture-provenance.json'
    }
  Invoke-C34JFixtureTransition -Fixture $positive -Transition 'upload-authorized'
  Invoke-C34JFixtureTransition -Fixture $positive -Transition 'upload-succeeded' `
    -Additional @{ EvidencePath = 'tmp/c34j-fixture-play.json' }
  Invoke-C34JFixtureTransition -Fixture $positive -Transition 'install-authorized'
  Invoke-C34JFixtureTransition -Fixture $positive -Transition 'install-succeeded' `
    -Additional @{ EvidencePath = 'tmp/c34j-fixture-oppo.json' }
  Invoke-C34JFixtureTransition -Fixture $positive -Transition 'device-accepted' `
    -Additional @{ EvidencePath = 'tmp/c34j-fixture-journeys.json' }
  $accepted = Get-C34JFixtureState -Fixture $positive
  Assert-C34JFixture -Condition (
    [string]$accepted.state.machineState -ceq
      'internal_testing_oppo_device_acceptance_succeeded' -and
    @(
      $accepted.state.actionCounts.build,
      $accepted.state.actionCounts.upload,
      $accepted.state.actionCounts.install,
      $accepted.state.actionCounts.deviceAcceptance
    ) -join ',' -ceq '1,1,1,1' -and
    -not [bool]$accepted.state.candidate.artifactReusable -and
    -not [bool]$accepted.aggregate.candidate.artifactReusable
  ) -Message 'positive all-phase transition result changed.'

  $rejectFixture = New-C34JFixture -Name 'positive-rejection'
  Invoke-C34JFixtureTransition -Fixture $rejectFixture -Transition 'reject' `
    -Additional @{
      RejectionMachineState = 'prebuild_rejected_fixture_successor_required'
      RejectionRegistryId = 'REG-20260817-9999-C34J-FIXTURE'
      EvidencePath = 'tmp/c34j-fixture-rejection.md'
    }
  $rejectedState = Get-C34JFixtureState -Fixture $rejectFixture
  Assert-C34JFixture -Condition (
    [string]$rejectedState.state.candidate.disposition -ceq 'rejected' -and
    [string]$rejectedState.aggregate.candidate.disposition -ceq 'rejected' -and
    -not [bool]$rejectedState.state.candidate.artifactReusable -and
    [bool]$rejectedState.state.rejection.successorRequired
  ) -Message 'positive rejection transition changed.'

  $buildFailure = New-C34JFixture -Name 'positive-build-failure'
  Invoke-C34JFixtureTransition -Fixture $buildFailure `
    -Transition 'founder-inputs-validated'
  Invoke-C34JFixtureTransition -Fixture $buildFailure -Transition 'build-start'
  Invoke-C34JFixtureTransition -Fixture $buildFailure -Transition 'build-failed' `
    -Additional @{ EvidencePath = 'tmp/c34j-fixture-build-failure.log' }
  $failedState = Get-C34JFixtureState -Fixture $buildFailure
  Assert-C34JFixture -Condition (
    [string]$failedState.state.machineState -ceq
      'single_release_AAB_failed_authority_consumed_successor_required' -and
    [string]$failedState.state.releaseAuthorities.build -ceq 'consumed' -and
    [string]$failedState.state.releaseAuthorities.uploadAndInternalActivation -ceq
      'rejected_candidate' -and
    [string]$failedState.aggregate.candidate.disposition -ceq 'rejected'
  ) -Message 'positive build-failure transition changed.'

  $prebuildFailure = New-C34JFixture -Name 'positive-prebuild-failure'
  Invoke-C34JFixtureTransition -Fixture $prebuildFailure `
    -Transition 'founder-inputs-validated'
  Invoke-C34JFixtureTransition -Fixture $prebuildFailure `
    -Transition 'prebuild-failed' `
    -Additional @{ EvidencePath = 'tmp/c34j-fixture-prebuild-owner.ps1' }
  $prebuildFailedState = Get-C34JFixtureState -Fixture $prebuildFailure
  Assert-C34JFixture -Condition (
    [string]$prebuildFailedState.state.machineState -ceq
      'founder_inputs_validated_prebuild_failed_successor_required' -and
    [string]$prebuildFailedState.state.releaseAuthorities.build -ceq
      'rejected_candidate' -and
    [int]$prebuildFailedState.state.actionCounts.build -eq 0 -and
    [string]$prebuildFailedState.aggregate.candidate.disposition -ceq 'rejected'
  ) -Message 'positive prebuild-failure transition changed.'

  $wrongPhase = New-C34JFixture -Name 'negative-wrong-phase'
  Assert-C34JExpectedRejection -Fixture $wrongPhase -Label 'wrong phase' -Action {
    Invoke-C34JFixtureTransition -Fixture $wrongPhase -Transition 'build-start'
  }

  $missingMirror = New-C34JFixture -Name 'negative-missing-mirror'
  $missingAggregate = Get-Content -Raw -LiteralPath $missingMirror.aggregatePath |
    ConvertFrom-Json
  $missingAggregate.releaseAuthorities.PSObject.Properties.Remove('build')
  Write-FixtureJson -Value $missingAggregate -Path $missingMirror.aggregatePath
  Assert-C34JExpectedRejection -Fixture $missingMirror -Label 'missing mirror' -Action {
    Invoke-C34JFixtureTransition -Fixture $missingMirror `
      -Transition 'founder-inputs-validated'
  }

  $staleCount = New-C34JFixture -Name 'negative-stale-count'
  $staleState = Get-Content -Raw -LiteralPath $staleCount.statePath | ConvertFrom-Json
  $staleAggregate = Get-Content -Raw -LiteralPath $staleCount.aggregatePath |
    ConvertFrom-Json
  $staleState.actionCounts.build = 1
  $staleAggregate.actionCounts.build = 1
  $staleAggregate.candidate.buildCount = 1
  Write-FixtureJson -Value $staleState -Path $staleCount.statePath
  Write-FixtureJson -Value $staleAggregate -Path $staleCount.aggregatePath
  Assert-C34JExpectedRejection -Fixture $staleCount -Label 'stale count' -Action {
    Invoke-C34JFixtureTransition -Fixture $staleCount `
      -Transition 'founder-inputs-validated'
  }

  $wrongArtifact = New-C34JFixture -Name 'negative-wrong-artifact'
  Invoke-C34JFixtureTransition -Fixture $wrongArtifact `
    -Transition 'founder-inputs-validated'
  Invoke-C34JFixtureTransition -Fixture $wrongArtifact -Transition 'build-start'
  Assert-C34JExpectedRejection -Fixture $wrongArtifact -Label 'wrong artifact' -Action {
    Invoke-C34JFixtureTransition -Fixture $wrongArtifact -Transition 'build-succeeded' `
      -Additional @{
        ArtifactPath = 'tmp/c34j-fixture.aab'
        ArtifactSha256 = 'INVALID'
        ArtifactBytes = 1
        UploadSignerSha256 = ('B' * 64)
        ArtifactProvenance = 'tmp/c34j-fixture-provenance.json'
      }
  }

  $secondInvocation = New-C34JFixture -Name 'negative-second-invocation'
  Invoke-C34JFixtureTransition -Fixture $secondInvocation `
    -Transition 'founder-inputs-validated'
  Assert-C34JExpectedRejection -Fixture $secondInvocation `
    -Label 'second invocation' -Action {
      Invoke-C34JFixtureTransition -Fixture $secondInvocation `
        -Transition 'founder-inputs-validated'
    }

  $rollback = New-C34JFixture -Name 'negative-rollback'
  Invoke-C34JFixtureTransition -Fixture $rollback `
    -Transition 'founder-inputs-validated'
  Assert-C34JExpectedRejection -Fixture $rollback `
    -Label 'injected second-write failure rollback' -Action {
      Invoke-C34JFixtureTransition -Fixture $rollback -Transition 'build-start' `
        -Additional @{ InjectFailureAfterStateCommit = $true }
    }

  Write-Output (
    'C34J lifecycle transition fixture passed: ' +
    'declaredTransitions=11; negativeFixtures=6; rollback=proved; ' +
    "hostPowerShellMajor=$($PSVersionTable.PSVersion.Major); externalWrites=0."
  )
} finally {
  if (Test-Path -LiteralPath $fixtureRoot) {
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    $expectedPrefix = [IO.Path]::GetFullPath(
      (Join-Path $root 'tmp/c34j-lifecycle-fixtures-')
    )
    if ($resolvedFixture.StartsWith(
      $expectedPrefix, [StringComparison]::OrdinalIgnoreCase
    )) {
      Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
    }
  }
}
