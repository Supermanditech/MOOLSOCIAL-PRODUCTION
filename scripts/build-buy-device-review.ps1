[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidatePattern('^(?:BUY|UAW)-[A-Z0-9][A-Z0-9.-]+$')]
  [string]$CandidateId,

  [Parameter(Mandatory)]
  [ValidatePattern('^\d+\.\d+\.\d+-r\d+(?:\.\d+)?$')]
  [string]$BuildName,

  [Parameter(Mandatory)]
  [ValidatePattern('^\d{10}$')]
  [string]$BuildNumber,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$SourceFingerprint,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$ArtifactDirectory,

  [Parameter(Mandatory)]
  [ValidateSet('debug', 'profile', 'release')]
  [string]$BuildMode,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$MachineStatePath,

  [string]$RuntimeStatePath,

  [ValidateSet(
    'EmulatorDeviceReview',
    'YouTubePublicDevReview',
    'PublicAuthSideloadPreflight'
  )]
  [string]$RuntimeProfile = 'EmulatorDeviceReview',

  [switch]$PreflightOnly
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = [IO.Path]::GetFullPath(
  (Split-Path -Parent $PSScriptRoot)
).TrimEnd([char[]]@(
  [IO.Path]::DirectorySeparatorChar,
  [IO.Path]::AltDirectorySeparatorChar
))
$mobileRoot = Join-Path $repositoryRoot 'apps\mobile'
$flutterSupportGuard = Join-Path `
  $PSScriptRoot `
  'invoke-flutter-with-clean-support.ps1'
. $flutterSupportGuard
$artifactPathGuard = Join-Path `
  $PSScriptRoot `
  'release-artifact-path-guard.ps1'
. $artifactPathGuard
$artifactRoot = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $repositoryRoot `
  -Path $ArtifactDirectory `
  -Label 'device-review artifact directory'
$machineStateFile = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $repositoryRoot `
  -Path $MachineStatePath `
  -Label 'APK regression machine-state file'
$runtimeStateFile = if ($CandidateId -ceq
    'UAW-R60.92-SOCIAL-RUNTIME-CONSOLIDATED-APK') {
  if ([string]::IsNullOrWhiteSpace($RuntimeStatePath)) {
    throw 'R60.92 runtime-definition state path is missing.'
  }
  Resolve-ReleaseArtifactRepositoryDescendant `
    -RepositoryRoot $repositoryRoot `
    -Path $RuntimeStatePath `
    -Label 'R60.92 runtime-definition state file'
} else {
  $machineStateFile
}
$runtimeDefineFile = $null

$branch = git -C $repositoryRoot branch --show-current
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
  throw 'Unable to identify the current Git branch.'
}
if ($branch.Trim() -eq 'main') {
  throw 'Device-review builds are forbidden on main.'
}

if ($CandidateId -ceq
  'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR') {
  $fix11ReadinessGate = Join-Path `
    $PSScriptRoot `
    'check-uaw-c34p-fix11-google-sign-in-forensic-readiness.ps1'
  & $fix11ReadinessGate -RepositoryRoot $repositoryRoot | Out-Null
  $fix11ReadinessPassed = $?
  if (-not $fix11ReadinessPassed) {
    throw 'FIX11 Google-only forensic readiness gate failed.'
  }
}

$successorBuildFoundationGate = Join-Path `
  $PSScriptRoot `
  'test-public-auth-sideload-build-controls.ps1'
& $successorBuildFoundationGate `
  -RepositoryRoot $repositoryRoot `
  -PreApkStatePath $machineStateFile | Out-Null
$successorBuildFoundationPassed = $?
if (-not $successorBuildFoundationPassed) {
  throw 'Mandatory successor APK build-foundation gate failed.'
}

$artifactPathGate = Join-Path `
  $PSScriptRoot `
  'test-release-artifact-path-containment.ps1'
& $artifactPathGate -RepositoryRoot $repositoryRoot | Out-Null
$pluginIntegrityFixtureGate = Join-Path `
  $PSScriptRoot `
  'test-release-production-plugin-integrity.ps1'
& $pluginIntegrityFixtureGate -RepositoryRoot $repositoryRoot | Out-Null
$pluginManifestNamespaceGate = Join-Path `
  $PSScriptRoot `
  'check-android-plugin-manifest-namespace-readiness.ps1'
$kotlinPluginReadinessGate = Join-Path `
  $PSScriptRoot `
  'check-android-release-kotlin-plugin-readiness.ps1'
$resourceIntegrityGate = Join-Path `
  $PSScriptRoot `
  'check-android-release-resource-integrity.ps1'

if (-not (Test-Path -LiteralPath $artifactRoot -PathType Container)) {
  New-Item -ItemType Directory -Path $artifactRoot | Out-Null
}

$artifactName = (
  $CandidateId.ToLowerInvariant() -replace '[^a-z0-9.-]', '-'
) + "-device-review-$BuildMode.apk"
$artifactPath = Join-Path $artifactRoot $artifactName
$manifestPath = Join-Path $artifactRoot (
  $CandidateId.ToLowerInvariant() + '-build-provenance.txt'
)

foreach ($reservedPath in @($artifactPath, $manifestPath)) {
  if (Test-Path -LiteralPath $reservedPath) {
    throw "Refusing to overwrite existing device-review evidence: $reservedPath"
  }
}

function Get-YouTubePublicDevRuntimeValues {
  param(
    [Parameter(Mandatory)]
    [object]$MachineState
  )

  $client = $MachineState.firebaseClientConfiguration
  if ($null -eq $client) {
    throw 'YouTube public Dev review requires registered Firebase client configuration.'
  }
  $expectedProjectId = [string]$client.projectId
  $expectedProjectNumber = [string]$client.projectNumber
  $expectedAppId = [string]$client.androidAppId
  $expectedPackageName = [string]$client.packageName
  if ($expectedProjectId -cne 'moolsocial-dev-503018' -or
      $expectedProjectNumber -cne '760290687711' -or
      $expectedAppId -cne '1:760290687711:android:4202409fd3ab38f6ce076a' -or
      $expectedPackageName -cne 'com.moolsocial.app') {
    throw 'Registered Firebase client identity is outside the exact Dev Android boundary.'
  }

  $contextGate = Join-Path `
    $PSScriptRoot `
    'check-youtube-public-dev-build-context.ps1'
  if (-not (Test-Path -LiteralPath $contextGate -PathType Leaf)) {
    throw 'The YouTube public Dev Google Cloud context gate is missing.'
  }
  $gcloudContext = & $contextGate `
    -ExpectedConfiguration 'moolsocial-dev-fsc02d' `
    -ExpectedAccount 'hello@moolsocial.com' `
    -ExpectedProject $expectedProjectId
  $gcloudSource = [string]$gcloudContext.gcloudSource
  if ([string]::IsNullOrWhiteSpace($gcloudSource)) {
    throw 'The qualified Google Cloud CLI source is missing.'
  }

  $accessToken = ''
  $configText = ''
  try {
    $accessToken = (& $gcloudSource auth print-access-token --quiet).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($accessToken)) {
      throw 'A short-lived Firebase Management API token could not be acquired.'
    }
    $encodedAppId = [Uri]::EscapeDataString($expectedAppId)
    $configUri = (
      'https://firebase.googleapis.com/v1beta1/projects/' +
      "$expectedProjectId/androidApps/$encodedAppId/config"
    )
    $response = Invoke-RestMethod `
      -Method Get `
      -Uri $configUri `
      -Headers @{
        Authorization = "Bearer $accessToken"
        'X-Goog-User-Project' = $expectedProjectId
      }
    if ([string]::IsNullOrWhiteSpace([string]$response.configFileContents)) {
      throw 'Firebase Android SDK configuration content is missing.'
    }
    $configText = [Text.Encoding]::UTF8.GetString(
      [Convert]::FromBase64String([string]$response.configFileContents)
    )
    $config = $configText | ConvertFrom-Json
    $matchingClients = @(
      $config.client | Where-Object {
        [string]$_.client_info.android_client_info.package_name -ceq `
          $expectedPackageName
      }
    )
    if ($matchingClients.Count -ne 1) {
      throw 'The exact Firebase Android package configuration is missing or duplicated.'
    }
    $matchingClient = $matchingClients[0]
    $firebaseApiKeys = @(
      $matchingClient.api_key | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_.current_key)
      }
    )
    if ([string]$config.project_info.project_id -cne $expectedProjectId -or
        [string]$config.project_info.project_number -cne $expectedProjectNumber -or
        [string]$matchingClient.client_info.mobilesdk_app_id -cne $expectedAppId -or
        $firebaseApiKeys.Count -ne 1) {
      throw 'Firebase Android SDK configuration identity does not match the registered candidate.'
    }

    return [ordered]@{
      MOOLSOCIAL_DEVICE_REVIEW = 'true'
      MOOLSOCIAL_USE_EMULATORS = 'false'
      MOOLSOCIAL_CANDIDATE_ID = $CandidateId
      MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW = 'true'
      MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF = 'true'
      MOOLSOCIAL_YOUTUBE_PROVIDER_URL = 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeProvider'
      MOOLSOCIAL_SOCIAL_CONTENT_URL = 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent'
      MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED = 'true'
      MOOLSOCIAL_YOUTUBE_SHORTS_AUTOPLAY_ENABLED = 'true'
      MOOLSOCIAL_FIREBASE_API_KEY = [string]$firebaseApiKeys[0].current_key
      MOOLSOCIAL_FIREBASE_APP_ID = $expectedAppId
      MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID = $expectedProjectNumber
      MOOLSOCIAL_FIREBASE_PROJECT_ID = $expectedProjectId
    }
  } finally {
    $accessToken = $null
    $configText = $null
    $config = $null
    $response = $null
    $gcloudContext = $null
    $gcloudSource = $null
  }
}

function Get-PublicAuthSideloadRuntimeValues {
  param(
    [Parameter(Mandatory)]
    [object]$MachineState
  )

  $client = $MachineState.firebaseClientConfiguration
  if (
    [string]$client.projectId -cne 'moolsocial-dev-503018' -or
    [string]$client.projectNumber -cne '760290687711' -or
    [string]$client.androidAppId -cne
      '1:760290687711:android:4202409fd3ab38f6ce076a' -or
    [string]$client.packageName -cne 'com.moolsocial.app'
  ) {
    throw 'Public-auth sideload Firebase identity is outside Dev Android.'
  }

  $privateBuildNames = @(
    'MOOLSOCIAL_UPLOAD_STORE_FILE',
    'MOOLSOCIAL_UPLOAD_STORE_PASSWORD',
    'MOOLSOCIAL_UPLOAD_KEY_ALIAS',
    'MOOLSOCIAL_UPLOAD_KEY_PASSWORD'
  )
  $facebookRuntimeRequired =
    [string]$MachineState.requiredRuntimeDefines.MOOLSOCIAL_FACEBOOK_ENABLED `
      -ceq 'true'
  if ($facebookRuntimeRequired) {
    $privateBuildNames += @(
      'MOOLSOCIAL_FACEBOOK_APP_ID',
      'MOOLSOCIAL_FACEBOOK_CLIENT_TOKEN'
    )
  }
  foreach ($name in $privateBuildNames) {
    if ([string]::IsNullOrWhiteSpace(
      [Environment]::GetEnvironmentVariable($name, 'Process')
    )) {
      throw 'Public-auth sideload private build input is missing.'
    }
  }
  if (-not (Test-Path -LiteralPath $env:MOOLSOCIAL_UPLOAD_STORE_FILE)) {
    throw 'Public-auth sideload keystore is missing.'
  }

  $runtimeNames = @(
    'MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW',
    'MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF',
    'MOOLSOCIAL_YOUTUBE_PROVIDER_URL',
    'MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED',
    'MOOLSOCIAL_YOUTUBE_SHORTS_AUTOPLAY_ENABLED',
    'MOOLSOCIAL_CHAT_URL',
    'MOOLSOCIAL_FIREBASE_API_KEY',
    'MOOLSOCIAL_FIREBASE_APP_ID',
    'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
    'MOOLSOCIAL_FIREBASE_PROJECT_ID',
    'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
    'MOOLSOCIAL_AUTH_API_BASE_URL',
    'MOOLSOCIAL_X_CALLBACK_URL',
    'MOOLSOCIAL_X_AUTHORIZATION_ENDPOINT',
    'MOOLSOCIAL_INSTAGRAM_CALLBACK_URL',
    'MOOLSOCIAL_INSTAGRAM_AUTHORIZATION_ENDPOINT',
    'MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL',
    'MOOLSOCIAL_EMAIL_LINK_DOMAIN',
    'MOOLSOCIAL_FACEBOOK_GRAPH_REVOCATION_ENDPOINT',
    'MOOLSOCIAL_GOOGLE_PROVIDER_QUALIFIED',
    'MOOLSOCIAL_GOOGLE_PLAY_SIGNING_QUALIFIED',
    'MOOLSOCIAL_SIDELOAD_PREFLIGHT_ENABLED',
    'MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT',
    'MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE',
    'MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED',
    'MOOLSOCIAL_PHONE_OTP_ENABLED',
    'MOOLSOCIAL_MOBILE_OTP_ATTESTATION_QUALIFIED',
    'MOOLSOCIAL_APPLE_ENABLED',
    'MOOLSOCIAL_APPLE_PROVIDER_QUALIFIED',
    'MOOLSOCIAL_APPLE_PLATFORM_CONFIGURATION_QUALIFIED',
    'MOOLSOCIAL_APPLE_REVOCATION_QUALIFIED',
    'MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED',
    'MOOLSOCIAL_X_CLIENT_ID_CONFIGURED',
    'MOOLSOCIAL_X_EXACT_REDIRECT_QUALIFIED',
    'MOOLSOCIAL_X_FIREBASE_BROKER_QUALIFIED',
    'MOOLSOCIAL_INSTAGRAM_ENABLED',
    'MOOLSOCIAL_INSTAGRAM_PROFESSIONAL_LOGIN_QUALIFIED',
    'MOOLSOCIAL_INSTAGRAM_EXACT_REDIRECT_QUALIFIED',
    'MOOLSOCIAL_INSTAGRAM_FIREBASE_BROKER_QUALIFIED',
    'MOOLSOCIAL_INSTAGRAM_REVOCATION_QUALIFIED',
    'MOOLSOCIAL_FACEBOOK_ENABLED',
    'MOOLSOCIAL_FACEBOOK_PROVIDER_QUALIFIED',
    'MOOLSOCIAL_FACEBOOK_ANDROID_CONFIGURATION_QUALIFIED',
    'MOOLSOCIAL_FACEBOOK_REVOCATION_QUALIFIED',
    'MOOLSOCIAL_FACEBOOK_DATA_DELETION_QUALIFIED'
  )
  $values = [ordered]@{
    MOOLSOCIAL_DEVICE_REVIEW = 'true'
    MOOLSOCIAL_USE_EMULATORS = 'false'
    MOOLSOCIAL_CANDIDATE_ID = $CandidateId
    MOOLSOCIAL_SOCIAL_CONTENT_URL = 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent'
  }
  foreach ($name in $runtimeNames) {
    $value = [Environment]::GetEnvironmentVariable($name, 'Process')
    $allowsEmptyDefaultEmailLinkDomain =
      $name -ceq 'MOOLSOCIAL_EMAIL_LINK_DOMAIN'
    $allowsEmptyHeldFix11ProviderInput =
      $CandidateId -ceq
        'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR' -and
      $name -ceq 'MOOLSOCIAL_YOUTUBE_PROVIDER_URL'
    if (
      -not $allowsEmptyDefaultEmailLinkDomain -and
      -not $allowsEmptyHeldFix11ProviderInput -and
      [string]::IsNullOrWhiteSpace($value)
    ) {
      throw "Public-auth sideload runtime input '$name' is missing."
    }
    if (
      ($allowsEmptyDefaultEmailLinkDomain -or
        $allowsEmptyHeldFix11ProviderInput) -and
      $null -eq $value
    ) {
      $value = ''
    }
    $values[$name] = $value
  }
  $expectedChatUrl =
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/' +
    'moolSocialChat'
  if ([string]$values.MOOLSOCIAL_CHAT_URL -cne $expectedChatUrl) {
    throw 'Public-auth sideload Chat endpoint differs from the live environment.'
  }
  if ($CandidateId -ceq
    'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR') {
    if (
      [string]$values.MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE -cne 'true' -or
      [string]$values.MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW -cne 'false' -or
      [string]$values.MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF -cne 'false' -or
      [string]$values.MOOLSOCIAL_PHONE_OTP_ENABLED -cne 'false' -or
      [string]$values.MOOLSOCIAL_APPLE_ENABLED -cne 'false' -or
      [string]$values.MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED -cne 'false' -or
      [string]$values.MOOLSOCIAL_INSTAGRAM_ENABLED -cne 'false' -or
      [string]$values.MOOLSOCIAL_FACEBOOK_ENABLED -cne 'false'
    ) {
      throw 'FIX11 runtime is not Google-only or a held provider is enabled.'
    }
  }
  return $values
}

$machineState = Get-Content -Raw -LiteralPath $runtimeStateFile |
  ConvertFrom-Json
if (
  [string]$machineState.requiredRuntimeDefines.
    MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL -cne 'https://moolsocial.com/app' -or
  [string]$machineState.requiredRuntimeDefines.
    MOOLSOCIAL_EMAIL_LINK_DOMAIN -cne ''
) {
  throw 'Public-auth sideload Email Link Hosting configuration is not qualified.'
}
$facebookRuntimeRequiredForBuild =
  $RuntimeProfile -ceq 'PublicAuthSideloadPreflight' -and
  [string]$machineState.requiredRuntimeDefines.MOOLSOCIAL_FACEBOOK_ENABLED `
    -ceq 'true'
$fullSocialRuntimeRequired =
  $RuntimeProfile -ceq 'PublicAuthSideloadPreflight' -and
  (
    $facebookRuntimeRequiredForBuild -or
    [string]$machineState.requiredRuntimeDefines.MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED `
      -ceq 'true' -or
    [string]$machineState.requiredRuntimeDefines.MOOLSOCIAL_INSTAGRAM_ENABLED `
      -ceq 'true'
  )
if ($fullSocialRuntimeRequired) {
  & (Join-Path $PSScriptRoot `
    'check-full-social-founder-dev-readiness.ps1') `
    -RepositoryRoot $repositoryRoot | Out-Null
  $fullSocialReadinessPassed = $?
  if (-not $fullSocialReadinessPassed) {
    throw 'Full-social founder Dev readiness prebuild gate failed.'
  }
}
$runtimeValues = if ($RuntimeProfile -ceq 'YouTubePublicDevReview') {
  Get-YouTubePublicDevRuntimeValues -MachineState $machineState
} elseif ($RuntimeProfile -ceq 'PublicAuthSideloadPreflight') {
  Get-PublicAuthSideloadRuntimeValues -MachineState $machineState
} else {
  [ordered]@{
    MOOLSOCIAL_DEVICE_REVIEW = 'true'
    MOOLSOCIAL_USE_EMULATORS = 'true'
    MOOLSOCIAL_CANDIDATE_ID = $CandidateId
  }
}
$runtimeDefines = @(
  $runtimeValues.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
)

& (Join-Path $PSScriptRoot `
  'check-google-android-identity-bridge-readiness.ps1') `
  -RepositoryRoot $repositoryRoot

if ($RuntimeProfile -ceq 'PublicAuthSideloadPreflight') {
  & (Join-Path $PSScriptRoot `
    'check-google-android-oauth-signing-readiness.ps1') `
    -GoogleServicesPath (
      Join-Path $mobileRoot 'android\app\google-services.json'
    ) `
    -GoogleServerClientId $runtimeValues['MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID'] `
    -KeystorePath $env:MOOLSOCIAL_UPLOAD_STORE_FILE `
    -KeyAlias $env:MOOLSOCIAL_UPLOAD_KEY_ALIAS
  $googleReadinessPassed = $?
  if (-not $googleReadinessPassed) {
    throw 'Google Android OAuth signer preflight failed.'
  }
}

Push-Location $mobileRoot
try {
  if ($CandidateId -ceq
      'UAW-R60.92-SOCIAL-RUNTIME-CONSOLIDATED-APK') {
    & (Join-Path $repositoryRoot `
      'scripts\check-pre-apk-readiness-r60-92.ps1') `
      -RepositoryRoot $repositoryRoot `
      -StatePath $machineStateFile `
      -Phase BuildAuthorized
    $apkMachineGatePassed = $?
  } else {
    $gateScript = Join-Path $repositoryRoot (
      'scripts\check-apk-regression-gate-state.ps1'
    )
    & $gateScript `
      -StatePath $machineStateFile `
      -CandidateId $CandidateId `
      -BuildName $BuildName `
      -BuildNumber $BuildNumber `
      -BuildMode $BuildMode `
      -SourceFingerprint $SourceFingerprint `
      -RuntimeDefine $runtimeDefines
    $apkMachineGatePassed = $?
  }
  if (-not $apkMachineGatePassed) {
    throw 'APK regression pre-build machine gate failed.'
  }

  $lockedDependencyReleasePreflight = {
    & flutter pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) {
      throw 'Locked Flutter dependency resolution failed before APK build.'
    }
    & $pluginManifestNamespaceGate `
      -RepositoryRoot $repositoryRoot | Out-Null
    if (-not $?) {
      throw 'Android plugin manifest-namespace readiness failed.'
    }
    & $kotlinPluginReadinessGate `
      -RepositoryRoot $repositoryRoot | Out-Null
    if (-not $?) {
      throw 'Android release Kotlin-plugin readiness failed.'
    }
    & $resourceIntegrityGate `
      -RepositoryRoot $repositoryRoot `
      -RunGradleLink | Out-Null
    if (-not $?) {
      throw 'Android release resource-integrity preflight failed.'
    }
  }

  if ($PreflightOnly) {
    $dependencyPreflightExit = Invoke-MoolSocialFlutterWithCleanSupport `
      -RepositoryRoot $repositoryRoot `
      -Invocation $lockedDependencyReleasePreflight
    if ($dependencyPreflightExit -ne 0) {
      throw 'Guarded Android dependency preflight failed.'
    }
    Write-Output (
      'Device-review APK preflight passed without artifact build: ' +
      "candidate=$CandidateId; version=$BuildName; buildNumber=$BuildNumber; " +
      "runtimeProfile=$RuntimeProfile."
    )
    return
  }

  $buildArguments = @(
    'build',
    'apk',
    "--$BuildMode",
    '--no-pub',
    '--build-name',
    $BuildName,
    '--build-number',
    $BuildNumber
  )
  if ($RuntimeProfile -cne 'EmulatorDeviceReview') {
    $runtimeDefineFile = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllText(
      $runtimeDefineFile,
      ($runtimeValues | ConvertTo-Json -Compress),
      [Text.UTF8Encoding]::new($false)
    )
    $buildArguments += @('--dart-define-from-file', $runtimeDefineFile)
  } else {
    foreach ($runtimeDefine in $runtimeDefines) {
      $buildArguments += @('--dart-define', $runtimeDefine)
    }
  }
  $flutterExit = Invoke-MoolSocialFlutterWithCleanSupport `
    -RepositoryRoot $repositoryRoot `
    -Invocation {
      & $lockedDependencyReleasePreflight
      & flutter @buildArguments
    }
  if ($flutterExit -ne 0) {
    throw 'Flutter device-review APK build failed.'
  }

  $generatedApk = Join-Path $mobileRoot (
    "build\app\outputs\flutter-apk\app-$BuildMode.apk"
  )
  if (-not (Test-Path -LiteralPath $generatedApk -PathType Leaf)) {
    throw "Expected Flutter APK is missing: $generatedApk"
  }
  $pluginIntegrityGate = Join-Path $repositoryRoot (
    'scripts\check-apk-production-plugin-integrity.ps1'
  )
  & $pluginIntegrityGate `
    -ApkPath $generatedApk `
    -CandidateId $CandidateId `
    -RepositoryRoot $repositoryRoot `
    -ProguardFolderPath (
      Join-Path $mobileRoot 'build\app\outputs\mapping\release'
    ) `
    -RequireMappingAware
  if (-not $?) {
    throw 'APK production plugin integrity gate failed.'
  }
  Copy-Item -LiteralPath $generatedApk -Destination $artifactPath
} finally {
  if ($null -ne $runtimeDefineFile -and
      (Test-Path -LiteralPath $runtimeDefineFile -PathType Leaf)) {
    Remove-Item -LiteralPath $runtimeDefineFile -Force
  }
  $runtimeValues = $null
  $runtimeDefines = $null
  Pop-Location
}

$apk = Get-Item -LiteralPath $artifactPath
$apkHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash
$head = git -C $repositoryRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0) {
  throw 'Unable to identify the current Git HEAD.'
}
$metaInputSummary = if (
  $RuntimeProfile -ceq 'PublicAuthSideloadPreflight' -and
  $facebookRuntimeRequiredForBuild
) {
  'MetaInputs=present_not_logged'
} else {
  'MetaInputs=absent_fail_closed'
}
$runtimeSummary = if ($RuntimeProfile -ceq 'YouTubePublicDevReview') {
  'YouTubePublicDevReview;FirebaseAndroidSdkConfig=present_not_logged;' +
  'YouTubeServerSecrets=absent'
} elseif ($RuntimeProfile -ceq 'PublicAuthSideloadPreflight') {
  'PublicAuthSideloadPreflight;FirebaseAndroidSdkConfig=present_not_logged;' +
  "SigningInputs=present_not_logged;$metaInputSummary;" +
  'PlaySigningQualified=false;' +
  'AppleEnabled=false;MobileOtpAttestationQualified=false'
} else {
  'MOOLSOCIAL_DEVICE_REVIEW=true;' +
  'MOOLSOCIAL_USE_EMULATORS=true;' +
  "MOOLSOCIAL_CANDIDATE_ID=$CandidateId"
}

@(
  "CandidateId=$CandidateId",
  "RuntimeProfile=$RuntimeProfile",
  "RuntimeDefines=$runtimeSummary",
  "Version=$BuildName",
  "VersionCode=$BuildNumber",
  "BuildMode=$BuildMode",
  "MachineState=$machineStateFile",
  "RuntimeState=$runtimeStateFile",
  "Branch=$($branch.Trim())",
  "HEAD=$($head.Trim())",
  "SourceFingerprint=$SourceFingerprint",
  "APK=$artifactPath",
  "Bytes=$($apk.Length)",
  "SHA256=$apkHash",
  "BuiltAt=$([DateTimeOffset]::Now.ToString('o'))"
) | Set-Content -LiteralPath $manifestPath -Encoding utf8

Get-Content -LiteralPath $manifestPath
