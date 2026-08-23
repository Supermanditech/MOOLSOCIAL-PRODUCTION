[CmdletBinding()]
param(
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34j.json',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$ticketId =
  'UAW-C34J-R60-74-RELEASE-LIFECYCLE-ATOMIC-PARITY-PLAY-OPPO-ACCEPTANCE'

function Assert-C34JGateFixture {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw "C34J candidate-gate fixture rejected: $Message" }
}

function Resolve-C34JGateFixturePath {
  param([string]$Path, [string]$Label)
  Assert-C34JGateFixture -Condition (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34JGateFixture -Condition (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or outside the repository."
  return $resolved
}

$sourceStateFile = Resolve-C34JGateFixturePath -Path $StatePath -Label 'source state'
$sourceState = Get-Content -Raw -LiteralPath $sourceStateFile | ConvertFrom-Json
$sourceAggregateFile = Resolve-C34JGateFixturePath `
  -Path ([string]$sourceState.aggregateStatePath) -Label 'source aggregate'
$sourceAggregate = Get-Content -Raw -LiteralPath $sourceAggregateFile | ConvertFrom-Json
Assert-C34JGateFixture -Condition (
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
) -Message 'source state is not the exact sealed prompt-ready candidate.'

$fixtureRootRelative =
  'tmp/c34j-candidate-gate-fixtures-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
$fixtureRoot = Join-Path $root $fixtureRootRelative
[void](New-Item -ItemType Directory -Path $fixtureRoot)
$fixtureStateRelative = "$fixtureRootRelative/state.json"
$fixtureAggregateRelative = "$fixtureRootRelative/aggregate.json"
$fixtureStateFile = Join-Path $root $fixtureStateRelative
$fixtureAggregateFile = Join-Path $root $fixtureAggregateRelative
$sourceState.aggregateStatePath = $fixtureAggregateRelative

function Write-C34JGateFixtureJson {
  param([object]$Value, [string]$Path)
  [IO.File]::WriteAllText(
    $Path,
    (($Value | ConvertTo-Json -Depth 50) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
  )
}

$transition = Join-Path $root 'scripts/invoke-release-lifecycle-transition-c34j.ps1'
$candidateGate =
  Join-Path $root 'scripts/check-uaw-c34j-r60-74-release-lifecycle-atomic-parity-readiness.ps1'

function Invoke-C34JFixtureTransition {
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

function Invoke-C34JFixtureGate {
  param([string]$Phase)
  & $candidateGate -Phase $Phase -StatePath $fixtureStateRelative `
    -RepositoryRoot $root | Out-Null
}

try {
  Write-C34JGateFixtureJson -Value $sourceState -Path $fixtureStateFile
  Write-C34JGateFixtureJson -Value $sourceAggregate -Path $fixtureAggregateFile

  Invoke-C34JFixtureGate -Phase 'preprompt'
  Invoke-C34JFixtureTransition -Name 'founder-inputs-validated'
  Invoke-C34JFixtureGate -Phase 'build'
  Invoke-C34JFixtureTransition -Name 'build-start'
  Invoke-C34JFixtureTransition -Name 'build-succeeded' -Additional @{
    ArtifactPath = 'tmp/c34j-candidate-gate-fixture.aab'
    ArtifactSha256 = ('A' * 64)
    ArtifactBytes = 94797571
    UploadSignerSha256 = ('B' * 64)
    ArtifactProvenance = 'tmp/c34j-candidate-gate-fixture-provenance.json'
  }
  Invoke-C34JFixtureGate -Phase 'postbuild'
  Invoke-C34JFixtureTransition -Name 'upload-authorized'
  Invoke-C34JFixtureGate -Phase 'preupload'
  Invoke-C34JFixtureTransition -Name 'upload-succeeded' `
    -Additional @{ EvidencePath = 'tmp/c34j-candidate-gate-fixture-play.json' }
  Invoke-C34JFixtureGate -Phase 'postupload'
  Invoke-C34JFixtureTransition -Name 'install-authorized'
  Invoke-C34JFixtureGate -Phase 'preinstall'
  Invoke-C34JFixtureTransition -Name 'install-succeeded' `
    -Additional @{ EvidencePath = 'tmp/c34j-candidate-gate-fixture-oppo.json' }
  Invoke-C34JFixtureGate -Phase 'postinstall'
  Invoke-C34JFixtureTransition -Name 'device-accepted' `
    -Additional @{ EvidencePath = 'tmp/c34j-candidate-gate-fixture-journeys.json' }
  Invoke-C34JFixtureGate -Phase 'journey'

  Write-Output (
    'C34J candidate lifecycle gates passed: phases=8/8; ' +
    'preprompt/build/postbuild/preupload/postupload/preinstall/postinstall/journey; ' +
    'counts=1/1/1/1; externalWrites=0; fixtureOnly=true.'
  )
} finally {
  if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    $expectedPrefix = [IO.Path]::GetFullPath(
      (Join-Path $root 'tmp/c34j-candidate-gate-fixtures-')
    )
    Assert-C34JGateFixture -Condition (
      $resolvedFixture.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) -Message 'fixture cleanup path escaped its exact temporary prefix.'
    Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
  }
}
