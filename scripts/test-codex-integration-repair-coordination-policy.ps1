[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireQualifiedGraph,
  [switch]$RequireOctoberSourceAdmission,
  [switch]$RequireOctoberBootstrapProbes
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
if (-not $RequireOctoberSourceAdmission) {
  Assert-RepairContract (
    @($expectedConflicts | Where-Object {
      @($repairClaim[0].owners) -cnotcontains $_
    }).Count -eq 0
  ) 'repair claim does not own every conflict owner.'
} else {
  $octoberClaim=@($policy.activeClaims | Where-Object { $_.task -ceq '/root' -and $_.role -ceq 'primary' })
  $octoberBinding=@($policy.productionGitDiscipline.continuationBindings | Where-Object { $_.id -ceq 'integration_repair_store_buy_combined_20261008' })
  Assert-RepairContract ($octoberClaim.Count -eq 1 -and $octoberBinding.Count -eq 1) 'October claim or binding missing or ambiguous.'
  $octoberOwners=@(
    '.gitattributes','apps/mobile/.flutter-plugins-dependencies',
    'apps/mobile/lib/features/journey01/journey_router.dart',
    'apps/mobile/test/ui_v2/buy/buy_v2_scoped_cart_checkout_dock_continuity_test.dart',
    'config/codex-development-regression-registry.json',
    'config/codex-subagent-coordination-policy.json','scripts/check-approved-ui-locks.ps1',
    'scripts/check-codex-subagent-coordination-policy.ps1','scripts/test-artifact-evidence-retention.ps1'
  ) + @($octoberBinding[0].bootstrapOwners)
  Assert-RepairContract (@($octoberOwners | Where-Object {
    @($octoberClaim[0].owners) -cnotcontains $_
  }).Count -eq 0) 'October primary claim does not own every admitted owner.'
}
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
  $graphRepair=$repair.PSObject.Copy()
  $graphSubject='^repair\(store-buy-conflict-repair-v3-20260904\): .+'
  if ($RequireOctoberSourceAdmission) {
    $graphRepair.requiredCodexCommit='8002e8cd740aaf613b75dc749212fb12ae4fddb7'
    $graphRepair.requiredCursorCommit='f32c17e1a3a41807564fe18f83c0520a66e0bfe6'
    $graphSubject='^repair\(store-buy-combined-20261008\): .+'
  }
  $head = (& git -C $root rev-parse HEAD).Trim()
  Assert-RepairContract ($LASTEXITCODE -eq 0) 'repair HEAD read failed.'
  $qualifiedMerges = @(& git -C $root rev-list --first-parent --merges `
      "$($graphRepair.requiredCodexCommit)..$head")
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
    $parents[1] -ceq [string]$graphRepair.requiredCursorCommit
  ) 'qualified repair parents changed.'
  $subject = (& git -C $root show -s --format='%s' $qualifiedMerge).Trim()
  Assert-RepairContract (
    $LASTEXITCODE -eq 0 -and
    $subject -cmatch $graphSubject
  ) 'qualified repair subject changed.'
  foreach ($requiredTip in @(
      [string]$graphRepair.requiredCodexCommit,
      [string]$graphRepair.requiredCursorCommit
    )) {
    & git -C $root merge-base --is-ancestor $requiredTip $head
    Assert-RepairContract ($LASTEXITCODE -eq 0) "qualified repair omits $requiredTip."
  }
}

if ($RequireOctoberSourceAdmission) {
  $parseTokens=$null; $parseErrors=$null
  $checkerAst=[System.Management.Automation.Language.Parser]::ParseFile($checkerPath,[ref]$parseTokens,[ref]$parseErrors)
  Assert-RepairContract (@($parseErrors).Count -eq 0) 'checker parse errors.'
  $functionNodes=@($checkerAst.FindAll({param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -cin @('Test-OctoberInheritedCursorDisposition','Test-OctoberIntegrationSelection','Test-OctoberIntegrationMergeSubject')
  },$true))
  Assert-RepairContract ($functionNodes.Count -eq 3) 'exact operative October predicates missing or duplicated.'
  foreach ($functionNode in $functionNodes) { . ([scriptblock]::Create($functionNode.Extent.Text)) }
  Assert-RepairContract (Test-OctoberIntegrationMergeSubject 'merge(store-buy-combined-baseline-20261008): integrate qualified Store and public Buy') 'exact merge subject rejected.'
  Assert-RepairContract (-not (Test-OctoberIntegrationMergeSubject 'merge(store-buy-combined-baseline-20261008): different outcome')) 'same prefix with different outcome accepted.'
  Assert-RepairContract (-not (Test-OctoberIntegrationMergeSubject 'merge(other-work): integrate qualified Store and public Buy')) 'wrong subject work ID accepted.'
  Write-Output 'October operative exact-merge-subject predicate: 3 cases passed.'
  $selectionCommit='8002e8cd740aaf613b75dc749212fb12ae4fddb7'
  $selectionBranch='work/integration-repair/store-buy-combined-20261008'
  Assert-RepairContract (Test-OctoberIntegrationSelection @($selectionCommit) @($selectionBranch)) 'exact selection predicate failed; graph qualification is separate.'
  foreach ($selection in @(
    @{commits=@();branches=@($selectionBranch)},
    @{commits=@($selectionCommit);branches=@()},
    @{commits=@($selectionCommit,$selectionCommit);branches=@($selectionBranch)},
    @{commits=@($selectionCommit);branches=@($selectionBranch,'work/cursor-ui/buy-ready-20260921')},
    @{commits=@($selectionCommit);branches=@('work/cursor-ui/buy-ready-20260921')},
    @{commits=@('invalid');branches=@($selectionBranch)},
    @{commits=@($selectionCommit.ToUpperInvariant());branches=@($selectionBranch)},
    @{commits=@($selectionCommit);branches=@($selectionBranch.ToUpperInvariant())}
  )) {
    Assert-RepairContract (-not (Test-OctoberIntegrationSelection $selection.commits $selection.branches)) 'invalid October selection accepted.'
  }
  Write-Output 'October operative integration-selection predicate: 9 cases passed; qualified-tip graph remains separate.'
  $octoberCommit='0e90a6ca74b81e212f118995f7c4fab0d3b78620'
  $octoberIdentity=@{Commit=$octoberCommit; CursorTip='f32c17e1a3a41807564fe18f83c0520a66e0bfe6'}
  foreach ($field in @(@('Parent','%P'),@('Tree','%T'),@('Subject','%s'))) {
    $value=@(& git -C $root show -s "--format=$($field[1])" $octoberCommit)
    Assert-RepairContract ($LASTEXITCODE -eq 0 -and $value.Count -eq 1) 'inherited identity read failed.'
    $octoberIdentity[$field[0]]=[string]$value[0]
  }
  $octoberIdentity.Paths=@(& git -C $root diff-tree --no-commit-id --name-only -r $octoberCommit)
  Assert-RepairContract ($LASTEXITCODE -eq 0) 'inherited owner read failed.'
  & git -C $root merge-base --is-ancestor $octoberCommit $octoberIdentity.CursorTip
  $octoberIdentity.IsAncestor=$LASTEXITCODE -eq 0
  Assert-RepairContract (Test-OctoberInheritedCursorDisposition $octoberIdentity) 'actual inherited disposition rejected.'
  $octoberCases=1
  foreach ($key in @('Commit','Parent','Tree','Subject','CursorTip','IsAncestor','Paths')) {
    $changed=$octoberIdentity.Clone(); $changed[$key]='altered'
    Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $changed)) "altered inherited $key accepted."
    $missing=$octoberIdentity.Clone(); $missing.Remove($key)
    Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $missing)) "missing inherited $key accepted."
    $octoberCases+=2
  }
  $sameSubject=$octoberIdentity.Clone(); $sameSubject.Commit=$octoberIdentity.Parent
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $sameSubject)) 'same-subject different commit accepted.'
  $sibling=$octoberIdentity.Clone(); $sibling.Paths=@($octoberIdentity.Paths[0..14])+'apps/mobile/lib/features/journey01/forbidden_sibling.dart'
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $sibling)) 'forbidden sibling accepted.'
  $duplicate=$octoberIdentity.Clone(); $duplicate.Paths=@($octoberIdentity.Paths[0..14])+$octoberIdentity.Paths[0]
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $duplicate)) 'duplicate owner accepted.'
  $notAncestor=$octoberIdentity.Clone(); $notAncestor.IsAncestor=$false
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $notAncestor)) 'non-ancestor accepted.'
  $textAncestor=$octoberIdentity.Clone(); $textAncestor.IsAncestor='true'
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $textAncestor)) 'string ancestry accepted.'
  $extra=$octoberIdentity.Clone(); $extra.Unknown='extra'
  Assert-RepairContract (-not (Test-OctoberInheritedCursorDisposition $extra)) 'extra field accepted.'
  $octoberCases+=6
  Write-Output "October operative inherited-disposition predicate: $octoberCases cases passed. Full graph replay remains separate."
}
if ($RequireOctoberBootstrapProbes) {
  Assert-RepairContract ([bool]$RequireOctoberSourceAdmission) 'October bootstrap probes require October fixture mode.'
  $bootstrapParameters=@{
    AgentRole='primary';AgentTask='/root'
    ClaimedOwners=@($octoberBinding[0].bootstrapOwners)
    ExpectedRegistryEntryCount=[int]$policy.registryBinding.entryCount
    ExpectedRegistrySha256=[string]$policy.registryBinding.sha256
    ProductionLane='integration_repair';ProductionPhase='coordination_bootstrap'
    ProductionWorkId='store-buy-combined-20261008'
    ProductionTicketId='UAW-INTEGRATION-REPAIR-STORE-BUY-COMBINED-20261008'
    RepositoryRoot=$root
  }
  foreach ($probeName in @('wrong-ticket','extra-app-owner','missing-owner','stale-generation')) {
    $probe=$bootstrapParameters.Clone()
    switch ($probeName) {
      'wrong-ticket' { $probe.ProductionTicketId='UAW-INTEGRATION-REPAIR-STORE-BUY-COMBINED-WRONG' }
      'extra-app-owner' { $probe.ClaimedOwners=@($probe.ClaimedOwners)+'apps/mobile/lib/features/journey01/journey_router.dart' }
      'missing-owner' { $probe.ClaimedOwners=@($probe.ClaimedOwners[0..3]) }
      'stale-generation' { $probe.ExpectedRegistrySha256=('0' * 64) }
    }
    $rejected=$false
    try { & $checkerPath @probe | Out-Null } catch { $rejected=$true; Write-Output "$probeName rejected: $($_.Exception.Message)" }
    Assert-RepairContract $rejected "operative bootstrap accepted $probeName."
  }
  Write-Output 'October operative bootstrap: 4 rejection probes passed; files were not mutated.'
}
Write-Output 'Codex Store-Buy integration repair coordination fixture passed.'
