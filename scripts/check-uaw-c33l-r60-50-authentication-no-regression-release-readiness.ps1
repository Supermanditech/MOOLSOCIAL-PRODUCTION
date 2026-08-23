[CmdletBinding()]
param(
  [ValidateSet('source', 'build', 'postbuild', 'preupload', 'postupload', 'preinstall', 'postinstall', 'journey')]
  [string]$Phase = 'source',

  [string]$StatePath = 'config/successor-aab-regression-hard-gate-state-c33l.json',

  [string]$ScopePath = 'config/mvp-scope-gate-state.json',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33L {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33L r60.50 no-regression release gate rejected: $Message"
  }
}

function Resolve-C33LFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C33L -Condition (-not [string]::IsNullOrWhiteSpace($Path)) `
    -Message "$Label path is empty."
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33L -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

function Assert-C33LSanitizedText {
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][string]$Label
  )
  foreach ($pattern in @(
    'AIza[0-9A-Za-z_-]{35}',
    '[0-9]{6,}-[0-9A-Za-z_-]+[.]apps[.]googleusercontent[.]com',
    'Bearer\s+[A-Za-z0-9._~+/-]+=*',
    '-----BEGIN [^-]*PRIVATE KEY-----',
    'eyJ[A-Za-z0-9_-]+[.]eyJ[A-Za-z0-9_-]+[.][A-Za-z0-9_-]+'
  )) {
    Assert-C33L -Condition (-not [regex]::IsMatch($Text, $pattern)) `
      -Message "$Label contains a credential-, token- or private-key-shaped value."
  }
}

function Assert-C33LPowerShellOwner {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $Path,
    [ref]$tokens,
    [ref]$errors
  )
  Assert-C33L -Condition (@($errors).Count -eq 0) `
    -Message "$Label PowerShell parser rejected the current owner."
}

function Assert-C33LManifestCurrent {
  param([Parameter(Mandatory)][string]$ManifestPath)
  foreach ($line in Get-Content -LiteralPath $ManifestPath) {
    $match = [regex]::Match($line, '^([0-9A-F]{64})  (.+)$')
    Assert-C33L -Condition $match.Success -Message 'source-manifest row is malformed.'
    $owner = Resolve-C33LFile -Path $match.Groups[2].Value -Label 'sealed source owner'
    Assert-C33L -Condition (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq
        $match.Groups[1].Value
    ) -Message "source changed after qualification: $($match.Groups[2].Value)"
  }
}

$ticketId = 'UAW-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE'
$ticketPath = Resolve-C33LFile `
  -Path 'config/uaw-c33l-r60-50-authentication-no-regression-play-oppo-acceptance-ticket.json' `
  -Label 'C33L ticket'
$ticketRaw = Get-Content -Raw -LiteralPath $ticketPath
Assert-C33LSanitizedText -Text $ticketRaw -Label 'C33L ticket'
Assert-C33L -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    '3867E192D5903FF8EC9ECBB9F82201C633088CF3F43C820403A4DC795693D4F1'
) -Message 'ticket bytes changed.'
$ticket = $ticketRaw | ConvertFrom-Json
Assert-C33L -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.state -ceq
    'founder_disclosed_and_end_to_end_authorized_prebuild_qualification_pending' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [string]$ticket.candidate.versionName -ceq '1.0.0-r60.50' -and
  [string]$ticket.candidate.versionCode -ceq '2026081350' -and
  [string]$ticket.candidate.playTrack -ceq 'internal' -and
  [bool]$ticket.historicalRegressionHardGate.allCurrentRegistryEntriesAppliedBeforeSourceSeal -and
  [bool]$ticket.historicalRegressionHardGate.registryFileSha256AndEntryCountBoundToCandidate -and
  [bool]$ticket.historicalRegressionHardGate.twoFreshIdenticalCompleteCyclesRequired -and
  [bool]$ticket.historicalRegressionHardGate.postSealRegistryChangeRejectsBuildOrPromotion -and
  [bool]$ticket.historicalRegressionHardGate.anyRepeatedOrNewDefectRejectsCandidate -and
  [bool]$ticket.historicalRegressionHardGate.exactRepairTicketBeforeRetryRequired -and
  -not [bool]$ticket.historicalRegressionHardGate.waiversAllowed -and
  [bool]$ticket.authority.oneAabBuildAuthorizedAfterAllGates -and
  [bool]$ticket.authority.oneInternalTestingUploadAndActivationAuthorizedAfterPostbuild -and
  [bool]$ticket.authority.oneInPlaceOppoPlayUpdateAuthorizedAfterActivation -and
  [bool]$ticket.authority.oneFounderReviewedPasswordlessEmailSendAuthorizedAfterInstall -and
  -not [bool]$ticket.authority.agentSecretOrPrivateLinkAccessAuthorized -and
  -not [bool]$ticket.authority.otherTrackAuthorized -and
  -not [bool]$ticket.authority.adbInstallUninstallDataClearDowngradeOrSideloadAuthorized -and
  -not [bool]$ticket.authority.backendHostingProviderOrProductionDeploymentAuthorized -and
  -not [bool]$ticket.authority.realSmsSendAuthorized -and
  -not [bool]$ticket.authority.youtubeQuotaOrEmailSubmissionAuthorized -and
  -not [bool]$ticket.authority.fundsAuthorized
) -Message 'ticket identity, no-regression rule or authority changed.'

$resolvedStatePath = Resolve-C33LFile -Path $StatePath -Label 'C33L state'
$stateRaw = Get-Content -Raw -LiteralPath $resolvedStatePath
Assert-C33LSanitizedText -Text $stateRaw -Label 'C33L state'
$state = $stateRaw | ConvertFrom-Json
$aggregatePath = Resolve-C33LFile `
  -Path ([string]$state.aggregateStatePath) `
  -Label 'C33L aggregate'
$aggregateRaw = Get-Content -Raw -LiteralPath $aggregatePath
Assert-C33LSanitizedText -Text $aggregateRaw -Label 'C33L aggregate'
$aggregate = $aggregateRaw | ConvertFrom-Json

Assert-C33L -Condition (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq
    'MOOLSOCIAL-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.ticketId -ceq $ticketId -and
  [string]$state.repositoryIdentity.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.repositoryIdentity.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.versionName -ceq '1.0.0-r60.50' -and
  [string]$state.candidate.versionCode -ceq '2026081350' -and
  [string]$state.candidate.authorizedTrack -ceq 'internal' -and
  [string]$state.candidate.playTrack -ceq 'internal' -and
  [string]$state.candidate.deviceSerial -ceq '2b3e0f71' -and
  [string]$state.candidate.deviceModel -ceq 'CPH2375'
) -Message 'state repository, candidate, package, track or OPPO identity changed.'
Assert-C33L -Condition (
  [string]$aggregate.contractId -ceq
    'MOOLSOCIAL-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-RELEASE-AGGREGATE-001' -and
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.versionName -ceq '1.0.0-r60.50' -and
  [string]$aggregate.candidate.versionCode -ceq '2026081350'
) -Message 'aggregate identity or candidate changed.'

$historicalPath = Resolve-C33LFile `
  -Path ([string]$state.historicalFailedCandidate.statePath) `
  -Label 'failed r60.49 state'
$historical = Get-Content -Raw -LiteralPath $historicalPath | ConvertFrom-Json
Assert-C33L -Condition (
  [string]$historical.machineState -ceq
    'acceptance_failed_r60_49_google_auth_guest_feed_social_identity_and_create_crash_successor_required' -and
  [string]$historical.candidate.versionName -ceq '1.0.0-r60.49' -and
  [string]$historical.candidate.versionCode -ceq '2026081349' -and
  [int]$historical.buildResult.buildCount -eq 1 -and
  [int]$historical.playResult.uploadCount -eq 1 -and
  [int]$historical.installResult.installCount -eq 1 -and
  [int]$historical.actionCounts.deviceAcceptance -eq 0 -and
  [string]$historical.buildAuthorization -ceq 'consumed' -and
  [string]$historical.uploadAuthorization -ceq 'consumed' -and
  [string]$historical.installAuthorization -ceq 'consumed' -and
  [string]$historical.deviceAuthorization -ceq 'consumed' -and
  -not [bool]$historical.installResult.acceptanceSucceeded -and
  [int]$state.historicalFailedCandidate.buildCount -eq 1 -and
  [int]$state.historicalFailedCandidate.uploadCount -eq 1 -and
  [int]$state.historicalFailedCandidate.installCount -eq 1 -and
  [int]$state.historicalFailedCandidate.deviceAcceptanceCount -eq 0 -and
  -not [bool]$state.historicalFailedCandidate.runtimeSuccessClaimed -and
  -not [bool]$state.historicalFailedCandidate.artifactReusable
) -Message 'failed r60.49 identity, 1/1/1/0 counts, consumed authorities or failure truth changed.'

$phoneState = Get-Content -Raw -LiteralPath (
  Resolve-C33LFile -Path ([string]$state.sourcePrerequisites.phoneReadinessPath) `
    -Label 'Phone readiness state'
) | ConvertFrom-Json
$emailSourceState = Get-Content -Raw -LiteralPath (
  Resolve-C33LFile -Path ([string]$state.sourcePrerequisites.emailSourceStatePath) `
    -Label 'email source state'
) | ConvertFrom-Json
$emailLiveState = Get-Content -Raw -LiteralPath (
  Resolve-C33LFile -Path ([string]$state.sourcePrerequisites.emailLiveReadinessPath) `
    -Label 'email live-readiness state'
) | ConvertFrom-Json
Assert-C33L -Condition (
  [string]$phoneState.state -ceq
    'source_qualified_prebuild_provider_prerequisites_qualified_candidate_device_pending' -and
  [bool]$phoneState.liveReadiness.phoneProviderEnabled -and
  [bool]$phoneState.liveReadiness.smsRegionPolicyQualified -and
  @($phoneState.liveReadiness.smsRegionPolicyRegions).Count -eq 1 -and
  [string]$phoneState.liveReadiness.smsRegionPolicyRegions[0] -ceq 'IN' -and
  -not [bool]$phoneState.liveReadiness.smsRegionPolicyRealSmsSent -and
  [bool]$emailSourceState.runtimeContract.coldStartEmailLinkOwner -and
  [bool]$emailSourceState.runtimeContract.foregroundEmailLinkOwner -and
  [bool]$emailSourceState.runtimeContract.exactPendingDestinationProviderAndDelegate -and
  [string]$emailLiveState.state -ceq
    'live_readiness_qualified_two_exact_configuration_writes_consumed' -and
  [bool]$emailLiveState.sanitizedAfterFacts.phoneProviderEnabled -and
  [bool]$emailLiveState.sanitizedAfterFacts.googleProviderEnabled -and
  [bool]$emailLiveState.sanitizedAfterFacts.emailPasswordProviderEnabled -and
  [bool]$emailLiveState.sanitizedAfterFacts.passwordlessEmailLinkEnabled -and
  [bool]$emailLiveState.sanitizedAfterFacts.moolSocialDomainAuthorized -and
  [int]$emailLiveState.actionCounts.emailProviderEnablement -eq 1 -and
  [int]$emailLiveState.actionCounts.authorizedDomainAddition -eq 1 -and
  [int]$emailLiveState.actionCounts.liveEmailSend -eq 0 -and
  [int]$emailLiveState.actionCounts.aabBuild -eq 0 -and
  [int]$emailLiveState.actionCounts.playUploadOrActivation -eq 0 -and
  [int]$emailLiveState.actionCounts.oppoMutation -eq 0 -and
  -not [bool]$emailLiveState.privacy.secretValuesObserved -and
  -not [bool]$emailLiveState.privacy.emailAddressObservedOrEntered
) -Message 'Phone or passwordless-email sanitized readiness changed.'

Assert-C33L -Condition (
  [bool]$state.promotionRule.allApplicableHistoricalRegressionGatesMustPassBeforeBuild -and
  [bool]$state.promotionRule.registrySealMustRemainExactThroughPromotion -and
  [bool]$state.promotionRule.zeroNewIssuesAfterBuildRequired -and
  [bool]$state.promotionRule.zeroNewDefectsAfterBuildRequired -and
  [bool]$state.promotionRule.zeroHistoricalRegressionRepeatsAcrossAabDeploymentOppoOrProduction -and
  [bool]$state.regressionMemory.postSealRegistryChangeRejectsBuildOrPromotion -and
  [bool]$state.regressionMemory.anyHistoricalOrNewRegressionRejectsCandidate -and
  [bool]$state.regressionMemory.exactRepairTicketBeforeRetryRequired -and
  -not [bool]$state.regressionMemory.waiversAllowed -and
  -not [bool]$state.promotionRule.waiversAllowed -and
  -not [bool]$state.promotionRule.productionReadinessClaimBeforeAllAcceptanceAllowed
) -Message 'no-regression fail-closed promotion rule changed.'
Assert-C33L -Condition (
  [bool]$state.authority.candidateIdentityApproved -and
  [bool]$state.authority.oneAabBuildAuthorizedAfterAllGates -and
  [bool]$state.authority.oneInternalTestingUploadAndActivationAuthorizedAfterPostbuild -and
  [bool]$state.authority.oneInPlaceOppoPlayUpdateAuthorizedAfterActivation -and
  [bool]$state.authority.oneFounderReviewedPasswordlessEmailAuthorizedAfterInstall -and
  -not [bool]$state.authority.agentSecretValueAccessAuthorized -and
  -not [bool]$state.authority.otherTrackAuthorized -and
  -not [bool]$state.authority.adbOrSideloadAuthorized -and
  -not [bool]$state.authority.backendOrHostingDeploymentAuthorized -and
  -not [bool]$state.authority.providerDeploymentAuthorized -and
  -not [bool]$state.authority.youtubeQuotaOrEmailSubmissionAuthorized -and
  -not [bool]$state.authority.realSmsSendAuthorized -and
  -not [bool]$state.authority.fundsAuthorized -and
  -not [bool]$state.privacyBoundary.secretValuesObserved -and
  -not [bool]$state.privacyBoundary.oauthClientIdentifierValuesObserved -and
  -not [bool]$state.privacyBoundary.tokenOrAttestationPayloadObserved -and
  -not [bool]$state.privacyBoundary.privateEmailLinkObserved -and
  -not [bool]$state.privacyBoundary.firebaseDebugLogRead
) -Message 'authority or privacy boundary changed.'
Assert-C33L -Condition (
  [int]$state.actionCounts.realSmsSend -eq 0 -and
  [int]$state.actionCounts.otherTrack -eq 0 -and
  [int]$state.actionCounts.backendHostingProviderOrProductionDeployment -eq 0 -and
  [int]$aggregate.actionCounts.realSmsSend -eq 0 -and
  [int]$aggregate.actionCounts.otherTrack -eq 0 -and
  [int]$aggregate.actionCounts.backendHostingProviderOrProductionDeployment -eq 0
) -Message 'forbidden action count advanced.'

$launcherPath = Resolve-C33LFile `
  -Path ([string]$state.releaseBinding.founderLauncher) `
  -Label 'C33L founder launcher'
$wrapperPath = Resolve-C33LFile `
  -Path ([string]$state.releaseBinding.authoritativeAabWrapper) `
  -Label 'generic single-AAB wrapper'
Assert-C33LPowerShellOwner -Path $launcherPath -Label 'C33L founder launcher'
Assert-C33LPowerShellOwner -Path $wrapperPath -Label 'generic single-AAB wrapper'
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$gateNeedle = 'scripts/check-uaw-c33l-r60-50-authentication-no-regression-release-readiness.ps1'
$gateIndex = $launcher.IndexOf($gateNeedle, [StringComparison]::Ordinal)
$promptIndex = $launcher.IndexOf('$uploadSecure = Read-Host', [StringComparison]::Ordinal)
$wrapperIndex = $launcher.IndexOf('& $wrapperPath -StatePath $statePath -RepositoryRoot $root', [StringComparison]::Ordinal)
Assert-C33L -Condition (
  $gateIndex -ge 0 -and
  $promptIndex -gt $gateIndex -and
  $wrapperIndex -gt $promptIndex -and
  [regex]::Matches($launcher, 'Read-Host[^\r\n]*-AsSecureString').Count -eq 3 -and
  $launcher.IndexOf('ZeroFreeBSTR', [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf("SetEnvironmentVariable(`$name, `$null, 'Process')", [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf('Remove-Item -LiteralPath $path -Force', [StringComparison]::Ordinal) -ge 0
) -Message 'founder launcher ordering, three hidden prompts or cleanup changed.'
foreach ($forbidden in @(
  'Write-Host $uploadPassword',
  'Write-Output $uploadPassword',
  'Write-Host $firebaseKey',
  'Write-Output $firebaseKey',
  'Write-Host $googleServerClientId',
  'Write-Output $googleServerClientId',
  'Set-Clipboard',
  'Get-Clipboard'
)) {
  Assert-C33L -Condition (
    $launcher.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -lt 0
  ) -Message "founder launcher contains forbidden output or clipboard owner: $forbidden"
}
Assert-C33L -Condition (
  $wrapper.IndexOf(
    "'MOOLSOCIAL-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33l-r60-50-authentication-no-regression-release-readiness.ps1' }",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $wrapper.IndexOf('& $gate -Phase build', [StringComparison]::Ordinal) -lt
    $wrapper.IndexOf("`$state.buildAuthorization = 'consumed'", [StringComparison]::Ordinal) -and
  [regex]::Matches($wrapper, "'appbundle'").Count -eq 1
) -Message 'generic wrapper C33L binding, gate order or single appbundle owner changed.'

$scopeGate = Resolve-C33LFile -Path 'scripts/check-mvp-scope-gate-state.ps1' -Label 'MVP scope gate'
& $scopeGate `
  -StatePath $ScopePath `
  -CandidateId $ticketId `
  -RequireExecutionAuthorized `
  -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C33LFile `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression-memory gate'
$memoryPhase = if ($Phase -in @('postinstall', 'journey')) {
  'device'
} elseif ($Phase -eq 'source') {
  'implementation'
} else {
  'build'
}
$memoryBuildMode = if ($memoryPhase -ceq 'build') { 'release' } else { 'none' }
& $memoryGate `
  -Phase $memoryPhase `
  -BuildMode $memoryBuildMode `
  -RepositoryRoot $root | Out-Null

$phoneGate = Resolve-C33LFile `
  -Path ([string]$state.sourcePrerequisites.phoneGatePath) `
  -Label 'Phone source gate'
& $phoneGate -Phase source -RepositoryRoot $root | Out-Null
$blockerGate = Resolve-C33LFile `
  -Path ([string]$state.sourcePrerequisites.blockerGatePath) `
  -Label 'C33G blocker gate'
if ($Phase -in @('postinstall', 'journey')) {
  & $blockerGate `
    -CandidateId $ticketId `
    -CandidateVersionCode '2026081350' `
    -Phase postinstall `
    -RepositoryRoot $root | Out-Null
} else {
  & $blockerGate `
    -CandidateId $ticketId `
    -CandidateVersionCode '2026081350' `
    -Phase prebuild `
    -RepositoryRoot $root | Out-Null
}
$googleStatePath = Resolve-C33LFile `
  -Path ([string]$state.sourcePrerequisites.googleLiveReadinessPath) `
  -Label 'Google live-readiness state'
$googleStateRaw = Get-Content -Raw -LiteralPath $googleStatePath
Assert-C33LSanitizedText -Text $googleStateRaw -Label 'Google live-readiness state'
$googleState = $googleStateRaw | ConvertFrom-Json
$googleFacts = @($googleState.readinessFacts)
$requiredGoogleFacts = @(
  'firebase_android_app_play_signer',
  'firebase_google_provider_enabled',
  'android_oauth_package_play_signer_relationship',
  'web_server_client_mobile_relationship'
)
Assert-C33L -Condition (
  [string]$googleState.contractId -ceq
    'GOOGLE-AUTH-LIVE-PROVIDER-READINESS-C33E-FIX2-001' -and
  [string]$googleState.machineState -ceq
    'qualified_sanitized_non_secret_evidence_release_gate_open_for_separately_authorized_candidate' -and
  [string]$googleState.applicationIdentity.project -ceq 'moolsocial-dev-503018' -and
  [string]$googleState.applicationIdentity.package -ceq 'com.moolsocial.app' -and
  [string]$googleState.applicationIdentity.authorizedTrack -ceq 'Internal Testing' -and
  $googleFacts.Count -eq 4 -and
  -not [bool]$googleState.privacyBoundary.secretValuesObserved -and
  -not [bool]$googleState.privacyBoundary.privateAccountIdentifiersObserved -and
  -not [bool]$googleState.privacyBoundary.oauthClientIdentifierValuesObserved -and
  -not [bool]$googleState.privacyBoundary.tokenOrAttestationPayloadObserved -and
  -not [bool]$googleState.privacyBoundary.firebaseDebugLogRead
) -Message 'sanitized Google readiness identity, fact count or privacy boundary changed.'
$googleFactIds = @($googleFacts | ForEach-Object { [string]$_.id })
Assert-C33L -Condition (
  @($googleFactIds | Select-Object -Unique).Count -eq 4 -and
  @($requiredGoogleFacts | Where-Object { $_ -cnotin $googleFactIds }).Count -eq 0
) -Message 'sanitized Google readiness fact identifiers changed.'
foreach ($googleFact in $googleFacts) {
  Assert-C33L -Condition (
    [string]$googleFact.status -ceq 'qualified_sanitized_non_secret_evidence' -and
    [string]$googleFact.evidenceSha256 -match '^[0-9A-F]{64}$'
  ) -Message "Google readiness fact is not qualified: $($googleFact.id)"
  $googleEvidencePath = Resolve-C33LFile `
    -Path ([string]$googleFact.evidencePath) `
    -Label "Google readiness evidence $($googleFact.id)"
  Assert-C33L -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $googleEvidencePath).Hash -ceq
      [string]$googleFact.evidenceSha256
  ) -Message "Google readiness evidence changed: $($googleFact.id)"
}
$runtimeGate = Resolve-C33LFile `
  -Path ([string]$state.sourcePrerequisites.releaseRuntimeGatePath) `
  -Label 'C30W release-runtime gate'
if ($Phase -ceq 'source') {
  & $runtimeGate -Phase source -StatePath $resolvedStatePath -RepositoryRoot $root | Out-Null
}

$registryPath = Resolve-C33LFile `
  -Path ([string]$state.regressionMemory.registryPath) `
  -Label 'regression registry'
$registryRaw = Get-Content -Raw -LiteralPath $registryPath
Assert-C33LSanitizedText -Text $registryRaw -Label 'regression registry'
$registry = $registryRaw | ConvertFrom-Json
$registryCount = @($registry.entries).Count
$registrySha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $registryPath).Hash
$cycles = [int]$state.sourceQualification.completedIdenticalCycles
$sourceQualified = (
  $cycles -eq 2 -and
  [int]$state.sourceQualification.requiredIdenticalCycles -eq 2 -and
  [bool]$state.regressionMemory.allEntriesAppliedBeforeSeal -and
  [int]$state.regressionMemory.sealedRegistryEntryCount -eq $registryCount -and
  [string]$state.regressionMemory.sealedRegistrySha256 -ceq $registrySha256 -and
  [int]$aggregate.regressionMemory.sealedRegistryEntryCount -eq $registryCount -and
  [string]$aggregate.regressionMemory.sealedRegistrySha256 -ceq $registrySha256 -and
  [bool]$state.sourceQualification.wholeMobileAnalyzerPassed -and
  [bool]$state.sourceQualification.flutterTestsPassed -and
  [bool]$state.sourceQualification.backendTestsPassed -and
  [bool]$state.sourceQualification.hostingTestsPassed -and
  [bool]$state.sourceQualification.dualPowerShellHostsPassed -and
  [bool]$state.sourceQualification.zeroFailures -and
  [bool]$aggregate.sourceQualification.zeroFailures -and
  @($state.sourceQualification.cycleEvidence).Count -eq 2 -and
  @($aggregate.sourceQualification.cycleEvidence).Count -eq 2
)
if ($cycles -eq 0) {
  Assert-C33L -Condition (
    [string]$state.machineState -ceq
      'prebuild_composition_registered_two_fresh_cycles_required' -and
    [string]$state.buildAuthorization -ceq 'held_source_qualification' -and
    [string]$aggregate.releaseAuthorities.build -ceq 'held_source_qualification' -and
    [int]$aggregate.sourceQualification.completedIdenticalCycles -eq 0
  ) -Message 'unqualified source state or held build authority changed.'
} else {
  Assert-C33L -Condition $sourceQualified `
    -Message 'two identical zero-failure cycles or exact regression-registry seal is incomplete.'
  Assert-C33L -Condition (
    [int]$aggregate.sourceQualification.completedIdenticalCycles -eq 2 -and
    [string]$aggregate.sourceQualification.manifestPath -ceq
      [string]$state.sourceQualification.manifestPath -and
    [string]$aggregate.sourceQualification.manifestSha256 -ceq
      [string]$state.sourceQualification.manifestSha256 -and
    [string]$aggregate.sourceQualification.focusedManifestSha256 -ceq
      [string]$state.sourceQualification.focusedManifestSha256
  ) -Message 'source qualification aggregate mirror changed.'
  $manifestPath = Resolve-C33LFile `
    -Path ([string]$state.sourceQualification.manifestPath) `
    -Label 'sealed source manifest'
  Assert-C33L -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash -ceq
      [string]$state.sourceQualification.manifestSha256
  ) -Message 'sealed source-manifest file changed.'
  Assert-C33LManifestCurrent -ManifestPath $manifestPath
  $focusedManifestPath = Resolve-C33LFile `
    -Path ([string]$state.sourceQualification.focusedManifestPath) `
    -Label 'focused test manifest'
  Assert-C33L -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $focusedManifestPath).Hash -ceq
      [string]$state.sourceQualification.focusedManifestSha256
  ) -Message 'focused test manifest changed.'
}

Assert-C33L -Condition (
  [int]$state.actionCounts.build -eq [int]$aggregate.actionCounts.build -and
  [int]$state.actionCounts.upload -eq [int]$aggregate.actionCounts.upload -and
  [int]$state.actionCounts.install -eq [int]$aggregate.actionCounts.install -and
  [int]$state.actionCounts.deviceAcceptance -eq [int]$aggregate.actionCounts.deviceAcceptance -and
  [int]$state.actionCounts.passwordlessEmailSend -eq [int]$aggregate.actionCounts.passwordlessEmailSend
) -Message 'state/aggregate action-count mirror changed.'

if ($Phase -ceq 'build') {
  Assert-C33L -Condition $sourceQualified `
    -Message 'build requires two identical zero-failure cycles and the exact registry seal.'
  Assert-C33L -Condition (
    [string]$state.machineState -ceq
      'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required' -and
    [string]$state.buildAuthorization -ceq 'available_once' -and
    [string]$aggregate.releaseAuthorities.build -ceq 'available_once' -and
    [string]$state.buildResult.state -ceq 'not_started' -and
    [int]$state.buildResult.buildCount -eq 0 -and
    [int]$state.actionCounts.build -eq 0 -and
    -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered
  ) -Message 'single AAB authority is unavailable, consumed, already prompted or not fully qualified.'
}

if ($Phase -ceq 'postbuild') {
  Assert-C33L -Condition (
    [string]$state.buildAuthorization -ceq 'consumed' -and
    [int]$state.buildResult.buildCount -eq 1 -and
    [int]$state.buildResult.wrapperInvocationCount -eq 1 -and
    [int]$state.buildResult.configOnlyCount -eq 1 -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 0 -and
    [int]$state.actionCounts.install -eq 0 -and
    [regex]::IsMatch([string]$state.buildResult.artifactSha256, '^[0-9A-F]{64}$') -and
    [int64]$state.buildResult.artifactBytes -gt 0 -and
    [bool]$state.buildResult.packageVersionManifestProved -and
    [bool]$state.buildResult.googleAppIdResourceProved -and
    [bool]$state.buildResult.crashlyticsBuildIdResourceProved -and
    [bool]$state.buildResult.splitAndArm64PayloadProved -and
    [bool]$state.buildResult.mergedReleaseManifestProved
  ) -Message 'postbuild artifact, count or payload qualification is incomplete.'
}

if ($Phase -ceq 'preupload') {
  Assert-C33L -Condition (
    [string]$state.uploadAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq 'available_once' -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 0 -and
    [int]$state.actionCounts.install -eq 0
  ) -Message 'Internal Testing upload authority or action counts are not ready.'
}

if ($Phase -ceq 'postupload') {
  Assert-C33L -Condition (
    [string]$state.uploadAuthorization -ceq 'consumed' -and
    [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq 'consumed' -and
    [int]$state.playResult.uploadCount -eq 1 -and
    [int]$state.playResult.internalActivationCount -eq 1 -and
    [int]$state.actionCounts.upload -eq 1 -and
    [int]$state.actionCounts.install -eq 0 -and
    -not [string]::IsNullOrWhiteSpace([string]$state.playResult.evidencePath)
  ) -Message 'Internal Testing upload/activation evidence or one-action count is incomplete.'
}

if ($Phase -ceq 'preinstall') {
  Assert-C33L -Condition (
    [string]$state.installAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq 'available_once' -and
    [int]$state.actionCounts.upload -eq 1 -and
    [int]$state.actionCounts.install -eq 0
  ) -Message 'one in-place OPPO Play-update authority or action counts are not ready.'
}

if ($Phase -in @('postinstall', 'journey')) {
  Assert-C33L -Condition (
    [string]$state.installAuthorization -ceq 'consumed' -and
    [int]$state.installResult.installCount -eq 1 -and
    [int]$state.actionCounts.install -eq 1 -and
    -not [string]::IsNullOrWhiteSpace([string]$state.installResult.coldStartEvidencePath) -and
    -not [string]::IsNullOrWhiteSpace([string]$state.installResult.retainedDataEvidencePath)
  ) -Message 'one in-place OPPO Play update or cold-start/retained-data evidence is incomplete.'
  & $runtimeGate `
    -Phase postinstall `
    -StatePath $resolvedStatePath `
    -AcceptanceEvidencePath ([string]$state.installResult.coldStartEvidencePath) `
    -RepositoryRoot $root | Out-Null
}

if ($Phase -ceq 'journey') {
  Assert-C33L -Condition (
    [int]$state.actionCounts.deviceAcceptance -eq 1 -and
    [int]$aggregate.actionCounts.deviceAcceptance -eq 1 -and
    [bool]$state.installResult.acceptanceSucceeded -and
    -not [string]::IsNullOrWhiteSpace([string]$state.installResult.journeyEvidencePath) -and
    [int]$state.actionCounts.passwordlessEmailSend -eq 1 -and
    [int]$state.actionCounts.realSmsSend -eq 0
  ) -Message 'complete Google, Phone, email, Social and whole-app device acceptance is incomplete.'
}

Write-Output (
  'C33L r60.50 no-regression release gate passed: ' +
  "phase=$Phase; registryEntries=$registryCount; sourceCycles=$cycles/2; " +
  "buildCount=$($state.actionCounts.build); uploadCount=$($state.actionCounts.upload); " +
  "installCount=$($state.actionCounts.install); deviceAcceptanceCount=$($state.actionCounts.deviceAcceptance); " +
  'historicalRepeatAllowed=false; newDefectAllowed=false; waivers=false; secretValuesObserved=false.'
)
