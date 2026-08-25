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
$lockCheckerPath = Join-Path $root 'scripts\check-approved-ui-locks.ps1'
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
$checker = Get-Content -Raw -LiteralPath $checkerPath
$lockChecker = Get-Content -Raw -LiteralPath $lockCheckerPath

function Assert-RepairContract([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "Integration repair fixture rejected: $Message" }
}

$repairLane = @($policy.productionGitDiscipline.lanes | Where-Object {
  [string]$_.id -ceq 'integration_repair'
})
$repairBinding = @($policy.productionGitDiscipline.continuationBindings |
  Where-Object { [string]$_.lane -ceq 'integration_repair' })
$repair = $policy.productionGitDiscipline.integration.repair
$repairClaim = @($policy.activeClaims | Where-Object {
  [string]$_.task -ceq '/root/repair_social_runtime_chat_20260825'
})
$integrationClaim = @($policy.activeClaims | Where-Object {
  [string]$_.task -ceq '/root/integration_social_runtime_chat_v2_20260825'
})

Assert-RepairContract ($repairLane.Count -eq 1) 'repair lane is missing or ambiguous.'
Assert-RepairContract ($repairBinding.Count -eq 1) 'repair continuation is missing or ambiguous.'
Assert-RepairContract ($repairClaim.Count -eq 1) 'repair owner claim is missing or ambiguous.'
Assert-RepairContract ($integrationClaim.Count -eq 1) 'fresh integration claim is missing or ambiguous.'
Assert-RepairContract (
  [string]$repair.requiredCodexCommit -ceq
    '922c2a9d776f7de96ba9ec9a7ca6175d1cc2fce9' -and
  [string]$repair.requiredCursorCommit -ceq
    '00ce93552091ee51739266c0a8fbe6d207d9f695' -and
  [int]$repair.maximumMergeCommits -eq 1 -and
  [int]$repair.maximumPreMergeCoordinationCommits -eq 4 -and
  @($repair.preMergeCoordinationOwners).Count -eq 6 -and
  [int]$repair.maximumPostMergeClosureCommits -eq 1 -and
  @($repair.postMergeClosureOwners).Count -eq 2 -and
  -not [bool]$repair.directSourceCommitsAllowed -and
  [bool]$repair.conflictResolutionAllowed -and
  @($repair.exactConflictOwners).Count -eq 10
) 'sealed parents or one-merge conflict boundary changed.'

$requiredCheckerTokens = @(
  "'integration_repair'",
  "'integration_admission_authorize'",
  'requiredCodexCommit',
  'requiredCursorCommit',
  'exactConflictOwners',
  'function Assert-QualifiedIntegrationRepairTip',
  'integration repair resolved delta does not equal every exact conflict owner',
  'integration repair resolved blob retains conflict markers',
  'qualified integration repair merge subject changed',
  'Assert-QualifiedIntegrationRepairTip -RepairCommit $head',
  '-RepairCommit $qualifiedRepairCommit',
  'integration repair contains a forbidden direct commit',
  'integration repair merge second parent changed',
  'fresh integration target is not clean at the governance tag'
)
foreach ($token in $requiredCheckerTokens) {
  Assert-RepairContract ($checker.Contains($token)) "checker token is missing: $token"
}
foreach ($lockToken in @(
    'function Test-SealedParallelContinuationFacts',
    'function Test-SealedParallelContinuationUnchanged',
    'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
    'integration/moolsocial/social-runtime-chat-v2-20260825',
    'if (Test-SealedParallelContinuationUnchanged -Path $Path)',
    'Approved UI sealed-parallel continuation fixture failed.'
  )) {
  Assert-RepairContract ($lockChecker.Contains($lockToken)) `
    "approved-lock token is missing: $lockToken"
}
$sealedFallbackCalls = [regex]::Matches(
  $lockChecker,
  'if \(Test-SealedParallelContinuationUnchanged -Path \$(?:Path|resolved)\)'
).Count
Assert-RepairContract ($sealedFallbackCalls -eq 2) `
  'sealed parallel fallback is not applied to both raw and production locks.'

if ($RequireQualifiedGraph) {
  $head = (& git -C $root rev-parse HEAD).Trim()
  Assert-RepairContract ($LASTEXITCODE -eq 0) 'repair HEAD read failed.'
  $qualifiedMerges = @(& git -C $root rev-list --merges `
      "$($repair.requiredCodexCommit)..$head")
  Assert-RepairContract (
    $LASTEXITCODE -eq 0 -and $qualifiedMerges.Count -eq 1
  ) 'qualified repair does not contain one exact merge.'
  $qualifiedMerge = [string]$qualifiedMerges[0]
  $parents = @((& git -C $root show -s --format='%P' $qualifiedMerge) -split ' ')
  Assert-RepairContract ($LASTEXITCODE -eq 0 -and $parents.Count -eq 2) `
    'qualified repair merge is not a two-parent merge.'
  Assert-RepairContract (
    $parents[1] -ceq [string]$repair.requiredCursorCommit
  ) 'qualified repair second parent is not the sealed Cursor tip.'
  $subject = (& git -C $root show -s --format='%s' $qualifiedMerge).Trim()
  Assert-RepairContract (
    $LASTEXITCODE -eq 0 -and
    $subject -cmatch '^repair\(social-runtime-chat-conflict-correction-20260825\): .+'
  ) 'qualified repair subject is not exact.'
  & git -C $root merge-base --is-ancestor `
    ([string]$repair.requiredCodexCommit) $head
  Assert-RepairContract ($LASTEXITCODE -eq 0) `
    'qualified repair does not contain the sealed Codex tip.'
}

Write-Output 'Codex integration repair coordination fixture passed.'
