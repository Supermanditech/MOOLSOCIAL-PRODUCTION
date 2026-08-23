[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$wrapperPath = Join-Path $root 'scripts/invoke-play-internal-aab-build-c30t.ps1'
$launcherPath = Join-Path $root 'tmp/run-c30v-single-aab-founder.ps1'
$gatePath = Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30v.ps1'

function Assert-C30VWrapper {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30V build-wrapper gate rejected: $Message" }
}

function Test-C30VContainsLiteral {
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][string]$Value,
    [Parameter(Mandatory)][StringComparison]$Comparison
  )
  return $Text.IndexOf($Value, $Comparison) -ge 0
}

foreach ($path in @($wrapperPath, $launcherPath, $gatePath)) {
  Assert-C30VWrapper -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "owner missing: $path"
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
  Assert-C30VWrapper -Condition (@($errors).Count -eq 0) -Message "PowerShell parser rejected: $path"
}

$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$gate = Get-Content -Raw -LiteralPath $gatePath

Assert-C30VWrapper -Condition (
  ([regex]::Matches($wrapper, "'appbundle'", [Text.RegularExpressions.RegexOptions]::CultureInvariant)).Count -eq 1
) -Message 'wrapper must contain exactly one appbundle invocation token.'
foreach ($required in @(
  'param([string]$StatePath',
  'check-play-internal-aab-regression-gate-state-c30v.ps1',
  '--config-only',
  '"--build-name=$versionName"',
  '"--build-number=$versionCode"',
  "@('build', 'appbundle', '--release', '--no-pub'",
  '-Phase build -StatePath $stateFile',
  '-Phase postbuild -StatePath $stateFile',
  'check-release-runtime-configuration-c30w.ps1',
  '-Phase build -StatePath $stateFile',
  'googleServerClientIdQualifiedByFounder',
  '$state.buildAuthorization = ''consumed''',
  '$state.buildResult.buildCount = 1'
)) {
  Assert-C30VWrapper -Condition (Test-C30VContainsLiteral -Text $wrapper -Value $required -Comparison Ordinal) -Message "wrapper owner missing: $required"
}
Assert-C30VWrapper -Condition (
  (Test-C30VContainsLiteral -Text $wrapper -Value 'RevocationBoundService[\s\S]{0,1000}\[com\.google\.android\.gms:play-services-auth:21\.6\.0\]' -Comparison Ordinal) -and
  -not (Test-C30VContainsLiteral -Text $wrapper -Value 'play-services-auth:20\.7\.0' -Comparison Ordinal)
) -Message 'wrapper does not bind RevocationBoundService to exact current play-services-auth 21.6.0 provenance.'
foreach ($forbidden in @(
  'flutter build appbundle',
  'flutter build apk --release',
  '--debug',
  '--profile',
  '2026081345',
  '1.0.0-r60.45',
  '2026081346',
  '1.0.0-r60.46',
  '$state.buildResult.secondBuildPerformed = $true',
  '$aggregate.releaseResult.secondBuildPerformed = $true'
)) {
  Assert-C30VWrapper -Condition (-not (Test-C30VContainsLiteral -Text $wrapper -Value $forbidden -Comparison OrdinalIgnoreCase)) -Message "wrapper contains forbidden literal: $forbidden"
}
foreach ($required in @(
  '$expectedReleaseRegistrantPluginCount = 16',
  '.Count -eq $expectedReleaseRegistrantPluginCount',
  'releaseRegistrantPluginCount = $expectedReleaseRegistrantPluginCount'
)) {
  Assert-C30VWrapper -Condition (Test-C30VContainsLiteral -Text $wrapper -Value $required -Comparison Ordinal) -Message "wrapper plugin-count binding missing: $required"
}

Assert-C30VWrapper -Condition (
  ([regex]::Matches($launcher, 'Read-Host[^\r\n]*-AsSecureString')).Count -eq 3
) -Message 'launcher must contain exactly three hidden founder prompts.'
foreach ($required in @(
  'PowerShell 7',
  'play-internal-aab-regression-gate-state-c30v.json',
  'source_qualified_founder_secret_prompt_required',
  'available_once',
  '2026081347',
  'r60.47',
  'invoke-play-internal-aab-build-c30t.ps1',
  '-StatePath $statePath',
  'MOOLSOCIAL_UPLOAD_STORE_PASSWORD',
  'MOOLSOCIAL_FIREBASE_API_KEY',
  'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
  'googleServerClientIdQualifiedByFounder',
  'apps.googleusercontent.com',
  'ZeroFreeBSTR',
  'SetEnvironmentVariable($name, $null, ''Process'')',
  'Remove-Item -LiteralPath $path -Force',
  'buildResult.buildCount -eq 0'
)) {
  Assert-C30VWrapper -Condition (Test-C30VContainsLiteral -Text $launcher -Value $required -Comparison Ordinal) -Message "launcher owner missing: $required"
}
foreach ($forbidden in @(
  'Write-Host $uploadPassword',
  'Write-Host $firebaseKey',
  'Write-Output $uploadPassword',
  'Write-Output $firebaseKey',
  'Write-Host $googleServerClientId',
  'Write-Output $googleServerClientId',
  'Set-Clipboard',
  'Get-Clipboard'
)) {
  Assert-C30VWrapper -Condition (-not (Test-C30VContainsLiteral -Text $launcher -Value $forbidden -Comparison OrdinalIgnoreCase)) -Message "launcher contains forbidden secret output or clipboard owner: $forbidden"
}
foreach ($required in @(
  'available_once',
  'passed_two_identical_cycles_with_preserved_Dev_services',
  'deploymentPassed',
  'releasePreflightPassed',
  'internal_release_active_upload_consumed',
  'Play_installed_identity_sealed_journeys_pending'
)) {
  Assert-C30VWrapper -Condition (Test-C30VContainsLiteral -Text $gate -Value $required -Comparison Ordinal) -Message "machine gate missing: $required"
}

$successEvidence = 'C30V build-wrapper gate passed: one dynamic successor-contract appbundle authority; three hidden founder inputs; transient cleanup enforced.'
Assert-C30VWrapper -Condition (
  (Test-C30VContainsLiteral `
    -Text $successEvidence `
    -Value 'dynamic successor-contract appbundle authority' `
    -Comparison Ordinal) -and
  -not [regex]::IsMatch($successEvidence, '(?i)\br60[.]47\b')
) -Message 'success evidence reintroduced the failed r60.47 identity or lost the dynamic successor label.'
Write-Output $successEvidence
