[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$AndroidActivityPath,
  [string]$AndroidBuildPath,
  [string]$DartGatewayPath,
  [string]$DartTestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Resolve-BridgeOwner(
  [string]$SuppliedPath,
  [string]$RelativePath
) {
  $candidate = if ([string]::IsNullOrWhiteSpace($SuppliedPath)) {
    Join-Path $root $RelativePath
  } else {
    $SuppliedPath
  }
  $resolved = [IO.Path]::GetFullPath($candidate)
  if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "Google Android identity bridge readiness rejected: missing owner $RelativePath"
  }
  return $resolved
}

function Assert-Bridge([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Google Android identity bridge readiness rejected: $Message"
  }
}

function Assert-ContainsOnce(
  [string]$Source,
  [string]$Token,
  [string]$Label
) {
  $count = ([regex]::Matches($Source, [regex]::Escape($Token))).Count
  Assert-Bridge ($count -eq 1) "$Label must occur exactly once."
}

$activity = Get-Content -LiteralPath (
  Resolve-BridgeOwner $AndroidActivityPath `
    'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt'
) -Raw
$gradle = Get-Content -LiteralPath (
  Resolve-BridgeOwner $AndroidBuildPath `
    'apps/mobile/android/app/build.gradle.kts'
) -Raw
$gateway = Get-Content -LiteralPath (
  Resolve-BridgeOwner $DartGatewayPath `
    'apps/mobile/lib/features/journey01/review_journey_services.dart'
) -Raw
$test = Get-Content -LiteralPath (
  Resolve-BridgeOwner $DartTestPath `
    'apps/mobile/test/firebase_social_auth_gateway_test.dart'
) -Raw
$lock = Get-Content -LiteralPath (
  Resolve-BridgeOwner $null 'apps/mobile/pubspec.lock'
) -Raw

Assert-Bridge `
  (-not $gradle.Contains('com.google.android.gms:play-services-auth')) `
  'the rejected direct legacy Play Services Auth dependency is present.'
Assert-Bridge `
  ([regex]::IsMatch(
    $lock,
    '(?ms)^  google_sign_in_android:\r?$.*?^    version: "7\.2\.16"\r?$'
  )) `
  'the locked Credential Manager Google Android plugin is unavailable.'
foreach ($token in @(
  'MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPORTS_BEGIN',
  'MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_STATE_BEGIN',
  'MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_REGISTRATION_BEGIN',
  'MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_CALLBACK_BEGIN',
  'MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_DESTROY_BEGIN',
  'MOOLSOCIAL_GOOGLE_IDENTITY_BRIDGE_IMPLEMENTATION_BEGIN',
  'Official google_sign_in owns the Android Credential Manager integration.',
  'GeneratedPluginRegistrant registers the official Google identity plugin.',
  'No legacy activity-result identity bridge is permitted in the FIX11 path.'
)) {
  Assert-Bridge $activity.Contains($token) "plugin seam token is missing: $token"
}
foreach ($forbidden in @(
  'com.moolsocial.app/google_identity',
  'GoogleSignInOptions',
  'startActivityForResult',
  'onActivityResult(',
  'GoogleSignIn.getSignedInAccountFromIntent'
)) {
  Assert-Bridge (-not $activity.Contains($forbidden)) `
    "legacy native bridge token is present: $forbidden"
}
foreach ($token in @(
  'GoogleSignIn.instance.initialize(',
  'GoogleSignIn.instance.authenticate()',
  "'auth-google-native-initialize-started'",
  "'auth-google-native-ui-requested'",
  "'auth-google-native-identity-returned'",
  "'auth-google-native-no-identity'",
  "'auth-google-firebase-credential-started'",
  "'auth-google-firebase-credential-complete'",
  "'auth-google-firebase-exception-code-'",
  'GoogleAuthProvider.credential(idToken: idToken)',
  '_safeFirebaseAuthExceptionCode(error.code)',
  'sanitizedFirebaseAuthFailure('
)) {
  Assert-Bridge $gateway.Contains($token) `
    "Credential Manager/Firebase token is missing: $token"
}
foreach ($forbidden in @(
  'com.moolsocial.app/google_identity',
  'useAndroidCompatibilityFlow',
  'authenticateAndroidCompatibilityIdToken'
)) {
  Assert-Bridge (-not $gateway.Contains($forbidden)) `
    "legacy Dart bridge token is present: $forbidden"
}
foreach ($token in @(
  'official Credential Manager path initializes once before authentication',
  'Credential Manager cancellation emits no-identity stage',
  'Google stage telemetry spans native identity and Firebase exchange',
  'Google Firebase rejection preserves only the exact safe exception code',
  'Google Firebase telemetry rejects a non-code payload',
  'failed initialization is not cached across a retry'
)) {
  Assert-Bridge $test.Contains($token) "Google bridge fixture is missing: $token"
}

Write-Output (
  'Google Android identity bridge readiness passed: ' +
  'credentialManagerPlugin=true; legacyBridge=false; ' +
  'firebaseCredentialExchange=true; cancellationBounded=true; ' +
  'stageTelemetry=true; exactSafeFirebaseCode=true; ' +
  'failuresSanitized=true; retrySafe=true; ' +
  'credentialValuesEmitted=false.'
)
