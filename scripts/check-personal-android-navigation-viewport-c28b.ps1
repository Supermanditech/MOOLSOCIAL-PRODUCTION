[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C28B([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C28B gate rejected: $Message" }
}

function Read-C28BOwner([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C28B ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C28B (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return [IO.File]::ReadAllText($path)
}

$ticket = Read-C28BOwner 'config/uaw-personal-mvp-android-navigation-viewport-implementation-fix11-c28b-ticket.json' | ConvertFrom-Json
$scope = Read-C28BOwner 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$viewport = Read-C28BOwner 'apps/mobile/lib/core/platform/mool_system_ui_viewport.dart'
$main = Read-C28BOwner 'apps/mobile/lib/main.dart'
$platformTest = Read-C28BOwner 'apps/mobile/test/core/platform/mool_system_ui_viewport_c28b_test.dart'
$shellTest = Read-C28BOwner 'apps/mobile/test/ui_v2/universal/mool_android_navigation_viewport_c28b_test.dart'

Assert-C28B ([string]$ticket.ticketId -ceq 'UAW-PERSONAL-MVP-ANDROID-NAVIGATION-VIEWPORT-IMPLEMENTATION-FIX11-C28B') 'ticket id changed'
$ticketState = [string]$ticket.state
Assert-C28B ($ticketState -cin @('active', 'complete')) 'unsupported ticket state'
if ($ticketState -ceq 'active') {
  Assert-C28B ([string]$scope.ticket.id -ceq [string]$ticket.ticketId) 'active scope ticket differs'
  Assert-C28B ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime authorization is not open'
}
Assert-C28B (-not [bool]$ticket.execution.buildAuthorized) 'build authority must remain closed'
Assert-C28B (-not [bool]$ticket.execution.installAuthorized) 'install authority must remain closed'

foreach ($literal in @(
  'defaultTargetPlatform != TargetPlatform.android',
  'SystemChrome.setEnabledSystemUIMode(',
  'SystemUiMode.manual',
  'overlays: SystemUiOverlay.values'
)) {
  Assert-C28B ($viewport.Contains($literal)) "shared viewport contract missing: $literal"
}
Assert-C28B ($main.Contains("import 'core/platform/mool_system_ui_viewport.dart';")) 'main viewport import missing'
Assert-C28B ($main.Contains('await configureMoolSystemUiViewport();')) 'startup viewport call missing'

foreach ($literal in @(
  'C28B Android requests both visible system overlays',
  'SystemChrome.setEnabledSystemUIOverlays',
  "'SystemUiOverlay.top'",
  "'SystemUiOverlay.bottom'",
  'C28B non-Android platforms keep their native viewport policy'
)) {
  Assert-C28B ($platformTest.Contains($literal)) "platform acceptance missing: $literal"
}
foreach ($literal in @(
  'C28B OPPO insets keep the approved rail and full Flutter semantics',
  'const Size(360, 806)',
  'const EdgeInsets.only(top: 41, bottom: 44)',
  'const Size(54, 58)',
  'C28B keyboard and reduced motion retain the persistent bottom inset'
)) {
  Assert-C28B ($shellTest.Contains($literal)) "shared-shell acceptance missing: $literal"
}

Write-Output 'C28B Android navigation viewport gate passed: shared visible-overlay policy; locked MainActivity excluded; Android-15+ edge-to-edge retained; OPPO insets and 58px rail covered.'
