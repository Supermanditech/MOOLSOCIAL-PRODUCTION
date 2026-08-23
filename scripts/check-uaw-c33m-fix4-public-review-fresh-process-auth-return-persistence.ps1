[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33MFix4 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33M FIX4 fresh-process auth-return persistence gate rejected: $Message"
  }
}

function Resolve-C33MFix4File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33MFix4 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Get-C33MFix4CanonicalTextSha256 {
  param([Parameter(Mandatory)][string]$Path)
  $utf8 = [Text.UTF8Encoding]::new($false)
  $text = [IO.File]::ReadAllText($Path, $utf8).
    Replace("`r`n", "`n").Replace("`r", "`n")
  $sha256 = [Security.Cryptography.SHA256]::Create()
  try {
    return [BitConverter]::ToString(
      $sha256.ComputeHash($utf8.GetBytes($text))
    ).Replace('-', '')
  } finally {
    $sha256.Dispose()
  }
}

function Get-C33MFix4GenericSuccessorMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix4EvidenceExists
  )
  $fix4Id = 'UAW-C33M-FIX4-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-PERSISTENCE'
  $fix4Hash = 'FB56B77AEE47D211D5924C568D72668B6BF150FE28AE5C0BEEFF10656F47025C'
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $currentId = [string]$checkpoint.currentTicketId
  if (
    $currentId -cne [string]$Scope.ticket.id -or
    $currentId -cne [string]$checkpoint.selectedTicketAssessment.ticketId -or
    [string]$checkpoint.selectedTicketAssessment.manifestSha256 -cne
      $SelectedTicketSha256
  ) {
    throw 'C33M FIX4 current, top-level or selected ticket binding changed.'
  }
  if ($currentId -ceq $fix4Id) {
    if ($SelectedTicketSha256 -cne $fix4Hash) {
      throw 'C33M FIX4 direct selection ticket hash changed.'
    }
    return 'FIX4_active'
  }
  $qualified = $checkpoint.priorC33MFix4SelectedTicketAssessment
  if (
    [string]$qualified.ticketId -cne $fix4Id -or
    [string]$qualified.manifestPath -cne
      'config/uaw-c33m-fix4-public-review-fresh-process-auth-return-persistence-ticket.json' -or
    [string]$qualified.manifestSha256 -cne $fix4Hash -or
    [string]$qualified.implementationState -cne
      'source_repair_two_identical_cycles_qualified_registry_2570_flutter_496_3_backend_537_web_8_dual_host_FIX4_FIX6_FIX7_passed_source_unchanged_build_Play_OPPO_provider_email_and_external_actions_held' -or
    [string]$qualified.evidencePath -cne
      'docs/quality/UAW-C33M-FIX4-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-PERSISTENCE-QUALIFICATION-20260816.md' -or
    -not $Fix4EvidenceExists
  ) {
    throw 'C33M FIX4 generic successor qualification binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

function Test-C33MFix4ExecutionBoundary {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectionMode
  )
  $selected = $Scope.preTicketSelectionCheckpoint.selectedTicketAssessment
  $historical = (
    $SelectionMode -ceq 'FIX4_active' -and
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

$ticketId = 'UAW-C33M-FIX4-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-PERSISTENCE'
$ticketPath = Resolve-C33MFix4File `
  -Path 'config/uaw-c33m-fix4-public-review-fresh-process-auth-return-persistence-ticket.json' `
  -Label 'FIX4 ticket'
Assert-C33MFix4 -Condition (
  (Get-C33MFix4CanonicalTextSha256 -Path $ticketPath) -ceq
    'FB56B77AEE47D211D5924C568D72668B6BF150FE28AE5C0BEEFF10656F47025C'
) -Message 'FIX4 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33MFix4 -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.findingId -ceq
    'REG-20260816-2583-C33M-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-STORE-RESET' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.robustnessAndReuseAssessment.reuseInventoryComplete -and
  [bool]$ticket.robustnessAndReuseAssessment.duplicateSearchComplete -and
  @($ticket.robustnessAndReuseAssessment.newScreens).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newRoutes).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newBackendOwners).Count -eq 0 -and
  [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX4 identity, scope assessment or authority boundary changed.'

$scopeGate = Resolve-C33MFix4File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
$scopePath = Resolve-C33MFix4File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$selectedManifestPath = Resolve-C33MFix4File `
  -Path ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath) `
  -Label 'selected ticket manifest'
$fix4EvidencePath = Join-Path $root `
  'docs/quality/UAW-C33M-FIX4-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-PERSISTENCE-QUALIFICATION-20260816.md'
$selectionMode = Get-C33MFix4GenericSuccessorMode `
  -Scope $scope `
  -SelectedTicketSha256 (Get-C33MFix4CanonicalTextSha256 `
    -Path $selectedManifestPath) `
  -Fix4EvidenceExists (
    Test-Path -LiteralPath $fix4EvidencePath -PathType Leaf
  )
Assert-C33MFix4 -Condition (
  Test-C33MFix4ExecutionBoundary -Scope $scope -SelectionMode $selectionMode
) -Message 'current email-link successor or historical execution boundary changed.'
& $scopeGate `
  -CandidateId ([string]$scope.ticket.id) `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null

$memoryGate = Resolve-C33MFix4File `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root | Out-Null

$registryPath = Resolve-C33MFix4File `
  -Path 'config/codex-development-regression-registry.json' `
  -Label 'regression registry'
$registry = Get-Content -Raw -LiteralPath $registryPath | ConvertFrom-Json
$finding = @($registry.entries | Where-Object {
  [string]$_.id -ceq
    'REG-20260816-2583-C33M-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-STORE-RESET'
})
Assert-C33MFix4 -Condition (
  $finding.Count -eq 1 -and
  [string]$finding[0].status -ceq
    'registered_r60_51_postbuild_rejected_exact_FIX4_required_before_any_successor'
) -Message 'REG2583 identity or r60.51 rejection state changed.'

$candidateStatePath = Resolve-C33MFix4File `
  -Path 'config/successor-aab-regression-hard-gate-state-c33m.json' `
  -Label 'r60.51 detailed candidate state'
$candidateState = Get-Content -Raw -LiteralPath $candidateStatePath |
  ConvertFrom-Json
$candidateAggregatePath = Resolve-C33MFix4File `
  -Path 'config/successor-aab-regression-hard-gate-aggregate-c33m.json' `
  -Label 'r60.51 aggregate candidate state'
$candidateAggregate = Get-Content -Raw -LiteralPath $candidateAggregatePath |
  ConvertFrom-Json
Assert-C33MFix4 -Condition (
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

$rejectionPath = Resolve-C33MFix4File `
  -Path 'docs/quality/UAW-C33M-R60-51-POSTBUILD-NEW-DEFECT-REJECTION-20260816.md' `
  -Label 'r60.51 postbuild rejection evidence'
$rejection = Get-Content -Raw -LiteralPath $rejectionPath
foreach ($required in @(
  '6C4C402DAA5CD813F66DF1ECE895A7FE39936F6D6413FC2D771667E274A7CA24',
  '1/0/0/0',
  'REG-20260816-2583-C33M-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-STORE-RESET',
  'REG-20260816-2585-C33M-PUBLIC-REVIEW-DEVICE-MODE-REVIEW-EMAIL-LINK-GATEWAY'
)) {
  Assert-C33MFix4 -Condition (
    $rejection.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "r60.51 rejection evidence is missing: $required"
}

$servicesPath = Resolve-C33MFix4File `
  -Path 'apps/mobile/lib/features/journey01/journey_services.dart' `
  -Label 'journey store owner'
$mainPath = Resolve-C33MFix4File `
  -Path 'apps/mobile/lib/main.dart' `
  -Label 'mobile bootstrap'
$focusedTestPath = Resolve-C33MFix4File `
  -Path 'apps/mobile/test/uaw_c33m_fix4_public_review_fresh_process_auth_return_persistence_test.dart' `
  -Label 'FIX4 focused Flutter test'
$services = Get-Content -Raw -LiteralPath $servicesPath
$main = Get-Content -Raw -LiteralPath $mainPath
$focusedTest = Get-Content -Raw -LiteralPath $focusedTestPath

foreach ($required in @(
  'class SeededJourneyStore implements JourneyStore',
  'final JourneyStore delegate;',
  'final JourneySnapshot seed;',
  'Future<JourneySnapshot?> read() async => await delegate.read() ?? seed;',
  'Future<void> write(JourneySnapshot snapshot) => delegate.write(snapshot);'
)) {
  Assert-C33MFix4 -Condition (
    $services.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "seed-if-empty owner is missing: $required"
}
Assert-C33MFix4 -Condition (
  $main.IndexOf('store: SeededJourneyStore(', [StringComparison]::Ordinal) -ge 0 -and
  $main.IndexOf(
    'delegate: SharedPreferencesJourneyStore(preferences)',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $main.IndexOf("pendingRoute: '/app/social?sub=videos'", [StringComparison]::Ordinal) -ge 0 -and
  $main.IndexOf('store: MemoryJourneyStore(', [StringComparison]::Ordinal) -lt 0
) -Message 'public-review bootstrap is not persistent seed-if-empty with exact Videos safe boot.'

foreach ($required in @(
  'empty durable state returns the public seed without writing it',
  'an existing durable snapshot wins over the public seed',
  'fresh store and session preserve shared-post destination cancel and Google success',
  'fresh process preserves Mobile OTP intent but not private input',
  'cold email-link return asks again then resumes the exact intent',
  'YouTube connection purpose and exact cancel survive a fresh process',
  'store read failure still reaches the existing boot recovery',
  'SharedPreferencesJourneyStore(preferences)',
  '/app/creator/youtube-connect',
  '_expectNoPrivateAuthenticationValues(preferences)'
)) {
  Assert-C33MFix4 -Condition (
    $focusedTest.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "focused fresh-process coverage is missing: $required"
}

Write-Output (
  'C33M FIX4 fresh-process auth-return persistence gate passed: ' +
  "selectionMode=$selectionMode; seedIfEmpty=true; durableStateWins=true; freshStores=true; " +
  'GoogleMobileOtpEmailLinkYouTube=true; r60.51=1/0/0/0 rejected; ' +
  'buildPlayDeviceExternal=false; secretValuesObserved=false.'
)
