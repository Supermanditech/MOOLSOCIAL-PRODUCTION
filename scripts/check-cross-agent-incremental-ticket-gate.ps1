[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('ticket_start', 'implementation', 'pre_build', 'handoff')]
  [string]$Phase,

  [Parameter(Mandatory)]
  [ValidateSet('cursor_ui', 'codex_ui', 'codex_backend', 'integration', 'integration_repair')]
  [string]$Lane,

  [Parameter(Mandatory)]
  [ValidatePattern('^[A-Z0-9][A-Z0-9-]{4,159}$')]
  [string]$TicketId,

  [Parameter(Mandatory)]
  [ValidatePattern('^[a-z][a-z0-9_.-]{2,119}$')]
  [string]$UiScope,

  [Parameter(Mandatory)]
  [ValidatePattern('^\d+\.\d+\.\d+-r\d+(?:\.\d+)?$')]
  [string]$CandidateVersionName,

  [Parameter(Mandatory)]
  [ValidateRange(1000000000, 2147483647)]
  [int]$CandidateVersionCode,

  [Parameter(Mandatory)]
  [ValidatePattern('^com\.moolsocial\.app(?:\.(?:cursorreview|runtime))?$')]
  [string]$PackageId,

  [string]$AcceptedUiCommit,
  [string]$UiContractPath,
  [string]$UiContractSha256,
  [string]$StatePath,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
if (-not $StatePath) {
  $StatePath = Join-Path $root `
    'config\cross-agent-incremental-ticket-gate.json'
}
$resolvedState = [IO.Path]::GetFullPath($StatePath)

function Assert-IncrementalTicket([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Incremental ticket gate rejected: $Message"
  }
}

function Test-CompatibilityIncrementalIdentity([hashtable]$Facts) {
  $expected=@{
    Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-INTEGRATION-REPAIR-store-buy-compatibility-20261008'
    Branch='work/integration-repair/store-buy-compatibility-20261008'
    Lane='integration_repair'
    Ticket='UAW-INTEGRATION-REPAIR-STORE-BUY-COMPATIBILITY-20261008'
    Scope='store.buy_publication_compatibility'
    Package='com.moolsocial.app.runtime'
    VersionName='1.0.0-r66.42'; VersionCode=2026100801
  }
  foreach($key in $expected.Keys) {
    if(-not $Facts.ContainsKey($key) -or [string]$Facts[$key] -cne [string]$expected[$key]) { return $false }
  }
  return $Facts.ContainsKey('Phase') -and
    [string]$Facts.Phase -cin @('ticket_start','implementation','handoff')
}

function Test-CompatibilityIncrementalImplementationStage([object]$Stage) {
  # Current Source15 preparation must be collected internally, not supplied by
  # a caller fact or inferred from a clean status. This grants no build/handoff.
  if($Stage -isnot [int]){return $false}
  if($Stage -in @(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)){return $true}
  if($Stage -notin @(16,17,18)){return $false}
  try {
    $prepared=if($Stage -eq 16){
      $stagedOwners=@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only'))
      $preparationPhase=if($stagedOwners.Count){'pre_commit'}else{'implementation'}
      Test-OctoberCompatibilityCurrentPreparation $preparationPhase
    }else{
      $observedHead=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))
      if($observedHead.Count -ne 1){return $false}
      $observedHistory=Get-OctoberCompatibilityHistoryStage $observedHead[0]
      if($observedHistory.PhaseStage -ne $Stage){return $false}
      Test-OctoberCompatibilityCurrentSourceState -History $observedHistory -Phase 'implementation'
    }
    return $prepared -is [bool] -and $prepared
  }catch{return $false}
}

# The accepted combined source is LF-01's start, not the retired August ticket.
# Delegate to the current exact owner/scope/Git checks; historical paths below
# remain unchanged. Exact accepted LF27 source publication grants no build/install.
if ($TicketId -cin @('LF-01','LF-02-1','LF-03','LF-04','LF-05','LF-06','LF-07','LF-08','LF-09','LF-10','LF-11','LF-12','LF-13','LF-14','LF-15','LF-16','LF-17','LF-18','LF-19','LF-20','LF-21','LF-22','LF-23','LF-24','LF-25','LF-26','LF-27') -or $UiScope -cin @('last-frontend-entry-recovery','last-frontend-store-details','last-frontend-product-media','last-frontend-selling-terms-offers','last-frontend-payment-return-policy','last-frontend-fulfilment-readiness','last-frontend-public-store-consistency','last-frontend-cart-checkout-consistency','last-frontend-payment-recovery','last-frontend-store-customer-orders','last-frontend-handover-tracking','last-frontend-after-sales-documents','last-frontend-customer-feedback','last-frontend-analytics-reconciliation','last-frontend-store-settings-truthfulness','last-frontend-pickup-preferences-recovery','last-frontend-store-attention-visual','last-frontend-store-defaults-recovery','last-frontend-store-input-consumers','last-frontend-trading-preferences-recovery','last-frontend-product-defaults-recovery','last-frontend-balance-payment-hold-recovery','last-frontend-readiness-preferences-recovery','last-frontend-offer-publish-availability','last-frontend-customer-terms-context','last-frontend-retail-facts-consistency','last-frontend-store-feedback-frontend')) {
  Assert-IncrementalTicket (($TicketId -ceq 'LF-01' -and $UiScope -ceq 'last-frontend-entry-recovery' -or
    $TicketId -ceq 'LF-02-1' -and $UiScope -ceq 'last-frontend-store-details' -or
    $TicketId -ceq 'LF-03' -and $UiScope -ceq 'last-frontend-product-media' -or
    $TicketId -ceq 'LF-04' -and $UiScope -ceq 'last-frontend-selling-terms-offers' -or
    $TicketId -ceq 'LF-05' -and $UiScope -ceq 'last-frontend-payment-return-policy' -or
    $TicketId -ceq 'LF-06' -and $UiScope -ceq 'last-frontend-fulfilment-readiness' -or
    $TicketId -ceq 'LF-07' -and $UiScope -ceq 'last-frontend-public-store-consistency' -or
    $TicketId -ceq 'LF-08' -and $UiScope -ceq 'last-frontend-cart-checkout-consistency' -or
    $TicketId -ceq 'LF-09' -and $UiScope -ceq 'last-frontend-payment-recovery' -or
    $TicketId -ceq 'LF-10' -and $UiScope -ceq 'last-frontend-store-customer-orders' -or
    $TicketId -ceq 'LF-11' -and $UiScope -ceq 'last-frontend-handover-tracking' -or
    $TicketId -ceq 'LF-12' -and $UiScope -ceq 'last-frontend-after-sales-documents' -or
    $TicketId -ceq 'LF-13' -and $UiScope -ceq 'last-frontend-customer-feedback' -or
    $TicketId -ceq 'LF-14' -and $UiScope -ceq 'last-frontend-analytics-reconciliation' -or
    $TicketId -ceq 'LF-15' -and $UiScope -ceq 'last-frontend-store-settings-truthfulness' -or
    $TicketId -ceq 'LF-16' -and $UiScope -ceq 'last-frontend-pickup-preferences-recovery' -or
    $TicketId -ceq 'LF-17' -and $UiScope -ceq 'last-frontend-store-attention-visual' -or
    $TicketId -ceq 'LF-18' -and $UiScope -ceq 'last-frontend-store-defaults-recovery' -or
    $TicketId -ceq 'LF-19' -and $UiScope -ceq 'last-frontend-store-input-consumers' -or
    $TicketId -ceq 'LF-20' -and $UiScope -ceq 'last-frontend-trading-preferences-recovery' -or
    $TicketId -ceq 'LF-21' -and $UiScope -ceq 'last-frontend-product-defaults-recovery' -or
    $TicketId -ceq 'LF-22' -and $UiScope -ceq 'last-frontend-balance-payment-hold-recovery' -or
    $TicketId -ceq 'LF-23' -and $UiScope -ceq 'last-frontend-readiness-preferences-recovery' -or
    $TicketId -ceq 'LF-24' -and $UiScope -ceq 'last-frontend-offer-publish-availability' -or
    $TicketId -ceq 'LF-25' -and $UiScope -ceq 'last-frontend-customer-terms-context' -or
    $TicketId -ceq 'LF-26' -and $UiScope -ceq 'last-frontend-retail-facts-consistency' -or
    $TicketId -ceq 'LF-27' -and $UiScope -ceq 'last-frontend-store-feedback-frontend') -and $Lane -ceq 'codex_ui' -and
    $PackageId -ceq 'com.moolsocial.app.runtime' -and
    $CandidateVersionName -ceq '1.0.0-r67.3' -and $CandidateVersionCode -eq 2026101303 -and
    ($Phase -cin @('ticket_start','implementation') -or
      ($Phase -ceq 'handoff' -and $TicketId -ceq 'LF-27' -and
        $AcceptedUiCommit -ceq 'cf08fb91ee6ba64973c9230c7db2f424bdd67cf1'))) 'LF-01 permits only its current hot-reload source identity; no build/handoff except accepted LF27 source publication.'
  $binding = (Get-Content -Raw -LiteralPath (Join-Path $root 'config/codex-subagent-coordination-policy.json') | ConvertFrom-Json).registryBinding
  $coordinationPhase = if ($Phase -ceq 'ticket_start') { 'task_start' }
    elseif ($Phase -ceq 'handoff') { 'handoff' } else { 'implementation' }
  & (Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1') `
    -RepositoryRoot $root -AgentRole primary -AgentTask /root -UseRecordedClaim `
    -ExpectedRegistryEntryCount $binding.entryCount -ExpectedRegistrySha256 $binding.sha256 `
    -ProductionLane codex_ui -ProductionPhase $coordinationPhase `
    -ProductionWorkId last-frontend-lf01-20261015 -ProductionTicketId $TicketId `
    -AcceptedUiCommit $AcceptedUiCommit
  return
}

Assert-IncrementalTicket (
  $resolvedState.StartsWith(
    $root + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  ) -and
  (Test-Path -LiteralPath $resolvedState -PathType Leaf)
) 'machine state is missing or outside the repository.'

try {
  $state = Get-Content -LiteralPath $resolvedState -Raw |
    ConvertFrom-Json
} catch {
  throw 'Incremental ticket gate rejected: machine state is invalid JSON.'
}

Assert-IncrementalTicket (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq
    'MOOLSOCIAL-CROSS-AGENT-INCREMENTAL-TICKET-001'
) 'machine-state identity changed.'

$compatibilityIncremental=$Lane -ceq 'integration_repair'
$selectedLane = @($state.lanes | Where-Object {
  $_.id -ceq $(if($compatibilityIncremental){'codex_ui'}else{$Lane})
})
Assert-IncrementalTicket ($selectedLane.Count -eq 1) `
  'lane contract is missing or duplicated.'
$selectedLane = $selectedLane[0]
if($compatibilityIncremental) {
  # Host/source preparation only; pre_build is intentionally not admitted.
  # Preserve the real runtime package/version floor and annotated baseline.
  $selectedLane=$selectedLane.PSObject.Copy()
  $selectedLane.branchPrefix='work/integration-repair/'
}

$branch = @(& git -C $root rev-parse --abbrev-ref HEAD)
Assert-IncrementalTicket (
  $LASTEXITCODE -eq 0 -and
  $branch.Count -eq 1 -and
  [string]$branch[0] -cne 'main' -and
  [string]$branch[0] -clike ([string]$selectedLane.branchPrefix + '*')
) 'branch does not match the selected lane.'

$head = @(& git -C $root rev-parse HEAD)
Assert-IncrementalTicket (
  $LASTEXITCODE -eq 0 -and
  $head.Count -eq 1 -and
  [string]$head[0] -cmatch '^[0-9a-f]{40}$'
) 'HEAD is unavailable.'
$head = [string]$head[0]
if($compatibilityIncremental) {
  Assert-IncrementalTicket (Test-CompatibilityIncrementalIdentity @{
    Root=$root.Replace('\','/'); Branch=[string]$branch[0]; Lane=$Lane
    Ticket=$TicketId; Scope=$UiScope; Package=$PackageId
    VersionName=$CandidateVersionName; VersionCode=$CandidateVersionCode; Phase=$Phase
  }) 'compatibility lane requires exact host-only identity/package/version; APK builds remain integration-gated.'
  $checkerPath=Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1'
  $tokens=$null; $errors=$null
  $ast=[System.Management.Automation.Language.Parser]::ParseFile($checkerPath,[ref]$tokens,[ref]$errors)
  Assert-IncrementalTicket ($errors.Count -eq 0) 'compatibility graph checker has parse errors.'
  foreach($name in @('Assert-Coordination','Get-OctoberCompatibilityBinding',
      'Get-OctoberCompatibilityApplicationOwners','Get-OctoberCompatibilityAmendmentOwners','Get-OctoberCompatibilityLayoutOwners','Get-OctoberCompatibilityHandoverOwners','Get-OctoberCompatibilityCoverageCartOwners','Get-OctoberCompatibilityInheritedCartTestOwners','Get-OctoberCompatibilityRetentionOwners','Get-OctoberCompatibilityForwardLayoutTestOwners','Get-OctoberCompatibilityScrollRepairOwners','Read-OctoberCompatibilityTestAdmissionContract','Test-OctoberCompatibilityBindingInventory',
      'Get-OctoberCompatibilityGitLines','Get-OctoberCompatibilityByteHash',
      'Read-OctoberCompatibilityJsonObject','Read-OctoberCompatibilityScopeRepairAdmission','Read-OctoberCompatibilityClaimHandoff',
      'Get-OctoberCompatibilityClaimHandoff','Get-OctoberCompatibilityHistoryStage',
      'Read-OctoberCompatibilityCurrentQualificationContract','Read-OctoberCompatibilityCurrentSuccessorSpecification','Test-OctoberCompatibilitySource15Preparation','Test-OctoberCompatibilityCurrentPreparation',
      'Read-OctoberCompatibilitySource17ForwardAmendment','Test-OctoberCompatibilitySource17Preparation','Test-OctoberCompatibilitySource17CurrentPreparation',
      'Read-OctoberCompatibilitySource19ForwardAmendment','Test-OctoberCompatibilitySource19Preparation','Test-OctoberCompatibilitySource19CurrentPreparation',
      'Read-OctoberCompatibilitySource21ForwardAmendment','Test-OctoberCompatibilitySource21Preparation','Test-OctoberCompatibilitySource21CurrentPreparation',
      'Read-OctoberCompatibilitySource23ForwardAmendment','Test-OctoberCompatibilitySource23Preparation','Test-OctoberCompatibilitySource23CurrentPreparation',
      'Read-OctoberCompatibilitySource25ForwardAmendment','Test-OctoberCompatibilitySource25Preparation','Test-OctoberCompatibilitySource25CurrentPreparation',
      'Read-OctoberCompatibilitySource27ForwardAmendment','Test-OctoberCompatibilitySource27Preparation','Test-OctoberCompatibilitySource27CurrentPreparation',
      'Read-OctoberCompatibilitySource28ForwardAmendment','Test-OctoberCompatibilitySource28Preparation','Test-OctoberCompatibilitySource28CurrentPreparation',
      'Get-ProductionRemoteBranchHead','Test-OctoberCompatibilityPublishedForwardCheckpoint',
      'Read-OctoberCompatibilityCurrentSourceState','Test-OctoberCompatibilityCurrentSourceState')) {
    $functions=@($ast.FindAll({param($node)
      $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name
    },$true))
    Assert-IncrementalTicket ($functions.Count -eq 1) 'compatibility graph function missing/duplicated.'
    . ([scriptblock]::Create($functions[0].Extent.Text))
  }
  $compatibilityHistory=Get-OctoberCompatibilityHistoryStage $head
  $compatibilityPolicy=Get-Content -Raw -LiteralPath (Join-Path $root 'config/codex-subagent-coordination-policy.json') | ConvertFrom-Json
  $baseLines=@(Get-OctoberCompatibilityGitLines @('show',"$($compatibilityHistory.Base):config/codex-subagent-coordination-policy.json"))
  $basePolicy=($baseLines -join "`n") | ConvertFrom-Json
  Assert-IncrementalTicket (Test-OctoberCompatibilityBindingInventory `
    -Bindings @($compatibilityPolicy.productionGitDiscipline.continuationBindings) `
    -BaseBindings @($basePolicy.productionGitDiscipline.continuationBindings)) 'compatibility binding inventory changed.'
  Assert-IncrementalTicket ($Phase -cne 'ticket_start' -or $compatibilityHistory.Stage -eq 1) 'compatibility start must be clean at exact G, not unqualified E.'
  Assert-IncrementalTicket ($Phase -cne 'implementation' -or (Test-CompatibilityIncrementalImplementationStage $compatibilityHistory.PhaseStage)) 'compatibility implementation requires exact sealed history and independent source-bound metadata preparation.'
  # Q is not documentary success: coordination handoff qualification remains
  # mandatory separately and this gate does not authorize integration.
  if($Phase -ceq 'handoff') {
    Assert-IncrementalTicket ($compatibilityHistory.Stage -eq ($compatibilityHistory.QualificationIndex+1) -and $compatibilityHistory.Forward -and
      $compatibilityHistory.PhaseStage -eq 19 -and
      (Test-OctoberCompatibilityPublishedForwardCheckpoint $compatibilityHistory.Head)) 'Compatibility handoff requires the exact published forward Q and complete native qualification; intermediate phases remain blocked.'
  }
}

$baselineTag = [string]$state.baselineTag
$tagType = @(& git -C $root cat-file -t $baselineTag 2>$null)
Assert-IncrementalTicket (
  $LASTEXITCODE -eq 0 -and
  $tagType.Count -eq 1 -and
  [string]$tagType[0] -ceq 'tag'
) 'latest baseline tag is missing or not annotated.'
$baselineCommit = @(& git -C $root rev-parse "$baselineTag^{commit}")
Assert-IncrementalTicket (
  $LASTEXITCODE -eq 0 -and
  $baselineCommit.Count -eq 1 -and
  [string]$baselineCommit[0] -cmatch '^[0-9a-f]{40}$'
) 'latest baseline commit cannot be resolved.'
$baselineCommit = [string]$baselineCommit[0]

$remoteTag = @(& git -C $root ls-remote --tags origin `
    "refs/tags/$baselineTag^{}")
Assert-IncrementalTicket (
  $LASTEXITCODE -eq 0 -and
  $remoteTag.Count -eq 1 -and
  ([string]$remoteTag[0] -split '\s+')[0] -ceq $baselineCommit
) 'latest baseline tag is not remote-exact.'

& git -C $root merge-base --is-ancestor $baselineCommit $head
Assert-IncrementalTicket ($LASTEXITCODE -eq 0) `
  'ticket HEAD does not descend from the latest baseline.'

$unstagedClean = $true
& git -C $root diff --quiet
if ($LASTEXITCODE -ne 0) { $unstagedClean = $false }
$stagedClean = $true
& git -C $root diff --cached --quiet
if ($LASTEXITCODE -ne 0) { $stagedClean = $false }
$untracked = @(& git -C $root ls-files --others --exclude-standard)
Assert-IncrementalTicket ($LASTEXITCODE -eq 0) `
  'untracked-owner inventory failed.'
$worktreeClean = $unstagedClean -and $stagedClean -and $untracked.Count -eq 0

if ($Phase -ceq 'ticket_start' -and -not $compatibilityIncremental) {
  $ticketStartsAtBaseline = $head -ceq $baselineCommit
  $ticketStartsAtAuthorizedBootstrap = $false
  if (-not $ticketStartsAtBaseline) {
    $coordinationPolicyPath = Join-Path $root `
      'config\codex-subagent-coordination-policy.json'
    Assert-IncrementalTicket (
      Test-Path -LiteralPath $coordinationPolicyPath -PathType Leaf
    ) 'coordination policy is unavailable for bootstrap verification.'
    try {
      $coordinationPolicy = Get-Content -Raw -LiteralPath `
        $coordinationPolicyPath | ConvertFrom-Json
    } catch {
      throw 'Incremental ticket gate rejected: coordination policy is invalid JSON.'
    }
    $branchName = [string]$branch[0]
    $bootstrapBindings = @(
      $coordinationPolicy.productionGitDiscipline.continuationBindings |
        Where-Object {
          [string]$_.lane -ceq $Lane -and
          [string]$_.ticketId -ceq $TicketId -and
          [string]$_.branch -ceq $branchName -and
          [string]$_.baselineHead -ceq $baselineCommit
        }
    )
    Assert-IncrementalTicket ($bootstrapBindings.Count -eq 1) `
      'ticket bootstrap has no exact founder-authorized continuation binding.'
    $bootstrapBinding = $bootstrapBindings[0]
    $bootstrapCommits = @(& git -C $root rev-list --first-parent `
        --reverse "$baselineCommit..$head")
    Assert-IncrementalTicket (
      $LASTEXITCODE -eq 0 -and
      $bootstrapCommits.Count -eq 1 -and
      [string]$bootstrapCommits[0] -ceq $head
    ) 'ticket start contains more than one post-baseline commit.'
    $bootstrapParent = @(& git -C $root rev-list --parents -n 1 $head)
    Assert-IncrementalTicket (
      $LASTEXITCODE -eq 0 -and
      $bootstrapParent.Count -eq 1 -and
      [string]$bootstrapParent[0] -ceq ($head + ' ' + $baselineCommit)
    ) 'ticket bootstrap is not a single-parent child of the baseline.'
    $bootstrapSubject = @(& git -C $root show -s --format=%s $head)
    Assert-IncrementalTicket (
      $LASTEXITCODE -eq 0 -and
      $bootstrapSubject.Count -eq 1 -and
      [string]$bootstrapSubject[0] -ceq
        [string]$bootstrapBinding.bootstrapCommitSubject
    ) 'ticket bootstrap subject differs from its authorized binding.'
    $bootstrapChangedOwners = @(& git -C $root diff --name-only `
        --diff-filter=ACMRTUXBD "$baselineCommit..$head")
    Assert-IncrementalTicket ($LASTEXITCODE -eq 0) `
      'ticket bootstrap owner inventory failed.'
    $expectedBootstrapOwners = @(
      $bootstrapBinding.bootstrapOwners | ForEach-Object {
        ([string]$_).Replace('\', '/').TrimStart('/')
      }
    )
    Assert-IncrementalTicket (
      (@($bootstrapChangedOwners | Sort-Object) -join '|') -ceq
      (@($expectedBootstrapOwners | Sort-Object) -join '|')
    ) 'ticket bootstrap changed an owner outside its authorized binding.'
    $ticketStartsAtAuthorizedBootstrap = $true
  }
  Assert-IncrementalTicket (
    $ticketStartsAtBaseline -or $ticketStartsAtAuthorizedBootstrap
  ) 'ticket did not start at the latest baseline or its exact coordination bootstrap.'
  Assert-IncrementalTicket $worktreeClean `
    'ticket-start worktree is not clean.'
}
if ($Phase -ceq 'handoff' -or ($compatibilityIncremental -and $Phase -ceq 'ticket_start')) {
  Assert-IncrementalTicket $worktreeClean `
    'handoff worktree is not clean.'
}

Assert-IncrementalTicket (
  $PackageId -ceq [string]$selectedLane.packageId
) 'package does not match the lane.'
Assert-IncrementalTicket (
  $CandidateVersionCode -gt [int]$selectedLane.minimumVersionCodeExclusive
) 'candidate version code is not incremental.'

if ($Lane -ceq 'codex_backend') {
  Assert-IncrementalTicket (
    [string]$state.uiFounderReview.state -ceq 'accepted'
  ) 'backend work is blocked until founder UI acceptance.'
  $scope = @($state.uiFounderReview.acceptedScopes | Where-Object {
      $_.id -ceq $UiScope
    })
  Assert-IncrementalTicket ($scope.Count -eq 1) `
    'backend UI scope is not accepted or is duplicated.'
  $scope = $scope[0]
  Assert-IncrementalTicket (
    $AcceptedUiCommit -ceq [string]$scope.uiCommit -and
    $UiContractPath -ceq [string]$scope.contractPath -and
    $UiContractSha256 -ceq [string]$scope.contractSha256 -and
    $AcceptedUiCommit -cmatch '^[0-9a-f]{40}$' -and
    $UiContractSha256 -cmatch '^[0-9A-F]{64}$'
  ) 'backend UI commit or contract binding differs.'
  $contractFile = [IO.Path]::GetFullPath((Join-Path $root $UiContractPath))
  Assert-IncrementalTicket (
    $contractFile.StartsWith(
      $root + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath $contractFile -PathType Leaf) -and
    (Get-FileHash -LiteralPath $contractFile -Algorithm SHA256).Hash -ceq
      $UiContractSha256
  ) 'backend UI contract is missing or changed.'
}

if ($Lane -cne 'codex_backend') {
  Assert-IncrementalTicket (
    -not @($state.uiFounderReview.blockedBackendScopes).Contains($UiScope)
  ) 'ticket scope is explicitly blocked by the current UI boundary.'
}

Write-Output (
  'Incremental ticket gate passed: ' +
  "phase=$Phase; lane=$Lane; ticket=$TicketId; scope=$UiScope; " +
  "baseline=$baselineTag@$baselineCommit; " +
  "version=$CandidateVersionName+$CandidateVersionCode; package=$PackageId."
)
