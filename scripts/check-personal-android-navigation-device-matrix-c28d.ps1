[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$contractPath = Join-Path $root 'config\mvp-personal-android-navigation-device-matrix-c28d.json'
$expectedContractSha256 = 'DD9FF27C9E87B5DB2411C6BA7CD951FE6ADFA6A50CE3E5E1B12AFFFB5BFA74F3'

function Assert-C28DMatrix([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C28D matrix gate rejected: $Message" }
}

function Resolve-C28DMatrixFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C28DMatrix ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C28DMatrix (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

Assert-C28DMatrix (Test-Path -LiteralPath $contractPath -PathType Leaf) 'contract is missing'
Assert-C28DMatrix ((Get-FileHash -Algorithm SHA256 -LiteralPath $contractPath).Hash -ceq $expectedContractSha256) 'contract checksum changed'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
Assert-C28DMatrix ([int]$contract.schemaVersion -eq 1) 'schema changed'
Assert-C28DMatrix ([string]$contract.contractId -ceq 'MOOLSOCIAL-PERSONAL-ANDROID-NAVIGATION-DEVICE-MATRIX-C28D-001') 'contract id changed'
Assert-C28DMatrix ([string]$contract.ticketId -ceq 'UAW-PERSONAL-MVP-ANDROID-NAVIGATION-OPPO-QUALIFICATION-FIX11-C28D') 'ticket changed'
Assert-C28DMatrix ([string]$contract.candidate.versionName -ceq '1.0.0-r60.27') 'version name changed'
Assert-C28DMatrix ([string]$contract.candidate.versionCode -ceq '2026081027') 'version code changed'
Assert-C28DMatrix ([string]$contract.candidate.deviceSerial -ceq '2b3e0f71') 'device serial changed'
Assert-C28DMatrix ([string]$contract.candidate.deviceModel -ceq 'CPH2375') 'device model changed'
Assert-C28DMatrix ([int]$contract.candidate.densityDpi -eq 320) 'density changed'
Assert-C28DMatrix ([double]$contract.candidate.minimumLogicalTarget -eq 44) 'minimum target changed'

$ownerProperties = @($contract.reusedOwners.PSObject.Properties)
Assert-C28DMatrix ($ownerProperties.Count -eq 4) 'reused owner inventory changed'
foreach ($property in $ownerProperties) { [void](Resolve-C28DMatrixFile ([string]$property.Value)) }

$families = @($contract.families)
$expectedFamilyIds = @('social','buy','eat','ride','book','work')
$familyIds = @($families | ForEach-Object { [string]$_.id })
Assert-C28DMatrix ($families.Count -eq 6 -and -not (Compare-Object $expectedFamilyIds $familyIds)) 'six-family inventory changed'
$actions = @($families | ForEach-Object { @($_.actions) })
$actionIds = @($actions | ForEach-Object { [string]$_.id })
$actionLabels = @($actions | ForEach-Object { [string]$_.label })
Assert-C28DMatrix ($actions.Count -eq 18) '18-action inventory changed'
Assert-C28DMatrix ($actionIds.Count -eq @($actionIds | Select-Object -Unique).Count) 'action ids are duplicated'
Assert-C28DMatrix ($actionLabels.Count -eq @($actionLabels | Select-Object -Unique).Count) 'action labels are duplicated'
foreach ($family in $families) {
  Assert-C28DMatrix (-not [string]::IsNullOrWhiteSpace([string]$family.familyRootSemantic)) "family root semantic missing: $($family.id)"
  foreach ($action in @($family.actions)) {
    Assert-C28DMatrix (-not [string]::IsNullOrWhiteSpace([string]$action.selectedSemantic)) "selected semantic missing: $($action.id)"
    Assert-C28DMatrix (@($action.contentAnyOf).Count -gt 0) "content reachability missing: $($action.id)"
  }
}

$expectedStateIds = @(
  'social-shorts','social-videos','social-feed','social-create-ime-visible','social-create-ime-back','switcher-social-create',
  'shop-products','shop-wholesale','shop-orders','food-order-food','food-book-table',
  'travel-bike','travel-auto','travel-cab','travel-bus',
  'care-doctor','care-medicine','switcher-care-medicine','care-medicine-after-switcher-back','care-salon',
  'work-earn-today','work-workspace','chat-from-work-workspace','work-workspace-after-chat-back',
  'switcher-open-by-swipe-up','workspace-after-swipe-down','switcher-before-outside-tap','workspace-after-outside-tap',
  'social-after-six-family-cycle'
)
$plannedStateIds = @($contract.plannedStateIds | ForEach-Object { [string]$_ })
Assert-C28DMatrix ($plannedStateIds.Count -eq 29 -and $plannedStateIds.Count -eq @($plannedStateIds | Select-Object -Unique).Count -and -not (Compare-Object $expectedStateIds $plannedStateIds)) '29-state plan changed'
Assert-C28DMatrix (@($contract.continuityRequirements).Count -eq 7) 'continuity plan changed'
$switcherRows = @($contract.switcher.rows | ForEach-Object { [string]$_ })
Assert-C28DMatrix ($switcherRows.Count -eq 6 -and -not (Compare-Object @('Social','Shop','Food','Travel','Care','Work') $switcherRows)) 'switcher rows changed'
Assert-C28DMatrix ([double]$contract.switcher.rowHeightLogical -ge 44) 'switcher row height fell below 44'

$ticketPath = Resolve-C28DMatrixFile 'config/uaw-personal-mvp-android-navigation-oppo-qualification-fix11-c28d-ticket.json'
$scopePath = Resolve-C28DMatrixFile 'config/mvp-scope-gate-state.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
Assert-C28DMatrix ([string]$scope.ticket.id -ceq [string]$contract.ticketId) 'scope ticket changed'
Assert-C28DMatrix ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$contract.ticketId) 'selected ticket changed'
Assert-C28DMatrix ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash) 'ticket seal changed'
Assert-C28DMatrix ([string]$ticket.state -cin @('active_prebuild_gates_only','active_build_authorized','active_install_authorized','device_qualified_founder_review_pending','device_gate_rejected_successor_required')) 'ticket state is unsupported'

$matrixState = [string]$contract.state
Assert-C28DMatrix ($matrixState -cin @('planned_prebuild','captured_founder_review_pending','device_gate_rejected')) 'matrix state is unsupported'
$capturedStates = @($contract.capturedStates)
if ($matrixState -ceq 'planned_prebuild') {
  Assert-C28DMatrix ($capturedStates.Count -eq 0) 'planned contract already contains captured evidence'
  Write-Output 'C28D planned device matrix passed: families=6; actions=18; states=29; boundsGate=required; build/install authority not inferred.'
  return
}

$evidenceRoot = [IO.Path]::GetFullPath((Join-Path $root ([string]$contract.evidenceRoot)))
Assert-C28DMatrix ($evidenceRoot.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) 'evidence root escaped repository'
if ($matrixState -ceq 'device_gate_rejected') {
  Assert-C28DMatrix ($capturedStates.Count -ge 1) 'rejected state lacks truthful first-gate evidence'
} else {
  $capturedIds = @($capturedStates | ForEach-Object { [string]$_.id })
  Assert-C28DMatrix ($capturedStates.Count -eq 29 -and $capturedIds.Count -eq @($capturedIds | Select-Object -Unique).Count -and -not (Compare-Object $expectedStateIds $capturedIds)) 'captured matrix is incomplete or duplicated'
}

$boundsGate = Resolve-C28DMatrixFile ([string]$contract.reusedOwners.boundsGate)
$matrixDigestRecords = @()
foreach ($state in $capturedStates) {
  $stateId = [string]$state.id
  Assert-C28DMatrix ($plannedStateIds -ccontains $stateId) "captured state is not planned: $stateId"
  $pngPath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.png)))
  $xmlPath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.xml)))
  $readyOnePath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.readyOneXml)))
  $readyTwoPath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.readyTwoXml)))
  foreach ($path in @($pngPath,$xmlPath,$readyOnePath,$readyTwoPath)) {
    Assert-C28DMatrix ($path.StartsWith($evidenceRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $path -PathType Leaf)) "state evidence missing or escaped root: $stateId"
  }
  Assert-C28DMatrix ((Get-Item -LiteralPath $pngPath).Length -ge 1024) "screenshot implausibly small: $stateId"
  $pngSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $pngPath).Hash
  Assert-C28DMatrix ($pngSha -ceq [string]$state.pngSha256) "screenshot checksum changed: $stateId"
  $raw = Get-Content -Raw -LiteralPath $xmlPath
  foreach ($semantic in @($state.requiredSemantics)) {
    Assert-C28DMatrix ($raw.Contains([string]$semantic)) "required semantic absent for ${stateId}: $semantic"
  }
  $familyId = [string]$state.railFamilyId
  if (-not [string]::IsNullOrWhiteSpace($familyId)) {
    $family = @($families | Where-Object { [string]$_.id -ceq $familyId })
    Assert-C28DMatrix ($family.Count -eq 1) "unknown rail family: $familyId"
    & $boundsGate -RepositoryRoot $root -XmlPath $xmlPath -DensityDpi ([int]$contract.candidate.densityDpi)
    $actionId = [string]$state.actionId
    if (-not [string]::IsNullOrWhiteSpace($actionId)) {
      $action = @($family[0].actions | Where-Object { [string]$_.id -ceq $actionId })
      Assert-C28DMatrix ($action.Count -eq 1) "unknown family action: $familyId/$actionId"
      $contentFound = $false
      foreach ($semantic in @($action[0].contentAnyOf)) { if ($raw.Contains([string]$semantic)) { $contentFound = $true } }
      Assert-C28DMatrix $contentFound "content reachability absent for $familyId/$actionId"
    }
  }
  if ([bool]$state.switcherOpen) {
    Assert-C28DMatrix ($raw.Contains([string]$contract.switcher.containerSemantic) -and $raw.Contains([string]$contract.switcher.closeSemantic)) "switcher shell absent: $stateId"
    [xml]$hierarchy = $raw
    $lastTop = -1
    foreach ($row in $switcherRows) {
      $semantics = @("Open $row", "$row, current domain")
      $nodes = @($hierarchy.SelectNodes('//node') | Where-Object { $semantics -ccontains [string]$_.'content-desc' })
      Assert-C28DMatrix ($nodes.Count -eq 1) "switcher row missing or duplicated: $row"
      $bounds = [string]$nodes[0].bounds
      Assert-C28DMatrix ($bounds -match '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') "switcher row bounds invalid: $row"
      $top = [int]$Matches[2]; $bottom = [int]$Matches[4]
      $logicalHeight = ($bottom - $top) / ([double]$contract.candidate.densityDpi / 160)
      Assert-C28DMatrix ($logicalHeight -ge 44) "switcher row below 44 logical pixels: $row"
      Assert-C28DMatrix ($top -gt $lastTop) "switcher row order changed: $row"
      $lastTop = $top
    }
  }
  $matrixDigestRecords += "$stateId|$pngSha"
}

$digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($matrixDigestRecords -join "`n"))))
Write-Output "C28D device matrix passed: state=$matrixState; captured=$($capturedStates.Count); digest=$digest"
