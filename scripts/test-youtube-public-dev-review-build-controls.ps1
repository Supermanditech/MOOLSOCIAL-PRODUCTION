[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Assert-Contains {
  param([string]$Text, [string]$Value, [string]$Message)
  if (-not $Text.Contains($Value, [StringComparison]::Ordinal)) {
    throw $Message
  }
}

$build = Get-Content -Raw -LiteralPath (
  Join-Path $root 'scripts/build-buy-device-review.ps1'
)
$gate = Get-Content -Raw -LiteralPath (
  Join-Path $root 'scripts/check-apk-regression-gate-state.ps1'
)
$context = Get-Content -Raw -LiteralPath (
  Join-Path $root 'scripts/check-youtube-public-dev-build-context.ps1'
)
$main = Get-Content -Raw -LiteralPath (
  Join-Path $root 'apps/mobile/lib/main.dart'
)

Assert-Contains $build 'YouTubePublicDevReview' `
  'The one-build wrapper lacks the exact YouTube public Dev profile.'
Assert-Contains $build 'https://firebase.googleapis.com/v1beta1/projects/' `
  'The wrapper lacks the official Firebase Management API boundary.'
Assert-Contains $build '$expectedProjectId/androidApps/$encodedAppId/config' `
  'The wrapper lacks the encoded Android getConfig resource path.'
Assert-Contains $build 'MOOLSOCIAL_YOUTUBE_PROVIDER_URL' `
  'The provider URL is not supplied by the qualified wrapper.'
Assert-Contains $build 'MOOLSOCIAL_SOCIAL_CONTENT_URL' `
  'The MoolSocial content URL is not supplied by the qualified wrapper.'
Assert-Contains $build '--dart-define-from-file' `
  'Firebase client configuration would be exposed on the process command line.'
Assert-Contains $build 'Remove-Item -LiteralPath $runtimeDefineFile' `
  'The temporary public client configuration is not removed.'
Assert-Contains $build '$accessToken = $null' `
  'The short-lived management token is not cleared from script memory.'
Assert-Contains $build 'check-youtube-public-dev-build-context.ps1' `
  'The build wrapper does not reuse the exact executable gcloud context gate.'
Assert-Contains $context "'moolsocial-dev-fsc02d'" `
  'The context gate lacks the exact isolated gcloud configuration.'
Assert-Contains $context "'hello@moolsocial.com'" `
  'The context gate lacks the exact authorized gcloud account.'
Assert-Contains $context "'moolsocial-dev-503018'" `
  'The context gate lacks the exact MoolSocial Dev project.'
Assert-Contains $context '--filter=is_active:true' `
  'The context gate does not verify the active configuration.'
Assert-Contains $context '${env:ProgramFiles(x86)}' `
  'The context gate lacks the exact newly installed x86 CLI fallback.'
Assert-Contains $context 'Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd' `
  'The context gate lacks the exact Google Cloud CLI fallback suffix.'
Assert-Contains $context 'Test-Path -LiteralPath $_ -PathType Leaf' `
  'The context gate does not verify the fallback executable exists.'
Assert-Contains $context 'AND status:ACTIVE' `
  'The context gate does not verify the exact active credential.'
Assert-Contains $context 'accessTokenRequested = $false' `
  'The context gate does not prove its no-token host boundary.'
Assert-Contains $build 'FirebaseAndroidSdkConfig=present_not_logged' `
  'Build provenance does not explicitly suppress Firebase client values.'
Assert-Contains $build 'YouTubeServerSecrets=absent' `
  'Build provenance does not state the server-secret boundary.'
Assert-Contains $gate 'requiredNonEmptyRuntimeDefines' `
  'The machine gate cannot require an unlogged Firebase client value.'
Assert-Contains $gate "'MOOLSOCIAL_FIREBASE_API_KEY'" `
  'The machine gate does not allow the Firebase-only client identifier.'
Assert-Contains $gate "'MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF'" `
  'The machine gate does not require the private Dev proof boundary.'
Assert-Contains $gate "'MOOLSOCIAL_SOCIAL_CONTENT_URL'" `
  'The machine gate does not allow the MoolSocial content endpoint.'
Assert-Contains $main '_youtubePublicReviewMode && youtubePrivateDevProofEnabled' `
  'Main does not bind non-emulator device review to the private Dev proof.'

Write-Output 'YouTube public Dev review build-control tests passed locally.'
Write-Output 'No Firebase client value, cloud resource, APK or device was touched.'
