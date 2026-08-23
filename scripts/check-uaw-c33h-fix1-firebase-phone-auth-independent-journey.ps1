[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [ValidateSet('source', 'live')]
  [string]$Phase = 'source'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33HPhone {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C33H Firebase Phone Auth gate rejected: $Message" }
}

function Read-C33HPhoneFile {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C33HPhone -Condition (-not [IO.Path]::IsPathRooted($Path)) `
    -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C33HPhone -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return Get-Content -Raw -LiteralPath $resolved
}

$ticket = (Read-C33HPhoneFile `
  -Path 'config/uaw-c30t-r60-45-mobile-otp-gate-nonfunctional-ticket.json' `
  -Label 'ticket') | ConvertFrom-Json
$state = (Read-C33HPhoneFile `
  -Path 'config/firebase-phone-auth-live-readiness-state-c33h.json' `
  -Label 'live-readiness state') | ConvertFrom-Json
$session = Read-C33HPhoneFile `
  -Path 'apps/mobile/lib/features/journey01/journey_session.dart' `
  -Label 'JourneySession'
$services = Read-C33HPhoneFile `
  -Path 'apps/mobile/lib/features/journey01/journey_services.dart' `
  -Label 'journey services'
$firebase = Read-C33HPhoneFile `
  -Path 'apps/mobile/lib/features/journey01/review_journey_services.dart' `
  -Label 'Firebase gateway'
$main = Read-C33HPhoneFile -Path 'apps/mobile/lib/main.dart' -Label 'runtime wiring'
$test = Read-C33HPhoneFile `
  -Path 'apps/mobile/test/uaw_c33h_fix1_firebase_phone_auth_independent_journey_test.dart' `
  -Label 'focused Phone OTP matrix'

Assert-C33HPhone -Condition (
  [string]$ticket.ticketId -ceq 'UAW-C30T-R60-45-MOBILE-OTP-GATE-NONFUNCTIONAL' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.sourceImplementationAuthorizedByFounder -and
  -not [bool]$ticket.authority.successorBuildUploadInstallAuthorized
) -Message 'ticket identity, classification or release boundary changed.'
Assert-C33HPhone -Condition (
  [string]$state.contractId -ceq 'MOOLSOCIAL-C33H-FIREBASE-PHONE-AUTH-LIVE-READINESS-001' -and
  [string]$state.state -ceq 'source_qualified_prebuild_provider_prerequisites_qualified_candidate_device_pending' -and
  [string]$state.projectId -ceq 'moolsocial-dev-503018' -and
  [string]$state.packageName -ceq 'com.moolsocial.app' -and
  -not [bool]$state.authority.firebaseProviderWriteAuthorized -and
  [bool]$state.authority.firebaseProviderWriteAuthorizationConsumed -and
  -not [bool]$state.authority.smsRegionPolicyWriteAuthorized -and
  [bool]$state.authority.smsRegionPolicyWriteAuthorizationConsumed -and
  -not [bool]$state.authority.smsSendOrBillingAuthorized -and
  -not [bool]$state.authority.buildPlayOrDeviceMutationAuthorized -and
  [bool]$state.liveReadiness.phoneProviderEnabled -and
  [bool]$state.liveReadiness.fictionalTestPairRegistered -and
  -not [bool]$state.liveReadiness.fictionalTestPairValuePersistedInRepository -and
  -not [bool]$state.liveReadiness.fictionalTestPairRealSmsSent -and
  [bool]$state.liveReadiness.smsRegionPolicyQualified -and
  [string]$state.liveReadiness.smsRegionPolicyMode -ceq 'allow' -and
  @($state.liveReadiness.smsRegionPolicyRegions).Count -eq 1 -and
  [string]$state.liveReadiness.smsRegionPolicyRegions[0] -ceq 'IN' -and
  [bool]$state.liveReadiness.smsRegionPolicyPreservedExistingMode -and
  -not [bool]$state.liveReadiness.smsRegionPolicyRealSmsSent -and
  -not [bool]$state.liveReadiness.secretValuesObserved -and
  -not [bool]$state.liveReadiness.phoneNumberOrOtpObserved
) -Message 'sanitized state identity, authority or privacy boundary changed.'
Assert-C33HPhone -Condition (
  [bool]$state.sourceQualification.rollbackImplemented -and
  [bool]$state.sourceQualification.focusedJourneyPassed -and
  [int]$state.sourceQualification.focusedJourneyPassedCount -eq 6 -and
  [bool]$state.sourceQualification.affectedRegressionsPassed -and
  [int]$state.sourceQualification.affectedRegressionsPassedCount -eq 54 -and
  [bool]$state.sourceQualification.wholeMobileAnalyzerPassed -and
  [bool]$state.sourceQualification.dualPowerShellGatePassed
) -Message 'source qualification facts or exact passing counts changed.'
foreach ($evidencePath in @($state.qualificationEvidence)) {
  [void](Read-C33HPhoneFile -Path ([string]$evidencePath) -Label 'qualification evidence')
}
Assert-C33HPhone -Condition (@($state.qualificationEvidence).Count -eq 4) `
  -Message 'qualification evidence set changed.'

foreach ($required in @(
  'try {',
  'await _completeAuthentication();',
  'await _rollbackIncompleteOtpAuthentication();',
  'Future<void> _rollbackIncompleteOtpAuthentication()',
  'await _otpGateway.signOut();'
)) {
  Assert-C33HPhone -Condition (
    $session.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "Phone OTP rollback owner is missing: $required"
}
Assert-C33HPhone -Condition (
  ([regex]::Matches(
    $session,
    [regex]::Escape('await _rollbackIncompleteOtpAuthentication();')
  )).Count -eq 2
) -Message 'automatic and manual Phone OTP rollback coverage changed.'
foreach ($required in @(
  'int signOutCount = 0;',
  'signOutCount += 1;',
  'Future<OtpRequestResult> requestCode(String phoneNumber)',
  'Future<String> verifyCode(String code)'
)) {
  Assert-C33HPhone -Condition (
    $services.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "Phone OTP test owner is missing: $required"
}
foreach ($required in @(
  'await _auth.verifyPhoneNumber(',
  'verificationCompleted:',
  'verificationFailed:',
  'codeSent:',
  'codeAutoRetrievalTimeout:',
  'PhoneAuthProvider.credential('
)) {
  Assert-C33HPhone -Condition (
    $firebase.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "Firebase Phone Auth owner is missing: $required"
}
foreach ($required in @(
  "bool.fromEnvironment('MOOLSOCIAL_PHONE_OTP_ENABLED')",
  'mobileOtpAvailable: _phoneOtpEnabled',
  '_productionSocialIdentityProviders'
)) {
  Assert-C33HPhone -Condition (
    $main.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "runtime Phone OTP fail-closed wiring is missing: $required"
}
foreach ($required in @(
  'Phone OTP rejects unavailable and invalid input before dispatch',
  'Phone OTP manual wrong expired resend and success remain independent',
  'manual Phone OTP rolls back partial auth when bootstrap fails',
  'automatic Phone verification rolls back and supports exact retry',
  'Phone OTP provider failure stays retryable without fake auth',
  'Phone OTP process return drops private input and preserves intent',
  "expect(restarted.phoneNumber, isNull)",
  "expect(gateway.signOutCount, 1)"
)) {
  Assert-C33HPhone -Condition (
    $test.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "focused Phone OTP matrix is missing: $required"
}

if ($Phase -ceq 'live') {
  foreach ($fact in @(
    'phoneProviderEnabled',
    'smsRegionPolicyQualified',
    'playSigningSha1Registered',
    'playSigningSha256Registered',
    'playIntegrityOrRecaptchaReturnQualified',
    'realDeviceSendVerifyAuthorized',
    'realDeviceSendVerifyPassed'
  )) {
    Assert-C33HPhone -Condition ([bool]$state.liveReadiness.$fact) `
      -Message "live-readiness fact is not qualified: $fact"
  }
}

Write-Output (
  'C33H Firebase Phone Auth gate passed: phase=' + $Phase +
  '; sourceRollback=automatic+manual; providerEnabled=true; smsAllowlist=IN; fictionalPair=true; realSMS=false; ' +
  'secretOrPrivateInputObserved=false; buildPlayDevice=false.'
)
