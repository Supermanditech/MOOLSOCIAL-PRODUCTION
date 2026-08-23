[CmdletBinding()]
param(
  [ValidateSet('source', 'build', 'postinstall')][string]$Phase = 'source',
  [string]$StatePath,
  [string]$AcceptanceEvidencePath,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C30WRuntime {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30W release-runtime gate rejected: $Message" }
}
function Resolve-C30WRepoFile {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $resolved = if ([IO.Path]::IsPathRooted($Path)) { [IO.Path]::GetFullPath($Path) } else { [IO.Path]::GetFullPath((Join-Path $root $Path)) }
  Assert-C30WRuntime -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped the repository."
  Assert-C30WRuntime -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) -Message "$Label is missing."
  return $resolved
}
function Assert-C30WContains {
  param([Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][string]$Needle, [Parameter(Mandatory)][string]$Label)
  Assert-C30WRuntime -Condition ($Text.IndexOf($Needle, [StringComparison]::Ordinal) -ge 0) -Message "$Label missing: $Needle"
}
function Assert-C30WPowerShellParses {
  param([Parameter(Mandatory)][string]$Path)
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
  Assert-C30WRuntime -Condition (@($errors).Count -eq 0) -Message "PowerShell parser rejected: $Path"
}
function Assert-C30WFounderLauncher {
  param([Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][string]$Label)
  Assert-C30WRuntime -Condition (([regex]::Matches($Text, 'Read-Host[^\r\n]*-AsSecureString')).Count -eq 3) -Message "$Label must contain exactly three hidden founder prompts."
  foreach ($required in @(
    'MOOLSOCIAL_FIREBASE_API_KEY',
    'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
    'googleServerClientIdQualifiedByFounder',
    'apps.googleusercontent.com',
    'ZeroFreeBSTR',
    'Remove-Item -LiteralPath $path -Force'
  )) { Assert-C30WContains -Text $Text -Needle $required -Label $Label }
  foreach ($forbidden in @(
    'Write-Host $uploadPassword',
    'Write-Host $firebaseKey',
    'Write-Host $googleServerClientId',
    'Write-Output $uploadPassword',
    'Write-Output $firebaseKey',
    'Write-Output $googleServerClientId',
    'Set-Clipboard',
    'Get-Clipboard'
  )) {
    Assert-C30WRuntime -Condition ($Text.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -lt 0) -Message "$Label contains forbidden secret output or clipboard owner: $forbidden"
  }
  Assert-C30WRuntime -Condition (-not [regex]::IsMatch($Text, '(?i)\b[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com\b')) -Message "$Label contains a credential-shaped OAuth client ID literal."
}
function Assert-C30WProperty {
  param([Parameter(Mandatory)][object]$Object, [Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Label)
  Assert-C30WRuntime -Condition ($null -ne $Object.PSObject.Properties[$Name]) -Message "$Label missing property: $Name"
}

$configurationPath = Resolve-C30WRepoFile -Path 'apps/mobile/lib/core/config/release_runtime_configuration.dart' -Label 'release configuration contract'
$mainPath = Resolve-C30WRepoFile -Path 'apps/mobile/lib/main.dart' -Label 'mobile bootstrap'
$testPath = Resolve-C30WRepoFile -Path 'apps/mobile/test/release_runtime_configuration_test.dart' -Label 'release configuration regression test'
$wrapperPath = Resolve-C30WRepoFile -Path 'scripts/invoke-play-internal-aab-build-c30t.ps1' -Label 'single AAB wrapper'
$launcherTemplatePath = Resolve-C30WRepoFile -Path 'tmp/run-c30v-single-aab-founder.ps1' -Label 'founder launcher template'
$c30vStatePath = Resolve-C30WRepoFile -Path 'config/play-internal-aab-regression-gate-state-c30v.json' -Label 'failed C30V AAB state'
$c30vAggregatePath = Resolve-C30WRepoFile -Path 'config/play-internal-seal-recovery-acceptance-gate-state-c30v.json' -Label 'failed C30V aggregate state'
foreach ($path in @($wrapperPath, $launcherTemplatePath)) { Assert-C30WPowerShellParses -Path $path }

$configurationSource = Get-Content -Raw -LiteralPath $configurationPath
$mainSource = Get-Content -Raw -LiteralPath $mainPath
$testSource = Get-Content -Raw -LiteralPath $testPath
$wrapperSource = Get-Content -Raw -LiteralPath $wrapperPath
$launcherTemplate = Get-Content -Raw -LiteralPath $launcherTemplatePath
$requiredDefineNames = @(
  'MOOLSOCIAL_FIREBASE_API_KEY',
  'MOOLSOCIAL_FIREBASE_APP_ID',
  'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
  'MOOLSOCIAL_FIREBASE_PROJECT_ID',
  'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID'
)
$contractDefineNames = @([regex]::Matches($configurationSource, 'MOOLSOCIAL_[A-Z0-9_]+') | ForEach-Object { $_.Value } | Sort-Object -Unique)
Assert-C30WRuntime -Condition ($contractDefineNames.Count -eq $requiredDefineNames.Count -and @(Compare-Object -ReferenceObject $requiredDefineNames -DifferenceObject $contractDefineNames).Count -eq 0) -Message 'release configuration contract define-name set is not exact.'
foreach ($required in @(
  'class ReleaseRuntimeConfiguration',
  'missingRequiredDefineNames',
  'class ReleaseConfigurationFailureApp',
  'MoolSocial needs an update',
  'Your account and ',
  'content are safe.'
)) { Assert-C30WContains -Text $configurationSource -Needle $required -Label 'release configuration contract' }

foreach ($required in @(
  "import 'core/config/release_runtime_configuration.dart';",
  'const _releaseRuntimeConfiguration = ReleaseRuntimeConfiguration(',
  '!_releaseRuntimeConfiguration.isComplete',
  '!_runtimeModeIsValid()',
  "_showReleaseBootstrapFailure('release_configuration')",
  'runApp(const ReleaseBootstrapApp());',
  'runApp(const ReleaseConfigurationFailureApp());'
)) { Assert-C30WContains -Text $mainSource -Needle $required -Label 'mobile bootstrap' }
$fallbackIndex = $mainSource.IndexOf("_showReleaseBootstrapFailure('release_configuration')", [StringComparison]::Ordinal)
$bootstrapIndex = $mainSource.IndexOf('runApp(const ReleaseBootstrapApp());', [StringComparison]::Ordinal)
$firebaseIndex = $mainSource.IndexOf('Firebase.initializeApp', [StringComparison]::Ordinal)
Assert-C30WRuntime -Condition ($fallbackIndex -ge 0 -and $bootstrapIndex -gt $fallbackIndex -and $firebaseIndex -gt $bootstrapIndex) -Message 'precheck fallback and named Flutter frame must precede Firebase initialization.'
Assert-C30WRuntime -Condition ($mainSource.IndexOf('Release configuration is incomplete', [StringComparison]::Ordinal) -lt 0) -Message 'mobile bootstrap still contains the pre-runApp release-configuration throw path.'
foreach ($defineName in $requiredDefineNames) { Assert-C30WContains -Text $testSource -Needle $defineName -Label 'release configuration regression test' }
foreach ($required in @('ReleaseConfigurationFailureApp', 'MoolSocial needs an update', 'googleusercontent.com')) { Assert-C30WContains -Text $testSource -Needle $required -Label 'release configuration regression test' }

Assert-C30WFounderLauncher -Text $launcherTemplate -Label 'founder launcher template'
foreach ($required in @(
  'check-release-runtime-configuration-c30w.ps1',
  '-Phase build -StatePath $stateFile',
  'googleServerClientIdQualifiedByFounder',
  "@('build', 'appbundle', '--release', '--no-pub'"
)) { Assert-C30WContains -Text $wrapperSource -Needle $required -Label 'single AAB wrapper' }
$runtimeGateIndex = $wrapperSource.IndexOf('-Phase build -StatePath $stateFile', [StringComparison]::Ordinal)
$appBundleIndex = $wrapperSource.IndexOf("@('build', 'appbundle', '--release', '--no-pub'", [StringComparison]::Ordinal)
Assert-C30WRuntime -Condition ($runtimeGateIndex -ge 0 -and $appBundleIndex -gt $runtimeGateIndex) -Message 'release-runtime build gate must execute before the appbundle invocation.'

$c30vState = Get-Content -Raw -LiteralPath $c30vStatePath | ConvertFrom-Json
$c30vAggregate = Get-Content -Raw -LiteralPath $c30vAggregatePath | ConvertFrom-Json
Assert-C30WRuntime -Condition ([string]$c30vState.machineState -ceq 'acceptance_failed_r60_47_cold_start_release_config_successor_required') -Message 'failed r60.47 AAB state was weakened.'
Assert-C30WRuntime -Condition ([string]$c30vAggregate.machineState -ceq 'acceptance_failed_r60_47_cold_start_release_config_successor_required') -Message 'failed r60.47 aggregate state was weakened.'
Assert-C30WRuntime -Condition ([int]$c30vAggregate.candidate.buildCount -eq 1 -and [int]$c30vAggregate.candidate.uploadCount -eq 1 -and [int]$c30vAggregate.candidate.installCount -eq 1) -Message 'failed r60.47 one-build/upload/install counts changed.'

if ($Phase -in @('build', 'postinstall')) {
  Assert-C30WRuntime -Condition (-not [string]::IsNullOrWhiteSpace($StatePath)) -Message 'candidate state path is required.'
  $candidateStatePath = Resolve-C30WRepoFile -Path $StatePath -Label 'candidate AAB state'
  $candidateState = Get-Content -Raw -LiteralPath $candidateStatePath | ConvertFrom-Json
  Assert-C30WProperty -Object $candidateState.runtimeConfiguration -Name 'googleServerClientIdQualifiedByFounder' -Label 'runtime configuration'
  Assert-C30WRuntime -Condition ([bool]$candidateState.runtimeConfiguration.googleServerClientIdQualifiedByFounder) -Message 'Google server client ID was not founder-qualified.'
  Assert-C30WProperty -Object $candidateState.runtimeConfiguration -Name 'founderLauncherPath' -Label 'runtime configuration'
  $candidateLauncherPath = Resolve-C30WRepoFile -Path ([string]$candidateState.runtimeConfiguration.founderLauncherPath) -Label 'candidate founder launcher'
  Assert-C30WPowerShellParses -Path $candidateLauncherPath
  Assert-C30WFounderLauncher -Text (Get-Content -Raw -LiteralPath $candidateLauncherPath) -Label 'candidate founder launcher'
  $candidateSecretDefineNames = @([string[]]$candidateState.runtimeConfiguration.requiredSecretDefineNames | Sort-Object -Unique)
  $expectedSecretDefineNames = @('MOOLSOCIAL_FIREBASE_API_KEY', 'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID')
  Assert-C30WRuntime -Condition ($candidateSecretDefineNames.Count -eq $expectedSecretDefineNames.Count -and @(Compare-Object -ReferenceObject $expectedSecretDefineNames -DifferenceObject $candidateSecretDefineNames).Count -eq 0) -Message 'candidate secret define-name set is incomplete or contains extras.'
}

if ($Phase -ceq 'postinstall') {
  Assert-C30WRuntime -Condition (-not [string]::IsNullOrWhiteSpace($AcceptanceEvidencePath)) -Message 'Play-installed cold-start evidence path is required.'
  $coldStartPath = Resolve-C30WRepoFile -Path $AcceptanceEvidencePath -Label 'Play-installed cold-start evidence'
  $coldStartRaw = Get-Content -Raw -LiteralPath $coldStartPath
  Assert-C30WRuntime -Condition (-not [regex]::IsMatch($coldStartRaw, 'AIza[0-9A-Za-z_-]{35}|(?i)\b[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com\b|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----')) -Message 'cold-start evidence contains credential-shaped material.'
  $coldStart = $coldStartRaw | ConvertFrom-Json
  foreach ($name in @('packageName', 'versionCode', 'installerPackage', 'firstScreenName', 'coldStartInteractive', 'blankHierarchy', 'timeout', 'flutterFatalErrorCount', 'androidRuntimeFatalCount', 'anrCount', 'appProcessErrorScanPassed', 'artifactRelationshipProved', 'inPlaceUpdateProved')) {
    Assert-C30WProperty -Object $coldStart -Name $name -Label 'Play-installed cold-start evidence'
  }
  Assert-C30WRuntime -Condition ([string]$coldStart.packageName -ceq 'com.moolsocial.app' -and [string]$coldStart.versionCode -ceq [string]$candidateState.candidate.versionCode) -Message 'Play-installed package or version does not match the candidate.'
  Assert-C30WRuntime -Condition ([string]$coldStart.installerPackage -ceq 'com.android.vending') -Message 'Play installer identity is not exact.'
  Assert-C30WRuntime -Condition (-not [string]::IsNullOrWhiteSpace([string]$coldStart.firstScreenName) -and [bool]$coldStart.coldStartInteractive -and -not [bool]$coldStart.blankHierarchy -and -not [bool]$coldStart.timeout) -Message 'candidate did not render a named interactive first screen.'
  Assert-C30WRuntime -Condition ([int]$coldStart.flutterFatalErrorCount -eq 0 -and [int]$coldStart.androidRuntimeFatalCount -eq 0 -and [int]$coldStart.anrCount -eq 0 -and [bool]$coldStart.appProcessErrorScanPassed) -Message 'candidate cold start contains a fatal error, ANR, or failed process scan.'
  Assert-C30WRuntime -Condition ([bool]$coldStart.artifactRelationshipProved -and [bool]$coldStart.inPlaceUpdateProved) -Message 'Play artifact relationship or in-place update proof is missing.'
}

Write-Output "C30W release-runtime gate passed: phase=$Phase; five define names; safe first frame; future Play-installed fatal/blank rejection active."
