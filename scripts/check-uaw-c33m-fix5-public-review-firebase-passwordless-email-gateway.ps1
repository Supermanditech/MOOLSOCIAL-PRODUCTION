[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33MFix5 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33M FIX5 Firebase passwordless email gateway rejected: $Message"
  }
}

function Resolve-C33MFix5File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33MFix5 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Get-C33MFix5CanonicalTextSha256 {
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

function Get-C33MFix5GenericSuccessorMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix5EvidenceExists
  )
  $fix5Id = 'UAW-C33M-FIX5-PUBLIC-REVIEW-FIREBASE-PASSWORDLESS-EMAIL-GATEWAY'
  $fix5Hash = '05FD94BC8FF515700BBBFF20C2AE8748C20AC1C1AFC6167E8042C0748A7552DD'
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  if (
    $currentId -cne [string]$Scope.ticket.id -or
    $currentId -cne [string]$checkpoint.selectedTicketAssessment.ticketId -or
    [string]$checkpoint.selectedTicketAssessment.manifestSha256 -cne
      $SelectedTicketSha256
  ) {
    throw 'C33M FIX5 current, top-level or selected ticket binding changed.'
  }
  if ($currentId -ceq $fix5Id) {
    if ($SelectedTicketSha256 -cne $fix5Hash) {
      throw 'C33M FIX5 direct selection ticket hash changed.'
    }
    return 'FIX5_active'
  }
  $qualified = $checkpoint.priorC33MFix5SelectedTicketAssessment
  if (
    [string]$qualified.ticketId -cne $fix5Id -or
    [string]$qualified.manifestPath -cne
      'config/uaw-c33m-fix5-public-review-firebase-passwordless-email-gateway-ticket.json' -or
    [string]$qualified.manifestSha256 -cne $fix5Hash -or
    [string]$qualified.implementationState -cne
      'source_repair_two_identical_cycles_qualified_registry_2574_flutter_501_3_backend_537_web_8_dual_host_FIX5_FIX6_FIX7_FIX8_passed_source_unchanged_build_Play_OPPO_provider_email_and_external_actions_held' -or
    [string]$qualified.evidencePath -cne
      'docs/quality/UAW-C33M-FIX5-PUBLIC-REVIEW-FIREBASE-PASSWORDLESS-EMAIL-GATEWAY-QUALIFICATION-20260816.md' -or
    -not $Fix5EvidenceExists
  ) {
    throw 'C33M FIX5 generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

function Test-C33MFix5ExecutionBoundary {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectionMode
  )
  $selected = $Scope.preTicketSelectionCheckpoint.selectedTicketAssessment
  $historical = (
    $SelectionMode -ceq 'FIX5_active' -and
    -not [bool]$Scope.execution.backendWriteAuthorized
  )
  $emailLink = (
    $SelectionMode -ceq 'qualified_generic_successor_replay' -and
    [string]$Scope.ticket.id -ceq 'UAW-CODEX-EMAIL-LINK-AUTH-20260823' -and
    [string]$selected.ticketId -ceq 'UAW-CODEX-EMAIL-LINK-AUTH-20260823' -and
    [string]$selected.manifestPath -ceq
      'docs/quality/UAW-CODEX-EMAIL-LINK-AUTH-20260823.md' -and
    [string]$selected.manifestSha256 -ceq
      '9286F0DADB04D669B03921524CF4AB762B59B4AF6BF86305344B033F1979DC3A' -and
    [bool]$Scope.execution.runtimeWriteAuthorized -and
    -not [bool]$Scope.execution.backendWriteAuthorized
  )
  return (
    [bool]$Scope.execution.testOrGateWriteAuthorized -and
    ($historical -or $emailLink) -and
    -not [bool]$Scope.execution.externalServiceWriteAuthorized -and
    -not [bool]$Scope.execution.liveEmailSendAuthorized -and
    -not [bool]$Scope.execution.buildAuthorized -and
    -not [bool]$Scope.execution.deviceInstallAuthorized
  )
}

$ticketId = 'UAW-C33M-FIX5-PUBLIC-REVIEW-FIREBASE-PASSWORDLESS-EMAIL-GATEWAY'
$ticketPath = Resolve-C33MFix5File `
  -Path 'config/uaw-c33m-fix5-public-review-firebase-passwordless-email-gateway-ticket.json' `
  -Label 'FIX5 ticket'
Assert-C33MFix5 -Condition (
  (Get-C33MFix5CanonicalTextSha256 -Path $ticketPath) -ceq
    '05FD94BC8FF515700BBBFF20C2AE8748C20AC1C1AFC6167E8042C0748A7552DD'
) -Message 'FIX5 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33MFix5 -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.findingId -ceq
    'REG-20260816-2585-C33M-PUBLIC-REVIEW-DEVICE-MODE-REVIEW-EMAIL-LINK-GATEWAY' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.robustnessAndReuseAssessment.reuseInventoryComplete -and
  [bool]$ticket.robustnessAndReuseAssessment.duplicateSearchComplete -and
  @($ticket.robustnessAndReuseAssessment.newScreens).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newRoutes).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newBackendOwners).Count -eq 0 -and
  [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX5 identity, scope assessment or authority boundary changed.'

$scopeGate = Resolve-C33MFix5File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
$scopePath = Resolve-C33MFix5File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$selectedManifestPath = Resolve-C33MFix5File `
  -Path ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath) `
  -Label 'selected ticket manifest'
$fix5EvidencePath = Join-Path $root `
  'docs/quality/UAW-C33M-FIX5-PUBLIC-REVIEW-FIREBASE-PASSWORDLESS-EMAIL-GATEWAY-QUALIFICATION-20260816.md'
$selectionMode = Get-C33MFix5GenericSuccessorMode `
  -Scope $scope `
  -SelectedTicketSha256 (Get-C33MFix5CanonicalTextSha256 `
    -Path $selectedManifestPath) `
  -Fix5EvidenceExists (
    Test-Path -LiteralPath $fix5EvidencePath -PathType Leaf
  )
Assert-C33MFix5 -Condition (
  Test-C33MFix5ExecutionBoundary -Scope $scope -SelectionMode $selectionMode
) -Message 'current email-link successor or historical execution boundary changed.'
& $scopeGate `
  -CandidateId ([string]$scope.ticket.id) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C33MFix5File `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root |
  Out-Null
$fix8Gate = Resolve-C33MFix5File `
  -Path 'scripts/check-uaw-c33m-fix8-fix4-gate-generic-successor-replay-compatibility.ps1' `
  -Label 'FIX8 gate'
& $fix8Gate -RepositoryRoot $root | Out-Null

$registryPath = Resolve-C33MFix5File `
  -Path 'config/codex-development-regression-registry.json' `
  -Label 'regression registry'
$registry = Get-Content -Raw -LiteralPath $registryPath | ConvertFrom-Json
$finding = @($registry.entries | Where-Object {
  [string]$_.id -ceq
    'REG-20260816-2585-C33M-PUBLIC-REVIEW-DEVICE-MODE-REVIEW-EMAIL-LINK-GATEWAY'
})
Assert-C33MFix5 -Condition (
  $finding.Count -eq 1 -and
  [string]$finding[0].status -ceq
    'registered_r60_51_postbuild_rejected_exact_FIX5_required_after_FIX4_qualification'
) -Message 'REG2585 identity or r60.51 rejection state changed.'

$candidateStatePath = Resolve-C33MFix5File `
  -Path 'config/successor-aab-regression-hard-gate-state-c33m.json' `
  -Label 'r60.51 detailed candidate state'
$candidateState = Get-Content -Raw -LiteralPath $candidateStatePath |
  ConvertFrom-Json
$candidateAggregatePath = Resolve-C33MFix5File `
  -Path 'config/successor-aab-regression-hard-gate-aggregate-c33m.json' `
  -Label 'r60.51 aggregate candidate state'
$candidateAggregate = Get-Content -Raw -LiteralPath $candidateAggregatePath |
  ConvertFrom-Json
Assert-C33MFix5 -Condition (
  [string]$candidateState.candidate.id -ceq
    'UAW-C33M-R60-51-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE' -and
  [string]$candidateState.candidate.versionName -ceq '1.0.0-r60.51' -and
  [string]$candidateState.candidate.versionCode -ceq '2026081351' -and
  [string]$candidateState.machineState -ceq
    'single_release_AAB_succeeded_authority_consumed' -and
  [int]$candidateState.actionCounts.build -eq 1 -and
  [int]$candidateState.actionCounts.upload -eq 0 -and
  [int]$candidateState.actionCounts.install -eq 0 -and
  [int]$candidateState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$candidateAggregate.candidate.aabSha256 -ceq
    '6C4C402DAA5CD813F66DF1ECE895A7FE39936F6D6413FC2D771667E274A7CA24'
) -Message 'r60.51 exact rejected build identity or 1/0/0/0 hold changed.'

$configurationPath = Resolve-C33MFix5File `
  -Path 'apps/mobile/lib/core/config/email_link_runtime_configuration.dart' `
  -Label 'email-link runtime configuration owner'
$mainPath = Resolve-C33MFix5File `
  -Path 'apps/mobile/lib/main.dart' `
  -Label 'mobile bootstrap'
$firebaseGatewayPath = Resolve-C33MFix5File `
  -Path 'apps/mobile/lib/features/journey01/review_journey_services.dart' `
  -Label 'Firebase email-link gateway owner'
$gatewayContractPath = Resolve-C33MFix5File `
  -Path 'apps/mobile/lib/features/journey01/journey_services.dart' `
  -Label 'review email-link gateway owner'
$focusedTestPath = Resolve-C33MFix5File `
  -Path 'apps/mobile/test/uaw_c33m_fix5_public_review_firebase_passwordless_email_gateway_test.dart' `
  -Label 'FIX5 focused Flutter test'
$configuration = Get-Content -Raw -LiteralPath $configurationPath
$main = Get-Content -Raw -LiteralPath $mainPath
$firebaseGateway = Get-Content -Raw -LiteralPath $firebaseGatewayPath
$gatewayContract = Get-Content -Raw -LiteralPath $gatewayContractPath
$focusedTest = Get-Content -Raw -LiteralPath $focusedTestPath

foreach ($required in @(
  'enum EmailLinkGatewaySelection { unavailable, review, firebase }',
  'EmailLinkGatewaySelection resolveEmailLinkGatewaySelection({',
  'required bool deviceReviewMode,',
  'required bool publicReviewMode,',
  'required bool runtimeConfigurationAvailable,',
  'if (publicReviewMode)',
  '? EmailLinkGatewaySelection.firebase',
  ': EmailLinkGatewaySelection.unavailable;',
  'if (deviceReviewMode) return EmailLinkGatewaySelection.review;'
)) {
  Assert-C33MFix5 -Condition (
    $configuration.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "gateway selection policy is missing: $required"
}

foreach ($required in @(
  'final emailLinkGatewaySelection = resolveEmailLinkGatewaySelection(',
  'deviceReviewMode: globalSocialLoginAuditComposition.useReviewAuthentication,',
  'publicReviewMode: _youtubePublicReviewMode,',
  'runtimeConfigurationAvailable: emailLinkRuntimeAvailable,',
  'EmailLinkGatewaySelection.review => ReviewEmailLinkGateway(),',
  'EmailLinkGatewaySelection.firebase => FirebaseEmailLinkGateway(',
  'EmailLinkGatewaySelection.unavailable =>',
  'const UnavailableEmailLinkGateway(),'
)) {
  Assert-C33MFix5 -Condition (
    $main.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "mobile gateway wiring is missing: $required"
}

Assert-C33MFix5 -Condition (
  $firebaseGateway.IndexOf(
    'class FirebaseEmailLinkGateway implements EmailLinkGateway',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $gatewayContract.IndexOf(
    'class ReviewEmailLinkGateway implements EmailLinkGateway',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'existing Firebase or isolated review gateway owner changed.'

foreach ($required in @(
  'combined public and device review selects qualified Firebase',
  'public review fails closed without qualified email runtime',
  'isolated non-release device review retains review gateway',
  'ordinary configured runtime selects Firebase',
  'ordinary unconfigured runtime remains unavailable',
  'deviceReviewMode: true,',
  'publicReviewMode: true,',
  'runtimeConfigurationAvailable: true,',
  'EmailLinkGatewaySelection.firebase',
  'EmailLinkGatewaySelection.unavailable',
  'EmailLinkGatewaySelection.review'
)) {
  Assert-C33MFix5 -Condition (
    $focusedTest.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "focused gateway matrix coverage is missing: $required"
}

Write-Output (
  'C33M FIX5 Firebase passwordless email gateway passed: ' +
  "selectionMode=$selectionMode; combinedPublicDeviceReview=Firebase; " +
  'invalidPublicReview=unavailable; ' +
  'isolatedDeviceReview=review; ordinaryConfigured=Firebase; ' +
  'r60.51=1/0/0/0 rejected; buildPlayDeviceProviderExternal=false; ' +
  'secretOrPrivateValuesObserved=false.'
)
