[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$StatePath,
  [ValidateSet('Prepared', 'RemoteReady', 'Recovery', 'Completed', 'Contained')]
  [string]$Phase = 'Prepared'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) {
  $StatePath = Join-Path $root `
    'config\social-runtime-deployment-execution-r60-92.json'
}
$statePathFull = [IO.Path]::GetFullPath($StatePath)

function Assert-Execution([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Social runtime deployment execution rejected: $Message"
  }
}

function Assert-ExactNames($Value, [string[]]$Expected, [string]$Label) {
  $actual = @($Value.PSObject.Properties.Name)
  Assert-Execution (
    $actual.Count -eq $Expected.Count -and
    (@($actual | Sort-Object) -join '|') -ceq
      (@($Expected | Sort-Object) -join '|')
  ) "$Label schema changed."
}

function Assert-ExactSet($Actual, [string[]]$Expected, [string]$Label) {
  $values = @($Actual | ForEach-Object { [string]$_ })
  Assert-Execution (
    $values.Count -eq $Expected.Count -and
    (@($values | Sort-Object) -join '|') -ceq
      (@($Expected | Sort-Object) -join '|')
  ) "$Label changed."
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

function Get-RemoteBranchHead([string]$Branch) {
  Assert-Execution (
    $Branch -cmatch '^integration/moolsocial/[a-z0-9][a-z0-9-]{2,64}$'
  ) 'final integration branch is invalid.'
  $ref = 'refs/heads/' + $Branch
  $rows = @(& git -C $root ls-remote --exit-code --heads origin $ref 2>$null)
  Assert-Execution (
    $LASTEXITCODE -eq 0 -and $rows.Count -eq 1 -and
    [string]$rows[0] -cmatch '^([0-9a-f]{40})[\t ]+refs/heads/'
  ) 'final integration remote readback failed.'
  return ([string]$rows[0] -split '\s+')[0]
}

Assert-Execution (
  $statePathFull.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
  (Test-Path -LiteralPath $statePathFull -PathType Leaf)
) 'execution state is missing or outside the repository.'
$state = Get-Content -LiteralPath $statePathFull -Raw | ConvertFrom-Json -Depth 100
Assert-ExactNames $state @(
  'schema','contractId','state','projectId','region','readinessContractId',
  'source','eligibility','runtimePackage','plan','predecessors',
  'secretBindingPosture','predeployReadback','authority','rollback','postdeploy',
  'result','blockers','privateValuesEmitted'
) 'execution state'
Assert-Execution (
  $state.schema -ceq 'moolsocial_social_runtime_deployment_execution_v1' -and
  $state.contractId -ceq 'MOOLSOCIAL-SOCIAL-RUNTIME-DEPLOYMENT-R60-92-001' -and
  $state.projectId -ceq 'moolsocial-dev-503018' -and
  $state.region -ceq 'asia-south1' -and
  $state.readinessContractId -ceq 'MOOLSOCIAL-PRE-APK-READINESS-001' -and
  $state.privateValuesEmitted -eq $false
) 'execution identity, scope or privacy changed.'

$source = $state.source
Assert-ExactNames $source @(
  'implementationCommit','backendFunctionsTree','finalIntegrationBranch',
  'finalIntegrationHead','finalIntegrationRemoteHead','finalIntegrationRemoteExact',
  'finalIntegrationBackendTreeMatches','localHeadMustMatch',
  'cleanWorktreeRequired','sourceSealPath','sourceSealSha256',
  'sourceSealFileCount','sourceSealVerifierPath','sourceSealVerifierSha256',
  'packageJsonSha256','packageLockSha256',
  'firebaseJsonSha256','remote'
) 'source'
Assert-Execution (
  $source.implementationCommit -ceq
    '62815b373edfe303fbc22491aeb0c3f6b74ae818' -and
  $source.backendFunctionsTree -ceq
    'd1a5cac92a90ab00af6cde793e1cd7c1ab0cf3cb' -and
  $source.finalIntegrationBranch -ceq
    'integration/moolsocial/social-runtime-share-v5-20260826' -and
  $source.localHeadMustMatch -eq $true -and
  $source.cleanWorktreeRequired -eq $true -and
  $source.packageJsonSha256 -ceq
    '110342F98559FB18CDC28ACC91C730FF83AF3C9406FF19FE13AB21F052E89C25' -and
  $source.packageLockSha256 -ceq
    '82CD01AC25C5463E2D2DDF490D179F7AE3149ABB8235CCAB2C5196EB64A887BC' -and
  $source.firebaseJsonSha256 -ceq
    '6F87A11EA15E47F3A3E09E6A756B550787D3DE3E445690CAF550027A9F724E94' -and
  $source.remote -ceq 'origin'
) 'implementation source identity changed.'
$implementationTree = @(& git -C $root rev-parse (
    [string]$source.implementationCommit + ':backend/functions'
  ) 2>$null)
Assert-Execution (
  $LASTEXITCODE -eq 0 -and $implementationTree.Count -eq 1 -and
  [string]$implementationTree[0] -ceq [string]$source.backendFunctionsTree
) 'implementation backend tree is unavailable or changed.'
Assert-Execution (
  (Get-CanonicalTextSha256 (Join-Path $root 'backend\functions\package.json')) -ceq
    [string]$source.packageJsonSha256 -and
  (Get-CanonicalTextSha256 (Join-Path $root 'backend\functions\package-lock.json')) -ceq
    [string]$source.packageLockSha256 -and
  (Get-CanonicalTextSha256 (Join-Path $root 'firebase.json')) -ceq
    [string]$source.firebaseJsonSha256
) 'package, lockfile or Firebase configuration changed.'

$eligibility = $state.eligibility
Assert-ExactNames $eligibility @(
  'mapPath','mapHashMode','mapSha256','nodeVersion','nodeArchiveSha256',
  'node22BackendTestCount','focusedBackendTestCount','focusedMobileTestCount',
  'flutterAnalysisClean','independentAudit'
) 'eligibility'
$mapPath = [IO.Path]::GetFullPath((Join-Path $root ([string]$eligibility.mapPath)))
Assert-Execution (
  $eligibility.mapPath -ceq 'config/social-runtime-deployment-map-r60-92.json' -and
  $mapPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
  (Test-Path -LiteralPath $mapPath -PathType Leaf) -and
  $eligibility.mapHashMode -ceq 'canonical_utf8_lf_sha256' -and
  $eligibility.mapSha256 -ceq (Get-CanonicalTextSha256 $mapPath) -and
  $eligibility.nodeVersion -ceq '22.23.2' -and
  $eligibility.nodeArchiveSha256 -ceq
    '1177B4137BA5ADAA56354AE40F1080C7450E8AE09CECB47DA459D1C52AC99F97' -and
  [int]$eligibility.node22BackendTestCount -eq 601 -and
  [int]$eligibility.focusedBackendTestCount -eq 42 -and
  [int]$eligibility.focusedMobileTestCount -eq 135 -and
  $eligibility.flutterAnalysisClean -eq $true -and
  $eligibility.independentAudit -ceq 'GO'
) 'eligibility evidence changed.'
& (Join-Path $root 'scripts\check-social-runtime-deployment-map-r60-92.ps1') `
  -RepositoryRoot $root -StatePath $mapPath | Out-Null

$runtimePackage = $state.runtimePackage
Assert-ExactNames $runtimePackage @(
  'packageEngine','firebaseCliVersion','gcloudCliVersion','cliAccountSha256',
  'firebaseAndGcloudAccountsMustMatch','runtimeKeySetSha256',
  'acceptedRuntimeTupleSha256','runtimeMaterializationSha256',
  'runtimeFileExactKeyCount','runtimeFileProvisioned',
  'privateSecretNamesPresent','privateValuesEmitted'
) 'runtime package'
Assert-Execution (
  $runtimePackage.packageEngine -ceq '22' -and
  [string]$runtimePackage.firebaseCliVersion -ceq '15.5.1' -and
  [string]$runtimePackage.gcloudCliVersion -ceq '579.0.0' -and
  $runtimePackage.cliAccountSha256 -ceq
    '744048CF9B5D2CD96798FBF5BBC233E4EE37AAB674ABFE8B2BFC2E7D18E22512' -and
  $runtimePackage.firebaseAndGcloudAccountsMustMatch -eq $true -and
  $runtimePackage.runtimeKeySetSha256 -ceq
    '54921B4382F45DEA5C40BBB45B94C9879C10BB0052D53D6236E2849AA0657314' -and
  $runtimePackage.acceptedRuntimeTupleSha256 -ceq
    '406BACAD2C968FE67763CB247D74DD87C989B77BEE8C46D588BDFAB81F502ABF' -and
  $runtimePackage.runtimeMaterializationSha256 -ceq
    '99F4AF35AE7E6A57EB7194297D3134F913D733B83B6D7CA512547EAC7020C140' -and
  [int]$runtimePackage.runtimeFileExactKeyCount -eq 4 -and
  $runtimePackage.privateSecretNamesPresent -eq $false -and
  $runtimePackage.privateValuesEmitted -eq $false
) 'runtime package contract changed.'

$plan = $state.plan
Assert-ExactSet $plan.deployFunctions @(
  'youtubeProvider','youtubeOAuthCallback'
) 'deploy function allowlist'
Assert-ExactSet $plan.preserveFunctions @(
  'moolSocialPublicAuth','moolSocialChat','moolSocialContent'
) 'preserved function inventory'
Assert-Execution (
  $plan.firebaseOnlyTarget -ceq
    'functions:provider:youtubeProvider,functions:provider:youtubeOAuthCallback' -and
  $plan.acceptedNonSecretRuntimeTupleRequired -eq $true -and
  [int]$plan.requiredSecretBindingCountPerDeployedFunction -eq 5 -and
  $plan.noInvokerIamCheckPostureRestoreRequired -eq $true -and
  [int]$plan.maximumMetadataRestoreCommandCount -eq 2 -and
  [int]$plan.maximumRollbackTrafficCommandCount -eq 2 -and
  $plan.actualSecretValuesReadOrEmitted -eq $false
) 'deploy target, runtime tuple or secret boundary changed.'

$expectedPredecessors = @{
  youtubeProvider = @('youtubeprovider','youtubeprovider-00049-kxt','1787650698264594',$true)
  youtubeOAuthCallback = @('youtubeoauthcallback','youtubeoauthcallback-00037-5rz','1787579502212873',$true)
  moolSocialPublicAuth = @('moolsocialpublicauth','moolsocialpublicauth-00004-ney','1787604612758485',$false)
  moolSocialChat = @('moolsocialchat','moolsocialchat-00003-zuz','1787563879877125',$false)
  moolSocialContent = @('moolsocialcontent','moolsocialcontent-00005-lep','1786645411348698',$false)
}
$expectedArchiveSha256 = @{
  youtubeProvider = '56E6176B19B17DBB8D6CEA8E0616B736822B0E5685A62C530911FC8E4378D219'
  youtubeOAuthCallback = '446F1A979E234E0663DD55291EB91398489F23F4F8224C8F6911045F2A9A760D'
  moolSocialPublicAuth = '41A11C26A6D95FDC390F0B052E574C13293E93AF9287148FC4A5BD7473C724FB'
  moolSocialChat = '7D5E82703094A558394E146268AB3D248595E2A8CABB063360F0622E54134C87'
  moolSocialContent = 'B1D0C6C0A31E6E504DD82B6CBE4C7DC6C34400CB5EE4523653D5CDD7C5EC7D8D'
}
$expectedServiceAccountSha256 = @{
  youtubeProvider = '0C5E3C5B4C432F20FA67E3D45FAB59357CD038100DA44001EC1E9A41B8D2237C'
  youtubeOAuthCallback = '0C5E3C5B4C432F20FA67E3D45FAB59357CD038100DA44001EC1E9A41B8D2237C'
  moolSocialPublicAuth = '4B738FF7B8094BE68AD7A28749961F3EACEF5782D171843675877689A76BE3D7'
  moolSocialChat = 'DDE17BEB5BC0B0A1759198C3C94262BADEE1CC469405C85CC874018E495866FC'
  moolSocialContent = 'DDE17BEB5BC0B0A1759198C3C94262BADEE1CC469405C85CC874018E495866FC'
}
$expectedSecretSetSha256 = @{
  youtubeProvider = 'F844B3DF3063561D7C878943D5E5FD38A5DDEDB5721A26F33B7065F9D4E64210'
  youtubeOAuthCallback = 'F844B3DF3063561D7C878943D5E5FD38A5DDEDB5721A26F33B7065F9D4E64210'
  moolSocialPublicAuth = 'DB377A29905B1407352592D34948FFDD6C9394635C068A4DA692A34BC029989A'
  moolSocialChat = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
  moolSocialContent = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
}
$expectedRuntimeFingerprintSha256 = @{
  youtubeProvider = '4EC1A5B83BBBB9E63F508141891B763103BB30CF3D9DDCBAC31D8AB01A58FE94'
  youtubeOAuthCallback = '39D87C04A8DB465EF24EDAAF13DB76EB499D29D8A742DE0611DAD5BA839F76EE'
  moolSocialPublicAuth = '468CC019A64F22ECC25A7E5ED0064E802110346C93D0BA332795007229677AFC'
  moolSocialChat = '40F344EE98F565BB80E3164028085CDF94EFDDE3C1B26A65C7B787D50AC2F0D1'
  moolSocialContent = 'EC5E0A51C74B8A28312E39C10513C536BADAEF0CDC23843D7E35BB573FC11204'
}
$expectedResource = @{
  youtubeProvider = @(120,512,1,1,5)
  youtubeOAuthCallback = @(120,512,1,1,5)
  moolSocialPublicAuth = @(45,256,5,10,9)
  moolSocialChat = @(60,256,4,40,0)
  moolSocialContent = @(120,512,4,20,0)
}
$predecessors = @($state.predecessors)
Assert-ExactSet ($predecessors | ForEach-Object { $_.function }) `
  @($expectedPredecessors.Keys) 'predecessor function inventory'
$secretPosture = @($state.secretBindingPosture)
Assert-ExactSet ($secretPosture | ForEach-Object { $_.function }) `
  @($expectedPredecessors.Keys) 'secret-binding posture inventory'
$expectedBindingResourceSetSha256 = @{
  youtubeProvider = '98C9EC33C1631557E24A3250E56551C21A1501B29A4EFDD3BBA5F7C45A1DAFD7'
  youtubeOAuthCallback = '98C9EC33C1631557E24A3250E56551C21A1501B29A4EFDD3BBA5F7C45A1DAFD7'
  moolSocialPublicAuth = 'D533156DFD6FFDE9BF370FE6B56B7AE2EF0DB3EA4F98F6DB83DA79A8C48808CE'
  moolSocialChat = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
  moolSocialContent = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
}
foreach ($posture in $secretPosture) {
  Assert-ExactNames $posture @(
    'function','bindingResourceSetSha256','secretVolumeCount'
  ) "$($posture.function) secret posture"
  Assert-Execution (
    $posture.bindingResourceSetSha256 -ceq
      $expectedBindingResourceSetSha256[[string]$posture.function] -and
    [int]$posture.secretVolumeCount -eq 0
  ) "$($posture.function) secret resource binding changed."
}
foreach ($predecessor in $predecessors) {
  $expected = $expectedPredecessors[[string]$predecessor.function]
  $resource = $expectedResource[[string]$predecessor.function]
  Assert-ExactNames $predecessor @(
    'function','service','functionState','revision','sourceBucket','sourceObject',
    'sourceGeneration','sourceArchiveSha256','runtime','trafficPercent',
    'trafficTagCount','serviceAccountSha256','timeoutSeconds','memoryMiB',
    'maxInstances','concurrency','acceptedNonSecretTupleSha256',
    'secretBindingCount','secretBindingIdentitySetSha256',
    'invokerIamCheckDisabled','runtimeFingerprintSha256','deployTarget'
  ) "$($predecessor.function) predecessor"
  Assert-Execution (
    $predecessor.service -ceq $expected[0] -and
    $predecessor.revision -ceq $expected[1] -and
    $predecessor.sourceGeneration -ceq $expected[2] -and
    [bool]$predecessor.deployTarget -eq [bool]$expected[3] -and
    $predecessor.functionState -ceq 'ACTIVE' -and
    $predecessor.sourceBucket -ceq
      'gcf-v2-sources-760290687711-asia-south1' -and
    $predecessor.sourceObject -ceq "$($predecessor.function)/function-source.zip" -and
    $predecessor.sourceArchiveSha256 -ceq
      $expectedArchiveSha256[[string]$predecessor.function] -and
    $predecessor.runtime -ceq 'nodejs22' -and
    [int]$predecessor.trafficPercent -eq 100 -and
    [int]$predecessor.trafficTagCount -eq 0 -and
    $predecessor.serviceAccountSha256 -ceq
      $expectedServiceAccountSha256[[string]$predecessor.function] -and
    [int]$predecessor.timeoutSeconds -eq [int]$resource[0] -and
    [int]$predecessor.memoryMiB -eq [int]$resource[1] -and
    [int]$predecessor.maxInstances -eq [int]$resource[2] -and
    [int]$predecessor.concurrency -eq [int]$resource[3] -and
    [int]$predecessor.secretBindingCount -eq [int]$resource[4] -and
    $predecessor.secretBindingIdentitySetSha256 -ceq
      $expectedSecretSetSha256[[string]$predecessor.function] -and
    $predecessor.invokerIamCheckDisabled -eq $true -and
    $predecessor.runtimeFingerprintSha256 -ceq
      $expectedRuntimeFingerprintSha256[[string]$predecessor.function] -and
    (
      ([bool]$predecessor.deployTarget -and
        $predecessor.acceptedNonSecretTupleSha256 -ceq
          '406BACAD2C968FE67763CB247D74DD87C989B77BEE8C46D588BDFAB81F502ABF') -or
      (-not [bool]$predecessor.deployTarget -and
        $null -eq $predecessor.acceptedNonSecretTupleSha256)
    )
  ) "$($predecessor.function) predecessor changed."
}

$authority = $state.authority
Assert-ExactNames $authority @(
  'founderCloudDeploymentAuthorized','requiredConfirmation',
  'requiredConfirmationSha256','authorizedOnlyTargetSha256','authorizationId',
  'authorizedIntegrationHead','authorizedExecutionStateSha256','issuedAtUtc',
  'expiresAtUtc','maxDeployAttempts','authorizationNonceSha256',
  'attemptReceiptPath','oneUseAuthorizationConsumed','deployCommandCount',
  'rollbackTrafficCommandCount','cloudWriteActionCount',
  'maximumSuccessfulCloudWriteActionCount','maximumContainedCloudWriteActionCount',
  'secretValueAccessAuthorized'
) 'authority'
Assert-Execution (
  $authority.requiredConfirmation -ceq
    'AUTHORIZE_SOCIAL_R60_92_PROVIDER_CALLBACK_DEPLOY_ONCE' -and
  $authority.requiredConfirmationSha256 -ceq
    'C7FF7658197FB76DEC4F238AB5225AE79604D0AAF09741154E689F6E6B7C1B73' -and
  $authority.authorizedOnlyTargetSha256 -ceq
    'F3CC18CEB835C66B00E3DF4C314ECFDCF77A01E71D40AAF4B8BF277F6FA0542D' -and
  [int]$authority.maxDeployAttempts -eq 1 -and
  [int]$authority.maximumSuccessfulCloudWriteActionCount -eq 3 -and
  [int]$authority.maximumContainedCloudWriteActionCount -eq 5 -and
  $authority.attemptReceiptPath -ceq
    'backend/functions/.env.social-runtime-deploy-r60-92-attempt.local' -and
  $authority.secretValueAccessAuthorized -eq $false -and
  [int]$authority.deployCommandCount -ge 0 -and
  [int]$authority.rollbackTrafficCommandCount -ge 0 -and
  [int]$authority.cloudWriteActionCount -eq
    ([int]$authority.deployCommandCount +
      [int]$authority.rollbackTrafficCommandCount)
) 'authority identity, counts or secret boundary changed.'
$receiptPath = [IO.Path]::GetFullPath((Join-Path $root `
  ([string]$authority.attemptReceiptPath)))
Assert-Execution (
  $receiptPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
) 'attempt receipt escaped the repository.'
& git -C $root check-ignore --quiet -- ([string]$authority.attemptReceiptPath)
Assert-Execution ($LASTEXITCODE -eq 0) 'attempt receipt is not ignored.'

function Get-ValidatedReceipt {
  Assert-Execution (Test-Path -LiteralPath $receiptPath -PathType Leaf) `
    'attempt receipt is missing.'
  $receipt = Get-Content -LiteralPath $receiptPath -Raw |
    ConvertFrom-Json -Depth 100
  $issued = [DateTimeOffset]::MinValue
  $expires = [DateTimeOffset]::MinValue
  $updated = [DateTimeOffset]::MinValue
  $issuedValid = [DateTimeOffset]::TryParseExact(
    [string]$receipt.issuedAtUtc,
    'yyyy-MM-ddTHH:mm:ss.fffZ',
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal,
    [ref]$issued
  )
  $expiresValid = [DateTimeOffset]::TryParseExact(
    [string]$receipt.expiresAtUtc,
    'yyyy-MM-ddTHH:mm:ss.fffZ',
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal,
    [ref]$expires
  )
  $updatedValid = [DateTimeOffset]::TryParseExact(
    [string]$receipt.updatedAtUtc,
    'yyyy-MM-ddTHH:mm:ss.fffZ',
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal,
    [ref]$updated
  )
  $names = @($receipt.PSObject.Properties.Name)
  $expectedNames = @(
    'schema','state','projectId','region','integrationHead',
    'executionStateSha256','confirmationSha256','onlyTargetSha256',
    'authorizationId','authorizationNonceSha256','issuedAtUtc','expiresAtUtc',
    'maxDeployAttempts','firebaseDryRunCommandCount','firebaseDeployCommandCount',
    'rollbackTrafficCommandCount','metadataRestoreCommandCount',
    'cloudWriteActionCount','providerMetadataRestoreClaimed',
    'callbackMetadataRestoreClaimed','providerTrafficRestoreClaimed',
    'callbackTrafficRestoreClaimed','predecessorProviderRevision',
    'predecessorCallbackRevision','newProviderRevision',
    'newProviderSourceGeneration','newCallbackRevision',
    'newCallbackSourceGeneration','preservedFunctionFingerprintSetSha256',
    'postdeployRuntimeFingerprintSetSha256','rollbackTrafficFingerprintSetSha256',
    'updatedAtUtc','privateValuesEmitted'
  )
  Assert-Execution (
    $names.Count -eq $expectedNames.Count -and
    (@($names | Sort-Object) -join '|') -ceq
      (@($expectedNames | Sort-Object) -join '|') -and
    $receipt.schema -ceq 'moolsocial_social_runtime_deploy_attempt_v1' -and
    $receipt.projectId -ceq $state.projectId -and
    $receipt.region -ceq $state.region -and
    $receipt.integrationHead -ceq [string]$source.finalIntegrationHead -and
    $receipt.executionStateSha256 -ceq
      (Get-CanonicalTextSha256 $statePathFull) -and
    $receipt.confirmationSha256 -ceq
      [string]$authority.requiredConfirmationSha256 -and
    $receipt.onlyTargetSha256 -ceq
      [string]$authority.authorizedOnlyTargetSha256 -and
    [string]$receipt.authorizationId -cmatch
      '^SOCIAL-R60-92-[0-9]{8}T[0-9]{6}Z-[0-9A-F]{8}$' -and
    [string]$receipt.authorizationNonceSha256 -cmatch '^[0-9A-F]{64}$' -and
    [int]$receipt.maxDeployAttempts -eq 1 -and
    $issuedValid -and $expiresValid -and $updatedValid -and
    $expires -gt $issued -and ($expires - $issued).TotalMinutes -eq 15 -and
    $updated -ge $issued -and
    [int]$receipt.firebaseDryRunCommandCount -eq 1 -and
    [int]$receipt.firebaseDeployCommandCount -in @(0, 1) -and
    [int]$receipt.metadataRestoreCommandCount -in @(0, 1, 2) -and
    [int]$receipt.rollbackTrafficCommandCount -in @(0, 1, 2) -and
    [int]$receipt.cloudWriteActionCount -eq (
      [int]$receipt.firebaseDeployCommandCount +
      [int]$receipt.metadataRestoreCommandCount +
      [int]$receipt.rollbackTrafficCommandCount
    ) -and
    $receipt.predecessorProviderRevision -ceq
      [string](@($state.predecessors | Where-Object function -eq
        'youtubeProvider')[0].revision) -and
    $receipt.predecessorCallbackRevision -ceq
      [string](@($state.predecessors | Where-Object function -eq
        'youtubeOAuthCallback')[0].revision) -and
    $receipt.privateValuesEmitted -eq $false
  ) 'attempt receipt binding, schema, privacy or counts changed.'
  $metadataClaims = @(
    [bool]$receipt.providerMetadataRestoreClaimed,
    [bool]$receipt.callbackMetadataRestoreClaimed
  )
  $trafficClaims = @(
    [bool]$receipt.providerTrafficRestoreClaimed,
    [bool]$receipt.callbackTrafficRestoreClaimed
  )
  Assert-Execution (
    [int]$receipt.metadataRestoreCommandCount -eq
      @($metadataClaims | Where-Object { $_ }).Count -and
    [int]$receipt.rollbackTrafficCommandCount -eq
      @($trafficClaims | Where-Object { $_ }).Count
  ) 'attempt receipt per-target claims do not match counts.'
  if ($receipt.state -ceq 'attempt_claimed') {
    Assert-Execution (
      [int]$receipt.firebaseDeployCommandCount -eq 0 -and
      [int]$receipt.metadataRestoreCommandCount -eq 0 -and
      [int]$receipt.rollbackTrafficCommandCount -eq 0
    ) 'unstarted receipt contains external action claims.'
  } elseif ($receipt.state -ceq 'completed') {
    Assert-Execution (
      [int]$receipt.firebaseDeployCommandCount -eq 1 -and
      [int]$receipt.metadataRestoreCommandCount -eq 2 -and
      [int]$receipt.rollbackTrafficCommandCount -eq 0 -and
      [int]$receipt.cloudWriteActionCount -eq 3
    ) 'completed receipt action claims changed.'
  } elseif ($receipt.state -ceq 'failed_contained') {
    Assert-Execution (
      [int]$receipt.firebaseDeployCommandCount -eq 1 -and
      [int]$receipt.metadataRestoreCommandCount -eq 2 -and
      [int]$receipt.rollbackTrafficCommandCount -eq 2 -and
      [int]$receipt.cloudWriteActionCount -eq 5
    ) 'contained receipt action claims changed.'
  } elseif ($receipt.state -cnotin @(
      'deployment_started','containment_critical','abandoned_before_deploy'
    )) {
    throw 'Social runtime deployment execution rejected: receipt state is invalid.'
  }
  return $receipt
}
Assert-Execution (
  $state.rollback.strategy -ceq
    'restore_both_Cloud_Run_services_to_sealed_predecessor_revisions_at_100_percent' -and
  $state.rollback.requiredAfterAnyAttemptedUnverifiedDeploy -eq $true -and
  $state.rollback.sourceGuardImplemented -eq $true -and
  $state.rollback.fixtureTested -eq $true
  ) 'rollback strategy or proof changed.'

$result = $state.result
Assert-ExactNames $result @(
  'firebaseDryRunCommandCount','firebaseDeployCommandCount',
  'authorizedFunctionTargetCount','rollbackTrafficCommandCount',
  'metadataRestoreCommandCount',
  'newProviderRevision','newProviderSourceGeneration','newCallbackRevision',
  'newCallbackSourceGeneration','preservedFunctionFingerprintSetSha256',
  'postdeployRuntimeFingerprintSetSha256','rollbackTrafficFingerprintSetSha256'
) 'result'
Assert-Execution ([int]$result.authorizedFunctionTargetCount -eq 2) `
  'authorized target count changed.'

if ($Phase -eq 'Prepared') {
  Assert-Execution (
    $state.state -ceq 'prepared_authority_held' -and
    [string]::IsNullOrEmpty([string]$source.finalIntegrationHead) -and
    [string]::IsNullOrEmpty([string]$source.finalIntegrationRemoteHead) -and
    $source.finalIntegrationRemoteExact -eq $false -and
    $source.finalIntegrationBackendTreeMatches -eq $false -and
    [string]::IsNullOrEmpty([string]$source.sourceSealPath) -and
    [string]::IsNullOrEmpty([string]$source.sourceSealSha256) -and
    [int]$source.sourceSealFileCount -eq 0 -and
    [string]::IsNullOrEmpty([string]$source.sourceSealVerifierPath) -and
    [string]::IsNullOrEmpty([string]$source.sourceSealVerifierSha256) -and
    $state.predeployReadback.state -ceq 'pending' -and
    [string]::IsNullOrEmpty([string]$state.predeployReadback.observedAtUtc) -and
    $state.predeployReadback.allFiveLiveIdentitiesExact -eq $false -and
    $state.predeployReadback.twoTargetRuntimeConfigurationsExact -eq $false -and
    $state.predeployReadback.threePreservedFunctionsExact -eq $false -and
    $runtimePackage.runtimeFileProvisioned -eq $false -and
    $authority.founderCloudDeploymentAuthorized -eq $false -and
    [string]::IsNullOrEmpty([string]$authority.authorizationId) -and
    [string]::IsNullOrEmpty([string]$authority.authorizedIntegrationHead) -and
    [string]::IsNullOrEmpty([string]$authority.authorizedExecutionStateSha256) -and
    [string]::IsNullOrEmpty([string]$authority.issuedAtUtc) -and
    [string]::IsNullOrEmpty([string]$authority.expiresAtUtc) -and
    [string]::IsNullOrEmpty([string]$authority.authorizationNonceSha256) -and
    $authority.oneUseAuthorizationConsumed -eq $false -and
    [int]$authority.deployCommandCount -eq 0 -and
    [int]$authority.rollbackTrafficCommandCount -eq 0 -and
    $state.rollback.completed -eq $false -and
    $state.postdeploy.state -ceq 'pending' -and
    -not (Test-Path -LiteralPath $receiptPath) -and
    [int]$result.firebaseDryRunCommandCount -eq 0 -and
    [int]$result.firebaseDeployCommandCount -eq 0 -and
    [int]$result.rollbackTrafficCommandCount -eq 0 -and
    [int]$result.metadataRestoreCommandCount -eq 0
  ) 'prepared authority, integration, readback or action state changed.'
  Assert-ExactSet $state.blockers @(
    'final_remote_exact_integration_pending',
    'fresh_predeploy_live_readback_pending',
    'secure_exact_runtime_file_provisioning_pending',
    'explicit_one_use_founder_cloud_deployment_authority_pending'
  ) 'prepared blocker inventory'
} elseif ($Phase -eq 'RemoteReady') {
  $expectedIntegrationRoot = (
    'C:/GUARANTEED OUTCOME/' +
    'MOOLSOCIAL-WORKTREE-INTEGRATION-social-runtime-share-v5-20260826'
  )
  $rootForward = $root.Replace('\', '/')
  $branch = (& git -C $root branch --show-current).Trim()
  $localHead = (& git -C $root rev-parse HEAD).Trim()
  $worktreeDirt = @(& git -C $root status --porcelain=v1 --untracked-files=normal)
  $remoteHead = Get-RemoteBranchHead ([string]$source.finalIntegrationBranch)
  $integrationTree = @(& git -C $root rev-parse (
      [string]$source.finalIntegrationHead + ':backend/functions'
    ) 2>$null)
  $observedAt = [DateTimeOffset]::MinValue
  $observedValid = [DateTimeOffset]::TryParseExact(
    [string]$state.predeployReadback.observedAtUtc,
    'yyyy-MM-ddTHH:mm:ss.fffZ',
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal,
    [ref]$observedAt
  )
  $readbackAge = [DateTimeOffset]::UtcNow - $observedAt.ToUniversalTime()
  $sourceSealPath = [IO.Path]::GetFullPath((Join-Path $root `
    ([string]$source.sourceSealPath)))
  $sourceSealVerifierPath = [IO.Path]::GetFullPath((Join-Path $root `
    ([string]$source.sourceSealVerifierPath)))
  Assert-Execution (
    $state.state -ceq 'remote_ready_authority_held' -and
    $rootForward -ceq $expectedIntegrationRoot -and
    $branch -ceq [string]$source.finalIntegrationBranch -and
    [string]$source.finalIntegrationHead -cmatch '^[0-9a-f]{40}$' -and
    $localHead -ceq [string]$source.finalIntegrationHead -and
    $source.finalIntegrationHead -ceq $remoteHead -and
    $source.finalIntegrationRemoteHead -ceq $remoteHead -and
    $source.finalIntegrationRemoteExact -eq $true -and
    $source.finalIntegrationBackendTreeMatches -eq $true -and
    $worktreeDirt.Count -eq 0 -and
    $integrationTree.Count -eq 1 -and
    [string]$integrationTree[0] -ceq [string]$source.backendFunctionsTree -and
    $sourceSealPath.StartsWith(
      $rootPrefix,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath $sourceSealPath -PathType Leaf) -and
    [string]$source.sourceSealSha256 -cmatch '^[0-9A-F]{64}$' -and
    (Get-CanonicalTextSha256 $sourceSealPath) -ceq
      [string]$source.sourceSealSha256 -and
    [int]$source.sourceSealFileCount -gt 0 -and
    $sourceSealVerifierPath.StartsWith(
      $rootPrefix,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath $sourceSealVerifierPath -PathType Leaf) -and
    [string]$source.sourceSealVerifierSha256 -cmatch '^[0-9A-F]{64}$' -and
    (Get-CanonicalTextSha256 $sourceSealVerifierPath) -ceq
      [string]$source.sourceSealVerifierSha256 -and
    $state.predeployReadback.state -ceq 'ready' -and
    $observedValid -and $readbackAge.TotalSeconds -ge 0 -and
    $readbackAge.TotalMinutes -le 15 -and
    $state.predeployReadback.allFiveLiveIdentitiesExact -eq $true -and
    $state.predeployReadback.twoTargetRuntimeConfigurationsExact -eq $true -and
    $state.predeployReadback.threePreservedFunctionsExact -eq $true -and
    $runtimePackage.runtimeFileProvisioned -eq $true -and
    $authority.founderCloudDeploymentAuthorized -eq $false -and
    [string]::IsNullOrEmpty([string]$authority.authorizationId) -and
    [string]::IsNullOrEmpty([string]$authority.authorizedIntegrationHead) -and
    [string]::IsNullOrEmpty([string]$authority.authorizedExecutionStateSha256) -and
    [string]::IsNullOrEmpty([string]$authority.issuedAtUtc) -and
    [string]::IsNullOrEmpty([string]$authority.expiresAtUtc) -and
    [string]::IsNullOrEmpty([string]$authority.authorizationNonceSha256) -and
    $authority.oneUseAuthorizationConsumed -eq $false -and
    [int]$authority.deployCommandCount -eq 0 -and
    [int]$authority.rollbackTrafficCommandCount -eq 0 -and
    -not (Test-Path -LiteralPath $receiptPath)
  ) 'remote-ready integration, readback or held authority is incomplete.'
  & $sourceSealVerifierPath -RepositoryRoot $root `
    -ManifestPath $sourceSealPath | Out-Null
  Assert-ExactSet $state.blockers @(
    'explicit_one_use_founder_cloud_deployment_authority_pending'
  ) 'remote-ready blocker inventory'
} elseif ($Phase -eq 'Recovery') {
  $receipt = Get-ValidatedReceipt
  Assert-Execution (
    $state.state -ceq 'remote_ready_authority_held' -and
    [string]$source.finalIntegrationHead -cmatch '^[0-9a-f]{40}$' -and
    $source.finalIntegrationBackendTreeMatches -eq $true -and
    $authority.founderCloudDeploymentAuthorized -eq $false -and
    $receipt.state -cin @(
      'attempt_claimed','deployment_started','containment_critical'
    )
  ) 'recovery requires one bound ignored attempt receipt.'
} elseif ($Phase -eq 'Completed') {
  $receipt = Get-ValidatedReceipt
  Assert-Execution (
    $receipt.state -ceq 'completed' -and
    [int]$receipt.firebaseDeployCommandCount -eq 1 -and
    [int]$receipt.metadataRestoreCommandCount -eq 2 -and
    [int]$receipt.rollbackTrafficCommandCount -eq 0 -and
    [int]$receipt.cloudWriteActionCount -eq 3 -and
    [string]$receipt.newProviderRevision -cmatch
      '^youtubeprovider-[0-9]{5}-[a-z0-9]{3}$' -and
    $receipt.newProviderRevision -cne
      [string]$receipt.predecessorProviderRevision -and
    [string]$receipt.newProviderSourceGeneration -cmatch '^[1-9][0-9]{10,24}$' -and
    [string]$receipt.newCallbackRevision -cmatch
      '^youtubeoauthcallback-[0-9]{5}-[a-z0-9]{3}$' -and
    $receipt.newCallbackRevision -cne
      [string]$receipt.predecessorCallbackRevision -and
    [string]$receipt.newCallbackSourceGeneration -cmatch '^[1-9][0-9]{10,24}$' -and
    [string]$receipt.preservedFunctionFingerprintSetSha256 -cmatch
      '^[0-9A-F]{64}$' -and
    [string]$receipt.postdeployRuntimeFingerprintSetSha256 -cmatch
      '^[0-9A-F]{64}$'
  ) 'completed deployment proof is incomplete.'
} else {
  $receipt = Get-ValidatedReceipt
  Assert-Execution (
    $receipt.state -ceq 'failed_contained' -and
    [int]$receipt.firebaseDeployCommandCount -eq 1 -and
    [int]$receipt.metadataRestoreCommandCount -eq 2 -and
    [int]$receipt.rollbackTrafficCommandCount -eq 2 -and
    [int]$receipt.cloudWriteActionCount -eq 5 -and
    [string]$receipt.rollbackTrafficFingerprintSetSha256 -cmatch
      '^[0-9A-F]{64}$'
  ) 'rollback containment proof is incomplete.'
}

Write-Output (
  'Social runtime deployment execution passed: ' +
  "phase=$Phase; deployFunctions=2; preserveFunctions=3; " +
  "deployCommands=$($authority.deployCommandCount); " +
  "rollbackCommands=$($authority.rollbackTrafficCommandCount)."
)
