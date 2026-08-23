[CmdletBinding()]
param(
  [switch]$RequireQualified,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C34PFix5([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34P FIX5 live-provider readiness gate rejected: $Message"
  }
}

function Resolve-C34PFix5File([string]$RelativePath, [string]$Label) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C34PFix5 (
    $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $path -PathType Leaf)
  ) "$Label is missing or escaped the repository."
  return $path
}

function Read-C34PFix5Json([string]$RelativePath, [string]$Label) {
  $path = Resolve-C34PFix5File $RelativePath $Label
  try { return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json }
  catch { throw "C34P FIX5 live-provider readiness gate rejected: $Label JSON is invalid." }
}

function Read-C34PFix5Text([string]$RelativePath, [string]$Label) {
  return Get-Content -LiteralPath (
    Resolve-C34PFix5File $RelativePath $Label
  ) -Raw
}

function Assert-C34PFix5Contains(
  [string]$Body,
  [string]$Expected,
  [string]$Label
) {
  Assert-C34PFix5 (
    $Body.IndexOf($Expected, [StringComparison]::Ordinal) -ge 0
  ) "$Label is missing $Expected"
}

$ticketId = 'UAW-C34P-FIX5-ALL-EIGHT-PUBLIC-AUTH-LIVE-PROVIDER-READINESS'
$ticket = Read-C34PFix5Json `
  'config/uaw-c34p-fix5-all-eight-public-auth-live-provider-readiness-ticket.json' `
  'FIX5 ticket'
$fix8TicketId = 'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR'
$fix8TicketRelative = `
  'config/uaw-c34p-fix8-global-social-login-oppo-successor-audit-repair-ticket.json'
$fix8TicketPath = Resolve-C34PFix5File $fix8TicketRelative 'FIX8 ticket'
$fix8Ticket = Read-C34PFix5Json $fix8TicketRelative 'FIX8 ticket'
$fix8TicketHash = (Get-FileHash -LiteralPath $fix8TicketPath -Algorithm SHA256).Hash
$mvp = Read-C34PFix5Json 'config/mvp-scope-gate-state.json' 'MVP state'
$state = Read-C34PFix5Json `
  'config/public-auth-live-provider-readiness-state-c34p-fix5.json' `
  'provider readiness state'
$apkState = Read-C34PFix5Json `
  'config/apk-regression-gate-state.json' `
  'APK regression state'
$ticketRelease = $fix8Ticket.releaseAuthorization
$auditRelease = $state.comprehensiveSuccessorAudit.releaseAuthorization
$fix8R6084ManifestPath = [IO.Path]::GetFullPath((Join-Path `
  $root `
  ([string]$ticketRelease.sourceManifestPath)
))
$fix8PrebuildLifecycle = (
  [string]$fix8Ticket.status -ceq
    'successor_candidate_registered_one_build_and_in_place_sideload_authorized' -and
  [string]$ticketRelease.state -ceq
    'prebuild_registered_one_build_and_one_in_place_sideload_authorized' -and
  [int]$ticketRelease.buildCount -eq 0 -and
  [int]$ticketRelease.installCount -eq 0 -and
  [bool]$fix8Ticket.authority.buildAuthorized -and
  [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  [string]$state.machineState -ceq
    'fix8_successor_candidate_registered_prebuild_authorized' -and
  [bool]$state.authority.buildAuthorized -and
  [bool]$state.authority.oppoAuthorized -and
  [int]$state.actionCounts.build -eq 0 -and
  [int]$state.actionCounts.oppoUpdate -eq 0 -and
  [string]$state.comprehensiveSuccessorAudit.state -ceq
    'successor_candidate_registered_one_build_and_in_place_sideload_authorized' -and
  [bool]$state.comprehensiveSuccessorAudit.newCandidateRegistered -and
  [bool]$state.comprehensiveSuccessorAudit.buildAuthorized -and
  [bool]$state.comprehensiveSuccessorAudit.installAuthorized -and
  [int]$auditRelease.buildCount -eq 0 -and
  [int]$auditRelease.installCount -eq 0 -and
  [bool]$mvp.execution.buildAuthorized -and
  [bool]$mvp.execution.deviceInstallAuthorized
)
$fix8FailedBuildLifecycle = (
  [string]$fix8Ticket.status -ceq
    'r60_81_build_attempt_failed_resource_link_repair_and_new_authority_required' -and
  [string]$ticketRelease.state -ceq
    'r60_81_build_attempt_consumed_failed_no_apk_or_install_new_build_authority_required' -and
  [int]$ticketRelease.buildCount -eq 1 -and
  [int]$ticketRelease.installCount -eq 0 -and
  -not [bool]$fix8Ticket.authority.buildAuthorized -and
  -not [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  [string]$state.machineState -ceq
    'fix8_r60_81_build_failed_resource_link_repair_required_no_retry_authorized' -and
  -not [bool]$state.authority.buildAuthorized -and
  -not [bool]$state.authority.oppoAuthorized -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$state.actionCounts.oppoUpdate -eq 0 -and
  [string]$state.comprehensiveSuccessorAudit.state -ceq
    'r60_81_build_attempt_failed_resource_link_no_apk_or_install_repair_and_new_authority_required' -and
  [bool]$state.comprehensiveSuccessorAudit.newCandidateRegistered -and
  -not [bool]$state.comprehensiveSuccessorAudit.buildAuthorized -and
  -not [bool]$state.comprehensiveSuccessorAudit.installAuthorized -and
  [int]$auditRelease.buildCount -eq 1 -and
  [int]$auditRelease.installCount -eq 0 -and
  -not [bool]$mvp.execution.buildAuthorized -and
  -not [bool]$mvp.execution.deviceInstallAuthorized
)
$fix8RepairQualifiedLifecycle = (
  [string]$fix8Ticket.status -ceq
    'r60_81_release_resource_repair_qualified_new_build_authority_pending' -and
  [string]$ticketRelease.state -ceq
    'r60_81_release_resource_repair_qualified_new_build_authority_pending' -and
  [int]$ticketRelease.buildCount -eq 1 -and
  [int]$ticketRelease.installCount -eq 0 -and
  -not [bool]$fix8Ticket.authority.buildAuthorized -and
  -not [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  [string]$state.machineState -ceq
    'fix8_r60_81_release_resource_repair_qualified_new_build_authority_pending' -and
  -not [bool]$state.authority.buildAuthorized -and
  -not [bool]$state.authority.oppoAuthorized -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$state.actionCounts.oppoUpdate -eq 0 -and
  [string]$state.comprehensiveSuccessorAudit.state -ceq
    'r60_81_release_resource_repair_qualified_no_apk_or_install_new_build_authority_pending' -and
  [bool]$state.comprehensiveSuccessorAudit.newCandidateRegistered -and
  -not [bool]$state.comprehensiveSuccessorAudit.buildAuthorized -and
  -not [bool]$state.comprehensiveSuccessorAudit.installAuthorized -and
  [int]$auditRelease.buildCount -eq 1 -and
  [int]$auditRelease.installCount -eq 0 -and
  -not [bool]$mvp.execution.buildAuthorized -and
  -not [bool]$mvp.execution.deviceInstallAuthorized
)
$fix8RepairRetryPrebuildLifecycle = (
  [string]$fix8Ticket.status -ceq
    'r60_81_release_resource_repair_one_rebuild_and_in_place_sideload_authorized' -and
  [string]$ticketRelease.state -ceq
    'r60_81_release_resource_repair_one_rebuild_and_in_place_sideload_authorized' -and
  [int]$ticketRelease.maximumBuildCount -eq 2 -and
  [int]$ticketRelease.buildCount -eq 1 -and
  [int]$ticketRelease.installCount -eq 0 -and
  [bool]$fix8Ticket.authority.buildAuthorized -and
  [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  [string]$state.machineState -ceq
    'fix8_r60_81_release_resource_repair_one_rebuild_and_in_place_sideload_authorized' -and
  [bool]$state.authority.buildAuthorized -and
  [bool]$state.authority.oppoAuthorized -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$state.actionCounts.oppoUpdate -eq 0 -and
  [string]$state.comprehensiveSuccessorAudit.state -ceq
    'r60_81_release_resource_repair_one_rebuild_and_in_place_sideload_authorized' -and
  [bool]$state.comprehensiveSuccessorAudit.newCandidateRegistered -and
  [bool]$state.comprehensiveSuccessorAudit.buildAuthorized -and
  [bool]$state.comprehensiveSuccessorAudit.installAuthorized -and
  [int]$auditRelease.maximumBuildCount -eq 2 -and
  [int]$auditRelease.buildCount -eq 1 -and
  [int]$auditRelease.installCount -eq 0 -and
  [bool]$mvp.execution.buildAuthorized -and
  [bool]$mvp.execution.deviceInstallAuthorized
)
$fix8PostbuildLifecycle = (
  [string]$fix8Ticket.status -ceq
    'r60_81_artifact_qualified_one_in_place_sideload_authorized' -and
  [string]$ticketRelease.state -ceq
    'r60_81_artifact_qualified_install_pending' -and
  [int]$ticketRelease.buildCount -eq 1 -and
  [int]$ticketRelease.installCount -eq 0 -and
  -not [bool]$fix8Ticket.authority.buildAuthorized -and
  [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  [string]$state.machineState -ceq
    'fix8_r60_81_artifact_qualified_install_authorized' -and
  -not [bool]$state.authority.buildAuthorized -and
  [bool]$state.authority.oppoAuthorized -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$state.actionCounts.oppoUpdate -eq 0 -and
  [string]$state.comprehensiveSuccessorAudit.state -ceq
    'r60_81_artifact_qualified_one_in_place_sideload_authorized' -and
  [bool]$state.comprehensiveSuccessorAudit.newCandidateRegistered -and
  -not [bool]$state.comprehensiveSuccessorAudit.buildAuthorized -and
  [bool]$state.comprehensiveSuccessorAudit.installAuthorized -and
  [int]$auditRelease.buildCount -eq 1 -and
  [int]$auditRelease.installCount -eq 0 -and
  -not [bool]$mvp.execution.buildAuthorized -and
  [bool]$mvp.execution.deviceInstallAuthorized
)
$fix8RepairRetryPostbuildLifecycle = (
  [string]$fix8Ticket.status -ceq
    'r60_81_artifact_qualified_one_in_place_sideload_authorized' -and
  [string]$ticketRelease.state -ceq
    'r60_81_artifact_qualified_install_pending' -and
  [int]$ticketRelease.maximumBuildCount -eq 2 -and
  [int]$ticketRelease.buildCount -eq 2 -and
  [int]$ticketRelease.installCount -eq 0 -and
  -not [bool]$fix8Ticket.authority.buildAuthorized -and
  [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  [string]$state.machineState -ceq
    'fix8_r60_81_artifact_qualified_install_authorized' -and
  -not [bool]$state.authority.buildAuthorized -and
  [bool]$state.authority.oppoAuthorized -and
  [int]$state.actionCounts.build -eq 2 -and
  [int]$state.actionCounts.oppoUpdate -eq 0 -and
  [string]$state.comprehensiveSuccessorAudit.state -ceq
    'r60_81_artifact_qualified_one_in_place_sideload_authorized' -and
  [bool]$state.comprehensiveSuccessorAudit.newCandidateRegistered -and
  -not [bool]$state.comprehensiveSuccessorAudit.buildAuthorized -and
  [bool]$state.comprehensiveSuccessorAudit.installAuthorized -and
  [int]$auditRelease.maximumBuildCount -eq 2 -and
  [int]$auditRelease.buildCount -eq 2 -and
  [int]$auditRelease.installCount -eq 0 -and
  -not [bool]$mvp.execution.buildAuthorized -and
  [bool]$mvp.execution.deviceInstallAuthorized
)
$fix8PostinstallLifecycle = (
  [string]$fix8Ticket.status -ceq
    'r60_81_in_place_sideload_complete_device_acceptance_pending' -and
  [string]$ticketRelease.state -ceq
    'r60_81_in_place_sideload_complete_device_acceptance_pending' -and
  [int]$ticketRelease.buildCount -eq 1 -and
  [int]$ticketRelease.installCount -eq 1 -and
  -not [bool]$fix8Ticket.authority.buildAuthorized -and
  -not [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  [string]$state.machineState -ceq
    'fix8_r60_81_in_place_sideload_complete_device_acceptance_pending' -and
  -not [bool]$state.authority.buildAuthorized -and
  -not [bool]$state.authority.oppoAuthorized -and
  [int]$state.actionCounts.build -eq 1 -and
  [int]$state.actionCounts.oppoUpdate -eq 1 -and
  [string]$state.comprehensiveSuccessorAudit.state -ceq
    'r60_81_in_place_sideload_complete_device_acceptance_pending' -and
  [bool]$state.comprehensiveSuccessorAudit.newCandidateRegistered -and
  -not [bool]$state.comprehensiveSuccessorAudit.buildAuthorized -and
  -not [bool]$state.comprehensiveSuccessorAudit.installAuthorized -and
  [int]$auditRelease.buildCount -eq 1 -and
  [int]$auditRelease.installCount -eq 1 -and
  -not [bool]$mvp.execution.buildAuthorized -and
  -not [bool]$mvp.execution.deviceInstallAuthorized
)
$fix8RepairRetryPostinstallLifecycle = (
  [string]$fix8Ticket.status -ceq
    'r60_81_in_place_sideload_complete_device_acceptance_pending' -and
  [string]$ticketRelease.state -ceq
    'r60_81_in_place_sideload_complete_device_acceptance_pending' -and
  [int]$ticketRelease.maximumBuildCount -eq 2 -and
  [int]$ticketRelease.buildCount -eq 2 -and
  [int]$ticketRelease.installCount -eq 1 -and
  -not [bool]$fix8Ticket.authority.buildAuthorized -and
  -not [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  [string]$state.machineState -ceq
    'fix8_r60_81_in_place_sideload_complete_device_acceptance_pending' -and
  -not [bool]$state.authority.buildAuthorized -and
  -not [bool]$state.authority.oppoAuthorized -and
  [int]$state.actionCounts.build -eq 2 -and
  [int]$state.actionCounts.oppoUpdate -eq 1 -and
  [string]$state.comprehensiveSuccessorAudit.state -ceq
    'r60_81_in_place_sideload_complete_device_acceptance_pending' -and
  [bool]$state.comprehensiveSuccessorAudit.newCandidateRegistered -and
  -not [bool]$state.comprehensiveSuccessorAudit.buildAuthorized -and
  -not [bool]$state.comprehensiveSuccessorAudit.installAuthorized -and
  [int]$auditRelease.maximumBuildCount -eq 2 -and
  [int]$auditRelease.buildCount -eq 2 -and
  [int]$auditRelease.installCount -eq 1 -and
  -not [bool]$mvp.execution.buildAuthorized -and
  -not [bool]$mvp.execution.deviceInstallAuthorized
)
$fix8R6083RejectedLifecycle = (
  [string]$fix8Ticket.status -ceq
    'fix10_all_auth_local_implementation_and_pre_apk_contract_qualified_device_provider_and_live_email_reproof_pending_no_build' -and
  [string]$ticketRelease.state -ceq
    'r60_83_full_social_one_build_and_one_install_attempt_consumed_receipt_ambiguous_readback_pending' -and
  [int]$ticketRelease.maximumBuildCount -eq 1 -and
  [int]$ticketRelease.maximumInstallCount -eq 1 -and
  [int]$ticketRelease.buildCount -eq 1 -and
  [int]$ticketRelease.installCount -eq 1 -and
  -not [bool]$fix8Ticket.authority.buildAuthorized -and
  -not [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  -not [bool]$fix8Ticket.currentBuildQualification.rebuildAuthorized -and
  [int]$fix8Ticket.currentBuildQualification.buildCount -eq 1 -and
  [int]$fix8Ticket.currentBuildQualification.oppoInstallCount -eq 1 -and
  [bool]$fix8Ticket.localForensicRepairQualification.freshSourceSealRequiredBeforeAnyFutureArtifact -and
  -not [bool]$fix8Ticket.localForensicRepairQualification.successorBuildAuthorized -and
  -not [bool]$fix8Ticket.localForensicRepairQualification.deployProviderConsoleWriteOrDeviceMutationAuthorized -and
  [string]$apkState.machineState -ceq
    'r60_83_rejected_six_auth_tracks_local_default_email_hosting_domain_repair_qualified_fresh_seal_and_authorization_required_no_build' -and
  [string]$apkState.buildAuthorization -ceq
    'consumed_one_build_rebuild_forbidden' -and
  [string]$apkState.preBuildValidation.state -ceq
    'superseded_by_post_r60_83_local_auth_and_email_hosting_domain_repairs_fresh_seal_required' -and
  [string]$apkState.candidate.id -ceq $fix8TicketId -and
  [string]$apkState.candidate.versionName -ceq '1.0.0-r60.83' -and
  [string]$apkState.candidate.versionCode -ceq '2026082183' -and
  -not [bool]$state.authority.buildAuthorized -and
  -not [bool]$state.authority.oppoAuthorized -and
  [int]$state.actionCounts.build -eq 2 -and
  [int]$state.actionCounts.oppoUpdate -eq 1 -and
  -not [bool]$state.comprehensiveSuccessorAudit.buildAuthorized -and
  -not [bool]$state.comprehensiveSuccessorAudit.installAuthorized -and
  [int]$auditRelease.buildCount -eq 2 -and
  [int]$auditRelease.installCount -eq 1 -and
  -not [bool]$mvp.execution.buildAuthorized -and
  -not [bool]$mvp.execution.deviceInstallAuthorized
)
$fix8R6084PrebuildLifecycle = (
  [string]$fix8Ticket.status -ceq
    'fix10_all_auth_local_implementation_and_pre_apk_contract_qualified_r60_84_one_build_and_one_in_place_oppo_sideload_authorized_device_provider_reproof_pending' -and
  [string]$ticketRelease.state -ceq
    'r60_84_full_social_one_build_and_one_in_place_install_authorized_fresh_source_seal_bound' -and
  [string]$ticketRelease.versionName -ceq '1.0.0-r60.84' -and
  [string]$ticketRelease.versionCode -ceq '2026082184' -and
  [int]$ticketRelease.maximumBuildCount -eq 1 -and
  [int]$ticketRelease.maximumInstallCount -eq 1 -and
  [int]$ticketRelease.buildCount -eq 0 -and
  [int]$ticketRelease.installCount -eq 0 -and
  (Test-Path -LiteralPath $fix8R6084ManifestPath -PathType Leaf) -and
  (Get-FileHash -LiteralPath $fix8R6084ManifestPath -Algorithm SHA256).Hash `
    -ceq [string]$ticketRelease.sourceManifestSha256 -and
  [bool]$fix8Ticket.authority.buildAuthorized -and
  [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  -not [bool]$fix8Ticket.authority.sqlConnectProvisioningOrMigrationAuthorized -and
  -not [bool]$fix8Ticket.authority.privateProviderLoginAuthorized -and
  -not [bool]$fix8Ticket.authority.realEmailOrSmsAuthorized -and
  -not [bool]$fix8Ticket.authority.playOrProductionAuthorized -and
  [string]$apkState.machineState -ceq 'prebuild_passed' -and
  [string]$apkState.buildAuthorization -ceq 'approved_for_one_build' -and
  [string]$apkState.preBuildValidation.state -ceq 'passed' -and
  [string]$apkState.candidate.id -ceq $fix8TicketId -and
  [string]$apkState.candidate.versionName -ceq '1.0.0-r60.84' -and
  [string]$apkState.candidate.versionCode -ceq '2026082184' -and
  [string]$apkState.source.manifestPath -ceq
    [string]$ticketRelease.sourceManifestPath -and
  [string]$apkState.source.manifestSha256 -ceq
    [string]$ticketRelease.sourceManifestSha256 -and
  [bool]$mvp.execution.buildAuthorized -and
  [bool]$mvp.execution.deviceInstallAuthorized -and
  -not [bool]$mvp.execution.externalServiceWriteAuthorized -and
  -not [bool]$mvp.execution.liveEmailSendAuthorized
)
$fix8R6084PostbuildLifecycle = (
  [string]$fix8Ticket.status -ceq
    'fix10_all_auth_r60_84_built_postbuild_qualified_one_in_place_oppo_sideload_authorized_device_provider_reproof_pending' -and
  [string]$ticketRelease.state -ceq
    'r60_84_one_build_consumed_postbuild_qualified_one_in_place_install_authorized' -and
  [string]$ticketRelease.versionName -ceq '1.0.0-r60.84' -and
  [string]$ticketRelease.versionCode -ceq '2026082184' -and
  [int]$ticketRelease.maximumBuildCount -eq 1 -and
  [int]$ticketRelease.maximumInstallCount -eq 1 -and
  [int]$ticketRelease.buildCount -eq 1 -and
  [int]$ticketRelease.installCount -eq 0 -and
  (Test-Path -LiteralPath $fix8R6084ManifestPath -PathType Leaf) -and
  (Get-FileHash -LiteralPath $fix8R6084ManifestPath -Algorithm SHA256).Hash `
    -ceq [string]$ticketRelease.sourceManifestSha256 -and
  -not [bool]$fix8Ticket.authority.buildAuthorized -and
  [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  -not [bool]$fix8Ticket.authority.sqlConnectProvisioningOrMigrationAuthorized -and
  -not [bool]$fix8Ticket.authority.privateProviderLoginAuthorized -and
  -not [bool]$fix8Ticket.authority.realEmailOrSmsAuthorized -and
  -not [bool]$fix8Ticket.authority.playOrProductionAuthorized -and
  [string]$apkState.machineState -ceq
    'r60_84_build_complete_postbuild_qualified_one_in_place_install_authorized' -and
  [string]$apkState.buildAuthorization -ceq
    'consumed_one_build_rebuild_forbidden' -and
  [int]$apkState.buildResult.buildCount -eq 1 -and
  [bool]$apkState.buildResult.authorizationConsumed -and
  [string]$apkState.qualificationResult.state -ceq
    'passed_postbuild_qualified' -and
  -not [bool]$mvp.execution.buildAuthorized -and
  [bool]$mvp.execution.deviceInstallAuthorized -and
  -not [bool]$mvp.execution.externalServiceWriteAuthorized -and
  -not [bool]$mvp.execution.liveEmailSendAuthorized
)
$fix8R6084PostinstallLifecycle = (
  [string]$fix8Ticket.status -ceq
    'fix10_all_auth_r60_84_built_and_installed_founder_private_provider_acceptance_pending' -and
  [string]$ticketRelease.state -ceq
    'r60_84_one_build_and_one_install_consumed_founder_private_provider_acceptance_pending' -and
  [string]$ticketRelease.versionName -ceq '1.0.0-r60.84' -and
  [string]$ticketRelease.versionCode -ceq '2026082184' -and
  [int]$ticketRelease.maximumBuildCount -eq 1 -and
  [int]$ticketRelease.maximumInstallCount -eq 1 -and
  [int]$ticketRelease.buildCount -eq 1 -and
  [int]$ticketRelease.installCount -eq 1 -and
  -not [bool]$fix8Ticket.authority.buildAuthorized -and
  -not [bool]$fix8Ticket.authority.installOrOppoMutationAuthorized -and
  -not [bool]$fix8Ticket.authority.sqlConnectProvisioningOrMigrationAuthorized -and
  -not [bool]$fix8Ticket.authority.privateProviderLoginAuthorized -and
  -not [bool]$fix8Ticket.authority.realEmailOrSmsAuthorized -and
  -not [bool]$fix8Ticket.authority.playOrProductionAuthorized -and
  [string]$apkState.machineState -ceq
    'r60_84_in_place_install_complete_founder_private_provider_acceptance_pending' -and
  [string]$apkState.buildAuthorization -ceq
    'consumed_one_build_rebuild_forbidden' -and
  [int]$apkState.installResult.installCount -eq 1 -and
  [bool]$apkState.installResult.installAuthorizationConsumed -and
  -not [bool]$mvp.execution.buildAuthorized -and
  -not [bool]$mvp.execution.deviceInstallAuthorized -and
  -not [bool]$mvp.execution.externalServiceWriteAuthorized -and
  -not [bool]$mvp.execution.liveEmailSendAuthorized
)
$fix8R6084Lifecycle = (
  $fix8R6084PrebuildLifecycle -or
  $fix8R6084PostbuildLifecycle -or
  $fix8R6084PostinstallLifecycle
)
$fix8ReleaseLifecycle = (
  $fix8PrebuildLifecycle -or
  $fix8FailedBuildLifecycle -or
  $fix8RepairQualifiedLifecycle -or
  $fix8RepairRetryPrebuildLifecycle -or
  $fix8PostbuildLifecycle -or
  $fix8RepairRetryPostbuildLifecycle -or
  $fix8PostinstallLifecycle -or
  $fix8RepairRetryPostinstallLifecycle -or
  $fix8R6083RejectedLifecycle -or
  $fix8R6084Lifecycle
)
$main = Read-C34PFix5Text 'apps/mobile/lib/main.dart' 'mobile main'
$releaseRuntime = Read-C34PFix5Text `
  'apps/mobile/lib/core/config/release_runtime_configuration.dart' `
  'release runtime configuration'
$devAppCheck = Read-C34PFix5Text `
  'apps/mobile/lib/core/youtube/youtube_private_dev_app_check.dart' `
  'Dev App Check activation'
$journeyRuntime = Read-C34PFix5Text `
  'apps/mobile/lib/features/journey01/review_journey_services.dart' `
  'journey runtime services'
$xContract = Read-C34PFix5Text `
  'apps/mobile/lib/core/auth/x_oauth2_pkce.dart' 'X contract'
$xMobile = Read-C34PFix5Text `
  'apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart' `
  'X mobile adapter'
$instagramMobile = Read-C34PFix5Text `
  'apps/mobile/lib/core/auth/instagram_oauth_network_adapter.dart' `
  'Instagram mobile adapter'
$facebook = Read-C34PFix5Text `
  'apps/mobile/lib/core/auth/facebook_native_sdk_adapter.dart' `
  'Facebook native adapter'
$backend = Read-C34PFix5Text 'backend/functions/src/index.ts' 'backend export'
$xBackend = Read-C34PFix5Text `
  'backend/functions/src/auth/x_pkce_broker.ts' 'X backend broker'
$instagramBackend = Read-C34PFix5Text `
  'backend/functions/src/auth/instagram_oauth_broker.ts' `
  'Instagram backend broker'
$instagramMetaCallbacks = Read-C34PFix5Text `
  'backend/functions/src/auth/instagram_meta_callbacks.ts' `
  'Instagram Meta callbacks'
$facebookMetaCallbacks = Read-C34PFix5Text `
  'backend/functions/src/auth/facebook_meta_callbacks.ts' `
  'Facebook Meta callbacks'
$runbook = Read-C34PFix5Text `
  'docs/quality/UAW-C34P-FIX5-FOUNDER-LIVE-PROVIDER-CONFIGURATION-RUNBOOK-20260820.md' `
  'founder provider runbook'
$emailLinkFallback = Read-C34PFix5Text `
  'apps/web/public/app/index.html' `
  'Email Link app fallback'

Assert-C34PFix5 (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.state -ceq
    'registered_founder_authorized_configuration_and_readback_pending_scope_selection' -and
  [string]$ticket.classification -ceq 'beyond_mvp' -and
  [bool]$ticket.authority.providerConsoleConfigurationAndReadbackAuthorizedAfterMvpGate -and
  [bool]$ticket.authority.devPublicAuthBrokerDeploymentAuthorizedAfterMvpGate -and
  [bool]$ticket.authority.founderOnlyRuntimeSecretEntryAuthorized -and
  -not [bool]$ticket.authority.agentSecretPrivateIdentifierOrKeyHashAccessAuthorized -and
  -not [bool]$ticket.authority.realEmailSmsOrPrivateLoginAuthorized -and
  -not [bool]$ticket.authority.buildPlayOrDeviceActionAuthorized
) 'ticket identity or authority changed.'

Assert-C34PFix5 (
  [string]$fix8Ticket.ticketId -ceq $fix8TicketId -and
  [string]$fix8Ticket.parentTicketId -ceq $ticketId -and
  [string]$fix8Ticket.classification -ceq 'mvp_required' -and
  [bool]$fix8Ticket.authority.sourceAndTestRepairAuthorizedAfterMvpGate -and
  -not [bool]$fix8Ticket.authority.sqlConnectProvisioningOrMigrationAuthorized -and
  $fix8ReleaseLifecycle -and
  -not [bool]$fix8Ticket.authority.privateProviderLoginAuthorized
) 'FIX8 successor ticket identity or release lifecycle changed.'

$selectedTicketId = [string]$mvp.ticket.id
$selectedAssessment = $mvp.preTicketSelectionCheckpoint.selectedTicketAssessment
$commonSelectionHeld = (
  [string]$mvp.state -ceq 'ticket_disclosed_and_authorized' -and
  [string]$mvp.preTicketSelectionCheckpoint.currentTicketId -ceq $selectedTicketId -and
  [string]$selectedAssessment.ticketId -ceq $selectedTicketId -and
  -not [bool]$mvp.execution.liveEmailSendAuthorized -and
  -not [bool]$mvp.execution.secretValueAccessAuthorized
)
$fix5Selection = (
  $selectedTicketId -ceq $ticketId -and
  [bool]$mvp.authorization.beyondMvpExplicitlyAuthorized -and
  [bool]$mvp.execution.externalServiceWriteAuthorized -and
  [bool]$mvp.execution.otherProviderWriteAuthorized
)
$fix8Selection = (
  $selectedTicketId -ceq $fix8TicketId -and
  [string]$mvp.authorization.state -ceq 'founder_acknowledged_mvp_scope' -and
  -not [bool]$mvp.authorization.beyondMvpExplicitlyAuthorized -and
  [bool]$mvp.execution.runtimeWriteAuthorized -and
  [bool]$mvp.execution.testOrGateWriteAuthorized -and
  [bool]$mvp.execution.backendWriteAuthorized -and
  $fix8ReleaseLifecycle -and
  -not [bool]$mvp.execution.externalServiceWriteAuthorized -and
  -not [bool]$mvp.execution.otherProviderWriteAuthorized -and
  [string]$selectedAssessment.manifestPath -ceq $fix8TicketRelative -and
  [string]$selectedAssessment.manifestSha256 -ceq $fix8TicketHash
)

Assert-C34PFix5 (
  $commonSelectionHeld -and ($fix5Selection -or $fix8Selection)
) 'MVP selection or held release boundary changed.'

Assert-C34PFix5 (
  [string]$state.ticketId -ceq $ticketId -and
  [string]$state.repositoryIdentity.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.repositoryIdentity.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  [bool]$state.sourceQualification.allEightSourceQualified -and
  [bool]$state.sourceQualification.wholeMobileAnalyzerPassed -and
  [bool]$state.sourceQualification.backendTypecheckPassed -and
  [bool]$state.providers.instagram.deauthorizationCallbackSourceQualified -and
  [bool]$state.providers.instagram.dataDeletionCallbackSourceQualified -and
  [bool]$state.providers.facebook.deauthorizationCallbackSourceQualified -and
  [bool]$state.providers.facebook.dataDeletionCallbackSourceQualified -and
  [bool]$state.publicAuthBroker.xAttemptTtlSourceQualified -and
  [bool]$state.publicAuthBroker.instagramAttemptTtlSourceQualified -and
  [bool]$state.publicAuthBroker.dedicatedRuntimeServiceAccountQualified -and
  [bool]$state.publicAuthBroker.firebaseAuthAdminIamQualified -and
  [bool]$state.publicAuthBroker.firestoreIamQualified -and
  [bool]$state.publicAuthBroker.loggingIamQualified -and
  [bool]$state.publicAuthBroker.selfTokenCreatorIamQualified -and
  [bool]$state.publicAuthBroker.secretContainersQualified -and
  [bool]$state.publicAuthBroker.allRequiredSecretVersionsQualified -and
  [int]$state.sourceQualification.affectedSuiteCount -eq 16 -and
  [int]$state.sourceQualification.affectedPassCountPerCycle -eq 158 -and
  [int]$state.sourceQualification.affectedCycleCount -eq 2
) 'source qualification or repository identity changed.'

foreach ($binding in @(
  @($main, 'FirebaseAppCheck.instance.getLimitedUseToken()', 'mobile main'),
  @($main, "'MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT'", 'global social login audit define'),
  @($main, 'resolveGlobalSocialLoginAuditComposition(', 'global social login composition'),
  @($main, 'FirebaseAuthenticatedSessionBootstrapGateway(', 'Firebase session bootstrap composition'),
  @($releaseRuntime, 'globalSocialLoginAudit && !publicAuthSideloadQualified', 'global login runtime fail closed'),
  @($devAppCheck, 'youtubePrivateDevProofEnabled || globalSocialLoginAuditEnabled', 'global login App Check activation'),
  @($journeyRuntime, 'class FirebaseAuthenticatedSessionBootstrapGateway', 'Firebase session bootstrap owner'),
  @($backend, 'verifyToken(token, { consume: true })', 'backend App Check'),
  @($backend, 'moolSocialPublicAuth', 'backend export'),
  @($xMobile, "scope == 'tweet.read users.read'", 'X mobile scope'),
  @($xBackend, 'const X_SCOPES = ["tweet.read", "users.read"] as const;', 'X backend scope'),
  @($xBackend, 'expiresAt: new Date(attempt.expiresAtMs)', 'X TTL timestamp'),
  @($instagramMobile, "scope == 'instagram_business_basic'", 'Instagram mobile scope'),
  @($instagramBackend, 'const INSTAGRAM_SCOPE = "instagram_business_basic";', 'Instagram backend scope'),
  @($instagramBackend, 'expiresAt: new Date(attempt.expiresAtMs)', 'Instagram TTL timestamp'),
  @($instagramMetaCallbacks, 'timingSafeEqual(receivedSignature, expectedSignature)', 'Instagram callback signature'),
  @($instagramMetaCallbacks, '"/instagram/deauthorize"', 'Instagram deauthorization callback'),
  @($instagramMetaCallbacks, '"/instagram/data-deletion"', 'Instagram data-deletion callback'),
  @($facebookMetaCallbacks, 'timingSafeEqual(signature, expected)', 'Facebook callback signature'),
  @($facebookMetaCallbacks, '"/facebook/deauthorize"', 'Facebook deauthorization callback'),
  @($facebookMetaCallbacks, '"/facebook/data-deletion"', 'Facebook data-deletion callback'),
  @($facebook, "static const List<String> permissions = <String>['public_profile'];", 'Facebook permission'),
  @($emailLinkFallback, 'Continue in MoolSocial', 'Email Link fallback')
)) {
  Assert-C34PFix5Contains ([string]$binding[0]) ([string]$binding[1]) `
    ([string]$binding[2])
}
Assert-C34PFix5 (-not $xContract.Contains('offline.access')) `
  'X contract contains forbidden offline access.'
Assert-C34PFix5 (-not $facebook.Contains("'email'")) `
  'Facebook native adapter contains the forbidden email permission.'

foreach ($token in @(
  'Google and YouTube identity', 'Apple through Firebase',
  'X OAuth 2.0 plus PKCE', 'Instagram professional login',
  'Facebook native login', 'Firebase passwordless Email Link',
  'Firebase Mobile OTP', 'Firebase App Check Token Verifier IAM role',
  'Firestore TTL'
)) {
  Assert-C34PFix5Contains $runbook $token 'founder provider runbook'
}

$counts = $state.actionCounts
$privacy = $state.privacyBoundary
Assert-C34PFix5 (
  -not [bool]$privacy.secretValuesObserved -and
  -not [bool]$privacy.providerIdentifiersObserved -and
  -not [bool]$privacy.keyHashValuesObserved -and
  -not [bool]$privacy.privateAccountIdentifiersObserved -and
  -not [bool]$privacy.privateEmailPhoneLinkOrOtpObserved -and
  -not [bool]$privacy.tokenOrCredentialObserved -and
  -not [bool]$state.authority.agentSecretPrivateIdentifierOrKeyHashAccessAuthorized -and
  $fix8ReleaseLifecycle -and
  -not [bool]$state.authority.playAuthorized -and
  -not [bool]$state.authority.realEmailSendAuthorized -and
  -not [bool]$state.authority.realSmsSendAuthorized -and
  -not [bool]$state.authority.fundsAuthorized -and
  -not [bool]$state.authority.productionPromotionAuthorized
) 'privacy or held release authority changed.'

$audit = $state.comprehensiveSuccessorAudit
$fix8R6083ExpectedFindingIds = @(
  'REG-20260822-3137-PUBLIC-AUTH-SIDELOAD-REVIEW-GATEWAY',
  'REG-20260822-3138-PUBLIC-AUTH-SIDELOAD-APP-CHECK-NOT-ACTIVATED',
  'REG-20260822-3139-DEVICE-REVIEW-UNQUALIFIED-AUTH-METHODS',
  'REG-20260822-3140-POST-LOGIN-FAKE-OR-HELD-SQL-CONNECT-BOOTSTRAP',
  'REG-20260822-3228-R60-81-OPPO-GOOGLE-SIGN-IN-NOT-COMPLETED',
  'REG-20260822-3229-R60-81-OPPO-YOUTUBE-SHARED-GOOGLE-SIGN-IN-NOT-COMPLETED',
  'REG-20260822-3230-R60-81-OPPO-FACEBOOK-SIGN-IN-NOT-COMPLETED',
  'REG-20260822-3231-R60-81-OPPO-INSTAGRAM-SIGN-IN-NOT-COMPLETED',
  'REG-20260822-3232-R60-81-OPPO-X-SIGN-IN-NOT-COMPLETED',
  'REG-20260822-3237-SCREEN03-BROKER-AUTHORIZATION-PENDING-SHOWN-AS-FAILURE',
  'REG-20260822-3243-PUBLIC-AUTH-SIDELOAD-READINESS-FACTS-HARDCODED-WITHOUT-SIGNER-PROVIDER-PROOF',
  'REG-20260822-3244-R60-81-SCREEN03-UNAVAILABLE-APPLE-EXPORTED-CLICKABLE',
  'REG-20260822-3245-R60-81-SCREEN03-UNATTESTED-MOBILE-OTP-EXPORTED-CLICKABLE',
  'REG-20260822-3246-R60-81-SCREEN03-TERMS-AND-PRIVACY-NOT-ACTIONABLE'
)
$fix8R6083FindingSetExact = (
  @($audit.registeredFindingIds).Count -eq
    $fix8R6083ExpectedFindingIds.Count -and
  (@($audit.registeredFindingIds) -join '|') -ceq
    ($fix8R6083ExpectedFindingIds -join '|')
)
Assert-C34PFix5 (
  $fix8ReleaseLifecycle -and
  [string]$audit.selectedRepairTicketId -ceq
    'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR' -and
  (
    (($fix8R6083RejectedLifecycle -or $fix8R6084Lifecycle) -and
      $fix8R6083FindingSetExact) -or
    (-not ($fix8R6083RejectedLifecycle -or $fix8R6084Lifecycle) -and
      @($audit.registeredFindingIds).Count -eq 4)
  ) -and
  @($audit.founderSequence).Count -eq 9 -and
  @($audit.preservedRejectedOrSupersededCandidates).Count -eq 4 -and
  @($audit.auditBoundaries).Count -eq 10 -and
  [string]$audit.sourceQualificationEvidence -ceq
    'docs/quality/UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-SOURCE-QUALIFICATION-20260822.md' -and
  [string]$audit.sourceAggregateSha256 -ceq
    'DC284B6DDF6E792A0A72859BFDE99C3406D78CC5E158B3920872568F3F66C1B4' -and
  [int]$audit.sourceCycleCount -eq 2 -and
  [int]$audit.mobilePassCountPerCycle -eq 255 -and
  [int]$audit.backendPassCountPerCycle -eq 586 -and
  [bool]$audit.stoppedAuditAgentsRemainStopped -and
  -not [bool]$audit.privateProviderLoginAuthorized -and
  -not [bool]$audit.realEmailOrSmsAuthorized -and
  -not [bool]$audit.playActionAuthorized -and
  [bool]$audit.oppoConnectedReadOnlyAvailabilityReported -and
  -not [bool]$audit.sqlConnectProvisioningOrMigrationAuthorized
) 'comprehensive successor audit sequence or held boundaries changed.'

if (-not $RequireQualified) {
  Assert-C34PFix5 (
    $fix8ReleaseLifecycle -and
    [int]$counts.providerConsoleWrite -ge 0 -and
    [int]$counts.devBrokerDeployment -ge 0 -and
    [int]$counts.devBrokerDeployment -le 1 -and
    [int]$counts.realAuthentication -eq 0 -and
    [int]$counts.realEmailSend -eq 0 -and
    [int]$counts.realSmsSend -eq 0 -and
    [int]$counts.playUpload -eq 0 -and
    [int]$counts.deviceAcceptance -eq 0 -and
    [int]$counts.productionPromotion -eq 0 -and
    [int]$counts.funds -eq 0
  ) 'pending provider state or zero action counts changed.'
  Write-Output (
    'C34P FIX5 successor lifecycle gate passed: methods=8; source=true; ' +
    "machineState=$($state.machineState); build=$($counts.build); " +
    "oppo=$($counts.oppoUpdate); Play=0; privateValues=false."
  )
  return
}

$requiredFacts = @(
  $state.providers.googleYoutube.firebaseGoogleProviderEnabled,
  $state.providers.googleYoutube.androidPackageQualified,
  $state.providers.googleYoutube.firebaseAndroidAppRegistered,
  $state.providers.googleYoutube.androidLaunchActivityQualified,
  $state.providers.googleYoutube.playSigningFingerprintsQualified,
  $state.providers.googleYoutube.serverClientRuntimeQualified,
  $state.providers.googleYoutube.exactReturnQualified,
  $state.providers.apple.firebaseAppleProviderEnabled,
  $state.providers.apple.appleAppOrServicesConfigurationQualified,
  $state.providers.apple.exactReturnQualified,
  $state.providers.apple.platformCapabilityQualified,
  $state.providers.apple.revocationQualified,
  $state.providers.x.oauth2PublicClientQualified,
  $state.providers.x.exactRedirectQualified,
  $state.providers.x.minimumScopesQualified,
  $state.providers.x.pkceS256Qualified,
  $state.providers.x.providerProjectLiveQualified,
  $state.providers.x.runtimeParametersQualifiedByFounder,
  $state.providers.x.runtimeSecretsQualifiedByFounder,
  $state.providers.x.revocationQualified,
  $state.providers.instagram.professionalLoginProductQualified,
  $state.providers.instagram.eligibleProfessionalAccountOnly,
  $state.providers.instagram.exactRedirectQualified,
  $state.providers.instagram.minimumScopeQualified,
  $state.providers.instagram.minimumPermissionProviderQualified,
  $state.providers.instagram.deauthorizationCallbackProviderQualified,
  $state.providers.instagram.dataDeletionCallbackProviderQualified,
  $state.providers.instagram.appReviewOrLiveModeQualified,
  $state.providers.instagram.runtimeParametersQualifiedByFounder,
  $state.providers.instagram.runtimeSecretsQualifiedByFounder,
  $state.providers.instagram.revocationQualified,
  $state.providers.facebook.nativeLoginProductQualified,
  $state.providers.facebook.firebaseFacebookProviderEnabled,
  $state.providers.facebook.publicProfileOnly,
  $state.providers.facebook.publicProfileProviderQualified,
  $state.providers.facebook.androidPackageQualified,
  $state.providers.facebook.androidLaunchActivityQualified,
  $state.providers.facebook.developmentKeyHashStoredByFounder,
  $state.providers.facebook.androidNotificationSsoDisabledQualified,
  $state.providers.facebook.nativeClientOAuthSettingsQualified,
  $state.providers.facebook.webEmbeddedDeviceAndJavascriptOAuthDisabledQualified,
  $state.providers.facebook.debugAndReleaseKeyHashesQualifiedByFounder,
  $state.providers.facebook.exactRedirectQualified,
  $state.providers.facebook.privacyPolicyQualified,
  $state.providers.facebook.dataDeletionQualified,
  $state.providers.facebook.deauthorizationCallbackProviderQualified,
  $state.providers.facebook.dataDeletionCallbackProviderQualified,
  $state.providers.facebook.automaticPurchaseAndSubscriptionLoggingDisabledQualified,
  $state.providers.facebook.versionedGraphRevocationEndpointQualified,
  $state.providers.facebook.buildValuesQualifiedByFounder,
  $state.providers.passwordlessEmailLink.firebaseEmailLinkProviderEnabled,
  $state.providers.passwordlessEmailLink.authorizedDomainQualified,
  $state.providers.passwordlessEmailLink.appContinuationFallbackSourceQualified,
  $state.providers.passwordlessEmailLink.appContinuationFallbackLiveQualified,
  $state.providers.passwordlessEmailLink.continueUrlQualified,
  $state.providers.mobileOtp.firebasePhoneProviderEnabled,
  $state.providers.mobileOtp.allowedRegionQualified,
  $state.providers.mobileOtp.firebaseAndroidAppRegistered,
  $state.providers.mobileOtp.firebaseCertificateRegistrationsPresent,
  $state.providers.mobileOtp.indiaOnlySmsAllowlistQualified,
  $state.providers.mobileOtp.playIntegrityOrRecaptchaQualified,
  $state.publicAuthBroker.exportQualified,
  $state.publicAuthBroker.devDeploymentAuthorized,
  $state.publicAuthBroker.devDeploymentCompleted,
  $state.publicAuthBroker.publicInvokerQualified,
  $state.publicAuthBroker.applicationRejectionStatusQualified,
  $state.publicAuthBroker.exactEndpointQualified,
  $state.publicAuthBroker.runtimeParametersQualifiedByFounder,
  $state.publicAuthBroker.runtimeSecretsQualifiedByFounder,
  $state.publicAuthBroker.appCheckLimitedUseClientQualified,
  $state.publicAuthBroker.appCheckConsumeBackendQualified,
  $state.publicAuthBroker.appCheckTokenVerifierIamQualified,
  $state.publicAuthBroker.xAttemptTtlQualified,
  $state.publicAuthBroker.instagramAttemptTtlQualified,
  $state.releaseInputContract.requiredDartDefineNamesQualified,
  $state.releaseInputContract.facebookAndroidBuildValuesQualified,
  $state.releaseInputContract.googleServicesConfigurationQualified,
  $state.releaseInputContract.uploadSigningQualified
)
Assert-C34PFix5 (
  [string]$state.machineState -ceq
    'live_provider_readback_qualified_release_candidate_selection_authorized' -and
  @($requiredFacts | Where-Object { -not [bool]$_ }).Count -eq 0 -and
  [int]$counts.providerConsoleWrite -ge 1 -and
  [int]$counts.devBrokerDeployment -eq 1 -and
  [int]$counts.realAuthentication -eq 0 -and
  [int]$counts.realEmailSend -eq 0 -and
  [int]$counts.realSmsSend -eq 0 -and
  [int]$counts.build -eq 0 -and
  [int]$counts.playUpload -eq 0 -and
  [int]$counts.oppoUpdate -eq 0 -and
  [int]$counts.deviceAcceptance -eq 0 -and
  [int]$counts.productionPromotion -eq 0 -and
  [int]$counts.funds -eq 0 -and
  -not [bool]$state.publicAuthBroker.stagingDeploymentCompleted -and
  -not [bool]$state.publicAuthBroker.productionDeploymentAuthorized -and
  -not [bool]$state.publicAuthBroker.productionDeploymentCompleted -and
  -not [bool]$state.releaseInputContract.agentReadAnyValue -and
  -not [bool]$state.releaseInputContract.agentReadAnyPrivateIdentifier
) 'qualified provider facts, counts or held promotion boundary are incomplete.'

Write-Output (
  'C34P FIX5 live-provider readiness gate passed qualified: methods=8; ' +
  'DevBroker=1; buildPlayOppo=0; privateValues=false.'
)
