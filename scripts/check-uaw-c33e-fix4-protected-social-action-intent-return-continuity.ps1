[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$ScopePath = 'config/mvp-scope-gate-state.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}

function Assert-C33EFix4 {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) {
    throw "C33E FIX4 protected Social action-intent gate rejected: $Message"
  }
}

$root = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
$rootPrefix = $root + [System.IO.Path]::DirectorySeparatorChar

function Resolve-C33EFix4File {
  param([string]$Path, [string]$Label)
  $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
    $Path
  } else {
    Join-Path $root $Path
  }
  $resolved = [System.IO.Path]::GetFullPath($candidate)
  Assert-C33EFix4 (
    $resolved.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) "$Label is missing or outside the repository."
  return $resolved
}

$ticketId = 'UAW-C33E-FIX4-PROTECTED-SOCIAL-ACTION-INTENT-RETURN-CONTINUITY'
$ticketSha256 = 'E243C28BEEB4732C8F512053146C41229AAD9E3109C87A3C99D041FA79499047'
$ticketPath = Resolve-C33EFix4File `
  'config/uaw-c33e-fix4-protected-social-action-intent-return-continuity-ticket.json' `
  'FIX4 ticket'
Assert-C33EFix4 (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq $ticketSha256
) 'FIX4 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33EFix4 (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) 'FIX4 ticket identity, classification or authority changed.'

$c33fTicketId =
  'UAW-C33F-R60-49-GOOGLE-AUTH-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
$c33fTicketSha256 = '815C70015058DE27B0F117517FB7599F6D7D99D340A217D65F9BFF3E163660C2'
$c33fTicketPath = Resolve-C33EFix4File `
  'config/uaw-c33f-r60-49-google-auth-successor-aab-play-internal-oppo-acceptance-ticket.json' `
  'C33F successor release ticket'
Assert-C33EFix4 (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $c33fTicketPath).Hash -ceq
    $c33fTicketSha256
) 'C33F successor release ticket bytes changed.'
$c33fTicket = Get-Content -Raw -LiteralPath $c33fTicketPath | ConvertFrom-Json
Assert-C33EFix4 (
  [string]$c33fTicket.ticketId -ceq $c33fTicketId -and
  [string]$c33fTicket.candidate.versionName -ceq '1.0.0-r60.49' -and
  [string]$c33fTicket.candidate.versionCode -ceq '2026081349' -and
  [bool]$c33fTicket.authority.oneAabBuildAuthorizedAfterAllGates -and
  -not [bool]$c33fTicket.authority.agentSecretValueAccessAuthorized -and
  -not [bool]$c33fTicket.authority.otherTrackAuthorized -and
  -not [bool]$c33fTicket.authority.providerDeploymentAuthorized
) 'C33F successor release ticket identity or authority changed.'

$scope = Get-Content -Raw -LiteralPath (
  Resolve-C33EFix4File $ScopePath 'MVP scope state'
) | ConvertFrom-Json
$activeTicketId = [string]$scope.ticket.id
$activeFix4 = $activeTicketId -ceq $ticketId
$activeC33F = $activeTicketId -ceq $c33fTicketId
$selectionValid = if ($activeFix4) {
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
    $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
    $ticketSha256 -and
  [bool]$scope.execution.runtimeWriteAuthorized -and
  [string]$scope.providerGate.nextTicket -ceq $ticketId
} else {
  $activeC33F -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $c33fTicketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
    $c33fTicketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
    $c33fTicketSha256 -and
  [string]$scope.preTicketSelectionCheckpoint.priorC33EFix4QualifiedAssessment.ticketId -ceq
    $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.priorC33EFix4QualifiedAssessment.manifestSha256 -ceq
    $ticketSha256 -and
  -not [bool]$scope.execution.runtimeWriteAuthorized -and
  [string]$scope.providerGate.nextTicket -ceq $c33fTicketId
}
Assert-C33EFix4 (
  [string]$scope.state -ceq 'ticket_disclosed_and_authorized' -and
  $selectionValid -and
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
  -not [bool]$scope.providerGate.DevProviderDeploymentAuthorized -and
  -not [bool]$scope.providerGate.emailOrQuotaSubmissionAuthorized
) 'FIX4 selected scope or authority boundary changed.'

$approvedUiGate = Resolve-C33EFix4File `
  'scripts/check-approved-ui-locks.ps1' `
  'approved UI lock gate'
& $approvedUiGate -RepositoryRoot $root | Out-Null

$owners = [ordered]@{
  'apps/mobile/lib/ui_v2/social/social_v2_public_content.dart' =
    'E7AD374BC9492DE317500AE710843E09945F16EC7E028BA1347D64EA2C4FEE5D'
  'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart' =
    'E46013FEFA4A48D969957F890516543B33BBD4F3A4938A3437237C71802708CA'
  'apps/mobile/lib/features/journey01/journey_router.dart' =
    'E86D02E68DA10F480A62D89D06CADDB31A60DBD735952D6A4D9ADE50A29647A0'
  'apps/mobile/test/c30t_social_auth_and_feed_gateway_test.dart' =
    '82A782DEEBD5F14E15F7424DC5FE49513B90D13CBB8B669911A9DFA72208A4B1'
  'apps/mobile/test/social_v2_create_publication_test.dart' =
    '6D01EF7A1E85856524BCECDC5A57D4FE36919FDC60A5E6999A9A0D3B2B45E7C6'
  'apps/mobile/test/uaw_c33e_fix4_protected_social_action_intent_return_continuity_test.dart' =
    '8B81B46FE1A668D92BE741CC61B510FF42C63340C4A198BFEB9FB9F7CAA600ED'
}
$ownerText = @{}
foreach ($entry in $owners.GetEnumerator()) {
  $path = Resolve-C33EFix4File $entry.Key $entry.Key
  Assert-C33EFix4 (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -ceq $entry.Value
  ) "$($entry.Key) bytes changed."
  $ownerText[$entry.Key] = Get-Content -Raw -LiteralPath $path
}

$publicContent = [string]$ownerText['apps/mobile/lib/ui_v2/social/social_v2_public_content.dart']
foreach ($needle in @(
  'enum SocialProtectedAction { like, reply, repost, save, vote }',
  'class SocialProtectedActionIntent',
  'ValueChanged<SocialProtectedActionIntent>? onAuthenticationRequired',
  'action: SocialProtectedAction.vote',
  'choiceIndex: index',
  'requireAuthentication(intent)',
  'action: SocialProtectedAction.like',
  'action: SocialProtectedAction.repost',
  'action: SocialProtectedAction.save'
)) {
  Assert-C33EFix4 $publicContent.Contains($needle) `
    "public action intent contract is missing: $needle"
}

$consumer = [string]$ownerText['apps/mobile/lib/ui_v2/social/social_v2_consumer.dart']
foreach ($needle in @(
  'final String? initialAction;',
  'final String? initialChoice;',
  'SocialProtectedActionIntent.tryParse(',
  '_handledInitialFeedActionToken == token',
  '_consumeInitialFeedActionRoute(item.id);',
  'if (!item.liked)',
  'if (!item.reposted)',
  'if (!item.saved)',
  'if (item.selectedChoiceIndex == null)',
  'if (currentItem != null) _openComments(currentItem);',
  "'That Feed action could not be restored. Nothing changed.'",
  "'action': intent.routeValue",
  "'choice': '`$choiceIndex'"
)) {
  Assert-C33EFix4 $consumer.Contains($needle) `
    "Social return consumer contract is missing: $needle"
}
$consumeIndex = $consumer.IndexOf('_consumeInitialFeedActionRoute(item.id);')
$switchIndex = $consumer.IndexOf('switch (intent.action)', $consumeIndex)
Assert-C33EFix4 ($consumeIndex -ge 0 -and $switchIndex -gt $consumeIndex) `
  'resumable route intent is not consumed before action dispatch.'

$router = [string]$ownerText['apps/mobile/lib/features/journey01/journey_router.dart']
Assert-C33EFix4 (
  $router.Contains("initialAction: state.uri.queryParameters['action']") -and
  $router.Contains("initialChoice: state.uri.queryParameters['choice']")
) 'Journey router no longer forwards protected Social action metadata.'

$behavioral = [string]$ownerText['apps/mobile/test/uaw_c33e_fix4_protected_social_action_intent_return_continuity_test.dart']
foreach ($needle in @(
  'carries the exact signed-out Poll choice through sign-in',
  'consumes Like return once and removes resumable route intent',
  'never toggles an already completed desired state off',
  'preserves and applies the selected Poll choice once',
  'reopens Replies with the existing signed-out draft',
  'rejects an out-of-range Poll choice without dispatch',
  'rejects an unknown action without gateway dispatch'
)) {
  Assert-C33EFix4 $behavioral.Contains($needle) `
    "FIX4 behavioral assertion is missing: $needle"
}
$publicationTest = [string]$ownerText['apps/mobile/test/social_v2_create_publication_test.dart']
Assert-C33EFix4 (
  $publicationTest.Contains('onAuthenticationRequired: authenticationRequests.add') -and
  $publicationTest.Contains('SocialProtectedAction.like') -and
  $publicationTest.Contains('SocialProtectedAction.save') -and
  $publicationTest.Contains('SocialProtectedAction.vote') -and
  $publicationTest.Contains('authenticationRequests.last.choiceIndex, 0')
) 'existing public-card authentication test no longer verifies typed intents.'

foreach ($priorGate in @(
  'scripts/check-c30z-authentication-method-truth-and-guest-feed-recovery.ps1',
  'scripts/check-uaw-c33e-fix2-google-auth-live-provider-readiness.ps1',
  'scripts/check-uaw-c33e-fix3-social-auth-rollback-independent-cleanup.ps1'
)) {
  $gate = Resolve-C33EFix4File $priorGate $priorGate
  & $gate -RepositoryRoot $root -ScopePath $ScopePath | Out-Null
}

Write-Output (
  'C33E FIX4 protected Social action-intent gate passed: actions=5; ' +
  'voteChoice=true; consumeBeforeDispatch=true; desiredStateSafe=true; ' +
  'replyDraft=true; liveProvider=false; build=false; device=false.'
)
