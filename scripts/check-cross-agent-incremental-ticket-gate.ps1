[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('ticket_start', 'implementation', 'pre_build', 'handoff')]
  [string]$Phase,

  [Parameter(Mandatory)]
  [ValidateSet('cursor_ui', 'codex_ui', 'codex_backend', 'integration')]
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

Assert-IncrementalTicket (
  $resolvedState.StartsWith(
    $root + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  ) -and
  (Test-Path -LiteralPath $resolvedState -PathType Leaf)
) 'machine state is missing or outside the repository.'

try {
  $state = Get-Content -LiteralPath $resolvedState -Raw |
    ConvertFrom-Json -Depth 30
} catch {
  throw 'Incremental ticket gate rejected: machine state is invalid JSON.'
}

Assert-IncrementalTicket (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq
    'MOOLSOCIAL-CROSS-AGENT-INCREMENTAL-TICKET-001'
) 'machine-state identity changed.'

$selectedLane = @($state.lanes | Where-Object { $_.id -ceq $Lane })
Assert-IncrementalTicket ($selectedLane.Count -eq 1) `
  'lane contract is missing or duplicated.'
$selectedLane = $selectedLane[0]

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

if ($Phase -ceq 'ticket_start') {
  Assert-IncrementalTicket ($head -ceq $baselineCommit) `
    'ticket did not start at the latest baseline commit.'
  Assert-IncrementalTicket $worktreeClean `
    'ticket-start worktree is not clean.'
}
if ($Phase -ceq 'handoff') {
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
