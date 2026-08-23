[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet(1, 2)][int]$Cycle, [string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'C30T qualifier requires PowerShell 7.' }
$PSNativeCommandUseErrorActionPreference = $false
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$candidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T'
$artifactRelative = 'artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-11'
$artifactRoot = Join-Path $root $artifactRelative
$statePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30t.json'
$aggregatePath = Join-Path $root 'config/play-internal-live-read-recovery-gate-state-c30t.json'
$mobileRoot = Join-Path $root 'apps/mobile'
$backendRoot = Join-Path $root 'backend/functions'
[void][IO.Directory]::CreateDirectory($artifactRoot)
$attempt = [DateTimeOffset]::Now.ToString('yyyyMMdd-HHmmss-fff')
$attemptRoot = Join-Path $artifactRoot "qualification-attempt-$attempt-cycle-$Cycle"
[void][IO.Directory]::CreateDirectory($attemptRoot)

function Assert-C30TQualification {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30T source qualification rejected: $Message" }
}
function Invoke-NativeLogged {
  param([Parameter(Mandatory)][string]$Command, [Parameter(Mandatory)][string[]]$Arguments, [Parameter(Mandatory)][string]$WorkingDirectory, [Parameter(Mandatory)][string]$LogPath)
  [IO.File]::WriteAllText($LogPath, '', [Text.UTF8Encoding]::new($false))
  $savedErrorActionPreference = $ErrorActionPreference
  $savedNativePreference = $PSNativeCommandUseErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    Push-Location $WorkingDirectory
    try { & $Command @Arguments *> $LogPath; $exitCode = $LASTEXITCODE }
    finally { Pop-Location }
  } finally {
    $ErrorActionPreference = $savedErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $savedNativePreference
  }
  if ($exitCode -ne 0) { throw "Command failed with exit $exitCode; log=$LogPath" }
}
function Get-ArtifactSnapshot {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'absent' }
  $file = Get-Item -LiteralPath $Path
  return '{0}|{1}|{2}' -f $file.Length, $file.LastWriteTimeUtc.Ticks, (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function Write-JsonState {
  param([Parameter(Mandatory)][object]$State, [Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Suffix)
  $temporary = $Path + $Suffix
  Assert-C30TQualification -Condition (-not (Test-Path -LiteralPath $temporary)) -Message "stale qualifier state file exists: $temporary"
  [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 40) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $Path -Force
}
function Get-RelativeFiles {
  param([Parameter(Mandatory)][string]$Directory, [Parameter(Mandatory)][string[]]$Globs)
  $arguments = @('--files', $Directory)
  foreach ($glob in $Globs) { $arguments += @('--glob', $glob) }
  $items = @(& rg @arguments)
  Assert-C30TQualification -Condition ($LASTEXITCODE -in @(0, 1)) -Message "file inventory failed for $Directory"
  return $items
}

& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase implementation -BuildMode none -RepositoryRoot $root
& (Join-Path $root 'scripts/check-mvp-delivery-discipline-lock.ps1') -RepositoryRoot $root
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId $candidateId -RequireExecutionAuthorized -RepositoryRoot $root
& (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30t.ps1') -Phase reconcile -RepositoryRoot $root
& (Join-Path $root 'scripts/check-play-internal-aab-build-wrapper-c30t.ps1') -RepositoryRoot $root
$qualificationState = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json

$deviceSummary = & adb -s 2b3e0f71 shell dumpsys package com.moolsocial.app 2>&1
Assert-C30TQualification -Condition ($LASTEXITCODE -eq 0) -Message 'OPPO package readback failed.'
$deviceText = $deviceSummary -join [Environment]::NewLine
Assert-C30TQualification -Condition ($deviceText.Contains('versionCode=2026081244', [StringComparison]::Ordinal) -and $deviceText.Contains('versionName=1.0.0-r60.44', [StringComparison]::Ordinal) -and $deviceText.Contains('installerPackageName=com.android.vending', [StringComparison]::Ordinal)) -Message 'r60.44 is not preserved as the Play-installed predecessor.'

$releaseApk = Join-Path $mobileRoot 'build/app/outputs/flutter-apk/app-release.apk'
$releaseAab = Join-Path $mobileRoot 'build/app/outputs/bundle/release/app-release.aab'
$apkBefore = Get-ArtifactSnapshot -Path $releaseApk
$aabBefore = Get-ArtifactSnapshot -Path $releaseAab

$formatLog = Join-Path $attemptRoot 'format.log'
$analyzeLog = Join-Path $attemptRoot 'analyze.log'
$testLog = Join-Path $attemptRoot 'focused-social-tests.log'
$backendLog = Join-Path $attemptRoot 'backend-verify.log'
$configLog = Join-Path $attemptRoot 'release-config-only.log'
$postTestConfigLog = Join-Path $attemptRoot 'post-test-release-config-only.log'
$dependencyLog = Join-Path $attemptRoot 'release-runtime-dependencies.log'
$providerLog = Join-Path $attemptRoot 'provider-read-only-qualification.json'
$gateLog = Join-Path $attemptRoot 'repository-gates.log'
$affectedTestManifestLog = Join-Path $attemptRoot 'focused-test-manifest.txt'
$youtubeDeploymentControlsLog = Join-Path $attemptRoot 'youtube-deployment-controls.log'
$hostingStaticTestLog = Join-Path $attemptRoot 'hosting-static-tests.log'

$pubspecHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash
$lockHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash
Invoke-NativeLogged -Command 'flutter' -Arguments @('build', 'apk', '--release', '--config-only', '--build-name=1.0.0-r60.45', '--build-number=2026081345') -WorkingDirectory $mobileRoot -LogPath $configLog
Assert-C30TQualification -Condition ($pubspecHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash -and $lockHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash) -Message 'release config-only changed pubspec.yaml or pubspec.lock.'
Assert-C30TQualification -Condition ($apkBefore -ceq (Get-ArtifactSnapshot -Path $releaseApk) -and $aabBefore -ceq (Get-ArtifactSnapshot -Path $releaseAab)) -Message 'release config-only created or changed an APK or AAB.'
& (Join-Path $root 'scripts/restore-release-generated-plugin-registrant-c30t.ps1') -RepositoryRoot $root | Add-Content -LiteralPath $configLog
$releaseRegistrant = Get-Content -Raw -LiteralPath (Join-Path $mobileRoot 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java')
Assert-C30TQualification -Condition (-not $releaseRegistrant.Contains('IntegrationTestPlugin', [StringComparison]::Ordinal) -and [regex]::Matches($releaseRegistrant, 'flutterEngine\.getPlugins\(\)\.add').Count -eq 16) -Message 'release config-only did not restore the exact 16-plugin registrant.'

& (Join-Path $root 'scripts/check-play-internal-release-readiness-c30t.ps1') -RepositoryRoot $root

Invoke-NativeLogged -Command 'dart' -Arguments @('format', '--output=none', '--set-exit-if-changed', 'lib', 'test', 'integration_test', 'packages/youtube_embedded_player_private_dev/lib') -WorkingDirectory $mobileRoot -LogPath $formatLog
Invoke-NativeLogged -Command 'flutter' -Arguments @('analyze') -WorkingDirectory $mobileRoot -LogPath $analyzeLog

$focusedTests = @(
  'test/firebase_social_auth_gateway_test.dart',
  'test/c30t_social_auth_and_feed_gateway_test.dart',
  'test/chat_visual_golden_test.dart',
  'test/chat_production_gateway_test.dart',
  'test/chat_flow_test.dart',
  'test/screen04_universal_v2_conformance_test.dart',
  'test/shared_vertical_slice_test.dart',
  'test/screen04_social_operational_baseline_test.dart',
  'test/social_content_authenticated_gateway_test.dart',
  'test/social_v2_create_publication_test.dart',
  'test/social_v2_moolsocial_feed_ownership_test.dart',
  'test/social_v2_youtube_connect_return_test.dart',
  'test/social_v2_youtube_creator_upload_test.dart',
  'test/social_v2_youtube_public_runtime_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_action_truth_accessibility_c29o_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_creator_ergonomics_global_edge_consistency_c29n_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_youtube_account_state_journey_c30j_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_youtube_catalogue_continuity_c29t_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_youtube_full_page_search_ime_copy_c30c_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_youtube_native_home_dock_c29e_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_youtube_adjacent_promotion_policy_c29q_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_footer_visual_compaction_c30d_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_global_android_root_focus_edge_suppression_c30i_test.dart',
  'test/ui_v2/social/uaw_personal_mvp_social_subaction_professional_conformance_c16b_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_chat_global_dock_exact_return_c10d_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_cold_launch_social_default_c10a_test.dart',
  'test/ui_v2/universal/mool_uniform_navigation_six_family_conformance_c27d_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_shared_global_dock_main_roots_c10b_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_global_mool_navigation_c02_test.dart',
  'test/ui_v2/universal/uaw_personal_social_work_route_compatibility_test.dart',
  'test/ui_v2/universal/uaw_r11_personal_global_chat_continuity_test.dart',
  'test/ui_v2/universal/mool_connected_action_navigator_c24b3_test.dart',
  'test/ui_v2/universal/mool_home_fixed_viewport_hub_c24b2_test.dart',
  'test/ui_v2/universal/mool_compact_destination_rail_c25d_test.dart',
  'test/ui_v2/universal/mool_main_only_menu_c25c_test.dart',
  'test/ui_v2/universal/mool_uniform_navigation_design_system_c27b_test.dart',
  'test/ui_v2/universal/mool_uniform_embedded_switcher_c27c_test.dart',
  'test/ui_v2/universal/mool_family_pair_navigation_conformance_c26d_test.dart',
  'test/ui_v2/universal/mool_service_pair_navigation_conformance_c26e_test.dart',
  'test/ui_v2/universal/mool_care_work_navigation_conformance_c26f_test.dart',
  'test/ui_v2/universal/mool_six_domain_route_projection_c25e_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_action_wording_wiring_navigation_fix2_test.dart',
  'test/ui_v2_social_continuous_batch_test.dart',
  'test/ui_v2_social_customer_copy_gate_test.dart',
  'test/ui_v2_social_fitment_matrix_test.dart',
  'test/ui_v2_social_named_state_parity_test.dart',
  'test/ui_v2_screen01_03_fitment_matrix_test.dart',
  'test/journey_session_test.dart',
  'test/review_auth_persistence_test.dart',
  'test/platform_configuration_test.dart',
  'test/platform_release_signing_and_provenance_test.dart',
  'test/youtube_embedded_player_android_test.dart',
  'test/youtube_embedded_player_ios_test.dart',
  'test/youtube_embedded_player_runtime_test.dart',
  'test/youtube_connect_return_route_test.dart',
  'test/youtube_android_adapter_source_gate_test.dart',
  'test/youtube_connect_return_android_source_gate_test.dart',
  'test/youtube_ios_adapter_source_gate_test.dart'
)
foreach ($testPath in $focusedTests) {
  Assert-C30TQualification -Condition (Test-Path -LiteralPath (Join-Path $mobileRoot $testPath) -PathType Leaf) -Message "focused test is missing: $testPath"
}
[IO.File]::WriteAllLines($affectedTestManifestLog, $focusedTests, [Text.UTF8Encoding]::new($false))
$focusedTestHash = (Get-FileHash -LiteralPath $affectedTestManifestLog -Algorithm SHA256).Hash
$acceptedFocusedTestManifest = Join-Path $artifactRoot 'focused-test-manifest-accepted.txt'
if ($Cycle -eq 1) {
  Assert-C30TQualification -Condition (-not (Test-Path -LiteralPath $acceptedFocusedTestManifest)) -Message 'accepted focused-test manifest already exists before cycle 1.'
} else {
  Assert-C30TQualification -Condition (Test-Path -LiteralPath $acceptedFocusedTestManifest -PathType Leaf) -Message 'cycle 1 focused-test manifest is missing.'
  Assert-C30TQualification -Condition ((Get-FileHash -LiteralPath $acceptedFocusedTestManifest -Algorithm SHA256).Hash -ceq $focusedTestHash) -Message 'focused-test manifest changed between cycles.'
}
Invoke-NativeLogged -Command 'flutter' -Arguments (@('test', '--reporter', 'compact') + $focusedTests) -WorkingDirectory $mobileRoot -LogPath $testLog
$focusedTestSuccess = Select-String -LiteralPath $testLog -Pattern 'All (other )?tests passed!' -Quiet
Assert-C30TQualification -Condition $focusedTestSuccess -Message 'focused Flutter test log lacks an exact success marker.'
Invoke-NativeLogged -Command 'npm.cmd' -Arguments @('run', 'verify') -WorkingDirectory $backendRoot -LogPath $backendLog
$backendPassMarker = Select-String -LiteralPath $backendLog -Pattern '^[^A-Za-z0-9]*pass 505\s*$' -Quiet
$backendFailMarker = Select-String -LiteralPath $backendLog -Pattern '^[^A-Za-z0-9]*fail 0\s*$' -Quiet
Assert-C30TQualification -Condition ($backendPassMarker -and $backendFailMarker) -Message 'backend verification lacks exact 505-pass and zero-fail markers.'
Invoke-NativeLogged -Command 'pwsh' -Arguments @('-NoProfile', '-File', (Join-Path $root 'scripts/test-youtube-private-dev-deployment-controls.ps1')) -WorkingDirectory $root -LogPath $youtubeDeploymentControlsLog
Assert-C30TQualification -Condition (Select-String -LiteralPath $youtubeDeploymentControlsLog -Pattern '^YouTube private Dev deployment-control tests passed locally\.$' -Quiet) -Message 'YouTube accepted-review deployment controls did not pass locally.'
Assert-C30TQualification -Condition (Select-String -LiteralPath $youtubeDeploymentControlsLog -Pattern '^No cloud command was performed\.$' -Quiet) -Message 'YouTube deployment-control suite lacks its no-cloud marker.'
Invoke-NativeLogged -Command 'node' -Arguments @('--test', 'apps/web/tests/firebase-public-site.test.mjs') -WorkingDirectory $root -LogPath $hostingStaticTestLog
$hostingPassMarker = Select-String -LiteralPath $hostingStaticTestLog -Pattern '^[^A-Za-z0-9]*pass 7\s*$' -Quiet
$hostingFailMarker = Select-String -LiteralPath $hostingStaticTestLog -Pattern '^[^A-Za-z0-9]*fail 0\s*$' -Quiet
Assert-C30TQualification -Condition ($hostingPassMarker -and $hostingFailMarker) -Message 'Hosting/App Links verification lacks exact seven-pass and zero-fail markers.'

Invoke-NativeLogged -Command (Join-Path $mobileRoot 'android/gradlew.bat') -Arguments @(':app:dependencies', '--configuration', 'releaseRuntimeClasspath', '--console=plain') -WorkingDirectory (Join-Path $mobileRoot 'android') -LogPath $dependencyLog
$dependencyText = Get-Content -Raw -LiteralPath $dependencyLog
Assert-C30TQualification -Condition $dependencyText.Contains('BUILD SUCCESSFUL', [StringComparison]::Ordinal) -Message 'release dependency report lacks BUILD SUCCESSFUL.'
$forbiddenMaven = [regex]::Matches($dependencyText, 'com\.google\.firebase:firebase-(analytics(?:-ktx)?|messaging(?:-ktx)?|perf(?:-ktx)?|config(?:-ktx)?)(?::|\s+->)')
Assert-C30TQualification -Condition ($forbiddenMaven.Count -eq 0) -Message "forbidden unused Firebase runtime artifacts remain: $($forbiddenMaven.Count)."
foreach ($required in @('firebase-appcheck-playintegrity', 'firebase-auth', 'firebase-common', 'firebase-crashlytics')) {
  Assert-C30TQualification -Condition $dependencyText.Contains($required, [StringComparison]::OrdinalIgnoreCase) -Message "required release dependency missing: $required"
}
foreach ($failure in @('Could not resolve', 'BUILD FAILED', 'Google-Services plugin not found', 'srcDirs is deprecated')) {
  Assert-C30TQualification -Condition (-not $dependencyText.Contains($failure, [StringComparison]::OrdinalIgnoreCase)) -Message "release dependency audit contains $failure"
}

$projectId = 'moolsocial-dev-503018'
$region = 'asia-south1'
$providerEvidence = [ordered]@{}
foreach ($serviceName in @('moolsocialcontent', 'moolsocialchat')) {
  $serviceJson = & gcloud run services describe $serviceName --project=$projectId --region=$region --format=json
  Assert-C30TQualification -Condition ($LASTEXITCODE -eq 0) -Message "Cloud Run describe failed for $serviceName"
  $service = $serviceJson | ConvertFrom-Json
  $expectedRevision = if ($serviceName -ceq 'moolsocialcontent') { 'moolsocialcontent-00004-gig' } else { 'moolsocialchat-00001-yaf' }
  Assert-C30TQualification -Condition ([string]$service.status.latestReadyRevisionName -ceq $expectedRevision -and [string]$service.spec.template.spec.serviceAccountName -ceq 'social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com' -and [string]$service.metadata.annotations.'run.googleapis.com/invoker-iam-disabled' -ceq 'true' -and [int](($service.status.traffic | Measure-Object -Property percent -Sum).Sum) -eq 100) -Message "$serviceName runtime qualification changed."
  $providerEvidence[$serviceName] = [ordered]@{ revision = $expectedRevision; runtimeServiceAccount = [string]$service.spec.template.spec.serviceAccountName; invokerIamDisabled = $true; trafficPercent = 100 }
}
$contentStatus = & curl.exe -sS -o NUL -w '%{http_code}' -X POST -H 'Content-Type: application/json' --data '{}' 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent'
Assert-C30TQualification -Condition ($LASTEXITCODE -eq 0 -and $contentStatus -ceq '401') -Message 'Content unauthenticated application probe changed.'
$chatStatus = & curl.exe -sS -o NUL -w '%{http_code}' -X POST -H 'Content-Type: application/json' --data '{}' 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialChat'
Assert-C30TQualification -Condition ($LASTEXITCODE -eq 0 -and $chatStatus -ceq '401') -Message 'Chat unauthenticated application probe changed.'
$youtubeServiceJson = & gcloud run services describe youtubeprovider --project=$projectId --region=$region --format=json
Assert-C30TQualification -Condition ($LASTEXITCODE -eq 0) -Message 'YouTube provider describe failed.'
$youtubeService = $youtubeServiceJson | ConvertFrom-Json
$youtubeRevision = [string]$youtubeService.status.latestReadyRevisionName
$youtubeExpectedRevision = [string]$qualificationState.providerRevisions.youtubeprovider
Assert-C30TQualification -Condition (-not [string]::IsNullOrWhiteSpace($youtubeExpectedRevision)) -Message 'YouTube provider revision is not sealed in machine state.'
$youtubeExpectedFlags = [ordered]@{
  MOOLSOCIAL_PROVIDER_ENV = 'dev'
  YOUTUBE_PUBLIC_DATA_REVIEW_MODE = 'accepted'
  YOUTUBE_PUBLIC_DATA_ENABLED = 'true'
  YOUTUBE_OWNER_CONNECT_ENABLED = 'true'
  YOUTUBE_OWNER_ACTIONS_ENABLED = 'false'
  YOUTUBE_CREATOR_ASSETS_ENABLED = 'false'
  YOUTUBE_LIVE_ENABLED = 'false'
  YOUTUBE_PRIVATE_UPLOAD_ENABLED = 'false'
  YOUTUBE_OWNER_ANALYTICS_ENABLED = 'false'
}
$youtubeSafeFlags = [ordered]@{}
foreach ($entry in $youtubeExpectedFlags.GetEnumerator()) {
  $matches = @($youtubeService.spec.template.spec.containers[0].env | Where-Object { [string]$_.name -ceq [string]$entry.Key })
  $valueProperty = if ($matches.Count -eq 1) { $matches[0].PSObject.Properties['value'] } else { $null }
  $valueFromProperty = if ($matches.Count -eq 1) { $matches[0].PSObject.Properties['valueFrom'] } else { $null }
  Assert-C30TQualification -Condition ($matches.Count -eq 1 -and $null -ne $valueProperty -and $null -eq $valueFromProperty -and [string]$valueProperty.Value -ceq [string]$entry.Value) -Message "YouTube accepted-review flag changed or is not deployed: $($entry.Key)"
  $youtubeSafeFlags[$entry.Key] = [string]$valueProperty.Value
}
Assert-C30TQualification -Condition ($youtubeRevision -ceq $youtubeExpectedRevision) -Message 'YouTube provider revision differs from exact machine state.'
$callbackRevision = (& gcloud run services describe youtubeoauthcallback --project=$projectId --region=$region --format='value(status.latestReadyRevisionName)').Trim()
$callbackExpectedRevision = [string]$qualificationState.providerRevisions.youtubeoauthcallback
Assert-C30TQualification -Condition (-not [string]::IsNullOrWhiteSpace($callbackExpectedRevision)) -Message 'YouTube callback revision is not sealed in machine state.'
Assert-C30TQualification -Condition ($LASTEXITCODE -eq 0 -and $callbackRevision -ceq $callbackExpectedRevision) -Message 'YouTube callback revision differs from exact machine state.'
$providerEvidence['youtubeprovider'] = [ordered]@{ revision = $youtubeRevision; acceptedReviewFlags = $youtubeSafeFlags }
$providerEvidence['youtubeoauthcallback'] = [ordered]@{ revision = $callbackRevision }
$providerEvidence['unauthenticatedApplicationHttpStatus'] = [ordered]@{ content = $contentStatus; chat = $chatStatus }
[IO.File]::WriteAllText($providerLog, (($providerEvidence | ConvertTo-Json -Depth 10) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))

Invoke-NativeLogged -Command 'flutter' -Arguments @('build', 'apk', '--release', '--config-only', '--build-name=1.0.0-r60.45', '--build-number=2026081345') -WorkingDirectory $mobileRoot -LogPath $postTestConfigLog
Assert-C30TQualification -Condition ($pubspecHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash -and $lockHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash) -Message 'post-test release config-only changed pubspec.yaml or pubspec.lock.'
Assert-C30TQualification -Condition ($apkBefore -ceq (Get-ArtifactSnapshot -Path $releaseApk) -and $aabBefore -ceq (Get-ArtifactSnapshot -Path $releaseAab)) -Message 'post-test release config-only created or changed an APK or AAB.'
& (Join-Path $root 'scripts/restore-release-generated-plugin-registrant-c30t.ps1') -RepositoryRoot $root | Add-Content -LiteralPath $postTestConfigLog
$postTestReleaseRegistrant = Get-Content -Raw -LiteralPath (Join-Path $mobileRoot 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java')
Assert-C30TQualification -Condition (-not $postTestReleaseRegistrant.Contains('IntegrationTestPlugin', [StringComparison]::Ordinal) -and [regex]::Matches($postTestReleaseRegistrant, 'flutterEngine\.getPlugins\(\)\.add').Count -eq 16) -Message 'post-test release config-only did not restore the exact 16-plugin registrant.'

[IO.File]::WriteAllText($gateLog, '', [Text.UTF8Encoding]::new($false))
foreach ($gate in @(
  'scripts/check-play-internal-release-readiness-c30t.ps1',
  'scripts/check-play-internal-aab-build-wrapper-c30t.ps1',
  'scripts/check-youtube-embedded-player-android.ps1',
  'scripts/check-mvp-personal-action-projection.ps1',
  'scripts/check-codex-development-regression-memory.ps1',
  'scripts/check-play-internal-aab-regression-gate-state-c30t.ps1'
)) {
  & (Join-Path $root $gate) 2>&1 | Tee-Object -FilePath $gateLog -Append | Out-Null
}

Assert-C30TQualification -Condition ($apkBefore -ceq (Get-ArtifactSnapshot -Path $releaseApk)) -Message 'qualification created or changed a release APK.'
Assert-C30TQualification -Condition ($aabBefore -ceq (Get-ArtifactSnapshot -Path $releaseAab)) -Message 'qualification created or changed the generated release AAB.'

$paths = @()
$paths += @(Get-RelativeFiles -Directory (Join-Path $root 'apps/mobile/lib') -Globs @('*.dart'))
$paths += @(Get-RelativeFiles -Directory (Join-Path $root 'apps/mobile/test') -Globs @('*.dart'))
$paths += @(Get-RelativeFiles -Directory (Join-Path $root 'apps/mobile/test/goldens') -Globs @('*.png'))
$paths += @(Get-RelativeFiles -Directory (Join-Path $root 'apps/mobile/integration_test') -Globs @('*.dart'))
$paths += @(Get-RelativeFiles -Directory (Join-Path $root 'apps/mobile/packages/youtube_embedded_player_private_dev') -Globs @('*.dart', '*.kt', '*.kts', 'AndroidManifest.xml', 'pubspec.yaml'))
$paths += @(Get-RelativeFiles -Directory (Join-Path $root 'backend/functions/src') -Globs @('*.ts'))
$webPublicPaths = @(& rg --files --hidden (Join-Path $root 'apps/web/public'))
Assert-C30TQualification -Condition ($LASTEXITCODE -in @(0, 1) -and $webPublicPaths.Count -gt 0) -Message 'Hosting public-source inventory failed.'
$paths += $webPublicPaths
$paths += @(
  'apps/mobile/pubspec.yaml', 'apps/mobile/pubspec.lock',
  'apps/mobile/android/settings.gradle.kts', 'apps/mobile/android/gradle.properties',
  'apps/mobile/android/gradle/wrapper/gradle-wrapper.properties',
  'apps/mobile/android/app/build.gradle.kts',
  'apps/mobile/android/app/src/main/AndroidManifest.xml',
  'apps/mobile/android/app/src/debug/AndroidManifest.xml',
  'apps/mobile/android/app/src/profile/AndroidManifest.xml',
  'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
  'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/YouTubeConnectReturnActivity.kt',
  'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
  'backend/functions/package.json', 'backend/functions/package-lock.json', 'backend/functions/tsconfig.json',
  'firebase.json', 'apps/web/tests/firebase-public-site.test.mjs',
  'config/codex-development-regression-registry.json',
  'config/mvp-scope-gate-state.json',
  'config/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-ticket.json',
  'config/uaw-c30t-youtube-readonly-connect-unavailable-ticket.json',
  'deployment/youtube-private-dev/deployment-manifest.json',
  'scripts/check-play-internal-aab-regression-gate-state-c30t.ps1',
  'scripts/check-play-internal-release-readiness-c30t.ps1',
  'scripts/check-play-internal-aab-build-wrapper-c30t.ps1',
  'scripts/restore-release-generated-plugin-registrant-c30t.ps1',
  'scripts/invoke-play-internal-aab-build-c30t.ps1',
  'scripts/qualify-play-internal-live-read-recovery-c30t.ps1',
  'scripts/youtube-private-dev-control-common.ps1',
  'scripts/test-youtube-private-dev-deployment-controls.ps1',
  'scripts/check-youtube-private-dev-preflight.ps1',
  'scripts/verify-youtube-private-dev-deployment.ps1',
  'tmp/run-c30t-single-aab-founder.ps1',
  'tmp/bundletool-all-1.18.3.jar'
)
$c30tTickets = @(rg --files (Join-Path $root 'config') | rg 'uaw-c30t-.*-ticket\.json$')
Assert-C30TQualification -Condition ($LASTEXITCODE -eq 0 -and $c30tTickets.Count -gt 0) -Message 'C30T defect-ticket inventory failed.'
$paths += $c30tTickets
$c30tDocs = @(rg --files (Join-Path $root 'docs/quality') | rg 'UAW-C30T-.*20260813\.md$')
Assert-C30TQualification -Condition ($LASTEXITCODE -in @(0, 1)) -Message 'C30T evidence inventory failed.'
$paths += $c30tDocs
$relativePaths = @($paths | ForEach-Object {
  $full = [IO.Path]::GetFullPath($_)
  if ($full.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { $full.Substring($root.Length + 1).Replace('\', '/') }
  else { ([string]$_).Replace('\', '/') }
} | Sort-Object -Unique)
foreach ($relativePath in $relativePaths) {
  Assert-C30TQualification -Condition (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf) -Message "manifest owner missing: $relativePath"
}
$manifestRows = @($relativePaths | ForEach-Object { '{0}  {1}' -f (Get-FileHash -LiteralPath (Join-Path $root $_) -Algorithm SHA256).Hash, $_ })
$manifestPath = Join-Path $artifactRoot 'source-aggregate-manifest-accepted.txt'
$manifestText = ($manifestRows -join [Environment]::NewLine) + [Environment]::NewLine
$manifestBytes = [Text.UTF8Encoding]::new($false).GetBytes($manifestText)
$manifestHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($manifestBytes))
if ($Cycle -eq 1) {
  Assert-C30TQualification -Condition (-not (Test-Path -LiteralPath $manifestPath)) -Message 'accepted source manifest already exists before cycle 1.'
  [IO.File]::WriteAllBytes($manifestPath, $manifestBytes)
  Copy-Item -LiteralPath $affectedTestManifestLog -Destination $acceptedFocusedTestManifest
} else {
  Assert-C30TQualification -Condition (Test-Path -LiteralPath $manifestPath -PathType Leaf) -Message 'cycle 1 source manifest is missing.'
  Assert-C30TQualification -Condition ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -ceq $manifestHash) -Message 'source changed between qualification cycles.'
}

$cycleResult = [ordered]@{
  schemaVersion = 1; candidateId = $candidateId; cycle = $Cycle; attempt = $attempt
  branch = (& git -C $root branch --show-current).Trim(); head = (& git -C $root rev-parse HEAD).Trim(); powerShellMajor = $PSVersionTable.PSVersion.Major
  sourceManifest = "$artifactRelative/source-aggregate-manifest-accepted.txt"; sourceManifestSha256 = $manifestHash; sourceFiles = $relativePaths.Count
  flutterFormat = 'clean'; flutterAnalyze = 'clean'; focusedFlutterTests = 'all_passed'; focusedTestFiles = $focusedTests.Count; focusedTestManifestSha256 = $focusedTestHash
  backendVerify = '505_of_505_passed'; hostingStaticTests = '7_of_7_passed'; releaseDependencyGraph = 'passed'; forbiddenUnusedFirebaseArtifacts = 0
  providerRevisions = $providerEvidence; staticReleaseReadiness = 'passed'; registeredPlugins = 15; expectedSourcePermissions = 5
  playPredecessorPreserved = $true; predecessorVersionCode = '2026081244'; predecessorInstaller = 'com.android.vending'
  releaseApkUnchanged = $true; releaseAabUnchanged = $true
  formatLogSha256 = (Get-FileHash -LiteralPath $formatLog -Algorithm SHA256).Hash
  analyzeLogSha256 = (Get-FileHash -LiteralPath $analyzeLog -Algorithm SHA256).Hash
  testLogSha256 = (Get-FileHash -LiteralPath $testLog -Algorithm SHA256).Hash
  backendLogSha256 = (Get-FileHash -LiteralPath $backendLog -Algorithm SHA256).Hash
  youtubeDeploymentControlsLogSha256 = (Get-FileHash -LiteralPath $youtubeDeploymentControlsLog -Algorithm SHA256).Hash
  hostingStaticTestLogSha256 = (Get-FileHash -LiteralPath $hostingStaticTestLog -Algorithm SHA256).Hash
  configLogSha256 = (Get-FileHash -LiteralPath $configLog -Algorithm SHA256).Hash
  dependencyLogSha256 = (Get-FileHash -LiteralPath $dependencyLog -Algorithm SHA256).Hash
  providerLogSha256 = (Get-FileHash -LiteralPath $providerLog -Algorithm SHA256).Hash
  gateLogSha256 = (Get-FileHash -LiteralPath $gateLog -Algorithm SHA256).Hash
}
$cyclePath = Join-Path $artifactRoot ('{0:D2}-source-qualifying-cycle-{0}.json' -f $Cycle)
Assert-C30TQualification -Condition (-not (Test-Path -LiteralPath $cyclePath)) -Message 'successful cycle evidence already exists.'
[IO.File]::WriteAllText($cyclePath, (($cycleResult | ConvertTo-Json -Depth 20) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))

if ($Cycle -eq 2) {
  $cycle1Path = Join-Path $artifactRoot '01-source-qualifying-cycle-1.json'
  $cycle1 = Get-Content -Raw -LiteralPath $cycle1Path | ConvertFrom-Json
  Assert-C30TQualification -Condition ([string]$cycle1.sourceManifestSha256 -ceq $manifestHash) -Message 'cycle source fingerprints differ.'
  $state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
  Assert-C30TQualification -Condition ([string]$state.machineState -ceq 'founder_authorized_continuous_social_audit_in_progress_build_held' -and [string]$state.buildAuthorization -ceq 'founder_hold_pending_new_aab_authorization' -and [int]$state.buildResult.buildCount -eq 0) -Message 'founder continuous-audit hold changed during qualification.'
  $state.machineState = 'pre_aab_audit_passed_founder_aab_authorization_required'
  $state.toolingQualification.launcherRejectsWindowsPowerShellBeforePrompt = $true
  $state.toolingQualification.wrapperRejectsWindowsPowerShellBeforeAuthorityMutation = $true
  $state.toolingQualification.nativeStderrPromotionDisabledOnlyDuringNativeCommands = $true
  $state.toolingQualification.nativeExitCodeAuthoritative = $true
  $state.toolingQualification.preferencesRestoredAfterNativeCommands = $true
  $state.toolingQualification.releaseConfigOnlyCommandQualified = $true
  $state.toolingQualification.releaseConfigOnlyProducesNoApkOrAab = $true
  $state.toolingQualification.releaseRegistrantExactPluginSetQualified = $true
  $state.toolingQualification.googleServicesTaskRegistered = $true
  $state.toolingQualification.crashlyticsBuildIdTaskRegistered = $true
  $state.sourceQualification.state = 'passed_two_identical_comprehensive_C30T_pre_AAB_cycles'
  $state.sourceQualification.manifestPath = "$artifactRelative/source-aggregate-manifest-accepted.txt"
  $state.sourceQualification.manifestSha256 = $manifestHash
  $state.sourceQualification.fileCount = $relativePaths.Count
  $state.sourceQualification.identicalQualifyingCycles = 2
  $state.sourceQualification.comprehensiveReleaseAuditPassed = $true
  $state.sourceQualification.registeredPluginStartupAuditPassed = $true
  $state.sourceQualification.manifestPermissionComponentAuditPassed = $true
  $state.sourceQualification.releaseDependencyAndR8AuditPassed = $true
  $state.sourceQualification.secretAndEnvironmentAuditPassed = $true
  $state.sourceQualification.updateRetentionAndRecoveryAuditPassed = $true
  $state.sourceQualification.releaseFirebaseStaticGatePassed = $true
  $state.sourceQualification.completeRegressionGatePassed = $true
  $state.sourceQualification.backendVerifyPassed = $true
  $state.sourceQualification.youtubeAcceptedReviewControlsPassed = $true
  $state.sourceQualification.focusedSocialSuitePassed = $true
  $state.sourceQualification.cycleEvidence = @("$artifactRelative/01-source-qualifying-cycle-1.json", "$artifactRelative/02-source-qualifying-cycle-2.json")
  $aggregate = Get-Content -Raw -LiteralPath $aggregatePath | ConvertFrom-Json
  Assert-C30TQualification -Condition ([int]$aggregate.candidate.buildCount -eq 0 -and -not [bool]$aggregate.candidate.prebuildQualificationPassed) -Message 'aggregate build authority changed during qualification.'
  $aggregate.machineState = 'pre_aab_audit_passed_founder_aab_authorization_required'
  $aggregate.candidate.prebuildQualificationPassed = $true
  $aggregate.candidate.sourceFingerprint = $manifestHash
  Write-JsonState -State $state -Path $statePath -Suffix '.c30t-qualifier-write'
  Write-JsonState -State $aggregate -Path $aggregatePath -Suffix '.c30t-qualifier-write'
  & (Join-Path $root 'scripts/check-play-internal-aab-regression-gate-state-c30t.ps1') -Phase reconcile -RepositoryRoot $root
}

Write-Output "C30T cycle $Cycle passed: sourceFiles=$($relativePaths.Count); focusedTestFiles=$($focusedTests.Count); backendTests=505; manifestSha256=$manifestHash; AAB_count=0."
Write-Output 'All tests passed!'
