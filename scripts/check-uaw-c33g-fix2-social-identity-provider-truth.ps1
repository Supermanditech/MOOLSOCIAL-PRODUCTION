[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33GFix2 {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C33G FIX2 social identity truth gate rejected: $Message" }
}

function Read-C33GFix2File {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C33GFix2 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  Assert-C33GFix2 -Condition (
    Test-Path -LiteralPath $resolved -PathType Leaf
  ) -Message "$Label is missing."
  return Get-Content -Raw -LiteralPath $resolved
}

function Get-C33GFix2CanonicalTextSha256 {
  param([Parameter(Mandatory)][string]$Path)
  $text = [IO.File]::ReadAllText($Path)
  $canonical = $text.Replace("`r`n", "`n").Replace("`r", "`n")
  $encoding = New-Object Text.UTF8Encoding($false)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString(
      $sha.ComputeHash($encoding.GetBytes($canonical))
    )).Replace('-', '')
  } finally {
    $sha.Dispose()
  }
}

function Test-C33GFix2FacebookAvailabilitySource {
  param([Parameter(Mandatory)][string]$RuntimeSource)
  return [regex]::IsMatch(
    $RuntimeSource,
    '(?s)bool\s+get\s+facebookAvailable\s*=>\s*' +
      'facebookEnabled\s*&&\s*facebookNativeAdapterInstalled\s*&&\s*' +
      'facebookProviderQualified\s*&&\s*' +
      'facebookAndroidConfigurationQualified\s*&&\s*' +
      'facebookRevocationQualified\s*&&\s*facebookDataDeletionQualified\s*;'
  )
}

function Test-C33GFix2ProductionProviderComposition {
  param([Parameter(Mandatory)][string]$MainSource)
  $functionMatch = [regex]::Match(
    $MainSource,
    '(?s)Set<SocialAuthProvider>\s+_productionSocialIdentityProviders\s*\(' +
      '.*?\)\s*=>\s*<SocialAuthProvider>\{(?<body>.*?)\};'
  )
  if (-not $functionMatch.Success) { return $false }
  $body = $functionMatch.Groups['body'].Value
  return (
    [regex]::IsMatch(
      $body,
      'if\s*\(configuration[.]googleAndYoutubeAvailable\)\s*' +
        'SocialAuthProvider[.]google'
    ) -and
    [regex]::IsMatch(
      $body,
      'if\s*\(!googleOnlyForensicMode\s*&&\s*' +
        'configuration[.]googleAndYoutubeAvailable\)\s*' +
        'SocialAuthProvider[.]youtube'
    ) -and
    [regex]::IsMatch(
      $body,
      'if\s*\(!googleOnlyForensicMode\s*&&\s*' +
        'configuration[.]appleAvailable\)\s*SocialAuthProvider[.]apple'
    ) -and
    [regex]::IsMatch(
      $body,
      'if\s*\(!googleOnlyForensicMode\s*&&\s*' +
        'configuration[.]xAvailable\)\s*SocialAuthProvider[.]x'
    ) -and
    [regex]::IsMatch(
      $body,
      'if\s*\(!googleOnlyForensicMode\s*&&\s*' +
        'configuration[.]instagramAvailable\)\s*' +
        'SocialAuthProvider[.]instagram'
    ) -and
    [regex]::IsMatch(
      $body,
      'if\s*\(!googleOnlyForensicMode\s*&&\s*' +
        'configuration[.]facebookAvailable\)\s*' +
        'SocialAuthProvider[.]facebook'
    )
  )
}

function Test-C33GFix2SharedGoogleIdentityDispatch {
  param([Parameter(Mandatory)][string]$GatewaySource)
  return (
    [regex]::IsMatch(
      $GatewaySource,
      '(?s)if\s*\(\s*provider\s*==\s*SocialAuthProvider[.]google\s*' +
        '[|][|]\s*provider\s*==\s*SocialAuthProvider[.]youtube\s*\)\s*' +
        '\{\s*userId\s*=\s*await\s+_signInWithGoogleIdentity\(\);'
    ) -and
    [regex]::Matches(
      $GatewaySource,
      'await\s+_signInWithGoogleIdentity\(\)'
    ).Count -eq 1
  )
}

function Test-C33GFix2CurrentFacebookSuccessor {
  param(
    [Parameter(Mandatory)][string]$TicketId,
    [Parameter(Mandatory)][string]$TicketHash,
    [Parameter(Mandatory)][string]$ClaimTask,
    [Parameter(Mandatory)][int]$ClaimOwnerCount,
    [Parameter(Mandatory)][bool]$ClaimHasGate,
    [Parameter(Mandatory)][bool]$AvailabilityQualified,
    [Parameter(Mandatory)][bool]$SourceShapeQualified,
    [Parameter(Mandatory)][bool]$BuildAuthorized,
    [Parameter(Mandatory)][bool]$DeviceAuthorized,
    [Parameter(Mandatory)][bool]$ExternalAuthorized,
    [Parameter(Mandatory)][bool]$SecretAuthorized
  )
  return (
    $TicketId -ceq 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' -and
    $TicketHash -ceq
      '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' -and
    $ClaimTask -ceq '/root/codex_auth_facebook_prebuild_20260824' -and
    $ClaimOwnerCount -eq 24 -and
    $ClaimHasGate -and
    $AvailabilityQualified -and
    $SourceShapeQualified -and
    -not $BuildAuthorized -and
    -not $DeviceAuthorized -and
    -not $ExternalAuthorized -and
    -not $SecretAuthorized
  )
}

$ticketRaw = Read-C33GFix2File `
  -Path 'config/uaw-c33g-fix2-social-identity-provider-truth-ticket.json' `
  -Label 'ticket'
$failedStateRaw = Read-C33GFix2File `
  -Path 'config/successor-aab-regression-hard-gate-state-c33f.json' `
  -Label 'failed r60.49 state'
$main = Read-C33GFix2File -Path 'apps/mobile/lib/main.dart' -Label 'main'
$runtime = Read-C33GFix2File `
  -Path 'apps/mobile/lib/core/auth/public_auth_runtime_configuration.dart' `
  -Label 'public auth runtime configuration'
$session = Read-C33GFix2File `
  -Path 'apps/mobile/lib/features/journey01/journey_session.dart' `
  -Label 'JourneySession'
$gateway = Read-C33GFix2File `
  -Path 'apps/mobile/lib/features/journey01/review_journey_services.dart' `
  -Label 'Firebase social gateway'
$screen = Read-C33GFix2File `
  -Path 'apps/mobile/lib/ui_v2/screens/screen03_login/login_screen_v2.dart' `
  -Label 'Screen 03'
$test = Read-C33GFix2File `
  -Path 'apps/mobile/test/uaw_c33g_fix2_social_identity_provider_truth_test.dart' `
  -Label 'focused Flutter test'

$ticket = $ticketRaw | ConvertFrom-Json
$failedState = $failedStateRaw | ConvertFrom-Json
Assert-C33GFix2 -Condition (
  [string]$ticket.ticketId -ceq 'UAW-C33G-FIX2-SOCIAL-IDENTITY-PROVIDER-TRUTH' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.providerWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized
) -Message 'ticket identity, classification or authority boundary changed.'
Assert-C33GFix2 -Condition (
  [string]$failedState.machineState -ceq
    'acceptance_failed_r60_49_google_auth_guest_feed_social_identity_and_create_crash_successor_required' -and
  [int]$failedState.actionCounts.build -eq 1 -and
  [int]$failedState.actionCounts.upload -eq 1 -and
  [int]$failedState.actionCounts.install -eq 1 -and
  [int]$failedState.actionCounts.deviceAcceptance -eq 0
) -Message 'failed r60.49 identity or 1/1/1/0 history changed.'

$coordinationRaw = Read-C33GFix2File `
  -Path 'config/codex-subagent-coordination-policy.json' `
  -Label 'coordination policy'
$scopeRaw = Read-C33GFix2File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state'
$facebookTicketRelative = `
  'docs/quality/UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824.md'
$facebookTicketRaw = Read-C33GFix2File `
  -Path $facebookTicketRelative -Label 'current Facebook ticket'
$facebookTicketPath = [IO.Path]::GetFullPath((Join-Path `
  $root $facebookTicketRelative
))
$facebookTicketHash = Get-C33GFix2CanonicalTextSha256 `
  -Path $facebookTicketPath
$coordination = $coordinationRaw | ConvertFrom-Json
$scope = $scopeRaw | ConvertFrom-Json
$gitDiscipline = $coordination.productionGitDiscipline
$authBatch = $gitDiscipline.agentTicketQueues.authPrebuildBatch
$facebookClaims = @($coordination.activeClaims | Where-Object {
  [string]$_.task -ceq '/root/codex_auth_facebook_prebuild_20260824'
})
$completedPrebuildProviders = @($authBatch.completedPrebuildProviders)
$facebookClaimTask = if ($facebookClaims.Count -eq 1) {
  [string]$facebookClaims[0].task
} else {
  'invalid'
}
$facebookClaimOwnerCount = if ($facebookClaims.Count -eq 1) {
  @($facebookClaims[0].owners).Count
} else {
  0
}
$facebookClaimHasGate = (
  $facebookClaims.Count -eq 1 -and
  @($facebookClaims[0].owners) -ccontains
    'scripts/check-uaw-c33g-fix2-social-identity-provider-truth.ps1'
)
$facebookAvailabilityQualified = `
  Test-C33GFix2FacebookAvailabilitySource -RuntimeSource $runtime
$facebookSourceShapeQualified = `
  Test-C33GFix2ProductionProviderComposition -MainSource $main
$facebookBatchHeld = (
  [string]$gitDiscipline.acceptedRuntimeBaseline.head -ceq
    'f105195ba505dcc9f25a35ab64aab104dadb47c2' -and
  [string]$gitDiscipline.acceptedRuntimeBaseline.tag -ceq
    'moolsocial-google-auth-r60.87-accepted-20260823' -and
  [string]$authBatch.state -ceq
    'founder_authorized_runtime_acceptance_deferred_2026_08_24' -and
  [string]$authBatch.currentProvider -ceq 'facebook' -and
  [int]$authBatch.maximumActiveMutationTickets -eq 1 -and
  [bool]$authBatch.runtimeAcceptanceDeferredUntilOneCombinedApk -and
  [bool]$authBatch.finalTicketCloseStillRequired -and
  $completedPrebuildProviders.Count -eq 1 -and
  [string]$completedPrebuildProviders[0].provider -ceq 'email_link' -and
  [string]$completedPrebuildProviders[0].implementationCommit -ceq
    '883f1d06c315438823c801b184b990b672c77f85' -and
  [string]$completedPrebuildProviders[0].qualificationCommit -ceq
    '84ab8e55414d4b87b3442a3b9631fe058efc6efe' -and
  [bool]$completedPrebuildProviders[0].remoteQualified -and
  [bool]$completedPrebuildProviders[0].runtimeAcceptancePending -and
  $facebookClaims.Count -eq 1 -and
  [string]$facebookClaims[0].role -ceq 'primary' -and
  @($facebookClaims[0].owners) -ccontains $facebookTicketRelative -and
  $facebookTicketRaw.Contains(
    '# UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824'
  ) -and
  $facebookTicketRaw.Contains(
    'Real Facebook and OPPO acceptance remains deferred to'
  ) -and
  [string]$scope.ticket.id -ceq 'UAW-CODEX-EMAIL-LINK-AUTH-20260823' -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq
    'UAW-CODEX-EMAIL-LINK-AUTH-20260823' -and
  [bool]$scope.execution.runtimeWriteAuthorized -and
  [bool]$scope.execution.testOrGateWriteAuthorized -and
  -not [bool]$scope.execution.backendWriteAuthorized -and
  -not [bool]$scope.execution.buildAuthorized -and
  -not [bool]$scope.execution.deviceInstallAuthorized -and
  -not [bool]$scope.execution.playUploadAuthorized -and
  -not [bool]$scope.execution.externalServiceWriteAuthorized -and
  -not [bool]$scope.execution.otherProviderWriteAuthorized -and
  -not [bool]$scope.execution.liveEmailSendAuthorized -and
  -not [bool]$scope.execution.secretValueAccessAuthorized
)

Assert-C33GFix2 -Condition (Test-C33GFix2CurrentFacebookSuccessor `
  -TicketId 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -AvailabilityQualified $true -SourceShapeQualified $true `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
) -Message 'current Facebook successor positive fixture failed.'
Assert-C33GFix2 -Condition (-not (Test-C33GFix2CurrentFacebookSuccessor `
  -TicketId 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-WRONG' `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -AvailabilityQualified $true -SourceShapeQualified $true `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) -Message 'wrong-ticket fixture passed unexpectedly.'
Assert-C33GFix2 -Condition (-not (Test-C33GFix2CurrentFacebookSuccessor `
  -TicketId 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' `
  -TicketHash '0919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -AvailabilityQualified $true -SourceShapeQualified $true `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) -Message 'wrong-hash fixture passed unexpectedly.'
Assert-C33GFix2 -Condition (-not (Test-C33GFix2CurrentFacebookSuccessor `
  -TicketId 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_wrong' `
  -ClaimOwnerCount 23 -ClaimHasGate $false `
  -AvailabilityQualified $true -SourceShapeQualified $true `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) -Message 'wrong-claim fixture passed unexpectedly.'
Assert-C33GFix2 -Condition (-not (Test-C33GFix2CurrentFacebookSuccessor `
  -TicketId 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -AvailabilityQualified $false -SourceShapeQualified $true `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) -Message 'wrong-availability fixture passed unexpectedly.'
Assert-C33GFix2 -Condition (-not (Test-C33GFix2CurrentFacebookSuccessor `
  -TicketId 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -AvailabilityQualified $true -SourceShapeQualified $false `
  -BuildAuthorized $false -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) -Message 'wrong-source-shape fixture passed unexpectedly.'
Assert-C33GFix2 -Condition (-not (Test-C33GFix2CurrentFacebookSuccessor `
  -TicketId 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -AvailabilityQualified $true -SourceShapeQualified $true `
  -BuildAuthorized $true -DeviceAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) -Message 'wrong-authority fixture passed unexpectedly.'

$currentFacebookSuccessor = (
  $facebookBatchHeld -and
  (Test-C33GFix2CurrentFacebookSuccessor `
    -TicketId 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' `
    -TicketHash $facebookTicketHash `
    -ClaimTask $facebookClaimTask `
    -ClaimOwnerCount $facebookClaimOwnerCount `
    -ClaimHasGate $facebookClaimHasGate `
    -AvailabilityQualified $facebookAvailabilityQualified `
    -SourceShapeQualified $facebookSourceShapeQualified `
    -BuildAuthorized ([bool]$scope.execution.buildAuthorized) `
    -DeviceAuthorized ([bool]$scope.execution.deviceInstallAuthorized) `
    -ExternalAuthorized ([bool]$scope.execution.externalServiceWriteAuthorized) `
    -SecretAuthorized ([bool]$scope.execution.secretValueAccessAuthorized))
)

$allowListMatch = [regex]::Match(
  $main,
  '(?s)const _productionSocialIdentityProviders = <SocialAuthProvider>\{(?<body>.*?)\};'
)
if ($currentFacebookSuccessor) {
  Assert-C33GFix2 -Condition $facebookAvailabilityQualified `
    -Message 'current Facebook availability predicate is incomplete.'
  Assert-C33GFix2 -Condition $facebookSourceShapeQualified `
    -Message 'current dynamic production provider composition is incomplete.'
  $wrongAvailabilityFixture = $runtime.Replace(
    'facebookDataDeletionQualified',
    'facebookEnabled'
  )
  Assert-C33GFix2 -Condition (-not (
    Test-C33GFix2FacebookAvailabilitySource `
      -RuntimeSource $wrongAvailabilityFixture
  )) -Message 'incomplete Facebook availability source fixture passed unexpectedly.'
  $wrongCompositionFixture = $main.Replace(
    '!googleOnlyForensicMode && configuration.facebookAvailable',
    'configuration.facebookAvailable'
  )
  Assert-C33GFix2 -Condition (-not (
    Test-C33GFix2ProductionProviderComposition `
      -MainSource $wrongCompositionFixture
  )) -Message 'Google-only Facebook exclusion fixture passed unexpectedly.'
} else {
  Assert-C33GFix2 -Condition $allowListMatch.Success `
    -Message 'production Social identity allow-list is missing.'
  $allowListBody = $allowListMatch.Groups['body'].Value
  $allowed = @(
    [regex]::Matches($allowListBody, 'SocialAuthProvider[.](?<name>[a-z]+)') |
      ForEach-Object { $_.Groups['name'].Value }
  )
  Assert-C33GFix2 -Condition (
    $allowed.Count -eq 2 -and
    $allowed -ccontains 'google' -and
    $allowed -ccontains 'youtube'
  ) -Message 'production identity allow-list must be exactly Google and YouTube.'
}

foreach ($required in @(
  'if (!isSocialAuthProviderAvailable(provider))',
  'sign-in is not available right now.',
  'return false;'
)) {
  Assert-C33GFix2 -Condition (
    $session.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "JourneySession is missing local fail-closed truth: $required"
}
if ($currentFacebookSuccessor) {
  Assert-C33GFix2 -Condition (
    Test-C33GFix2SharedGoogleIdentityDispatch -GatewaySource $gateway
  ) -Message 'Google and YouTube do not share the Google identity owner.'
  $splitIdentityFixture = (
    'if (provider == SocialAuthProvider.google) { ' +
    'userId = await _signInWithGoogleIdentity(); } ' +
    'if (provider == SocialAuthProvider.youtube) { ' +
    'userId = await _signInWithGoogleIdentity(); }'
  )
  Assert-C33GFix2 -Condition (-not (
    Test-C33GFix2SharedGoogleIdentityDispatch `
      -GatewaySource $splitIdentityFixture
  )) -Message 'split Google/YouTube identity fixture passed unexpectedly.'
} else {
  Assert-C33GFix2 -Condition ([regex]::IsMatch(
    $gateway,
    'SocialAuthProvider[.]google\s*[|][|]\s*SocialAuthProvider[.]youtube\s*=>\s*await\s*_signInWithGoogleIdentity[(][)]'
  )) -Message 'Google and YouTube do not share the Google identity owner.'
}
foreach ($required in @(
  'for (final provider in SocialAuthProvider.values)',
  'Key(''screen03-provider-${provider.name}'')'
)) {
  Assert-C33GFix2 -Condition (
    $screen.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "Screen 03 is missing visible provider ownership: $required"
}
foreach ($required in @(
  'production unsupported identity taps stay local with zero gateway dispatch',
  'SocialAuthProvider.apple',
  'SocialAuthProvider.x',
  'SocialAuthProvider.instagram',
  'SocialAuthProvider.facebook',
  'expect(gateway.signInCount, 0',
  'production Google and YouTube identity taps reach the Google-backed gateway',
  'expect(gateway.signInCount, 2)'
)) {
  Assert-C33GFix2 -Condition (
    $test.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "focused Flutter matrix is missing: $required"
}

if ($currentFacebookSuccessor) {
  Write-Output (
    'C33G FIX2 social identity truth gate passed: visible=6; ' +
    'activeTicket=UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824; ' +
    'facebookAvailability=qualified; googleOnlyForensic=facebookExcluded; ' +
    'googleYoutubeShared=true; newScreens=0; newRoutes=0; ' +
    'providerWrites=false; buildPlayDevice=false; privateValues=false.'
  )
} else {
  Write-Output (
    'C33G FIX2 social identity truth gate passed: visible=6; ' +
    'productionAvailable=Google+YouTube; unsupportedLocal=4; ' +
    'providerWrites=false; buildPlayDevice=false.'
  )
}
