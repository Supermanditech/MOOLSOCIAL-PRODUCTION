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

$ticketRaw = Read-C33GFix2File `
  -Path 'config/uaw-c33g-fix2-social-identity-provider-truth-ticket.json' `
  -Label 'ticket'
$failedStateRaw = Read-C33GFix2File `
  -Path 'config/successor-aab-regression-hard-gate-state-c33f.json' `
  -Label 'failed r60.49 state'
$main = Read-C33GFix2File -Path 'apps/mobile/lib/main.dart' -Label 'main'
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

$allowListMatch = [regex]::Match(
  $main,
  '(?s)const _productionSocialIdentityProviders = <SocialAuthProvider>\{(?<body>.*?)\};'
)
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

foreach ($required in @(
  'if (!isSocialAuthProviderAvailable(provider))',
  'sign-in is not available right now.',
  'return false;'
)) {
  Assert-C33GFix2 -Condition (
    $session.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "JourneySession is missing local fail-closed truth: $required"
}
Assert-C33GFix2 -Condition ([regex]::IsMatch(
  $gateway,
  'SocialAuthProvider[.]google\s*[|][|]\s*SocialAuthProvider[.]youtube\s*=>\s*await\s*_signInWithGoogleIdentity[(][)]'
)) -Message 'Google and YouTube do not share the Google identity owner.'
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

Write-Output (
  'C33G FIX2 social identity truth gate passed: visible=6; ' +
  'productionAvailable=Google+YouTube; unsupportedLocal=4; ' +
  'providerWrites=false; buildPlayDevice=false.'
)
