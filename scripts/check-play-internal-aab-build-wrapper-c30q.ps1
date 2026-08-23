[CmdletBinding()]
param([string]$RepositoryRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$wrapperPath = Join-Path $root 'scripts/invoke-play-internal-aab-build-c30q.ps1'
$launcherPath = Join-Path $root 'tmp/run-c30q-single-aab-founder.ps1'
foreach ($path in @($wrapperPath, $launcherPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C30Q wrapper gate rejected: missing $path" }
}
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$required = @(
  '$PSVersionTable.PSVersion.Major -lt 7',
  "'apk',", "'--release',", "'--config-only'",
  '$pubspecHashBefore', '$lockHashBefore',
  'return $LASTEXITCODE',
  '$releaseConfigExitCode = Invoke-NativeCaptured',
  'IntegrationTestPlugin',
  "'appbundle',", "'--build-name=1.0.0-r60.43',", "'--build-number=2026081243',",
  '$PSNativeCommandUseErrorActionPreference = $false',
  "`$ErrorActionPreference = 'Continue'",
  'single_release_AAB_succeeded_authority_consumed',
  '-printcert', '-jarfile', '-Phase postbuild'
)
foreach ($pattern in $required) {
  if (-not $wrapper.Contains($pattern, [StringComparison]::Ordinal)) { throw "C30Q wrapper gate rejected: missing $pattern" }
}
foreach ($pattern in @('$PSVersionTable.PSVersion.Major -lt 7', 'Read-Host', '-AsSecureString', 'c30q-firebase-defines.transient.json', 'invoke-play-internal-aab-build-c30q.ps1')) {
  if (-not $launcher.Contains($pattern, [StringComparison]::Ordinal)) { throw "C30Q launcher gate rejected: missing $pattern" }
}
$appBundleMatches = [regex]::Matches($wrapper, "'appbundle'").Count
if ($appBundleMatches -ne 1) { throw "C30Q wrapper gate rejected: appbundle invocation count is $appBundleMatches." }
foreach ($pattern in @('flutter build apk', '--debug', '--profile', 'bundleProduction', 'Get-Content -Raw -LiteralPath $secretDefinePath', 'MOOLSOCIAL_UPLOAD_STORE_PASSWORD=')) {
  if ($wrapper.Contains($pattern, [StringComparison]::OrdinalIgnoreCase) -or $launcher.Contains($pattern, [StringComparison]::OrdinalIgnoreCase)) { throw "C30Q wrapper gate rejected: forbidden $pattern" }
}
Write-Output 'C30Q release-config-only, PowerShell-7, secret-safe, single-AAB wrapper gate passed.'
