[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'C30S post-build recovery requires PowerShell 7 or newer.' }
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-Recovery {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30S existing-AAB post-build recovery rejected: $Message" }
}
function Resolve-RepoFile {
  param([Parameter(Mandatory)][string]$RelativePath, [Parameter(Mandatory)][string]$Label)
  Assert-Recovery -Condition (-not [IO.Path]::IsPathRooted($RelativePath)) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-Recovery -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  Assert-Recovery -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) -Message "$Label is missing."
  return $resolved
}
function Write-State {
  param([Parameter(Mandatory)][object]$State, [Parameter(Mandatory)][string]$Path)
  $temporary = $Path + '.postbuild-recovery-write'
  Assert-Recovery -Condition (-not (Test-Path -LiteralPath $temporary)) -Message 'stale recovery state file exists.'
  try {
    [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 40) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $Path -Force
  } finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
  }
}

$candidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S'
$artifactRelative = 'artifacts/quality/uaw-personal-mvp-social-play-internal-firebase-startup-recovery-c30s-r60-44-20260812-01'
$statePath = Resolve-RepoFile -RelativePath 'config/play-internal-aab-regression-gate-state-c30s.json' -Label 'C30S state'
$prebuildPath = Resolve-RepoFile -RelativePath "$artifactRelative/03a-prebuild-machine-state-attempt-3.json" -Label 'attempt-3 prebuild state'
$configLogPath = Resolve-RepoFile -RelativePath "$artifactRelative/03-release-config-only-attempt-3.log" -Label 'attempt-3 config log'
$manifestLogPath = Resolve-RepoFile -RelativePath "$artifactRelative/04-release-manifest-preflight-attempt-3.log" -Label 'attempt-3 manifest log'
$buildLogPath = Resolve-RepoFile -RelativePath "$artifactRelative/05-release-aab-build-attempt-3.log" -Label 'attempt-3 build log'
$mergedManifestPath = Resolve-RepoFile -RelativePath "$artifactRelative/04a-merged-release-manifest-attempt-3.xml" -Label 'attempt-3 merged manifest'
$manifestBlamePath = Resolve-RepoFile -RelativePath "$artifactRelative/04b-release-manifest-merger-blame-attempt-3.txt" -Label 'attempt-3 manifest blame'
$sealedRelative = "$artifactRelative/MoolSocial-1.0.0-r60.44-2026081244-release.aab"
$sealedPath = Resolve-RepoFile -RelativePath $sealedRelative -Label 'sealed r60.44 AAB'
$bundletoolPath = Resolve-RepoFile -RelativePath 'tmp/bundletool-all-1.18.3.jar' -Label 'standalone bundletool'
$provenanceRelative = "$artifactRelative/06-release-aab-provenance-attempt-3-recovered.json"
$provenancePath = [IO.Path]::GetFullPath((Join-Path $root $provenanceRelative))
Assert-Recovery -Condition (-not (Test-Path -LiteralPath $provenancePath)) -Message 'recovered provenance already exists.'

$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
Assert-Recovery -Condition (
  [string]$state.candidate.id -ceq $candidateId -and
  [string]$state.candidate.versionCode -ceq '2026081244' -and
  [string]$state.machineState -ceq 'single_release_AAB_sealed_postbuild_verification_recovery_pending' -and
  [string]$state.buildAuthorization -ceq 'consumed' -and
  [int]$state.buildResult.buildCount -eq 1 -and
  [int]$state.buildResult.wrapperInvocationCount -eq 1 -and
  [int]$state.buildResult.configOnlyCount -eq 1 -and
  [int]$state.playReleaseResult.uploadCount -eq 0 -and
  [int]$state.installResult.candidateInstallCount -eq 0
) -Message 'single sealed-artifact recovery state changed.'
Assert-Recovery -Condition (-not (Test-Path -LiteralPath (Join-Path $root 'apps/mobile/android/app/src/release/google-services.json'))) -Message 'transient Google Services file remains.'
Assert-Recovery -Condition (-not (Test-Path -LiteralPath 'C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRIVATE-SIGNING\c30s-firebase-defines.transient.json')) -Message 'transient Firebase define file remains.'

$prebuild = Get-Content -Raw -LiteralPath $prebuildPath | ConvertFrom-Json
Assert-Recovery -Condition (
  [string]$prebuild.machineState -ceq 'source_qualified_founder_secret_prompt_required' -and
  [string]$prebuild.buildAuthorization -ceq 'available_once' -and
  [int]$prebuild.buildResult.buildCount -eq 0 -and
  [int]$prebuild.sourceQualification.identicalQualifyingCycles -eq 2 -and
  [string]$prebuild.sourceQualification.manifestPath -ceq "$artifactRelative/source-aggregate-manifest-accepted-r7.txt" -and
  [string]$prebuild.sourceQualification.manifestSha256 -ceq '0C0AD30E14F8B270C28B902664ACFB24DC7FFB66327152F0E356AEB41E6A2446'
) -Message 'attempt-3 prebuild authority or source seal changed.'
$acceptedManifestPath = Resolve-RepoFile -RelativePath ([string]$prebuild.sourceQualification.manifestPath) -Label 'artifact source manifest'
Assert-Recovery -Condition ((Get-FileHash -LiteralPath $acceptedManifestPath -Algorithm SHA256).Hash -ceq [string]$prebuild.sourceQualification.manifestSha256) -Message 'artifact source-manifest file changed.'

foreach ($log in @($configLogPath, $manifestLogPath, $buildLogPath)) {
  $credentialHits = @(Select-String -LiteralPath $log -Pattern 'AIza[0-9A-Za-z_-]{35}|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----')
  Assert-Recovery -Condition ($credentialHits.Count -eq 0) -Message "credential-shaped output detected in $(Split-Path -Leaf $log)."
}
Assert-Recovery -Condition (@(Select-String -LiteralPath $buildLogPath -Pattern 'Built build[\\/]app[\\/]outputs[\\/]bundle[\\/]release[\\/]app-release.aab').Count -eq 1) -Message 'attempt-3 build completion line is missing or duplicated.'
Assert-Recovery -Condition (@(Select-String -LiteralPath $buildLogPath -Pattern 'BUILD FAILED|FAILURE:|Exception:').Count -eq 0) -Message 'attempt-3 build log contains a build failure.'

$expectedArtifactSha256 = '2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55'
$artifactHash = (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash
$artifactBytes = (Get-Item -LiteralPath $sealedPath).Length
Assert-Recovery -Condition ($artifactHash -ceq $expectedArtifactSha256 -and $artifactBytes -eq 93201374) -Message 'sealed r60.44 identity changed.'
Assert-Recovery -Condition ((Get-FileHash -LiteralPath $bundletoolPath -Algorithm SHA256).Hash -ceq 'A099CFA1543F55593BC2ED16A70A7C67FE54B1747BB7301F37FDFD6D91028E29') -Message 'bundletool identity changed.'

$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
$java = 'C:\Program Files\Android\Android Studio\jbr\bin\java.exe'
$keytoolPresent = Test-Path -LiteralPath $keytool -PathType Leaf
$javaPresent = Test-Path -LiteralPath $java -PathType Leaf
Assert-Recovery -Condition ($keytoolPresent -and $javaPresent) -Message 'Android Studio Java or keytool is missing.'
$certificateOutput = & $keytool -printcert -jarfile $sealedPath 2>&1
Assert-Recovery -Condition ($LASTEXITCODE -eq 0) -Message 'AAB signer certificate is unreadable.'
$shaMatch = [regex]::Match(($certificateOutput -join [Environment]::NewLine), 'SHA256:\s*([0-9A-Fa-f:]{64,95})')
Assert-Recovery -Condition $shaMatch.Success -Message 'AAB signer SHA-256 is missing.'
$uploadSigner = $shaMatch.Groups[1].Value.Replace(':', '').ToUpperInvariant()
$expectedSigner = ([string]$state.signingQualification.uploadCertificateSha256).Replace(':', '').ToUpperInvariant()
Assert-Recovery -Condition ($uploadSigner -ceq $expectedSigner) -Message 'AAB signer differs from the founder upload certificate.'
$certificateOutput = $null

$packageOutput = & $java -jar $bundletoolPath dump manifest "--bundle=$sealedPath" '--xpath=/manifest/@package' 2>&1
Assert-Recovery -Condition ($LASTEXITCODE -eq 0 -and ($packageOutput -join '').Trim() -ceq 'com.moolsocial.app') -Message 'AAB package proof failed.'
$versionCodeOutput = & $java -jar $bundletoolPath dump manifest "--bundle=$sealedPath" '--xpath=/manifest/@android:versionCode' 2>&1
Assert-Recovery -Condition ($LASTEXITCODE -eq 0 -and ($versionCodeOutput -join '').Trim() -ceq '2026081244') -Message 'AAB versionCode proof failed.'
$versionNameOutput = & $java -jar $bundletoolPath dump manifest "--bundle=$sealedPath" '--xpath=/manifest/@android:versionName' 2>&1
Assert-Recovery -Condition ($LASTEXITCODE -eq 0 -and ($versionNameOutput -join '').Trim() -ceq '1.0.0-r60.44') -Message 'AAB versionName proof failed.'
$googleAppOutput = & $java -jar $bundletoolPath dump resources "--bundle=$sealedPath" '--resource=string/google_app_id' --values 2>&1
$googleAppText = $googleAppOutput -join [Environment]::NewLine
Assert-Recovery -Condition ($LASTEXITCODE -eq 0 -and $googleAppText.Contains('google_app_id', [StringComparison]::Ordinal) -and $googleAppText.Contains('1:760290687711:android:4202409fd3ab38f6ce076a', [StringComparison]::Ordinal)) -Message 'AAB google_app_id resource proof failed.'
$crashlyticsOutput = & $java -jar $bundletoolPath dump resources "--bundle=$sealedPath" '--resource=string/com.google.firebase.crashlytics.mapping_file_id' --values 2>&1
$crashlyticsText = $crashlyticsOutput -join [Environment]::NewLine
Assert-Recovery -Condition ($LASTEXITCODE -eq 0 -and $crashlyticsText.Contains('com.google.firebase.crashlytics.mapping_file_id', [StringComparison]::Ordinal) -and [regex]::IsMatch($crashlyticsText, '(?i)\b[0-9a-f]{32}\b') -and [regex]::IsMatch($crashlyticsText, '(?m)\[STR\]\s+"[^"]+"')) -Message 'AAB Crashlytics mapping-file build-ID resource proof failed.'
$googleAppOutput = $null; $googleAppText = $null; $crashlyticsOutput = $null; $crashlyticsText = $null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($sealedPath)
try {
  $entryNames = @($archive.Entries | ForEach-Object { $_.FullName })
  $payloadComplete = $entryNames -contains 'base/lib/arm64-v8a/libapp.so' -and $entryNames -contains 'base/lib/arm64-v8a/libflutter.so' -and $entryNames -contains 'base/resources.pb' -and $entryNames -contains 'base/manifest/AndroidManifest.xml'
  Assert-Recovery -Condition $payloadComplete -Message 'AAB base resources, manifest or arm64 payload is incomplete.'
} finally { $archive.Dispose() }

[xml]$manifestXml = Get-Content -Raw -LiteralPath $mergedManifestPath
$namespace = [Xml.XmlNamespaceManager]::new($manifestXml.NameTable)
$namespace.AddNamespace('android', 'http://schemas.android.com/apk/res/android')
$exportedNames = @($manifestXml.SelectNodes('//*[@android:exported="true"]', $namespace) | ForEach-Object { $_.GetAttribute('name', 'http://schemas.android.com/apk/res/android') })
$expectedExportedNames = @('com.moolsocial.app.MainActivity', 'com.moolsocial.app.YouTubeConnectReturnActivity', 'com.google.firebase.auth.internal.GenericIdpActivity', 'com.google.firebase.auth.internal.RecaptchaActivity', 'com.google.android.gms.auth.api.signin.RevocationBoundService', 'androidx.profileinstaller.ProfileInstallReceiver')
Assert-Recovery -Condition ($exportedNames.Count -eq 6 -and @($expectedExportedNames | Where-Object { $exportedNames -notcontains $_ }).Count -eq 0) -Message 'sealed merged-manifest exported surface changed.'
$manifestBlame = Get-Content -Raw -LiteralPath $manifestBlamePath
foreach ($pattern in @('READ_GSERVICES[\s\S]{0,1000}\[com\.google\.android\.recaptcha:recaptcha:18\.7\.1\]', 'GenericIdpActivity[\s\S]{0,1000}\[com\.google\.firebase:firebase-auth:24\.1\.0\]', 'RecaptchaActivity[\s\S]{0,1000}\[com\.google\.firebase:firebase-auth:24\.1\.0\]', 'RevocationBoundService[\s\S]{0,1000}\[com\.google\.android\.gms:play-services-auth:20\.7\.0\]', 'ProfileInstallReceiver[\s\S]{0,1000}\[androidx\.profileinstaller:profileinstaller:1\.4\.0\]')) {
  Assert-Recovery -Condition ([regex]::IsMatch($manifestBlame, $pattern)) -Message 'sealed manifest dependency origin changed.'
}

$provenance = [ordered]@{
  schemaVersion = 1; candidateId = $candidateId; postbuildRecovery = $true; secondBuildPerformed = $false
  preflightAttempt = 3; versionName = '1.0.0-r60.44'; versionCode = '2026081244'; packageName = 'com.moolsocial.app'
  buildMode = 'release'; artifactType = 'AAB'; authorizedTrack = 'internal'
  branch = [string]$state.candidate.branch; head = [string]$state.candidate.head
  artifactSourceManifest = [string]$prebuild.sourceQualification.manifestPath; artifactSourceManifestSha256 = [string]$prebuild.sourceQualification.manifestSha256; artifactSourceFiles = [int]$prebuild.sourceQualification.fileCount
  artifactPath = $sealedRelative; artifactSha256 = $artifactHash; artifactBytes = $artifactBytes; uploadSignerSha256 = $uploadSigner
  releaseConfigOnly = "$artifactRelative/03-release-config-only-attempt-3.log"; releaseManifestPreflight = "$artifactRelative/04-release-manifest-preflight-attempt-3.log"; buildLog = "$artifactRelative/05-release-aab-build-attempt-3.log"
  mergedReleaseManifest = "$artifactRelative/04a-merged-release-manifest-attempt-3.xml"; releaseManifestMergerBlame = "$artifactRelative/04b-release-manifest-merger-blame-attempt-3.txt"
  packageVersionManifestProved = $true; googleAppIdResourceProved = $true; crashlyticsBuildIdResourceProved = $true; splitAndArm64PayloadProved = $true; mergedReleaseManifestProved = $true
  postbuildRecoveryToolingOutsideArtifactSource = $true; secretValuesRecorded = $false; secretFilesPresent = $false
  recoveredAt = [DateTimeOffset]::Now.ToString('o')
}
[IO.File]::WriteAllText($provenancePath, (($provenance | ConvertTo-Json -Depth 16) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
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
Write-State -State $state -Path $statePath
& (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30s.ps1') -Phase postbuild -RepositoryRoot $root
Write-Output "C30S existing r60.44 AAB post-build recovery passed: sha256=$artifactHash; bytes=$artifactBytes; secondBuild=false; upload remains pending."
