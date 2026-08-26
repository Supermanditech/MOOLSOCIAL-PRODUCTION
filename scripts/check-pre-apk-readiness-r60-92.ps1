[CmdletBinding()]
param(
  [string]$StatePath,

  [ValidateSet('CandidateReservation', 'PreauthorizationReady', 'BuildAuthorized')]
  [string]$Phase = 'CandidateReservation',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
if (-not $StatePath) {
  $StatePath = Join-Path $root 'config\pre-apk-readiness-r60-92.json'
}
$stateFile = [IO.Path]::GetFullPath($StatePath)
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-PreApk([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "R60.92 pre-APK readiness rejected: $Message"
  }
}

function Get-ExactNames($Value) {
  return @($Value.PSObject.Properties.Name)
}

function Assert-ExactNames($Value, [string[]]$Expected, [string]$Label) {
  $actual = @(Get-ExactNames $Value)
  Assert-PreApk (
    $actual.Count -eq $Expected.Count -and
    (@($actual | Sort-Object) -join '|') -ceq
      (@($Expected | Sort-Object) -join '|')
  ) "$Label schema changed."
}

function Get-RelativeOwner([string]$Path) {
  $resolved = [IO.Path]::GetFullPath($Path)
  Assert-PreApk (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) 'owner escaped the repository.'
  return $resolved.Substring($rootPrefix.Length).Replace('\', '/')
}

function Get-CanonicalTextSha256([string]$Path) {
  $text = [IO.File]::ReadAllText($Path)
  $canonical = $text.Replace("`r`n", "`n").Replace("`r", "`n")
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString(
      $sha.ComputeHash([Text.UTF8Encoding]::new($false).GetBytes($canonical))
    )).Replace('-', '')
  } finally {
    $sha.Dispose()
  }
}

function Assert-ExactStringSet($Actual, [string[]]$Expected, [string]$Label) {
  $actualValues = @($Actual | ForEach-Object { [string]$_ })
  Assert-PreApk (
    $actualValues.Count -eq $Expected.Count -and
    (@($actualValues | Sort-Object) -join '|') -ceq
      (@($Expected | Sort-Object) -join '|')
  ) "$Label changed."
}

Assert-PreApk (
  $stateFile.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
  (Test-Path -LiteralPath $stateFile -PathType Leaf)
) 'candidate state is missing or outside the repository.'

try { $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json }
catch { throw 'R60.92 pre-APK readiness rejected: candidate state JSON is invalid.' }

Assert-ExactNames $state @(
  'schemaVersion','contractId','state','candidate','predecessor','authority',
  'versionGate','integrationGate','sourceSeal','runtimeConfiguration',
  'dependencyGate','socialDeployment','preBuildGates','postBuildGates',
  'blockers','privateValuesEmitted'
) 'candidate state'
Assert-PreApk (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq 'MOOLSOCIAL-PRE-APK-READINESS-001' -and
  -not [bool]$state.privateValuesEmitted
) 'candidate state identity or privacy boundary changed.'

$socialDeployment = $state.socialDeployment
Assert-ExactNames $socialDeployment @(
  'state','mapPath','mapSha256','mapHashMode','eligibleDeployments',
  'preservedFunctions','coordinatedWindowFunctions',
  'actualDeploymentAuthorized','privateValuesEmitted'
) 'Social deployment'
$socialMapPath = [IO.Path]::GetFullPath(
  (Join-Path $root ([string]$socialDeployment.mapPath))
)
Assert-PreApk (
  [string]$socialDeployment.mapPath -ceq
    'config/social-runtime-deployment-map-r60-92.json' -and
  $socialMapPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
  (Test-Path -LiteralPath $socialMapPath -PathType Leaf) -and
  [string]$socialDeployment.mapHashMode -ceq 'canonical_utf8_lf_sha256' -and
  [string]$socialDeployment.mapSha256 -ceq
    (Get-CanonicalTextSha256 $socialMapPath) -and
  -not [bool]$socialDeployment.actualDeploymentAuthorized -and
  -not [bool]$socialDeployment.privateValuesEmitted
) 'Social deployment map path, hash mode, hash or authority changed.'
Assert-ExactStringSet $socialDeployment.eligibleDeployments @(
  'youtubeProvider','youtubeOAuthCallback'
) 'eligible Social deployments'
Assert-ExactStringSet $socialDeployment.preservedFunctions @(
  'moolSocialPublicAuth','moolSocialChat','moolSocialContent'
) 'preserved Social functions'
Assert-ExactStringSet $socialDeployment.coordinatedWindowFunctions @(
  'youtubeProvider','youtubeOAuthCallback'
) 'coordinated-window Social functions'

$candidate = $state.candidate
Assert-ExactNames $candidate @(
  'id','versionName','versionCode','packageName','buildMode','runtimeProfile',
  'finalIntegrationBranch','finalIntegrationHead','artifactDirectory','artifactName'
) 'candidate'
Assert-PreApk (
  [string]$candidate.id -ceq 'UAW-R60.92-SOCIAL-RUNTIME-CONSOLIDATED-APK' -and
  [string]$candidate.versionName -ceq '1.0.0-r60.92' -and
  [string]$candidate.versionCode -ceq '2026082692' -and
  [string]$candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$candidate.buildMode -ceq 'release' -and
  [string]$candidate.runtimeProfile -ceq 'PublicAuthSideloadPreflight' -and
  [string]$candidate.finalIntegrationBranch -ceq
    'integration/moolsocial/social-runtime-share-v5-20260826' -and
  [string]$candidate.artifactDirectory -ceq
    'artifacts/quality/uaw-r60-92-social-runtime-consolidated-apk-20260826-01' -and
  [string]$candidate.artifactName -ceq
    'uaw-r60.92-social-runtime-consolidated-apk-device-review-release.apk'
) 'candidate identity, version, package, mode or artifact reservation changed.'

$predecessor = $state.predecessor
Assert-ExactNames $predecessor @(
  'versionName','versionCode','packageName','sourceCommit','apkSha256','preserved'
) 'predecessor'
Assert-PreApk (
  [string]$predecessor.versionName -ceq '1.0.0-r60.91' -and
  [string]$predecessor.versionCode -ceq '2026082591' -and
  [string]$predecessor.packageName -ceq 'com.moolsocial.app' -and
  [string]$predecessor.sourceCommit -cmatch '^[0-9a-f]{40}$' -and
  [string]$predecessor.apkSha256 -cmatch '^[0-9A-F]{64}$' -and
  [bool]$predecessor.preserved
) 'installed predecessor identity or preservation changed.'

Assert-PreApk (
  [string]$candidate.versionName -cmatch '^1[.]0[.]0-r60[.]([0-9]+)$'
) 'candidate version name is malformed.'
$candidateOrdinal = [int]$Matches[1]
Assert-PreApk (
  [string]$predecessor.versionName -cmatch '^1[.]0[.]0-r60[.]([0-9]+)$'
) 'predecessor version name is malformed.'
$predecessorOrdinal = [int]$Matches[1]
Assert-PreApk (
  $candidateOrdinal -eq 92 -and
  $predecessorOrdinal -eq 91 -and
  $candidateOrdinal -gt $predecessorOrdinal
) 'candidate version is not the exact monotonic successor.'
Assert-PreApk (
  [string]$candidate.versionCode -cmatch '^20260826[0-9]{2}$' -and
  [Int64]$candidate.versionCode -gt [Int64]$predecessor.versionCode
) 'candidate versionCode is not date-bound and strictly monotonic.'

$versionGate = $state.versionGate
Assert-ExactNames $versionGate @(
  'state','candidateNumber','predecessorNumber','versionCodeDatePrefix',
  'allowedIdentityOwners'
) 'version gate'
$allowedIdentityOwners = @($versionGate.allowedIdentityOwners | ForEach-Object {
  [string]$_
})
Assert-PreApk (
  [string]$versionGate.state -ceq 'passed' -and
  [int]$versionGate.candidateNumber -eq 92 -and
  [int]$versionGate.predecessorNumber -eq 91 -and
  [string]$versionGate.versionCodeDatePrefix -ceq '20260826' -and
  (@($allowedIdentityOwners | Sort-Object) -join '|') -ceq
    (@(
      'config/pre-apk-readiness-r60-92.json',
      'config/runtime/moolsocial-production-runtime-tickets-20260825.json'
    ) | Sort-Object) -join '|'
) 'version reservation evidence changed.'

$identityValues = @(
  [string]$candidate.id,
  [string]$candidate.versionName,
  [string]$candidate.versionCode
)
$configRoot = Join-Path $root 'config'
foreach ($identityValue in $identityValues) {
  $matchingOwners = @()
  foreach ($jsonFile in @(Get-ChildItem -LiteralPath $configRoot -Filter '*.json' `
      -File -Recurse)) {
    $text = Get-Content -Raw -LiteralPath $jsonFile.FullName
    if ($text.Contains($identityValue, [StringComparison]::Ordinal)) {
      $matchingOwners += Get-RelativeOwner $jsonFile.FullName
    }
  }
  Assert-PreApk (
    (@($matchingOwners | Sort-Object -Unique) -join '|') -ceq
      (@($allowedIdentityOwners | Sort-Object) -join '|')
  ) "candidate identity '$identityValue' is missing, duplicated or reused."
}

$authority = $state.authority
Assert-ExactNames $authority @(
  'preApkPreparationAuthorized','buildAuthorized','oneBuildAuthorizationConsumed',
  'buildCount','cloudDeploymentAuthorized','cloudDeploymentCount',
  'installAuthorized','installCount','playUploadAuthorized','playUploadCount',
  'oppoMutationAuthorized','secretValueAccessAuthorized'
) 'authority'
Assert-PreApk (
  [bool]$authority.preApkPreparationAuthorized -and
  [int]$authority.buildCount -eq 0 -and
  [int]$authority.cloudDeploymentCount -eq 0 -and
  [int]$authority.installCount -eq 0 -and
  [int]$authority.playUploadCount -eq 0 -and
  -not [bool]$authority.oneBuildAuthorizationConsumed -and
  -not [bool]$authority.cloudDeploymentAuthorized -and
  -not [bool]$authority.installAuthorized -and
  -not [bool]$authority.playUploadAuthorized -and
  -not [bool]$authority.oppoMutationAuthorized -and
  -not [bool]$authority.secretValueAccessAuthorized
) 'pre-APK authority counts or held actions changed.'

if ($Phase -cin @('CandidateReservation', 'PreauthorizationReady')) {
  Assert-PreApk (-not [bool]$authority.buildAuthorized) `
    'build authority must remain closed during preparation.'
} else {
  Assert-PreApk (
    [bool]$authority.buildAuthorized -and
    -not [bool]$authority.oneBuildAuthorizationConsumed -and
    [int]$authority.buildCount -eq 0
  ) 'one unused founder-authorized build is not recorded.'
}

$artifactPath = [IO.Path]::GetFullPath(
  (Join-Path $root (
    [string]$candidate.artifactDirectory + '/' + [string]$candidate.artifactName
  ))
)
Assert-PreApk (
  $artifactPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
) 'reserved APK path escaped the repository.'
Assert-PreApk (-not (Test-Path -LiteralPath $artifactPath)) `
  'reserved APK already exists before the single authorized build.'

$postBuildIds = @($state.postBuildGates | ForEach-Object { [string]$_.id })
Assert-PreApk (
  $postBuildIds.Count -eq 16 -and
  @($postBuildIds | Select-Object -Unique).Count -eq $postBuildIds.Count
) 'post-build gate inventory is incomplete or duplicated.'
Assert-PreApk (
  @($state.postBuildGates | Where-Object { [string]$_.state -cne 'pending' }).Count -eq 0
) 'post-build evidence cannot pass before an authorized APK exists.'

if ($Phase -cin @('PreauthorizationReady', 'BuildAuthorized')) {
  $expectedState = if ($Phase -ceq 'BuildAuthorized') {
    'one_build_authorized'
  } else {
    'preauthorization_ready'
  }
  Assert-PreApk ([string]$state.state -ceq $expectedState) `
    "candidate state is not '$expectedState'."
  $pendingPreBuild = @($state.preBuildGates | Where-Object {
    [string]$_.state -cne 'passed'
  })
  Assert-PreApk ($pendingPreBuild.Count -eq 0) `
    'one or more mandatory pre-build gates are not passed.'
  Assert-PreApk (
    [string]$candidate.finalIntegrationHead -cmatch '^[0-9a-f]{40}$' -and
    [string]$state.integrationGate.state -ceq 'passed' -and
    [string]$state.sourceSeal.state -ceq 'passed' -and
    [string]$state.sourceSeal.manifestSha256 -cmatch '^[0-9A-F]{64}$' -and
    [int]$state.sourceSeal.fileCount -gt 0 -and
    [string]$state.sourceSeal.cycle1 -ceq 'passed' -and
    [string]$state.sourceSeal.cycle2 -ceq 'passed' -and
    [string]$state.runtimeConfiguration.state -ceq 'passed_sanitized_binding' -and
    [bool]$state.runtimeConfiguration.exactNonSecretDefinesBound -and
    [bool]$state.runtimeConfiguration.requiredPrivateDefineNamesBoundWithoutValues -and
    [bool]$state.runtimeConfiguration.mixedClientServerContractPrevented -and
    -not [bool]$state.runtimeConfiguration.privateValuesEmitted -and
    [string]$state.dependencyGate.state -ceq 'passed' -and
    [bool]$state.dependencyGate.wrapperQualified -and
    [bool]$state.dependencyGate.postBuildPluginIntegrityQualified -and
    [string]$state.socialDeployment.state -ceq 'passed_deploy_map_held' -and
    [string]$state.socialDeployment.mapSha256 -cmatch '^[0-9A-F]{64}$' -and
    -not [bool]$state.socialDeployment.actualDeploymentAuthorized -and
    -not [bool]$state.socialDeployment.privateValuesEmitted
  ) 'sealed integration, source, runtime, dependency or Social deployment proof is incomplete.'
  if ($Phase -ceq 'PreauthorizationReady') {
    Assert-PreApk (
      @($state.blockers).Count -eq 1 -and
      [string]$state.blockers[0] -ceq 'one_build_authority_founder_held'
    ) 'preauthorization readiness has an unresolved blocker beyond founder build authority.'
  } else {
    Assert-PreApk (@($state.blockers).Count -eq 0) `
      'one-build authorization cannot retain a preparation blocker.'
  }
}

Write-Output (
  'R60.92 pre-APK readiness passed: ' +
  "phase=$Phase; candidate=$($candidate.id); version=$($candidate.versionName); " +
  "versionCode=$($candidate.versionCode); buildAuthorized=$($authority.buildAuthorized)."
)
