[CmdletBinding()]
param(
  [string]$StatePath,

  [string]$CandidateId =
    'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30O',

  [ValidateSet('reconcile', 'build', 'postbuild', 'preupload', 'preinstall', 'journey')]
  [string]$Phase = 'reconcile',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$repositoryRootFull = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$repositoryPrefix = $repositoryRootFull + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) {
  $StatePath = Join-Path `
    $repositoryRootFull `
    'config/play-internal-aab-regression-gate-state-c30o.json'
}

function Assert-C30O {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw ('C30O Play Internal AAB gate rejected: {0}' -f $Message)
  }
}

function Resolve-RepositoryFile {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath,

    [Parameter(Mandatory)]
    [string]$Label
  )

  Assert-C30O `
    -Condition (-not [string]::IsNullOrWhiteSpace($RelativePath)) `
    -Message ('{0} path is missing.' -f $Label)
  Assert-C30O `
    -Condition (-not [IO.Path]::IsPathRooted($RelativePath)) `
    -Message ('{0} path must be repository-relative.' -f $Label)
  $resolved = [IO.Path]::GetFullPath(
    (Join-Path $repositoryRootFull $RelativePath)
  )
  Assert-C30O -Condition (
    $resolved.StartsWith(
      $repositoryPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message ('{0} escaped the production repository.' -f $Label)
  Assert-C30O `
    -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) `
    -Message ('{0} is missing.' -f $Label)
  return $resolved
}

$resolvedStatePath = [IO.Path]::GetFullPath($StatePath)
Assert-C30O -Condition (
  $resolvedStatePath.StartsWith(
    $repositoryPrefix,
    [StringComparison]::OrdinalIgnoreCase
  )
) -Message 'machine state escaped the production repository.'
Assert-C30O `
  -Condition (Test-Path -LiteralPath $resolvedStatePath -PathType Leaf) `
  -Message 'machine state is missing.'

$state = Get-Content -Raw -LiteralPath $resolvedStatePath | ConvertFrom-Json
Assert-C30O -Condition ([int]$state.schemaVersion -eq 1) `
  -Message 'unsupported machine-state schema.'
Assert-C30O -Condition (
  [string]$state.contractId -ceq
    'PLAY-INTERNAL-AAB-REGRESSION-GATES-C30O-001'
) -Message 'unexpected machine-state contract.'
Assert-C30O -Condition ([string]$state.candidate.id -ceq $CandidateId) `
  -Message 'candidate id mismatch.'
Assert-C30O -Condition (
  [string]$state.candidate.branch -ceq
    'remediation/prototype-conformance-2026-07-20'
) -Message 'candidate branch is not the authorized branch.'
Assert-C30O -Condition (
  [string]$state.candidate.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) -Message 'candidate HEAD is not the authorized HEAD.'
Assert-C30O -Condition (
  [string]$state.candidate.versionName -ceq '1.0.0-r60.41' -and
  [string]$state.candidate.versionCode -ceq '2026081241' -and
  [string]$state.candidate.buildMode -ceq 'release' -and
  [string]$state.candidate.artifactType -ceq 'AAB' -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app'
) -Message 'candidate identity is not the exact r60.41 release AAB.'

$branch = (& git -C $repositoryRootFull branch --show-current).Trim()
Assert-C30O -Condition ($LASTEXITCODE -eq 0) `
  -Message 'current branch could not be read.'
$head = (& git -C $repositoryRootFull rev-parse HEAD).Trim()
Assert-C30O -Condition ($LASTEXITCODE -eq 0) `
  -Message 'current HEAD could not be read.'
Assert-C30O -Condition ($branch -ceq [string]$state.candidate.branch) `
  -Message 'working branch differs from the candidate.'
Assert-C30O -Condition ($head -ceq [string]$state.candidate.head) `
  -Message 'working HEAD differs from the candidate.'

$scopeGate = Join-Path $repositoryRootFull 'scripts/check-mvp-scope-gate-state.ps1'
& $scopeGate `
  -CandidateId $CandidateId `
  -RequireExecutionAuthorized `
  -RepositoryRoot $repositoryRootFull
Assert-C30O -Condition ($LASTEXITCODE -eq 0) `
  -Message 'authorized MVP scope gate failed.'

Assert-C30O -Condition (
  [string]$state.distribution.authorizedTrack -ceq 'internal' -and
  -not [bool]$state.distribution.productionTrackAuthorized -and
  -not [bool]$state.distribution.openTestingAuthorized -and
  -not [bool]$state.distribution.publicListingAuthorized
) -Message 'distribution escaped private Internal Testing.'
Assert-C30O -Condition (
  -not [bool]$state.signingQualification.secretValuesRecorded -and
  -not [bool]$state.signingQualification.agentSecretValueAccessAuthorized -and
  -not [bool]$state.firebaseAppCheck.privateVerdictReadAuthorized
) -Message 'secret or private-verdict boundary is not fail closed.'
Assert-C30O -Condition (
  -not [bool]$state.communicationHold.gmailDraftCreated -and
  -not [bool]$state.communicationHold.emailSent -and
  -not [bool]$state.communicationHold.quotaSubmitted
) -Message 'communication hold was violated.'
Assert-C30O -Condition (
  [int]$state.buildResult.buildCount -le 1 -and
  -not [bool]$state.buildResult.secondBuildPerformed -and
  [int]$state.playReleaseResult.uploadCount -le 1 -and
  [int]$state.installResult.candidateInstallCount -le 1 -and
  -not [bool]$state.installResult.uninstallPerformed -and
  -not [bool]$state.installResult.dataClearPerformed -and
  -not [bool]$state.installResult.downgradePerformed -and
  -not [bool]$state.installResult.adbSuccessorInstallPerformed -and
  -not [bool]$state.installResult.secondInstallPerformed
) -Message 'single build/upload/install or protected-device boundary was violated.'

[void](Resolve-RepositoryFile `
  -RelativePath ([string]$state.protectedPredecessor.statePath) `
  -Label 'protected C30N state')
[void](Resolve-RepositoryFile `
  -RelativePath ([string]$state.communicationHold.reviewerPackage) `
  -Label 'reviewer package')

if ($Phase -in @('build', 'postbuild', 'preupload', 'preinstall', 'journey')) {
  Assert-C30O -Condition (
    [string]$state.sourceQualification.state -ceq
      'passed_two_identical_complete_C30O_cycles' -and
    [int]$state.sourceQualification.identicalQualifyingCycles -eq 2 -and
    [bool]$state.sourceQualification.completeSocialCyclesPassed
  ) -Message 'two complete C30O source cycles are not sealed.'
  $manifestPath = Resolve-RepositoryFile `
    -RelativePath ([string]$state.sourceQualification.manifestPath) `
    -Label 'source manifest'
  $manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
  Assert-C30O -Condition (
    $manifestHash -ceq
      ([string]$state.sourceQualification.manifestSha256).ToUpperInvariant()
  ) -Message 'source manifest hash mismatch.'
  Assert-C30O -Condition (
    [bool]$state.signingQualification.founderControlledUploadKeyPresent -and
    -not [string]::IsNullOrWhiteSpace(
      [string]$state.signingQualification.uploadCertificateSha256
    ) -and
    [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
    -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent
  ) -Message 'founder-controlled signing or secret-safe define input is not qualified.'
}

if ($Phase -ceq 'build') {
  Assert-C30O -Condition (
    [string]$state.machineState -ceq
      'source_and_founder_inputs_qualified_single_release_AAB_build_authorized' -and
    [string]$state.buildAuthorization -ceq 'available_not_consumed' -and
    [int]$state.buildResult.buildCount -eq 0 -and
    [int]$state.buildResult.wrapperInvocationCount -eq 0 -and
    [string]$state.buildResult.state -ceq 'not_started'
  ) -Message 'single AAB build authority is unavailable or already consumed.'
}

if ($Phase -in @('postbuild', 'preupload', 'preinstall', 'journey')) {
  Assert-C30O -Condition (
    [string]$state.buildAuthorization -ceq 'consumed' -and
    [int]$state.buildResult.buildCount -eq 1 -and
    [int]$state.buildResult.wrapperInvocationCount -eq 1 -and
    [string]$state.buildResult.state -ceq
      'single_release_AAB_succeeded_authority_consumed'
  ) -Message 'single release AAB result is not sealed.'
  $artifactPath = Resolve-RepositoryFile `
    -RelativePath ([string]$state.buildResult.artifactPath) `
    -Label 'release AAB'
  $artifactHash = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash
  Assert-C30O -Condition (
    $artifactHash -ceq ([string]$state.buildResult.artifactSha256).ToUpperInvariant()
  ) -Message 'release AAB checksum mismatch.'
}

if ($Phase -in @('preupload', 'preinstall', 'journey')) {
  Assert-C30O -Condition (
    [bool]$state.distribution.appCreated -and
    -not [string]::IsNullOrWhiteSpace([string]$state.distribution.playAppId) -and
    [bool]$state.firebaseAppCheck.playProjectLinked -and
    [bool]$state.firebaseAppCheck.playAppSigningCertificateRegistered -and
    [string]$state.firebaseAppCheck.playAppSigningSha256 -ceq
      [string]$state.signingQualification.playAppSigningCertificateSha256
  ) -Message 'Play app-signing and Firebase App Check identities are not sealed.'
}

if ($Phase -in @('preinstall', 'journey')) {
  Assert-C30O -Condition (
    [bool]$state.distribution.releaseUploaded -and
    [bool]$state.distribution.founderTesterEligible -and
    -not [string]::IsNullOrWhiteSpace(
      [string]$state.distribution.testerOptInLink
    ) -and
    [int]$state.playReleaseResult.uploadCount -eq 1 -and
    [string]$state.playReleaseResult.track -ceq 'internal' -and
    -not [bool]$state.playReleaseResult.productionRolloutPerformed
  ) -Message 'Internal Testing upload or founder tester access is not sealed.'
}

if ($Phase -ceq 'journey') {
  Assert-C30O -Condition (
    [int]$state.installResult.candidateInstallCount -eq 1 -and
    [string]$state.installResult.installerPackageName -ceq 'com.android.vending' -and
    [string]$state.installResult.versionName -ceq
      [string]$state.candidate.versionName -and
    [string]$state.installResult.versionCode -ceq
      [string]$state.candidate.versionCode -and
    [bool]$state.installResult.playArtifactRelationshipProved
  ) -Message 'Play-installed OPPO identity is not sealed.'
}

Write-Output (
  'C30O Play Internal AAB gate passed: phase={0}; candidate={1}; buildCount={2}; uploadCount={3}; installCount={4}.' -f
    $Phase,
    $CandidateId,
    [int]$state.buildResult.buildCount,
    [int]$state.playReleaseResult.uploadCount,
    [int]$state.installResult.candidateInstallCount
)
