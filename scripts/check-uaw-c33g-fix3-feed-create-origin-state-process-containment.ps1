[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33GFix3 {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C33G FIX3 Feed/Create containment gate rejected: $Message" }
}

function Read-C33GFix3File {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C33GFix3 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  Assert-C33GFix3 -Condition (
    Test-Path -LiteralPath $resolved -PathType Leaf
  ) -Message "$Label is missing."
  return Get-Content -Raw -LiteralPath $resolved
}

$ticket = (Read-C33GFix3File `
  -Path 'config/uaw-c33g-fix3-feed-create-origin-state-process-containment-ticket.json' `
  -Label 'ticket') | ConvertFrom-Json
$failedState = (Read-C33GFix3File `
  -Path 'config/successor-aab-regression-hard-gate-state-c33f.json' `
  -Label 'failed r60.49 state') | ConvertFrom-Json
$router = Read-C33GFix3File `
  -Path 'apps/mobile/lib/features/journey01/journey_router.dart' `
  -Label 'Journey router'
$consumer = Read-C33GFix3File `
  -Path 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart' `
  -Label 'Social consumer'
$session = Read-C33GFix3File `
  -Path 'apps/mobile/lib/features/journey01/journey_session.dart' `
  -Label 'JourneySession'
$services = Read-C33GFix3File `
  -Path 'apps/mobile/lib/features/journey01/journey_services.dart' `
  -Label 'journey snapshot contract'
$store = Read-C33GFix3File `
  -Path 'apps/mobile/lib/features/journey01/review_journey_services.dart' `
  -Label 'journey persistence owner'
$focusedTest = Read-C33GFix3File `
  -Path 'apps/mobile/test/uaw_c33g_fix3_feed_create_origin_state_process_containment_test.dart' `
  -Label 'focused Flutter matrix'
$existingTest = Read-C33GFix3File `
  -Path 'apps/mobile/test/c30t_social_auth_and_feed_gateway_test.dart' `
  -Label 'existing Feed action matrix'

Assert-C33GFix3 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C33G-FIX3-FEED-CREATE-ORIGIN-STATE-PROCESS-CONTAINMENT' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.backendWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized
) -Message 'ticket identity, classification or authority boundary changed.'
Assert-C33GFix3 -Condition (
  [string]$failedState.machineState -ceq
    'acceptance_failed_r60_49_google_auth_guest_feed_social_identity_and_create_crash_successor_required' -and
  [int]$failedState.actionCounts.build -eq 1 -and
  [int]$failedState.actionCounts.upload -eq 1 -and
  [int]$failedState.actionCounts.install -eq 1 -and
  [int]$failedState.actionCounts.deviceAcceptance -eq 0
) -Message 'failed r60.49 identity or 1/1/1/0 history changed.'

Assert-C33GFix3 -Condition ([regex]::IsMatch(
  $router,
  "(?s)final authenticatedRoute\s*=\s*location[.]startsWith[(]'/app/chat'[)]\s*[|][|]\s*[(]location == '/app/social'\s*&&\s*state[.]uri[.]queryParameters\['sub'\] == 'create'[)]"
)) -Message 'router must protect Create but not public Feed.'
Assert-C33GFix3 -Condition (
  -not [regex]::IsMatch(
    $router,
    "queryParameters\['sub'\] == 'feed'"
  )
) -Message 'router incorrectly treats public Feed as an authenticated route.'
Assert-C33GFix3 -Condition (
  ([regex]::Matches(
    $consumer,
    "returnLocation: '/app/social[?]sub=create'"
  )).Count -eq 2
) -Message 'Social Create entry points do not preserve the exact protected return.'
$cancelOriginNeedle = 'cancelLocation: ''/app/social?sub=${_tab.name}'','
$selectStart = $consumer.IndexOf(
  'void _selectChoice(String choiceId)',
  [StringComparison]::Ordinal
)
$createStart = $consumer.IndexOf(
  'void _openCreationGateway()',
  [StringComparison]::Ordinal
)
$youtubeStart = $consumer.IndexOf(
  'Future<void> _openYouTubeChannelStatus()',
  [StringComparison]::Ordinal
)
Assert-C33GFix3 -Condition (
  $selectStart -ge 0 -and
  $createStart -gt $selectStart -and
  $youtubeStart -gt $createStart
) -Message 'Social Create ownership method boundaries changed.'
$selectBlock = $consumer.Substring($selectStart, $createStart - $selectStart)
$createBlock = $consumer.Substring($createStart, $youtubeStart - $createStart)
Assert-C33GFix3 -Condition (
  ([regex]::Matches(
    $selectBlock,
    [regex]::Escape($cancelOriginNeedle)
  )).Count -eq 1 -and
  ([regex]::Matches(
    $createBlock,
    [regex]::Escape($cancelOriginNeedle)
  )).Count -eq 1
) -Message 'Social Create entry points do not preserve their exact cancellation origin.'

foreach ($required in @(
  'final resumesPersistedAuthentication =',
  '_requiresAuthentication(pendingAuthenticationUri)',
  'stage = resumesPersistedAuthentication',
  'pendingAuthenticationCancelRoute:',
  'pendingAuthenticationPurpose:',
  'return subAction == ''feed'' && uri.queryParameters.containsKey(''action'');',
  'returnTo = null;',
  '_persist(setupComplete: true);'
)) {
  Assert-C33GFix3 -Condition (
    $session.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "JourneySession restart containment is missing: $required"
}
foreach ($required in @(
  'final String? pendingAuthenticationCancelRoute;',
  'final String? pendingAuthenticationPurpose;'
)) {
  Assert-C33GFix3 -Condition (
    $services.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "JourneySnapshot is missing: $required"
}
foreach ($required in @(
  'journey01.pending_authentication_cancel_route',
  'journey01.pending_authentication_purpose',
  'snapshot.pendingAuthenticationCancelRoute',
  'snapshot.pendingAuthenticationPurpose'
)) {
  Assert-C33GFix3 -Condition (
    $store.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "journey persistence owner is missing: $required"
}

foreach ($required in @(
  'guest public Feed opens without authentication or exception',
  'guest Create from ${origin.key} preserves exact sign-in and cancel origins',
  "'home': 'videos'",
  "'feed': 'feed'",
  'authenticated direct Create renders and closes without exception',
  'shared-post Create intent survives restart then supports cancel retry success',
  'expect(tester.takeException(), isNull)',
  'pendingAuthenticationCancelRoute',
  'pendingAuthenticationPurpose',
  'Journey persistence did not settle within 20 microtasks.'
)) {
  Assert-C33GFix3 -Condition (
    $focusedTest.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "focused origin/state/process matrix is missing: $required"
}
foreach ($required in @(
  '/app/social?sub=create&state=shared-post&item=public-action-truth',
  'C30T guest Like enters sign-in and preserves exact Feed return',
  'C30T Feed Create uses the authenticated creation gateway'
)) {
  Assert-C33GFix3 -Condition (
    $existingTest.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "existing protected action coverage is missing: $required"
}

Write-Output (
  'C33G FIX3 Feed/Create containment gate passed: guestFeed=public; ' +
  'Create=protected; origins=home+feed+shared-post+retained-state; ' +
  'r60.49 failed preserved; buildPlayDevice=false.'
)
