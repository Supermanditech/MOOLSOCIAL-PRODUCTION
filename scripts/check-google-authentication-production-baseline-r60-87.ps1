[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$baselinePath = Join-Path $root `
  'config/google-authentication-production-baseline-r60-87.json'
$lockPath = Join-Path $root `
  'config/google-authentication-production-baseline-r60-87.lock.json'

function Assert-GoogleBaseline([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Google authentication r60.87 baseline rejected: $Message"
  }
}

function Resolve-GoogleBaselineOwner([string]$RelativePath) {
  Assert-GoogleBaseline `
    (-not [IO.Path]::IsPathRooted($RelativePath) -and
      -not $RelativePath.Contains('..', [StringComparison]::Ordinal)) `
    'a baseline owner is not repository-relative.'
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-GoogleBaseline `
    ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) `
    'a baseline owner escaped the repository.'
  Assert-GoogleBaseline (Test-Path -LiteralPath $resolved -PathType Leaf) `
    "a baseline owner is missing: $RelativePath"
  return $resolved
}

Assert-GoogleBaseline (Test-Path -LiteralPath $baselinePath -PathType Leaf) `
  'the baseline record is missing.'
Assert-GoogleBaseline (Test-Path -LiteralPath $lockPath -PathType Leaf) `
  'the baseline lock is missing.'
$baseline = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json
$lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json

Assert-GoogleBaseline ([int]$baseline.schemaVersion -eq 1) `
  'the baseline schema changed.'
Assert-GoogleBaseline ([string]$baseline.scope -ceq 'google_sign_in_only') `
  'the baseline escaped Google-only scope.'
Assert-GoogleBaseline `
  ([string]$baseline.status -ceq 'LOCKED_GOOGLE_AUTH_ACCEPTED') `
  'the accepted status changed.'
Assert-GoogleBaseline `
  ((Get-FileHash -LiteralPath $baselinePath -Algorithm SHA256).Hash -ceq
    [string]$lock.baselineSha256) `
  'the baseline record changed after locking.'
Assert-GoogleBaseline `
  ((Get-FileHash -LiteralPath $MyInvocation.MyCommand.Path `
      -Algorithm SHA256).Hash -ceq [string]$lock.checkerSha256) `
  'the baseline checker changed after locking.'

$branch = (git -C $root branch --show-current).Trim()
$head = (git -C $root rev-parse HEAD).Trim()
Assert-GoogleBaseline ($branch -ceq [string]$baseline.branch) `
  'the branch differs from the accepted baseline.'
$acceptedTagName = 'moolsocial-google-auth-r60.87-accepted-20260823'
if ($head -cne [string]$baseline.head) {
  $taggedHead = (git -C $root rev-parse "$acceptedTagName^{commit}" 2>$null).Trim()
  Assert-GoogleBaseline ($LASTEXITCODE -eq 0 -and $taggedHead -ceq $head) `
    'HEAD is neither the build-time anchor nor the accepted r60.87 tag.'
  $tagType = (git -C $root cat-file -t $acceptedTagName 2>$null).Trim()
  Assert-GoogleBaseline ($LASTEXITCODE -eq 0 -and $tagType -ceq 'tag') `
    'the accepted r60.87 tag is missing or not annotated.'
  & git -C $root merge-base --is-ancestor ([string]$baseline.head) $head
  Assert-GoogleBaseline ($LASTEXITCODE -eq 0) `
    'the accepted r60.87 Git baseline is not descended from its build anchor.'
}

$apk = Resolve-GoogleBaselineOwner ([string]$baseline.candidate.artifactPath)
Assert-GoogleBaseline `
  ((Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash -ceq
    [string]$baseline.candidate.artifactSha256) `
  'the accepted APK hash changed.'
Assert-GoogleBaseline `
  ((Get-Item -LiteralPath $apk).Length -eq [long]$baseline.candidate.artifactBytes) `
  'the accepted APK byte count changed.'

$manifest = Resolve-GoogleBaselineOwner `
  ([string]$baseline.sourceSeal.manifestPath)
Assert-GoogleBaseline `
  ((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash -ceq
    [string]$baseline.sourceSeal.manifestSha256) `
  'the accepted source-manifest hash changed.'
$manifestLines = @(Get-Content -LiteralPath $manifest)
Assert-GoogleBaseline `
  ($manifestLines.Count -eq [int]$baseline.sourceSeal.ownerCount) `
  'the accepted source owner count changed.'
$generatedExclusions = @(
  $baseline.sourceSeal.postBuildGeneratedOwnerExclusions |
    ForEach-Object { [string]$_ }
)
$localRuntimeConfigurationExclusions = @(
  $baseline.sourceSeal.localRuntimeConfigurationExclusions |
    ForEach-Object { [string]$_ }
)
$administrativeExclusions = @(
  $baseline.sourceSeal.postAcceptanceAdministrativeOwnerExclusions |
    ForEach-Object { [string]$_ }
)
$generatedExclusionCount = 0
$localRuntimeConfigurationExclusionCount = 0
$administrativeExclusionCount = 0
foreach ($line in $manifestLines) {
  Assert-GoogleBaseline ($line -cmatch '^([0-9A-F]{64})  ([^\r\n]+)$') `
    'the accepted source manifest contains a malformed row.'
  $expectedHash = $Matches[1]
  $relativeOwner = $Matches[2]
  if ($localRuntimeConfigurationExclusions -ccontains $relativeOwner) {
    $localRuntimeConfigurationExclusionCount++
    $localRuntimeConfigurationOwner = Resolve-GoogleBaselineOwner $relativeOwner
    Assert-GoogleBaseline `
      ((Get-FileHash -LiteralPath $localRuntimeConfigurationOwner `
          -Algorithm SHA256).Hash -ceq $expectedHash) `
      'the founder-held local Firebase Android configuration differs from the accepted r60.87 build input.'
    continue
  }
  $owner = Resolve-GoogleBaselineOwner $relativeOwner
  if ($generatedExclusions -ccontains $relativeOwner) {
    $generatedExclusionCount++
    continue
  }
  if ($administrativeExclusions -ccontains $relativeOwner) {
    $administrativeExclusionCount++
    continue
  }
  Assert-GoogleBaseline `
    ((Get-FileHash -LiteralPath $owner -Algorithm SHA256).Hash -ceq
      $expectedHash) `
    'an accepted source owner changed.'
}
Assert-GoogleBaseline `
  ($generatedExclusionCount -eq 1 -and $generatedExclusions.Count -eq 1) `
  'the exact post-build generated-owner disposition changed.'
Assert-GoogleBaseline `
  ($localRuntimeConfigurationExclusionCount -eq 1 -and
    $localRuntimeConfigurationExclusions.Count -eq 1 -and
    $localRuntimeConfigurationExclusions[0] -ceq
      'apps/mobile/android/app/google-services.json') `
  'the exact founder-held local Firebase Android configuration disposition changed.'
Assert-GoogleBaseline `
  ($administrativeExclusionCount -eq 1 -and
    $administrativeExclusions.Count -eq 1 -and
    $administrativeExclusions[0] -ceq
      'scripts/check-codex-subagent-coordination-policy.ps1') `
  'the exact post-acceptance administrative-owner disposition changed.'

$coordinationPolicyPath = Resolve-GoogleBaselineOwner `
  'config/codex-subagent-coordination-policy.json'
$registryPath = Resolve-GoogleBaselineOwner `
  'config/codex-development-regression-registry.json'
$coordinationPolicy = Get-Content -LiteralPath $coordinationPolicyPath -Raw |
  ConvertFrom-Json
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
Assert-GoogleBaseline `
  ([string]$coordinationPolicy.policyId -ceq
      'MOOLSOCIAL-CODEX-SUBAGENT-COORDINATION-001' -and
    [string]$coordinationPolicy.state -ceq
      'mandatory_before_every_subagent_action' -and
    [int]$coordinationPolicy.registryBinding.entryCount -eq
      @($registry.entries).Count -and
    [string]$coordinationPolicy.registryBinding.sha256 -ceq
      (Get-FileHash -LiteralPath $registryPath -Algorithm SHA256).Hash -and
    [bool]$coordinationPolicy.releaseSerialization.primaryIsSingleActionCoordinator -and
    -not [bool]$coordinationPolicy.releaseSerialization.parallelRealActionsAllowed) `
  'the post-acceptance coordination policy or registry binding is invalid.'

foreach ($seal in @($baseline.componentSeals)) {
  $owner = Resolve-GoogleBaselineOwner ([string]$seal.path)
  Assert-GoogleBaseline `
    ((Get-FileHash -LiteralPath $owner -Algorithm SHA256).Hash -ceq
      [string]$seal.sha256) `
    "a Google baseline component changed: $($seal.path)"
}

foreach ($ticketSeal in @($baseline.p0Tickets)) {
  $ticketPath = Resolve-GoogleBaselineOwner ([string]$ticketSeal.path)
  $ticket = Get-Content -LiteralPath $ticketPath -Raw | ConvertFrom-Json
  Assert-GoogleBaseline `
    ([string]$ticket.ticketId -ceq [string]$ticketSeal.ticketId -and
      [string]$ticket.state -ceq [string]$ticketSeal.state -and
      [string]$ticket.classification -ceq [string]$ticketSeal.classification) `
    "a P0 ticket disposition changed: $($ticketSeal.ticketId)"
}

$acceptancePath = Resolve-GoogleBaselineOwner `
  ([string]$baseline.runtimeAcceptance.path)
$acceptance = Get-Content -LiteralPath $acceptancePath -Raw | ConvertFrom-Json
Assert-GoogleBaseline `
  ([string]$acceptance.decision -ceq 'GOOGLE_SIGN_IN_ACCEPTED_ON_OPPO') `
  'the OPPO acceptance decision changed.'
Assert-GoogleBaseline `
  (@($acceptance.acceptanceRequirements | Where-Object {
    [string]$_.status -ceq 'PASS'
  }).Count -eq 4) `
  'the four OPPO acceptance requirements are not all passed.'
Assert-GoogleBaseline `
  ([bool]$acceptance.deviceResult.moolSocialAuthenticatedStateReached -and
    [bool]$acceptance.deviceResult.coldRelaunchAuthenticatedStateRestored -and
    [int]$acceptance.deviceResult.fatalOrAnrCount -eq 0) `
  'the authenticated OPPO result or persistence evidence changed.'

& (Join-Path $root `
  'scripts/check-google-authentication-production-traceability-map.ps1') `
  -RepositoryRoot $root | Out-Null
Assert-GoogleBaseline $? 'the production traceability map rejected.'

$propertiesPath = Join-Path $root 'apps/mobile/android/local.properties'
$sdkRoot = $env:ANDROID_SDK_ROOT
if ([string]::IsNullOrWhiteSpace($sdkRoot) -and
    (Test-Path -LiteralPath $propertiesPath -PathType Leaf)) {
  $sdkLine = Get-Content -LiteralPath $propertiesPath |
    Where-Object { $_.StartsWith('sdk.dir=') } | Select-Object -First 1
  if ($sdkLine) {
    $sdkRoot = $sdkLine.Substring('sdk.dir='.Length).
      Replace('\:', ':').Replace('\\', '\')
  }
}
Assert-GoogleBaseline (-not [string]::IsNullOrWhiteSpace($sdkRoot)) `
  'the Android SDK is unresolved.'
$apkAnalyzer = Join-Path $sdkRoot `
  'cmdline-tools/latest/bin/apkanalyzer.bat'
Assert-GoogleBaseline (Test-Path -LiteralPath $apkAnalyzer -PathType Leaf) `
  'apkanalyzer is unavailable.'
$buildTools = Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'build-tools') `
  -Directory | Sort-Object Name -Descending | Select-Object -First 1
Assert-GoogleBaseline ($null -ne $buildTools) 'Android build-tools are unavailable.'
$apkSigner = Join-Path $buildTools.FullName 'apksigner.bat'
Assert-GoogleBaseline (Test-Path -LiteralPath $apkSigner -PathType Leaf) `
  'apksigner is unavailable.'

$packageName = (& $apkAnalyzer manifest application-id $apk 2>$null).Trim()
$versionName = (& $apkAnalyzer manifest version-name $apk 2>$null).Trim()
$versionCode = (& $apkAnalyzer manifest version-code $apk 2>$null).Trim()
Assert-GoogleBaseline `
  ($packageName -ceq [string]$baseline.candidate.packageName -and
    $versionName -ceq [string]$baseline.candidate.versionName -and
    $versionCode -ceq [string]$baseline.candidate.versionCode) `
  'the accepted APK package or version changed.'
& $apkSigner verify --verbose $apk *> $null
Assert-GoogleBaseline ($LASTEXITCODE -eq 0) 'the accepted APK signature is invalid.'

$referenceApk = Resolve-GoogleBaselineOwner `
  ([string]$baseline.candidate.signerReferencePath)
$candidateSigner = @(& $apkSigner verify --print-certs $apk 2>$null |
  Where-Object { $_ -like 'Signer #1 certificate SHA-256 digest:*' })
$referenceSigner = @(& $apkSigner verify --print-certs $referenceApk 2>$null |
  Where-Object { $_ -like 'Signer #1 certificate SHA-256 digest:*' })
Assert-GoogleBaseline `
  ($candidateSigner.Count -eq 1 -and $referenceSigner.Count -eq 1 -and
    $candidateSigner[0] -ceq $referenceSigner[0]) `
  'the accepted APK signer differs from the corrected signer.'
$candidateSigner = $null
$referenceSigner = $null

Assert-GoogleBaseline `
  ([int]$baseline.postInstallGoogleLogAudit.blockingIssueCount -eq 0 -and
    [int]$baseline.postInstallGoogleLogAudit.fatalOrAnrCount -eq 0 -and
    -not [bool]$baseline.postInstallGoogleLogAudit.privateValuesRecorded) `
  'the sealed Google log audit is not clean.'
Assert-GoogleBaseline `
  (-not [bool]$baseline.baselineRules.newBuildOrInstallAuthorized -and
    [bool]$baseline.baselineRules.otherProvidersHeld) `
  'the locked action boundary changed.'

Write-Output (
  'Google authentication r60.87 baseline passed: locked=true; ' +
  'sourceOwners=652; package=com.moolsocial.app; version=1.0.0-r60.87; ' +
  'oppoAccepted=true; persistence=true; googleBlockingIssues=0; ' +
  'otherProvidersHeld=true; credentialValuesEmitted=false.'
)
