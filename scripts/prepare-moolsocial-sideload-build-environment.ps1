[CmdletBinding()]
param(
  [switch]$GoogleOnly,
  [string]$CandidateId =
    'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'MoolSocial sideload preparation requires PowerShell 7.'
}
if ($CandidateId -cne
  'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR') {
  throw 'MoolSocial sideload preparation candidate is not authorized.'
}
if (-not $GoogleOnly) {
  throw 'MoolSocial FIX11 preparation requires the GoogleOnly profile.'
}

function Read-MoolSocialSecretText([string]$Prompt) {
  $secureValue = Read-Host $Prompt -AsSecureString
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    $secureValue.Dispose()
  }
}

try {
  $fullSocialProviderQualified = 'false'
  Remove-Item Env:\MOOLSOCIAL_FACEBOOK_APP_ID -ErrorAction SilentlyContinue
  Remove-Item Env:\MOOLSOCIAL_FACEBOOK_CLIENT_TOKEN `
    -ErrorAction SilentlyContinue
  $env:MOOLSOCIAL_UPLOAD_STORE_PASSWORD =
    Read-MoolSocialSecretText 'Enter finalized upload keystore password'
  $env:MOOLSOCIAL_UPLOAD_KEY_PASSWORD =
    Read-MoolSocialSecretText 'Enter finalized upload key password'
  $env:MOOLSOCIAL_UPLOAD_STORE_FILE = Join-Path $env:USERPROFILE `
    'Documents\MoolSocial-Signing\moolsocial-upload.jks'
  $env:MOOLSOCIAL_UPLOAD_KEY_ALIAS = 'moolsocial-upload'

  $configPath = Join-Path $PWD `
    'apps\mobile\android\app\google-services.json'
  $googleConfig = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
  $matchingClients = @($googleConfig.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq 'com.moolsocial.app'
  })
  if ($matchingClients.Count -ne 1) { throw 'ANDROID_CLIENT_MATCH_FAILED' }
  $androidClient = $matchingClients[0]
  $apiKeys = @($androidClient.api_key | Where-Object current_key)
  $webOauthClients = @($androidClient.oauth_client | Where-Object {
    $_.client_type -eq 3 -and $_.client_id
  })
  if ($apiKeys.Count -lt 1) { throw 'FIREBASE_API_KEY_MISSING' }
  if ($webOauthClients.Count -lt 1) {
    throw 'GOOGLE_SERVER_CLIENT_ID_MISSING'
  }
  $env:MOOLSOCIAL_FIREBASE_API_KEY = $apiKeys[0].current_key
  $env:MOOLSOCIAL_FIREBASE_APP_ID =
    $androidClient.client_info.mobilesdk_app_id
  $env:MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID =
    $googleConfig.project_info.project_number
  $env:MOOLSOCIAL_FIREBASE_PROJECT_ID =
    $googleConfig.project_info.project_id
  $env:MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID = $webOauthClients[0].client_id

  $env:MOOLSOCIAL_CANDIDATE_ID = $CandidateId
  $env:MOOLSOCIAL_AUTH_API_BASE_URL =
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialPublicAuth'
  $env:MOOLSOCIAL_X_CALLBACK_URL = 'https://moolsocial.com/app/auth/x'
  $env:MOOLSOCIAL_X_AUTHORIZATION_ENDPOINT =
    'https://x.com/i/oauth2/authorize'
  $env:MOOLSOCIAL_INSTAGRAM_CALLBACK_URL =
    'https://moolsocial.com/app/auth/instagram'
  $env:MOOLSOCIAL_INSTAGRAM_AUTHORIZATION_ENDPOINT =
    'https://www.instagram.com/oauth/authorize'
  $env:MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL = 'https://moolsocial.com/app'
  $env:MOOLSOCIAL_EMAIL_LINK_DOMAIN = ''
  $env:MOOLSOCIAL_FACEBOOK_GRAPH_REVOCATION_ENDPOINT =
    'https://graph.facebook.com/v25.0/me/permissions'

  $facts = @{
    MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW = 'false'
    MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF = 'false'
    MOOLSOCIAL_YOUTUBE_PROVIDER_URL = ''
    MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED = 'false'
    MOOLSOCIAL_YOUTUBE_SHORTS_AUTOPLAY_ENABLED = 'false'
    MOOLSOCIAL_GOOGLE_PROVIDER_QUALIFIED = 'true'
    MOOLSOCIAL_GOOGLE_PLAY_SIGNING_QUALIFIED = 'false'
    MOOLSOCIAL_SIDELOAD_PREFLIGHT_ENABLED = 'true'
    MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT = 'true'
    MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE = 'true'
    MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED = 'false'
    MOOLSOCIAL_PHONE_OTP_ENABLED = 'false'
    MOOLSOCIAL_MOBILE_OTP_ATTESTATION_QUALIFIED = 'false'
    MOOLSOCIAL_APPLE_ENABLED = 'false'
    MOOLSOCIAL_APPLE_PROVIDER_QUALIFIED = 'false'
    MOOLSOCIAL_APPLE_PLATFORM_CONFIGURATION_QUALIFIED = 'false'
    MOOLSOCIAL_APPLE_REVOCATION_QUALIFIED = 'false'
    MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED = $fullSocialProviderQualified
    MOOLSOCIAL_X_CLIENT_ID_CONFIGURED = $fullSocialProviderQualified
    MOOLSOCIAL_X_EXACT_REDIRECT_QUALIFIED = $fullSocialProviderQualified
    MOOLSOCIAL_X_FIREBASE_BROKER_QUALIFIED = $fullSocialProviderQualified
    MOOLSOCIAL_INSTAGRAM_ENABLED = $fullSocialProviderQualified
    MOOLSOCIAL_INSTAGRAM_PROFESSIONAL_LOGIN_QUALIFIED = $fullSocialProviderQualified
    MOOLSOCIAL_INSTAGRAM_EXACT_REDIRECT_QUALIFIED = $fullSocialProviderQualified
    MOOLSOCIAL_INSTAGRAM_FIREBASE_BROKER_QUALIFIED = $fullSocialProviderQualified
    MOOLSOCIAL_INSTAGRAM_REVOCATION_QUALIFIED = $fullSocialProviderQualified
    MOOLSOCIAL_FACEBOOK_ENABLED = $fullSocialProviderQualified
    MOOLSOCIAL_FACEBOOK_PROVIDER_QUALIFIED = $fullSocialProviderQualified
    MOOLSOCIAL_FACEBOOK_ANDROID_CONFIGURATION_QUALIFIED = $fullSocialProviderQualified
    MOOLSOCIAL_FACEBOOK_REVOCATION_QUALIFIED = $fullSocialProviderQualified
    MOOLSOCIAL_FACEBOOK_DATA_DELETION_QUALIFIED = $fullSocialProviderQualified
  }
  foreach ($fact in $facts.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable(
      [string]$fact.Key,
      [string]$fact.Value,
      'Process'
    )
  }

  $required = @(
    'MOOLSOCIAL_UPLOAD_STORE_FILE',
    'MOOLSOCIAL_UPLOAD_STORE_PASSWORD',
    'MOOLSOCIAL_UPLOAD_KEY_ALIAS',
    'MOOLSOCIAL_UPLOAD_KEY_PASSWORD',
    'MOOLSOCIAL_FIREBASE_API_KEY',
    'MOOLSOCIAL_FIREBASE_APP_ID',
    'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
    'MOOLSOCIAL_FIREBASE_PROJECT_ID',
    'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID'
  )
  $missing = @($required | Where-Object {
    [string]::IsNullOrWhiteSpace(
      [Environment]::GetEnvironmentVariable($_, 'Process')
    )
  })
  if (
    $missing.Count -ne 0 -or
    -not (Test-Path -LiteralPath $env:MOOLSOCIAL_UPLOAD_STORE_FILE)
  ) {
    throw 'REQUIRED_BUILD_INPUT_MISSING'
  }
  & (Join-Path $PSScriptRoot 'check-google-android-oauth-signing-readiness.ps1') `
    -GoogleServicesPath $configPath `
    -GoogleServerClientId $env:MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID `
    -KeystorePath $env:MOOLSOCIAL_UPLOAD_STORE_FILE `
    -KeyAlias $env:MOOLSOCIAL_UPLOAD_KEY_ALIAS | Out-Null
  $googleReadinessPassed = $?
  if (-not $googleReadinessPassed) {
    throw 'GOOGLE_ANDROID_OAUTH_SIGNING_NOT_QUALIFIED'
  }
  $env:MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED = 'true'
  Clear-Host
  Write-Host 'SIDELOAD_BUILD_ENV_READY' -ForegroundColor Green
  Write-Host 'Runtime profile: Google only; unrelated providers fail closed.'
  Write-Host 'Keep this PowerShell window open.'
}
catch {
  Clear-Host
  Write-Host ('SIDELOAD_BUILD_ENV_FAILED: ' + $_.Exception.Message) `
    -ForegroundColor Red
}
finally {
  Remove-Item Function:\Read-MoolSocialSecretText `
    -ErrorAction SilentlyContinue
}
