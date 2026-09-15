[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$StatePath,
  [switch]$VerifyLiveSource
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
if (-not $StatePath) {
  $StatePath = Join-Path $root 'config\social-runtime-deployment-map-r60-92.json'
}

function Assert-DeploymentMap([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "Social runtime deployment map rejected: $Message" }
}

function Assert-ExactSet($Actual, [string[]]$Expected, [string]$Label) {
  $actualValues = @($Actual | ForEach-Object { [string]$_ })
  Assert-DeploymentMap (
    $actualValues.Count -eq $Expected.Count -and
    (@($actualValues | Sort-Object) -join '|') -ceq
      (@($Expected | Sort-Object) -join '|')
  ) "$Label changed."
}

function Get-ExactStringSetSha256($Values, [string]$Label) {
  $items = @($Values | ForEach-Object { [string]$_ })
  Assert-DeploymentMap ($items.Count -gt 0) "$Label is empty."
  $seen = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
  )
  foreach ($item in $items) {
    Assert-DeploymentMap (
      -not [string]::IsNullOrWhiteSpace($item) -and $seen.Add($item)
    ) "$Label is empty or duplicated."
  }
  $sorted = [string[]]$items.Clone()
  [Array]::Sort($sorted, [StringComparer]::Ordinal)
  $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($sorted -join "`n"))
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
  } finally {
    $sha.Dispose()
  }
}

$statePathFull = [IO.Path]::GetFullPath($StatePath)
Assert-DeploymentMap (Test-Path -LiteralPath $statePathFull -PathType Leaf) `
  'state file is missing.'
$state = Get-Content -LiteralPath $statePathFull -Raw | ConvertFrom-Json -Depth 100
Assert-DeploymentMap ($state.schema -ceq 'moolsocial_social_runtime_deployment_map_v1') `
  'schema changed.'
Assert-DeploymentMap (
  $state.readinessContractId -ceq 'MOOLSOCIAL-PRE-APK-READINESS-001' -and
  $state.projectId -ceq 'moolsocial-dev-503018' -and
  $state.region -ceq 'asia-south1' -and
  $state.scope -ceq 'five_live_Social_Cloud_Functions_only'
) 'candidate or project scope changed.'
Assert-DeploymentMap (
  $state.cloudWriteAuthorized -eq $false -and
  [int]$state.cloudWriteActionCount -eq 0
) 'a cloud write occurred or was authorized during preflight.'
Assert-DeploymentMap (
  $state.nodeVerification.requiredVersion -ceq '22.23.2' -and
  $state.nodeVerification.archiveSha256 -ceq
    '1177B4137BA5ADAA56354AE40F1080C7450E8AE09CECB47DA459D1C52AC99F97' -and
  $state.nodeVerification.npmCiPassed -eq $true -and
  $state.nodeVerification.typecheckPassed -eq $true -and
  [int]$state.nodeVerification.compiledTestCount -eq 601 -and
  [int]$state.nodeVerification.compiledTestPassedCount -eq 601 -and
  $state.nodeVerification.state -ceq 'verified_pass'
) 'Node 22 backend verification is incomplete.'
Assert-DeploymentMap (
  [int]$state.dependencyAudit.productionHigh -eq 0 -and
  [int]$state.dependencyAudit.productionCritical -eq 0 -and
  [int]$state.dependencyAudit.productionModerate -eq 7 -and
  [int]$state.dependencyAudit.underlyingAdvisoryCount -eq 1 -and
  $state.dependencyAudit.applicationDirectImport -eq $false -and
  $state.dependencyAudit.affectedOperationReachable -eq $false -and
  $state.dependencyAudit.automaticFixAllowed -eq $false -and
  $state.dependencyAudit.reportedFixRequiresUnsafeMajorDowngrade -eq $true -and
  $state.dependencyAudit.apkBinaryImpact -eq $false
) 'dependency-risk classification changed.'

$expectedFunctions = @(
  'moolSocialPublicAuth',
  'youtubeProvider',
  'moolSocialChat',
  'moolSocialContent',
  'youtubeOAuthCallback'
)
$functions = @($state.functions)
Assert-DeploymentMap ($functions.Count -eq 5) 'exactly five functions are required.'
Assert-ExactSet ($functions | ForEach-Object { $_.name }) $expectedFunctions `
  'function inventory'
$expectedGeneration = @{
  moolSocialPublicAuth = '1787604612758485'
  youtubeProvider = '1787650698264594'
  moolSocialChat = '1787563879877125'
  moolSocialContent = '1786645411348698'
  youtubeOAuthCallback = '1787579502212873'
}
$expectedModuleCount = @{
  moolSocialPublicAuth = 37
  youtubeProvider = 31
  moolSocialChat = 6
  moolSocialContent = 4
  youtubeOAuthCallback = 32
}
$expectedModulePathSetSha256 = @{
  moolSocialPublicAuth = '687612C8055F32B580A1F34641265C7DC5A231E7A69A6059530757A24C01A0EB'
  youtubeProvider = 'CC880CECFEEDA9CA0233BC84E1E7DDBEC28EF30BD965BDF73BCC8A836AA941B4'
  moolSocialChat = '68A46041C05714C59BF424BE8AF28F2F28035C0707E68A57F7EF3447C5FD7A17'
  moolSocialContent = '78CFE140B4A09398EBAF3413DCB5CDE42D6319E862592CC705006C68F8C9A61A'
  youtubeOAuthCallback = '6F5A6357DDCD112BE99FA7FBF38B657D644822FEAC982FF97E5453E4764D3FF7'
}
$expectedMarkerSetSha256 = @{
  moolSocialPublicAuth = 'D928B1C11351B7A92A41492FE0DB697F2645ED9C9AD9BF46D350A9E45901C42F'
  youtubeProvider = 'AF71D034AD76062439DEB24DEA634D33679B2D000170F4C21B6C9DEA36D70C4E'
  moolSocialChat = 'E32CD43F74D4954971D4200E6E6F065D615F845B55C32F73372267318EDA9114'
  moolSocialContent = '20D71D35B49B0C73034EAA82ABE7BF9B2992C422BB2DC34B9E50F160C2C7BCCC'
  youtubeOAuthCallback = 'A12B0B6A99B70F4156354EAD31F698EE30C0144EA1C4B6DF3526560D55925980'
}
$expectedSecretBindingCount = @{
  moolSocialPublicAuth = 9
  youtubeProvider = 5
  moolSocialChat = 0
  moolSocialContent = 0
  youtubeOAuthCallback = 5
}
foreach ($function in $functions) {
  $name = [string]$function.name
  $moduleSetSha256 = Get-ExactStringSetSha256 `
    $function.requiredModules "$name required modules"
  $markerSetSha256 = Get-ExactStringSetSha256 `
    $function.requiredContractMarkers "$name required markers"
  Assert-DeploymentMap (
    $moduleSetSha256 -ceq $expectedModulePathSetSha256[$name] -and
    $moduleSetSha256 -ceq [string]$function.requiredModulePathSetSha256 -and
    $markerSetSha256 -ceq $expectedMarkerSetSha256[$name] -and
    $markerSetSha256 -ceq [string]$function.requiredContractMarkerSetSha256
  ) "$name attestation target set changed."
  Assert-DeploymentMap (
    $function.runtime -ceq 'nodejs22' -and
    $function.liveState -ceq 'ACTIVE' -and
    [int]$function.trafficPercent -eq 100 -and
    $function.source.object -ceq "$name/function-source.zip" -and
    $function.source.generation -ceq $expectedGeneration[$name] -and
    [string]$function.latestReadyRevision -cmatch '^[a-z0-9]+-[0-9]{5}-[a-z0-9]{3}$'
  ) "$name live source or traffic identity changed."
  Assert-DeploymentMap (
    [string]$function.sourceAudit.archiveSha256 -cmatch '^[0-9A-F]{64}$' -and
    $function.sourceAudit.indexSliceMatches -eq $true -and
    [int]$function.sourceAudit.requiredModuleCount -eq $expectedModuleCount[$name] -and
    $function.sourceAudit.requiredContractMarkersPresent -eq $true -and
    [int]$function.sourceAudit.privateCredentialEntryCount -eq 0 -and
    [int]$function.sourceAudit.riskyEntryCount -eq
      [int]$function.sourceAudit.dotenvEntryCount -and
    [int]$function.sourceAudit.dotenvEntryCount -ge 1 -and
    [int]$function.sourceAudit.dotenvEntryCount -le 2
  ) "$name source attestation is incomplete."
  $tupleRequired = $name -cin @('youtubeProvider', 'youtubeOAuthCallback')
  Assert-DeploymentMap (
    [int]$function.runtimeConfigurationAudit.timeoutSeconds -gt 0 -and
    [int]$function.runtimeConfigurationAudit.memoryMiB -in @(256, 512) -and
    [int]$function.runtimeConfigurationAudit.maxInstances -gt 0 -and
    [int]$function.runtimeConfigurationAudit.concurrency -gt 0 -and
    [int]$function.runtimeConfigurationAudit.secretBindingCount -eq
      $expectedSecretBindingCount[$name] -and
    $function.runtimeConfigurationAudit.serviceAccountMatchesExpected -eq $true -and
    $function.runtimeConfigurationAudit.resourceLimitsMatchExpected -eq $true -and
    $function.runtimeConfigurationAudit.acceptedNonSecretRuntimeTupleRequired -eq
      $tupleRequired -and
    (
      ($tupleRequired -and
        $function.runtimeConfigurationAudit.acceptedNonSecretRuntimeTupleMatches -eq $true) -or
      (-not $tupleRequired -and
        $null -eq $function.runtimeConfigurationAudit.acceptedNonSecretRuntimeTupleMatches)
    )
  ) "$name live runtime-configuration attestation is incomplete."
}

$preserve = @(
  'moolSocialPublicAuth',
  'moolSocialChat',
  'moolSocialContent'
)
Assert-ExactSet $state.deploymentPolicy.preserveLiveFunctions $preserve `
  'preserve-live inventory'
Assert-ExactSet $state.deploymentPolicy.approvedDeploymentAllowlist `
  @('youtubeProvider', 'youtubeOAuthCallback') 'preflight deployment allowlist'
Assert-ExactSet $state.deploymentPolicy.remainingHolds @(
  'final_integration_remote_exact',
  'explicit_founder_cloud_write_authority',
  'fresh_predeploy_live_readback'
) 'remaining deployment holds'
Assert-DeploymentMap (
  $state.deploymentPolicy.defaultDecision -ceq 'preserve' -and
  $state.deploymentPolicy.allowDeployWithoutExactSourceAudit -eq $false -and
  $state.deploymentPolicy.allowDeployWithAnyHighOrCriticalAdvisory -eq $false -and
  $state.deploymentPolicy.allowDeployWithFailedNode22Verification -eq $false -and
  $state.deploymentPolicy.allowDeployWithUnprovenMobileContract -eq $false -and
  $state.deploymentPolicy.deployNowAllowed -eq $false
) 'deployment policy no longer fails closed.'
foreach ($name in @('moolSocialChat', 'moolSocialContent')) {
  $function = @($functions | Where-Object { $_.name -ceq $name })[0]
  Assert-DeploymentMap (
    $function.decision -ceq 'preserve_live' -and
    [int]$function.sourceAudit.requiredModuleMatchCount -eq
      [int]$function.sourceAudit.requiredModuleCount -and
    @($function.sourceAudit.mismatchedModules).Count -eq 0 -and
    [string]$function.sourceAudit.state -cmatch '^verified_target_exact'
  ) "$name is not safe to preserve."
}

$publicAuth = @($functions | Where-Object {
  $_.name -ceq 'moolSocialPublicAuth'
})[0]
Assert-DeploymentMap (
  $publicAuth.decision -ceq 'preserve_live' -and
  $publicAuth.sourceAudit.state -ceq
    'verified_target_runtime_delta_unreachable_to_public_auth_routes' -and
  $publicAuth.sourceAudit.indexExact -eq $true -and
  [int]$publicAuth.sourceAudit.requiredModuleMatchCount -eq 34 -and
  $publicAuth.sourceAudit.mismatchedModuleSourceCommit -ceq
    '6d4d74354c7ce73fd41b23d394064c6b4607da9a' -and
  $publicAuth.sourceAudit.implementedModuleSourceCommit -ceq
    '62815b373edfe303fbc22491aeb0c3f6b74ae818' -and
  $publicAuth.sourceAudit.deltaClassification -ceq
    'atomic_quota_measurement_modules_not_reached_by_public_auth_routes'
) 'public-auth preservation classification changed.'
Assert-ExactSet $publicAuth.sourceAudit.mismatchedModules @(
  'lib/youtube/adapters.js',
  'lib/youtube/firestore_store.js',
  'lib/youtube/quota.js'
) 'public-auth mismatched-module inventory'

$provider = @($functions | Where-Object { $_.name -ceq 'youtubeProvider' })[0]
$callback = @($functions | Where-Object {
  $_.name -ceq 'youtubeOAuthCallback'
})[0]
Assert-DeploymentMap (
  $provider.sourceAudit.state -ceq 'verified_target_runtime_delta' -and
  $provider.sourceAudit.indexExact -eq $true -and
  [int]$provider.sourceAudit.requiredModuleMatchCount -eq 28 -and
  $provider.sourceAudit.mismatchedModuleSourceCommit -ceq
    '6d4d74354c7ce73fd41b23d394064c6b4607da9a' -and
  $provider.sourceAudit.implementedModuleSourceCommit -ceq
    '62815b373edfe303fbc22491aeb0c3f6b74ae818' -and
  $provider.sourceAudit.deltaClassification -ceq
    'split_quota_measurement_replaced_by_atomic_usage_and_measurement_transaction'
) 'provider runtime delta changed.'
Assert-DeploymentMap (
  $callback.sourceAudit.state -ceq 'verified_target_runtime_delta' -and
  $callback.sourceAudit.indexExact -eq $true -and
  [int]$callback.sourceAudit.requiredModuleMatchCount -eq 29 -and
  $callback.sourceAudit.mismatchedModuleSourceCommit -ceq
    '646cf6ffb69802ec3986c6ed5dc467183192e353' -and
  $callback.sourceAudit.implementedModuleSourceCommit -ceq
    '62815b373edfe303fbc22491aeb0c3f6b74ae818' -and
  $callback.sourceAudit.deltaClassification -ceq
    'pre_measurement_callback_replaced_by_atomic_usage_and_measurement_transaction'
) 'callback runtime delta changed.'
foreach ($function in @($provider, $callback)) {
  Assert-ExactSet $function.sourceAudit.mismatchedModules @(
  'lib/youtube/adapters.js',
  'lib/youtube/firestore_store.js',
  'lib/youtube/quota.js'
  ) "$($function.name) mismatched-module inventory"
  Assert-DeploymentMap (
    $function.mobileContractPreflight -ceq
      'passed_135_of_135_youtube_callback_auth_and_mobile_contract_tests' -and
    [int]$function.deploymentQualification.node22BackendTestsPassed -eq 601 -and
    [int]$function.deploymentQualification.focusedMobileTestsPassed -eq 135 -and
    $function.deploymentQualification.flutterAnalysisClean -eq $true -and
    $function.deploymentQualification.failureRecoveryCovered -eq $true -and
    $function.deploymentQualification.finalIntegrationRemoteExact -eq $false -and
    $function.deploymentQualification.freshPredeployLiveReadback -eq $false -and
    $function.deploymentQualification.explicitFounderCloudWriteAuthority -eq $false -and
    $function.decision -ceq
      'preflight_qualified_pending_final_integration_and_explicit_authority'
  ) "$($function.name) deployment admission is not preflight-qualified and held."
}
Assert-DeploymentMap (
  $state.finalState -ceq
    'preflight_mapped_two_deployments_qualified_cloud_write_held'
) 'final preflight state changed.'

if ($VerifyLiveSource) {
  $auditor = Join-Path $root `
    'scripts\audit-deployed-social-function-source-r60-92.ps1'
  Assert-DeploymentMap (Test-Path -LiteralPath $auditor -PathType Leaf) `
    'live source auditor is missing.'
  $auditRaw = (& $auditor -RepositoryRoot $root -DeploymentMapPath $statePathFull |
      Out-String)
  $audit = $auditRaw | ConvertFrom-Json -Depth 100
  Assert-DeploymentMap (
    $audit.schema -ceq 'moolsocial_deployed_social_source_audit_result_v1' -and
    [int]$audit.functionCount -eq 5 -and
    [int]$audit.cloudWriteActionCount -eq 0
  ) 'live source audit summary changed.'
  foreach ($result in @($audit.results)) {
    $mapped = @($functions | Where-Object { $_.name -ceq $result.name })[0]
    $dynamicIndexExact = [string]$result.indexSha256 -ceq
      [string]$result.localIndexSha256
    $dynamicMatches = @($result.modules | Where-Object { $_.matches }).Count
    $dynamicMismatches = @($result.modules | Where-Object {
      -not $_.matches
    } | ForEach-Object { [string]$_.path })
    Assert-DeploymentMap (
      $result.archiveSha256 -ceq $mapped.sourceAudit.archiveSha256 -and
      $dynamicIndexExact -eq $mapped.sourceAudit.indexExact -and
      $result.indexSliceMatches -eq $mapped.sourceAudit.indexSliceMatches -and
      @($result.modules).Count -eq [int]$mapped.sourceAudit.requiredModuleCount -and
      $dynamicMatches -eq [int]$mapped.sourceAudit.requiredModuleMatchCount -and
      $result.requiredContractMarkersPresent -eq
        $mapped.sourceAudit.requiredContractMarkersPresent -and
      [int]$result.dotenvEntryCount -eq
        [int]$mapped.sourceAudit.dotenvEntryCount -and
      [int]$result.riskyEntryCount -eq
        [int]$mapped.sourceAudit.riskyEntryCount -and
      [int]$result.privateCredentialEntryCount -eq 0 -and
      $result.liveIdentityMatches -eq $true -and
      $result.gitAttributionMatches -eq $true
    ) "$($result.name) live source differs from the machine map."
    Assert-DeploymentMap (
      [int]$result.runtimeConfiguration.secretBindingCount -eq
        [int]$mapped.runtimeConfigurationAudit.secretBindingCount -and
      $result.runtimeConfiguration.serviceAccountMatches -eq
        $mapped.runtimeConfigurationAudit.serviceAccountMatchesExpected -and
      $result.runtimeConfiguration.resourceLimitsMatch -eq
        $mapped.runtimeConfigurationAudit.resourceLimitsMatchExpected -and
      $result.runtimeConfiguration.acceptedNonSecretRuntimeTupleMatches -eq
        $mapped.runtimeConfigurationAudit.acceptedNonSecretRuntimeTupleMatches
    ) "$($result.name) live runtime configuration differs from the machine map."
    Assert-ExactSet $dynamicMismatches $mapped.sourceAudit.mismatchedModules `
      "$($result.name) live mismatched-module inventory"
  }
}

Write-Output (
  'Social runtime deployment map passed: functions=5; preserve=3; ' +
  'preflightAllowlist=2; node22Tests=601; mobileTests=135; cloudWrites=0; ' +
  "liveSource=$($VerifyLiveSource.IsPresent.ToString().ToLowerInvariant())."
)
