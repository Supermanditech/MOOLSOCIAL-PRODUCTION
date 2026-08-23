[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33MFix7 {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) {
    throw "C33M FIX7 C33K generic successor replay rejected: $Message"
  }
}

function Resolve-C33MFix7File {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33MFix7 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Get-C33MFix7CanonicalTextSha256 {
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

function Get-C33MFix7SelectionMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix7EvidenceExists
  )
  $fix7Id = 'UAW-C33M-FIX7-C33K-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
  $fix7Hash = 'C040D3CEEAE8EB4E46CE29FBD2250C16F006E3F48A53FA1587E88FF031671CFB'
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  if (
    $currentId -cne [string]$Scope.ticket.id -or
    $currentId -cne [string]$checkpoint.selectedTicketAssessment.ticketId -or
    [string]$checkpoint.selectedTicketAssessment.manifestSha256 -cne
      $SelectedTicketSha256
  ) {
    throw 'C33M FIX7 current, top-level or selected ticket binding changed.'
  }
  if ($currentId -ceq $fix7Id) {
    if ($SelectedTicketSha256 -cne $fix7Hash) {
      throw 'C33M FIX7 direct selection hash changed.'
    }
    return 'FIX7_active'
  }
  $fix7 = $checkpoint.priorC33MFix7SelectedTicketAssessment
  if (
    [string]$fix7.ticketId -cne $fix7Id -or
    [string]$fix7.manifestPath -cne
      'config/uaw-c33m-fix7-c33k-gate-generic-successor-replay-compatibility-ticket.json' -or
    [string]$fix7.manifestSha256 -cne $fix7Hash -or
    [string]$fix7.implementationState -cne
      'C33K_generic_successor_replay_qualified_dual_host_historical_1_generic_1_negative_6_live_Postwrite_FIX4_reselection_required' -or
    [string]$fix7.evidencePath -cne
      'docs/quality/UAW-C33M-FIX7-C33K-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md' -or
    -not $Fix7EvidenceExists
  ) {
    throw 'C33M FIX7 generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

$ticketId = 'UAW-C33M-FIX7-C33K-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
$ticketPath = Resolve-C33MFix7File `
  -Path 'config/uaw-c33m-fix7-c33k-gate-generic-successor-replay-compatibility-ticket.json' `
  -Label 'FIX7 ticket'
Assert-C33MFix7 -Condition (
  (Get-C33MFix7CanonicalTextSha256 -Path $ticketPath) -ceq
    'C040D3CEEAE8EB4E46CE29FBD2250C16F006E3F48A53FA1587E88FF031671CFB'
) -Message 'FIX7 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33MFix7 -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.findingId -ceq
    'REG-20260816-2595-C33K-LIVE-READINESS-GATE-BOUNDED-TO-HISTORICAL-TICKET' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.gateSourceWriteAuthorized -and
  [bool]$ticket.authority.gateTestWriteAuthorized -and
  -not [bool]$ticket.authority.mobileRuntimeSourceWriteAuthorized -and
  -not [bool]$ticket.authority.firebaseOrProviderWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.externalServiceAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX7 identity or authority boundary changed.'

$scopePath = Resolve-C33MFix7File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$selectedManifestPath = Resolve-C33MFix7File `
  -Path ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath) `
  -Label 'selected ticket manifest'
$fix7EvidencePath = Join-Path $root `
  'docs/quality/UAW-C33M-FIX7-C33K-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md'
$selectionMode = Get-C33MFix7SelectionMode `
  -Scope $scope `
  -SelectedTicketSha256 (Get-C33MFix7CanonicalTextSha256 `
    -Path $selectedManifestPath) `
  -Fix7EvidenceExists (Test-Path -LiteralPath $fix7EvidencePath -PathType Leaf)
$scopeGate = Resolve-C33MFix7File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate `
  -CandidateId ([string]$scope.ticket.id) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C33MFix7File `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root |
  Out-Null

$c33kGatePath = Resolve-C33MFix7File `
  -Path 'scripts/check-uaw-c33k-firebase-passwordless-email-link-live-readiness.ps1' `
  -Label 'C33K gate'
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $c33kGatePath,
  [ref]$tokens,
  [ref]$parseErrors
)
Assert-C33MFix7 -Condition (@($parseErrors).Count -eq 0) `
  -Message 'C33K gate does not parse.'
$functions = @($ast.FindAll(
  {
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Get-C33KGenericSuccessorMode'
  },
  $true
))
Assert-C33MFix7 -Condition ($functions.Count -eq 1) `
  -Message 'C33K generic successor function is missing or duplicated.'
Invoke-Expression $functions[0].Extent.Text
$boundaryFunctions = @($ast.FindAll(
  {
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Test-C33KExecutionBoundary'
  },
  $true
))
Assert-C33MFix7 -Condition ($boundaryFunctions.Count -eq 1) `
  -Message 'C33K execution-boundary function is missing or duplicated.'
Invoke-Expression $boundaryFunctions[0].Extent.Text

$c33kId = 'UAW-C33K-FIREBASE-PASSWORDLESS-EMAIL-LINK-LIVE-READINESS'
$emailLinkId = 'UAW-CODEX-EMAIL-LINK-AUTH-20260823'
$emailLinkManifestPath = 'docs/quality/UAW-CODEX-EMAIL-LINK-AUTH-20260823.md'
$emailLinkManifestSha = '9286F0DADB04D669B03921524CF4AB762B59B4AF6BF86305344B033F1979DC3A'
$fixtureSha = 'FIXTURE-SELECTED-SHA'
function New-C33MFix7Fixture {
  param(
    [string]$CurrentId = $ticketId,
    [string]$TopId = $ticketId,
    [string]$SelectedId = $ticketId,
    [string]$SelectedSha = $fixtureSha,
    [string]$SelectedManifestPath = 'FIXTURE-MANIFEST',
    [string]$C33KHash = '2104B114818AD7DE29671B0DFD14FF7F3E6510A6F5E95E9148CA5C5674C192FF',
    [string]$C33KState = 'live_readiness_qualified_two_exact_Firebase_Authentication_writes_consumed_provider_domain_and_dual_origin_App_Links_readbacks_passed_live_email_release_and_device_held',
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
      priorC33KSelectedTicketAssessment = [pscustomobject]@{
        ticketId = $c33kId
        manifestPath = 'config/uaw-c33k-firebase-passwordless-email-link-live-readiness-ticket.json'
        manifestSha256 = $C33KHash
        implementationState = $C33KState
        evidencePath = 'docs/quality/UAW-C33K-FIREBASE-PASSWORDLESS-EMAIL-LINK-LIVE-READINESS-QUALIFICATION-20260815.md'
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
      secretValueAccessAuthorized = $false
    }
  }
}

$genericMode = Get-C33KGenericSuccessorMode `
  -Scope (New-C33MFix7Fixture) `
  -SelectedTicketSha256 $fixtureSha `
  -C33KEvidenceExists $true
Assert-C33MFix7 -Condition (
  $genericMode -ceq 'qualified_generic_successor_replay'
) -Message 'generic successor positive fixture failed.'
$historicalScope = New-C33MFix7Fixture `
  -CurrentId $c33kId `
  -TopId $c33kId `
  -SelectedId $c33kId `
  -SelectedSha '2104B114818AD7DE29671B0DFD14FF7F3E6510A6F5E95E9148CA5C5674C192FF'
$historicalMode = Get-C33KGenericSuccessorMode `
  -Scope $historicalScope `
  -SelectedTicketSha256 '2104B114818AD7DE29671B0DFD14FF7F3E6510A6F5E95E9148CA5C5674C192FF' `
  -C33KEvidenceExists $true
Assert-C33MFix7 -Condition ($historicalMode -ceq 'C33K_active') `
  -Message 'historical C33K mode changed.'

$emailLinkScope = New-C33MFix7Fixture `
  -CurrentId $emailLinkId -TopId $emailLinkId -SelectedId $emailLinkId `
  -SelectedSha $emailLinkManifestSha `
  -SelectedManifestPath $emailLinkManifestPath
Assert-C33MFix7 -Condition (
  Test-C33KExecutionBoundary `
    -Scope $emailLinkScope -SelectionMode 'qualified_generic_successor_replay'
) -Message 'current email-link C33K successor boundary failed.'
$wrongTicket = New-C33MFix7Fixture `
  -CurrentId 'WRONG' -TopId 'WRONG' -SelectedId 'WRONG' `
  -SelectedSha $emailLinkManifestSha -SelectedManifestPath $emailLinkManifestPath
$wrongHash = New-C33MFix7Fixture `
  -CurrentId $emailLinkId -TopId $emailLinkId -SelectedId $emailLinkId `
  -SelectedSha 'WRONG' -SelectedManifestPath $emailLinkManifestPath
$wrongAuthority = New-C33MFix7Fixture `
  -CurrentId $emailLinkId -TopId $emailLinkId -SelectedId $emailLinkId `
  -SelectedSha $emailLinkManifestSha -SelectedManifestPath $emailLinkManifestPath `
  -BackendWriteAuthorized $true
$boundaryRejected = 0
foreach ($case in @($wrongTicket, $wrongHash, $wrongAuthority)) {
  if (-not (Test-C33KExecutionBoundary `
      -Scope $case -SelectionMode 'qualified_generic_successor_replay')) {
    $boundaryRejected++
  }
}
Assert-C33MFix7 -Condition ($boundaryRejected -eq 3) `
  -Message 'one or more current email-link C33K boundary negatives passed.'

$negativeCases = @(
  [pscustomobject]@{ Scope = (New-C33MFix7Fixture -TopId 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix7Fixture -SelectedId 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix7Fixture); Sha = 'WRONG'; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix7Fixture -C33KHash 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix7Fixture -C33KState 'WRONG'); Sha = $fixtureSha; Evidence = $true },
  [pscustomobject]@{ Scope = (New-C33MFix7Fixture); Sha = $fixtureSha; Evidence = $false }
)
$negativeRejected = 0
foreach ($case in $negativeCases) {
  try {
    [void](Get-C33KGenericSuccessorMode `
      -Scope $case.Scope `
      -SelectedTicketSha256 $case.Sha `
      -C33KEvidenceExists $case.Evidence)
  } catch {
    $negativeRejected++
  }
}
Assert-C33MFix7 -Condition ($negativeRejected -eq 6) `
  -Message 'one or more C33K negative fixtures passed.'

$liveOutput = & $c33kGatePath -Phase Postwrite -RepositoryRoot $root
Assert-C33MFix7 -Condition (
  ($liveOutput -join [Environment]::NewLine).IndexOf(
    'selectionMode=qualified_generic_successor_replay',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'live C33K Postwrite generic replay did not pass.'

Write-Output (
  'C33M FIX7 C33K generic successor replay passed: historical=1/1; ' +
  "selectionMode=$selectionMode; generic=1/1; negative=6/6; " +
  "emailLinkBoundary=1/1; boundaryNegative=3/3; livePostwrite=1/1; " +
  'providerWrites=0; buildPlayDeviceExternal=false; secretValuesObserved=false.'
)
