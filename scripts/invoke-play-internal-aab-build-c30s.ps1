[CmdletBinding()]
param([string]$StatePath, [string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'C30S requires PowerShell 7 before authority mutation.' }
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) { $StatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30s.json' }
$stateFile = [IO.Path]::GetFullPath($StatePath)

function Assert-C30SBuild {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30S single AAB build rejected: $Message" }
}
function Resolve-RepoPath {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C30SBuild -Condition (-not [IO.Path]::IsPathRooted($Path)) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30SBuild -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  return $resolved
}
function Write-State {
  param([Parameter(Mandatory)][object]$State)
  $temporary = $stateFile + '.c30s-write'
  Assert-C30SBuild -Condition (-not (Test-Path -LiteralPath $temporary)) -Message 'stale state temporary exists.'
  [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 40) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $stateFile -Force
}
function Get-ArtifactSnapshot {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'absent' }
  $file = Get-Item -LiteralPath $Path
  return '{0}|{1}|{2}' -f $file.Length, $file.LastWriteTimeUtc.Ticks, (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function Invoke-FlutterCaptured {
  param([Parameter(Mandatory)][string[]]$Arguments, [Parameter(Mandatory)][string]$LogPath)
  $savedErrorActionPreference = $ErrorActionPreference
  $savedNativePreference = $PSNativeCommandUseErrorActionPreference
  try {
    $PSNativeCommandUseErrorActionPreference = $false
    $ErrorActionPreference = 'Continue'
    & flutter @Arguments *> $LogPath
    return $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $savedErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $savedNativePreference
  }
}
function Invoke-GradleCaptured {
  param([Parameter(Mandatory)][string[]]$Arguments, [Parameter(Mandatory)][string]$LogPath)
  $savedErrorActionPreference = $ErrorActionPreference
  $savedNativePreference = $PSNativeCommandUseErrorActionPreference
  try {
    $PSNativeCommandUseErrorActionPreference = $false
    $ErrorActionPreference = 'Continue'
    & .\gradlew.bat @Arguments *> $LogPath
    return $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $savedErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $savedNativePreference
  }
}
function Assert-SourceManifestCurrent {
  param([Parameter(Mandatory)][string]$ManifestPath)
  foreach ($line in Get-Content -LiteralPath $ManifestPath) {
    $match = [regex]::Match($line, '^([0-9A-F]{64})  (.+)$')
    Assert-C30SBuild -Condition $match.Success -Message 'source manifest row is malformed.'
    $path = Resolve-RepoPath -Path $match.Groups[2].Value -Label 'source owner'
    Assert-C30SBuild -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "source owner is missing: $path"
    Assert-C30SBuild -Condition ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ceq $match.Groups[1].Value) -Message "source changed after qualification: $($match.Groups[2].Value)"
  }
}

Assert-C30SBuild -Condition ($stateFile.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $stateFile -PathType Leaf)) -Message 'state path invalid.'
$gate = Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30s.ps1'
& $gate -Phase build -RepositoryRoot $root
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C30SBuild -Condition ([bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder) -Message 'founder Firebase inputs are not qualified.'

foreach ($name in @([string[]]$state.signingQualification.uploadKeyEnvironmentNames) + @([string]$state.runtimeConfiguration.secretDefineFileEnvironmentName) + @([string]$state.runtimeConfiguration.googleServicesFileEnvironmentName)) {
  Assert-C30SBuild -Condition (Test-Path -LiteralPath ('Env:{0}' -f $name)) -Message "founder environment entry missing: $name"
}
$uploadStorePath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_UPLOAD_STORE_FILE')
$secretDefinePath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_FIREBASE_DART_DEFINE_FILE')
$googleServicesPath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_GOOGLE_SERVICES_JSON')
Assert-C30SBuild -Condition (Test-Path -LiteralPath $uploadStorePath -PathType Leaf) -Message 'upload keystore missing.'
Assert-C30SBuild -Condition (Test-Path -LiteralPath $secretDefinePath -PathType Leaf) -Message 'transient define file missing.'
$expectedGoogleServicesPath = Resolve-RepoPath -Path ([string]$state.runtimeConfiguration.transientGoogleServicesPath) -Label 'transient Google Services configuration'
Assert-C30SBuild -Condition ([IO.Path]::GetFullPath($googleServicesPath) -ceq $expectedGoogleServicesPath -and (Test-Path -LiteralPath $expectedGoogleServicesPath -PathType Leaf)) -Message 'transient Google Services configuration path changed.'

$artifactRelative = 'artifacts/quality/uaw-personal-mvp-social-play-internal-firebase-startup-recovery-c30s-r60-44-20260812-01'
$artifactRoot = Resolve-RepoPath -Path $artifactRelative -Label 'evidence directory'
Assert-C30SBuild -Condition (Test-Path -LiteralPath $artifactRoot -PathType Container) -Message 'evidence directory missing.'
$mobileRoot = Resolve-RepoPath -Path 'apps/mobile' -Label 'mobile root'
$generatedPath = Resolve-RepoPath -Path 'apps/mobile/build/app/outputs/bundle/release/app-release.aab' -Label 'generated AAB'
$releaseApkPath = Resolve-RepoPath -Path 'apps/mobile/build/app/outputs/flutter-apk/app-release.apk' -Label 'release APK sentinel'
$registrantPath = Resolve-RepoPath -Path 'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java' -Label 'generated registrant'
$mergedManifestPath = Resolve-RepoPath -Path 'apps/mobile/build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml' -Label 'fresh merged release manifest'
$manifestBlamePath = Resolve-RepoPath -Path 'apps/mobile/build/app/intermediates/manifest_merge_blame_file/release/processReleaseMainManifest/manifest-merger-blame-release-report.txt' -Label 'fresh release manifest merger blame'
$bundletoolPath = Resolve-RepoPath -Path ([string]$state.toolingQualification.standaloneBundletoolPath) -Label 'standalone bundletool'
$sealedRelative = "$artifactRelative/MoolSocial-1.0.0-r60.44-2026081244-release.aab"
$sealedPath = Resolve-RepoPath -Path $sealedRelative -Label 'sealed AAB'
Assert-C30SBuild -Condition (-not (Test-Path -LiteralPath $sealedPath)) -Message 'sealed r60.44 AAB already exists.'
$preflightAttempt = 0
do {
  $preflightAttempt++
  Assert-C30SBuild -Condition ($preflightAttempt -le 5) -Message 'all five immutable preflight evidence slots are occupied.'
  $attemptSuffix = if ($preflightAttempt -eq 1) { '' } else { "-attempt-$preflightAttempt" }
  $configLogRelative = "$artifactRelative/03-release-config-only$attemptSuffix.log"
  $configLogPath = Resolve-RepoPath -Path $configLogRelative -Label 'config log'
  $manifestLogRelative = "$artifactRelative/04-release-manifest-preflight$attemptSuffix.log"
  $manifestLogPath = Resolve-RepoPath -Path $manifestLogRelative -Label 'manifest log'
  $buildLogRelative = "$artifactRelative/05-release-aab-build$attemptSuffix.log"
  $buildLogPath = Resolve-RepoPath -Path $buildLogRelative -Label 'build log'
  $prebuildRelative = "$artifactRelative/03a-prebuild-machine-state$attemptSuffix.json"
  $prebuildPath = Resolve-RepoPath -Path $prebuildRelative -Label 'prebuild state'
  $mergedManifestEvidenceRelative = "$artifactRelative/04a-merged-release-manifest$attemptSuffix.xml"
  $mergedManifestEvidencePath = Resolve-RepoPath -Path $mergedManifestEvidenceRelative -Label 'merged manifest evidence'
  $manifestBlameEvidenceRelative = "$artifactRelative/04b-release-manifest-merger-blame$attemptSuffix.txt"
  $manifestBlameEvidencePath = Resolve-RepoPath -Path $manifestBlameEvidenceRelative -Label 'manifest merger blame evidence'
  $provenanceRelative = "$artifactRelative/06-release-aab-provenance$attemptSuffix.json"
  $provenancePath = Resolve-RepoPath -Path $provenanceRelative -Label 'provenance'
  $attemptOutputs = @($configLogPath, $manifestLogPath, $buildLogPath, $prebuildPath, $mergedManifestEvidencePath, $manifestBlameEvidencePath, $provenancePath)
  $attemptOccupied = @($attemptOutputs | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0
} while ($attemptOccupied)

Assert-C30SBuild -Condition ((Get-FileHash -LiteralPath $bundletoolPath -Algorithm SHA256).Hash -ceq [string]$state.toolingQualification.standaloneBundletoolSha256) -Message 'standalone bundletool identity changed.'
Assert-C30SBuild -Condition ((Split-Path -Leaf $bundletoolPath) -ceq 'bundletool-all-1.18.3.jar') -Message 'standalone bundletool filename changed.'
$sourceManifest = Resolve-RepoPath -Path ([string]$state.sourceQualification.manifestPath) -Label 'source manifest'
Assert-C30SBuild -Condition ((Get-FileHash -LiteralPath $sourceManifest -Algorithm SHA256).Hash -ceq ([string]$state.sourceQualification.manifestSha256).ToUpperInvariant()) -Message 'accepted source-manifest file changed.'
Assert-SourceManifestCurrent -ManifestPath $sourceManifest

$mobilePushed = $false
$androidPushed = $false
try {
  Push-Location $mobileRoot
  $mobilePushed = $true
  $releaseApkBefore = Get-ArtifactSnapshot -Path $releaseApkPath
  $releaseAabBefore = Get-ArtifactSnapshot -Path $generatedPath
  $pubspecHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash
  $lockHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash
  $releaseConfigArguments = @('build', 'apk', '--release', '--config-only', '--build-name=1.0.0-r60.44', '--build-number=2026081244')
  $releaseConfigExitCode = Invoke-FlutterCaptured -Arguments $releaseConfigArguments -LogPath $configLogPath
  if ($releaseConfigExitCode -ne 0) { throw "release config-only failed with exit $releaseConfigExitCode" }
  Assert-C30SBuild -Condition ($pubspecHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash -and $lockHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash) -Message 'release config-only changed pubspec.yaml or pubspec.lock.'
  Assert-C30SBuild -Condition ($releaseApkBefore -ceq (Get-ArtifactSnapshot -Path $releaseApkPath) -and $releaseAabBefore -ceq (Get-ArtifactSnapshot -Path $generatedPath)) -Message 'release config-only created or changed an APK or AAB.'
  Assert-C30SBuild -Condition (Test-Path -LiteralPath $registrantPath -PathType Leaf) -Message 'release registrant missing after config-only.'
  $registrant = Get-Content -Raw -LiteralPath $registrantPath
  Assert-C30SBuild -Condition (-not $registrant.Contains('IntegrationTestPlugin', [StringComparison]::Ordinal) -and [regex]::Matches($registrant, 'flutterEngine\.getPlugins\(\)\.add').Count -eq 15) -Message 'release registrant plugin set changed.'
  Pop-Location
  $mobilePushed = $false

  Push-Location (Join-Path $mobileRoot 'android')
  $androidPushed = $true
  $manifestExitCode = Invoke-GradleCaptured -Arguments @(':app:processReleaseMainManifest', '--rerun-tasks', '--console=plain') -LogPath $manifestLogPath
  if ($manifestExitCode -ne 0) { throw "fresh release manifest preflight failed with exit $manifestExitCode" }
  Pop-Location
  $androidPushed = $false

  Assert-C30SBuild -Condition (Test-Path -LiteralPath $mergedManifestPath -PathType Leaf) -Message 'fresh merged release manifest is missing.'
  $manifestLogText = Get-Content -Raw -LiteralPath $manifestLogPath
  Assert-C30SBuild -Condition ($manifestLogText.Contains('processReleaseGoogleServices', [StringComparison]::Ordinal) -and $manifestLogText.Contains('injectCrashlyticsMappingFileIdRelease', [StringComparison]::Ordinal) -and $manifestLogText.Contains('BUILD SUCCESSFUL', [StringComparison]::Ordinal)) -Message 'release manifest preflight lacks explicit Google Services or Crashlytics build-ID execution proof.'
  $manifestLogText = $null
  $mergedManifest = Get-Content -Raw -LiteralPath $mergedManifestPath
  foreach ($pattern in @('package="com.moolsocial.app"', 'android:versionCode="2026081244"', 'android:versionName="1.0.0-r60.44"', 'android:minSdkVersion="24"', 'android:targetSdkVersion="36"', 'android:allowBackup="false"')) {
    Assert-C30SBuild -Condition $mergedManifest.Contains($pattern, [StringComparison]::Ordinal) -Message "merged release manifest missing $pattern"
  }
  Assert-C30SBuild -Condition (-not $mergedManifest.Contains('android:usesCleartextTraffic="true"', [StringComparison]::OrdinalIgnoreCase)) -Message 'merged release manifest enables cleartext traffic.'
  [xml]$manifestXml = $mergedManifest
  $namespace = [Xml.XmlNamespaceManager]::new($manifestXml.NameTable)
  $namespace.AddNamespace('android', 'http://schemas.android.com/apk/res/android')
  $mergedPermissions = @($manifestXml.SelectNodes('/manifest/uses-permission', $namespace) | ForEach-Object { $_.GetAttribute('name', 'http://schemas.android.com/apk/res/android') })
  $readGservicesPermission = 'com.google.android.providers.gsf.permission.READ_GSERVICES'
  Assert-C30SBuild -Condition (@($mergedPermissions | Where-Object { $_ -ceq $readGservicesPermission }).Count -eq 1) -Message 'Firebase Auth reCAPTCHA READ_GSERVICES permission is missing or duplicated.'
  foreach ($permission in @('android.permission.POST_NOTIFICATIONS', 'com.google.android.c2dm.permission.RECEIVE', 'com.google.android.gms.permission.AD_ID', 'android.permission.ACCESS_ADSERVICES_ATTRIBUTION', 'android.permission.ACCESS_ADSERVICES_AD_ID')) {
    Assert-C30SBuild -Condition (-not $mergedManifest.Contains($permission, [StringComparison]::Ordinal)) -Message "unexpected release permission remains: $permission"
  }
  Assert-C30SBuild -Condition (Test-Path -LiteralPath $manifestBlamePath -PathType Leaf) -Message 'fresh release manifest merger blame is missing.'
  $manifestBlame = Get-Content -Raw -LiteralPath $manifestBlamePath
  $readGservicesOrigin = [regex]::Escape($readGservicesPermission) + '[\s\S]{0,1000}\[com\.google\.android\.recaptcha:recaptcha:18\.7\.1\]'
  Assert-C30SBuild -Condition ([regex]::Matches($manifestBlame, [regex]::Escape($readGservicesPermission)).Count -eq 1 -and [regex]::IsMatch($manifestBlame, $readGservicesOrigin)) -Message 'READ_GSERVICES merger-blame origin differs from exact reCAPTCHA 18.7.1.'
  $exportedNodes = @($manifestXml.SelectNodes('//*[@android:exported="true"]', $namespace))
  $exportedByName = @{}
  foreach ($node in $exportedNodes) {
    $nodeName = $node.GetAttribute('name', 'http://schemas.android.com/apk/res/android')
    Assert-C30SBuild -Condition (-not [string]::IsNullOrWhiteSpace($nodeName) -and -not $exportedByName.ContainsKey($nodeName)) -Message 'exported component name is blank or duplicated.'
    $exportedByName[$nodeName] = $node
  }
  $expectedExported = @(
    [pscustomobject]@{ Name = 'com.moolsocial.app.MainActivity'; Node = 'activity'; Permission = ''; Action = 'android.intent.action.MAIN'; Scheme = 'https'; Host = 'moolsocial.com' },
    [pscustomobject]@{ Name = 'com.moolsocial.app.YouTubeConnectReturnActivity'; Node = 'activity'; Permission = ''; Action = 'android.intent.action.VIEW'; Scheme = 'moolsocial'; Host = '' },
    [pscustomobject]@{ Name = 'com.google.firebase.auth.internal.GenericIdpActivity'; Node = 'activity'; Permission = ''; Action = 'android.intent.action.VIEW'; Scheme = 'genericidp'; Host = 'firebase.auth' },
    [pscustomobject]@{ Name = 'com.google.firebase.auth.internal.RecaptchaActivity'; Node = 'activity'; Permission = ''; Action = 'android.intent.action.VIEW'; Scheme = 'recaptcha'; Host = 'firebase.auth' },
    [pscustomobject]@{ Name = 'com.google.android.gms.auth.api.signin.RevocationBoundService'; Node = 'service'; Permission = 'com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION'; Action = ''; Scheme = ''; Host = '' },
    [pscustomobject]@{ Name = 'androidx.profileinstaller.ProfileInstallReceiver'; Node = 'receiver'; Permission = 'android.permission.DUMP'; Action = 'androidx.profileinstaller.action.INSTALL_PROFILE'; Scheme = ''; Host = '' }
  )
  Assert-C30SBuild -Condition ($exportedNodes.Count -eq $expectedExported.Count) -Message 'merged release exported-component count changed.'
  foreach ($expected in $expectedExported) {
    Assert-C30SBuild -Condition $exportedByName.ContainsKey($expected.Name) -Message "required exported component changed: $($expected.Name)"
    $node = $exportedByName[$expected.Name]
    $permission = $node.GetAttribute('permission', 'http://schemas.android.com/apk/res/android')
    $actions = @($node.SelectNodes('.//action', $namespace) | ForEach-Object { $_.GetAttribute('name', 'http://schemas.android.com/apk/res/android') })
    $schemes = @($node.SelectNodes('.//data', $namespace) | ForEach-Object { $_.GetAttribute('scheme', 'http://schemas.android.com/apk/res/android') })
    $hosts = @($node.SelectNodes('.//data', $namespace) | ForEach-Object { $_.GetAttribute('host', 'http://schemas.android.com/apk/res/android') })
    Assert-C30SBuild -Condition ($node.LocalName -ceq $expected.Node -and $permission -ceq $expected.Permission) -Message "exported component type or permission changed: $($expected.Name)"
    Assert-C30SBuild -Condition ([string]::IsNullOrEmpty($expected.Action) -or $actions -contains $expected.Action) -Message "exported component action changed: $($expected.Name)"
    Assert-C30SBuild -Condition ([string]::IsNullOrEmpty($expected.Scheme) -or $schemes -contains $expected.Scheme) -Message "exported component scheme changed: $($expected.Name)"
    Assert-C30SBuild -Condition ([string]::IsNullOrEmpty($expected.Host) -or $hosts -contains $expected.Host) -Message "exported component host changed: $($expected.Name)"
  }
  foreach ($originPattern in @(
    'GenericIdpActivity[\s\S]{0,1000}\[com\.google\.firebase:firebase-auth:24\.1\.0\]',
    'RecaptchaActivity[\s\S]{0,1000}\[com\.google\.firebase:firebase-auth:24\.1\.0\]',
    'RevocationBoundService[\s\S]{0,1000}\[com\.google\.android\.gms:play-services-auth:20\.7\.0\]',
    'ProfileInstallReceiver[\s\S]{0,1000}\[androidx\.profileinstaller:profileinstaller:1\.4\.0\]'
  )) {
    Assert-C30SBuild -Condition ([regex]::IsMatch($manifestBlame, $originPattern)) -Message 'exported dependency-component merger-blame origin changed.'
  }
  $mergedManifest = $null; $manifestXml = $null; $manifestBlame = $null
  Copy-Item -LiteralPath $mergedManifestPath -Destination $mergedManifestEvidencePath
  Copy-Item -LiteralPath $manifestBlamePath -Destination $manifestBlameEvidencePath

  foreach ($log in @($configLogPath, $manifestLogPath)) {
    $credentialHits = @(Select-String -LiteralPath $log -Pattern 'AIza[0-9A-Za-z_-]{35}|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----')
    Assert-C30SBuild -Condition ($credentialHits.Count -eq 0) -Message "credential-shaped output detected in $(Split-Path -Leaf $log)."
  }
  Assert-SourceManifestCurrent -ManifestPath $sourceManifest
}
finally {
  if ($androidPushed) { Pop-Location }
  if ($mobilePushed) { Pop-Location }
}

[IO.File]::WriteAllText($prebuildPath, (($state | ConvertTo-Json -Depth 40) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
$state.machineState = 'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
$state.buildAuthorization = 'consumed'
$state.buildResult.state = 'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
$state.buildResult.buildCount = 1
$state.buildResult.wrapperInvocationCount = 1
$state.buildResult.configOnlyCount = 1
Write-State -State $state

$buildSucceeded = $false
try {
  Push-Location $mobileRoot
  $mobilePushed = $true
  $buildArguments = @(
    'build', 'appbundle', '--release', '--no-pub',
    '--build-name=1.0.0-r60.44', '--build-number=2026081244',
    ('--dart-define-from-file={0}' -f $secretDefinePath)
  )
  foreach ($property in $state.runtimeConfiguration.requiredNonSecretDefines.PSObject.Properties) {
    $buildArguments += '--dart-define={0}={1}' -f $property.Name, $property.Value
  }
  $buildExitCode = Invoke-FlutterCaptured -Arguments $buildArguments -LogPath $buildLogPath
  if ($buildExitCode -ne 0) { throw "single release AAB failed with exit $buildExitCode" }
  $buildSucceeded = $true
}
catch {
  $failed = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
  $failed.machineState = 'single_release_AAB_failed_authority_consumed'
  $failed.buildResult.state = 'single_release_AAB_failed_authority_consumed'
  Write-State -State $failed
  throw
}
finally {
  if ($mobilePushed) { Pop-Location; $mobilePushed = $false }
}
Assert-C30SBuild -Condition $buildSucceeded -Message 'single release AAB did not succeed.'
Assert-C30SBuild -Condition (Test-Path -LiteralPath $generatedPath -PathType Leaf) -Message 'Flutter succeeded without an AAB.'
Copy-Item -LiteralPath $generatedPath -Destination $sealedPath

$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
$java = 'C:\Program Files\Android\Android Studio\jbr\bin\java.exe'
Assert-C30SBuild -Condition ((Test-Path -LiteralPath $keytool -PathType Leaf) -and (Test-Path -LiteralPath $java -PathType Leaf)) -Message 'Android Studio Java or keytool missing.'
$certificateOutput = & $keytool -printcert -jarfile $sealedPath 2>&1
Assert-C30SBuild -Condition ($LASTEXITCODE -eq 0) -Message 'AAB signer certificate unreadable.'
$shaMatch = [regex]::Match(($certificateOutput -join [Environment]::NewLine), 'SHA256:\s*([0-9A-Fa-f:]{64,95})')
Assert-C30SBuild -Condition $shaMatch.Success -Message 'AAB signer SHA-256 missing.'
$uploadSigner = $shaMatch.Groups[1].Value.Replace(':', '').ToUpperInvariant()
$expectedSigner = ([string]$state.signingQualification.uploadCertificateSha256).Replace(':', '').ToUpperInvariant()
Assert-C30SBuild -Condition ($uploadSigner -ceq $expectedSigner) -Message 'AAB signer differs from founder upload certificate.'
$certificateOutput = $null

$packageOutput = & $java -jar $bundletoolPath dump manifest "--bundle=$sealedPath" '--xpath=/manifest/@package' 2>&1
Assert-C30SBuild -Condition ($LASTEXITCODE -eq 0 -and ($packageOutput -join '').Trim() -ceq 'com.moolsocial.app') -Message 'AAB package proof failed.'
$versionCodeOutput = & $java -jar $bundletoolPath dump manifest "--bundle=$sealedPath" '--xpath=/manifest/@android:versionCode' 2>&1
Assert-C30SBuild -Condition ($LASTEXITCODE -eq 0 -and ($versionCodeOutput -join '').Trim() -ceq '2026081244') -Message 'AAB versionCode proof failed.'
$versionNameOutput = & $java -jar $bundletoolPath dump manifest "--bundle=$sealedPath" '--xpath=/manifest/@android:versionName' 2>&1
Assert-C30SBuild -Condition ($LASTEXITCODE -eq 0 -and ($versionNameOutput -join '').Trim() -ceq '1.0.0-r60.44') -Message 'AAB versionName proof failed.'
$googleAppOutput = & $java -jar $bundletoolPath dump resources "--bundle=$sealedPath" '--resource=string/google_app_id' --values 2>&1
$googleAppText = $googleAppOutput -join [Environment]::NewLine
Assert-C30SBuild -Condition ($LASTEXITCODE -eq 0 -and $googleAppText.Contains('google_app_id', [StringComparison]::Ordinal) -and $googleAppText.Contains('1:760290687711:android:4202409fd3ab38f6ce076a', [StringComparison]::Ordinal)) -Message 'AAB google_app_id resource proof failed.'
$crashlyticsOutput = & $java -jar $bundletoolPath dump resources "--bundle=$sealedPath" '--resource=string/com.google.firebase.crashlytics.mapping_file_id' --values 2>&1
$crashlyticsText = $crashlyticsOutput -join [Environment]::NewLine
Assert-C30SBuild -Condition ($LASTEXITCODE -eq 0 -and $crashlyticsText.Contains('com.google.firebase.crashlytics.mapping_file_id', [StringComparison]::Ordinal) -and [regex]::IsMatch($crashlyticsText, '(?i)\b[0-9a-f]{32}\b') -and [regex]::IsMatch($crashlyticsText, '(?m)\[STR\]\s+"[^"]+"')) -Message 'AAB Crashlytics mapping-file build-ID resource proof failed.'
$googleAppOutput = $null; $googleAppText = $null; $crashlyticsOutput = $null; $crashlyticsText = $null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($sealedPath)
try {
  $entryNames = @($archive.Entries | ForEach-Object { $_.FullName })
  $splitAndArm64 = $entryNames -contains 'base/lib/arm64-v8a/libapp.so' -and $entryNames -contains 'base/lib/arm64-v8a/libflutter.so' -and $entryNames -contains 'base/resources.pb' -and $entryNames -contains 'base/manifest/AndroidManifest.xml'
  Assert-C30SBuild -Condition $splitAndArm64 -Message 'AAB base resources, manifest or arm64 runtime payload is incomplete.'
} finally { $archive.Dispose() }

$credentialHits = @(Select-String -LiteralPath $buildLogPath -Pattern 'AIza[0-9A-Za-z_-]{35}|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----')
Assert-C30SBuild -Condition ($credentialHits.Count -eq 0) -Message 'credential-shaped output detected in release build log.'
$artifactHash = (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash
$artifactBytes = (Get-Item -LiteralPath $sealedPath).Length
$sourceHash = (Get-FileHash -LiteralPath $sourceManifest -Algorithm SHA256).Hash
Assert-SourceManifestCurrent -ManifestPath $sourceManifest
$provenance = [ordered]@{
  schemaVersion = 1; candidateId = [string]$state.candidate.id
  preflightAttempt = $preflightAttempt
  versionName = '1.0.0-r60.44'; versionCode = '2026081244'; packageName = 'com.moolsocial.app'
  buildMode = 'release'; artifactType = 'AAB'; authorizedTrack = 'internal'
  branch = [string]$state.candidate.branch; head = [string]$state.candidate.head; powerShellMajor = $PSVersionTable.PSVersion.Major
  releaseConfigOnly = $configLogRelative; releaseManifestPreflight = $manifestLogRelative; mergedReleaseManifest = $mergedManifestEvidenceRelative; releaseManifestMergerBlame = $manifestBlameEvidenceRelative
  releaseConfigOnlyProducedApkOrAab = $false; releaseRegistrantPluginCount = 15
  googleServicesGradlePlugin = '4.5.0'; crashlyticsGradlePlugin = '3.0.7'; crashlyticsMappingUploadEnabled = $false
  sourceManifest = [string]$state.sourceQualification.manifestPath; sourceManifestSha256 = $sourceHash; sourceFiles = [int]$state.sourceQualification.fileCount
  artifactPath = $sealedRelative; artifactSha256 = $artifactHash; artifactBytes = $artifactBytes; uploadSignerSha256 = $uploadSigner
  packageVersionManifestProved = $true; googleAppIdResourceProved = $true; crashlyticsBuildIdResourceProved = $true; splitAndArm64PayloadProved = $true
  bundletoolPath = [string]$state.toolingQualification.standaloneBundletoolPath; bundletoolSha256 = [string]$state.toolingQualification.standaloneBundletoolSha256; bundletoolVersion = '1.18.3'
  buildLog = $buildLogRelative; secretDefineFileReadByAgent = $false; googleServicesFileReadByAgent = $false; secretValuesRecorded = $false
  builtAt = [DateTimeOffset]::Now.ToString('o')
}
[IO.File]::WriteAllText($provenancePath, (($provenance | ConvertTo-Json -Depth 16) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$state.machineState = 'single_release_AAB_succeeded_authority_consumed'
$state.buildResult.state = 'single_release_AAB_succeeded_authority_consumed'
$state.buildResult.artifactPath = $sealedRelative
$state.buildResult.artifactSha256 = $artifactHash
$state.buildResult.artifactBytes = $artifactBytes
$state.buildResult.uploadSignerSha256 = $uploadSigner
$state.buildResult.crashlyticsBuildIdResourceProved = $true
$state.buildResult.googleAppIdResourceProved = $true
$state.buildResult.packageVersionManifestProved = $true
$state.buildResult.splitAndArm64PayloadProved = $true
$state.buildResult.mergedReleaseManifestProved = $true
$state.buildResult.provenance = $provenanceRelative
Write-State -State $state
& $gate -Phase postbuild -RepositoryRoot $root
Write-Output "C30S single release AAB succeeded: versionCode=2026081244; sha256=$artifactHash; bytes=$artifactBytes; CrashlyticsBuildId=proved; googleAppId=proved; authority=consumed."
