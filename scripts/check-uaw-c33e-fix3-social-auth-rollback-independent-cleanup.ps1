[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$ScopePath = 'config/mvp-scope-gate-state.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33EFix3 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33E FIX3 Social auth rollback gate rejected: $Message"
  }
}

function Resolve-C33EFix3File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33EFix3 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

$ticketId = 'UAW-C33E-FIX3-SOCIAL-AUTH-ROLLBACK-INDEPENDENT-CLEANUP'
$ticketSha256 = 'C0DC198E6CB37F1AFB8D8EF73D05390F1EF0E9BB089E0FB4A218F4975C07CFD9'
$ticketPath = Resolve-C33EFix3File `
  -Path 'config/uaw-c33e-fix3-social-auth-rollback-independent-cleanup-ticket.json' `
  -Label 'FIX3 ticket'
Assert-C33EFix3 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    $ticketSha256
) -Message 'FIX3 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33EFix3 -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX3 ticket identity, classification or authority changed.'

$fix4TicketId = 'UAW-C33E-FIX4-PROTECTED-SOCIAL-ACTION-INTENT-RETURN-CONTINUITY'
$fix4TicketSha256 = 'E243C28BEEB4732C8F512053146C41229AAD9E3109C87A3C99D041FA79499047'
$fix4TicketPath = Resolve-C33EFix3File `
  -Path 'config/uaw-c33e-fix4-protected-social-action-intent-return-continuity-ticket.json' `
  -Label 'FIX4 successor ticket'
Assert-C33EFix3 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $fix4TicketPath).Hash -ceq
    $fix4TicketSha256
) -Message 'FIX4 successor ticket bytes changed.'
$fix4Ticket = Get-Content -Raw -LiteralPath $fix4TicketPath | ConvertFrom-Json
Assert-C33EFix3 -Condition (
  [string]$fix4Ticket.ticketId -ceq $fix4TicketId -and
  [bool]$fix4Ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$fix4Ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$fix4Ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$fix4Ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$fix4Ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$fix4Ticket.authority.secretValueAccessAuthorized
) -Message 'FIX4 successor ticket identity or authority changed.'

$c33fTicketId = 'UAW-C33F-R60-49-GOOGLE-AUTH-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
$c33fTicketSha256 = '815C70015058DE27B0F117517FB7599F6D7D99D340A217D65F9BFF3E163660C2'
$c33fTicketPath = Resolve-C33EFix3File `
  -Path 'config/uaw-c33f-r60-49-google-auth-successor-aab-play-internal-oppo-acceptance-ticket.json' `
  -Label 'C33F successor release ticket'
Assert-C33EFix3 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $c33fTicketPath).Hash -ceq
    $c33fTicketSha256
) -Message 'C33F successor release ticket bytes changed.'
$c33fTicket = Get-Content -Raw -LiteralPath $c33fTicketPath | ConvertFrom-Json
Assert-C33EFix3 -Condition (
  [string]$c33fTicket.ticketId -ceq $c33fTicketId -and
  [string]$c33fTicket.candidate.versionName -ceq '1.0.0-r60.49' -and
  [string]$c33fTicket.candidate.versionCode -ceq '2026081349' -and
  [bool]$c33fTicket.authority.oneAabBuildAuthorizedAfterAllGates -and
  -not [bool]$c33fTicket.authority.agentSecretValueAccessAuthorized -and
  -not [bool]$c33fTicket.authority.otherTrackAuthorized -and
  -not [bool]$c33fTicket.authority.providerDeploymentAuthorized
) -Message 'C33F successor release ticket identity or authority changed.'

$resolvedScopePath = Resolve-C33EFix3File -Path $ScopePath -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $resolvedScopePath | ConvertFrom-Json
$activeTicketId = [string]$scope.ticket.id
$activeFix3 = $activeTicketId -ceq $ticketId
$activeFix4 = $activeTicketId -ceq $fix4TicketId
$activeC33F = $activeTicketId -ceq $c33fTicketId
$selectionValid = if ($activeFix3) {
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
    $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
    $ticketSha256 -and
  [string]$scope.providerGate.nextTicket -ceq $ticketId
} elseif ($activeFix4) {
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $fix4TicketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
    $fix4TicketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
    $fix4TicketSha256 -and
  [string]$scope.preTicketSelectionCheckpoint.priorC33EFix3QualifiedAssessment.ticketId -ceq
    $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.priorC33EFix3QualifiedAssessment.manifestSha256 -ceq
    $ticketSha256 -and
  [string]$scope.preTicketSelectionCheckpoint.priorC33EFix3QualifiedAssessment.implementationState -ceq
    'source_repair_two_identical_cycles_qualified_no_live_provider_release_device_external_or_secret_action' -and
  [string]$scope.providerGate.nextTicket -ceq $fix4TicketId
} else {
  $activeC33F -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $c33fTicketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
    $c33fTicketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
    $c33fTicketSha256 -and
  [string]$scope.preTicketSelectionCheckpoint.priorC33EFix3QualifiedAssessment.ticketId -ceq
    $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.priorC33EFix3QualifiedAssessment.manifestSha256 -ceq
    $ticketSha256 -and
  [string]$scope.preTicketSelectionCheckpoint.priorC33EFix4QualifiedAssessment.ticketId -ceq
    $fix4TicketId -and
  [string]$scope.preTicketSelectionCheckpoint.priorC33EFix4QualifiedAssessment.manifestSha256 -ceq
    $fix4TicketSha256 -and
  [string]$scope.providerGate.nextTicket -ceq $c33fTicketId
}
$runtimeAuthorityValid = if ($activeC33F) {
  -not [bool]$scope.execution.runtimeWriteAuthorized
} else {
  [bool]$scope.execution.runtimeWriteAuthorized
}
Assert-C33EFix3 -Condition (
  [string]$scope.state -ceq 'ticket_disclosed_and_authorized' -and
  $selectionValid -and
  $runtimeAuthorityValid -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.execution.referenceWriteAuthorized -and
  -not [bool]$scope.execution.backendWriteAuthorized -and
  -not [bool]$scope.execution.buildAuthorized -and
  -not [bool]$scope.execution.deviceInstallAuthorized -and
  -not [bool]$scope.execution.externalServiceWriteAuthorized -and
  -not [bool]$scope.execution.secretValueAccessAuthorized -and
  -not [bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized -and
  -not [bool]$scope.providerGate.externalServiceWriteAuthorized -and
  -not [bool]$scope.providerGate.secretValueAccessAuthorized -and
  -not [bool]$scope.providerGate.apkBuildOrInstallAuthorized -and
  -not [bool]$scope.providerGate.productionOrProviderDeploymentAuthorized -and
  -not [bool]$scope.providerGate.emailOrQuotaSubmissionAuthorized
) -Message 'FIX3/FIX4 selected scope or authority boundary changed.'

$approvedUiGate = Resolve-C33EFix3File `
  -Path 'scripts/check-approved-ui-locks.ps1' `
  -Label 'approved UI lock gate'
& $approvedUiGate -RepositoryRoot $root | Out-Null

$screen03Test = Resolve-C33EFix3File `
  -Path 'apps/mobile/test/screen03_session_test.dart' `
  -Label 'preserved Screen03 session test'
$firebaseGatewayTest = Resolve-C33EFix3File `
  -Path 'apps/mobile/test/firebase_social_auth_gateway_test.dart' `
  -Label 'preserved Firebase Social auth test'
Assert-C33EFix3 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $screen03Test).Hash -ceq
    '186E3C48FECAD71F3C67A8053DCD93E880A6D452650556DA2E95BEF6838CBBEB' -and
  (Get-FileHash -Algorithm SHA256 -LiteralPath $firebaseGatewayTest).Hash -ceq
    '4195AA8C6CF84D52F58037E7ED4AAC7FC4684AB00EADAB79289C5892BDE175F7'
) -Message 'preserved authentication regression owner changed.'

$runtimePath = Resolve-C33EFix3File `
  -Path 'apps/mobile/lib/features/journey01/review_journey_services.dart' `
  -Label 'Firebase Social auth gateway'
$runtime = Get-Content -Raw -LiteralPath $runtimePath
$gatewayStart = $runtime.IndexOf(
  'class FirebaseSocialAuthGateway implements SocialAuthGateway',
  [StringComparison]::Ordinal
)
$gatewayEnd = $runtime.IndexOf(
  'class HttpEmailOtpGateway implements EmailOtpGateway',
  [StringComparison]::Ordinal
)
Assert-C33EFix3 -Condition (
  $gatewayStart -ge 0 -and $gatewayEnd -gt $gatewayStart
) -Message 'Firebase Social auth gateway boundary changed.'
$gateway = $runtime.Substring($gatewayStart, $gatewayEnd - $gatewayStart)
foreach ($needle in @(
  'Object? firstFailure;',
  'StackTrace? firstFailureStackTrace;',
  'await _authClient.signOut();',
  'await _googleIdentityGateway.signOut();',
  'firstFailure ??= error;',
  'firstFailureStackTrace ??= stackTrace;',
  'Error.throwWithStackTrace(failure, firstFailureStackTrace!);'
)) {
  Assert-C33EFix3 -Condition (
    $gateway.IndexOf($needle, [StringComparison]::Ordinal) -ge 0
  ) -Message "independent cleanup owner is missing: $needle"
}
Assert-C33EFix3 -Condition (
  [regex]::Matches($gateway, 'on Object catch \(error, stackTrace\)').Count -eq 2 -and
  [regex]::Matches($gateway, 'await _authClient[.]signOut\(\);').Count -eq 1 -and
  [regex]::Matches($gateway, 'await _googleIdentityGateway[.]signOut\(\);').Count -eq 1 -and
  -not [regex]::IsMatch(
    $gateway,
    'await _authClient[.]signOut\(\);\s*await _googleIdentityGateway[.]signOut\(\);'
  )
) -Message 'cleanup calls are duplicated or remain success-only sequential.'

$testPath = Resolve-C33EFix3File `
  -Path 'apps/mobile/test/uaw_c33e_fix3_social_auth_rollback_independent_cleanup_test.dart' `
  -Label 'FIX3 behavioral test'
$test = Get-Content -Raw -LiteralPath $testPath
foreach ($needle in @(
  'successful cleanup retains Firebase then Google order',
  'Firebase cleanup failure still attempts Google cleanup',
  'Google cleanup failure follows completed Firebase cleanup',
  'bootstrap and cleanup failure retains signed-out origin recovery',
  'expect(session.isAuthenticated, isFalse);',
  'expect(session.stage, JourneyStage.signIn);',
  'expect(session.busy, isFalse);',
  'expect(session.readyRoute(), origin);',
  "expect(session.errorMessage, isNot(contains('cleanup')));"
)) {
  Assert-C33EFix3 -Condition (
    $test.IndexOf($needle, [StringComparison]::Ordinal) -ge 0
  ) -Message "FIX3 behavioral assertion is missing: $needle"
}

$c30zGate = Resolve-C33EFix3File `
  -Path 'scripts/check-c30z-authentication-method-truth-and-guest-feed-recovery.ps1' `
  -Label 'C30Z authentication truth gate'
& $c30zGate -RepositoryRoot $root -ScopePath $ScopePath | Out-Null
$fix2Gate = Resolve-C33EFix3File `
  -Path 'scripts/check-uaw-c33e-fix2-google-auth-live-provider-readiness.ps1' `
  -Label 'C33E FIX2 live-readiness gate'
& $fix2Gate `
  -Phase implementation `
  -StatePath 'config/google-auth-live-provider-readiness-state-c33e-fix2.json' `
  -ScopePath $ScopePath `
  -RepositoryRoot $root | Out-Null

Write-Output (
  'C33E FIX3 Social auth rollback gate passed: cleanupOwners=2/2; ' +
  'failureBranches=2/2; originalBootstrapRecovery=true; exactOrigin=true; ' +
  'lockedScreen03Changed=false; build=false; device=false; provider=false.'
)
