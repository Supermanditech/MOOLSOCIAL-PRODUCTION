[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Read-Fix11Owner([string]$RelativePath) {
  $path = Join-Path $root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "FIX11 Google forensic readiness rejected: missing owner $RelativePath"
  }
  return Get-Content -LiteralPath $path -Raw
}

function Assert-Fix11([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "FIX11 Google forensic readiness rejected: $Message"
  }
}

$candidate = 'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR'
$ticket = Read-Fix11Owner `
  'config/uaw-c34p-fix11-google-sign-in-oppo-forensic-repair-ticket.json' |
  ConvertFrom-Json
$wrapper = Read-Fix11Owner `
  'scripts/prepare-moolsocial-sideload-build-environment.ps1'
$buildWrapper = Read-Fix11Owner 'scripts/build-buy-device-review.ps1'
$main = Read-Fix11Owner 'apps/mobile/lib/main.dart'
$gateway = Read-Fix11Owner `
  'apps/mobile/lib/features/journey01/review_journey_services.dart'
$session = Read-Fix11Owner `
  'apps/mobile/lib/features/journey01/journey_session.dart'
$activity = Read-Fix11Owner (
  'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/' +
  'MainActivity.kt'
)
$test = Read-Fix11Owner 'apps/mobile/test/firebase_social_auth_gateway_test.dart'

Assert-Fix11 ([string]$ticket.ticketId -ceq $candidate) `
  'the permanent ticket identity changed.'
Assert-Fix11 ($wrapper.Contains("'$candidate'")) `
  'the sideload environment does not authorize FIX11.'
foreach ($token in @(
  'if (-not $GoogleOnly)',
  "MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE = 'true'",
  "MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF = 'false'",
  "MOOLSOCIAL_YOUTUBE_PROVIDER_URL = ''",
  "MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED = 'false'",
  "MOOLSOCIAL_PHONE_OTP_ENABLED = 'false'",
  "MOOLSOCIAL_APPLE_ENABLED = 'false'",
  'MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED = $fullSocialProviderQualified',
  'MOOLSOCIAL_INSTAGRAM_ENABLED = $fullSocialProviderQualified',
  'MOOLSOCIAL_FACEBOOK_ENABLED = $fullSocialProviderQualified',
  "`$fullSocialProviderQualified = 'false'"
)) {
  Assert-Fix11 $wrapper.Contains($token) `
    "the Google-only wrapper token is missing: $token"
}
foreach ($forbidden in @(
  'check-full-social-founder-dev-readiness.ps1',
  'Paste Facebook App ID',
  'Paste Facebook client token',
  "MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF = 'true'",
  "MOOLSOCIAL_PHONE_OTP_ENABLED = 'true'"
)) {
  Assert-Fix11 (-not $wrapper.Contains($forbidden)) `
    "unrelated provider/runtime input escaped the hold: $forbidden"
}
foreach ($token in @(
  "'MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE'",
  "'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR'",
  "MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF -cne 'false'",
  "MOOLSOCIAL_PHONE_OTP_ENABLED -cne 'false'",
  "MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED -cne 'false'",
  "MOOLSOCIAL_INSTAGRAM_ENABLED -cne 'false'",
  "MOOLSOCIAL_FACEBOOK_ENABLED -cne 'false'",
  'FIX11 runtime is not Google-only or a held provider is enabled.'
)) {
  Assert-Fix11 $buildWrapper.Contains($token) `
    "the build-wrapper Google-only assertion is missing: $token"
}

foreach ($token in @(
  "'MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE'",
  'googleOnlyForensicMode: _googleOnlyForensicMode',
  '_globalSocialLoginAuditMode && !_googleOnlyForensicMode',
  'if (!googleOnlyForensicMode && configuration.googleAndYoutubeAvailable)',
  'if (!googleOnlyForensicMode && configuration.facebookAvailable)'
)) {
  Assert-Fix11 $main.Contains($token) `
    "the Google-only runtime projection is incomplete: $token"
}

foreach ($token in @(
  'GoogleSignIn.instance.initialize(',
  'GoogleSignIn.instance.authenticate()',
  "'auth-google-native-ui-requested'",
  "'auth-google-native-no-identity'",
  "'auth-google-firebase-credential-started'",
  "'auth-google-firebase-credential-complete'",
  "'auth-google-firebase-exception-code-'",
  'GoogleAuthProvider.credential(idToken: idToken)',
  '_safeFirebaseAuthExceptionCode(error.code)',
  'sanitizedFirebaseAuthFailure('
)) {
  Assert-Fix11 $gateway.Contains($token) `
    "the Google stage contract is incomplete: $token"
}
Assert-Fix11 $session.Contains("'auth-google-native-no-identity'") `
  'the no-identity receipt is not preserved by the session.'
Assert-Fix11 $session.Contains('(GSI-N01)') `
  'the founder-visible sanitized failure code is missing.'

foreach ($forbidden in @(
  'com.moolsocial.app/google_identity',
  'GoogleSignInOptions',
  'startActivityForResult',
  'GoogleSignIn.getSignedInAccountFromIntent'
)) {
  Assert-Fix11 (-not $activity.Contains($forbidden)) `
    "the rejected legacy Android bridge remains: $forbidden"
  Assert-Fix11 (-not $gateway.Contains($forbidden)) `
    "the rejected legacy Dart bridge remains: $forbidden"
}

foreach ($fixture in @(
  'official Credential Manager path initializes once before authentication',
  'Credential Manager cancellation emits no-identity stage',
  'Google stage telemetry spans native identity and Firebase exchange',
  'Google Firebase rejection preserves only the exact safe exception code',
  'Google Firebase telemetry rejects a non-code payload',
  'failed initialization is not cached across a retry'
)) {
  Assert-Fix11 $test.Contains($fixture) `
    "the focused Google fixture is missing: $fixture"
}

Write-Output (
  'FIX11 Google sign-in forensic readiness passed: ticket=true; ' +
  'googleOnly=true; credentialManager=true; legacyBridge=false; ' +
  'firebaseExchange=true; stageTelemetry=true; exactSafeFirebaseCode=true; ' +
  'sanitizedRecovery=true; ' +
  'unrelatedProvidersHeld=true; credentialValuesEmitted=false.'
)
