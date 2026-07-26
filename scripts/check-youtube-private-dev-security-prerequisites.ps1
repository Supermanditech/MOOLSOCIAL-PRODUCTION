[CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = "None")]
param(
  [ValidateSet("moolsocial-dev-503018")]
  [string]$ProjectId = "moolsocial-dev-503018",
  [Parameter(Mandatory = $true)]
  [string]$ServerApiKeyUid,
  [Parameter(Mandatory = $true)]
  [string]$AndroidAppId,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedSha256,
  [switch]$AllowNoServerIpRestriction
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "youtube-private-dev-control-common.ps1")

$expectedProject = "moolsocial-dev-503018"
$expectedProjectNumber = "760290687711"
$expectedAndroidPackage = "com.moolsocial.app"

function Assert-True {
  param(
    [Parameter(Mandatory = $true)]
    [bool]$Condition,
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

function Property-Value {
  param(
    [AllowNull()]
    [object]$Object,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }
  return $property.Value
}

function Invoke-GcloudJson {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [Parameter(Mandatory = $true)]
    [string]$Description
  )

  $previousErrorActionPreference = $ErrorActionPreference
  $nativePreference = Get-Variable `
    -Name PSNativeCommandUseErrorActionPreference `
    -ErrorAction SilentlyContinue
  $previousNativePreference = if ($null -ne $nativePreference) {
    $nativePreference.Value
  } else {
    $null
  }
  try {
    $ErrorActionPreference = "Continue"
    if ($null -ne $nativePreference) {
      $PSNativeCommandUseErrorActionPreference = $false
    }
    $output = & $script:GcloudExecutable `
      @Arguments --quiet --format=json 2>$null
    $commandExitCode = $LASTEXITCODE
  } finally {
    if ($null -ne $nativePreference) {
      $PSNativeCommandUseErrorActionPreference = $previousNativePreference
    }
    $ErrorActionPreference = $previousErrorActionPreference
  }
  Assert-True ($commandExitCode -eq 0) "Unable to $Description."
  try {
    return ($output | Out-String) | ConvertFrom-Json
  } catch {
    throw "The $Description response was not valid JSON."
  }
}

function Get-GoogleJson {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Uri,
    [Parameter(Mandatory = $true)]
    [string]$AccessToken,
    [Parameter(Mandatory = $true)]
    [string]$Description
  )

  try {
    return Invoke-RestMethod `
      -Method Get `
      -Uri $Uri `
      -Headers @{
        Authorization = "Bearer $AccessToken"
        "X-Goog-User-Project" = $ProjectId
      }
  } catch {
    throw "Unable to $Description."
  }
}

function Get-SecretText {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $value = & $script:GcloudExecutable secrets versions access latest `
    "--secret=$Name" `
    "--project=$ProjectId" `
    --quiet 2>$null
  Assert-True ($LASTEXITCODE -eq 0) `
    "Unable to inspect enabled value for $Name."
  $text = ($value | Out-String).Trim()
  Assert-True (-not [string]::IsNullOrWhiteSpace($text)) `
    "$Name has no enabled value."
  return $text
}

function Get-Sha256Bytes {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value
  )

  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
  try {
    return $sha.ComputeHash($bytes)
  } finally {
    [Array]::Clear($bytes, 0, $bytes.Length)
    $sha.Dispose()
  }
}

function Test-FixedTimeEqual {
  param(
    [Parameter(Mandatory = $true)]
    [byte[]]$Left,
    [Parameter(Mandatory = $true)]
    [byte[]]$Right
  )

  if ($Left.Length -ne $Right.Length) {
    return $false
  }
  $difference = 0
  for ($index = 0; $index -lt $Left.Length; $index += 1) {
    $difference = $difference -bor ($Left[$index] -bxor $Right[$index])
  }
  return $difference -eq 0
}

function ConvertFrom-Base64Url {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $normalized = $Value.Trim().Replace("-", "+").Replace("_", "/")
  switch ($normalized.Length % 4) {
    0 { }
    2 { $normalized += "==" }
    3 { $normalized += "=" }
    default { throw "$Name is not valid base64url." }
  }
  try {
    return [Convert]::FromBase64String($normalized)
  } catch {
    throw "$Name is not valid base64url."
  }
}

function Normalize-Sha256 {
  param([Parameter(Mandatory = $true)][string]$Value)

  $normalized = ($Value -replace ":", "").Trim().ToUpperInvariant()
  Assert-True ($normalized -match "^[0-9A-F]{64}$") `
    "ExpectedSha256 must be one SHA-256 certificate fingerprint."
  return $normalized
}

Assert-True ($ProjectId -eq $expectedProject) `
  "Only $expectedProject is authorized by this security preflight."
Assert-True (
  $ServerApiKeyUid -match "^[A-Za-z0-9_-]{8,128}$"
) "ServerApiKeyUid must be the API key UID, never the key string."
Assert-True (
  $AndroidAppId -match "^1:[0-9]+:android:[a-fA-F0-9]+$"
) "AndroidAppId has an invalid Firebase Android app ID format."
$sha256 = Normalize-Sha256 $ExpectedSha256

$gcloud = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
if ($null -eq $gcloud) {
  $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
}
Assert-True ($null -ne $gcloud) "gcloud is required for security preflight."
$script:GcloudExecutable = $gcloud.Definition

$apiKey = Invoke-GcloudJson `
  @(
    "services",
    "api-keys",
    "describe",
    $ServerApiKeyUid,
    "--location=global",
    "--project=$ProjectId"
  ) `
  "inspect the restricted YouTube server API key"
Assert-True (
  $apiKey.name -eq
    "projects/$expectedProjectNumber/locations/global/keys/$ServerApiKeyUid"
) "The server API key resource identity changed."
$apiKeyDeleteTime = "$(Property-Value $apiKey "deleteTime")".Trim()
Assert-True ([string]::IsNullOrWhiteSpace($apiKeyDeleteTime)) `
  "The server API key is deleted or pending deletion."
$keyRestrictions = Property-Value $apiKey "restrictions"
Assert-True ($null -ne $keyRestrictions) `
  "The server API key has no restrictions."
$apiTargetValue = Property-Value $keyRestrictions "apiTargets"
$apiTargets = @($apiTargetValue)
Assert-True (
  $apiTargets.Count -eq 1 -and
  $apiTargets[0].service -eq "youtube.googleapis.com"
) "The server API key must target only YouTube Data API v3."
foreach ($forbiddenRestriction in @(
  "androidKeyRestrictions",
  "browserKeyRestrictions",
  "iosKeyRestrictions"
)) {
  Assert-True (
    $null -eq (Property-Value $keyRestrictions $forbiddenRestriction)
  ) "The backend key has an invalid $forbiddenRestriction block."
}
$serverRestrictions = Property-Value `
  $keyRestrictions `
  "serverKeyRestrictions"
$allowedIpValue = if ($null -eq $serverRestrictions) {
  $null
} else {
  Property-Value $serverRestrictions "allowedIps"
}
$allowedIps = @($allowedIpValue)
if ($allowedIps.Count -eq 0) {
  Assert-True ($AllowNoServerIpRestriction.IsPresent) `
    "The key has no fixed server IP restriction. Pass " +
    "-AllowNoServerIpRestriction only under the reviewed compensating controls."
} else {
  Assert-True (
    ($allowedIps -notcontains "0.0.0.0/0") -and
    ($allowedIps -notcontains "::/0")
  ) "The server API key allows an unrestricted source range."
}

$apiKeyString = $null
$secretApiKeyString = $null
$apiKeyHash = $null
$secretApiKeyHash = $null
$encryptionKeyV1Text = $null
$encryptionKeyV2Text = $null
$encryptionKeyV1 = $null
$encryptionKeyV2 = $null
$encryptionKeyV1Hash = $null
$encryptionKeyV2Hash = $null
try {
  $apiKeyStringResult = Invoke-GcloudJson `
    @(
      "services",
      "api-keys",
      "get-key-string",
      $ServerApiKeyUid,
      "--location=global",
      "--project=$ProjectId"
    ) `
    "inspect the restricted YouTube server API key value"
  $apiKeyString = "$(Property-Value $apiKeyStringResult "keyString")".Trim()
  Assert-True (-not [string]::IsNullOrWhiteSpace($apiKeyString)) `
    "The restricted YouTube server API key value is unavailable."
  $secretApiKeyString = Get-SecretText "YOUTUBE_SERVER_API_KEY"
  $apiKeyHash = Get-Sha256Bytes $apiKeyString
  $secretApiKeyHash = Get-Sha256Bytes $secretApiKeyString
  Assert-True (
    Test-FixedTimeEqual $apiKeyHash $secretApiKeyHash
  ) "YOUTUBE_SERVER_API_KEY does not contain the reviewed API key."

  $encryptionKeyV1Text = Get-SecretText "YOUTUBE_TOKEN_ENCRYPTION_KEY_V1"
  $encryptionKeyV2Text = Get-SecretText "YOUTUBE_TOKEN_ENCRYPTION_KEY_V2"
  $encryptionKeyV1 = ConvertFrom-Base64Url `
    $encryptionKeyV1Text `
    "YOUTUBE_TOKEN_ENCRYPTION_KEY_V1"
  $encryptionKeyV2 = ConvertFrom-Base64Url `
    $encryptionKeyV2Text `
    "YOUTUBE_TOKEN_ENCRYPTION_KEY_V2"
  Assert-True ($encryptionKeyV1.Length -eq 32) `
    "YOUTUBE_TOKEN_ENCRYPTION_KEY_V1 must decode to exactly 32 bytes."
  Assert-True ($encryptionKeyV2.Length -eq 32) `
    "YOUTUBE_TOKEN_ENCRYPTION_KEY_V2 must decode to exactly 32 bytes."
  $encryptionKeyV1Hash = Get-Sha256Bytes `
    ([Convert]::ToBase64String($encryptionKeyV1))
  $encryptionKeyV2Hash = Get-Sha256Bytes `
    ([Convert]::ToBase64String($encryptionKeyV2))
  Assert-True (
    -not (Test-FixedTimeEqual $encryptionKeyV1Hash $encryptionKeyV2Hash)
  ) "The two token-encryption secrets must contain distinct keys."
} finally {
  foreach ($sensitiveBytes in @(
    $apiKeyHash,
    $secretApiKeyHash,
    $encryptionKeyV1,
    $encryptionKeyV2,
    $encryptionKeyV1Hash,
    $encryptionKeyV2Hash
  )) {
    if ($null -ne $sensitiveBytes) {
      [Array]::Clear($sensitiveBytes, 0, $sensitiveBytes.Length)
    }
  }
  $apiKeyString = $null
  $secretApiKeyString = $null
  $encryptionKeyV1Text = $null
  $encryptionKeyV2Text = $null
}

$accessTokenOutput = & $script:GcloudExecutable `
  auth print-access-token --quiet 2>$null
Assert-True ($LASTEXITCODE -eq 0) `
  "Unable to obtain a short-lived token for Firebase inspection."
$accessToken = ($accessTokenOutput | Out-String).Trim()
Assert-True (-not [string]::IsNullOrWhiteSpace($accessToken)) `
  "The Firebase inspection token was empty."
$escapedAppId = [uri]::EscapeDataString($AndroidAppId)

try {
  $androidApp = Get-GoogleJson `
    "https://firebase.googleapis.com/v1beta1/projects/$ProjectId/androidApps/$escapedAppId" `
    $accessToken `
    "inspect the Dev Android app"
  Assert-True ((Property-Value $androidApp "state") -eq "ACTIVE") `
    "The Firebase Android app is not active."
  Assert-True (
    (Property-Value $androidApp "packageName") -eq $expectedAndroidPackage
  ) "The Firebase Android app package identity changed."

  $playIntegrity = Get-GoogleJson `
    "https://firebaseappcheck.googleapis.com/v1/projects/$expectedProjectNumber/apps/$escapedAppId/playIntegrityConfig" `
    $accessToken `
    "inspect the Play Integrity App Check registration"
  $appIntegrity = Property-Value $playIntegrity "appIntegrity"
  $accountDetails = Property-Value $playIntegrity "accountDetails"
  $deviceIntegrity = Property-Value $playIntegrity "deviceIntegrity"
  Assert-True (
    (Property-Value $appIntegrity "allowUnrecognizedVersion") -eq $true
  ) "Private Dev OPPO proof requires unrecognized sideloaded versions."
Assert-True (
  Test-YouTubePrivateDevEffectiveFalse (
    Property-Value $accountDetails "requireLicensed"
  )
) "Private Dev OPPO proof cannot require a Play Store license."
  Assert-True (
    (Property-Value $deviceIntegrity "minDeviceRecognitionLevel") -eq
      "MEETS_DEVICE_INTEGRITY"
  ) "Private Dev OPPO proof must require device integrity."

  $certificates = Get-GoogleJson `
    "https://firebase.googleapis.com/v1beta1/projects/$ProjectId/androidApps/$escapedAppId/sha" `
    $accessToken `
    "inspect the Dev Android signing certificates"
  $certificateList = Property-Value $certificates "certificates"
  $sha256Certificates = if ($null -eq $certificateList) {
    @()
  } else {
    @(
      @($certificateList) |
        Where-Object {
          (Property-Value $_ "certType") -eq "SHA_256"
        } |
        ForEach-Object {
          $hash = Property-Value $_ "shaHash"
          if ($null -ne $hash) {
            Normalize-Sha256 "$hash"
          }
        }
    )
  }
  Assert-True ($sha256Certificates -contains $sha256) `
    "The expected Dev SHA-256 fingerprint is not registered."

  $debugTokens = Get-GoogleJson `
    "https://firebaseappcheck.googleapis.com/v1/projects/$expectedProjectNumber/apps/$escapedAppId/debugTokens?pageSize=100" `
    $accessToken `
    "inspect registered App Check debug tokens"
  $registeredDebugTokens = Property-Value $debugTokens "debugTokens"
  $debugTokenCount = if ($null -eq $registeredDebugTokens) {
    0
  } else {
    @($registeredDebugTokens).Count
  }
  Assert-True ($debugTokenCount -eq 0) `
    "Registered App Check debug tokens remain in the Dev project."
} finally {
  $accessToken = $null
}

Write-Host "YouTube private Dev security prerequisites passed."
Write-Host "API key: restricted to YouTube Data API v3."
Write-Host "App Check: off-Play OPPO contract verified; no debug tokens."
Write-Host "Cloud mutations performed: none."
