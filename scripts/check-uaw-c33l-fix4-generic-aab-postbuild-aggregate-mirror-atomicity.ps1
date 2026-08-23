[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33LFix4 {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C33L FIX4 aggregate mirror gate rejected: $Message" }
}

function Resolve-C33LFix4File {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33LFix4 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

function Get-C33LFix4SelectionMode {
  param(
    [Parameter(Mandatory)][object]$MvpState,
    [Parameter(Mandatory)][string]$Fix4TicketSha256,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix4EvidenceExists
  )
  $fix4Id = 'UAW-C33L-FIX4-GENERIC-AAB-POSTBUILD-AGGREGATE-MIRROR-ATOMICITY'
  $checkpoint = $MvpState.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  $selected = $checkpoint.selectedTicketAssessment
  if ($currentId -cne [string]$selected.ticketId) {
    throw 'C33L FIX4 current and selected ticket identities differ.'
  }
  if ([string]$selected.manifestSha256 -cne $SelectedTicketSha256) {
    throw 'C33L FIX4 selected ticket manifest hash changed.'
  }
  if ($currentId -ceq $fix4Id) {
    if ($SelectedTicketSha256 -cne $Fix4TicketSha256) {
      throw 'C33L FIX4 active ticket hash differs from its manifest.'
    }
    return 'active_FIX4'
  }
  if ($null -eq $checkpoint.PSObject.Properties['priorC33LFix4SelectedTicketAssessment']) {
    throw 'C33L FIX4 qualified predecessor assessment is missing.'
  }
  $prior = $checkpoint.priorC33LFix4SelectedTicketAssessment
  if (
    [string]$prior.ticketId -cne $fix4Id -or
    [string]$prior.manifestSha256 -cne $Fix4TicketSha256 -or
    [string]$prior.implementationState -cne
      'source_test_gate_repair_qualified_dual_host_parent_successor_required_build_Play_OPPO_and_external_actions_held' -or
    -not $Fix4EvidenceExists
  ) {
    throw 'C33L FIX4 qualified predecessor hash, state or evidence changed.'
  }
  return 'qualified_successor_replay'
}

$ticketPath = Resolve-C33LFix4File `
  -Path 'config/uaw-c33l-fix4-generic-aab-postbuild-aggregate-mirror-atomicity-ticket.json' `
  -Label 'FIX4 ticket'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33LFix4 -Condition (
  [string]$ticket.ticketId -ceq 'UAW-C33L-FIX4-GENERIC-AAB-POSTBUILD-AGGREGATE-MIRROR-ATOMICITY' -and
  [string]$ticket.findingId -ceq 'REG-20260816-2547-C33L-SUCCESSFUL-AAB-INCOMPLETE-AGGREGATE-BUILD-MIRROR' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.sourceTestAndGateRepairAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, scope classification or held authority changed.'

$mvpStatePath = Resolve-C33LFix4File -Path 'config/mvp-scope-gate-state.json' -Label 'MVP state'
$mvpState = Get-Content -Raw -LiteralPath $mvpStatePath | ConvertFrom-Json
$checkpoint = $mvpState.preTicketSelectionCheckpoint
$selectedAssessment = $checkpoint.selectedTicketAssessment
$selectedTicketPath = Resolve-C33LFix4File -Path ([string]$selectedAssessment.manifestPath) -Label 'selected ticket'
$selectedTicketSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $selectedTicketPath).Hash
$fix4TicketSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$fix4EvidenceExists = $false
if ($null -ne $checkpoint.PSObject.Properties['priorC33LFix4SelectedTicketAssessment']) {
  $evidenceRelative = [string]$checkpoint.priorC33LFix4SelectedTicketAssessment.evidencePath
  if (-not [string]::IsNullOrWhiteSpace($evidenceRelative)) {
    $evidenceAbsolute = [IO.Path]::GetFullPath((Join-Path $root $evidenceRelative))
    $fix4EvidenceExists = (
      $evidenceAbsolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
      (Test-Path -LiteralPath $evidenceAbsolute -PathType Leaf)
    )
  }
}
$selectionMode = Get-C33LFix4SelectionMode `
  -MvpState $mvpState `
  -Fix4TicketSha256 $fix4TicketSha256 `
  -SelectedTicketSha256 $selectedTicketSha256 `
  -Fix4EvidenceExists $fix4EvidenceExists
$scopeGate = Resolve-C33LFix4File -Path 'scripts/check-mvp-scope-gate-state.ps1' -Label 'MVP scope gate'
& $scopeGate `
  -CandidateId ([string]$checkpoint.currentTicketId) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null

$wrapperPath = Resolve-C33LFix4File -Path 'scripts/invoke-play-internal-aab-build-c30t.ps1' -Label 'generic AAB wrapper'
$checkerPath = Resolve-C33LFix4File -Path 'scripts/check-play-internal-aab-build-wrapper-c30t.ps1' -Label 'generic wrapper checker'
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$checker = Get-Content -Raw -LiteralPath $checkerPath
foreach ($forbidden in @(
  'Get-Content -Raw -LiteralPath $secretDefinePath',
  'Get-Content -Raw -LiteralPath $googleServicesPath',
  'MOOLSOCIAL_UPLOAD_STORE_PASSWORD=',
  'MOOLSOCIAL_FIREBASE_API_KEY=',
  'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID='
)) {
  Assert-C33LFix4 -Condition (
    $wrapper.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -lt 0
  ) -Message "generic wrapper contains forbidden private-value use: $forbidden"
}
Assert-C33LFix4 -Condition (
  $checker.IndexOf('Get-Content -Raw -LiteralPath $secretDefinePath', [StringComparison]::Ordinal) -ge 0 -and
  $checker.IndexOf('Get-Content -Raw -LiteralPath $googleServicesPath', [StringComparison]::Ordinal) -ge 0
) -Message 'generic checker private-file-read sentinels changed.'

$parseErrors = $null
$tokens = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $wrapperPath,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33LFix4 -Condition (@($parseErrors).Count -eq 0) -Message 'generic AAB wrapper does not parse.'
$functionAst = @(
  $ast.FindAll(
    { param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Set-C30TAggregateBuildConsumed' },
    $true
  )
)
Assert-C33LFix4 -Condition ($functionAst.Count -eq 1) -Message 'aggregate transition function is missing or duplicated.'
Invoke-Expression $functionAst[0].Extent.Text

$successor = [pscustomobject]@{
  actionCounts = [pscustomobject]@{ build = 0; upload = 0 }
  releaseAuthorities = [pscustomobject]@{ build = 'available_once'; uploadAndInternalActivation = 'held_postbuild_qualification' }
}
Set-C30TAggregateBuildConsumed -Aggregate $successor
Assert-C33LFix4 -Condition (
  [int]$successor.actionCounts.build -eq 1 -and
  [string]$successor.releaseAuthorities.build -ceq 'consumed' -and
  [int]$successor.actionCounts.upload -eq 0 -and
  [string]$successor.releaseAuthorities.uploadAndInternalActivation -ceq 'held_postbuild_qualification'
) -Message 'successor aggregate transition changed unrelated state or missed a build mirror.'

$authorityOnly = [pscustomobject]@{
  releaseAuthorities = [pscustomobject]@{ build = 'available_once' }
}
Set-C30TAggregateBuildConsumed -Aggregate $authorityOnly
Assert-C33LFix4 -Condition (
  [string]$authorityOnly.releaseAuthorities.build -ceq 'consumed' -and
  $null -eq $authorityOnly.PSObject.Properties['actionCounts']
) -Message 'C33F-compatible authority-only aggregate transition failed.'

$actionOnly = [pscustomobject]@{ actionCounts = [pscustomobject]@{ build = 0 } }
Set-C30TAggregateBuildConsumed -Aggregate $actionOnly
Assert-C33LFix4 -Condition (
  [int]$actionOnly.actionCounts.build -eq 1 -and
  $null -eq $actionOnly.PSObject.Properties['releaseAuthorities']
) -Message 'action-only aggregate transition failed.'

$legacy = [pscustomobject]@{ candidate = [pscustomobject]@{ buildCount = 0 } }
Set-C30TAggregateBuildConsumed -Aggregate $legacy
Assert-C33LFix4 -Condition (
  [int]$legacy.candidate.buildCount -eq 0 -and
  $null -eq $legacy.PSObject.Properties['actionCounts'] -and
  $null -eq $legacy.PSObject.Properties['releaseAuthorities']
) -Message 'legacy aggregate gained an unsupported lifecycle property.'

$malformedActionRejected = $false
try {
  Set-C30TAggregateBuildConsumed -Aggregate ([pscustomobject]@{
    actionCounts = [pscustomobject]@{ upload = 0 }
  })
} catch {
  $malformedActionRejected = $_.Exception.Message.IndexOf(
    'aggregate action-count contract is malformed',
    [StringComparison]::Ordinal
  ) -ge 0
}
Assert-C33LFix4 -Condition $malformedActionRejected -Message 'malformed action-count mirror did not fail closed.'

$malformedAuthorityRejected = $false
try {
  Set-C30TAggregateBuildConsumed -Aggregate ([pscustomobject]@{
    releaseAuthorities = [pscustomobject]@{ uploadAndInternalActivation = 'held' }
  })
} catch {
  $malformedAuthorityRejected = $_.Exception.Message.IndexOf(
    'aggregate release-authority contract is malformed',
    [StringComparison]::Ordinal
  ) -ge 0
}
Assert-C33LFix4 -Condition $malformedAuthorityRejected -Message 'malformed release-authority mirror did not fail closed.'

$callToken = 'Set-C30TAggregateBuildConsumed -Aggregate $aggregate'
Assert-C33LFix4 -Condition (
  [regex]::Matches($wrapper, [regex]::Escape($callToken)).Count -eq 2 -and
  $checker.IndexOf('aggregate build-consumption transition count', [StringComparison]::Ordinal) -ge 0 -and
  $checker.IndexOf('build-consumption mirror or write order changed', [StringComparison]::Ordinal) -ge 0 -and
  $checker.IndexOf('successful-build mirror or write order changed', [StringComparison]::Ordinal) -ge 0
) -Message 'two transition calls or exact static write-order prevention changed.'

$statePath = Resolve-C33LFix4File -Path 'config/successor-aab-regression-hard-gate-state-c33l.json' -Label 'rejected r60.50 state'
$aggregatePath = Resolve-C33LFix4File -Path 'config/successor-aab-regression-hard-gate-aggregate-c33l.json' -Label 'rejected r60.50 aggregate'
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
$aggregate = Get-Content -Raw -LiteralPath $aggregatePath | ConvertFrom-Json
$artifactPath = Resolve-C33LFix4File -Path ([string]$state.buildResult.artifactPath) -Label 'rejected r60.50 AAB'
Assert-C33LFix4 -Condition (
  [string]$state.candidate.versionCode -ceq '2026081350' -and
  [string]$state.buildAuthorization -ceq 'consumed' -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$state.actionCounts.upload -eq 0 -and
  [int]$state.actionCounts.install -eq 0 -and
  [int]$state.actionCounts.deviceAcceptance -eq 0 -and
  [int]$aggregate.candidate.buildCount -eq 1 -and
  [int]$aggregate.actionCounts.build -eq 0 -and
  [string]$aggregate.releaseAuthorities.build -ceq 'available_once' -and
  (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash -ceq [string]$state.buildResult.artifactSha256
) -Message 'rejected r60.50 artifact, 1/0/0/0 counts or preserved mismatch evidence changed.'

Write-Output (
  'C33L FIX4 aggregate mirror atomicity gate passed: ' +
  "selectionMode=$selectionMode; " +
  'successor=1/consumed; authorityOnly=consumed; actionOnly=1; legacy=unchanged; ' +
  'malformedActionRejected=true; malformedAuthorityRejected=true; rejectedR60_50=preserved_1_0_0_0; ' +
  'buildPlayDeviceExternal=false; secretValuesObserved=false.'
)
