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
$copyCheckerPath = Join-Path $root 'scripts\check-user-facing-copy.ps1'
$interactionCheckerPath = Join-Path $root 'scripts\check-interaction-contracts.ps1'
$buyReferenceCheckerPath = Join-Path $root 'scripts\check-buy-approved-reference.ps1'
$socialBaselineCheckerPath = Join-Path $root 'scripts\check-social-protected-baseline.ps1'
$buyBaselineCheckerPath = Join-Path $root 'scripts\check-buy-protected-baseline.ps1'
$buyBackendCheckerPath = Join-Path $root 'scripts\check-buy-backend-contract-boundary.ps1'
$buyEgressCheckerPath = Join-Path $root 'scripts\check-buy-data-egress-boundary.ps1'
$brandCheckerPath = Join-Path $root 'scripts\check-brand-integrity.ps1'
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
$checker = Get-Content -Raw -LiteralPath $checkerPath
$lockChecker = Get-Content -Raw -LiteralPath $lockCheckerPath
$copyChecker = Get-Content -Raw -LiteralPath $copyCheckerPath
$interactionChecker = Get-Content -Raw -LiteralPath $interactionCheckerPath
$buyReferenceChecker = Get-Content -Raw -LiteralPath $buyReferenceCheckerPath
$socialBaselineChecker = Get-Content -Raw -LiteralPath $socialBaselineCheckerPath
$buyBaselineChecker = Get-Content -Raw -LiteralPath $buyBaselineCheckerPath
$buyBackendChecker = Get-Content -Raw -LiteralPath $buyBackendCheckerPath
$buyEgressChecker = Get-Content -Raw -LiteralPath $buyEgressCheckerPath
$brandChecker = Get-Content -Raw -LiteralPath $brandCheckerPath

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
  [string]$_.task -ceq '/root/integration_social_runtime_chat_v4_20260826'
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
  [int]$repair.maximumPostMergeClosureCommits -eq 5 -and
  @($repair.postMergeClosureOwners).Count -eq 17 -and
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
$firstParentReverseTraversals = [regex]::Matches(
  $checker,
  'rev-list --first-parent --reverse'
).Count
Assert-RepairContract ($firstParentReverseTraversals -ge 3) `
  'repair bootstrap or subject inventory can traverse second-parent history.'
foreach ($lockToken in @(
    'function Test-SealedParallelContinuationFacts',
    'function Test-SealedParallelContinuationUnchanged',
    'work/integration-repair/social-runtime-chat-conflict-correction-20260825',
    'integration/moolsocial/social-runtime-chat-v2-20260825',
    'integration/moolsocial/social-runtime-chat-v3-20260826',
    'integration/moolsocial/social-runtime-chat-v4-20260826',
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
foreach ($copyToken in @(
    'function Remove-DartInterpolationForCustomerCopy',
    'User-facing copy interpolation fixture failed.',
    'function Test-NonVisibleDartCopyLine',
    'User-facing copy non-visible Dart metadata fixture failed.',
    '$safeCodeMapFixture',
    '$brokerSetFixture',
    '$argumentFixture',
    '$switchCodeFixture',
    '$authCodeFixture',
    '$violations | ForEach-Object { Write-Output $_ }'
  )) {
  Assert-RepairContract ($copyChecker.Contains($copyToken)) `
    "customer-copy token is missing: $copyToken"
}
foreach ($interactionToken in @(
    'function Test-InterpolatedRouteTarget',
    'function Test-ExternalAuthCallbackTemplate',
    'function Test-EmailContinuePathContract',
    'function Test-RoutePredicateLiteral',
    'function Test-NavigatorRouteSettingsName',
    '$violations | ForEach-Object { Write-Output $_ }',
    'Interaction contract interpolated-route fixture failed.'
  )) {
  Assert-RepairContract ($interactionChecker.Contains($interactionToken)) `
    "interaction-contract token is missing: $interactionToken"
}
foreach ($buyReferenceToken in @(
    'function Test-BuyReferenceBytes',
    'Buy approved sealed-parallel fixture failed.'
  )) {
  Assert-RepairContract ($buyReferenceChecker.Contains($buyReferenceToken)) `
    "Buy approved-reference token is missing: $buyReferenceToken"
}
foreach ($socialBaselineToken in @(
    'function Test-SealedSocialOverlay',
    'Social protected sealed-overlay fixture failed.'
  )) {
  Assert-RepairContract ($socialBaselineChecker.Contains($socialBaselineToken)) `
    "Social protected-baseline token is missing: $socialBaselineToken"
}
foreach ($buyBaselineToken in @(
    'function Resolve-BuyProtectedBaselinePath',
    'Buy protected baseline resolver fixture failed.'
  )) {
  Assert-RepairContract ($buyBaselineChecker.Contains($buyBaselineToken)) `
    "Buy protected-baseline token is missing: $buyBaselineToken"
}
foreach ($buyBackendToken in @(
    'function Test-SealedBuyBackendOverlay',
    'Buy backend sealed-overlay fixture failed.'
  )) {
  Assert-RepairContract ($buyBackendChecker.Contains($buyBackendToken)) `
    "Buy backend-boundary token is missing: $buyBackendToken"
}
foreach ($buyEgressToken in @(
    'function Test-SealedBuyEgressClipboardAction',
    'Buy egress clipboard fixture failed.'
  )) {
  Assert-RepairContract ($buyEgressChecker.Contains($buyEgressToken)) `
    "Buy data-egress token is missing: $buyEgressToken"
}
foreach ($brandToken in @(
    'function Test-SealedBuyThemeIntegration',
    'function Test-SealedChatBrandProjection',
    'function Test-SealedSocialBrandEntries',
    'Brand integrity sealed Buy theme fixture failed.'
  )) {
  Assert-RepairContract ($brandChecker.Contains($brandToken)) `
    "brand-integrity token is missing: $brandToken"
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
