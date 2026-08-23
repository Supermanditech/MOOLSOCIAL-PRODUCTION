[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33MFix6 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33M FIX6 C33J gate trilogy replay rejected: $Message"
  }
}

function Resolve-C33MFix6File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33MFix6 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Get-C33MFix6CanonicalTextSha256 {
  param([Parameter(Mandatory)][string]$Path)

  $utf8 = [Text.UTF8Encoding]::new($false)
  $text = [IO.File]::ReadAllText($Path, $utf8).
    Replace("`r`n", "`n").
    Replace("`r", "`n")
  $sha256 = [Security.Cryptography.SHA256]::Create()
  try {
    return [BitConverter]::ToString(
      $sha256.ComputeHash($utf8.GetBytes($text))
    ).Replace('-', '')
  } finally {
    $sha256.Dispose()
  }
}

function Get-C33MFix6SelectionMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix6EvidenceExists
  )
  $fix6Id = 'UAW-C33M-FIX6-C33J-GATE-TRILOGY-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
  $fix6Hash = '0C395D2A7F73A938D320D637B6ED721328E72269BD22EC94BF51012AA8892431'
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  if (
    $currentId -cne [string]$Scope.ticket.id -or
    $currentId -cne [string]$checkpoint.selectedTicketAssessment.ticketId -or
    [string]$checkpoint.selectedTicketAssessment.manifestSha256 -cne
      $SelectedTicketSha256
  ) {
    throw 'C33M FIX6 current, top-level or selected ticket binding changed.'
  }
  if ($currentId -ceq $fix6Id) {
    if ($SelectedTicketSha256 -cne $fix6Hash) {
      throw 'C33M FIX6 direct selection hash changed.'
    }
    return 'FIX6_active'
  }
  $fix6 = $checkpoint.priorC33MFix6SelectedTicketAssessment
  if (
    [string]$fix6.ticketId -cne $fix6Id -or
    [string]$fix6.manifestPath -cne
      'config/uaw-c33m-fix6-c33j-gate-trilogy-generic-successor-replay-compatibility-ticket.json' -or
    [string]$fix6.manifestSha256 -cne $fix6Hash -or
    [string]$fix6.implementationState -cne
      'gate_trilogy_generic_successor_replay_qualified_dual_host_historical_6_generic_3_negative_21_live_3_FIX4_reselection_required' -or
    [string]$fix6.evidencePath -cne
      'docs/quality/UAW-C33M-FIX6-C33J-GATE-TRILOGY-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md' -or
    -not $Fix6EvidenceExists
  ) {
    throw 'C33M FIX6 generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

$ticketId = 'UAW-C33M-FIX6-C33J-GATE-TRILOGY-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
$ticketPath = Resolve-C33MFix6File `
  -Path 'config/uaw-c33m-fix6-c33j-gate-trilogy-generic-successor-replay-compatibility-ticket.json' `
  -Label 'FIX6 ticket'
$ticketHash = Get-C33MFix6CanonicalTextSha256 -Path $ticketPath
Assert-C33MFix6 -Condition (
  $ticketHash -ceq '0C395D2A7F73A938D320D637B6ED721328E72269BD22EC94BF51012AA8892431'
) -Message 'FIX6 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33MFix6 -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  @($ticket.findingIds).Count -eq 2 -and
  @($ticket.findingIds) -ccontains
    'REG-20260816-2590-C33J-PARENT-GATE-BOUNDED-TO-PARENT-FIX1-FIX2-SELECTIONS' -and
  @($ticket.findingIds) -ccontains
    'REG-20260816-2592-C33J-FIX1-FIX2-GATES-BOUNDED-TO-HISTORICAL-SELECTIONS' -and
  [bool]$ticket.authority.gateSourceWriteAuthorized -and
  [bool]$ticket.authority.gateTestWriteAuthorized -and
  -not [bool]$ticket.authority.mobileRuntimeSourceWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX6 identity, findings or authority boundary changed.'

$scopeGate = Resolve-C33MFix6File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
$scopePath = Resolve-C33MFix6File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$activeScope = $scope
$selectedManifestPath = Resolve-C33MFix6File `
  -Path ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath) `
  -Label 'selected ticket manifest'
$fix6EvidencePath = Resolve-C33MFix6File `
  -Path 'docs/quality/UAW-C33M-FIX6-C33J-GATE-TRILOGY-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY-QUALIFICATION-20260816.md' `
  -Label 'FIX6 qualification evidence'
$selectionMode = Get-C33MFix6SelectionMode `
  -Scope $scope `
  -SelectedTicketSha256 (Get-C33MFix6CanonicalTextSha256 `
    -Path $selectedManifestPath) `
  -Fix6EvidenceExists (Test-Path -LiteralPath $fix6EvidencePath -PathType Leaf)
& $scopeGate `
  -CandidateId ([string]$scope.ticket.id) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C33MFix6File `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root |
  Out-Null

$gateSpecs = @(
  [pscustomobject]@{
    Path = 'scripts/check-uaw-c33j-screen03-passwordless-email-link-native-parity.ps1'
    Function = 'Get-C33JGenericSuccessorMode'
  },
  [pscustomobject]@{
    Path = 'scripts/check-uaw-c33j-fix1-foreground-email-link-return-handoff.ps1'
    Function = 'Get-C33JFix1GenericSuccessorMode'
  },
  [pscustomobject]@{
    Path = 'scripts/check-uaw-c33j-fix2-android-email-link-same-device-exact-return.ps1'
    Function = 'Get-C33JFix2GenericSuccessorMode'
  }
)
foreach ($spec in $gateSpecs) {
  $path = Resolve-C33MFix6File -Path $spec.Path -Label 'C33J gate'
  $tokens = $null
  $parseErrors = $null
  $ast = [Management.Automation.Language.Parser]::ParseFile(
    $path,
    [ref]$tokens,
    [ref]$parseErrors
  )
  Assert-C33MFix6 -Condition (@($parseErrors).Count -eq 0) `
    -Message "$($spec.Function) owner does not parse."
  $functions = @($ast.FindAll(
    {
      param($node)
      $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
      $node.Name -ceq $spec.Function
    },
    $true
  ))
  Assert-C33MFix6 -Condition ($functions.Count -eq 1) `
    -Message "$($spec.Function) is missing or duplicated."
  Invoke-Expression $functions[0].Extent.Text
}

$primaryGatePath = Resolve-C33MFix6File `
  -Path 'scripts/check-uaw-c33j-screen03-passwordless-email-link-native-parity.ps1' `
  -Label 'primary C33J gate'
$primaryTokens = $null
$primaryParseErrors = $null
$primaryAst = [Management.Automation.Language.Parser]::ParseFile(
  $primaryGatePath,
  [ref]$primaryTokens,
  [ref]$primaryParseErrors
)
Assert-C33MFix6 -Condition (@($primaryParseErrors).Count -eq 0) `
  -Message 'primary C33J execution-boundary owner does not parse.'
$boundaryFunctions = @($primaryAst.FindAll(
  {
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Test-C33JExecutionBoundary'
  },
  $true
))
Assert-C33MFix6 -Condition ($boundaryFunctions.Count -eq 1) `
  -Message 'Test-C33JExecutionBoundary is missing or duplicated.'
Invoke-Expression $boundaryFunctions[0].Extent.Text

$parentId = 'UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY'
$fix1Id = 'UAW-C33J-FIX1-FOREGROUND-EMAIL-LINK-RETURN-HANDOFF'
$fix2Id = 'UAW-C33J-FIX2-ANDROID-EMAIL-LINK-SAME-DEVICE-EXACT-RETURN'
$emailLinkId = 'UAW-CODEX-EMAIL-LINK-AUTH-20260823'
$emailLinkManifestPath = 'docs/quality/UAW-CODEX-EMAIL-LINK-AUTH-20260823.md'
$emailLinkManifestSha = '9286F0DADB04D669B03921524CF4AB762B59B4AF6BF86305344B033F1979DC3A'
$fixtureSha = 'FIXTURE-SELECTED-SHA'

function New-C33MFix6Fixture {
  param(
    [string]$CurrentId = $ticketId,
    [string]$TopId = $ticketId,
    [string]$SelectedId = $ticketId,
    [string]$SelectedSha = $fixtureSha,
    [string]$SelectedManifestPath = 'FIXTURE-MANIFEST',
    [string]$ParentHash = 'C0181F1B56DCC1D070FD9F8E8048800F694C41007FBAEAE26219C7B2E764A00B',
    [string]$Fix1State = 'source_qualified_3_focused_68_affected_whole_mobile_analyzer_clean_dual_host_gates_passed_live_external_release_and_device_acceptance_held',
    [string]$Fix2State = 'fix10_current_Firebase_Hosting_email_action_flow_local_source_qualified_default_linkDomain_omitted_latest_115_combined_focused_auth_and_analyzer_clean_live_email_external_release_and_device_acceptance_held',
    [bool]$RuntimeWriteAuthorized = $true,
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
      priorC33JSelectedTicketAssessment = [pscustomobject]@{
        ticketId = $parentId
        manifestPath = 'config/uaw-c33j-screen03-passwordless-email-link-native-parity-ticket.json'
        manifestSha256 = $ParentHash
        implementationState = 'native_v5_cold_and_foreground_email_link_source_qualified_10_parent_3_FIX1_68_affected_whole_mobile_analyzer_clean_dual_host_gates_passed_live_external_release_and_device_acceptance_held'
        evidencePath = 'docs/quality/UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY-QUALIFICATION-20260815.md'
      }
      priorC33JFix1SelectedTicketAssessment = [pscustomobject]@{
        ticketId = $fix1Id
        manifestPath = 'config/uaw-c33j-fix1-foreground-email-link-return-handoff-ticket.json'
        manifestSha256 = '8C2B5075F2CFD4E711EA24A2064D789A8ACF2DB974C8B5211B3A4FE065EC261D'
        implementationState = $Fix1State
        evidencePath = 'docs/quality/UAW-C33J-FIX1-FOREGROUND-EMAIL-LINK-RETURN-HANDOFF-QUALIFICATION-20260815.md'
      }
      priorC33JFix2SelectedTicketAssessment = [pscustomobject]@{
        ticketId = $fix2Id
        manifestPath = 'config/uaw-c33j-fix2-android-email-link-same-device-exact-return-ticket.json'
        manifestSha256 = '0DEF2CC05C15B8B6BD3113F4078B1EC2BEC2276010804A274C79050D88ECCA31'
        implementationState = $Fix2State
        evidencePath = 'docs/quality/UAW-C33J-FIX2-ANDROID-EMAIL-LINK-SAME-DEVICE-EXACT-RETURN-QUALIFICATION-20260815.md'
      }
    }
    execution = [pscustomobject]@{
      testOrGateWriteAuthorized = $true
      runtimeWriteAuthorized = $RuntimeWriteAuthorized
      backendWriteAuthorized = $BackendWriteAuthorized
      externalServiceWriteAuthorized = $false
      firebaseEmailPasswordAndEmailLinkEnablementAuthorizedOnce = $false
      firebaseMoolSocialAuthorizedDomainAdditionAuthorizedOnce = $false
      hostingDeploymentAuthorized = $false
      liveEmailSendAuthorized = $false
      buildAuthorized = $false
      deviceInstallAuthorized = $false
    }
  }
}

$genericPassed = 0
foreach ($functionName in @(
  'Get-C33JGenericSuccessorMode',
  'Get-C33JFix1GenericSuccessorMode',
  'Get-C33JFix2GenericSuccessorMode'
)) {
  $mode = & $functionName `
    -Scope (New-C33MFix6Fixture) `
    -SelectedTicketSha256 $fixtureSha `
    -ParentEvidenceExists $true `
    -Fix1EvidenceExists $true `
    -Fix2EvidenceExists $true
  if ($mode -ceq 'qualified_generic_successor_replay') { $genericPassed++ }
}
Assert-C33MFix6 -Condition ($genericPassed -eq 3) `
  -Message 'one or more generic successor positive fixtures failed.'

$emailLinkScope = New-C33MFix6Fixture `
  -CurrentId $emailLinkId `
  -TopId $emailLinkId `
  -SelectedId $emailLinkId `
  -SelectedSha $emailLinkManifestSha `
  -SelectedManifestPath $emailLinkManifestPath `
  -BackendWriteAuthorized $false
Assert-C33MFix6 -Condition (
  Test-C33JExecutionBoundary `
    -Scope $emailLinkScope `
    -SelectionMode 'qualified_generic_successor_replay'
) -Message 'current email-link successor execution boundary failed.'

$wrongTicketScope = New-C33MFix6Fixture `
  -CurrentId 'WRONG' `
  -TopId 'WRONG' `
  -SelectedId 'WRONG' `
  -SelectedSha $emailLinkManifestSha `
  -SelectedManifestPath $emailLinkManifestPath `
  -BackendWriteAuthorized $false
$wrongHashScope = New-C33MFix6Fixture `
  -CurrentId $emailLinkId `
  -TopId $emailLinkId `
  -SelectedId $emailLinkId `
  -SelectedSha 'WRONG' `
  -SelectedManifestPath $emailLinkManifestPath `
  -BackendWriteAuthorized $false
$wrongBackendScope = New-C33MFix6Fixture `
  -CurrentId $emailLinkId `
  -TopId $emailLinkId `
  -SelectedId $emailLinkId `
  -SelectedSha $emailLinkManifestSha `
  -SelectedManifestPath $emailLinkManifestPath `
  -BackendWriteAuthorized $true
$boundaryNegativeCases = @(
  $wrongTicketScope,
  $wrongHashScope,
  $wrongBackendScope
)
$boundaryNegativeRejected = 0
foreach ($case in $boundaryNegativeCases) {
  if (-not (Test-C33JExecutionBoundary `
      -Scope $case `
      -SelectionMode 'qualified_generic_successor_replay')) {
    $boundaryNegativeRejected++
  }
}
Assert-C33MFix6 -Condition ($boundaryNegativeRejected -eq 3) `
  -Message 'one or more email-link successor boundary negative fixtures passed.'

$historicalModes = @(
  [pscustomobject]@{
    Function = 'Get-C33JGenericSuccessorMode'; Current = $parentId
    Expected = 'parent_active'
  },
  [pscustomobject]@{
    Function = 'Get-C33JGenericSuccessorMode'; Current = $fix1Id
    Expected = 'FIX1_active'
  },
  [pscustomobject]@{
    Function = 'Get-C33JGenericSuccessorMode'; Current = $fix2Id
    Expected = 'FIX2_active'
  },
  [pscustomobject]@{
    Function = 'Get-C33JFix1GenericSuccessorMode'; Current = $fix1Id
    Expected = 'FIX1_active'
  },
  [pscustomobject]@{
    Function = 'Get-C33JFix1GenericSuccessorMode'; Current = $fix2Id
    Expected = 'FIX2_active'
  },
  [pscustomobject]@{
    Function = 'Get-C33JFix2GenericSuccessorMode'; Current = $fix2Id
    Expected = 'FIX2_active'
  }
)
$historicalPassed = 0
foreach ($case in $historicalModes) {
  $scope = New-C33MFix6Fixture `
    -CurrentId $case.Current `
    -TopId $case.Current `
    -SelectedId $case.Current
  $mode = & $case.Function `
    -Scope $scope `
    -SelectedTicketSha256 $fixtureSha `
    -ParentEvidenceExists $true `
    -Fix1EvidenceExists $true `
    -Fix2EvidenceExists $true
  if ($mode -ceq $case.Expected) { $historicalPassed++ }
}
Assert-C33MFix6 -Condition ($historicalPassed -eq 6) `
  -Message 'one or more historical selection modes changed.'

$negativeCases = @(
  [pscustomobject]@{ Scope = (New-C33MFix6Fixture -TopId 'WRONG'); Sha = $fixtureSha; Parent = $true; Fix1 = $true; Fix2 = $true },
  [pscustomobject]@{ Scope = (New-C33MFix6Fixture -SelectedId 'WRONG'); Sha = $fixtureSha; Parent = $true; Fix1 = $true; Fix2 = $true },
  [pscustomobject]@{ Scope = (New-C33MFix6Fixture); Sha = 'WRONG'; Parent = $true; Fix1 = $true; Fix2 = $true },
  [pscustomobject]@{ Scope = (New-C33MFix6Fixture -ParentHash 'WRONG'); Sha = $fixtureSha; Parent = $true; Fix1 = $true; Fix2 = $true },
  [pscustomobject]@{ Scope = (New-C33MFix6Fixture -Fix1State 'WRONG'); Sha = $fixtureSha; Parent = $true; Fix1 = $true; Fix2 = $true },
  [pscustomobject]@{ Scope = (New-C33MFix6Fixture -Fix2State 'WRONG'); Sha = $fixtureSha; Parent = $true; Fix1 = $true; Fix2 = $true },
  [pscustomobject]@{ Scope = (New-C33MFix6Fixture); Sha = $fixtureSha; Parent = $true; Fix1 = $true; Fix2 = $false }
)
$negativeRejected = 0
foreach ($functionName in @(
  'Get-C33JGenericSuccessorMode',
  'Get-C33JFix1GenericSuccessorMode',
  'Get-C33JFix2GenericSuccessorMode'
)) {
  foreach ($case in $negativeCases) {
    try {
      [void](& $functionName `
        -Scope $case.Scope `
        -SelectedTicketSha256 $case.Sha `
        -ParentEvidenceExists $case.Parent `
        -Fix1EvidenceExists $case.Fix1 `
        -Fix2EvidenceExists $case.Fix2)
    } catch {
      $negativeRejected++
    }
  }
}
Assert-C33MFix6 -Condition ($negativeRejected -eq 21) `
  -Message 'one or more generic successor negative fixtures passed.'

$liveGateSpecs = if ([string]$activeScope.ticket.id -ceq $emailLinkId) {
  @($gateSpecs[0])
} else {
  $gateSpecs
}
$livePassed = 0
foreach ($spec in $liveGateSpecs) {
  $livePath = Resolve-C33MFix6File -Path $spec.Path -Label 'live C33J gate'
  $liveOutput = & $livePath -RepositoryRoot $root
  $liveText = $liveOutput -join [Environment]::NewLine
  Assert-C33MFix6 -Condition (
    $liveText.IndexOf(
      'selectionMode=qualified_generic_successor_replay',
      [StringComparison]::Ordinal
    ) -ge 0 -and
    (
      $spec.Function -cne 'Get-C33JGenericSuccessorMode' -or
      $liveText.IndexOf('focusedMatrix=12', [StringComparison]::Ordinal) -ge 0
    )
  ) -Message "$($spec.Function) live generic replay did not pass."
  $livePassed++
}

Write-Output (
  'C33M FIX6 C33J gate trilogy replay passed: historical=6/6; ' +
  "selectionMode=$selectionMode; generic=3/3; negative=21/21; " +
  "emailLinkBoundary=1/1; boundaryNegative=3/3; " +
  "live=$livePassed/$($liveGateSpecs.Count); " +
  'runtimeBuildPlayDeviceExternal=false; secretValuesObserved=false.'
)
