[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$AabPath,

  [Parameter(Mandatory)]
  [string]$ProguardFolderPath,

  [Parameter(Mandatory)]
  [string]$BundletoolPath,

  [Parameter(Mandatory)]
  [string]$UploadCertificatePath,

  [Parameter(Mandatory)]
  [string]$ExpectedVersionName,

  [Parameter(Mandatory)]
  [string]$ExpectedVersionCode,

  [Parameter(Mandatory)]
  [string]$CandidateId,

  [string]$PackageName = 'com.moolsocial.app',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Assert-AabReleaseArtifact([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "AAB release artifact readiness rejected: $Message"
  }
}

function Resolve-JavaTool([string]$Name) {
  $candidates = @()
  if (-not [string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
    $candidates += Join-Path $env:JAVA_HOME "bin\$Name.exe"
  }
  $candidates += "C:\Program Files\Android\Android Studio\jbr\bin\$Name.exe"
  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($null -ne $command) {
    $candidates += $command.Source
  }
  $resolved = @($candidates | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_) -and
    (Test-Path -LiteralPath $_ -PathType Leaf)
  } | Select-Object -Unique)
  Assert-AabReleaseArtifact ($resolved.Count -ge 1) "$Name is unavailable."
  return $resolved[0]
}

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$resolvedRoot = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
$resolvedAab = [IO.Path]::GetFullPath($AabPath)
$resolvedProguard = [IO.Path]::GetFullPath($ProguardFolderPath)
$resolvedBundletool = [IO.Path]::GetFullPath($BundletoolPath)
$resolvedUploadCertificate = [IO.Path]::GetFullPath($UploadCertificatePath)
Assert-AabReleaseArtifact `
  (Test-Path -LiteralPath $resolvedAab -PathType Leaf) `
  'the AAB is unavailable.'
Assert-AabReleaseArtifact `
  (Test-Path -LiteralPath $resolvedProguard -PathType Container) `
  'the Proguard folder is unavailable.'
Assert-AabReleaseArtifact `
  (Test-Path -LiteralPath $resolvedBundletool -PathType Leaf) `
  'bundletool is unavailable.'
Assert-AabReleaseArtifact `
  (Test-Path -LiteralPath $resolvedUploadCertificate -PathType Leaf) `
  'the public upload certificate is unavailable.'
Assert-AabReleaseArtifact `
  ($resolvedAab.StartsWith(
    $resolvedRoot + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  )) `
  'the AAB must be the repository-local generated artifact.'
Assert-AabReleaseArtifact `
  ((Get-FileHash -LiteralPath $resolvedBundletool -Algorithm SHA256).Hash -ceq
    'A099CFA1543F55593BC2ED16A70A7C67FE54B1747BB7301F37FDFD6D91028E29') `
  'bundletool does not match the pinned 1.18.3 binary.'
Assert-AabReleaseArtifact `
  ($PackageName -cmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$') `
  'the expected package name is malformed.'
Assert-AabReleaseArtifact `
  ($ExpectedVersionCode -cmatch '^\d+$') `
  'the expected version code is malformed.'
Assert-AabReleaseArtifact `
  (-not [string]::IsNullOrWhiteSpace($ExpectedVersionName)) `
  'the expected version name is missing.'
Assert-AabReleaseArtifact `
  (-not [string]::IsNullOrWhiteSpace($CandidateId)) `
  'the candidate identity is missing.'

$java = Resolve-JavaTool 'java'
$jarsigner = Resolve-JavaTool 'jarsigner'
$keytool = Resolve-JavaTool 'keytool'
$package = (& $java -jar $resolvedBundletool dump manifest `
  "--bundle=$resolvedAab" '--xpath=/manifest/@package' 2>$null).Trim()
Assert-AabReleaseArtifact `
  ($LASTEXITCODE -eq 0 -and $package -ceq $PackageName) `
  'the AAB package is incorrect.'
$versionCode = (& $java -jar $resolvedBundletool dump manifest `
  "--bundle=$resolvedAab" '--xpath=/manifest/@android:versionCode' 2>$null).Trim()
Assert-AabReleaseArtifact `
  ($LASTEXITCODE -eq 0 -and $versionCode -ceq $ExpectedVersionCode) `
  'the AAB version code is incorrect.'
$versionName = (& $java -jar $resolvedBundletool dump manifest `
  "--bundle=$resolvedAab" '--xpath=/manifest/@android:versionName' 2>$null).Trim()
Assert-AabReleaseArtifact `
  ($LASTEXITCODE -eq 0 -and $versionName -ceq $ExpectedVersionName) `
  'the AAB version name is incorrect.'

& $jarsigner -verify -certs $resolvedAab *> $null
Assert-AabReleaseArtifact `
  ($LASTEXITCODE -eq 0) `
  'the AAB archive signature is invalid.'
$artifactCertificate = @(& $keytool '-J-Duser.language=en' `
  -printcert -jarfile $resolvedAab 2>&1)
Assert-AabReleaseArtifact `
  ($LASTEXITCODE -eq 0) `
  'the AAB signer certificate is unreadable.'
$uploadCertificate = @(& $keytool '-J-Duser.language=en' `
  -printcert -file $resolvedUploadCertificate 2>&1)
Assert-AabReleaseArtifact `
  ($LASTEXITCODE -eq 0) `
  'the public upload certificate is unreadable.'
$certificatePattern = '(?im)^\s*SHA256:\s*([0-9A-F:]{95})\s*$'
$artifactSha = [regex]::Match(
  $artifactCertificate -join [Environment]::NewLine,
  $certificatePattern
)
$uploadSha = [regex]::Match(
  $uploadCertificate -join [Environment]::NewLine,
  $certificatePattern
)
Assert-AabReleaseArtifact `
  ($artifactSha.Success -and $uploadSha.Success) `
  'the signer identities are incomplete.'
Assert-AabReleaseArtifact `
  ($artifactSha.Groups[1].Value.Replace(':', '') -ceq
    $uploadSha.Groups[1].Value.Replace(':', '')) `
  'the AAB signer does not match the public upload certificate.'

$pluginGate = Join-Path $PSScriptRoot 'check-aab-production-plugin-integrity.ps1'
Assert-AabReleaseArtifact `
  (Test-Path -LiteralPath $pluginGate -PathType Leaf) `
  'the production plugin gate is unavailable.'
& $pluginGate `
  -AabPath $resolvedAab `
  -CandidateId $CandidateId `
  -ProguardFolderPath $resolvedProguard `
  -RepositoryRoot $resolvedRoot *> $null
$pluginGatePassed = $?
Assert-AabReleaseArtifact `
  $pluginGatePassed `
  'the production plugin integrity gate failed.'

$artifactSha = $null
$uploadSha = $null
Write-Output (
  'AAB release artifact readiness passed: ' +
  "package=$PackageName; versionName=$ExpectedVersionName; " +
  "versionCode=$ExpectedVersionCode; candidate=$CandidateId; " +
  'bundletoolPinned=true; archiveSignatureValid=true; ' +
  'uploadCertificateMatched=true; productionPluginsMatched=true; ' +
  'privateValuesEmitted=false.'
)
