[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$ScopePath = 'config/mvp-scope-gate-state.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33LFix1 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33L FIX1 Screen 04 safe-boot regression gate rejected: $Message"
  }
}

function Resolve-C33LFix1File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33LFix1 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Get-C33LFix1GenericSuccessorMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix1EvidenceExists,
    [Parameter(Mandatory)][bool]$Fix2EvidenceExists
  )
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $selected = $checkpoint.selectedTicketAssessment
  $currentId = [string]$checkpoint.currentTicketId
  if (
    $currentId -cne [string]$Scope.ticket.id -or
    $currentId -cne [string]$selected.ticketId
  ) {
    throw 'C33L FIX1 generic successor current and selected identities differ.'
  }
  if ([string]$selected.manifestSha256 -cne $SelectedTicketSha256) {
    throw 'C33L FIX1 generic successor selected ticket hash changed.'
  }
  $fix1 = $checkpoint.priorC33LFix1SelectedTicketAssessment
  $fix2 = $checkpoint.priorC33LFix2SelectedTicketAssessment
  if (
    [string]$fix1.ticketId -cne
      'UAW-C33L-FIX1-PRIVATE-DEV-PUBLIC-REVIEW-SCREEN04-SAFE-BOOT-REGRESSION' -or
    [string]$fix1.manifestSha256 -cne
      '40F11A474FE95C0303E29040ED2E2FC9F537766E527C2F01704A32DBB44A3B6F' -or
    [string]$fix1.implementationState -cne
      'source_test_contract_repair_qualified_43_affected_passed_analyzer_clean_dual_host_gate_passed_parent_reselected' -or
    [string]$fix2.ticketId -cne
      'UAW-C33L-FIX2-FIX1-GATE-PARENT-REPLAY-COMPATIBILITY' -or
    [string]$fix2.manifestSha256 -cne
      '59C383D45D30FBCF26722FFAB851ED35ECA33621DDAD86D1765C6CD6F86ABCC0' -or
    [string]$fix2.implementationState -cne
      'gate_parent_replay_compatibility_qualified_dual_host_repair_lifecycle_passed_parent_reselection_and_new_source_seal_required' -or
    -not $Fix1EvidenceExists -or
    -not $Fix2EvidenceExists
  ) {
    throw 'C33L FIX1 generic successor qualified FIX1/FIX2 binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

$ticketId = 'UAW-C33L-FIX1-PRIVATE-DEV-PUBLIC-REVIEW-SCREEN04-SAFE-BOOT-REGRESSION'
$ticketPath = Resolve-C33LFix1File `
  -Path 'config/uaw-c33l-fix1-private-dev-public-review-screen04-safe-boot-regression-ticket.json' `
  -Label 'FIX1 ticket'
Assert-C33LFix1 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    '40F11A474FE95C0303E29040ED2E2FC9F537766E527C2F01704A32DBB44A3B6F'
) -Message 'FIX1 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33LFix1 -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.parentTicket -ceq
    'UAW-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE' -and
  [string]$ticket.finding -ceq
    'REG-20260816-2538-C33L-PRIVATE-DEV-PUBLIC-REVIEW-SCREEN04-SAFE-BOOT-FAILURE' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.robustnessAndReuseAssessment.reuseInventoryComplete -and
  [bool]$ticket.robustnessAndReuseAssessment.duplicateSearchComplete -and
  @($ticket.robustnessAndReuseAssessment.newScreens).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newRoutes).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newBackendOwners).Count -eq 0 -and
  [bool]$ticket.authority.ticketEvidenceSourceTestAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.aabBuildAuthorized -and
  -not [bool]$ticket.authority.playUploadOrActivationAuthorized -and
  -not [bool]$ticket.authority.oppoMutationAuthorized -and
  -not [bool]$ticket.authority.firebaseBackendHostingProviderOrProductionDeploymentAuthorized -and
  -not [bool]$ticket.authority.emailOrSmsSendAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX1 identity, scope assessment or authority changed.'

$mainPath = Resolve-C33LFix1File -Path 'apps/mobile/lib/main.dart' -Label 'mobile bootstrap'
$testPath = Resolve-C33LFix1File `
  -Path 'apps/mobile/test/social_v2_youtube_public_runtime_test.dart' `
  -Label 'public runtime regression test'
$emailFix1TestPath = Resolve-C33LFix1File `
  -Path 'apps/mobile/test/uaw_c33j_fix1_foreground_email_link_return_handoff_test.dart' `
  -Label 'foreground email-link regression test'
$emailFix2TestPath = Resolve-C33LFix1File `
  -Path 'apps/mobile/test/uaw_c33j_fix2_android_email_link_same_device_exact_return_test.dart' `
  -Label 'same-device email-link regression test'
$main = Get-Content -Raw -LiteralPath $mainPath
$test = Get-Content -Raw -LiteralPath $testPath
[void](Get-Content -Raw -LiteralPath $emailFix1TestPath)
[void](Get-Content -Raw -LiteralPath $emailFix2TestPath)

$youtubeOwner = 'final youtubeInitialLocation = youtubeConnectReturnLocation('
$emailOwner = 'final emailLinkInitialLocation ='
$emailGuard = 'youtubeInitialLocation == null &&'
$emailPrepare = 'await session.prepareEmailLinkReturn(platformRouteName);'
$initialOwner = 'initialLocation:'
$youtubeFallback = 'youtubeInitialLocation ??'
$bootFallback = "(emailLinkInitialLocation ? '/sign-in' : '/boot'),"
$youtubeOwnerIndex = $main.IndexOf($youtubeOwner, [StringComparison]::Ordinal)
$emailOwnerIndex = $main.IndexOf($emailOwner, [StringComparison]::Ordinal)
$emailGuardIndex = $main.IndexOf($emailGuard, $emailOwnerIndex, [StringComparison]::Ordinal)
$emailPrepareIndex = $main.IndexOf($emailPrepare, $emailGuardIndex, [StringComparison]::Ordinal)
$initialOwnerIndex = $main.IndexOf($initialOwner, $emailPrepareIndex, [StringComparison]::Ordinal)
$youtubeFallbackIndex = $main.IndexOf($youtubeFallback, $initialOwnerIndex, [StringComparison]::Ordinal)
$bootFallbackIndex = $main.IndexOf($bootFallback, $youtubeFallbackIndex, [StringComparison]::Ordinal)
Assert-C33LFix1 -Condition (
  $youtubeOwnerIndex -ge 0 -and
  $emailOwnerIndex -gt $youtubeOwnerIndex -and
  $emailGuardIndex -gt $emailOwnerIndex -and
  $emailPrepareIndex -gt $emailGuardIndex -and
  $initialOwnerIndex -gt $emailPrepareIndex -and
  $youtubeFallbackIndex -gt $initialOwnerIndex -and
  $bootFallbackIndex -gt $youtubeFallbackIndex
) -Message 'YouTube return, email-link return and safe-boot fallback order changed.'
Assert-C33LFix1 -Condition (
  $main.IndexOf("pendingRoute: '/app/social?sub=videos'", [StringComparison]::Ordinal) -ge 0 -and
  $main.IndexOf('initialLocation: _youtubePublicReviewMode', [StringComparison]::Ordinal) -lt 0
) -Message 'private-Dev public-review pending route or protected boot restoration changed.'

foreach ($required in @(
  'contains("pendingRoute: ''/app/social?sub=videos''")',
  "'final emailLinkInitialLocation =\n'",
  "'      youtubeInitialLocation == null &&\n'",
  "'      await session.prepareEmailLinkReturn(platformRouteName);'",
  "'initialLocation:\n'",
  "'          youtubeInitialLocation ??\n'",
  '"          (emailLinkInitialLocation ? ''/sign-in'' : ''/boot''),"'
)) {
  Assert-C33LFix1 -Condition (
    $test.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "focused public runtime assertion is missing: $required"
}
Assert-C33LFix1 -Condition (
  $test.IndexOf("initialLocation: initialLocation ?? '/boot'", [StringComparison]::Ordinal) -lt 0
) -Message 'stale pre-email-link static assertion remains.'

$scopeGate = Resolve-C33LFix1File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
$resolvedScopePath = Resolve-C33LFix1File -Path $ScopePath -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $resolvedScopePath | ConvertFrom-Json
$parentTicketId = 'UAW-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE'
$repairTicketId = 'UAW-C33L-FIX2-FIX1-GATE-PARENT-REPLAY-COMPATIBILITY'
$activeTicketId = [string]$scope.ticket.id
$activeAssessmentId = [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId
$scopeCandidateId = $activeTicketId
Assert-C33LFix1 -Condition (
  $activeTicketId -ceq $activeAssessmentId -and
  $activeTicketId -ceq
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId
) -Message 'active MVP current, ticket and selected identities differ.'
$selectionMode = 'active_FIX1'

if ($activeTicketId -cne $ticketId) {
  $qualifiedFix1 = $scope.preTicketSelectionCheckpoint.priorC33LFix1SelectedTicketAssessment
  Assert-C33LFix1 -Condition (
    $null -ne $qualifiedFix1 -and
    [string]$qualifiedFix1.ticketId -ceq $ticketId -and
    [string]$qualifiedFix1.manifestPath -ceq
      'config/uaw-c33l-fix1-private-dev-public-review-screen04-safe-boot-regression-ticket.json' -and
    [string]$qualifiedFix1.manifestSha256 -ceq
      '40F11A474FE95C0303E29040ED2E2FC9F537766E527C2F01704A32DBB44A3B6F' -and
    [string]$qualifiedFix1.implementationState -ceq
      'source_test_contract_repair_qualified_43_affected_passed_analyzer_clean_dual_host_gate_passed_parent_reselected' -and
    [string]$qualifiedFix1.evidencePath -ceq
      'docs/quality/UAW-C33L-FIX1-PRIVATE-DEV-PUBLIC-REVIEW-SCREEN04-SAFE-BOOT-QUALIFICATION-20260816.md'
  ) -Message 'parent or FIX2 replay lacks the exact qualified FIX1 assessment.'
  $qualifiedFix1Evidence = Resolve-C33LFix1File `
    -Path ([string]$qualifiedFix1.evidencePath) `
    -Label 'qualified FIX1 evidence'
  [void](Get-Content -Raw -LiteralPath $qualifiedFix1Evidence)
}

if ($activeTicketId -ceq $parentTicketId) {
  $selectionMode = 'C33L_parent_replay'
  Assert-C33LFix1 -Condition (
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath -ceq
      'config/uaw-c33l-r60-50-authentication-no-regression-play-oppo-acceptance-ticket.json' -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
      '3867E192D5903FF8EC9ECBB9F82201C633088CF3F43C820403A4DC795693D4F1'
  ) -Message 'parent replay is not bound to the exact C33L candidate ticket.'
} elseif ($activeTicketId -ceq $repairTicketId) {
  $selectionMode = 'FIX2_repair_lifecycle'
  Assert-C33LFix1 -Condition (
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath -ceq
      'config/uaw-c33l-fix2-fix1-gate-parent-replay-compatibility-ticket.json' -and
    $null -ne $scope.preTicketSelectionCheckpoint.priorC33LParentSelectedTicketAssessment -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33LParentSelectedTicketAssessment.ticketId -ceq
      $parentTicketId -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33LParentSelectedTicketAssessment.manifestSha256 -ceq
      '3867E192D5903FF8EC9ECBB9F82201C633088CF3F43C820403A4DC795693D4F1'
  ) -Message 'FIX2 qualification is not bound to the exact C33L parent lifecycle.'
} elseif ($activeTicketId -cne $ticketId) {
  $selectedAssessment =
    $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
  $selectedTicketPath = Resolve-C33LFix1File `
    -Path ([string]$selectedAssessment.manifestPath) `
    -Label 'generic successor selected ticket'
  $qualifiedFix2 =
    $scope.preTicketSelectionCheckpoint.priorC33LFix2SelectedTicketAssessment
  $qualifiedFix2Evidence = Resolve-C33LFix1File `
    -Path ([string]$qualifiedFix2.evidencePath) `
    -Label 'qualified FIX2 evidence'
  $selectionMode = Get-C33LFix1GenericSuccessorMode `
    -Scope $scope `
    -SelectedTicketSha256 (
      Get-FileHash -Algorithm SHA256 -LiteralPath $selectedTicketPath
    ).Hash `
    -Fix1EvidenceExists (Test-Path -LiteralPath $qualifiedFix1Evidence -PathType Leaf) `
    -Fix2EvidenceExists (Test-Path -LiteralPath $qualifiedFix2Evidence -PathType Leaf)
}
& $scopeGate `
  -StatePath $resolvedScopePath `
  -CandidateId $scopeCandidateId `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C33LFix1File `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression-memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root | Out-Null

Write-Output (
  'C33L FIX1 Screen 04 safe-boot regression gate passed: ' +
  "selectionMode=$selectionMode; " +
  'YouTubeReturn->EmailLinkReturn->BootFallback exact; newScreens=0; newRoutes=0; ' +
  'buildPlayOppoExternal=false.'
)
