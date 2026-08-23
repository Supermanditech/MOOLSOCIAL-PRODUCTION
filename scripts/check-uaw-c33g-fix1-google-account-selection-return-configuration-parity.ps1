[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33GFix1 {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) {
    throw "C33G FIX1 Google return configuration parity gate rejected: $Message"
  }
}

function Resolve-C33GFix1File {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C33GFix1 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  Assert-C33GFix1 -Condition (
    Test-Path -LiteralPath $resolved -PathType Leaf
  ) -Message "$Label is missing."
  return $resolved
}

function Assert-C33GFix1Parses {
  param([Parameter(Mandatory)][string]$Path)
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $Path,
    [ref]$tokens,
    [ref]$errors
  )
  Assert-C33GFix1 -Condition (@($errors).Count -eq 0) `
    -Message "PowerShell parser rejected: $Path"
}

$ticketPath = Resolve-C33GFix1File `
  -Path 'config/uaw-c33g-fix1-google-account-selection-return-configuration-parity-ticket.json' `
  -Label 'ticket'
$statePath = Resolve-C33GFix1File `
  -Path 'config/successor-aab-regression-hard-gate-state-c33f.json' `
  -Label 'failed r60.49 state'
$launcherPath = Resolve-C33GFix1File `
  -Path 'tmp/run-c30x-successor-single-aab-founder.ps1' `
  -Label 'founder launcher'
$sessionPath = Resolve-C33GFix1File `
  -Path 'apps/mobile/lib/features/journey01/journey_session.dart' `
  -Label 'JourneySession'
$testPath = Resolve-C33GFix1File `
  -Path 'apps/mobile/test/uaw_c33g_fix1_google_account_selection_return_configuration_parity_test.dart' `
  -Label 'focused Flutter test'

Assert-C33GFix1Parses -Path $launcherPath
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$session = Get-Content -Raw -LiteralPath $sessionPath
$test = Get-Content -Raw -LiteralPath $testPath

Assert-C33GFix1 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C33G-FIX1-GOOGLE-ACCOUNT-SELECTION-RETURN-CONFIGURATION-PARITY' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceMutationAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, classification or authority boundary changed.'

Assert-C33GFix1 -Condition (
  [string]$state.machineState -ceq
    'acceptance_failed_r60_49_google_auth_guest_feed_social_identity_and_create_crash_successor_required' -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$state.actionCounts.upload -eq 1 -and
  [int]$state.actionCounts.install -eq 1 -and
  [int]$state.actionCounts.deviceAcceptance -eq 0 -and
  -not [bool]$state.installResult.acceptanceSucceeded
) -Message 'failed r60.49 identity or 1/1/1/0 history changed.'

foreach ($required in @(
  'oauth_client = @([ordered]@{',
  'client_id = $googleServerClientId',
  'client_type = 3',
  'appinvite_service = [ordered]@{',
  'other_platform_oauth_client = @([ordered]@{',
  'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID = $googleServerClientId',
  'Remove-Item -LiteralPath $path -Force'
)) {
  Assert-C33GFix1 -Condition (
    $launcher.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "founder launcher is missing registration parity owner: $required"
}
Assert-C33GFix1 -Condition (
  ([regex]::Matches(
    $launcher,
    [regex]::Escape('client_id = $googleServerClientId')
  )).Count -eq 2
) -Message 'hidden Web client relationship is not bound exactly twice in google-services registration.'
Assert-C33GFix1 -Condition (
  ([regex]::Matches(
    $launcher,
    [regex]::Escape('client_type = 3')
  )).Count -eq 2
) -Message 'google-services Web client type is not exact.'
Assert-C33GFix1 -Condition (
  -not [regex]::IsMatch(
    $launcher,
    '(?i)\b[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com\b'
  )
) -Message 'founder launcher contains a credential-shaped OAuth client ID literal.'

$syntheticWebClient = '000000-synthetic' + '.apps.googleusercontent.com'
$syntheticServices = [ordered]@{
  client = @([ordered]@{
    oauth_client = @([ordered]@{
      client_id = $syntheticWebClient
      client_type = 3
    })
    services = [ordered]@{
      appinvite_service = [ordered]@{
        other_platform_oauth_client = @([ordered]@{
          client_id = $syntheticWebClient
          client_type = 3
        })
      }
    }
  })
}
$syntheticRoundTrip = (
  $syntheticServices | ConvertTo-Json -Depth 12 | ConvertFrom-Json
)
Assert-C33GFix1 -Condition (
  @($syntheticRoundTrip.client[0].oauth_client).Count -eq 1 -and
  [int]$syntheticRoundTrip.client[0].oauth_client[0].client_type -eq 3 -and
  [string]$syntheticRoundTrip.client[0].oauth_client[0].client_id -ceq
    $syntheticWebClient -and
  @(
    $syntheticRoundTrip.client[0].services.appinvite_service.other_platform_oauth_client
  ).Count -eq 1 -and
  [int](
    $syntheticRoundTrip.client[0].services.appinvite_service.other_platform_oauth_client[0].client_type
  ) -eq 3 -and
  [string](
    $syntheticRoundTrip.client[0].services.appinvite_service.other_platform_oauth_client[0].client_id
  ) -ceq $syntheticWebClient
) -Message 'synthetic value-free google-services parity round trip failed.'
$syntheticRoundTrip = $null
$syntheticServices = $null
$syntheticWebClient = $null

foreach ($required in @(
  "sign-in wasn’t completed.",
  'SocialAuthState.cancelled',
  'Try again or choose another method.'
)) {
  Assert-C33GFix1 -Condition (
    $session.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "JourneySession is missing ambiguous-return recovery owner: $required"
}
Assert-C33GFix1 -Condition (
  -not [regex]::IsMatch(
    $session,
    '\$\{_socialProviderLabel\(provider\)\} sign-in was cancelled[.]'
  )
) -Message 'JourneySession still claims every ambiguous provider return was a user cancellation.'

foreach ($required in @(
  'ambiguous Google account-selection return stays incomplete and retryable',
  "contains('wasn’t completed')",
  "isNot(contains('was cancelled'))",
  'supported Google-backed identity methods remain exact',
  'SocialAuthProvider.youtube'
)) {
  Assert-C33GFix1 -Condition (
    $test.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "focused Flutter test is missing: $required"
}

Write-Output (
  'C33G FIX1 Google return configuration parity gate passed: ' +
  'r60.49 failed counts=1/1/1/0; Web client type=3; ' +
  'hidden registration parity=true; secretValuesObserved=false; ' +
  'buildPlayDevice=false.'
)
