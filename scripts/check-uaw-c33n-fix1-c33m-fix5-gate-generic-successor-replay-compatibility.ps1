[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33NFix1 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33N FIX1 FIX5 generic successor replay rejected: $Message"
  }
}

function Resolve-C33NFix1File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33NFix1 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Get-C33NFix1CanonicalTextSha256 {
  param([Parameter(Mandatory)][string]$Path)
  $utf8 = [Text.UTF8Encoding]::new($false)
  $text = [IO.File]::ReadAllText($Path, $utf8).
    Replace("`r`n", "`n").Replace("`r", "`n")
  $sha256 = [Security.Cryptography.SHA256]::Create()
  try {
    return [BitConverter]::ToString(
      $sha256.ComputeHash($utf8.GetBytes($text))
    ).Replace('-', '')
  } finally { $sha256.Dispose() }
}

function Get-C33NFix1SelectionMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix1EvidenceExists
  )
  $fix1Id = 'UAW-C33N-FIX1-C33M-FIX5-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
  $fix1Hash = '39F5640A6C4EB8BA3D530DCC796E0A0E9007CB647DED8F62852E51245E69698F'
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  if (
    $currentId -cne [string]$Scope.ticket.id -or
    $currentId -cne [string]$checkpoint.selectedTicketAssessment.ticketId -or
    [string]$checkpoint.selectedTicketAssessment.manifestSha256 -cne
      $SelectedTicketSha256
  ) {
    throw 'C33N FIX1 current, top-level or selected ticket binding changed.'
  }
  if ($currentId -ceq $fix1Id) {
    if ($SelectedTicketSha256 -cne $fix1Hash) {
      throw 'C33N FIX1 direct selection ticket hash changed.'
    }
    return 'FIX1_active'
  }
  $qualified = $checkpoint.priorC33NFix1SelectedTicketAssessment
  if (
    [string]$qualified.ticketId -cne $fix1Id -or
    [string]$qualified.manifestPath -cne
      'config/uaw-c33n-fix1-c33m-fix5-gate-generic-successor-replay-compatibility-ticket.json' -or
    [string]$qualified.manifestSha256 -cne $fix1Hash -or
    [string]$qualified.implementationState -cne
      'FIX5_generic_successor_replay_qualified_dual_host_historical_1_generic_1_negative_6_live_C33N_reselection_required' -or
    [string]$qualified.evidencePath -cne
      'docs/quality/UAW-C33N-FIX1-C33M-FIX5-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md' -or
    -not $Fix1EvidenceExists
  ) {
    throw 'C33N FIX1 generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

$ticketId = 'UAW-C33N-FIX1-C33M-FIX5-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
$ticketPath = Resolve-C33NFix1File `
  -Path 'config/uaw-c33n-fix1-c33m-fix5-gate-generic-successor-replay-compatibility-ticket.json' `
  -Label 'FIX1 ticket'
Assert-C33NFix1 -Condition (
  (Get-C33NFix1CanonicalTextSha256 -Path $ticketPath) -ceq
    '39F5640A6C4EB8BA3D530DCC796E0A0E9007CB647DED8F62852E51245E69698F'
) -Message 'FIX1 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33NFix1 -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.findingId -ceq
    'REG-20260816-2605-C33M-FIX5-GATE-BOUNDED-TO-FIX5-ACTIVE-SELECTION' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.ticketAndEvidenceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  -not [bool]$ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX1 identity or authority boundary changed.'

$scopePath = Resolve-C33NFix1File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$selectedManifestPath = Resolve-C33NFix1File `
  -Path ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath) `
  -Label 'selected ticket manifest'
$fix1EvidencePath = Join-Path $root `
  'docs/quality/UAW-C33N-FIX1-C33M-FIX5-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md'
$selectionMode = Get-C33NFix1SelectionMode `
  -Scope $scope `
  -SelectedTicketSha256 (Get-C33NFix1CanonicalTextSha256 `
    -Path $selectedManifestPath) `
  -Fix1EvidenceExists (
    Test-Path -LiteralPath $fix1EvidencePath -PathType Leaf
  )
$scopeGate = Resolve-C33NFix1File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate `
  -CandidateId ([string]$scope.ticket.id) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C33NFix1File `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root |
  Out-Null

$fix5GatePath = Resolve-C33NFix1File `
  -Path 'scripts/check-uaw-c33m-fix5-public-review-firebase-passwordless-email-gateway.ps1' `
  -Label 'FIX5 gate'
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $fix5GatePath,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33NFix1 -Condition (@($parseErrors).Count -eq 0) `
  -Message 'FIX5 gate does not parse.'
$functions = @($ast.FindAll(
  {
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Get-C33MFix5GenericSuccessorMode'
  },
  $true
))
Assert-C33NFix1 -Condition ($functions.Count -eq 1) `
  -Message 'FIX5 generic successor function is missing or duplicated.'
Invoke-Expression $functions[0].Extent.Text
$boundaryFunctions = @($ast.FindAll(
  {
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Test-C33MFix5ExecutionBoundary'
  },
  $true
))
Assert-C33NFix1 -Condition ($boundaryFunctions.Count -eq 1) `
  -Message 'FIX5 execution-boundary function is missing or duplicated.'
Invoke-Expression $boundaryFunctions[0].Extent.Text

$fix5Id = 'UAW-C33M-FIX5-PUBLIC-REVIEW-FIREBASE-PASSWORDLESS-EMAIL-GATEWAY'
$fix5Hash = '05FD94BC8FF515700BBBFF20C2AE8748C20AC1C1AFC6167E8042C0748A7552DD'
$fix5State = 'source_repair_two_identical_cycles_qualified_registry_2574_flutter_501_3_backend_537_web_8_dual_host_FIX5_FIX6_FIX7_FIX8_passed_source_unchanged_build_Play_OPPO_provider_email_and_external_actions_held'
$emailLinkId = 'UAW-CODEX-EMAIL-LINK-AUTH-20260823'
$emailLinkManifestPath = 'docs/quality/UAW-CODEX-EMAIL-LINK-AUTH-20260823.md'
$emailLinkManifestSha = '9286F0DADB04D669B03921524CF4AB762B59B4AF6BF86305344B033F1979DC3A'
$fixtureSha = 'FIXTURE-SELECTED-SHA'
function New-C33NFix1Fixture {
  param(
    [string]$CurrentId = $ticketId,
    [string]$TopId = $ticketId,
    [string]$SelectedId = $ticketId,
    [string]$SelectedSha = $fixtureSha,
    [string]$SelectedManifestPath = 'FIXTURE-MANIFEST',
    [string]$Fix5Hash = $fix5Hash,
    [string]$Fix5State = $fix5State,
    [bool]$BackendWriteAuthorized = $false
  )
  return [pscustomobject]@{
    ticket = [pscustomobject]@{ id = $TopId }
    preTicketSelectionCheckpoint = [pscustomobject]@{
      currentTicketId = $CurrentId
      selectedTicketAssessment = [pscustomobject]@{
        ticketId = $SelectedId
        manifestSha256 = $SelectedSha
        manifestPath = $SelectedManifestPath
      }
      priorC33MFix5SelectedTicketAssessment = [pscustomobject]@{
        ticketId = $fix5Id
        manifestPath = 'config/uaw-c33m-fix5-public-review-firebase-passwordless-email-gateway-ticket.json'
        manifestSha256 = $Fix5Hash
        implementationState = $Fix5State
        evidencePath = 'docs/quality/UAW-C33M-FIX5-PUBLIC-REVIEW-FIREBASE-PASSWORDLESS-EMAIL-GATEWAY-QUALIFICATION-20260816.md'
      }
    }
    execution = [pscustomobject]@{
      testOrGateWriteAuthorized = $true
      runtimeWriteAuthorized = $true
      backendWriteAuthorized = $BackendWriteAuthorized
      externalServiceWriteAuthorized = $false
      liveEmailSendAuthorized = $false
      buildAuthorized = $false
      deviceInstallAuthorized = $false
    }
  }
}

$genericMode = Get-C33MFix5GenericSuccessorMode `
  -Scope (New-C33NFix1Fixture) `
  -SelectedTicketSha256 $fixtureSha `
  -Fix5EvidenceExists $true
Assert-C33NFix1 -Condition (
  $genericMode -ceq 'qualified_generic_successor_replay'
) -Message 'generic successor positive fixture failed.'
$historicalScope = New-C33NFix1Fixture `
  -CurrentId $fix5Id `
  -TopId $fix5Id `
  -SelectedId $fix5Id `
  -SelectedSha $fix5Hash
$historicalMode = Get-C33MFix5GenericSuccessorMode `
  -Scope $historicalScope `
  -SelectedTicketSha256 $fix5Hash `
  -Fix5EvidenceExists $true
Assert-C33NFix1 -Condition ($historicalMode -ceq 'FIX5_active') `
  -Message 'historical FIX5 mode changed.'

$emailLinkScope = New-C33NFix1Fixture `
  -CurrentId $emailLinkId -TopId $emailLinkId -SelectedId $emailLinkId `
  -SelectedSha $emailLinkManifestSha `
  -SelectedManifestPath $emailLinkManifestPath
Assert-C33NFix1 -Condition (
  Test-C33MFix5ExecutionBoundary `
    -Scope $emailLinkScope -SelectionMode 'qualified_generic_successor_replay'
) -Message 'current email-link FIX5 successor boundary failed.'
$wrongTicket = New-C33NFix1Fixture `
  -CurrentId 'WRONG' -TopId 'WRONG' -SelectedId 'WRONG' `
  -SelectedSha $emailLinkManifestSha -SelectedManifestPath $emailLinkManifestPath
$wrongHash = New-C33NFix1Fixture `
  -CurrentId $emailLinkId -TopId $emailLinkId -SelectedId $emailLinkId `
  -SelectedSha 'WRONG' -SelectedManifestPath $emailLinkManifestPath
$wrongAuthority = New-C33NFix1Fixture `
  -CurrentId $emailLinkId -TopId $emailLinkId -SelectedId $emailLinkId `
  -SelectedSha $emailLinkManifestSha -SelectedManifestPath $emailLinkManifestPath `
  -BackendWriteAuthorized $true
$boundaryRejected = 0
foreach ($case in @($wrongTicket, $wrongHash, $wrongAuthority)) {
  if (-not (Test-C33MFix5ExecutionBoundary `
      -Scope $case -SelectionMode 'qualified_generic_successor_replay')) {
    $boundaryRejected++
  }
}
Assert-C33NFix1 -Condition ($boundaryRejected -eq 3) `
  -Message 'one or more current email-link FIX5 boundary negatives passed.'

$negativeCases = @(
  [pscustomobject]@{ Scope = (New-C33NFix1Fixture -TopId 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33NFix1Fixture -SelectedId 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33NFix1Fixture); Sha = 'WRONG'; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33NFix1Fixture -Fix5Hash 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33NFix1Fixture -Fix5State 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33NFix1Fixture); Sha = $fixtureSha; Evidence = $false }
)
$negativeRejected = 0
foreach ($case in $negativeCases) {
  try {
    [void](Get-C33MFix5GenericSuccessorMode `
      -Scope $case.Scope `
      -SelectedTicketSha256 $case.Sha `
      -Fix5EvidenceExists $case.Evidence)
  } catch {
    $negativeRejected++
  }
}
Assert-C33NFix1 -Condition ($negativeRejected -eq 6) `
  -Message 'one or more FIX5 negative fixtures passed.'

$liveOutput = & $fix5GatePath -RepositoryRoot $root
Assert-C33NFix1 -Condition (
  ($liveOutput -join [Environment]::NewLine).IndexOf(
    'selectionMode=qualified_generic_successor_replay',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'live FIX5 generic replay did not pass.'

Write-Output (
  'C33N FIX1 FIX5 generic successor replay passed: historical=1/1; ' +
  "selectionMode=$selectionMode; generic=1/1; negative=6/6; " +
  "emailLinkBoundary=1/1; boundaryNegative=3/3; live=1/1; " +
  'runtimeBuildPlayDeviceProviderExternal=false; secretValuesObserved=false.'
)
