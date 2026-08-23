[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33LFix5 {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C33L FIX5 launcher result gate rejected: $Message" }
}

function Resolve-C33LFix5File {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33LFix5 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

function Get-C33LFix5SelectionMode {
  param(
    [Parameter(Mandatory)][object]$MvpState,
    [Parameter(Mandatory)][string]$Fix5TicketSha256,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix5EvidenceExists
  )
  $fix5Id =
    'UAW-C33L-FIX5-FOUNDER-AAB-LAUNCHER-POSTCLEANUP-RESULT-RETENTION'
  $checkpoint = $MvpState.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  $selected = $checkpoint.selectedTicketAssessment
  if ($currentId -cne [string]$selected.ticketId) {
    throw 'C33L FIX5 current and selected ticket identities differ.'
  }
  if ([string]$selected.manifestSha256 -cne $SelectedTicketSha256) {
    throw 'C33L FIX5 selected ticket manifest hash changed.'
  }
  if ($currentId -ceq $fix5Id) {
    if ($SelectedTicketSha256 -cne $Fix5TicketSha256) {
      throw 'C33L FIX5 active ticket hash differs from its manifest.'
    }
    return 'active_FIX5'
  }
  if (
    $null -eq
      $checkpoint.PSObject.Properties['priorC33LFix5SelectedTicketAssessment']
  ) {
    throw 'C33L FIX5 qualified predecessor assessment is missing.'
  }
  $prior = $checkpoint.priorC33LFix5SelectedTicketAssessment
  if (
    [string]$prior.ticketId -cne $fix5Id -or
    [string]$prior.manifestSha256 -cne $Fix5TicketSha256 -or
    [string]$prior.implementationState -cne
      'source_test_gate_repair_qualified_dual_host_future_launcher_binding_required_build_Play_OPPO_and_external_actions_held' -or
    -not $Fix5EvidenceExists
  ) {
    throw 'C33L FIX5 qualified predecessor hash, state or evidence changed.'
  }
  return 'qualified_successor_replay'
}

$ticketPath = Resolve-C33LFix5File `
  -Path 'config/uaw-c33l-fix5-founder-aab-launcher-postcleanup-result-retention-ticket.json' `
  -Label 'FIX5 ticket'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33LFix5 -Condition (
  [string]$ticket.ticketId -ceq 'UAW-C33L-FIX5-FOUNDER-AAB-LAUNCHER-POSTCLEANUP-RESULT-RETENTION' -and
  [string]$ticket.findingId -ceq 'REG-20260816-2550-C33L-FOUNDER-LAUNCHER-EXIT-AMBIGUOUS-AFTER-POSTBUILD-FAILURE' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.sourceTestAndGateRepairAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, classification or held authority changed.'

$mvpStatePath = Resolve-C33LFix5File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP state'
$mvpState = Get-Content -Raw -LiteralPath $mvpStatePath | ConvertFrom-Json
$checkpoint = $mvpState.preTicketSelectionCheckpoint
$selectedAssessment = $checkpoint.selectedTicketAssessment
$selectedTicketPath = Resolve-C33LFix5File `
  -Path ([string]$selectedAssessment.manifestPath) `
  -Label 'selected ticket'
$selectedTicketSha256 =
  (Get-FileHash -Algorithm SHA256 -LiteralPath $selectedTicketPath).Hash
$fix5TicketSha256 =
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$fix5EvidenceExists = $false
if (
  $null -ne
    $checkpoint.PSObject.Properties['priorC33LFix5SelectedTicketAssessment']
) {
  $evidenceRelative =
    [string]$checkpoint.priorC33LFix5SelectedTicketAssessment.evidencePath
  if (-not [string]::IsNullOrWhiteSpace($evidenceRelative)) {
    $evidenceAbsolute =
      [IO.Path]::GetFullPath((Join-Path $root $evidenceRelative))
    $fix5EvidenceExists = (
      $evidenceAbsolute.StartsWith(
        $prefix,
        [StringComparison]::OrdinalIgnoreCase
      ) -and
      (Test-Path -LiteralPath $evidenceAbsolute -PathType Leaf)
    )
  }
}
$selectionMode = Get-C33LFix5SelectionMode `
  -MvpState $mvpState `
  -Fix5TicketSha256 $fix5TicketSha256 `
  -SelectedTicketSha256 $selectedTicketSha256 `
  -Fix5EvidenceExists $fix5EvidenceExists
$scopeGate = Resolve-C33LFix5File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate `
  -CandidateId ([string]$checkpoint.currentTicketId) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null

$helperPath = Resolve-C33LFix5File `
  -Path 'scripts/c30t-founder-launcher-result-retention.ps1' `
  -Label 'launcher result owner'
$helper = Get-Content -Raw -LiteralPath $helperPath
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $helperPath,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33LFix5 -Condition (@($parseErrors).Count -eq 0) -Message 'launcher result owner does not parse.'
$functionAst = @(
  $ast.FindAll(
    { param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Complete-C30TFounderLauncherResult' },
    $true
  )
)
Assert-C33LFix5 -Condition ($functionAst.Count -eq 1) -Message 'launcher result function is missing or duplicated.'
$parameterNames = @(
  $functionAst[0].Body.ParamBlock.Parameters |
    ForEach-Object { $_.Name.VariablePath.UserPath }
)
Assert-C33LFix5 -Condition (
  $parameterNames.Count -eq 2 -and
  $parameterNames[0] -ceq 'Result' -and
  $parameterNames[1] -ceq 'NoWait'
) -Message 'launcher result owner accepts a private or unexpected input.'
foreach ($forbidden in @(
  'SecureString', 'PSCredential', 'Exception', 'ErrorRecord', 'Password',
  'ApiKey', 'ClientId', 'Token', 'Nonce', 'PrivateKey', 'Attestation'
)) {
  Assert-C33LFix5 -Condition (
    $helper.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -lt 0
  ) -Message "launcher result owner contains forbidden private-payload vocabulary: $forbidden"
}

. $helperPath
$successOutput = (& {
  Complete-C30TFounderLauncherResult -Result build_qualified -NoWait
} 6>&1 | Out-String)
$failureOutput = (& {
  Complete-C30TFounderLauncherResult -Result stopped_after_cleanup -NoWait
} 6>&1 | Out-String)

$successLine = 'AAB build and postbuild qualification completed.'
$scopeLine = 'Play upload, OPPO update, device journeys and production readiness are not implied.'
$returnLine = 'Return to Codex and report the visible result before any next release action.'
$failureLine = 'AAB launcher stopped after cleanup. No success is claimed.'
$reconcileLine = 'Return to Codex for repository reconciliation before any retry.'
Assert-C33LFix5 -Condition (
  $successOutput.IndexOf($successLine, [StringComparison]::Ordinal) -ge 0 -and
  $successOutput.IndexOf($scopeLine, [StringComparison]::Ordinal) -ge 0 -and
  $successOutput.IndexOf($returnLine, [StringComparison]::Ordinal) -ge 0 -and
  $successOutput.IndexOf($failureLine, [StringComparison]::Ordinal) -lt 0 -and
  $failureOutput.IndexOf($failureLine, [StringComparison]::Ordinal) -ge 0 -and
  $failureOutput.IndexOf($reconcileLine, [StringComparison]::Ordinal) -ge 0 -and
  $failureOutput.IndexOf($successLine, [StringComparison]::Ordinal) -lt 0
) -Message 'bounded success or failure result text changed.'

Assert-C33LFix5 -Condition (
  $helper.IndexOf("[ValidateSet('build_qualified', 'stopped_after_cleanup')]", [StringComparison]::Ordinal) -ge 0 -and
  $helper.IndexOf("Read-Host 'After reporting the result to Codex, press Enter to close this launcher'", [StringComparison]::Ordinal) -ge 0 -and
  $helper.IndexOf('if (-not $NoWait)', [StringComparison]::Ordinal) -ge 0
) -Message 'exact two-result or interactive hold contract changed.'

$rejectedLauncherPath = Resolve-C33LFix5File `
  -Path 'tmp/run-c33l-r60-50-single-aab-founder.ps1' `
  -Label 'rejected r60.50 launcher'
$statePath = Resolve-C33LFix5File `
  -Path 'config/successor-aab-regression-hard-gate-state-c33l.json' `
  -Label 'rejected r60.50 state'
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
Assert-C33LFix5 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $rejectedLauncherPath).Hash -ceq
    'FE7D5741C453AD5CC029EF30141F9E35ED339F7CFE36265C9C1BEB0FC00593CF' -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$state.actionCounts.upload -eq 0 -and
  [int]$state.actionCounts.install -eq 0 -and
  [int]$state.actionCounts.deviceAcceptance -eq 0
) -Message 'rejected r60.50 launcher or 1/0/0/0 counts changed.'

$fix4 = $mvpState.preTicketSelectionCheckpoint.priorC33LFix4SelectedTicketAssessment
$fix4TicketPath = Resolve-C33LFix5File -Path ([string]$fix4.manifestPath) -Label 'qualified FIX4 ticket'
$fix4EvidencePath = Resolve-C33LFix5File -Path ([string]$fix4.evidencePath) -Label 'qualified FIX4 evidence'
Assert-C33LFix5 -Condition (
  [string]$fix4.ticketId -ceq 'UAW-C33L-FIX4-GENERIC-AAB-POSTBUILD-AGGREGATE-MIRROR-ATOMICITY' -and
  (Get-FileHash -Algorithm SHA256 -LiteralPath $fix4TicketPath).Hash -ceq [string]$fix4.manifestSha256 -and
  [string]$fix4.implementationState -ceq 'source_test_gate_repair_qualified_dual_host_parent_successor_required_build_Play_OPPO_and_external_actions_held' -and
  (Test-Path -LiteralPath $fix4EvidencePath -PathType Leaf)
) -Message 'qualified FIX4 predecessor assessment changed.'

Write-Output (
  'C33L FIX5 launcher result-retention gate passed: ' +
  "selectionMode=$selectionMode; results=2/2; " +
  'successTruth=true; failureTruth=true; privatePayloadInputs=0; interactiveHold=true; ' +
  'rejectedR60_50=preserved_1_0_0_0; buildPlayDeviceExternal=false; secretValuesObserved=false.'
)
