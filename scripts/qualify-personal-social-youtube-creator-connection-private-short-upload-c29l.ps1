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
$backendRoot = Join-Path $root 'backend\functions'
if (-not $EvidenceDirectory) {
  $EvidenceDirectory = Join-Path $root 'artifacts\quality\uaw-personal-mvp-social-youtube-creator-connection-private-short-upload-c29l-host-qualification-20260811-03'
}
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
$allowedEvidenceRoot = [IO.Path]::GetFullPath((Join-Path $root 'artifacts\quality'))
if (-not $evidenceRoot.StartsWith($allowedEvidenceRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'C29L evidence directory must remain inside artifacts/quality.'
}

$sourceOwners = @(
  'scripts/check-personal-social-youtube-creator-connection-private-short-upload-c29l.ps1',
  'scripts/qualify-personal-social-youtube-creator-connection-private-short-upload-c29l.ps1',
  'scripts/check-codex-development-regression-memory.ps1',
  'scripts/check-mvp-delivery-discipline-lock.ps1',
  'scripts/check-mvp-scope-gate-state.ps1',
  'apps/mobile/lib/core/youtube/youtube_private_dev_client.dart',
  'apps/mobile/lib/core/youtube/youtube_private_dev_models.dart',
  'apps/mobile/lib/core/youtube/youtube_private_dev_system_browser.dart',
  'apps/mobile/lib/core/youtube/youtube_private_dev_transport.dart',
  'apps/mobile/lib/core/youtube/youtube_private_dev_uploader.dart',
  'apps/mobile/lib/core/youtube/youtube_private_dev_workflow.dart',
  'apps/mobile/lib/features/shared/social_media_picker.dart',
  'apps/mobile/lib/features/journey01/journey_router.dart',
  'apps/mobile/lib/ui_v2/social/social_v2_consumer.dart',
  'apps/mobile/lib/ui_v2/social/social_v2_youtube_creator_upload.dart',
  'backend/functions/src/index.ts',
  'backend/functions/src/youtube/config.ts',
  'backend/functions/src/youtube/config.test.ts',
  'backend/functions/src/youtube/request_contract.test.ts',
  'backend/functions/src/youtube/provider_service.test.ts',
  'backend/functions/src/youtube/provider_service.ts',
  'backend/functions/src/youtube/oauth.ts',
  'backend/functions/src/youtube/token_vault.ts',
  'apps/mobile/test/social_v2_youtube_creator_upload_test.dart',
  'apps/mobile/test/youtube_private_dev_client_test.dart',
  'apps/mobile/test/social_v2_create_publication_test.dart',
  'apps/mobile/test/screen04_universal_v2_conformance_test.dart',
  'apps/mobile/test/ui_v2_social_customer_copy_gate_test.dart',
  'apps/mobile/test/ui_v2_social_named_state_parity_test.dart',
  'apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_youtube_native_home_dock_c29e_test.dart',
  'apps/mobile/test/social_v2_youtube_connect_return_test.dart'
)

function Get-C29LManifestRecords {
  $records = foreach ($relative in $sourceOwners) {
    $path = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "C29L source owner is missing or outside repository: $relative"
    }
    $portable = $relative.Replace('\', '/')
    "$((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash)  $portable"
  }
  return @($records | Sort-Object)
}

function Get-C29LManifestSha([string[]]$Records) {
  $bytes = [Text.Encoding]::UTF8.GetBytes(($Records -join "`n"))
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return [Convert]::ToHexString($sha.ComputeHash($bytes)) } finally { $sha.Dispose() }
}

function Invoke-C29LPowerShellGate([string]$RelativePath, [hashtable]$Parameters = @{}) {
  & (Join-Path $root $RelativePath) @Parameters
}

$cyclePath = Join-Path $evidenceRoot "qualifying-cycle-$Cycle.json"
if (Test-Path -LiteralPath $cyclePath) { throw "C29L refuses to overwrite existing evidence: $cyclePath" }
$manifestPath = Join-Path $evidenceRoot 'source-aggregate-manifest.txt'
$recordsBefore = Get-C29LManifestRecords
$manifestShaBefore = Get-C29LManifestSha $recordsBefore
if ($Cycle -eq 2) {
  $cycleOnePath = Join-Path $evidenceRoot 'qualifying-cycle-1.json'
  if (-not (Test-Path -LiteralPath $cycleOnePath -PathType Leaf) -or
      -not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'C29L cycle 2 requires cycle 1 and its immutable aggregate manifest.'
  }
  $cycleOne = Get-Content -Raw -LiteralPath $cycleOnePath | ConvertFrom-Json
  if ([string]$cycleOne.sourceManifestSha256 -cne $manifestShaBefore) {
    throw 'C29L cycle 2 source aggregate differs from cycle 1.'
  }
}

$timer = [Diagnostics.Stopwatch]::StartNew()
Invoke-C29LPowerShellGate 'scripts/check-personal-social-youtube-creator-connection-private-short-upload-c29l.ps1' @{ RepositoryRoot = $root }
Invoke-C29LPowerShellGate 'scripts/check-codex-development-regression-memory.ps1' @{ RepositoryRoot = $root; Phase = 'implementation'; BuildMode = 'none' }
Invoke-C29LPowerShellGate 'scripts/check-mvp-delivery-discipline-lock.ps1' @{ RepositoryRoot = $root; RequireTicketSelectionAssessment = $true }
Invoke-C29LPowerShellGate 'scripts/check-mvp-scope-gate-state.ps1' @{ RepositoryRoot = $root; RequireExecutionAuthorized = $true }
Invoke-C29LPowerShellGate 'scripts/test-youtube-public-dev-review-build-controls.ps1'

Push-Location $backendRoot
try {
  & npm run typecheck
  if ($LASTEXITCODE -ne 0) { throw "C29L backend typecheck failed with exit $LASTEXITCODE." }
  & npm test
  if ($LASTEXITCODE -ne 0) { throw "C29L backend test suite failed with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}

$mobileTests = @(
  'test/social_v2_youtube_creator_upload_test.dart',
  'test/youtube_private_dev_client_test.dart',
  'test/social_v2_create_publication_test.dart',
  'test/screen04_universal_v2_conformance_test.dart',
  'test/ui_v2_social_customer_copy_gate_test.dart',
  'test/ui_v2_social_named_state_parity_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_youtube_native_home_dock_c29e_test.dart',
  'test/social_v2_youtube_connect_return_test.dart'
)
$formatOwners = @(
  'lib/core/youtube/youtube_private_dev_uploader.dart',
  'lib/core/youtube/youtube_private_dev_workflow.dart',
  'lib/features/journey01/journey_router.dart',
  'lib/ui_v2/social/social_v2_consumer.dart',
  'lib/ui_v2/social/social_v2_youtube_creator_upload.dart'
)
Push-Location $mobileRoot
try {
  & dart format --output=none --set-exit-if-changed @formatOwners @mobileTests
  if ($LASTEXITCODE -ne 0) { throw "C29L format check failed with exit $LASTEXITCODE." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "C29L full Flutter analysis failed with exit $LASTEXITCODE." }
  & flutter test @mobileTests --reporter compact
  if ($LASTEXITCODE -ne 0) { throw "C29L required Flutter suite failed with exit $LASTEXITCODE." }
} finally {
  Pop-Location
}
$timer.Stop()

$recordsAfter = Get-C29LManifestRecords
$manifestShaAfter = Get-C29LManifestSha $recordsAfter
if ($manifestShaAfter -cne $manifestShaBefore -or
    (($recordsAfter -join "`n") -cne ($recordsBefore -join "`n"))) {
  throw "C29L source changed during qualification: before=$manifestShaBefore after=$manifestShaAfter"
}

[IO.Directory]::CreateDirectory($evidenceRoot) | Out-Null
if ($Cycle -eq 1) {
  [IO.File]::WriteAllText($manifestPath, (($recordsAfter -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
} else {
  $retainedRecords = (Get-Content -Raw -LiteralPath $manifestPath).TrimEnd("`r", "`n") -split "`r?`n"
  if (($retainedRecords -join "`n") -cne ($recordsAfter -join "`n")) {
    throw 'C29L retained source manifest differs during cycle 2.'
  }
}

$buildProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(dart|flutter|gradle|java)$' }).Count
$evidence = [ordered]@{
  schemaVersion = 1
  ticketId = 'UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-CREATOR-CONNECTION-PRIVATE-SHORT-UPLOAD-C29L'
  cycle = $Cycle
  status = 'passed'
  wallSeconds = [Math]::Round($timer.Elapsed.TotalSeconds, 1)
  sourceManifest = 'artifacts/quality/uaw-personal-mvp-social-youtube-creator-connection-private-short-upload-c29l-host-qualification-20260811-03/source-aggregate-manifest.txt'
  sourceManifestSha256 = $manifestShaAfter
  sourceFiles = $recordsAfter.Count
  sourceFingerprintBeforeAndAfterIdentical = $true
  ticketManifestSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'config/uaw-personal-mvp-social-youtube-creator-connection-private-short-upload-c29l-ticket.json')).Hash
  scopeGateStateSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'config/mvp-scope-gate-state.json')).Hash
  regressionRegistrySha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'config/codex-development-regression-registry.json')).Hash
  protectedC29KMachineStateSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'config/apk-regression-gate-state-c29k.json')).Hash
  ticketSpecificGate = 'passed'
  regressionMemory = 'passed'
  mvpDeliveryAndScopeLocks = 'passed'
  globalApprovedUiLock = 'preexisting_dirty_owner_outside_c29l_manifest_not_resealed_or_waived'
  publicDevBuildControlTests = 'passed'
  backendTypecheck = 'passed'
  backendTestSuite = 'passed'
  dartFormat = 'clean'
  flutterAnalysis = 'clean'
  requiredFlutterTestFiles = $mobileTests.Count
  requiredFlutterSuite = 'passed'
  activeBuildProcessesAfter = $buildProcesses
  protectedInstalledVersionName = '1.0.0-r60.34'
  protectedInstalledVersionCode = '2026081134'
  protectedInstalledApkSha256 = '96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29'
  apkBuildPerformed = $false
  deviceMutationPerformed = $false
  providerMutationPerformed = $false
  secretValueAccessPerformed = $false
}
[IO.File]::WriteAllText($cyclePath, (($evidence | ConvertTo-Json -Depth 6) + "`n"), [Text.UTF8Encoding]::new($false))
$evidenceSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $cyclePath).Hash

Write-Output "C29L host cycle passed: cycle=$Cycle; sourceManifestSha256=$manifestShaAfter; sourceFiles=$($recordsAfter.Count); requiredFlutterTestFiles=$($mobileTests.Count); backendTypecheck=passed; FlutterAnalysis=clean; r60.34Preserved=true; buildInstallProviderSecretWrites=false; evidenceSha256=$evidenceSha."
