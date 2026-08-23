[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33MFix1 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33M FIX1 FIX5 successor replay gate rejected: $Message"
  }
}

function Resolve-C33MFix1File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33MFix1 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

$ticketPath = Resolve-C33MFix1File `
  -Path 'config/uaw-c33m-fix1-c33l-fix5-gate-successor-replay-compatibility-ticket.json' `
  -Label 'C33M FIX1 ticket'
Assert-C33MFix1 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    '5BA0420B29288C3BAB861E2C6A9D0B4A81389341F091883C76F3F9B5F144BD89'
) -Message 'C33M FIX1 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33MFix1 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C33M-FIX1-C33L-FIX5-GATE-SUCCESSOR-REPLAY-COMPATIBILITY' -and
  [string]$ticket.findingId -ceq
    'REG-20260816-2567-C33L-FIX5-GATE-ACTIVE-TICKET-ONLY-SUCCESSOR-REPLAY-FAILURE' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.sourceTestAndGateRepairAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceAuthorized -and
  -not [bool]$ticket.authority.emailOrSmsAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, classification or held authority changed.'

$scopeGate = Resolve-C33MFix1File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate `
  -CandidateId ([string]$ticket.ticketId) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null

$fix5GatePath = Resolve-C33MFix1File `
  -Path 'scripts/check-uaw-c33l-fix5-founder-aab-launcher-postcleanup-result-retention.ps1' `
  -Label 'FIX5 gate'
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $fix5GatePath,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33MFix1 -Condition (@($parseErrors).Count -eq 0) `
  -Message 'FIX5 gate does not parse.'
$bindingAst = @(
  $ast.FindAll(
    {
      param($node)
      $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
      $node.Name -ceq 'Get-C33LFix5SelectionMode'
    },
    $true
  )
)
Assert-C33MFix1 -Condition ($bindingAst.Count -eq 1) `
  -Message 'FIX5 selection-binding function is missing or duplicated.'
Invoke-Expression $bindingAst[0].Extent.Text

$fix5Id =
  'UAW-C33L-FIX5-FOUNDER-AAB-LAUNCHER-POSTCLEANUP-RESULT-RETENTION'
$fix1Id = [string]$ticket.ticketId
$fix5Sha = 'FIX5-SHA'
$fix1Sha = 'FIX1-SHA'
function New-C33MFix1Fixture {
  param(
    [string]$CurrentId = $fix1Id,
    [string]$SelectedId = $fix1Id,
    [string]$SelectedSha = $fix1Sha,
    [string]$PriorSha = $fix5Sha,
    [string]$PriorState =
      'source_test_gate_repair_qualified_dual_host_future_launcher_binding_required_build_Play_OPPO_and_external_actions_held'
  )
  return [pscustomobject]@{
    preTicketSelectionCheckpoint = [pscustomobject]@{
      currentTicketId = $CurrentId
      selectedTicketAssessment = [pscustomobject]@{
        ticketId = $SelectedId
        manifestSha256 = $SelectedSha
      }
      priorC33LFix5SelectedTicketAssessment = [pscustomobject]@{
        ticketId = $fix5Id
        manifestSha256 = $PriorSha
        implementationState = $PriorState
      }
    }
  }
}

$activeFixture = New-C33MFix1Fixture `
  -CurrentId $fix5Id `
  -SelectedId $fix5Id `
  -SelectedSha $fix5Sha
$activeMode = Get-C33LFix5SelectionMode `
  -MvpState $activeFixture `
  -Fix5TicketSha256 $fix5Sha `
  -SelectedTicketSha256 $fix5Sha `
  -Fix5EvidenceExists $true
$successorFixture = New-C33MFix1Fixture
$successorMode = Get-C33LFix5SelectionMode `
  -MvpState $successorFixture `
  -Fix5TicketSha256 $fix5Sha `
  -SelectedTicketSha256 $fix1Sha `
  -Fix5EvidenceExists $true
Assert-C33MFix1 -Condition (
  $activeMode -ceq 'active_FIX5' -and
  $successorMode -ceq 'qualified_successor_replay'
) -Message 'active or qualified-successor selection mode failed.'

$negativeRejected = 0
$negativeCases = @(
  [pscustomobject]@{
    State = (New-C33MFix1Fixture -CurrentId 'WRONG')
    Fix5Sha = $fix5Sha; SelectedSha = $fix1Sha; Evidence = $true
  },
  [pscustomobject]@{
    State = (New-C33MFix1Fixture -PriorSha 'WRONG')
    Fix5Sha = $fix5Sha; SelectedSha = $fix1Sha; Evidence = $true
  },
  [pscustomobject]@{
    State = (New-C33MFix1Fixture -PriorState 'not_qualified')
    Fix5Sha = $fix5Sha; SelectedSha = $fix1Sha; Evidence = $true
  },
  [pscustomobject]@{
    State = (New-C33MFix1Fixture)
    Fix5Sha = $fix5Sha; SelectedSha = $fix1Sha; Evidence = $false
  }
)
foreach ($case in $negativeCases) {
  try {
    [void](Get-C33LFix5SelectionMode `
      -MvpState $case.State `
      -Fix5TicketSha256 $case.Fix5Sha `
      -SelectedTicketSha256 $case.SelectedSha `
      -Fix5EvidenceExists $case.Evidence)
  } catch {
    $negativeRejected++
  }
}
Assert-C33MFix1 -Condition ($negativeRejected -eq 4) `
  -Message 'one or more successor-binding negative fixtures passed.'

$liveOutput = & $fix5GatePath -RepositoryRoot $root
Assert-C33MFix1 -Condition (
  ($liveOutput -join [Environment]::NewLine).IndexOf(
    'selectionMode=qualified_successor_replay',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'live FIX1-selected FIX5 replay did not pass in successor mode.'

Write-Output (
  'C33M FIX1 FIX5 successor replay gate passed: active=1/1; ' +
  'successor=1/1; negative=4/4; liveSuccessorReplay=true; ' +
  'buildPlayDeviceEmailExternal=false; secretValuesObserved=false.'
)
