[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))

function Assert-Recovery([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "FIX8 r60.81 postbuild recovery rejected: $Message"
  }
}

function Get-SdkRoot {
  $sdkRoot = $env:ANDROID_SDK_ROOT
  if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
    $sdkRoot = $env:ANDROID_HOME
  }
  if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
    $propertiesPath = Join-Path $root 'apps\mobile\android\local.properties'
    Assert-Recovery (
      Test-Path -LiteralPath $propertiesPath -PathType Leaf
    ) 'Android SDK is unresolved.'
    $sdkLine = Get-Content -LiteralPath $propertiesPath |
      Where-Object { $_.StartsWith('sdk.dir=') } |
      Select-Object -First 1
    Assert-Recovery ($null -ne $sdkLine) 'Android SDK path is absent.'
    $sdkRoot = $sdkLine.Substring('sdk.dir='.Length).
      Replace('\:', ':').Replace('\\', '\')
  }
  $resolved = [IO.Path]::GetFullPath($sdkRoot)
  Assert-Recovery (
    Test-Path -LiteralPath $resolved -PathType Container
  ) 'Android SDK path is missing.'
  return $resolved
}

$candidateId = 'UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR'
$expectedBranch = 'remediation/prototype-conformance-2026-07-20'
$expectedHead = 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
$expectedVersionName = '1.0.0-r60.81'
$expectedVersionCode = '2026082181'
$expectedApkSha = 'F127CD8DB071AB320A4DD724C3A66A2CD4AADE9CF5E8605AADC1F271569FF20B'
$expectedApkBytes = 104047396L
$expectedSourceSha = '9C6BFBC71C82E3F4CA446AC62A335C5FD37F23B83893A6059BC9BEAF71A69182'
$expectedSourceRows = 637
$artifactRelative = 'artifacts/quality/uaw-c34p-fix8-global-social-login-oppo-successor-r60-81-20260822-09'
$sourceManifestRelative = Join-Path $artifactRelative 'source-aggregate-manifest.txt'
$generatedApkRelative = 'apps/mobile/build/app/outputs/flutter-apk/app-release.apk'
$mappingRelative = 'apps/mobile/build/app/outputs/mapping/release'
$predecessorRelative = 'artifacts/quality/uaw-c34p-fix5-public-auth-sideload-preflight-r60-80-20260821-01/uaw-c34p-fix5-all-eight-public-auth-live-provider-readiness-device-review-release.apk'
$sealedApkName = 'uaw-c34p-fix8-global-social-login-oppo-successor-audit-repair-device-review-release.apk'
$provenanceName = 'uaw-c34p-fix8-global-social-login-oppo-successor-audit-repair-build-provenance.txt'
$qualificationName = '04-artifact-qualification.json'

$pathGuard = Join-Path $PSScriptRoot 'release-artifact-path-guard.ps1'
. $pathGuard
$artifactRoot = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $artifactRelative `
  -Label 'FIX8 recovery evidence directory'
$sourceManifest = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $sourceManifestRelative `
  -Label 'FIX8 source manifest'
$generatedApk = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $generatedApkRelative `
  -Label 'FIX8 generated APK'
$mappingFolder = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $mappingRelative `
  -Label 'FIX8 mapping folder'
$predecessorApk = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $predecessorRelative `
  -Label 'preserved r60.80 APK'
$sealedApk = Join-Path $artifactRoot $sealedApkName
$provenancePath = Join-Path $artifactRoot $provenanceName
$qualificationPath = Join-Path $artifactRoot $qualificationName

$branch = (& git -C $root branch --show-current 2>&1) -join ''
Assert-Recovery ($LASTEXITCODE -eq 0 -and $branch -ceq $expectedBranch) `
  'branch changed.'
$head = (& git -C $root rev-parse HEAD 2>&1) -join ''
Assert-Recovery ($LASTEXITCODE -eq 0 -and $head -ceq $expectedHead) `
  'HEAD changed.'

foreach ($required in @(
  $artifactRoot,
  $sourceManifest,
  $generatedApk,
  $mappingFolder,
  $predecessorApk
)) {
  Assert-Recovery (Test-Path -LiteralPath $required) "required owner is missing: $required"
}
foreach ($reserved in @($sealedApk, $provenancePath, $qualificationPath)) {
  Assert-Recovery (-not (Test-Path -LiteralPath $reserved)) `
    "recovery evidence already exists: $reserved"
}
$existingArtifactFiles = @(Get-ChildItem -LiteralPath $artifactRoot -File)
Assert-Recovery (
  $existingArtifactFiles.Count -eq 1 -and
  $existingArtifactFiles[0].Name -ceq 'source-aggregate-manifest.txt'
) 'evidence directory is not at the exact pre-recovery one-file state.'

$sourceRows = @(Get-Content -LiteralPath $sourceManifest)
$sourceSha = (Get-FileHash -LiteralPath $sourceManifest -Algorithm SHA256).Hash
Assert-Recovery (
  $sourceRows.Count -eq $expectedSourceRows -and $sourceSha -ceq $expectedSourceSha
) 'source manifest identity changed.'

$missingOwners = @()
$mismatchedOwners = @()
foreach ($row in $sourceRows) {
  Assert-Recovery ($row -cmatch '^([0-9A-F]{64})  (.+)$') `
    'source manifest row format changed.'
  $expectedOwnerSha = [string]$Matches[1]
  $relativeOwner = [string]$Matches[2]
  $resolvedOwner = Resolve-ReleaseArtifactRepositoryDescendant `
    -RepositoryRoot $root `
    -Path $relativeOwner `
    -Label 'source manifest owner'
  if (-not (Test-Path -LiteralPath $resolvedOwner -PathType Leaf)) {
    $missingOwners += $relativeOwner
    continue
  }
  $actualOwnerSha = (Get-FileHash -LiteralPath $resolvedOwner -Algorithm SHA256).Hash
  if ($actualOwnerSha -cne $expectedOwnerSha) {
    $mismatchedOwners += $relativeOwner
  }
}
$allowedPostBuildControlChanges = @(
  'scripts/build-buy-device-review.ps1',
  'scripts/check-apk-production-plugin-integrity.ps1',
  'scripts/invoke-play-internal-aab-build-c30t.ps1',
  'scripts/new-fix8-r60-81-build-input-manifest.ps1',
  'scripts/test-public-auth-sideload-build-controls.ps1'
)
$actualMismatchSet = @($mismatchedOwners | Sort-Object)
$expectedMismatchSet = @($allowedPostBuildControlChanges | Sort-Object)
Assert-Recovery ($missingOwners.Count -eq 0) 'one or more sealed source owners are missing.'
Assert-Recovery (
  ($actualMismatchSet -join '|') -ceq ($expectedMismatchSet -join '|')
) 'source drift exceeds the exact postbuild verifier/control allowlist.'

$generatedApkItem = Get-Item -LiteralPath $generatedApk
$generatedApkSha = (Get-FileHash -LiteralPath $generatedApk -Algorithm SHA256).Hash
Assert-Recovery (
  $generatedApkItem.Length -eq $expectedApkBytes -and
  $generatedApkSha -ceq $expectedApkSha
) 'preserved generated APK identity changed.'

$pluginGate = Join-Path $root 'scripts\check-apk-production-plugin-integrity.ps1'
$pluginGateOutput = & $pluginGate `
  -ApkPath $generatedApk `
  -CandidateId $candidateId `
  -RepositoryRoot $root `
  -ProguardFolderPath $mappingFolder `
  -RequireMappingAware
Assert-Recovery ($?) 'mapping-aware APK plugin integrity failed.'
Assert-Recovery (
  ($pluginGateOutput -join '').Contains('mappingAware=true') -and
  ($pluginGateOutput -join '').Contains('firebaseCore=true') -and
  ($pluginGateOutput -join '').Contains('integrationTest=false')
) 'mapping-aware APK plugin integrity output is incomplete.'

$sdkRoot = Get-SdkRoot
$apkAnalyzerCandidates = @(
  (Join-Path $sdkRoot 'cmdline-tools\latest\bin\apkanalyzer.bat'),
  (Join-Path $sdkRoot 'cmdline-tools\bin\apkanalyzer.bat')
)
$apkAnalyzers = @($apkAnalyzerCandidates | Where-Object {
  Test-Path -LiteralPath $_ -PathType Leaf
} | Select-Object -First 1)
Assert-Recovery ($apkAnalyzers.Count -eq 1) 'apkanalyzer is unavailable.'
$apkAnalyzer = $apkAnalyzers[0]

$applicationId = ((& $apkAnalyzer manifest application-id $generatedApk 2>&1) -join '').Trim()
Assert-Recovery ($LASTEXITCODE -eq 0 -and $applicationId -ceq 'com.moolsocial.app') `
  'APK application ID is invalid.'
$versionName = ((& $apkAnalyzer manifest version-name $generatedApk 2>&1) -join '').Trim()
Assert-Recovery ($LASTEXITCODE -eq 0 -and $versionName -ceq $expectedVersionName) `
  'APK version name is invalid.'
$versionCode = ((& $apkAnalyzer manifest version-code $generatedApk 2>&1) -join '').Trim()
Assert-Recovery ($LASTEXITCODE -eq 0 -and $versionCode -ceq $expectedVersionCode) `
  'APK version code is invalid.'

$buildToolsRoot = Join-Path $sdkRoot 'build-tools'
$apksigners = @(
  Get-ChildItem -LiteralPath $buildToolsRoot -Directory |
    Where-Object { $_.Name -cmatch '^\d+(?:[.]\d+){1,3}$' } |
    Sort-Object { [version]$_.Name } -Descending |
    ForEach-Object { Join-Path $_.FullName 'apksigner.bat' } |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1
)
Assert-Recovery ($apksigners.Count -eq 1) 'apksigner is unavailable.'
$apksigner = $apksigners[0]

$currentVerify = @(& $apksigner verify --verbose $generatedApk 2>&1)
$currentVerifyExit = $LASTEXITCODE
$predecessorVerify = @(& $apksigner verify --verbose $predecessorApk 2>&1)
$predecessorVerifyExit = $LASTEXITCODE
Assert-Recovery (
  $currentVerifyExit -eq 0 -and $predecessorVerifyExit -eq 0
) 'APK signature verification failed.'

$currentCertOutput = @(& $apksigner verify --print-certs $generatedApk 2>&1)
$currentCertExit = $LASTEXITCODE
$predecessorCertOutput = @(& $apksigner verify --print-certs $predecessorApk 2>&1)
$predecessorCertExit = $LASTEXITCODE
Assert-Recovery (
  $currentCertExit -eq 0 -and $predecessorCertExit -eq 0
) 'APK signer readback failed.'
$currentCertDigests = @(
  $currentCertOutput | Where-Object {
    [string]$_ -cmatch '^Signer #[0-9]+ certificate SHA-256 digest:'
  } | ForEach-Object { ([string]$_).Split(':', 2)[1].Trim() }
)
$predecessorCertDigests = @(
  $predecessorCertOutput | Where-Object {
    [string]$_ -cmatch '^Signer #[0-9]+ certificate SHA-256 digest:'
  } | ForEach-Object { ([string]$_).Split(':', 2)[1].Trim() }
)
Assert-Recovery (
  $currentCertDigests.Count -eq 1 -and
  $predecessorCertDigests.Count -eq 1 -and
  $currentCertDigests[0] -ceq $predecessorCertDigests[0]
) 'APK signer continuity failed.'

$controlOwnerPaths = @(
  $allowedPostBuildControlChanges +
  @(
    'scripts/check-aab-production-plugin-integrity.ps1',
    'scripts/check-android-plugin-manifest-namespace-readiness.ps1',
    'scripts/test-release-production-plugin-integrity.ps1'
  )
)
$controlHashes = [ordered]@{}
foreach ($controlOwner in @($controlOwnerPaths | Sort-Object -Unique)) {
  $controlPath = Resolve-ReleaseArtifactRepositoryDescendant `
    -RepositoryRoot $root `
    -Path $controlOwner `
    -Label 'postbuild control owner'
  Assert-Recovery (Test-Path -LiteralPath $controlPath -PathType Leaf) `
    "postbuild control owner is missing: $controlOwner"
  $controlHashes[$controlOwner] = (
    Get-FileHash -LiteralPath $controlPath -Algorithm SHA256
  ).Hash
}

Copy-Item -LiteralPath $generatedApk -Destination $sealedApk
$sealedItem = Get-Item -LiteralPath $sealedApk
$sealedSha = (Get-FileHash -LiteralPath $sealedApk -Algorithm SHA256).Hash
Assert-Recovery (
  $sealedItem.Length -eq $expectedApkBytes -and $sealedSha -ceq $expectedApkSha
) 'sealed APK copy differs from the qualified generated APK.'

$recoveredAt = [DateTimeOffset]::Now.ToString('o')
@(
  "CandidateId=$candidateId",
  'RecoveryMode=postbuild_mapping_aware_no_rebuild',
  'AdditionalBuildCount=0',
  'TotalBuildCount=2',
  "Version=$versionName",
  "VersionCode=$versionCode",
  'BuildMode=release',
  "Branch=$branch",
  "HEAD=$head",
  "OriginalSourceManifest=$sourceManifestRelative",
  "OriginalSourceFingerprint=$sourceSha",
  "OriginalSourceRows=$($sourceRows.Count)",
  'OriginalAppRuntimeOwnersUnchanged=true',
  "PostBuildControlMismatchCount=$($actualMismatchSet.Count)",
  'MappingAwarePluginIntegrity=true',
  'GeneratedPluginRegistrant=true',
  'FirebaseCorePlugin=true',
  'MainActivity=true',
  'IntegrationTest=false',
  'ApkSignatureValid=true',
  'SignerMatchesPreservedR60_80=true',
  "APK=$sealedApk",
  "Bytes=$($sealedItem.Length)",
  "SHA256=$sealedSha",
  "RecoveredAt=$recoveredAt"
) | Set-Content -LiteralPath $provenancePath -Encoding utf8

$qualification = [ordered]@{
  schemaVersion = 1
  state = 'qualified_recovered_postbuild_mapping_aware_no_rebuild'
  candidateId = $candidateId
  packageName = $applicationId
  versionName = $versionName
  versionCode = $versionCode
  buildMode = 'release'
  source = [ordered]@{
    manifestPath = $sourceManifestRelative.Replace('\', '/')
    manifestSha256 = $sourceSha
    fileCount = $sourceRows.Count
    missingOwnerCount = $missingOwners.Count
    postBuildControlMismatchCount = $actualMismatchSet.Count
    postBuildControlMismatches = $actualMismatchSet
    appRuntimeOwnersUnchanged = $true
  }
  artifact = [ordered]@{
    path = (Join-Path $artifactRelative $sealedApkName).Replace('\', '/')
    bytes = $sealedItem.Length
    sha256 = $sealedSha
    signatureValid = $true
    signerMatchesPreservedR60_80 = $true
    mappingAwarePluginIntegrity = $true
    generatedPluginRegistrantPresent = $true
    firebaseCorePluginPresent = $true
    mainActivityPresent = $true
    integrationTestAbsent = $true
  }
  recovery = [ordered]@{
    incident = 'REG-20260822-3205-R60-81-POSTBUILD-FIREBASE-CORE-PLUGIN-INTEGRITY-REJECTION'
    rootCause = 'unmapped_apkanalyzer_false_negative_for_R8_renamed_Firebase_Core_class'
    additionalBuildCount = 0
    totalBuildCount = 2
    installCount = 0
    deviceActionCount = 0
    postBuildControlHashes = $controlHashes
  }
  authority = [ordered]@{
    buildAuthorized = $false
    buildAuthorizationConsumed = $true
    installAuthorizationConsumed = $false
    privateProviderLoginAuthorized = $false
    playOrProductionAuthorized = $false
  }
  recoveredAt = $recoveredAt
}
$qualification | ConvertTo-Json -Depth 20 |
  Set-Content -LiteralPath $qualificationPath -Encoding utf8

Write-Output (
  'FIX8 r60.81 postbuild artifact recovered without rebuild: ' +
  "package=$applicationId; version=$versionName+$versionCode; " +
  "bytes=$($sealedItem.Length); sha256=$sealedSha; " +
  'signature=true; signerContinuity=true; mappingAware=true; ' +
  'integrationTest=false; additionalBuildCount=0; installCount=0.'
)
