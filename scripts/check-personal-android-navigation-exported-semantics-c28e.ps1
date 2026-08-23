[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C28E([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C28E exported-semantics gate rejected: $Message" }
}

function Resolve-C28EFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C28E ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C28E (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

$contractPath = Resolve-C28EFile 'config/mvp-personal-android-navigation-exported-semantics-c28e.json'
$ticketPath = Resolve-C28EFile 'config/uaw-personal-mvp-android-navigation-exported-semantics-host-remediation-fix12-c28e-ticket.json'
$scopePath = Resolve-C28EFile 'config/mvp-scope-gate-state.json'
$systemOwner = Resolve-C28EFile 'apps/mobile/lib/core/platform/mool_system_ui_viewport.dart'
$railOwner = Resolve-C28EFile 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
$systemTest = Resolve-C28EFile 'apps/mobile/test/core/platform/mool_system_ui_viewport_c28b_test.dart'
$railTest = Resolve-C28EFile 'apps/mobile/test/ui_v2/universal/mool_android_navigation_viewport_c28b_test.dart'

$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$systemSource = Get-Content -Raw -LiteralPath $systemOwner
$railSource = Get-Content -Raw -LiteralPath $railOwner
$systemTestSource = Get-Content -Raw -LiteralPath $systemTest
$railTestSource = Get-Content -Raw -LiteralPath $railTest

$ticketId = 'UAW-PERSONAL-MVP-ANDROID-NAVIGATION-EXPORTED-SEMANTICS-HOST-REMEDIATION-FIX12-C28E'
Assert-C28E ([string]$contract.contractId -ceq 'MOOLSOCIAL-PERSONAL-ANDROID-NAVIGATION-EXPORTED-SEMANTICS-C28E-001') 'contract id changed'
Assert-C28E ([string]$contract.ticketId -ceq $ticketId) 'contract ticket changed'
Assert-C28E ([string]$ticket.ticketId -ceq $ticketId) 'ticket manifest changed'
Assert-C28E ([string]$ticket.state -cin @('active', 'complete')) 'ticket is not active or complete'
if ([string]$ticket.state -ceq 'active') {
  Assert-C28E ([string]$scope.ticket.id -ceq $ticketId) 'active machine scope differs'
  Assert-C28E ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime authority is closed'
}

Assert-C28E ([int]$contract.systemUi.targetSdk -eq 36) 'target SDK contract changed'
Assert-C28E ([string]$contract.systemUi.mode -ceq 'SystemUiMode.edgeToEdge') 'edge-to-edge ownership changed'
Assert-C28E (-not [bool]$contract.systemUi.manualModeAllowed) 'manual system UI was re-authorized'
Assert-C28E ([double]$contract.geometry.destinationRailHeight -eq 58) 'accepted rail height changed'
Assert-C28E ([double]$contract.geometry.minimumExportedLogicalHeight -eq 44) 'exported height minimum changed'
Assert-C28E ([double]$contract.oppoHostSimulation.expectedClearance -eq 27) 'OPPO host clearance changed'
Assert-C28E ([double]$contract.oppoHostSimulation.expectedMinimumExportedHeight -eq 44) 'OPPO exported result changed'
Assert-C28E (@($contract.currentNavigationProjection).Count -eq 6) 'six-family projection changed'

$social = @($contract.currentNavigationProjection | Where-Object { [string]$_.familyId -ceq 'social' })
$buy = @($contract.currentNavigationProjection | Where-Object { [string]$_.familyId -ceq 'buy' })
Assert-C28E ($social.Count -eq 1 -and -not [bool]$social[0].familyRootExpected) 'FSC01 Social-root absence changed'
Assert-C28E (@($social[0].localLabels).Count -eq 4) 'Social direct action count changed'
Assert-C28E ($buy.Count -eq 1 -and [bool]$buy[0].familyRootExpected) 'Shop root changed'
Assert-C28E (@($buy[0].localLabels).Count -eq 2) 'FSC06 Buy action count changed'
Assert-C28E (-not (@($buy[0].localLabels) -ccontains 'Products')) 'Products returned to Buy'

Assert-C28E ($systemSource.Contains('SystemUiMode.edgeToEdge')) 'runtime does not request edge-to-edge'
Assert-C28E (-not $systemSource.Contains('SystemUiMode.manual')) 'unsupported manual mode returned'
foreach ($required in @(
  'moolAndroidExportedSemanticsClearance',
  'View.of(context)',
  'view.viewPadding',
  'MoolMetrics.minimumTapTarget',
  'moolsocial-android-exported-semantics-clearance'
)) {
  Assert-C28E ($railSource.Contains($required)) "rail owner is missing: $required"
}
Assert-C28E ($systemTestSource.Contains('SystemUiMode.edgeToEdge')) 'system-mode test is stale'
Assert-C28E ($railTestSource.Contains('TargetPlatformVariant.only(TargetPlatform.android)')) 'Android platform variant is missing'
Assert-C28E ($railTestSource.Contains('FakeViewPadding(top: 41, bottom: 44)')) 'raw OPPO view padding is missing'
Assert-C28E ($railTestSource.Contains('greaterThanOrEqualTo(44)')) '44-pixel exported assertion is missing'

foreach ($closed in @(
  [bool]$ticket.execution.buildAuthorized,
  [bool]$ticket.execution.installAuthorized,
  [bool]$ticket.execution.backendWriteAuthorized,
  [bool]$ticket.execution.externalServiceWriteAuthorized,
  [bool]$scope.execution.buildAuthorized,
  [bool]$scope.execution.deviceInstallAuthorized,
  [bool]$scope.execution.backendWriteAuthorized,
  [bool]$scope.execution.externalServiceWriteAuthorized
)) {
  Assert-C28E (-not $closed) 'build, install, backend or external authority opened during host remediation'
}

Write-Output 'C28E exported-semantics gate passed: edgeToEdge=true; rail=58; OPPOClearance=27; exportedMinimum=44; SocialRoot=false; BuyProducts=false; buildInstall=false.'
