[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$ApkPath,

  [Parameter(Mandatory)]
  [string]$GoogleServicesPath,

  [Parameter(Mandatory)]
  [string]$ExpectedVersionName,

  [Parameter(Mandatory)]
  [string]$ExpectedVersionCode,

  [string]$PackageName = 'com.moolsocial.app',

  [string]$ExpectedApplicationLabel = 'MoolSocial',

  [ValidateSet('debug', 'release-apk', 'play-delivered')]
  [string]$ArtifactKind = 'play-delivered',

  [string]$AndroidSdkRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-PlayGoogleSigning([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "APK Google signing readiness rejected: $Message"
  }
}

function Normalize-CertificateHash([string]$Value) {
  return $Value.Replace(':', '').Trim().ToUpperInvariant()
}

if ([string]::IsNullOrWhiteSpace($AndroidSdkRoot)) {
  $sdkCandidates = @(
    [Environment]::GetEnvironmentVariable('ANDROID_SDK_ROOT', 'Process'),
    [Environment]::GetEnvironmentVariable('ANDROID_HOME', 'Process')
  )
  if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    $sdkCandidates += Join-Path $env:LOCALAPPDATA 'Android\Sdk'
  }
  $AndroidSdkRoot = @($sdkCandidates | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_) -and
    (Test-Path -LiteralPath $_ -PathType Container)
  } | Select-Object -Unique -First 1)
}

Assert-PlayGoogleSigning `
  (-not [string]::IsNullOrWhiteSpace($AndroidSdkRoot)) `
  'the Android SDK is unavailable.'
$resolvedSdk = [IO.Path]::GetFullPath($AndroidSdkRoot)
$resolvedApk = [IO.Path]::GetFullPath($ApkPath)
$resolvedGoogleServices = [IO.Path]::GetFullPath($GoogleServicesPath)
Assert-PlayGoogleSigning `
  (Test-Path -LiteralPath $resolvedApk -PathType Leaf) `
  'the APK is unavailable.'
Assert-PlayGoogleSigning `
  (Test-Path -LiteralPath $resolvedGoogleServices -PathType Leaf) `
  'the Firebase Android configuration is unavailable.'
Assert-PlayGoogleSigning `
  ($PackageName -cmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$') `
  'the expected package name is malformed.'
Assert-PlayGoogleSigning `
  ($ExpectedVersionCode -cmatch '^\d+$') `
  'the expected version code is malformed.'
Assert-PlayGoogleSigning `
  (-not [string]::IsNullOrWhiteSpace($ExpectedVersionName)) `
  'the expected version name is missing.'

$apkSigner = Get-ChildItem -LiteralPath (Join-Path $resolvedSdk 'build-tools') `
  -Filter 'apksigner.bat' -File -Recurse |
  Sort-Object FullName -Descending |
  Select-Object -First 1
Assert-PlayGoogleSigning ($null -ne $apkSigner) 'apksigner is unavailable.'
$aapt2 = Join-Path $apkSigner.Directory.FullName 'aapt2.exe'
Assert-PlayGoogleSigning `
  (Test-Path -LiteralPath $aapt2 -PathType Leaf) `
  'aapt2 is unavailable beside apksigner.'

$certificateOutput = @(& $apkSigner.FullName verify --print-certs $resolvedApk 2>&1)
Assert-PlayGoogleSigning `
  ($LASTEXITCODE -eq 0) `
  'the APK signature is invalid.'
$certificateText = $certificateOutput -join [Environment]::NewLine
$sha1Match = [regex]::Match(
  $certificateText,
  '(?im)^Signer #1 certificate SHA-1 digest:\s*([0-9a-f]{40})\s*$'
)
$sha256Match = [regex]::Match(
  $certificateText,
  '(?im)^Signer #1 certificate SHA-256 digest:\s*([0-9a-f]{64})\s*$'
)
Assert-PlayGoogleSigning `
  ($sha1Match.Success -and $sha256Match.Success) `
  'the APK signer identity is unreadable.'
$playSha1 = Normalize-CertificateHash $sha1Match.Groups[1].Value
$playSha256 = Normalize-CertificateHash $sha256Match.Groups[1].Value

$badgingOutput = @(& $aapt2 dump badging $resolvedApk 2>&1)
Assert-PlayGoogleSigning ($LASTEXITCODE -eq 0) 'APK metadata is unreadable.'
$badgingText = $badgingOutput -join [Environment]::NewLine
$packageMatch = [regex]::Match(
  $badgingText,
  "(?m)^package: name='([^']+)' versionCode='([^']+)' versionName='([^']*)'"
)
$labelMatch = [regex]::Match(
  $badgingText,
  "(?m)^application-label:'([^']*)'"
)
Assert-PlayGoogleSigning $packageMatch.Success 'APK package metadata is missing.'
Assert-PlayGoogleSigning `
  ($packageMatch.Groups[1].Value -ceq $PackageName) `
  'the APK package is incorrect.'
Assert-PlayGoogleSigning `
  ($packageMatch.Groups[2].Value -ceq $ExpectedVersionCode) `
  'the APK version code is incorrect.'
Assert-PlayGoogleSigning `
  ($packageMatch.Groups[3].Value -ceq $ExpectedVersionName) `
  'the APK version name is incorrect.'
Assert-PlayGoogleSigning `
  ($labelMatch.Success -and
    $labelMatch.Groups[1].Value -ceq $ExpectedApplicationLabel) `
  'the APK application label is incorrect.'

$configuration = Get-Content -LiteralPath $resolvedGoogleServices -Raw |
  ConvertFrom-Json -Depth 30
$packageClients = @($configuration.client | Where-Object {
  [string]$_.client_info.android_client_info.package_name -ceq $PackageName
})
Assert-PlayGoogleSigning `
  ($packageClients.Count -eq 1) `
  'the package must have exactly one Firebase Android client.'
$packageClient = $packageClients[0]
$apiKeys = @($packageClient.api_key | Where-Object {
  -not [string]::IsNullOrWhiteSpace([string]$_.current_key)
})
$webClients = @($packageClient.oauth_client | Where-Object {
  [int]$_.client_type -eq 3 -and
  -not [string]::IsNullOrWhiteSpace([string]$_.client_id)
})
$matchingAndroidClients = @($packageClient.oauth_client | Where-Object {
  [int]$_.client_type -eq 1 -and
  [string]$_.android_info.package_name -ceq $PackageName -and
  (Normalize-CertificateHash ([string]$_.android_info.certificate_hash)) `
    -ceq $playSha1
})
Assert-PlayGoogleSigning `
  ($apiKeys.Count -eq 1) `
  'the package must expose exactly one API key.'
Assert-PlayGoogleSigning `
  ($webClients.Count -eq 1) `
  'the package must expose exactly one Web OAuth client.'
Assert-PlayGoogleSigning `
  ($matchingAndroidClients.Count -eq 1) `
  'the APK signer is not registered in google-services.json.'

$firebaseCommand = Get-Command firebase -ErrorAction SilentlyContinue
Assert-PlayGoogleSigning `
  ($null -ne $firebaseCommand) `
  'Firebase CLI is unavailable for certificate readback.'
$firebaseAppId = [string]$packageClient.client_info.mobilesdk_app_id
$firebaseProjectId = [string]$configuration.project_info.project_id
Assert-PlayGoogleSigning `
  (-not [string]::IsNullOrWhiteSpace($firebaseAppId) -and
    -not [string]::IsNullOrWhiteSpace($firebaseProjectId)) `
  'Firebase app identity is incomplete.'
$firebaseOutput = @(& $firebaseCommand.Source apps:android:sha:list `
  $firebaseAppId --project $firebaseProjectId --json 2>&1)
Assert-PlayGoogleSigning `
  ($LASTEXITCODE -eq 0) `
  'Firebase certificate readback failed.'
$jsonStart = ($firebaseOutput | Select-String -Pattern '^\s*\{' |
  Select-Object -First 1).LineNumber
Assert-PlayGoogleSigning `
  ($null -ne $jsonStart) `
  'Firebase certificate readback returned no JSON result.'
$firebasePayload = ($firebaseOutput[($jsonStart - 1)..($firebaseOutput.Count - 1)] `
  -join [Environment]::NewLine) | ConvertFrom-Json -Depth 30
$registeredHashes = @($firebasePayload.result | ForEach-Object {
  Normalize-CertificateHash ([string]$_.shaHash)
})
Assert-PlayGoogleSigning `
  (@($registeredHashes | Where-Object { $_ -ceq $playSha1 }).Count -eq 1) `
  'Firebase is missing the APK SHA-1 certificate.'
Assert-PlayGoogleSigning `
  (@($registeredHashes | Where-Object { $_ -ceq $playSha256 }).Count -eq 1) `
  'Firebase is missing the APK SHA-256 certificate.'

$playSha1 = $null
$playSha256 = $null
Write-Output (
  'APK Google signing readiness passed: ' +
  "artifactKind=$ArtifactKind; package=$PackageName; " +
  "versionName=$ExpectedVersionName; " +
  "versionCode=$ExpectedVersionCode; applicationLabelMatched=true; " +
  'apkSignatureValid=true; googleServicesApkSignerMatched=true; ' +
  'firebaseSha1Matched=true; firebaseSha256Matched=true; ' +
  'privateValuesEmitted=false.'
)
