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
      'Get-OctoberCompatibilityApplicationOwners','Get-OctoberCompatibilityLayoutOwners','Test-OctoberCompatibilityBindingInventory',
      'Get-OctoberCompatibilityGitLines','Get-OctoberCompatibilityHistoryStage')) {
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
  Assert-IncrementalTicket ($Phase -cne 'implementation' -or $compatibilityHistory.Stage -in @(1,2,3)) 'compatibility implementation requires exact G/C/L.'
  # Q is not documentary success: coordination handoff qualification remains
  # mandatory separately and this gate does not authorize integration.
  Assert-IncrementalTicket ($Phase -cne 'handoff' -or $compatibilityHistory.Stage -eq 4) 'compatibility handoff requires exact Q after L.'
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
