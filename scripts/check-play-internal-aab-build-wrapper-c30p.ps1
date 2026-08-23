[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$wrapperPath = Join-Path $root 'scripts/invoke-play-internal-aab-build-c30p.ps1'
$launcherPath = Join-Path $root 'tmp/run-c30p-single-aab-founder.ps1'
foreach ($path in @($wrapperPath, $launcherPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "C30P build-wrapper gate rejected: required owner is missing: $path"
  }
}
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$launcher = Get-Content -Raw -LiteralPath $launcherPath

$wrapperRequired = @(
  '$PSVersionTable.PSVersion.Major -lt 7',
  '-Phase build',
  "'build',",
  "'appbundle',",
  "'--release',",
  "'--no-pub',",
  "'--build-name=1.0.0-r60.42',",
  "'--build-number=2026081242',",
  '--dart-define-from-file={0}',
  '$PSNativeCommandUseErrorActionPreference = $false',
  "`$ErrorActionPreference = 'Continue'",
  '$buildExitCode = $LASTEXITCODE',
  '$ErrorActionPreference = $savedErrorActionPreference',
  '$PSNativeCommandUseErrorActionPreference = $savedNativePreference',
  'single_release_AAB_build_in_progress_authority_consumed',
  'single_release_AAB_failed_authority_consumed',
  'single_release_AAB_succeeded_authority_consumed',
  '-printcert',
  '-jarfile',
  '-Phase postbuild',
  'secretDefineFileReadByAgent = $false',
  'secretValuesRecorded = $false'
)
foreach ($pattern in $wrapperRequired) {
  if (-not $wrapper.Contains($pattern, [StringComparison]::Ordinal)) {
    throw "C30P build-wrapper gate rejected: wrapper is missing $pattern"
  }
}

$launcherRequired = @(
  '$PSVersionTable.PSVersion.Major -lt 7',
  'PowerShell 7 or newer is required before founder prompts',
  'Read-Host',
  '-AsSecureString',
  'c30p-firebase-defines.transient.json',
  'invoke-play-internal-aab-build-c30p.ps1'
)
foreach ($pattern in $launcherRequired) {
  if (-not $launcher.Contains($pattern, [StringComparison]::Ordinal)) {
    throw "C30P build-wrapper gate rejected: launcher is missing $pattern"
  }
}

$forbidden = @(
  'flutter build apk', '--debug', '--profile', 'assembleRelease',
  'bundleProduction', 'Get-Content -LiteralPath $secretDefinePath',
  'Get-Content -Raw -LiteralPath $secretDefinePath',
  'MOOLSOCIAL_UPLOAD_STORE_PASSWORD=', 'MOOLSOCIAL_UPLOAD_KEY_PASSWORD='
)
foreach ($pattern in $forbidden) {
  if ($wrapper.Contains($pattern, [StringComparison]::OrdinalIgnoreCase) -or
      $launcher.Contains($pattern, [StringComparison]::OrdinalIgnoreCase)) {
    throw "C30P build-wrapper gate rejected: forbidden source pattern $pattern"
  }
}

Write-Output 'C30P PowerShell-7-fail-closed secret-safe single release AAB build-wrapper gate passed.'
