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
$utcFormat = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
$utf8 = [Text.UTF8Encoding]::new($false)
$countNames = @(
  'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
  'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
)
$authorityNames = @(
  'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)

function Assert-C34LJournal([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C34L transaction-journal fixture rejected: $Message" }
}
function ConvertTo-C34LJournalRelative([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path)
  Assert-C34LJournal ($full.StartsWith(
    $rootPrefix, [StringComparison]::OrdinalIgnoreCase
  )) 'journal fixture path escaped repository.'
  return $full.Substring($rootPrefix.Length).Replace('\', '/')
}
function Write-C34LJournalJson([string]$Path, [object]$Value) {
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent)
  }
  [IO.File]::WriteAllText(
    $Path,
    (($Value | ConvertTo-Json -Depth 60) + [Environment]::NewLine),
    $utf8
  )
}
function ConvertTo-C34LJournalUtc([object]$Value) {
  if ($Value -is [DateTimeOffset]) {
    $instant = ([DateTimeOffset]$Value).ToUniversalTime()
  } elseif ($Value -is [DateTime]) {
    $instant = [DateTimeOffset]::new(([DateTime]$Value).ToUniversalTime())
  } else {
    $instant = [DateTimeOffset]::ParseExact(
      [string]$Value,
      $utcFormat,
      [Globalization.CultureInfo]::InvariantCulture,
      [Globalization.DateTimeStyles]::AssumeUniversal -bor
        [Globalization.DateTimeStyles]::AdjustToUniversal
    )
  }
  return $instant.ToString(
    $utcFormat,
    [Globalization.CultureInfo]::InvariantCulture
  )
}
function ConvertTo-C34LJournalBrowserBinding([object]$Binding) {
  $normalized = ($Binding | ConvertTo-Json -Depth 20) | ConvertFrom-Json
  $normalized.browserEvidenceProducedUtc = ConvertTo-C34LJournalUtc `
    $Binding.browserEvidenceProducedUtc
  $normalized.browserEvidenceExpiresUtc = ConvertTo-C34LJournalUtc `
    $Binding.browserEvidenceExpiresUtc
  return $normalized
}
function Write-C34LCanonicalJournalMutation([string]$Path, [object]$Value) {
  foreach ($field in @('preparedUtc','committedUtc','reconciledUtc')) {
    if ($null -ne $Value.PSObject.Properties[$field] -and
      -not [string]::IsNullOrWhiteSpace([string]$Value.$field)) {
      $Value.$field = ConvertTo-C34LJournalUtc $Value.$field
    }
  }
  if ($null -ne $Value.PSObject.Properties['browserEvidence'] -and
    $null -ne $Value.browserEvidence) {
    $Value.browserEvidence = ConvertTo-C34LJournalBrowserBinding `
      $Value.browserEvidence
  }
  Write-C34LJournalJson $Path $Value
  $raw = [IO.File]::ReadAllText($Path)
  foreach ($field in @('preparedUtc','committedUtc','reconciledUtc')) {
    if ($null -ne $Value.PSObject.Properties[$field] -and
      -not [string]::IsNullOrWhiteSpace([string]$Value.$field)) {
      $pattern = '"' + [regex]::Escape($field) + '"\s*:\s*"' +
        [regex]::Escape([string]$Value.$field) + '"'
      Assert-C34LJournal ([regex]::Matches($raw,$pattern).Count -eq 1) `
        "canonical journal mutation changed the singular $field wire token."
    }
  }
  if ($null -ne $Value.PSObject.Properties['browserEvidence'] -and
    $null -ne $Value.browserEvidence) {
    foreach ($field in @('browserEvidenceProducedUtc','browserEvidenceExpiresUtc')) {
      $pattern = '"' + [regex]::Escape($field) + '"\s*:\s*"' +
        [regex]::Escape([string]$Value.browserEvidence.$field) + '"'
      Assert-C34LJournal ([regex]::Matches($raw,$pattern).Count -eq 1) `
        "canonical journal mutation changed the singular $field wire token."
    }
  }
}
function Get-C34LJournalFileHash([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
}
function Get-C34LJournalBytesHash([byte[]]$Bytes) {
  $sha=[Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-','')
  } finally { $sha.Dispose() }
}
function Get-C34LJournalFile([string]$Path) {
  return [pscustomobject]@{
    Path=$Path; Relative=ConvertTo-C34LJournalRelative $Path
    Sha256=Get-C34LJournalFileHash $Path
    Bytes=(Get-Item -LiteralPath $Path).Length
  }
}
function Get-C34LJournalPairHash([object]$Fixture) {
  return ((Get-C34LJournalFileHash $Fixture.StatePath) + ':' +
    (Get-C34LJournalFileHash $Fixture.AggregatePath))
}
function New-C34LJournalFixture([string]$Name) {
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
    browserEvidenceExpiresUtc=$null
    sourceManifestPath=$null; sourceManifestSha256=$null; sourceManifestBytes=0
    blockerLedgerPath=$null; blockerLedgerSha256=$null; blockerLedgerBytes=0
    liveBrowserRouteQualified=$false
    signedInMoolSocialAppRouteProved=$false; internalTestingRouteProved=$false
    noPlayWritePerformed=$true
  }
  $state = [ordered]@{
    schemaVersion=1; contractId='MOOLSOCIAL-C34L-JOURNAL-STATE-FIXTURE'
    ticketId=$ticketId; aggregateStatePath=ConvertTo-C34LJournalRelative $aggregatePath
    evidenceRoot=(ConvertTo-C34LJournalRelative $directory) + '/evidence'
    machineState=$initial
    buildAuthorization='available_once'; uploadAuthorization='held_postbuild_qualification'
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
    schemaVersion=1; contractId='MOOLSOCIAL-C34L-JOURNAL-AGGREGATE-FIXTURE'
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
      browserEvidenceExpiresUtc=$null
      sourceManifestPath=$null; sourceManifestSha256=$null; sourceManifestBytes=0
      blockerLedgerPath=$null; blockerLedgerSha256=$null; blockerLedgerBytes=0
      liveBrowserRouteQualified=$false
      signedInMoolSocialAppRouteProved=$false; internalTestingRouteProved=$false
      noPlayWritePerformed=$true
    }
    lifecycleTransactionProofs=@(); rejection=$null
  }
  Assert-C34LJournal (
    -not [object]::ReferenceEquals($state.releaseAuthorities, $aggregate.releaseAuthorities) -and
    -not [object]::ReferenceEquals($state.actionCounts, $aggregate.actionCounts) -and
    @($state.actionCounts.Keys).Count -eq 8 -and
    @($aggregate.actionCounts.Keys).Count -eq 8 -and
    @($state.releaseAuthorities.Keys).Count -eq 4 -and
    @($aggregate.releaseAuthorities.Keys).Count -eq 4
  ) 'journal detailed/aggregate vectors must be complete distinct projections.'
  Write-C34LJournalJson $statePath $state
  Write-C34LJournalJson $aggregatePath $aggregate
  return [pscustomobject]@{
    Directory=$directory; StatePath=$statePath; AggregatePath=$aggregatePath
    StateRelative=ConvertTo-C34LJournalRelative $statePath
    JournalRoot=Join-Path $directory 'journals'
  }
}
function New-C34LJournalProof(
  [object]$Fixture,
  [string]$Transition = 'founder-inputs-validated',
  [string]$Phase = 'preprompt'
) {
  $state = Get-Content -Raw -LiteralPath $Fixture.StatePath | ConvertFrom-Json
  $proofPath = Join-Path $Fixture.Directory ('proof-' + $Transition + '.json')
  $proof = [ordered]@{
    ticketId=$ticketId; attempt=1
    versionName=$versionName; versionCode=$versionCode
    transition=$Transition; phase=$Phase; passed=$true
    stateSha256=Get-C34LJournalFileHash $Fixture.StatePath
    aggregateSha256=Get-C34LJournalFileHash $Fixture.AggregatePath
    actionCounts=$state.actionCounts; releaseAuthorities=$state.releaseAuthorities
  }
  Write-C34LJournalJson $proofPath $proof
  return [pscustomobject]@{
    Relative=ConvertTo-C34LJournalRelative $proofPath
    Sha256=Get-C34LJournalFileHash $proofPath
  }
}
function New-C34LJournalBrowserProof([object]$Fixture) {
  $state = Get-Content -Raw -LiteralPath $Fixture.StatePath | ConvertFrom-Json
  $aggregate = Get-Content -Raw -LiteralPath $Fixture.AggregatePath |
    ConvertFrom-Json
  $machineState = 'single_release_AAB_succeeded_authority_consumed'
  $state.machineState = $machineState; $aggregate.machineState = $machineState
  $state.candidate.disposition = $machineState
  $aggregate.candidate.disposition = $machineState
  $state.candidate.artifactReusable = $true
  $aggregate.candidate.artifactReusable = $true
  $state.buildAuthorization = 'consumed'
  $state.releaseAuthorities.build = 'consumed'
  $aggregate.releaseAuthorities.build = 'consumed'
  $state.actionCounts.build = 1; $aggregate.actionCounts.build = 1
  $aggregate.candidate.buildCount = 1
  $state.buildResult.state = $machineState; $state.buildResult.buildCount = 1
  $artifactPath = Join-Path $Fixture.Directory 'fixture-release.aab'
  $provenancePath = Join-Path $Fixture.Directory 'fixture-provenance.json'
  [IO.File]::WriteAllText($artifactPath,'fixture-journal-aab',$utf8)
  Write-C34LJournalJson $provenancePath ([ordered]@{
    candidateId=$ticketId; attempt=1
  })
  $artifact = Get-C34LJournalFile $artifactPath
  $provenance = Get-C34LJournalFile $provenancePath
  $state.buildResult.wrapperInvocationCount = 1
  $state.buildResult.artifactPath = $artifact.Relative
  $state.buildResult.artifactSha256 = $artifact.Sha256
  $state.buildResult.artifactBytes = $artifact.Bytes
  $state.buildResult.uploadSignerSha256 = 'E' * 64
  $state.buildResult.provenance = $provenance.Relative
  $state.buildResult.packageVersionManifestProved = $true
  $state.buildResult.googleAppIdResourceProved = $true
  $state.buildResult.crashlyticsBuildIdResourceProved = $true
  $state.buildResult.splitAndArm64PayloadProved = $true
  $state.buildResult.mergedReleaseManifestProved = $true
  $aggregate.candidate.aabSha256 = $artifact.Sha256
  Write-C34LJournalJson $Fixture.StatePath $state
  Write-C34LJournalJson $Fixture.AggregatePath $aggregate
  $stateSha256 = Get-C34LJournalFileHash $Fixture.StatePath
  $aggregateSha256 = Get-C34LJournalFileHash $Fixture.AggregatePath
  $producedUtc = [DateTimeOffset]::UtcNow.AddSeconds(-2).ToString(
    $utcFormat, [Globalization.CultureInfo]::InvariantCulture
  )
  $expiresUtc = [DateTimeOffset]::UtcNow.AddMinutes(10).ToString(
    $utcFormat, [Globalization.CultureInfo]::InvariantCulture
  )
  $nonceSha256 = 'A' * 64
  $sessionId = 'c34l-browser-session-' + $nonceSha256.Substring(0, 16)
  $sourceManifestPath = Join-Path $Fixture.Directory 'source-manifest.txt'
  $blockerLedgerPath = Join-Path $Fixture.Directory 'blocker-ledger.json'
  [IO.File]::WriteAllText(
    $sourceManifestPath,
    ('fixture source manifest' + [Environment]::NewLine),
    $utf8
  )
  Write-C34LJournalJson $blockerLedgerPath ([ordered]@{
    fixture=$true; mutableOutsideSourceSeal=$true
  })
  $sourceManifestRelative = ConvertTo-C34LJournalRelative $sourceManifestPath
  $sourceManifestSha256 = Get-C34LJournalFileHash $sourceManifestPath
  $sourceManifestBytes = (Get-Item -LiteralPath $sourceManifestPath).Length
  $blockerLedgerRelative = ConvertTo-C34LJournalRelative $blockerLedgerPath
  $blockerLedgerSha256 = Get-C34LJournalFileHash $blockerLedgerPath
  $blockerLedgerBytes = (Get-Item -LiteralPath $blockerLedgerPath).Length
  $browserPath = Join-Path $Fixture.Directory 'browser.json'
  $browserRelative = ConvertTo-C34LJournalRelative $browserPath
  $browser = [ordered]@{
    schemaVersion=1; contractId=$browserContractId; ticketId=$ticketId
    attempt=1; versionName=$versionName; versionCode=$versionCode
    transition='upload-authorized'; phase='preupload'
    stateSha256=$stateSha256; aggregateSha256=$aggregateSha256
    sourceManifest=[ordered]@{
      path=$sourceManifestRelative; sha256=$sourceManifestSha256
      bytes=$sourceManifestBytes
    }
    blockerLedger=[ordered]@{
      path=$blockerLedgerRelative; sha256=$blockerLedgerSha256
      bytes=$blockerLedgerBytes; mutableOutsideSourceSeal=$true
    }
    sessionId=$sessionId; sessionNonceSha256=$nonceSha256
    producerId=$browserProducerId; producedUtc=$producedUtc; expiresUtc=$expiresUtc
    routes=[ordered]@{
      liveBrowserRouteQualified=$true
      signedInMoolSocialAppRouteProved=$true
      internalTestingRouteProved=$true
      sanitizedHost='play.google.com'
      sanitizedPath='/console/app/internal-testing'
      queryPresent=$false; fragmentPresent=$false
    }
    actionCounts=$state.actionCounts; releaseAuthorities=$state.releaseAuthorities
    copiedFromPriorCandidate=$false
    noPlayWritePerformed=$true; uploadActionCount=0
    activationActionCount=0; otherTrackActionCount=0
    privateValuesObserved=$false
  }
  Write-C34LJournalJson $browserPath $browser
  $binding = [pscustomobject][ordered]@{
    browserEvidencePath=$browserRelative
    browserEvidenceSha256=Get-C34LJournalFileHash $browserPath
    browserEvidenceBytes=(Get-Item -LiteralPath $browserPath).Length
    browserEvidenceAttempt=1; browserEvidenceTransition='upload-authorized'
    browserEvidencePhase='preupload'; browserEvidencePreStateSha256=$stateSha256
    browserEvidencePreAggregateSha256=$aggregateSha256
    browserSessionId=$sessionId; browserSessionNonceSha256=$nonceSha256
    browserEvidenceProducerId=$browserProducerId
    browserEvidenceProducedUtc=$producedUtc; browserEvidenceExpiresUtc=$expiresUtc
    sourceManifestPath=$sourceManifestRelative
    sourceManifestSha256=$sourceManifestSha256
    sourceManifestBytes=$sourceManifestBytes
    blockerLedgerPath=$blockerLedgerRelative
    blockerLedgerSha256=$blockerLedgerSha256
    blockerLedgerBytes=$blockerLedgerBytes
    liveBrowserRouteQualified=$true; signedInMoolSocialAppRouteProved=$true
    internalTestingRouteProved=$true; noPlayWritePerformed=$true
  }
  $proofPath = Join-Path $Fixture.Directory 'browser-prerequisite.json'
  $proof = [ordered]@{
    ticketId=$ticketId; attempt=1; versionName=$versionName; versionCode=$versionCode
    transition='upload-authorized'; phase='preupload'; passed=$true
    stateSha256=$stateSha256; aggregateSha256=$aggregateSha256
    actionCounts=$state.actionCounts; releaseAuthorities=$state.releaseAuthorities
    browserEvidence=$binding
  }
  Write-C34LJournalJson $proofPath $proof
  return [pscustomobject]@{
    Relative=ConvertTo-C34LJournalRelative $proofPath
    Sha256=Get-C34LJournalFileHash $proofPath
    BrowserPath=$browserPath; Binding=$binding
  }
}

function New-C34LJournalSourceBinding(
  [object]$Fixture,
  [ValidateSet('play','oppo','journey')][string]$Kind
) {
  $state = Get-Content -Raw -LiteralPath $Fixture.StatePath | ConvertFrom-Json
  $aggregate = Get-Content -Raw -LiteralPath $Fixture.AggregatePath |
    ConvertFrom-Json
  $stateSha256 = Get-C34LJournalFileHash $Fixture.StatePath
  $aggregateSha256 = Get-C34LJournalFileHash $Fixture.AggregatePath
  $evidenceRoot = [string]$state.evidenceRoot
  $captureRoot = Join-Path $root (
    "$evidenceRoot/captures/attempt-1/$Kind".Replace('/','\')
  )
  [void](New-Item -ItemType Directory -Path $captureRoot -Force)
  $producedUtc = [DateTimeOffset]::UtcNow.AddSeconds(-2).ToString(
    $utcFormat,[Globalization.CultureInfo]::InvariantCulture
  )
  $expiresUtc = [DateTimeOffset]::UtcNow.AddMinutes(10).ToString(
    $utcFormat,[Globalization.CultureInfo]::InvariantCulture
  )
  $spec = switch ($Kind) {
    'play' { [pscustomobject]@{
      Type='play_internal_testing_activation'; Short='play'
      Producer='MOOLSOCIAL-C34L-PLAY-CAPTURE-PRODUCER-001'
      Roles=@('internal_testing_release_receipt','internal_testing_status_observation')
      Leaves=@{
        internal_testing_release_receipt='internal-testing-release-receipt.json'
        internal_testing_status_observation='internal-testing-status-observation.json'
      }
      Nonce='A'
    } }
    'oppo' { [pscustomobject]@{
      Type='oppo_play_in_place_update_pair'; Short='oppo'
      Producer='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
      Roles=@('cold_start_observation','retained_state_observation')
      Leaves=@{
        cold_start_observation='cold-start-observation.json'
        retained_state_observation='retained-state-observation.json'
      }
      Nonce='B'
    } }
    'journey' { [pscustomobject]@{
      Type='mandatory_whole_app_journey_acceptance'; Short='journey'
      Producer='MOOLSOCIAL-C34L-JOURNEY-CAPTURE-PRODUCER-001'
      Roles=@('journey_acceptance_manifest')
      Leaves=@{ journey_acceptance_manifest='journey-acceptance-manifest.json' }
      Nonce='C'
    } }
  }
  $artifacts = @()
  $digests = [ordered]@{}
  if ($Kind -ceq 'journey') {
    $journeyDirectory = Join-Path $captureRoot 'journeys'
    [void](New-Item -ItemType Directory -Path $journeyDirectory -Force)
    $rows = @()
    foreach ($journeyId in @(
      'publicGuest','protectedGateway','supportedAuthentication','social',
      'wholeApp','c33gBlocker'
    )) {
      $rowPath = Join-Path $journeyDirectory "$journeyId.json"
      Write-C34LJournalJson $rowPath ([ordered]@{
        schemaVersion=1; journeyId=$journeyId; passed=$true
      })
      $rowFile = Get-C34LJournalFile $rowPath
      $rows += [ordered]@{
        journeyId=$journeyId; path=$rowFile.Relative; sha256=$rowFile.Sha256
        bytes=$rowFile.Bytes; passed=$true
      }
      $digests[$journeyId + 'DigestSha256'] = $rowFile.Sha256
    }
    $manifestPath = Join-Path $captureRoot $spec.Leaves.journey_acceptance_manifest
    Write-C34LJournalJson $manifestPath $rows
    $manifestFile = Get-C34LJournalFile $manifestPath
    $artifacts += [ordered]@{
      role='journey_acceptance_manifest'; path=$manifestFile.Relative
      sha256=$manifestFile.Sha256; bytes=$manifestFile.Bytes
      mediaType='application/json'
    }
  } else {
    foreach ($role in $spec.Roles) {
      $artifactPath = Join-Path $captureRoot $spec.Leaves[$role]
      Write-C34LJournalJson $artifactPath ([ordered]@{
        schemaVersion=1; role=$role; passed=$true
      })
      $artifactFile = Get-C34LJournalFile $artifactPath
      $artifacts += [ordered]@{
        role=$role; path=$artifactFile.Relative; sha256=$artifactFile.Sha256
        bytes=$artifactFile.Bytes; mediaType='application/json'
      }
    }
    if ($Kind -ceq 'play') {
      $digests['internalTestingRouteDigestSha256']=$artifacts[0].sha256
      $digests['uploadReceiptDigestSha256']=$artifacts[0].sha256
      $digests['activationStateDigestSha256']=$artifacts[1].sha256
    } else {
      $digests['packageStateDigestSha256']=$artifacts[0].sha256
      $digests['coldStartDigestSha256']=$artifacts[0].sha256
      $digests['retainedDataDigestSha256']=$artifacts[1].sha256
    }
  }
  $sessionId = "c34l-$Kind-journal-session-00000001"
  $capturePath = Join-Path $captureRoot 'capture-manifest.json'
  Write-C34LJournalJson $capturePath ([ordered]@{
    schemaVersion=1
    captureContractId='MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001'
    evidenceType=$spec.Type; ticketId=$ticketId; attempt=1
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; preStateSha256=$stateSha256
    preAggregateSha256=$aggregateSha256; actionCounts=$state.actionCounts
    releaseAuthorities=$state.releaseAuthorities
    artifactSha256=[string]$state.buildResult.artifactSha256
    artifactBytes=[int64]$state.buildResult.artifactBytes
    sourceProducerId=$spec.Producer; sessionId=$sessionId
    nonceSha256=($spec.Nonce * 64); producedUtc=$producedUtc; expiresUtc=$expiresUtc
    captureDigests=$digests
    captureArtifactContractPath=$captureArtifactContractPath
    captureArtifactContractSha256=$captureArtifactContractSha256
    captureArtifactContractId=$captureArtifactContractId
    captureArtifacts=$artifacts
  })
  $captureFile = Get-C34LJournalFile $capturePath
  $attestationPath = Join-Path $Fixture.Directory (
    "evidence/attestations/source-attestation-$Kind-attempt-1.json".Replace('/','\')
  )
  Write-C34LJournalJson $attestationPath ([ordered]@{
    schemaVersion=1
    attestationContractId='MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001'
    evidenceType=$spec.Type; ticketId=$ticketId; attempt=1
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; preStateSha256=$stateSha256
    preAggregateSha256=$aggregateSha256; actionCounts=$state.actionCounts
    releaseAuthorities=$state.releaseAuthorities
    artifactSha256=[string]$state.buildResult.artifactSha256
    artifactBytes=[int64]$state.buildResult.artifactBytes
    sourceProducerId=$spec.Producer; sessionId=$sessionId
    nonceSha256=($spec.Nonce * 64); producedUtc=$producedUtc; expiresUtc=$expiresUtc
    captureManifestPath=$captureFile.Relative
    captureManifestSha256=$captureFile.Sha256
    captureManifestBytes=$captureFile.Bytes; captureDigests=$digests
  })
  $attestationFile = Get-C34LJournalFile $attestationPath
  return [pscustomobject]@{
    State=$state; Aggregate=$aggregate; StateSha256=$stateSha256
    AggregateSha256=$aggregateSha256; EvidenceRoot=$evidenceRoot; Spec=$spec
    CaptureFile=$captureFile; CaptureArtifacts=$artifacts
    AttestationFile=$attestationFile
    Binding=[pscustomobject][ordered]@{
      path=$attestationFile.Relative; sha256=$attestationFile.Sha256
      bytes=$attestationFile.Bytes; evidenceType=$spec.Type
      sourceProducerId=$spec.Producer; sessionId=$sessionId
      nonceSha256=($spec.Nonce * 64); producedUtc=$producedUtc; expiresUtc=$expiresUtc
      captureManifestPath=$captureFile.Relative
      captureManifestSha256=$captureFile.Sha256
      captureManifestBytes=$captureFile.Bytes; captureDigests=$digests
    }
  }
}

function New-C34LJournalFinalEvidence(
  [object]$Fixture,
  [ValidateSet('play','oppo','journey')][string]$Kind
) {
  $source = New-C34LJournalSourceBinding $Fixture $Kind
  $common = [ordered]@{
    schemaVersion=1; ticketId=$ticketId; attempt=1
    preStateSha256=$source.StateSha256; preAggregateSha256=$source.AggregateSha256
    actionCounts=$source.State.actionCounts
    releaseAuthorities=$source.State.releaseAuthorities
    packageName='com.moolsocial.app'; versionName=$versionName; versionCode=$versionCode
    artifactSha256=[string]$source.State.buildResult.artifactSha256
    artifactBytes=[int64]$source.State.buildResult.artifactBytes
  }
  $evidenceRootPath = Join-Path $root ($source.EvidenceRoot.Replace('/','\'))
  [void](New-Item -ItemType Directory -Path $evidenceRootPath -Force)
  if ($Kind -ceq 'play') {
    $path = Join-Path $evidenceRootPath `
      '07-play-internal-testing-activation-evidence.json'
    $value=[ordered]@{}+$common
    $value['evidenceContractId']='MOOLSOCIAL-C34L-PLAY-EVIDENCE-001'
    $value['evidenceType']='play_internal_testing_activation';$value['track']='internal'
    $value['internalReleaseActive']=$true;$value['uploadCount']=1
    $value['internalActivationCount']=1;$value['otherTrackChanged']=$false
    $value['sourceAttestation']=$source.Binding
    Write-C34LJournalJson $path $value
    return [pscustomobject]@{Play=Get-C34LJournalFile $path;Source=$source}
  }
  if ($Kind -ceq 'oppo') {
    $pairId="oppo-1-$($source.StateSha256)"
    $identity=[ordered]@{}+$common
    $identity['evidenceContractId']='MOOLSOCIAL-C34L-OPPO-EVIDENCE-001'
    $identity['evidencePairId']=$pairId
    $identity['deviceBindingSha256']=$deviceBindingSha256
    $identity['deviceModel']='CPH2375';$identity['installerPackage']='com.android.vending'
    $identity['sourceAttestation']=$source.Binding
    $coldPath=Join-Path $evidenceRootPath `
      '08-oppo-play-in-place-update-cold-start-evidence.json'
    $cold=[ordered]@{}+$identity
    $cold['evidenceType']='oppo_play_in_place_update_cold_start'
    $cold['coldStartInteractive']=$true;$cold['blankHierarchy']=$false
    $cold['timeout']=$false;$cold['flutterFatalErrorCount']=0
    $cold['androidRuntimeFatalCount']=0;$cold['anrCount']=0
    $cold['appProcessErrorScanPassed']=$true
    $cold['artifactRelationshipProved']=$true;$cold['inPlaceUpdateProved']=$true
    Write-C34LJournalJson $coldPath $cold;$coldFile=Get-C34LJournalFile $coldPath
    $retainedPath=Join-Path $evidenceRootPath `
      '09-oppo-in-place-retained-data-evidence.json'
    $retained=[ordered]@{}+$identity
    $retained['evidenceType']='oppo_in_place_retained_data'
    $retained['firstInstallTimeMillis']=1000L;$retained['lastUpdateTimeMillis']=2000L
    $retained['firstInstallTimePreserved']=$true
    $retained['retainedDataContinuityProved']=$true
    $retained['inPlacePlayUpdateProved']=$true
    $retained['uninstallPerformed']=$false;$retained['dataClearPerformed']=$false
    $retained['downgradePerformed']=$false;$retained['adbInstallPerformed']=$false
    Write-C34LJournalJson $retainedPath $retained
    $retainedFile=Get-C34LJournalFile $retainedPath
    $transactionDirectory=Join-Path $evidenceRootPath 'transactions'
    [void](New-Item -ItemType Directory -Path $transactionDirectory -Force)
    $transactionPath=Join-Path $transactionDirectory `
      'oppo-evidence-pair-attempt-1.json'
    $preparedUtc=[DateTimeOffset]::UtcNow.AddSeconds(-1).ToString(
      $utcFormat,[Globalization.CultureInfo]::InvariantCulture
    )
    $committedUtc=[DateTimeOffset]::UtcNow.ToString(
      $utcFormat,[Globalization.CultureInfo]::InvariantCulture
    )
    Write-C34LJournalJson $transactionPath ([ordered]@{
      schemaVersion=1
      transactionContractId='MOOLSOCIAL-C34L-OPPO-EVIDENCE-TRANSACTION-001'
      transactionId="oppo-evidence-1-$($source.StateSha256)-$($source.AggregateSha256)"
      ticketId=$ticketId;attempt=1;status='committed'
      preStateSha256=$source.StateSha256;preAggregateSha256=$source.AggregateSha256
      artifactSha256=[string]$source.State.buildResult.artifactSha256
      artifactBytes=[int64]$source.State.buildResult.artifactBytes
      coldStart=[ordered]@{path=$coldFile.Relative;sha256=$coldFile.Sha256;bytes=$coldFile.Bytes}
      retainedData=[ordered]@{
        path=$retainedFile.Relative;sha256=$retainedFile.Sha256;bytes=$retainedFile.Bytes
      }
      sourceAttestation=$source.Binding;preparedUtc=$preparedUtc;committedUtc=$committedUtc
    })
    return [pscustomobject]@{Cold=$coldFile;Retained=$retainedFile;Source=$source}
  }
  $path=Join-Path $evidenceRootPath '10-mandatory-whole-app-journey-evidence.json'
  $value=[ordered]@{}+$common
  $value['evidenceContractId']='MOOLSOCIAL-C34L-JOURNEY-EVIDENCE-001'
  $value['evidenceType']='mandatory_whole_app_journey_acceptance'
  $value['track']='internal';$value['deviceBindingSha256']=$deviceBindingSha256
  $value['deviceModel']='CPH2375';$value['installerPackage']='com.android.vending'
  foreach($name in @(
    'publicGuestJourneyPassed','protectedGatewayJourneyPassed',
    'supportedAuthenticationJourneysPassed','socialJourneysPassed',
    'wholeAppJourneysPassed','c33gBlockerJourneysPassed',
    'allMandatoryJourneysPassed','evidenceComplete','acceptanceSucceeded','successClaimed'
  )){$value[$name]=$true}
  foreach($name in @(
    'newIssueCount','newDefectCount','blankScreenCount','flutterFatalErrorCount',
    'androidRuntimeFatalCount','anrCount'
  )){$value[$name]=0}
  $value['sourceAttestation']=$source.Binding
  Write-C34LJournalJson $path $value
  return [pscustomobject]@{Journey=Get-C34LJournalFile $path;Source=$source}
}
function Invoke-C34LInjectedBrowserTransition([object]$Fixture, [string]$Boundary) {
  $proof = New-C34LJournalBrowserProof $Fixture
  $binding = $proof.Binding
  $pairBefore = Get-C34LJournalPairHash $Fixture
  $crashed = $false
  try {
    & $transitionPath -Transition 'upload-authorized' `
      -StatePath $Fixture.StateRelative -FixtureMode `
      -PrerequisiteGateEvidencePath $proof.Relative `
      -PrerequisiteGateEvidenceSha256 $proof.Sha256 `
      -PrerequisiteGatePhase 'preupload' -Attempt 1 `
      -BrowserEvidencePath $binding.browserEvidencePath `
      -BrowserEvidenceSha256 $binding.browserEvidenceSha256 `
      -BrowserEvidenceBytes $binding.browserEvidenceBytes `
      -BrowserSessionId $binding.browserSessionId `
      -BrowserSessionNonceSha256 $binding.browserSessionNonceSha256 `
      -BrowserEvidenceProducerId $binding.browserEvidenceProducerId `
      -BrowserEvidenceProducedUtc $binding.browserEvidenceProducedUtc `
      -BrowserEvidenceExpiresUtc $binding.browserEvidenceExpiresUtc `
      -SourceManifestPath $binding.sourceManifestPath `
      -SourceManifestSha256 $binding.sourceManifestSha256 `
      -SourceManifestBytes $binding.sourceManifestBytes `
      -BlockerLedgerPath $binding.blockerLedgerPath `
      -BlockerLedgerSha256 $binding.blockerLedgerSha256 `
      -BlockerLedgerBytes $binding.blockerLedgerBytes `
      -LiveBrowserRouteQualified -SignedInMoolSocialAppRouteProved `
      -InternalTestingRouteProved -NoPlayWritePerformed `
      -InjectCrashBoundary $Boundary -RepositoryRoot $root | Out-Null
  } catch {
    $expected = 'C34L fixture injected crash ' + ($Boundary.Replace('-', ' ')) + '.'
    $crashed = $_.Exception.Message -ceq $expected
  }
  Assert-C34LJournal $crashed "browser injected boundary $Boundary did not stop exactly."
  $proof | Add-Member -NotePropertyName PairBefore -NotePropertyValue $pairBefore
  return $proof
}
function Invoke-C34LInjectedTransition(
  [object]$Fixture,
  [string]$Boundary,
  [string]$Transition = 'founder-inputs-validated',
  [string]$Phase = 'preprompt'
) {
  $proof = New-C34LJournalProof $Fixture $Transition $Phase
  $crashed = $false
  try {
    & $transitionPath -Transition $Transition `
      -StatePath $Fixture.StateRelative -FixtureMode `
      -PrerequisiteGateEvidencePath $proof.Relative `
      -PrerequisiteGateEvidenceSha256 $proof.Sha256 `
      -PrerequisiteGatePhase $Phase -InjectCrashBoundary $Boundary `
      -RepositoryRoot $root | Out-Null
  } catch {
    $expected = 'C34L fixture injected crash ' + ($Boundary.Replace('-', ' ')) + '.'
    $crashed = $_.Exception.Message -ceq $expected
  }
  Assert-C34LJournal $crashed "injected boundary $Boundary did not stop exactly."
}
function Invoke-C34LInjectedFinalTransition(
  [object]$Fixture,
  [ValidateSet('upload-succeeded','install-succeeded','device-accepted')]
  [string]$Transition,
  [object]$Evidence,
  [string]$Boundary='after-journal-write'
) {
  $phase = switch ($Transition) {
    'upload-succeeded' { 'postupload' }
    'install-succeeded' { 'postinstall' }
    'device-accepted' { 'journey' }
  }
  $proof = New-C34LJournalProof $Fixture $Transition $phase
  $parameters = @{
    Transition=$Transition;StatePath=$Fixture.StateRelative;FixtureMode=$true
    PrerequisiteGateEvidencePath=$proof.Relative
    PrerequisiteGateEvidenceSha256=$proof.Sha256
    PrerequisiteGatePhase=$phase;Attempt=1;InjectCrashBoundary=$Boundary
    RepositoryRoot=$root
  }
  if ($Transition -ceq 'upload-succeeded') {
    $parameters['EvidencePath']=$Evidence.Play.Relative
    $parameters['EvidenceSha256']=$Evidence.Play.Sha256
    $parameters['EvidenceBytes']=$Evidence.Play.Bytes
  } elseif ($Transition -ceq 'install-succeeded') {
    $parameters['EvidencePath']=$Evidence.Cold.Relative
    $parameters['EvidenceSha256']=$Evidence.Cold.Sha256
    $parameters['EvidenceBytes']=$Evidence.Cold.Bytes
    $parameters['RetainedDataEvidencePath']=$Evidence.Retained.Relative
    $parameters['RetainedDataEvidenceSha256']=$Evidence.Retained.Sha256
    $parameters['RetainedDataEvidenceBytes']=$Evidence.Retained.Bytes
  } else {
    $parameters['EvidencePath']=$Evidence.Journey.Relative
    $parameters['EvidenceSha256']=$Evidence.Journey.Sha256
    $parameters['EvidenceBytes']=$Evidence.Journey.Bytes
  }
  $crashed=$false
  try { & $transitionPath @parameters | Out-Null } catch {
    $expected='C34L fixture injected crash ' + ($Boundary.Replace('-',' ')) + '.'
    $crashed=$_.Exception.Message -ceq $expected
  }
  Assert-C34LJournal $crashed `
    "$Transition injected boundary $Boundary did not stop exactly."
}

function New-C34LJournalFinalReadyFixture(
  [string]$Name,
  [ValidateSet('play','oppo','journey')][string]$Kind
) {
  $fixture=New-C34LJournalFixture $Name
  [void](Invoke-C34LInjectedBrowserTransition $fixture 'after-journal-write')
  Invoke-C34LReconcile $fixture
  if ($Kind -ceq 'play') { return $fixture }
  $play=New-C34LJournalFinalEvidence $fixture play
  Invoke-C34LInjectedFinalTransition $fixture 'upload-succeeded' $play
  Invoke-C34LReconcile $fixture
  Invoke-C34LInjectedTransition $fixture 'after-journal-write' `
    'install-authorized' 'postupload'
  Invoke-C34LReconcile $fixture
  if ($Kind -ceq 'oppo') { return $fixture }
  $oppo=New-C34LJournalFinalEvidence $fixture oppo
  Invoke-C34LInjectedFinalTransition $fixture 'install-succeeded' $oppo
  Invoke-C34LReconcile $fixture
  return $fixture
}
function Invoke-C34LReconcile([object]$Fixture) {
  & $transitionPath -StatePath $Fixture.StateRelative -FixtureMode `
    -ReconcileOnly -RepositoryRoot $root | Out-Null
}

function Get-C34LOnlyJournal([object]$Fixture) {
  $files = @(Get-ChildItem -LiteralPath $Fixture.JournalRoot -Filter '*.json' -File)
  Assert-C34LJournal ($files.Count -eq 1) 'fixture did not retain exactly one journal.'
  return [pscustomobject]@{
    Path=$files[0].FullName
    Value=Get-Content -Raw -LiteralPath $files[0].FullName | ConvertFrom-Json
  }
}
function Get-C34LNewestJournal([object]$Fixture) {
  $rows=@(Get-ChildItem -LiteralPath $Fixture.JournalRoot -Filter '*.json' -File |
    ForEach-Object {
      [pscustomobject]@{
        Path=$_.FullName
        Value=Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json
      }
    } | Sort-Object { [int]$_.Value.sequence })
  Assert-C34LJournal ($rows.Count -gt 0) 'fixture retained no journal rows.'
  return $rows[-1]
}
function Assert-C34LJournalPayload(
  [object]$Fixture,
  [object]$Journal,
  [string]$ExpectedTransition = 'founder-inputs-validated',
  [string]$ExpectedPhase = 'preprompt',
  [object]$ExpectedBrowserBinding = $null
) {
  $value = $Journal.Value
  $expectedProperties = @(
    'schemaVersion', 'contractId', 'ticketId', 'attempt', 'transactionId', 'sequence',
    'transition', 'status', 'statePath', 'aggregateStatePath',
    'prerequisiteGateEvidencePath', 'prerequisiteGateEvidenceSha256',
    'prerequisiteGatePhase', 'browserEvidence',
    'stateBeforeSha256', 'aggregateBeforeSha256', 'stateAfterSha256',
    'aggregateAfterSha256', 'stateBeforeBase64', 'aggregateBeforeBase64',
    'stateAfterBase64', 'aggregateAfterBase64', 'preparedUtc', 'committedUtc',
    'reconciledUtc', 'observedStateSha256', 'observedAggregateSha256'
  )
  $actualProperties = @($value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LJournal (
    (@($actualProperties | Sort-Object) -join ',') -ceq
      (@($expectedProperties | Sort-Object) -join ',')
  ) 'journal property schema is missing, extra or status-dependent.'
  Assert-C34LJournal (
    [string]$value.ticketId -ceq $ticketId -and
    [int]$value.attempt -eq 1 -and
    [int]$value.sequence -gt 0 -and
    [string]$value.transition -ceq $ExpectedTransition -and
    [string]$value.statePath -ceq $Fixture.StateRelative -and
    [string]$value.aggregateStatePath -ceq
      (ConvertTo-C34LJournalRelative $Fixture.AggregatePath) -and
    [string]$value.prerequisiteGatePhase -ceq $ExpectedPhase -and
    [string]$value.prerequisiteGateEvidenceSha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$value.stateBeforeSha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$value.aggregateBeforeSha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$value.stateAfterSha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$value.aggregateAfterSha256 -cmatch '^[0-9A-F]{64}$'
  ) 'journal identity, target, proof or pre/post hash binding changed.'
  if ($null -eq $ExpectedBrowserBinding) {
    Assert-C34LJournal ($null -eq $value.browserEvidence) `
      'non-browser journal retained browser evidence.'
  } else {
    $actualBrowserBinding = ConvertTo-C34LJournalBrowserBinding `
      $value.browserEvidence
    $expectedBrowserBinding = ConvertTo-C34LJournalBrowserBinding `
      $ExpectedBrowserBinding
    Assert-C34LJournal (
      @($actualBrowserBinding.PSObject.Properties).Count -eq 23 -and
      @($expectedBrowserBinding.PSObject.Properties).Count -eq 23 -and
      (ConvertTo-Json -InputObject $actualBrowserBinding -Depth 20 -Compress) -ceq
        (ConvertTo-Json -InputObject $expectedBrowserBinding -Depth 20 -Compress)
    ) 'browser journal exact 23-field binding changed.'
  }
  foreach ($field in @(
    'stateBeforeBase64', 'aggregateBeforeBase64', 'stateAfterBase64',
    'aggregateAfterBase64'
  )) {
    Assert-C34LJournal (-not [string]::IsNullOrWhiteSpace([string]$value.$field)) `
      "journal is missing $field."
  }
  switch ([string]$value.status) {
    'prepared' {
      Assert-C34LJournal (
        [string]::IsNullOrWhiteSpace([string]$value.committedUtc) -and
        [string]::IsNullOrWhiteSpace([string]$value.reconciledUtc) -and
        [string]::IsNullOrWhiteSpace([string]$value.observedStateSha256) -and
        [string]::IsNullOrWhiteSpace([string]$value.observedAggregateSha256)
      ) 'prepared journal populated terminal-only fields.'
    }
    'committed' {
      Assert-C34LJournal (
        -not [string]::IsNullOrWhiteSpace([string]$value.committedUtc) -and
        [string]::IsNullOrWhiteSpace([string]$value.reconciledUtc) -and
        [string]$value.observedStateSha256 -ceq [string]$value.stateAfterSha256 -and
        [string]$value.observedAggregateSha256 -ceq [string]$value.aggregateAfterSha256
      ) 'committed journal terminal fields changed.'
    }
    'reconciled_committed' {
      Assert-C34LJournal (
        [string]::IsNullOrWhiteSpace([string]$value.committedUtc) -and
        -not [string]::IsNullOrWhiteSpace([string]$value.reconciledUtc) -and
        [string]$value.observedStateSha256 -ceq [string]$value.stateAfterSha256 -and
        [string]$value.observedAggregateSha256 -ceq [string]$value.aggregateAfterSha256
      ) 'reconciled journal terminal fields changed.'
    }
    default { Assert-C34LJournal $false 'journal status is not allowed.' }
  }
}
function Assert-C34LExpectedJournalRejection(
  [object]$Fixture, [scriptblock]$Action, [string]$Label
) {
  $pairBefore = Get-C34LJournalPairHash $Fixture
  $journalBefore = Get-C34LJournalFileHash (Get-C34LOnlyJournal $Fixture).Path
  $rejected = $false
  try { & $Action } catch { $rejected = $true }
  $pairAfter = Get-C34LJournalPairHash $Fixture
  $journalAfter = Get-C34LJournalFileHash (Get-C34LOnlyJournal $Fixture).Path
  Assert-C34LJournal (
    $rejected -and $pairAfter -ceq $pairBefore -and $journalAfter -ceq $journalBefore
  ) "$Label did not fail closed without another target or journal write."
}
function Get-C34LJournalSetFingerprint([object]$Fixture) {
  $records = @(Get-ChildItem -LiteralPath $Fixture.JournalRoot -Filter '*.json' -File |
    Sort-Object Name | ForEach-Object {
      $_.Name + ':' + (Get-C34LJournalFileHash $_.FullName)
    })
  return ($records -join '|')
}
function Assert-C34LExpectedJournalSetRejection(
  [object]$Fixture,
  [scriptblock]$Action,
  [string]$Label,
  [string]$ExpectedMessage
) {
  $pairBefore = Get-C34LJournalPairHash $Fixture
  $journalBefore = Get-C34LJournalSetFingerprint $Fixture
  $rejected = $false
  $actualMessage = $null
  try { & $Action } catch {
    $rejected = $true
    $actualMessage = [string]$_.Exception.Message
  }
  Assert-C34LJournal (
    $rejected -and
    [string]$actualMessage -ceq $ExpectedMessage -and
    (Get-C34LJournalPairHash $Fixture) -ceq $pairBefore -and
    (Get-C34LJournalSetFingerprint $Fixture) -ceq $journalBefore
  ) (
    "$Label did not fail with the exact class without changing the journal " +
    "set or targets; actual=$actualMessage"
  )
}
function Assert-C34LExpectedJournalClassRejection(
  [object]$Fixture,
  [scriptblock]$Action,
  [string]$Label,
  [string]$ExpectedPattern
) {
  $pairBefore=Get-C34LJournalPairHash $Fixture
  $journalBefore=Get-C34LJournalSetFingerprint $Fixture
  $message=$null
  try { & $Action } catch { $message=[string]$_.Exception.Message }
  Assert-C34LJournal (
    -not [string]::IsNullOrWhiteSpace($message) -and
    [regex]::IsMatch($message,$ExpectedPattern) -and
    (Get-C34LJournalPairHash $Fixture) -ceq $pairBefore -and
    (Get-C34LJournalSetFingerprint $Fixture) -ceq $journalBefore
  ) "$Label did not fail in the expected class without target or journal writes: $message"
}

function Assert-C34LMissingJournalRejection(
  [object]$Fixture,
  [scriptblock]$Action,
  [string]$Label
) {
  $pairBefore = Get-C34LJournalPairHash $Fixture
  $journalBefore = Get-C34LJournalSetFingerprint $Fixture
  Assert-C34LJournal ([string]::IsNullOrEmpty($journalBefore)) `
    "$Label fixture still retained a journal before the rejection check."
  $actualMessage = $null
  try { & $Action } catch { $actualMessage = [string]$_.Exception.Message }
  Assert-C34LJournal (
    $actualMessage -ceq (
      'C34L lifecycle transaction rejected: transaction journal files are ' +
      'missing for retained lifecycle history.'
    ) -and
    (Get-C34LJournalPairHash $Fixture) -ceq $pairBefore -and
    (Get-C34LJournalSetFingerprint $Fixture) -ceq $journalBefore
  ) (
    "$Label did not reject the missing retained journal history exactly " +
    "without writes; actual=$actualMessage"
  )
}

Assert-C34LJournal (Test-Path -LiteralPath $transitionPath -PathType Leaf) `
  'transition owner is missing.'
$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
  $transitionPath, [ref]$null, [ref]$parseErrors
)
Assert-C34LJournal (@($parseErrors).Count -eq 0) 'transition owner does not parse.'
$transitionSource = Get-Content -Raw -LiteralPath $transitionPath
foreach ($required in @(
  "status = 'prepared'", "status = 'committed'", 'reconciled_committed',
  'stateBeforeSha256', 'aggregateBeforeSha256', 'stateAfterSha256',
  'aggregateAfterSha256', 'ConvertTo-C34LRepositoryRelativePath',
  'browserEvidence', 'browserSessionNonceSha256',
  'sourceManifestPath', 'sourceManifestSha256', 'sourceManifestBytes',
  'blockerLedgerPath', 'blockerLedgerSha256', 'blockerLedgerBytes',
  'transaction journal files are missing for retained lifecycle history.'
)) {
  Assert-C34LJournal ($transitionSource.Contains($required)) `
    "transition journal owner is missing $required."
}
Assert-C34LJournal (
  $transitionSource.IndexOf(
    'freshSessionProof', [StringComparison]::OrdinalIgnoreCase
  ) -lt 0
) 'transition journal owner retained forbidden private freshSessionProof.'

$fixtureBase = Join-Path $root 'tmp/c34l-release-transaction-fixtures'
if (-not (Test-Path -LiteralPath $fixtureBase -PathType Container)) {
  [void](New-Item -ItemType Directory -Path $fixtureBase)
}
$fixtureRunRoot = Join-Path $fixtureBase (
  'journal-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
)
[void](New-Item -ItemType Directory -Path $fixtureRunRoot)

try {
  $boundaries = @(
    'before-journal-write', 'after-journal-write', 'after-detailed-replace',
    'after-aggregate-replace', 'after-journal-commit'
  )
  foreach ($boundary in $boundaries) {
    $fixture = New-C34LJournalFixture $boundary
    $beforePair = Get-C34LJournalPairHash $fixture
    Invoke-C34LInjectedTransition $fixture $boundary
    if ($boundary -ceq 'before-journal-write') {
      Assert-C34LJournal (
        (Get-C34LJournalPairHash $fixture) -ceq $beforePair -and
        -not (Test-Path -LiteralPath $fixture.JournalRoot -PathType Container)
      ) 'before-journal crash changed a target or created a journal.'
      Invoke-C34LReconcile $fixture
      Assert-C34LJournal ((Get-C34LJournalPairHash $fixture) -ceq $beforePair) `
        'before-journal reconciliation changed an unprepared transaction.'
      continue
    }
    $journal = Get-C34LOnlyJournal $fixture
    Assert-C34LJournalPayload $fixture $journal
    if ($boundary -ceq 'after-journal-commit') {
      Assert-C34LJournal ([string]$journal.Value.status -ceq 'committed') `
        'after-commit crash did not retain a committed journal.'
    } else {
      Assert-C34LJournal ([string]$journal.Value.status -ceq 'prepared') `
        "$boundary did not retain a prepared journal."
    }
    Invoke-C34LReconcile $fixture
    $reconciled = Get-C34LOnlyJournal $fixture
    Assert-C34LJournalPayload $fixture $reconciled
    $expectedStatus = if ($boundary -ceq 'after-journal-commit') {
      'committed'
    } else { 'reconciled_committed' }
    Assert-C34LJournal (
      (Get-C34LJournalFileHash $fixture.StatePath) -ceq
        [string]$reconciled.Value.stateAfterSha256 -and
      (Get-C34LJournalFileHash $fixture.AggregatePath) -ceq
        [string]$reconciled.Value.aggregateAfterSha256 -and
      [string]$reconciled.Value.status -ceq $expectedStatus
    ) "$boundary did not reconcile deterministically to the complete postimage."
    $stablePair = Get-C34LJournalPairHash $fixture
    $stableJournal = Get-C34LJournalFileHash $reconciled.Path
    Invoke-C34LReconcile $fixture
    Assert-C34LJournal (
      (Get-C34LJournalPairHash $fixture) -ceq $stablePair -and
      (Get-C34LJournalFileHash $reconciled.Path) -ceq $stableJournal
    ) "$boundary reconciliation was not idempotent."
  }

  foreach ($boundary in $boundaries) {
    $fixture = New-C34LJournalFixture ('browser-' + $boundary)
    $browserProof = Invoke-C34LInjectedBrowserTransition $fixture $boundary
    if ($boundary -ceq 'before-journal-write') {
      Assert-C34LJournal (
        (Get-C34LJournalPairHash $fixture) -ceq $browserProof.PairBefore -and
        -not (Test-Path -LiteralPath $fixture.JournalRoot -PathType Container)
      ) 'browser before-journal crash changed a target or created a journal.'
      Invoke-C34LReconcile $fixture
      Assert-C34LJournal (
        (Get-C34LJournalPairHash $fixture) -ceq $browserProof.PairBefore
      ) 'browser before-journal reconciliation changed an unprepared transaction.'
      continue
    }
    $journal = Get-C34LOnlyJournal $fixture
    Assert-C34LJournalPayload $fixture $journal 'upload-authorized' 'preupload' `
      $browserProof.Binding
    Invoke-C34LReconcile $fixture
    $reconciled = Get-C34LOnlyJournal $fixture
    Assert-C34LJournalPayload $fixture $reconciled 'upload-authorized' 'preupload' `
      $browserProof.Binding
    $expectedStatus = if ($boundary -ceq 'after-journal-commit') {
      'committed'
    } else { 'reconciled_committed' }
    $stateValue = Get-Content -Raw -LiteralPath $fixture.StatePath |
      ConvertFrom-Json
    $aggregateValue = Get-Content -Raw -LiteralPath $fixture.AggregatePath |
      ConvertFrom-Json
    Assert-C34LJournal (
      [string]$reconciled.Value.status -ceq $expectedStatus -and
      [string]$stateValue.presealUploadWorkflow.browserSessionId -ceq
        [string]$browserProof.Binding.browserSessionId -and
      [string]$aggregateValue.presealUploadWorkflow.browserSessionId -ceq
        [string]$browserProof.Binding.browserSessionId -and
      @($stateValue.presealUploadWorkflow.PSObject.Properties).Count -eq 23 -and
      @($aggregateValue.presealUploadWorkflow.PSObject.Properties).Count -eq 23 -and
      [string]$stateValue.presealUploadWorkflow.sourceManifestSha256 -ceq
        [string]$browserProof.Binding.sourceManifestSha256 -and
      [string]$stateValue.presealUploadWorkflow.blockerLedgerSha256 -ceq
        [string]$browserProof.Binding.blockerLedgerSha256 -and
      [string]$stateValue.releaseAuthorities.uploadAndInternalActivation -ceq
        'available_once' -and
      [string]$stateValue.lifecycleTransactionProofs[-1].releaseAuthorities.uploadAndInternalActivation `
        -ceq 'held_postbuild_qualification'
    ) "$boundary browser binding or pre/post authority separation changed."
  }

  $playReconciliation = New-C34LJournalFinalReadyFixture `
    'final-play-prepared-reconciliation' play
  $playReconciliationEvidence = New-C34LJournalFinalEvidence `
    $playReconciliation play
  Invoke-C34LInjectedFinalTransition $playReconciliation `
    'upload-succeeded' $playReconciliationEvidence
  Invoke-C34LReconcile $playReconciliation
  $playReconciledState = Get-Content -Raw `
    -LiteralPath $playReconciliation.StatePath | ConvertFrom-Json
  Assert-C34LJournal (
    [string]$playReconciledState.playResult.evidenceSha256 -ceq
      [string]$playReconciliationEvidence.Play.Sha256 -and
    [int]$playReconciledState.actionCounts.upload -eq 1
  ) 'prepared Play final-evidence journal did not reconcile exactly.'

  $oppoReconciliation = New-C34LJournalFinalReadyFixture `
    'final-oppo-prepared-reconciliation' oppo
  $oppoReconciliationEvidence = New-C34LJournalFinalEvidence `
    $oppoReconciliation oppo
  Invoke-C34LInjectedFinalTransition $oppoReconciliation `
    'install-succeeded' $oppoReconciliationEvidence
  Invoke-C34LReconcile $oppoReconciliation
  $oppoReconciledState = Get-Content -Raw `
    -LiteralPath $oppoReconciliation.StatePath | ConvertFrom-Json
  Assert-C34LJournal (
    [string]$oppoReconciledState.installResult.coldStartEvidenceSha256 -ceq
      [string]$oppoReconciliationEvidence.Cold.Sha256 -and
    [string]$oppoReconciledState.installResult.retainedDataEvidenceSha256 -ceq
      [string]$oppoReconciliationEvidence.Retained.Sha256 -and
    [int]$oppoReconciledState.actionCounts.install -eq 1
  ) 'prepared OPPO final-evidence journal did not reconcile exactly.'

  $journeyReconciliation = New-C34LJournalFinalReadyFixture `
    'final-journey-prepared-reconciliation' journey
  $journeyReconciliationEvidence = New-C34LJournalFinalEvidence `
    $journeyReconciliation journey
  Invoke-C34LInjectedFinalTransition $journeyReconciliation `
    'device-accepted' $journeyReconciliationEvidence
  Invoke-C34LReconcile $journeyReconciliation
  $journeyReconciledState = Get-Content -Raw `
    -LiteralPath $journeyReconciliation.StatePath | ConvertFrom-Json
  Assert-C34LJournal (
    [string]$journeyReconciledState.installResult.journeyEvidenceSha256 -ceq
      [string]$journeyReconciliationEvidence.Journey.Sha256 -and
    [int]$journeyReconciledState.actionCounts.deviceAcceptance -eq 1 -and
    [bool]$journeyReconciledState.installResult.acceptanceSucceeded
  ) 'prepared journey final-evidence journal did not reconcile exactly.'

  $missingFinalAttestation = New-C34LJournalFinalReadyFixture `
    'negative-final-play-missing-attestation' play
  $missingFinalEvidence = New-C34LJournalFinalEvidence `
    $missingFinalAttestation play
  Invoke-C34LInjectedFinalTransition $missingFinalAttestation `
    'upload-succeeded' $missingFinalEvidence
  $missingFinalMovedPath = $missingFinalEvidence.Source.AttestationFile.Path +
    '.fixture-missing'
  Move-Item -LiteralPath $missingFinalEvidence.Source.AttestationFile.Path `
    -Destination $missingFinalMovedPath
  Assert-C34LExpectedJournalClassRejection $missingFinalAttestation {
    Invoke-C34LReconcile $missingFinalAttestation
  } 'prepared Play journal missing attestation' 'source attestation is missing[.]'

  $tamperedFinalCapture = New-C34LJournalFinalReadyFixture `
    'negative-final-play-tampered-capture' play
  $tamperedFinalEvidence = New-C34LJournalFinalEvidence `
    $tamperedFinalCapture play
  Invoke-C34LInjectedFinalTransition $tamperedFinalCapture `
    'upload-succeeded' $tamperedFinalEvidence
  $tamperedFinalArtifactPath = Join-Path $root (
    [string]$tamperedFinalEvidence.Source.CaptureArtifacts[0].path
  ).Replace('/','\')
  [IO.File]::AppendAllText(
    $tamperedFinalArtifactPath,[Environment]::NewLine,$utf8
  )
  Assert-C34LExpectedJournalClassRejection $tamperedFinalCapture {
    Invoke-C34LReconcile $tamperedFinalCapture
  } 'prepared Play journal tampered capture artifact' `
    'capture artifact .* SHA-256 or byte-length binding changed'

  $wrongNewestProof = New-C34LJournalFinalReadyFixture `
    'negative-final-play-newest-proof-path' play
  $wrongNewestProofEvidence = New-C34LJournalFinalEvidence `
    $wrongNewestProof play
  Invoke-C34LInjectedFinalTransition $wrongNewestProof `
    'upload-succeeded' $wrongNewestProofEvidence
  $wrongNewestJournal = Get-C34LNewestJournal $wrongNewestProof
  $wrongNewestRaw = Get-Content -Raw -LiteralPath $wrongNewestJournal.Path
  $wrongNewestState = $utf8.GetString([Convert]::FromBase64String(
    [string]$wrongNewestJournal.Value.stateAfterBase64
  )) | ConvertFrom-Json
  $wrongNewestAggregate = $utf8.GetString([Convert]::FromBase64String(
    [string]$wrongNewestJournal.Value.aggregateAfterBase64
  )) | ConvertFrom-Json
  $wrongNewestState.lifecycleTransactionProofs[-1].evidencePath =
    'tmp/c34l-wrong-newest-proof-path.json'
  $wrongNewestAggregate.lifecycleTransactionProofs[-1].evidencePath =
    'tmp/c34l-wrong-newest-proof-path.json'
  $wrongNewestStateBytes = $utf8.GetBytes(
    (($wrongNewestState | ConvertTo-Json -Depth 60) + [Environment]::NewLine)
  )
  $wrongNewestAggregateBytes = $utf8.GetBytes(
    (($wrongNewestAggregate | ConvertTo-Json -Depth 60) + [Environment]::NewLine)
  )
  $wrongNewestReplacements = [ordered]@{
    ([string]$wrongNewestJournal.Value.stateAfterBase64)=
      [Convert]::ToBase64String($wrongNewestStateBytes)
    ([string]$wrongNewestJournal.Value.aggregateAfterBase64)=
      [Convert]::ToBase64String($wrongNewestAggregateBytes)
    ([string]$wrongNewestJournal.Value.stateAfterSha256)=
      (Get-C34LJournalBytesHash $wrongNewestStateBytes)
    ([string]$wrongNewestJournal.Value.aggregateAfterSha256)=
      (Get-C34LJournalBytesHash $wrongNewestAggregateBytes)
  }
  foreach($oldValue in $wrongNewestReplacements.Keys){
    Assert-C34LJournal (
      [regex]::Matches($wrongNewestRaw,[regex]::Escape($oldValue)).Count -eq 1
    ) 'newest-proof fixture journal token was not singular.'
    $wrongNewestRaw=$wrongNewestRaw.Replace(
      $oldValue,[string]$wrongNewestReplacements[$oldValue]
    )
  }
  [IO.File]::WriteAllText($wrongNewestJournal.Path,$wrongNewestRaw,$utf8)
  Assert-C34LExpectedJournalClassRejection $wrongNewestProof {
    Invoke-C34LReconcile $wrongNewestProof
  } 'prepared Play journal newest proof evidencePath' `
    'newest lifecycle proof record does not match the journal tuple'

  $unrelatedTarget = New-C34LJournalFixture 'negative-unrelated-target'
  Invoke-C34LInjectedTransition $unrelatedTarget 'after-journal-write'
  $unrelatedState = Get-Content -Raw -LiteralPath $unrelatedTarget.StatePath |
    ConvertFrom-Json
  $unrelatedState | Add-Member -NotePropertyName unrelatedMutation -NotePropertyValue $true
  Write-C34LJournalJson $unrelatedTarget.StatePath $unrelatedState
  Assert-C34LExpectedJournalRejection $unrelatedTarget {
    Invoke-C34LReconcile $unrelatedTarget
  } 'unrelated target hash'

  $terminalTamper = New-C34LJournalFixture 'negative-terminal-target-tamper'
  Invoke-C34LInjectedTransition $terminalTamper 'after-journal-commit'
  $terminalJournal = Get-C34LOnlyJournal $terminalTamper
  [IO.File]::WriteAllBytes(
    $terminalTamper.StatePath,
    [Convert]::FromBase64String([string]$terminalJournal.Value.stateBeforeBase64)
  )
  Assert-C34LExpectedJournalRejection $terminalTamper {
    Invoke-C34LReconcile $terminalTamper
  } 'committed target tamper'

  $missingProof = New-C34LJournalFixture 'negative-missing-prerequisite-proof'
  Invoke-C34LInjectedTransition $missingProof 'after-journal-write'
  $missingProofJournal = Get-C34LOnlyJournal $missingProof
  $missingProofPath = [IO.Path]::GetFullPath((Join-Path $root `
    ([string]$missingProofJournal.Value.prerequisiteGateEvidencePath)))
  $missingProofPrefix = [IO.Path]::GetFullPath($missingProof.Directory).TrimEnd(
    [char[]]@('\', '/')
  ) + [IO.Path]::DirectorySeparatorChar
  Assert-C34LJournal (
    $missingProofPath.StartsWith(
      $missingProofPrefix, [StringComparison]::OrdinalIgnoreCase
    ) -and (Test-Path -LiteralPath $missingProofPath -PathType Leaf)
  ) 'missing-proof fixture owner was not confined before deletion.'
  Remove-Item -LiteralPath $missingProofPath -Force
  Assert-C34LExpectedJournalRejection $missingProof {
    Invoke-C34LReconcile $missingProof
  } 'missing prerequisite proof owner'

  $tamperedProof = New-C34LJournalFixture 'negative-tampered-prerequisite-proof'
  Invoke-C34LInjectedTransition $tamperedProof 'after-journal-write'
  $tamperedProofJournal = Get-C34LOnlyJournal $tamperedProof
  $tamperedProofPath = [IO.Path]::GetFullPath((Join-Path $root `
    ([string]$tamperedProofJournal.Value.prerequisiteGateEvidencePath)))
  $tamperedProofPrefix = [IO.Path]::GetFullPath($tamperedProof.Directory).TrimEnd(
    [char[]]@('\', '/')
  ) + [IO.Path]::DirectorySeparatorChar
  Assert-C34LJournal ($tamperedProofPath.StartsWith(
    $tamperedProofPrefix, [StringComparison]::OrdinalIgnoreCase
  )) 'tampered-proof fixture owner escaped its exact fixture directory.'
  $tamperedProofValue = Get-Content -Raw -LiteralPath $tamperedProofPath |
    ConvertFrom-Json
  $tamperedProofValue.passed = $false
  Write-C34LJournalJson $tamperedProofPath $tamperedProofValue
  Assert-C34LExpectedJournalRejection $tamperedProof {
    Invoke-C34LReconcile $tamperedProof
  } 'tampered prerequisite proof owner'

  $tamperedBrowser = New-C34LJournalFixture `
    'negative-tampered-browser-evidence'
  $tamperedBrowserProof = Invoke-C34LInjectedBrowserTransition `
    $tamperedBrowser 'after-journal-write'
  [IO.File]::AppendAllText(
    $tamperedBrowserProof.BrowserPath,
    [Environment]::NewLine,
    $utf8
  )
  Assert-C34LExpectedJournalRejection $tamperedBrowser {
    Invoke-C34LReconcile $tamperedBrowser
  } 'tampered retained browser evidence owner'

  $tamperedBrowserJournal = New-C34LJournalFixture `
    'negative-tampered-browser-journal-binding'
  [void](Invoke-C34LInjectedBrowserTransition `
    $tamperedBrowserJournal 'after-journal-write')
  $browserJournal = Get-C34LOnlyJournal $tamperedBrowserJournal
  $browserJournal.Value.browserEvidence.browserSessionId =
    'c34l-browser-session-' + [Guid]::NewGuid().ToString('N')
  Write-C34LCanonicalJournalMutation $browserJournal.Path $browserJournal.Value
  Assert-C34LExpectedJournalRejection $tamperedBrowserJournal {
    Invoke-C34LReconcile $tamperedBrowserJournal
  } 'tampered journal browser binding'

  $semanticTamper = New-C34LJournalFixture 'negative-semantic-journal-metadata'
  Invoke-C34LInjectedTransition $semanticTamper 'after-journal-write'
  $semanticJournal = Get-C34LOnlyJournal $semanticTamper
  $semanticJournal.Value.attempt = 2
  Write-C34LCanonicalJournalMutation $semanticJournal.Path $semanticJournal.Value
  Assert-C34LExpectedJournalRejection $semanticTamper {
    Invoke-C34LReconcile $semanticTamper
  } 'semantic journal attempt metadata tamper'

  $utcWireTamper = New-C34LJournalFixture 'negative-prepared-utc-wire'
  Invoke-C34LInjectedTransition $utcWireTamper 'after-journal-write'
  $utcWireJournal = Get-C34LOnlyJournal $utcWireTamper
  $canonicalPreparedUtc = ConvertTo-C34LJournalUtc `
    $utcWireJournal.Value.preparedUtc
  $utcWireRaw = [IO.File]::ReadAllText($utcWireJournal.Path)
  $canonicalPreparedPattern = '"preparedUtc"\s*:\s*"' +
    [regex]::Escape($canonicalPreparedUtc) + '"'
  Assert-C34LJournal (
    [regex]::Matches($utcWireRaw,$canonicalPreparedPattern).Count -eq 1
  ) 'preparedUtc UTC-wire negative token was not singular.'
  $canonicalPreparedProperty =
    '"preparedUtc": "' + $canonicalPreparedUtc + '"'
  $utcWireRaw = [regex]::Replace(
    $utcWireRaw,$canonicalPreparedPattern,
    $canonicalPreparedProperty + ',' + [Environment]::NewLine +
      '  ' + $canonicalPreparedProperty,
    [Text.RegularExpressions.RegexOptions]::None,[TimeSpan]::FromSeconds(1)
  )
  Assert-C34LJournal (
    [regex]::Matches($utcWireRaw,$canonicalPreparedPattern).Count -eq 2
  ) 'preparedUtc UTC-wire negative did not retain two canonical raw tokens.'
  [IO.File]::WriteAllText($utcWireJournal.Path,$utcWireRaw,$utf8)
  Assert-C34LExpectedJournalSetRejection $utcWireTamper {
    Invoke-C34LReconcile $utcWireTamper
  } 'preparedUtc raw JSON token cardinality' (
    'C34L lifecycle transaction rejected: transaction preparedUtc raw JSON ' +
    'wire token changed.'
  )

  $sequenceGap = New-C34LJournalFixture 'negative-sequence-gap'
  Invoke-C34LInjectedTransition $sequenceGap 'after-journal-write'
  $gapJournal = Get-C34LOnlyJournal $sequenceGap
  $gapJournal.Value.sequence = 2
  Write-C34LCanonicalJournalMutation $gapJournal.Path $gapJournal.Value
  Assert-C34LExpectedJournalSetRejection $sequenceGap {
    Invoke-C34LReconcile $sequenceGap
  } 'journal sequence gap' (
    'C34L lifecycle transaction rejected: transaction journal sequence has a gap.'
  )

  $duplicateSequence = New-C34LJournalFixture 'negative-duplicate-sequence'
  Invoke-C34LInjectedTransition $duplicateSequence 'after-journal-write'
  $duplicateFirst = Get-C34LOnlyJournal $duplicateSequence
  $duplicateSecond = ($duplicateFirst.Value | ConvertTo-Json -Depth 60) |
    ConvertFrom-Json
  $duplicateSecond.transactionId = [Guid]::NewGuid().ToString('N')
  $duplicatePath = Join-Path $duplicateSequence.JournalRoot (
    'transaction-' + [string]$duplicateSecond.transactionId + '.json'
  )
  Write-C34LCanonicalJournalMutation $duplicatePath $duplicateSecond
  Assert-C34LExpectedJournalSetRejection $duplicateSequence {
    Invoke-C34LReconcile $duplicateSequence
  } 'duplicate journal sequence identity' (
    'C34L lifecycle transaction rejected: transaction journal has ' +
    'duplicate sequence or transaction identity.'
  )

  $forkedChain = New-C34LJournalFixture 'negative-forked-chain'
  Invoke-C34LInjectedTransition $forkedChain 'after-journal-commit'
  $forkFirst = Get-C34LOnlyJournal $forkedChain
  $forkSecond = ($forkFirst.Value | ConvertTo-Json -Depth 60) | ConvertFrom-Json
  $forkSecond.transactionId = [Guid]::NewGuid().ToString('N')
  $forkSecond.sequence = 2
  $forkSecond.status = 'prepared'
  $forkSecond.preparedUtc = ConvertTo-C34LJournalUtc ([DateTimeOffset]::UtcNow)
  $forkSecond.committedUtc = $null
  $forkSecond.reconciledUtc = $null
  $forkSecond.observedStateSha256 = $null
  $forkSecond.observedAggregateSha256 = $null
  $forkPath = Join-Path $forkedChain.JournalRoot (
    'transaction-' + [string]$forkSecond.transactionId + '.json'
  )
  Write-C34LCanonicalJournalMutation $forkPath $forkSecond
  Assert-C34LExpectedJournalSetRejection $forkedChain {
    Invoke-C34LReconcile $forkedChain
  } 'forked journal preimage chain' (
    'C34L lifecycle transaction rejected: transaction journal chain has a fork ' +
    'or preimage gap.'
  )

  $olderNonterminal = New-C34LJournalFixture 'negative-older-nonterminal'
  Invoke-C34LInjectedTransition $olderNonterminal 'after-journal-commit'
  Invoke-C34LInjectedTransition `
    $olderNonterminal 'after-journal-commit' 'build-start' 'build'
  $olderRows = @(Get-ChildItem -LiteralPath $olderNonterminal.JournalRoot `
    -Filter '*.json' -File | ForEach-Object {
      [pscustomobject]@{
        Path=$_.FullName
        Value=Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json
      }
    } | Sort-Object { [int]$_.Value.sequence })
  Assert-C34LJournal ($olderRows.Count -eq 2) `
    'older-nonterminal fixture did not retain two lawful chained journals.'
  $olderRows[0].Value.status = 'prepared'
  $olderRows[0].Value.committedUtc = $null
  $olderRows[0].Value.reconciledUtc = $null
  $olderRows[0].Value.observedStateSha256 = $null
  $olderRows[0].Value.observedAggregateSha256 = $null
  Write-C34LCanonicalJournalMutation $olderRows[0].Path $olderRows[0].Value
  Assert-C34LExpectedJournalSetRejection $olderNonterminal {
    Invoke-C34LReconcile $olderNonterminal
  } 'older unreconciled nonterminal' (
    'C34L lifecycle transaction rejected: transaction journal has an ' +
    'unreconciled nonterminal before the chain head.'
  )

  $missingAllReconcile = New-C34LJournalFixture `
    'negative-missing-all-journals-reconcile'
  Invoke-C34LInjectedTransition $missingAllReconcile 'after-journal-commit'
  $missingAllReconcileJournal = Get-C34LOnlyJournal $missingAllReconcile
  $missingAllReconcilePrefix = [IO.Path]::GetFullPath(
    $missingAllReconcile.JournalRoot
  ).TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
  Assert-C34LJournal (
    [IO.Path]::GetFullPath($missingAllReconcileJournal.Path).StartsWith(
      $missingAllReconcilePrefix, [StringComparison]::OrdinalIgnoreCase
    )
  ) 'missing-all reconcile fixture journal escaped its exact journal root.'
  [IO.File]::Delete($missingAllReconcileJournal.Path)
  Assert-C34LMissingJournalRejection $missingAllReconcile {
    Invoke-C34LReconcile $missingAllReconcile
  } 'deleted-all journal reconciliation'

  $missingAllAppend = New-C34LJournalFixture `
    'negative-missing-all-journals-append'
  Invoke-C34LInjectedTransition $missingAllAppend 'after-journal-commit'
  $missingAllAppendJournal = Get-C34LOnlyJournal $missingAllAppend
  $missingAllAppendPrefix = [IO.Path]::GetFullPath(
    $missingAllAppend.JournalRoot
  ).TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
  Assert-C34LJournal (
    [IO.Path]::GetFullPath($missingAllAppendJournal.Path).StartsWith(
      $missingAllAppendPrefix, [StringComparison]::OrdinalIgnoreCase
    )
  ) 'missing-all append fixture journal escaped its exact journal root.'
  [IO.File]::Delete($missingAllAppendJournal.Path)
  $missingAllAppendProof = New-C34LJournalProof $missingAllAppend
  Assert-C34LMissingJournalRejection $missingAllAppend {
    & $transitionPath -Transition 'founder-inputs-validated' `
      -StatePath $missingAllAppend.StateRelative -FixtureMode `
      -PrerequisiteGateEvidencePath $missingAllAppendProof.Relative `
      -PrerequisiteGateEvidenceSha256 $missingAllAppendProof.Sha256 `
      -PrerequisiteGatePhase 'preprompt' -RepositoryRoot $root | Out-Null
  } 'deleted-all journal sequence reset attempt'

  Write-Output (
    'C34L transaction journal fixture passed: crashBoundaries=10; ' +
    'browserCrashBoundaries=5; preparedReconciliations=9; committedRecovery=2; ' +
    'beforeJournalNoop=2; idempotentReplay=5; tamperRejections=10; ' +
    'prerequisiteProofRejections=2; browserBindingTamperRejections=2; ' +
    'semanticJournalTamperRejections=1; utcWireRejections=1; chainRejections=4; ' +
    'missingAllJournalHistoryRejections=2; finalEvidenceReconciliations=3; ' +
    'finalEvidenceReconcileRejections=3; ' +
    'gapsForksDuplicatesAndNonterminalHistory=failClosed; proofHashes=bound; ' +
    "hostPowerShellMajor=$($PSVersionTable.PSVersion.Major); realStateWrites=0; " +
    'externalWrites=0.'
  )
} finally {
  if (Test-Path -LiteralPath $fixtureRunRoot -PathType Container) {
    $resolved = [IO.Path]::GetFullPath($fixtureRunRoot)
    $expectedPrefix = [IO.Path]::GetFullPath(
      (Join-Path $root 'tmp/c34l-release-transaction-fixtures/journal-')
    )
    Assert-C34LJournal ($resolved.StartsWith(
      $expectedPrefix, [StringComparison]::OrdinalIgnoreCase
    )) 'journal cleanup target escaped its unique fixture prefix.'
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}
