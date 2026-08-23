[CmdletBinding()]
param(
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34k.json',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$ticketId =
  'UAW-C34K-R60-75-RELEASE-LIFECYCLE-ATOMIC-PARITY-PLAY-OPPO-ACCEPTANCE'

function Assert-C34KGateFixture {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw "C34K candidate-gate fixture rejected: $Message" }
}

function Resolve-C34KGateFixturePath {
  param([string]$Path, [string]$Label)
  Assert-C34KGateFixture -Condition (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34KGateFixture -Condition (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or outside the repository."
  return $resolved
}

$sourceStateFile = Resolve-C34KGateFixturePath -Path $StatePath -Label 'source state'
$sourceState = Get-Content -Raw -LiteralPath $sourceStateFile | ConvertFrom-Json
$sourceAggregateFile = Resolve-C34KGateFixturePath `
  -Path ([string]$sourceState.aggregateStatePath) -Label 'source aggregate'
$sourceAggregate = Get-Content -Raw -LiteralPath $sourceAggregateFile | ConvertFrom-Json
$promptReady = (
  [string]$sourceState.ticketId -ceq $ticketId -and
  [string]$sourceState.machineState -ceq
    'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required' -and
  [string]$sourceAggregate.machineState -ceq [string]$sourceState.machineState -and
  [int]$sourceState.sourceQualification.completedIdenticalCycles -eq 2 -and
  [int]$sourceAggregate.sourceQualification.completedIdenticalCycles -eq 2 -and
  [string]$sourceState.releaseAuthorities.build -ceq 'available_once' -and
  [string]$sourceAggregate.releaseAuthorities.build -ceq 'available_once' -and
  [int]$sourceState.actionCounts.build -eq 0 -and
  [int]$sourceState.actionCounts.upload -eq 0 -and
  [int]$sourceState.actionCounts.install -eq 0 -and
  [int]$sourceState.actionCounts.deviceAcceptance -eq 0
)
$precycleReady = (
  [string]$sourceState.ticketId -ceq $ticketId -and
  [string]$sourceState.machineState -ceq
    'prebuild_composition_registered_two_fresh_cycles_required' -and
  [string]$sourceAggregate.machineState -ceq [string]$sourceState.machineState -and
  [int]$sourceState.sourceQualification.completedIdenticalCycles -eq 0 -and
  [int]$sourceAggregate.sourceQualification.completedIdenticalCycles -eq 0 -and
  [string]$sourceState.releaseAuthorities.build -ceq
    'held_founder_aab_authorization_and_source_qualification' -and
  [string]$sourceAggregate.releaseAuthorities.build -ceq
    'held_founder_aab_authorization_and_source_qualification' -and
  -not [bool]$sourceState.authority.founderHiddenInputEntryAuthorized -and
  [int]$sourceState.actionCounts.build -eq 0 -and
  [int]$sourceState.actionCounts.upload -eq 0 -and
  [int]$sourceState.actionCounts.install -eq 0 -and
  [int]$sourceState.actionCounts.deviceAcceptance -eq 0
)
Assert-C34KGateFixture -Condition ($promptReady -or $precycleReady) `
  -Message 'source state is neither exact precycle composition nor sealed prompt-ready.'

if ($precycleReady) {
  $promptState =
    'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required'
  $sourceState.machineState = $promptState
  $sourceAggregate.machineState = $promptState
  $sourceState.candidate.disposition = $promptState
  $sourceAggregate.candidate.disposition = $promptState
  $sourceState.buildAuthorization = 'available_once'
  $sourceState.releaseAuthorities.build = 'available_once'
  $sourceAggregate.releaseAuthorities.build = 'available_once'
  $sourceState.authority.founderHiddenInputEntryAuthorized = $true
  $sourceState.sourceQualification.completedIdenticalCycles = 2
  $sourceAggregate.sourceQualification.completedIdenticalCycles = 2
}

$fixtureRootRelative =
  'tmp/c34k-candidate-gate-fixtures-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
$fixtureRoot = Join-Path $root $fixtureRootRelative
[void](New-Item -ItemType Directory -Path $fixtureRoot)
$fixtureStateRelative = "$fixtureRootRelative/state.json"
$fixtureAggregateRelative = "$fixtureRootRelative/aggregate.json"
$fixtureLedgerRelative = "$fixtureRootRelative/blocker-ledger.json"
$fixtureStateFile = Join-Path $root $fixtureStateRelative
$fixtureAggregateFile = Join-Path $root $fixtureAggregateRelative
$fixtureLedgerFile = Join-Path $root $fixtureLedgerRelative
$sourceState.aggregateStatePath = $fixtureAggregateRelative
$sourceLedger = Get-Content -Raw -LiteralPath (
  Join-Path $root 'config/release-acceptance-blocker-ledger-c33g.json'
) | ConvertFrom-Json

function Write-C34KGateFixtureJson {
  param([object]$Value, [string]$Path)
  [IO.File]::WriteAllText(
    $Path,
    (($Value | ConvertTo-Json -Depth 50) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
  )
}

$transition = Join-Path $root 'scripts/invoke-release-lifecycle-transition-c34k.ps1'
$candidateGate =
  Join-Path $root 'scripts/check-uaw-c34k-r60-75-release-lifecycle-atomic-parity-readiness.ps1'

function Invoke-C34KFixtureTransition {
  param([string]$Name, [hashtable]$Additional = @{})
  $parameters = @{
    Transition = $Name
    StatePath = $fixtureStateRelative
    FixtureMode = $true
    RepositoryRoot = $root
  }
  foreach ($key in $Additional.Keys) { $parameters[$key] = $Additional[$key] }
  & $transition @parameters | Out-Null
}

function Invoke-C34KFixtureGate {
  param([string]$Phase)
  & $candidateGate -Phase $Phase -StatePath $fixtureStateRelative `
    -BlockerLedgerPath $fixtureLedgerRelative -FixtureMode `
    -RepositoryRoot $root | Out-Null
}

try {
  Write-C34KGateFixtureJson -Value $sourceState -Path $fixtureStateFile
  Write-C34KGateFixtureJson -Value $sourceAggregate -Path $fixtureAggregateFile
  Write-C34KGateFixtureJson -Value $sourceLedger -Path $fixtureLedgerFile

  Invoke-C34KFixtureGate -Phase 'preprompt'
  Invoke-C34KFixtureTransition -Name 'founder-inputs-validated'
  Invoke-C34KFixtureGate -Phase 'build'
  Invoke-C34KFixtureTransition -Name 'build-start'
  Invoke-C34KFixtureTransition -Name 'build-succeeded' -Additional @{
    ArtifactPath = 'tmp/c34k-candidate-gate-fixture.aab'
    ArtifactSha256 = ('A' * 64)
    ArtifactBytes = 94797571
    UploadSignerSha256 = ('B' * 64)
    ArtifactProvenance = 'tmp/c34k-candidate-gate-fixture-provenance.json'
  }
  Invoke-C34KFixtureGate -Phase 'postbuild'
  Invoke-C34KFixtureTransition -Name 'upload-authorized'
  Invoke-C34KFixtureGate -Phase 'preupload'
  Invoke-C34KFixtureTransition -Name 'upload-succeeded' `
    -Additional @{ EvidencePath = 'tmp/c34k-candidate-gate-fixture-play.json' }
  Invoke-C34KFixtureGate -Phase 'postupload'
  Invoke-C34KFixtureTransition -Name 'install-authorized'
  Invoke-C34KFixtureGate -Phase 'preinstall'
  Invoke-C34KFixtureTransition -Name 'install-succeeded' `
    -Additional @{ EvidencePath = 'tmp/c34k-candidate-gate-fixture-oppo.json' }
  Invoke-C34KFixtureGate -Phase 'postinstall'
  Invoke-C34KFixtureTransition -Name 'device-accepted' `
    -Additional @{ EvidencePath = 'tmp/c34k-candidate-gate-fixture-journeys.json' }
  $fixtureDeviceEvidenceRelative = "$fixtureRootRelative/device-acceptance.json"
  [IO.File]::WriteAllText(
    (Join-Path $root $fixtureDeviceEvidenceRelative),
    "{`"fixtureOnly`":true}`n",
    [Text.UTF8Encoding]::new($false)
  )
  foreach ($blocker in @($sourceLedger.blockers)) {
    $blocker.status = 'resolved_complete'
    $blocker.futurePlayDeviceEvidencePath = $fixtureDeviceEvidenceRelative
    $blocker.futurePlayDeviceAcceptancePassed = $true
    $blocker.resolvedCandidateId = $ticketId
    $blocker.resolvedCandidateVersionCode = '2026081375'
  }
  Write-C34KGateFixtureJson -Value $sourceLedger -Path $fixtureLedgerFile
  Invoke-C34KFixtureGate -Phase 'journey'

  Write-Output (
    'C34K candidate lifecycle gates passed: phases=8/8; ' +
    'preprompt/build/postbuild/preupload/postupload/preinstall/postinstall/journey; ' +
    "counts=1/1/1/1; seed=$(if ($precycleReady) { 'precycle' } else { 'prompt' }); " +
    'externalWrites=0; fixtureOnly=true.'
  )
} finally {
  if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    $expectedPrefix = [IO.Path]::GetFullPath(
      (Join-Path $root 'tmp/c34k-candidate-gate-fixtures-')
    )
    Assert-C34KGateFixture -Condition (
      $resolvedFixture.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) -Message 'fixture cleanup path escaped its exact temporary prefix.'
    Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
  }
}
