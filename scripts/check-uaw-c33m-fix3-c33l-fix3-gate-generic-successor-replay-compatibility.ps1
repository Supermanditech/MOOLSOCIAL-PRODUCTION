[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33MFix3 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33M FIX3 C33L FIX3 generic replay gate rejected: $Message"
  }
}

function Resolve-C33MFix3File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33MFix3 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

$ticketPath = Resolve-C33MFix3File `
  -Path 'config/uaw-c33m-fix3-c33l-fix3-gate-generic-successor-replay-compatibility-ticket.json' `
  -Label 'C33M FIX3 ticket'
Assert-C33MFix3 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    '2722BB4C6F167D4481A98BE638140564135B210F82CD56E2515C77B5BA5E6A53'
) -Message 'C33M FIX3 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33MFix3 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C33M-FIX3-C33L-FIX3-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY' -and
  [string]$ticket.findingId -ceq
    'REG-20260816-2573-C33L-FIX3-GATE-BOUNDED-PARENT-ONLY-C33M-SUCCESSOR-BLOCKER' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.sourceTestAndGateRepairAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceAuthorized -and
  -not [bool]$ticket.authority.emailOrSmsAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, classification or held authority changed.'

$scopeGate = Resolve-C33MFix3File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate `
  -CandidateId ([string]$ticket.ticketId) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null

$fix3GatePath = Resolve-C33MFix3File `
  -Path 'scripts/check-uaw-c33l-fix3-authoritative-flutter-null-event-classification.ps1' `
  -Label 'C33L FIX3 gate'
$fix3Gate = Get-Content -Raw -LiteralPath $fix3GatePath
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $fix3GatePath,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33MFix3 -Condition (@($parseErrors).Count -eq 0) `
  -Message 'C33L FIX3 gate does not parse.'
$bindingAst = @(
  $ast.FindAll(
    {
      param($node)
      $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
      $node.Name -ceq 'Get-C33LFix3GenericSuccessorMode'
    },
    $true
  )
)
Assert-C33MFix3 -Condition ($bindingAst.Count -eq 1) `
  -Message 'C33L FIX3 generic successor function is missing or duplicated.'
Assert-C33MFix3 -Condition (
  $fix3Gate.IndexOf(
    "if (`$activeTicketId -ceq `$ticketId)",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $fix3Gate.IndexOf(
    "elseif (`$activeTicketId -ceq `$parentTicketId)",
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'historical FIX3 child or C33L parent lifecycle branch was removed.'
Invoke-Expression $bindingAst[0].Extent.Text

$fix3Id = [string]$ticket.ticketId
$fix3Sha = 'C33M-FIX3-SHA'
function New-C33MFix3Fixture {
  param(
    [string]$CurrentId = $fix3Id,
    [string]$TopId = $fix3Id,
    [string]$SelectedId = $fix3Id,
    [string]$SelectedSha = $fix3Sha,
    [string]$PriorFix3Sha =
      '60FBA619B2DB3C71FF66208D4B8FA175CD13FC8A9344BCE85E9879F184C9B757',
    [string]$PriorFix3State =
      'runner_null_and_blank_classification_qualified_dual_host_behavioral_gate_passed_parent_reselection_and_new_source_seal_required'
  )
  return [pscustomobject]@{
    ticket = [pscustomobject]@{ id = $TopId }
    preTicketSelectionCheckpoint = [pscustomobject]@{
      currentTicketId = $CurrentId
      selectedTicketAssessment = [pscustomobject]@{
        ticketId = $SelectedId
        manifestSha256 = $SelectedSha
      }
      priorC33LFix3SelectedTicketAssessment = [pscustomobject]@{
        ticketId = 'UAW-C33L-FIX3-AUTHORITATIVE-FLUTTER-NULL-EVENT-CLASSIFICATION'
        manifestPath = 'config/uaw-c33l-fix3-authoritative-flutter-null-event-classification-ticket.json'
        manifestSha256 = $PriorFix3Sha
        implementationState = $PriorFix3State
        evidencePath = 'docs/quality/UAW-C33L-FIX3-AUTHORITATIVE-FLUTTER-NULL-EVENT-CLASSIFICATION-QUALIFICATION-20260816.md'
      }
    }
  }
}

$successorMode = Get-C33LFix3GenericSuccessorMode `
  -Scope (New-C33MFix3Fixture) `
  -SelectedTicketSha256 $fix3Sha `
  -Fix3EvidenceExists $true
Assert-C33MFix3 -Condition (
  $successorMode -ceq 'qualified_generic_successor_replay'
) -Message 'generic qualified-successor fixture failed.'

$negativeRejected = 0
$negativeCases = @(
  [pscustomobject]@{
    Scope = (New-C33MFix3Fixture -CurrentId 'WRONG')
    SelectedSha = $fix3Sha; Evidence = $true
  },
  [pscustomobject]@{
    Scope = (New-C33MFix3Fixture -TopId 'WRONG')
    SelectedSha = $fix3Sha; Evidence = $true
  },
  [pscustomobject]@{
    Scope = (New-C33MFix3Fixture)
    SelectedSha = 'WRONG'; Evidence = $true
  },
  [pscustomobject]@{
    Scope = (New-C33MFix3Fixture -PriorFix3Sha 'WRONG')
    SelectedSha = $fix3Sha; Evidence = $true
  },
  [pscustomobject]@{
    Scope = (New-C33MFix3Fixture -PriorFix3State 'not_qualified')
    SelectedSha = $fix3Sha; Evidence = $true
  },
  [pscustomobject]@{
    Scope = (New-C33MFix3Fixture)
    SelectedSha = $fix3Sha; Evidence = $false
  }
)
foreach ($case in $negativeCases) {
  try {
    [void](Get-C33LFix3GenericSuccessorMode `
      -Scope $case.Scope `
      -SelectedTicketSha256 $case.SelectedSha `
      -Fix3EvidenceExists $case.Evidence)
  } catch {
    $negativeRejected++
  }
}
Assert-C33MFix3 -Condition ($negativeRejected -eq 6) `
  -Message 'one or more generic-successor negative fixtures passed.'

$liveOutput = & $fix3GatePath -RepositoryRoot $root
Assert-C33MFix3 -Condition (
  ($liveOutput -join [Environment]::NewLine).IndexOf(
    'selectionMode=qualified_generic_successor_replay',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'live FIX3-selected authoritative classification replay did not pass generically.'

Write-Output (
  'C33M FIX3 C33L FIX3 generic successor replay gate passed: ' +
  'historicalModesPreserved=2; successor=1/1; negative=6/6; ' +
  'liveSuccessorReplay=true; buildPlayDeviceEmailExternal=false; ' +
  'secretValuesObserved=false.'
)
