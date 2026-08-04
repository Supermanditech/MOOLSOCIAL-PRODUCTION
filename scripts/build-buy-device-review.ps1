[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidatePattern('^BUY-[A-Z0-9][A-Z0-9.-]+$')]
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
  [ValidateSet('debug', 'profile')]
  [string]$BuildMode,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$MachineStatePath
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = [IO.Path]::GetFullPath(
  (Split-Path -Parent $PSScriptRoot)
)
$mobileRoot = Join-Path $repositoryRoot 'apps\mobile'
$artifactRoot = [IO.Path]::GetFullPath($ArtifactDirectory)

if (-not $artifactRoot.StartsWith(
    $repositoryRoot,
    [StringComparison]::OrdinalIgnoreCase
  )) {
  throw 'Device-review artifacts must stay inside the production repository.'
}

$branch = git -C $repositoryRoot branch --show-current
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
  throw 'Unable to identify the current Git branch.'
}
if ($branch.Trim() -eq 'main') {
  throw 'Buy device-review builds are forbidden on main.'
}

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

Push-Location $mobileRoot
try {
  $runtimeDefines = @(
    'MOOLSOCIAL_DEVICE_REVIEW=true',
    'MOOLSOCIAL_USE_EMULATORS=true',
    "MOOLSOCIAL_CANDIDATE_ID=$CandidateId"
  )
  $gateScript = Join-Path $repositoryRoot (
    'scripts\check-apk-regression-gate-state.ps1'
  )
  & $gateScript `
    -StatePath $MachineStatePath `
    -CandidateId $CandidateId `
    -BuildName $BuildName `
    -BuildNumber $BuildNumber `
    -BuildMode $BuildMode `
    -SourceFingerprint $SourceFingerprint `
    -RuntimeDefine $runtimeDefines
  if ($LASTEXITCODE -ne 0) {
    throw 'APK regression pre-build machine gate failed.'
  }

  $buildArguments = @(
    'build',
    'apk',
    "--$BuildMode",
    '--no-pub',
    '--build-name',
    $BuildName,
    '--build-number',
    $BuildNumber,
    '--dart-define',
    'MOOLSOCIAL_DEVICE_REVIEW=true',
    '--dart-define',
    'MOOLSOCIAL_USE_EMULATORS=true',
    '--dart-define',
    "MOOLSOCIAL_CANDIDATE_ID=$CandidateId"
  )
  & flutter @buildArguments
  if ($LASTEXITCODE -ne 0) {
    throw 'Flutter device-review APK build failed.'
  }

  $generatedApk = Join-Path $mobileRoot (
    "build\app\outputs\flutter-apk\app-$BuildMode.apk"
  )
  if (-not (Test-Path -LiteralPath $generatedApk -PathType Leaf)) {
    throw "Expected Flutter APK is missing: $generatedApk"
  }
  Copy-Item -LiteralPath $generatedApk -Destination $artifactPath
} finally {
  Pop-Location
}

$apk = Get-Item -LiteralPath $artifactPath
$apkHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash
$head = git -C $repositoryRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0) {
  throw 'Unable to identify the current Git HEAD.'
}
$runtimeDefines = (
  'MOOLSOCIAL_DEVICE_REVIEW=true;' +
  'MOOLSOCIAL_USE_EMULATORS=true;' +
  "MOOLSOCIAL_CANDIDATE_ID=$CandidateId"
)

@(
  "CandidateId=$CandidateId",
  "RuntimeDefines=$runtimeDefines",
  "Version=$BuildName",
  "VersionCode=$BuildNumber",
  "BuildMode=$BuildMode",
  "MachineState=$([IO.Path]::GetFullPath($MachineStatePath))",
  "Branch=$($branch.Trim())",
  "HEAD=$($head.Trim())",
  "SourceFingerprint=$SourceFingerprint",
  "APK=$artifactPath",
  "Bytes=$($apk.Length)",
  "SHA256=$apkHash",
  "BuiltAt=$([DateTimeOffset]::Now.ToString('o'))"
) | Set-Content -LiteralPath $manifestPath -Encoding utf8

Get-Content -LiteralPath $manifestPath
