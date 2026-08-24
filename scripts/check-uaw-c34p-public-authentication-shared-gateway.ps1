[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C34P([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34P public-authentication gate rejected: $Message"
  }
}

function Read-Owner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C34P ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) `
    "owner escaped the repository: $RelativePath"
  Assert-C34P (Test-Path -LiteralPath $path -PathType Leaf) `
    "owner is missing: $RelativePath"
  return Get-Content -LiteralPath $path -Raw
}

function Get-C34PCanonicalTextSha256([string]$Path) {
  $text = [IO.File]::ReadAllText($Path)
  $canonical = $text.Replace("`r`n", "`n").Replace("`r", "`n")
  $encoding = New-Object Text.UTF8Encoding($false)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString(
      $sha.ComputeHash($encoding.GetBytes($canonical))
    )).Replace('-', '')
  } finally {
    $sha.Dispose()
  }
}

function Test-C34PCurrentFacebookSuccessor(
  [string]$TicketId,
  [string]$TicketHash,
  [string]$ClaimTask,
  [int]$ClaimOwnerCount,
  [bool]$ClaimHasGate,
  [string]$Lifecycle,
  [bool]$BuildAuthorized,
  [bool]$DeviceAuthorized,
  [bool]$PlayAuthorized,
  [bool]$ExternalAuthorized,
  [bool]$SecretAuthorized
) {
  return (
    $TicketId -ceq 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' -and
    $TicketHash -ceq
      '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' -and
    $ClaimTask -ceq '/root/codex_auth_facebook_prebuild_20260824' -and
    $ClaimOwnerCount -eq 24 -and
    $ClaimHasGate -and
    $Lifecycle -ceq
      'facebook_prebuild_selected_runtime_acceptance_deferred' -and
    -not $BuildAuthorized -and
    -not $DeviceAuthorized -and
    -not $PlayAuthorized -and
    -not $ExternalAuthorized -and
    -not $SecretAuthorized
  )
}

function Test-C34PSafeFirebaseMessageBoundary([string]$GatewaySource) {
  return (
    $GatewaySource.Contains('sanitizedFirebaseAuthFailure(') -and
    $GatewaySource.Contains(
      '_safeFirebaseAuthCauseCategory(code: error.code, message: error.message)'
    ) -and
    $GatewaySource.Contains(
      'throw JourneyServiceException(failure.publicMessage, code: failure.code);'
    ) -and
    -not $GatewaySource.Contains('JourneyServiceException(error.message') -and
    -not $GatewaySource.Contains('publicMessage: error.message') -and
    -not $GatewaySource.Contains('_googleStageObserver(error.message')
  )
}

function Test-C34PSharedGoogleIdentityDispatch([string]$GatewaySource) {
  $combinedDispatch = [regex]::IsMatch(
    $GatewaySource,
    '(?s)if\s*\(\s*provider\s*==\s*SocialAuthProvider[.]google\s*[|][|]\s*' +
      'provider\s*==\s*SocialAuthProvider[.]youtube\s*\)\s*\{\s*' +
      'userId\s*=\s*await\s+_signInWithGoogleIdentity\(\);'
  )
  $awaitedIdentityCalls = [regex]::Matches(
    $GatewaySource,
    'await\s+_signInWithGoogleIdentity\(\)'
  ).Count
  return $combinedDispatch -and $awaitedIdentityCalls -eq 1
}

function Test-C34PGlobalSocialAuditComposition([string]$MainSource) {
  return (
    $MainSource.Contains('MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT') -and
    $MainSource.Contains('resolveGlobalSocialLoginAuditComposition(') -and
    $MainSource.Contains(
      'globalSocialLoginAuditComposition.useReviewAuthentication'
    ) -and
    $MainSource.Contains('useProductionProviderAvailability') -and
    [regex]::IsMatch(
      $MainSource,
      'globalSocialLoginAuditEnabled:\s*' +
        '_globalSocialLoginAuditMode\s*&&\s*!_googleOnlyForensicMode'
    ) -and
    $MainSource.Contains('FirebaseAuthenticatedSessionBootstrapGateway(')
  )
}

function Test-C34PAuthorizedTicketSelection(
  [string]$CurrentTicketId,
  [string]$CheckpointTicketId,
  [string[]]$AuthorizedTicketIds
) {
  return (
    $CurrentTicketId -ceq $CheckpointTicketId -and
    $AuthorizedTicketIds -ccontains $CurrentTicketId
  )
}

$parentTicketPath = Join-Path $root `
  'config\uaw-c34p-fix1a-all-eight-public-auth-live-adapter-blocker-resolution-ticket.json'
$parentTicket = Get-Content -LiteralPath $parentTicketPath -Raw |
  ConvertFrom-Json
Assert-C34P (
  [string]$parentTicket.ticketId -ceq
  'UAW-C34P-FIX1A-ALL-EIGHT-PUBLIC-AUTH-LIVE-ADAPTER-BLOCKER-RESOLUTION'
) 'parent ticket identity changed.'
Assert-C34P ([string]$parentTicket.classification -ceq 'beyond_mvp') `
  'parent classification changed.'
Assert-C34P ([bool]$parentTicket.oneLogicalImplementationWave) `
  'parent no longer selects one implementation wave.'
Assert-C34P (@($parentTicket.acceptanceChildren).Count -eq 4) `
  'parent acceptance-child inventory changed.'
Assert-C34P ([bool]$parentTicket.authority.runtimeSourceWriteAuthorizedAfterMvpGate) `
  'runtime source authority is missing.'
Assert-C34P ([bool]$parentTicket.authority.testAndGateWriteAuthorizedAfterMvpGate) `
  'test/gate authority is missing.'
Assert-C34P ([bool]$parentTicket.authority.backendSourceWriteAuthorizedAfterMvpGate) `
  'backend source authority is missing.'
Assert-C34P (-not [bool]$parentTicket.authority.buildPlayOrDeviceActionAuthorized) `
  'build, Play or device authority was added.'
Assert-C34P (-not [bool]$parentTicket.authority.secretOrPrivateValueAccessAuthorized) `
  'secret access authority was added.'

$scopeState = Get-Content -LiteralPath (
  Join-Path $root 'config\mvp-scope-gate-state.json'
) -Raw | ConvertFrom-Json
$coordination = Get-Content -LiteralPath (
  Join-Path $root 'config\codex-subagent-coordination-policy.json'
) -Raw | ConvertFrom-Json
$facebookTicketId = 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824'
$facebookTicketRelative = `
  'docs/quality/UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824.md'
$facebookTicketPath = [IO.Path]::GetFullPath((Join-Path `
  $root $facebookTicketRelative
))
Assert-C34P (
  $facebookTicketPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and
  (Test-Path -LiteralPath $facebookTicketPath -PathType Leaf)
) 'current Facebook ticket is missing or escaped the repository.'
$facebookTicketText = Get-Content -LiteralPath $facebookTicketPath -Raw
$facebookTicketHash = Get-C34PCanonicalTextSha256 $facebookTicketPath
$gitDiscipline = $coordination.productionGitDiscipline
$authBatch = $gitDiscipline.agentTicketQueues.authPrebuildBatch
$facebookClaims = @($coordination.activeClaims | Where-Object {
  [string]$_.task -ceq '/root/codex_auth_facebook_prebuild_20260824'
})
$completedPrebuildProviders = @($authBatch.completedPrebuildProviders)
$facebookClaimTask = if ($facebookClaims.Count -eq 1) {
  [string]$facebookClaims[0].task
} else {
  'invalid'
}
$facebookClaimOwnerCount = if ($facebookClaims.Count -eq 1) {
  @($facebookClaims[0].owners).Count
} else {
  0
}
$facebookClaimHasGate = (
  $facebookClaims.Count -eq 1 -and
  @($facebookClaims[0].owners) -ccontains
    'scripts/check-uaw-c34p-public-authentication-shared-gateway.ps1'
)
$facebookLifecycleHeld = (
  [string]$gitDiscipline.acceptedRuntimeBaseline.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$gitDiscipline.acceptedRuntimeBaseline.head -ceq
    'f105195ba505dcc9f25a35ab64aab104dadb47c2' -and
  [string]$gitDiscipline.acceptedRuntimeBaseline.tag -ceq
    'moolsocial-google-auth-r60.87-accepted-20260823' -and
  [string]$authBatch.state -ceq
    'founder_authorized_runtime_acceptance_deferred_2026_08_24' -and
  [string]$authBatch.currentProvider -ceq 'facebook' -and
  [int]$authBatch.maximumActiveMutationTickets -eq 1 -and
  [bool]$authBatch.priorProviderImplementationAndQualificationCommitsRequired -and
  [bool]$authBatch.runtimeAcceptanceDeferredUntilOneCombinedApk -and
  [bool]$authBatch.finalTicketCloseStillRequired -and
  $completedPrebuildProviders.Count -eq 1 -and
  [string]$completedPrebuildProviders[0].provider -ceq 'email_link' -and
  [string]$completedPrebuildProviders[0].ticketId -ceq
    'UAW-CODEX-EMAIL-LINK-AUTH-20260823' -and
  [string]$completedPrebuildProviders[0].implementationCommit -ceq
    '883f1d06c315438823c801b184b990b672c77f85' -and
  [string]$completedPrebuildProviders[0].qualificationCommit -ceq
    '84ab8e55414d4b87b3442a3b9631fe058efc6efe' -and
  [bool]$completedPrebuildProviders[0].remoteQualified -and
  [bool]$completedPrebuildProviders[0].runtimeAcceptancePending -and
  $facebookClaims.Count -eq 1 -and
  [string]$facebookClaims[0].role -ceq 'primary' -and
  @($facebookClaims[0].owners) -ccontains $facebookTicketRelative -and
  $facebookTicketText.Contains("# $facebookTicketId") -and
  $facebookTicketText.Contains(
    'Branch: `work/codex-auth/facebook-auth-prebuild-20260824`'
  ) -and
  $facebookTicketText.Contains(
    'Real Facebook and OPPO acceptance remains deferred to'
  ) -and
  [string]$scopeState.ticket.id -ceq
    'UAW-CODEX-EMAIL-LINK-AUTH-20260823' -and
  [string]$scopeState.preTicketSelectionCheckpoint.currentTicketId -ceq
    'UAW-CODEX-EMAIL-LINK-AUTH-20260823' -and
  [bool]$scopeState.execution.runtimeWriteAuthorized -and
  [bool]$scopeState.execution.testOrGateWriteAuthorized -and
  -not [bool]$scopeState.execution.backendWriteAuthorized -and
  -not [bool]$scopeState.execution.otherProviderWriteAuthorized -and
  -not [bool]$scopeState.execution.liveEmailSendAuthorized
)
$facebookLifecycle = if ($facebookLifecycleHeld) {
  'facebook_prebuild_selected_runtime_acceptance_deferred'
} else {
  'invalid'
}

Assert-C34P (Test-C34PCurrentFacebookSuccessor `
  -TicketId $facebookTicketId `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -Lifecycle 'facebook_prebuild_selected_runtime_acceptance_deferred' `
  -BuildAuthorized $false -DeviceAuthorized $false -PlayAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
) 'current Facebook successor positive fixture failed.'
Assert-C34P (-not (Test-C34PCurrentFacebookSuccessor `
  -TicketId 'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-WRONG' `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -Lifecycle 'facebook_prebuild_selected_runtime_acceptance_deferred' `
  -BuildAuthorized $false -DeviceAuthorized $false -PlayAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) 'current Facebook successor wrong-ticket fixture passed unexpectedly.'
Assert-C34P (-not (Test-C34PCurrentFacebookSuccessor `
  -TicketId $facebookTicketId `
  -TicketHash '0919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -Lifecycle 'facebook_prebuild_selected_runtime_acceptance_deferred' `
  -BuildAuthorized $false -DeviceAuthorized $false -PlayAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) 'current Facebook successor wrong-hash fixture passed unexpectedly.'
Assert-C34P (-not (Test-C34PCurrentFacebookSuccessor `
  -TicketId $facebookTicketId `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_wrong' `
  -ClaimOwnerCount 23 -ClaimHasGate $false `
  -Lifecycle 'facebook_prebuild_selected_runtime_acceptance_deferred' `
  -BuildAuthorized $false -DeviceAuthorized $false -PlayAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) 'current Facebook successor wrong-claim fixture passed unexpectedly.'
Assert-C34P (-not (Test-C34PCurrentFacebookSuccessor `
  -TicketId $facebookTicketId `
  -TicketHash '6919BA2D3346E328AA518C443FEFC64655BA54F57F5B466CD29E47E3EF3025E0' `
  -ClaimTask '/root/codex_auth_facebook_prebuild_20260824' `
  -ClaimOwnerCount 24 -ClaimHasGate $true `
  -Lifecycle 'facebook_prebuild_selected_runtime_acceptance_deferred' `
  -BuildAuthorized $true -DeviceAuthorized $false -PlayAuthorized $false `
  -ExternalAuthorized $false -SecretAuthorized $false
)) 'current Facebook successor wrong-authority fixture passed unexpectedly.'

$currentFacebookSuccessor = (
  $facebookLifecycleHeld -and
  (Test-C34PCurrentFacebookSuccessor `
    -TicketId $facebookTicketId -TicketHash $facebookTicketHash `
    -ClaimTask $facebookClaimTask -ClaimOwnerCount $facebookClaimOwnerCount `
    -ClaimHasGate $facebookClaimHasGate -Lifecycle $facebookLifecycle `
    -BuildAuthorized ([bool]$scopeState.execution.buildAuthorized) `
    -DeviceAuthorized ([bool]$scopeState.execution.deviceInstallAuthorized) `
    -PlayAuthorized ([bool]$scopeState.execution.playUploadAuthorized) `
    -ExternalAuthorized ([bool]$scopeState.execution.externalServiceWriteAuthorized) `
    -SecretAuthorized ([bool]$scopeState.execution.secretValueAccessAuthorized))
)
$authorizedTicketIds = @(
  [string]$parentTicket.ticketId,
  'UAW-C34P-FIX5-ALL-EIGHT-PUBLIC-AUTH-LIVE-PROVIDER-READINESS',
  'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR'
)
$historicalC34PSelection = Test-C34PAuthorizedTicketSelection `
    -CurrentTicketId ([string]$scopeState.ticket.id) `
    -CheckpointTicketId (
      [string]$scopeState.preTicketSelectionCheckpoint.currentTicketId
    ) `
    -AuthorizedTicketIds $authorizedTicketIds
Assert-C34P ($historicalC34PSelection -or $currentFacebookSuccessor) `
  'MVP scope state does not select an authorized C34P auth ticket.'
Assert-C34P (-not (
  Test-C34PAuthorizedTicketSelection `
    -CurrentTicketId 'UNRELATED-TICKET' `
    -CheckpointTicketId 'UNRELATED-TICKET' `
    -AuthorizedTicketIds $authorizedTicketIds
)) 'unrelated-ticket negative fixture was accepted.'
$selectedTicketId = [string]$scopeState.ticket.id
$fix8TicketId = 'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR'
$fix8RepairRetryAuthorized = $false
$fix8ExpectedBuildAuthorized = $false
$fix8ExpectedInstallAuthorized = $false
if ($selectedTicketId -ceq $fix8TicketId) {
  $fix8Relative = `
    'config/uaw-c34p-fix8-global-social-login-oppo-successor-audit-repair-ticket.json'
  $fix8Path = Join-Path $root $fix8Relative
  Assert-C34P (Test-Path -LiteralPath $fix8Path -PathType Leaf) `
    'FIX8 selected ticket is missing.'
  $fix8 = Get-Content -LiteralPath $fix8Path -Raw | ConvertFrom-Json
  $fix8Hash = (Get-FileHash -LiteralPath $fix8Path -Algorithm SHA256).Hash
  $assessment = $scopeState.preTicketSelectionCheckpoint.selectedTicketAssessment
  $fix8SourceOnlyHeld = (
    [bool]$fix8.authority.sourceAndTestRepairAuthorizedAfterMvpGate -and
    -not [bool]$fix8.authority.buildAuthorized -and
    -not [bool]$fix8.authority.installOrOppoMutationAuthorized -and
    -not [bool]$fix8.authority.privateProviderLoginAuthorized
  )
  $fix8RepairRetryState = `
    'r60_81_release_resource_repair_one_rebuild_and_in_place_sideload_authorized'
  $fix8LegacyRepairRetryAuthorized = (
    [string]$fix8.status -ceq $fix8RepairRetryState -and
    [string]$fix8.releaseAuthorization.state -ceq $fix8RepairRetryState -and
    [int]$fix8.releaseAuthorization.maximumBuildCount -eq 2 -and
    [int]$fix8.releaseAuthorization.buildCount -eq 1 -and
    [int]$fix8.releaseAuthorization.installCount -eq 0 -and
    [bool]$fix8.authority.sourceAndTestRepairAuthorizedAfterMvpGate -and
    [bool]$fix8.authority.buildAuthorized -and
    [bool]$fix8.authority.installOrOppoMutationAuthorized -and
    -not [bool]$fix8.authority.sqlConnectProvisioningOrMigrationAuthorized -and
    -not [bool]$fix8.authority.privateProviderLoginAuthorized -and
    -not [bool]$fix8.authority.realEmailOrSmsAuthorized -and
    -not [bool]$fix8.authority.playOrProductionAuthorized -and
    -not [bool]$fix8.authority.youtubeApiFinalSubmissionAuthorized -and
    -not [bool]$fix8.authority.commitPushMergeAuthorized
  )
  $fix8R6084PrebuildAuthorizationState = `
    'r60_84_full_social_one_build_and_one_in_place_install_authorized_fresh_source_seal_bound'
  $fix8R6084PrebuildTicketState = `
    'fix10_all_auth_local_implementation_and_pre_apk_contract_qualified_r60_84_one_build_and_one_in_place_oppo_sideload_authorized_device_provider_reproof_pending'
  $fix8SourceManifestPath = [IO.Path]::GetFullPath((Join-Path `
    $root `
    ([string]$fix8.releaseAuthorization.sourceManifestPath)
  ))
  $fix8R6084Common = (
    [string]$fix8.releaseAuthorization.versionName -ceq '1.0.0-r60.84' -and
    [string]$fix8.releaseAuthorization.versionCode -ceq '2026082184' -and
    [int]$fix8.releaseAuthorization.maximumBuildCount -eq 1 -and
    [int]$fix8.releaseAuthorization.maximumInstallCount -eq 1 -and
    (Test-Path -LiteralPath $fix8SourceManifestPath -PathType Leaf) -and
    (Get-FileHash -LiteralPath $fix8SourceManifestPath -Algorithm SHA256).Hash `
      -ceq [string]$fix8.releaseAuthorization.sourceManifestSha256 -and
    [bool]$fix8.authority.sourceAndTestRepairAuthorizedAfterMvpGate -and
    -not [bool]$fix8.authority.sqlConnectProvisioningOrMigrationAuthorized -and
    -not [bool]$fix8.authority.privateProviderLoginAuthorized -and
    -not [bool]$fix8.authority.realEmailOrSmsAuthorized -and
    -not [bool]$fix8.authority.playOrProductionAuthorized -and
    -not [bool]$fix8.authority.youtubeApiFinalSubmissionAuthorized -and
    -not [bool]$fix8.authority.commitPushMergeAuthorized
  )
  $fix8R6084PrebuildAuthorized = (
    $fix8R6084Common -and
    [string]$fix8.status -ceq $fix8R6084PrebuildTicketState -and
    [string]$fix8.releaseAuthorization.state -ceq
      $fix8R6084PrebuildAuthorizationState -and
    [int]$fix8.releaseAuthorization.buildCount -eq 0 -and
    [int]$fix8.releaseAuthorization.installCount -eq 0 -and
    [bool]$fix8.authority.buildAuthorized -and
    [bool]$fix8.authority.installOrOppoMutationAuthorized
  )
  $fix8R6084PostbuildAuthorized = (
    $fix8R6084Common -and
    [string]$fix8.status -ceq
      'fix10_all_auth_r60_84_built_postbuild_qualified_one_in_place_oppo_sideload_authorized_device_provider_reproof_pending' -and
    [string]$fix8.releaseAuthorization.state -ceq
      'r60_84_one_build_consumed_postbuild_qualified_one_in_place_install_authorized' -and
    [int]$fix8.releaseAuthorization.buildCount -eq 1 -and
    [int]$fix8.releaseAuthorization.installCount -eq 0 -and
    -not [bool]$fix8.authority.buildAuthorized -and
    [bool]$fix8.authority.installOrOppoMutationAuthorized
  )
  $fix8R6084PostinstallAuthorized = (
    $fix8R6084Common -and
    [string]$fix8.status -ceq
      'fix10_all_auth_r60_84_built_and_installed_founder_private_provider_acceptance_pending' -and
    [string]$fix8.releaseAuthorization.state -ceq
      'r60_84_one_build_and_one_install_consumed_founder_private_provider_acceptance_pending' -and
    [int]$fix8.releaseAuthorization.buildCount -eq 1 -and
    [int]$fix8.releaseAuthorization.installCount -eq 1 -and
    -not [bool]$fix8.authority.buildAuthorized -and
    -not [bool]$fix8.authority.installOrOppoMutationAuthorized
  )
  $fix8RepairRetryAuthorized = (
    $fix8LegacyRepairRetryAuthorized -or
    $fix8R6084PrebuildAuthorized -or
    $fix8R6084PostbuildAuthorized -or
    $fix8R6084PostinstallAuthorized
  )
  $fix8ExpectedBuildAuthorized = (
    $fix8LegacyRepairRetryAuthorized -or $fix8R6084PrebuildAuthorized
  )
  $fix8ExpectedInstallAuthorized = (
    $fix8LegacyRepairRetryAuthorized -or
    $fix8R6084PrebuildAuthorized -or
    $fix8R6084PostbuildAuthorized
  )
  Assert-C34P (
    [string]$fix8.ticketId -ceq $fix8TicketId -and
    [string]$assessment.manifestPath -ceq $fix8Relative -and
    [string]$assessment.manifestSha256 -ceq $fix8Hash -and
    ($fix8SourceOnlyHeld -or $fix8RepairRetryAuthorized)
  ) 'FIX8 manifest binding or held authority changed.'
}
$externalProviderWriteExpected = $selectedTicketId -ceq `
  'UAW-C34P-FIX5-ALL-EIGHT-PUBLIC-AUTH-LIVE-PROVIDER-READINESS'
$backendWriteExpected = -not $currentFacebookSuccessor
Assert-C34P (
  [bool]$scopeState.execution.runtimeWriteAuthorized -and
  [bool]$scopeState.execution.testOrGateWriteAuthorized -and
  [bool]$scopeState.execution.backendWriteAuthorized -eq
    $backendWriteExpected -and
  [bool]$scopeState.execution.buildAuthorized -eq
    $fix8ExpectedBuildAuthorized -and
  [bool]$scopeState.execution.deviceInstallAuthorized -eq
    $fix8ExpectedInstallAuthorized -and
  [bool]$scopeState.execution.externalServiceWriteAuthorized -eq
    $externalProviderWriteExpected -and
  (-not $currentFacebookSuccessor -or (
    -not [bool]$scopeState.execution.playUploadAuthorized -and
    -not [bool]$scopeState.execution.otherProviderWriteAuthorized -and
    -not [bool]$scopeState.execution.liveEmailSendAuthorized
  )) -and
  -not [bool]$scopeState.execution.secretValueAccessAuthorized
) 'MVP execution authority does not match the selected C34P auth ticket.'

$failureSource = Read-Owner 'apps/mobile/lib/core/auth/public_auth_failure.dart'
$runtimeSource = Read-Owner `
  'apps/mobile/lib/core/auth/public_auth_runtime_configuration.dart'
$gatewaySource = Read-Owner `
  'apps/mobile/lib/features/journey01/review_journey_services.dart'
$mainSource = Read-Owner 'apps/mobile/lib/main.dart'
$xSource = Read-Owner 'apps/mobile/lib/core/auth/x_oauth2_pkce.dart'
$facebookSource = Read-Owner `
  'apps/mobile/lib/core/auth/facebook_login_contract.dart'
$xTest = Read-Owner 'apps/mobile/test/uaw_c34p_x_oauth2_pkce_test.dart'
$facebookTest = Read-Owner `
  'apps/mobile/test/uaw_c34p_facebook_login_contract_test.dart'

foreach ($token in @(
  'sanitizedGoogleIdentityFailure',
  'sanitizedFirebaseAuthFailure',
  'PublicAuthFailureClass.accountCollision',
  "'auth-unknown'"
)) {
  Assert-C34P ($failureSource.Contains($token)) `
    "sanitized failure taxonomy is missing: $token"
}
Assert-C34P (Test-C34PSafeFirebaseMessageBoundary $gatewaySource) `
  'Firebase provider message is not confined to a safe cause classifier.'
$unsafeFirebaseMessageFixture = (
  $gatewaySource + "`nthrow JourneyServiceException(error.message);"
)
Assert-C34P (-not (
  Test-C34PSafeFirebaseMessageBoundary $unsafeFirebaseMessageFixture
)) 'unsafe Firebase public-message negative fixture passed unexpectedly.'
Assert-C34P (-not $gatewaySource.Contains('TwitterAuthProvider()')) `
  'X regressed to the Firebase OAuth 1 provider.'
Assert-C34P (-not $gatewaySource.Contains('FacebookAuthProvider()')) `
  'Facebook regressed to unsupported native Firebase provider dispatch.'
Assert-C34P (Test-C34PSharedGoogleIdentityDispatch $gatewaySource) `
  'Google and YouTube no longer share one identity dispatch.'
$splitGoogleYoutubeDispatchFixture = (
  'if (provider == SocialAuthProvider.google) { ' +
  'userId = await _signInWithGoogleIdentity(); } ' +
  'if (provider == SocialAuthProvider.youtube) { ' +
  'userId = await _signInWithGoogleIdentity(); }'
)
Assert-C34P (-not (
  Test-C34PSharedGoogleIdentityDispatch $splitGoogleYoutubeDispatchFixture
)) 'split Google/YouTube dispatch negative fixture passed unexpectedly.'

foreach ($token in @(
  'googleAndYoutubeAvailable',
  'passwordlessEmailAvailable',
  'mobileOtpAvailable',
  'appleAvailable',
  'xAvailable',
  'instagramAvailable',
  'facebookAvailable',
  'xFirebaseBrokerQualified',
  'instagramBrokerQualified',
  'facebookDataDeletionQualified'
)) {
  Assert-C34P ($runtimeSource.Contains($token)) `
    "runtime availability contract is missing: $token"
}
Assert-C34P ($mainSource.Contains('xPkceAdapterInstalled: xAdapter != null')) `
  'X is not bound to the real PKCE adapter readiness.'
Assert-C34P (
  $mainSource.Contains('instagramBrokerAdapterInstalled: instagramAdapter != null')
) 'Instagram is not bound to the real broker adapter readiness.'
Assert-C34P (
  $mainSource.Contains('facebookNativeAdapterInstalled: facebookAdapter.isConfigured')
) 'Facebook is not bound to the real native adapter readiness.'
Assert-C34P ($mainSource.Contains('MOOLSOCIAL_MOBILE_OTP_ATTESTATION_QUALIFIED')) `
  'mobile OTP lacks candidate-specific attestation readiness.'
foreach ($token in @(
  'MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT',
  'resolveGlobalSocialLoginAuditComposition(',
  'globalSocialLoginAuditComposition.useReviewAuthentication',
  'useProductionProviderAvailability',
  'FirebaseAuthenticatedSessionBootstrapGateway('
)) {
  Assert-C34P ($mainSource.Contains($token)) `
    "FIX8 main composition is missing: $token"
}
Assert-C34P (Test-C34PGlobalSocialAuditComposition $mainSource) `
  'FIX8 global-social audit composition is not fail-closed for Google-only mode.'
$unsafeGlobalSocialCompositionFixture = $mainSource.Replace(
  '_globalSocialLoginAuditMode && !_googleOnlyForensicMode',
  '_globalSocialLoginAuditMode'
)
Assert-C34P (-not (
  Test-C34PGlobalSocialAuditComposition $unsafeGlobalSocialCompositionFixture
)) 'unsafe global-social composition negative fixture passed unexpectedly.'
Assert-C34P (
  $gatewaySource.Contains('class FirebaseAuthenticatedSessionBootstrapGateway')
) 'FIX8 Firebase session bootstrap owner is missing.'

foreach ($token in @(
  "import 'package:crypto/crypto.dart' as crypto;",
  "'tweet.read'",
  "'users.read'",
  "'code_challenge_method': 'S256'",
  "const <String>['token', 'client_id']",
  'includesClientSecret => false',
  'executesNetwork => false',
  'persistsCredentials => false'
)) {
  Assert-C34P ($xSource.Contains($token)) "X PKCE contract is missing: $token"
}
Assert-C34P (-not $xSource.Contains('offline.access')) `
  'X pure contract contains forbidden offline access.'
Assert-C34P (-not $xSource.Contains('roundConstants')) `
  'X contains a duplicate hand-written SHA-256 primitive.'
Assert-C34P ($xTest.Contains('RFC 7636')) `
  'X tests lack the RFC 7636 known vector.'

foreach ($token in @(
  "'com.moolsocial.app'",
  "'com.moolsocial.app.MainActivity'",
  "<String>{'public_profile'}",
  'emailPermissionRequestedByDefault = false',
  'FacebookLoginConfigurationIssue.nativeAdapterUnavailable',
  'FacebookAccountRequestKind.revokeAccess',
  'FacebookAccountRequestKind.dataDeletion'
)) {
  Assert-C34P ($facebookSource.Contains($token)) `
    "Facebook contract is missing: $token"
}
foreach ($forbidden in @(
  'flutter_facebook_auth',
  'FacebookAuth.instance',
  'HttpClient(',
  'client_secret',
  'access_token'
)) {
  Assert-C34P (-not $facebookSource.Contains($forbidden)) `
    "Facebook contract crossed its fail-closed boundary: $forbidden"
}
Assert-C34P ($facebookTest.Contains('public_profile')) `
  'Facebook tests lack the minimum-permission proof.'

$reportedTicketId = if ($currentFacebookSuccessor) {
  $facebookTicketId
} else {
  $selectedTicketId
}
Write-Output (
  'C34P public-authentication shared-gateway gate passed: ' +
  'parent=FIX1A; activeTicket=' + $reportedTicketId + '; ' +
  'children=4; runtimeBackendTest=true; ' +
  'googleYoutubeShared=true; appleFirebase=true; xPkce=true; ' +
  'instagramProfessional=true; facebookNative=true; ' +
  'emailLink=true; mobileOtpAttested=true; newScreens=0; newRoutes=0; ' +
  'externalProviderWriteAuthority=' +
  $externalProviderWriteExpected.ToString().ToLowerInvariant() + '.'
)
