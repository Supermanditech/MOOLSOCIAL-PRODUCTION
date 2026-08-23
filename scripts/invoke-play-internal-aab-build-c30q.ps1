[CmdletBinding()]
param([string]$StatePath, [string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'C30Q requires PowerShell 7 before authority mutation.' }
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) { $StatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30q.json' }
$stateFile = [IO.Path]::GetFullPath($StatePath)

function Assert-C30QBuild {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30Q single AAB build rejected: $Message" }
}
function Resolve-RepoPath {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C30QBuild -Condition (-not [IO.Path]::IsPathRooted($Path)) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30QBuild -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  return $resolved
}
function Write-State {
  param([Parameter(Mandatory)][object]$State)
  $temporary = $stateFile + '.c30q-write'
  Assert-C30QBuild -Condition (-not (Test-Path -LiteralPath $temporary)) -Message 'stale state temporary exists.'
  [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 32) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $stateFile -Force
}
function Get-ApkSnapshot {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'absent' }
  $file = Get-Item -LiteralPath $Path
  return '{0}|{1}|{2}' -f $file.Length, $file.LastWriteTimeUtc.Ticks, (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function Invoke-NativeCaptured {
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

Assert-C30QBuild -Condition ($stateFile.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $stateFile -PathType Leaf)) -Message 'state path invalid.'
$gate = Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30q.ps1'
& $gate -Phase build -RepositoryRoot $root
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json

foreach ($name in @([string[]]$state.signingQualification.uploadKeyEnvironmentNames) + @([string]$state.runtimeConfiguration.secretDefineFileEnvironmentName)) {
  Assert-C30QBuild -Condition (Test-Path -LiteralPath ('Env:{0}' -f $name)) -Message "founder environment entry missing: $name"
}
$uploadStorePath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_UPLOAD_STORE_FILE')
$secretDefinePath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_FIREBASE_DART_DEFINE_FILE')
Assert-C30QBuild -Condition (Test-Path -LiteralPath $uploadStorePath -PathType Leaf) -Message 'upload keystore missing.'
Assert-C30QBuild -Condition (Test-Path -LiteralPath $secretDefinePath -PathType Leaf) -Message 'transient define file missing.'

$artifactRelative = 'artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01'
$artifactRoot = Resolve-RepoPath -Path $artifactRelative -Label 'evidence directory'
Assert-C30QBuild -Condition (Test-Path -LiteralPath $artifactRoot -PathType Container) -Message 'evidence directory missing.'
$generatedPath = Resolve-RepoPath -Path 'apps/mobile/build/app/outputs/bundle/release/app-release.aab' -Label 'generated AAB'
$releaseApkPath = Resolve-RepoPath -Path 'apps/mobile/build/app/outputs/flutter-apk/app-release.apk' -Label 'release APK sentinel'
$registrantPath = Resolve-RepoPath -Path 'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java' -Label 'generated registrant'
$sealedRelative = "$artifactRelative/MoolSocial-1.0.0-r60.43-2026081243-release.aab"
$sealedPath = Resolve-RepoPath -Path $sealedRelative -Label 'sealed AAB'
$configLogRelative = "$artifactRelative/03-release-config-only.log"
$configLogPath = Resolve-RepoPath -Path $configLogRelative -Label 'config log'
$buildLogRelative = "$artifactRelative/04-release-aab-build.log"
$buildLogPath = Resolve-RepoPath -Path $buildLogRelative -Label 'build log'
$prebuildRelative = "$artifactRelative/03a-prebuild-machine-state.json"
$prebuildPath = Resolve-RepoPath -Path $prebuildRelative -Label 'prebuild state'
$provenanceRelative = "$artifactRelative/05-release-aab-provenance.json"
$provenancePath = Resolve-RepoPath -Path $provenanceRelative -Label 'provenance'
foreach ($path in @($generatedPath, $sealedPath, $configLogPath, $buildLogPath, $prebuildPath, $provenancePath)) {
  Assert-C30QBuild -Condition (-not (Test-Path -LiteralPath $path)) -Message "single-attempt output already exists: $path"
}

[IO.File]::WriteAllText($prebuildPath, (($state | ConvertTo-Json -Depth 32) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
$state.machineState = 'release_config_and_single_AAB_build_in_progress_authority_consumed'
$state.buildAuthorization = 'consumed'
$state.buildResult.state = 'release_config_and_single_AAB_build_in_progress'
$state.buildResult.buildCount = 1
$state.buildResult.wrapperInvocationCount = 1
$state.buildResult.configOnlyCount = 1
Write-State -State $state

$mobileRoot = Join-Path $root 'apps/mobile'
$pushed = $false
try {
  Push-Location $mobileRoot
  $pushed = $true
  $apkBefore = Get-ApkSnapshot -Path $releaseApkPath
  $pubspecHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash
  $lockHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash
  $releaseConfigArguments = @('build', 'apk', '--release', '--config-only')
  $releaseConfigExitCode = Invoke-NativeCaptured -Arguments $releaseConfigArguments -LogPath $configLogPath
  if ($releaseConfigExitCode -ne 0) { throw "release config-only failed with exit $releaseConfigExitCode" }
  Assert-C30QBuild -Condition (
    $pubspecHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash -and
    $lockHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash
  ) -Message 'release config-only changed pubspec.yaml or pubspec.lock.'
  $apkAfter = Get-ApkSnapshot -Path $releaseApkPath
  Assert-C30QBuild -Condition ($apkBefore -ceq $apkAfter) -Message 'release config-only created or changed an APK.'
  Assert-C30QBuild -Condition (Test-Path -LiteralPath $registrantPath -PathType Leaf) -Message 'release registrant is missing after config-only.'
  $registrant = Get-Content -Raw -LiteralPath $registrantPath
  Assert-C30QBuild -Condition (-not $registrant.Contains('IntegrationTestPlugin', [StringComparison]::Ordinal)) -Message 'release registrant still references IntegrationTestPlugin.'
  $registrant = $null

  $buildArguments = @(
    'build', 'appbundle', '--release', '--no-pub',
    '--build-name=1.0.0-r60.43', '--build-number=2026081243',
    ('--dart-define-from-file={0}' -f $secretDefinePath)
  )
  foreach ($property in $state.runtimeConfiguration.requiredNonSecretDefines.PSObject.Properties) {
    $buildArguments += '--dart-define={0}={1}' -f $property.Name, $property.Value
  }
  $buildExitCode = Invoke-NativeCaptured -Arguments $buildArguments -LogPath $buildLogPath
  if ($buildExitCode -ne 0) { throw "single release AAB failed with exit $buildExitCode" }
}
catch {
  $failed = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
  $failed.machineState = 'single_release_AAB_failed_authority_consumed'
  $failed.buildResult.state = 'single_release_AAB_failed_authority_consumed'
  Write-State -State $failed
  throw
}
finally {
  if ($pushed) { Pop-Location }
}

Assert-C30QBuild -Condition (Test-Path -LiteralPath $generatedPath -PathType Leaf) -Message 'Flutter succeeded without AAB.'
Copy-Item -LiteralPath $generatedPath -Destination $sealedPath
$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
Assert-C30QBuild -Condition (Test-Path -LiteralPath $keytool -PathType Leaf) -Message 'keytool missing.'
$certificateOutput = & $keytool -printcert -jarfile $sealedPath 2>&1
Assert-C30QBuild -Condition ($LASTEXITCODE -eq 0) -Message 'AAB signer certificate unreadable.'
$shaMatch = [regex]::Match(($certificateOutput -join [Environment]::NewLine), 'SHA256:\s*([0-9A-Fa-f:]{64,95})')
Assert-C30QBuild -Condition $shaMatch.Success -Message 'AAB signer SHA-256 missing.'
$uploadSigner = $shaMatch.Groups[1].Value.Replace(':', '').ToUpperInvariant()
$expectedSigner = ([string]$state.signingQualification.uploadCertificateSha256).Replace(':', '').ToUpperInvariant()
Assert-C30QBuild -Condition ($uploadSigner -ceq $expectedSigner) -Message 'AAB signer differs from founder upload certificate.'
$certificateOutput = $null

$artifactHash = (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash
$artifactBytes = (Get-Item -LiteralPath $sealedPath).Length
$sourceManifest = Resolve-RepoPath -Path ([string]$state.sourceQualification.manifestPath) -Label 'source manifest'
$sourceHash = (Get-FileHash -LiteralPath $sourceManifest -Algorithm SHA256).Hash
Assert-C30QBuild -Condition ($sourceHash -ceq ([string]$state.sourceQualification.manifestSha256).ToUpperInvariant()) -Message 'source changed during build.'
$provenance = [ordered]@{
  schemaVersion = 1; candidateId = [string]$state.candidate.id
  versionName = [string]$state.candidate.versionName; versionCode = [string]$state.candidate.versionCode
  packageName = [string]$state.candidate.packageName; buildMode = 'release'; artifactType = 'AAB'; authorizedTrack = 'internal'
  branch = [string]$state.candidate.branch; head = [string]$state.candidate.head; powerShellMajor = $PSVersionTable.PSVersion.Major
  releaseConfigOnly = $configLogRelative; releaseConfigOnlyProducedApk = $false; releaseRegistrantExcludedIntegrationTestPlugin = $true
  sourceManifest = [string]$state.sourceQualification.manifestPath; sourceManifestSha256 = $sourceHash; sourceFiles = [int]$state.sourceQualification.fileCount
  artifactPath = $sealedRelative; artifactSha256 = $artifactHash; artifactBytes = $artifactBytes; uploadSignerSha256 = $uploadSigner
  buildLog = $buildLogRelative; secretDefineFileReadByAgent = $false; secretValuesRecorded = $false; builtAt = [DateTimeOffset]::Now.ToString('o')
}
[IO.File]::WriteAllText($provenancePath, (($provenance | ConvertTo-Json -Depth 12) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$state.machineState = 'single_release_AAB_succeeded_authority_consumed'
$state.buildResult.state = 'single_release_AAB_succeeded_authority_consumed'
$state.buildResult.artifactPath = $sealedRelative
$state.buildResult.artifactSha256 = $artifactHash
$state.buildResult.artifactBytes = $artifactBytes
$state.buildResult.uploadSignerSha256 = $uploadSigner
$state.buildResult.provenance = $provenanceRelative
Write-State -State $state
& $gate -Phase postbuild -RepositoryRoot $root
Write-Output "C30Q single release AAB succeeded: versionCode=$($state.candidate.versionCode); sha256=$artifactHash; bytes=$artifactBytes; authority=consumed."
