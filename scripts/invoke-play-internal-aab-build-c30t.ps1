[CmdletBinding()]
param([string]$StatePath, [string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'C30T requires PowerShell 7 before authority mutation.' }
$PSNativeCommandUseErrorActionPreference = $false
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$artifactPathGuard = Join-Path $PSScriptRoot 'release-artifact-path-guard.ps1'
. $artifactPathGuard
$successorBuildFoundationGate = Join-Path `
  $PSScriptRoot `
  'test-public-auth-sideload-build-controls.ps1'
& $successorBuildFoundationGate -RepositoryRoot $root | Out-Null
$successorBuildFoundationPassed = $?
if (-not $successorBuildFoundationPassed) {
  throw 'Mandatory successor AAB build-foundation gate failed.'
}
$artifactPathGate = Join-Path `
  $PSScriptRoot `
  'test-release-artifact-path-containment.ps1'
& $artifactPathGate -RepositoryRoot $root | Out-Null
$pluginIntegrityFixtureGate = Join-Path `
  $PSScriptRoot `
  'test-release-production-plugin-integrity.ps1'
& $pluginIntegrityFixtureGate -RepositoryRoot $root | Out-Null
$pluginManifestNamespaceGate = Join-Path `
  $PSScriptRoot `
  'check-android-plugin-manifest-namespace-readiness.ps1'
& $pluginManifestNamespaceGate -RepositoryRoot $root | Out-Null
$kotlinPluginReadinessGate = Join-Path `
  $PSScriptRoot `
  'check-android-release-kotlin-plugin-readiness.ps1'
& $kotlinPluginReadinessGate -RepositoryRoot $root | Out-Null
$resourceIntegrityGate = Join-Path `
  $PSScriptRoot `
  'check-android-release-resource-integrity.ps1'
& $resourceIntegrityGate `
  -RepositoryRoot $root `
  -RunGradleLink | Out-Null
if (-not $StatePath) { $StatePath = Join-Path $root 'config/play-internal-aab-regression-gate-state-c30t.json' }
$stateFile = Resolve-ReleaseArtifactRepositoryDescendant `
  -RepositoryRoot $root `
  -Path $StatePath `
  -Label 'C30T state path'

function Assert-C30TBuild {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30T single AAB build rejected: $Message" }
}
function Resolve-RepoPath {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C30TBuild -Condition (-not [IO.Path]::IsPathRooted($Path)) -Message "$Label must be repository-relative."
  return Resolve-ReleaseArtifactRepositoryDescendant `
    -RepositoryRoot $root `
    -Path $Path `
    -Label $Label
}
function New-C34LTransitionProof {
  param(
    [Parameter(Mandatory)][string]$GatePath,
    [Parameter(Mandatory)][string]$StateRelative,
    [Parameter(Mandatory)][ValidateSet('build', 'rejection')][string]$Phase,
    [Parameter(Mandatory)][ValidateRange(1, 5)][int]$Attempt,
    [Parameter(Mandatory)][ValidateSet('build-start', 'build-failed', 'build-succeeded', 'reject')]
    [string]$Transition,
    [Parameter(Mandatory)][string]$ProofRelative
  )
  $proofPath = Resolve-RepoPath -Path $ProofRelative -Label "C34L $Transition proof"
  Assert-C30TBuild -Condition (-not (Test-Path -LiteralPath $proofPath)) `
    -Message "C34L $Transition proof already exists."
  & $GatePath -Phase $Phase -Transition $Transition -Attempt $Attempt `
    -StatePath $StateRelative -ProofOutputPath $ProofRelative `
    -RepositoryRoot $root | Out-Null
  Assert-C30TBuild -Condition (Test-Path -LiteralPath $proofPath -PathType Leaf) `
    -Message "C34L $Transition proof was not retained."
  $proofSha256 = (Get-FileHash -LiteralPath $proofPath -Algorithm SHA256).Hash
  $proof = Get-Content -Raw -LiteralPath $proofPath | ConvertFrom-Json
  Assert-C30TBuild -Condition (
    [string]$proof.transition -ceq $Transition -and
    [string]$proof.phase -ceq $Phase -and
    [int]$proof.attempt -eq $Attempt -and
    [bool]$proof.passed -and
    [string]$proofSha256 -cmatch '^[0-9A-F]{64}$'
  ) -Message "C34L $Transition proof identity is invalid."
  return [pscustomobject]@{
    Relative = $ProofRelative
    Sha256 = $proofSha256
  }
}
function Write-JsonState {
  param([Parameter(Mandatory)][object]$State, [Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Suffix)
  $temporary = $Path + $Suffix
  Assert-C30TBuild -Condition (-not (Test-Path -LiteralPath $temporary)) -Message "stale state temporary exists: $temporary"
  [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 40) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $Path -Force
}
function Set-C30TAggregateBuildConsumed {
  param([Parameter(Mandatory)][object]$Aggregate)
  if ($null -ne $Aggregate.PSObject.Properties['actionCounts']) {
    if ($null -eq $Aggregate.actionCounts.PSObject.Properties['build']) {
      throw 'C30T aggregate action-count contract is malformed.'
    }
    $Aggregate.actionCounts.build = 1
  }
  if ($null -ne $Aggregate.PSObject.Properties['releaseAuthorities']) {
    if ($null -eq $Aggregate.releaseAuthorities.PSObject.Properties['build']) {
      throw 'C30T aggregate release-authority contract is malformed.'
    }
    $Aggregate.releaseAuthorities.build = 'consumed'
  }
}
function Get-ArtifactSnapshot {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return 'absent' }
  $file = Get-Item -LiteralPath $Path
  return '{0}|{1}|{2}' -f $file.Length, $file.LastWriteTimeUtc.Ticks, (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function Invoke-NativeCaptured {
  param([Parameter(Mandatory)][string]$Command, [Parameter(Mandatory)][string[]]$Arguments, [Parameter(Mandatory)][string]$WorkingDirectory, [Parameter(Mandatory)][string]$LogPath)
  $savedErrorActionPreference = $ErrorActionPreference
  $savedNativePreference = $PSNativeCommandUseErrorActionPreference
  try {
    $PSNativeCommandUseErrorActionPreference = $false
    $ErrorActionPreference = 'Continue'
    Push-Location $WorkingDirectory
    try { & $Command @Arguments *> $LogPath; return $LASTEXITCODE }
    finally { Pop-Location }
  } finally {
    $ErrorActionPreference = $savedErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $savedNativePreference
  }
}
function Assert-SourceManifestCurrent {
  param([Parameter(Mandatory)][string]$ManifestPath)
  foreach ($line in Get-Content -LiteralPath $ManifestPath) {
    $match = [regex]::Match($line, '^([0-9A-F]{64})  (.+)$')
    Assert-C30TBuild -Condition $match.Success -Message 'source manifest row is malformed.'
    $path = Resolve-RepoPath -Path $match.Groups[2].Value -Label 'source owner'
    Assert-C30TBuild -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "source owner is missing: $($match.Groups[2].Value)"
    Assert-C30TBuild -Condition ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ceq $match.Groups[1].Value) -Message "source changed after qualification: $($match.Groups[2].Value)"
  }
}
function Restore-C30TQualifiedGeneratedOwners {
  param(
    [Parameter(Mandatory)][object[]]$Owners,
    [Parameter(Mandatory)][string]$RestoreGate
  )
  foreach ($owner in $Owners) {
    & $RestoreGate `
      -SnapshotPath ([string]$owner.snapshotRelative `
      ) `
      -OwnerPath ([string]$owner.ownerRelative) `
      -ExpectedSha256 ([string]$owner.expectedSha256) `
      -RepositoryRoot $root | Out-Null
  }
}

function Write-C34LTerminalResultEvidence {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][int]$Attempt,
    [Parameter(Mandatory)][ValidateSet(
      'build_in_progress_no_success_claimed',
      'aab_succeeded_postbuild_qualified',
      'rejected_no_success_claimed'
    )]
    [string]$Outcome,
    [AllowNull()][string]$FailureStage,
    [string]$ArtifactSha256,
    [long]$ArtifactBytes = 0
  )
  Assert-C30TBuild -Condition (
    ($Outcome -ceq 'rejected_no_success_claimed' -and
      $FailureStage -match '^[a-z0-9_]{3,80}$') -or
    ($Outcome -cne 'rejected_no_success_claimed' -and
      [string]::IsNullOrEmpty($FailureStage))
  ) -Message 'C34L terminal-result stage is not sanitized.'
  $terminal = [ordered]@{
    schemaVersion = 1
    candidateId = [string]$State.candidate.id
    versionName = [string]$State.candidate.versionName
    versionCode = [string]$State.candidate.versionCode
    preflightAttempt = $Attempt
    failureStage = $FailureStage
    terminalOutcome = $Outcome
    sanitized = $true
    secretOrPrivateValuesRecorded = $false
    buildCount = [int]$State.actionCounts.build
    uploadCount = [int]$State.actionCounts.upload
    installCount = [int]$State.actionCounts.install
    deviceAcceptanceCount = [int]$State.actionCounts.deviceAcceptance
  }
  if ($Outcome -ceq 'aab_succeeded_postbuild_qualified') {
    Assert-C30TBuild -Condition (
      $ArtifactSha256 -match '^[0-9A-F]{64}$' -and $ArtifactBytes -gt 0
    ) -Message 'C34L terminal success artifact identity is invalid.'
    $terminal.artifactSha256 = $ArtifactSha256
    $terminal.artifactBytes = $ArtifactBytes
  }
  Write-JsonState -State $terminal -Path $Path -Suffix '.c34l-terminal-write'
}

function Invoke-C34LTerminalFailure {
  param(
    [Parameter(Mandatory)][string]$GatePath,
    [Parameter(Mandatory)][string]$TransitionOwner,
    [Parameter(Mandatory)][string]$StateRelative,
    [Parameter(Mandatory)][string]$StateAbsolute,
    [Parameter(Mandatory)][ValidateRange(1, 5)][int]$Attempt,
    [Parameter(Mandatory)][string]$BuildFailedProofRelative,
    [Parameter(Mandatory)][string]$RejectProofRelative,
    [Parameter(Mandatory)][string]$EvidenceRelative,
    [Parameter(Mandatory)][string]$FailureStage
  )
  $current = Get-Content -Raw -LiteralPath $StateAbsolute | ConvertFrom-Json
  if ([int]$current.actionCounts.build -ne 1) {
    return
  }
  try {
    $buildFailedProof = New-C34LTransitionProof `
      -GatePath $GatePath `
      -StateRelative $StateRelative `
      -Phase build `
      -Attempt $Attempt `
      -Transition build-failed `
      -ProofRelative $BuildFailedProofRelative
    & $TransitionOwner -Transition build-failed `
      -StatePath $StateRelative `
      -PrerequisiteGateEvidencePath $buildFailedProof.Relative `
      -PrerequisiteGateEvidenceSha256 $buildFailedProof.Sha256 `
      -PrerequisiteGatePhase build `
      -Attempt $Attempt `
      -EvidencePath $EvidenceRelative `
      -FailureStage $FailureStage `
      -RepositoryRoot $root | Out-Null
    return
  } catch {
    # A failure after build-succeeded is no longer in the build-failed source
    # phase. The generic reject transition is the exact terminal fallback.
  }
  $rejectProof = New-C34LTransitionProof `
    -GatePath $GatePath `
    -StateRelative $StateRelative `
    -Phase rejection `
    -Attempt $Attempt `
    -Transition reject `
    -ProofRelative $RejectProofRelative
  & $TransitionOwner -Transition reject `
    -StatePath $StateRelative `
    -PrerequisiteGateEvidencePath $rejectProof.Relative `
    -PrerequisiteGateEvidenceSha256 $rejectProof.Sha256 `
    -PrerequisiteGatePhase rejection `
    -Attempt $Attempt `
    -RejectionMachineState 'build_wrapper_post_start_failure_terminal_rejected' `
    -RejectionRegistryId `
      'REG-20260817-2729-C34K-CONSOLIDATED-PRE-AAB-LIFECYCLE-AUDIT-GAPS' `
    -EvidencePath $EvidenceRelative `
    -FailureStage $FailureStage `
    -RepositoryRoot $root | Out-Null
}

Assert-C30TBuild -Condition ($stateFile.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $stateFile -PathType Leaf)) -Message 'state path invalid.'
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$acceptanceBlockerGate = Resolve-RepoPath `
  -Path 'scripts/check-uaw-c33g-fix4-unresolved-acceptance-blocker-pre-aab-ledger.ps1' `
  -Label 'acceptance blocker gate'
Assert-C30TBuild -Condition (Test-Path -LiteralPath $acceptanceBlockerGate -PathType Leaf) `
  -Message 'acceptance blocker gate is missing.'
& $acceptanceBlockerGate `
  -CandidateId ([string]$state.candidate.id) `
  -CandidateVersionCode ([string]$state.candidate.versionCode) `
  -Phase prebuild `
  -RepositoryRoot $root
& (Join-Path $root `
  'scripts/check-google-android-identity-bridge-readiness.ps1') `
  -RepositoryRoot $root
$aggregateFile = Resolve-RepoPath -Path ([string]$state.aggregateStatePath) -Label 'aggregate state'
Assert-C30TBuild -Condition (Test-Path -LiteralPath $aggregateFile -PathType Leaf) -Message 'aggregate state missing.'
$gateName = switch ([string]$state.contractId) {
  'MOOLSOCIAL-C34L-R60-76-RELEASE-LIFECYCLE-TRANSACTION-JOURNAL-001' { 'check-uaw-c34l-r60-76-consolidated-release-transaction-evidence-readiness.ps1' }
  'MOOLSOCIAL-C34J-R60-74-RELEASE-LIFECYCLE-ATOMIC-PARITY-STATE-001' { 'check-uaw-c34j-r60-74-release-lifecycle-atomic-parity-readiness.ps1' }
  'MOOLSOCIAL-C34K-R60-75-RELEASE-LIFECYCLE-ATOMIC-PARITY-STATE-001' { 'check-uaw-c34k-r60-75-release-lifecycle-atomic-parity-readiness.ps1' }
  'MOOLSOCIAL-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-RELEASE-STATE-001' { 'check-uaw-c34i-r60-73-authentication-privacy-safe-release-readiness.ps1' }
  'MOOLSOCIAL-C34H-R60-72-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c34h-r60-72-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C34G-R60-71-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c34g-r60-71-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C34F-R60-70-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c34f-r60-70-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C34E-R60-69-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c34e-r60-69-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C34D-R60-68-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c34d-r60-68-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C34C-R60-67-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c34c-r60-67-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C34B-R60-66-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c34b-r60-66-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C34A-R60-65-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c34a-r60-65-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33Z-R60-64-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33z-r60-64-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33Y-R60-63-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33y-r60-63-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33X-R60-62-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33x-r60-62-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33W-R60-61-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33w-r60-61-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33V-R60-60-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33v-r60-60-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33U-R60-59-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33u-r60-59-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33T-R60-58-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33t-r60-58-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33S-R60-57-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33s-r60-57-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33R-R60-56-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33r-r60-56-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33Q-R60-55-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33q-r60-55-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33P-R60-54-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33p-r60-54-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33O-R60-53-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33o-r60-53-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33N-R60-52-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33n-r60-52-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33M-R60-51-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33m-r60-51-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' { 'check-uaw-c33l-r60-50-authentication-no-regression-release-readiness.ps1' }
  'MOOLSOCIAL-C33F-R60-49-SUCCESSOR-RELEASE-STATE-001' { 'check-uaw-c33f-r60-49-successor-release-readiness.ps1' }
  'SUCCESSOR-AAB-REGRESSION-HARD-GATE-C30X-001' { 'check-successor-aab-regression-hard-gate-c30x.ps1' }
  'PLAY-INTERNAL-AAB-REGRESSION-GATES-C30V-001' { 'check-play-internal-aab-regression-gate-state-c30v.ps1' }
  'PLAY-INTERNAL-AAB-REGRESSION-GATES-C30U-001' { 'check-play-internal-aab-regression-gate-state-c30u.ps1' }
  'PLAY-INTERNAL-AAB-REGRESSION-GATES-C30T-001' { 'check-play-internal-aab-regression-gate-state-c30t.ps1' }
  default { throw "C30T single AAB build rejected: unsupported state contract $($state.contractId)" }
}
$gate = Join-Path $root "scripts/$gateName"
$isC34J = [string]$state.contractId -ceq
  'MOOLSOCIAL-C34J-R60-74-RELEASE-LIFECYCLE-ATOMIC-PARITY-STATE-001'
$isC34K = [string]$state.contractId -ceq
  'MOOLSOCIAL-C34K-R60-75-RELEASE-LIFECYCLE-ATOMIC-PARITY-STATE-001'
$isC34L = [string]$state.contractId -ceq
  'MOOLSOCIAL-C34L-R60-76-RELEASE-LIFECYCLE-TRANSACTION-JOURNAL-001'
$c34jTransition = $null
$c34jStateRelative = $null
if ($isC34J -or $isC34K -or $isC34L) {
  $transitionOwner = if ($isC34L) {
    'scripts/invoke-release-lifecycle-transition-c34l.ps1'
  } elseif ($isC34K) {
    'scripts/invoke-release-lifecycle-transition-c34k.ps1'
  } else { 'scripts/invoke-release-lifecycle-transition-c34j.ps1' }
  $c34jTransition = Resolve-RepoPath `
    -Path $transitionOwner `
    -Label 'atomic lifecycle transition owner'
  Assert-C30TBuild -Condition (
    Test-Path -LiteralPath $c34jTransition -PathType Leaf
  ) -Message 'atomic lifecycle transition owner is missing.'
  $c34jStateRelative = $stateFile.Substring($prefix.Length).Replace('\', '/')
}
if (-not $isC34L) {
  & $gate -Phase build -StatePath $stateFile -RepositoryRoot $root
}
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
$emailLinkDefines = $state.runtimeConfiguration.requiredNonSecretDefines
Assert-C30TBuild -Condition (
  $null -ne $emailLinkDefines.PSObject.Properties[
    'MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL'
  ] -and
  [string]$emailLinkDefines.MOOLSOCIAL_EMAIL_LINK_CONTINUE_URL `
    -ceq 'https://moolsocial.com/app'
) -Message 'AAB Email Link continue URL is missing or differs from the exact-return route.'
Assert-C30TBuild -Condition (
  $null -ne $emailLinkDefines.PSObject.Properties[
    'MOOLSOCIAL_EMAIL_LINK_DOMAIN'
  ] -and
  [string]$emailLinkDefines.MOOLSOCIAL_EMAIL_LINK_DOMAIN `
    -ceq ''
) -Message 'AAB Email Link must omit linkDomain so Firebase selects its default Hosting domain.'
$releaseRuntimeGate = Join-Path $root 'scripts/check-release-runtime-configuration-c30w.ps1'
Assert-C30TBuild -Condition (Test-Path -LiteralPath $releaseRuntimeGate -PathType Leaf) -Message 'release-runtime configuration gate is missing.'
& $releaseRuntimeGate -Phase build -StatePath $stateFile -RepositoryRoot $root
$authReadinessGate = Join-Path $root `
  'scripts/check-uaw-c33e-fix2-google-auth-live-provider-readiness.ps1'
Assert-C30TBuild -Condition (
  Test-Path -LiteralPath $authReadinessGate -PathType Leaf
) -Message 'Google auth live-readiness gate is missing.'
# C33L through C34I compose the same four sanitized facts and their exact evidence
# hashes in their successor gates without inheriting the stale failed-C33F
# ticket hash.
if (
  [string]$state.contractId -cne
    'MOOLSOCIAL-C34I-R60-73-AUTHENTICATION-PRIVACY-SAFE-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C34H-R60-72-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C34G-R60-71-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C34F-R60-70-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C34E-R60-69-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C34D-R60-68-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C34C-R60-67-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C34B-R60-66-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C34A-R60-65-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33Z-R60-64-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33Y-R60-63-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33X-R60-62-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33W-R60-61-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33V-R60-60-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33U-R60-59-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33T-R60-58-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33S-R60-57-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33R-R60-56-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33Q-R60-55-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33P-R60-54-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33O-R60-53-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33N-R60-52-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001' -and
  [string]$state.contractId -cne
    'MOOLSOCIAL-C33M-R60-51-AUTHENTICATION-NO-REGRESSION-RELEASE-STATE-001'
) {
  # C33E FIX2: fail closed before any AAB authority consumption.
  & $authReadinessGate `
    -Phase build `
    -StatePath 'config/google-auth-live-provider-readiness-state-c33e-fix2.json' `
    -RepositoryRoot $root
}
$versionName = [string]$state.candidate.versionName
$versionCode = [string]$state.candidate.versionCode
Assert-C30TBuild -Condition ([bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder) -Message 'founder Firebase inputs are not qualified.'
Assert-C30TBuild -Condition (
  $null -ne $state.runtimeConfiguration.PSObject.Properties['googleServerClientIdQualifiedByFounder'] -and
  [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder
) -Message 'founder Google server client ID is not qualified.'

foreach ($name in @([string[]]$state.signingQualification.uploadKeyEnvironmentNames) + @([string]$state.runtimeConfiguration.secretDefineFileEnvironmentName) + @([string]$state.runtimeConfiguration.googleServicesFileEnvironmentName)) {
  Assert-C30TBuild -Condition (Test-Path -LiteralPath ('Env:{0}' -f $name)) -Message "founder environment entry missing: $name"
}
$uploadStorePath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_UPLOAD_STORE_FILE')
$secretDefinePath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_FIREBASE_DART_DEFINE_FILE')
$googleServicesPath = [Environment]::GetEnvironmentVariable('MOOLSOCIAL_GOOGLE_SERVICES_JSON')
Assert-C30TBuild -Condition (Test-Path -LiteralPath $uploadStorePath -PathType Leaf) -Message 'upload keystore missing.'
Assert-C30TBuild -Condition (Test-Path -LiteralPath $secretDefinePath -PathType Leaf) -Message 'transient define file missing.'
$expectedGoogleServicesPath = Resolve-RepoPath -Path ([string]$state.runtimeConfiguration.transientGoogleServicesPath) -Label 'transient Google Services configuration'
Assert-C30TBuild -Condition ([IO.Path]::GetFullPath($googleServicesPath) -ceq $expectedGoogleServicesPath -and (Test-Path -LiteralPath $expectedGoogleServicesPath -PathType Leaf)) -Message 'transient Google Services configuration path changed.'

$artifactRelative = if ($aggregate.PSObject.Properties['evidenceRoot']) { [string]$aggregate.evidenceRoot } else { 'artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-01' }
$artifactRoot = Resolve-RepoPath -Path $artifactRelative -Label 'evidence directory'
Assert-C30TBuild -Condition (Test-Path -LiteralPath $artifactRoot -PathType Container) -Message 'evidence directory missing.'
$mobileRoot = Resolve-RepoPath -Path 'apps/mobile' -Label 'mobile root'
$generatedPath = Resolve-RepoPath -Path 'apps/mobile/build/app/outputs/bundle/release/app-release.aab' -Label 'generated AAB'
$mappingFolder = Resolve-RepoPath -Path 'apps/mobile/build/app/outputs/mapping/release' -Label 'release Proguard mapping folder'
$releaseApkPath = Resolve-RepoPath -Path 'apps/mobile/build/app/outputs/flutter-apk/app-release.apk' -Label 'release APK sentinel'
$registrantPath = Resolve-RepoPath -Path 'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java' -Label 'generated registrant'
$mergedManifestPath = Resolve-RepoPath -Path 'apps/mobile/build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml' -Label 'fresh merged release manifest'
$manifestBlamePath = Resolve-RepoPath -Path 'apps/mobile/build/app/intermediates/manifest_merge_blame_file/release/processReleaseMainManifest/manifest-merger-blame-release-report.txt' -Label 'fresh release manifest merger blame'
$bundletoolPath = Resolve-RepoPath -Path ([string]$state.toolingQualification.standaloneBundletoolPath) -Label 'standalone bundletool'
$sealedRelative = "$artifactRelative/MoolSocial-$versionName-$versionCode-release.aab"
$sealedPath = Resolve-RepoPath -Path $sealedRelative -Label 'sealed AAB'
Assert-C30TBuild -Condition (-not (Test-Path -LiteralPath $sealedPath)) -Message "sealed $versionName AAB already exists."

$preflightAttempt = 0
do {
  $preflightAttempt++
  Assert-C30TBuild -Condition ($preflightAttempt -le 5) -Message 'all five immutable preflight evidence slots are occupied.'
  $attemptSuffix = if ($preflightAttempt -eq 1) { '' } else { "-attempt-$preflightAttempt" }
  $configLogRelative = "$artifactRelative/03-release-config-only$attemptSuffix.log"
  $configLogPath = Resolve-RepoPath -Path $configLogRelative -Label 'config log'
  $manifestLogRelative = "$artifactRelative/04-release-manifest-preflight$attemptSuffix.log"
  $manifestLogPath = Resolve-RepoPath -Path $manifestLogRelative -Label 'manifest log'
  $buildLogRelative = "$artifactRelative/05-release-aab-build$attemptSuffix.log"
  $buildLogPath = Resolve-RepoPath -Path $buildLogRelative -Label 'build log'
  $prebuildRelative = "$artifactRelative/03a-prebuild-machine-state$attemptSuffix.json"
  $prebuildPath = Resolve-RepoPath -Path $prebuildRelative -Label 'prebuild state'
  $registrantSnapshotRelative = "$artifactRelative/03b-qualified-registrant-snapshot$attemptSuffix.java"
  $registrantSnapshotPath = Resolve-RepoPath -Path $registrantSnapshotRelative -Label 'qualified registrant snapshot'
  $localPropertiesSnapshotRelative = "$artifactRelative/03c-qualified-local-properties-snapshot$attemptSuffix.properties"
  $localPropertiesSnapshotPath = Resolve-RepoPath -Path $localPropertiesSnapshotRelative -Label 'qualified local-properties snapshot'
  $mergedManifestEvidenceRelative = "$artifactRelative/04a-merged-release-manifest$attemptSuffix.xml"
  $mergedManifestEvidencePath = Resolve-RepoPath -Path $mergedManifestEvidenceRelative -Label 'merged manifest evidence'
  $manifestBlameEvidenceRelative = "$artifactRelative/04b-release-manifest-merger-blame$attemptSuffix.txt"
  $manifestBlameEvidencePath = Resolve-RepoPath -Path $manifestBlameEvidenceRelative -Label 'manifest merger blame evidence'
  $provenanceRelative = "$artifactRelative/06-release-aab-provenance$attemptSuffix.json"
  $provenancePath = Resolve-RepoPath -Path $provenanceRelative -Label 'provenance'
  $terminalResultRelative =
    "$artifactRelative/12-release-terminal-result-attempt-$preflightAttempt.json"
  $terminalResultPath = Resolve-RepoPath `
    -Path $terminalResultRelative `
    -Label 'C34L terminal result'
  $buildStartProofRelative =
    "$artifactRelative/11a-build-start-proof-attempt-$preflightAttempt.json"
  $buildStartProofPath = Resolve-RepoPath `
    -Path $buildStartProofRelative -Label 'C34L build-start proof'
  $buildSucceededProofRelative =
    "$artifactRelative/11b-build-succeeded-proof-attempt-$preflightAttempt.json"
  $buildSucceededProofPath = Resolve-RepoPath `
    -Path $buildSucceededProofRelative -Label 'C34L build-succeeded proof'
  $buildFailedProofRelative =
    "$artifactRelative/11c-build-failed-proof-attempt-$preflightAttempt.json"
  $buildFailedProofPath = Resolve-RepoPath `
    -Path $buildFailedProofRelative -Label 'C34L build-failed proof'
  $rejectProofRelative =
    "$artifactRelative/11d-reject-proof-attempt-$preflightAttempt.json"
  $rejectProofPath = Resolve-RepoPath `
    -Path $rejectProofRelative -Label 'C34L reject proof'
  $attemptOutputs = @(
    $configLogPath, $manifestLogPath, $buildLogPath, $prebuildPath,
    $registrantSnapshotPath, $localPropertiesSnapshotPath,
    $mergedManifestEvidencePath, $manifestBlameEvidencePath, $provenancePath,
    $terminalResultPath, $buildStartProofPath, $buildSucceededProofPath,
    $buildFailedProofPath, $rejectProofPath
  )
  $attemptOccupied = @($attemptOutputs | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0
} while ($attemptOccupied)

Assert-C30TBuild -Condition ((Get-FileHash -LiteralPath $bundletoolPath -Algorithm SHA256).Hash -ceq [string]$state.toolingQualification.standaloneBundletoolSha256) -Message 'standalone bundletool identity changed.'
Assert-C30TBuild -Condition ((Split-Path -Leaf $bundletoolPath) -ceq 'bundletool-all-1.18.3.jar') -Message 'standalone bundletool filename changed.'
$sourceManifest = Resolve-RepoPath -Path ([string]$state.sourceQualification.manifestPath) -Label 'source manifest'
Assert-C30TBuild -Condition ((Get-FileHash -LiteralPath $sourceManifest -Algorithm SHA256).Hash -ceq ([string]$state.sourceQualification.manifestSha256).ToUpperInvariant()) -Message 'accepted source-manifest file changed.'
Assert-SourceManifestCurrent -ManifestPath $sourceManifest
$restoreQualifiedOwnerPath = Resolve-RepoPath `
  -Path 'scripts/restore-qualified-generated-owner-c30y-fix2.ps1' `
  -Label 'C30Y FIX2 qualified-owner restore gate'
$localPropertiesPath = Resolve-RepoPath `
  -Path 'apps/mobile/android/local.properties' `
  -Label 'qualified Android local properties'
$qualifiedGeneratedOwners = @(
  [pscustomobject]@{
    ownerRelative = 'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
    snapshotRelative = $registrantSnapshotRelative
    ownerPath = $registrantPath
    snapshotPath = $registrantSnapshotPath
    expectedSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $registrantPath).Hash
  },
  [pscustomobject]@{
    ownerRelative = 'apps/mobile/android/local.properties'
    snapshotRelative = $localPropertiesSnapshotRelative
    ownerPath = $localPropertiesPath
    snapshotPath = $localPropertiesSnapshotPath
    expectedSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $localPropertiesPath).Hash
  }
)
foreach ($owner in $qualifiedGeneratedOwners) {
  Copy-Item -LiteralPath ([string]$owner.ownerPath) `
    -Destination ([string]$owner.snapshotPath)
  Assert-C30TBuild -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath ([string]$owner.snapshotPath)).Hash -ceq
      [string]$owner.expectedSha256
  ) -Message 'qualified generated-owner snapshot changed during capture.'
}
$expectedReleaseRegistrantPluginCount = 16

# C30Y FIX2: begin mutation-safe preflight transaction.
try {
$releaseApkBefore = Get-ArtifactSnapshot -Path $releaseApkPath
$releaseAabBefore = Get-ArtifactSnapshot -Path $generatedPath
$pubspecHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash
$lockHashBefore = (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash
$releaseConfigExitCode = Invoke-NativeCaptured -Command 'flutter' -Arguments @('build', 'apk', '--release', '--config-only', "--build-name=$versionName", "--build-number=$versionCode") -WorkingDirectory $mobileRoot -LogPath $configLogPath
if ($releaseConfigExitCode -ne 0) { throw "release config-only failed with exit $releaseConfigExitCode" }
Assert-C30TBuild -Condition ($pubspecHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Algorithm SHA256).Hash -and $lockHashBefore -ceq (Get-FileHash -LiteralPath (Join-Path $mobileRoot 'pubspec.lock') -Algorithm SHA256).Hash) -Message 'release config-only changed pubspec.yaml or pubspec.lock.'
Assert-C30TBuild -Condition ($releaseApkBefore -ceq (Get-ArtifactSnapshot -Path $releaseApkPath) -and $releaseAabBefore -ceq (Get-ArtifactSnapshot -Path $generatedPath)) -Message 'release config-only created or changed an APK or AAB.'
& (Join-Path $root 'scripts/restore-release-generated-plugin-registrant-c30t.ps1') -RepositoryRoot $root | Add-Content -LiteralPath $configLogPath
$registrant = Get-Content -Raw -LiteralPath $registrantPath
Assert-C30TBuild -Condition (-not $registrant.Contains('IntegrationTestPlugin', [StringComparison]::Ordinal) -and [regex]::Matches($registrant, 'flutterEngine\.getPlugins\(\)\.add').Count -eq $expectedReleaseRegistrantPluginCount) -Message 'release registrant plugin set changed.'

$manifestExitCode = Invoke-NativeCaptured -Command '.\gradlew.bat' -Arguments @(':app:processReleaseMainManifest', '--rerun-tasks', '--console=plain') -WorkingDirectory (Join-Path $mobileRoot 'android') -LogPath $manifestLogPath
if ($manifestExitCode -ne 0) { throw "fresh release manifest preflight failed with exit $manifestExitCode" }
Assert-C30TBuild -Condition (Test-Path -LiteralPath $mergedManifestPath -PathType Leaf) -Message 'fresh merged release manifest is missing.'
$manifestLogText = Get-Content -Raw -LiteralPath $manifestLogPath
Assert-C30TBuild -Condition ($manifestLogText.Contains('processReleaseGoogleServices', [StringComparison]::Ordinal) -and $manifestLogText.Contains('injectCrashlyticsMappingFileIdRelease', [StringComparison]::Ordinal) -and $manifestLogText.Contains('BUILD SUCCESSFUL', [StringComparison]::Ordinal)) -Message 'release manifest preflight lacks Google Services or Crashlytics build-ID proof.'
$mergedManifest = Get-Content -Raw -LiteralPath $mergedManifestPath
foreach ($pattern in @('package="com.moolsocial.app"', "android:versionCode=`"$versionCode`"", "android:versionName=`"$versionName`"", 'android:minSdkVersion="24"', 'android:targetSdkVersion="36"', 'android:allowBackup="false"')) {
  Assert-C30TBuild -Condition $mergedManifest.Contains($pattern, [StringComparison]::Ordinal) -Message "merged release manifest missing $pattern"
}
Assert-C30TBuild -Condition (-not $mergedManifest.Contains('android:usesCleartextTraffic="true"', [StringComparison]::OrdinalIgnoreCase)) -Message 'merged release manifest enables cleartext traffic.'
[xml]$manifestXml = $mergedManifest
$namespace = [Xml.XmlNamespaceManager]::new($manifestXml.NameTable)
$namespace.AddNamespace('android', 'http://schemas.android.com/apk/res/android')
$mergedPermissions = @($manifestXml.SelectNodes('/manifest/uses-permission', $namespace) | ForEach-Object { $_.GetAttribute('name', 'http://schemas.android.com/apk/res/android') })
$readGservicesPermission = 'com.google.android.providers.gsf.permission.READ_GSERVICES'
Assert-C30TBuild -Condition (@($mergedPermissions | Where-Object { $_ -ceq $readGservicesPermission }).Count -eq 1) -Message 'Firebase Auth reCAPTCHA READ_GSERVICES permission is missing or duplicated.'
foreach ($permission in @('android.permission.POST_NOTIFICATIONS', 'com.google.android.c2dm.permission.RECEIVE', 'com.google.android.gms.permission.AD_ID', 'android.permission.ACCESS_ADSERVICES_ATTRIBUTION', 'android.permission.ACCESS_ADSERVICES_AD_ID')) {
  Assert-C30TBuild -Condition (-not $mergedManifest.Contains($permission, [StringComparison]::Ordinal)) -Message "unexpected release permission remains: $permission"
}
Assert-C30TBuild -Condition (Test-Path -LiteralPath $manifestBlamePath -PathType Leaf) -Message 'fresh release manifest merger blame is missing.'
$manifestBlame = Get-Content -Raw -LiteralPath $manifestBlamePath
Assert-C30TBuild -Condition ([regex]::Matches($manifestBlame, [regex]::Escape($readGservicesPermission)).Count -eq 1 -and [regex]::IsMatch($manifestBlame, ([regex]::Escape($readGservicesPermission) + '[\s\S]{0,1000}\[com\.google\.android\.recaptcha:recaptcha:18\.7\.1\]'))) -Message 'READ_GSERVICES merger-blame origin differs from exact reCAPTCHA 18.7.1.'
$expectedExportedNames = @(
  'com.moolsocial.app.MainActivity',
  'com.moolsocial.app.YouTubeConnectReturnActivity',
  'com.google.firebase.auth.internal.GenericIdpActivity',
  'com.google.firebase.auth.internal.RecaptchaActivity',
  'com.google.android.gms.auth.api.signin.RevocationBoundService',
  'androidx.profileinstaller.ProfileInstallReceiver'
)
$exportedNodes = @($manifestXml.SelectNodes('//*[@android:exported="true"]', $namespace))
$exportedNames = @($exportedNodes | ForEach-Object { $_.GetAttribute('name', 'http://schemas.android.com/apk/res/android') })
Assert-C30TBuild -Condition ($exportedNames.Count -eq $expectedExportedNames.Count -and @($exportedNames | Where-Object { $_ -notin $expectedExportedNames }).Count -eq 0) -Message 'merged release exported-component surface changed.'
foreach ($originPattern in @(
  'GenericIdpActivity[\s\S]{0,1000}\[com\.google\.firebase:firebase-auth:24\.1\.0\]',
  'RecaptchaActivity[\s\S]{0,1000}\[com\.google\.firebase:firebase-auth:24\.1\.0\]',
  'RevocationBoundService[\s\S]{0,1000}\[com\.google\.android\.gms:play-services-auth:21\.6\.0\]',
  'ProfileInstallReceiver[\s\S]{0,1000}\[androidx\.profileinstaller:profileinstaller:1\.4\.0\]'
)) {
  Assert-C30TBuild -Condition ([regex]::IsMatch($manifestBlame, $originPattern)) -Message 'exported dependency-component merger-blame origin changed.'
}
Copy-Item -LiteralPath $mergedManifestPath -Destination $mergedManifestEvidencePath
Copy-Item -LiteralPath $manifestBlamePath -Destination $manifestBlameEvidencePath
foreach ($log in @($configLogPath, $manifestLogPath)) {
  $credentialHits = @(Select-String -LiteralPath $log -Pattern 'AIza[0-9A-Za-z_-]{35}|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----')
  Assert-C30TBuild -Condition ($credentialHits.Count -eq 0) -Message "credential-shaped output detected in $(Split-Path -Leaf $log)."
}
} finally {
  # C30Y FIX2: restore full qualified source before authority consumption.
  Restore-C30TQualifiedGeneratedOwners `
    -Owners $qualifiedGeneratedOwners `
    -RestoreGate $restoreQualifiedOwnerPath
}
Assert-SourceManifestCurrent -ManifestPath $sourceManifest

$state.sourceQualification.releasePreflightPassed = $true
$aggregate.sourceQualification.releasePreflightPassed = $true
[IO.File]::WriteAllText($prebuildPath, (($state | ConvertTo-Json -Depth 40) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
$c34lBuildStartAttempted = $false
$c34lFailureStage = 'build_start_transition'
try {
if ($isC34J -or $isC34K -or $isC34L) {
  if ($isC34L) {
    $buildStartProof = New-C34LTransitionProof `
      -GatePath $gate `
      -StateRelative $c34jStateRelative `
      -Phase build `
      -Attempt $preflightAttempt `
      -Transition build-start `
      -ProofRelative $buildStartProofRelative
    $c34lBuildStartAttempted = $true
    & $c34jTransition -Transition build-start `
      -StatePath $c34jStateRelative `
      -PrerequisiteGateEvidencePath $buildStartProof.Relative `
      -PrerequisiteGateEvidenceSha256 $buildStartProof.Sha256 `
      -PrerequisiteGatePhase build `
      -Attempt $preflightAttempt `
      -RepositoryRoot $root | Out-Null
  } else {
    & $c34jTransition -Transition build-start -StatePath $c34jStateRelative `
      -RepositoryRoot $root | Out-Null
  }
  $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
  $aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
  if ($isC34L) {
    Write-C34LTerminalResultEvidence `
      -Path $terminalResultPath `
      -State $state `
      -Attempt $preflightAttempt `
      -Outcome build_in_progress_no_success_claimed `
      -FailureStage $null
  }
} else {
  $state.machineState = 'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
  $state.buildAuthorization = 'consumed'
  $state.founderAuthorization.hiddenFounderInputsEntered = $true
  $state.buildResult.state = 'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
  $state.buildResult.buildCount = 1
  $state.buildResult.wrapperInvocationCount = 1
  $state.buildResult.configOnlyCount = 1
  $state.actionCounts.build = 1
  $aggregate.candidate.buildCount = 1
  Set-C30TAggregateBuildConsumed -Aggregate $aggregate
  Write-JsonState -State $state -Path $stateFile -Suffix '.c30t-build-write'
  Write-JsonState -State $aggregate -Path $aggregateFile -Suffix '.c30t-build-write'
}

$buildSucceeded = $false
$c34lFailureStage = 'flutter_aab_build'
try {
  try {
    # C30Y FIX2: begin mutation-safe AAB transaction.
    & (Join-Path $root 'scripts/restore-release-generated-plugin-registrant-c30t.ps1') `
      -RepositoryRoot $root | Out-Null
    $releaseRegistrant = Get-Content -Raw -LiteralPath $registrantPath
    Assert-C30TBuild -Condition (
      -not $releaseRegistrant.Contains('IntegrationTestPlugin', [StringComparison]::Ordinal) -and
      [regex]::Matches(
        $releaseRegistrant,
        'flutterEngine\.getPlugins\(\)\.add'
      ).Count -eq $expectedReleaseRegistrantPluginCount
    ) -Message 'release registrant changed immediately before the AAB build.'
    $buildArguments = @('build', 'appbundle', '--release', '--no-pub', "--build-name=$versionName", "--build-number=$versionCode", ('--dart-define-from-file={0}' -f $secretDefinePath))
    foreach ($property in $state.runtimeConfiguration.requiredNonSecretDefines.PSObject.Properties) {
      $buildArguments += '--dart-define={0}={1}' -f $property.Name, $property.Value
    }
    $buildExitCode = Invoke-NativeCaptured -Command 'flutter' -Arguments $buildArguments -WorkingDirectory $mobileRoot -LogPath $buildLogPath
    if ($buildExitCode -ne 0) { throw "single release AAB failed with exit $buildExitCode" }
  } finally {
    $c34lFailureStage = 'postbuild_source_restore'
    # C30Y FIX2: restore full qualified source before postbuild rebind.
    Restore-C30TQualifiedGeneratedOwners `
      -Owners $qualifiedGeneratedOwners `
      -RestoreGate $restoreQualifiedOwnerPath
  }
  $c34lFailureStage = 'postbuild_source_rebind'
  Assert-SourceManifestCurrent -ManifestPath $sourceManifest
  $buildSucceeded = $true
}
catch {
  if ($isC34J -or $isC34K) {
    $failureEvidence = if (Test-Path -LiteralPath $buildLogPath -PathType Leaf) {
      $buildLogRelative
    } else {
      $manifestLogRelative
    }
    & $c34jTransition -Transition build-failed -StatePath $c34jStateRelative `
      -EvidencePath $failureEvidence -RepositoryRoot $root | Out-Null
  } elseif (-not $isC34L) {
    $failed = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
    $failed.machineState = 'single_release_AAB_failed_authority_consumed'
    $failed.buildResult.state = 'single_release_AAB_failed_authority_consumed'
    Write-JsonState -State $failed -Path $stateFile -Suffix '.c30t-failed-write'
  }
  throw
}
Assert-C30TBuild -Condition $buildSucceeded -Message 'single release AAB did not succeed.'
$c34lFailureStage = 'generated_aab_validation'
Assert-C30TBuild -Condition (Test-Path -LiteralPath $generatedPath -PathType Leaf) -Message 'Flutter succeeded without an AAB.'
$c34lFailureStage = 'production_plugin_integrity'
& (Join-Path $root 'scripts/check-aab-production-plugin-integrity.ps1') `
  -AabPath $generatedPath `
  -CandidateId ([string]$state.candidate.id) `
  -ProguardFolderPath $mappingFolder `
  -RepositoryRoot $root | Out-Null
$c34lFailureStage = 'sealed_aab_copy'
Copy-Item -LiteralPath $generatedPath -Destination $sealedPath

$c34lFailureStage = 'signer_proof'
$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
$java = 'C:\Program Files\Android\Android Studio\jbr\bin\java.exe'
Assert-C30TBuild -Condition ((Test-Path -LiteralPath $keytool -PathType Leaf) -and (Test-Path -LiteralPath $java -PathType Leaf)) -Message 'Android Studio Java or keytool missing.'
$certificateOutput = & $keytool -printcert -jarfile $sealedPath 2>&1
Assert-C30TBuild -Condition ($LASTEXITCODE -eq 0) -Message 'AAB signer certificate unreadable.'
$shaMatch = [regex]::Match(($certificateOutput -join [Environment]::NewLine), 'SHA256:\s*([0-9A-Fa-f:]{64,95})')
Assert-C30TBuild -Condition $shaMatch.Success -Message 'AAB signer SHA-256 missing.'
$uploadSigner = $shaMatch.Groups[1].Value.Replace(':', '').ToUpperInvariant()
$expectedSigner = ([string]$state.signingQualification.uploadCertificateSha256).Replace(':', '').ToUpperInvariant()
Assert-C30TBuild -Condition ($uploadSigner -ceq $expectedSigner) -Message 'AAB signer differs from founder upload certificate.'

$c34lFailureStage = 'package_version_proof'
$packageOutput = & $java -jar $bundletoolPath dump manifest "--bundle=$sealedPath" '--xpath=/manifest/@package' 2>&1
Assert-C30TBuild -Condition ($LASTEXITCODE -eq 0 -and ($packageOutput -join '').Trim() -ceq 'com.moolsocial.app') -Message 'AAB package proof failed.'
$versionCodeOutput = & $java -jar $bundletoolPath dump manifest "--bundle=$sealedPath" '--xpath=/manifest/@android:versionCode' 2>&1
Assert-C30TBuild -Condition ($LASTEXITCODE -eq 0 -and ($versionCodeOutput -join '').Trim() -ceq $versionCode) -Message 'AAB versionCode proof failed.'
$versionNameOutput = & $java -jar $bundletoolPath dump manifest "--bundle=$sealedPath" '--xpath=/manifest/@android:versionName' 2>&1
Assert-C30TBuild -Condition ($LASTEXITCODE -eq 0 -and ($versionNameOutput -join '').Trim() -ceq $versionName) -Message 'AAB versionName proof failed.'
$c34lFailureStage = 'firebase_resource_proof'
$googleAppOutput = & $java -jar $bundletoolPath dump resources "--bundle=$sealedPath" '--resource=string/google_app_id' --values 2>&1
$googleAppText = $googleAppOutput -join [Environment]::NewLine
Assert-C30TBuild -Condition ($LASTEXITCODE -eq 0 -and $googleAppText.Contains('1:760290687711:android:4202409fd3ab38f6ce076a', [StringComparison]::Ordinal)) -Message 'AAB google_app_id resource proof failed.'
$crashlyticsOutput = & $java -jar $bundletoolPath dump resources "--bundle=$sealedPath" '--resource=string/com.google.firebase.crashlytics.mapping_file_id' --values 2>&1
$crashlyticsText = $crashlyticsOutput -join [Environment]::NewLine
Assert-C30TBuild -Condition ($LASTEXITCODE -eq 0 -and $crashlyticsText.Contains('com.google.firebase.crashlytics.mapping_file_id', [StringComparison]::Ordinal) -and [regex]::IsMatch($crashlyticsText, '(?i)\b[0-9a-f]{32}\b') -and [regex]::IsMatch($crashlyticsText, '(?m)\[STR\]\s+"[^"]+"')) -Message 'AAB Crashlytics mapping-file build-ID resource proof failed.'

$c34lFailureStage = 'archive_payload_proof'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($sealedPath)
try {
  $entryNames = @($archive.Entries | ForEach-Object { $_.FullName })
  $splitAndArm64 = $entryNames -contains 'base/lib/arm64-v8a/libapp.so' -and $entryNames -contains 'base/lib/arm64-v8a/libflutter.so' -and $entryNames -contains 'base/resources.pb' -and $entryNames -contains 'base/manifest/AndroidManifest.xml'
  Assert-C30TBuild -Condition $splitAndArm64 -Message 'AAB base resources, manifest or arm64 runtime payload is incomplete.'
} finally { $archive.Dispose() }

$c34lFailureStage = 'credential_scan'
$credentialHits = @(Select-String -LiteralPath $buildLogPath -Pattern 'AIza[0-9A-Za-z_-]{35}|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----')
Assert-C30TBuild -Condition ($credentialHits.Count -eq 0) -Message 'credential-shaped output detected in release build log.'
$artifactHash = (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash
$artifactBytes = (Get-Item -LiteralPath $sealedPath).Length
$sourceHash = (Get-FileHash -LiteralPath $sourceManifest -Algorithm SHA256).Hash
Assert-SourceManifestCurrent -ManifestPath $sourceManifest
$provenance = [ordered]@{
  schemaVersion = 1; candidateId = [string]$state.candidate.id; preflightAttempt = $preflightAttempt
  versionName = $versionName; versionCode = $versionCode; packageName = 'com.moolsocial.app'
  buildMode = 'release'; artifactType = 'AAB'; authorizedTrack = 'internal'
  branch = [string]$state.candidate.branch; head = [string]$state.candidate.head; powerShellMajor = $PSVersionTable.PSVersion.Major
  providerRevisions = $state.providerRevisions
  releaseConfigOnly = $configLogRelative; qualifiedRegistrantSnapshot = $registrantSnapshotRelative; qualifiedLocalPropertiesSnapshot = $localPropertiesSnapshotRelative; releaseManifestPreflight = $manifestLogRelative; mergedReleaseManifest = $mergedManifestEvidenceRelative; releaseManifestMergerBlame = $manifestBlameEvidenceRelative
  releaseConfigOnlyProducedApkOrAab = $false; releaseRegistrantPluginCount = $expectedReleaseRegistrantPluginCount
  googleServicesGradlePlugin = '4.5.0'; crashlyticsGradlePlugin = '3.0.7'; crashlyticsMappingUploadEnabled = $false
  sourceManifest = [string]$state.sourceQualification.manifestPath; sourceManifestSha256 = $sourceHash; sourceFiles = [int]$state.sourceQualification.fileCount
  artifactPath = $sealedRelative; artifactSha256 = $artifactHash; artifactBytes = $artifactBytes; uploadSignerSha256 = $uploadSigner
  packageVersionManifestProved = $true; googleAppIdResourceProved = $true; crashlyticsBuildIdResourceProved = $true; splitAndArm64PayloadProved = $true
  bundletoolPath = [string]$state.toolingQualification.standaloneBundletoolPath; bundletoolSha256 = [string]$state.toolingQualification.standaloneBundletoolSha256; bundletoolVersion = '1.18.3'
  buildLog = $buildLogRelative; secretDefineFileReadByAgent = $false; googleServicesFileReadByAgent = $false; secretValuesRecorded = $false
  builtAt = [DateTimeOffset]::Now.ToString('o')
}
$c34lFailureStage = 'provenance_write'
[IO.File]::WriteAllText($provenancePath, (($provenance | ConvertTo-Json -Depth 20) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
if ($isC34J -or $isC34K -or $isC34L) {
  $c34lFailureStage = 'build_succeeded_transition'
  if ($isC34L) {
    $buildSucceededProof = New-C34LTransitionProof `
      -GatePath $gate `
      -StateRelative $c34jStateRelative `
      -Phase build `
      -Attempt $preflightAttempt `
      -Transition build-succeeded `
      -ProofRelative $buildSucceededProofRelative
    & $c34jTransition -Transition build-succeeded `
      -StatePath $c34jStateRelative `
      -PrerequisiteGateEvidencePath $buildSucceededProof.Relative `
      -PrerequisiteGateEvidenceSha256 $buildSucceededProof.Sha256 `
      -PrerequisiteGatePhase build `
      -Attempt $preflightAttempt `
      -ArtifactPath $sealedRelative `
      -ArtifactSha256 $artifactHash `
      -ArtifactBytes $artifactBytes `
      -UploadSignerSha256 $uploadSigner `
      -ArtifactProvenance $provenanceRelative `
      -RepositoryRoot $root | Out-Null
  } else {
    & $c34jTransition -Transition build-succeeded `
      -StatePath $c34jStateRelative `
      -ArtifactPath $sealedRelative `
      -ArtifactSha256 $artifactHash `
      -ArtifactBytes $artifactBytes `
      -UploadSignerSha256 $uploadSigner `
      -ArtifactProvenance $provenanceRelative `
      -RepositoryRoot $root | Out-Null
  }
  $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
  $aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
} else {
  $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
  $state.machineState = 'single_release_AAB_succeeded_authority_consumed'
  $state.buildResult.state = 'single_release_AAB_succeeded_authority_consumed'
  $state.buildResult.artifactPath = $sealedRelative
  $state.buildResult.artifactSha256 = $artifactHash
  $state.buildResult.artifactBytes = $artifactBytes
  $state.buildResult.uploadSignerSha256 = $uploadSigner
  $state.buildResult.crashlyticsBuildIdResourceProved = $true
  $state.buildResult.googleAppIdResourceProved = $true
  $state.buildResult.packageVersionManifestProved = $true
  $state.buildResult.splitAndArm64PayloadProved = $true
  $state.buildResult.mergedReleaseManifestProved = $true
  $state.buildResult.provenance = $provenanceRelative
  $aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
  $aggregate.machineState = 'single_release_AAB_succeeded_authority_consumed'
  $aggregate.candidate.aabSha256 = $artifactHash
  Set-C30TAggregateBuildConsumed -Aggregate $aggregate
  Write-JsonState -State $state -Path $stateFile -Suffix '.c30t-success-write'
  Write-JsonState -State $aggregate -Path $aggregateFile -Suffix '.c30t-success-write'
}
$c34lFailureStage = 'postbuild_gate'
& $gate -Phase postbuild -StatePath $stateFile -RepositoryRoot $root
if ($isC34L) {
  $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
  Write-C34LTerminalResultEvidence `
    -Path $terminalResultPath `
    -State $state `
    -Attempt $preflightAttempt `
    -Outcome aab_succeeded_postbuild_qualified `
    -FailureStage $null `
    -ArtifactSha256 $artifactHash `
    -ArtifactBytes $artifactBytes
}
Write-Output "MoolSocial single release AAB succeeded: versionCode=$versionCode; sha256=$artifactHash; bytes=$artifactBytes; CrashlyticsBuildId=proved; googleAppId=proved; authority=consumed."
} catch {
  if ($isC34L -and $c34lBuildStartAttempted) {
    $failedState = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
    if ([int]$failedState.actionCounts.build -eq 1) {
      Write-C34LTerminalResultEvidence `
        -Path $terminalResultPath `
        -State $failedState `
        -Attempt $preflightAttempt `
        -Outcome rejected_no_success_claimed `
        -FailureStage $c34lFailureStage
      Invoke-C34LTerminalFailure `
        -GatePath $gate `
        -TransitionOwner $c34jTransition `
        -StateRelative $c34jStateRelative `
        -StateAbsolute $stateFile `
        -Attempt $preflightAttempt `
        -BuildFailedProofRelative $buildFailedProofRelative `
        -RejectProofRelative $rejectProofRelative `
        -EvidenceRelative $terminalResultRelative `
        -FailureStage $c34lFailureStage
    }
  }
  throw
}
