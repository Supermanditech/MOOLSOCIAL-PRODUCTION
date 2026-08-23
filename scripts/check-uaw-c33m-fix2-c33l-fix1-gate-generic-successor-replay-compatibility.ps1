[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33MFix2 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33M FIX2 FIX1 generic replay gate rejected: $Message"
  }
}

function Resolve-C33MFix2File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33MFix2 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

$ticketPath = Resolve-C33MFix2File `
  -Path 'config/uaw-c33m-fix2-c33l-fix1-gate-generic-successor-replay-compatibility-ticket.json' `
  -Label 'C33M FIX2 ticket'
Assert-C33MFix2 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    'AFF8F6A5741ECEBEF68B47F46CF47B77FBB961D4A3327F89F2C5C81EB35E7EED'
) -Message 'C33M FIX2 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33MFix2 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C33M-FIX2-C33L-FIX1-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY' -and
  [string]$ticket.findingId -ceq
    'REG-20260816-2571-C33L-FIX1-GATE-BOUNDED-PARENT-ONLY-C33M-SUCCESSOR-REPLAY-FAILURE' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.sourceTestAndGateRepairAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceAuthorized -and
  -not [bool]$ticket.authority.emailOrSmsAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, classification or held authority changed.'

$scopeGate = Resolve-C33MFix2File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate `
  -CandidateId ([string]$ticket.ticketId) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null

$fix1GatePath = Resolve-C33MFix2File `
  -Path 'scripts/check-uaw-c33l-fix1-private-dev-public-review-screen04-safe-boot-regression.ps1' `
  -Label 'FIX1 safe-boot gate'
$fix1Gate = Get-Content -Raw -LiteralPath $fix1GatePath
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $fix1GatePath,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33MFix2 -Condition (@($parseErrors).Count -eq 0) `
  -Message 'FIX1 gate does not parse.'
$bindingAst = @(
  $ast.FindAll(
    {
      param($node)
      $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
      $node.Name -ceq 'Get-C33LFix1GenericSuccessorMode'
    },
    $true
  )
)
Assert-C33MFix2 -Condition ($bindingAst.Count -eq 1) `
  -Message 'FIX1 generic successor function is missing or duplicated.'
Assert-C33MFix2 -Condition (
  $fix1Gate.IndexOf(
    "if (`$activeTicketId -ceq `$parentTicketId)",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $fix1Gate.IndexOf(
    "elseif (`$activeTicketId -ceq `$repairTicketId)",
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'historical C33L parent or FIX2 lifecycle branch was removed.'
Invoke-Expression $bindingAst[0].Extent.Text

$fix2Id = [string]$ticket.ticketId
$fix2Sha = 'C33M-FIX2-SHA'
function New-C33MFix2Fixture {
  param(
    [string]$CurrentId = $fix2Id,
    [string]$SelectedId = $fix2Id,
    [string]$SelectedSha = $fix2Sha,
    [string]$PriorFix1Sha =
      '40F11A474FE95C0303E29040ED2E2FC9F537766E527C2F01704A32DBB44A3B6F',
    [string]$PriorFix2State =
      'gate_parent_replay_compatibility_qualified_dual_host_repair_lifecycle_passed_parent_reselection_and_new_source_seal_required'
  )
  return [pscustomobject]@{
    ticket = [pscustomobject]@{ id = $CurrentId }
    preTicketSelectionCheckpoint = [pscustomobject]@{
      currentTicketId = $CurrentId
      selectedTicketAssessment = [pscustomobject]@{
        ticketId = $SelectedId
        manifestSha256 = $SelectedSha
      }
      priorC33LFix1SelectedTicketAssessment = [pscustomobject]@{
        ticketId =
          'UAW-C33L-FIX1-PRIVATE-DEV-PUBLIC-REVIEW-SCREEN04-SAFE-BOOT-REGRESSION'
        manifestSha256 = $PriorFix1Sha
        implementationState =
          'source_test_contract_repair_qualified_43_affected_passed_analyzer_clean_dual_host_gate_passed_parent_reselected'
      }
      priorC33LFix2SelectedTicketAssessment = [pscustomobject]@{
        ticketId = 'UAW-C33L-FIX2-FIX1-GATE-PARENT-REPLAY-COMPATIBILITY'
        manifestSha256 =
          '59C383D45D30FBCF26722FFAB851ED35ECA33621DDAD86D1765C6CD6F86ABCC0'
        implementationState = $PriorFix2State
      }
    }
  }
}

$successorMode = Get-C33LFix1GenericSuccessorMode `
  -Scope (New-C33MFix2Fixture) `
  -SelectedTicketSha256 $fix2Sha `
  -Fix1EvidenceExists $true `
  -Fix2EvidenceExists $true
Assert-C33MFix2 -Condition (
  $successorMode -ceq 'qualified_generic_successor_replay'
) -Message 'generic qualified-successor fixture failed.'

$negativeRejected = 0
$negativeCases = @(
  [pscustomobject]@{
    Scope = (New-C33MFix2Fixture -CurrentId 'WRONG')
    SelectedSha = $fix2Sha; Fix1Evidence = $true; Fix2Evidence = $true
  },
  [pscustomobject]@{
    Scope = (New-C33MFix2Fixture -PriorFix1Sha 'WRONG')
    SelectedSha = $fix2Sha; Fix1Evidence = $true; Fix2Evidence = $true
  },
  [pscustomobject]@{
    Scope = (New-C33MFix2Fixture -PriorFix2State 'not_qualified')
    SelectedSha = $fix2Sha; Fix1Evidence = $true; Fix2Evidence = $true
  },
  [pscustomobject]@{
    Scope = (New-C33MFix2Fixture)
    SelectedSha = $fix2Sha; Fix1Evidence = $true; Fix2Evidence = $false
  }
)
foreach ($case in $negativeCases) {
  try {
    [void](Get-C33LFix1GenericSuccessorMode `
      -Scope $case.Scope `
      -SelectedTicketSha256 $case.SelectedSha `
      -Fix1EvidenceExists $case.Fix1Evidence `
      -Fix2EvidenceExists $case.Fix2Evidence)
  } catch {
    $negativeRejected++
  }
}
Assert-C33MFix2 -Condition ($negativeRejected -eq 4) `
  -Message 'one or more generic-successor negative fixtures passed.'

$liveOutput = & $fix1GatePath -RepositoryRoot $root
Assert-C33MFix2 -Condition (
  ($liveOutput -join [Environment]::NewLine).IndexOf(
    'selectionMode=qualified_generic_successor_replay',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'live FIX2-selected safe-boot replay did not pass generically.'

Write-Output (
  'C33M FIX2 FIX1 generic successor replay gate passed: ' +
  'historicalModesPreserved=3; successor=1/1; negative=4/4; ' +
  'liveSuccessorReplay=true; buildPlayDeviceEmailExternal=false; ' +
  'secretValuesObserved=false.'
)
