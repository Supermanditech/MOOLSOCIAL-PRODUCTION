[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C29N([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C29N source gate rejected: $Message" }
}

function Resolve-C29NFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C29N ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C29N (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Get-C29NContent([string]$RelativePath) {
  return Get-Content -Raw -LiteralPath (Resolve-C29NFile $RelativePath)
}

function Assert-C29NContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29NContent $RelativePath
  Assert-C29N ($content.Contains($Text, [StringComparison]::Ordinal)) "required contract missing from $RelativePath`: $Text"
}

function Assert-C29NNotContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29NContent $RelativePath
  Assert-C29N (-not $content.Contains($Text, [StringComparison]::Ordinal)) "rejected contract remains in $RelativePath`: $Text"
}

$expectedTicket = 'UAW-PERSONAL-MVP-SOCIAL-CREATOR-ERGONOMICS-AND-GLOBAL-EDGE-CONSISTENCY-C29N'
$ticketPath = Resolve-C29NFile 'config/uaw-personal-mvp-social-creator-ergonomics-global-edge-consistency-c29n-ticket.json'
$scopePath = Resolve-C29NFile 'config/mvp-scope-gate-state.json'
$apkPath = Resolve-C29NFile 'config/apk-regression-gate-state-c29k.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash

Assert-C29N ([string]$ticket.ticketId -ceq $expectedTicket) 'ticket identity changed'
Assert-C29N ([string]$ticket.state -cin @('selected_execution_authorized_source_only', 'source_qualified_provider_gate_pending')) 'ticket state is not source-only'
Assert-C29N ([string]$ticket.classification -ceq 'mvp_required') 'MVP classification changed'
Assert-C29N ([string]$scope.ticket.id -ceq $expectedTicket) 'active scope ticket differs'
Assert-C29N ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
Assert-C29N ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha) 'ticket manifest seal changed'
Assert-C29N ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime source authority is closed'
Assert-C29N ([bool]$scope.execution.testOrGateWriteAuthorized) 'test/evidence authority is closed'

foreach ($closed in @(
  [bool]$scope.execution.backendWriteAuthorized,
  [bool]$scope.execution.buildAuthorized,
  [bool]$scope.execution.deviceInstallAuthorized,
  [bool]$scope.execution.externalServiceWriteAuthorized,
  [bool]$scope.execution.secretValueAccessAuthorized,
  [bool]$ticket.execution.backendSourceWriteAuthorized,
  [bool]$ticket.execution.externalDevQualificationAuthorized,
  [bool]$ticket.execution.buildAuthorized,
  [bool]$ticket.execution.installAuthorized,
  [bool]$ticket.execution.deployAuthorized,
  [bool]$ticket.execution.productionWriteAuthorized,
  [bool]$ticket.execution.providerMessageAuthorized,
  [bool]$ticket.execution.secretValueAccessAuthorized,
  [bool]$ticket.execution.referenceWriteAuthorized
)) {
  Assert-C29N (-not $closed) 'backend/build/install/deploy/external/secret/reference authority opened'
}

Assert-C29N ([string]$apk.machineState -ceq 'device_qualified_founder_review_pending') 'protected C29K machine state changed'
Assert-C29N ([string]$apk.buildAuthorization -ceq 'consumed') 'protected C29K build authorization changed'
Assert-C29N ([string]$apk.installResult.deviceSerial -ceq '2b3e0f71') 'protected OPPO serial changed'
Assert-C29N ([string]$apk.installResult.versionName -ceq '1.0.0-r60.34') 'protected installed version name changed'
Assert-C29N ([string]$apk.installResult.versionCode -ceq '2026081134') 'protected installed version code changed'
Assert-C29N ([string]$apk.installResult.installedApkSha256 -ceq '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29') 'protected installed APK checksum changed'
Assert-C29N (-not [bool]$apk.installResult.uninstallPerformed) 'protected app was uninstalled'
Assert-C29N (-not [bool]$apk.installResult.dataClearPerformed) 'protected app data was cleared'
Assert-C29N (-not [bool]$apk.installResult.downgradePerformed) 'protected app was downgraded'
Assert-C29N ([bool]$apk.deviceQualificationResult.founderAcceptancePending) 'founder-review gate changed'
Assert-C29N (-not [bool]$apk.deviceQualificationResult.protectedBaselineUpdated) 'protected baseline was advanced'

$navigation = 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$design = 'apps/mobile/lib/core/design/mool_design_system.dart'
$consumer = 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart'
$gateway = 'apps/mobile/lib/ui_v2/social/social_v2_youtube_creator_upload.dart'
$workbench = 'apps/mobile/lib/ui_v2/social/social_v2_create_workbench.dart'
$focusedTest = 'apps/mobile/test/ui_v2/social/uaw-personal-mvp-social-creator-ergonomics-global-edge-consistency-c29n-test.dart'.Replace('-', '_')

Assert-C29NContains $navigation 'class MoolGlobalChatNavigationV2'
Assert-C29NContains $navigation 'destinationFixedCellWidthFor('
Assert-C29NContains $design 'destinationMinimumFixedCellWidth = 44'
Assert-C29NContains $design 'destinationCompactWidthBreakpoint = 340'
Assert-C29NContains $navigation "Key('mool-global-chat-white-surface')"
Assert-C29NContains $navigation "Key('mool-compact-launcher-white-surface')"
Assert-C29NContains $navigation 'color: Colors.white'
Assert-C29NContains $consumer "if (_world != 'social')"
Assert-C29NContains $consumer 'bottomNavigationBar: composerOpen'
Assert-C29NContains $consumer 'initialIntent: switch (_createView)'
Assert-C29NContains $consumer "_createView = 'text'"
Assert-C29NNotContains $consumer 'compactOverlayAlignEnd: true'
Assert-C29NContains $gateway 'ValueChanged<SocialCreateIntentV2> onCreateMoolSocial'
foreach ($id in @('post', 'image', 'carousel', 'image-poll', 'quick-poll', 'quiz')) {
  Assert-C29NContains $gateway "Key('social-create-moolsocial-$id')"
}
Assert-C29NContains $gateway "Key('social-create-youtube-short')"
Assert-C29NNotContains $gateway 'onCreateMoolSocialPost'
Assert-C29NNotContains $gateway 'Create a MoolSocial post'
Assert-C29NContains $workbench 'enum SocialCreateIntentV2'
Assert-C29NContains $workbench "Key('screen04-create-composer-header')"
Assert-C29NContains $workbench "Key('screen04-create-scrollable-composer')"
Assert-C29NContains $workbench "Key('screen04-create-close')"
Assert-C29NContains $workbench 'maximumSize: const Size(96, 44)'
Assert-C29NContains $workbench 'ScrollViewKeyboardDismissBehavior.onDrag'
Assert-C29NNotContains $workbench 'class _ContentLibrary'
Assert-C29NContains $focusedTest 'FakeViewPadding(bottom: 320)'
Assert-C29NContains $focusedTest 'Size(320, 568)'
Assert-C29NContains $focusedTest 'TextScaler.linear(1.4)'
Assert-C29NContains $focusedTest "Key('mool-compact-launcher-white-surface')"
Assert-C29NContains $focusedTest "Key('mool-global-chat-white-surface')"
Assert-C29NContains 'apps/mobile/test/screen04_universal_v2_conformance_test.dart' 'Create hides the dock until the composer closes'
Assert-C29NContains 'apps/mobile/test/ui_v2_social_continuous_batch_test.dart' 'social-create-moolsocial-quiz'
Assert-C29NNotContains 'apps/mobile/test/ui_v2_social_continuous_batch_test.dart' 'need provider access'
Assert-C29NContains 'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_subaction_professional_conformance_c16b_test.dart' 'C29N Social preserves ownership semantics and reduced motion'

$consumerContent = Get-C29NContent $consumer
$dockStart = $consumerContent.IndexOf('class _SocialOwnershipDock', [StringComparison]::Ordinal)
Assert-C29N ($dockStart -ge 0) 'Social dock owner missing'
$dock = $consumerContent.Substring($dockStart)
$moolIndex = $dock.IndexOf('MoolGlobalNavigationV2(', [StringComparison]::Ordinal)
$homeIndex = $dock.IndexOf("Key('screen04-rail-videos')", [StringComparison]::Ordinal)
$chatIndex = $dock.IndexOf('MoolGlobalChatNavigationV2(', [StringComparison]::Ordinal)
Assert-C29N ($moolIndex -ge 0 -and $homeIndex -gt $moolIndex -and $chatIndex -gt $homeIndex) 'Social learned edge order is not Mool-left, local-middle, Chat-right'

$requiredTests = @(
  'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_creator_ergonomics_global_edge_consistency_c29n_test.dart',
  'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_youtube_native_home_dock_c29e_test.dart',
  'apps/mobile/test/social_v2_youtube_creator_upload_test.dart',
  'apps/mobile/test/social_v2_create_publication_test.dart',
  'apps/mobile/test/screen04_universal_v2_conformance_test.dart',
  'apps/mobile/test/ui_v2_social_customer_copy_gate_test.dart',
  'apps/mobile/test/ui_v2_social_named_state_parity_test.dart',
  'apps/mobile/test/ui_v2_social_continuous_batch_test.dart',
  'apps/mobile/test/ui_v2/universal/mool_compact_destination_rail_c25d_test.dart',
  'apps/mobile/test/ui_v2/universal/mool_uniform_navigation_design_system_c27b_test.dart',
  'apps/mobile/test/ui_v2/universal/mool_embedded_vertical_switcher_c26c_test.dart',
  'apps/mobile/test/ui_v2/universal/mool_android_navigation_viewport_c28b_test.dart'
)
foreach ($relative in $requiredTests) { [void](Resolve-C29NFile $relative) }

Write-Output 'C29N source gate passed: global white Mool-left/Chat-right controls; Social middle actions; direct YouTube and six MoolSocial intents; header/content-library removal; keyboard-safe composer; protected r60.34 preserved; backend/build/install/deploy/external/secret authority closed.'
