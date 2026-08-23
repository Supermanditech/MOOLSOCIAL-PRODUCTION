[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [Parameter(Mandatory = $true)]
  [ValidateSet(1, 2)]
  [int]$Cycle,
  [string]$EvidenceDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$mobileRoot = Join-Path $root 'apps\mobile'
if (-not $EvidenceDirectory) {
  $EvidenceDirectory = Join-Path $root 'artifacts\quality\uaw-personal-mvp-social-creator-ergonomics-global-edge-consistency-c29n-host-qualification-20260811-01'
}
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
$allowedEvidenceRoot = [IO.Path]::GetFullPath((Join-Path $root 'artifacts\quality'))
if (-not $evidenceRoot.StartsWith($allowedEvidenceRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'C29N evidence directory must remain inside artifacts/quality.'
}

$mobileTests = @(
  'test/ui_v2/social/uaw_personal_mvp_social_creator_ergonomics_global_edge_consistency_c29n_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_youtube_native_home_dock_c29e_test.dart',
  'test/social_v2_youtube_creator_upload_test.dart',
  'test/social_v2_create_publication_test.dart',
  'test/social_v2_youtube_connect_return_test.dart',
  'test/social_v2_youtube_public_runtime_test.dart',
  'test/social_v2_moolsocial_feed_ownership_test.dart',
  'test/screen04_universal_v2_conformance_test.dart',
  'test/ui_v2_social_customer_copy_gate_test.dart',
  'test/ui_v2_social_named_state_parity_test.dart',
  'test/ui_v2_social_continuous_batch_test.dart',
  'test/ui_v2_social_fitment_matrix_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_subaction_professional_conformance_c16b_test.dart',
  'test/ui_v2/universal/mool_compact_destination_rail_c25d_test.dart',
  'test/ui_v2/universal/mool_uniform_navigation_design_system_c27b_test.dart',
  'test/ui_v2/universal/mool_embedded_vertical_switcher_c26c_test.dart',
  'test/ui_v2/universal/mool_android_navigation_viewport_c28b_test.dart'
)

$sourceOwners = @(
  'scripts/check-personal-social-creator-ergonomics-global-edge-consistency-c29n.ps1',
  'scripts/qualify-personal-social-creator-ergonomics-global-edge-consistency-c29n.ps1',
  'scripts/check-codex-development-regression-memory.ps1',
  'scripts/check-mvp-delivery-discipline-lock.ps1',
  'scripts/check-mvp-scope-gate-state.ps1',
  'apps/mobile/lib/core/design/mool_design_system.dart',
  'apps/mobile/lib/features/shared/shared_session.dart',
  'apps/mobile/lib/features/shared/social_media_picker.dart',
  'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart',
  'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart',
  'apps/mobile/lib/ui_v2/social/social_v2_create_workbench.dart',
  'apps/mobile/lib/ui_v2/social/social_v2_youtube_creator_upload.dart'
)
foreach ($test in $mobileTests) { $sourceOwners += "apps/mobile/$test" }

function Get-C29NManifestRecords {
  $records = foreach ($relative in $sourceOwners) {
    $path = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "C29N source owner is missing or outside repository: $relative"
    }
    "$((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash)  $($relative.Replace('\', '/'))"
  }
  return @($records | Sort-Object)
}

function Get-C29NManifestSha([string[]]$Records) {
  $bytes = [Text.Encoding]::UTF8.GetBytes(($Records -join "`n"))
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return [Convert]::ToHexString($sha.ComputeHash($bytes)) } finally { $sha.Dispose() }
}

$cyclePath = Join-Path $evidenceRoot "qualifying-cycle-$Cycle.json"
if (Test-Path -LiteralPath $cyclePath) { throw "C29N refuses to overwrite existing evidence: $cyclePath" }
$manifestPath = Join-Path $evidenceRoot 'source-aggregate-manifest.txt'
$recordsBefore = Get-C29NManifestRecords
$manifestShaBefore = Get-C29NManifestSha $recordsBefore
if ($Cycle -eq 2) {
  $cycleOnePath = Join-Path $evidenceRoot 'qualifying-cycle-1.json'
  if (-not (Test-Path -LiteralPath $cycleOnePath -PathType Leaf) -or
      -not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'C29N cycle 2 requires cycle 1 and its immutable aggregate manifest.'
  }
  $cycleOne = Get-Content -Raw -LiteralPath $cycleOnePath | ConvertFrom-Json
  if ([string]$cycleOne.sourceManifestSha256 -cne $manifestShaBefore) {
    throw 'C29N cycle 2 source aggregate differs from cycle 1.'
  }
}

$timer = [Diagnostics.Stopwatch]::StartNew()
& (Join-Path $root 'scripts/check-personal-social-creator-ergonomics-global-edge-consistency-c29n.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -RepositoryRoot $root -Phase implementation -BuildMode none
& (Join-Path $root 'scripts/check-mvp-delivery-discipline-lock.ps1') -RepositoryRoot $root -RequireTicketSelectionAssessment
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -RepositoryRoot $root -RequireExecutionAuthorized

$formatOwners = @(
  'lib/ui_v2/universal/mool_global_navigation_v2.dart',
  'lib/ui_v2/social/social_v2_consumer.dart',
  'lib/ui_v2/social/social_v2_create_workbench.dart',
  'lib/ui_v2/social/social_v2_youtube_creator_upload.dart'
) + $mobileTests
Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @formatOwners
  if ($LASTEXITCODE -ne 0) { throw "C29N format check failed with exit $LASTEXITCODE." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C29N full Flutter analysis failed with exit $LASTEXITCODE." }
  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C29N required Flutter suite failed with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}
$timer.Stop()

$recordsAfter = Get-C29NManifestRecords
$manifestShaAfter = Get-C29NManifestSha $recordsAfter
if ($manifestShaAfter -cne $manifestShaBefore -or
    (($recordsAfter -join "`n") -cne ($recordsBefore -join "`n"))) {
  throw "C29N source changed during qualification: before=$manifestShaBefore after=$manifestShaAfter"
}

[IO.Directory]::CreateDirectory($evidenceRoot) | Out-Null
if ($Cycle -eq 1) {
  [IO.File]::WriteAllText($manifestPath, (($recordsAfter -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
} else {
  $retainedRecords = (Get-Content -Raw -LiteralPath $manifestPath).TrimEnd("`r", "`n") -split "`r?`n"
  if (($retainedRecords -join "`n") -cne ($recordsAfter -join "`n")) {
    throw 'C29N retained source manifest differs during cycle 2.'
  }
}

$evidence = [ordered]@{
  schemaVersion = 1
  ticketId = 'UAW-PERSONAL-MVP-SOCIAL-CREATOR-ERGONOMICS-AND-GLOBAL-EDGE-CONSISTENCY-C29N'
  cycle = $Cycle
  status = 'passed'
  wallSeconds = [Math]::Round($timer.Elapsed.TotalSeconds, 1)
  sourceManifest = 'artifacts/quality/uaw-personal-mvp-social-creator-ergonomics-global-edge-consistency-c29n-host-qualification-20260811-01/source-aggregate-manifest.txt'
  sourceManifestSha256 = $manifestShaAfter
  sourceFiles = $recordsAfter.Count
  sourceFingerprintBeforeAndAfterIdentical = $true
  ticketManifestSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'config/uaw-personal-mvp-social-creator-ergonomics-global-edge-consistency-c29n-ticket.json')).Hash
  scopeGateStateSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'config/mvp-scope-gate-state.json')).Hash
  regressionRegistrySha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'config/codex-development-regression-registry.json')).Hash
  protectedC29KMachineStateSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'config/apk-regression-gate-state-c29k.json')).Hash
  ticketSpecificGate = 'passed'
  regressionMemory = 'passed'
  mvpDeliveryAndScopeLocks = 'passed'
  globalApprovedUiLock = 'preexisting_dirty_owner_outside_c29n_manifest_not_resealed_or_waived'
  dartFormat = 'clean'
  flutterAnalysis = 'clean'
  requiredFlutterTestFiles = $mobileTests.Count
  requiredFlutterSuite = 'passed'
  protectedInstalledVersionName = '1.0.0-r60.34'
  protectedInstalledVersionCode = '2026081134'
  protectedInstalledApkSha256 = '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29'
  apkBuildPerformed = $false
  deviceMutationPerformed = $false
  backendMutationPerformed = $false
  providerMutationPerformed = $false
  secretValueAccessPerformed = $false
}
[IO.File]::WriteAllText($cyclePath, (($evidence | ConvertTo-Json -Depth 6) + "`n"), [Text.UTF8Encoding]::new($false))
$evidenceSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $cyclePath).Hash

Write-Output "C29N host cycle passed: cycle=$Cycle; sourceManifestSha256=$manifestShaAfter; sourceFiles=$($recordsAfter.Count); requiredFlutterTestFiles=$($mobileTests.Count); FlutterAnalysis=clean; r60.34Preserved=true; buildInstallBackendProviderSecretWrites=false; evidenceSha256=$evidenceSha."
