[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-composite-glass-legibility-fix5-c22f1-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$contractPath = Join-Path $root 'config\mvp-personal-capsule-system-regression-c22.json'
$designPath = Join-Path $root 'apps\mobile\lib\core\design\mool_design_system.dart'
$testPath = Join-Path $root 'apps\mobile\test\core\design\mool_composite_glass_legibility_c22f1_test.dart'
$apkPath = Join-Path $root 'config\apk-regression-gate-state.json'
foreach ($path in @($ticketPath, $scopePath, $contractPath, $designPath, $testPath, $apkPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "C22F1 required owner is missing: $path" }
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$expected = 'UAW-PERSONAL-MVP-COMPOSITE-GLASS-LEGIBILITY-FIX5-C22F1'
if ([string]$ticket.ticketId -cne $expected -or [string]$scope.ticket.id -cne $expected -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expected -or
    [string]$scope.state -cne 'ticket_disclosed_and_authorized' -or
    -not [bool]$scope.execution.runtimeWriteAuthorized -or [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized -or [bool]$scope.execution.backendWriteAuthorized -or
    [bool]$scope.execution.externalServiceWriteAuthorized) {
  throw 'C22F1 selected ticket or closed build/install authority is invalid.'
}

$rules = $contract.visualRules
if ([string]$contract.state -cne 'c22g_cycle1_rejected_c22f1_active_runtime_test_gate_authorized_build_install_closed' -or
    [string]$rules.neutralGlassTopArgb -cne 'B30D1326' -or [string]$rules.neutralGlassBottomArgb -cne 'AB050816' -or
    [double]$rules.minimumNeutralDestinationTransmission -ne 0.29 -or
    [double]$rules.minimumCompositeWhiteForegroundContrast -ne 4.5 -or
    [double]$rules.maximumSelectedEmissionAlpha -ne 0.28 -or
    [double]$rules.selectedEmissionCenterAlpha -ne 0.27 -or
    [double]$rules.selectedEmissionMiddleAlpha -ne 0.135 -or
    [double]$rules.pressedEmissionLayerOpacity -ne 0.62 -or
    [double]$rules.capsuleWidth -ne 72 -or [double]$rules.controlHeight -ne 48 -or
    [double]$rules.controlRadius -ne 24 -or [double]$rules.itemGap -ne 8 -or
    [double]$rules.labelFontSize -ne 12 -or [int]$rules.labelFontWeight -ne 800 -or
    [bool]$rules.fullWidthBandPanelTrapezoidOrSegmentedStripAllowed -or
    -not [bool]$rules.destinationPixelsVisibleOutsideAndBetweenCapsules -or
    -not [bool]$contract.runtimeMutationAuthorized -or [bool]$contract.buildAuthorized -or [bool]$contract.installAuthorized) {
  throw 'C22F1 machine-readable legibility contract has drifted.'
}

$design = Get-Content -Raw -LiteralPath $designPath
foreach ($token in @(
  'static const Color neutralGlassTop = Color(0xB30D1326);',
  'static const Color neutralGlassBottom = Color(0xAB050816);',
  'static const double minimumNeutralDestinationTransmission = .29;',
  'static const double minimumWhiteForegroundContrast = 4.5;',
  'static const double maximumInnerEmissionAlpha = .28;',
  'static const double innerEmissionCenterAlpha = .27;',
  'static const double innerEmissionMiddleAlpha = .135;',
  'static const double pressedEmissionOpacity = .62;'
)) {
  if (-not $design.Contains($token)) { throw "C22F1 shared design token is missing: $token" }
}
if ([string]$apk.machineState -cne 'r60_20_founder_rejected_installed_checksum_identity_preserved_successor_build_closed' -or
    [string]$apk.installResult.installedBaseSha256 -cne 'FF3932D84794BA8802946CBB04F8A346F34386F4A5C8321F3970AD8E6228EF8A') {
  throw 'C22F1 refuses changed installed r60.20 identity.'
}

Write-Output 'C22F1 composite-glass gate passed: families=6; glass=B3/AB nonopaque; minimumTransmission=0.29; emission=0.27/0.135; compositeContrast=4.5; geometry=72x48-r24; r60.20=preserved; buildInstall=closed.'
