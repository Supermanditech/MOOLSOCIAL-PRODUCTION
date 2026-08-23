[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33LFix6 {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C33L FIX6 successor replay gate rejected: $Message" }
}

function Resolve-C33LFix6File {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33LFix6 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

$ticketPath = Resolve-C33LFix6File `
  -Path 'config/uaw-c33l-fix6-fix4-gate-successor-replay-compatibility-ticket.json' `
  -Label 'FIX6 ticket'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33LFix6 -Condition (
  [string]$ticket.ticketId -ceq 'UAW-C33L-FIX6-FIX4-GATE-SUCCESSOR-REPLAY-COMPATIBILITY' -and
  [string]$ticket.findingId -ceq 'REG-20260816-2562-C33L-FIX4-GATE-ACTIVE-TICKET-ONLY-SUCCESSOR-REPLAY-RISK' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.sourceTestAndGateRepairAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, classification or held authority changed.'

$scopeGate = Resolve-C33LFix6File -Path 'scripts/check-mvp-scope-gate-state.ps1' -Label 'MVP scope gate'
& $scopeGate `
  -CandidateId ([string]$ticket.ticketId) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null

$fix4GatePath = Resolve-C33LFix6File `
  -Path 'scripts/check-uaw-c33l-fix4-generic-aab-postbuild-aggregate-mirror-atomicity.ps1' `
  -Label 'FIX4 gate'
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $fix4GatePath,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33LFix6 -Condition (@($parseErrors).Count -eq 0) -Message 'FIX4 gate does not parse.'
$bindingAst = @(
  $ast.FindAll(
    { param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Get-C33LFix4SelectionMode' },
    $true
  )
)
Assert-C33LFix6 -Condition ($bindingAst.Count -eq 1) -Message 'FIX4 selection-binding function is missing or duplicated.'
Invoke-Expression $bindingAst[0].Extent.Text

$fix4Id = 'UAW-C33L-FIX4-GENERIC-AAB-POSTBUILD-AGGREGATE-MIRROR-ATOMICITY'
$fix6Id = [string]$ticket.ticketId
$fix4Sha = 'FIX4-SHA'
$fix6Sha = 'FIX6-SHA'
function New-C33LFix6Fixture {
  param(
    [string]$CurrentId = $fix6Id,
    [string]$SelectedId = $fix6Id,
    [string]$SelectedSha = $fix6Sha,
    [string]$PriorSha = $fix4Sha,
    [string]$PriorState = 'source_test_gate_repair_qualified_dual_host_parent_successor_required_build_Play_OPPO_and_external_actions_held'
  )
  return [pscustomobject]@{
    preTicketSelectionCheckpoint = [pscustomobject]@{
      currentTicketId = $CurrentId
      selectedTicketAssessment = [pscustomobject]@{
        ticketId = $SelectedId
        manifestSha256 = $SelectedSha
      }
      priorC33LFix4SelectedTicketAssessment = [pscustomobject]@{
        ticketId = $fix4Id
        manifestSha256 = $PriorSha
        implementationState = $PriorState
      }
    }
  }
}

$activeFixture = New-C33LFix6Fixture `
  -CurrentId $fix4Id `
  -SelectedId $fix4Id `
  -SelectedSha $fix4Sha
$activeMode = Get-C33LFix4SelectionMode `
  -MvpState $activeFixture `
  -Fix4TicketSha256 $fix4Sha `
  -SelectedTicketSha256 $fix4Sha `
  -Fix4EvidenceExists $true
$successorFixture = New-C33LFix6Fixture
$successorMode = Get-C33LFix4SelectionMode `
  -MvpState $successorFixture `
  -Fix4TicketSha256 $fix4Sha `
  -SelectedTicketSha256 $fix6Sha `
  -Fix4EvidenceExists $true
Assert-C33LFix6 -Condition (
  $activeMode -ceq 'active_FIX4' -and
  $successorMode -ceq 'qualified_successor_replay'
) -Message 'active or qualified-successor selection mode failed.'

$negativeRejected = 0
$negativeCases = @(
  [pscustomobject]@{ State = (New-C33LFix6Fixture -CurrentId 'WRONG'); Fix4Sha = $fix4Sha; SelectedSha = $fix6Sha; Evidence = $true },
  [pscustomobject]@{ State = (New-C33LFix6Fixture -PriorSha 'WRONG'); Fix4Sha = $fix4Sha; SelectedSha = $fix6Sha; Evidence = $true },
  [pscustomobject]@{ State = (New-C33LFix6Fixture -PriorState 'not_qualified'); Fix4Sha = $fix4Sha; SelectedSha = $fix6Sha; Evidence = $true },
  [pscustomobject]@{ State = (New-C33LFix6Fixture); Fix4Sha = $fix4Sha; SelectedSha = $fix6Sha; Evidence = $false }
)
foreach ($case in $negativeCases) {
  try {
    [void](Get-C33LFix4SelectionMode `
      -MvpState $case.State `
      -Fix4TicketSha256 $case.Fix4Sha `
      -SelectedTicketSha256 $case.SelectedSha `
      -Fix4EvidenceExists $case.Evidence)
  } catch {
    $negativeRejected++
  }
}
Assert-C33LFix6 -Condition ($negativeRejected -eq 4) -Message 'one or more successor-binding negative fixtures passed.'

$liveOutput = & $fix4GatePath -RepositoryRoot $root
Assert-C33LFix6 -Condition (
  ($liveOutput -join [Environment]::NewLine).IndexOf(
    'selectionMode=qualified_successor_replay',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'live FIX6-selected FIX4 replay did not pass in successor mode.'

Write-Output (
  'C33L FIX6 FIX4 successor replay gate passed: active=1/1; successor=1/1; ' +
  'negative=4/4; liveSuccessorReplay=true; buildPlayDeviceExternal=false; secretValuesObserved=false.'
)
