[CmdletBinding()]
param(
  [ValidateSet('source', 'preprompt', 'build', 'postbuild', 'preupload', 'postupload', 'preinstall', 'postinstall', 'journey')]
  [string]$Phase = 'source',

  [string]$StatePath = 'config/successor-aab-regression-hard-gate-state-c34d.json',

  [string]$ScopePath = 'config/mvp-scope-gate-state.json',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C34D {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34D r60.68 no-regression release gate rejected: $Message"
  }
}

function Resolve-C34DFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34D -Condition (-not [string]::IsNullOrWhiteSpace($Path)) `
    -Message "$Label path is empty."
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C34D -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

function Assert-C34DSanitizedText {
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
    Assert-C34D -Condition (-not [regex]::IsMatch($Text, $pattern)) `
      -Message "$Label contains a credential-, token- or private-key-shaped value."
  }
}

function Assert-C34DPowerShellOwner {
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
  Assert-C34D -Condition (@($errors).Count -eq 0) `
    -Message "$Label PowerShell parser rejected the current owner."
}

function Assert-C34DManifestCurrent {
  param([Parameter(Mandatory)][string]$ManifestPath)
  foreach ($line in Get-Content -LiteralPath $ManifestPath) {
    $match = [regex]::Match($line, '^([0-9A-F]{64})  (.+)$')
    Assert-C34D -Condition $match.Success -Message 'source-manifest row is malformed.'
    $owner = Resolve-C34DFile -Path $match.Groups[2].Value -Label 'sealed source owner'
    Assert-C34D -Condition (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq
        $match.Groups[1].Value
    ) -Message "source changed after qualification: $($match.Groups[2].Value)"
  }
}

$ticketId = 'UAW-C34D-R60-68-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE'
$ticketPath = Resolve-C34DFile `
  -Path 'config/uaw-c34d-r60-68-authentication-no-regression-play-oppo-acceptance-ticket.json' `
  -Label 'C34D ticket'
$ticketRaw = Get-Content -Raw -LiteralPath $ticketPath
Assert-C34DSanitizedText -Text $ticketRaw -Label 'C34D ticket'
Assert-C34D -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    'B5D624675ADCF578C2A83F4F80752D6735AD025ADF655AF494F7887601D580A4'
) -Message 'ticket bytes changed.'
$ticket = $ticketRaw | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.state -ceq
    'registered_founder_authorized_preparation_and_selection_source_qualification_pending' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [string]$ticket.candidate.versionName -ceq '1.0.0-r60.68' -and
  [string]$ticket.candidate.versionCode -ceq '2026081368' -and
  [string]$ticket.candidate.playTrack -ceq 'internal' -and
  [bool]$ticket.robustnessAndReuseAssessment.reuseInventoryComplete -and
  [bool]$ticket.robustnessAndReuseAssessment.duplicateSearchComplete -and
  [bool]$ticket.robustnessAndReuseAssessment.within60To75DayLock -and
  @($ticket.parentTickets) -contains
    'UAW-C34C-R60-67-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE' -and
  [string]$ticket.classificationReason -match 'REG2659' -and
  [string]$ticket.classificationReason -match 'REG2660' -and
  [string]$ticket.classificationReason -match 'REG2661' -and
  @($ticket.robustnessAndReuseAssessment.newScreens).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newRoutes).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newBackendOwners).Count -eq 0 -and
  @($ticket.minimumCompleteScope) -contains
    'declare_the_source_manifest_SHA256_and_file_count_binding_fields_in_both_state_and_aggregate_before_source_seal_then_apply_and_verify_each_post_generation_binding_separately' -and
  @($ticket.minimumCompleteScope) -contains
    'model_preseal_composition_and_postseal_manifest_bound_precycle_as_distinct_machine_states_before_source_seal' -and
  @($ticket.minimumCompleteScope) -contains
    'reset_all_three_current_candidate_founder_configuration_qualification_flags_false_before_source_seal_and_require_the_launcher_to_call_a_distinct_preprompt_gate_before_hidden_entry' -and
  @($ticket.minimumCompleteScope) -contains
    'declare_founder_inputs_validated_single_aab_build_required_as_the_only_postinput_prebuild_state_and_require_all_three_founder_qualification_flags_true_agent_read_flags_false_and_hidden_input_entry_recorded_before_the_generic_wrapper_build_gate' -and
  @($ticket.minimumCompleteScope) -contains
    'restrict_secret_adjacent_diagnostics_to_exact_named_boolean_properties_and_never_serialize_runtime_configuration_parent_objects_or_broad_line_ranges' -and
  @($ticket.minimumCompleteScope) -contains
    'apply_and_verify_each_candidate_gate_correction_as_an_exact_separate_hunk_then_parse_all_bounded_PowerShell_owners_in_both_hosts_before_any_source_gate' -and
  @($ticket.minimumCompleteScope) -contains
    'declare_the_exact_postcycle_build_authority_held_machine_state_every_cycle_result_field_both_summary_paths_and_the_later_founder_prompt_transition_in_state_aggregate_gate_and_runbook_before_source_seal' -and
  @($ticket.minimumCompleteScope) -contains
    'apply_and_verify_each_candidate_document_correction_as_an_exact_separate_hunk_before_registry_and_ticket_hash_binding' -and
  @($ticket.minimumCompleteScope) -contains
    'reject_the_candidate_and_register_an_exact_repair_ticket_before_retry_if_any_historical_or_new_regression_occurs' -and
  [bool]$ticket.authority.candidatePreparationAndSelectionAuthorized -and
  [bool]$ticket.authority.sourceQualificationAuthorized -and
  -not [bool]$ticket.authority.oneAabBuildAuthorizedAfterAllGates -and
  -not [bool]$ticket.authority.oneInternalTestingUploadAndActivationAuthorizedAfterPostbuild -and
  -not [bool]$ticket.authority.oneInPlaceOppoPlayUpdateAuthorizedAfterActivation -and
  -not [bool]$ticket.authority.oneFounderReviewedPasswordlessEmailSendAuthorizedAfterInstall -and
  -not [bool]$ticket.authority.founderHiddenInputEntryAuthorized -and
  -not [bool]$ticket.authority.agentSecretOrPrivateLinkAccessAuthorized -and
  -not [bool]$ticket.authority.otherTrackAuthorized -and
  -not [bool]$ticket.authority.adbInstallUninstallDataClearDowngradeOrSideloadAuthorized -and
  -not [bool]$ticket.authority.backendHostingProviderOrProductionDeploymentAuthorized -and
  -not [bool]$ticket.authority.realSmsSendAuthorized -and
  -not [bool]$ticket.authority.youtubeQuotaOrEmailSubmissionAuthorized -and
  -not [bool]$ticket.authority.fundsAuthorized
) -Message 'ticket identity, no-regression rule or authority changed.'

$uploadRunbookPath = Resolve-C34DFile `
  -Path 'docs/quality/UAW-C34D-PRESEALED-INTERNAL-TESTING-UPLOAD-RUNBOOK-20260816.md' `
  -Label 'C34D pre-sealed Internal Testing upload runbook'
$uploadRunbook = Get-Content -Raw -LiteralPath $uploadRunbookPath
Assert-C34DSanitizedText -Text $uploadRunbook -Label 'C34D upload runbook'
Assert-C34D -Condition (
  $uploadRunbook.Contains('After the source seal, repository discovery commands are prohibited.') -and
  $uploadRunbook.Contains('The authoritative Flutter runner receives the focused manifest') -and
  $uploadRunbook.Contains('Those two lifecycle transitions cannot be combined.') -and
  $uploadRunbook.Contains('founder_inputs_validated_single_aab_build_required') -and
  $uploadRunbook.Contains('The wrapper''s existing `build` replay requires that exact') -and
  $uploadRunbook.Contains('Historical Play evidence may be inspected') -and
  $uploadRunbook.Contains('Raw evidence') -and
  [regex]::IsMatch($uploadRunbook, 'Testing\s*>\s*Internal\s+testing') -and
  $uploadRunbook.Contains('No post-seal source, registry, ticket, runbook or gate mutation is allowed.')
) -Message 'pre-sealed Internal Testing upload workflow boundary changed.'

$resolvedStatePath = Resolve-C34DFile -Path $StatePath -Label 'C34D state'
$stateRaw = Get-Content -Raw -LiteralPath $resolvedStatePath
Assert-C34DSanitizedText -Text $stateRaw -Label 'C34D state'
$state = $stateRaw | ConvertFrom-Json
$aggregatePath = Resolve-C34DFile `
  -Path ([string]$state.aggregateStatePath) `
  -Label 'C34D aggregate'
$aggregateRaw = Get-Content -Raw -LiteralPath $aggregatePath
Assert-C34DSanitizedText -Text $aggregateRaw -Label 'C34D aggregate'
$aggregate = $aggregateRaw | ConvertFrom-Json

Assert-C34D -Condition (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq
    'MOOLSOCIAL-C34D-R60-68-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.ticketId -ceq $ticketId -and
  [string]$state.repositoryIdentity.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.repositoryIdentity.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.versionName -ceq '1.0.0-r60.68' -and
  [string]$state.candidate.versionCode -ceq '2026081368' -and
  [string]$state.candidate.authorizedTrack -ceq 'internal' -and
  [string]$state.candidate.playTrack -ceq 'internal' -and
  [string]$state.candidate.deviceSerial -ceq '2b3e0f71' -and
  [string]$state.candidate.deviceModel -ceq 'CPH2375'
) -Message 'state repository, candidate, package, track or OPPO identity changed.'
Assert-C34D -Condition (
  [string]$aggregate.contractId -ceq
    'MOOLSOCIAL-C34D-R60-68-AUTHENTICATION-NO-REGRESSION-RELEASE-AGGREGATE-001' -and
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.versionName -ceq '1.0.0-r60.68' -and
  [string]$aggregate.candidate.versionCode -ceq '2026081368'
) -Message 'aggregate identity or candidate changed.'
Assert-C34D -Condition (
  [string]$state.lifecycleTransitions.presealComposition -ceq
    'prebuild_composition_registered_two_fresh_cycles_required' -and
  [string]$state.lifecycleTransitions.postsealManifestBoundPrecycle -ceq
    'prebuild_manifest_bound_two_fresh_cycles_required' -and
  [string]$state.lifecycleTransitions.postcycleBuildAuthorityHeld -ceq
    'source_regression_memory_two_identical_cycles_qualified_build_authority_held' -and
  [string]$state.lifecycleTransitions.founderPromptRequired -ceq
    'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required' -and
  [string]$state.lifecycleTransitions.founderInputsValidatedBuildRequired -ceq
    'founder_inputs_validated_single_aab_build_required' -and
  @($state.lifecycleTransitions.postcyclePersistenceOrder).Count -eq 6 -and
  [string]$aggregate.lifecycleTransitions.presealComposition -ceq
    [string]$state.lifecycleTransitions.presealComposition -and
  [string]$aggregate.lifecycleTransitions.postsealManifestBoundPrecycle -ceq
    [string]$state.lifecycleTransitions.postsealManifestBoundPrecycle -and
  [string]$aggregate.lifecycleTransitions.postcycleBuildAuthorityHeld -ceq
    [string]$state.lifecycleTransitions.postcycleBuildAuthorityHeld -and
  [string]$aggregate.lifecycleTransitions.founderPromptRequired -ceq
    [string]$state.lifecycleTransitions.founderPromptRequired -and
  [string]$aggregate.lifecycleTransitions.founderInputsValidatedBuildRequired -ceq
    [string]$state.lifecycleTransitions.founderInputsValidatedBuildRequired -and
  @($aggregate.lifecycleTransitions.postcyclePersistenceOrder).Count -eq 6
) -Message 'predeclared postseal lifecycle transition contract changed.'

$browserQualificationPath = Resolve-C34DFile `
  -Path ([string]$state.presealUploadWorkflow.evidencePath) `
  -Label 'C34D pre-sealed browser qualification evidence'
$founderAuthorizationPath = Resolve-C34DFile `
  -Path ([string]$state.presealUploadWorkflow.founderAuthorizationPath) `
  -Label 'C34D end-to-end founder authorization'
Assert-C34D -Condition (
  [string]$state.presealUploadWorkflow.runbookPath -ceq
    'docs/quality/UAW-C34D-PRESEALED-INTERNAL-TESTING-UPLOAD-RUNBOOK-20260816.md' -and
  [string]$state.presealUploadWorkflow.evidencePath -ceq
    'docs/quality/UAW-C34D-PRESEALED-INTERNAL-TESTING-BROWSER-QUALIFICATION-20260816.md' -and
  [string]$state.presealUploadWorkflow.founderAuthorizationPath -ceq
    'docs/quality/UAW-C34D-END-TO-END-FOUNDER-AUTHORIZATION-20260816.md' -and
  [bool]$state.presealUploadWorkflow.noPlayWritePerformed -and
  -not [bool]$state.presealUploadWorkflow.genericSelectorControlsAllowed -and
  [string]$aggregate.presealUploadWorkflow.evidencePath -ceq
    [string]$state.presealUploadWorkflow.evidencePath -and
  [bool]$aggregate.presealUploadWorkflow.liveBrowserRouteQualified -eq
    [bool]$state.presealUploadWorkflow.liveBrowserRouteQualified -and
  [bool]$aggregate.presealUploadWorkflow.signedInMoolSocialAppRouteProved -eq
    [bool]$state.presealUploadWorkflow.signedInMoolSocialAppRouteProved -and
  [bool]$aggregate.presealUploadWorkflow.internalTestingRouteProved -eq
    [bool]$state.presealUploadWorkflow.internalTestingRouteProved -and
  [bool]$aggregate.presealUploadWorkflow.noPlayWritePerformed
) -Message 'pre-sealed browser workflow, founder authority or zero-Play-write mirror changed.'

$historicalContracts = @($state.historicalCandidates)
$aggregateHistoricalContracts = @($aggregate.historicalCandidates)
Assert-C34D -Condition (
  $historicalContracts.Count -eq 19 -and
  $aggregateHistoricalContracts.Count -eq 19
) -Message 'exact failed/rejected candidate history is incomplete.'

$failedContract = $historicalContracts[0]
$failedStatePath = Resolve-C34DFile -Path ([string]$failedContract.statePath) `
  -Label 'failed r60.49 state'
$failedState = Get-Content -Raw -LiteralPath $failedStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$failedContract.versionName -ceq '1.0.0-r60.49' -and
  [string]$failedContract.versionCode -ceq '2026081349' -and
  [string]$failedContract.disposition -ceq 'failed' -and
  [int]$failedContract.buildCount -eq 1 -and
  [int]$failedContract.uploadCount -eq 1 -and
  [int]$failedContract.installCount -eq 1 -and
  [int]$failedContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$failedContract.artifactReusable -and
  [string]$failedState.machineState -ceq
    'acceptance_failed_r60_49_google_auth_guest_feed_social_identity_and_create_crash_successor_required' -and
  [int]$failedState.buildResult.buildCount -eq 1 -and
  [int]$failedState.playResult.uploadCount -eq 1 -and
  [int]$failedState.installResult.installCount -eq 1 -and
  [int]$failedState.actionCounts.deviceAcceptance -eq 0
) -Message 'failed r60.49 identity or 1/1/1/0 truth changed.'

foreach ($index in 1..2) {
  $rejectedContract = $historicalContracts[$index]
  $expectedName = if ($index -eq 1) { '1.0.0-r60.50' } else { '1.0.0-r60.51' }
  $expectedCode = if ($index -eq 1) { '2026081350' } else { '2026081351' }
  $expectedSha = if ($index -eq 1) {
    '541F02EA0F7C1C8B9067B31D50AE3CE0BB495E16746A3E4E2FF4AEAA28354F99'
  } else {
    '6C4C402DAA5CD813F66DF1ECE895A7FE39936F6D6413FC2D771667E274A7CA24'
  }
  $rejectedStatePath = Resolve-C34DFile -Path ([string]$rejectedContract.statePath) `
    -Label "rejected $expectedName state"
  $rejectedState = Get-Content -Raw -LiteralPath $rejectedStatePath | ConvertFrom-Json
  Assert-C34D -Condition (
    [string]$rejectedContract.versionName -ceq $expectedName -and
    [string]$rejectedContract.versionCode -ceq $expectedCode -and
    [string]$rejectedContract.disposition -ceq 'rejected' -and
    [int]$rejectedContract.buildCount -eq 1 -and
    [int]$rejectedContract.uploadCount -eq 0 -and
    [int]$rejectedContract.installCount -eq 0 -and
    [int]$rejectedContract.deviceAcceptanceCount -eq 0 -and
    -not [bool]$rejectedContract.artifactReusable -and
    [string]$rejectedContract.artifactSha256 -ceq $expectedSha -and
    [string]$rejectedState.machineState -ceq
      'single_release_AAB_succeeded_authority_consumed' -and
    [string]$rejectedState.buildAuthorization -ceq 'consumed' -and
    [int]$rejectedState.buildResult.buildCount -eq 1 -and
    [int]$rejectedState.actionCounts.build -eq 1 -and
    [int]$rejectedState.actionCounts.upload -eq 0 -and
    [int]$rejectedState.actionCounts.install -eq 0 -and
    [int]$rejectedState.actionCounts.deviceAcceptance -eq 0 -and
    [string]$rejectedState.buildResult.artifactSha256 -ceq $expectedSha
  ) -Message "rejected $expectedName artifact or 1/0/0/0 truth changed."
}

$rejectedC33NContract = $historicalContracts[3]
$rejectedC33NStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC33NContract.statePath) `
  -Label 'rejected r60.52 state'
$rejectedC33NState = Get-Content -Raw -LiteralPath $rejectedC33NStatePath |
  ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33NContract.versionName -ceq '1.0.0-r60.52' -and
  [string]$rejectedC33NContract.versionCode -ceq '2026081352' -and
  [string]$rejectedC33NContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33NContract.machineState -ceq
    'postbuild_rejected_postseal_registry_change_successor_required' -and
  [int]$rejectedC33NContract.buildCount -eq 1 -and
  [int]$rejectedC33NContract.uploadCount -eq 0 -and
  [int]$rejectedC33NContract.installCount -eq 0 -and
  [int]$rejectedC33NContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33NContract.artifactReusable -and
  [string]$rejectedC33NContract.artifactSha256 -ceq
    'E56BF124B3F46D27D34387A5AB6B12012125227095026EAB04CEC56B69A2E8A3' -and
  [string]$rejectedC33NState.machineState -ceq
    'postbuild_rejected_postseal_registry_change_successor_required' -and
  [string]$rejectedC33NState.buildAuthorization -ceq 'consumed' -and
  [int]$rejectedC33NState.buildResult.buildCount -eq 1 -and
  [int]$rejectedC33NState.actionCounts.build -eq 1 -and
  [int]$rejectedC33NState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33NState.actionCounts.install -eq 0 -and
  [int]$rejectedC33NState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$rejectedC33NState.buildResult.artifactSha256 -ceq
    'E56BF124B3F46D27D34387A5AB6B12012125227095026EAB04CEC56B69A2E8A3' -and
  [string]$aggregateHistoricalContracts[3].machineState -ceq
    'postbuild_rejected_postseal_registry_change_successor_required' -and
  [string]$aggregateHistoricalContracts[3].aabSha256 -ceq
    'E56BF124B3F46D27D34387A5AB6B12012125227095026EAB04CEC56B69A2E8A3'
) -Message 'rejected r60.52 artifact, post-seal disposition or 1/0/0/0 truth changed.'

$rejectedC33OContract = $historicalContracts[4]
$rejectedC33OStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC33OContract.statePath) `
  -Label 'rejected r60.53 state'
$rejectedC33OState = Get-Content -Raw -LiteralPath $rejectedC33OStatePath |
  ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33OContract.versionName -ceq '1.0.0-r60.53' -and
  [string]$rejectedC33OContract.versionCode -ceq '2026081353' -and
  [string]$rejectedC33OContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33OContract.machineState -ceq
    'prebuild_rejected_postseal_registry_change_successor_required' -and
  [int]$rejectedC33OContract.buildCount -eq 0 -and
  [int]$rejectedC33OContract.uploadCount -eq 0 -and
  [int]$rejectedC33OContract.installCount -eq 0 -and
  [int]$rejectedC33OContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33OContract.artifactReusable -and
  [string]$rejectedC33OState.machineState -ceq
    'prebuild_rejected_postseal_registry_change_successor_required' -and
  [string]$rejectedC33OState.buildAuthorization -ceq
    'rejected_postseal_registry_change' -and
  [int]$rejectedC33OState.actionCounts.build -eq 0 -and
  [int]$rejectedC33OState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33OState.actionCounts.install -eq 0 -and
  [int]$rejectedC33OState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$rejectedC33OState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2621-C33O-CYCLE2-EVIDENCE-LOGGER-UNSUPPORTED-TEE-PARAMETER' -and
  [string]$aggregateHistoricalContracts[4].machineState -ceq
    'prebuild_rejected_postseal_registry_change_successor_required'
) -Message 'rejected r60.53 post-seal logger disposition or 0/0/0/0 truth changed.'

$rejectedC33PContract = $historicalContracts[5]
$rejectedC33PStatePath = Resolve-C34DFile -Path ([string]$rejectedC33PContract.statePath) -Label 'rejected r60.54 state'
$rejectedC33PState = Get-Content -Raw -LiteralPath $rejectedC33PStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33PContract.versionName -ceq '1.0.0-r60.54' -and
  [string]$rejectedC33PContract.versionCode -ceq '2026081354' -and
  [string]$rejectedC33PContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33PContract.machineState -ceq
    'prebuild_rejected_postseal_registry_change_successor_required' -and
  [int]$rejectedC33PContract.buildCount -eq 0 -and
  [int]$rejectedC33PContract.uploadCount -eq 0 -and
  [int]$rejectedC33PContract.installCount -eq 0 -and
  [int]$rejectedC33PContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33PContract.artifactReusable -and
  [string]$rejectedC33PState.machineState -ceq
    'prebuild_rejected_postseal_registry_change_successor_required' -and
  [string]$rejectedC33PState.buildAuthorization -ceq
    'rejected_postseal_registry_change' -and
  [int]$rejectedC33PState.actionCounts.build -eq 0 -and
  [int]$rejectedC33PState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33PState.actionCounts.install -eq 0 -and
  [int]$rejectedC33PState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$rejectedC33PState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2626-C33P-FLUTTER-RUNNER-ABSOLUTE-MANIFEST-DOUBLE-ROOT' -and
  [string]$aggregateHistoricalContracts[5].machineState -ceq
    'prebuild_rejected_postseal_registry_change_successor_required'
) -Message 'rejected r60.54 post-seal Flutter runner disposition or 0/0/0/0 truth changed.'

$rejectedC33QContract = $historicalContracts[6]
$rejectedC33QStatePath = Resolve-C34DFile -Path ([string]$rejectedC33QContract.statePath) -Label 'rejected r60.55 state'
$rejectedC33QState = Get-Content -Raw -LiteralPath $rejectedC33QStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33QContract.versionName -ceq '1.0.0-r60.55' -and
  [string]$rejectedC33QContract.versionCode -ceq '2026081355' -and
  [string]$rejectedC33QContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33QContract.machineState -ceq 'prebuild_rejected_postseal_registry_change_successor_required' -and
  [int]$rejectedC33QContract.buildCount -eq 0 -and
  [int]$rejectedC33QContract.uploadCount -eq 0 -and
  [int]$rejectedC33QContract.installCount -eq 0 -and
  [int]$rejectedC33QContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33QContract.artifactReusable -and
  [string]$rejectedC33QState.machineState -ceq 'prebuild_rejected_postseal_registry_change_successor_required' -and
  [string]$rejectedC33QState.buildAuthorization -ceq 'rejected_postseal_registry_change' -and
  [int]$rejectedC33QState.actionCounts.build -eq 0 -and
  [int]$rejectedC33QState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33QState.actionCounts.install -eq 0 -and
  [int]$rejectedC33QState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$rejectedC33QState.rejection.reasonRegistryIds[0] -ceq 'REG-20260816-2627-C33Q-SOURCE-GATE-AUTHORITY-EXPOSED-BEFORE-FINAL-SOURCE-REPLAY' -and
  [string]$aggregateHistoricalContracts[6].machineState -ceq 'prebuild_rejected_postseal_registry_change_successor_required'
) -Message 'rejected r60.55 post-seal authority-order disposition or 0/0/0/0 truth changed.'

$rejectedC33RContract = $historicalContracts[7]
$rejectedC33RStatePath = Resolve-C34DFile -Path ([string]$rejectedC33RContract.statePath) -Label 'rejected r60.56 state'
$rejectedC33RState = Get-Content -Raw -LiteralPath $rejectedC33RStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33RContract.versionName -ceq '1.0.0-r60.56' -and
  [string]$rejectedC33RContract.versionCode -ceq '2026081356' -and
  [string]$rejectedC33RContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33RContract.machineState -ceq 'prebuild_rejected_postseal_registry_change_successor_required' -and
  [int]$rejectedC33RContract.buildCount -eq 0 -and
  [int]$rejectedC33RContract.uploadCount -eq 0 -and
  [int]$rejectedC33RContract.installCount -eq 0 -and
  [int]$rejectedC33RContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33RContract.artifactReusable -and
  [string]$rejectedC33RState.machineState -ceq 'prebuild_rejected_postseal_registry_change_successor_required' -and
  [string]$rejectedC33RState.buildAuthorization -ceq 'rejected_postseal_registry_change' -and
  [int]$rejectedC33RState.actionCounts.build -eq 0 -and
  [int]$rejectedC33RState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33RState.actionCounts.install -eq 0 -and
  [int]$rejectedC33RState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$rejectedC33RState.rejection.reasonRegistryIds[0] -ceq 'REG-20260816-2628-C33R-FOUNDER-LAUNCHER-DETACHED-NONINTERACTIVE-HOST' -and
  [string]$aggregateHistoricalContracts[7].machineState -ceq 'prebuild_rejected_postseal_registry_change_successor_required'
) -Message 'rejected r60.56 detached-launcher disposition or 0/0/0/0 truth changed.'

$rejectedC33SContract = $historicalContracts[8]
$rejectedC33SStatePath = Resolve-C34DFile -Path ([string]$rejectedC33SContract.statePath) -Label 'rejected r60.57 state'
$rejectedC33SState = Get-Content -Raw -LiteralPath $rejectedC33SStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33SContract.versionName -ceq '1.0.0-r60.57' -and
  [string]$rejectedC33SContract.versionCode -ceq '2026081357' -and
  [string]$rejectedC33SContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33SContract.machineState -ceq 'prebuild_rejected_postseal_registry_change_successor_required' -and
  [int]$rejectedC33SContract.buildCount -eq 0 -and
  [int]$rejectedC33SContract.uploadCount -eq 0 -and
  [int]$rejectedC33SContract.installCount -eq 0 -and
  [int]$rejectedC33SContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33SContract.artifactReusable -and
  [string]$rejectedC33SState.machineState -ceq 'prebuild_rejected_postseal_registry_change_successor_required' -and
  [string]$rejectedC33SState.buildAuthorization -ceq 'rejected_postseal_registry_change' -and
  [int]$rejectedC33SState.actionCounts.build -eq 0 -and
  [int]$rejectedC33SState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33SState.actionCounts.install -eq 0 -and
  [int]$rejectedC33SState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$rejectedC33SState.rejection.reasonRegistryIds[0] -ceq 'REG-20260816-2633-C33S-POWERSHELL-SCRIPT-LASTEXITCODE-NULL-EARLY-EXIT-RECURRENCE' -and
  [string]$aggregateHistoricalContracts[8].machineState -ceq 'prebuild_rejected_postseal_registry_change_successor_required'
) -Message 'rejected r60.57 post-seal gate-orchestration disposition or 0/0/0/0 truth changed.'

$rejectedC33TContract = $historicalContracts[9]
$rejectedC33TStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC33TContract.statePath) `
  -Label 'rejected r60.58 state'
$rejectedC33TState = Get-Content -Raw -LiteralPath $rejectedC33TStatePath |
  ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33TContract.versionName -ceq '1.0.0-r60.58' -and
  [string]$rejectedC33TContract.versionCode -ceq '2026081358' -and
  [string]$rejectedC33TContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33TContract.machineState -ceq
    'prebuild_founder_launcher_gate_rejected_successor_required' -and
  [int]$rejectedC33TContract.buildCount -eq 0 -and
  [int]$rejectedC33TContract.uploadCount -eq 0 -and
  [int]$rejectedC33TContract.installCount -eq 0 -and
  [int]$rejectedC33TContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33TContract.artifactReusable -and
  [string]$rejectedC33TState.machineState -ceq
    'prebuild_founder_launcher_gate_rejected_successor_required' -and
  [string]$rejectedC33TState.buildAuthorization -ceq
    'rejected_preprompt_gate_failure' -and
  -not [bool]$rejectedC33TState.founderAuthorization.hiddenFounderInputsEntered -and
  [int]$rejectedC33TState.buildResult.wrapperInvocationCount -eq 0 -and
  [int]$rejectedC33TState.actionCounts.build -eq 0 -and
  [int]$rejectedC33TState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33TState.actionCounts.install -eq 0 -and
  [int]$rejectedC33TState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$rejectedC33TState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2634-C33T-MVP-STATE-RELATIVE-PATH-RESOLVED-AGAINST-CALLER-CWD' -and
  [string]$aggregateHistoricalContracts[9].machineState -ceq
    'prebuild_founder_launcher_gate_rejected_successor_required'
) -Message 'rejected r60.58 preprompt MVP-path disposition or 0/0/0/0 truth changed.'

$rejectedC33UContract = $historicalContracts[10]
$rejectedC33UStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC33UContract.statePath) `
  -Label 'rejected r60.59 state'
$rejectedC33UState = Get-Content -Raw -LiteralPath $rejectedC33UStatePath |
  ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33UContract.versionName -ceq '1.0.0-r60.59' -and
  [string]$rejectedC33UContract.versionCode -ceq '2026081359' -and
  [string]$rejectedC33UContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33UContract.machineState -ceq
    'postupload_rejected_privacy_boundary_tooling_incident_successor_required' -and
  [int]$rejectedC33UContract.buildCount -eq 1 -and
  [int]$rejectedC33UContract.uploadCount -eq 1 -and
  [int]$rejectedC33UContract.installCount -eq 0 -and
  [int]$rejectedC33UContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33UContract.artifactReusable -and
  [string]$rejectedC33UContract.artifactSha256 -ceq
    '148D679AA5FACF5AF670FF56DC8B50F9056082D7466C480D3DB4F246F04D6074' -and
  [string]$rejectedC33UState.machineState -ceq
    'postupload_rejected_privacy_boundary_tooling_incident_successor_required' -and
  [string]$rejectedC33UState.buildAuthorization -ceq 'consumed' -and
  [string]$rejectedC33UState.uploadAuthorization -ceq 'consumed' -and
  [string]$rejectedC33UState.installAuthorization -ceq 'rejected_candidate' -and
  [int]$rejectedC33UState.actionCounts.build -eq 1 -and
  [int]$rejectedC33UState.actionCounts.upload -eq 1 -and
  [int]$rejectedC33UState.actionCounts.install -eq 0 -and
  [int]$rejectedC33UState.actionCounts.deviceAcceptance -eq 0 -and
  [int]$rejectedC33UState.playResult.uploadCount -eq 1 -and
  [int]$rejectedC33UState.playResult.internalActivationCount -eq 1 -and
  [string]$rejectedC33UState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2638-C33U-POSTUPLOAD-HISTORICAL-PLAY-EVIDENCE-RAW-PRIVACY-BOUNDARY' -and
  [bool]$rejectedC33UState.privacyBoundary.privateAccountIdentifiersObserved -and
  [bool]$rejectedC33UState.privacyBoundary.privateLinksObserved -and
  [string]$aggregateHistoricalContracts[10].machineState -ceq
    'postupload_rejected_privacy_boundary_tooling_incident_successor_required' -and
  [string]$aggregateHistoricalContracts[10].aabSha256 -ceq
    '148D679AA5FACF5AF670FF56DC8B50F9056082D7466C480D3DB4F246F04D6074'
) -Message 'rejected r60.59 privacy-tooling disposition or 1/1/0/0 truth changed.'

$rejectedC33VContract = $historicalContracts[11]
$rejectedC33VStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC33VContract.statePath) `
  -Label 'rejected r60.60 state'
$rejectedC33VState = Get-Content -Raw -LiteralPath $rejectedC33VStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33VContract.versionName -ceq '1.0.0-r60.60' -and
  [string]$rejectedC33VContract.versionCode -ceq '2026081360' -and
  [string]$rejectedC33VContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33VContract.machineState -ceq
    'prebuild_rejected_postseal_cycle_orchestration_inventory_missing_successor_required' -and
  [int]$rejectedC33VContract.buildCount -eq 0 -and
  [int]$rejectedC33VContract.uploadCount -eq 0 -and
  [int]$rejectedC33VContract.installCount -eq 0 -and
  [int]$rejectedC33VContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33VContract.artifactReusable -and
  [string]$rejectedC33VState.machineState -ceq
    'prebuild_rejected_postseal_cycle_orchestration_inventory_missing_successor_required' -and
  [string]$rejectedC33VState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2645-C33V-SOURCE-SEALED-BEFORE-EXACT-CYCLE-ORCHESTRATION-INVENTORY' -and
  [int]$rejectedC33VState.actionCounts.build -eq 0 -and
  [int]$rejectedC33VState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33VState.actionCounts.install -eq 0 -and
  [int]$rejectedC33VState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$aggregateHistoricalContracts[11].machineState -ceq
    'prebuild_rejected_postseal_cycle_orchestration_inventory_missing_successor_required'
) -Message 'rejected r60.60 postseal cycle-owner disposition or 0/0/0/0 truth changed.'

$rejectedC33WContract = $historicalContracts[12]
$rejectedC33WStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC33WContract.statePath) `
  -Label 'rejected r60.61 state'
$rejectedC33WState = Get-Content -Raw -LiteralPath $rejectedC33WStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33WContract.versionName -ceq '1.0.0-r60.61' -and
  [string]$rejectedC33WContract.versionCode -ceq '2026081361' -and
  [string]$rejectedC33WContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33WContract.machineState -ceq
    'prebuild_rejected_final_source_replay_focused_manifest_hash_mismatch_successor_required' -and
  [int]$rejectedC33WContract.buildCount -eq 0 -and
  [int]$rejectedC33WContract.uploadCount -eq 0 -and
  [int]$rejectedC33WContract.installCount -eq 0 -and
  [int]$rejectedC33WContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33WContract.artifactReusable -and
  [string]$rejectedC33WState.machineState -ceq
    'prebuild_rejected_final_source_replay_focused_manifest_hash_mismatch_successor_required' -and
  [string]$rejectedC33WState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2648-C33W-FOCUSED-MANIFEST-APPLY-PATCH-BYTE-HASH-MISMATCH' -and
  [int]$rejectedC33WState.sourceQualification.completedIdenticalCycles -eq 2 -and
  [int]$rejectedC33WState.actionCounts.build -eq 0 -and
  [int]$rejectedC33WState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33WState.actionCounts.install -eq 0 -and
  [int]$rejectedC33WState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$aggregateHistoricalContracts[12].machineState -ceq
    'prebuild_rejected_final_source_replay_focused_manifest_hash_mismatch_successor_required'
) -Message 'rejected r60.61 focused-manifest final-replay disposition or 0/0/0/0 truth changed.'

$rejectedC33XContract = $historicalContracts[13]
$rejectedC33XStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC33XContract.statePath) `
  -Label 'rejected r60.62 state'
$rejectedC33XState = Get-Content -Raw -LiteralPath $rejectedC33XStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33XContract.versionName -ceq '1.0.0-r60.62' -and
  [string]$rejectedC33XContract.versionCode -ceq '2026081362' -and
  [string]$rejectedC33XContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33XContract.machineState -ceq
    'prebuild_rejected_postseal_manifest_binding_patch_context_mismatch_successor_required' -and
  [int]$rejectedC33XContract.buildCount -eq 0 -and
  [int]$rejectedC33XContract.uploadCount -eq 0 -and
  [int]$rejectedC33XContract.installCount -eq 0 -and
  [int]$rejectedC33XContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33XContract.artifactReusable -and
  [string]$rejectedC33XState.machineState -ceq
    'prebuild_rejected_postseal_manifest_binding_patch_context_mismatch_successor_required' -and
  [string]$rejectedC33XState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2649-C33X-POSTSEAL-MANIFEST-BINDING-COMPOUND-PATCH-CONTEXT-MISMATCH' -and
  [int]$rejectedC33XState.sourceQualification.completedIdenticalCycles -eq 0 -and
  [int]$rejectedC33XState.actionCounts.build -eq 0 -and
  [int]$rejectedC33XState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33XState.actionCounts.install -eq 0 -and
  [int]$rejectedC33XState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$aggregateHistoricalContracts[13].machineState -ceq
    'prebuild_rejected_postseal_manifest_binding_patch_context_mismatch_successor_required'
) -Message 'rejected r60.62 postseal manifest-binding disposition or 0/0/0/0 truth changed.'

$rejectedC33YContract = $historicalContracts[14]
$rejectedC33YStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC33YContract.statePath) `
  -Label 'rejected r60.63 state'
$rejectedC33YState = Get-Content -Raw -LiteralPath $rejectedC33YStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33YContract.versionName -ceq '1.0.0-r60.63' -and
  [string]$rejectedC33YContract.versionCode -ceq '2026081363' -and
  [string]$rejectedC33YContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33YContract.machineState -ceq
    'prebuild_rejected_postseal_precycle_manifest_binding_state_contradiction_successor_required' -and
  [int]$rejectedC33YContract.buildCount -eq 0 -and
  [int]$rejectedC33YContract.uploadCount -eq 0 -and
  [int]$rejectedC33YContract.installCount -eq 0 -and
  [int]$rejectedC33YContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33YContract.artifactReusable -and
  [string]$rejectedC33YState.machineState -ceq
    'prebuild_rejected_postseal_precycle_manifest_binding_state_contradiction_successor_required' -and
  [string]$rejectedC33YState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2651-C33Y-POSTSEAL-PRECYCLE-MANIFEST-BINDING-STATE-CONTRADICTION' -and
  [int]$rejectedC33YState.sourceQualification.completedIdenticalCycles -eq 0 -and
  [int]$rejectedC33YState.actionCounts.build -eq 0 -and
  [int]$rejectedC33YState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33YState.actionCounts.install -eq 0 -and
  [int]$rejectedC33YState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$aggregateHistoricalContracts[14].machineState -ceq
    'prebuild_rejected_postseal_precycle_manifest_binding_state_contradiction_successor_required'
) -Message 'rejected r60.63 postseal precycle state contradiction or 0/0/0/0 truth changed.'

$rejectedC33ZContract = $historicalContracts[15]
$rejectedC33ZStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC33ZContract.statePath) `
  -Label 'rejected r60.64 state'
$rejectedC33ZState = Get-Content -Raw -LiteralPath $rejectedC33ZStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC33ZContract.versionName -ceq '1.0.0-r60.64' -and
  [string]$rejectedC33ZContract.versionCode -ceq '2026081364' -and
  [string]$rejectedC33ZContract.disposition -ceq 'rejected' -and
  [string]$rejectedC33ZContract.machineState -ceq
    'prebuild_founder_launcher_preprompt_qualification_flag_rejected_successor_required' -and
  [int]$rejectedC33ZContract.buildCount -eq 0 -and
  [int]$rejectedC33ZContract.uploadCount -eq 0 -and
  [int]$rejectedC33ZContract.installCount -eq 0 -and
  [int]$rejectedC33ZContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC33ZContract.artifactReusable -and
  [string]$rejectedC33ZState.machineState -ceq
    'prebuild_founder_launcher_preprompt_qualification_flag_rejected_successor_required' -and
  [string]$rejectedC33ZState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2652-C33Z-PREPROMPT-FOUNDER-QUALIFICATION-FLAGS-RETAINED' -and
  -not [bool]$rejectedC33ZState.rejection.hiddenInputsEntered -and
  -not [bool]$rejectedC33ZState.rejection.buildAuthorityConsumed -and
  [int]$rejectedC33ZState.actionCounts.build -eq 0 -and
  [int]$rejectedC33ZState.actionCounts.upload -eq 0 -and
  [int]$rejectedC33ZState.actionCounts.install -eq 0 -and
  [int]$rejectedC33ZState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$aggregateHistoricalContracts[15].machineState -ceq
    'prebuild_founder_launcher_preprompt_qualification_flag_rejected_successor_required'
) -Message 'rejected r60.64 preprompt qualification-flag disposition or 0/0/0/0 truth changed.'

$rejectedC34AContract = $historicalContracts[16]
$rejectedC34AStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC34AContract.statePath) `
  -Label 'rejected r60.65 state'
$rejectedC34AState = Get-Content -Raw -LiteralPath $rejectedC34AStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC34AContract.versionName -ceq '1.0.0-r60.65' -and
  [string]$rejectedC34AContract.versionCode -ceq '2026081365' -and
  [string]$rejectedC34AContract.disposition -ceq 'rejected' -and
  [string]$rejectedC34AContract.machineState -ceq
    'prebuild_rejected_postseal_intermediate_state_discovery_after_two_cycles_successor_required' -and
  [int]$rejectedC34AContract.buildCount -eq 0 -and
  [int]$rejectedC34AContract.uploadCount -eq 0 -and
  [int]$rejectedC34AContract.installCount -eq 0 -and
  [int]$rejectedC34AContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC34AContract.artifactReusable -and
  [string]$rejectedC34AState.machineState -ceq
    'prebuild_rejected_postseal_intermediate_state_discovery_after_two_cycles_successor_required' -and
  [string]$rejectedC34AState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2656-C34A-POSTSEAL-INTERMEDIATE-STATE-NAME-REPOSITORY-DISCOVERY' -and
  [int]$rejectedC34AState.sourceQualification.completedIdenticalCycles -eq 2 -and
  [int]$rejectedC34AState.actionCounts.build -eq 0 -and
  [int]$rejectedC34AState.actionCounts.upload -eq 0 -and
  [int]$rejectedC34AState.actionCounts.install -eq 0 -and
  [int]$rejectedC34AState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$aggregateHistoricalContracts[16].machineState -ceq
    'prebuild_rejected_postseal_intermediate_state_discovery_after_two_cycles_successor_required'
) -Message 'rejected r60.65 postseal discovery disposition, two retained cycles or 0/0/0/0 truth changed.'

$rejectedC34BContract = $historicalContracts[17]
$rejectedC34BStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC34BContract.statePath) `
  -Label 'rejected r60.66 state'
$rejectedC34BState = Get-Content -Raw -LiteralPath $rejectedC34BStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC34BContract.versionName -ceq '1.0.0-r60.66' -and
  [string]$rejectedC34BContract.versionCode -ceq '2026081366' -and
  [string]$rejectedC34BContract.disposition -ceq 'rejected' -and
  [string]$rejectedC34BContract.machineState -ceq
    'prebuild_rejected_postinput_build_gate_phase_contradiction_successor_required' -and
  [int]$rejectedC34BContract.buildCount -eq 0 -and
  [int]$rejectedC34BContract.uploadCount -eq 0 -and
  [int]$rejectedC34BContract.installCount -eq 0 -and
  [int]$rejectedC34BContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC34BContract.artifactReusable -and
  [string]$rejectedC34BState.machineState -ceq
    'prebuild_rejected_postinput_build_gate_phase_contradiction_successor_required' -and
  [string]$rejectedC34BState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2658-C34B-POSTINPUT-BUILD-GATE-FOUNDER-QUALIFICATION-FLAG-PHASE-CONTRADICTION' -and
  [bool]$rejectedC34BState.rejection.hiddenInputsEnteredAndErased -and
  -not [bool]$rejectedC34BState.rejection.buildAuthorityConsumed -and
  [int]$rejectedC34BState.actionCounts.build -eq 0 -and
  [int]$rejectedC34BState.actionCounts.upload -eq 0 -and
  [int]$rejectedC34BState.actionCounts.install -eq 0 -and
  [int]$rejectedC34BState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$aggregateHistoricalContracts[17].machineState -ceq
    'prebuild_rejected_postinput_build_gate_phase_contradiction_successor_required'
) -Message 'rejected r60.66 postinput phase-contradiction disposition or 0/0/0/0 truth changed.'

$rejectedC34CContract = $historicalContracts[18]
$rejectedC34CStatePath = Resolve-C34DFile `
  -Path ([string]$rejectedC34CContract.statePath) `
  -Label 'rejected r60.67 state'
$rejectedC34CState = Get-Content -Raw -LiteralPath $rejectedC34CStatePath | ConvertFrom-Json
Assert-C34D -Condition (
  [string]$rejectedC34CContract.versionName -ceq '1.0.0-r60.67' -and
  [string]$rejectedC34CContract.versionCode -ceq '2026081367' -and
  [string]$rejectedC34CContract.disposition -ceq 'rejected' -and
  [string]$rejectedC34CContract.machineState -ceq
    'prebuild_rejected_postseal_fixture_patch_context_mismatch_after_two_cycles_successor_required' -and
  [int]$rejectedC34CContract.buildCount -eq 0 -and
  [int]$rejectedC34CContract.uploadCount -eq 0 -and
  [int]$rejectedC34CContract.installCount -eq 0 -and
  [int]$rejectedC34CContract.deviceAcceptanceCount -eq 0 -and
  -not [bool]$rejectedC34CContract.artifactReusable -and
  [string]$rejectedC34CState.machineState -ceq
    'prebuild_rejected_postseal_fixture_patch_context_mismatch_after_two_cycles_successor_required' -and
  [string]$rejectedC34CState.rejection.reasonRegistryIds[0] -ceq
    'REG-20260816-2659-C34C-POSTSEAL-BUILD-FIXTURE-COMPOUND-PATCH-CONTEXT-MISMATCH' -and
  -not [bool]$rejectedC34CState.rejection.hiddenInputsEntered -and
  -not [bool]$rejectedC34CState.rejection.buildAuthorityConsumed -and
  [int]$rejectedC34CState.sourceQualification.completedIdenticalCycles -eq 2 -and
  [int]$rejectedC34CState.actionCounts.build -eq 0 -and
  [int]$rejectedC34CState.actionCounts.upload -eq 0 -and
  [int]$rejectedC34CState.actionCounts.install -eq 0 -and
  [int]$rejectedC34CState.actionCounts.deviceAcceptance -eq 0 -and
  [string]$aggregateHistoricalContracts[18].machineState -ceq
    'prebuild_rejected_postseal_fixture_patch_context_mismatch_after_two_cycles_successor_required'
) -Message 'rejected r60.67 postseal fixture-patch disposition, retained cycles or 0/0/0/0 truth changed.'

for ($index = 0; $index -lt 19; $index++) {
  Assert-C34D -Condition (
    [string]$aggregateHistoricalContracts[$index].versionName -ceq
      [string]$historicalContracts[$index].versionName -and
    [string]$aggregateHistoricalContracts[$index].versionCode -ceq
      [string]$historicalContracts[$index].versionCode -and
    [int]$aggregateHistoricalContracts[$index].buildCount -eq
      [int]$historicalContracts[$index].buildCount -and
    [int]$aggregateHistoricalContracts[$index].uploadCount -eq
      [int]$historicalContracts[$index].uploadCount -and
    [int]$aggregateHistoricalContracts[$index].installCount -eq
      [int]$historicalContracts[$index].installCount -and
    [int]$aggregateHistoricalContracts[$index].deviceAcceptanceCount -eq
      [int]$historicalContracts[$index].deviceAcceptanceCount -and
    -not [bool]$aggregateHistoricalContracts[$index].artifactReusable
  ) -Message "historical aggregate mirror changed at index $index."
}

$phoneState = Get-Content -Raw -LiteralPath (
  Resolve-C34DFile -Path ([string]$state.sourcePrerequisites.phoneReadinessPath) `
    -Label 'Phone readiness state'
) | ConvertFrom-Json
$emailSourceState = Get-Content -Raw -LiteralPath (
  Resolve-C34DFile -Path ([string]$state.sourcePrerequisites.emailSourceStatePath) `
    -Label 'email source state'
) | ConvertFrom-Json
$emailLiveState = Get-Content -Raw -LiteralPath (
  Resolve-C34DFile -Path ([string]$state.sourcePrerequisites.emailLiveReadinessPath) `
    -Label 'email live-readiness state'
) | ConvertFrom-Json
Assert-C34D -Condition (
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

Assert-C34D -Condition (
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
Assert-C34D -Condition (
  [bool]$state.authority.candidatePreparationAndSelectionAuthorized -and
  [bool]$state.authority.candidateIdentityApproved -and
  [bool]$state.authority.sourceQualificationAuthorized -and
  -not [bool]$state.authority.agentSecretValueAccessAuthorized -and
  -not [bool]$state.authority.otherTrackAuthorized -and
  -not [bool]$state.authority.adbOrSideloadAuthorized -and
  -not [bool]$state.authority.backendOrHostingDeploymentAuthorized -and
  -not [bool]$state.authority.providerDeploymentAuthorized -and
  -not [bool]$state.authority.youtubeQuotaOrEmailSubmissionAuthorized -and
  -not [bool]$state.authority.realSmsSendAuthorized -and
  -not [bool]$state.authority.fundsAuthorized -and
  -not [bool]$state.privacyBoundary.secretValuesObserved -and
  -not [bool]$state.privacyBoundary.privateAccountIdentifiersObserved -and
  -not [bool]$state.privacyBoundary.privateLinksObserved -and
  -not [bool]$state.privacyBoundary.oauthClientIdentifierValuesObserved -and
  -not [bool]$state.privacyBoundary.tokenOrAttestationPayloadObserved -and
  -not [bool]$state.privacyBoundary.privateEmailLinkObserved -and
  -not [bool]$state.privacyBoundary.firebaseDebugLogRead
) -Message 'authority or privacy boundary changed.'
if ($Phase -ceq 'source') {
  Assert-C34D -Condition (
    -not [bool]$state.authority.oneAabBuildAuthorizedAfterAllGates -and
    -not [bool]$state.authority.oneInternalTestingUploadAndActivationAuthorizedAfterPostbuild -and
    -not [bool]$state.authority.oneInPlaceOppoPlayUpdateAuthorizedAfterActivation -and
    -not [bool]$state.authority.oneFounderReviewedPasswordlessEmailAuthorizedAfterInstall -and
    -not [bool]$state.authority.founderHiddenInputEntryAuthorized -and
    -not [bool]$state.founderAuthorization.oneSuccessorAabBuildApprovedAfterAllGates -and
    -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
    -not [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder
  ) -Message 'source-only preparation gained AAB, hidden-input, Play, OPPO or email authority.'
}
Assert-C34D -Condition (
  [int]$state.actionCounts.realSmsSend -eq 0 -and
  [int]$state.actionCounts.otherTrack -eq 0 -and
  [int]$state.actionCounts.backendHostingProviderOrProductionDeployment -eq 0 -and
  [int]$aggregate.actionCounts.realSmsSend -eq 0 -and
  [int]$aggregate.actionCounts.otherTrack -eq 0 -and
  [int]$aggregate.actionCounts.backendHostingProviderOrProductionDeployment -eq 0
) -Message 'forbidden action count advanced.'

$launcherPath = Resolve-C34DFile `
  -Path ([string]$state.releaseBinding.founderLauncher) `
  -Label 'C34D founder launcher'
$wrapperPath = Resolve-C34DFile `
  -Path ([string]$state.releaseBinding.authoritativeAabWrapper) `
  -Label 'generic single-AAB wrapper'
$recoveryPath = Resolve-C34DFile `
  -Path ([string]$state.releaseBinding.postbuildRecoveryOwner) `
  -Label 'C34D interrupted-postbuild recovery owner'
$cycleOwnerPath = Resolve-C34DFile `
  -Path ([string]$state.releaseBinding.sourceCycleOwner) `
  -Label 'C34D predeclared source-cycle owner'
$resultRetentionPath = Resolve-C34DFile `
  -Path ([string]$state.releaseBinding.launcherResultRetentionOwner) `
  -Label 'founder launcher result-retention owner'
Assert-C34DPowerShellOwner -Path $launcherPath -Label 'C34D founder launcher'
Assert-C34DPowerShellOwner -Path $wrapperPath -Label 'generic single-AAB wrapper'
Assert-C34DPowerShellOwner `
  -Path $recoveryPath `
  -Label 'C34D interrupted-postbuild recovery owner'
Assert-C34DPowerShellOwner `
  -Path $cycleOwnerPath `
  -Label 'C34D predeclared source-cycle owner'
Assert-C34DPowerShellOwner `
  -Path $resultRetentionPath `
  -Label 'founder launcher result-retention owner'
$launcher = Get-Content -Raw -LiteralPath $launcherPath
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$recovery = Get-Content -Raw -LiteralPath $recoveryPath
$cycleOwner = Get-Content -Raw -LiteralPath $cycleOwnerPath
Assert-C34D -Condition (
  $cycleOwner.IndexOf("[ValidateSet(1, 2)]", [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf("-Manifest', `$focusedRelative", [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf('prebuild_manifest_bound_two_fresh_cycles_required', [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf("'501'", [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf('backendTestsPassed = 537', [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf('webTestsPassed = 8', [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf('sourceUnchanged = $true', [StringComparison]::Ordinal) -ge 0 -and
  $cycleOwner.IndexOf('playWrites = 0', [StringComparison]::Ordinal) -ge 0
) -Message 'predeclared source-cycle command, count, evidence or source-immutability contract changed.'
$gateNeedle = 'scripts/check-uaw-c34d-r60-68-authentication-no-regression-release-readiness.ps1'
$gateIndex = $launcher.IndexOf($gateNeedle, [StringComparison]::Ordinal)
$prepromptPhaseIndex = $launcher.IndexOf('-Phase preprompt', [StringComparison]::Ordinal)
$promptIndex = $launcher.IndexOf('$uploadSecure = Read-Host', [StringComparison]::Ordinal)
$wrapperIndex = $launcher.IndexOf('& $wrapperPath -StatePath $statePath -RepositoryRoot $root', [StringComparison]::Ordinal)
$postinputStateIndex = $launcher.IndexOf(
  "`$state.machineState = 'founder_inputs_validated_single_aab_build_required'",
  [StringComparison]::Ordinal
)
$aggregatePostinputStateIndex = $launcher.IndexOf(
  "`$aggregate.machineState = 'founder_inputs_validated_single_aab_build_required'",
  [StringComparison]::Ordinal
)
$hiddenInputRecordedIndex = $launcher.IndexOf(
  '$state.founderAuthorization.hiddenFounderInputsEntered = $true',
  [StringComparison]::Ordinal
)
$environmentCleanupIndex = $launcher.IndexOf(
  "SetEnvironmentVariable(`$name, `$null, 'Process')",
  [StringComparison]::Ordinal
)
$fileCleanupIndex = $launcher.IndexOf(
  'Remove-Item -LiteralPath $path -Force',
  [StringComparison]::Ordinal
)
$retainedResultIndex = $launcher.IndexOf(
  'Complete-C30TFounderLauncherResult -Result $launcherResult',
  [StringComparison]::Ordinal
)
Assert-C34D -Condition (
  $gateIndex -ge 0 -and
  $prepromptPhaseIndex -gt $gateIndex -and
  $promptIndex -gt $prepromptPhaseIndex -and
  $wrapperIndex -gt $promptIndex -and
  [regex]::Matches($launcher, 'Read-Host[^\r\n]*-AsSecureString').Count -eq 3 -and
  $launcher.IndexOf('ZeroFreeBSTR', [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf('Write-Host ("PowerShell {0}" -f $PSVersionTable.PSVersion.ToString())', [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf('C34D r60.68 founder-owned visible console confirmed.', [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf('-not [bool]$preState.runtimeConfiguration.secretDefineFileQualifiedByFounder', [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf('-not [bool]$preState.runtimeConfiguration.googleServicesFileQualifiedByFounder', [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf('-not [bool]$preState.runtimeConfiguration.googleServerClientIdQualifiedByFounder', [StringComparison]::Ordinal) -ge 0 -and
  $postinputStateIndex -gt $promptIndex -and
  $aggregatePostinputStateIndex -gt $promptIndex -and
  $hiddenInputRecordedIndex -gt $promptIndex -and
  $postinputStateIndex -lt $wrapperIndex -and
  $aggregatePostinputStateIndex -lt $wrapperIndex -and
  $hiddenInputRecordedIndex -lt $wrapperIndex -and
  $launcher.IndexOf('$state.runtimeConfiguration.secretDefineFileQualifiedByFounder = $true', [StringComparison]::Ordinal) -lt $wrapperIndex -and
  $launcher.IndexOf('$state.runtimeConfiguration.googleServicesFileQualifiedByFounder = $true', [StringComparison]::Ordinal) -lt $wrapperIndex -and
  $launcher.IndexOf('$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder = $true', [StringComparison]::Ordinal) -lt $wrapperIndex -and
  $environmentCleanupIndex -gt $wrapperIndex -and
  $fileCleanupIndex -gt $environmentCleanupIndex -and
  $retainedResultIndex -gt $fileCleanupIndex -and
  $launcher.IndexOf("`$launcherResult = 'build_qualified'", [StringComparison]::Ordinal) -gt
    $wrapperIndex -and
  $launcher.IndexOf("`$launcherResult = 'stopped_after_cleanup'", [StringComparison]::Ordinal) -ge 0 -and
  $launcher.IndexOf(
    "throw 'C34D founder launcher stopped after cleanup; reconcile repository state before any retry.'",
    [StringComparison]::Ordinal
  ) -gt $retainedResultIndex
) -Message 'founder launcher ordering, three hidden prompts, cleanup or retained result changed.'
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
  Assert-C34D -Condition (
    $launcher.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -lt 0
  ) -Message "founder launcher contains forbidden output or clipboard owner: $forbidden"
}
Assert-C34D -Condition (
  $wrapper.IndexOf(
    "'MOOLSOCIAL-C34D-R60-68-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c34d-r60-68-authentication-no-regression-release-readiness.ps1' }",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $wrapper.IndexOf('& $gate -Phase build', [StringComparison]::Ordinal) -lt
    $wrapper.IndexOf("`$state.buildAuthorization = 'consumed'", [StringComparison]::Ordinal) -and
  [regex]::Matches($wrapper, "'appbundle'").Count -eq 1
) -Message 'generic wrapper C34D binding, gate order or single appbundle owner changed.'
Assert-C34D -Condition (
  $recovery.IndexOf(
    "[ValidateSet('audit', 'apply')]",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $recovery.IndexOf(
    "[string]`$state.buildAuthorization -ceq 'consumed'",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $recovery.IndexOf(
    '[int]$aggregate.actionCounts.build -eq 1',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $recovery.IndexOf(
    "[string]`$aggregate.releaseAuthorities.build -ceq 'consumed'",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $recovery.IndexOf('exactly one completed provenance owner is required.', [StringComparison]::Ordinal) -ge 0 -and
  $recovery.IndexOf("if (`$Mode -ceq 'apply')", [StringComparison]::Ordinal) -ge 0 -and
  $recovery.IndexOf('secondBuild=false', [StringComparison]::Ordinal) -ge 0 -and
  $recovery.IndexOf('flutter build', [StringComparison]::OrdinalIgnoreCase) -lt 0 -and
  $recovery.IndexOf("'appbundle'", [StringComparison]::OrdinalIgnoreCase) -lt 0 -and
  $recovery.IndexOf('adb install', [StringComparison]::OrdinalIgnoreCase) -lt 0 -and
  $recovery.IndexOf('play upload', [StringComparison]::OrdinalIgnoreCase) -lt 0
) -Message 'presealed recovery owner can rebuild, mutate device/Play or bypass exact provenance and consumed mirrors.'

$scopeGate = Resolve-C34DFile -Path 'scripts/check-mvp-scope-gate-state.ps1' -Label 'MVP scope gate'
if ($Phase -ceq 'source') {
  & $scopeGate `
    -StatePath $ScopePath `
    -CandidateId $ticketId `
    -RepositoryRoot $root | Out-Null
} else {
  & $scopeGate `
    -StatePath $ScopePath `
    -CandidateId $ticketId `
    -RequireExecutionAuthorized `
    -RepositoryRoot $root | Out-Null
}
$mvpStatePath = Resolve-C34DFile -Path $ScopePath -Label 'MVP state'
$mvpState = Get-Content -Raw -LiteralPath $mvpStatePath | ConvertFrom-Json
$checkpoint = $mvpState.preTicketSelectionCheckpoint
$qualifiedPreventions = @(
  [pscustomobject]@{
    assessment = $checkpoint.priorC33LFix4SelectedTicketAssessment
    ticketId = 'UAW-C33L-FIX4-GENERIC-AAB-POSTBUILD-AGGREGATE-MIRROR-ATOMICITY'
    ticketSha = '2EE039F85DE0E313593D7875BF1A1B7694F7359CBC403B301DA22C4D65FF7BA1'
    state = 'source_test_gate_repair_qualified_dual_host_parent_successor_required_build_Play_OPPO_and_external_actions_held'
    evidenceSha = '1ABA97C1E97A227007F6D248DAB88C3F4DBDE87C7CB38894E678C2E305E1A257'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33LFix5SelectedTicketAssessment
    ticketId = 'UAW-C33L-FIX5-FOUNDER-AAB-LAUNCHER-POSTCLEANUP-RESULT-RETENTION'
    ticketSha = '2F558255A40D63AA940D9FD14DFD1D3D1AB67B87A095F45AF342046FD8FA957D'
    state = 'source_test_gate_repair_qualified_dual_host_future_launcher_binding_required_build_Play_OPPO_and_external_actions_held'
    evidenceSha = 'C600BD1F9D148154AB7032A1413C0893F4B8B52D78FC5AF7C5F837ED94FC40E5'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33LFix6SelectedTicketAssessment
    ticketId = 'UAW-C33L-FIX6-FIX4-GATE-SUCCESSOR-REPLAY-COMPATIBILITY'
    ticketSha = '67F9F63ED3F44DC94A0E6DC5480704183AC52F18CEFE16225DDDCFDA86D98BB1'
    state = 'source_test_gate_repair_qualified_dual_host_parent_successor_replay_ready_build_Play_OPPO_and_external_actions_held'
    evidenceSha = 'F1BDEE542DF89349C791A27E38E4B8FD7CFA882AA05F6712171234CA20AE90EC'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33MFix1SelectedTicketAssessment
    ticketId = 'UAW-C33M-FIX1-C33L-FIX5-GATE-SUCCESSOR-REPLAY-COMPATIBILITY'
    ticketSha = '5BA0420B29288C3BAB861E2C6A9D0B4A81389341F091883C76F3F9B5F144BD89'
    state = 'source_test_gate_repair_qualified_dual_host_parent_successor_replay_ready_build_Play_OPPO_email_and_external_actions_held'
    evidenceSha = '8271D2BE07CDBA4564EFB5A7F370B8D24EB388F27A31A1615EF85D35C4FE056F'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33MFix2SelectedTicketAssessment
    ticketId = 'UAW-C33M-FIX2-C33L-FIX1-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
    ticketSha = 'AFF8F6A5741ECEBEF68B47F46CF47B77FBB961D4A3327F89F2C5C81EB35E7EED'
    state = 'source_test_gate_repair_qualified_dual_host_generic_successor_replay_ready_build_Play_OPPO_email_and_external_actions_held'
    evidenceSha = 'F6BFAE580AF5746D63BE58455A8130E0E3A08B0BA9458D1BA8CB9FD65486F6D6'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33MFix3SelectedTicketAssessment
    ticketId = 'UAW-C33M-FIX3-C33L-FIX3-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
    ticketSha = '2722BB4C6F167D4481A98BE638140564135B210F82CD56E2515C77B5BA5E6A53'
    state = 'source_test_gate_repair_qualified_dual_host_historical_generic_successor_and_negative_replay_ready_build_Play_OPPO_email_and_external_actions_held'
    evidenceSha = 'A4260CCC605CB98A3506E72E7D4B8D90E7EF23826FA185CA59898EE251FAEC16'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33MFix4SelectedTicketAssessment
    ticketId = 'UAW-C33M-FIX4-PUBLIC-REVIEW-FRESH-PROCESS-AUTH-RETURN-PERSISTENCE'
    ticketSha = 'FB56B77AEE47D211D5924C568D72668B6BF150FE28AE5C0BEEFF10656F47025C'
    state = 'source_repair_two_identical_cycles_qualified_registry_2570_flutter_496_3_backend_537_web_8_dual_host_FIX4_FIX6_FIX7_passed_source_unchanged_build_Play_OPPO_provider_email_and_external_actions_held'
    evidenceSha = '684DF0F6D14325705BA128EEFF9D58047799245AC9A8A6819CA962342D0AB9A2'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33MFix5SelectedTicketAssessment
    ticketId = 'UAW-C33M-FIX5-PUBLIC-REVIEW-FIREBASE-PASSWORDLESS-EMAIL-GATEWAY'
    ticketSha = '05FD94BC8FF515700BBBFF20C2AE8748C20AC1C1AFC6167E8042C0748A7552DD'
    state = 'source_repair_two_identical_cycles_qualified_registry_2574_flutter_501_3_backend_537_web_8_dual_host_FIX5_FIX6_FIX7_FIX8_passed_source_unchanged_build_Play_OPPO_provider_email_and_external_actions_held'
    evidenceSha = 'CF8FDF23320089A09B53905F73ABE411E053E3145F9B12E03995BDB466210212'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33MFix6SelectedTicketAssessment
    ticketId = 'UAW-C33M-FIX6-C33J-GATE-TRILOGY-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
    ticketSha = '0C395D2A7F73A938D320D637B6ED721328E72269BD22EC94BF51012AA8892431'
    state = 'gate_trilogy_generic_successor_replay_qualified_dual_host_historical_6_generic_3_negative_21_live_3_FIX4_reselection_required'
    evidenceSha = '76DCB9561CD7C737A517CF196E1C2BBC48F5962F2B99BB1CBADF620224D916BE'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33MFix7SelectedTicketAssessment
    ticketId = 'UAW-C33M-FIX7-C33K-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
    ticketSha = 'C040D3CEEAE8EB4E46CE29FBD2250C16F006E3F48A53FA1587E88FF031671CFB'
    state = 'C33K_generic_successor_replay_qualified_dual_host_historical_1_generic_1_negative_6_live_Postwrite_FIX4_reselection_required'
    evidenceSha = '85C19BA5A8837F5A57AA851C67A360805A51AB4B084B5E4B73DE4BDC3A02C86F'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33MFix8SelectedTicketAssessment
    ticketId = 'UAW-C33M-FIX8-FIX4-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
    ticketSha = '806B59F65D4E9A7422F23D2F6C79010A01F2A6AA592359A754071B42019671F8'
    state = 'FIX4_generic_successor_replay_qualified_dual_host_historical_1_generic_1_negative_6_live_FIX5_reselection_required'
    evidenceSha = '56F41DB33ACFACB602B7B848CDDFBFB9BE64F7C959273458A9B16F25FDFE152B'
  },
  [pscustomobject]@{
    assessment = $checkpoint.priorC33NFix1SelectedTicketAssessment
    ticketId = 'UAW-C33N-FIX1-C33M-FIX5-GATE-GENERIC-SUCCESSOR-REPLAY-COMPATIBILITY'
    ticketSha = '39F5640A6C4EB8BA3D530DCC796E0A0E9007CB647DED8F62852E51245E69698F'
    state = 'FIX5_generic_successor_replay_qualified_dual_host_historical_1_generic_1_negative_6_live_C33N_reselection_required'
    evidenceSha = '591C795792CE3541DE1C0D29DB489668432A3F81A60FF24C4F9C375D99F965D4'
  }
)
foreach ($prevention in $qualifiedPreventions) {
  $assessment = $prevention.assessment
  $preventionTicketPath = Resolve-C34DFile `
    -Path ([string]$assessment.manifestPath) `
    -Label "qualified prevention ticket $($prevention.ticketId)"
  $preventionEvidencePath = Resolve-C34DFile `
    -Path ([string]$assessment.evidencePath) `
    -Label "qualified prevention evidence $($prevention.ticketId)"
  Assert-C34D -Condition (
    [string]$assessment.ticketId -ceq [string]$prevention.ticketId -and
    [string]$assessment.manifestSha256 -ceq [string]$prevention.ticketSha -and
    (Get-FileHash -Algorithm SHA256 -LiteralPath $preventionTicketPath).Hash -ceq
      [string]$prevention.ticketSha -and
    [string]$assessment.implementationState -ceq [string]$prevention.state -and
    (Get-FileHash -Algorithm SHA256 -LiteralPath $preventionEvidencePath).Hash -ceq
      [string]$prevention.evidenceSha
  ) -Message "qualified prevention binding changed: $($prevention.ticketId)"
}
$fix4Gate = Resolve-C34DFile `
  -Path 'scripts/check-uaw-c33l-fix4-generic-aab-postbuild-aggregate-mirror-atomicity.ps1' `
  -Label 'FIX4 successor replay gate'
$fix5Gate = Resolve-C34DFile `
  -Path 'scripts/check-uaw-c33l-fix5-founder-aab-launcher-postcleanup-result-retention.ps1' `
  -Label 'FIX5 successor replay gate'
$safeBootGate = Resolve-C34DFile `
  -Path 'scripts/check-uaw-c33l-fix1-private-dev-public-review-screen04-safe-boot-regression.ps1' `
  -Label 'Screen 04 safe-boot successor replay gate'
$flutterClassificationGate = Resolve-C34DFile `
  -Path 'scripts/check-uaw-c33l-fix3-authoritative-flutter-null-event-classification.ps1' `
  -Label 'authoritative Flutter classification successor replay gate'
& $fix4Gate -RepositoryRoot $root | Out-Null
& $fix5Gate -RepositoryRoot $root | Out-Null
& $safeBootGate -RepositoryRoot $root | Out-Null
& $flutterClassificationGate -RepositoryRoot $root | Out-Null
foreach ($successorGatePath in @(
  'scripts/check-uaw-c33m-fix4-public-review-fresh-process-auth-return-persistence.ps1',
  'scripts/check-uaw-c33m-fix5-public-review-firebase-passwordless-email-gateway.ps1',
  'scripts/check-uaw-c33m-fix6-c33j-gate-trilogy-generic-successor-replay-compatibility.ps1',
  'scripts/check-uaw-c33m-fix7-c33k-gate-generic-successor-replay-compatibility.ps1',
  'scripts/check-uaw-c33m-fix8-fix4-gate-generic-successor-replay-compatibility.ps1',
  'scripts/check-uaw-c33n-fix1-c33m-fix5-gate-generic-successor-replay-compatibility.ps1'
)) {
  $successorGate = Resolve-C34DFile -Path $successorGatePath `
    -Label 'qualified C33M successor replay gate'
  & $successorGate -RepositoryRoot $root | Out-Null
}
$memoryGate = Resolve-C34DFile `
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

$phoneGate = Resolve-C34DFile `
  -Path ([string]$state.sourcePrerequisites.phoneGatePath) `
  -Label 'Phone source gate'
& $phoneGate -Phase source -RepositoryRoot $root | Out-Null
$blockerGate = Resolve-C34DFile `
  -Path ([string]$state.sourcePrerequisites.blockerGatePath) `
  -Label 'C33G blocker gate'
if ($Phase -in @('postinstall', 'journey')) {
  & $blockerGate `
    -CandidateId $ticketId `
    -CandidateVersionCode '2026081368' `
    -Phase postinstall `
    -RepositoryRoot $root | Out-Null
} else {
  & $blockerGate `
    -CandidateId $ticketId `
    -CandidateVersionCode '2026081368' `
    -Phase prebuild `
    -RepositoryRoot $root | Out-Null
}
$googleStatePath = Resolve-C34DFile `
  -Path ([string]$state.sourcePrerequisites.googleLiveReadinessPath) `
  -Label 'Google live-readiness state'
$googleStateRaw = Get-Content -Raw -LiteralPath $googleStatePath
Assert-C34DSanitizedText -Text $googleStateRaw -Label 'Google live-readiness state'
$googleState = $googleStateRaw | ConvertFrom-Json
$googleFacts = @($googleState.readinessFacts)
$requiredGoogleFacts = @(
  'firebase_android_app_play_signer',
  'firebase_google_provider_enabled',
  'android_oauth_package_play_signer_relationship',
  'web_server_client_mobile_relationship'
)
Assert-C34D -Condition (
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
Assert-C34D -Condition (
  @($googleFactIds | Select-Object -Unique).Count -eq 4 -and
  @($requiredGoogleFacts | Where-Object { $_ -cnotin $googleFactIds }).Count -eq 0
) -Message 'sanitized Google readiness fact identifiers changed.'
foreach ($googleFact in $googleFacts) {
  Assert-C34D -Condition (
    [string]$googleFact.status -ceq 'qualified_sanitized_non_secret_evidence' -and
    [string]$googleFact.evidenceSha256 -match '^[0-9A-F]{64}$'
  ) -Message "Google readiness fact is not qualified: $($googleFact.id)"
  $googleEvidencePath = Resolve-C34DFile `
    -Path ([string]$googleFact.evidencePath) `
    -Label "Google readiness evidence $($googleFact.id)"
  Assert-C34D -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $googleEvidencePath).Hash -ceq
      [string]$googleFact.evidenceSha256
  ) -Message "Google readiness evidence changed: $($googleFact.id)"
}
$runtimeGate = Resolve-C34DFile `
  -Path ([string]$state.sourcePrerequisites.releaseRuntimeGatePath) `
  -Label 'C30W release-runtime gate'
if ($Phase -ceq 'source') {
  & $runtimeGate -Phase source -StatePath $resolvedStatePath -RepositoryRoot $root | Out-Null
}

$registryPath = Resolve-C34DFile `
  -Path ([string]$state.regressionMemory.registryPath) `
  -Label 'regression registry'
$registryRaw = Get-Content -Raw -LiteralPath $registryPath
Assert-C34DSanitizedText -Text $registryRaw -Label 'regression registry'
$registry = $registryRaw | ConvertFrom-Json
$registryCount = @($registry.entries).Count
$registrySha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $registryPath).Hash
$cycles = [int]$state.sourceQualification.completedIdenticalCycles
$focusedManifestPath = Resolve-C34DFile `
  -Path ([string]$state.sourceQualification.focusedManifestPath) `
  -Label 'focused test manifest'
$focusedManifestFileCount = @(
  Get-Content -LiteralPath $focusedManifestPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
).Count
Assert-C34D -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $focusedManifestPath).Hash -ceq
    [string]$state.sourceQualification.focusedManifestSha256 -and
  [string]$aggregate.sourceQualification.focusedManifestSha256 -ceq
    [string]$state.sourceQualification.focusedManifestSha256 -and
  $focusedManifestFileCount -eq 73 -and
  [int]$state.sourceQualification.focusedManifestFileCount -eq 73 -and
  [int]$aggregate.sourceQualification.focusedManifestFileCount -eq 73
) -Message 'final on-disk focused test manifest SHA-256 or nonblank count changed before sealing.'
$browserWorkflowQualified = (
  [bool]$state.presealUploadWorkflow.liveBrowserRouteQualified -and
  [bool]$state.presealUploadWorkflow.signedInMoolSocialAppRouteProved -and
  [bool]$state.presealUploadWorkflow.internalTestingRouteProved -and
  [bool]$state.presealUploadWorkflow.noPlayWritePerformed -and
  [bool]$aggregate.presealUploadWorkflow.liveBrowserRouteQualified -and
  [bool]$aggregate.presealUploadWorkflow.signedInMoolSocialAppRouteProved -and
  [bool]$aggregate.presealUploadWorkflow.internalTestingRouteProved -and
  [bool]$aggregate.presealUploadWorkflow.noPlayWritePerformed
)
$sourceQualified = (
  $cycles -eq 2 -and
  $browserWorkflowQualified -and
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
if ($Phase -ceq 'source' -and $cycles -eq 2) {
  Assert-C34D -Condition (
    [string]$state.machineState -ceq
      'source_regression_memory_two_identical_cycles_qualified_build_authority_held' -and
    [string]$aggregate.machineState -ceq
      'source_regression_memory_two_identical_cycles_qualified_build_authority_held' -and
    [string]$state.buildAuthorization -ceq
      'held_founder_aab_authorization_and_source_qualification' -and
    [string]$aggregate.releaseAuthorities.build -ceq
      'held_founder_aab_authorization_and_source_qualification'
  ) -Message 'post-cycle source replay requires the predeclared build-authority-held transition.'
}
if ($cycles -eq 0) {
  if ([string]$state.machineState -ceq 'prebuild_composition_registered_two_fresh_cycles_required') {
    Assert-C34D -Condition (
      [string]$aggregate.machineState -ceq
        'prebuild_composition_registered_two_fresh_cycles_required' -and
      [string]$state.buildAuthorization -ceq
        'held_founder_aab_authorization_and_source_qualification' -and
      [string]$aggregate.releaseAuthorities.build -ceq
        'held_founder_aab_authorization_and_source_qualification' -and
      [int]$aggregate.sourceQualification.completedIdenticalCycles -eq 0 -and
      $null -eq $state.sourceQualification.manifestSha256 -and
      $null -eq $aggregate.sourceQualification.manifestSha256 -and
      [int]$state.sourceQualification.fileCount -eq 0 -and
      [int]$aggregate.sourceQualification.fileCount -eq 0
    ) -Message 'pre-seal composition state, empty manifest bindings or held build authority changed.'
  } elseif ([string]$state.machineState -ceq 'prebuild_manifest_bound_two_fresh_cycles_required') {
    Assert-C34D -Condition (
      [string]$aggregate.machineState -ceq
        'prebuild_manifest_bound_two_fresh_cycles_required' -and
      [string]$state.buildAuthorization -ceq
        'held_founder_aab_authorization_and_source_qualification' -and
      [string]$aggregate.releaseAuthorities.build -ceq
        'held_founder_aab_authorization_and_source_qualification' -and
      [int]$aggregate.sourceQualification.completedIdenticalCycles -eq 0 -and
      -not [string]::IsNullOrWhiteSpace([string]$state.sourceQualification.manifestSha256) -and
      [string]$aggregate.sourceQualification.manifestSha256 -ceq
        [string]$state.sourceQualification.manifestSha256 -and
      [int]$state.sourceQualification.fileCount -gt 0 -and
      [int]$aggregate.sourceQualification.fileCount -eq
        [int]$state.sourceQualification.fileCount
    ) -Message 'post-seal manifest-bound pre-cycle state or held build authority changed.'
    $manifestPath = Resolve-C34DFile `
      -Path ([string]$state.sourceQualification.manifestPath) `
      -Label 'sealed source manifest'
    Assert-C34D -Condition (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash -ceq
        [string]$state.sourceQualification.manifestSha256
    ) -Message 'sealed source-manifest file changed before cycle 1.'
    Assert-C34DManifestCurrent -ManifestPath $manifestPath
  } else {
    Assert-C34D -Condition $false `
      -Message 'cycles-zero lifecycle is neither pre-seal composition nor post-seal manifest-bound preparation.'
  }
} else {
  Assert-C34D -Condition $browserWorkflowQualified `
    -Message 'source cycles cannot be counted before the signed-in MoolSocial Internal Testing route is prequalified.'
  Assert-C34D -Condition $sourceQualified `
    -Message 'two identical zero-failure cycles or exact regression-registry seal is incomplete.'
  Assert-C34D -Condition (
    [int]$aggregate.sourceQualification.completedIdenticalCycles -eq 2 -and
    [string]$aggregate.sourceQualification.manifestPath -ceq
      [string]$state.sourceQualification.manifestPath -and
    [string]$aggregate.sourceQualification.manifestSha256 -ceq
      [string]$state.sourceQualification.manifestSha256 -and
    [int]$state.sourceQualification.fileCount -gt 0 -and
    [int]$aggregate.sourceQualification.fileCount -eq
      [int]$state.sourceQualification.fileCount -and
    [string]$aggregate.sourceQualification.focusedManifestSha256 -ceq
      [string]$state.sourceQualification.focusedManifestSha256
  ) -Message 'source qualification aggregate mirror changed.'
  $manifestPath = Resolve-C34DFile `
    -Path ([string]$state.sourceQualification.manifestPath) `
    -Label 'sealed source manifest'
  Assert-C34D -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash -ceq
      [string]$state.sourceQualification.manifestSha256
  ) -Message 'sealed source-manifest file changed.'
  Assert-C34DManifestCurrent -ManifestPath $manifestPath
  Assert-C34D -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $focusedManifestPath).Hash -ceq
      [string]$state.sourceQualification.focusedManifestSha256
  ) -Message 'focused test manifest changed.'
}

Assert-C34D -Condition (
  [int]$state.actionCounts.build -eq [int]$aggregate.actionCounts.build -and
  [int]$state.actionCounts.upload -eq [int]$aggregate.actionCounts.upload -and
  [int]$state.actionCounts.install -eq [int]$aggregate.actionCounts.install -and
  [int]$state.actionCounts.deviceAcceptance -eq [int]$aggregate.actionCounts.deviceAcceptance -and
  [int]$state.actionCounts.passwordlessEmailSend -eq [int]$aggregate.actionCounts.passwordlessEmailSend
) -Message 'state/aggregate action-count mirror changed.'

if ($Phase -ceq 'preprompt') {
  Assert-C34D -Condition $sourceQualified `
    -Message 'preprompt requires two identical zero-failure cycles and the exact registry seal.'
  Assert-C34D -Condition (
    [bool]$state.authority.oneAabBuildAuthorizedAfterAllGates -and
    [bool]$state.authority.founderHiddenInputEntryAuthorized -and
    [bool]$state.founderAuthorization.oneSuccessorAabBuildApprovedAfterAllGates -and
    [bool]$state.founderAuthorization.candidateIdentitySealed -and
    [string]$state.machineState -ceq
      'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required' -and
    [string]$aggregate.machineState -ceq
      'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required' -and
    [string]$state.buildAuthorization -ceq 'available_once' -and
    [string]$aggregate.releaseAuthorities.build -ceq 'available_once' -and
    [string]$state.buildResult.state -ceq 'not_started' -and
    [int]$state.buildResult.buildCount -eq 0 -and
    [int]$state.actionCounts.build -eq 0 -and
    -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
    -not [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent -and
    -not [bool]$state.runtimeConfiguration.googleServicesFileReadByAgent
  ) -Message 'preprompt authority, false qualification flags or prompt-required state changed.'
}

if ($Phase -ceq 'build') {
  Assert-C34D -Condition $sourceQualified `
    -Message 'build requires two identical zero-failure cycles and the exact registry seal.'
  Assert-C34D -Condition (
    [bool]$state.authority.oneAabBuildAuthorizedAfterAllGates -and
    [bool]$state.authority.founderHiddenInputEntryAuthorized -and
    [bool]$state.founderAuthorization.oneSuccessorAabBuildApprovedAfterAllGates -and
    [bool]$state.founderAuthorization.candidateIdentitySealed -and
    [string]$state.machineState -ceq
      'founder_inputs_validated_single_aab_build_required' -and
    [string]$aggregate.machineState -ceq
      'founder_inputs_validated_single_aab_build_required' -and
    [string]$state.buildAuthorization -ceq 'available_once' -and
    [string]$aggregate.releaseAuthorities.build -ceq 'available_once' -and
    [string]$state.buildResult.state -ceq 'not_started' -and
    [int]$state.buildResult.buildCount -eq 0 -and
    [int]$state.actionCounts.build -eq 0 -and
    [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
    [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
    [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
    [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent -and
    -not [bool]$state.runtimeConfiguration.googleServicesFileReadByAgent
  ) -Message 'single AAB postinput authority, validated qualification flags or build state changed.'
}

if ($Phase -ceq 'postbuild') {
  Assert-C34D -Condition (
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
  Assert-C34D -Condition (
    [string]$state.uploadAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq 'available_once' -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 0 -and
    [int]$state.actionCounts.install -eq 0
  ) -Message 'Internal Testing upload authority or action counts are not ready.'
}

if ($Phase -ceq 'postupload') {
  Assert-C34D -Condition (
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
  Assert-C34D -Condition (
    [string]$state.installAuthorization -ceq 'available_once' -and
    [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq 'available_once' -and
    [int]$state.actionCounts.upload -eq 1 -and
    [int]$state.actionCounts.install -eq 0
  ) -Message 'one in-place OPPO Play-update authority or action counts are not ready.'
}

if ($Phase -in @('postinstall', 'journey')) {
  Assert-C34D -Condition (
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
  Assert-C34D -Condition (
    [int]$state.actionCounts.deviceAcceptance -eq 1 -and
    [int]$aggregate.actionCounts.deviceAcceptance -eq 1 -and
    [bool]$state.installResult.acceptanceSucceeded -and
    -not [string]::IsNullOrWhiteSpace([string]$state.installResult.journeyEvidencePath) -and
    [int]$state.actionCounts.passwordlessEmailSend -eq 1 -and
    [int]$state.actionCounts.realSmsSend -eq 0
  ) -Message 'complete Google, Phone, email, Social and whole-app device acceptance is incomplete.'
}

Write-Output (
  'C34D r60.68 no-regression release gate passed: ' +
  "phase=$Phase; registryEntries=$registryCount; sourceCycles=$cycles/2; " +
  "buildCount=$($state.actionCounts.build); uploadCount=$($state.actionCounts.upload); " +
  "installCount=$($state.actionCounts.install); deviceAcceptanceCount=$($state.actionCounts.deviceAcceptance); " +
  'historicalRepeatAllowed=false; newDefectAllowed=false; waivers=false; secretValuesObserved=false.'
)
