[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$contractPath = Join-Path $root 'config\mvp-personal-android-navigation-device-matrix-c28f.json'
$expectedContractSha256 = 'EED84CD27E5834813ACC2DC7A0D83885E435FD8829DCBA4DF621AE2EC14EAE15'

function Assert-C28FMatrix([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C28F matrix gate rejected: $Message" }
}

function Resolve-C28FMatrixFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C28FMatrix ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C28FMatrix (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

Assert-C28FMatrix (Test-Path -LiteralPath $contractPath -PathType Leaf) 'contract is missing'
Assert-C28FMatrix ((Get-FileHash -Algorithm SHA256 -LiteralPath $contractPath).Hash -ceq $expectedContractSha256) 'contract checksum changed'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
Assert-C28FMatrix ([int]$contract.schemaVersion -eq 1) 'schema changed'
Assert-C28FMatrix ([string]$contract.contractId -ceq 'MOOLSOCIAL-PERSONAL-ANDROID-NAVIGATION-DEVICE-MATRIX-C28F-001') 'contract id changed'
Assert-C28FMatrix ([string]$contract.ticketId -ceq 'UAW-PERSONAL-MVP-ANDROID-NAVIGATION-EXPORTED-SEMANTICS-OPPO-QUALIFICATION-FIX12-C28F') 'ticket changed'
Assert-C28FMatrix ([string]$contract.candidate.versionName -ceq '1.0.0-r60.28') 'version name changed'
Assert-C28FMatrix ([string]$contract.candidate.versionCode -ceq '2026081028') 'version code changed'
Assert-C28FMatrix ([string]$contract.candidate.deviceSerial -ceq '2b3e0f71') 'device serial changed'
Assert-C28FMatrix ([string]$contract.candidate.deviceModel -ceq 'CPH2375') 'device model changed'
Assert-C28FMatrix ([int]$contract.candidate.densityDpi -eq 320) 'density changed'
Assert-C28FMatrix ([double]$contract.candidate.minimumLogicalTarget -eq 44) 'minimum target changed'

$ownerProperties = @($contract.reusedOwners.PSObject.Properties)
Assert-C28FMatrix ($ownerProperties.Count -eq 4) 'reused owner inventory changed'
foreach ($property in $ownerProperties) { [void](Resolve-C28FMatrixFile ([string]$property.Value)) }

$families = @($contract.families)
$expectedFamilyIds = @('social','buy','eat','ride','book','work')
$familyIds = @($families | ForEach-Object { [string]$_.id })
Assert-C28FMatrix ($families.Count -eq 6 -and -not (Compare-Object $expectedFamilyIds $familyIds)) 'six-family inventory changed'
$actions = @($families | ForEach-Object { @($_.actions) })
$actionIds = @($actions | ForEach-Object { [string]$_.id })
$actionLabels = @($actions | ForEach-Object { [string]$_.label })
Assert-C28FMatrix ($actions.Count -eq 17) '17-action inventory changed'
Assert-C28FMatrix ($actionIds.Count -eq @($actionIds | Select-Object -Unique).Count) 'action ids are duplicated'
Assert-C28FMatrix ($actionLabels.Count -eq @($actionLabels | Select-Object -Unique).Count) 'action labels are duplicated'
foreach ($family in $families) {
  Assert-C28FMatrix (-not [string]::IsNullOrWhiteSpace([string]$family.familyRootSemantic)) "family-root semantic missing: $($family.id)"
  foreach ($action in @($family.actions)) {
    Assert-C28FMatrix (-not [string]::IsNullOrWhiteSpace([string]$action.selectedSemantic)) "selected semantic missing: $($action.id)"
    Assert-C28FMatrix (@($action.contentAnyOf).Count -gt 0) "content reachability missing: $($action.id)"
  }
}
$social = @($families | Where-Object { [string]$_.id -ceq 'social' })[0]
$buy = @($families | Where-Object { [string]$_.id -ceq 'buy' })[0]
Assert-C28FMatrix (-not [bool]$social.familyRootExpected) 'FSC01 Social root returned'
Assert-C28FMatrix ([bool]$buy.familyRootExpected) 'Shop family root disappeared'
Assert-C28FMatrix ((@($buy.actions | ForEach-Object { [string]$_.label }) -join '|') -ceq 'Wholesale|Orders') 'FSC06 Buy action catalogue changed'
Assert-C28FMatrix ((@($buy.forbiddenLocalLabels) -join '|') -ceq 'Products|Shop') 'FSC06 forbidden labels changed'

$expectedStateIds = @(
  'social-shorts','social-videos','social-feed','social-create-ime-visible','social-create-ime-back','switcher-social-create',
  'shop-wholesale','shop-orders','food-order-food','food-book-table',
  'travel-bike','travel-auto','travel-cab','travel-bus',
  'care-doctor','care-medicine','switcher-care-medicine','care-medicine-after-switcher-back','care-salon',
  'work-earn-today','work-workspace','chat-from-work-workspace','work-workspace-after-chat-back',
  'switcher-open-by-swipe-up','workspace-after-swipe-down','switcher-before-outside-tap','workspace-after-outside-tap',
  'social-after-six-family-cycle'
)
$plannedStateIds = @($contract.plannedStateIds | ForEach-Object { [string]$_ })
Assert-C28FMatrix ($plannedStateIds.Count -eq 28 -and $plannedStateIds.Count -eq @($plannedStateIds | Select-Object -Unique).Count -and -not (Compare-Object $expectedStateIds $plannedStateIds)) '28-state plan changed'
Assert-C28FMatrix (@($contract.continuityRequirements).Count -eq 7) 'continuity plan changed'
$switcherRows = @($contract.switcher.rows | ForEach-Object { [string]$_ })
Assert-C28FMatrix ($switcherRows.Count -eq 6 -and -not (Compare-Object @('Social','Shop','Food','Travel','Care','Work') $switcherRows)) 'switcher rows changed'
Assert-C28FMatrix ([double]$contract.switcher.rowHeightLogical -ge 44) 'switcher row height fell below 44'

$ticketPath = Resolve-C28FMatrixFile 'config/uaw-personal-mvp-android-navigation-exported-semantics-oppo-qualification-fix12-c28f-ticket.json'
$scopePath = Resolve-C28FMatrixFile 'config/mvp-scope-gate-state.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
if ([string]$scope.state -ceq 'awaiting_next_ticket_classification') {
  Assert-C28FMatrix ([string]::IsNullOrWhiteSpace([string]$scope.ticket.id)) 'closed scope retained an active ticket'
  Assert-C28FMatrix ([string]$scope.ticket.lastClosedTicketId -ceq [string]$contract.ticketId) 'closed scope last ticket changed'
  Assert-C28FMatrix (-not [bool]$scope.checkpoint.successorRegistered) 'closed scope still registers a successor'
} else {
  Assert-C28FMatrix ([string]$scope.ticket.id -ceq [string]$contract.ticketId) 'scope ticket changed'
}
Assert-C28FMatrix ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$contract.ticketId) 'selected ticket changed'
Assert-C28FMatrix ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash) 'ticket seal changed'
Assert-C28FMatrix ([string]$ticket.state -cin @('active_prebuild_gates_only','active_build_authorized','active_install_authorized','device_qualified_founder_review_pending','device_gate_rejected_successor_required')) 'ticket state is unsupported'

$matrixState = [string]$contract.state
Assert-C28FMatrix ($matrixState -cin @('planned_prebuild','captured_founder_review_pending','device_gate_rejected')) 'matrix state is unsupported'
$capturedStates = @($contract.capturedStates)
if ($matrixState -ceq 'planned_prebuild') {
  Assert-C28FMatrix ($capturedStates.Count -eq 0) 'planned contract already contains captured evidence'
  Write-Output 'C28F planned device matrix passed: families=6; actions=17; states=28; SocialRoot=false; BuyProducts=false; boundsGate=required; build/install authority not inferred.'
  return
}

$evidenceRoot = [IO.Path]::GetFullPath((Join-Path $root ([string]$contract.evidenceRoot)))
Assert-C28FMatrix ($evidenceRoot.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) 'evidence root escaped repository'
if ($matrixState -ceq 'device_gate_rejected') {
  Assert-C28FMatrix ($capturedStates.Count -ge 1) 'rejected state lacks truthful first-gate evidence'
} else {
  $capturedIds = @($capturedStates | ForEach-Object { [string]$_.id })
  Assert-C28FMatrix ($capturedStates.Count -eq 28 -and $capturedIds.Count -eq @($capturedIds | Select-Object -Unique).Count -and -not (Compare-Object $expectedStateIds $capturedIds)) 'captured matrix is incomplete or duplicated'
}

$boundsGate = Resolve-C28FMatrixFile ([string]$contract.reusedOwners.boundsGate)
$matrixDigestRecords = @()
foreach ($state in $capturedStates) {
  $stateId = [string]$state.id
  Assert-C28FMatrix ($plannedStateIds -ccontains $stateId) "captured state is not planned: $stateId"
  $pngPath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.png)))
  $xmlPath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.xml)))
  $readyOnePath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.readyOneXml)))
  $readyTwoPath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.readyTwoXml)))
  foreach ($path in @($pngPath,$xmlPath,$readyOnePath,$readyTwoPath)) {
    Assert-C28FMatrix ($path.StartsWith($evidenceRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $path -PathType Leaf)) "state evidence missing or escaped root: $stateId"
  }
  Assert-C28FMatrix ((Get-Item -LiteralPath $pngPath).Length -ge 1024) "screenshot implausibly small: $stateId"
  $pngSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $pngPath).Hash
  Assert-C28FMatrix ($pngSha -ceq [string]$state.pngSha256) "screenshot checksum changed: $stateId"
  $raw = Get-Content -Raw -LiteralPath $xmlPath
  foreach ($semantic in @($state.requiredSemantics)) {
    Assert-C28FMatrix ($raw.Contains([string]$semantic)) "required semantic absent for ${stateId}: $semantic"
  }
  Assert-C28FMatrix ($state.PSObject.Properties['forbiddenSemantics'] -and @($state.forbiddenSemantics).Count -gt 0) "forbidden semantic contract missing: $stateId"
  foreach ($semantic in @($state.forbiddenSemantics)) {
    Assert-C28FMatrix (-not $raw.Contains([string]$semantic)) "forbidden semantic present for ${stateId}: $semantic"
  }
  $familyId = [string]$state.railFamilyId
  if (-not [string]::IsNullOrWhiteSpace($familyId)) {
    $family = @($families | Where-Object { [string]$_.id -ceq $familyId })
    Assert-C28FMatrix ($family.Count -eq 1) "unknown rail family: $familyId"
    & $boundsGate -RepositoryRoot $root -XmlPath $xmlPath -DensityDpi ([int]$contract.candidate.densityDpi)
    $actionId = [string]$state.actionId
    if (-not [string]::IsNullOrWhiteSpace($actionId)) {
      $action = @($family[0].actions | Where-Object { [string]$_.id -ceq $actionId })
      Assert-C28FMatrix ($action.Count -eq 1) "unknown family action: $familyId/$actionId"
      $contentFound = $false
      foreach ($semantic in @($action[0].contentAnyOf)) { if ($raw.Contains([string]$semantic)) { $contentFound = $true } }
      Assert-C28FMatrix $contentFound "content reachability absent for $familyId/$actionId"
    }
  }
  if ([bool]$state.switcherOpen) {
    Assert-C28FMatrix ($raw.Contains([string]$contract.switcher.containerSemantic) -and $raw.Contains([string]$contract.switcher.closeSemantic)) "switcher shell absent: $stateId"
    [xml]$hierarchy = $raw
    $lastTop = -1
    foreach ($row in $switcherRows) {
      $semantics = @("Open $row", "$row, current domain")
      $nodes = @($hierarchy.SelectNodes('//node') | Where-Object { $semantics -ccontains [string]$_.GetAttribute('content-desc') })
      Assert-C28FMatrix ($nodes.Count -eq 1) "switcher row missing or duplicated: $row"
      $bounds = [string]$nodes[0].GetAttribute('bounds')
      Assert-C28FMatrix ($bounds -match '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') "switcher row bounds invalid: $row"
      $top = [int]$Matches[2]; $bottom = [int]$Matches[4]
      $logicalHeight = ($bottom - $top) / ([double]$contract.candidate.densityDpi / 160)
      Assert-C28FMatrix ($logicalHeight -ge 44) "switcher row below 44 logical pixels: $row"
      Assert-C28FMatrix ($top -gt $lastTop) "switcher row order changed: $row"
      $lastTop = $top
    }
  }
  $matrixDigestRecords += "$stateId|$pngSha"
}

$sha = [Security.Cryptography.SHA256]::Create()
try {
  $digest = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($matrixDigestRecords -join "`n")))).Replace('-', '')
} finally {
  $sha.Dispose()
}
Write-Output "C28F device matrix passed: state=$matrixState; captured=$($capturedStates.Count); digest=$digest"
