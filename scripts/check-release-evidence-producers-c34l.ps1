[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$AuthoritativeReceiptOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$ticketId =
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE'
$versionName = '1.0.0-r60.76'
$versionCode = '2026081376'
$deviceBindingSha256 =
  '97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF'
$captureArtifactContractPath =
  'config/release-evidence-capture-artifact-contract-c34l.json'
$captureArtifactContractSha256 =
  'D7B8DE822D709F25CEB1AEFFFF4093260B3EFB83DCADE1F632309026ECC0B9D2'
$captureArtifactContractId = 'MOOLSOCIAL-C34L-CAPTURE-ARTIFACT-CONTRACT-003'
$utf8 = [Text.UTF8Encoding]::new($false)
$fixtureRoots = [Collections.Generic.List[string]]::new()
$playWriter = Join-Path $root 'scripts/write-release-play-evidence-c34l.ps1'
$oppoWriter = Join-Path $root 'scripts/write-release-oppo-evidence-c34l.ps1'
$journeyWriter = Join-Path $root 'scripts/write-release-journey-evidence-c34l.ps1'
$retainedChecker = Join-Path $root 'scripts/check-release-retained-evidence-c34l.ps1'
$attestationWriter = Join-Path $root 'scripts/write-release-source-attestation-c34l.ps1'
$attestationChecker = Join-Path $root 'scripts/check-release-source-attestation-c34l.ps1'
$oppoTransactionChecker = Join-Path $root `
  'scripts/check-release-oppo-evidence-transaction-c34l.ps1'
$authoritativeProducer = Join-Path $root `
  'scripts/write-release-authoritative-capture-receipt-c34l.ps1'

function Assert-C34LProducerFixture([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34L evidence-producer fixture rejected: $Message"
  }
}
function Write-C34LProducerText([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  [IO.File]::WriteAllText($Path, $Text, $utf8)
}
function Write-C34LProducerJson([string]$Path, $Value) {
  Write-C34LProducerText $Path (($Value | ConvertTo-Json -Depth 60) +
    [Environment]::NewLine)
}
function Get-C34LProducerSha([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}
function New-C34LProducerCounts(
  [int]$Build,
  [int]$Upload,
  [int]$Install,
  [int]$DeviceAcceptance
) {
  return [pscustomobject][ordered]@{
    build = $Build
    upload = $Upload
    install = $Install
    deviceAcceptance = $DeviceAcceptance
    passwordlessEmailSend = 0
    realSmsSend = 0
    otherTrack = 0
    backendHostingProviderOrProductionDeployment = 0
  }
}
function New-C34LProducerAuthorities(
  [string]$Build,
  [string]$Upload,
  [string]$Install,
  [string]$Acceptance
) {
  return [pscustomobject][ordered]@{
    build = $Build
    uploadAndInternalActivation = $Upload
    inPlaceOppoPlayUpdate = $Install
    postinstallAcceptance = $Acceptance
  }
}
function Set-C34LProducerPhase($Fixture, [ValidateSet('play','oppo','journey','final')][string]$Phase) {
  $state = Get-Content -Raw -LiteralPath $Fixture.StatePath | ConvertFrom-Json
  $aggregate = Get-Content -Raw -LiteralPath $Fixture.AggregatePath |
    ConvertFrom-Json
  switch ($Phase) {
    'play' {
      $counts = New-C34LProducerCounts 1 0 0 0
      $authorities = New-C34LProducerAuthorities 'consumed' 'available_once' `
        'held_postupload_qualification' 'held_postinstall_journey_qualification'
      $machine = 'postbuild_qualified_internal_testing_upload_authority_available_once'
    }
    'oppo' {
      $counts = New-C34LProducerCounts 1 1 0 0
      $authorities = New-C34LProducerAuthorities 'consumed' 'consumed' `
        'available_once' 'held_postinstall_journey_qualification'
      $machine =
        'postupload_qualified_in_place_oppo_play_update_authority_available_once'
    }
    'journey' {
      $counts = New-C34LProducerCounts 1 1 1 0
      $authorities = New-C34LProducerAuthorities 'consumed' 'consumed' `
        'consumed' 'held_postinstall_journey_qualification'
      $machine = 'oppo_play_in_place_update_succeeded_postinstall_acceptance_held'
    }
    'final' {
      $counts = New-C34LProducerCounts 1 1 1 1
      $authorities = New-C34LProducerAuthorities 'consumed' 'consumed' `
        'consumed' 'consumed'
      $machine = 'internal_testing_oppo_device_acceptance_succeeded'
    }
  }
  $state.actionCounts = $counts
  $aggregate.actionCounts = $counts
  $state.releaseAuthorities = $authorities
  $aggregate.releaseAuthorities = $authorities
  $state.machineState = $machine
  $aggregate.machineState = $machine
  $aggregate.candidate.buildCount = $counts.build
  $aggregate.candidate.uploadCount = $counts.upload
  $aggregate.candidate.installCount = $counts.install
  $aggregate.candidate.deviceAcceptanceCount = $counts.deviceAcceptance
  Write-C34LProducerJson $Fixture.StatePath $state
  Write-C34LProducerJson $Fixture.AggregatePath $aggregate
}
function New-C34LProducerFixture {
  $fixtureName =
    'c34l-retained-evidence-fixtures-' + [Guid]::NewGuid().ToString('N')
  $fixtureRelative = "tmp/$fixtureName"
  $fixtureRoot = Join-Path $root $fixtureRelative
  $evidenceRelative = "$fixtureRelative/evidence"
  $evidenceRoot = Join-Path $root $evidenceRelative
  [void](New-Item -ItemType Directory -Path $evidenceRoot -Force)
  [void]$fixtureRoots.Add($fixtureRoot)

  $artifactRelative =
    "$evidenceRelative/MoolSocial-$versionName-$versionCode-release.aab"
  $artifactPath = Join-Path $root $artifactRelative
  Write-C34LProducerText $artifactPath 'C34L producer fixture AAB bytes'
  $artifactSha = Get-C34LProducerSha $artifactPath
  $artifactBytes = (Get-Item -LiteralPath $artifactPath).Length
  $sourceOwnerRelative = "$fixtureRelative/source-owner.txt"
  $sourceOwnerPath = Join-Path $root $sourceOwnerRelative
  Write-C34LProducerText $sourceOwnerPath 'C34L producer source owner'
  $sourceManifestRelative = "$fixtureRelative/source-manifest.txt"
  $sourceManifestPath = Join-Path $root $sourceManifestRelative
  Write-C34LProducerText $sourceManifestPath (
    "$(Get-C34LProducerSha $sourceOwnerPath)  $sourceOwnerRelative" +
    [Environment]::NewLine
  )
  $configRelative = "$evidenceRelative/03-release-config-only.log"
  $manifestRelative = "$evidenceRelative/04-release-manifest-preflight.log"
  $mergedRelative = "$evidenceRelative/04a-merged-release-manifest.xml"
  $blameRelative = "$evidenceRelative/04b-release-manifest-merger-blame.txt"
  $buildLogRelative = "$evidenceRelative/05-release-aab-build.log"
  Write-C34LProducerText (Join-Path $root $configRelative) 'config passed'
  Write-C34LProducerText (Join-Path $root $manifestRelative) 'manifest passed'
  Write-C34LProducerText (Join-Path $root $mergedRelative) '<manifest />'
  Write-C34LProducerText (Join-Path $root $blameRelative) 'blame passed'
  Write-C34LProducerText (Join-Path $root $buildLogRelative) `
    'Built build/app/outputs/bundle/release/app-release.aab'
  $provenanceRelative = "$evidenceRelative/06-release-aab-provenance.json"
  $provenancePath = Join-Path $root $provenanceRelative
  $provenance = [pscustomobject][ordered]@{
    schemaVersion = 1; candidateId = $ticketId; preflightAttempt = 1
    versionName = $versionName; versionCode = $versionCode
    packageName = 'com.moolsocial.app'; buildMode = 'release'
    artifactType = 'AAB'; authorizedTrack = 'internal'
    branch = 'remediation/prototype-conformance-2026-07-20'
    head = 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
    powerShellMajor = 7; providerRevisions = [pscustomobject][ordered]@{}
    releaseConfigOnly = $configRelative
    qualifiedRegistrantSnapshot = $configRelative
    qualifiedLocalPropertiesSnapshot = $configRelative
    releaseManifestPreflight = $manifestRelative
    mergedReleaseManifest = $mergedRelative
    releaseManifestMergerBlame = $blameRelative
    releaseConfigOnlyProducedApkOrAab = $false
    releaseRegistrantPluginCount = 10
    googleServicesGradlePlugin = '4.5.0'
    crashlyticsGradlePlugin = '3.0.7'
    crashlyticsMappingUploadEnabled = $false
    sourceManifest = $sourceManifestRelative
    sourceManifestSha256 = Get-C34LProducerSha $sourceManifestPath
    sourceFiles = 1
    artifactPath = $artifactRelative; artifactSha256 = $artifactSha
    artifactBytes = $artifactBytes; uploadSignerSha256 = ('A' * 64)
    packageVersionManifestProved = $true; googleAppIdResourceProved = $true
    crashlyticsBuildIdResourceProved = $true; splitAndArm64PayloadProved = $true
    bundletoolPath = 'tmp/bundletool-all-1.18.3.jar'
    bundletoolSha256 = ('B' * 64); bundletoolVersion = '1.18.3'
    buildLog = $buildLogRelative; secretDefineFileReadByAgent = $false
    googleServicesFileReadByAgent = $false; secretValuesRecorded = $false
    builtAt = '2026-08-17T00:00:00.0000000+00:00'
  }
  Write-C34LProducerJson $provenancePath $provenance

  $aggregateRelative = "$fixtureRelative/aggregate.json"
  $aggregatePath = Join-Path $root $aggregateRelative
  $candidate = [pscustomobject][ordered]@{
    id = $ticketId; packageName = 'com.moolsocial.app'
    versionName = $versionName; versionCode = $versionCode
    playTrack = 'internal'; deviceBindingSha256 = $deviceBindingSha256
    deviceModel = 'CPH2375'
    disposition = 'fixture'; artifactReusable = $true
    buildCount = 1; uploadCount = 0; installCount = 0; deviceAcceptanceCount = 0
  }
  $counts = New-C34LProducerCounts 1 0 0 0
  $authorities = New-C34LProducerAuthorities 'consumed' 'available_once' `
    'held_postupload_qualification' 'held_postinstall_journey_qualification'
  $aggregate = [pscustomobject][ordered]@{
    ticketId = $ticketId; candidate = $candidate
    machineState = 'postbuild_qualified_internal_testing_upload_authority_available_once'
    actionCounts = $counts; releaseAuthorities = $authorities
    lifecycleTransactionProofs = @()
  }
  Write-C34LProducerJson $aggregatePath $aggregate
  $stateRelative = "$fixtureRelative/state.json"
  $statePath = Join-Path $root $stateRelative
  $state = [pscustomobject][ordered]@{
    ticketId = $ticketId; candidate = $candidate
    aggregateStatePath = $aggregateRelative
    machineState = 'postbuild_qualified_internal_testing_upload_authority_available_once'
    evidenceRoot = $evidenceRelative
    sourceQualification = [pscustomobject][ordered]@{
      manifestPath = $sourceManifestRelative
      manifestSha256 = Get-C34LProducerSha $sourceManifestPath
    }
    buildResult = [pscustomobject][ordered]@{
      artifactPath = $artifactRelative; artifactSha256 = $artifactSha
      artifactBytes = $artifactBytes; uploadSignerSha256 = ('A' * 64)
      provenance = $provenanceRelative
    }
    playResult = [pscustomobject][ordered]@{}
    installResult = [pscustomobject][ordered]@{}
    actionCounts = $counts; releaseAuthorities = $authorities
    lifecycleTransactionProofs = @()
  }
  Write-C34LProducerJson $statePath $state
  return [pscustomobject]@{
    Root = $fixtureRoot; Relative = $fixtureRelative
    EvidenceRoot = $evidenceRoot; EvidenceRelative = $evidenceRelative
    StatePath = $statePath; StateRelative = $stateRelative
    AggregatePath = $aggregatePath; AggregateRelative = $aggregateRelative
    ArtifactPath = $artifactPath
  }
}
function New-C34LAuthoritativeFixture(
  [ValidateSet(
    'play_internal_testing_activation','oppo_play_in_place_update_pair',
    'mandatory_whole_app_journey_acceptance'
  )][string]$EvidenceType='play_internal_testing_activation'
) {
  $fixtureRelative = 'tmp/c34l-authoritative-capture-fixtures-' +
    [Guid]::NewGuid().ToString('N').ToLowerInvariant()
  $fixtureRoot = Join-Path $root $fixtureRelative
  $evidenceRelative = "$fixtureRelative/evidence"
  $evidenceRoot = Join-Path $root $evidenceRelative
  [void](New-Item -ItemType Directory -Path `
    (Join-Path $evidenceRoot 'captures') -Force)
  [void](New-Item -ItemType Directory -Path `
    (Join-Path $evidenceRoot 'attestations') -Force)
  [void](New-Item -ItemType Directory -Path `
    (Join-Path $fixtureRoot 'adapters') -Force)
  [void](New-Item -ItemType Directory -Path `
    (Join-Path $fixtureRoot 'journals') -Force)
  [void]$fixtureRoots.Add($fixtureRoot)
  $artifactRelative =
    "$evidenceRelative/MoolSocial-$versionName-$versionCode-release.aab"
  $artifactPath = Join-Path $root $artifactRelative
  Write-C34LProducerText $artifactPath 'authoritative producer fixture AAB'
  $manifestRelative = "$fixtureRelative/source-manifest.txt"
  $manifestPath = Join-Path $root $manifestRelative
  Write-C34LProducerText $manifestPath `
    "C34L authoritative fixture sealed source manifest`r`n"
  $aggregateRelative = "$fixtureRelative/aggregate.json"
  $aggregatePath = Join-Path $root $aggregateRelative
  $stateRelative = "$fixtureRelative/state.json"
  $statePath = Join-Path $root $stateRelative
  $candidate = [pscustomobject][ordered]@{
    id=$ticketId;packageName='com.moolsocial.app';versionName=$versionName
    versionCode=$versionCode;playTrack='internal'
    deviceBindingSha256=$deviceBindingSha256;deviceModel='CPH2375'
    buildCount=1;uploadCount=0;installCount=0;deviceAcceptanceCount=0
  }
  if ($EvidenceType -ceq 'play_internal_testing_activation') {
    $counts = New-C34LProducerCounts 1 0 0 0
    $authorities = New-C34LProducerAuthorities 'consumed' 'available_once' `
      'held_postupload_qualification' 'held_postinstall_journey_qualification'
    $machineState=
      'postbuild_qualified_internal_testing_upload_authority_available_once'
  } elseif ($EvidenceType -ceq 'oppo_play_in_place_update_pair') {
    $counts = New-C34LProducerCounts 1 1 0 0
    $authorities = New-C34LProducerAuthorities 'consumed' 'consumed' `
      'available_once' 'held_postinstall_journey_qualification'
    $candidate.uploadCount=1
    $machineState=
      'postupload_qualified_in_place_oppo_play_update_authority_available_once'
  } else {
    $counts = New-C34LProducerCounts 1 1 1 0
    $authorities = New-C34LProducerAuthorities 'consumed' 'consumed' `
      'consumed' 'held_postinstall_journey_qualification'
    $candidate.uploadCount=1;$candidate.installCount=1
    $machineState='oppo_play_in_place_update_succeeded_postinstall_acceptance_held'
  }
  $proof = [pscustomobject][ordered]@{ sequence=1;attempt=1 }
  $aggregate = [pscustomobject][ordered]@{
    ticketId=$ticketId;candidate=$candidate;machineState=$machineState
    actionCounts=$counts
    releaseAuthorities=$authorities;lifecycleTransactionProofs=@($proof)
  }
  $artifactSha = Get-C34LProducerSha $artifactPath
  $artifactBytes = [int64](Get-Item -LiteralPath $artifactPath).Length
  $manifestSha = Get-C34LProducerSha $manifestPath
  $manifestBytes = [int64](Get-Item -LiteralPath $manifestPath).Length
  $state = [pscustomobject][ordered]@{
    ticketId=$ticketId;candidate=$candidate;aggregateStatePath=$aggregateRelative
    machineState=$machineState;evidenceRoot=$evidenceRelative;actionCounts=$counts
    releaseAuthorities=$authorities
    sourceQualification=[pscustomobject][ordered]@{
      manifestPath=$manifestRelative;manifestSha256=$manifestSha
      manifestBytes=$manifestBytes
    }
    buildResult=[pscustomobject][ordered]@{
      artifactPath=$artifactRelative;artifactSha256=$artifactSha
      artifactBytes=$artifactBytes
    }
    lifecycleTransactionProofs=@($proof)
    presealUploadWorkflow=[pscustomobject][ordered]@{}
  }
  Write-C34LProducerJson $aggregatePath $aggregate
  Write-C34LProducerJson $statePath $state
  $journal = [pscustomobject][ordered]@{
    schemaVersion=1;ticketId=$ticketId;attempt=1;transactionId='fixture0001'
    sequence=1;status='committed';statePath=$stateRelative
    aggregateStatePath=$aggregateRelative
    stateAfterSha256=Get-C34LProducerSha $statePath
    aggregateAfterSha256=Get-C34LProducerSha $aggregatePath
  }
  Write-C34LProducerJson `
    (Join-Path $fixtureRoot 'journals/transaction-fixture0001.json') $journal
  return [pscustomobject]@{
    Root=$fixtureRoot;Relative=$fixtureRelative;EvidenceRoot=$evidenceRoot
    EvidenceRelative=$evidenceRelative;StatePath=$statePath
    StateRelative=$stateRelative;AggregatePath=$aggregatePath
    AggregateRelative=$aggregateRelative;ArtifactPath=$artifactPath
  }
}
function Write-C34LAuthoritativeAdapter(
  $Fixture,
  [ValidateSet(
    'play_internal_testing_activation','oppo_play_in_place_update_pair',
    'mandatory_whole_app_journey_acceptance'
  )][string]$EvidenceType,
  [ValidateSet('valid','wrong-challenge','wrong-adapter','wrong-seal','wrong-owner')]
  [string]$Mode='valid'
) {
  $adapterRelative = "$($Fixture.Relative)/adapters/$EvidenceType.ps1"
  $adapterPath = Join-Path $root $adapterRelative
  $source = @'
[CmdletBinding()]
param(
  [string]$EvidenceType,[int]$Attempt,[string]$StatePath,
  [string]$ChallengeSha256,[string]$OutputPath,[switch]$FixtureMode,
  [string]$FixtureRunRoot,[string]$RepositoryRoot
)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\','/'))
$prefix=$root+[IO.Path]::DirectorySeparatorChar
$utf8=[Text.UTF8Encoding]::new($false)
function Sha([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()}
function Binding([string]$Path){[pscustomobject][ordered]@{path=([IO.Path]::GetFullPath($Path)).Substring($prefix.Length).Replace('\','/');sha256=Sha $Path;bytes=[int64](Get-Item -LiteralPath $Path).Length}}
function WriteJson([string]$Path,$Value){$parent=Split-Path -Parent $Path;if(-not(Test-Path -LiteralPath $parent)){[void](New-Item -ItemType Directory -Path $parent -Force)};[IO.File]::WriteAllText($Path,(($Value|ConvertTo-Json -Depth 40)+[Environment]::NewLine),$utf8)}
$stateFile=Join-Path $root $StatePath
$state=Get-Content -Raw -LiteralPath $stateFile|ConvertFrom-Json
$aggregateFile=Join-Path $root ([string]$state.aggregateStatePath)
$artifactFile=Join-Path $root ([string]$state.buildResult.artifactPath)
$sealFile=Join-Path $root ([string]$state.sourceQualification.manifestPath)
$self=Binding $MyInvocation.MyCommand.Path
$seal=Binding $sealFile
$mode='__MODE__'
$challenge=if($mode -ceq 'wrong-challenge'){'E'*64}else{$ChallengeSha256}
if($mode -ceq 'wrong-owner'){$self.sha256='D'*64}
if($mode -ceq 'wrong-seal'){$seal.sha256='C'*64}
$ids=@{
  play_internal_testing_activation='MOOLSOCIAL-C34L-PLAY-BROWSER-TRANSACTION-ADAPTER-001'
  oppo_play_in_place_update_pair='MOOLSOCIAL-C34L-OPPO-READONLY-PACKAGE-INSTALLER-TIME-LOG-ADAPTER-001'
  mandatory_whole_app_journey_acceptance='MOOLSOCIAL-C34L-JOURNEY-GATE-OUTPUT-ADAPTER-001'
}
$adapterId=if($mode -ceq 'wrong-adapter'){'WRONG-ADAPTER'}else{$ids[$EvidenceType]}
$produced=[DateTime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'",[Globalization.CultureInfo]::InvariantCulture)
if($EvidenceType -ceq 'mandatory_whole_app_journey_acceptance'){
  $gates=@()
  foreach($id in @('publicGuest','protectedGateway','supportedAuthentication','social','wholeApp','c33gBlocker')){
    $receiptPath=Join-Path $root "$FixtureRunRoot/sources/$id.json"
    WriteJson $receiptPath ([pscustomobject][ordered]@{schemaVersion=1;journeyId=$id;passed=$true;producedUtc=$produced})
    $gates += [pscustomobject][ordered]@{journeyId=$id;owner=$self;receipt=(Binding $receiptPath);passed=$true}
  }
  $value=[pscustomobject][ordered]@{
    schemaVersion=1;adapterContractId=$ids[$EvidenceType];adapterId=$adapterId
    evidenceType=$EvidenceType;ticketId=[string]$state.ticketId;attempt=$Attempt
    packageName='com.moolsocial.app';versionName='1.0.0-r60.76'
    versionCode='2026081376';challengeSha256=$challenge
    preStateSha256=Sha $stateFile;preAggregateSha256=Sha $aggregateFile
    artifactSha256=Sha $artifactFile;artifactBytes=[int64](Get-Item -LiteralPath $artifactFile).Length
    sourceOwner=$self;sourceSealManifest=$seal;gates=$gates;producedUtc=$produced
  }
} else {
  $artifacts=if($EvidenceType -ceq 'play_internal_testing_activation'){@(
    [pscustomobject][ordered]@{role='internal_testing_release_receipt';mediaType='application/json';payload=[pscustomobject][ordered]@{track='internal';uploadCount=1;otherTrackChanged=$false}},
    [pscustomobject][ordered]@{role='internal_testing_status_observation';mediaType='application/json';payload=[pscustomobject][ordered]@{track='internal';internalReleaseActive=$true;internalActivationCount=1}}
  )}else{@(
    [pscustomobject][ordered]@{role='cold_start_observation';mediaType='application/json';payload=[pscustomobject][ordered]@{coldStartInteractive=$true;blankHierarchy=$false;timeout=$false;flutterFatalErrorCount=0;androidRuntimeFatalCount=0;anrCount=0;appProcessErrorScanPassed=$true;artifactRelationshipProved=$true;inPlaceUpdateProved=$true}},
    [pscustomobject][ordered]@{role='retained_state_observation';mediaType='application/json';payload=[pscustomobject][ordered]@{firstInstallTimeMillis=1000;lastUpdateTimeMillis=2000;firstInstallTimePreserved=$true;retainedDataContinuityProved=$true;inPlacePlayUpdateProved=$true;uninstallPerformed=$false;dataClearPerformed=$false;downgradePerformed=$false;adbInstallPerformed=$false}}
  )}
  $value=[pscustomobject][ordered]@{schemaVersion=1;adapterId=$adapterId;evidenceType=$EvidenceType;ticketId=[string]$state.ticketId;attempt=$Attempt;challengeSha256=$challenge;sourceOwner=$self;sealedSourceManifest=$seal;artifacts=$artifacts;producedUtc=$produced}
}
$output=Join-Path $root $OutputPath
WriteJson $output $value
'@.Replace('__MODE__',$Mode)
  Write-C34LProducerText $adapterPath $source
  return [pscustomobject]@{ Path=$adapterPath;Relative=$adapterRelative }
}
function Invoke-C34LAuthoritativeFixture(
  $Fixture,
  [string]$EvidenceType,
  [string]$Mode='valid'
) {
  $adapter = Write-C34LAuthoritativeAdapter $Fixture $EvidenceType $Mode
  $output = @(& $authoritativeProducer -EvidenceType $EvidenceType -Attempt 1 `
    -StatePath $Fixture.StateRelative -FixtureMode `
    -FixtureRunRoot $Fixture.Relative -FixtureAdapterPath $adapter.Relative `
    -RepositoryRoot $root)
  Assert-C34LProducerFixture ($output.Count -eq 1) `
    'authoritative producer did not emit one receipt binding.'
  return $output[0]
}
function Assert-C34LAuthoritativeExpectedRejection(
  [scriptblock]$Action,
  [string]$Expected,
  [string]$Label,
  [Collections.Generic.List[string]]$Labels
) {
  $rejected=$false;$observed=''
  try { & $Action | Out-Null } catch {
    $rejected=$true;$observed=$_.Exception.Message
  }
  Assert-C34LProducerFixture (
    $rejected -and $observed.Contains($Expected)
  ) "$Label did not produce the expected authoritative fail-closed rejection."
  [void]$Labels.Add($Label)
}
function Invoke-C34LAuthoritativeAttestation($Fixture,$ProducerResult,[string]$Type) {
  $output = @(& $attestationWriter -EvidenceType $Type -Attempt 1 `
    -StatePath $Fixture.StateRelative `
    -AuthoritativeReceiptPath ([string]$ProducerResult.receiptPath) `
    -AuthoritativeReceiptSha256 ([string]$ProducerResult.receiptSha256) `
    -AuthoritativeReceiptBytes ([int64]$ProducerResult.receiptBytes) `
    -FixtureMode -RepositoryRoot $root)
  Assert-C34LProducerFixture ($output.Count -eq 1) `
    'authoritative source attestation did not emit one result.'
  try { return ([string]$output[0] | ConvertFrom-Json) } catch {
    throw 'C34L evidence-producer fixture rejected: authoritative attestation result is not JSON.'
  }
}
function New-C34LProducerAttestation(
  $Fixture,
  [ValidateSet('play','oppo','journey')][string]$Kind
) {
  $state = Get-Content -Raw -LiteralPath $Fixture.StatePath | ConvertFrom-Json
  $aggregate = Get-Content -Raw -LiteralPath $Fixture.AggregatePath |
    ConvertFrom-Json
  $attestationDirectory = Join-Path $Fixture.EvidenceRoot 'attestations'
  if (-not (Test-Path -LiteralPath $attestationDirectory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $attestationDirectory)
  }
  $captureRootRelative =
    "$($Fixture.EvidenceRelative)/captures/attempt-1/$Kind"
  $captureRoot = Join-Path $root $captureRootRelative
  [void](New-Item -ItemType Directory -Path $captureRoot -Force)
  $session = "fixture-$Kind-session-" + [Guid]::NewGuid().ToString('N')
  $nonce = 'D' * 64
  $artifactSha = [string]$state.buildResult.artifactSha256
  $artifactBytes = [int64]$state.buildResult.artifactBytes
  $captureArtifacts = @()
  switch ($Kind) {
    'play' {
      $type='play_internal_testing_activation'
      $producer='MOOLSOCIAL-C34L-PLAY-CAPTURE-PRODUCER-001'
      $receiptRelative="$captureRootRelative/internal-testing-release-receipt.json"
      $receiptPath=Join-Path $root $receiptRelative
      Write-C34LProducerJson $receiptPath ([pscustomobject][ordered]@{
        schemaVersion=1;captureRole='internal_testing_release_receipt'
        ticketId=$ticketId;attempt=1;packageName='com.moolsocial.app'
        versionName=$versionName;versionCode=$versionCode
        artifactSha256=$artifactSha;artifactBytes=$artifactBytes
        track='internal';uploadCount=1;otherTrackChanged=$false
        sourceProducerId=$producer;sessionId=$session;nonceSha256=$nonce
      })
      $statusRelative="$captureRootRelative/internal-testing-status-observation.json"
      $statusPath=Join-Path $root $statusRelative
      Write-C34LProducerJson $statusPath ([pscustomobject][ordered]@{
        schemaVersion=1;captureRole='internal_testing_status_observation'
        ticketId=$ticketId;attempt=1;packageName='com.moolsocial.app'
        versionName=$versionName;versionCode=$versionCode
        artifactSha256=$artifactSha;artifactBytes=$artifactBytes
        track='internal';internalReleaseActive=$true;internalActivationCount=1
        sourceProducerId=$producer;sessionId=$session;nonceSha256=$nonce
      })
      $receiptSha=Get-C34LProducerSha $receiptPath
      $statusSha=Get-C34LProducerSha $statusPath
      $captureArtifacts=@(
        [pscustomobject][ordered]@{role='internal_testing_release_receipt';path=$receiptRelative;sha256=$receiptSha;bytes=(Get-Item -LiteralPath $receiptPath).Length;mediaType='application/json'},
        [pscustomobject][ordered]@{role='internal_testing_status_observation';path=$statusRelative;sha256=$statusSha;bytes=(Get-Item -LiteralPath $statusPath).Length;mediaType='application/json'}
      )
      $digests=[pscustomobject][ordered]@{
        internalTestingRouteDigestSha256=$receiptSha
        uploadReceiptDigestSha256=$receiptSha
        activationStateDigestSha256=$statusSha
      }
    }
    'oppo' {
      $type='oppo_play_in_place_update_pair'
      $producer='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
      $coldRelative="$captureRootRelative/cold-start-observation.json"
      $coldPath=Join-Path $root $coldRelative
      Write-C34LProducerJson $coldPath ([pscustomobject][ordered]@{
        schemaVersion=1;captureArtifactContractId=$captureArtifactContractId
        evidenceType=$type;role='cold_start_observation';ticketId=$ticketId
        attempt=1;packageName='com.moolsocial.app';versionName=$versionName
        versionCode=$versionCode;artifactSha256=$artifactSha
        artifactBytes=$artifactBytes;deviceBindingSha256=$deviceBindingSha256
        deviceModel='CPH2375';installerPackage='com.android.vending'
        sourceProducerId=$producer;sessionId=$session;nonceSha256=$nonce
        coldStartInteractive=$true;blankHierarchy=$false;timeout=$false
        flutterFatalErrorCount=0;androidRuntimeFatalCount=0;anrCount=0
        appProcessErrorScanPassed=$true;artifactRelationshipProved=$true
        inPlaceUpdateProved=$true
      })
      $retainedRelative="$captureRootRelative/retained-state-observation.json"
      $retainedPath=Join-Path $root $retainedRelative
      Write-C34LProducerJson $retainedPath ([pscustomobject][ordered]@{
        schemaVersion=1;captureArtifactContractId=$captureArtifactContractId
        evidenceType=$type;role='retained_state_observation';ticketId=$ticketId
        attempt=1;packageName='com.moolsocial.app';versionName=$versionName
        versionCode=$versionCode;artifactSha256=$artifactSha
        artifactBytes=$artifactBytes;deviceBindingSha256=$deviceBindingSha256
        deviceModel='CPH2375';installerPackage='com.android.vending'
        sourceProducerId=$producer;sessionId=$session;nonceSha256=$nonce
        firstInstallTimeMillis=1000;lastUpdateTimeMillis=2000
        firstInstallTimePreserved=$true;retainedDataContinuityProved=$true
        inPlacePlayUpdateProved=$true;uninstallPerformed=$false
        dataClearPerformed=$false;downgradePerformed=$false
        adbInstallPerformed=$false
      })
      $coldSha=Get-C34LProducerSha $coldPath
      $retainedSha=Get-C34LProducerSha $retainedPath
      $captureArtifacts=@(
        [pscustomobject][ordered]@{role='cold_start_observation';path=$coldRelative;sha256=$coldSha;bytes=(Get-Item -LiteralPath $coldPath).Length;mediaType='application/json'},
        [pscustomobject][ordered]@{role='retained_state_observation';path=$retainedRelative;sha256=$retainedSha;bytes=(Get-Item -LiteralPath $retainedPath).Length;mediaType='application/json'}
      )
      $digests=[pscustomobject][ordered]@{
        packageStateDigestSha256=$coldSha
        coldStartDigestSha256=$coldSha
        retainedDataDigestSha256=$retainedSha
      }
    }
    'journey' {
      $type='mandatory_whole_app_journey_acceptance'
      $producer='MOOLSOCIAL-C34L-JOURNEY-CAPTURE-PRODUCER-001'
      $rows=@()
      $digests=[pscustomobject][ordered]@{}
      foreach($journeyId in @(
        'publicGuest','protectedGateway','supportedAuthentication','social',
        'wholeApp','c33gBlocker'
      )){
        $rowRelative="$captureRootRelative/journeys/$journeyId.json"
        $rowPath=Join-Path $root $rowRelative
        Write-C34LProducerJson $rowPath ([pscustomobject][ordered]@{
          schemaVersion=1;journeyId=$journeyId;ticketId=$ticketId;attempt=1
          packageName='com.moolsocial.app';versionName=$versionName
          versionCode=$versionCode;artifactSha256=$artifactSha
          artifactBytes=$artifactBytes;deviceBindingSha256=$deviceBindingSha256
          passed=$true;newIssueCount=0;newDefectCount=0;blankScreenCount=0
          flutterFatalErrorCount=0;androidRuntimeFatalCount=0;anrCount=0
          sourceProducerId=$producer;sessionId=$session;nonceSha256=$nonce
        })
        $rowSha=Get-C34LProducerSha $rowPath
        $rows += [pscustomobject][ordered]@{
          journeyId=$journeyId;path=$rowRelative;sha256=$rowSha
          bytes=(Get-Item -LiteralPath $rowPath).Length;passed=$true
        }
        $digests | Add-Member -NotePropertyName ($journeyId+'DigestSha256') `
          -NotePropertyValue $rowSha
      }
      $journeyManifestRelative="$captureRootRelative/journey-acceptance-manifest.json"
      $journeyManifestPath=Join-Path $root $journeyManifestRelative
      Write-C34LProducerJson $journeyManifestPath $rows
      $journeyManifestSha=Get-C34LProducerSha $journeyManifestPath
      $captureArtifacts=@([pscustomobject][ordered]@{
        role='journey_acceptance_manifest';path=$journeyManifestRelative
        sha256=$journeyManifestSha
        bytes=(Get-Item -LiteralPath $journeyManifestPath).Length
        mediaType='application/json'
      })
    }
  }
  $format = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
  $now = [DateTimeOffset]::UtcNow
  $captureRelative = "$captureRootRelative/capture-manifest.json"
  $capturePath = Join-Path $root $captureRelative
  $capture = [pscustomobject][ordered]@{
    schemaVersion=1
    captureContractId='MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001'
    evidenceType=$type; ticketId=$ticketId; attempt=1
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; preStateSha256=(Get-C34LProducerSha $Fixture.StatePath)
    preAggregateSha256=(Get-C34LProducerSha $Fixture.AggregatePath)
    actionCounts=$state.actionCounts; releaseAuthorities=$state.releaseAuthorities
    artifactSha256=$artifactSha; artifactBytes=$artifactBytes
    sourceProducerId=$producer; sessionId=$session; nonceSha256=$nonce
    producedUtc=$now.AddSeconds(-1).ToString(
      $format,[Globalization.CultureInfo]::InvariantCulture)
    expiresUtc=$now.AddMinutes(10).ToString(
      $format,[Globalization.CultureInfo]::InvariantCulture)
    captureDigests=$digests
    captureArtifactContractPath=$captureArtifactContractPath
    captureArtifactContractSha256=$captureArtifactContractSha256
    captureArtifactContractId=$captureArtifactContractId
    captureArtifacts=$captureArtifacts
  }
  Write-C34LProducerJson $capturePath $capture
  $arguments = @{
    EvidenceType=$type; Attempt=1; StatePath=$Fixture.StateRelative
    CaptureManifestPath=$captureRelative
    CaptureManifestSha256=(Get-C34LProducerSha $capturePath)
    CaptureManifestBytes=(Get-Item -LiteralPath $capturePath).Length
    FixtureMode=$true; RepositoryRoot=$root
  }
  $output = @(& $attestationWriter @arguments)
  Assert-C34LProducerFixture ($output.Count -eq 1) `
    "$Kind source-attestation writer did not emit one sanitized result."
  try { return ([string]$output[0] | ConvertFrom-Json) } catch {
    throw "C34L evidence-producer fixture rejected: $Kind source-attestation result is not JSON."
  }
}

function Invoke-C34LProducerWriter(
  [string]$Writer,
  [hashtable]$Arguments,
  [string]$Label
) {
  $output = @(& $Writer @Arguments)
  Assert-C34LProducerFixture ($output.Count -eq 1) `
    "$Label did not emit one sanitized result."
  try { $result = [string]$output[0] | ConvertFrom-Json } catch {
    throw "C34L evidence-producer fixture rejected: $Label result is not JSON."
  }
  return $result
}
function Assert-C34LProducerResult($Fixture, $Result, [string]$Path, [string]$Label) {
  Assert-C34LProducerFixture (
    [string]$Result.ticketId -ceq $ticketId -and
    [int]$Result.attempt -eq 1 -and
    [string]$Result.path -ceq $Path -and
    [string]$Result.sha256 -cmatch '^[0-9A-F]{64}$' -and
    [int64]$Result.bytes -gt 0 -and
    [int]$Result.externalActionsPerformed -eq 0 -and
    -not [bool]$Result.secretOrPrivateValuesRecorded
  ) "$Label result identity, action or privacy fields changed."
  $file = Join-Path $root $Path
  Assert-C34LProducerFixture (
    (Test-Path -LiteralPath $file -PathType Leaf) -and
    (Get-C34LProducerSha $file) -ceq [string]$Result.sha256 -and
    (Get-Item -LiteralPath $file).Length -eq [int64]$Result.bytes
  ) "$Label result SHA-256 or byte binding changed."
  $evidence = Get-Content -Raw -LiteralPath $file | ConvertFrom-Json
  Assert-C34LProducerFixture (
    [string]$evidence.preStateSha256 -ceq [string]$Result.preStateSha256 -and
    [string]$evidence.preAggregateSha256 -ceq
      [string]$Result.preAggregateSha256
  ) "$Label result preimage binding changed."
  return $evidence
}
function New-C34LProducerProof(
  $Evidence,
  [string]$EvidencePath,
  [string]$EvidenceSha256
) {
  switch ([string]$Evidence.evidenceType) {
    'play_internal_testing_activation' {
      $transition='upload-succeeded'; $phase='preupload'
    }
    'oppo_play_in_place_update_cold_start' {
      $transition='install-succeeded'; $phase='preinstall'
    }
    'mandatory_whole_app_journey_acceptance' {
      $transition='device-accepted'; $phase='journey'
    }
    default { throw 'C34L evidence-producer fixture rejected: unknown proof evidence type.' }
  }
  return [pscustomobject][ordered]@{
    ticketId = $ticketId
    attempt = 1
    transition = $transition
    phase = $phase
    evidencePath = $EvidencePath
    sha256 = $EvidenceSha256
    preStateSha256 = [string]$Evidence.preStateSha256
    preAggregateSha256 = [string]$Evidence.preAggregateSha256
    actionCounts = $Evidence.actionCounts
    releaseAuthorities = $Evidence.releaseAuthorities
    browserEvidence = $null
  }
}
function Complete-C34LProducerFixture(
  $Fixture,
  $PlayResult,
  $PlayEvidence,
  $OppoResult,
  $OppoEvidence,
  $JourneyResult,
  $JourneyEvidence
) {
  Set-C34LProducerPhase $Fixture final
  $state = Get-Content -Raw -LiteralPath $Fixture.StatePath | ConvertFrom-Json
  $aggregate = Get-Content -Raw -LiteralPath $Fixture.AggregatePath |
    ConvertFrom-Json
  $proofs = @(
    (New-C34LProducerProof $PlayEvidence `
      ([string]$PlayResult.path) ([string]$PlayResult.sha256)),
    (New-C34LProducerProof $OppoEvidence `
      ([string]$OppoResult.coldStart.path) `
      ([string]$OppoResult.coldStart.sha256)),
    (New-C34LProducerProof $JourneyEvidence `
      ([string]$JourneyResult.path) ([string]$JourneyResult.sha256))
  )
  $state.playResult = [pscustomobject][ordered]@{
    evidencePath = [string]$PlayResult.path
    evidenceSha256 = [string]$PlayResult.sha256
    evidenceBytes = [int64]$PlayResult.bytes
  }
  $state.installResult = [pscustomobject][ordered]@{
    coldStartEvidencePath = [string]$OppoResult.coldStart.path
    coldStartEvidenceSha256 = [string]$OppoResult.coldStart.sha256
    coldStartEvidenceBytes = [int64]$OppoResult.coldStart.bytes
    retainedDataEvidencePath = [string]$OppoResult.retainedData.path
    retainedDataEvidenceSha256 = [string]$OppoResult.retainedData.sha256
    retainedDataEvidenceBytes = [int64]$OppoResult.retainedData.bytes
    journeyEvidencePath = [string]$JourneyResult.path
    journeyEvidenceSha256 = [string]$JourneyResult.sha256
    journeyEvidenceBytes = [int64]$JourneyResult.bytes
  }
  $state.lifecycleTransactionProofs = $proofs
  $aggregate.lifecycleTransactionProofs = $proofs
  Write-C34LProducerJson $Fixture.StatePath $state
  Write-C34LProducerJson $Fixture.AggregatePath $aggregate
}

try {
$authoritativeLabels = [Collections.Generic.List[string]]::new()
$authoritativeTypes = @(
  'play_internal_testing_activation','oppo_play_in_place_update_pair',
  'mandatory_whole_app_journey_acceptance'
)
$authoritativePositive = @{}
foreach ($type in $authoritativeTypes) {
  $fixture = New-C34LAuthoritativeFixture $type
  $result = Invoke-C34LAuthoritativeFixture $fixture $type
  $receiptFile = Join-Path $root ([string]$result.receiptPath)
  Assert-C34LProducerFixture (
    (Test-Path -LiteralPath $receiptFile -PathType Leaf) -and
    (Get-C34LProducerSha $receiptFile) -ceq [string]$result.receiptSha256 -and
    (Get-Item -LiteralPath $receiptFile).Length -eq
      [int64]$result.receiptBytes
  ) 'authoritative producer result did not bind one immutable receipt.'
  $attestation = Invoke-C34LAuthoritativeAttestation $fixture $result $type
  Assert-C34LProducerFixture (
    [string]$attestation.sourceProducerId -ceq
      'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-PRODUCER-001'
  ) 'authoritative receipt did not derive the exact source attestation.'
  $writer = if ($type -ceq 'play_internal_testing_activation') {
    $playWriter
  } elseif ($type -ceq 'oppo_play_in_place_update_pair') {
    $oppoWriter
  } else {
    $journeyWriter
  }
  $writerResult = Invoke-C34LProducerWriter $writer @{
    Attempt=1;StatePath=$fixture.StateRelative
    AuthoritativeReceiptPath=[string]$result.receiptPath
    AuthoritativeReceiptSha256=[string]$result.receiptSha256
    AuthoritativeReceiptBytes=[int64]$result.receiptBytes
    FixtureMode=$true;RepositoryRoot=$root
  } "authoritative $type final writer"
  $authoritativePositive[$type] = [pscustomobject]@{
    Fixture=$fixture;Result=$result;Attestation=$attestation
    WriterResult=$writerResult
  }
}

foreach ($negative in @(
    @('wrong-challenge','observation adapter identity','caller-forged challenge'),
    @('wrong-adapter','observation adapter identity','wrong adapter identity'),
    @('wrong-seal','observation adapter identity','wrong sealed source'),
    @('wrong-owner','source-owner binding changed','wrong adapter script hash')
  )) {
  $negativeFixture = New-C34LAuthoritativeFixture `
    'play_internal_testing_activation'
  $mode=[string]$negative[0]
  Assert-C34LAuthoritativeExpectedRejection {
    Invoke-C34LAuthoritativeFixture $negativeFixture `
      'play_internal_testing_activation' $mode
  } ([string]$negative[1]) ([string]$negative[2]) $authoritativeLabels
}

$replayFixture = New-C34LAuthoritativeFixture 'play_internal_testing_activation'
[void](Invoke-C34LAuthoritativeFixture $replayFixture `
  'play_internal_testing_activation')
Assert-C34LAuthoritativeExpectedRejection {
  Invoke-C34LAuthoritativeFixture $replayFixture `
    'play_internal_testing_activation'
} 'single-use challenge changed' 'receipt challenge replay' $authoritativeLabels

$escapeFixture = New-C34LAuthoritativeFixture 'play_internal_testing_activation'
$siblingFixture = New-C34LAuthoritativeFixture 'play_internal_testing_activation'
$siblingAdapter = Write-C34LAuthoritativeAdapter $siblingFixture `
  'play_internal_testing_activation'
Assert-C34LAuthoritativeExpectedRejection {
  & $authoritativeProducer -EvidenceType play_internal_testing_activation `
    -Attempt 1 -StatePath $escapeFixture.StateRelative -FixtureMode `
    -FixtureRunRoot $escapeFixture.Relative `
    -FixtureAdapterPath $siblingAdapter.Relative -RepositoryRoot $root
} 'fixture adapter escaped its exact type-owned path' `
  'fixture adapter escape' $authoritativeLabels

foreach ($missing in @(
    @('play_internal_testing_activation',
      'MOOLSOCIAL-C34L-PLAY-INTERNAL-TRANSACTION-OBSERVATION-001',
      'Play production adapter missing'),
    @('oppo_play_in_place_update_pair',
      'MOOLSOCIAL-C34L-OPPO-READONLY-INTERACTIVE-RETENTION-ADAPTER-001',
      'OPPO production adapter missing')
  )) {
  $missingType=[string]$missing[0]
  Assert-C34LAuthoritativeExpectedRejection {
    & $authoritativeProducer -EvidenceType $missingType -Attempt 1 `
      -RepositoryRoot $root
  } ([string]$missing[1]) ([string]$missing[2]) $authoritativeLabels
}

foreach ($tamper in @('producer','seal','session','capture','journal')) {
  $fixture = New-C34LAuthoritativeFixture 'play_internal_testing_activation'
  $result = Invoke-C34LAuthoritativeFixture $fixture `
    'play_internal_testing_activation'
  $receiptFile = Join-Path $root ([string]$result.receiptPath)
  $receipt = Get-Content -Raw -LiteralPath $receiptFile | ConvertFrom-Json
  if ($tamper -ceq 'producer') {
    $receipt.producerOwner.sha256='A'*64
    $expected='contract, producer, state or artifact binding changed'
  } elseif ($tamper -ceq 'seal') {
    $receipt.sealedSourceManifest.sha256='B'*64
    $expected='sealed-source binding changed'
  } elseif ($tamper -ceq 'session') {
    $receipt.sessionId='c34l-authoritative-session-wrong000000000000000'
    $expected='challenge or derived session changed'
  } elseif ($tamper -ceq 'capture') {
    $captureFile=Join-Path $root ([string]$receipt.captureManifest.path)
    [IO.File]::AppendAllText($captureFile," `r`n",$utf8)
    $expected='capture manifest SHA-256 or byte-length binding changed'
  } else {
    $journalFile=Join-Path $root ([string]$result.journalPath)
    $journal=Get-Content -Raw -LiteralPath $journalFile|ConvertFrom-Json
    $journal.receipt.sha256='F'*64
    Write-C34LProducerJson $journalFile $journal
    $expected='journal receipt, challenge or chain binding changed'
  }
  if ($tamper -cin @('producer','seal','session')) {
    Write-C34LProducerJson $receiptFile $receipt
    $result.receiptSha256=Get-C34LProducerSha $receiptFile
    $result.receiptBytes=[int64](Get-Item -LiteralPath $receiptFile).Length
  }
  Assert-C34LAuthoritativeExpectedRejection {
    Invoke-C34LAuthoritativeAttestation $fixture $result `
      'play_internal_testing_activation'
  } $expected "authoritative $tamper tamper" $authoritativeLabels
}

$forgedFixture = New-C34LAuthoritativeFixture 'play_internal_testing_activation'
$forgedRelative =
  "$($forgedFixture.EvidenceRelative)/captures/attempt-1/play/authoritative-capture-receipt.json"
$forgedPath = Join-Path $root $forgedRelative
Write-C34LProducerJson $forgedPath ([pscustomobject][ordered]@{
  schemaVersion=1;receiptContractId='caller-forged'
})
$forgedResult=[pscustomobject]@{
  receiptPath=$forgedRelative;receiptSha256=Get-C34LProducerSha $forgedPath
  receiptBytes=[int64](Get-Item -LiteralPath $forgedPath).Length
}
Assert-C34LAuthoritativeExpectedRejection {
  Invoke-C34LAuthoritativeAttestation $forgedFixture $forgedResult `
    'play_internal_testing_activation'
} 'property count changed' 'caller-forged receipt JSON' $authoritativeLabels

Assert-C34LProducerFixture (
  $authoritativeLabels.Count -eq 14 -and
  @($authoritativeLabels | Select-Object -Unique).Count -eq 14
) 'authoritative negative count or uniqueness changed.'
$productionForbidden=@(
  'InternalReleaseActive','UploadCount','InternalActivationCount',
  'OtherTrackChanged','ColdStartInteractive','FirstInstallTimeMillis',
  'RetainedDataContinuityProved','PublicGuestJourneyPassed',
  'AllMandatoryJourneysPassed','NewIssueCount','AcceptanceSucceeded',
  'SuccessClaimed','SourceAttestationPath','SourceAttestationSha256',
  'SourceAttestationBytes'
)
foreach($writer in @($playWriter,$oppoWriter,$journeyWriter)){
  $productionSet=@((Get-Command -Name $writer -CommandType ExternalScript).
    ParameterSets|Where-Object{$_.Name -ceq 'ProductionReceipt'})
  Assert-C34LProducerFixture ($productionSet.Count -eq 1) `
    'final writer does not expose one ProductionReceipt set.'
  $productionNames=@($productionSet[0].Parameters.Name)
  $productionRequired=@(
    'AuthoritativeReceiptPath','AuthoritativeReceiptSha256',
    'AuthoritativeReceiptBytes'
  )
  Assert-C34LProducerFixture (
    @($productionForbidden|Where-Object{$productionNames -ccontains $_}).Count -eq 0 -and
    @($productionRequired|Where-Object{
      $productionNames -ccontains $_
    }).Count -eq 3
  ) 'final writer production interface accepts a caller-authored claim.'
}
if ($AuthoritativeReceiptOnly) {
  Write-Output (
    'C34L authoritative capture receipt fixtures passed: positive=3; ' +
    'negative=14; producerScriptBound=true; sealedSourceBound=true; ' +
    'stateAggregateArtifactVectorBound=true; transitionChallengeSingleUse=true; ' +
    'callerForgeryRejected=true; replayRejected=true; tamperRejected=true; ' +
    'fixtureEscapeRejected=true; productionMissingAdapters=2; ' +
    'realStateWrites=0; externalActions=0; browserActions=0; deviceActions=0; ' +
    'secretOrPrivateValuesObserved=false; cleanupVerified=true.'
  )
  return
}
$attestationQualification = @(& $attestationChecker -RepositoryRoot $root)
Assert-C34LProducerFixture (
  $attestationQualification.Count -eq 1 -and
  [string]$attestationQualification[0] -match '"positiveTypes":3' -and
  [string]$attestationQualification[0] -match '"externalActions":0'
) 'source-attestation qualification did not prove three zero-action types.'
$oppoTransactionQualification = @(& $oppoTransactionChecker `
  -RepositoryRoot $root)
Assert-C34LProducerFixture (
  $oppoTransactionQualification.Count -eq 1 -and
  [string]$oppoTransactionQualification[0] -match
    'C34L OPPO evidence transaction fixture passed:' -and
  [string]$oppoTransactionQualification[0] -match 'externalActions=0'
) 'OPPO transaction qualification did not prove zero-action crash recovery.'

$positive = New-C34LProducerFixture
$playAttestation = New-C34LProducerAttestation $positive play
$playArguments = @{
  Attempt = 1; StatePath = $positive.StateRelative
  InternalReleaseActive = $true; UploadCount = 1
  InternalActivationCount = 1; OtherTrackChanged = $false
  SourceAttestationPath=[string]$playAttestation.path
  SourceAttestationSha256=[string]$playAttestation.sha256
  SourceAttestationBytes=[int64]$playAttestation.bytes
  FixtureMode = $true; RepositoryRoot = $root
}
$playResult = Invoke-C34LProducerWriter $playWriter $playArguments 'Play writer'
$playEvidence = Assert-C34LProducerResult $positive $playResult `
  "$($positive.EvidenceRelative)/07-play-internal-testing-activation-evidence.json" `
  'Play writer'

Set-C34LProducerPhase $positive oppo
$oppoAttestation = New-C34LProducerAttestation $positive oppo
$oppoArguments = @{
  Attempt = 1; StatePath = $positive.StateRelative
  ColdStartInteractive = $true; BlankHierarchy = $false; Timeout = $false
  FlutterFatalErrorCount = 0; AndroidRuntimeFatalCount = 0; AnrCount = 0
  AppProcessErrorScanPassed = $true; ArtifactRelationshipProved = $true
  InPlaceUpdateProved = $true; FirstInstallTimeMillis = 1000
  LastUpdateTimeMillis = 2000; FirstInstallTimePreserved = $true
  RetainedDataContinuityProved = $true; InPlacePlayUpdateProved = $true
  UninstallPerformed = $false; DataClearPerformed = $false
  DowngradePerformed = $false; AdbInstallPerformed = $false
  SourceAttestationPath=[string]$oppoAttestation.path
  SourceAttestationSha256=[string]$oppoAttestation.sha256
  SourceAttestationBytes=[int64]$oppoAttestation.bytes
  FixtureMode = $true; RepositoryRoot = $root
}
$oppoResult = Invoke-C34LProducerWriter $oppoWriter $oppoArguments 'OPPO writer'
$oppoColdPath =
  "$($positive.EvidenceRelative)/08-oppo-play-in-place-update-cold-start-evidence.json"
$oppoRetainedPath =
  "$($positive.EvidenceRelative)/09-oppo-in-place-retained-data-evidence.json"
$oppoColdProjection = [pscustomobject][ordered]@{
  ticketId = $oppoResult.ticketId; attempt = $oppoResult.attempt
  path = $oppoResult.coldStart.path; sha256 = $oppoResult.coldStart.sha256
  bytes = $oppoResult.coldStart.bytes
  preStateSha256 = $oppoResult.preStateSha256
  preAggregateSha256 = $oppoResult.preAggregateSha256
  externalActionsPerformed = $oppoResult.externalActionsPerformed
  secretOrPrivateValuesRecorded = $oppoResult.secretOrPrivateValuesRecorded
}
$oppoRetainedProjection = [pscustomobject][ordered]@{
  ticketId = $oppoResult.ticketId; attempt = $oppoResult.attempt
  path = $oppoResult.retainedData.path; sha256 = $oppoResult.retainedData.sha256
  bytes = $oppoResult.retainedData.bytes
  preStateSha256 = $oppoResult.preStateSha256
  preAggregateSha256 = $oppoResult.preAggregateSha256
  externalActionsPerformed = $oppoResult.externalActionsPerformed
  secretOrPrivateValuesRecorded = $oppoResult.secretOrPrivateValuesRecorded
}
$oppoEvidence = Assert-C34LProducerResult $positive $oppoColdProjection `
  $oppoColdPath 'OPPO cold writer'
[void](Assert-C34LProducerResult $positive $oppoRetainedProjection `
  $oppoRetainedPath 'OPPO retained writer')

Set-C34LProducerPhase $positive journey
$journeyAttestation = New-C34LProducerAttestation $positive journey
$journeyArguments = @{
  Attempt = 1; StatePath = $positive.StateRelative
  PublicGuestJourneyPassed = $true; ProtectedGatewayJourneyPassed = $true
  SupportedAuthenticationJourneysPassed = $true; SocialJourneysPassed = $true
  WholeAppJourneysPassed = $true; C33gBlockerJourneysPassed = $true
  AllMandatoryJourneysPassed = $true; EvidenceComplete = $true
  NewIssueCount = 0; NewDefectCount = 0; BlankScreenCount = 0
  FlutterFatalErrorCount = 0; AndroidRuntimeFatalCount = 0; AnrCount = 0
  AcceptanceSucceeded = $true; SuccessClaimed = $true
  SourceAttestationPath=[string]$journeyAttestation.path
  SourceAttestationSha256=[string]$journeyAttestation.sha256
  SourceAttestationBytes=[int64]$journeyAttestation.bytes
  FixtureMode = $true; RepositoryRoot = $root
}
$journeyResult = Invoke-C34LProducerWriter $journeyWriter $journeyArguments `
  'journey writer'
$journeyEvidence = Assert-C34LProducerResult $positive $journeyResult `
  "$($positive.EvidenceRelative)/10-mandatory-whole-app-journey-evidence.json" `
  'journey writer'
Complete-C34LProducerFixture $positive $playResult $playEvidence $oppoResult `
  $oppoEvidence $journeyResult $journeyEvidence
$roundTripOutput = @(& $retainedChecker -Phase all -Attempt 1 `
  -StatePath $positive.StateRelative -FixtureMode -RepositoryRoot $root)
Assert-C34LProducerFixture (
  $roundTripOutput.Count -eq 1 -and
  [string]$roundTripOutput[0] -ceq
    "C34L retained-evidence gate passed: phase=all; attempt=1; candidate=$ticketId; unrelatedFilesAccepted=false."
) 'positive producer output did not round-trip through the retained-evidence gate.'

function Copy-C34LProducerArguments([hashtable]$Source) {
  $copy = @{}
  foreach ($key in $Source.Keys) { $copy[$key] = $Source[$key] }
  return $copy
}
$negativeLabels = @()
function Assert-C34LProducerExpectedRejection(
  [string]$Writer,
  [hashtable]$Arguments,
  [string]$ExpectedMessage,
  [string]$Label
) {
  $rejected = $false
  $observed = ''
  try { & $Writer @Arguments | Out-Null } catch {
    $rejected = $true
    $observed = $_.Exception.Message
  }
  Assert-C34LProducerFixture (
    $rejected -and $observed.Contains($ExpectedMessage)
  ) "$Label did not produce the expected fail-closed rejection."
  $script:negativeLabels += $Label
}

$incompletePlay = New-C34LProducerFixture
$incompletePlayArguments = Copy-C34LProducerArguments $playArguments
$incompletePlayArguments.StatePath = $incompletePlay.StateRelative
$incompletePlayArguments.InternalReleaseActive = $false
Assert-C34LProducerExpectedRejection $playWriter $incompletePlayArguments `
  'one active Internal Testing upload and zero other-track changes are required.' `
  'Play incomplete observation'

$wrongCount = New-C34LProducerFixture
$wrongCountState = Get-Content -Raw -LiteralPath $wrongCount.StatePath |
  ConvertFrom-Json
$wrongCountAggregate = Get-Content -Raw -LiteralPath $wrongCount.AggregatePath |
  ConvertFrom-Json
$wrongCountState.actionCounts.otherTrack = 1
$wrongCountAggregate.actionCounts.otherTrack = 1
Write-C34LProducerJson $wrongCount.StatePath $wrongCountState
Write-C34LProducerJson $wrongCount.AggregatePath $wrongCountAggregate
$wrongCountArguments = Copy-C34LProducerArguments $playArguments
$wrongCountArguments.StatePath = $wrongCount.StateRelative
Assert-C34LProducerExpectedRejection $playWriter $wrongCountArguments `
  'Play preimage action count changed at otherTrack.' 'eight-count vector'

$wrongAuthority = New-C34LProducerFixture
$wrongAuthorityState = Get-Content -Raw -LiteralPath $wrongAuthority.StatePath |
  ConvertFrom-Json
$wrongAuthorityAggregate = Get-Content -Raw -LiteralPath `
  $wrongAuthority.AggregatePath | ConvertFrom-Json
$wrongAuthorityState.releaseAuthorities.inPlaceOppoPlayUpdate = 'consumed'
$wrongAuthorityAggregate.releaseAuthorities.inPlaceOppoPlayUpdate = 'consumed'
Write-C34LProducerJson $wrongAuthority.StatePath $wrongAuthorityState
Write-C34LProducerJson $wrongAuthority.AggregatePath $wrongAuthorityAggregate
$wrongAuthorityArguments = Copy-C34LProducerArguments $playArguments
$wrongAuthorityArguments.StatePath = $wrongAuthority.StateRelative
Assert-C34LProducerExpectedRejection $playWriter $wrongAuthorityArguments `
  'Play preimage release authority changed at inPlaceOppoPlayUpdate.' `
  'four-authority vector'

$wrongArtifact = New-C34LProducerFixture
$wrongArtifactState = Get-Content -Raw -LiteralPath $wrongArtifact.StatePath |
  ConvertFrom-Json
$wrongArtifactState.buildResult.artifactSha256 = ('B' * 64)
Write-C34LProducerJson $wrongArtifact.StatePath $wrongArtifactState
$wrongArtifactArguments = Copy-C34LProducerArguments $playArguments
$wrongArtifactArguments.StatePath = $wrongArtifact.StateRelative
Assert-C34LProducerExpectedRejection $playWriter $wrongArtifactArguments `
  'sealed artifact path, SHA-256 or byte length changed.' `
  'artifact SHA-256 binding'

$immutablePlay = New-C34LProducerFixture
$immutablePlayArguments = Copy-C34LProducerArguments $playArguments
$immutablePlayArguments.StatePath = $immutablePlay.StateRelative
$immutablePlayAttestation = New-C34LProducerAttestation $immutablePlay play
$immutablePlayArguments.SourceAttestationPath =
  [string]$immutablePlayAttestation.path
$immutablePlayArguments.SourceAttestationSha256 =
  [string]$immutablePlayAttestation.sha256
$immutablePlayArguments.SourceAttestationBytes =
  [int64]$immutablePlayAttestation.bytes
[void](Invoke-C34LProducerWriter $playWriter $immutablePlayArguments `
  'immutable Play setup')
Assert-C34LProducerExpectedRejection $playWriter $immutablePlayArguments `
  'the immutable Play evidence owner already exists.' 'immutable output owner'

$outsideName =
  'c34l-evidence-producer-outside-' + [Guid]::NewGuid().ToString('N')
$outsideRelative = "tmp/$outsideName/state.json"
$outsidePath = Join-Path $root $outsideRelative
[void]$fixtureRoots.Add((Split-Path -Parent $outsidePath))
$outsideState = Get-Content -Raw -LiteralPath $incompletePlay.StatePath |
  ConvertFrom-Json
Write-C34LProducerJson $outsidePath $outsideState
$outsideArguments = Copy-C34LProducerArguments $playArguments
$outsideArguments.StatePath = $outsideRelative
Assert-C34LProducerExpectedRejection $playWriter $outsideArguments `
  'fixture state is outside the exact C34L evidence-producer root.' `
  'fixture root confinement'

$forbiddenOppo = New-C34LProducerFixture
Set-C34LProducerPhase $forbiddenOppo oppo
$forbiddenOppoArguments = Copy-C34LProducerArguments $oppoArguments
$forbiddenOppoArguments.StatePath = $forbiddenOppo.StateRelative
$forbiddenOppoAttestation = New-C34LProducerAttestation $forbiddenOppo oppo
$forbiddenOppoArguments.SourceAttestationPath =
  [string]$forbiddenOppoAttestation.path
$forbiddenOppoArguments.SourceAttestationSha256 =
  [string]$forbiddenOppoAttestation.sha256
$forbiddenOppoArguments.SourceAttestationBytes =
  [int64]$forbiddenOppoAttestation.bytes
$forbiddenOppoArguments.AdbInstallPerformed = $true
Assert-C34LProducerExpectedRejection $oppoWriter $forbiddenOppoArguments `
  'caller OPPO observations do not equal the authoritative retained capture artifacts.' `
  'OPPO prohibited ADB install'

$wrongOppoVector = New-C34LProducerFixture
Set-C34LProducerPhase $wrongOppoVector oppo
$wrongOppoState = Get-Content -Raw -LiteralPath $wrongOppoVector.StatePath |
  ConvertFrom-Json
$wrongOppoAggregate = Get-Content -Raw -LiteralPath `
  $wrongOppoVector.AggregatePath | ConvertFrom-Json
$wrongOppoState.actionCounts.realSmsSend = 1
$wrongOppoAggregate.actionCounts.realSmsSend = 1
Write-C34LProducerJson $wrongOppoVector.StatePath $wrongOppoState
Write-C34LProducerJson $wrongOppoVector.AggregatePath $wrongOppoAggregate
$wrongOppoArguments = Copy-C34LProducerArguments $oppoArguments
$wrongOppoArguments.StatePath = $wrongOppoVector.StateRelative
Assert-C34LProducerExpectedRejection $oppoWriter $wrongOppoArguments `
  'OPPO preimage action count changed at realSmsSend.' 'OPPO count vector'

$defectiveJourney = New-C34LProducerFixture
Set-C34LProducerPhase $defectiveJourney journey
$defectiveJourneyArguments = Copy-C34LProducerArguments $journeyArguments
$defectiveJourneyArguments.StatePath = $defectiveJourney.StateRelative
$defectiveJourneyArguments.NewDefectCount = 1
Assert-C34LProducerExpectedRejection $journeyWriter `
  $defectiveJourneyArguments `
  'complete defect-free mandatory journey acceptance is required.' `
  'journey defect count'

$wrongJourneyTicket = New-C34LProducerFixture
Set-C34LProducerPhase $wrongJourneyTicket journey
$wrongJourneyState = Get-Content -Raw -LiteralPath `
  $wrongJourneyTicket.StatePath | ConvertFrom-Json
$wrongJourneyAggregate = Get-Content -Raw -LiteralPath `
  $wrongJourneyTicket.AggregatePath | ConvertFrom-Json
$wrongJourneyState.ticketId = 'WRONG-C34L-TICKET'
$wrongJourneyState.candidate.id = 'WRONG-C34L-TICKET'
$wrongJourneyAggregate.ticketId = 'WRONG-C34L-TICKET'
$wrongJourneyAggregate.candidate.id = 'WRONG-C34L-TICKET'
Write-C34LProducerJson $wrongJourneyTicket.StatePath $wrongJourneyState
Write-C34LProducerJson $wrongJourneyTicket.AggregatePath $wrongJourneyAggregate
$wrongJourneyArguments = Copy-C34LProducerArguments $journeyArguments
$wrongJourneyArguments.StatePath = $wrongJourneyTicket.StateRelative
Assert-C34LProducerExpectedRejection $journeyWriter $wrongJourneyArguments `
  'candidate identity, phase, device or evidence root changed.' `
  'wrong ticket identity'

function Assert-C34LRetainedExpectedRejection(
  $Fixture,
  [string]$ExpectedMessage,
  [string]$Label
) {
  $rejected = $false
  $observed = ''
  try {
    & $retainedChecker -Phase all -Attempt 1 `
      -StatePath $Fixture.StateRelative -FixtureMode -RepositoryRoot $root |
      Out-Null
  } catch {
    $rejected = $true
    $observed = $_.Exception.Message
  }
  Assert-C34LProducerFixture (
    $rejected -and $observed.Contains($ExpectedMessage)
  ) "$Label did not produce the expected retained-evidence rejection."
  $script:negativeLabels += $Label
}

$finalStateText = [IO.File]::ReadAllText($positive.StatePath)
$finalAggregateText = [IO.File]::ReadAllText($positive.AggregatePath)
$journeyFile = Join-Path $root ([string]$journeyResult.path)
$journeyText = [IO.File]::ReadAllText($journeyFile)

$wrongPlayShaState = $finalStateText | ConvertFrom-Json
$wrongPlayShaState.playResult.evidenceSha256 = ('C' * 64)
Write-C34LProducerJson $positive.StatePath $wrongPlayShaState
Assert-C34LRetainedExpectedRejection $positive `
  'Internal Testing evidence SHA-256 or byte-length binding changed.' `
  'Play output SHA-256 tamper'
Write-C34LProducerText $positive.StatePath $finalStateText

$wrongProofPathState = $finalStateText | ConvertFrom-Json
$wrongProofPathAggregate = $finalAggregateText | ConvertFrom-Json
$wrongProofPath =
  "$($positive.EvidenceRelative)/alternate-lifecycle-proof-owner.json"
$wrongProofPathState.lifecycleTransactionProofs[2].evidencePath = $wrongProofPath
$wrongProofPathAggregate.lifecycleTransactionProofs[2].evidencePath = $wrongProofPath
Write-C34LProducerJson $positive.StatePath $wrongProofPathState
Write-C34LProducerJson $positive.AggregatePath $wrongProofPathAggregate
Assert-C34LRetainedExpectedRejection $positive `
  'mandatory journey evidence is not bound once to its exact newest lifecycle proof.' `
  'lifecycle proof evidence-path owner'
Write-C34LProducerText $positive.StatePath $finalStateText
Write-C34LProducerText $positive.AggregatePath $finalAggregateText

$wrongProofShaState = $finalStateText | ConvertFrom-Json
$wrongProofShaAggregate = $finalAggregateText | ConvertFrom-Json
$wrongProofShaState.lifecycleTransactionProofs[2].sha256 = ('E' * 64)
$wrongProofShaAggregate.lifecycleTransactionProofs[2].sha256 = ('E' * 64)
Write-C34LProducerJson $positive.StatePath $wrongProofShaState
Write-C34LProducerJson $positive.AggregatePath $wrongProofShaAggregate
Assert-C34LRetainedExpectedRejection $positive `
  'mandatory journey evidence is not bound once to its exact newest lifecycle proof.' `
  'lifecycle proof evidence SHA-256'
Write-C34LProducerText $positive.StatePath $finalStateText
Write-C34LProducerText $positive.AggregatePath $finalAggregateText

$wrongJourneyBytesState = $finalStateText | ConvertFrom-Json
$wrongJourneyBytesState.installResult.journeyEvidenceBytes =
  [int64]$wrongJourneyBytesState.installResult.journeyEvidenceBytes + 1
Write-C34LProducerJson $positive.StatePath $wrongJourneyBytesState
Assert-C34LRetainedExpectedRejection $positive `
  'mandatory journey evidence SHA-256 or byte-length binding changed.' `
  'journey output byte-length tamper'
Write-C34LProducerText $positive.StatePath $finalStateText

$wrongAttemptJourney = $journeyText | ConvertFrom-Json
$wrongAttemptJourney.attempt = 2
Write-C34LProducerJson $journeyFile $wrongAttemptJourney
$wrongAttemptState = $finalStateText | ConvertFrom-Json
$wrongAttemptState.installResult.journeyEvidenceSha256 =
  Get-C34LProducerSha $journeyFile
$wrongAttemptState.installResult.journeyEvidenceBytes =
  (Get-Item -LiteralPath $journeyFile).Length
Write-C34LProducerJson $positive.StatePath $wrongAttemptState
Assert-C34LRetainedExpectedRejection $positive `
  'mandatory journey evidence ticket, attempt or preimage identity changed.' `
  'journey attempt tamper'
Write-C34LProducerText $journeyFile $journeyText
Write-C34LProducerText $positive.StatePath $finalStateText

$wrongPreimageJourney = $journeyText | ConvertFrom-Json
$wrongPreimageJourney.preStateSha256 = ('D' * 64)
Write-C34LProducerJson $journeyFile $wrongPreimageJourney
$wrongPreimageState = $finalStateText | ConvertFrom-Json
$wrongPreimageState.installResult.journeyEvidenceSha256 =
  Get-C34LProducerSha $journeyFile
$wrongPreimageState.installResult.journeyEvidenceBytes =
  (Get-Item -LiteralPath $journeyFile).Length
$wrongPreimageAggregate = $finalAggregateText | ConvertFrom-Json
$wrongPreimageState.lifecycleTransactionProofs[2].sha256 =
  [string]$wrongPreimageState.installResult.journeyEvidenceSha256
$wrongPreimageAggregate.lifecycleTransactionProofs[2].sha256 =
  [string]$wrongPreimageState.installResult.journeyEvidenceSha256
Write-C34LProducerJson $positive.StatePath $wrongPreimageState
Write-C34LProducerJson $positive.AggregatePath $wrongPreimageAggregate
Assert-C34LRetainedExpectedRejection $positive `
  'mandatory journey evidence is not bound once to its exact newest lifecycle proof.' `
  'journey preimage tamper'
Write-C34LProducerText $journeyFile $journeyText
Write-C34LProducerText $positive.StatePath $finalStateText
Write-C34LProducerText $positive.AggregatePath $finalAggregateText

$secretShapeJourney = $journeyText | ConvertFrom-Json
$secretShapeJourney | Add-Member -NotePropertyName forbiddenCredentialPayload `
  -NotePropertyValue ('Bearer ' + ('E' * 16))
Write-C34LProducerJson $journeyFile $secretShapeJourney
$secretShapeState = $finalStateText | ConvertFrom-Json
$secretShapeState.installResult.journeyEvidenceSha256 =
  Get-C34LProducerSha $journeyFile
$secretShapeState.installResult.journeyEvidenceBytes =
  (Get-Item -LiteralPath $journeyFile).Length
Write-C34LProducerJson $positive.StatePath $secretShapeState
Assert-C34LRetainedExpectedRejection $positive `
  'mandatory journey evidence contains a forbidden private property name at forbiddenCredentialPayload.' `
  'forbidden credential-shaped field'
Write-C34LProducerText $journeyFile $journeyText
Write-C34LProducerText $positive.StatePath $finalStateText

$secretValueJourney = $journeyText | ConvertFrom-Json
$secretValueJourney.deviceModel = 'Bearer ' + ('F' * 16)
Write-C34LProducerJson $journeyFile $secretValueJourney
$secretValueState = $finalStateText | ConvertFrom-Json
$secretValueState.installResult.journeyEvidenceSha256 =
  Get-C34LProducerSha $journeyFile
$secretValueState.installResult.journeyEvidenceBytes =
  (Get-Item -LiteralPath $journeyFile).Length
Write-C34LProducerJson $positive.StatePath $secretValueState
Assert-C34LRetainedExpectedRejection $positive `
  'mandatory journey evidence contains a forbidden private value shape at deviceModel.' `
  'forbidden credential-shaped value'
Write-C34LProducerText $journeyFile $journeyText
Write-C34LProducerText $positive.StatePath $finalStateText

$wrongPathState = $finalStateText | ConvertFrom-Json
$wrongPathState.installResult.journeyEvidencePath =
  "$($positive.EvidenceRelative)/alternate-journey-evidence.json"
Write-C34LProducerJson $positive.StatePath $wrongPathState
Assert-C34LRetainedExpectedRejection $positive `
  'mandatory journey evidence is not the exact candidate evidence owner.' `
  'journey output path tamper'
Write-C34LProducerText $positive.StatePath $finalStateText

function Assert-C34LExactNames($Value, [string[]]$Expected, [string]$Label) {
  $actual = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LProducerFixture (
    $actual.Count -eq $Expected.Count -and
    (@($actual | Sort-Object) -join ',') -ceq
      (@($Expected | Sort-Object) -join ',')
  ) "$Label property schema changed."
}
function Assert-C34LFinalVectorNames($Value, [string]$Label) {
  Assert-C34LExactNames $Value.actionCounts @(
    'build','upload','install','deviceAcceptance','passwordlessEmailSend',
    'realSmsSend','otherTrack','backendHostingProviderOrProductionDeployment'
  ) "$Label action counts"
  Assert-C34LExactNames $Value.releaseAuthorities @(
    'build','uploadAndInternalActivation','inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  ) "$Label release authorities"
}
function Get-C34LWriterParameterNames([string]$Path) {
  $tokens = $null
  $parseErrors = $null
  $ast = [Management.Automation.Language.Parser]::ParseFile(
    $Path, [ref]$tokens, [ref]$parseErrors
  )
  Assert-C34LProducerFixture (@($parseErrors).Count -eq 0) `
    'writer parser found an error.'
  return @($ast.ParamBlock.Parameters | ForEach-Object {
    $_.Name.VariablePath.UserPath
  })
}
function Assert-C34LWriterParameters(
  [string]$Path,
  [string[]]$Expected,
  [string]$Label
) {
  $actual = @(Get-C34LWriterParameterNames $Path)
  Assert-C34LProducerFixture (
    $actual.Count -eq $Expected.Count -and
    (@($actual | Sort-Object) -join ',') -ceq
      (@($Expected | Sort-Object) -join ',')
  ) "$Label parameter surface changed."
}
function Assert-C34LProductionReceiptParameterSet(
  [string]$Path,
  [string]$Label
) {
  $scriptNames=@(Get-C34LWriterParameterNames $Path)
  $command=Get-Command -Name $Path -CommandType ExternalScript
  $set=@($command.ParameterSets | Where-Object {
    $_.Name -ceq 'ProductionReceipt'
  })
  Assert-C34LProducerFixture ($set.Count -eq 1) `
    "$Label does not expose one exact ProductionReceipt parameter set."
  $actual=@($set[0].Parameters.Name | Where-Object {
    $scriptNames -ccontains $_
  })
  $expected=@(
    'Attempt','StatePath','AuthoritativeReceiptPath',
    'AuthoritativeReceiptSha256','AuthoritativeReceiptBytes','RepositoryRoot'
  )
  Assert-C34LProducerFixture (
    $actual.Count -eq $expected.Count -and
    (@($actual | Sort-Object) -join ',') -ceq
      (@($expected | Sort-Object) -join ',')
  ) "$Label production parameter set accepts a caller success claim."
}

$playValue = Get-Content -Raw -LiteralPath (Join-Path $root $playResult.path) |
  ConvertFrom-Json
$coldValue = Get-Content -Raw -LiteralPath `
  (Join-Path $root $oppoResult.coldStart.path) | ConvertFrom-Json
$retainedValue = Get-Content -Raw -LiteralPath `
  (Join-Path $root $oppoResult.retainedData.path) | ConvertFrom-Json
$journeyValue = Get-Content -Raw -LiteralPath `
  (Join-Path $root $journeyResult.path) | ConvertFrom-Json
$commonFinalNames = @(
  'schemaVersion','evidenceContractId','evidenceType','ticketId','attempt',
  'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
  'packageName','versionName','versionCode','artifactSha256','artifactBytes',
  'sourceAttestation'
)
Assert-C34LExactNames $playValue ($commonFinalNames + @(
  'track','internalReleaseActive','uploadCount','internalActivationCount',
  'otherTrackChanged'
)) 'Play evidence'
Assert-C34LExactNames $coldValue ($commonFinalNames + @(
  'evidencePairId','deviceBindingSha256','deviceModel','installerPackage',
  'coldStartInteractive','blankHierarchy','timeout','flutterFatalErrorCount',
  'androidRuntimeFatalCount','anrCount','appProcessErrorScanPassed',
  'artifactRelationshipProved','inPlaceUpdateProved'
)) 'OPPO cold evidence'
Assert-C34LExactNames $retainedValue ($commonFinalNames + @(
  'evidencePairId','deviceBindingSha256','deviceModel','installerPackage',
  'firstInstallTimeMillis','lastUpdateTimeMillis','firstInstallTimePreserved',
  'retainedDataContinuityProved','inPlacePlayUpdateProved','uninstallPerformed',
  'dataClearPerformed','downgradePerformed','adbInstallPerformed'
)) 'OPPO retained evidence'
Assert-C34LExactNames $journeyValue ($commonFinalNames + @(
  'track','deviceBindingSha256','deviceModel','installerPackage',
  'publicGuestJourneyPassed','protectedGatewayJourneyPassed',
  'supportedAuthenticationJourneysPassed','socialJourneysPassed',
  'wholeAppJourneysPassed','c33gBlockerJourneysPassed',
  'allMandatoryJourneysPassed','evidenceComplete','newIssueCount',
  'newDefectCount','blankScreenCount','flutterFatalErrorCount',
  'androidRuntimeFatalCount','anrCount','acceptanceSucceeded','successClaimed'
)) 'journey evidence'
foreach ($row in @(
  @($playValue,'Play'), @($coldValue,'OPPO cold'),
  @($retainedValue,'OPPO retained'), @($journeyValue,'journey')
)) {
  Assert-C34LFinalVectorNames $row[0] $row[1]
  Assert-C34LExactNames $row[0].sourceAttestation @(
    'path','sha256','bytes','evidenceType','sourceProducerId','sessionId',
    'nonceSha256','producedUtc','expiresUtc','captureManifestPath',
    'captureManifestSha256','captureManifestBytes','captureDigests'
  ) "$($row[1]) source attestation"
}

Assert-C34LWriterParameters $playWriter @(
  'Attempt','StatePath','InternalReleaseActive','UploadCount',
  'InternalActivationCount','OtherTrackChanged','SourceAttestationPath',
  'SourceAttestationSha256','SourceAttestationBytes','AuthoritativeReceiptPath',
  'AuthoritativeReceiptSha256','AuthoritativeReceiptBytes','FixtureMode',
  'RepositoryRoot'
) 'Play writer'
Assert-C34LWriterParameters $oppoWriter @(
  'Attempt','StatePath','ColdStartInteractive','BlankHierarchy','Timeout',
  'FlutterFatalErrorCount','AndroidRuntimeFatalCount','AnrCount',
  'AppProcessErrorScanPassed','ArtifactRelationshipProved','InPlaceUpdateProved',
  'FirstInstallTimeMillis','LastUpdateTimeMillis','FirstInstallTimePreserved',
  'RetainedDataContinuityProved','InPlacePlayUpdateProved','UninstallPerformed',
  'DataClearPerformed','DowngradePerformed','AdbInstallPerformed',
  'SourceAttestationPath','SourceAttestationSha256','SourceAttestationBytes',
  'AuthoritativeReceiptPath','AuthoritativeReceiptSha256',
  'AuthoritativeReceiptBytes','FixtureMode','FixtureCrashBoundary',
  'RepositoryRoot'
) 'OPPO writer'
Assert-C34LWriterParameters $journeyWriter @(
  'Attempt','StatePath','PublicGuestJourneyPassed',
  'ProtectedGatewayJourneyPassed','SupportedAuthenticationJourneysPassed',
  'SocialJourneysPassed','WholeAppJourneysPassed','C33gBlockerJourneysPassed',
  'AllMandatoryJourneysPassed','EvidenceComplete','NewIssueCount',
  'NewDefectCount','BlankScreenCount','FlutterFatalErrorCount',
  'AndroidRuntimeFatalCount','AnrCount','AcceptanceSucceeded','SuccessClaimed',
  'SourceAttestationPath','SourceAttestationSha256','SourceAttestationBytes',
  'AuthoritativeReceiptPath','AuthoritativeReceiptSha256',
  'AuthoritativeReceiptBytes','FixtureMode','RepositoryRoot'
) 'journey writer'
Assert-C34LProductionReceiptParameterSet $playWriter 'Play writer'
Assert-C34LProductionReceiptParameterSet $oppoWriter 'OPPO writer'
Assert-C34LProductionReceiptParameterSet $journeyWriter 'journey writer'

$prohibitedActionTokens = @(
  'Start-Process','Invoke-WebRequest','Invoke-RestMethod','Get-Credential',
  'Read-Host','Start-Job','adb.exe','& adb','flutter build','firebase deploy',
  'gcloud','play.google.com','googleapis.com'
)
foreach ($writer in @($playWriter,$oppoWriter,$journeyWriter)) {
  $source = Get-Content -Raw -LiteralPath $writer
  foreach ($token in $prohibitedActionTokens) {
    Assert-C34LProducerFixture (-not $source.Contains($token)) `
      "writer contains prohibited external-action token: $token"
  }
  foreach ($required in @(
    'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
    'externalActionsPerformed','secretOrPrivateValuesRecorded'
  )) {
    Assert-C34LProducerFixture ($source.Contains($required)) `
      "writer is missing required sanitized binding token: $required"
  }
}

$expectedNegativeLabels = @(
  'Play incomplete observation','eight-count vector','four-authority vector',
  'artifact SHA-256 binding','immutable output owner','fixture root confinement',
  'OPPO prohibited ADB install','OPPO count vector','journey defect count',
  'wrong ticket identity','Play output SHA-256 tamper',
  'lifecycle proof evidence-path owner','lifecycle proof evidence SHA-256',
  'journey output byte-length tamper','journey attempt tamper',
  'journey preimage tamper','forbidden credential-shaped field',
  'forbidden credential-shaped value','journey output path tamper'
)
Assert-C34LProducerFixture (
  $negativeLabels.Count -eq $expectedNegativeLabels.Count -and
  @($negativeLabels | Select-Object -Unique).Count -eq
    $expectedNegativeLabels.Count
) 'negative fixture count or uniqueness changed.'
for ($index = 0; $index -lt $expectedNegativeLabels.Count; $index++) {
  Assert-C34LProducerFixture (
    [string]$negativeLabels[$index] -ceq [string]$expectedNegativeLabels[$index]
  ) "negative fixture inventory changed at index $index."
}
$restoredRoundTrip = @(& $retainedChecker -Phase all -Attempt 1 `
  -StatePath $positive.StateRelative -FixtureMode -RepositoryRoot $root)
Assert-C34LProducerFixture (
  $restoredRoundTrip.Count -eq 1 -and
  [string]$restoredRoundTrip[0] -ceq
    "C34L retained-evidence gate passed: phase=all; attempt=1; candidate=$ticketId; unrelatedFilesAccepted=false."
) 'fixture restoration did not preserve retained-evidence round-trip compatibility.'
Write-Output (
  "C34L evidence-producer fixtures passed: positive=3; negative=$($negativeLabels.Count); " +
  'ticketId=true; attempt=true; preimages=true; counts=8; authorities=4; ' +
  'PlayShaBytes=true; OppoColdShaBytes=true; OppoRetainedShaBytes=true; ' +
  'journeyShaBytes=true; immutablePaths=true; forbiddenFieldsRejected=true; ' +
  'sourceAttestationQualification=true; oppoAtomicTransactionQualification=true; ' +
  'sourceBindings=13; captureArtifactsBound=true; retainedRoundTrip=true; ' +
  'cleanupVerified=true; realStateWrites=0; externalActions=0; ' +
  'secretOrPrivateValuesObserved=false.'
)
} finally {
  foreach($fixtureRoot in $fixtureRoots){
    if(-not (Test-Path -LiteralPath $fixtureRoot)){ continue }
    $fixtureItem=Get-Item -LiteralPath $fixtureRoot -Force
    $retainedPrefix=Join-Path $root 'tmp\c34l-retained-evidence-fixtures-'
    $outsidePrefix=Join-Path $root 'tmp\c34l-evidence-producer-outside-'
    $authoritativePrefix=Join-Path $root `
      'tmp\c34l-authoritative-capture-fixtures-'
    Assert-C34LProducerFixture (
      $fixtureItem.FullName.StartsWith(
        $retainedPrefix,[StringComparison]::OrdinalIgnoreCase
      ) -or $fixtureItem.FullName.StartsWith(
        $outsidePrefix,[StringComparison]::OrdinalIgnoreCase
      ) -or $fixtureItem.FullName.StartsWith(
        $authoritativePrefix,[StringComparison]::OrdinalIgnoreCase
      )
    ) 'combined fixture cleanup root identity changed.'
    foreach($kind in @('play','oppo','journey')){
      $junction=Join-Path $fixtureRoot "evidence/captures/attempt-1/$kind"
      if(Test-Path -LiteralPath $junction){
        $junctionItem=Get-Item -LiteralPath $junction -Force
        if($junctionItem.Attributes -band [IO.FileAttributes]::ReparsePoint){
          $junctionItem.Delete()
          Assert-C34LProducerFixture (-not (Test-Path -LiteralPath $junction)) `
            'combined fixture junction cleanup was incomplete.'
        }
      }
    }
    $fixtureItem=Get-Item -LiteralPath $fixtureRoot -Force
    $fixtureItem.Delete($true)
    Assert-C34LProducerFixture (-not (Test-Path -LiteralPath $fixtureRoot)) `
      'combined fixture-root cleanup was incomplete.'
  }
}
