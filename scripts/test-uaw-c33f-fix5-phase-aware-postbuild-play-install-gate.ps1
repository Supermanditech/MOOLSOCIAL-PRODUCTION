[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$phaseGate = Join-Path $root 'scripts/check-uaw-c33f-fix5-release-phase-transition.ps1'
$statePath = Join-Path $root 'config/successor-aab-regression-hard-gate-state-c33f.json'
$aggregatePath = Join-Path $root 'config/successor-aab-regression-hard-gate-aggregate-c33f.json'
$evidenceRoot = Join-Path $root 'artifacts/quality/uaw-c33f-r60-49-successor-preparation-20260815-01'
$fixtureRoot = Join-Path $evidenceRoot ('.tmp-fix5-phase-fixtures-' + [guid]::NewGuid().ToString('N'))
$fixturePrefix = [IO.Path]::GetFullPath($fixtureRoot) + [IO.Path]::DirectorySeparatorChar

function Assert-C33FFix5Test {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33F FIX5 phase test rejected: $Message"
  }
}

function Copy-C33FFix5Object {
  param([Parameter(Mandatory)]$Object)
  return ($Object | ConvertTo-Json -Depth 50 | ConvertFrom-Json)
}

function ConvertTo-C33FFix5RelativePath {
  param([Parameter(Mandatory)][string]$Path)
  $resolved = [IO.Path]::GetFullPath($Path)
  $rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
  Assert-C33FFix5Test -Condition (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "fixture path escaped the repository: $Path"
  return $resolved.Substring($rootPrefix.Length).Replace('\', '/')
}

function Write-C33FFix5Json {
  param(
    [Parameter(Mandatory)]$Value,
    [Parameter(Mandatory)][string]$Path
  )
  [IO.File]::WriteAllText(
    $Path,
    (($Value | ConvertTo-Json -Depth 50) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
  )
}

function Write-C33FFix5Fixture {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)]$State,
    [Parameter(Mandatory)]$Aggregate
  )
  $aggregateFixture = Join-Path $fixtureRoot ($Name + '-aggregate.json')
  $stateFixture = Join-Path $fixtureRoot ($Name + '-state.json')
  $State.aggregateStatePath = ConvertTo-C33FFix5RelativePath -Path $aggregateFixture
  Write-C33FFix5Json -Value $Aggregate -Path $aggregateFixture
  Write-C33FFix5Json -Value $State -Path $stateFixture
  return $stateFixture
}

function Invoke-C33FFix5ExpectedPass {
  param(
    [Parameter(Mandatory)][string]$Phase,
    [Parameter(Mandatory)][string]$FixturePath
  )
  & $phaseGate -Phase $Phase -StatePath $FixturePath -RepositoryRoot $root | Out-Null
}

function Invoke-C33FFix5ExpectedReject {
  param(
    [Parameter(Mandatory)][string]$Phase,
    [Parameter(Mandatory)][string]$FixturePath,
    [Parameter(Mandatory)][string]$Label
  )
  $rejected = $false
  try {
    & $phaseGate -Phase $Phase -StatePath $FixturePath -RepositoryRoot $root | Out-Null
  } catch {
    $rejected = $_.Exception.Message.StartsWith(
      'C33F FIX5 release phase transition rejected:',
      [StringComparison]::Ordinal
    )
  }
  Assert-C33FFix5Test -Condition $rejected -Message "$Label was not rejected."
}

$tokens = $null
$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
  $phaseGate,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33FFix5Test -Condition (@($parseErrors).Count -eq 0) `
  -Message 'phase-transition gate does not parse.'
Assert-C33FFix5Test -Condition (Test-Path -LiteralPath $statePath -PathType Leaf) `
  -Message 'current C33F state is missing.'
Assert-C33FFix5Test -Condition (Test-Path -LiteralPath $aggregatePath -PathType Leaf) `
  -Message 'current C33F aggregate is missing.'

$baseState = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
$baseAggregate = Get-Content -Raw -LiteralPath $aggregatePath | ConvertFrom-Json

try {
  [void](New-Item -ItemType Directory -Path $fixtureRoot -Force)

  $playPath = Join-Path $fixtureRoot 'play-internal-evidence.json'
  $coldPath = Join-Path $fixtureRoot 'cold-start-evidence.json'
  $retainedPath = Join-Path $fixtureRoot 'retained-data-evidence.json'
  $journeyPath = Join-Path $fixtureRoot 'journey-evidence.json'

  $playEvidence = [ordered]@{
    candidateId = [string]$baseState.candidate.id
    packageName = 'com.moolsocial.app'
    versionName = [string]$baseState.candidate.versionName
    versionCode = [string]$baseState.candidate.versionCode
    artifactSha256 = [string]$baseState.buildResult.artifactSha256
    track = 'internal'
    internalReleaseActive = $true
    uploadCount = 1
    otherTrackChanged = $false
  }
  $coldEvidence = [ordered]@{
    packageName = 'com.moolsocial.app'
    versionCode = [string]$baseState.candidate.versionCode
    installerPackage = 'com.android.vending'
    firstScreenName = 'MoolSocialHome'
    coldStartInteractive = $true
    blankHierarchy = $false
    timeout = $false
    flutterFatalErrorCount = 0
    androidRuntimeFatalCount = 0
    anrCount = 0
    appProcessErrorScanPassed = $true
    artifactRelationshipProved = $true
    inPlaceUpdateProved = $true
  }
  $retainedEvidence = [ordered]@{
    packageName = 'com.moolsocial.app'
    versionCode = [string]$baseState.candidate.versionCode
    installerPackage = 'com.android.vending'
    firstInstallTimeMillis = 1000
    lastUpdateTimeMillis = 2000
    firstInstallTimePreserved = $true
    retainedDataContinuityProved = $true
    inPlacePlayUpdateProved = $true
    uninstallPerformed = $false
    dataClearPerformed = $false
    downgradePerformed = $false
    adbInstallPerformed = $false
  }
  $journeyEvidence = [ordered]@{
    candidateId = [string]$baseState.candidate.id
    versionName = [string]$baseState.candidate.versionName
    versionCode = [string]$baseState.candidate.versionCode
    packageName = 'com.moolsocial.app'
    track = 'internal'
    deviceSerial = '2b3e0f71'
    installerPackage = 'com.android.vending'
    allMandatoryJourneysPassed = $true
    evidenceComplete = $true
    newIssueCount = 0
    newDefectCount = 0
    blankScreenCount = 0
    flutterFatalErrorCount = 0
    androidRuntimeFatalCount = 0
    anrCount = 0
    acceptanceSucceeded = $true
    successClaimed = $true
  }
  Write-C33FFix5Json -Value $playEvidence -Path $playPath
  Write-C33FFix5Json -Value $coldEvidence -Path $coldPath
  Write-C33FFix5Json -Value $retainedEvidence -Path $retainedPath
  Write-C33FFix5Json -Value $journeyEvidence -Path $journeyPath

  $phaseFixtures = [ordered]@{}

  foreach ($phase in @('implementation', 'build')) {
    $state = Copy-C33FFix5Object -Object $baseState
    $aggregate = Copy-C33FFix5Object -Object $baseAggregate
    $state.machineState = 'source_and_live_readiness_qualified_founder_secret_prompt_required'
    $aggregate.machineState = $state.machineState
    $state.buildAuthorization = 'available_once'
    $state.uploadAuthorization = 'held_postbuild_qualification'
    $state.installAuthorization = 'held_Play_activation_and_provenance'
    $state.deviceAuthorization = 'held_in_place_Play_update'
    $state.founderAuthorization.hiddenFounderInputsEntered = $false
    $state.buildResult.state = 'not_started'
    $state.buildResult.buildCount = 0
    $state.buildResult.wrapperInvocationCount = 0
    $state.buildResult.configOnlyCount = 0
    $state.actionCounts.build = 0
    $state.actionCounts.upload = 0
    $state.actionCounts.install = 0
    $state.actionCounts.deviceAcceptance = 0
    $state.playResult.uploadCount = 0
    $state.playResult.internalActivationCount = 0
    $state.installResult.installCount = 0
    $aggregate.candidate.buildCount = 0
    $aggregate.candidate.uploadCount = 0
    $aggregate.candidate.installCount = 0
    $aggregate.candidate.deviceAcceptanceCount = 0
    $fixture = Write-C33FFix5Fixture -Name $phase -State $state -Aggregate $aggregate
    $phaseFixtures[$phase] = [pscustomobject]@{ State=$state; Aggregate=$aggregate; Path=$fixture }
  }

  $state = Copy-C33FFix5Object -Object $baseState
  $aggregate = Copy-C33FFix5Object -Object $baseAggregate
  $state.machineState = 'single_release_AAB_succeeded_authority_consumed'
  $aggregate.machineState = $state.machineState
  $state.buildAuthorization = 'consumed'
  $state.uploadAuthorization = 'held_postbuild_qualification'
  $state.installAuthorization = 'held_Play_activation_and_provenance'
  $state.deviceAuthorization = 'held_in_place_Play_update'
  $state.founderAuthorization.hiddenFounderInputsEntered = $true
  $state.buildResult.state = 'single_release_AAB_succeeded_authority_consumed'
  $state.buildResult.buildCount = 1
  $state.buildResult.wrapperInvocationCount = 1
  $state.buildResult.configOnlyCount = 1
  $state.actionCounts.build = 1
  $state.playResult.uploadCount = 0
  $state.playResult.internalActivationCount = 0
  $state.actionCounts.upload = 0
  $state.installResult.installCount = 0
  $state.installResult.acceptanceSucceeded = $false
  $state.actionCounts.install = 0
  $state.actionCounts.deviceAcceptance = 0
  $aggregate.candidate.buildCount = 1
  $aggregate.candidate.uploadCount = 0
  $aggregate.candidate.installCount = 0
  $aggregate.candidate.deviceAcceptanceCount = 0
  $fixture = Write-C33FFix5Fixture -Name 'postbuild' -State $state -Aggregate $aggregate
  $phaseFixtures.postbuild = [pscustomobject]@{ State=$state; Aggregate=$aggregate; Path=$fixture }

  $state = Copy-C33FFix5Object -Object $phaseFixtures.postbuild.State
  $aggregate = Copy-C33FFix5Object -Object $phaseFixtures.postbuild.Aggregate
  $state.uploadAuthorization = 'available_once'
  $fixture = Write-C33FFix5Fixture -Name 'preupload' -State $state -Aggregate $aggregate
  $phaseFixtures.preupload = [pscustomobject]@{ State=$state; Aggregate=$aggregate; Path=$fixture }

  $state = Copy-C33FFix5Object -Object $phaseFixtures.preupload.State
  $aggregate = Copy-C33FFix5Object -Object $phaseFixtures.preupload.Aggregate
  $state.machineState = 'internal_release_active_upload_consumed'
  $aggregate.machineState = $state.machineState
  $state.uploadAuthorization = 'consumed'
  $state.installAuthorization = 'held_Play_activation_and_provenance'
  $state.deviceAuthorization = 'held_in_place_Play_update'
  $state.playResult.uploadCount = 1
  $state.playResult.internalActivationCount = 1
  $state.playResult.evidencePath = ConvertTo-C33FFix5RelativePath -Path $playPath
  $state.actionCounts.upload = 1
  $aggregate.candidate.uploadCount = 1
  $fixture = Write-C33FFix5Fixture -Name 'postupload' -State $state -Aggregate $aggregate
  $phaseFixtures.postupload = [pscustomobject]@{ State=$state; Aggregate=$aggregate; Path=$fixture }

  $state = Copy-C33FFix5Object -Object $phaseFixtures.postupload.State
  $aggregate = Copy-C33FFix5Object -Object $phaseFixtures.postupload.Aggregate
  $state.installAuthorization = 'available_once'
  $state.deviceAuthorization = 'available_once'
  $fixture = Write-C33FFix5Fixture -Name 'preinstall' -State $state -Aggregate $aggregate
  $phaseFixtures.preinstall = [pscustomobject]@{ State=$state; Aggregate=$aggregate; Path=$fixture }

  $state = Copy-C33FFix5Object -Object $phaseFixtures.preinstall.State
  $aggregate = Copy-C33FFix5Object -Object $phaseFixtures.preinstall.Aggregate
  $state.machineState = 'Play_installed_identity_sealed_journeys_pending'
  $aggregate.machineState = $state.machineState
  $state.installAuthorization = 'consumed'
  $state.deviceAuthorization = 'consumed'
  $state.installResult.installCount = 1
  $state.installResult.coldStartEvidencePath = ConvertTo-C33FFix5RelativePath -Path $coldPath
  $state.installResult.retainedDataEvidencePath = ConvertTo-C33FFix5RelativePath -Path $retainedPath
  $state.installResult.journeyEvidencePath = ConvertTo-C33FFix5RelativePath -Path $journeyPath
  $state.installResult.acceptanceSucceeded = $false
  $state.actionCounts.install = 1
  $aggregate.candidate.installCount = 1
  $fixture = Write-C33FFix5Fixture -Name 'postinstall' -State $state -Aggregate $aggregate
  $phaseFixtures.postinstall = [pscustomobject]@{ State=$state; Aggregate=$aggregate; Path=$fixture }

  $state = Copy-C33FFix5Object -Object $phaseFixtures.postinstall.State
  $aggregate = Copy-C33FFix5Object -Object $phaseFixtures.postinstall.Aggregate
  $state.machineState = 'acceptance_passed_zero_new_issue_or_defect_promotion_eligible'
  $aggregate.machineState = $state.machineState
  $state.installResult.acceptanceSucceeded = $true
  $state.actionCounts.deviceAcceptance = 1
  $aggregate.candidate.deviceAcceptanceCount = 1
  $fixture = Write-C33FFix5Fixture -Name 'journey' -State $state -Aggregate $aggregate
  $phaseFixtures.journey = [pscustomobject]@{ State=$state; Aggregate=$aggregate; Path=$fixture }

  foreach ($phase in @(
    'implementation', 'build', 'postbuild', 'preupload',
    'postupload', 'preinstall', 'postinstall', 'journey'
  )) {
    Invoke-C33FFix5ExpectedPass -Phase $phase -FixturePath $phaseFixtures[$phase].Path

    $wrongState = Copy-C33FFix5Object -Object $phaseFixtures[$phase].State
    $wrongAggregate = Copy-C33FFix5Object -Object $phaseFixtures[$phase].Aggregate
    $wrongState.machineState = 'wrong_phase_state'
    $wrongAggregate.machineState = 'wrong_phase_state'
    $wrongPath = Write-C33FFix5Fixture `
      -Name ($phase + '-wrong-state') `
      -State $wrongState `
      -Aggregate $wrongAggregate
    Invoke-C33FFix5ExpectedReject `
      -Phase $phase `
      -FixturePath $wrongPath `
      -Label "$phase wrong machine state"
  }

  $countState = Copy-C33FFix5Object -Object $phaseFixtures.postbuild.State
  $countAggregate = Copy-C33FFix5Object -Object $phaseFixtures.postbuild.Aggregate
  $countState.actionCounts.build = 0
  $countPath = Write-C33FFix5Fixture `
    -Name 'postbuild-stale-build-count-mirror' `
    -State $countState `
    -Aggregate $countAggregate
  Invoke-C33FFix5ExpectedReject `
    -Phase postbuild `
    -FixturePath $countPath `
    -Label 'postbuild stale build-count mirror'

  $trackState = Copy-C33FFix5Object -Object $phaseFixtures.postupload.State
  $trackAggregate = Copy-C33FFix5Object -Object $phaseFixtures.postupload.Aggregate
  $badPlayPath = Join-Path $fixtureRoot 'play-other-track-evidence.json'
  $badPlay = Copy-C33FFix5Object -Object $playEvidence
  $badPlay.track = 'production'
  $badPlay.otherTrackChanged = $true
  Write-C33FFix5Json -Value $badPlay -Path $badPlayPath
  $trackState.playResult.evidencePath = ConvertTo-C33FFix5RelativePath -Path $badPlayPath
  $trackPath = Write-C33FFix5Fixture `
    -Name 'postupload-other-track' `
    -State $trackState `
    -Aggregate $trackAggregate
  Invoke-C33FFix5ExpectedReject `
    -Phase postupload `
    -FixturePath $trackPath `
    -Label 'postupload other-track evidence'

  $adbState = Copy-C33FFix5Object -Object $phaseFixtures.postinstall.State
  $adbAggregate = Copy-C33FFix5Object -Object $phaseFixtures.postinstall.Aggregate
  $badRetainedPath = Join-Path $fixtureRoot 'retained-data-adb-evidence.json'
  $badRetained = Copy-C33FFix5Object -Object $retainedEvidence
  $badRetained.adbInstallPerformed = $true
  Write-C33FFix5Json -Value $badRetained -Path $badRetainedPath
  $adbState.installResult.retainedDataEvidencePath = ConvertTo-C33FFix5RelativePath -Path $badRetainedPath
  $adbPath = Write-C33FFix5Fixture `
    -Name 'postinstall-adb-install' `
    -State $adbState `
    -Aggregate $adbAggregate
  Invoke-C33FFix5ExpectedReject `
    -Phase postinstall `
    -FixturePath $adbPath `
    -Label 'postinstall ADB-install evidence'

  $defectState = Copy-C33FFix5Object -Object $phaseFixtures.journey.State
  $defectAggregate = Copy-C33FFix5Object -Object $phaseFixtures.journey.Aggregate
  $badJourneyPath = Join-Path $fixtureRoot 'journey-new-defect-evidence.json'
  $badJourney = Copy-C33FFix5Object -Object $journeyEvidence
  $badJourney.newDefectCount = 1
  $badJourney.allMandatoryJourneysPassed = $false
  $badJourney.acceptanceSucceeded = $false
  $badJourney.successClaimed = $false
  Write-C33FFix5Json -Value $badJourney -Path $badJourneyPath
  $defectState.installResult.journeyEvidencePath = ConvertTo-C33FFix5RelativePath -Path $badJourneyPath
  $defectPath = Write-C33FFix5Fixture `
    -Name 'journey-new-defect' `
    -State $defectState `
    -Aggregate $defectAggregate
  Invoke-C33FFix5ExpectedReject `
    -Phase journey `
    -FixturePath $defectPath `
    -Label 'journey new-defect evidence'
} finally {
  $resolvedFixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
  $resolvedEvidenceRoot = [IO.Path]::GetFullPath($evidenceRoot) +
    [IO.Path]::DirectorySeparatorChar
  if (
    $resolvedFixtureRoot.StartsWith(
      $resolvedEvidenceRoot,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    $resolvedFixtureRoot.StartsWith(
      $fixturePrefix.TrimEnd([IO.Path]::DirectorySeparatorChar),
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath $resolvedFixtureRoot)
  ) {
    Remove-Item -LiteralPath $resolvedFixtureRoot -Recurse -Force
  }
}

Write-Output (
  'C33F FIX5 phase-aware lifecycle test passed: phases=8/8; ' +
  'wrongPhaseRejections=8/8; staleBuildMirrorRejected=true; ' +
  'otherTrackRejected=true; adbInstallRejected=true; ' +
  'newDefectJourneyRejected=true; externalActions=false.'
)
