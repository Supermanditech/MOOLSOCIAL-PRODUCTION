[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$repositoryRootFull = [IO.Path]::GetFullPath($RepositoryRoot)
$wrapperPath = Join-Path `
  $repositoryRootFull `
  'scripts/invoke-play-internal-aab-build-c30o.ps1'
if (-not (Test-Path -LiteralPath $wrapperPath -PathType Leaf)) {
  throw 'C30O build-wrapper gate rejected: wrapper is missing.'
}
$source = Get-Content -Raw -LiteralPath $wrapperPath

$requiredSourcePatterns = @(
  "-Phase build",
  "'build',",
  "'appbundle',",
  "'--release',",
  "'--no-pub',",
  "'--build-name=1.0.0-r60.41',",
  "'--build-number=2026081241',",
  "--dart-define-from-file={0}",
  "single_release_AAB_build_in_progress_authority_consumed",
  "single_release_AAB_failed_authority_consumed",
  "single_release_AAB_succeeded_authority_consumed",
  "-printcert",
  "-jarfile",
  "-Phase postbuild",
  "secretDefineFileReadByAgent = `$false",
  "secretValuesRecorded = `$false"
)
foreach ($pattern in $requiredSourcePatterns) {
  if (-not $source.Contains($pattern, [StringComparison]::Ordinal)) {
    throw ('C30O build-wrapper gate rejected: source owner is missing {0}.' -f $pattern)
  }
}

$forbiddenPatterns = @(
  'flutter build apk',
  '--debug',
  '--profile',
  'assembleRelease',
  'bundleProduction',
  'Get-Content -LiteralPath $secretDefinePath',
  'Get-Content -Raw -LiteralPath $secretDefinePath',
  'MOOLSOCIAL_UPLOAD_STORE_PASSWORD=' ,
  'MOOLSOCIAL_UPLOAD_KEY_PASSWORD='
)
foreach ($pattern in $forbiddenPatterns) {
  if ($source.Contains($pattern, [StringComparison]::OrdinalIgnoreCase)) {
    throw ('C30O build-wrapper gate rejected: forbidden source pattern {0}.' -f $pattern)
  }
}

Write-Output 'C30O secret-safe single release AAB build-wrapper gate passed.'
