[CmdletBinding()]
param(
  [ValidateSet('implementation', 'build')]
  [string]$Phase = 'implementation',

  [string]$StatePath = 'config/google-auth-live-provider-readiness-state-c33e-fix2.json',

  [string]$ScopePath = 'config/mvp-scope-gate-state.json',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33EFix2 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33E FIX2 Google auth readiness gate rejected: $Message"
  }
}

function Resolve-C33EFix2File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33EFix2 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

function Assert-C33EFix2SanitizedText {
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][string]$Label
  )
  $secretValuePatterns = @(
    'AIza[0-9A-Za-z_-]{35}',
    '[0-9]{6,}-[0-9A-Za-z_-]+[.]apps[.]googleusercontent[.]com',
    'Bearer\s+[A-Za-z0-9._~+/-]+=*',
    '-----BEGIN [^-]*PRIVATE KEY-----',
    'eyJ[A-Za-z0-9_-]+[.]eyJ[A-Za-z0-9_-]+[.][A-Za-z0-9_-]+'
  )
  foreach ($pattern in $secretValuePatterns) {
    Assert-C33EFix2 -Condition (-not [regex]::IsMatch($Text, $pattern)) `
      -Message "$Label contains a credential-, token- or private-key-shaped value."
  }
  $forbiddenPropertyPattern =
    '(?i)"(?:apiKey|oauthClientId|clientSecret|accessToken|refreshToken|idToken|nonce|privateKey|attestationPayload|appCheckToken)"\s*:'
  Assert-C33EFix2 -Condition (
    -not [regex]::IsMatch($Text, $forbiddenPropertyPattern)
  ) -Message "$Label contains a forbidden private-value property."
}

$ticketPath = Resolve-C33EFix2File `
  -Path 'config/uaw-c33e-fix2-google-auth-live-provider-readiness-hard-gate-ticket.json' `
  -Label 'C33E FIX2 ticket'
$ticketSha256 = 'DFECEF0BBBC320472AB0267BE293CC836FBD1C12FEDF6B61C8048FF0ED1A74F1'
Assert-C33EFix2 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    $ticketSha256
) -Message 'C33E FIX2 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33EFix2 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C33E-FIX2-GOOGLE-AUTH-LIVE-PROVIDER-READINESS-HARD-GATE' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.runtimeSourceWriteAuthorized -and
  -not [bool]$ticket.authority.backendSourceWriteAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'ticket identity, classification or authority changed.'
$fix3TicketPath = Resolve-C33EFix2File `
  -Path 'config/uaw-c33e-fix3-social-auth-rollback-independent-cleanup-ticket.json' `
  -Label 'C33E FIX3 successor ticket'
$fix3TicketSha256 = 'C0DC198E6CB37F1AFB8D8EF73D05390F1EF0E9BB089E0FB4A218F4975C07CFD9'
Assert-C33EFix2 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $fix3TicketPath).Hash -ceq
    $fix3TicketSha256
) -Message 'C33E FIX3 successor ticket bytes changed.'
$fix3Ticket = Get-Content -Raw -LiteralPath $fix3TicketPath | ConvertFrom-Json
Assert-C33EFix2 -Condition (
  [string]$fix3Ticket.ticketId -ceq
    'UAW-C33E-FIX3-SOCIAL-AUTH-ROLLBACK-INDEPENDENT-CLEANUP' -and
  [bool]$fix3Ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$fix3Ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$fix3Ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$fix3Ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$fix3Ticket.authority.secretValueAccessAuthorized
) -Message 'C33E FIX3 successor identity or authority changed.'
$fix4TicketPath = Resolve-C33EFix2File `
  -Path 'config/uaw-c33e-fix4-protected-social-action-intent-return-continuity-ticket.json' `
  -Label 'C33E FIX4 successor ticket'
$fix4TicketSha256 = 'E243C28BEEB4732C8F512053146C41229AAD9E3109C87A3C99D041FA79499047'
Assert-C33EFix2 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $fix4TicketPath).Hash -ceq
    $fix4TicketSha256
) -Message 'C33E FIX4 successor ticket bytes changed.'
$fix4Ticket = Get-Content -Raw -LiteralPath $fix4TicketPath | ConvertFrom-Json
Assert-C33EFix2 -Condition (
  [string]$fix4Ticket.ticketId -ceq
    'UAW-C33E-FIX4-PROTECTED-SOCIAL-ACTION-INTENT-RETURN-CONTINUITY' -and
  [bool]$fix4Ticket.authority.runtimeSourceWriteAuthorized -and
  [bool]$fix4Ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$fix4Ticket.authority.buildPlayOrDeviceInstallAuthorized -and
  -not [bool]$fix4Ticket.authority.providerOrExternalServiceAuthorized -and
  -not [bool]$fix4Ticket.authority.secretValueAccessAuthorized
) -Message 'C33E FIX4 successor identity or authority changed.'
$c33fTicketPath = Resolve-C33EFix2File `
  -Path 'config/uaw-c33f-r60-49-google-auth-successor-aab-play-internal-oppo-acceptance-ticket.json' `
  -Label 'C33F successor release ticket'
$c33fTicketSha256 = '815C70015058DE27B0F117517FB7599F6D7D99D340A217D65F9BFF3E163660C2'
Assert-C33EFix2 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $c33fTicketPath).Hash -ceq
    $c33fTicketSha256
) -Message 'C33F successor release ticket bytes changed.'
$c33fTicket = Get-Content -Raw -LiteralPath $c33fTicketPath | ConvertFrom-Json
Assert-C33EFix2 -Condition (
  [string]$c33fTicket.ticketId -ceq
    'UAW-C33F-R60-49-GOOGLE-AUTH-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE' -and
  [string]$c33fTicket.candidate.versionName -ceq '1.0.0-r60.49' -and
  [string]$c33fTicket.candidate.versionCode -ceq '2026081349' -and
  [bool]$c33fTicket.authority.oneAabBuildAuthorizedAfterAllGates -and
  -not [bool]$c33fTicket.authority.agentSecretValueAccessAuthorized -and
  -not [bool]$c33fTicket.authority.otherTrackAuthorized -and
  -not [bool]$c33fTicket.authority.adbOrSideloadAuthorized -and
  -not [bool]$c33fTicket.authority.backendOrHostingDeploymentAuthorized -and
  -not [bool]$c33fTicket.authority.providerDeploymentAuthorized -and
  -not [bool]$c33fTicket.authority.emailOrQuotaSubmissionAuthorized
) -Message 'C33F successor release identity or authority changed.'

$resolvedStatePath = Resolve-C33EFix2File -Path $StatePath -Label 'readiness state'
$stateRaw = Get-Content -Raw -LiteralPath $resolvedStatePath
Assert-C33EFix2SanitizedText -Text $stateRaw -Label 'readiness state'
$state = $stateRaw | ConvertFrom-Json
Assert-C33EFix2 -Condition (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq
    'GOOGLE-AUTH-LIVE-PROVIDER-READINESS-C33E-FIX2-001' -and
  [string]$state.ticketId -ceq [string]$ticket.ticketId -and
  [string]$state.repositoryIdentity.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.repositoryIdentity.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  [string]$state.applicationIdentity.project -ceq 'moolsocial-dev-503018' -and
  [string]$state.applicationIdentity.package -ceq 'com.moolsocial.app' -and
  [string]$state.applicationIdentity.authorizedTrack -ceq 'Internal Testing'
) -Message 'repository, application or contract identity changed.'
Assert-C33EFix2 -Condition (
  [string]$state.failedCandidateBinding.candidate -ceq
    '1.0.0-r60.48+2026081348' -and
  [string]$state.failedCandidateBinding.state -ceq
    'acceptance_failed_social_auth_and_action_journey_defects_successor_required' -and
  [int]$state.failedCandidateBinding.buildCount -eq 1 -and
  [int]$state.failedCandidateBinding.uploadCount -eq 1 -and
  [int]$state.failedCandidateBinding.installCount -eq 1 -and
  -not [bool]$state.failedCandidateBinding.runtimeSuccessClaimed -and
  -not [bool]$state.failedCandidateBinding.sourceRepairContainedInInstalledCandidate
) -Message 'failed r60.48 identity, counts or failure truth changed.'

$sourceTicketPath = Resolve-C33EFix2File `
  -Path ([string]$state.sourceRepairBinding.ticketPath) `
  -Label 'C30Z source-repair ticket'
Assert-C33EFix2 -Condition (
  [string]$state.sourceRepairBinding.ticketId -ceq
    'UAW-C30Z-R60-48-AUTHENTICATION-METHOD-TRUTH-AND-GUEST-FEED-RECOVERY' -and
  [string]$state.sourceRepairBinding.ticketSha256 -ceq
    '5A03AD26DAE2AAA9CD724A1F05AE1D0CE0FB4F0D5DFEEFB05AF3DDE58F7B1AD8' -and
  (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceTicketPath).Hash -ceq
    [string]$state.sourceRepairBinding.ticketSha256 -and
  [string]$state.sourceRepairBinding.qualificationState -ceq
    'two_identical_cycles_passed_partial_ticket_qualification' -and
  [string]$state.sourceRepairBinding.historicalCountsPreserved -ceq '1/1/1' -and
  [string]$state.sourceRepairBinding.newReleaseActions -ceq '0/0/0'
) -Message 'C30Z source-repair binding changed.'

$privacy = $state.privacyBoundary
Assert-C33EFix2 -Condition (
  -not [bool]$privacy.secretValuesObserved -and
  -not [bool]$privacy.privateAccountIdentifiersObserved -and
  -not [bool]$privacy.oauthClientIdentifierValuesObserved -and
  -not [bool]$privacy.tokenOrAttestationPayloadObserved -and
  -not [bool]$privacy.firebaseDebugLogRead
) -Message 'privacy boundary records private data observation.'
$authority = $state.authority
Assert-C33EFix2 -Condition (
  [bool]$authority.ticketAndEvidenceWriteAuthorized -and
  [bool]$authority.testAndGateWriteAuthorized -and
  -not [bool]$authority.runtimeSourceWriteAuthorized -and
  -not [bool]$authority.backendSourceWriteAuthorized -and
  -not [bool]$authority.buildAuthorized -and
  -not [bool]$authority.playUploadOrActivationAuthorized -and
  -not [bool]$authority.deviceInstallOrUpdateAuthorized -and
  -not [bool]$authority.providerOrExternalServiceAuthorized -and
  -not [bool]$authority.secretValueAccessAuthorized
) -Message 'readiness state grants forbidden authority.'

$requiredFactIds = @(
  'firebase_android_app_play_signer',
  'firebase_google_provider_enabled',
  'android_oauth_package_play_signer_relationship',
  'web_server_client_mobile_relationship'
)
$facts = @($state.readinessFacts)
$factIds = @($facts | ForEach-Object { [string]$_.id })
Assert-C33EFix2 -Condition (
  $facts.Count -eq $requiredFactIds.Count -and
  @($factIds | Select-Object -Unique).Count -eq $requiredFactIds.Count -and
  @($factIds | Where-Object { $requiredFactIds -cnotcontains $_ }).Count -eq 0
) -Message 'the four exact readiness facts are missing or duplicated.'

$qualifiedCount = 0
foreach ($fact in $facts) {
  $status = [string]$fact.status
  Assert-C33EFix2 -Condition (
    @(
      'pending_sanitized_evidence',
      'qualified_sanitized_non_secret_evidence',
      'failed_sanitized_evidence'
    ) -ccontains $status
  ) -Message "readiness fact $($fact.id) has an unsupported status."
  if ($status -ceq 'qualified_sanitized_non_secret_evidence') {
    $qualifiedCount++
    Assert-C33EFix2 -Condition (
      -not [string]::IsNullOrWhiteSpace([string]$fact.evidencePath) -and
      [regex]::IsMatch([string]$fact.evidenceSha256, '^[0-9A-F]{64}$')
    ) -Message "qualified readiness fact $($fact.id) lacks evidence identity."
    $evidencePath = Resolve-C33EFix2File `
      -Path ([string]$fact.evidencePath) `
      -Label "readiness evidence $($fact.id)"
    Assert-C33EFix2 -Condition (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $evidencePath).Hash -ceq
        [string]$fact.evidenceSha256
    ) -Message "readiness evidence hash changed for $($fact.id)."
    $evidenceRaw = Get-Content -Raw -LiteralPath $evidencePath
    Assert-C33EFix2SanitizedText -Text $evidenceRaw `
      -Label "readiness evidence $($fact.id)"
    $evidence = $evidenceRaw | ConvertFrom-Json
    Assert-C33EFix2 -Condition (
      [int]$evidence.schemaVersion -eq 1 -and
      [string]$evidence.contractId -ceq
        'GOOGLE-AUTH-LIVE-READINESS-EVIDENCE-C33E-FIX2-001' -and
      [string]$evidence.factId -ceq [string]$fact.id -and
      [string]$evidence.result -ceq 'qualified' -and
      [string]$evidence.project -ceq 'moolsocial-dev-503018' -and
      [string]$evidence.package -ceq 'com.moolsocial.app' -and
      -not [string]::IsNullOrWhiteSpace([string]$evidence.verifiedAtUtc) -and
      -not [bool]$evidence.secretValuesObserved -and
      -not [bool]$evidence.privateAccountIdentifiersObserved -and
      -not [bool]$evidence.oauthClientIdentifierValuesObserved
    ) -Message "readiness evidence contract failed for $($fact.id)."
  } else {
    Assert-C33EFix2 -Condition (
      [string]::IsNullOrWhiteSpace([string]$fact.evidencePath) -and
      [string]::IsNullOrWhiteSpace([string]$fact.evidenceSha256)
    ) -Message "unqualified readiness fact $($fact.id) must not cite evidence."
  }
}

$fullyQualified = $qualifiedCount -eq $requiredFactIds.Count
$expectedMachineState = if ($fullyQualified) {
  'qualified_sanitized_non_secret_evidence_release_gate_open_for_separately_authorized_candidate'
} else {
  'pending_sanitized_non_secret_console_evidence_release_blocked'
}
Assert-C33EFix2 -Condition (
  [string]$state.machineState -ceq $expectedMachineState
) -Message 'machine state does not match readiness fact qualification.'

$wrapperPath = Resolve-C33EFix2File `
  -Path ([string]$state.releaseBinding.authoritativeAabWrapper) `
  -Label 'authoritative AAB wrapper'
$launcherPath = Resolve-C33EFix2File `
  -Path ([string]$state.releaseBinding.founderLauncher) `
  -Label 'founder launcher'
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$gateNeedle = 'check-uaw-c33e-fix2-google-auth-live-provider-readiness.ps1'
$wrapperGateIndex = $wrapper.IndexOf($gateNeedle, [StringComparison]::Ordinal)
$wrapperConsumeIndex = $wrapper.IndexOf(
  '$state.buildAuthorization = ''consumed''',
  [StringComparison]::Ordinal
)
$launcherGateIndex = $launcher.IndexOf($gateNeedle, [StringComparison]::Ordinal)
$launcherPromptIndex = $launcher.IndexOf(
  "Read-Host 'Enter the moolsocial-upload-2026 password'",
  [StringComparison]::Ordinal
)
Assert-C33EFix2 -Condition (
  [bool]$state.releaseBinding.gateRequiredBeforeFounderPrompt -and
  [bool]$state.releaseBinding.gateRequiredBeforeAabAuthorityConsumption -and
  $wrapperGateIndex -ge 0 -and
  $wrapperConsumeIndex -gt $wrapperGateIndex -and
  $launcherGateIndex -ge 0 -and
  $launcherPromptIndex -gt $launcherGateIndex
) -Message 'readiness gate is not ordered before founder prompt and AAB authority consumption.'

if ($Phase -ceq 'implementation') {
  $resolvedScopePath = Resolve-C33EFix2File -Path $ScopePath -Label 'MVP scope state'
  $scope = Get-Content -Raw -LiteralPath $resolvedScopePath | ConvertFrom-Json
  $activeTicketId = [string]$scope.ticket.id
  $activeFix2 = $activeTicketId -ceq [string]$ticket.ticketId
  $activeFix3 = $activeTicketId -ceq [string]$fix3Ticket.ticketId
  $activeFix4 = $activeTicketId -ceq [string]$fix4Ticket.ticketId
  $activeC33F = $activeTicketId -ceq [string]$c33fTicket.ticketId
  $selectionValid = if ($activeFix2) {
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq
      [string]$ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
      [string]$ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
      $ticketSha256 -and
    -not [bool]$scope.execution.runtimeWriteAuthorized -and
    [string]$scope.providerGate.nextTicket -ceq [string]$ticket.ticketId
  } elseif ($activeFix3) {
    $activeFix3 -and
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq
      [string]$fix3Ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
      [string]$fix3Ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
      $fix3TicketSha256 -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix2QualifiedAssessment.ticketId -ceq
      [string]$ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix2QualifiedAssessment.manifestSha256 -ceq
      $ticketSha256 -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix2QualifiedAssessment.implementationState -ceq
      'dual_host_behavioral_and_pre_AAB_order_qualified_live_facts_pending' -and
    [bool]$scope.execution.runtimeWriteAuthorized -and
    [string]$scope.providerGate.nextTicket -ceq [string]$fix3Ticket.ticketId
  } elseif ($activeFix4) {
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq
      [string]$fix4Ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
      [string]$fix4Ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
      $fix4TicketSha256 -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix2QualifiedAssessment.ticketId -ceq
      [string]$ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix2QualifiedAssessment.manifestSha256 -ceq
      $ticketSha256 -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix2QualifiedAssessment.implementationState -ceq
      'dual_host_behavioral_and_pre_AAB_order_qualified_live_facts_pending' -and
    [bool]$scope.execution.runtimeWriteAuthorized -and
    [string]$scope.providerGate.nextTicket -ceq [string]$fix4Ticket.ticketId
  } else {
    $activeC33F -and
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq
      [string]$c33fTicket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
      [string]$c33fTicket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
      $c33fTicketSha256 -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix2QualifiedAssessment.ticketId -ceq
      [string]$ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix2QualifiedAssessment.manifestSha256 -ceq
      $ticketSha256 -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix4QualifiedAssessment.ticketId -ceq
      [string]$fix4Ticket.ticketId -and
    [string]$scope.preTicketSelectionCheckpoint.priorC33EFix4QualifiedAssessment.manifestSha256 -ceq
      $fix4TicketSha256 -and
    -not [bool]$scope.execution.runtimeWriteAuthorized -and
    [string]$scope.providerGate.nextTicket -ceq [string]$c33fTicket.ticketId
  }
  Assert-C33EFix2 -Condition (
    [string]$scope.state -ceq 'ticket_disclosed_and_authorized' -and
    $selectionValid -and
    -not [bool]$scope.execution.referenceWriteAuthorized -and
    [bool]$scope.execution.testOrGateWriteAuthorized -and
    -not [bool]$scope.execution.backendWriteAuthorized -and
    -not [bool]$scope.execution.buildAuthorized -and
    -not [bool]$scope.execution.deviceInstallAuthorized -and
    -not [bool]$scope.execution.externalServiceWriteAuthorized -and
    -not [bool]$scope.execution.secretValueAccessAuthorized -and
    -not [bool]$scope.providerGate.existingProtectedClientLaunchAndTapAuthorized -and
    -not [bool]$scope.providerGate.emailOrQuotaSubmissionAuthorized
  ) -Message 'active FIX2/FIX3/FIX4 lifecycle or authority boundary changed.'
  $c30zGate = Resolve-C33EFix2File `
    -Path 'scripts/check-c30z-authentication-method-truth-and-guest-feed-recovery.ps1' `
    -Label 'C30Z source gate'
  & $c30zGate -RepositoryRoot $root -ScopePath $ScopePath | Out-Null
} else {
  Assert-C33EFix2 -Condition $fullyQualified `
    -Message 'all four sanitized live-readiness facts must qualify before a build.'
}

Write-Output (
  'C33E FIX2 Google auth live readiness gate passed: ' +
  "phase=$Phase; qualifiedFacts=$qualifiedCount/$($requiredFactIds.Count); " +
  'secretValuesObserved=false; buildAuthorityCreated=false.'
)
