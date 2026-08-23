[CmdletBinding()]
param([string]$StatePath, [string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'C30P single AAB build rejected: PowerShell 7 or newer is required before build authority mutation.'
}
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) {
  $StatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30p.json'
}
$statePathFull = [IO.Path]::GetFullPath($StatePath)

function Assert-C30PBuild {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) {
    throw ('C30P single AAB build rejected: {0}' -f $Message)
  }
}

function Resolve-C30PPath {
  param([Parameter(Mandatory)][string]$RelativePath, [Parameter(Mandatory)][string]$Label)
  Assert-C30PBuild -Condition (-not [IO.Path]::IsPathRooted($RelativePath)) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C30PBuild -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  return $resolved
}

function Write-C30PState {
  param([Parameter(Mandatory)][object]$State)
  $temporary = $statePathFull + '.c30p-write'
  Assert-C30PBuild -Condition (-not (Test-Path -LiteralPath $temporary)) -Message 'stale machine-state temporary file exists.'
  [IO.File]::WriteAllText(
    $temporary,
    (($State | ConvertTo-Json -Depth 32) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
  )
  Move-Item -LiteralPath $temporary -Destination $statePathFull -Force
}

Assert-C30PBuild -Condition ($statePathFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message 'machine state escaped the repository.'
Assert-C30PBuild -Condition (Test-Path -LiteralPath $statePathFull -PathType Leaf) -Message 'machine state is missing.'

$gatePath = Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30p.ps1'
& $gatePath -Phase build -RepositoryRoot $root

$state = Get-Content -Raw -LiteralPath $statePathFull | ConvertFrom-Json
$candidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30P'
Assert-C30PBuild -Condition ([string]$state.candidate.id -ceq $candidateId) -Message 'candidate changed after build gate.'

$requiredEnvironmentNames = @([string[]]$state.signingQualification.uploadKeyEnvironmentNames) + @([string]$state.runtimeConfiguration.secretDefineFileEnvironmentName)
foreach ($name in $requiredEnvironmentNames) {
  Assert-C30PBuild -Condition (Test-Path -LiteralPath ('Env:{0}' -f $name)) -Message "required founder environment entry is absent: $name"
}
$uploadStorePath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_UPLOAD_STORE_FILE')
$secretDefinePath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_FIREBASE_DART_DEFINE_FILE')
Assert-C30PBuild -Condition (Test-Path -LiteralPath $uploadStorePath -PathType Leaf) -Message 'upload keystore path is not a file.'
Assert-C30PBuild -Condition (Test-Path -LiteralPath $secretDefinePath -PathType Leaf) -Message 'founder-qualified define path is not a file.'

$artifactRootRelative = 'artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30p-r60-42-20260812-01'
$artifactRoot = Resolve-C30PPath -RelativePath $artifactRootRelative -Label 'C30P evidence directory'
Assert-C30PBuild -Condition (Test-Path -LiteralPath $artifactRoot -PathType Container) -Message 'C30P evidence directory is missing.'

$generatedRelative = 'apps/mobile/build/app/outputs/bundle/release/app-release.aab'
$sealedRelative = $artifactRootRelative + '/MoolSocial-1.0.0-r60.42-2026081242-release.aab'
$buildLogRelative = $artifactRootRelative + '/03-release-aab-build.log'
$provenanceRelative = $artifactRootRelative + '/04-release-aab-provenance.json'
$prebuildStateRelative = $artifactRootRelative + '/03a-prebuild-machine-state.json'
$generatedPath = Resolve-C30PPath -RelativePath $generatedRelative -Label 'generated AAB'
$sealedPath = Resolve-C30PPath -RelativePath $sealedRelative -Label 'sealed AAB'
$buildLogPath = Resolve-C30PPath -RelativePath $buildLogRelative -Label 'build log'
$provenancePath = Resolve-C30PPath -RelativePath $provenanceRelative -Label 'provenance'
$prebuildStatePath = Resolve-C30PPath -RelativePath $prebuildStateRelative -Label 'prebuild state'
foreach ($mustBeAbsent in @($generatedPath, $sealedPath, $buildLogPath, $provenancePath, $prebuildStatePath)) {
  Assert-C30PBuild -Condition (-not (Test-Path -LiteralPath $mustBeAbsent)) -Message "single-build output already exists: $mustBeAbsent"
}

[IO.File]::WriteAllText(
  $prebuildStatePath,
  (($state | ConvertTo-Json -Depth 32) + [Environment]::NewLine),
  [Text.UTF8Encoding]::new($false)
)
$state.machineState = 'single_release_AAB_build_in_progress_authority_consumed'
$state.buildAuthorization = 'consumed'
$state.buildResult.state = 'single_release_AAB_build_in_progress'
$state.buildResult.buildCount = 1
$state.buildResult.wrapperInvocationCount = 1
Write-C30PState -State $state

$buildArguments = @(
  'build',
  'appbundle',
  '--release',
  '--no-pub',
  '--build-name=1.0.0-r60.42',
  '--build-number=2026081242',
  ('--dart-define-from-file={0}' -f $secretDefinePath)
)
foreach ($property in $state.runtimeConfiguration.requiredNonSecretDefines.PSObject.Properties) {
  $buildArguments += '--dart-define={0}={1}' -f $property.Name, $property.Value
}

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
Assert-C30PBuild -Condition ($null -ne $flutterCommand) -Message 'Flutter is unavailable.'
$mobileRoot = Join-Path $root 'apps/mobile'
$buildExitCode = -1
$pushed = $false
$nativeVariable = Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue
$nativePreferenceExisted = $null -ne $nativeVariable
$savedNativePreference = if ($nativePreferenceExisted) { [bool]$nativeVariable.Value } else { $false }
$savedErrorActionPreference = $ErrorActionPreference
try {
  Push-Location $mobileRoot
  $pushed = $true
  $PSNativeCommandUseErrorActionPreference = $false
  $ErrorActionPreference = 'Continue'
  & flutter @buildArguments *> $buildLogPath
  $buildExitCode = $LASTEXITCODE
}
finally {
  $ErrorActionPreference = $savedErrorActionPreference
  if ($nativePreferenceExisted) {
    $PSNativeCommandUseErrorActionPreference = $savedNativePreference
  } else {
    Remove-Variable -Name PSNativeCommandUseErrorActionPreference -Scope Script -ErrorAction SilentlyContinue
  }
  if ($pushed) {
    Pop-Location
  }
}

if ($buildExitCode -ne 0) {
  $state = Get-Content -Raw -LiteralPath $statePathFull | ConvertFrom-Json
  $state.machineState = 'single_release_AAB_failed_authority_consumed'
  $state.buildResult.state = 'single_release_AAB_failed_authority_consumed'
  Write-C30PState -State $state
  throw "C30P single release AAB build failed with exit code $buildExitCode."
}

Assert-C30PBuild -Condition (Test-Path -LiteralPath $generatedPath -PathType Leaf) -Message 'Flutter reported success without the exact release AAB.'
Copy-Item -LiteralPath $generatedPath -Destination $sealedPath

$keytoolPath = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
Assert-C30PBuild -Condition (Test-Path -LiteralPath $keytoolPath -PathType Leaf) -Message 'qualified keytool is unavailable.'
$certificateOutput = & $keytoolPath -printcert -jarfile $sealedPath 2>&1
Assert-C30PBuild -Condition ($LASTEXITCODE -eq 0) -Message 'sealed AAB signer certificate could not be read.'
$certificateText = $certificateOutput -join [Environment]::NewLine
$shaMatch = [regex]::Match($certificateText, 'SHA256:\s*([0-9A-Fa-f:]{64,95})')
Assert-C30PBuild -Condition $shaMatch.Success -Message 'sealed AAB signer SHA-256 was absent.'
$uploadSignerSha256 = $shaMatch.Groups[1].Value.Replace(':', '').ToUpperInvariant()
$expectedSigner = ([string]$state.signingQualification.uploadCertificateSha256).Replace(':', '').ToUpperInvariant()
Assert-C30PBuild -Condition ($uploadSignerSha256 -ceq $expectedSigner) -Message 'sealed AAB signer differs from founder upload certificate.'
$certificateOutput = $null
$certificateText = $null

$artifactHash = (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash
$artifactBytes = (Get-Item -LiteralPath $sealedPath).Length
$sourceManifest = Resolve-C30PPath -RelativePath ([string]$state.sourceQualification.manifestPath) -Label 'sealed source manifest'
$sourceHash = (Get-FileHash -LiteralPath $sourceManifest -Algorithm SHA256).Hash
Assert-C30PBuild -Condition ($sourceHash -ceq ([string]$state.sourceQualification.manifestSha256).ToUpperInvariant()) -Message 'source manifest changed during build.'

$provenance = [ordered]@{
  schemaVersion = 1
  candidateId = $candidateId
  versionName = [string]$state.candidate.versionName
  versionCode = [string]$state.candidate.versionCode
  packageName = [string]$state.candidate.packageName
  buildMode = 'release'
  artifactType = 'AAB'
  authorizedTrack = 'internal'
  branch = [string]$state.candidate.branch
  head = [string]$state.candidate.head
  powerShellMajor = $PSVersionTable.PSVersion.Major
  sourceManifest = [string]$state.sourceQualification.manifestPath
  sourceManifestSha256 = $sourceHash
  sourceFiles = [int]$state.sourceQualification.fileCount
  artifactPath = $sealedRelative
  artifactSha256 = $artifactHash
  artifactBytes = $artifactBytes
  uploadSignerSha256 = $uploadSignerSha256
  buildLog = $buildLogRelative
  secretDefineFileReadByAgent = $false
  secretValuesRecorded = $false
  requiredSecretDefineNames = @([string[]]$state.runtimeConfiguration.requiredSecretDefineNames)
  requiredNonSecretDefineNames = @($state.runtimeConfiguration.requiredNonSecretDefines.PSObject.Properties.Name)
  builtAt = [DateTimeOffset]::Now.ToString('o')
}
[IO.File]::WriteAllText(
  $provenancePath,
  (($provenance | ConvertTo-Json -Depth 12) + [Environment]::NewLine),
  [Text.UTF8Encoding]::new($false)
)

$state = Get-Content -Raw -LiteralPath $statePathFull | ConvertFrom-Json
$state.machineState = 'single_release_AAB_succeeded_authority_consumed'
$state.buildResult.state = 'single_release_AAB_succeeded_authority_consumed'
$state.buildResult.artifactPath = $sealedRelative
$state.buildResult.artifactSha256 = $artifactHash
$state.buildResult.artifactBytes = $artifactBytes
$state.buildResult.uploadSignerSha256 = $uploadSignerSha256
$state.buildResult.provenance = $provenanceRelative
Write-C30PState -State $state

& $gatePath -Phase postbuild -RepositoryRoot $root
Write-Output ('C30P single release AAB succeeded: versionCode={0}; sha256={1}; bytes={2}; authority=consumed.' -f [string]$state.candidate.versionCode, $artifactHash, $artifactBytes)
