[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$contractPath = Join-Path $root 'config\mvp-personal-approved-navigation-device-matrix-c26h.json'
if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) { throw 'C26H device-matrix contract is missing.' }
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
if ([int]$contract.schemaVersion -ne 1 -or [string]$contract.contractId -cne 'MOOLSOCIAL-PERSONAL-APPROVED-NAVIGATION-DEVICE-MATRIX-C26H-001') {
  throw 'C26H device-matrix contract identity is invalid.'
}
if ([string]$contract.deviceSerial -cne '2b3e0f71' -or [string]$contract.installedApkSha256 -cne '21C7AE3B58C9FA7C662E768FC20662228FF45DE79C4148CDC341B4DB17CB60C8') {
  throw 'C26H device or installed-candidate identity changed.'
}
$requiredIds = @(
  'social-shorts','social-videos','social-feed','social-create-ime-visible','social-create-ime-back','switcher-social-create',
  'shop-products','shop-wholesale','shop-orders','food-order-food','food-book-table',
  'travel-bike','travel-auto','travel-cab','travel-bus',
  'care-doctor','care-medicine','switcher-care-medicine','care-medicine-after-switcher-back','care-salon',
  'work-earn-today','work-workspace','chat-from-work-workspace','work-workspace-after-chat-back',
  'switcher-open-by-swipe-up','workspace-after-swipe-down','switcher-before-outside-tap','workspace-after-outside-tap',
  'social-after-six-family-cycle'
)
$states = @($contract.states)
$ids = @($states | ForEach-Object { [string]$_.id })
if ($states.Count -ne 29 -or $ids.Count -ne @($ids | Select-Object -Unique).Count -or (Compare-Object $requiredIds $ids)) {
  throw 'C26H device-matrix state inventory is incomplete, duplicated or changed.'
}
$evidenceRoot = [IO.Path]::GetFullPath((Join-Path $root ([string]$contract.evidenceRoot)))
if (-not $evidenceRoot.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw 'C26H evidence root escapes the repository.' }
foreach ($state in $states) {
  $pngPath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.png)))
  $xmlPath = [IO.Path]::GetFullPath((Join-Path $evidenceRoot ([string]$state.xml)))
  foreach ($path in @($pngPath, $xmlPath)) {
    if (-not $path.StartsWith($evidenceRoot, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "C26H matrix evidence is missing or outside its root: $path"
    }
  }
  if ((Get-Item -LiteralPath $pngPath).Length -lt 1024) { throw "C26H screenshot is implausibly small: $($state.id)" }
  $actualSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $pngPath).Hash
  if ($actualSha -cne [string]$state.sha256) { throw "C26H screenshot checksum changed: $($state.id)" }
  [xml]$hierarchy = Get-Content -Raw -LiteralPath $xmlPath
  $raw = Get-Content -Raw -LiteralPath $xmlPath
  $selected = @($hierarchy.SelectNodes('//node[@selected="true"]') | ForEach-Object {
    if (-not [string]::IsNullOrWhiteSpace([string]$_.'content-desc')) { [string]$_.'content-desc' } else { [string]$_.text }
  })
  foreach ($expected in @($state.selected)) {
    if ($selected -cnotcontains [string]$expected) { throw "C26H selected state is absent for $($state.id): $expected" }
  }
  foreach ($semantic in @($state.semantics)) {
    if (-not $raw.Contains([string]$semantic)) { throw "C26H semantic is absent for $($state.id): $semantic" }
  }
  $stem = [IO.Path]::GetFileNameWithoutExtension($pngPath)
  foreach ($suffix in @('-ready-1.xml','-ready-2.xml')) {
    $readyPath = Join-Path $evidenceRoot "$stem$suffix"
    if (-not (Test-Path -LiteralPath $readyPath -PathType Leaf)) { throw "C26H stable readiness evidence is missing: $readyPath" }
  }
}
$journeys = @($contract.familyJourneys)
if ($journeys.Count -ne 6 -or @($journeys.family | Select-Object -Unique).Count -ne 6) { throw 'C26H six-family direct journey inventory changed.' }
foreach ($journey in $journeys) {
  $preTap = Join-Path $evidenceRoot ([string]$journey.preTapXml)
  if (-not (Test-Path -LiteralPath $preTap -PathType Leaf) -or -not (Get-Content -Raw -LiteralPath $preTap).Contains([string]$journey.openSemantic)) {
    throw "C26H direct family journey is unproven: $($journey.family)"
  }
  if ($ids -cnotcontains [string]$journey.resultState) { throw "C26H family journey result is not sealed: $($journey.family)" }
}
$matrixDigestSource = ($states | ForEach-Object { "{0}|{1}" -f $_.id,$_.sha256 }) -join "`n"
$digestBytes = [Text.Encoding]::UTF8.GetBytes($matrixDigestSource)
$matrixDigest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($digestBytes))
if ($matrixDigest -cne '0EC85E0A0BFE5DD3A118AC31DA369B6C07B4F7E0F53DD0FDD48E845143659ADA') {
  throw 'C26H cumulative matrix digest changed.'
}
$ticketPath = Join-Path $root 'config\uaw-personal-mvp-approved-navigation-oppo-qualification-fix9-c26h-ticket.json'
$parentPath = Join-Path $root 'config\uaw-personal-mvp-approved-html-embedded-navigation-shell-recovery-fix9-c26-ticket.json'
$scopePath = Join-Path $root 'config\mvp-scope-gate-state.json'
$apkStatePath = Join-Path $root 'config\apk-regression-gate-state.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$parent = Get-Content -Raw -LiteralPath $parentPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkStatePath | ConvertFrom-Json
$ticketHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
if ([string]$ticket.state -cne 'device_qualified_founder_review_pending' -or
    [string]$parent.state -cne 'c26a_through_c26h_device_qualified_founder_review_pending' -or
    [string]$scope.checkpoint.approvalState -cne 'c26a_through_c26h_device_qualified_founder_review_pending' -or
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -cne $ticketHash -or
    [string]$apk.machineState -cne 'c26h_r60_25_device_qualified_founder_review_pending' -or
    [string]$apk.founderDeviceReview.state -cne 'c26h_r60_25_device_qualified_founder_review_pending') {
  throw 'C26H device-qualified founder-review state is inconsistent.'
}
if (-not [bool]$ticket.execution.referenceWriteAuthorized -or
    [bool]$ticket.execution.runtimeSourceWriteAuthorized -or [bool]$ticket.execution.testOrGateWriteAuthorized -or
    [bool]$ticket.execution.buildAuthorized -or [bool]$ticket.execution.installAuthorized -or
    [bool]$ticket.execution.backendWriteAuthorized -or [bool]$ticket.execution.externalServiceWriteAuthorized -or
    [bool]$apk.buildResult.installAuthorized -or [bool]$apk.founderDeviceReview.successorBuildAuthorized -or
    [bool]$apk.founderDeviceReview.successorInstallAuthorized) {
  throw 'C26H mutation, build, install, backend or external authority is unexpectedly open.'
}
$reviewedFamilies = @($apk.founderDeviceReview.reviewedFamilies)
if ($reviewedFamilies.Count -ne 6 -or (Compare-Object @('Social','Shop','Food','Travel','Care','Work') $reviewedFamilies)) {
  throw 'C26H founder-review family inventory is incomplete.'
}
$postMatrixApk = Join-Path $evidenceRoot '77-installed-base-r60.25-post-matrix.apk'
if (-not (Test-Path -LiteralPath $postMatrixApk -PathType Leaf) -or
    (Get-FileHash -Algorithm SHA256 -LiteralPath $postMatrixApk).Hash -cne [string]$contract.installedApkSha256) {
  throw 'C26H post-matrix installed-base identity is missing or changed.'
}
Write-Output "C26H OPPO device matrix passed: states=$($states.Count); families=$($journeys.Count); digest=$matrixDigest"
