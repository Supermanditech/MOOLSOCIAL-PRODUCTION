[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$utf8Strict = [Text.UTF8Encoding]::new($false, $true)
$utf8NoBom = [Text.UTF8Encoding]::new($false)

function Assert-C32N([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C32N gate rejected: $Message" }
}

function Resolve-C32N([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C32N ($path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C32N (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Read-C32N([string]$RelativePath) {
  return [IO.File]::ReadAllText((Resolve-C32N $RelativePath))
}

function Get-C32NPortableSha256([string]$Path) {
  $bytes = [IO.File]::ReadAllBytes($Path)
  try {
    $text = $utf8Strict.GetString($bytes)
    $bytes = $utf8NoBom.GetBytes($text.Replace("`r`n", "`n"))
  } catch {
  }
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Get-C32NTreeSha256([string[]]$RelativeFiles, [string]$HistoricalJourneySha256) {
  $lines = foreach ($relative in $RelativeFiles) {
    $hash = Get-C32NPortableSha256 (Resolve-C32N $relative)
    if (-not [string]::IsNullOrWhiteSpace($HistoricalJourneySha256) -and $relative -ceq 'apps/mobile/lib/features/journey01/journey_router.dart') {
      $hash = $HistoricalJourneySha256
    }
    "$hash  $relative"
  }
  $payload = ($lines -join "`n") + "`n"
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($utf8NoBom.GetBytes($payload)))).Replace('-', '').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

$ticketPath = Resolve-C32N 'config/uaw-c32n-personal-mvp-buy-protected-shared-router-delta-attribution-hold-ticket.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Read-C32N 'config/mvp-scope-gate-state.json' | ConvertFrom-Json
$baseline = Read-C32N 'artifacts/quality/moolsocial-fsc06-shop-products-cell-disposition-20260810-01/BASELINE.json' | ConvertFrom-Json
$c25f = Read-C32N 'artifacts/quality/buy-protected-candidate-c25f-domain-navigation-20260809-01/BASELINE.json' | ConvertFrom-Json
$predecessorManifestPath = [string]$c25f.protectedRuntime.predecessorManifest
$predecessorManifest = Get-Content -LiteralPath (Resolve-C32N $predecessorManifestPath)
$c32mGate = Read-C32N 'scripts/check-uaw-c32m-chained-successor-gate-historical-scope-binding.ps1'
$c32mManifest = Read-C32N 'artifacts/quality/uaw-c32m-chained-successor-gate-historical-scope-binding-20260815-01/source-manifest-c32m.txt'

Assert-C32N ([string]$ticket.ticketId -ceq 'UAW-C32N-PERSONAL-MVP-BUY-PROTECTED-SHARED-ROUTER-DELTA-ATTRIBUTION-HOLD') 'ticket id changed'
Assert-C32N ([string]$ticket.classification -ceq 'mvp_supporting') 'ticket classification changed'
Assert-C32N ([bool]$ticket.authority.testAndGateWriteAuthorized) 'ticket test/gate authority closed'
Assert-C32N (-not [bool]$ticket.authority.runtimeSourceWriteAuthorized) 'ticket runtime authority opened'
Assert-C32N (-not [bool]$ticket.authority.backendSourceWriteAuthorized) 'ticket backend authority opened'
Assert-C32N (-not [bool]$ticket.authority.referenceWriteAuthorized) 'ticket reference authority opened'
Assert-C32N (-not [bool]$ticket.authority.baselineReplacementAuthorized) 'ticket baseline replacement authority opened'
Assert-C32N (-not [bool]$ticket.authority.buildAuthorized) 'ticket build authority opened'
Assert-C32N (-not [bool]$ticket.authority.deviceMutationAuthorized) 'ticket device authority opened'
Assert-C32N (-not [bool]$ticket.authority.externalCommunicationAuthorized) 'ticket communication authority opened'

$selected = $scope.preTicketSelectionCheckpoint.selectedTicketAssessment
$activeScope = [string]$scope.ticket.id -ceq [string]$ticket.ticketId
if ($activeScope) {
  Assert-C32N ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq [string]$ticket.ticketId) 'pre-ticket current ticket differs'
  Assert-C32N ([string]$selected.ticketId -ceq [string]$ticket.ticketId) 'selected assessment ticket differs'
  Assert-C32N ([string]$selected.manifestSha256 -ceq '258F5A287EEF5A2FF6F44294EBC4303184CF5EF7C1A4BB8E7D6A883547FCA526') 'selected ticket manifest hash differs'
  Assert-C32N ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$selected.manifestSha256) 'selected ticket bytes differ'
} else {
  $priorC32N = $scope.preTicketSelectionCheckpoint.priorC32NBlockedTicketAssessment
  Assert-C32N ($null -ne $priorC32N) 'preserved prior C32N assessment missing'
  Assert-C32N ([string]$priorC32N.ticketId -ceq [string]$ticket.ticketId) 'preserved prior C32N ticket differs'
  Assert-C32N ([string]$priorC32N.manifestSha256 -ceq '258F5A287EEF5A2FF6F44294EBC4303184CF5EF7C1A4BB8E7D6A883547FCA526') 'preserved prior C32N manifest hash differs'
  Assert-C32N ([string]$priorC32N.implementationState -ceq 'source_gate_attribution_implemented_initial_cycle_blocked_only_at_stale_Buy_router_launcher_test_protected_baseline_hold_preserved') 'preserved prior C32N implementation state differs'
  Assert-C32N ((Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq [string]$priorC32N.manifestSha256) 'preserved prior C32N ticket bytes differ'
}

$priorC32M = $scope.preTicketSelectionCheckpoint.priorC32MFocusedTicketAssessment
Assert-C32N ($null -ne $priorC32M) 'prior C32M assessment missing'
Assert-C32N ([string]$priorC32M.ticketId -ceq 'UAW-C32M-PERSONAL-MVP-CHAINED-SUCCESSOR-GATE-HISTORICAL-SCOPE-BINDING') 'prior C32M ticket differs'
Assert-C32N ([string]$priorC32M.manifestSha256 -ceq '8881FE40683A31FAE3C7EE3B87D85294E3FBC66F2C86E7DFB263D3C1BD71658A') 'prior C32M manifest hash differs'
Assert-C32N ([string]$priorC32M.implementationState -ceq 'source_gate_chain_repair_implemented_two_focused_cycles_passed_full_preflight_Buy_protected_baseline_hold_no_qualification_claim') 'prior C32M state differs'
Assert-C32N ($c32mGate.Contains('priorC32MFocusedTicketAssessment')) 'C32M historical scope property is not enforced'
Assert-C32N ($c32mGate.Contains('8881FE40683A31FAE3C7EE3B87D85294E3FBC66F2C86E7DFB263D3C1BD71658A')) 'C32M historical manifest hash is not enforced'
Assert-C32N ($c32mGate.Contains('scopeBinding=')) 'C32M lifecycle pass identity is missing'
Assert-C32N (-not $c32mGate.Contains('active=C32M')) 'C32M pass identity still claims permanent active scope'
Assert-C32N ($c32mManifest.Contains('F206A95FA9A77E4715C1A0D2249F6FEC206962747CC6B5447B2788C610EA0AA3')) 'C32M focused source fingerprint evidence differs'

Assert-C32N ([int]$baseline.protectedRuntime.fileCount -eq 43) 'FSC06 file count changed'
Assert-C32N ([string]$baseline.protectedRuntime.portableTreeSha256 -ceq '6e2c18af399d8c2e0a3ab8cb63d76d5e32228f2ea69d26f0d1df662c3f3bbd8e') 'FSC06 tree hash changed'
Assert-C32N ([string]$predecessorManifestPath -ceq 'artifacts/quality/buy-protected-candidate-c24f-connected-back-20260809-02/RUNTIME-MANIFEST.txt') 'declared predecessor manifest path changed'

$parsedRows = foreach ($line in $predecessorManifest) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $parts = $line -split '  ', 2
  Assert-C32N ($parts.Count -eq 2) "malformed predecessor manifest row: $line"
  [pscustomobject]@{ digest = [string]$parts[0]; path = [string]$parts[1] }
}
$malformedRows = @($parsedRows | Where-Object { $_.digest -notmatch '^[0-9a-f]{64}$' })
Assert-C32N ($parsedRows.Count -eq 43) 'predecessor manifest row count changed'
Assert-C32N ($malformedRows.Count -eq 1) 'known malformed predecessor row count changed'
Assert-C32N ([string]$malformedRows[0].path -ceq 'apps/mobile/lib/features/buy/buy_v2_saved_products_store.dart') 'known malformed predecessor row owner changed'
Assert-C32N ([string]$malformedRows[0].digest -ceq '044da1e06b33bbad7d0c31f725ee6c41fe9e563f6c6f5006079bbb06b7ed94') 'known shortened digest changed'

$journeyRow = @($parsedRows | Where-Object { $_.path -ceq 'apps/mobile/lib/features/journey01/journey_router.dart' })
Assert-C32N ($journeyRow.Count -eq 1) 'historical journey-router row differs'
$historicalJourneySha256 = [string]$journeyRow[0].digest
Assert-C32N ($historicalJourneySha256 -ceq 'a98bc91ffaff2d5205e14d258097650d2de7e2a67c214c51ca00ebb312a71429') 'historical journey-router hash changed'

$files = @()
foreach ($relativeRoot in @('apps/mobile/lib/features/buy', 'apps/mobile/lib/ui_v2/buy')) {
  $absoluteRoot = [IO.Path]::GetFullPath((Join-Path $root $relativeRoot))
  Assert-C32N ($absoluteRoot.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) "protected root escaped repository: $relativeRoot"
  Assert-C32N (Test-Path -LiteralPath $absoluteRoot -PathType Container) "protected root missing: $relativeRoot"
  $files += Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File
}
foreach ($relative in @(
  'apps/mobile/lib/features/journey01/journey_router.dart',
  'apps/mobile/assets/prototype/moolsocial-category-media-atlas-v3a-2026.png',
  'apps/mobile/assets/prototype/moolsocial-category-media-atlas-v3b-2026.png',
  'apps/mobile/assets/prototype/moolsocial-category-media-atlas-v3c-2026.png',
  'apps/mobile/assets/prototype/moolsocial-medicine-media-atlas-v3d-2026.png',
  'apps/mobile/assets/prototype/moolsocial-product-packshot-atlas-v2-2026.png'
)) {
  $files += Get-Item -LiteralPath (Resolve-C32N $relative)
}
$relativeFiles = @($files | ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } | Sort-Object -Unique)
Assert-C32N ($relativeFiles.Count -eq 43) 'current protected inventory changed'

$currentTree = Get-C32NTreeSha256 $relativeFiles ''
$reconstructedFsc06Tree = Get-C32NTreeSha256 $relativeFiles $historicalJourneySha256
$currentJourneySha256 = Get-C32NPortableSha256 (Resolve-C32N 'apps/mobile/lib/features/journey01/journey_router.dart')
Assert-C32N ($currentTree -ceq '12a9880a51c172f060133a90bcffc38d84f68959ff1caf88e13be43e86631bc5') 'current protected tree changed'
Assert-C32N ($currentJourneySha256 -ceq '758eb64038abc04e6e85a4bf053c2148f180d93964c998165d4cbf6744f2319f') 'current journey-router hash changed'
Assert-C32N ($reconstructedFsc06Tree -ceq [string]$baseline.protectedRuntime.portableTreeSha256) 'single-router substitution no longer reconstructs FSC06'

Assert-C32N ([bool]$scope.execution.testOrGateWriteAuthorized) 'scope test/gate authority closed'
Assert-C32N (-not [bool]$scope.execution.referenceWriteAuthorized) 'scope reference authority opened'
Assert-C32N (-not [bool]$scope.execution.runtimeWriteAuthorized) 'scope runtime authority opened'
Assert-C32N (-not [bool]$scope.execution.backendWriteAuthorized) 'scope backend authority opened'
Assert-C32N (-not [bool]$scope.execution.buildAuthorized) 'scope build authority opened'
Assert-C32N (-not [bool]$scope.execution.deviceInstallAuthorized) 'scope device authority opened'
Assert-C32N (-not [bool]$scope.execution.externalServiceWriteAuthorized) 'scope external authority opened'
Assert-C32N (-not [bool]$scope.execution.secretValueAccessAuthorized) 'scope secret authority opened'
Assert-C32N (-not [bool]$scope.protectedCandidateState.protectedBaselineUpdated) 'protected baseline was changed'
Assert-C32N ([bool]$scope.protectedCandidateState.founderAcceptancePending) 'protected founder hold was removed'

Write-Output "C32N Buy protected delta attribution gate passed: scopeBinding=$(if ($activeScope) { 'active' } else { 'preservedPrior' }); files=43; changedOwner=journey_router.dart; reconstructedFSC06=true; BuyBusinessOwnersChanged=false; baselineUpdate=false."
