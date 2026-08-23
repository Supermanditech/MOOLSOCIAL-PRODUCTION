[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C29R([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C29R source gate rejected: $Message" }
}

function Resolve-C29RFile([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C29R ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "owner escaped repository: $RelativePath"
  Assert-C29R (Test-Path -LiteralPath $path -PathType Leaf) "owner missing: $RelativePath"
  return $path
}

function Get-C29RContent([string]$RelativePath) {
  return Get-Content -Raw -LiteralPath (Resolve-C29RFile $RelativePath)
}

function Assert-C29RContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29RContent $RelativePath
  Assert-C29R ($content.Contains($Text, [StringComparison]::Ordinal)) "required contract missing from $RelativePath`: $Text"
}

function Assert-C29RNotContains([string]$RelativePath, [string]$Text) {
  $content = Get-C29RContent $RelativePath
  Assert-C29R (-not $content.Contains($Text, [StringComparison]::OrdinalIgnoreCase)) "forbidden contract found in $RelativePath`: $Text"
}

$expectedTicket = 'UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-QUOTA-PURPOSE-AND-CATALOGUE-REFRESH-C29R'
$ticketPath = Resolve-C29RFile 'config/uaw-personal-mvp-social-youtube-quota-purpose-catalogue-refresh-c29r-ticket.json'
$scopePath = Resolve-C29RFile 'config/mvp-scope-gate-state.json'
$apkPath = Resolve-C29RFile 'config/apk-regression-gate-state-c29k.json'
$evidencePath = Resolve-C29RFile 'config/uaw-personal-mvp-social-youtube-quota-purpose-c29r-evidence.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$apk = Get-Content -Raw -LiteralPath $apkPath | ConvertFrom-Json
$evidence = Get-Content -Raw -LiteralPath $evidencePath | ConvertFrom-Json
$ticketSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash
$inheritedCustomerCopyPath = Resolve-C29RFile 'apps/mobile/test/ui_v2_customer_copy_machine_gate_test.dart'
$inheritedCustomerCopySha = (Get-FileHash -Algorithm SHA256 -LiteralPath $inheritedCustomerCopyPath).Hash

Assert-C29R ([string]$ticket.ticketId -ceq $expectedTicket) 'ticket identity changed'
Assert-C29R ([string]$ticket.state -cin @('selected_source_implementation_authorized', 'source_qualified_external_dev_measurement_and_oppo_pending')) 'ticket state is not source-only'
Assert-C29R ([string]$ticket.classification -ceq 'mvp_required') 'MVP classification changed'
Assert-C29R ([string]$scope.ticket.id -ceq $expectedTicket) 'active scope ticket differs'
Assert-C29R ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
Assert-C29R ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $ticketSha) 'ticket manifest seal changed'
Assert-C29R ($inheritedCustomerCopySha -ceq '8BB8D600D9072C69543D38B8FC20868DA7F352CFB554D5891E624BF997351CF9') 'inherited shared customer-copy owner changed during C29R'
Assert-C29R ([bool]$scope.execution.runtimeWriteAuthorized) 'runtime source authority is closed'
Assert-C29R ([bool]$scope.execution.testOrGateWriteAuthorized) 'test authority is closed'
Assert-C29R ([bool]$scope.execution.backendWriteAuthorized) 'backend source authority is closed'

foreach ($closed in @(
  [bool]$scope.execution.referenceWriteAuthorized,
  [bool]$scope.execution.buildAuthorized,
  [bool]$scope.execution.deviceInstallAuthorized,
  [bool]$scope.execution.externalServiceWriteAuthorized,
  [bool]$scope.execution.secretValueAccessAuthorized,
  [bool]$ticket.execution.externalDevQualificationAuthorized,
  [bool]$ticket.execution.buildAuthorized,
  [bool]$ticket.execution.installAuthorized,
  [bool]$ticket.execution.deployAuthorized,
  [bool]$ticket.execution.productionWriteAuthorized,
  [bool]$ticket.execution.providerMessageAuthorized,
  [bool]$ticket.execution.secretValueAccessAuthorized,
  [bool]$ticket.execution.referenceWriteAuthorized
)) {
  Assert-C29R (-not $closed) 'build/install/deploy/external/secret/reference authority opened'
}

Assert-C29R ([string]$apk.machineState -ceq 'device_qualified_founder_review_pending') 'protected C29K machine state changed'
Assert-C29R ([string]$apk.installResult.deviceSerial -ceq '2b3e0f71') 'protected OPPO serial changed'
Assert-C29R ([string]$apk.installResult.versionName -ceq '1.0.0-r60.34') 'protected installed version name changed'
Assert-C29R ([string]$apk.installResult.versionCode -ceq '2026081134') 'protected installed version code changed'
Assert-C29R ([string]$apk.installResult.installedApkSha256 -ceq '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29') 'protected installed APK checksum changed'
Assert-C29R (-not [bool]$apk.installResult.uninstallPerformed) 'protected app was uninstalled'
Assert-C29R (-not [bool]$apk.installResult.dataClearPerformed) 'protected app data was cleared'
Assert-C29R (-not [bool]$apk.installResult.downgradePerformed) 'protected app was downgraded'

$shared = 'backend/functions/src/youtube/shared_catalogue.ts'
$client = 'backend/functions/src/youtube/client.ts'
$quota = 'backend/functions/src/youtube/firestore_store.ts'
$index = 'backend/functions/src/index.ts'
$mobileClient = 'apps/mobile/lib/core/youtube/youtube_private_dev_client.dart'
$runtime = 'apps/mobile/lib/ui_v2/social/social_v2_youtube_public_runtime.dart'

foreach ($literal in @(
  'const SNAPSHOT_TTL_MS = 30 * 60 * 1000;',
  'const REFRESH_LEASE_MS = 2 * 60 * 1000;',
  'const STALE_FALLBACK_MS = 6 * 60 * 60 * 1000;',
  'const TARGET_ITEMS = 20;',
  'const MAXIMUM_PAGES = 4;',
  '"cache_hit"',
  '"refresh_success"',
  '"stale_fallback"',
  '"refresh_error"',
  '"lease_contended"',
  'video.availability.regionCode.toUpperCase() === INDIA_REGION_CODE',
  'creatorDeclaredShort(video)'
)) { Assert-C29RContains $shared $literal }

Assert-C29RContains $client '"search.list.explicit"'
Assert-C29RContains $client '"search.list.sharedShortsRefresh"'
Assert-C29RContains $client '"shared-shorts-catalogue"'
Assert-C29RContains $quota 'youtubeProviderQuotaMeasurements'
Assert-C29RContains $quota 'acceptedLocalReservations'
Assert-C29RNotContains $quota 'acceptedUnits'
Assert-C29RContains $index 'case "publicShortsCatalogue":'
Assert-C29RContains $index 'new FirestoreSharedShortsCatalogueStore(persistence.database)'
Assert-C29RContains $mobileClient "_invoke('publicShortsCatalogue')"

$runtimeContent = Get-C29RContent $runtime
$loaderStart = $runtimeContent.IndexOf('loadScreen04YouTubePublicShorts()', [StringComparison]::Ordinal)
$loaderEnd = $runtimeContent.IndexOf('bool _isEligiblePublicVideo', $loaderStart, [StringComparison]::Ordinal)
Assert-C29R ($loaderStart -ge 0 -and $loaderEnd -gt $loaderStart) 'automatic Shorts loader boundary is missing'
$loader = $runtimeContent.Substring($loaderStart, $loaderEnd - $loaderStart)
Assert-C29R ($loader.Contains('client.sharedShortsCatalogue()', [StringComparison]::Ordinal)) 'automatic Shorts loader does not use the shared catalogue'
Assert-C29R (-not $loader.Contains('client.search(', [StringComparison]::Ordinal)) 'automatic Shorts loader still uses explicit search'

Assert-C29R ([string]$evidence.ticketId -ceq $expectedTicket) 'quota-purpose evidence ticket differs'
Assert-C29R ([string]$evidence.state -ceq 'source_implemented_representative_dev_measurement_pending') 'evidence falsely claims provider measurement'
Assert-C29R ([string]$evidence.externalGate.representativeDevMeasurementWindow -ceq 'pending_separate_authority') 'representative Dev measurement gate changed'
Assert-C29R ([string]$evidence.externalGate.quotaOrComplianceSubmission -ceq 'not_submitted') 'quota/compliance submission was claimed'
Assert-C29R ([string]$evidence.externalGate.providerMessage -ceq 'not_sent') 'provider message was claimed'
Assert-C29R ([string]$evidence.externalGate.credentialAccess -ceq 'not_performed') 'credential access was claimed'

foreach ($owner in @($shared, $runtime, $evidencePath)) {
  $relative = if ($owner -is [string] -and [IO.Path]::IsPathRooted($owner)) { [IO.Path]::GetRelativePath($root, $owner) } else { [string]$owner }
  Assert-C29RNotContains $relative 'watchHistory'
  Assert-C29RNotContains $relative 'personalized recommender'
  Assert-C29RNotContains $relative 'engagement incentive enabled'
}

Write-Output 'C29R source gate passed: automatic Shorts uses a durable shared 30-minute catalogue, explicit search remains separate, quota and cache outcomes are measured without user history, provider measurement/submission remains pending, and r60.34 is protected.'
