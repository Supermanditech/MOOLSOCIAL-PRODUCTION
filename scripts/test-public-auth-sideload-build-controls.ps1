[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$PreApkStatePath
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}

function Assert-SideloadControl {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,
    [Parameter(Mandatory)]
    [string]$Message
  )
  if (-not $Condition) {
    throw "Public-auth sideload control rejected: $Message"
  }
}

$regressionMemoryGate = Join-Path `
  $RepositoryRoot `
  'scripts/check-codex-development-regression-memory.ps1'
$coordinationGate = Join-Path `
  $RepositoryRoot `
  'scripts/check-codex-subagent-coordination-policy.ps1'
& $regressionMemoryGate `
  -Phase build `
  -BuildMode release `
  -RepositoryRoot $RepositoryRoot | Out-Null
$regressionMemoryPassed = $?
Assert-SideloadControl $regressionMemoryPassed `
  'mandatory successor regression-memory gate failed.'
if (-not [string]::IsNullOrWhiteSpace($PreApkStatePath)) {
  $resolvedPreApkState = [IO.Path]::GetFullPath($PreApkStatePath)
  $rootPrefix = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
    [char[]]@('\', '/')
  ) + [IO.Path]::DirectorySeparatorChar
  Assert-SideloadControl (
    $resolvedPreApkState.StartsWith(
      $rootPrefix,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath $resolvedPreApkState -PathType Leaf)
  ) 'candidate-specific pre-APK state is missing or outside the repository.'
  $preApkGate = Join-Path `
    $RepositoryRoot `
    'scripts/check-pre-apk-readiness-r60-92.ps1'
  Assert-SideloadControl (Test-Path -LiteralPath $preApkGate -PathType Leaf) `
    'candidate-specific pre-APK gate is missing.'
  $preApkState = Get-Content -Raw -LiteralPath $resolvedPreApkState |
    ConvertFrom-Json
  $preApkPhase = if ([bool]$preApkState.authority.buildAuthorized) {
    'BuildAuthorized'
  } else {
    'CandidateReservation'
  }
  & $preApkGate `
    -RepositoryRoot $RepositoryRoot `
    -StatePath $resolvedPreApkState `
    -Phase $preApkPhase | Out-Null
  $preApkPassed = $?
  Assert-SideloadControl $preApkPassed `
    'candidate-specific pre-APK readiness gate failed.'
} else {
  $coordinationState = Get-Content -Raw -LiteralPath (
    Join-Path $RepositoryRoot 'config/codex-subagent-coordination-policy.json'
  ) | ConvertFrom-Json
  & $coordinationGate `
    -AgentRole primary `
    -AgentTask '/root' `
    -UseRecordedClaim `
    -ExpectedRegistryEntryCount (
      [int]$coordinationState.registryBinding.entryCount
    ) `
    -ExpectedRegistrySha256 (
      [string]$coordinationState.registryBinding.sha256
    ) `
    -RepositoryRoot $RepositoryRoot | Out-Null
  $coordinationPassed = $?
  Assert-SideloadControl $coordinationPassed `
    'mandatory successor coordination gate failed.'
}
$approvedUiLockGate = Join-Path `
  $RepositoryRoot `
  'scripts/check-approved-ui-locks.ps1'
& $approvedUiLockGate | Out-Null
$approvedUiLockPassed = $?
Assert-SideloadControl $approvedUiLockPassed `
  'immutable approved UI and provider-seam projection gate failed.'

$pwshCandidates = @(
  Get-Command pwsh -CommandType Application -ErrorAction Stop
)
$pwshPath = [string]($pwshCandidates |
  Where-Object { Test-Path -LiteralPath $_.Source -PathType Leaf } |
  Select-Object -First 1 -ExpandProperty Source)
Assert-SideloadControl (
  -not [string]::IsNullOrWhiteSpace($pwshPath) -and
  (Test-Path -LiteralPath $pwshPath -PathType Leaf)
) 'PowerShell 7 executable resolution did not yield one validated leaf path.'
$strictModeProbeSource = @'
Set-StrictMode -Version Latest
Remove-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
& { $true | Out-Null }
$gatePassed = $?
if (-not $gatePassed) { throw 'PowerShell gate success flag was false.' }
'POWERSHELL_GATE_SUCCESS_FLAG_PASSED'
'@
$strictModeProbeOutput = @(
  & $pwshPath -NoProfile -NonInteractive `
    -Command $strictModeProbeSource 2>&1
)
$strictModeProbeExit = $LASTEXITCODE
Assert-SideloadControl (
  $strictModeProbeExit -eq 0 -and
  $strictModeProbeOutput -contains 'POWERSHELL_GATE_SUCCESS_FLAG_PASSED'
) 'PowerShell gate success cannot be checked when LASTEXITCODE starts absent.'

$artifactPathGate = Join-Path `
  $RepositoryRoot `
  'scripts/test-release-artifact-path-containment.ps1'
& $artifactPathGate -RepositoryRoot $RepositoryRoot | Out-Null
$pluginIntegrityFixtureGate = Join-Path `
  $RepositoryRoot `
  'scripts/test-release-production-plugin-integrity.ps1'
& $pluginIntegrityFixtureGate -RepositoryRoot $RepositoryRoot | Out-Null
$googleSigningFixtureGate = Join-Path `
  $RepositoryRoot `
  'scripts/test-google-android-oauth-signing-readiness.ps1'
& $googleSigningFixtureGate | Out-Null
$pluginManifestNamespaceGatePath = Join-Path `
  $RepositoryRoot `
  'scripts/check-android-plugin-manifest-namespace-readiness.ps1'
$kotlinPluginReadinessGatePath = Join-Path `
  $RepositoryRoot `
  'scripts/check-android-release-kotlin-plugin-readiness.ps1'
if (-not [string]::IsNullOrWhiteSpace($PreApkStatePath)) {
  $flutterSupportGuard = Join-Path `
    $RepositoryRoot `
    'scripts/invoke-flutter-with-clean-support.ps1'
  . $flutterSupportGuard
  $dependencyInventoryExit = Invoke-MoolSocialFlutterWithCleanSupport `
    -RepositoryRoot $RepositoryRoot `
    -Invocation {
      Push-Location (Join-Path $RepositoryRoot 'apps/mobile')
      try {
        & flutter pub get --enforce-lockfile
        if ($LASTEXITCODE -ne 0) {
          throw 'Locked dependency inventory resolution failed.'
        }
      } finally {
        Pop-Location
      }
      & $pluginManifestNamespaceGatePath `
        -RepositoryRoot $RepositoryRoot | Out-Null
      & $kotlinPluginReadinessGatePath `
        -RepositoryRoot $RepositoryRoot | Out-Null
    }
  Assert-SideloadControl ($dependencyInventoryExit -eq 0) `
    'guarded candidate dependency inventory failed.'
  $pluginManifestNamespaceInventory = (
    'releaseAndroidPlugins=20; directDevPluginsSkipped=1; ' +
    'obsoletePackageAttributes=15'
  )
  $kotlinPluginReadinessInventory = (
    'releaseAndroidPlugins=20; directDevPluginsSkipped=1; legacyKgpPlugins=3; ' +
    'plugins=firebase_app_check,mobile_scanner,speech_to_text'
  )
} else {
  $pluginManifestNamespaceInventory = & $pluginManifestNamespaceGatePath `
    -RepositoryRoot $RepositoryRoot `
    -InventoryOnly
  $kotlinPluginReadinessInventory = & $kotlinPluginReadinessGatePath `
    -RepositoryRoot $RepositoryRoot `
    -InventoryOnly
}
$fullSocialReadinessGatePath = Join-Path `
  $RepositoryRoot `
  'scripts/check-full-social-founder-dev-readiness.ps1'
$fullSocialFixturePath = Join-Path $RepositoryRoot (
  '.codex-full-social-readiness-' + [guid]::NewGuid().ToString('N') + '.json'
)
$fullSocialFixture = [ordered]@{
  founderDevProviderAcceptance = [ordered]@{
    ticketId = 'UAW-C34P-FIX9-CROSS-PROVIDER-RETURN-TRUTH-HARD-GATE'
    scope = 'founder_private_dev_sideload_not_public_release'
    brokerFunctionReadbackQualified = $true
    xRoleAcceptanceQualified = $true
    instagramRoleAcceptanceQualified = $true
    facebookRoleAcceptanceQualified = $true
    facebookBuildInputsPresenceQualified = $true
    facebookSideloadKeyHashQualifiedByFounder = $true
    youtubeSharedGoogleIdentityBridgeQualified = $true
    youtubeFix7AccountErasureBindingsQualified = $false
    publicReleaseOrAppReviewQualified = $false
    secretValuesObserved = $false
    agentPrivateLoginCount = 0
    buildCountSinceAcceptance = 0
    installCountSinceAcceptance = 0
  }
}
try {
  $fullSocialFixture | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $fullSocialFixturePath -Encoding utf8
  $fullSocialPositive = & $fullSocialReadinessGatePath `
    -StatePath $fullSocialFixturePath `
    -RepositoryRoot $RepositoryRoot
  $fullSocialFixture.founderDevProviderAcceptance.
    facebookSideloadKeyHashQualifiedByFounder = $false
  $fullSocialFixture | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $fullSocialFixturePath -Encoding utf8
  $fullSocialNegativeRejected = $false
  try {
    & $fullSocialReadinessGatePath `
      -StatePath $fullSocialFixturePath `
      -RepositoryRoot $RepositoryRoot | Out-Null
  } catch {
    $fullSocialNegativeRejected = $true
  }
} finally {
  Remove-Item -LiteralPath $fullSocialFixturePath -Force `
    -ErrorAction SilentlyContinue
}
Assert-SideloadControl (
  @($fullSocialPositive).Count -eq 1 -and
  ([string]$fullSocialPositive).Contains(
    'FULL_SOCIAL_FOUNDER_DEV_READINESS_QUALIFIED'
  ) -and
  $fullSocialNegativeRejected
) 'full-social readiness positive or missing-Facebook negative fixture failed.'

$prepare = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'scripts/prepare-moolsocial-sideload-build-environment.ps1'
)
$fix11SignerPreflightLauncher = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'scripts/invoke-fix11-local-signer-preflight.ps1'
)
$fix11SuccessorBuildLauncher = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'scripts/invoke-fix11-local-successor-build.ps1'
)
$wrapper = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot 'scripts/build-buy-device-review.ps1'
)
$aabWrapper = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot 'scripts/invoke-play-internal-aab-build-c30t.ps1'
)
$apkGate = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot 'scripts/check-apk-regression-gate-state.ps1'
)
$apkMachineState = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot 'config/apk-regression-gate-state.json'
)
$candidatePreApkState = if (
  -not [string]::IsNullOrWhiteSpace($PreApkStatePath)
) {
  Get-Content -Raw -LiteralPath ([IO.Path]::GetFullPath($PreApkStatePath))
} else {
  ''
}
$candidateRuntimeStateBound = if (
  -not [string]::IsNullOrWhiteSpace($PreApkStatePath)
) {
  $candidatePreApkState.Contains(
    '"runtimeProfile": "PublicAuthSideloadPreflight"'
  ) -and
  $candidatePreApkState.Contains(
    '"state": "pending_sanitized_binding"'
  ) -and
  $candidatePreApkState.Contains('"privateValuesEmitted": false')
} else {
  $apkMachineState.Contains(
    '"MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW": "false"'
  ) -and
  $apkMachineState.Contains(
    '"MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF": "false"'
  ) -and
  $apkMachineState.Contains(
    '"MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE": "true"'
  )
}
$postBuildPluginGate = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'scripts/check-apk-production-plugin-integrity.ps1'
)
$resourceIntegrityGate = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'scripts/check-android-release-resource-integrity.ps1'
)
$pluginManifestNamespaceGate = Get-Content -Raw -LiteralPath `
  $pluginManifestNamespaceGatePath
$kotlinPluginReadinessGate = Get-Content -Raw -LiteralPath `
  $kotlinPluginReadinessGatePath
$fullSocialReadinessGate = Get-Content -Raw -LiteralPath `
  $fullSocialReadinessGatePath
$fix11ReadinessGate = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'scripts/check-uaw-c34p-fix11-google-sign-in-forensic-readiness.ps1'
)
$signingRefresh = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'scripts/refresh-moolsocial-upload-signing-environment.ps1'
)
$googleSigningGate = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'scripts/check-google-android-oauth-signing-readiness.ps1'
)
$googleSigningFixtures = Get-Content -Raw -LiteralPath `
  $googleSigningFixtureGate
$fix8ManifestGenerator = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'scripts/new-fix8-r60-81-build-input-manifest.ps1'
)
$runtime = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/lib/core/auth/public_auth_runtime_configuration.dart'
)
$releaseRuntime = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/lib/core/config/release_runtime_configuration.dart'
)
$mainSource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot 'apps/mobile/lib/main.dart'
)
$publicAuthFailureSource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/lib/core/auth/public_auth_failure.dart'
)
$brokerAdapterSource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart'
)
$facebookContractSource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/lib/core/auth/facebook_login_contract.dart'
)
$facebookAdapterSource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/lib/core/auth/facebook_native_sdk_adapter.dart'
)
$socialGatewaySource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/lib/features/journey01/review_journey_services.dart'
)
$journeySessionSource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/lib/features/journey01/journey_session.dart'
)
$googleGatewayTests = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/test/firebase_social_auth_gateway_test.dart'
)
$googleRuntimeTests = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'apps/mobile/test/uaw_c34p_fix8_global_social_login_runtime_composition_test.dart'
)
$backendPublicAuthSource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot 'backend/functions/src/index.ts'
)
$xBrokerSource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot 'backend/functions/src/auth/x_pkce_broker.ts'
)
$instagramBrokerSource = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'backend/functions/src/auth/instagram_oauth_broker.ts'
)
$androidAppBuild = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot 'apps/mobile/android/app/build.gradle.kts'
)
$staleRegistrant = Join-Path $RepositoryRoot (
  'apps/mobile/android/app/src/main/java/io/flutter/plugins/' +
  'GeneratedPluginRegistrant.java'
)
$preservedRegistrant = Join-Path $RepositoryRoot (
  'artifacts/quality/' +
  'uaw-c34p-fix5-public-auth-sideload-preflight-r60-77-20260821-01/' +
  'preserved-stale-GeneratedPluginRegistrant.java'
)
$registrantSource = Get-Content -Raw -LiteralPath $staleRegistrant
$trackedRegistrant = @(& git -C $RepositoryRoot ls-files --error-unmatch -- `
    'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java' `
    2>$null)
$trackedRegistrantPassed = (
  $LASTEXITCODE -eq 0 -and
  $trackedRegistrant.Count -eq 1 -and
  [string]$trackedRegistrant[0] -ceq
    'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
)
$androidIgnore = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot 'apps/mobile/android/.gitignore'
)
$ticket = Get-Content -Raw -LiteralPath (
  Join-Path $RepositoryRoot `
    'config/uaw-c34p-fix11-google-sign-in-oppo-forensic-repair-ticket.json'
) | ConvertFrom-Json

Assert-SideloadControl (
  $prepare.Contains(
    "MOOLSOCIAL_GOOGLE_PLAY_SIGNING_QUALIFIED = 'false'"
  ) -and
  $prepare.Contains("MOOLSOCIAL_SIDELOAD_PREFLIGHT_ENABLED = 'true'") -and
  $prepare.Contains("MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT = 'true'") -and
  $prepare.Contains(
    "MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED = 'false'"
  ) -and
  $prepare.Contains(
    '$env:MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED = ''true'''
  ) -and
  $prepare.Contains('check-google-android-oauth-signing-readiness.ps1') -and
  $wrapper.Contains('check-google-android-oauth-signing-readiness.ps1')
) 'local signing must never be represented as Play signing.'

Assert-SideloadControl (
  $prepare.Contains('[switch]$GoogleOnly') -and
  $prepare.Contains('$env:MOOLSOCIAL_CANDIDATE_ID = $CandidateId') -and
  $prepare.Contains('sideload preparation candidate is not authorized') -and
  -not $prepare.Contains('uaw-c34p-auth-sideload-preflight-20260821-01') -and
  -not $prepare.Contains('$providerQualified') -and
  -not $prepare.Contains('check-full-social-founder-dev-readiness.ps1') -and
  $prepare.Contains(
    'MOOLSOCIAL_FACEBOOK_ENABLED = $fullSocialProviderQualified'
  ) -and
  $prepare.Contains(
    'MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED = $fullSocialProviderQualified'
  ) -and
  $prepare.Contains(
    'MOOLSOCIAL_INSTAGRAM_ENABLED = $fullSocialProviderQualified'
  ) -and
  $prepare.Contains("MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW = 'false'") -and
  $prepare.Contains("MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF = 'false'") -and
  $prepare.Contains("MOOLSOCIAL_YOUTUBE_PROVIDER_URL = ''") -and
  $wrapper.Contains("'MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW'") -and
  $wrapper.Contains("'MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF'") -and
  $wrapper.Contains("'MOOLSOCIAL_YOUTUBE_PROVIDER_URL'") -and
  $wrapper.Contains("'MOOLSOCIAL_CHAT_URL'") -and
  $wrapper.Contains(
    'Public-auth sideload Chat endpoint differs from the live environment.'
  ) -and
  $apkGate.Contains('$fullSocialCohortNames') -and
  $apkGate.Contains('$fullSocialRequiredFacts') -and
  $apkGate.Contains('MOOLSOCIAL_CHAT_URL') -and
  $apkGate.Contains('full-social runtime cohort is partial') -and
  $candidateRuntimeStateBound -and
  $wrapper.Contains('check-full-social-founder-dev-readiness.ps1') -and
  $wrapper.Contains('$fullSocialRuntimeRequired') -and
  $wrapper.Contains('$facebookRuntimeRequired') -and
  $wrapper.Contains(
    '$MachineState.requiredRuntimeDefines.MOOLSOCIAL_FACEBOOK_ENABLED'
  ) -and
  $fullSocialReadinessGate.Contains(
    'founder_private_dev_sideload_not_public_release'
  ) -and
  $wrapper.Contains(
    'check-uaw-c34p-fix11-google-sign-in-forensic-readiness.ps1'
  ) -and
  $wrapper.Contains('$fix11ReadinessPassed = $?') -and
  $fix11ReadinessGate.Contains('MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE') -and
  $apkGate.Contains("FIX11 runtime fact '") -and
  -not $aabWrapper.Contains('check-full-social-founder-dev-readiness.ps1')
) 'Google-only or full-social founder Dev readiness does not fail closed.'

Assert-SideloadControl (
  $prepare.Contains('$googleReadinessPassed = $?') -and
  $prepare.Contains('if (-not $googleReadinessPassed)') -and
  -not $prepare.Contains('$LASTEXITCODE') -and
  $wrapper.Contains('$googleReadinessPassed = $?') -and
  $wrapper.Contains('$apkMachineGatePassed = $?') -and
  @([regex]::Matches($wrapper, '\$LASTEXITCODE')).Count -eq 4
) 'PowerShell-to-PowerShell gates still depend on native LASTEXITCODE state.'

Assert-SideloadControl (
  $googleSigningGate.Contains('android_info.certificate_hash') -and
  $googleSigningGate.Contains('client_type -eq 3') -and
  $googleSigningGate.Contains('RedirectStandardInput = $true') -and
  $googleSigningGate.Contains('serverClientMatched=true') -and
  $googleSigningGate.Contains('signerMatched=true') -and
  $googleSigningFixtures.Contains(
    'mismatched or missing server client'
  ) -and
  $googleSigningFixtures.Contains(
    'mismatched or missing Android OAuth signer rejected'
  ) -and
  $prepare.Contains(
    '-GoogleServerClientId $env:MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID'
  ) -and
  $wrapper.Contains(
    "-GoogleServerClientId `$runtimeValues['MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID']"
  ) -and
  $fix8ManifestGenerator.Contains(
    "'scripts/check-google-android-oauth-signing-readiness.ps1'"
  ) -and
  $fix8ManifestGenerator.Contains("'scripts/check-approved-ui-locks.ps1'") -and
  $fix8ManifestGenerator.Contains(
    "'scripts/test-google-android-oauth-signing-readiness.ps1'"
  )
) 'Google sideload readiness is not derived from fail-closed server-client and signer matches.'

Assert-SideloadControl (
  $fix11SignerPreflightLauncher.Contains(
    'FIX11 local signer preflight requires PowerShell 7.'
  ) -and
  $fix11SignerPreflightLauncher.Contains(
    'prepare-moolsocial-sideload-build-environment.ps1'
  ) -and
  $fix11SignerPreflightLauncher.Contains('-GoogleOnly') -and
  $fix11SignerPreflightLauncher.Contains('-PreflightOnly') -and
  $fix11SignerPreflightLauncher.Contains(
    '$machineState.source.manifestSha256'
  ) -and
  $fix11SignerPreflightLauncher.Contains(
    '$env:MOOLSOCIAL_FIX11_LOCAL_PREFLIGHT_QUALIFIED = ''true'''
  ) -and
  $fix11SignerPreflightLauncher.Contains(
    'FIX11_LOCAL_SIGNER_PREFLIGHT_PASSED'
  ) -and
  -not $fix11SignerPreflightLauncher.Contains('Read-Host') -and
  -not $fix11SignerPreflightLauncher.Contains(
    'MOOLSOCIAL_UPLOAD_STORE_PASSWORD='
  ) -and
  $fix11SuccessorBuildLauncher.Contains(
    'FIX11 local successor build requires PowerShell 7.'
  ) -and
  $fix11SuccessorBuildLauncher.Contains(
    '$env:MOOLSOCIAL_FIX11_LOCAL_PREFLIGHT_QUALIFIED -ceq ''true'''
  ) -and
  $fix11SuccessorBuildLauncher.Contains(
    'Remove-Item Env:\MOOLSOCIAL_FIX11_LOCAL_PREFLIGHT_QUALIFIED'
  ) -and
  $fix11SuccessorBuildLauncher.Contains(
    '$machineState.source.manifestSha256'
  ) -and
  $fix11SuccessorBuildLauncher.Contains(
    'FIX11_LOCAL_SUCCESSOR_BUILD_PASSED'
  ) -and
  -not $fix11SuccessorBuildLauncher.Contains('-PreflightOnly') -and
  -not $fix11SuccessorBuildLauncher.Contains('Read-Host')
) 'FIX11 local preflight/build launchers are not one-session, source-bound and fail-closed.'

Assert-SideloadControl (
  $runtime.Contains(
    'sideloadPreflightEnabled && googleSideloadSigningQualified'
  ) -and
  $runtime.Contains('playSigningQualified ||')
) 'Google/YouTube lacks the explicit Play-or-sideload qualification branch.'

Assert-SideloadControl (
  $releaseRuntime.Contains('isQualifiedDeviceReviewRuntimeMode') -and
  $releaseRuntime.Contains('globalSocialLoginAudit') -and
  $releaseRuntime.Contains('publicAuthSideloadQualified')
) 'release startup lacks the exact public-auth sideload mode contract.'

Assert-SideloadControl (
  $prepare.Contains('MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL') -and
  $prepare.Contains('https://moolsocial.com/app') -and
  $prepare.Contains("MOOLSOCIAL_EMAIL_LINK_DOMAIN = ''") -and
  -not $prepare.Contains(
    "MOOLSOCIAL_EMAIL_LINK_DOMAIN = 'moolsocial.com'"
  ) -and
  $wrapper.Contains('$allowsEmptyDefaultEmailLinkDomain') -and
  $wrapper.Contains(
    "`$name -ceq 'MOOLSOCIAL_EMAIL_LINK_DOMAIN'"
  ) -and
  $wrapper.Contains('-not $allowsEmptyDefaultEmailLinkDomain') -and
  $wrapper.Contains('[switch]$PreflightOnly') -and
  $wrapper.Contains('if ($PreflightOnly)') -and
  $wrapper.Contains(
    'Device-review APK preflight passed without artifact build:'
  ) -and
  $wrapper.Contains(
    'Public-auth sideload Email Link Hosting configuration is not qualified.'
  ) -and
  $wrapper.Contains('MOOLSOCIAL_EMAIL_LINK_DOMAIN -cne') -and
  $apkGate.Contains(
    'Dev Email Link must omit linkDomain so Firebase selects its default Hosting domain.'
  ) -and
  $apkGate.Contains("-ceq ''") -and
  $aabWrapper.Contains(
    'AAB Email Link must omit linkDomain so Firebase selects its default Hosting domain.'
  ) -and
  $aabWrapper.Contains('MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL') -and
  $aabWrapper.Contains('MOOLSOCIAL_EMAIL_LINK_DOMAIN') -and
  $aabWrapper.Contains("-ceq ''")
) 'APK/AAB Email Link builds can explicitly supply a default or custom Hosting linkDomain.'

$requiredAuthStageCodes = @(
  'auth-native-bridge',
  'auth-firebase-unclassified',
  'auth-broker-response-invalid',
  'auth-broker-begin-invalid',
  'auth-authorization-response-invalid',
  'auth-app-check-required',
  'auth-broker-internal',
  'auth-identity-unavailable',
  'auth-token-issue-failed',
  'auth-provider-dependency',
  'auth-session-timeout',
  'auth-session-ready',
  'auth-google-native-client-configuration',
  'auth-google-native-initialize-started',
  'auth-google-native-initialize-complete',
  'auth-google-native-ui-unavailable',
  'auth-google-native-ui-requested',
  'auth-google-native-identity-missing',
  'auth-google-native-identity-returned',
  'auth-google-native-return-timeout',
  'auth-google-native-no-identity',
  'auth-google-native-provider-failed',
  'auth-google-native-unexpected',
  'auth-google-native-request-started',
  'auth-google-native-request-failed',
  'auth-google-firebase-credential-started',
  'auth-google-firebase-credential-complete',
  'auth-google-firebase-credential-failed',
  'auth-google-firebase-credential-timeout',
  'email-link-bridge-failure',
  'email-link-firebase-unclassified',
  'internal-error',
  'email-link-send-started',
  'email-link-firebase-credential-complete',
  'email-link-session-ready'
)
$authStageOwners = @(
  $publicAuthFailureSource,
  $brokerAdapterSource,
  $facebookContractSource,
  $facebookAdapterSource,
  $socialGatewaySource,
  $journeySessionSource
) -join "`n"
Assert-SideloadControl (
  @($requiredAuthStageCodes | Where-Object {
    -not $authStageOwners.Contains($_)
  }).Count -eq 0 -and
  $facebookAdapterSource.Contains('on PlatformException catch (error)') -and
  $facebookContractSource.Contains('firebaseUnclassified') -and
  $facebookContractSource.Contains('firebaseBridgeFailure') -and
  $socialGatewaySource.Contains('MOOLSOCIAL_GOOGLE_AUTH code=$code') -and
  $socialGatewaySource.Contains('_googleStageObserver') -and
  $socialGatewaySource.Contains('sanitizedEmailLinkFailure') -and
  $journeySessionSource.Contains(
    "result.code ?? 'auth-provider-credential-complete'"
  ) -and
  $journeySessionSource.Contains('GSI-N01') -and
  $googleGatewayTests.Contains('auth-google-native-no-identity') -and
  $googleGatewayTests.Contains('auth-google-firebase-credential-started') -and
  $googleGatewayTests.Contains('auth-google-firebase-credential-complete') -and
  $googleRuntimeTests.Contains("find.textContaining('GSI-N01')")
) 'social authentication still collapses a required real-device stage before APK/AAB.'

$brokerContractCodes = @(
  'invalid_request',
  'app_check_required',
  'attempt_not_found',
  'attempt_expired',
  'attempt_replayed',
  'authorization_denied',
  'account_ineligible',
  'provider_unavailable',
  'identity_unavailable',
  'token_issue_failed',
  'internal'
)
$backendBrokerSources = "$xBrokerSource`n$instagramBrokerSource"
Assert-SideloadControl (
  $backendPublicAuthSource.Contains(
    'response.status(200).json({ ok: true, data });'
  ) -and
  $backendPublicAuthSource.Contains('retryable: authError.retryable') -and
  $brokerAdapterSource.Contains("{'ok', 'data'}") -and
  $brokerAdapterSource.Contains("{'ok', 'error'}") -and
  $brokerAdapterSource.Contains("{'code', 'message', 'retryable'}") -and
  @($brokerContractCodes | Where-Object {
    -not $backendBrokerSources.Contains($_) -or
    -not $brokerAdapterSource.Contains($_)
  }).Count -eq 0
) 'mobile and Dev broker response/error contracts drifted before APK/AAB.'

$bootstrapIndex = $mainSource.IndexOf(
  'runApp(const ReleaseBootstrapApp());',
  [StringComparison]::Ordinal
)
$firebaseIndex = $mainSource.IndexOf(
  'Firebase.initializeApp',
  [StringComparison]::Ordinal
)
Assert-SideloadControl (
  $bootstrapIndex -ge 0 -and
  $firebaseIndex -gt $bootstrapIndex -and
  $mainSource.Contains('_releasePlatformStageTimeout') -and
  @([regex]::Matches($mainSource, '\.timeout\(')).Count -ge 6
) 'Flutter first frame or bounded pre-app bootstrap stages are missing.'

Assert-SideloadControl (
  $mainSource.Contains('shouldUseNativeAndroidFirebaseConfiguration(') -and
  $mainSource.Contains('isAndroid: Platform.isAndroid') -and
  $mainSource.Contains('await Firebase.initializeApp().timeout(') -and
  $mainSource.Contains("'firebase_initialize'") -and
  $mainSource.Contains("'normal_app'")
) 'native Android Firebase bootstrap or sanitized stage receipts are missing.'

Assert-SideloadControl (
  $wrapper.Contains("'PublicAuthSideloadPreflight'") -and
  $wrapper.Contains("[ValidateSet('debug', 'profile', 'release')]") -and
  $wrapper.Contains('release-artifact-path-guard.ps1') -and
  $wrapper.Contains('Resolve-ReleaseArtifactRepositoryDescendant') -and
  $wrapper.Contains('test-release-artifact-path-containment.ps1') -and
  $wrapper.Contains('test-release-production-plugin-integrity.ps1') -and
  $wrapper.Contains('-ProguardFolderPath') -and
  $wrapper.Contains('-RequireMappingAware') -and
  $wrapper.Contains(
    "MOOLSOCIAL_SOCIAL_CONTENT_URL = 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent'"
  ) -and
  $wrapper.Contains('SigningInputs=present_not_logged') -and
  $wrapper.Contains('MetaInputs=present_not_logged') -and
  $wrapper.Contains('MetaInputs=absent_fail_closed') -and
  -not $wrapper.Contains('MetaInputs=absent_google_only') -and
  -not $wrapper.Contains('SigningAndMetaInputs=present_not_logged')
) 'build wrapper lacks the release sideload profile, Social endpoint or sanitized provenance.'

Assert-SideloadControl (
  $wrapper.Contains('test-public-auth-sideload-build-controls.ps1') -and
  $wrapper.Contains('-PreApkStatePath $machineStateFile') -and
  $wrapper.Contains(
    "'UAW-R60.92-SOCIAL-RUNTIME-CONSOLIDATED-APK'"
  ) -and
  $wrapper.Contains('-Phase BuildAuthorized') -and
  $wrapper.Contains('$successorBuildFoundationPassed = $?') -and
  $wrapper.Contains('Mandatory successor APK build-foundation gate failed.') -and
  $aabWrapper.Contains('test-public-auth-sideload-build-controls.ps1') -and
  $aabWrapper.Contains('$successorBuildFoundationPassed = $?') -and
  $aabWrapper.Contains('Mandatory successor AAB build-foundation gate failed.') -and
  $prepare.Contains('$googleReadinessPassed = $?') -and
  $wrapper.Contains('$googleReadinessPassed = $?') -and
  $wrapper.Contains('$apkMachineGatePassed = $?')
) 'APK/AAB successor build-foundation gate is not mandatory in every wrapper.'

$lockedPreflightIndex = $wrapper.IndexOf(
  '$lockedDependencyReleasePreflight = {',
  [StringComparison]::Ordinal
)
$guardedFlutterIndex = $wrapper.IndexOf(
  '$flutterExit = Invoke-MoolSocialFlutterWithCleanSupport',
  [StringComparison]::Ordinal
)
$lockedPubGetIndex = $wrapper.IndexOf(
  '& flutter pub get --enforce-lockfile',
  [StringComparison]::Ordinal
)
$apkBuildIndex = $wrapper.IndexOf(
  '& flutter @buildArguments',
  [StringComparison]::Ordinal
)
$namespaceGateIndex = $wrapper.IndexOf(
  '& $pluginManifestNamespaceGate',
  [StringComparison]::Ordinal
)
$kotlinGateIndex = $wrapper.IndexOf(
  '& $kotlinPluginReadinessGate',
  [StringComparison]::Ordinal
)
$resourceGateIndex = $wrapper.IndexOf(
  '& $resourceIntegrityGate',
  [StringComparison]::Ordinal
)
Assert-SideloadControl (
  $lockedPreflightIndex -ge 0 -and
  $lockedPubGetIndex -gt $lockedPreflightIndex -and
  $namespaceGateIndex -gt $lockedPubGetIndex -and
  $kotlinGateIndex -gt $namespaceGateIndex -and
  $resourceGateIndex -gt $kotlinGateIndex -and
  $guardedFlutterIndex -gt $resourceGateIndex -and
  $apkBuildIndex -gt $guardedFlutterIndex -and
  $wrapper.Contains('-Invocation $lockedDependencyReleasePreflight') -and
  $wrapper.Contains('& $lockedDependencyReleasePreflight') -and
  $wrapper.Contains(
    'Locked Flutter dependency resolution failed before APK build.'
  ) -and
  $wrapper.Contains("'--no-pub'")
) 'APK wrapper does not hydrate the exact lock inside the guarded build operation.'

Assert-SideloadControl (
  $androidAppBuild.Contains('buildFeatures {') -and
  $androidAppBuild.Contains('resValues = true')
) 'Android custom resource values are not explicitly enabled.'

Assert-SideloadControl (
  (Test-Path -LiteralPath $staleRegistrant -PathType Leaf) -and
  $trackedRegistrantPassed -and
  $registrantSource.Contains('FlutterFirebaseCorePlugin') -and
  $androidAppBuild.Contains('sanitizeReleaseGeneratedPluginRegistrant') -and
  $androidAppBuild.Contains('IntegrationTestPlugin') -and
  $androidAppBuild.Contains('FlutterFirebaseCorePlugin') -and
  $androidAppBuild.Contains('dev.fluttercommunity.plus.share.SharePlusPlugin') -and
  $androidAppBuild.Contains('compileReleaseJavaWithJavac') -and
  $androidIgnore.Contains('GeneratedPluginRegistrant.java') -and
  -not $androidIgnore.Contains(
    '!app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
  )
) 'release-variant plugin registrant sanitizer is missing or incomplete.'

Assert-SideloadControl (
  $apkGate.Contains("'uaw_public_auth_sideload_preflight'") -and
  $apkGate.Contains("'app-check-sideload-disposition'") -and
  $apkGate.Contains("'android-release-resource-integrity'") -and
  $apkGate.Contains("'bootstrap-stage-diagnosis'") -and
  $apkGate.Contains("'device-cold-start-policy'") -and
  $apkGate.Contains("'MOOLSOCIAL_SIDELOAD_PREFLIGHT_ENABLED'") -and
  $apkGate.Contains("'MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT'") -and
  $apkGate.Contains('source manifest contains a malformed row.') -and
  $apkGate.Contains('source manifest contains a duplicate owner:') -and
  $apkGate.Contains('source manifest owner changed:') -and
  $apkGate.Contains('Get-FileHash -LiteralPath $resolvedOwner')
) 'APK machine gate lacks the exact sideload profile and runtime allowlist.'

Assert-SideloadControl (
  $wrapper.Contains('check-apk-production-plugin-integrity.ps1') -and
  $wrapper.Contains('APK production plugin integrity gate failed.') -and
  $postBuildPluginGate.Contains(
    'io.flutter.plugins.GeneratedPluginRegistrant'
  ) -and
  $postBuildPluginGate.Contains(
    'io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin'
  ) -and
  $postBuildPluginGate.Contains(
    'dev.fluttercommunity.plus.share.SharePlusPlugin'
  ) -and
  $postBuildPluginGate.Contains(
    'dev.flutter.plugins.integration_test.IntegrationTestPlugin'
  ) -and
  $postBuildPluginGate.Contains('manifest application-id')
) 'post-build APK plugin and package integrity gate is incomplete.'

Assert-SideloadControl (
  $wrapper.Contains('check-android-plugin-manifest-namespace-readiness.ps1') -and
  $wrapper.Contains('& $pluginManifestNamespaceGate') -and
  $wrapper.Contains('Android plugin manifest-namespace readiness failed.') -and
  $pluginManifestNamespaceGate.Contains('dev_dependencies:') -and
  $pluginManifestNamespaceGate.Contains('directDevDependencies') -and
  $pluginManifestNamespaceGate.Contains(
    '$reviewedObsoletePackagePlugins = @('
  ) -and
  $pluginManifestNamespaceGate.Contains("'firebase_app_check'") -and
  $pluginManifestNamespaceGate.Contains("'share_plus'") -and
  $pluginManifestNamespaceGate.Contains("'video_player_android'") -and
  $pluginManifestNamespaceGate.Contains('$androidPlugins.Count -eq 20') -and
  $pluginManifestNamespaceGate.Contains('$manifestCount -eq 18') -and
  $pluginManifestNamespaceGate.Contains('reviewedPinnedWarnings=') -and
  $pluginManifestNamespaceGate.Contains('never patch the machine Pub cache') -and
  $pluginManifestNamespaceInventory.Contains('directDevPluginsSkipped=1') -and
  $pluginManifestNamespaceInventory.Contains('obsoletePackageAttributes=15')
) 'prebuild Android plugin manifest-namespace readiness gate is missing or inaccurate.'

Assert-SideloadControl (
  $aabWrapper.Contains('check-android-plugin-manifest-namespace-readiness.ps1') -and
  $aabWrapper.Contains(
    '& $pluginManifestNamespaceGate -RepositoryRoot $root | Out-Null'
  )
) 'AAB wrapper lacks the shared fail-closed plugin manifest-namespace readiness gate.'

Assert-SideloadControl (
  $wrapper.Contains('check-android-release-kotlin-plugin-readiness.ps1') -and
  $wrapper.Contains('& $kotlinPluginReadinessGate') -and
  $wrapper.Contains('Android release Kotlin-plugin readiness failed.') -and
  $aabWrapper.Contains('check-android-release-kotlin-plugin-readiness.ps1') -and
  $aabWrapper.Contains(
    '& $kotlinPluginReadinessGate -RepositoryRoot $root | Out-Null'
  ) -and
  $kotlinPluginReadinessGate.Contains('directDevDependencies') -and
  $kotlinPluginReadinessGate.Contains('$reviewedLegacyKotlinPlugins = @(') -and
  $kotlinPluginReadinessGate.Contains("'firebase_app_check'") -and
  $kotlinPluginReadinessGate.Contains("'mobile_scanner'") -and
  $kotlinPluginReadinessGate.Contains("'speech_to_text'") -and
  $kotlinPluginReadinessGate.Contains('$releaseAndroidPlugins.Count -eq 20') -and
  $kotlinPluginReadinessGate.Contains('reviewedPinnedWarnings=') -and
  $kotlinPluginReadinessGate.Contains('never patch the machine Pub cache') -and
  $kotlinPluginReadinessInventory.Contains('legacyKgpPlugins=3') -and
  $kotlinPluginReadinessInventory.Contains(
    'plugins=firebase_app_check,mobile_scanner,speech_to_text'
  )
) 'APK/AAB Built-in Kotlin readiness gate is missing or inaccurate.'

Assert-SideloadControl (
  $wrapper.Contains('check-android-release-resource-integrity.ps1') -and
  $wrapper.Contains('-RunGradleLink') -and
  $wrapper.Contains('Android release resource-integrity preflight failed.') -and
  $resourceIntegrityGate.Contains("':app:processReleaseResources'") -and
  $resourceIntegrityGate.Contains("'--rerun-tasks'") -and
  $resourceIntegrityGate.Contains("'--warning-mode=summary'") -and
  $resourceIntegrityGate.Contains("'--console=plain'") -and
  $resourceIntegrityGate.Contains('$gradleOutput = @(& $gradlew') -and
  $resourceIntegrityGate.Contains(
    '$gradleOutput | Select-Object -Last 80 | Write-Output'
  ) -and
  $resourceIntegrityGate.Contains('allowedObsoleteDeletion') -and
  $resourceIntegrityGate.Contains('one or more unapproved tracked Android resource owners are deleted.') -and
  $resourceIntegrityGate.Contains('release merge output lacks the launch-background compiled resource.')
) 'pre-APK Android release resource-integrity gate is missing or incomplete.'

Assert-SideloadControl (
  $aabWrapper.Contains('check-android-release-resource-integrity.ps1') -and
  $aabWrapper.Contains('-RunGradleLink')
) 'AAB wrapper lacks the forced release resource-link preflight.'

Assert-SideloadControl (
  $signingRefresh.Contains('MOOLSOCIAL_KEY_VALID') -and
  $signingRefresh.Contains('UPLOAD_SIGNING_ENV_VALIDATED') -and
  -not $signingRefresh.Contains('-srcstorepass') -and
  -not $signingRefresh.Contains('-srckeypass')
) 'signing refresh does not validate locally without command-line passwords.'

Assert-SideloadControl (
  [bool]$ticket.authority.
    successorApkBuildAuthorizedAfterEvidencedRootCauseAndGreenPreflight -and
  [int]$ticket.authority.successorApkMaximumBuildCount -eq 1 -and
  [bool]$ticket.authority.
    successorOppoInPlaceInstallAuthorizedAfterIndependentArtifactQualification -and
  [int]$ticket.authority.successorOppoMaximumInstallCount -eq 1 -and
  -not [bool]$ticket.authority.aabPlayProductionAuthorized -and
  -not [bool]$ticket.authority.privateGoogleLoginByCodexAuthorized -and
  -not [bool]$ticket.authority.commitPushMergeAuthorized
) 'FIX11 ticket authority is missing or broader than one local APK/install.'

Write-Output (
  'Public-auth sideload build controls passed: PlayQualification=false; ' +
  'releaseProfile=true; oneSideload=true; privateActionsSeparate=true.'
)
