[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-Fix6([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34P FIX6 pre-AAB auth hardening rejected: $Message"
  }
}

function Read-Fix6([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-Fix6 ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) `
    "owner escaped repository: $RelativePath"
  Assert-Fix6 (Test-Path -LiteralPath $path -PathType Leaf) `
    "owner missing: $RelativePath"
  return Get-Content -LiteralPath $path -Raw
}

function Assert-Tokens(
  [string]$Body,
  [string[]]$Tokens,
  [string]$Label
) {
  foreach ($token in $Tokens) {
    Assert-Fix6 ($Body.Contains($token)) "$Label token missing: $token"
  }
}

$ticket = Read-Fix6 `
  'config/uaw-c34p-fix6-pre-aab-public-auth-production-hardening-ticket.json' |
  ConvertFrom-Json
Assert-Fix6 (
  [string]$ticket.ticketId -ceq
    'UAW-C34P-FIX6-PRE-AAB-PUBLIC-AUTH-PRODUCTION-HARDENING' -and
  [string]$ticket.status -ceq 'source_qualified_with_fix7_release_blocker' -and
  @($ticket.confirmedDefects).Count -eq 5 -and
  @($ticket.confirmedDefects | Where-Object {
    [string]$_.state -ceq 'implemented_qualified'
  }).Count -eq 4 -and
  @($ticket.confirmedDefects | Where-Object {
    [string]$_.state -ceq 'release_blocking_followup_required'
  }).Count -eq 1
) 'ticket identity or defect inventory changed.'
Assert-Fix6 (
  [string]($ticket.confirmedDefects | Where-Object {
    [string]$_.id -ceq 'FIX6-05-META-APP-DATA-ERASURE'
  }).followupTicketId -ceq 'UAW-C34P-FIX7-META-ACCOUNT-DATA-ERASURE'
) 'Meta erasure release blocker is not bound to FIX7.'

$mobileAdapter = Read-Fix6 `
  'apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart'
$instagramAdapter = Read-Fix6 `
  'apps/mobile/lib/core/auth/instagram_oauth_network_adapter.dart'
$main = Read-Fix6 'apps/mobile/lib/main.dart'
$phone = Read-Fix6 `
  'apps/mobile/lib/features/journey01/review_journey_services.dart'
$xBroker = Read-Fix6 'backend/functions/src/auth/x_pkce_broker.ts'
$instagramBroker = Read-Fix6 `
  'backend/functions/src/auth/instagram_oauth_broker.ts'
$backendIndex = Read-Fix6 'backend/functions/src/index.ts'
$gradle = Read-Fix6 'apps/mobile/android/app/build.gradle.kts'
$mobileAdapterTest = Read-Fix6 `
  'apps/mobile/test/uaw_c34p_x_oauth2_pkce_network_adapter_test.dart'
$phoneTest = Read-Fix6 `
  'apps/mobile/test/uaw_c33h_fix1_firebase_phone_auth_independent_journey_test.dart'
$xTest = Read-Fix6 'backend/functions/src/auth/x_pkce_broker.test.ts'
$instagramTest = Read-Fix6 `
  'backend/functions/src/auth/instagram_oauth_broker.test.ts'

Assert-Tokens $mobileAdapter @(
  'operationTimeout = const Duration(seconds: 70)',
  'operation().timeout(_operationTimeout)',
  'operationTimeout: operationTimeout'
) 'mobile broker timeout'
Assert-Tokens $instagramAdapter @('operationTimeout: operationTimeout') `
  'Instagram shared timeout'
Assert-Tokens $main @(
  '.timeout(const Duration(seconds: 60))',
  'const Duration(seconds: 50)'
) 'mobile HTTP ordering'
Assert-Tokens $backendIndex @('timeoutSeconds: 45') 'backend timeout ceiling'

foreach ($entry in @(
  @{ Body = $xBroker; Label = 'X broker' },
  @{ Body = $instagramBroker; Label = 'Instagram broker' }
)) {
  Assert-Tokens $entry.Body @(
    'nowMs >= stored.expiresAtMs',
    'providerError',
    'stream.getReader()',
    'byteLength > 64 * 1024'
  ) $entry.Label
}
Assert-Tokens $xBroker @('providerError === "access_denied"') `
  'X denial classification'
Assert-Tokens $instagramBroker @(
  'error === "access_denied" || error === "user_denied"'
) 'Instagram denial classification'

Assert-Tokens $phone @(
  'PhoneVerificationCompletionGate',
  'claimTerminal(requestGeneration)',
  'invalidate(requestGeneration)',
  'const Duration(seconds: 70)'
) 'phone first-terminal gate'
Assert-Tokens $mobileAdapterTest @(
  'a hung dependency is bounded by the whole-operation timeout'
) 'mobile timeout test'
Assert-Tokens $phoneTest @(
  'phone verification gate allows one terminal callback per request',
  'phone verification gate invalidates callbacks after timeout'
) 'phone race tests'
foreach ($test in @($xTest, $instagramTest)) {
  Assert-Tokens $test @(
    'provider server errors are not misreported as user denial',
    'fetch transport rejects an oversized provider body before parsing'
  ) 'backend hardening tests'
}

Assert-Tokens $gradle @('MOOLSOCIAL_UPLOAD_STORE_FILE') `
  'canonical signing contract'
Assert-Fix6 (-not $gradle.Contains('MOOLSOCIAL_UPLOAD_KEYSTORE_PATH')) `
  'stale keystore path environment name entered Gradle.'

Write-Output (
  'C34P FIX6 pre-AAB auth hardening passed: defects=5; implemented=4; ' +
  'metaErasureFollowup=release-blocking; mobileTotalTimeout=70s; ' +
  'backendCeiling=45s; phoneFirstTerminal=true; exactExpiry=true; ' +
  'providerErrorTruth=true; boundedProviderBody=true; buildPlayOppo=false.'
)
