[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33MFix8 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33M FIX8 FIX4 generic successor replay rejected: $Message"
  }
}

function Resolve-C33MFix8File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33MFix8 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Get-C33MFix8SelectionMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix8EvidenceExists
  )
  $fix8Id = 'UAW-C33M-FIX8-FIX4-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
  $fix8Hash = '806B59F65D4E9A7422F23D2F6C79010A01F2A6AA592359A754071B42019671F8'
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  if (
    $currentId -cne [string]$Scope.ticket.id -or
    $currentId -cne [string]$checkpoint.selectedTicketAssessment.ticketId -or
    [string]$checkpoint.selectedTicketAssessment.manifestSha256 -cne
      $SelectedTicketSha256
  ) {
    throw 'C33M FIX8 current, top-level or selected ticket binding changed.'
  }
  if ($currentId -ceq $fix8Id) {
    if ($SelectedTicketSha256 -cne $fix8Hash) {
      throw 'C33M FIX8 direct selection ticket hash changed.'
    }
    return 'FIX8_active'
  }
  $qualified = $checkpoint.priorC33MFix8SelectedTicketAssessment
  if (
    [string]$qualified.ticketId -cne $fix8Id -or
    [string]$qualified.manifestPath -cne
      'config/uaw-c33m-fix8-fix4-gate-generic-successor-replay-compatibility-ticket.json' -or
    [string]$qualified.manifestSha256 -cne $fix8Hash -or
    [string]$qualified.implementationState -cne
      'FIX4_generic_successor_replay_qualified_dual_host_historical_1_generic_1_negative_6_live_FIX5_reselection_required' -or
    [string]$qualified.evidencePath -cne
      'docs/quality/UAW-C33M-FIX8-FIX4-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md' -or
    -not $Fix8EvidenceExists
  ) {
    throw 'C33M FIX8 generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

$ticketId = 'UAW-C33M-FIX8-FIX4-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
$ticketPath = Resolve-C33MFix8File `
  -Path 'config/uaw-c33m-fix8-fix4-gate-generic-successor-replay-compatibility-ticket.json' `
  -Label 'FIX8 ticket'
Assert-C33MFix8 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    '806B59F65D4E9A7422F23D2F6C79010A01F2A6AA592359A754071B42019671F8'
) -Message 'FIX8 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33MFix8 -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.findingId -ceq
    'REG-20260816-2602-C33M-FIX4-GATE-BOUNDED-TO-FIX4-ACTIVE-SELECTION' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.ticketAndEvidenceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  -not [bool]$ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX8 identity or authority boundary changed.'

$scopePath = Resolve-C33MFix8File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$selectedManifestPath = Resolve-C33MFix8File `
  -Path ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath) `
  -Label 'selected ticket manifest'
$fix8EvidencePath = Join-Path $root `
  'docs/quality/UAW-C33M-FIX8-FIX4-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md'
$selectionMode = Get-C33MFix8SelectionMode `
  -Scope $scope `
  -SelectedTicketSha256 (
    Get-FileHash -Algorithm SHA256 -LiteralPath $selectedManifestPath
  ).Hash `
  -Fix8EvidenceExists (
    Test-Path -LiteralPath $fix8EvidencePath -PathType Leaf
  )
$scopeGate = Resolve-C33MFix8File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate `
  -CandidateId ([string]$scope.ticket.id) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C33MFix8File `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root |
  Out-Null

$fix4GatePath = Resolve-C33MFix8File `
  -Path 'scripts/check-uaw-c33m-fix4-public-review-fresh-process-auth-return-persistence.ps1' `
  -Label 'FIX4 gate'
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $fix4GatePath,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33MFix8 -Condition (@($parseErrors).Count -eq 0) `
  -Message 'FIX4 gate does not parse.'
$functions = @($ast.FindAll(
  {
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Get-C33MFix4GenericSuccessorMode'
  },
  $true
))
Assert-C33MFix8 -Condition ($functions.Count -eq 1) `
  -Message 'FIX4 generic successor function is missing or duplicated.'
Invoke-Expression $functions[0].Extent.Text

$fix4Id = 'UAW-C33M-FIX4-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-PERSISTENCE'
$fix4Hash = 'FB56B77AEE47D211D5924C568D72668B6BF150FE28AE5C0BEEFF10656F47025C'
$fix4State = 'source_repair_two_identical_cycles_qualified_registry_2570_flutter_496_3_backend_537_web_8_dual_host_FIX4_FIX6_FIX7_passed_source_unchanged_build_Play_OPPO_provider_email_and_external_actions_held'
$fixtureSha = 'FIXTURE-SELECTED-SHA'
function New-C33MFix8Fixture {
  param(
    [string]$CurrentId = $ticketId,
    [string]$TopId = $ticketId,
    [string]$SelectedId = $ticketId,
    [string]$SelectedSha = $fixtureSha,
    [string]$Fix4Hash = $fix4Hash,
    [string]$Fix4State = $fix4State
  )
  return [pscustomobject]@{
    ticket = [pscustomobject]@{ id = $TopId }
    preTicketSelectionCheckpoint = [pscustomobject]@{
      currentTicketId = $CurrentId
      selectedTicketAssessment = [pscustomobject]@{
        ticketId = $SelectedId
        manifestSha256 = $SelectedSha
      }
      priorC33MFix4SelectedTicketAssessment = [pscustomobject]@{
        ticketId = $fix4Id
        manifestPath = 'config/uaw-c33m-fix4-public-review-fresh-process-auth-return-persistence-ticket.json'
        manifestSha256 = $Fix4Hash
        implementationState = $Fix4State
        evidencePath = 'docs/quality/UAW-C33M-FIX4-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-PERSISTENCE-QUALIFICATION-20260816.md'
      }
    }
  }
}

$genericMode = Get-C33MFix4GenericSuccessorMode `
  -Scope (New-C33MFix8Fixture) `
  -SelectedTicketSha256 $fixtureSha `
  -Fix4EvidenceExists $true
Assert-C33MFix8 -Condition (
  $genericMode -ceq 'qualified_generic_successor_replay'
) -Message 'generic successor positive fixture failed.'
$historicalScope = New-C33MFix8Fixture `
  -CurrentId $fix4Id `
  -TopId $fix4Id `
  -SelectedId $fix4Id `
  -SelectedSha $fix4Hash
$historicalMode = Get-C33MFix4GenericSuccessorMode `
  -Scope $historicalScope `
  -SelectedTicketSha256 $fix4Hash `
  -Fix4EvidenceExists $true
Assert-C33MFix8 -Condition ($historicalMode -ceq 'FIX4_active') `
  -Message 'historical FIX4 mode changed.'

$negativeCases = @(
  [pscustomobject]@{ Scope = (New-C33MFix8Fixture -TopId 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix8Fixture -SelectedId 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix8Fixture); Sha = 'WRONG'; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix8Fixture -Fix4Hash 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix8Fixture -Fix4State 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix8Fixture); Sha = $fixtureSha; Evidence = $false }
)
$negativeRejected = 0
foreach ($case in $negativeCases) {
  try {
    [void](Get-C33MFix4GenericSuccessorMode `
      -Scope $case.Scope `
      -SelectedTicketSha256 $case.Sha `
      -Fix4EvidenceExists $case.Evidence)
  } catch {
    $negativeRejected++
  }
}
Assert-C33MFix8 -Condition ($negativeRejected -eq 6) `
  -Message 'one or more FIX4 negative fixtures passed.'

$liveOutput = & $fix4GatePath -RepositoryRoot $root
Assert-C33MFix8 -Condition (
  ($liveOutput -join [Environment]::NewLine).IndexOf(
    'selectionMode=qualified_generic_successor_replay',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'live FIX4 generic replay did not pass.'

Write-Output (
  'C33M FIX8 FIX4 generic successor replay passed: historical=1/1; ' +
  "selectionMode=$selectionMode; generic=1/1; negative=6/6; live=1/1; " +
  'runtimeBuildPlayDeviceProviderExternal=false; secretValuesObserved=false.'
)
