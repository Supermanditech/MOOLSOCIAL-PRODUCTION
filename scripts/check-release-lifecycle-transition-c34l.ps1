[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$transitionPath = Join-Path $root 'scripts/invoke-release-lifecycle-transition-c34l.ps1'
$ticketId =
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE'
$versionName = '1.0.0-r60.76'
$versionCode = '2026081376'
$browserContractId = 'MOOLSOCIAL-C34L-R60-76-PREUPLOAD-BROWSER-ROUTE-PROOF-001'
$browserProducerId = 'MOOLSOCIAL-C34L-BROWSER-QUALIFICATION-PRODUCER-001'
$captureArtifactContractPath =
  'config/release-evidence-capture-artifact-contract-c34l.json'
$captureArtifactContractSha256 =
  'D7B8DE822D709F25CEB1AEFFFF4093260B3EFB83DCADE1F632309026ECC0B9D2'
$captureArtifactContractId = 'MOOLSOCIAL-C34L-CAPTURE-ARTIFACT-CONTRACT-003'
$deviceBindingSha256 =
  '97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF'
$utf8 = [Text.UTF8Encoding]::new($false)
$phaseByTransition = @{
  'founder-inputs-validated' = 'preprompt'; 'prebuild-failed' = 'prebuild'
  'build-start' = 'build'; 'build-failed' = 'build'; 'build-succeeded' = 'build'
  'upload-authorized' = 'preupload'; 'upload-succeeded' = 'postupload'
  'install-authorized' = 'postupload'; 'install-succeeded' = 'postinstall'
  'device-accepted' = 'journey'; 'reject' = 'rejection'
}
$countNames = @(
  'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
  'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
)
$authorityNames = @(
  'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)

function Assert-C34LFixture([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C34L lifecycle fixture rejected: $Message" }
}
function ConvertTo-C34LFixtureRelative([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path)
  Assert-C34LFixture ($full.StartsWith(
    $rootPrefix, [StringComparison]::OrdinalIgnoreCase
  )) 'fixture path escaped repository.'
  return $full.Substring($rootPrefix.Length).Replace('\', '/')
}
function Write-C34LFixtureText([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent)
  }
  [IO.File]::WriteAllText($Path, $Text, $utf8)
}
function Write-C34LFixtureJson([string]$Path, [object]$Value) {
  Write-C34LFixtureText $Path (($Value | ConvertTo-Json -Depth 60) +
    [Environment]::NewLine)
}
function Get-C34LFixtureFile([string]$Path) {
  return [pscustomobject]@{
    Path = $Path
    Relative = ConvertTo-C34LFixtureRelative $Path
    Sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    Bytes = (Get-Item -LiteralPath $Path).Length
  }
}
function New-C34LFixture([string]$Name) {
  $directory = Join-Path $fixtureRunRoot $Name
  [void](New-Item -ItemType Directory -Path $directory)
  $statePath = Join-Path $directory 'state.json'
  $aggregatePath = Join-Path $directory 'aggregate.json'
  $initial =
    'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required'
  $counts = [ordered]@{
    build=0; upload=0; install=0; deviceAcceptance=0
    passwordlessEmailSend=0; realSmsSend=0; otherTrack=0
    backendHostingProviderOrProductionDeployment=0
  }
  $authorities = [ordered]@{
    build='available_once'; uploadAndInternalActivation='held_postbuild_qualification'
    inPlaceOppoPlayUpdate='held_postupload_qualification'
    postinstallAcceptance='held_postinstall_journey_qualification'
  }
  $browserWorkflow = [ordered]@{
    browserEvidencePath=$null; browserEvidenceSha256=$null
    browserEvidenceBytes=0; browserEvidenceAttempt=0
    browserEvidenceTransition=$null; browserEvidencePhase=$null
    browserEvidencePreStateSha256=$null; browserEvidencePreAggregateSha256=$null
    browserSessionId=$null; browserSessionNonceSha256=$null
    browserEvidenceProducerId=$null; browserEvidenceProducedUtc=$null
    browserEvidenceExpiresUtc=$null; liveBrowserRouteQualified=$false
    sourceManifestPath=$null; sourceManifestSha256=$null; sourceManifestBytes=0
    blockerLedgerPath=$null; blockerLedgerSha256=$null; blockerLedgerBytes=0
    signedInMoolSocialAppRouteProved=$false; internalTestingRouteProved=$false
    noPlayWritePerformed=$true
  }
  $state = [ordered]@{
    schemaVersion=1; contractId='MOOLSOCIAL-C34L-STATE-FIXTURE'; ticketId=$ticketId
    aggregateStatePath=ConvertTo-C34LFixtureRelative $aggregatePath
    evidenceRoot=(ConvertTo-C34LFixtureRelative $directory) + '/evidence'
    machineState=$initial; buildAuthorization='available_once'
    uploadAuthorization='held_postbuild_qualification'
    installAuthorization='held_postupload_qualification'
    deviceAuthorization='held_postinstall_journey_qualification'
    candidate=[ordered]@{
      id=$ticketId; packageName='com.moolsocial.app'; versionName=$versionName
      versionCode=$versionCode; playTrack='internal'
      deviceBindingSha256=$deviceBindingSha256
      deviceModel='CPH2375'; disposition=$initial; artifactReusable=$false
    }
    authority=[ordered]@{ founderHiddenInputEntryAuthorized=$true }
    founderAuthorization=[ordered]@{ hiddenFounderInputsEntered=$false }
    runtimeConfiguration=[ordered]@{
      secretDefineFileQualifiedByFounder=$false
      googleServicesFileQualifiedByFounder=$false
      googleServerClientIdQualifiedByFounder=$false
    }
    releaseAuthorities=$authorities; actionCounts=$counts
    presealUploadWorkflow=$browserWorkflow
    buildResult=[ordered]@{
      state='not_started'; buildCount=0; wrapperInvocationCount=0; configOnlyCount=0
      artifactPath=$null; artifactSha256=$null; artifactBytes=0
      uploadSignerSha256=$null; provenance=$null
      packageVersionManifestProved=$false; googleAppIdResourceProved=$false
      crashlyticsBuildIdResourceProved=$false; splitAndArm64PayloadProved=$false
      mergedReleaseManifestProved=$false
    }
    playResult=[ordered]@{
      uploadCount=0; internalActivationCount=0; evidencePath=$null
      evidenceSha256=$null; evidenceBytes=0
    }
    installResult=[ordered]@{
      installCount=0; coldStartEvidencePath=$null; coldStartEvidenceSha256=$null
      coldStartEvidenceBytes=0; retainedDataEvidencePath=$null
      retainedDataEvidenceSha256=$null; retainedDataEvidenceBytes=0
      journeyEvidencePath=$null; journeyEvidenceSha256=$null
      journeyEvidenceBytes=0; acceptanceSucceeded=$false; failureEvidencePath=$null
    }
    lifecycleTransactionProofs=@(); rejection=$null
  }
  $aggregate = [ordered]@{
    schemaVersion=1; contractId='MOOLSOCIAL-C34L-AGGREGATE-FIXTURE'
    ticketId=$ticketId; machineState=$initial
    candidate=[ordered]@{
      id=$ticketId; versionName=$versionName; versionCode=$versionCode
      buildCount=0; uploadCount=0; installCount=0; deviceAcceptanceCount=0
      aabSha256=$null; disposition=$initial; artifactReusable=$false
    }
    releaseAuthorities=[ordered]@{
      build='available_once'; uploadAndInternalActivation='held_postbuild_qualification'
      inPlaceOppoPlayUpdate='held_postupload_qualification'
      postinstallAcceptance='held_postinstall_journey_qualification'
    }
    actionCounts=[ordered]@{
      build=0; upload=0; install=0; deviceAcceptance=0
      passwordlessEmailSend=0; realSmsSend=0; otherTrack=0
      backendHostingProviderOrProductionDeployment=0
    }
    presealUploadWorkflow=[ordered]@{
      browserEvidencePath=$null; browserEvidenceSha256=$null
      browserEvidenceBytes=0; browserEvidenceAttempt=0
      browserEvidenceTransition=$null; browserEvidencePhase=$null
      browserEvidencePreStateSha256=$null; browserEvidencePreAggregateSha256=$null
      browserSessionId=$null; browserSessionNonceSha256=$null
      browserEvidenceProducerId=$null; browserEvidenceProducedUtc=$null
      browserEvidenceExpiresUtc=$null; liveBrowserRouteQualified=$false
      sourceManifestPath=$null; sourceManifestSha256=$null; sourceManifestBytes=0
      blockerLedgerPath=$null; blockerLedgerSha256=$null; blockerLedgerBytes=0
      signedInMoolSocialAppRouteProved=$false; internalTestingRouteProved=$false
      noPlayWritePerformed=$true
    }
    lifecycleTransactionProofs=@(); rejection=$null
  }
  Assert-C34LFixture (
    -not [object]::ReferenceEquals($state.releaseAuthorities, $aggregate.releaseAuthorities) -and
    -not [object]::ReferenceEquals($state.actionCounts, $aggregate.actionCounts) -and
    @($state.actionCounts.Keys).Count -eq 8 -and
    @($aggregate.actionCounts.Keys).Count -eq 8 -and
    @($state.releaseAuthorities.Keys).Count -eq 4 -and
    @($aggregate.releaseAuthorities.Keys).Count -eq 4
  ) 'fixture detailed/aggregate vectors must be complete distinct projections.'
  Write-C34LFixtureJson $statePath $state
  Write-C34LFixtureJson $aggregatePath $aggregate
  return [pscustomobject]@{
    Directory=$directory; StatePath=$statePath; AggregatePath=$aggregatePath
    StateRelative=ConvertTo-C34LFixtureRelative $statePath; ProofNumber=0
  }
}
function Read-C34LFixture([object]$Fixture) {
  return [pscustomobject]@{
    State=Get-Content -Raw -LiteralPath $Fixture.StatePath | ConvertFrom-Json
    Aggregate=Get-Content -Raw -LiteralPath $Fixture.AggregatePath | ConvertFrom-Json
  }
}
function Get-C34LFixturePairHash([object]$Fixture) {
  return ((Get-FileHash -Algorithm SHA256 -LiteralPath $Fixture.StatePath).Hash + ':' +
    (Get-FileHash -Algorithm SHA256 -LiteralPath $Fixture.AggregatePath).Hash)
}
function New-C34LPrerequisiteProof(
  [object]$Fixture, [string]$Transition, [string]$Phase, [int]$Attempt = 1,
  [object]$BrowserEvidence = $null
) {
  $Fixture.ProofNumber++
  $current = Read-C34LFixture $Fixture
  $proofPath = Join-Path $Fixture.Directory (
    'proof-{0:D2}-{1}.json' -f $Fixture.ProofNumber, $Transition
  )
  $proof = [ordered]@{
    ticketId=$ticketId; attempt=$Attempt
    versionName=$versionName; versionCode=$versionCode
    transition=$Transition; phase=$Phase; passed=$true
    stateSha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $Fixture.StatePath).Hash
    aggregateSha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $Fixture.AggregatePath).Hash
    actionCounts=$current.State.actionCounts
    releaseAuthorities=$current.State.releaseAuthorities
  }
  if ($null -ne $BrowserEvidence) {
    $proof['browserEvidence'] = $BrowserEvidence
  }
  Write-C34LFixtureJson $proofPath $proof
  return Get-C34LFixtureFile $proofPath
}

function New-C34LBrowserEvidence([object]$Fixture, [string]$Name) {
  $current = Read-C34LFixture $Fixture
  $path = Join-Path $Fixture.Directory $Name
  $relative = ConvertTo-C34LFixtureRelative $path
  $utcFormat = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
  $produced = [DateTimeOffset]::UtcNow.AddSeconds(-2).ToString(
    $utcFormat, [Globalization.CultureInfo]::InvariantCulture
  )
  $expires = [DateTimeOffset]::UtcNow.AddMinutes(10).ToString(
    $utcFormat, [Globalization.CultureInfo]::InvariantCulture
  )
  $sessionNonceSha256 = 'A' * 64
  $sessionId = 'c34l-browser-session-' + $sessionNonceSha256.Substring(0, 16)
  $stateSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $Fixture.StatePath).Hash
  $aggregateSha256 = (
    Get-FileHash -Algorithm SHA256 -LiteralPath $Fixture.AggregatePath
  ).Hash
  $sourceManifestPath = Join-Path $Fixture.Directory 'source-manifest.txt'
  $blockerLedgerPath = Join-Path $Fixture.Directory 'blocker-ledger.json'
  Write-C34LFixtureText $sourceManifestPath 'fixture source manifest'
  Write-C34LFixtureJson $blockerLedgerPath ([ordered]@{
    fixture=$true; mutableOutsideSourceSeal=$true
  })
  $sourceManifest = Get-C34LFixtureFile $sourceManifestPath
  $blockerLedger = Get-C34LFixtureFile $blockerLedgerPath
  $evidence = [ordered]@{
    schemaVersion=1; contractId=$browserContractId; ticketId=$ticketId
    attempt=1; versionName=$versionName; versionCode=$versionCode
    transition='upload-authorized'; phase='preupload'
    stateSha256=$stateSha256; aggregateSha256=$aggregateSha256
    sourceManifest=[ordered]@{
      path=$sourceManifest.Relative; sha256=$sourceManifest.Sha256
      bytes=$sourceManifest.Bytes
    }
    blockerLedger=[ordered]@{
      path=$blockerLedger.Relative; sha256=$blockerLedger.Sha256
      bytes=$blockerLedger.Bytes; mutableOutsideSourceSeal=$true
    }
    sessionId=$sessionId; sessionNonceSha256=$sessionNonceSha256
    producerId=$browserProducerId; producedUtc=$produced; expiresUtc=$expires
    routes=[ordered]@{
      liveBrowserRouteQualified=$true
      signedInMoolSocialAppRouteProved=$true
      internalTestingRouteProved=$true
      sanitizedHost='play.google.com'
      sanitizedPath='/console/app/internal-testing'
      queryPresent=$false; fragmentPresent=$false
    }
    actionCounts=$current.State.actionCounts
    releaseAuthorities=$current.State.releaseAuthorities
    copiedFromPriorCandidate=$false
    noPlayWritePerformed=$true; uploadActionCount=0
    activationActionCount=0; otherTrackActionCount=0
    privateValuesObserved=$false
  }
  Write-C34LFixtureJson $path $evidence
  $file = Get-C34LFixtureFile $path
  $binding = [pscustomobject][ordered]@{
    browserEvidencePath=$relative; browserEvidenceSha256=$file.Sha256
    browserEvidenceBytes=$file.Bytes; browserEvidenceAttempt=1
    browserEvidenceTransition='upload-authorized'; browserEvidencePhase='preupload'
    browserEvidencePreStateSha256=$stateSha256
    browserEvidencePreAggregateSha256=$aggregateSha256
    browserSessionId=$sessionId; browserSessionNonceSha256=$sessionNonceSha256
    browserEvidenceProducerId=$browserProducerId
    browserEvidenceProducedUtc=$produced; browserEvidenceExpiresUtc=$expires
    sourceManifestPath=$sourceManifest.Relative
    sourceManifestSha256=$sourceManifest.Sha256
    sourceManifestBytes=$sourceManifest.Bytes
    blockerLedgerPath=$blockerLedger.Relative
    blockerLedgerSha256=$blockerLedger.Sha256
    blockerLedgerBytes=$blockerLedger.Bytes
    liveBrowserRouteQualified=$true; signedInMoolSocialAppRouteProved=$true
    internalTestingRouteProved=$true; noPlayWritePerformed=$true
  }
  return [pscustomobject]@{ File=$file; Binding=$binding }
}
function New-C34LFixtureSourceBinding(
  [object]$Fixture,
  [ValidateSet('play','oppo','journey')][string]$Kind
) {
  $current = Read-C34LFixture $Fixture
  $stateSha256 = (Get-FileHash -Algorithm SHA256 `
    -LiteralPath $Fixture.StatePath).Hash
  $aggregateSha256 = (Get-FileHash -Algorithm SHA256 `
    -LiteralPath $Fixture.AggregatePath).Hash
  $evidenceRoot = [string]$current.State.evidenceRoot
  $captureRoot = Join-Path $root (
    "$evidenceRoot/captures/attempt-1/$Kind".Replace('/','\')
  )
  [void](New-Item -ItemType Directory -Path $captureRoot -Force)
  $utcFormat = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
  $producedUtc = [DateTimeOffset]::UtcNow.AddSeconds(-2).ToString(
    $utcFormat,[Globalization.CultureInfo]::InvariantCulture
  )
  $expiresUtc = [DateTimeOffset]::UtcNow.AddMinutes(10).ToString(
    $utcFormat,[Globalization.CultureInfo]::InvariantCulture
  )
  $nonceCharacter = switch ($Kind) {
    'play' { 'A' }
    'oppo' { 'B' }
    'journey' { 'C' }
  }
  $spec = switch ($Kind) {
    'play' { [pscustomobject]@{
      EvidenceType='play_internal_testing_activation'
      Producer='MOOLSOCIAL-C34L-PLAY-CAPTURE-PRODUCER-001'
      Roles=@('internal_testing_release_receipt','internal_testing_status_observation')
      Leaves=@{
        internal_testing_release_receipt='internal-testing-release-receipt.json'
        internal_testing_status_observation='internal-testing-status-observation.json'
      }
    } }
    'oppo' { [pscustomobject]@{
      EvidenceType='oppo_play_in_place_update_pair'
      Producer='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
      Roles=@('cold_start_observation','retained_state_observation')
      Leaves=@{
        cold_start_observation='cold-start-observation.json'
        retained_state_observation='retained-state-observation.json'
      }
    } }
    'journey' { [pscustomobject]@{
      EvidenceType='mandatory_whole_app_journey_acceptance'
      Producer='MOOLSOCIAL-C34L-JOURNEY-CAPTURE-PRODUCER-001'
      Roles=@('journey_acceptance_manifest')
      Leaves=@{ journey_acceptance_manifest='journey-acceptance-manifest.json' }
    } }
  }
  $artifactBindings = @()
  $captureDigests = [ordered]@{}
  if ($Kind -ceq 'journey') {
    $journeyDirectory = Join-Path $captureRoot 'journeys'
    [void](New-Item -ItemType Directory -Path $journeyDirectory -Force)
    $journeyRows = @()
    foreach ($journeyId in @(
      'publicGuest','protectedGateway','supportedAuthentication','social',
      'wholeApp','c33gBlocker'
    )) {
      $journeyPath = Join-Path $journeyDirectory "$journeyId.json"
      Write-C34LFixtureJson $journeyPath ([ordered]@{
        schemaVersion=1; journeyId=$journeyId; passed=$true
      })
      $journeyFile = Get-C34LFixtureFile $journeyPath
      $journeyRows += [ordered]@{
        journeyId=$journeyId; path=$journeyFile.Relative
        sha256=$journeyFile.Sha256; bytes=$journeyFile.Bytes; passed=$true
      }
      $captureDigests[$journeyId + 'DigestSha256'] = $journeyFile.Sha256
    }
    $manifestPath = Join-Path $captureRoot `
      $spec.Leaves.journey_acceptance_manifest
    Write-C34LFixtureJson $manifestPath $journeyRows
    $manifestFile = Get-C34LFixtureFile $manifestPath
    $artifactBindings += [ordered]@{
      role='journey_acceptance_manifest'; path=$manifestFile.Relative
      sha256=$manifestFile.Sha256; bytes=$manifestFile.Bytes
      mediaType='application/json'
    }
  } else {
    foreach ($role in $spec.Roles) {
      $artifactPath = Join-Path $captureRoot $spec.Leaves[$role]
      Write-C34LFixtureJson $artifactPath ([ordered]@{
        schemaVersion=1; role=$role; passed=$true
      })
      $artifactFile = Get-C34LFixtureFile $artifactPath
      $artifactBindings += [ordered]@{
        role=$role; path=$artifactFile.Relative; sha256=$artifactFile.Sha256
        bytes=$artifactFile.Bytes; mediaType='application/json'
      }
    }
    if ($Kind -ceq 'play') {
      $receiptSha = [string]$artifactBindings[0].sha256
      $statusSha = [string]$artifactBindings[1].sha256
      $captureDigests['internalTestingRouteDigestSha256'] = $receiptSha
      $captureDigests['uploadReceiptDigestSha256'] = $receiptSha
      $captureDigests['activationStateDigestSha256'] = $statusSha
    } else {
      $coldSha = [string]$artifactBindings[0].sha256
      $retainedSha = [string]$artifactBindings[1].sha256
      $captureDigests['packageStateDigestSha256'] = $coldSha
      $captureDigests['coldStartDigestSha256'] = $coldSha
      $captureDigests['retainedDataDigestSha256'] = $retainedSha
    }
  }
  $capturePath = Join-Path $captureRoot 'capture-manifest.json'
  $capture = [ordered]@{
    schemaVersion=1
    captureContractId='MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001'
    evidenceType=$spec.EvidenceType; ticketId=$ticketId; attempt=1
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; preStateSha256=$stateSha256
    preAggregateSha256=$aggregateSha256
    actionCounts=$current.State.actionCounts
    releaseAuthorities=$current.State.releaseAuthorities
    artifactSha256=[string]$current.State.buildResult.artifactSha256
    artifactBytes=[int64]$current.State.buildResult.artifactBytes
    sourceProducerId=$spec.Producer
    sessionId="c34l-$Kind-session-00000001"
    nonceSha256=($nonceCharacter * 64)
    producedUtc=$producedUtc; expiresUtc=$expiresUtc
    captureDigests=$captureDigests
    captureArtifactContractPath=$captureArtifactContractPath
    captureArtifactContractSha256=$captureArtifactContractSha256
    captureArtifactContractId=$captureArtifactContractId
    captureArtifacts=$artifactBindings
  }
  Write-C34LFixtureJson $capturePath $capture
  $captureFile = Get-C34LFixtureFile $capturePath
  $attestationPath = Join-Path $Fixture.Directory (
    "evidence/attestations/source-attestation-$Kind-attempt-1.json".Replace('/','\')
  )
  $attestation = [ordered]@{
    schemaVersion=1; attestationContractId='MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001'
    evidenceType=$spec.EvidenceType; ticketId=$ticketId; attempt=1
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; preStateSha256=$stateSha256
    preAggregateSha256=$aggregateSha256
    actionCounts=$current.State.actionCounts
    releaseAuthorities=$current.State.releaseAuthorities
    artifactSha256=[string]$current.State.buildResult.artifactSha256
    artifactBytes=[int64]$current.State.buildResult.artifactBytes
    sourceProducerId=$spec.Producer; sessionId=$capture.sessionId
    nonceSha256=$capture.nonceSha256; producedUtc=$producedUtc; expiresUtc=$expiresUtc
    captureManifestPath=$captureFile.Relative
    captureManifestSha256=$captureFile.Sha256
    captureManifestBytes=$captureFile.Bytes; captureDigests=$captureDigests
  }
  Write-C34LFixtureJson $attestationPath $attestation
  $attestationFile = Get-C34LFixtureFile $attestationPath
  return [pscustomobject]@{
    Kind=$Kind; Current=$current; StateSha256=$stateSha256
    AggregateSha256=$aggregateSha256; EvidenceRoot=$evidenceRoot
    Spec=$spec; Attestation=$attestation; AttestationFile=$attestationFile
    Capture=$capture; CaptureFile=$captureFile
    SourceBinding=[pscustomobject][ordered]@{
      path=$attestationFile.Relative; sha256=$attestationFile.Sha256
      bytes=$attestationFile.Bytes; evidenceType=$spec.EvidenceType
      sourceProducerId=$spec.Producer; sessionId=$attestation.sessionId
      nonceSha256=$attestation.nonceSha256; producedUtc=$producedUtc
      expiresUtc=$expiresUtc; captureManifestPath=$captureFile.Relative
      captureManifestSha256=$captureFile.Sha256
      captureManifestBytes=$captureFile.Bytes; captureDigests=$captureDigests
    }
  }
}

function New-C34LFinalEvidenceSet(
  [object]$Fixture,
  [ValidateSet('play','oppo','journey')][string]$Kind
) {
  $source = New-C34LFixtureSourceBinding $Fixture $Kind
  $current = $source.Current
  $common = [ordered]@{
    schemaVersion=1; ticketId=$ticketId; attempt=1
    preStateSha256=$source.StateSha256
    preAggregateSha256=$source.AggregateSha256
    actionCounts=$current.State.actionCounts
    releaseAuthorities=$current.State.releaseAuthorities
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode
    artifactSha256=[string]$current.State.buildResult.artifactSha256
    artifactBytes=[int64]$current.State.buildResult.artifactBytes
  }
  $evidenceRootPath = Join-Path $root ($source.EvidenceRoot.Replace('/','\'))
  [void](New-Item -ItemType Directory -Path $evidenceRootPath -Force)
  if ($Kind -ceq 'play') {
    $path = Join-Path $evidenceRootPath `
      '07-play-internal-testing-activation-evidence.json'
    $value = [ordered]@{} + $common
    $value['evidenceContractId']='MOOLSOCIAL-C34L-PLAY-EVIDENCE-001'
    $value['evidenceType']='play_internal_testing_activation'
    $value['track']='internal'; $value['internalReleaseActive']=$true
    $value['uploadCount']=1; $value['internalActivationCount']=1
    $value['otherTrackChanged']=$false
    $value['sourceAttestation']=$source.SourceBinding
    Write-C34LFixtureJson $path $value
    return [pscustomobject]@{ Play=Get-C34LFixtureFile $path; Source=$source }
  }
  if ($Kind -ceq 'oppo') {
    $pairId = "oppo-1-$($source.StateSha256)"
    $identity = [ordered]@{} + $common
    $identity['evidenceContractId']='MOOLSOCIAL-C34L-OPPO-EVIDENCE-001'
    $identity['evidencePairId']=$pairId
    $identity['deviceBindingSha256']=$deviceBindingSha256
    $identity['deviceModel']='CPH2375'
    $identity['installerPackage']='com.android.vending'
    $identity['sourceAttestation']=$source.SourceBinding
    $coldPath = Join-Path $evidenceRootPath `
      '08-oppo-play-in-place-update-cold-start-evidence.json'
    $cold = [ordered]@{} + $identity
    $cold['evidenceType']='oppo_play_in_place_update_cold_start'
    $cold['coldStartInteractive']=$true; $cold['blankHierarchy']=$false
    $cold['timeout']=$false; $cold['flutterFatalErrorCount']=0
    $cold['androidRuntimeFatalCount']=0; $cold['anrCount']=0
    $cold['appProcessErrorScanPassed']=$true
    $cold['artifactRelationshipProved']=$true
    $cold['inPlaceUpdateProved']=$true
    Write-C34LFixtureJson $coldPath $cold
    $coldFile = Get-C34LFixtureFile $coldPath
    $retainedPath = Join-Path $evidenceRootPath `
      '09-oppo-in-place-retained-data-evidence.json'
    $retained = [ordered]@{} + $identity
    $retained['evidenceType']='oppo_in_place_retained_data'
    $retained['firstInstallTimeMillis']=1000L
    $retained['lastUpdateTimeMillis']=2000L
    $retained['firstInstallTimePreserved']=$true
    $retained['retainedDataContinuityProved']=$true
    $retained['inPlacePlayUpdateProved']=$true
    $retained['uninstallPerformed']=$false; $retained['dataClearPerformed']=$false
    $retained['downgradePerformed']=$false; $retained['adbInstallPerformed']=$false
    Write-C34LFixtureJson $retainedPath $retained
    $retainedFile = Get-C34LFixtureFile $retainedPath
    $transactionDirectory = Join-Path $evidenceRootPath 'transactions'
    [void](New-Item -ItemType Directory -Path $transactionDirectory -Force)
    $transactionPath = Join-Path $transactionDirectory `
      'oppo-evidence-pair-attempt-1.json'
    $utcFormat = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
    $preparedUtc = [DateTimeOffset]::UtcNow.AddSeconds(-1).ToString(
      $utcFormat,[Globalization.CultureInfo]::InvariantCulture
    )
    $committedUtc = [DateTimeOffset]::UtcNow.ToString(
      $utcFormat,[Globalization.CultureInfo]::InvariantCulture
    )
    Write-C34LFixtureJson $transactionPath ([ordered]@{
      schemaVersion=1
      transactionContractId='MOOLSOCIAL-C34L-OPPO-EVIDENCE-TRANSACTION-001'
      transactionId="oppo-evidence-1-$($source.StateSha256)-$($source.AggregateSha256)"
      ticketId=$ticketId; attempt=1; status='committed'
      preStateSha256=$source.StateSha256
      preAggregateSha256=$source.AggregateSha256
      artifactSha256=[string]$current.State.buildResult.artifactSha256
      artifactBytes=[int64]$current.State.buildResult.artifactBytes
      coldStart=[ordered]@{
        path=$coldFile.Relative; sha256=$coldFile.Sha256; bytes=$coldFile.Bytes
      }
      retainedData=[ordered]@{
        path=$retainedFile.Relative; sha256=$retainedFile.Sha256
        bytes=$retainedFile.Bytes
      }
      sourceAttestation=$source.SourceBinding
      preparedUtc=$preparedUtc; committedUtc=$committedUtc
    })
    return [pscustomobject]@{
      Cold=$coldFile; Retained=$retainedFile
      Transaction=Get-C34LFixtureFile $transactionPath; Source=$source
    }
  }
  $path = Join-Path $evidenceRootPath `
    '10-mandatory-whole-app-journey-evidence.json'
  $value = [ordered]@{} + $common
  $value['evidenceContractId']='MOOLSOCIAL-C34L-JOURNEY-EVIDENCE-001'
  $value['evidenceType']='mandatory_whole_app_journey_acceptance'
  $value['track']='internal'; $value['deviceBindingSha256']=$deviceBindingSha256
  $value['deviceModel']='CPH2375'; $value['installerPackage']='com.android.vending'
  $value['publicGuestJourneyPassed']=$true
  $value['protectedGatewayJourneyPassed']=$true
  $value['supportedAuthenticationJourneysPassed']=$true
  $value['socialJourneysPassed']=$true; $value['wholeAppJourneysPassed']=$true
  $value['c33gBlockerJourneysPassed']=$true
  $value['allMandatoryJourneysPassed']=$true; $value['evidenceComplete']=$true
  $value['newIssueCount']=0; $value['newDefectCount']=0
  $value['blankScreenCount']=0; $value['flutterFatalErrorCount']=0
  $value['androidRuntimeFatalCount']=0; $value['anrCount']=0
  $value['acceptanceSucceeded']=$true; $value['successClaimed']=$true
  $value['sourceAttestation']=$source.SourceBinding
  Write-C34LFixtureJson $path $value
  return [pscustomobject]@{ Journey=Get-C34LFixtureFile $path; Source=$source }
}

function Sync-C34LFixtureEvidenceSource(
  [object]$Source,
  [object]$EvidenceFile
) {
  $attestationFile = Get-C34LFixtureFile $Source.AttestationFile.Path
  $attestation = Get-Content -Raw -LiteralPath $attestationFile.Path |
    ConvertFrom-Json
  $evidence = Get-Content -Raw -LiteralPath $EvidenceFile.Path | ConvertFrom-Json
  $evidence.sourceAttestation.sha256 = $attestationFile.Sha256
  $evidence.sourceAttestation.bytes = $attestationFile.Bytes
  $evidence.sourceAttestation.captureManifestSha256 =
    [string]$attestation.captureManifestSha256
  $evidence.sourceAttestation.captureManifestBytes =
    [int64]$attestation.captureManifestBytes
  $evidence.sourceAttestation.captureDigests = $attestation.captureDigests
  Write-C34LFixtureJson $EvidenceFile.Path $evidence
  return Get-C34LFixtureFile $EvidenceFile.Path
}

function Invoke-C34LFixtureTransition {
  param(
    [Parameter(Mandatory)][object]$Fixture,
    [Parameter(Mandatory)][string]$Transition,
    [string]$Phase = [string]$phaseByTransition[$Transition],
    [hashtable]$Additional = @{}
  )
  $browserBinding = $null
  if ($Additional.ContainsKey('BrowserBinding')) {
    $browserBinding = $Additional.BrowserBinding
  }
  $proof = New-C34LPrerequisiteProof $Fixture $Transition $Phase 1 $browserBinding
  $parameters = @{
    Transition=$Transition; StatePath=$Fixture.StateRelative; FixtureMode=$true
    PrerequisiteGateEvidencePath=$proof.Relative
    PrerequisiteGateEvidenceSha256=$proof.Sha256
    PrerequisiteGatePhase=$Phase; Attempt=1; RepositoryRoot=$root
  }
  if ($null -ne $browserBinding) {
    $browserParameterMap = [ordered]@{
      BrowserEvidencePath='browserEvidencePath'
      BrowserEvidenceSha256='browserEvidenceSha256'
      BrowserEvidenceBytes='browserEvidenceBytes'
      BrowserSessionId='browserSessionId'
      BrowserSessionNonceSha256='browserSessionNonceSha256'
      BrowserEvidenceProducerId='browserEvidenceProducerId'
      BrowserEvidenceProducedUtc='browserEvidenceProducedUtc'
      BrowserEvidenceExpiresUtc='browserEvidenceExpiresUtc'
      SourceManifestPath='sourceManifestPath'
      SourceManifestSha256='sourceManifestSha256'
      SourceManifestBytes='sourceManifestBytes'
      BlockerLedgerPath='blockerLedgerPath'
      BlockerLedgerSha256='blockerLedgerSha256'
      BlockerLedgerBytes='blockerLedgerBytes'
      LiveBrowserRouteQualified='liveBrowserRouteQualified'
      SignedInMoolSocialAppRouteProved='signedInMoolSocialAppRouteProved'
      InternalTestingRouteProved='internalTestingRouteProved'
      NoPlayWritePerformed='noPlayWritePerformed'
    }
    foreach ($parameterName in $browserParameterMap.Keys) {
      $propertyName = $browserParameterMap[$parameterName]
      $parameters[$parameterName] = $browserBinding.$propertyName
    }
  }
  foreach ($key in $Additional.Keys) {
    if ($key -cne 'BrowserBinding') { $parameters[$key] = $Additional[$key] }
  }
  & $transitionPath @parameters | Out-Null
  [void]$coveredTransitions.Add($Transition)
}
function New-C34LBrowserReadyFixture([string]$Name) {
  $fixture = New-C34LFixture $Name
  Invoke-C34LFixtureTransition $fixture 'founder-inputs-validated'
  Invoke-C34LFixtureTransition $fixture 'build-start'
  $artifactPath = Join-Path $fixture.Directory 'fixture.aab'
  $provenancePath = Join-Path $fixture.Directory 'provenance.json'
  Write-C34LFixtureText $artifactPath 'fixture-aab'
  Write-C34LFixtureJson $provenancePath ([ordered]@{ candidateId=$ticketId; attempt=1 })
  $artifact = Get-C34LFixtureFile $artifactPath
  $provenance = Get-C34LFixtureFile $provenancePath
  Invoke-C34LFixtureTransition $fixture 'build-succeeded' -Additional @{
    ArtifactPath=$artifact.Relative; ArtifactSha256=$artifact.Sha256
    ArtifactBytes=$artifact.Bytes; UploadSignerSha256=('E' * 64)
    ArtifactProvenance=$provenance.Relative
  }
  return [pscustomobject]@{
    Fixture=$fixture
    Browser=New-C34LBrowserEvidence $fixture 'browser.json'
  }
}
function New-C34LUploadAuthorizedFixture([string]$Name) {
  $ready = New-C34LBrowserReadyFixture $Name
  Invoke-C34LFixtureTransition $ready.Fixture 'upload-authorized' -Additional @{
    BrowserBinding=$ready.Browser.Binding
  }
  return $ready.Fixture
}
function New-C34LDeviceReadyFixture([string]$Name) {
  $fixture = New-C34LUploadAuthorizedFixture $Name
  $play = New-C34LFinalEvidenceSet $fixture play
  Invoke-C34LFixtureTransition $fixture 'upload-succeeded' -Additional @{
    EvidencePath=$play.Play.Relative; EvidenceSha256=$play.Play.Sha256
    EvidenceBytes=$play.Play.Bytes
  }
  Invoke-C34LFixtureTransition $fixture 'install-authorized'
  $oppo = New-C34LFinalEvidenceSet $fixture oppo
  Invoke-C34LFixtureTransition $fixture 'install-succeeded' -Additional @{
    EvidencePath=$oppo.Cold.Relative; EvidenceSha256=$oppo.Cold.Sha256
    EvidenceBytes=$oppo.Cold.Bytes
    RetainedDataEvidencePath=$oppo.Retained.Relative
    RetainedDataEvidenceSha256=$oppo.Retained.Sha256
    RetainedDataEvidenceBytes=$oppo.Retained.Bytes
  }
  return $fixture
}
function Invoke-C34LBrowserBoundFixture {
  param(
    [Parameter(Mandatory)][object]$Fixture,
    [Parameter(Mandatory)][object]$ProofBinding,
    [Parameter(Mandatory)][object]$InvocationBinding,
    [string]$Transition='upload-authorized',
    [string]$Phase='preupload'
  )
  $proof = New-C34LPrerequisiteProof $Fixture $Transition $Phase 1 $ProofBinding
  & $transitionPath -Transition $Transition -StatePath $Fixture.StateRelative `
    -FixtureMode -PrerequisiteGateEvidencePath $proof.Relative `
    -PrerequisiteGateEvidenceSha256 $proof.Sha256 `
    -PrerequisiteGatePhase $Phase -Attempt 1 `
    -BrowserEvidencePath ([string]$InvocationBinding.browserEvidencePath) `
    -BrowserEvidenceSha256 ([string]$InvocationBinding.browserEvidenceSha256) `
    -BrowserEvidenceBytes ([long]$InvocationBinding.browserEvidenceBytes) `
    -BrowserSessionId ([string]$InvocationBinding.browserSessionId) `
    -BrowserSessionNonceSha256 `
      ([string]$InvocationBinding.browserSessionNonceSha256) `
    -BrowserEvidenceProducerId `
      ([string]$InvocationBinding.browserEvidenceProducerId) `
    -BrowserEvidenceProducedUtc `
      ([string]$InvocationBinding.browserEvidenceProducedUtc) `
    -BrowserEvidenceExpiresUtc `
      ([string]$InvocationBinding.browserEvidenceExpiresUtc) `
    -SourceManifestPath ([string]$InvocationBinding.sourceManifestPath) `
    -SourceManifestSha256 ([string]$InvocationBinding.sourceManifestSha256) `
    -SourceManifestBytes ([long]$InvocationBinding.sourceManifestBytes) `
    -BlockerLedgerPath ([string]$InvocationBinding.blockerLedgerPath) `
    -BlockerLedgerSha256 ([string]$InvocationBinding.blockerLedgerSha256) `
    -BlockerLedgerBytes ([long]$InvocationBinding.blockerLedgerBytes) `
    -LiveBrowserRouteQualified `
    -SignedInMoolSocialAppRouteProved `
    -InternalTestingRouteProved -NoPlayWritePerformed `
    -RepositoryRoot $root | Out-Null
}
function Assert-C34LExpectedRejection(
  [object]$Fixture, [scriptblock]$Action, [string]$Label
) {
  $before = Get-C34LFixturePairHash $Fixture
  $rejected = $false
  try { & $Action } catch { $rejected = $true }
  $after = Get-C34LFixturePairHash $Fixture
  Assert-C34LFixture ($rejected -and $before -ceq $after) `
    "$Label did not reject before changing either state owner."
}
function Assert-C34LExpectedClassRejection(
  [object]$Fixture,
  [scriptblock]$Action,
  [string]$Label,
  [string]$ExpectedMessagePattern
) {
  $before = Get-C34LFixturePairHash $Fixture
  $message = $null
  try { & $Action } catch { $message = [string]$_.Exception.Message }
  $after = Get-C34LFixturePairHash $Fixture
  Assert-C34LFixture (
    -not [string]::IsNullOrWhiteSpace($message) -and $before -ceq $after
  ) "$Label did not reject before changing either state owner."
  Assert-C34LFixture (
    [regex]::IsMatch($message,$ExpectedMessagePattern)
  ) "$Label rejected in an unexpected class: $message"
}
function Assert-C34LFinalParity([object]$Fixture) {
  $current = Read-C34LFixture $Fixture
  foreach ($name in $countNames) {
    Assert-C34LFixture (
      [int]$current.State.actionCounts.$name -eq [int]$current.Aggregate.actionCounts.$name
    ) "final count parity changed at $name."
  }
  foreach ($name in $authorityNames) {
    Assert-C34LFixture (
      [string]$current.State.releaseAuthorities.$name -ceq
        [string]$current.Aggregate.releaseAuthorities.$name
    ) "final authority parity changed at $name."
  }
}

Assert-C34LFixture (Test-Path -LiteralPath $transitionPath -PathType Leaf) `
  'transition owner is missing.'
$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
  $transitionPath, [ref]$null, [ref]$parseErrors
)
Assert-C34LFixture (@($parseErrors).Count -eq 0) 'transition owner does not parse.'
$transitionSource = Get-Content -Raw -LiteralPath $transitionPath
Assert-C34LFixture (
  $transitionSource.IndexOf('[IO.Path]::GetRelativePath',
    [StringComparison]::OrdinalIgnoreCase) -lt 0
) 'transition owner still depends on Path.GetRelativePath.'
foreach ($required in @(
  'playResult.evidenceSha256', 'playResult.evidenceBytes',
  'installResult.coldStartEvidenceSha256', 'installResult.coldStartEvidenceBytes',
  'installResult.retainedDataEvidenceSha256', 'installResult.retainedDataEvidenceBytes',
  'installResult.journeyEvidenceSha256', 'installResult.journeyEvidenceBytes',
  'preStateSha256', 'preAggregateSha256', 'browserEvidencePath',
  'browserSessionNonceSha256', 'browserEvidenceExpiresUtc',
  'sourceManifestPath', 'sourceManifestSha256', 'sourceManifestBytes',
  'blockerLedgerPath', 'blockerLedgerSha256', 'blockerLedgerBytes',
  "'c34l-browser-session-'", '[string]$browser.routes.sanitizedHost',
  "'play.google.com'", '[string]$browser.routes.sanitizedPath',
  "'/console/app/internal-testing'", '-ceq',
  "'upload-authorized' = 'preupload'"
)) {
  Assert-C34LFixture ($transitionSource.Contains($required)) `
    "transition owner is missing required binding $required."
}
foreach ($forbidden in @(
  'firebase login:list --json', 'Authorization: Bearer',
  ('-----BEGIN' + ' PRIVATE KEY-----'), 'freshSessionProof'
)) {
  Assert-C34LFixture ($transitionSource.IndexOf(
    $forbidden, [StringComparison]::OrdinalIgnoreCase
  ) -lt 0) "transition owner contains forbidden action $forbidden."
}
foreach ($actionPattern in @(
  '(?im)^\s*(?:&\s+)?adb(?:\.exe)?\s+(?:install|uninstall)\b',
  '(?im)^\s*(?:&\s+)?adb(?:\.exe)?\s+shell\s+pm\s+clear\b',
  '(?im)^\s*Start-Process\s+(?:-FilePath\s+)?[''"]?adb(?:\.exe)?[''"]?\b'
)) {
  Assert-C34LFixture (-not [regex]::IsMatch($transitionSource,$actionPattern)) `
    'transition owner contains an executable OPPO mutation action.'
}

$fixtureBase = Join-Path $root 'tmp/c34l-release-transaction-fixtures'
if (-not (Test-Path -LiteralPath $fixtureBase -PathType Container)) {
  [void](New-Item -ItemType Directory -Path $fixtureBase)
}
$fixtureRunRoot = Join-Path $fixtureBase (
  'lifecycle-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
)
[void](New-Item -ItemType Directory -Path $fixtureRunRoot)
$escapeRoot = Join-Path $root (
  'tmp/c34l-release-transaction-escape-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
)
$coveredTransitions = [Collections.Generic.HashSet[string]]::new(
  [StringComparer]::Ordinal
)
$fixtureReparsePoints = [Collections.Generic.List[string]]::new()

try {
  $positive = New-C34LFixture 'positive-eleven-transitions'
  Invoke-C34LFixtureTransition $positive 'founder-inputs-validated'
  $atomicJournalFiles = @(Get-ChildItem -LiteralPath (
    Join-Path $positive.Directory 'journals'
  ) -Filter '*.json' -File)
  $atomicResidue = @(Get-ChildItem -LiteralPath $positive.Directory -Recurse -File |
    Where-Object { $_.Name -like '*.tmp-*' -or $_.Name -like '*.backup-*' })
  Assert-C34LFixture (
    $atomicJournalFiles.Count -eq 1 -and $atomicResidue.Count -eq 0 -and
    (Test-Path -LiteralPath $positive.StatePath -PathType Leaf) -and
    (Test-Path -LiteralPath $positive.AggregatePath -PathType Leaf)
  ) 'atomic helper did not prove new journal plus existing state writes without residue.'
  Invoke-C34LFixtureTransition $positive 'build-start'
  $twoTransitionJournals = @(Get-ChildItem -LiteralPath (
    Join-Path $positive.Directory 'journals'
  ) -Filter '*.json' -File | ForEach-Object {
    Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json
  } | Sort-Object sequence)
  Assert-C34LFixture (
    $twoTransitionJournals.Count -eq 2 -and
    [int]$twoTransitionJournals[0].sequence -eq 1 -and
    [int]$twoTransitionJournals[1].sequence -eq 2 -and
    [string]$twoTransitionJournals[0].stateAfterSha256 -ceq
      [string]$twoTransitionJournals[1].stateBeforeSha256 -and
    [string]$twoTransitionJournals[0].aggregateAfterSha256 -ceq
      [string]$twoTransitionJournals[1].aggregateBeforeSha256
  ) 'two consecutive lawful transitions did not form one contiguous journal chain.'
  $artifactPath = Join-Path $positive.Directory 'MoolSocial-fixture.aab'
  $provenancePath = Join-Path $positive.Directory 'provenance.json'
  Write-C34LFixtureText $artifactPath 'fixture-aab-bytes'
  Write-C34LFixtureJson $provenancePath ([ordered]@{ candidateId=$ticketId; attempt=1 })
  $artifact = Get-C34LFixtureFile $artifactPath
  $provenance = Get-C34LFixtureFile $provenancePath
  Invoke-C34LFixtureTransition $positive 'build-succeeded' -Additional @{
    ArtifactPath=$artifact.Relative; ArtifactSha256=$artifact.Sha256
    ArtifactBytes=$artifact.Bytes; UploadSignerSha256=('B' * 64)
    ArtifactProvenance=$provenance.Relative
  }
  $browserEvidence = New-C34LBrowserEvidence $positive 'browser.json'
  Invoke-C34LFixtureTransition $positive 'upload-authorized' -Additional @{
    BrowserBinding=$browserEvidence.Binding
  }
  $playSet = New-C34LFinalEvidenceSet $positive play
  $playEvidence = $playSet.Play
  Invoke-C34LFixtureTransition $positive 'upload-succeeded' -Additional @{
    EvidencePath=$playEvidence.Relative; EvidenceSha256=$playEvidence.Sha256
    EvidenceBytes=$playEvidence.Bytes
  }
  Invoke-C34LFixtureTransition $positive 'install-authorized'
  $oppoSet = New-C34LFinalEvidenceSet $positive oppo
  $coldEvidence = $oppoSet.Cold
  $retainedEvidence = $oppoSet.Retained
  Invoke-C34LFixtureTransition $positive 'install-succeeded' -Additional @{
    EvidencePath=$coldEvidence.Relative; EvidenceSha256=$coldEvidence.Sha256
    EvidenceBytes=$coldEvidence.Bytes; RetainedDataEvidencePath=$retainedEvidence.Relative
    RetainedDataEvidenceSha256=$retainedEvidence.Sha256
    RetainedDataEvidenceBytes=$retainedEvidence.Bytes
  }
  $journeySet = New-C34LFinalEvidenceSet $positive journey
  $journeyEvidence = $journeySet.Journey
  Invoke-C34LFixtureTransition $positive 'device-accepted' -Additional @{
    EvidencePath=$journeyEvidence.Relative; EvidenceSha256=$journeyEvidence.Sha256
    EvidenceBytes=$journeyEvidence.Bytes
  }
  $accepted = Read-C34LFixture $positive
  Assert-C34LFixture (
    [string]$accepted.State.machineState -ceq
      'internal_testing_oppo_device_acceptance_succeeded' -and
    (@($countNames | ForEach-Object { [int]$accepted.State.actionCounts.$_ }) -join ',') -ceq
      '1,1,1,1,0,0,0,0' -and
    (@($authorityNames | ForEach-Object {
      [string]$accepted.State.releaseAuthorities.$_
    }) -join ',') -ceq 'consumed,consumed,consumed,consumed' -and
    [string]$accepted.State.playResult.evidenceSha256 -ceq $playEvidence.Sha256 -and
    [int64]$accepted.State.playResult.evidenceBytes -eq $playEvidence.Bytes -and
    [string]$accepted.State.installResult.coldStartEvidenceSha256 -ceq
      $coldEvidence.Sha256 -and
    [int64]$accepted.State.installResult.coldStartEvidenceBytes -eq $coldEvidence.Bytes -and
    [string]$accepted.State.installResult.retainedDataEvidenceSha256 -ceq
      $retainedEvidence.Sha256 -and
    [int64]$accepted.State.installResult.retainedDataEvidenceBytes -eq
      $retainedEvidence.Bytes -and
    [string]$accepted.State.installResult.journeyEvidenceSha256 -ceq
      $journeyEvidence.Sha256 -and
    [int64]$accepted.State.installResult.journeyEvidenceBytes -eq $journeyEvidence.Bytes -and
    [string]$accepted.State.presealUploadWorkflow.browserEvidenceSha256 -ceq
      $browserEvidence.File.Sha256 -and
    [string]$accepted.Aggregate.presealUploadWorkflow.browserEvidenceSha256 -ceq
      $browserEvidence.File.Sha256 -and
    [string]$accepted.State.presealUploadWorkflow.browserSessionId -ceq
      [string]$browserEvidence.Binding.browserSessionId -and
    @($accepted.State.presealUploadWorkflow.PSObject.Properties | Where-Object {
      $_.Name -in @(
        'browserEvidencePath', 'browserEvidenceSha256', 'browserEvidenceBytes',
        'browserEvidenceAttempt', 'browserEvidenceTransition',
        'browserEvidencePhase', 'browserEvidencePreStateSha256',
        'browserEvidencePreAggregateSha256', 'browserSessionId',
        'browserSessionNonceSha256', 'browserEvidenceProducerId',
        'browserEvidenceProducedUtc', 'browserEvidenceExpiresUtc',
        'sourceManifestPath', 'sourceManifestSha256', 'sourceManifestBytes',
        'blockerLedgerPath', 'blockerLedgerSha256', 'blockerLedgerBytes',
        'liveBrowserRouteQualified', 'signedInMoolSocialAppRouteProved',
        'internalTestingRouteProved', 'noPlayWritePerformed'
      )
    }).Count -eq 23 -and
    [string]$accepted.State.presealUploadWorkflow.browserSessionId -ceq (
      'c34l-browser-session-' +
        [string]$accepted.State.presealUploadWorkflow.browserSessionNonceSha256.Substring(0, 16)
    ) -and
    [string]$accepted.State.presealUploadWorkflow.sourceManifestSha256 -ceq
      [string]$browserEvidence.Binding.sourceManifestSha256 -and
    [string]$accepted.State.presealUploadWorkflow.blockerLedgerSha256 -ceq
      [string]$browserEvidence.Binding.blockerLedgerSha256 -and
    @($accepted.State.lifecycleTransactionProofs | Where-Object {
      [string]$_.transition -ceq 'upload-authorized' -and
      [string]$_.browserEvidence.browserSessionId -ceq
        [string]$browserEvidence.Binding.browserSessionId
    }).Count -eq 1 -and
    @($accepted.State.lifecycleTransactionProofs).Count -eq 8 -and
    @($accepted.State.lifecycleTransactionProofs | Where-Object {
      [string]$_.ticketId -cne $ticketId -or [int]$_.attempt -ne 1
    }).Count -eq 0 -and
    (ConvertTo-Json -InputObject @($accepted.State.lifecycleTransactionProofs) `
      -Depth 60 -Compress) -ceq
      (ConvertTo-Json -InputObject @($accepted.Aggregate.lifecycleTransactionProofs) `
        -Depth 60 -Compress)
  ) 'positive lifecycle or retained evidence bindings changed.'
  $retainedActionEvidence = Get-Content -Raw -LiteralPath $retainedEvidence.Path |
    ConvertFrom-Json
  Assert-C34LFixture (
    -not [bool]$retainedActionEvidence.uninstallPerformed -and
    -not [bool]$retainedActionEvidence.dataClearPerformed -and
    -not [bool]$retainedActionEvidence.downgradePerformed -and
    -not [bool]$retainedActionEvidence.adbInstallPerformed -and
    [int]$accepted.State.actionCounts.passwordlessEmailSend -eq 0 -and
    [int]$accepted.State.actionCounts.realSmsSend -eq 0 -and
    [int]$accepted.State.actionCounts.otherTrack -eq 0 -and
    [int]$accepted.State.actionCounts.backendHostingProviderOrProductionDeployment -eq 0
  ) 'fixture lifecycle recorded a forbidden external, device-destructive or private action.'
  Assert-C34LFinalParity $positive

  $prebuildFailure = New-C34LFixture 'positive-prebuild-failure'
  Invoke-C34LFixtureTransition $prebuildFailure 'founder-inputs-validated'
  $prebuildLog = Join-Path $prebuildFailure.Directory 'prebuild-failure.log'
  Write-C34LFixtureText $prebuildLog 'sanitized fixture prebuild failure'
  Invoke-C34LFixtureTransition $prebuildFailure 'prebuild-failed' -Additional @{
    EvidencePath=ConvertTo-C34LFixtureRelative $prebuildLog
    FailureStage='candidate-gate'
  }
  $prebuildRejected = Read-C34LFixture $prebuildFailure
  Assert-C34LFixture (
    [string]$prebuildRejected.State.rejection.failureStage -ceq 'candidate-gate' -and
    [int]$prebuildRejected.State.actionCounts.build -eq 0
  ) 'prebuild-failed did not retain FailureStage at zero actions.'

  $buildFailure = New-C34LFixture 'positive-build-failure'
  Invoke-C34LFixtureTransition $buildFailure 'founder-inputs-validated'
  Invoke-C34LFixtureTransition $buildFailure 'build-start'
  $buildLog = Join-Path $buildFailure.Directory 'build-failure.log'
  Write-C34LFixtureText $buildLog 'sanitized fixture build failure'
  Invoke-C34LFixtureTransition $buildFailure 'build-failed' -Additional @{
    EvidencePath=ConvertTo-C34LFixtureRelative $buildLog; FailureStage='copy'
  }
  Assert-C34LFinalParity $buildFailure

  $rejection = New-C34LFixture 'positive-rejection'
  $rejectionEvidence = Join-Path $rejection.Directory 'rejection.json'
  Write-C34LFixtureJson $rejectionEvidence ([ordered]@{ sanitized=$true })
  Invoke-C34LFixtureTransition $rejection 'reject' -Additional @{
    EvidencePath=ConvertTo-C34LFixtureRelative $rejectionEvidence
    RejectionMachineState='prebuild_rejected_fixture_successor_required'
    RejectionRegistryId='REG-20260817-9999-C34L-FIXTURE'
  }
  Assert-C34LFinalParity $rejection

  Assert-C34LFixture (
    $coveredTransitions.Count -eq 11 -and
    @($phaseByTransition.Keys | Where-Object { -not $coveredTransitions.Contains($_) }).Count -eq 0
  ) 'positive coverage did not execute all eleven declared transitions.'

  $wrongPhase = New-C34LFixture 'negative-wrong-phase'
  Assert-C34LExpectedRejection $wrongPhase {
    Invoke-C34LFixtureTransition $wrongPhase 'founder-inputs-validated' -Phase 'build'
  } 'wrong transition phase'

  $wrongAttempt = New-C34LFixture 'negative-wrong-attempt'
  $wrongAttemptProof = New-C34LPrerequisiteProof `
    $wrongAttempt 'founder-inputs-validated' 'preprompt' 1
  Assert-C34LExpectedRejection $wrongAttempt {
    & $transitionPath -Transition 'founder-inputs-validated' `
      -StatePath $wrongAttempt.StateRelative -FixtureMode `
      -PrerequisiteGateEvidencePath $wrongAttemptProof.Relative `
      -PrerequisiteGateEvidenceSha256 $wrongAttemptProof.Sha256 `
      -PrerequisiteGatePhase 'preprompt' -Attempt 2 -RepositoryRoot $root
  } 'wrong prerequisite proof attempt'

  $missingDeviceBinding = New-C34LFixture 'negative-missing-device-binding'
  $missingDeviceObjects = Read-C34LFixture $missingDeviceBinding
  $missingDeviceObjects.State.candidate.PSObject.Properties.Remove(
    'deviceBindingSha256'
  )
  Write-C34LFixtureJson $missingDeviceBinding.StatePath $missingDeviceObjects.State
  Assert-C34LExpectedClassRejection $missingDeviceBinding {
    Invoke-C34LFixtureTransition $missingDeviceBinding 'founder-inputs-validated'
  } 'missing candidate device binding' 'candidate device binding schema changed'

  $wrongCandidateBinding = New-C34LFixture 'negative-wrong-candidate-device-binding'
  $wrongCandidateObjects = Read-C34LFixture $wrongCandidateBinding
  $wrongCandidateObjects.State.candidate.deviceBindingSha256 = 'D' * 64
  Write-C34LFixtureJson $wrongCandidateBinding.StatePath $wrongCandidateObjects.State
  Assert-C34LExpectedClassRejection $wrongCandidateBinding {
    Invoke-C34LFixtureTransition $wrongCandidateBinding 'founder-inputs-validated'
  } 'wrong candidate device binding' `
    'candidate identity or detailed/aggregate common parity changed'

  $rawCandidateField = New-C34LFixture 'negative-raw-candidate-device-field'
  $rawFieldObjects = Read-C34LFixture $rawCandidateField
  $rawFieldObjects.State.candidate | Add-Member -NotePropertyName deviceSerial `
    -NotePropertyValue 'fixture-raw-device-value'
  Write-C34LFixtureJson $rawCandidateField.StatePath $rawFieldObjects.State
  Assert-C34LExpectedClassRejection $rawCandidateField {
    Invoke-C34LFixtureTransition $rawCandidateField 'founder-inputs-validated'
  } 'raw candidate device field' `
    'detailed candidate contains forbidden private property candidate[.]deviceSerial'

  $rawCandidateValue = New-C34LFixture 'negative-raw-candidate-device-value'
  $rawValueObjects = Read-C34LFixture $rawCandidateValue
  $rawValueObjects.State.candidate | Add-Member -NotePropertyName deviceBindingHint `
    -NotePropertyValue '2b3e0f71'
  Write-C34LFixtureJson $rawCandidateValue.StatePath $rawValueObjects.State
  Assert-C34LExpectedClassRejection $rawCandidateValue {
    Invoke-C34LFixtureTransition $rawCandidateValue 'founder-inputs-validated'
  } 'raw candidate device value' `
    'detailed candidate contains a forbidden private value shape at candidate[.]deviceBindingHint'

  $missingBrowser = New-C34LBrowserReadyFixture 'negative-browser-missing'
  Assert-C34LExpectedRejection $missingBrowser.Fixture {
    Invoke-C34LFixtureTransition $missingBrowser.Fixture 'upload-authorized'
  } 'missing browser invocation and prerequisite binding'

  $mismatchedBrowser = New-C34LBrowserReadyFixture 'negative-browser-mismatch'
  $mismatchedInvocation = (
    $mismatchedBrowser.Browser.Binding | ConvertTo-Json -Depth 20
  ) | ConvertFrom-Json
  $mismatchedInvocation.browserSessionId =
    'c34l-browser-session-' + [Guid]::NewGuid().ToString('N')
  Assert-C34LExpectedRejection $mismatchedBrowser.Fixture {
    Invoke-C34LBrowserBoundFixture `
      -Fixture $mismatchedBrowser.Fixture `
      -ProofBinding $mismatchedBrowser.Browser.Binding `
      -InvocationBinding $mismatchedInvocation
  } 'browser invocation and prerequisite mismatch'

  $tamperedBrowser = New-C34LBrowserReadyFixture 'negative-browser-tamper'
  [IO.File]::AppendAllText(
    $tamperedBrowser.Browser.File.Path,
    [Environment]::NewLine,
    $utf8
  )
  Assert-C34LExpectedRejection $tamperedBrowser.Fixture {
    Invoke-C34LBrowserBoundFixture `
      -Fixture $tamperedBrowser.Fixture `
      -ProofBinding $tamperedBrowser.Browser.Binding `
      -InvocationBinding $tamperedBrowser.Browser.Binding
  } 'tampered retained browser evidence'

  $replayedBrowser = New-C34LBrowserReadyFixture 'negative-browser-replay'
  Invoke-C34LBrowserBoundFixture `
    -Fixture $replayedBrowser.Fixture `
    -ProofBinding $replayedBrowser.Browser.Binding `
    -InvocationBinding $replayedBrowser.Browser.Binding
  Assert-C34LExpectedRejection $replayedBrowser.Fixture {
    Invoke-C34LBrowserBoundFixture `
      -Fixture $replayedBrowser.Fixture `
      -ProofBinding $replayedBrowser.Browser.Binding `
      -InvocationBinding $replayedBrowser.Browser.Binding
  } 'replayed browser session binding'

  $wrongBrowserPhase = New-C34LBrowserReadyFixture 'negative-browser-phase'
  Assert-C34LExpectedRejection $wrongBrowserPhase.Fixture {
    Invoke-C34LBrowserBoundFixture `
      -Fixture $wrongBrowserPhase.Fixture `
      -ProofBinding $wrongBrowserPhase.Browser.Binding `
      -InvocationBinding $wrongBrowserPhase.Browser.Binding `
      -Phase 'postbuild'
  } 'browser wrong transition phase'

  $wrongBrowserTransition = New-C34LBrowserReadyFixture `
    'negative-browser-transition'
  Assert-C34LExpectedRejection $wrongBrowserTransition.Fixture {
    Invoke-C34LBrowserBoundFixture `
      -Fixture $wrongBrowserTransition.Fixture `
      -ProofBinding $wrongBrowserTransition.Browser.Binding `
      -InvocationBinding $wrongBrowserTransition.Browser.Binding `
      -Transition 'upload-succeeded'
  } 'browser metadata on wrong transition'

  $wrongDerivedSession = New-C34LBrowserReadyFixture `
    'negative-browser-session-derivation'
  $wrongDerivedValue = Get-Content -Raw `
    -LiteralPath $wrongDerivedSession.Browser.File.Path | ConvertFrom-Json
  $wrongDerivedValue.sessionId = 'c34l-browser-session-BBBBBBBBBBBBBBBB'
  Write-C34LFixtureJson `
    $wrongDerivedSession.Browser.File.Path $wrongDerivedValue
  $wrongDerivedSession.Browser.Binding.browserSessionId =
    [string]$wrongDerivedValue.sessionId
  $wrongDerivedSession.Browser.Binding.browserEvidenceSha256 =
    (Get-FileHash -Algorithm SHA256 `
      -LiteralPath $wrongDerivedSession.Browser.File.Path).Hash
  $wrongDerivedSession.Browser.Binding.browserEvidenceBytes =
    (Get-Item -LiteralPath $wrongDerivedSession.Browser.File.Path).Length
  Assert-C34LExpectedRejection $wrongDerivedSession.Fixture {
    Invoke-C34LBrowserBoundFixture `
      -Fixture $wrongDerivedSession.Fixture `
      -ProofBinding $wrongDerivedSession.Browser.Binding `
      -InvocationBinding $wrongDerivedSession.Browser.Binding
  } 'browser session id not derived from nonce SHA-256'

  $wrongSanitizedRoute = New-C34LBrowserReadyFixture `
    'negative-browser-sanitized-route'
  $wrongRouteValue = Get-Content -Raw `
    -LiteralPath $wrongSanitizedRoute.Browser.File.Path | ConvertFrom-Json
  $wrongRouteValue.routes.sanitizedHost = 'example.invalid'
  Write-C34LFixtureJson $wrongSanitizedRoute.Browser.File.Path $wrongRouteValue
  $wrongSanitizedRoute.Browser.Binding.browserEvidenceSha256 =
    (Get-FileHash -Algorithm SHA256 `
      -LiteralPath $wrongSanitizedRoute.Browser.File.Path).Hash
  $wrongSanitizedRoute.Browser.Binding.browserEvidenceBytes =
    (Get-Item -LiteralPath $wrongSanitizedRoute.Browser.File.Path).Length
  Assert-C34LExpectedRejection $wrongSanitizedRoute.Fixture {
    Invoke-C34LBrowserBoundFixture `
      -Fixture $wrongSanitizedRoute.Fixture `
      -ProofBinding $wrongSanitizedRoute.Browser.Binding `
      -InvocationBinding $wrongSanitizedRoute.Browser.Binding
  } 'browser sanitized host changed'

  $missingSourceBinding = New-C34LBrowserReadyFixture `
    'negative-browser-source-binding'
  $missingSourceBinding.Browser.Binding.sourceManifestPath = $null
  Assert-C34LExpectedRejection $missingSourceBinding.Fixture {
    Invoke-C34LBrowserBoundFixture `
      -Fixture $missingSourceBinding.Fixture `
      -ProofBinding $missingSourceBinding.Browser.Binding `
      -InvocationBinding $missingSourceBinding.Browser.Binding
  } 'browser source manifest binding missing'

  $staleProof = New-C34LFixture 'negative-stale-proof'
  $proof = New-C34LPrerequisiteProof $staleProof 'founder-inputs-validated' 'preprompt'
  $staleObjects = Read-C34LFixture $staleProof
  $staleObjects.State | Add-Member -NotePropertyName fixtureNonce -NotePropertyValue 'changed'
  $staleObjects.Aggregate | Add-Member -NotePropertyName fixtureNonce -NotePropertyValue 'changed'
  Write-C34LFixtureJson $staleProof.StatePath $staleObjects.State
  Write-C34LFixtureJson $staleProof.AggregatePath $staleObjects.Aggregate
  Assert-C34LExpectedRejection $staleProof {
    & $transitionPath -Transition 'founder-inputs-validated' `
      -StatePath $staleProof.StateRelative -FixtureMode `
      -PrerequisiteGateEvidencePath $proof.Relative `
      -PrerequisiteGateEvidenceSha256 $proof.Sha256 `
      -PrerequisiteGatePhase 'preprompt' -RepositoryRoot $root
  } 'stale prerequisite proof hash'

  $wrongEvidenceHash = New-C34LFixture 'negative-evidence-hash'
  Invoke-C34LFixtureTransition $wrongEvidenceHash 'founder-inputs-validated'
  Invoke-C34LFixtureTransition $wrongEvidenceHash 'build-start'
  $wrongArtifactPath = Join-Path $wrongEvidenceHash.Directory 'fixture.aab'
  $wrongProvenancePath = Join-Path $wrongEvidenceHash.Directory 'provenance.json'
  Write-C34LFixtureText $wrongArtifactPath 'fixture-aab'
  Write-C34LFixtureJson $wrongProvenancePath ([ordered]@{ fixture=$true })
  $wrongArtifact = Get-C34LFixtureFile $wrongArtifactPath
  $wrongProvenance = Get-C34LFixtureFile $wrongProvenancePath
  Invoke-C34LFixtureTransition $wrongEvidenceHash 'build-succeeded' -Additional @{
    ArtifactPath=$wrongArtifact.Relative; ArtifactSha256=$wrongArtifact.Sha256
    ArtifactBytes=$wrongArtifact.Bytes; UploadSignerSha256=('C' * 64)
    ArtifactProvenance=$wrongProvenance.Relative
  }
  $wrongHashBrowser = New-C34LBrowserEvidence $wrongEvidenceHash 'browser.json'
  Invoke-C34LFixtureTransition $wrongEvidenceHash 'upload-authorized' -Additional @{
    BrowserBinding=$wrongHashBrowser.Binding
  }
  $badHashEvidence = (New-C34LFinalEvidenceSet $wrongEvidenceHash play).Play
  Assert-C34LExpectedRejection $wrongEvidenceHash {
    Invoke-C34LFixtureTransition $wrongEvidenceHash 'upload-succeeded' -Additional @{
      EvidencePath=$badHashEvidence.Relative; EvidenceSha256=('D' * 64)
      EvidenceBytes=$badHashEvidence.Bytes
    }
  } 'wrong retained evidence hash'

  $wrongVector = New-C34LDeviceReadyFixture 'negative-evidence-vector'
  $vectorEvidence = (New-C34LFinalEvidenceSet $wrongVector journey).Journey
  $vectorObject = Get-Content -Raw -LiteralPath $vectorEvidence.Path | ConvertFrom-Json
  $vectorObject.actionCounts.otherTrack = 1
  Write-C34LFixtureJson $vectorEvidence.Path $vectorObject
  $vectorEvidence = Get-C34LFixtureFile $vectorEvidence.Path
  Assert-C34LExpectedRejection $wrongVector {
    Invoke-C34LFixtureTransition $wrongVector 'device-accepted' -Additional @{
      EvidencePath=$vectorEvidence.Relative; EvidenceSha256=$vectorEvidence.Sha256
      EvidenceBytes=$vectorEvidence.Bytes
    }
  } 'wrong evidence action vector'

  $missingAttestation = New-C34LUploadAuthorizedFixture `
    'negative-missing-source-attestation'
  $missingAttestationSet = New-C34LFinalEvidenceSet $missingAttestation play
  $missingAttestationOwner = $missingAttestationSet.Source.AttestationFile.Path +
    '.fixture-missing'
  Move-Item -LiteralPath $missingAttestationSet.Source.AttestationFile.Path `
    -Destination $missingAttestationOwner
  Assert-C34LExpectedClassRejection $missingAttestation {
    Invoke-C34LFixtureTransition $missingAttestation 'upload-succeeded' -Additional @{
      EvidencePath=$missingAttestationSet.Play.Relative
      EvidenceSha256=$missingAttestationSet.Play.Sha256
      EvidenceBytes=$missingAttestationSet.Play.Bytes
    }
  } 'missing source attestation' 'source attestation is missing[.]'

  $tamperedAttestation = New-C34LUploadAuthorizedFixture `
    'negative-tampered-source-attestation'
  $tamperedAttestationSet = New-C34LFinalEvidenceSet $tamperedAttestation play
  [IO.File]::AppendAllText(
    $tamperedAttestationSet.Source.AttestationFile.Path,
    [Environment]::NewLine,
    $utf8
  )
  Assert-C34LExpectedClassRejection $tamperedAttestation {
    Invoke-C34LFixtureTransition $tamperedAttestation 'upload-succeeded' -Additional @{
      EvidencePath=$tamperedAttestationSet.Play.Relative
      EvidenceSha256=$tamperedAttestationSet.Play.Sha256
      EvidenceBytes=$tamperedAttestationSet.Play.Bytes
    }
  } 'tampered source attestation' 'source attestation SHA-256 or byte-length binding changed'

  $replayedAttestation = New-C34LUploadAuthorizedFixture `
    'negative-replayed-source-attestation'
  $replayedSet = New-C34LFinalEvidenceSet $replayedAttestation play
  $replayedRaw = Get-Content -Raw `
    -LiteralPath $replayedSet.Source.AttestationFile.Path
  $replayedPattern = '"preStateSha256"\s*:\s*"' +
    [regex]::Escape([string]$replayedSet.Source.StateSha256) + '"'
  $replayedMatches = [regex]::Matches($replayedRaw,$replayedPattern)
  Assert-C34LFixture ($replayedMatches.Count -eq 1) `
    'replay fixture did not contain one exact preStateSha256 wire token.'
  $replayedToken = [string]$replayedMatches[0].Value
  $replayedReplacement = $replayedToken.Replace(
    [string]$replayedSet.Source.StateSha256,
    ('D' * 64)
  )
  Write-C34LFixtureText $replayedSet.Source.AttestationFile.Path `
    ($replayedRaw.Replace($replayedToken,$replayedReplacement))
  $replayedSet.Play = Sync-C34LFixtureEvidenceSource `
    $replayedSet.Source $replayedSet.Play
  Assert-C34LExpectedClassRejection $replayedAttestation {
    Invoke-C34LFixtureTransition $replayedAttestation 'upload-succeeded' -Additional @{
      EvidencePath=$replayedSet.Play.Relative; EvidenceSha256=$replayedSet.Play.Sha256
      EvidenceBytes=$replayedSet.Play.Bytes
    }
  } 'replayed source attestation preimage' 'source-attestation transaction preimage changed'

  $noncanonicalUtc = New-C34LUploadAuthorizedFixture `
    'negative-source-attestation-utc-wire'
  $noncanonicalUtcSet = New-C34LFinalEvidenceSet $noncanonicalUtc play
  $noncanonicalUtcRaw = Get-Content -Raw `
    -LiteralPath $noncanonicalUtcSet.Source.AttestationFile.Path
  $producedUtcMatches = [regex]::Matches(
    $noncanonicalUtcRaw,
    '"producedUtc"\s*:\s*"([^"\r\n]+)"'
  )
  Assert-C34LFixture ($producedUtcMatches.Count -eq 1) `
    'UTC-wire fixture did not contain one producedUtc token.'
  $producedUtcToken = [string]$producedUtcMatches[0].Value
  $noncanonicalUtcToken = $producedUtcToken -replace 'Z"$','0Z"'
  Assert-C34LFixture ($noncanonicalUtcToken -cne $producedUtcToken) `
    'UTC-wire fixture did not produce a noncanonical equivalent token.'
  Write-C34LFixtureText $noncanonicalUtcSet.Source.AttestationFile.Path `
    ($noncanonicalUtcRaw.Replace($producedUtcToken,$noncanonicalUtcToken))
  $noncanonicalUtcSet.Play = Sync-C34LFixtureEvidenceSource `
    $noncanonicalUtcSet.Source $noncanonicalUtcSet.Play
  Assert-C34LExpectedClassRejection $noncanonicalUtc {
    Invoke-C34LFixtureTransition $noncanonicalUtc 'upload-succeeded' -Additional @{
      EvidencePath=$noncanonicalUtcSet.Play.Relative
      EvidenceSha256=$noncanonicalUtcSet.Play.Sha256
      EvidenceBytes=$noncanonicalUtcSet.Play.Bytes
    }
  } 'source attestation noncanonical UTC wire' 'source attestation producedUtc'

  $tamperedCapture = New-C34LUploadAuthorizedFixture `
    'negative-tampered-capture-artifact'
  $tamperedCaptureSet = New-C34LFinalEvidenceSet $tamperedCapture play
  $tamperedCapturePath = Join-Path $root (
    [string]$tamperedCaptureSet.Source.Capture.captureArtifacts[0].path
  ).Replace('/','\')
  [IO.File]::AppendAllText($tamperedCapturePath,[Environment]::NewLine,$utf8)
  Assert-C34LExpectedClassRejection $tamperedCapture {
    Invoke-C34LFixtureTransition $tamperedCapture 'upload-succeeded' -Additional @{
      EvidencePath=$tamperedCaptureSet.Play.Relative
      EvidenceSha256=$tamperedCaptureSet.Play.Sha256
      EvidenceBytes=$tamperedCaptureSet.Play.Bytes
    }
  } 'tampered capture artifact' 'capture artifact .* SHA-256 or byte-length binding changed'

  $rawDeviceCapture = New-C34LUploadAuthorizedFixture `
    'negative-raw-device-capture-extra'
  $rawDeviceSet = New-C34LFinalEvidenceSet $rawDeviceCapture play
  $rawDeviceArtifactBinding = $rawDeviceSet.Source.Capture.captureArtifacts[0]
  $rawDeviceArtifactPath = Join-Path $root `
    ([string]$rawDeviceArtifactBinding.path).Replace('/','\')
  $rawDeviceArtifact = Get-Content -Raw -LiteralPath $rawDeviceArtifactPath |
    ConvertFrom-Json
  $rawDeviceArtifact | Add-Member -NotePropertyName deviceSerial `
    -NotePropertyValue 'fixture-raw-device-value'
  Write-C34LFixtureJson $rawDeviceArtifactPath $rawDeviceArtifact
  $rawDeviceArtifactFile = Get-C34LFixtureFile $rawDeviceArtifactPath
  $rawDeviceCaptureValue = Get-Content -Raw `
    -LiteralPath $rawDeviceSet.Source.CaptureFile.Path | ConvertFrom-Json
  $rawDeviceCaptureValue.captureArtifacts[0].sha256 = $rawDeviceArtifactFile.Sha256
  $rawDeviceCaptureValue.captureArtifacts[0].bytes = $rawDeviceArtifactFile.Bytes
  $rawDeviceCaptureValue.captureDigests.internalTestingRouteDigestSha256 =
    $rawDeviceArtifactFile.Sha256
  $rawDeviceCaptureValue.captureDigests.uploadReceiptDigestSha256 =
    $rawDeviceArtifactFile.Sha256
  Write-C34LFixtureJson $rawDeviceSet.Source.CaptureFile.Path $rawDeviceCaptureValue
  $rawDeviceCaptureFile = Get-C34LFixtureFile $rawDeviceSet.Source.CaptureFile.Path
  $rawDeviceAttestation = Get-Content -Raw `
    -LiteralPath $rawDeviceSet.Source.AttestationFile.Path | ConvertFrom-Json
  $rawDeviceAttestation.captureManifestSha256 = $rawDeviceCaptureFile.Sha256
  $rawDeviceAttestation.captureManifestBytes = $rawDeviceCaptureFile.Bytes
  $rawDeviceAttestation.captureDigests = $rawDeviceCaptureValue.captureDigests
  Write-C34LFixtureJson $rawDeviceSet.Source.AttestationFile.Path $rawDeviceAttestation
  $rawDeviceSet.Play = Sync-C34LFixtureEvidenceSource `
    $rawDeviceSet.Source $rawDeviceSet.Play
  Assert-C34LExpectedClassRejection $rawDeviceCapture {
    Invoke-C34LFixtureTransition $rawDeviceCapture 'upload-succeeded' -Additional @{
      EvidencePath=$rawDeviceSet.Play.Relative; EvidenceSha256=$rawDeviceSet.Play.Sha256
      EvidenceBytes=$rawDeviceSet.Play.Bytes
    }
  } 'raw device capture extra' 'contains forbidden private property .*deviceSerial'

  $misplacedSessionCapture = New-C34LUploadAuthorizedFixture `
    'negative-capture-artifact-session-position'
  $misplacedSessionSet = New-C34LFinalEvidenceSet $misplacedSessionCapture play
  $misplacedSessionBinding = $misplacedSessionSet.Source.Capture.captureArtifacts[0]
  $misplacedSessionArtifactPath = Join-Path $root `
    ([string]$misplacedSessionBinding.path).Replace('/','\')
  $misplacedSessionArtifact = Get-Content -Raw `
    -LiteralPath $misplacedSessionArtifactPath | ConvertFrom-Json
  $misplacedSessionArtifact | Add-Member -NotePropertyName sessionId `
    -NotePropertyValue 'c34l-play-session-00000001'
  Write-C34LFixtureJson $misplacedSessionArtifactPath $misplacedSessionArtifact
  $misplacedSessionArtifactFile = Get-C34LFixtureFile $misplacedSessionArtifactPath
  $misplacedSessionCaptureValue = Get-Content -Raw `
    -LiteralPath $misplacedSessionSet.Source.CaptureFile.Path | ConvertFrom-Json
  $misplacedSessionCaptureValue.captureArtifacts[0].sha256 =
    $misplacedSessionArtifactFile.Sha256
  $misplacedSessionCaptureValue.captureArtifacts[0].bytes =
    $misplacedSessionArtifactFile.Bytes
  $misplacedSessionCaptureValue.captureDigests.internalTestingRouteDigestSha256 =
    $misplacedSessionArtifactFile.Sha256
  $misplacedSessionCaptureValue.captureDigests.uploadReceiptDigestSha256 =
    $misplacedSessionArtifactFile.Sha256
  Write-C34LFixtureJson $misplacedSessionSet.Source.CaptureFile.Path `
    $misplacedSessionCaptureValue
  $misplacedSessionCaptureFile = Get-C34LFixtureFile `
    $misplacedSessionSet.Source.CaptureFile.Path
  $misplacedSessionAttestation = Get-Content -Raw `
    -LiteralPath $misplacedSessionSet.Source.AttestationFile.Path | ConvertFrom-Json
  $misplacedSessionAttestation.captureManifestSha256 =
    $misplacedSessionCaptureFile.Sha256
  $misplacedSessionAttestation.captureManifestBytes =
    $misplacedSessionCaptureFile.Bytes
  $misplacedSessionAttestation.captureDigests =
    $misplacedSessionCaptureValue.captureDigests
  Write-C34LFixtureJson $misplacedSessionSet.Source.AttestationFile.Path `
    $misplacedSessionAttestation
  $misplacedSessionSet.Play = Sync-C34LFixtureEvidenceSource `
    $misplacedSessionSet.Source $misplacedSessionSet.Play
  Assert-C34LExpectedClassRejection $misplacedSessionCapture {
    Invoke-C34LFixtureTransition $misplacedSessionCapture `
      'upload-succeeded' -Additional @{
        EvidencePath=$misplacedSessionSet.Play.Relative
        EvidenceSha256=$misplacedSessionSet.Play.Sha256
        EvidenceBytes=$misplacedSessionSet.Play.Bytes
      }
  } 'capture artifact misplaced sessionId' `
    'sessionId is outside an approved public schema position'

  $wrongDeviceBinding = New-C34LDeviceReadyFixture `
    'negative-wrong-device-binding'
  $wrongDeviceSet = New-C34LFinalEvidenceSet $wrongDeviceBinding journey
  $wrongDeviceValue = Get-Content -Raw -LiteralPath $wrongDeviceSet.Journey.Path |
    ConvertFrom-Json
  $wrongDeviceValue.deviceBindingSha256 = 'D' * 64
  Write-C34LFixtureJson $wrongDeviceSet.Journey.Path $wrongDeviceValue
  $wrongDeviceSet.Journey = Get-C34LFixtureFile $wrongDeviceSet.Journey.Path
  Assert-C34LExpectedClassRejection $wrongDeviceBinding {
    Invoke-C34LFixtureTransition $wrongDeviceBinding 'device-accepted' -Additional @{
      EvidencePath=$wrongDeviceSet.Journey.Relative
      EvidenceSha256=$wrongDeviceSet.Journey.Sha256
      EvidenceBytes=$wrongDeviceSet.Journey.Bytes
    }
  } 'wrong nonraw device binding' 'journey transition evidence success contract changed'

  $proofHistoryMismatch = New-C34LUploadAuthorizedFixture `
    'negative-proof-history-evidence-path'
  $proofMismatchObjects = Read-C34LFixture $proofHistoryMismatch
  $proofMismatchObjects.Aggregate.lifecycleTransactionProofs[-1].evidencePath =
    'tmp/c34l-fixture-mismatched-proof.json'
  Write-C34LFixtureJson $proofHistoryMismatch.AggregatePath `
    $proofMismatchObjects.Aggregate
  Assert-C34LExpectedClassRejection $proofHistoryMismatch {
    Invoke-C34LFixtureTransition $proofHistoryMismatch 'install-authorized'
  } 'committed target proof-history evidence-path tamper' `
    'newest committed transaction does not match current targets'

  $reparseAttestation = New-C34LUploadAuthorizedFixture `
    'negative-attestation-ancestor-reparse'
  $reparseSet = New-C34LFinalEvidenceSet $reparseAttestation play
  $attestationDirectory = Split-Path -Parent $reparseSet.Source.AttestationFile.Path
  $attestationTarget = Join-Path $reparseAttestation.Directory `
    'attestation-owner-target'
  $fixturePrefix = [IO.Path]::GetFullPath($reparseAttestation.Directory).TrimEnd(
    [char[]]@('\','/')
  ) + [IO.Path]::DirectorySeparatorChar
  Assert-C34LFixture (
    [IO.Path]::GetFullPath($attestationDirectory).StartsWith(
      $fixturePrefix,[StringComparison]::OrdinalIgnoreCase
    ) -and [IO.Path]::GetFullPath($attestationTarget).StartsWith(
      $fixturePrefix,[StringComparison]::OrdinalIgnoreCase
    )
  ) 'reparse fixture owners escaped the unique fixture root.'
  Move-Item -LiteralPath $attestationDirectory -Destination $attestationTarget
  [void](New-Item -ItemType Junction -Path $attestationDirectory `
    -Target $attestationTarget)
  [void]$fixtureReparsePoints.Add($attestationDirectory)
  Assert-C34LExpectedClassRejection $reparseAttestation {
    Invoke-C34LFixtureTransition $reparseAttestation 'upload-succeeded' -Additional @{
      EvidencePath=$reparseSet.Play.Relative; EvidenceSha256=$reparseSet.Play.Sha256
      EvidenceBytes=$reparseSet.Play.Bytes
    }
  } 'source attestation ancestor reparse' 'contains a reparse-point ancestor'

  $missingMirror = New-C34LFixture 'negative-missing-authority-mirror'
  $missingObjects = Read-C34LFixture $missingMirror
  $missingObjects.Aggregate.releaseAuthorities.PSObject.Properties.Remove(
    'postinstallAcceptance'
  )
  Write-C34LFixtureJson $missingMirror.AggregatePath $missingObjects.Aggregate
  Assert-C34LExpectedRejection $missingMirror {
    Invoke-C34LFixtureTransition $missingMirror 'founder-inputs-validated'
  } 'missing aggregate authority mirror'

  [void](New-Item -ItemType Directory -Path $escapeRoot)
  $escapeSource = New-C34LFixture 'escape-source'
  $escapeObjects = Read-C34LFixture $escapeSource
  $escapeStatePath = Join-Path $escapeRoot 'state.json'
  $escapeAggregatePath = Join-Path $escapeRoot 'aggregate.json'
  $escapeObjects.State.aggregateStatePath = ConvertTo-C34LFixtureRelative $escapeAggregatePath
  Write-C34LFixtureJson $escapeStatePath $escapeObjects.State
  Write-C34LFixtureJson $escapeAggregatePath $escapeObjects.Aggregate
  $escapePair = [pscustomobject]@{
    StatePath=$escapeStatePath; AggregatePath=$escapeAggregatePath
  }
  Assert-C34LExpectedRejection $escapePair {
    & $transitionPath -Transition 'founder-inputs-validated' `
      -StatePath (ConvertTo-C34LFixtureRelative $escapeStatePath) -FixtureMode `
      -RepositoryRoot $root
  } 'fixture state escape'

  $siblingAggregateSource = New-C34LFixture `
    'negative-sibling-aggregate-source'
  $siblingAggregateTarget = New-C34LFixture `
    'negative-sibling-aggregate-target'
  $siblingAggregateState = Read-C34LFixture $siblingAggregateSource
  $siblingAggregateState.State.aggregateStatePath =
    ConvertTo-C34LFixtureRelative $siblingAggregateTarget.AggregatePath
  Write-C34LFixtureJson `
    $siblingAggregateSource.StatePath $siblingAggregateState.State
  Assert-C34LExpectedRejection $siblingAggregateSource {
    & $transitionPath -Transition 'founder-inputs-validated' `
      -StatePath $siblingAggregateSource.StateRelative -FixtureMode `
      -RepositoryRoot $root
  } 'sibling fixture aggregate target'

  $siblingProofSource = New-C34LFixture 'negative-sibling-proof-source'
  $siblingProofTarget = New-C34LFixture 'negative-sibling-proof-target'
  $siblingProof = New-C34LPrerequisiteProof `
    $siblingProofTarget 'founder-inputs-validated' 'preprompt'
  Assert-C34LExpectedRejection $siblingProofSource {
    & $transitionPath -Transition 'founder-inputs-validated' `
      -StatePath $siblingProofSource.StateRelative -FixtureMode `
      -PrerequisiteGateEvidencePath $siblingProof.Relative `
      -PrerequisiteGateEvidenceSha256 $siblingProof.Sha256 `
      -PrerequisiteGatePhase 'preprompt' -RepositoryRoot $root
  } 'sibling fixture prerequisite proof'

  $siblingBrowserSource = New-C34LBrowserReadyFixture `
    'negative-sibling-browser-source'
  $siblingBrowserTarget = New-C34LBrowserReadyFixture `
    'negative-sibling-browser-target'
  $siblingBrowserBinding = (
    $siblingBrowserSource.Browser.Binding | ConvertTo-Json -Depth 20
  ) | ConvertFrom-Json
  $siblingBrowserBinding.browserEvidencePath =
    [string]$siblingBrowserTarget.Browser.Binding.browserEvidencePath
  $siblingBrowserBinding.browserEvidenceSha256 =
    [string]$siblingBrowserTarget.Browser.Binding.browserEvidenceSha256
  $siblingBrowserBinding.browserEvidenceBytes =
    [long]$siblingBrowserTarget.Browser.Binding.browserEvidenceBytes
  Assert-C34LExpectedRejection $siblingBrowserSource.Fixture {
    Invoke-C34LBrowserBoundFixture `
      -Fixture $siblingBrowserSource.Fixture `
      -ProofBinding $siblingBrowserBinding `
      -InvocationBinding $siblingBrowserBinding
  } 'sibling fixture browser evidence'

  $siblingArtifactSource = New-C34LFixture `
    'negative-sibling-artifact-source'
  Invoke-C34LFixtureTransition $siblingArtifactSource 'founder-inputs-validated'
  Invoke-C34LFixtureTransition $siblingArtifactSource 'build-start'
  $siblingArtifactTarget = New-C34LFixture `
    'negative-sibling-artifact-target'
  $siblingArtifactPath = Join-Path $siblingArtifactTarget.Directory 'fixture.aab'
  $siblingProvenancePath = Join-Path `
    $siblingArtifactTarget.Directory 'provenance.json'
  Write-C34LFixtureText $siblingArtifactPath 'fixture-aab'
  Write-C34LFixtureJson $siblingProvenancePath ([ordered]@{ fixture=$true })
  $siblingArtifact = Get-C34LFixtureFile $siblingArtifactPath
  $siblingProvenance = Get-C34LFixtureFile $siblingProvenancePath
  Assert-C34LExpectedRejection $siblingArtifactSource {
    Invoke-C34LFixtureTransition $siblingArtifactSource 'build-succeeded' -Additional @{
      ArtifactPath=$siblingArtifact.Relative; ArtifactSha256=$siblingArtifact.Sha256
      ArtifactBytes=$siblingArtifact.Bytes; UploadSignerSha256=('F' * 64)
      ArtifactProvenance=$siblingProvenance.Relative
    }
  } 'sibling fixture artifact evidence'

  $siblingEvidenceSource = New-C34LBrowserReadyFixture `
    'negative-sibling-evidence-source'
  Invoke-C34LFixtureTransition `
    $siblingEvidenceSource.Fixture 'upload-authorized' -Additional @{
      BrowserBinding=$siblingEvidenceSource.Browser.Binding
    }
  $siblingEvidenceTarget = New-C34LFixture `
    'negative-sibling-evidence-target'
  $siblingEvidence = (New-C34LFinalEvidenceSet `
    $siblingEvidenceTarget play).Play
  Assert-C34LExpectedRejection $siblingEvidenceSource.Fixture {
    Invoke-C34LFixtureTransition `
      $siblingEvidenceSource.Fixture 'upload-succeeded' -Additional @{
        EvidencePath=$siblingEvidence.Relative
        EvidenceSha256=$siblingEvidence.Sha256
        EvidenceBytes=$siblingEvidence.Bytes
      }
  } 'sibling fixture retained evidence'

  $realStateRelative = 'config/successor-aab-regression-hard-gate-state-c34l.json'
  $realStatePath = Join-Path $root $realStateRelative
  $realAggregatePath = Join-Path $root `
    'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
  Assert-C34LFixture (
    (Test-Path -LiteralPath $realStatePath -PathType Leaf) -and
    (Test-Path -LiteralPath $realAggregatePath -PathType Leaf)
  ) 'real C34L selection state is missing before fixture confinement test.'
  $realPairBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $realStatePath).Hash +
    ':' + (Get-FileHash -Algorithm SHA256 -LiteralPath $realAggregatePath).Hash
  $realRejected = $false
  try {
    & $transitionPath -Transition 'founder-inputs-validated' `
      -StatePath $realStateRelative -FixtureMode -RepositoryRoot $root
  } catch { $realRejected = $true }
  $realPairAfter = (Get-FileHash -Algorithm SHA256 -LiteralPath $realStatePath).Hash +
    ':' + (Get-FileHash -Algorithm SHA256 -LiteralPath $realAggregatePath).Hash
  Assert-C34LFixture (
    $realRejected -and $realPairAfter -ceq $realPairBefore
  ) 'FixtureMode did not fail closed without changing real C34L state.'

  $escapedEvidencePath = Join-Path $escapeRoot 'play.json'
  Write-C34LFixtureText $escapedEvidencePath (
    [IO.File]::ReadAllText($badHashEvidence.Path)
  )
  $escapedEvidence = Get-C34LFixtureFile $escapedEvidencePath
  Assert-C34LExpectedRejection $wrongEvidenceHash {
    Invoke-C34LFixtureTransition $wrongEvidenceHash 'upload-succeeded' -Additional @{
      EvidencePath=$escapedEvidence.Relative; EvidenceSha256=$escapedEvidence.Sha256
      EvidenceBytes=$escapedEvidence.Bytes
    }
  } 'fixture evidence escape'

  Write-Output (
    'C34L lifecycle transition fixture passed: declaredTransitions=11; ' +
    'positiveTransitions=11; negativeFixtures=37; evidenceHashesAndBytes=proved; ' +
    'browserMissingMismatchTamperReplayAndTuple=failClosed; ' +
    'allEightActionCounts=proved; allFourReleaseAuthorities=proved; ' +
    'atomicNewAndExistingWrites=proved; consecutiveJournalChain=proved; ' +
    'exactSiblingRunConfinement=aggregate,proof,browser,artifact,evidence; ' +
    "hostPowerShellMajor=$($PSVersionTable.PSVersion.Major); " +
    'sourceAttestationAndCaptureNegatives=10; realStateWrites=0; externalWrites=0.'
  )
} finally {
  foreach ($reparsePoint in @($fixtureReparsePoints)) {
    if (Test-Path -LiteralPath $reparsePoint) {
      $resolvedReparse = [IO.Path]::GetFullPath($reparsePoint)
      Assert-C34LFixture ($resolvedReparse.StartsWith(
        [IO.Path]::GetFullPath($fixtureRunRoot).TrimEnd([char[]]@('\','/')) +
          [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      )) 'fixture reparse cleanup target escaped its unique run root.'
      Assert-C34LFixture (
        ((Get-Item -LiteralPath $resolvedReparse -Force).Attributes -band
          [IO.FileAttributes]::ReparsePoint) -ne 0
      ) 'fixture reparse cleanup target is not a reparse point.'
      [IO.Directory]::Delete($resolvedReparse,$false)
      Assert-C34LFixture (-not (Test-Path -LiteralPath $resolvedReparse)) `
        'fixture reparse point remained after nonrecursive unlink.'
    }
  }
  foreach ($path in @($fixtureRunRoot, $escapeRoot)) {
    if (Test-Path -LiteralPath $path -PathType Container) {
      $resolved = [IO.Path]::GetFullPath($path)
      $allowed = @(
        [IO.Path]::GetFullPath((Join-Path $root 'tmp/c34l-release-transaction-fixtures/lifecycle-')),
        [IO.Path]::GetFullPath((Join-Path $root 'tmp/c34l-release-transaction-escape-'))
      )
      Assert-C34LFixture (@($allowed | Where-Object {
        $resolved.StartsWith($_, [StringComparison]::OrdinalIgnoreCase)
      }).Count -eq 1) 'fixture cleanup target escaped its unique test prefix.'
      Remove-Item -LiteralPath $resolved -Recurse -Force
      Assert-C34LFixture (-not (Test-Path -LiteralPath $resolved)) `
        'fixture run root remained after verified cleanup.'
    }
  }
}
