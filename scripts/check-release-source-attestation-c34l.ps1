[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$ticketId =
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE'
$packageName = 'com.moolsocial.app'
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
$writer = Join-Path $root 'scripts/write-release-source-attestation-c34l.ps1'
$playWriter = Join-Path $root 'scripts/write-release-play-evidence-c34l.ps1'
$journeyWriter = Join-Path $root 'scripts/write-release-journey-evidence-c34l.ps1'
$fixtureRoots = [Collections.Generic.List[string]]::new()

function Assert-C34LAttestationFixture([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C34L source-attestation fixture rejected: $Message" }
}
function Write-C34LText([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  [IO.File]::WriteAllText($Path, $Text, $utf8)
}
function Write-C34LJson([string]$Path, $Value) {
  Write-C34LText $Path (($Value | ConvertTo-Json -Depth 30) +
    [Environment]::NewLine)
}
function Get-C34LSha([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}
function New-C34LCounts([int]$Build, [int]$Upload, [int]$Install) {
  return [pscustomobject][ordered]@{
    build=$Build; upload=$Upload; install=$Install; deviceAcceptance=0
    passwordlessEmailSend=0; realSmsSend=0; otherTrack=0
    backendHostingProviderOrProductionDeployment=0
  }
}
function New-C34LAuthorities(
  [string]$Build,
  [string]$Upload,
  [string]$Install
) {
  return [pscustomobject][ordered]@{
    build=$Build; uploadAndInternalActivation=$Upload
    inPlaceOppoPlayUpdate=$Install
    postinstallAcceptance='held_postinstall_journey_qualification'
  }
}
function Get-C34LSpec([string]$Type) {
  switch ($Type) {
    'play_internal_testing_activation' {
      return [pscustomobject]@{
        Short='play'; Producer='MOOLSOCIAL-C34L-PLAY-CAPTURE-PRODUCER-001'
        Counts=(New-C34LCounts 1 0 0)
        Authorities=(New-C34LAuthorities 'consumed' 'available_once' `
          'held_postupload_qualification')
        Machine='postbuild_qualified_internal_testing_upload_authority_available_once'
        Digests=$null
      }
    }
    'oppo_play_in_place_update_pair' {
      return [pscustomobject]@{
        Short='oppo'; Producer='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
        Counts=(New-C34LCounts 1 1 0)
        Authorities=(New-C34LAuthorities 'consumed' 'consumed' 'available_once')
        Machine='postupload_qualified_in_place_oppo_play_update_authority_available_once'
        Digests=$null
      }
    }
    'mandatory_whole_app_journey_acceptance' {
      return [pscustomobject]@{
        Short='journey'
        Producer='MOOLSOCIAL-C34L-JOURNEY-CAPTURE-PRODUCER-001'
        Counts=(New-C34LCounts 1 1 1)
        Authorities=(New-C34LAuthorities 'consumed' 'consumed' 'consumed')
        Machine='oppo_play_in_place_update_succeeded_postinstall_acceptance_held'
        Digests=$null
      }
    }
  }
}
function New-C34LFixture(
  [string]$Type,
  [switch]$ReparseAttestationDirectory
) {
  $spec = Get-C34LSpec $Type
  $name = 'c34l-retained-evidence-fixtures-' + [Guid]::NewGuid().ToString('N')
  $relative = "tmp/$name"
  $fixtureRoot = Join-Path $root $relative
  $evidenceRelative = "$relative/evidence"
  $evidenceRoot = Join-Path $root $evidenceRelative
  [void](New-Item -ItemType Directory -Path $evidenceRoot -Force)
  [void]$fixtureRoots.Add($fixtureRoot)
  $attestationDirectory = Join-Path $evidenceRoot 'attestations'
  [void](New-Item -ItemType Directory -Path $attestationDirectory -Force)
  $captureAttemptDirectory = Join-Path $evidenceRoot 'captures/attempt-1'
  [void](New-Item -ItemType Directory -Path $captureAttemptDirectory -Force)
  $captureKindDirectory = Join-Path $captureAttemptDirectory $spec.Short
  $junctionPath = $null
  if ($ReparseAttestationDirectory) {
    $target = Join-Path $fixtureRoot 'capture-target'
    [void](New-Item -ItemType Directory -Path $target -Force)
    [void](New-Item -ItemType Junction -Path $captureKindDirectory -Target $target)
    $junctionPath = $captureKindDirectory
  } else {
    [void](New-Item -ItemType Directory -Path $captureKindDirectory -Force)
  }
  $artifactRelative =
    "$evidenceRelative/MoolSocial-$versionName-$versionCode-release.aab"
  $artifactPath = Join-Path $root $artifactRelative
  Write-C34LText $artifactPath 'C34L attestation fixture artifact bytes'
  $artifactSha = Get-C34LSha $artifactPath
  $artifactBytes = (Get-Item -LiteralPath $artifactPath).Length
  $candidate = [pscustomobject][ordered]@{
    id=$ticketId; packageName=$packageName; versionName=$versionName
    versionCode=$versionCode; playTrack='internal'
    deviceBindingSha256=$deviceBindingSha256
    deviceModel='CPH2375'; disposition='fixture'; artifactReusable=$true
    buildCount=[int]$spec.Counts.build; uploadCount=[int]$spec.Counts.upload
    installCount=[int]$spec.Counts.install; deviceAcceptanceCount=0
  }
  $aggregateRelative = "$relative/aggregate.json"
  $aggregatePath = Join-Path $root $aggregateRelative
  $aggregate = [pscustomobject][ordered]@{
    ticketId=$ticketId; candidate=$candidate; machineState=$spec.Machine
    actionCounts=$spec.Counts; releaseAuthorities=$spec.Authorities
    lifecycleTransactionProofs=@()
  }
  Write-C34LJson $aggregatePath $aggregate
  $stateRelative = "$relative/state.json"
  $statePath = Join-Path $root $stateRelative
  $state = [pscustomobject][ordered]@{
    ticketId=$ticketId; candidate=$candidate; aggregateStatePath=$aggregateRelative
    machineState=$spec.Machine; evidenceRoot=$evidenceRelative
    buildResult=[pscustomobject][ordered]@{
      artifactPath=$artifactRelative; artifactSha256=$artifactSha
      artifactBytes=$artifactBytes
    }
    actionCounts=$spec.Counts; releaseAuthorities=$spec.Authorities
  }
  Write-C34LJson $statePath $state
  $sessionId = 'fixture-session-' + [Guid]::NewGuid().ToString('N')
  $nonceSha256 = 'D' * 64
  $captureArtifacts = @()
  if ($spec.Short -ceq 'play') {
    $receiptRelative =
      "$evidenceRelative/captures/attempt-1/play/internal-testing-release-receipt.json"
    $receiptPath = Join-Path $root $receiptRelative
    Write-C34LJson $receiptPath ([pscustomobject][ordered]@{
      schemaVersion=1; captureRole='internal_testing_release_receipt'
      ticketId=$ticketId; attempt=1; packageName=$packageName
      versionName=$versionName; versionCode=$versionCode
      artifactSha256=$artifactSha; artifactBytes=$artifactBytes
      track='internal'; uploadCount=1; otherTrackChanged=$false
      sourceProducerId=$spec.Producer; sessionId=$sessionId
      nonceSha256=$nonceSha256
    })
    $statusRelative =
      "$evidenceRelative/captures/attempt-1/play/internal-testing-status-observation.json"
    $statusPath = Join-Path $root $statusRelative
    Write-C34LJson $statusPath ([pscustomobject][ordered]@{
      schemaVersion=1; captureRole='internal_testing_status_observation'
      ticketId=$ticketId; attempt=1; packageName=$packageName
      versionName=$versionName; versionCode=$versionCode
      artifactSha256=$artifactSha; artifactBytes=$artifactBytes
      track='internal'; internalReleaseActive=$true; internalActivationCount=1
      sourceProducerId=$spec.Producer; sessionId=$sessionId
      nonceSha256=$nonceSha256
    })
    $receiptSha = Get-C34LSha $receiptPath
    $statusSha = Get-C34LSha $statusPath
    $captureArtifacts = @(
      [pscustomobject][ordered]@{role='internal_testing_release_receipt';path=$receiptRelative;sha256=$receiptSha;bytes=(Get-Item -LiteralPath $receiptPath).Length;mediaType='application/json'},
      [pscustomobject][ordered]@{role='internal_testing_status_observation';path=$statusRelative;sha256=$statusSha;bytes=(Get-Item -LiteralPath $statusPath).Length;mediaType='application/json'}
    )
    $spec.Digests = [pscustomobject][ordered]@{
      internalTestingRouteDigestSha256=$receiptSha
      uploadReceiptDigestSha256=$receiptSha
      activationStateDigestSha256=$statusSha
    }
  } elseif ($spec.Short -ceq 'oppo') {
    $coldRelative =
      "$evidenceRelative/captures/attempt-1/oppo/cold-start-observation.json"
    $coldPath = Join-Path $root $coldRelative
    Write-C34LJson $coldPath ([pscustomobject][ordered]@{
      schemaVersion=1; captureRole='cold_start_observation'; ticketId=$ticketId
      attempt=1; packageName=$packageName; versionName=$versionName
      versionCode=$versionCode; artifactSha256=$artifactSha
      artifactBytes=$artifactBytes; deviceBindingSha256=$deviceBindingSha256
      deviceModel='CPH2375'; installerPackage='com.android.vending'
      sourceProducerId=$spec.Producer; sessionId=$sessionId
      nonceSha256=$nonceSha256; coldStartInteractive=$true
    })
    $retainedRelative =
      "$evidenceRelative/captures/attempt-1/oppo/retained-state-observation.json"
    $retainedPath = Join-Path $root $retainedRelative
    Write-C34LJson $retainedPath ([pscustomobject][ordered]@{
      schemaVersion=1; captureRole='retained_state_observation'; ticketId=$ticketId
      attempt=1; packageName=$packageName; versionName=$versionName
      versionCode=$versionCode; artifactSha256=$artifactSha
      artifactBytes=$artifactBytes; deviceBindingSha256=$deviceBindingSha256
      deviceModel='CPH2375'; installerPackage='com.android.vending'
      sourceProducerId=$spec.Producer; sessionId=$sessionId
      nonceSha256=$nonceSha256; retainedDataContinuityProved=$true
    })
    $coldSha = Get-C34LSha $coldPath
    $retainedSha = Get-C34LSha $retainedPath
    $captureArtifacts = @(
      [pscustomobject][ordered]@{role='cold_start_observation';path=$coldRelative;sha256=$coldSha;bytes=(Get-Item -LiteralPath $coldPath).Length;mediaType='application/json'},
      [pscustomobject][ordered]@{role='retained_state_observation';path=$retainedRelative;sha256=$retainedSha;bytes=(Get-Item -LiteralPath $retainedPath).Length;mediaType='application/json'}
    )
    $spec.Digests = [pscustomobject][ordered]@{
      packageStateDigestSha256=$coldSha; coldStartDigestSha256=$coldSha
      retainedDataDigestSha256=$retainedSha
    }
  } else {
    $journeyRows = @()
    foreach ($journeyId in @(
      'publicGuest','protectedGateway','supportedAuthentication','social',
      'wholeApp','c33gBlocker'
    )) {
      $journeyRelative =
        "$evidenceRelative/captures/attempt-1/journey/journeys/$journeyId.json"
      $journeyPath = Join-Path $root $journeyRelative
      Write-C34LJson $journeyPath ([pscustomobject][ordered]@{
        schemaVersion=1; journeyId=$journeyId; ticketId=$ticketId; attempt=1
        packageName=$packageName; versionName=$versionName; versionCode=$versionCode
        artifactSha256=$artifactSha; artifactBytes=$artifactBytes
        deviceBindingSha256=$deviceBindingSha256; passed=$true
        newIssueCount=0; newDefectCount=0; blankScreenCount=0
        flutterFatalErrorCount=0; androidRuntimeFatalCount=0; anrCount=0
        sourceProducerId=$spec.Producer; sessionId=$sessionId
        nonceSha256=$nonceSha256
      })
      $journeySha = Get-C34LSha $journeyPath
      $journeyRows += [pscustomobject][ordered]@{
        journeyId=$journeyId; path=$journeyRelative; sha256=$journeySha
        bytes=(Get-Item -LiteralPath $journeyPath).Length; passed=$true
      }
    }
    $journeyManifestRelative =
      "$evidenceRelative/captures/attempt-1/journey/journey-acceptance-manifest.json"
    $journeyManifestPath = Join-Path $root $journeyManifestRelative
    Write-C34LJson $journeyManifestPath $journeyRows
    $journeyManifestSha = Get-C34LSha $journeyManifestPath
    $captureArtifacts = @([pscustomobject][ordered]@{
      role='journey_acceptance_manifest'; path=$journeyManifestRelative
      sha256=$journeyManifestSha
      bytes=(Get-Item -LiteralPath $journeyManifestPath).Length
      mediaType='application/json'
    })
    $spec.Digests = [pscustomobject][ordered]@{}
    foreach ($row in $journeyRows) {
      $spec.Digests | Add-Member -NotePropertyName `
        ([string]$row.journeyId + 'DigestSha256') -NotePropertyValue `
        ([string]$row.sha256)
    }
  }
  $captureRelative =
    "$evidenceRelative/captures/attempt-1/$($spec.Short)/capture-manifest.json"
  $capturePath = Join-Path $root $captureRelative
  $now = [DateTimeOffset]::UtcNow
  $format = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
  $capture = [pscustomobject][ordered]@{
    schemaVersion=1
    captureContractId='MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001'
    evidenceType=$Type; ticketId=$ticketId; attempt=1; packageName=$packageName
    versionName=$versionName; versionCode=$versionCode
    preStateSha256=(Get-C34LSha $statePath)
    preAggregateSha256=(Get-C34LSha $aggregatePath)
    actionCounts=$spec.Counts; releaseAuthorities=$spec.Authorities
    artifactSha256=$artifactSha; artifactBytes=$artifactBytes
    sourceProducerId=$spec.Producer
    sessionId=$sessionId; nonceSha256=$nonceSha256
    producedUtc=$now.AddSeconds(-1).ToString($format,
      [Globalization.CultureInfo]::InvariantCulture)
    expiresUtc=$now.AddMinutes(10).ToString($format,
      [Globalization.CultureInfo]::InvariantCulture)
    captureDigests=$spec.Digests
    captureArtifactContractPath=$captureArtifactContractPath
    captureArtifactContractSha256=$captureArtifactContractSha256
    captureArtifactContractId=$captureArtifactContractId
    captureArtifacts=$captureArtifacts
  }
  Write-C34LJson $capturePath $capture
  return [pscustomobject]@{
    Spec=$spec; Root=$fixtureRoot; Relative=$relative
    EvidenceRelative=$evidenceRelative; StatePath=$statePath
    StateRelative=$stateRelative; AggregatePath=$aggregatePath
    ArtifactPath=$artifactPath; CapturePath=$capturePath
    CaptureRelative=$captureRelative; Capture=$capture
    CaptureArtifacts=$captureArtifacts; Junction=$junctionPath
  }
}
function Get-C34LAttestationArguments($Fixture) {
  return @{
    EvidenceType=[string]$Fixture.Capture.evidenceType; Attempt=1
    StatePath=$Fixture.StateRelative; CaptureManifestPath=$Fixture.CaptureRelative
    CaptureManifestSha256=(Get-C34LSha $Fixture.CapturePath)
    CaptureManifestBytes=(Get-Item -LiteralPath $Fixture.CapturePath).Length
    FixtureMode=$true; RepositoryRoot=$root
  }
}
function Invoke-C34LAttestation($Fixture) {
  $writerParameters = Get-C34LAttestationArguments $Fixture
  $output = @(& $writer @writerParameters)
  Assert-C34LAttestationFixture ($output.Count -eq 1) `
    'attestation writer did not emit one sanitized result.'
  return ([string]$output[0] | ConvertFrom-Json)
}
function Assert-C34LExpectedRejection(
  [string]$Owner,
  [hashtable]$Arguments,
  [string]$Expected,
  [string]$Label
) {
  $rejected = $false
  $observed = ''
  try { & $Owner @Arguments | Out-Null } catch {
    $rejected = $true
    $observed = $_.Exception.Message
  }
  Assert-C34LAttestationFixture (
    $rejected -and $observed.Contains($Expected)
  ) "$Label did not reach the exact expected rejection."
}
function Rewrite-C34LCapture($Fixture, $Capture) {
  Write-C34LJson $Fixture.CapturePath $Capture
  $Fixture.Capture = $Capture
}
function New-C34LPlayArguments($Fixture, $Attestation) {
  return @{
    Attempt=1; StatePath=$Fixture.StateRelative; InternalReleaseActive=$true
    UploadCount=1; InternalActivationCount=1; OtherTrackChanged=$false
    SourceAttestationPath=[string]$Attestation.path
    SourceAttestationSha256=[string]$Attestation.sha256
    SourceAttestationBytes=[int64]$Attestation.bytes
    FixtureMode=$true; RepositoryRoot=$root
  }
}
function New-C34LJourneyArguments($Fixture, $Attestation) {
  return @{
    Attempt=1; StatePath=$Fixture.StateRelative
    PublicGuestJourneyPassed=$true; ProtectedGatewayJourneyPassed=$true
    SupportedAuthenticationJourneysPassed=$true; SocialJourneysPassed=$true
    WholeAppJourneysPassed=$true; C33gBlockerJourneysPassed=$true
    AllMandatoryJourneysPassed=$true; EvidenceComplete=$true
    NewIssueCount=0; NewDefectCount=0; BlankScreenCount=0
    FlutterFatalErrorCount=0; AndroidRuntimeFatalCount=0; AnrCount=0
    AcceptanceSucceeded=$true; SuccessClaimed=$true
    SourceAttestationPath=[string]$Attestation.path
    SourceAttestationSha256=[string]$Attestation.sha256
    SourceAttestationBytes=[int64]$Attestation.bytes
    FixtureMode=$true; RepositoryRoot=$root
  }
}

$negativeLabels = [Collections.Generic.List[string]]::new()
$checkerSource = Get-Content -Raw -LiteralPath $PSCommandPath
$oldInvocationPattern = '@\(' + '(?:Get|New)-C34L'
Assert-C34LAttestationFixture (
  -not [regex]::IsMatch($checkerSource, $oldInvocationPattern)
) 'checker retains an array-subexpression owner invocation.'
try {
  Write-Verbose 'c34l-attestation-progress=positive-play-start'
  $play = New-C34LFixture 'play_internal_testing_activation'
  Write-Verbose 'c34l-attestation-progress=positive-play-fixture-created'
  $playAttestation = Invoke-C34LAttestation $play
  Write-Verbose 'c34l-attestation-progress=positive-play-attestation-created'
  $playParameters = New-C34LPlayArguments $play $playAttestation
  Write-Verbose 'c34l-attestation-progress=positive-play-writer-start'
  $playOutput = @(& $playWriter @playParameters)
  Write-Verbose 'c34l-attestation-progress=positive-play-writer-complete'
  Assert-C34LAttestationFixture ($playOutput.Count -eq 1) `
    'Play writer did not accept the exact source attestation.'
  $playEvidence = Get-Content -Raw -LiteralPath (
    Join-Path $root (([string]$playOutput[0] | ConvertFrom-Json).path)
  ) | ConvertFrom-Json
  Assert-C34LAttestationFixture (
    [string]$playEvidence.sourceAttestation.sha256 -ceq
      [string]$playAttestation.sha256 -and
    [string]$playEvidence.sourceAttestation.sessionId -ceq
      [string]$playAttestation.sessionId
  ) 'Play evidence did not retain the exact attestation binding.'
  Write-Verbose 'c34l-attestation-progress=positive-play-complete'

  Write-Verbose 'c34l-attestation-progress=positive-oppo-start'
  $oppo = New-C34LFixture 'oppo_play_in_place_update_pair'
  $oppoAttestation = Invoke-C34LAttestation $oppo
  Assert-C34LAttestationFixture (
    [string]$oppoAttestation.evidenceType -ceq
      'oppo_play_in_place_update_pair'
  ) 'OPPO source-attestation contract did not qualify.'
  Write-Verbose 'c34l-attestation-progress=positive-oppo-complete'

  Write-Verbose 'c34l-attestation-progress=positive-journey-start'
  $journey = New-C34LFixture 'mandatory_whole_app_journey_acceptance'
  $journeyAttestation = Invoke-C34LAttestation $journey
  $journeyParameters = New-C34LJourneyArguments $journey $journeyAttestation
  $journeyOutput = @(& $journeyWriter @journeyParameters)
  Assert-C34LAttestationFixture ($journeyOutput.Count -eq 1) `
    'journey writer did not accept the exact source attestation.'
  $journeyEvidence = Get-Content -Raw -LiteralPath (
    Join-Path $root (([string]$journeyOutput[0] | ConvertFrom-Json).path)
  ) | ConvertFrom-Json
  Assert-C34LAttestationFixture (
    [string]$journeyEvidence.sourceAttestation.sha256 -ceq
      [string]$journeyAttestation.sha256 -and
    [string]$journeyEvidence.sourceAttestation.sessionId -ceq
      [string]$journeyAttestation.sessionId
  ) 'journey evidence did not retain the exact attestation binding.'
  Write-Verbose 'c34l-attestation-progress=positive-journey-complete'

  Write-Verbose 'c34l-attestation-progress=legacy-negatives-start'
  $missing = New-C34LFixture 'play_internal_testing_activation'
  $missingArguments = @{
    Attempt=1; StatePath=$missing.StateRelative
    AuthoritativeReceiptSha256='A' * 64;AuthoritativeReceiptBytes=1
    FixtureMode=$true; RepositoryRoot=$root
  }
  Assert-C34LExpectedRejection $playWriter $missingArguments `
    'AuthoritativeReceiptPath' 'missing'
  [void]$negativeLabels.Add('missing')

  $wrong = New-C34LFixture 'play_internal_testing_activation'
  $wrongArguments = Get-C34LAttestationArguments $wrong
  $wrongArguments.CaptureManifestSha256 = 'E' * 64
  Assert-C34LExpectedRejection $writer $wrongArguments `
    'capture manifest SHA-256 or byte-length binding changed.' 'wrong'
  [void]$negativeLabels.Add('wrong')

  $bytes = New-C34LFixture 'play_internal_testing_activation'
  $bytesArguments = Get-C34LAttestationArguments $bytes
  $bytesArguments.CaptureManifestBytes++
  Assert-C34LExpectedRejection $writer $bytesArguments `
    'capture manifest SHA-256 or byte-length binding changed.' 'bytes'
  [void]$negativeLabels.Add('bytes')

  $tamper = New-C34LFixture 'play_internal_testing_activation'
  $tamperAttestation = Invoke-C34LAttestation $tamper
  $tamperFile = Join-Path $root ([string]$tamperAttestation.path)
  [IO.File]::AppendAllText($tamperFile, ' ', $utf8)
  Assert-C34LExpectedRejection $playWriter `
    (New-C34LPlayArguments $tamper $tamperAttestation) `
    'Play source-attestation SHA-256 or bytes changed.' 'tamper'
  [void]$negativeLabels.Add('tamper')

  $replay = New-C34LFixture 'play_internal_testing_activation'
  $replayCapture = $replay.Capture
  $format = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
  $replayCapture.producedUtc = [DateTimeOffset]::UtcNow.AddMinutes(-30).
    ToString($format, [Globalization.CultureInfo]::InvariantCulture)
  $replayCapture.expiresUtc = [DateTimeOffset]::UtcNow.AddMinutes(-15).
    ToString($format, [Globalization.CultureInfo]::InvariantCulture)
  Rewrite-C34LCapture $replay $replayCapture
  Assert-C34LExpectedRejection $writer (Get-C34LAttestationArguments $replay) `
    'capture session is expired, premature or exceeds the 15-minute window.' `
    'replay'
  [void]$negativeLabels.Add('replay')

  $type = New-C34LFixture 'play_internal_testing_activation'
  $typeCapture = $type.Capture
  $typeCapture.evidenceType = 'mandatory_whole_app_journey_acceptance'
  Rewrite-C34LCapture $type $typeCapture
  $typeArguments = Get-C34LAttestationArguments $type
  $typeArguments.EvidenceType = 'play_internal_testing_activation'
  Assert-C34LExpectedRejection $writer $typeArguments `
    'capture field evidenceType changed.' `
    'type'
  [void]$negativeLabels.Add('type')

  $preimage = New-C34LFixture 'play_internal_testing_activation'
  $preimageCapture = $preimage.Capture
  $preimageCapture.preStateSha256 = 'F' * 64
  Rewrite-C34LCapture $preimage $preimageCapture
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $preimage) `
    'capture field preStateSha256 changed.' `
    'preimage'
  [void]$negativeLabels.Add('preimage')

  $vector = New-C34LFixture 'play_internal_testing_activation'
  $vectorCapture = $vector.Capture
  $vectorCapture.actionCounts.otherTrack = 1
  Rewrite-C34LCapture $vector $vectorCapture
  Assert-C34LExpectedRejection $writer (Get-C34LAttestationArguments $vector) `
    'capture manifest action count changed at otherTrack.' 'vector'
  [void]$negativeLabels.Add('vector')

  $unknown = New-C34LFixture 'play_internal_testing_activation'
  $unknownCapture = $unknown.Capture
  $unknownCapture | Add-Member -NotePropertyName unexpectedField `
    -NotePropertyValue 'synthetic-fixture'
  Rewrite-C34LCapture $unknown $unknownCapture
  Assert-C34LExpectedRejection $writer (Get-C34LAttestationArguments $unknown) `
    'capture manifest property count changed.' 'unknown'
  [void]$negativeLabels.Add('unknown')

  $private = New-C34LFixture 'play_internal_testing_activation'
  $privateCapture = $private.Capture
  $privateCapture | Add-Member -NotePropertyName operatorEmail `
    -NotePropertyValue 'fixture@example.invalid'
  Rewrite-C34LCapture $private $privateCapture
  Assert-C34LExpectedRejection $writer (Get-C34LAttestationArguments $private) `
    'capture manifest property count changed.' 'private'
  [void]$negativeLabels.Add('private')

  $reparse = New-C34LFixture 'play_internal_testing_activation' `
    -ReparseAttestationDirectory
  Assert-C34LExpectedRejection $writer (Get-C34LAttestationArguments $reparse) `
    'capture manifest contains a reparse-point ancestor.' 'reparse'
  [void]$negativeLabels.Add('reparse')
  Write-Verbose 'c34l-attestation-progress=legacy-negatives-complete'

  Write-Verbose 'c34l-attestation-progress=artifact-negatives-start'
  $missingArtifact = New-C34LFixture 'play_internal_testing_activation'
  [IO.File]::Delete((Join-Path $root `
    ([string]$missingArtifact.Capture.captureArtifacts[0].path)))
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $missingArtifact) `
    'capture artifact internal_testing_release_receipt is missing.' `
    'missing artifact'
  [void]$negativeLabels.Add('missing artifact')

  $wrongArtifactSha = New-C34LFixture 'play_internal_testing_activation'
  $wrongArtifactSha.Capture.captureArtifacts[0].sha256 = 'E' * 64
  Rewrite-C34LCapture $wrongArtifactSha $wrongArtifactSha.Capture
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $wrongArtifactSha) `
    'capture artifact SHA-256 or bytes changed at internal_testing_release_receipt.' `
    'wrong artifact SHA'
  [void]$negativeLabels.Add('wrong artifact SHA')

  $tamperedArtifact = New-C34LFixture 'play_internal_testing_activation'
  [IO.File]::AppendAllText((Join-Path $root `
    ([string]$tamperedArtifact.Capture.captureArtifacts[0].path)),' ', $utf8)
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $tamperedArtifact) `
    'capture artifact SHA-256 or bytes changed at internal_testing_release_receipt.' `
    'tampered artifact'
  [void]$negativeLabels.Add('tampered artifact')

  $extraArtifact = New-C34LFixture 'play_internal_testing_activation'
  $extraArtifact.Capture.captureArtifacts =
    @($extraArtifact.Capture.captureArtifacts) +
    @([pscustomobject][ordered]@{
      role='unexpected_role'; path=[string]$extraArtifact.Capture.captureArtifacts[0].path
      sha256=[string]$extraArtifact.Capture.captureArtifacts[0].sha256
      bytes=[int64]$extraArtifact.Capture.captureArtifacts[0].bytes
      mediaType='application/json'
    })
  Rewrite-C34LCapture $extraArtifact $extraArtifact.Capture
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $extraArtifact) `
    'capture-artifact role set changed.' 'extra artifact'
  [void]$negativeLabels.Add('extra artifact')

  $aliasArtifact = New-C34LFixture 'play_internal_testing_activation'
  $aliasArtifact.Capture.captureArtifacts[0].path =
    [string]$aliasArtifact.Capture.captureArtifacts[1].path
  $aliasArtifact.Capture.captureArtifacts[0].sha256 =
    [string]$aliasArtifact.Capture.captureArtifacts[1].sha256
  $aliasArtifact.Capture.captureArtifacts[0].bytes =
    [int64]$aliasArtifact.Capture.captureArtifacts[1].bytes
  Rewrite-C34LCapture $aliasArtifact $aliasArtifact.Capture
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $aliasArtifact) `
    'capture artifact path, role, identity or media type changed at internal_testing_release_receipt.' `
    'artifact alias'
  [void]$negativeLabels.Add('artifact alias')

  $wrongRole = New-C34LFixture 'play_internal_testing_activation'
  $wrongRole.Capture.captureArtifacts[0].role = 'cold_start_observation'
  Rewrite-C34LCapture $wrongRole $wrongRole.Capture
  Assert-C34LExpectedRejection $writer (Get-C34LAttestationArguments $wrongRole) `
    'capture-artifact role set changed.' 'wrong artifact role'
  [void]$negativeLabels.Add('wrong artifact role')

  $wrongMedia = New-C34LFixture 'play_internal_testing_activation'
  $wrongMedia.Capture.captureArtifacts[0].mediaType = 'text/plain'
  Rewrite-C34LCapture $wrongMedia $wrongMedia.Capture
  Assert-C34LExpectedRejection $writer (Get-C34LAttestationArguments $wrongMedia) `
    'capture artifact path, role, identity or media type changed at internal_testing_release_receipt.' `
    'wrong artifact media'
  [void]$negativeLabels.Add('wrong artifact media')

  $rawDeviceField = New-C34LFixture 'play_internal_testing_activation'
  $rawDevicePath = Join-Path $root `
    ([string]$rawDeviceField.Capture.captureArtifacts[0].path)
  $rawDeviceValue = Get-Content -Raw -LiteralPath $rawDevicePath | ConvertFrom-Json
  $rawDeviceValue | Add-Member -NotePropertyName deviceSerial `
    -NotePropertyValue 'synthetic-redacted-fixture'
  Write-C34LJson $rawDevicePath $rawDeviceValue
  $rawDeviceSha = Get-C34LSha $rawDevicePath
  $rawDeviceField.Capture.captureArtifacts[0].sha256 = $rawDeviceSha
  $rawDeviceField.Capture.captureArtifacts[0].bytes =
    (Get-Item -LiteralPath $rawDevicePath).Length
  $rawDeviceField.Capture.captureDigests.internalTestingRouteDigestSha256 =
    $rawDeviceSha
  $rawDeviceField.Capture.captureDigests.uploadReceiptDigestSha256 = $rawDeviceSha
  Rewrite-C34LCapture $rawDeviceField $rawDeviceField.Capture
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $rawDeviceField) `
    'capture artifact internal_testing_release_receipt contains forbidden private property deviceSerial.' `
    'raw device field'
  [void]$negativeLabels.Add('raw device field')

  $rawDeviceShape = New-C34LFixture 'play_internal_testing_activation'
  $rawShapePath = Join-Path $root `
    ([string]$rawDeviceShape.Capture.captureArtifacts[0].path)
  $rawShapeValue = Get-Content -Raw -LiteralPath $rawShapePath | ConvertFrom-Json
  $rawShapeValue | Add-Member -NotePropertyName deviceBindingHint `
    -NotePropertyValue '2b3e0f71'
  Write-C34LJson $rawShapePath $rawShapeValue
  $rawShapeSha = Get-C34LSha $rawShapePath
  $rawDeviceShape.Capture.captureArtifacts[0].sha256 = $rawShapeSha
  $rawDeviceShape.Capture.captureArtifacts[0].bytes =
    (Get-Item -LiteralPath $rawShapePath).Length
  $rawDeviceShape.Capture.captureDigests.internalTestingRouteDigestSha256 =
    $rawShapeSha
  $rawDeviceShape.Capture.captureDigests.uploadReceiptDigestSha256 = $rawShapeSha
  Rewrite-C34LCapture $rawDeviceShape $rawDeviceShape.Capture
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $rawDeviceShape) `
    'capture artifact internal_testing_release_receipt contains a forbidden private value shape at $.deviceBindingHint.' `
    'raw device value'
  [void]$negativeLabels.Add('raw device value')

  $journeyTamper = New-C34LFixture 'mandatory_whole_app_journey_acceptance'
  $journeyManifestPath = Join-Path $root `
    ([string]$journeyTamper.Capture.captureArtifacts[0].path)
  $journeyRowsParsed = Get-Content -Raw -LiteralPath $journeyManifestPath |
    ConvertFrom-Json
  $journeyRows = @(foreach($row in [Array]$journeyRowsParsed){ $row })
  [IO.File]::AppendAllText((Join-Path $root ([string]$journeyRows[0].path)),
    ' ', $utf8)
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $journeyTamper) `
    'journey capture artifact SHA-256 or bytes changed at publicGuest.' `
    'journey row tamper'
  [void]$negativeLabels.Add('journey row tamper')

  $wrongContract = New-C34LFixture 'play_internal_testing_activation'
  $wrongContract.Capture.captureArtifactContractSha256 = 'A' * 64
  Rewrite-C34LCapture $wrongContract $wrongContract.Capture
  Assert-C34LExpectedRejection $writer `
    (Get-C34LAttestationArguments $wrongContract) `
    'capture-artifact contract identity or binding changed.' 'contract hash'
  [void]$negativeLabels.Add('contract hash')
  Write-Verbose 'c34l-attestation-progress=artifact-negatives-complete'

  Assert-C34LAttestationFixture ($negativeLabels.Count -eq 22) `
    'source-attestation negative matrix is incomplete.'
  Write-Output (([pscustomobject][ordered]@{
    gate='C34L source attestation'; hostMajor=$PSVersionTable.PSVersion.Major
    positiveTypes=3; playJourneyProducerBindings=2
    negativeCount=$negativeLabels.Count; negatives=@($negativeLabels)
    captureArtifactsBound=$true; cleanupVerified=$true
    realStateWrites=0; externalActions=0; privateValuesObserved=$false
  }) | ConvertTo-Json -Compress)
} finally {
  Write-Verbose ('c34l-attestation-progress=cleanup-start;roots={0}' -f
    $fixtureRoots.Count)
  foreach ($fixtureRoot in $fixtureRoots) {
    foreach ($kind in @('play','oppo','journey')) {
      $junction = Join-Path $fixtureRoot "evidence/captures/attempt-1/$kind"
      if (Test-Path -LiteralPath $junction) {
        $item = Get-Item -LiteralPath $junction -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
          $item.Delete()
          Assert-C34LAttestationFixture (-not (Test-Path -LiteralPath $junction)) `
            'verified fixture junction cleanup was incomplete.'
        }
      }
    }
    if (Test-Path -LiteralPath $fixtureRoot) {
      $fixtureItem = Get-Item -LiteralPath $fixtureRoot -Force
      Assert-C34LAttestationFixture (
        $fixtureItem.FullName.StartsWith(
          (Join-Path $root 'tmp\c34l-retained-evidence-fixtures-'),
          [StringComparison]::OrdinalIgnoreCase
        )
      ) 'fixture cleanup root identity changed.'
      $fixtureItem.Delete($true)
      Assert-C34LAttestationFixture (-not (Test-Path -LiteralPath $fixtureRoot)) `
        'verified fixture-root cleanup was incomplete.'
    }
  }
  Write-Verbose 'c34l-attestation-progress=cleanup-complete'
}
