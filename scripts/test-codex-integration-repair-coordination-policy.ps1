[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireQualifiedGraph
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$policyPath = Join-Path $root 'config\codex-subagent-coordination-policy.json'
$checkerPath = Join-Path $root 'scripts\check-codex-subagent-coordination-policy.ps1'
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
$checker = Get-Content -Raw -LiteralPath $checkerPath

function Assert-RepairContract([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "Integration repair fixture rejected: $Message" }
}

$repair = $policy.productionGitDiscipline.integration.repair
$repairBinding = @(
  $policy.productionGitDiscipline.continuationBindings | Where-Object {
    [string]$_.id -ceq 'integration_repair_store_buy_conflict_v3_20260904'
  }
)
$repairClaim = @($policy.activeClaims | Where-Object {
  [string]$_.task -ceq '/root/repair_store_buy_conflict_v3_20260904'
})
$expectedConflicts = @(
  'config/codex-development-regression-registry.json',
  'config/codex-subagent-coordination-policy.json',
  'scripts/check-codex-subagent-coordination-policy.ps1'
)
$expectedBootstrapOwners = @(
  'config/codex-development-regression-registry.json',
  'config/codex-subagent-coordination-policy.json',
  'docs/quality/STORE-BUY-V3-PRE-INTEGRATION-RECONCILIATION-20260904.md',
  'docs/quality/UAW-INTEGRATION-REPAIR-STORE-BUY-V3-20260904.md',
  'scripts/check-codex-development-regression-memory.ps1',
  'scripts/check-codex-subagent-coordination-policy.ps1',
  'scripts/test-codex-integration-repair-coordination-policy.ps1'
)

Assert-RepairContract ($repairBinding.Count -eq 1) 'repair binding is missing or ambiguous.'
Assert-RepairContract ($repairClaim.Count -eq 1) 'repair owner claim is missing or ambiguous.'
Assert-RepairContract (
  [string]$repair.requiredCodexCommit -ceq
    'f208fbef80303ad3c6b1bf41a385616adcc969b5' -and
  [string]$repair.requiredCursorCommit -ceq
    'fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d' -and
  [string]$repairBinding[0].baselineHead -ceq
    [string]$repair.requiredCodexCommit -and
  [int]$repair.maximumMergeCommits -eq 1 -and
  [int]$repair.maximumPreMergeCoordinationCommits -eq 1 -and
  [int]$repair.maximumPostMergeClosureCommits -eq 3 -and
  -not [bool]$repair.directSourceCommitsAllowed -and
  [bool]$repair.conflictResolutionAllowed
) 'sealed parents or one-merge boundary changed.'
Assert-RepairContract (
  (@($repair.exactConflictOwners | Sort-Object) -join '|') -ceq
    (@($expectedConflicts | Sort-Object) -join '|')
) 'exact conflict owner set changed.'
Assert-RepairContract (
  (@($repairBinding[0].bootstrapOwners | Sort-Object) -join '|') -ceq
    (@($expectedBootstrapOwners | Sort-Object) -join '|')
) 'bootstrap owner set changed.'
Assert-RepairContract (
  @($expectedConflicts | Where-Object {
    @($repairClaim[0].owners) -cnotcontains $_
  }).Count -eq 0
) 'repair claim does not own every conflict owner.'
foreach ($token in @(
  "'integration_repair'",
  "'integration_admission_authorize'",
  'function Assert-IntegrationRepairMerge',
  'function Assert-QualifiedIntegrationRepairTip',
  'integration repair conflict inventory changed',
  'integration repair resolved delta does not equal every exact conflict owner',
  'integration repair resolved blob retains conflict markers',
  'integration repair merge second parent changed',
  'fresh integration target is not clean at the governance tag'
)) {
  Assert-RepairContract ($checker.Contains($token)) "checker token is missing: $token"
}

if ($RequireQualifiedGraph) {
  $head = (& git -C $root rev-parse HEAD).Trim()
  Assert-RepairContract ($LASTEXITCODE -eq 0) 'repair HEAD read failed.'
  $qualifiedMerges = @(& git -C $root rev-list --first-parent --merges `
      "$($repair.requiredCodexCommit)..$head")
  Assert-RepairContract (
    $LASTEXITCODE -eq 0 -and $qualifiedMerges.Count -eq 1
  ) 'qualified repair does not contain one exact merge.'
  $qualifiedMerge = [string]$qualifiedMerges[0]
  $parentOutput = @(& git -C $root show -s --format='%P' $qualifiedMerge)
  Assert-RepairContract (
    $LASTEXITCODE -eq 0 -and $parentOutput.Count -eq 1
  ) 'qualified repair parent read failed.'
  $parents = @([string]$parentOutput[0] -split ' ')
  Assert-RepairContract (
    $parents.Count -eq 2 -and
    $parents[1] -ceq [string]$repair.requiredCursorCommit
  ) 'qualified repair parents changed.'
  $subject = (& git -C $root show -s --format='%s' $qualifiedMerge).Trim()
  Assert-RepairContract (
    $LASTEXITCODE -eq 0 -and
    $subject -cmatch '^repair\(store-buy-conflict-repair-v3-20260904\): .+'
  ) 'qualified repair subject changed.'
  foreach ($requiredTip in @(
      [string]$repair.requiredCodexCommit,
      [string]$repair.requiredCursorCommit
    )) {
    & git -C $root merge-base --is-ancestor $requiredTip $head
    Assert-RepairContract ($LASTEXITCODE -eq 0) "qualified repair omits $requiredTip."
  }
}

Write-Output 'Codex Store-Buy integration repair coordination fixture passed.'
