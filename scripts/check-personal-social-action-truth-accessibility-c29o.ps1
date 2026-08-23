[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C29O([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C29O source gate rejected: $Message" }
}

function Resolve-C29OFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C29O ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C29O (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Get-C29OContent([string]$RelativePath) {
  return Get-Content -Raw -LiteralPath (Resolve-C29OFile $RelativePath)
}

function Assert-C29OContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29OContent $RelativePath
  Assert-C29O ($content.Contains($Text, [StringComparison]::Ordinal)) "required contract missing from $RelativePath`: $Text"
}

function Assert-C29ONotContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29OContent $RelativePath
  Assert-C29O (-not $content.Contains($Text, [StringComparison]::Ordinal)) "rejected contract remains in $RelativePath`: $Text"
}

$expectedTicket = 'UAW-PERSONAL-MVP-SOCIAL-ACTION-TRUTH-AND-ACCESSIBILITY-C29O'
$ticketPath = Resolve-C29OFile 'config/uaw-personal-mvp-social-action-truth-accessibility-c29o-ticket.json'
$scopePath = Resolve-C29OFile 'config/mvp-scope-gate-state.json'
$apkPath = Resolve-C29OFile 'config/apk-regression-gate-state-c29k.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash

Assert-C29O ([string]$ticket.ticketId -ceq $expectedTicket) 'ticket identity changed'
Assert-C29O ([string]$ticket.state -cin @('selected_source_implementation_authorized', 'source_qualified_apk_cross_comparison_pending')) 'ticket state is not source-only'
Assert-C29O ([string]$ticket.classification -ceq 'mvp_required') 'MVP classification changed'
Assert-C29O ([string]$scope.ticket.id -ceq $expectedTicket) 'active scope ticket differs'
Assert-C29O ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
Assert-C29O ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha) 'ticket manifest seal changed'
Assert-C29O ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime source authority is closed'
Assert-C29O ([bool]$scope.execution.testOrGateWriteAuthorized) 'test/evidence authority is closed'

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
  Assert-C29O (-not $closed) 'backend/build/install/deploy/external/secret/reference authority opened'
}

Assert-C29O ([string]$apk.machineState -ceq 'device_qualified_founder_review_pending') 'protected C29K machine state changed'
Assert-C29O ([string]$apk.installResult.deviceSerial -ceq '2b3e0f71') 'protected OPPO serial changed'
Assert-C29O ([string]$apk.installResult.versionName -ceq '1.0.0-r60.34') 'protected installed version name changed'
Assert-C29O ([string]$apk.installResult.versionCode -ceq '2026081134') 'protected installed version code changed'
Assert-C29O ([string]$apk.installResult.installedApkSha256 -ceq '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29') 'protected installed APK checksum changed'
Assert-C29O (-not [bool]$apk.installResult.uninstallPerformed) 'protected app was uninstalled'
Assert-C29O (-not [bool]$apk.installResult.dataClearPerformed) 'protected app data was cleared'
Assert-C29O (-not [bool]$apk.installResult.downgradePerformed) 'protected app was downgraded'

$consumer = 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart'
$workbench = 'apps/mobile/lib/ui_v2/social/social_v2_create_workbench.dart'
$focusedTest = 'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_action_truth_accessibility_c29o_test.dart'
$conformanceTest = 'apps/mobile/test/screen04_universal_v2_conformance_test.dart'
$runtimeTest = 'apps/mobile/test/social_v2_youtube_public_runtime_test.dart'

Assert-C29OContains $consumer 'data: media,'
Assert-C29ONotContains $consumer 'TextScaler.linear(effectiveTextScale)'
Assert-C29ONotContains $consumer "Key('screen04-video-save')"
Assert-C29ONotContains $consumer "Key('screen04-video-discuss')"
Assert-C29ONotContains $consumer 'Comment posted on MoolSocial'
Assert-C29ONotContains $consumer 'class _VideoWatchScreen'
Assert-C29ONotContains $consumer 'Finding videos for you'
Assert-C29ONotContains $consumer 'Search YouTube videos'
Assert-C29OContains $consumer "title: 'Filter loaded videos'"
Assert-C29OContains $consumer "title: 'Loading YouTube videos'"
Assert-C29OContains $consumer "tooltip: 'Filter loaded YouTube videos'"
Assert-C29OContains $consumer 'Clipboard.setData(ClipboardData(text: url.toString()))'
Assert-C29OContains $consumer "showSocialV2Message(context, 'YouTube link copied')"
Assert-C29OContains $consumer "label: 'Available actions for this YouTube video'"
Assert-C29OContains $consumer 'alignment: WrapAlignment.center'
Assert-C29OContains $consumer 'overflow: TextOverflow.ellipsis'
Assert-C29OContains $workbench 'final additionalHeight = textScale > 1 ? (textScale - 1) * 14.0 : 0.0;'
Assert-C29OContains $workbench 'height: 56.0 + additionalHeight'

Assert-C29OContains $focusedTest 'TextScaler.linear(1.4)'
Assert-C29OContains $focusedTest 'MediaQuery.textScalerOf(socialContext).scale(10)'
Assert-C29OContains $focusedTest "'shorts': Key('screen04-youtube-shorts-state-provider-access')"
Assert-C29OContains $focusedTest "Key('screen04-rail-`${journey.key}')"
Assert-C29OContains $focusedTest "Key('social-global-chat')"
Assert-C29OContains $conformanceTest 'https://www.youtube.com/watch?v=def456UVW10'
Assert-C29OContains $conformanceTest "Key('screen04-video-save')"
Assert-C29OContains $conformanceTest 'findsNothing'
Assert-C29OContains $runtimeTest 'isNot(contains(''screen04-video-save''))'
Assert-C29OContains $runtimeTest 'isNot(contains(''screen04-video-discuss''))'

foreach ($relative in @(
  'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_action_truth_accessibility_c29o_test.dart',
  'apps/mobile/test/screen04_universal_v2_conformance_test.dart',
  'apps/mobile/test/social_v2_youtube_public_runtime_test.dart',
  'apps/mobile/test/ui_v2_social_fitment_matrix_test.dart',
  'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_creator_ergonomics_global_edge_consistency_c29n_test.dart',
  'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_youtube_native_home_dock_c29e_test.dart'
)) { [void](Resolve-C29OFile $relative) }

Write-Output 'C29O source gate passed: real 140 percent system text, adaptive narrow rows, truthful YouTube watch/share/filter copy, C29N navigation preserved, r60.34 protected, backend/build/install/deploy/external/secret authority closed.'
