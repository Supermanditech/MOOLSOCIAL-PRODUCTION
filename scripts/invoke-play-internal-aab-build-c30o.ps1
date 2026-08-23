[CmdletBinding()]
param(
  [string]$StatePath,

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$repositoryRootFull = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$repositoryPrefix = $repositoryRootFull + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) {
  $StatePath = Join-Path `
    $repositoryRootFull `
    'config/play-internal-aab-regression-gate-state-c30o.json'
}
$statePathFull = [IO.Path]::GetFullPath($StatePath)

function Assert-C30OBuild {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw ('C30O single AAB build rejected: {0}' -f $Message)
  }
}

function Resolve-C30ORepositoryPath {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath,

    [Parameter(Mandatory)]
    [string]$Label
  )

  Assert-C30OBuild `
    -Condition (-not [IO.Path]::IsPathRooted($RelativePath)) `
    -Message ('{0} must be repository-relative.' -f $Label)
  $resolved = [IO.Path]::GetFullPath(
    (Join-Path $repositoryRootFull $RelativePath)
  )
  Assert-C30OBuild -Condition (
    $resolved.StartsWith(
      $repositoryPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message ('{0} escaped the production repository.' -f $Label)
  return $resolved
}

function Write-C30OState {
  param(
    [Parameter(Mandatory)]
    [object]$State
  )

  $temporaryPath = $statePathFull + '.c30o-write'
  Assert-C30OBuild `
    -Condition (-not (Test-Path -LiteralPath $temporaryPath)) `
    -Message 'a stale machine-state temporary file exists.'
  $json = $State | ConvertTo-Json -Depth 32
  [IO.File]::WriteAllText(
    $temporaryPath,
    $json + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false)
  )
  Move-Item `
    -LiteralPath $temporaryPath `
    -Destination $statePathFull `
    -Force
}

Assert-C30OBuild -Condition (
  $statePathFull.StartsWith(
    $repositoryPrefix,
    [StringComparison]::OrdinalIgnoreCase
  )
) -Message 'machine state escaped the production repository.'
Assert-C30OBuild `
  -Condition (Test-Path -LiteralPath $statePathFull -PathType Leaf) `
  -Message 'machine state is missing.'

$gatePath = Join-Path `
  $repositoryRootFull `
  'scripts/check-play-internal-aab-regression-gate-state-c30o.ps1'
& $gatePath -Phase build -RepositoryRoot $repositoryRootFull

$state = Get-Content -Raw -LiteralPath $statePathFull | ConvertFrom-Json
$candidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30O'
Assert-C30OBuild `
  -Condition ([string]$state.candidate.id -ceq $candidateId) `
  -Message 'candidate identity changed after the build gate.'

$requiredEnvironmentNames = @(
  [string[]]$state.signingQualification.uploadKeyEnvironmentNames
) + @([string]$state.runtimeConfiguration.secretDefineFileEnvironmentName)
foreach ($environmentName in $requiredEnvironmentNames) {
  Assert-C30OBuild `
    -Condition (Test-Path -LiteralPath ('Env:{0}' -f $environmentName)) `
    -Message ('required founder-controlled environment entry is absent: {0}.' -f $environmentName)
}

$uploadStorePath = [Environment]::GetEnvironmentVariable(
  'MOOLSOCIAL_UPLOAD_STORE_FILE'
)
$secretDefinePath = [Environment]::GetEnvironmentVariable(
  'MOOLSOCIAL_FIREBASE_DART_DEFINE_FILE'
)
Assert-C30OBuild `
  -Condition (Test-Path -LiteralPath $uploadStorePath -PathType Leaf) `
  -Message 'founder-controlled upload keystore path is not a file.'
Assert-C30OBuild `
  -Condition (Test-Path -LiteralPath $secretDefinePath -PathType Leaf) `
  -Message 'founder-qualified secret define path is not a file.'

$artifactRootRelative =
  'artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30o-r60-41-20260812-02'
$artifactRoot = Resolve-C30ORepositoryPath `
  -RelativePath $artifactRootRelative `
  -Label 'C30O evidence directory'
Assert-C30OBuild `
  -Condition (Test-Path -LiteralPath $artifactRoot -PathType Container) `
  -Message 'C30O evidence directory is missing.'

$generatedRelative =
  'apps/mobile/build/app/outputs/bundle/release/app-release.aab'
$sealedRelative = $artifactRootRelative +
  '/MoolSocial-1.0.0-r60.41-2026081241-release.aab'
$buildLogRelative = $artifactRootRelative + '/03-release-aab-build.log'
$provenanceRelative = $artifactRootRelative +
  '/04-release-aab-provenance.json'
$prebuildStateRelative = $artifactRootRelative +
  '/03a-prebuild-machine-state.json'
$generatedPath = Resolve-C30ORepositoryPath `
  -RelativePath $generatedRelative `
  -Label 'generated AAB'
$sealedPath = Resolve-C30ORepositoryPath `
  -RelativePath $sealedRelative `
  -Label 'sealed AAB'
$buildLogPath = Resolve-C30ORepositoryPath `
  -RelativePath $buildLogRelative `
  -Label 'build log'
$provenancePath = Resolve-C30ORepositoryPath `
  -RelativePath $provenanceRelative `
  -Label 'provenance'
$prebuildStatePath = Resolve-C30ORepositoryPath `
  -RelativePath $prebuildStateRelative `
  -Label 'prebuild state evidence'

foreach ($mustBeAbsent in @(
  $generatedPath,
  $sealedPath,
  $buildLogPath,
  $provenancePath,
  $prebuildStatePath
)) {
  Assert-C30OBuild `
    -Condition (-not (Test-Path -LiteralPath $mustBeAbsent)) `
    -Message ('single-build output already exists: {0}.' -f $mustBeAbsent)
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
Write-C30OState -State $state

$buildArguments = @(
  'build',
  'appbundle',
  '--release',
  '--no-pub',
  '--build-name=1.0.0-r60.41',
  '--build-number=2026081241',
  ('--dart-define-from-file={0}' -f $secretDefinePath)
)
foreach ($property in $state.runtimeConfiguration.requiredNonSecretDefines.PSObject.Properties) {
  $buildArguments += '--dart-define={0}={1}' -f $property.Name, $property.Value
}

$mobileRoot = Join-Path $repositoryRootFull 'apps/mobile'
$buildExitCode = -1
$pushedLocation = $false
try {
  Push-Location $mobileRoot
  $pushedLocation = $true
  & flutter @buildArguments *> $buildLogPath
  $buildExitCode = $LASTEXITCODE
} catch {
  $state.machineState = 'single_release_AAB_failed_authority_consumed'
  $state.buildResult.state = 'single_release_AAB_failed_authority_consumed'
  Write-C30OState -State $state
  throw
} finally {
  if ($pushedLocation) {
    Pop-Location
  }
}

if ($buildExitCode -ne 0) {
  $state.machineState = 'single_release_AAB_failed_authority_consumed'
  $state.buildResult.state = 'single_release_AAB_failed_authority_consumed'
  Write-C30OState -State $state
  throw ('C30O single release AAB build failed with exit code {0}.' -f $buildExitCode)
}

Assert-C30OBuild `
  -Condition (Test-Path -LiteralPath $generatedPath -PathType Leaf) `
  -Message 'Flutter reported success without the exact release AAB.'
Copy-Item -LiteralPath $generatedPath -Destination $sealedPath

$keytoolCommand = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytoolCommand -and (Test-Path -LiteralPath Env:JAVA_HOME)) {
  $javaHomeKeytool = Join-Path `
    ([Environment]::GetEnvironmentVariable('JAVA_HOME')) `
    'bin/keytool.exe'
  if (Test-Path -LiteralPath $javaHomeKeytool -PathType Leaf) {
    $keytoolCommand = Get-Item -LiteralPath $javaHomeKeytool
  }
}
Assert-C30OBuild `
  -Condition ($null -ne $keytoolCommand) `
  -Message 'keytool is unavailable for public signer-certificate verification.'
$certificateOutput = & $keytoolCommand.Source `
  -printcert `
  -jarfile $sealedPath 2>&1
Assert-C30OBuild `
  -Condition ($LASTEXITCODE -eq 0) `
  -Message 'sealed AAB signer certificate could not be read.'
$certificateText = $certificateOutput -join [Environment]::NewLine
$shaMatch = [regex]::Match(
  $certificateText,
  'SHA256:\s*([0-9A-Fa-f:]{64,95})'
)
Assert-C30OBuild `
  -Condition $shaMatch.Success `
  -Message 'sealed AAB SHA-256 signer fingerprint was absent.'
$uploadSignerSha256 = $shaMatch.Groups[1].Value.Replace(':', '').ToUpperInvariant()
$expectedUploadSignerSha256 = (
  [string]$state.signingQualification.uploadCertificateSha256
).Replace(':', '').ToUpperInvariant()
Assert-C30OBuild `
  -Condition ($uploadSignerSha256 -ceq $expectedUploadSignerSha256) `
  -Message 'sealed AAB signer differs from the founder-qualified upload certificate.'

$artifactHash = (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash
$artifactBytes = (Get-Item -LiteralPath $sealedPath).Length
$sourceManifestPath = Resolve-C30ORepositoryPath `
  -RelativePath ([string]$state.sourceQualification.manifestPath) `
  -Label 'sealed source manifest'
$sourceManifestHash = (
  Get-FileHash -LiteralPath $sourceManifestPath -Algorithm SHA256
).Hash
Assert-C30OBuild -Condition (
  $sourceManifestHash -ceq
    ([string]$state.sourceQualification.manifestSha256).ToUpperInvariant()
) -Message 'source manifest changed during the single build.'

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
  sourceManifest = [string]$state.sourceQualification.manifestPath
  sourceManifestSha256 = $sourceManifestHash
  sourceFiles = [int]$state.sourceQualification.fileCount
  artifactPath = $sealedRelative
  artifactSha256 = $artifactHash
  artifactBytes = $artifactBytes
  uploadSignerSha256 = $uploadSignerSha256
  buildLog = $buildLogRelative
  secretDefineFileReadByAgent = $false
  secretValuesRecorded = $false
  requiredSecretDefineNames = @(
    [string[]]$state.runtimeConfiguration.requiredSecretDefineNames
  )
  requiredNonSecretDefineNames = @(
    $state.runtimeConfiguration.requiredNonSecretDefines.PSObject.Properties.Name
  )
  builtAt = [DateTimeOffset]::Now.ToString('o')
}
[IO.File]::WriteAllText(
  $provenancePath,
  (($provenance | ConvertTo-Json -Depth 12) + [Environment]::NewLine),
  [Text.UTF8Encoding]::new($false)
)

$state.machineState = 'single_release_AAB_succeeded_authority_consumed'
$state.buildResult.state = 'single_release_AAB_succeeded_authority_consumed'
$state.buildResult.artifactPath = $sealedRelative
$state.buildResult.artifactSha256 = $artifactHash
$state.buildResult.artifactBytes = $artifactBytes
$state.buildResult.uploadSignerSha256 = $uploadSignerSha256
$state.buildResult.provenance = $provenanceRelative
Write-C30OState -State $state

& $gatePath -Phase postbuild -RepositoryRoot $repositoryRootFull
Write-Output (
  'C30O single release AAB succeeded: versionCode={0}; sha256={1}; bytes={2}; authority=consumed.' -f
    [string]$state.candidate.versionCode,
    $artifactHash,
    $artifactBytes
)
