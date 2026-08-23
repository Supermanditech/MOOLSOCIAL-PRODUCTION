[CmdletBinding()]
param(
  [ValidateSet(
    'implementation', 'build', 'postbuild', 'preupload',
    'postupload', 'preinstall', 'postinstall', 'journey'
  )]
  [string]$Phase = 'implementation',

  [string]$StatePath = 'config/successor-aab-regression-hard-gate-state-c33f.json',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33FFix5 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33F FIX5 release phase transition rejected: $Message"
  }
}

function Resolve-C33FFix5File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33FFix5 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

function Read-C33FFix5Json {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = Resolve-C33FFix5File -Path $Path -Label $Label
  $raw = Get-Content -Raw -LiteralPath $resolved
  foreach ($pattern in @(
    'AIza[0-9A-Za-z_-]{35}',
    '[0-9]{6,}-[0-9A-Za-z_-]+[.]apps[.]googleusercontent[.]com',
    'Bearer\s+[A-Za-z0-9._~+/-]+=*',
    '-----BEGIN [^-]*PRIVATE KEY-----',
    'eyJ[A-Za-z0-9_-]+[.]eyJ[A-Za-z0-9_-]+[.][A-Za-z0-9_-]+'
  )) {
    Assert-C33FFix5 -Condition (-not [regex]::IsMatch($raw, $pattern)) `
      -Message "$Label contains credential-, token- or private-key-shaped material."
  }
  Assert-C33FFix5 -Condition (
    -not [regex]::IsMatch(
      $raw,
      '(?i)"(?:apiKey|oauthClientId|clientSecret|accessToken|refreshToken|idToken|nonce|privateKey|attestationPayload|appCheckToken)"\s*:'
    )
  ) -Message "$Label contains a forbidden private-value property."
  return [pscustomobject]@{
    Path = $resolved
    Value = ($raw | ConvertFrom-Json)
  }
}

function Assert-C33FFix5Properties {
  param(
    [Parameter(Mandatory)]$Object,
    [Parameter(Mandatory)][string[]]$Names,
    [Parameter(Mandatory)][string]$Label
  )
  foreach ($name in $Names) {
    Assert-C33FFix5 -Condition ($null -ne $Object.PSObject.Properties[$name]) `
      -Message "$Label is missing required property: $name"
  }
}

function Assert-C33FFix5ArtifactBinding {
  param(
    [Parameter(Mandatory)]$State,
    [Parameter(Mandatory)]$Aggregate
  )
  $artifactPath = Resolve-C33FFix5File `
    -Path ([string]$State.buildResult.artifactPath) `
    -Label 'sealed r60.49 AAB'
  $artifact = Get-Item -LiteralPath $artifactPath
  $artifactHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash
  Assert-C33FFix5 -Condition (
    $artifactHash -ceq ([string]$State.buildResult.artifactSha256).ToUpperInvariant() -and
    $artifactHash -ceq ([string]$Aggregate.candidate.aabSha256).ToUpperInvariant() -and
    [int64]$artifact.Length -eq [int64]$State.buildResult.artifactBytes -and
    [regex]::IsMatch([string]$State.buildResult.uploadSignerSha256, '^[0-9A-F]{64}$') -and
    [bool]$State.buildResult.packageVersionManifestProved -and
    [bool]$State.buildResult.googleAppIdResourceProved -and
    [bool]$State.buildResult.crashlyticsBuildIdResourceProved -and
    [bool]$State.buildResult.splitAndArm64PayloadProved -and
    [bool]$State.buildResult.mergedReleaseManifestProved
  ) -Message 'sealed AAB hash, bytes, signer or payload proof changed.'

  $provenanceRead = Read-C33FFix5Json `
    -Path ([string]$State.buildResult.provenance) `
    -Label 'sealed r60.49 AAB provenance'
  $provenance = $provenanceRead.Value
  Assert-C33FFix5Properties -Object $provenance -Label 'sealed AAB provenance' -Names @(
    'candidateId', 'versionName', 'versionCode', 'packageName', 'buildMode',
    'artifactType', 'authorizedTrack', 'sourceManifestSha256', 'artifactPath',
    'artifactSha256', 'artifactBytes', 'uploadSignerSha256',
    'packageVersionManifestProved', 'googleAppIdResourceProved',
    'crashlyticsBuildIdResourceProved', 'splitAndArm64PayloadProved',
    'secretDefineFileReadByAgent', 'googleServicesFileReadByAgent',
    'secretValuesRecorded'
  )
  Assert-C33FFix5 -Condition (
    [string]$provenance.candidateId -ceq [string]$State.candidate.id -and
    [string]$provenance.versionName -ceq [string]$State.candidate.versionName -and
    [string]$provenance.versionCode -ceq [string]$State.candidate.versionCode -and
    [string]$provenance.packageName -ceq 'com.moolsocial.app' -and
    [string]$provenance.buildMode -ceq 'release' -and
    [string]$provenance.artifactType -ceq 'AAB' -and
    [string]$provenance.authorizedTrack -ceq 'internal' -and
    ([string]$provenance.sourceManifestSha256).ToUpperInvariant() -ceq
      ([string]$State.sourceQualification.manifestSha256).ToUpperInvariant() -and
    ([string]$provenance.artifactSha256).ToUpperInvariant() -ceq $artifactHash -and
    [int64]$provenance.artifactBytes -eq [int64]$artifact.Length -and
    ([string]$provenance.uploadSignerSha256).ToUpperInvariant() -ceq
      ([string]$State.buildResult.uploadSignerSha256).ToUpperInvariant() -and
    [bool]$provenance.packageVersionManifestProved -and
    [bool]$provenance.googleAppIdResourceProved -and
    [bool]$provenance.crashlyticsBuildIdResourceProved -and
    [bool]$provenance.splitAndArm64PayloadProved -and
    -not [bool]$provenance.secretDefineFileReadByAgent -and
    -not [bool]$provenance.googleServicesFileReadByAgent -and
    -not [bool]$provenance.secretValuesRecorded
  ) -Message 'sealed AAB provenance identity, payload or privacy binding changed.'
}

function Assert-C33FFix5PlayEvidence {
  param([Parameter(Mandatory)]$State)
  $playRead = Read-C33FFix5Json `
    -Path ([string]$State.playResult.evidencePath) `
    -Label 'Internal Testing activation evidence'
  $play = $playRead.Value
  Assert-C33FFix5Properties -Object $play -Label 'Internal Testing activation evidence' -Names @(
    'candidateId', 'packageName', 'versionName', 'versionCode',
    'artifactSha256', 'track', 'internalReleaseActive', 'uploadCount',
    'otherTrackChanged'
  )
  Assert-C33FFix5 -Condition (
    [string]$play.candidateId -ceq [string]$State.candidate.id -and
    [string]$play.packageName -ceq 'com.moolsocial.app' -and
    [string]$play.versionName -ceq [string]$State.candidate.versionName -and
    [string]$play.versionCode -ceq [string]$State.candidate.versionCode -and
    ([string]$play.artifactSha256).ToUpperInvariant() -ceq
      ([string]$State.buildResult.artifactSha256).ToUpperInvariant() -and
    [string]$play.track -ceq 'internal' -and
    [bool]$play.internalReleaseActive -and
    [int]$play.uploadCount -eq 1 -and
    -not [bool]$play.otherTrackChanged
  ) -Message 'Internal Testing activation evidence identity, artifact or one-track rule failed.'
}

function Assert-C33FFix5InstallEvidence {
  param([Parameter(Mandatory)]$State)
  $coldRead = Read-C33FFix5Json `
    -Path ([string]$State.installResult.coldStartEvidencePath) `
    -Label 'Play-installed cold-start evidence'
  $cold = $coldRead.Value
  Assert-C33FFix5Properties -Object $cold -Label 'Play-installed cold-start evidence' -Names @(
    'packageName', 'versionCode', 'installerPackage', 'firstScreenName',
    'coldStartInteractive', 'blankHierarchy', 'timeout',
    'flutterFatalErrorCount', 'androidRuntimeFatalCount', 'anrCount',
    'appProcessErrorScanPassed', 'artifactRelationshipProved', 'inPlaceUpdateProved'
  )
  Assert-C33FFix5 -Condition (
    [string]$cold.packageName -ceq 'com.moolsocial.app' -and
    [string]$cold.versionCode -ceq [string]$State.candidate.versionCode -and
    [string]$cold.installerPackage -ceq 'com.android.vending' -and
    -not [string]::IsNullOrWhiteSpace([string]$cold.firstScreenName) -and
    [bool]$cold.coldStartInteractive -and
    -not [bool]$cold.blankHierarchy -and
    -not [bool]$cold.timeout -and
    [int]$cold.flutterFatalErrorCount -eq 0 -and
    [int]$cold.androidRuntimeFatalCount -eq 0 -and
    [int]$cold.anrCount -eq 0 -and
    [bool]$cold.appProcessErrorScanPassed -and
    [bool]$cold.artifactRelationshipProved -and
    [bool]$cold.inPlaceUpdateProved
  ) -Message 'Play-installed cold-start, fatal/ANR or in-place update proof failed.'

  $retainedRead = Read-C33FFix5Json `
    -Path ([string]$State.installResult.retainedDataEvidencePath) `
    -Label 'retained-data Play-update evidence'
  $retained = $retainedRead.Value
  Assert-C33FFix5Properties -Object $retained -Label 'retained-data Play-update evidence' -Names @(
    'packageName', 'versionCode', 'installerPackage',
    'firstInstallTimeMillis', 'lastUpdateTimeMillis',
    'firstInstallTimePreserved', 'retainedDataContinuityProved',
    'inPlacePlayUpdateProved', 'uninstallPerformed', 'dataClearPerformed',
    'downgradePerformed', 'adbInstallPerformed'
  )
  Assert-C33FFix5 -Condition (
    [string]$retained.packageName -ceq 'com.moolsocial.app' -and
    [string]$retained.versionCode -ceq [string]$State.candidate.versionCode -and
    [string]$retained.installerPackage -ceq 'com.android.vending' -and
    [int64]$retained.firstInstallTimeMillis -lt [int64]$retained.lastUpdateTimeMillis -and
    [bool]$retained.firstInstallTimePreserved -and
    [bool]$retained.retainedDataContinuityProved -and
    [bool]$retained.inPlacePlayUpdateProved -and
    -not [bool]$retained.uninstallPerformed -and
    -not [bool]$retained.dataClearPerformed -and
    -not [bool]$retained.downgradePerformed -and
    -not [bool]$retained.adbInstallPerformed
  ) -Message 'retained-data or in-place Play update evidence failed.'
}

function Assert-C33FFix5JourneyEvidence {
  param([Parameter(Mandatory)]$State)
  $journeyRead = Read-C33FFix5Json `
    -Path ([string]$State.installResult.journeyEvidencePath) `
    -Label 'mandatory whole-app journey evidence'
  $journey = $journeyRead.Value
  Assert-C33FFix5Properties -Object $journey -Label 'mandatory whole-app journey evidence' -Names @(
    'candidateId', 'versionName', 'versionCode', 'packageName', 'track',
    'deviceSerial', 'installerPackage', 'allMandatoryJourneysPassed',
    'evidenceComplete', 'newIssueCount', 'newDefectCount', 'blankScreenCount',
    'flutterFatalErrorCount', 'androidRuntimeFatalCount', 'anrCount',
    'acceptanceSucceeded', 'successClaimed'
  )
  Assert-C33FFix5 -Condition (
    [string]$journey.candidateId -ceq [string]$State.candidate.id -and
    [string]$journey.versionName -ceq [string]$State.candidate.versionName -and
    [string]$journey.versionCode -ceq [string]$State.candidate.versionCode -and
    [string]$journey.packageName -ceq 'com.moolsocial.app' -and
    [string]$journey.track -ceq 'internal' -and
    [string]$journey.deviceSerial -ceq '2b3e0f71' -and
    [string]$journey.installerPackage -ceq 'com.android.vending' -and
    [bool]$journey.allMandatoryJourneysPassed -and
    [bool]$journey.evidenceComplete -and
    [int]$journey.newIssueCount -eq 0 -and
    [int]$journey.newDefectCount -eq 0 -and
    [int]$journey.blankScreenCount -eq 0 -and
    [int]$journey.flutterFatalErrorCount -eq 0 -and
    [int]$journey.androidRuntimeFatalCount -eq 0 -and
    [int]$journey.anrCount -eq 0 -and
    [bool]$journey.acceptanceSucceeded -and
    [bool]$journey.successClaimed
  ) -Message 'mandatory whole-app journey or zero-new-issue/defect acceptance failed.'
}

$stateRead = Read-C33FFix5Json -Path $StatePath -Label 'C33F lifecycle state'
$state = $stateRead.Value
$aggregateRead = Read-C33FFix5Json `
  -Path ([string]$state.aggregateStatePath) `
  -Label 'C33F lifecycle aggregate'
$aggregate = $aggregateRead.Value

Assert-C33FFix5 -Condition (
  [string]$state.contractId -ceq 'MOOLSOCIAL-C33F-R60-49-SUCCESSOR-RELEASE-STATE-001' -and
  [string]$aggregate.contractId -ceq 'MOOLSOCIAL-C33F-R60-49-SUCCESSOR-RELEASE-AGGREGATE-001' -and
  [string]$state.ticketId -ceq
    'UAW-C33F-R60-49-GOOGLE-AUTH-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE' -and
  [string]$aggregate.ticketId -ceq [string]$state.ticketId -and
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.versionName -ceq '1.0.0-r60.49' -and
  [string]$state.candidate.versionCode -ceq '2026081349' -and
  [string]$state.candidate.authorizedTrack -ceq 'internal' -and
  [string]$state.candidate.deviceSerial -ceq '2b3e0f71' -and
  [string]$state.candidate.deviceModel -ceq 'CPH2375'
) -Message 'state, aggregate, candidate, package, track or device identity changed.'
Assert-C33FFix5 -Condition (
  [bool]$state.authority.candidateIdentityApproved -and
  [bool]$state.authority.oneAabBuildAuthorizedAfterAllGates -and
  [bool]$state.authority.oneInternalTestingUploadAndActivationAuthorizedAfterPostbuild -and
  [bool]$state.authority.oneInPlaceOppoPlayUpdateAuthorizedAfterActivation -and
  -not [bool]$state.authority.agentSecretValueAccessAuthorized -and
  -not [bool]$state.authority.otherTrackAuthorized -and
  -not [bool]$state.authority.adbOrSideloadAuthorized -and
  -not [bool]$state.authority.backendOrHostingDeploymentAuthorized -and
  -not [bool]$state.authority.providerDeploymentAuthorized -and
  -not [bool]$state.authority.emailOrQuotaSubmissionAuthorized -and
  -not [bool]$state.privacyBoundary.secretValuesObserved -and
  -not [bool]$state.privacyBoundary.oauthClientIdentifierValuesObserved -and
  -not [bool]$state.privacyBoundary.tokenOrAttestationPayloadObserved -and
  -not [bool]$state.privacyBoundary.firebaseDebugLogRead
) -Message 'founder authority or privacy boundary changed.'

switch ($Phase) {
  { $_ -in @('implementation', 'build') } {
    $qualifiedFacts = [int]$state.liveReadiness.qualifiedFacts
    $sourceQualified = (
      [int]$state.sourceQualification.completedIdenticalCycles -eq 2 -and
      [int]$state.sourceQualification.requiredIdenticalCycles -eq 2
    )
    $expectedState = if ($qualifiedFacts -lt 4) {
      "registered_founder_authorized_live_readiness_${qualifiedFacts}_of_4_source_cycles_pending"
    } elseif (-not $sourceQualified) {
      'live_readiness_qualified_source_cycles_pending'
    } else {
      'source_and_live_readiness_qualified_founder_secret_prompt_required'
    }
    Assert-C33FFix5 -Condition (
      [string]$state.machineState -ceq $expectedState -and
      [string]$aggregate.machineState -ceq $expectedState -and
      [string]$state.buildAuthorization -ceq 'available_once' -and
      [string]$state.buildResult.state -ceq 'not_started' -and
      [int]$state.buildResult.buildCount -eq 0 -and
      [int]$aggregate.candidate.buildCount -eq 0 -and
      [int]$state.actionCounts.build -eq 0 -and
      [int]$state.playResult.uploadCount -eq 0 -and
      [int]$aggregate.candidate.uploadCount -eq 0 -and
      [int]$state.actionCounts.upload -eq 0 -and
      [int]$state.installResult.installCount -eq 0 -and
      [int]$aggregate.candidate.installCount -eq 0 -and
      [int]$state.actionCounts.install -eq 0 -and
      [int]$state.actionCounts.deviceAcceptance -eq 0 -and
      -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered
    ) -Message 'prerelease state, authority or zero-action contract failed.'
  }
  'postbuild' {
    Assert-C33FFix5 -Condition (
      [string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
      [string]$aggregate.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
      [string]$state.buildAuthorization -ceq 'consumed' -and
      [string]$state.uploadAuthorization -ceq 'held_postbuild_qualification' -and
      [string]$state.buildResult.state -ceq 'single_release_AAB_succeeded_authority_consumed' -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [int]$aggregate.candidate.buildCount -eq 1 -and
      [int]$state.actionCounts.build -eq 1 -and
      [int]$state.playResult.uploadCount -eq 0 -and
      [int]$aggregate.candidate.uploadCount -eq 0 -and
      [int]$state.actionCounts.upload -eq 0 -and
      [int]$state.installResult.installCount -eq 0 -and
      [int]$aggregate.candidate.installCount -eq 0 -and
      [int]$state.actionCounts.install -eq 0 -and
      [int]$state.actionCounts.deviceAcceptance -eq 0
    ) -Message 'postbuild machine state, authority or exact action-count contract failed.'
    Assert-C33FFix5ArtifactBinding -State $state -Aggregate $aggregate
  }
  'preupload' {
    Assert-C33FFix5 -Condition (
      [string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
      [string]$aggregate.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
      [string]$state.buildAuthorization -ceq 'consumed' -and
      [string]$state.uploadAuthorization -ceq 'available_once' -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [int]$aggregate.candidate.buildCount -eq 1 -and
      [int]$state.actionCounts.build -eq 1 -and
      [int]$state.playResult.uploadCount -eq 0 -and
      [int]$aggregate.candidate.uploadCount -eq 0 -and
      [int]$state.actionCounts.upload -eq 0 -and
      [int]$state.installResult.installCount -eq 0 -and
      [int]$aggregate.candidate.installCount -eq 0 -and
      [int]$state.actionCounts.install -eq 0 -and
      [int]$state.actionCounts.deviceAcceptance -eq 0
    ) -Message 'preupload state, one-upload authority or exact action-count contract failed.'
    Assert-C33FFix5ArtifactBinding -State $state -Aggregate $aggregate
  }
  'postupload' {
    Assert-C33FFix5 -Condition (
      [string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and
      [string]$aggregate.machineState -ceq 'internal_release_active_upload_consumed' -and
      [string]$state.buildAuthorization -ceq 'consumed' -and
      [string]$state.uploadAuthorization -ceq 'consumed' -and
      [string]$state.installAuthorization -ceq 'held_Play_activation_and_provenance' -and
      [string]$state.deviceAuthorization -ceq 'held_in_place_Play_update' -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [int]$aggregate.candidate.buildCount -eq 1 -and
      [int]$state.actionCounts.build -eq 1 -and
      [int]$state.playResult.uploadCount -eq 1 -and
      [int]$state.playResult.internalActivationCount -eq 1 -and
      [int]$aggregate.candidate.uploadCount -eq 1 -and
      [int]$state.actionCounts.upload -eq 1 -and
      [int]$state.installResult.installCount -eq 0 -and
      [int]$aggregate.candidate.installCount -eq 0 -and
      [int]$state.actionCounts.install -eq 0 -and
      [int]$state.actionCounts.deviceAcceptance -eq 0
    ) -Message 'postupload Internal Testing state, authority or one-action contract failed.'
    Assert-C33FFix5ArtifactBinding -State $state -Aggregate $aggregate
    Assert-C33FFix5PlayEvidence -State $state
  }
  'preinstall' {
    Assert-C33FFix5 -Condition (
      [string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and
      [string]$aggregate.machineState -ceq 'internal_release_active_upload_consumed' -and
      [string]$state.uploadAuthorization -ceq 'consumed' -and
      [string]$state.installAuthorization -ceq 'available_once' -and
      [string]$state.deviceAuthorization -ceq 'available_once' -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [int]$aggregate.candidate.buildCount -eq 1 -and
      [int]$state.actionCounts.build -eq 1 -and
      [int]$state.playResult.uploadCount -eq 1 -and
      [int]$aggregate.candidate.uploadCount -eq 1 -and
      [int]$state.actionCounts.upload -eq 1 -and
      [int]$state.installResult.installCount -eq 0 -and
      [int]$aggregate.candidate.installCount -eq 0 -and
      [int]$state.actionCounts.install -eq 0 -and
      [int]$state.actionCounts.deviceAcceptance -eq 0
    ) -Message 'preinstall state, one in-place Play-update authority or count contract failed.'
    Assert-C33FFix5ArtifactBinding -State $state -Aggregate $aggregate
    Assert-C33FFix5PlayEvidence -State $state
  }
  'postinstall' {
    Assert-C33FFix5 -Condition (
      [string]$state.machineState -ceq 'Play_installed_identity_sealed_journeys_pending' -and
      [string]$aggregate.machineState -ceq 'Play_installed_identity_sealed_journeys_pending' -and
      [string]$state.uploadAuthorization -ceq 'consumed' -and
      [string]$state.installAuthorization -ceq 'consumed' -and
      [string]$state.deviceAuthorization -ceq 'consumed' -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [int]$aggregate.candidate.buildCount -eq 1 -and
      [int]$state.actionCounts.build -eq 1 -and
      [int]$state.playResult.uploadCount -eq 1 -and
      [int]$aggregate.candidate.uploadCount -eq 1 -and
      [int]$state.actionCounts.upload -eq 1 -and
      [int]$state.installResult.installCount -eq 1 -and
      [int]$aggregate.candidate.installCount -eq 1 -and
      [int]$state.actionCounts.install -eq 1 -and
      [int]$state.actionCounts.deviceAcceptance -eq 0 -and
      -not [bool]$state.installResult.acceptanceSucceeded
    ) -Message 'postinstall Play identity, consumed authority or one-action contract failed.'
    Assert-C33FFix5ArtifactBinding -State $state -Aggregate $aggregate
    Assert-C33FFix5PlayEvidence -State $state
    Assert-C33FFix5InstallEvidence -State $state
  }
  'journey' {
    Assert-C33FFix5 -Condition (
      [string]$state.machineState -ceq 'acceptance_passed_zero_new_issue_or_defect_promotion_eligible' -and
      [string]$aggregate.machineState -ceq 'acceptance_passed_zero_new_issue_or_defect_promotion_eligible' -and
      [string]$state.uploadAuthorization -ceq 'consumed' -and
      [string]$state.installAuthorization -ceq 'consumed' -and
      [string]$state.deviceAuthorization -ceq 'consumed' -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [int]$aggregate.candidate.buildCount -eq 1 -and
      [int]$state.actionCounts.build -eq 1 -and
      [int]$state.playResult.uploadCount -eq 1 -and
      [int]$aggregate.candidate.uploadCount -eq 1 -and
      [int]$state.actionCounts.upload -eq 1 -and
      [int]$state.installResult.installCount -eq 1 -and
      [int]$aggregate.candidate.installCount -eq 1 -and
      [int]$state.actionCounts.install -eq 1 -and
      [int]$state.actionCounts.deviceAcceptance -eq 1 -and
      [bool]$state.installResult.acceptanceSucceeded
    ) -Message 'journey promotion state, consumed authority or exact action-count contract failed.'
    Assert-C33FFix5ArtifactBinding -State $state -Aggregate $aggregate
    Assert-C33FFix5PlayEvidence -State $state
    Assert-C33FFix5InstallEvidence -State $state
    Assert-C33FFix5JourneyEvidence -State $state
  }
}

Write-Output (
  'C33F FIX5 release phase transition passed: ' +
  "phase=$Phase; buildCount=$([int]$state.buildResult.buildCount); " +
  "uploadCount=$([int]$state.playResult.uploadCount); " +
  "installCount=$([int]$state.installResult.installCount); " +
  "deviceAcceptanceCount=$([int]$state.actionCounts.deviceAcceptance); " +
  'track=internal; secretValuesObserved=false.'
)
