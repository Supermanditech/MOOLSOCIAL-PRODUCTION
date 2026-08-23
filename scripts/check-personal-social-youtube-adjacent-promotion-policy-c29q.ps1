[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C29Q([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C29Q source gate rejected: $Message" }
}

function Resolve-C29QFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C29Q ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C29Q (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Get-C29QContent([string]$RelativePath) {
  return Get-Content -Raw -LiteralPath (Resolve-C29QFile $RelativePath)
}

function Assert-C29QContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29QContent $RelativePath
  Assert-C29Q ($content.Contains($Text, [StringComparison]::Ordinal)) "required contract missing from $RelativePath`: $Text"
}

function Assert-C29QNotContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29QContent $RelativePath
  Assert-C29Q (-not $content.Contains($Text, [StringComparison]::Ordinal)) "forbidden visible-promotion contract found in $RelativePath`: $Text"
}

$expectedTicket = 'UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-ADJACENT-PROMOTION-POLICY-C29Q'
$ticketPath = Resolve-C29QFile 'config/uaw-personal-mvp-social-youtube-adjacent-promotion-policy-c29q-ticket.json'
$scopePath = Resolve-C29QFile 'config/mvp-scope-gate-state.json'
$apkPath = Resolve-C29QFile 'config/apk-regression-gate-state-c29k.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash

Assert-C29Q ([string]$ticket.ticketId -ceq $expectedTicket) 'ticket identity changed'
Assert-C29Q ([string]$ticket.state -cin @('selected_source_policy_implementation_authorized', 'source_qualified_no_visible_ad_oppo_pending')) 'ticket state is not source-only'
Assert-C29Q ([string]$ticket.classification -ceq 'mvp_supporting') 'MVP classification changed'
Assert-C29Q ([string]$scope.ticket.id -ceq $expectedTicket) 'active scope ticket differs'
Assert-C29Q ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
Assert-C29Q ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha) 'ticket manifest seal changed'
Assert-C29Q ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime source authority is closed'
Assert-C29Q ([bool]$scope.execution.testOrGateWriteAuthorized) 'test authority is closed'
Assert-C29Q (-not [bool]$scope.execution.backendWriteAuthorized) 'backend authority opened'

foreach ($closed in @(
  [bool]$scope.execution.referenceWriteAuthorized,
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
  Assert-C29Q (-not $closed) 'backend/build/install/deploy/external/secret/reference authority opened'
}

Assert-C29Q ([string]$apk.machineState -ceq 'device_qualified_founder_review_pending') 'protected C29K machine state changed'
Assert-C29Q ([string]$apk.installResult.deviceSerial -ceq '2b3e0f71') 'protected OPPO serial changed'
Assert-C29Q ([string]$apk.installResult.versionName -ceq '1.0.0-r60.34') 'protected installed version name changed'
Assert-C29Q ([string]$apk.installResult.versionCode -ceq '2026081134') 'protected installed version code changed'
Assert-C29Q ([string]$apk.installResult.installedApkSha256 -ceq '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29') 'protected installed APK checksum changed'
Assert-C29Q (-not [bool]$apk.installResult.uninstallPerformed) 'protected app was uninstalled'
Assert-C29Q (-not [bool]$apk.installResult.dataClearPerformed) 'protected app data was cleared'
Assert-C29Q (-not [bool]$apk.installResult.downgradePerformed) 'protected app was downgraded'

$policy = 'apps/mobile/lib/ui_v2/social/social_v2_youtube_adjacent_promotion_policy.dart'
$focusedTest = 'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_youtube_adjacent_promotion_policy_c29q_test.dart'
Assert-C29QContains $policy 'const YouTubeAdjacentPromotionPolicy.production()'
Assert-C29QContains $policy 'this._(deliveryEnabled: false);'
Assert-C29QContains $policy 'YouTubePromotionDecisionCode.youtubeOwnedSurface'
Assert-C29QContains $policy 'YouTubePromotionSurface.moolSocialIndependentAdjacent'
Assert-C29QContains $policy "candidate.disclosure.trim() != 'Promoted on MoolSocial'"
Assert-C29QContains $policy 'candidate.incentivizesYouTubeEngagement'
Assert-C29QContains $policy '!candidate.legalApproved'
Assert-C29QContains $policy '!candidate.youtubeApiComplianceApproved'
Assert-C29QContains $policy '!candidate.remoteKillSwitchConfigured'
Assert-C29QContains $policy '!candidate.remoteDeliveryAllowed'
Assert-C29QContains $focusedTest 'production delivery stays disabled for a complete campaign'
Assert-C29QContains $focusedTest 'denies every YouTube-owned surface even when delivery is enabled'
Assert-C29QContains $focusedTest 'renders no promotion on YouTube Home Shorts or Watch'

foreach ($surfaceOwner in @(
  'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart',
  'apps/mobile/lib/core/youtube/youtube_embedded_player_android.dart',
  'apps/mobile/lib/core/youtube/youtube_embedded_player_contract.dart',
  'apps/mobile/lib/core/youtube/youtube_embedded_player_controller.dart'
)) {
  Assert-C29QNotContains $surfaceOwner 'Promoted on MoolSocial'
  Assert-C29QNotContains $surfaceOwner 'Advertisement'
}

Write-Output 'C29Q source gate passed: production promotion delivery hard-disabled, every YouTube-owned surface denied, all future independent-value dependencies enforced, no visible Home/Watch/Shorts ad, r60.34 protected, backend/build/install/deploy/external authority closed.'
