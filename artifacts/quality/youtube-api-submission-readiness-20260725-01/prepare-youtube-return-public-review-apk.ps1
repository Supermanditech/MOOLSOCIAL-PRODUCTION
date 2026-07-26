[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$repoRoot = "C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION"
$mobileRoot = Join-Path $repoRoot "apps\mobile"
$evidenceRoot = Join-Path $repoRoot (
  "artifacts\quality\youtube-private-dev-oppo-public-viewing-20260725-01"
)
$projectId = "moolsocial-dev-503018"
$projectNumber = "760290687711"
$androidAppId = "1:760290687711:android:4202409fd3ab38f6ce076a"
$expectedPackage = "com.moolsocial.app"
$providerUrl = (
  "https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/" +
  "youtubeProvider"
)
$candidateId = "youtube-return-oppo-20260726-10"
$outputApk = Join-Path $evidenceRoot (
  "moolsocial-youtube-videos-shorts-private-dev-r10.apk"
)

if (Test-Path -LiteralPath $outputApk) {
  throw "The immutable r10 evidence APK already exists."
}

$env:PATH = (
  "C:\GUARANTEED OUTCOME\.tools\google-cloud-sdk\bin;" +
  $env:PATH
)
$env:CLOUDSDK_CORE_PROJECT = $projectId

$account = (& gcloud.cmd auth list `
  --filter="status:ACTIVE" `
  --format="value(account)" | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $account -ne "hello@moolsocial.com") {
  throw "The exact MoolSocial Google Cloud account is not active."
}

$token = (& gcloud.cmd auth print-access-token | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
  throw "Unable to obtain an in-memory Google Cloud access token."
}

try {
  $headers = @{
    Authorization = "Bearer $token"
    "x-goog-user-project" = $projectId
  }
  $escapedAppId = [uri]::EscapeDataString($androidAppId)
  $response = Invoke-RestMethod `
    -Headers $headers `
    -Uri (
      "https://firebase.googleapis.com/v1beta1/projects/$projectId/" +
      "androidApps/$escapedAppId/config"
    ) `
    -Method Get
  $configText = [Text.Encoding]::UTF8.GetString(
    [Convert]::FromBase64String([string]$response.configFileContents)
  )
  $config = $configText | ConvertFrom-Json
} finally {
  $token = $null
  $headers = $null
  $response = $null
  $configText = $null
}

if ($config.project_info.project_id -ne $projectId) {
  throw "The Firebase configuration is not for the exact Dev project."
}
if ("$($config.project_info.project_number)" -ne $projectNumber) {
  throw "The Firebase configuration project number does not match."
}

$androidClient = @(
  $config.client |
    Where-Object {
      $_.client_info.android_client_info.package_name -eq $expectedPackage
    }
) | Select-Object -First 1
if ($null -eq $androidClient) {
  throw "The expected MoolSocial Android client is missing."
}
if ($androidClient.client_info.mobilesdk_app_id -ne $androidAppId) {
  throw "The Firebase Android app ID does not match."
}

$apiKey = [string](
  @($androidClient.api_key) | Select-Object -First 1
).current_key
if ([string]::IsNullOrWhiteSpace($apiKey)) {
  throw "The Firebase Android API key is missing."
}

$defines = @(
  "--dart-define=MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW=true",
  "--dart-define=MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF=true",
  "--dart-define=MOOLSOCIAL_USE_EMULATORS=false",
  "--dart-define=MOOLSOCIAL_FIREBASE_API_KEY=$apiKey",
  "--dart-define=MOOLSOCIAL_FIREBASE_APP_ID=$androidAppId",
  "--dart-define=MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID=$projectNumber",
  "--dart-define=MOOLSOCIAL_FIREBASE_PROJECT_ID=$projectId",
  "--dart-define=MOOLSOCIAL_YOUTUBE_PROVIDER_URL=$providerUrl",
  "--dart-define=MOOLSOCIAL_CANDIDATE_ID=$candidateId"
)

try {
  Set-Location -LiteralPath $mobileRoot
  & flutter.bat build apk --debug @defines
  if ($LASTEXITCODE -ne 0) {
    throw "The YouTube return public-review APK build failed."
  }
} finally {
  $apiKey = $null
  $defines = $null
  $config = $null
  $androidClient = $null
}

$builtApk = Join-Path (
  $mobileRoot
) "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path -LiteralPath $builtApk -PathType Leaf)) {
  throw "The expected YouTube return public-review APK was not created."
}

Copy-Item -LiteralPath $builtApk -Destination $outputApk
$stream = [IO.File]::OpenRead($outputApk)
try {
  $sha256 = [Security.Cryptography.SHA256]::Create()
  try {
    $hash = (
      [BitConverter]::ToString($sha256.ComputeHash($stream))
    ).Replace("-", "")
  } finally {
    $sha256.Dispose()
  }
} finally {
  $stream.Dispose()
}

Write-Host "YouTube return public-review APK build passed."
Write-Host "CANDIDATE=$candidateId"
Write-Host "APK=$outputApk"
Write-Host "SHA256=$hash"
