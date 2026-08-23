[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$ContractPath,
  [string]$TicketPath,
  [string]$ScopePath,
  [string]$ApkStatePath
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
if (-not $ContractPath) { $ContractPath = Join-Path $root 'config/mvp-personal-mool-home-action-hub-regression-c23.json' }
if (-not $TicketPath) { $TicketPath = Join-Path $root 'config/uaw-personal-mvp-founder-mool-home-action-hub-contract-fix6-c23a-ticket.json' }
if (-not $ScopePath) { $ScopePath = Join-Path $root 'config/mvp-scope-gate-state.json' }
if (-not $ApkStatePath) { $ApkStatePath = Join-Path $root 'config/apk-regression-gate-state.json' }

foreach ($path in @($ContractPath, $TicketPath, $ScopePath, $ApkStatePath)) {
  $resolved = [IO.Path]::GetFullPath($path)
  if (-not $resolved.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or
      -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "C23A owner is missing or outside the repository: $path"
  }
}

$contract = Get-Content -Raw -LiteralPath $ContractPath | ConvertFrom-Json
$ticket = Get-Content -Raw -LiteralPath $TicketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $ScopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $ApkStatePath | ConvertFrom-Json
$expectedTicket = 'UAW-PERSONAL-MVP-FOUNDER-MOOL-HOME-ACTION-HUB-CONTRACT-FIX6-C23A'

if ([string]$contract.contractId -cne 'UAW-PERSONAL-MVP-MOOL-HOME-ACTION-HUB-REGRESSION-C23' -or
    [string]$ticket.ticketId -cne $expectedTicket -or
    [string]$scope.ticket.id -cne $expectedTicket -or
    [string]$scope.preTicketSelectionCheckpoint.currentTicketId -cne $expectedTicket) {
  throw 'C23A contract, ticket or scope identity is invalid.'
}
if ([string]$apk.machineState -cne 'r60_21_founder_rejected_installed_checksum_identity_preserved_successor_build_install_closed' -or
    [string]$apk.installResult.installedVersionName -cne '1.0.0-r60.21' -or
    [string]$apk.installResult.installedVersionCode -cne '2026080921' -or
    [string]$apk.installResult.installedBaseSha256 -cne '17AF5DC2353E7195A597555C88AA42B345AFFDA0EC160900B55B0D3E822691BE') {
  throw 'C23A refuses changed r60.21 founder-rejected installed identity.'
}

$shell = $contract.destinationShell
$hub = $contract.homeHub
if ([bool]$shell.persistentGlobalRailAllowed -or
    [bool]$shell.persistentSubactionRailAllowed -or
    [bool]$shell.fullWidthBottomSurfaceAllowed -or
    [bool]$shell.horizontalActionScrollingAllowed -or
    -not [bool]$shell.singleMoolHomeLauncherRequired -or
    [int]$shell.launcherMinimumTapSize -lt 56 -or
    [bool]$shell.chatPersistentBottomControlAllowed) {
  throw 'C23A destination-shell zero-rail/single-launcher contract weakened.'
}
if ([string]$hub.existingRoute -cne '/app/mool' -or [bool]$hub.newScreenAllowed -or
    [bool]$hub.familyExpansionTapAllowed -or [int]$hub.mainDefaultTapCountFromHome -ne 1 -or
    [int]$hub.subactionTapCountFromHome -ne 1 -or [int]$hub.maximumTapCountFromDestination -ne 2 -or
    [int]$hub.minimumTapSize -lt 44 -or -not [bool]$hub.professionalNeutralSurfaceRequired -or
    -not [bool]$hub.restrainedFamilyAccentRequired -or [bool]$hub.largeBlockFamilyColourAllowed -or
    [bool]$hub.fillerActionAllowed) {
  throw 'C23A Home-hub structure, tap budget or professional surface contract weakened.'
}

$families = @($contract.families)
$expectedCounts = @{ social = 4; buy = 4; eat = 2; ride = 3; book = 2; work = 2 }
if ($families.Count -ne 6 -or (@($families.id) -join ',') -cne 'social,buy,eat,ride,book,work') {
  throw 'C23A family order or count is invalid.'
}
$routes = @()
$actionCount = 0
foreach ($family in $families) {
  $id = [string]$family.id
  if (-not $expectedCounts.ContainsKey($id) -or @($family.actions).Count -ne $expectedCounts[$id]) {
    throw "C23A truthful action count drifted for $id."
  }
  if ([string]::IsNullOrWhiteSpace([string]$family.label) -or
      -not ([string]$family.route).StartsWith('/app/', [StringComparison]::Ordinal) -or
      -not ([string]$family.accent -match '^[0-9A-F]{6}$')) {
    throw "C23A family metadata is invalid for $id."
  }
  $routes += [string]$family.route
  foreach ($action in @($family.actions)) {
    if ([string]::IsNullOrWhiteSpace([string]$action.label) -or
        -not ([string]$action.route).StartsWith('/app/', [StringComparison]::Ordinal)) {
      throw "C23A subaction metadata is invalid for $id."
    }
    $routes += [string]$action.route
    $actionCount++
  }
}
if ($actionCount -ne 17 -or $routes.Count -ne @($routes | Select-Object -Unique).Count) {
  throw 'C23A route matrix is incomplete or duplicated.'
}
if (-not [bool]$contract.motion.finiteOnly -or [int]$contract.motion.launcherPressMilliseconds -le 0 -or
    [int]$contract.motion.hubArrivalMaximumMilliseconds -gt 220 -or
    -not [bool]$contract.motion.reducedMotionImmediate) {
  throw 'C23A motion/reduced-motion contract is invalid.'
}
if ([bool]$contract.authority.runtimeMutationAuthorized -or [bool]$contract.authority.buildAuthorized -or
    [bool]$contract.authority.installAuthorized -or [bool]$ticket.execution.runtimeSourceWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or [bool]$ticket.execution.installAuthorized -or
    [bool]$scope.execution.runtimeWriteAuthorized -or [bool]$scope.execution.buildAuthorized -or
    [bool]$scope.execution.deviceInstallAuthorized) {
  throw 'C23A contract-only runtime/build/install authority is not closed.'
}

Write-Output 'C23A founder Home-hub contract passed: zeroRails=true; singleLauncher=true; families=6; subactions=17; fromHomeTaps=1; destinationMaxTaps=2; runtimeBuildInstall=closed.'
