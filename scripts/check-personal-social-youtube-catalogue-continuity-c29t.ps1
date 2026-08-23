[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C29T([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C29T source gate rejected: $Message" }
}

function Resolve-C29TFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C29T ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C29T (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Get-C29TContent([string]$RelativePath) {
  return Get-Content -Raw -LiteralPath (Resolve-C29TFile $RelativePath)
}

function Assert-C29TContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29TContent $RelativePath
  Assert-C29T ($content.Contains($Text, [StringComparison]::Ordinal)) "required contract missing from $RelativePath`: $Text"
}

$expectedTicket = 'UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-CATALOGUE-CONTINUITY-C29T'
$ticketPath = Resolve-C29TFile 'config/uaw-personal-mvp-social-youtube-catalogue-continuity-c29t-ticket.json'
$scopePath = Resolve-C29TFile 'config/mvp-scope-gate-state.json'
$apkPath = Resolve-C29TFile 'config/apk-regression-gate-state-c29k.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash

Assert-C29T ([string]$ticket.ticketId -ceq $expectedTicket) 'ticket identity changed'
Assert-C29T ([string]$ticket.state -cin @('selected_source_implementation_authorized', 'source_qualified_apk_cross_comparison_pending')) 'ticket state is not source-only'
Assert-C29T ([string]$ticket.classification -ceq 'mvp_required') 'MVP classification changed'
Assert-C29T ([string]$scope.ticket.id -ceq $expectedTicket) 'active scope ticket differs'
Assert-C29T ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
Assert-C29T ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha) 'ticket manifest seal changed'
Assert-C29T ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime source authority is closed'
Assert-C29T ([bool]$scope.execution.testOrGateWriteAuthorized) 'test/evidence authority is closed'

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
  Assert-C29T (-not $closed) 'backend/build/install/deploy/external/secret/reference authority opened'
}

Assert-C29T ([string]$apk.machineState -ceq 'device_qualified_founder_review_pending') 'protected C29K machine state changed'
Assert-C29T ([string]$apk.installResult.deviceSerial -ceq '2b3e0f71') 'protected OPPO serial changed'
Assert-C29T ([string]$apk.installResult.versionName -ceq '1.0.0-r60.34') 'protected installed version name changed'
Assert-C29T ([string]$apk.installResult.versionCode -ceq '2026081134') 'protected installed version code changed'
Assert-C29T ([string]$apk.installResult.installedApkSha256 -ceq '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29') 'protected installed APK checksum changed'
Assert-C29T (-not [bool]$apk.installResult.uninstallPerformed) 'protected app was uninstalled'
Assert-C29T (-not [bool]$apk.installResult.dataClearPerformed) 'protected app data was cleared'
Assert-C29T (-not [bool]$apk.installResult.downgradePerformed) 'protected app was downgraded'

$runtime = 'apps/mobile/lib/ui_v2/social/social_v2_youtube_public_runtime.dart'
$consumer = 'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart'
$focusedTest = 'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_youtube_catalogue_continuity_c29t_test.dart'
$runtimeTest = 'apps/mobile/test/social_v2_youtube_public_runtime_test.dart'

Assert-C29TContains $runtime 'final screen04YouTubeCatalogueSnapshots ='
Assert-C29TContains $runtime 'class Screen04YouTubeCatalogueSnapshotStore'
Assert-C29TContains $runtime 'this.timeToLive = const Duration(minutes: 5)'
Assert-C29TContains $runtime 'List<Screen04YouTubePublicVideo>.unmodifiable(items)'
Assert-C29TContains $runtime 'if (age.isNegative || age > timeToLive) return null;'
Assert-C29TContains $consumer 'final Screen04YouTubeCatalogueSnapshotStore? youtubeCatalogueSnapshotStore;'
Assert-C29TContains $consumer '_youtubeCatalogueSnapshots.readFreshVideos()'
Assert-C29TContains $consumer '_youtubeCatalogueSnapshots.readFreshShorts()'
Assert-C29TContains $consumer '_liveYouTubeLoading = !_hasYouTubeVideosSnapshot;'
Assert-C29TContains $consumer '_liveYouTubeShortsLoading = !_hasYouTubeShortsSnapshot;'
Assert-C29TContains $consumer 'if (videosFailure == null) {'
Assert-C29TContains $consumer 'if (_liveYouTubeError != null && !_hasYouTubeVideosSnapshot)'
Assert-C29TContains $consumer 'if (_liveYouTubeShortsError != null && !_hasYouTubeShortsSnapshot)'
Assert-C29TContains $consumer "Key('screen04-youtube-videos-refresh-error')"
Assert-C29TContains $consumer "Key('screen04-youtube-shorts-refresh-error')"
Assert-C29TContains $consumer 'Showing your last loaded catalogue.'
Assert-C29TContains $focusedTest 'reopens Videos and Shorts from snapshots while refresh is pending'
Assert-C29TContains $focusedTest 'expired snapshot uses only the in-surface cold start'
Assert-C29TContains $focusedTest 'find.byType(Dialog), findsNothing'
Assert-C29TContains $runtimeTest 'catalogue snapshots are immutable and expire after the short TTL'

Write-Output 'C29T source gate passed: fresh provider catalogue hydrates on reopen, refresh stays background/nonmodal, transient failure retains content, cold start stays in-surface, r60.34 protected, backend/build/install/deploy/external/secret authority closed.'
