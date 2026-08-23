[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C29L([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C29L source gate rejected: $Message" }
}

function Resolve-C29LFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C29L ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C29L (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Assert-C29LContains([string]$RelativePath, [string]$Text) {
  $content = Get-Content -Raw -LiteralPath (Resolve-C29LFile $RelativePath)
  Assert-C29L ($content.Contains($Text, [StringComparison]::Ordinal)) "required contract missing from $RelativePath`: $Text"
}

function Assert-C29LNotContains([string]$RelativePath, [string]$Text) {
  $content = Get-Content -Raw -LiteralPath (Resolve-C29LFile $RelativePath)
  Assert-C29L (-not $content.Contains($Text, [StringComparison]::Ordinal)) "forbidden local/fabricated authority remains in $RelativePath`: $Text"
}

$expectedTicket = 'UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-CREATOR-CONNECTION-PRIVATE-SHORT-UPLOAD-C29L'
$ticketPath = Resolve-C29LFile 'config/uaw-personal-mvp-social-youtube-creator-connection-private-short-upload-c29l-ticket.json'
$scopePath = Resolve-C29LFile 'config/mvp-scope-gate-state.json'
$apkPath = Resolve-C29LFile 'config/apk-regression-gate-state-c29k.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash

Assert-C29L ([string]$ticket.ticketId -ceq $expectedTicket) 'ticket identity changed'
Assert-C29L ([string]$ticket.state -cin @('selected_execution_authorized_source_only', 'source_qualified_provider_gate_pending')) 'ticket state is not a source-only C29L state'
Assert-C29L ([string]$ticket.classification -ceq 'mvp_required') 'MVP classification changed'
Assert-C29L ([string]$scope.ticket.id -ceq $expectedTicket) 'active scope ticket differs'
Assert-C29L ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
Assert-C29L ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha) 'ticket manifest seal changed'
Assert-C29L ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime source authority is closed'
Assert-C29L ([bool]$scope.execution.testOrGateWriteAuthorized) 'test/evidence authority is closed'

foreach ($closed in @(
  [bool]$scope.execution.backendWriteAuthorized,
  [bool]$scope.execution.buildAuthorized,
  [bool]$scope.execution.deviceInstallAuthorized,
  [bool]$scope.execution.externalServiceWriteAuthorized,
  [bool]$scope.execution.secretValueAccessAuthorized,
  [bool]$ticket.execution.buildAuthorized,
  [bool]$ticket.execution.installAuthorized,
  [bool]$ticket.execution.deployAuthorized,
  [bool]$ticket.execution.productionWriteAuthorized,
  [bool]$ticket.execution.providerMessageAuthorized,
  [bool]$ticket.execution.secretValueAccessAuthorized,
  [bool]$ticket.execution.referenceWriteAuthorized
)) {
  Assert-C29L (-not $closed) 'backend/build/install/deploy/external/secret/reference authority opened early'
}

Assert-C29L ([string]$apk.machineState -ceq 'device_qualified_founder_review_pending') 'protected C29K machine state changed'
Assert-C29L ([string]$apk.buildAuthorization -ceq 'consumed') 'protected C29K build authorization changed'
Assert-C29L ([string]$apk.installResult.deviceSerial -ceq '2b3e0f71') 'protected OPPO serial changed'
Assert-C29L ([string]$apk.installResult.versionName -ceq '1.0.0-r60.34') 'protected installed version name changed'
Assert-C29L ([string]$apk.installResult.versionCode -ceq '2026081134') 'protected installed version code changed'
Assert-C29L ([string]$apk.installResult.installedApkSha256 -ceq '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29') 'protected installed APK checksum changed'
Assert-C29L (-not [bool]$apk.installResult.uninstallPerformed) 'protected app was uninstalled'
Assert-C29L (-not [bool]$apk.installResult.dataClearPerformed) 'protected app data was cleared'
Assert-C29L (-not [bool]$apk.installResult.downgradePerformed) 'protected app was downgraded'
Assert-C29L ([bool]$apk.deviceQualificationResult.founderAcceptancePending) 'C29K founder-review gate changed'
Assert-C29L (-not [bool]$apk.deviceQualificationResult.protectedBaselineUpdated) 'protected baseline was advanced'

$creator = 'apps/mobile/lib/ui_v2/social/social_v2_youtube_creator_upload.dart'
$consumer = 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart'
$router = 'apps/mobile/lib/features/journey01/journey_router.dart'
$workflow = 'apps/mobile/lib/core/youtube/youtube_private_dev_workflow.dart'
$uploader = 'apps/mobile/lib/core/youtube/youtube_private_dev_uploader.dart'
$backendIndex = 'backend/functions/src/index.ts'
$backendConfig = 'backend/functions/src/youtube/config.ts'

Assert-C29LContains $creator 'abstract interface class SocialYouTubeCreatorGateway'
Assert-C29LContains $creator 'SocialYouTubeCreatorUploadScreen'
Assert-C29LContains $creator '_capabilities?.privateUpload == true'
Assert-C29LContains $creator 'if (capabilities.privateUpload)'
Assert-C29LContains $creator 'SocialYouTubeShortMediaInspector'
Assert-C29LContains $creator 'Upload privately to YouTube'
Assert-C29LContains $creator 'YouTubeUploadCancellation'
Assert-C29LContains $consumer 'SocialCreatorGatewayV2'
Assert-C29LContains $consumer 'youtubeCreatorAccessOverride'
Assert-C29LContains $router 'SocialYouTubeCreatorUploadScreen('
Assert-C29LContains $workflow 'without proxying media through'
Assert-C29LContains $uploader "session.privacyStatus != 'private'"
Assert-C29LContains $uploader 'class YouTubeUploadCancellation'
Assert-C29LContains $backendConfig 'requireOwnerConnectionStatusCapability'
Assert-C29LContains $backendConfig 'capabilities.ownerConnect || capabilities.privateUpload'
Assert-C29LContains $backendIndex 'requireOwnerConnectionStatusCapability(readCapabilities())'
Assert-C29LNotContains $creator 'setYouTubeChannelConnected'
Assert-C29LNotContains $consumer 'setYouTubeChannelConnected'
Assert-C29LNotContains $router 'setYouTubeChannelConnected'
Assert-C29LNotContains $creator 'capabilities.ownerConnect && capabilities.privateUpload'
Assert-C29LNotContains $consumer 'capabilities.ownerConnect && capabilities.privateUpload'

$requiredTests = @(
  'apps/mobile/test/social_v2_youtube_creator_upload_test.dart',
  'apps/mobile/test/youtube_private_dev_client_test.dart',
  'apps/mobile/test/social_v2_create_publication_test.dart',
  'apps/mobile/test/screen04_universal_v2_conformance_test.dart',
  'apps/mobile/test/ui_v2_social_customer_copy_gate_test.dart',
  'apps/mobile/test/ui_v2_social_named_state_parity_test.dart',
  'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_youtube_native_home_dock_c29e_test.dart',
  'apps/mobile/test/social_v2_youtube_connect_return_test.dart'
)
foreach ($relative in $requiredTests) { [void](Resolve-C29LFile $relative) }

Write-Output 'C29L source gate passed: exact-channel provider authority; capability fail-closed; direct private YouTube upload; cancellation/retry/processing owners; explicit MoolSocial/YouTube host choice; protected r60.34 preserved; build/install/deploy/external/secret authority closed.'
