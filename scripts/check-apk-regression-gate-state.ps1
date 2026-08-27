[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$StatePath,

  [Parameter(Mandatory)]
  [string]$CandidateId,

  [Parameter(Mandatory)]
  [string]$BuildName,

  [Parameter(Mandatory)]
  [string]$BuildNumber,

  [Parameter(Mandatory)]
  [ValidateSet('debug', 'profile', 'release')]
  [string]$BuildMode,

  [Parameter(Mandatory)]
  [string]$SourceFingerprint,

  [Parameter(Mandatory)]
  [string[]]$RuntimeDefine
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = [IO.Path]::GetFullPath(
  (Split-Path -Parent $PSScriptRoot)
)
$resolvedStatePath = [IO.Path]::GetFullPath($StatePath)

function Assert-Gate {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "APK regression pre-build gate rejected: $Message"
  }
}

Assert-Gate -Condition $resolvedStatePath.StartsWith(
  $repositoryRoot,
  [StringComparison]::OrdinalIgnoreCase
) -Message 'machine state must stay inside the production repository.'
Assert-Gate -Condition (Test-Path -LiteralPath $resolvedStatePath -PathType Leaf) `
  -Message "machine state is missing: $resolvedStatePath"

$state = Get-Content -Raw -LiteralPath $resolvedStatePath | ConvertFrom-Json
Assert-Gate -Condition ([int]$state.schemaVersion -eq 1) `
  -Message 'unsupported machine-state schema.'
Assert-Gate -Condition (
  [string]$state.contractId -ceq 'APK-BUILD-REGRESSION-GATES-001'
) -Message 'unexpected machine-state contract id.'
$cursorUiReview = [string]$state.candidate.gateProfile -ceq `
  'uaw_cursor_ui_review_debug'
if (-not $cursorUiReview) {
  Assert-Gate -Condition (
    [string]$state.requiredRuntimeDefines.MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL `
      -ceq 'https://moolsocial.com/app'
  ) -Message 'Email Link continue URL differs from the authorized exact-return route.'
  Assert-Gate -Condition (
    [string]$state.requiredRuntimeDefines.MOOLSOCIAL_EMAIL_LINK_DOMAIN `
      -ceq ''
  ) -Message 'Dev Email Link must omit linkDomain so Firebase selects its default Hosting domain.'
}

$fix11GoogleOnly = $CandidateId -ceq
  'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR'
if ($fix11GoogleOnly) {
  Assert-Gate -Condition (
    [bool]$state.fix11SuccessorPreflight.externalGoogleProviderReadbackEstablished
  ) -Message 'FIX11 Dev Google provider evidence is not established.'
  $fix11RequiredFacts = [ordered]@{
    MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE = 'true'
    MOOLSOCIAL_GOOGLE_PROVIDER_QUALIFIED = 'true'
    MOOLSOCIAL_SIDELOAD_PREFLIGHT_ENABLED = 'true'
    MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED = 'true'
    MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW = 'false'
    MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF = 'false'
    MOOLSOCIAL_YOUTUBE_PROVIDER_URL = ''
    MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED = 'false'
    MOOLSOCIAL_YOUTUBE_SHORTS_AUTOPLAY_ENABLED = 'false'
    MOOLSOCIAL_PHONE_OTP_ENABLED = 'false'
    MOOLSOCIAL_APPLE_ENABLED = 'false'
    MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED = 'false'
    MOOLSOCIAL_INSTAGRAM_ENABLED = 'false'
    MOOLSOCIAL_FACEBOOK_ENABLED = 'false'
  }
  foreach ($fact in $fix11RequiredFacts.GetEnumerator()) {
    Assert-Gate -Condition (
      [string]$state.requiredRuntimeDefines.($fact.Key) -ceq
        [string]$fact.Value
    ) -Message "FIX11 runtime fact '$($fact.Key)' is not exact."
  }
}

$fullSocialCohortNames = @(
  'MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED',
  'MOOLSOCIAL_X_CLIENT_ID_CONFIGURED',
  'MOOLSOCIAL_X_EXACT_REDIRECT_QUALIFIED',
  'MOOLSOCIAL_X_FIREBASE_BROKER_QUALIFIED',
  'MOOLSOCIAL_INSTAGRAM_ENABLED',
  'MOOLSOCIAL_INSTAGRAM_PROFESSIONAL_LOGIN_QUALIFIED',
  'MOOLSOCIAL_INSTAGRAM_EXACT_REDIRECT_QUALIFIED',
  'MOOLSOCIAL_INSTAGRAM_FIREBASE_BROKER_QUALIFIED',
  'MOOLSOCIAL_INSTAGRAM_REVOCATION_QUALIFIED',
  'MOOLSOCIAL_FACEBOOK_ENABLED',
  'MOOLSOCIAL_FACEBOOK_PROVIDER_QUALIFIED',
  'MOOLSOCIAL_FACEBOOK_ANDROID_CONFIGURATION_QUALIFIED',
  'MOOLSOCIAL_FACEBOOK_REVOCATION_QUALIFIED',
  'MOOLSOCIAL_FACEBOOK_DATA_DELETION_QUALIFIED'
)
$fullSocialRequested = @(
  $fullSocialCohortNames | Where-Object {
    [string]$state.requiredRuntimeDefines.$_ -ceq 'true'
  }
).Count -gt 0
if ($fullSocialRequested) {
  foreach ($name in $fullSocialCohortNames) {
    Assert-Gate -Condition (
      [string]$state.requiredRuntimeDefines.$name -ceq 'true'
    ) -Message "full-social runtime cohort is partial at '$name'."
  }
  $fullSocialRequiredFacts = [ordered]@{
    MOOLSOCIAL_GOOGLE_PROVIDER_QUALIFIED = 'true'
    MOOLSOCIAL_SIDELOAD_PREFLIGHT_ENABLED = 'true'
    MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT = 'true'
    MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED = 'true'
    MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW = 'false'
    MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF = 'true'
    MOOLSOCIAL_YOUTUBE_PROVIDER_URL =
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeProvider'
    MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED = 'true'
    MOOLSOCIAL_YOUTUBE_SHORTS_AUTOPLAY_ENABLED = 'false'
    MOOLSOCIAL_CHAT_URL =
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialChat'
  }
  foreach ($fact in $fullSocialRequiredFacts.GetEnumerator()) {
    Assert-Gate -Condition (
      [string]$state.requiredRuntimeDefines.($fact.Key) -ceq
        [string]$fact.Value
    ) -Message "full-social runtime fact '$($fact.Key)' is not exact."
  }
}

$mvpScopeGate = Join-Path $PSScriptRoot 'check-mvp-scope-gate-state.ps1'
Assert-Gate -Condition (
  Test-Path -LiteralPath $mvpScopeGate -PathType Leaf
) -Message 'MVP scope machine gate is missing.'
$mvpScopeState = Join-Path `
  $repositoryRoot `
  'config/mvp-scope-gate-state.json'
& $mvpScopeGate `
  -StatePath $mvpScopeState `
  -CandidateId $CandidateId `
  -RequireExecutionAuthorized `
  -RepositoryRoot $repositoryRoot

$motionPolicyGate = Join-Path `
  $PSScriptRoot `
  'check-buy-premium-motion-policy-state.ps1'
Assert-Gate -Condition (
  Test-Path -LiteralPath $motionPolicyGate -PathType Leaf
) -Message 'premium-motion policy machine gate is missing.'
& $motionPolicyGate `
  -StatePath $resolvedStatePath `
  -RepositoryRoot $repositoryRoot

Assert-Gate -Condition (
  [string]$state.machineState -ceq 'prebuild_passed'
) -Message "machine state is '$($state.machineState)', not 'prebuild_passed'."
Assert-Gate -Condition (
  [string]$state.buildAuthorization -ceq 'approved_for_one_build'
) -Message 'one-build authorization is not recorded.'
Assert-Gate -Condition (
  [string]$state.preBuildValidation.state -ceq 'passed'
) -Message 'pre-build validation result is not sealed as passed.'

$branch = (git -C $repositoryRoot branch --show-current).Trim()
Assert-Gate -Condition ($LASTEXITCODE -eq 0 -and $branch.Length -gt 0) `
  -Message 'current branch could not be identified.'
$head = (git -C $repositoryRoot rev-parse HEAD).Trim()
Assert-Gate -Condition ($LASTEXITCODE -eq 0 -and $head.Length -gt 0) `
  -Message 'current HEAD could not be identified.'
Assert-Gate -Condition ($branch -cne 'main') `
  -Message 'APK builds are forbidden on main.'
Assert-Gate -Condition ($branch -ceq [string]$state.candidate.branch) `
  -Message 'branch differs from the registered candidate.'
Assert-Gate -Condition ($head -ceq [string]$state.candidate.head) `
  -Message 'HEAD differs from the registered candidate.'

Assert-Gate -Condition ($CandidateId -ceq [string]$state.candidate.id) `
  -Message 'candidate id differs from machine state.'
Assert-Gate -Condition ($BuildName -ceq [string]$state.candidate.versionName) `
  -Message 'version name differs from machine state.'
Assert-Gate -Condition ($BuildNumber -ceq [string]$state.candidate.versionCode) `
  -Message 'version code differs from machine state.'
Assert-Gate -Condition ($BuildMode -ceq [string]$state.candidate.buildMode) `
  -Message 'build mode differs from machine state.'
Assert-Gate -Condition (
  $SourceFingerprint -ceq [string]$state.source.manifestSha256
) -Message 'source fingerprint differs from machine state.'

$manifestPath = [IO.Path]::GetFullPath(
  (Join-Path $repositoryRoot ([string]$state.source.manifestPath))
)
Assert-Gate -Condition $manifestPath.StartsWith(
  $repositoryRoot,
  [StringComparison]::OrdinalIgnoreCase
) -Message 'source manifest escaped the production repository.'
Assert-Gate -Condition (Test-Path -LiteralPath $manifestPath -PathType Leaf) `
  -Message "source manifest is missing: $manifestPath"
$manifestHash = (
  Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256
).Hash
Assert-Gate -Condition (
  $manifestHash -ceq [string]$state.source.manifestSha256
) -Message 'live source-manifest checksum differs from machine state.'
$manifestLines = @(Get-Content -LiteralPath $manifestPath)
Assert-Gate -Condition (
  $manifestLines.Count -eq [int]$state.source.fileCount
) -Message 'source-manifest file count differs from machine state.'
$repositoryPrefix = $repositoryRoot.TrimEnd(
  [char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
) + [IO.Path]::DirectorySeparatorChar
$manifestOwners = [System.Collections.Generic.HashSet[string]]::new(
  [StringComparer]::OrdinalIgnoreCase
)
foreach ($line in $manifestLines) {
  Assert-Gate -Condition (
    $line -cmatch '^([0-9A-F]{64})  ([^\r\n]+)$'
  ) -Message 'source manifest contains a malformed row.'
  $expectedOwnerHash = $Matches[1]
  $relativeOwner = $Matches[2]
  Assert-Gate -Condition (
    -not [IO.Path]::IsPathRooted($relativeOwner) -and
    -not $relativeOwner.Contains('..', [StringComparison]::Ordinal)
  ) -Message "source manifest contains a non-canonical owner: $relativeOwner"
  $resolvedOwner = [IO.Path]::GetFullPath(
    (Join-Path $repositoryRoot $relativeOwner)
  )
  Assert-Gate -Condition (
    $resolvedOwner.StartsWith(
      $repositoryPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message "source manifest owner escaped the repository: $relativeOwner"
  Assert-Gate -Condition ($manifestOwners.Add($resolvedOwner)) `
    -Message "source manifest contains a duplicate owner: $relativeOwner"
  Assert-Gate -Condition (
    Test-Path -LiteralPath $resolvedOwner -PathType Leaf
  ) -Message "source manifest owner is missing: $relativeOwner"
  $liveOwnerHash = (
    Get-FileHash -LiteralPath $resolvedOwner -Algorithm SHA256
  ).Hash
  Assert-Gate -Condition ($liveOwnerHash -ceq $expectedOwnerHash) `
    -Message "source manifest owner changed: $relativeOwner"
}

$requiredGateIds = @(
  'branch-head',
  'source-manifest',
  'format-analysis',
  'focused-tests',
  'positive-release-gates',
  'protected-boundary-disposition',
  'rejected-candidate-preserved',
  'startup-config-regression-registered'
)
$gateProfile = [string]$state.candidate.gateProfile
if ($CandidateId.StartsWith('BUY-', [StringComparison]::Ordinal)) {
  Assert-Gate -Condition (
    [string]::IsNullOrWhiteSpace($gateProfile) -or
    $gateProfile -ceq 'buy_device_review'
  ) -Message "unsupported Buy candidate gate profile '$gateProfile'."
  $requiredGateIds += @('buy-regression-1', 'buy-regression-2')
} elseif ($CandidateId.StartsWith('UAW-', [StringComparison]::Ordinal)) {
  if ($gateProfile -ceq 'uaw_personal_r01_r15_cumulative') {
    $requiredGateIds += @(
      'buy-regression-1',
      'buy-regression-2',
      'personal-regression-1',
      'personal-regression-2',
      'qualified-mobile-regression-1',
      'qualified-mobile-regression-2',
      'legacy-regression-disposition',
      'clean-state-regression',
      'wrapper-self-test'
    )
  } elseif ($gateProfile -ceq 'uaw_cursor_ui_review_debug') {
    $requiredGateIds += @(
      'buy-regression-1',
      'buy-regression-2',
      'clean-state-regression',
      'wrapper-self-test',
      'package-isolation'
    )
  } elseif (
    $gateProfile -ceq 'uaw_public_auth_sideload_preflight' -or
    $gateProfile -ceq 'uaw_fix11_google_only_sideload_preflight'
  ) {
    $requiredGateIds += @(
      'auth-regression-1',
      'auth-regression-2',
      'runtime-config-fail-closed',
      'bootstrap-stage-diagnosis',
      'device-cold-start-policy',
      'local-signing-provider-registration',
      'app-check-sideload-disposition',
      'android-release-resource-integrity',
      'clean-state-regression',
      'wrapper-self-test'
    )
    if ($gateProfile -ceq 'uaw_fix11_google_only_sideload_preflight') {
      $requiredGateIds += 'fix11-google-forensic'
    }
  } else {
    Assert-Gate -Condition $false `
      -Message "unsupported UAW candidate gate profile '$gateProfile'."
  }
} else {
  Assert-Gate -Condition $false `
    -Message "unsupported candidate family '$CandidateId'."
}
$preBuildValidationEvidence = [IO.Path]::GetFullPath(
  (Join-Path $repositoryRoot ([string]$state.preBuildValidation.evidence))
)
Assert-Gate -Condition (Test-Path -LiteralPath $preBuildValidationEvidence -PathType Leaf) `
  -Message 'sealed pre-build validation evidence is missing.'
$registeredGateIds = @($state.preBuildGates | ForEach-Object { [string]$_.id })
Assert-Gate -Condition (
  $registeredGateIds.Count -eq (@($registeredGateIds | Select-Object -Unique)).Count
) -Message 'pre-build gate ids are not unique.'

foreach ($gateId in $requiredGateIds) {
  $gate = @($state.preBuildGates | Where-Object { $_.id -ceq $gateId })
  Assert-Gate -Condition ($gate.Count -eq 1) `
    -Message "required pre-build gate '$gateId' is missing or duplicated."
  Assert-Gate -Condition ([string]$gate[0].state -ceq 'passed') `
    -Message "required pre-build gate '$gateId' is not passed."
  $evidencePaths = @($gate[0].evidence)
  Assert-Gate -Condition ($evidencePaths.Count -gt 0) `
    -Message "required pre-build gate '$gateId' has no evidence."
  foreach ($evidencePath in $evidencePaths) {
    $resolvedEvidencePath = [IO.Path]::GetFullPath(
      (Join-Path $repositoryRoot ([string]$evidencePath))
    )
    Assert-Gate -Condition $resolvedEvidencePath.StartsWith(
      $repositoryRoot,
      [StringComparison]::OrdinalIgnoreCase
    ) -Message "evidence for '$gateId' escaped the repository."
    Assert-Gate -Condition (Test-Path -LiteralPath $resolvedEvidencePath) `
      -Message "evidence for '$gateId' is missing: $resolvedEvidencePath"
  }
}

$actualByName = @{}
foreach ($runtimeDefine in $RuntimeDefine) {
  $parts = $runtimeDefine.Split('=', 2)
  Assert-Gate -Condition ($parts.Count -eq 2 -and $parts[0].Length -gt 0) `
    -Message 'runtime define is malformed.'
  Assert-Gate -Condition (-not $actualByName.ContainsKey($parts[0])) `
    -Message "runtime define '$($parts[0])' is duplicated."
  $actualByName[$parts[0]] = $parts[1]
}
$exactProperties = @($state.requiredRuntimeDefines.PSObject.Properties)
$requiresSocialContentEndpoint = (
  $CandidateId.Contains('SOCIAL', [StringComparison]::OrdinalIgnoreCase) -and
  [string]$state.requiredRuntimeDefines.MOOLSOCIAL_USE_EMULATORS -ceq 'false'
)
if ($requiresSocialContentEndpoint) {
  $socialContentProperty = $state.requiredRuntimeDefines.PSObject.Properties[
    'MOOLSOCIAL_SOCIAL_CONTENT_URL'
  ]
  Assert-Gate -Condition ($null -ne $socialContentProperty) `
    -Message 'Social content endpoint is missing from machine state.'
  $firebaseProjectId = [string]$state.firebaseClientConfiguration.projectId
  Assert-Gate -Condition (
    -not [string]::IsNullOrWhiteSpace($firebaseProjectId)
  ) -Message 'Firebase project id is missing for the Social content endpoint.'
  $expectedSocialContentUrl = (
    "https://asia-south1-$firebaseProjectId.cloudfunctions.net/moolSocialContent"
  )
  Assert-Gate -Condition (
    [string]$socialContentProperty.Value -ceq $expectedSocialContentUrl
  ) -Message 'Social content endpoint differs from the registered environment.'
}
$requiredNonEmptyNames = if (
  $state.PSObject.Properties.Name -contains 'requiredNonEmptyRuntimeDefines'
) {
  @($state.requiredNonEmptyRuntimeDefines | ForEach-Object { [string]$_ })
} else {
  @()
}
$expectedNames = @(
  @($exactProperties | ForEach-Object { [string]$_.Name }) +
  $requiredNonEmptyNames |
    Sort-Object -Unique
)
$actualNames = @($actualByName.Keys | Sort-Object -Unique)
Assert-Gate -Condition (
  ($expectedNames -join ';') -ceq ($actualNames -join ';')
) -Message 'runtime define names differ from the exact registered allowlist.'
foreach ($property in $exactProperties) {
  Assert-Gate -Condition (
    [string]$actualByName[[string]$property.Name] -ceq [string]$property.Value
  ) -Message "runtime define '$($property.Name)' differs from machine state."
}
foreach ($requiredName in $requiredNonEmptyNames) {
  Assert-Gate -Condition (
    -not [string]::IsNullOrWhiteSpace([string]$actualByName[$requiredName])
  ) -Message "runtime define '$requiredName' must be present and non-empty."
}

$allowedDefineNames = @(
  'MOOLSOCIAL_CANDIDATE_ID',
  'MOOLSOCIAL_DEVICE_REVIEW',
  'MOOLSOCIAL_USE_EMULATORS',
  'MOOLSOCIAL_UI_REVIEW_ONLY',
  'MOOLSOCIAL_YOUTUBE_PUBLIC_REVIEW',
  'MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF',
  'MOOLSOCIAL_YOUTUBE_PROVIDER_URL',
  'MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED',
  'MOOLSOCIAL_YOUTUBE_SHORTS_AUTOPLAY_ENABLED',
  'MOOLSOCIAL_SOCIAL_CONTENT_URL',
  'MOOLSOCIAL_CHAT_URL',
  'MOOLSOCIAL_FIREBASE_API_KEY',
  'MOOLSOCIAL_FIREBASE_APP_ID',
  'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
  'MOOLSOCIAL_FIREBASE_PROJECT_ID',
  'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
  'MOOLSOCIAL_AUTH_API_BASE_URL',
  'MOOLSOCIAL_X_CALLBACK_URL',
  'MOOLSOCIAL_X_AUTHORIZATION_ENDPOINT',
  'MOOLSOCIAL_INSTAGRAM_CALLBACK_URL',
  'MOOLSOCIAL_INSTAGRAM_AUTHORIZATION_ENDPOINT',
  'MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL',
  'MOOLSOCIAL_EMAIL_LINK_DOMAIN',
  'MOOLSOCIAL_FACEBOOK_GRAPH_REVOCATION_ENDPOINT',
  'MOOLSOCIAL_GOOGLE_PROVIDER_QUALIFIED',
  'MOOLSOCIAL_GOOGLE_PLAY_SIGNING_QUALIFIED',
  'MOOLSOCIAL_SIDELOAD_PREFLIGHT_ENABLED',
  'MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT',
  'MOOLSOCIAL_GOOGLE_ONLY_FORENSIC_MODE',
  'MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED',
  'MOOLSOCIAL_PHONE_OTP_ENABLED',
  'MOOLSOCIAL_MOBILE_OTP_ATTESTATION_QUALIFIED',
  'MOOLSOCIAL_APPLE_ENABLED',
  'MOOLSOCIAL_APPLE_PROVIDER_QUALIFIED',
  'MOOLSOCIAL_APPLE_PLATFORM_CONFIGURATION_QUALIFIED',
  'MOOLSOCIAL_APPLE_REVOCATION_QUALIFIED',
  'MOOLSOCIAL_X_PUBLIC_CLIENT_ENABLED',
  'MOOLSOCIAL_X_CLIENT_ID_CONFIGURED',
  'MOOLSOCIAL_X_EXACT_REDIRECT_QUALIFIED',
  'MOOLSOCIAL_X_FIREBASE_BROKER_QUALIFIED',
  'MOOLSOCIAL_INSTAGRAM_ENABLED',
  'MOOLSOCIAL_INSTAGRAM_PROFESSIONAL_LOGIN_QUALIFIED',
  'MOOLSOCIAL_INSTAGRAM_EXACT_REDIRECT_QUALIFIED',
  'MOOLSOCIAL_INSTAGRAM_FIREBASE_BROKER_QUALIFIED',
  'MOOLSOCIAL_INSTAGRAM_REVOCATION_QUALIFIED',
  'MOOLSOCIAL_FACEBOOK_ENABLED',
  'MOOLSOCIAL_FACEBOOK_PROVIDER_QUALIFIED',
  'MOOLSOCIAL_FACEBOOK_ANDROID_CONFIGURATION_QUALIFIED',
  'MOOLSOCIAL_FACEBOOK_REVOCATION_QUALIFIED',
  'MOOLSOCIAL_FACEBOOK_DATA_DELETION_QUALIFIED'
)
foreach ($defineName in $actualNames) {
  Assert-Gate -Condition ($allowedDefineNames -ccontains $defineName) `
    -Message "runtime define '$defineName' is not allowed in device review."
}

Write-Output (
  "APK regression pre-build gate passed: candidate=$CandidateId; " +
  "mode=$BuildMode; source=$SourceFingerprint; gates=$($requiredGateIds.Count)."
)
