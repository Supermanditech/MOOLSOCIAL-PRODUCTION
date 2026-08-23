[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$wrapperPath = Join-Path $root 'scripts/invoke-play-internal-aab-build-c30t.ps1'
$launcherPath = Join-Path $root 'tmp/run-c30u-single-aab-founder.ps1'
$gatePath = Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30u.ps1'

function Assert-C30UWrapper {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30U build-wrapper gate rejected: $Message" }
}

foreach ($path in @($wrapperPath, $launcherPath, $gatePath)) {
  Assert-C30UWrapper -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "owner missing: $path"
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
  Assert-C30UWrapper -Condition (@($errors).Count -eq 0) -Message "PowerShell parser rejected: $path"
}

$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$gate = Get-Content -Raw -LiteralPath $gatePath

Assert-C30UWrapper -Condition (
  ([regex]::Matches($wrapper, "'appbundle'", [Text.RegularExpressions.RegexOptions]::CultureInvariant)).Count -eq 1
) -Message 'wrapper must contain exactly one appbundle invocation token.'
foreach ($required in @(
  'param([string]$StatePath',
  'check-play-internal-aab-regression-gate-state-c30u.ps1',
  '--config-only',
  '"--build-name=$versionName"',
  '"--build-number=$versionCode"',
  "@('build', 'appbundle', '--release', '--no-pub'",
  '-Phase build -StatePath $stateFile',
  '-Phase postbuild -StatePath $stateFile',
  '$state.buildAuthorization = ''consumed''',
  '$state.buildResult.buildCount = 1'
)) {
  Assert-C30UWrapper -Condition ($wrapper.Contains($required, [StringComparison]::Ordinal)) -Message "wrapper owner missing: $required"
}
Assert-C30UWrapper -Condition (
  $wrapper.Contains('RevocationBoundService[\s\S]{0,1000}\[com\.google\.android\.gms:play-services-auth:21\.6\.0\]', [StringComparison]::Ordinal) -and
  -not $wrapper.Contains('play-services-auth:20\.7\.0', [StringComparison]::Ordinal)
) -Message 'wrapper does not bind RevocationBoundService to exact current play-services-auth 21.6.0 provenance.'
foreach ($forbidden in @(
  'flutter build appbundle',
  'flutter build apk --release',
  '--debug',
  '--profile',
  '2026081345',
  '1.0.0-r60.45',
  '$state.buildResult.secondBuildPerformed = $true',
  '$aggregate.releaseResult.secondBuildPerformed = $true'
)) {
  Assert-C30UWrapper -Condition (-not $wrapper.Contains($forbidden, [StringComparison]::OrdinalIgnoreCase)) -Message "wrapper contains forbidden literal: $forbidden"
}

Assert-C30UWrapper -Condition (
  ([regex]::Matches($launcher, 'Read-Host[^\r\n]*-AsSecureString')).Count -eq 2
) -Message 'launcher must contain exactly two hidden founder prompts.'
foreach ($required in @(
  'PowerShell 7',
  'play-internal-aab-regression-gate-state-c30u.json',
  'source_qualified_founder_secret_prompt_required',
  'available_once',
  '2026081346',
  'r60.46',
  'invoke-play-internal-aab-build-c30t.ps1',
  '-StatePath $statePath',
  'MOOLSOCIAL_UPLOAD_STORE_PASSWORD',
  'MOOLSOCIAL_FIREBASE_API_KEY',
  'ZeroFreeBSTR',
  'SetEnvironmentVariable($name, $null, ''Process'')',
  'Remove-Item -LiteralPath $path -Force',
  'buildResult.buildCount -eq 0'
)) {
  Assert-C30UWrapper -Condition ($launcher.Contains($required, [StringComparison]::Ordinal)) -Message "launcher owner missing: $required"
}
foreach ($forbidden in @(
  'Write-Host $uploadPassword',
  'Write-Host $firebaseKey',
  'Write-Output $uploadPassword',
  'Write-Output $firebaseKey',
  'Set-Clipboard',
  'Get-Clipboard'
)) {
  Assert-C30UWrapper -Condition (-not $launcher.Contains($forbidden, [StringComparison]::OrdinalIgnoreCase)) -Message "launcher contains forbidden secret output or clipboard owner: $forbidden"
}
foreach ($required in @(
  'available_once',
  'passed_two_identical_cycles_after_Dev_content_deployment',
  'deploymentPassed',
  'releasePreflightPassed',
  'internal_release_active_upload_consumed',
  'Play_installed_identity_sealed_journeys_pending'
)) {
  Assert-C30UWrapper -Condition ($gate.Contains($required, [StringComparison]::Ordinal)) -Message "machine gate missing: $required"
}

Write-Output 'C30U build-wrapper gate passed: one dynamic r60.46 appbundle authority; two hidden founder inputs; transient cleanup enforced.'
