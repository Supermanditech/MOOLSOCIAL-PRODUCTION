[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$NestedInvocationChild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$writer = Join-Path $root 'scripts/write-release-oppo-evidence-c34l.ps1'
$attestationChecker = Join-Path $root `
  'scripts/check-release-source-attestation-c34l.ps1'
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
$captureArtifactContractId =
  'MOOLSOCIAL-C34L-CAPTURE-ARTIFACT-CONTRACT-003'
$utf8 = [Text.UTF8Encoding]::new($false)
$fixtureRoots = New-Object 'System.Collections.Generic.List[string]'
$reparseOwners = New-Object 'System.Collections.Generic.List[string]'

function Assert-C34LOppoTransactionFixture(
  [bool]$Condition,
  [string]$Message
) {
  if (-not $Condition) {
    throw "C34L OPPO transaction fixture rejected: $Message"
  }
}
function Write-C34LOppoTransactionText([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  [IO.File]::WriteAllText($Path, $Text, $utf8)
}
function Write-C34LOppoTransactionJson([string]$Path, $Value) {
  foreach ($name in @('producedUtc','expiresUtc','preparedUtc','committedUtc')) {
    $property = $Value.PSObject.Properties[$name]
    if ($null -ne $property -and $null -ne $property.Value -and
        ($property.Value -is [DateTime] -or
         $property.Value -is [DateTimeOffset])) {
      $instant = if ($property.Value -is [DateTimeOffset]) {
        ([DateTimeOffset]$property.Value).ToUniversalTime()
      } else {
        [DateTimeOffset]::new(
          ([DateTime]$property.Value).ToUniversalTime(), [TimeSpan]::Zero
        )
      }
      $property.Value = $instant.ToString(
        "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
        [Globalization.CultureInfo]::InvariantCulture
      )
    }
  }
  Write-C34LOppoTransactionText $Path (
    ($Value | ConvertTo-Json -Depth 60) + [Environment]::NewLine
  )
}
function Assert-C34LOppoCaptureWireTokens([string]$Path, [string]$Label) {
  $raw = Get-Content -Raw -LiteralPath $Path
  foreach ($name in @('producedUtc','expiresUtc')) {
    $matches = [regex]::Matches(
      $raw,
      '"' + $name +
        '"\s*:\s*"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[.][0-9]{3}Z"'
    )
    Assert-C34LOppoTransactionFixture ($matches.Count -eq 1) `
      "$Label $name wire-token cardinality changed."
  }
}
function Get-C34LOppoTransactionSha([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.
    ToUpperInvariant()
}
function Get-C34LOppoTransactionStringSha([string]$Value) {
  $bytes = $utf8.GetBytes($Value)
  $hasher = [Security.Cryptography.SHA256]::Create()
  try { $digest = $hasher.ComputeHash($bytes) } finally { $hasher.Dispose() }
  return ([BitConverter]::ToString($digest)).Replace('-', '')
}
function Assert-C34LOppoJournalWireTokens(
  [string]$Path,
  [ValidateSet('prepared','cold_moved','both_moved','committed')]
  [string]$Status
) {
  $raw = Get-Content -Raw -LiteralPath $Path
  $utcValue =
    '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[.][0-9]{3}Z'
  $prepared = [regex]::Matches(
    $raw, '"preparedUtc"\s*:\s*"(' + $utcValue + ')"'
  )
  $committed = [regex]::Matches(
    $raw, '"committedUtc"\s*:\s*"(' + $utcValue + ')"'
  )
  $committedNull = [regex]::Matches(
    $raw, '"committedUtc"\s*:\s*null'
  )
  if ($prepared.Count -ne 1) {
    $anyPrepared = [regex]::Matches(
      $raw, '"preparedUtc"\s*:\s*"[^"]*"'
    )
    $nullPrepared = [regex]::Matches(
      $raw, '"preparedUtc"\s*:\s*null'
    )
    try {
      $parsedJournal = $raw | ConvertFrom-Json
      $runtimeType = if ($null -eq $parsedJournal.preparedUtc) {
        'null'
      } else {
        $parsedJournal.preparedUtc.GetType().FullName
      }
    } catch {
      $runtimeType = 'invalid_json'
    }
    throw (
      'C34L OPPO transaction fixture rejected: journal preparedUtc wire ' +
      "cardinality changed; canonical=$($prepared.Count); " +
      "quoted=$($anyPrepared.Count); null=$($nullPrepared.Count); " +
      "runtimeType=$runtimeType."
    )
  }
  if ($Status -ceq 'committed') {
    Assert-C34LOppoTransactionFixture (
      $committed.Count -eq 1 -and $committedNull.Count -eq 0
    ) 'committed journal UTC wire-token cardinality changed.'
  } else {
    Assert-C34LOppoTransactionFixture (
      $committed.Count -eq 0 -and $committedNull.Count -eq 1
    ) 'noncommitted journal UTC wire-token cardinality changed.'
  }
}
function New-C34LOppoTransactionCounts {
  return [pscustomobject][ordered]@{
    build=1; upload=1; install=0; deviceAcceptance=0
    passwordlessEmailSend=0; realSmsSend=0; otherTrack=0
    backendHostingProviderOrProductionDeployment=0
  }
}
function New-C34LOppoTransactionAuthorities {
  return [pscustomobject][ordered]@{
    build='consumed'; uploadAndInternalActivation='consumed'
    inPlaceOppoPlayUpdate='available_once'
    postinstallAcceptance='held_postinstall_journey_qualification'
  }
}
function New-C34LOppoTransactionFixture {
  $name = 'c34l-retained-evidence-fixtures-' +
    [Guid]::NewGuid().ToString('N')
  $relative = "tmp/$name"
  $fixtureRoot = Join-Path $root $relative
  $fixtureRoots.Add($fixtureRoot)
  $evidenceRelative = "$relative/evidence"
  $evidenceRoot = Join-Path $root $evidenceRelative
  $attestationsRoot = Join-Path $evidenceRoot 'attestations'
  [void](New-Item -ItemType Directory -Path $attestationsRoot -Force)

  $artifactRelative =
    "$evidenceRelative/MoolSocial-$versionName-$versionCode-release.aab"
  $artifactPath = Join-Path $root $artifactRelative
  Write-C34LOppoTransactionText $artifactPath `
    ('C34L OPPO fixture AAB ' + [Guid]::NewGuid().ToString('N'))
  $artifactSha = Get-C34LOppoTransactionSha $artifactPath
  $artifactBytes = (Get-Item -LiteralPath $artifactPath).Length
  $counts = New-C34LOppoTransactionCounts
  $authorities = New-C34LOppoTransactionAuthorities
  $aggregateRelative = "$relative/aggregate.json"
  $aggregatePath = Join-Path $root $aggregateRelative
  $stateRelative = "$relative/state.json"
  $statePath = Join-Path $root $stateRelative
  $machine =
    'postupload_qualified_in_place_oppo_play_update_authority_available_once'
  $aggregate = [pscustomobject][ordered]@{
    ticketId=$ticketId
    candidate=[pscustomobject][ordered]@{
      id=$ticketId; versionName=$versionName; versionCode=$versionCode
    }
    machineState=$machine; actionCounts=$counts
    releaseAuthorities=$authorities
  }
  Write-C34LOppoTransactionJson $aggregatePath $aggregate
  $state = [pscustomobject][ordered]@{
    ticketId=$ticketId
    candidate=[pscustomobject][ordered]@{
      id=$ticketId; packageName='com.moolsocial.app'
      versionName=$versionName; versionCode=$versionCode; playTrack='internal'
      deviceBindingSha256=$deviceBindingSha256; deviceModel='CPH2375'
    }
    aggregateStatePath=$aggregateRelative; machineState=$machine
    evidenceRoot=$evidenceRelative; actionCounts=$counts
    releaseAuthorities=$authorities
    buildResult=[pscustomobject][ordered]@{
      artifactPath=$artifactRelative; artifactSha256=$artifactSha
      artifactBytes=$artifactBytes
    }
  }
  Write-C34LOppoTransactionJson $statePath $state
  $stateSha = Get-C34LOppoTransactionSha $statePath
  $aggregateSha = Get-C34LOppoTransactionSha $aggregatePath
  $produced = [DateTimeOffset]::UtcNow.AddSeconds(-5)
  $expires = $produced.AddMinutes(10)
  $producedText = $produced.ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture
  )
  $expiresText = $expires.ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture
  )
  $session = 'oppo-session-' + [Guid]::NewGuid().ToString('N')
  $nonce = Get-C34LOppoTransactionStringSha `
    ([Guid]::NewGuid().ToString('N'))
  $captureRootRelative = "$evidenceRelative/captures/attempt-1/oppo"
  $captureRoot = Join-Path $root $captureRootRelative
  [void](New-Item -ItemType Directory -Path $captureRoot -Force)
  $coldCaptureRelative = "$captureRootRelative/cold-start-observation.json"
  $coldCapturePath = Join-Path $root $coldCaptureRelative
  $coldCapture = [pscustomobject][ordered]@{
    schemaVersion=1; captureArtifactContractId=$captureArtifactContractId
    evidenceType='oppo_play_in_place_update_pair'
    role='cold_start_observation'; ticketId=$ticketId; attempt=1
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; artifactSha256=$artifactSha
    artifactBytes=$artifactBytes; deviceBindingSha256=$deviceBindingSha256
    deviceModel='CPH2375'; installerPackage='com.android.vending'
    sourceProducerId='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
    sessionId=$session; nonceSha256=$nonce; coldStartInteractive=$true
    blankHierarchy=$false; timeout=$false; flutterFatalErrorCount=0
    androidRuntimeFatalCount=0; anrCount=0; appProcessErrorScanPassed=$true
    artifactRelationshipProved=$true; inPlaceUpdateProved=$true
  }
  Write-C34LOppoTransactionJson $coldCapturePath $coldCapture
  $retainedCaptureRelative =
    "$captureRootRelative/retained-state-observation.json"
  $retainedCapturePath = Join-Path $root $retainedCaptureRelative
  $retainedCapture = [pscustomobject][ordered]@{
    schemaVersion=1; captureArtifactContractId=$captureArtifactContractId
    evidenceType='oppo_play_in_place_update_pair'
    role='retained_state_observation'; ticketId=$ticketId; attempt=1
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; artifactSha256=$artifactSha
    artifactBytes=$artifactBytes; deviceBindingSha256=$deviceBindingSha256
    deviceModel='CPH2375'; installerPackage='com.android.vending'
    sourceProducerId='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
    sessionId=$session; nonceSha256=$nonce; firstInstallTimeMillis=1000
    lastUpdateTimeMillis=2000; firstInstallTimePreserved=$true
    retainedDataContinuityProved=$true; inPlacePlayUpdateProved=$true
    uninstallPerformed=$false; dataClearPerformed=$false
    downgradePerformed=$false; adbInstallPerformed=$false
  }
  Write-C34LOppoTransactionJson $retainedCapturePath $retainedCapture
  $coldCaptureSha = Get-C34LOppoTransactionSha $coldCapturePath
  $retainedCaptureSha = Get-C34LOppoTransactionSha $retainedCapturePath
  $digests = [pscustomobject][ordered]@{
    packageStateDigestSha256=$coldCaptureSha
    coldStartDigestSha256=$coldCaptureSha
    retainedDataDigestSha256=$retainedCaptureSha
  }
  $captureRelative = "$captureRootRelative/capture-manifest.json"
  $capturePath = Join-Path $root $captureRelative
  $capture = [pscustomobject][ordered]@{
    schemaVersion=1
    captureContractId='MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001'
    evidenceType='oppo_play_in_place_update_pair'; ticketId=$ticketId
    attempt=1; packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; preStateSha256=$stateSha
    preAggregateSha256=$aggregateSha; actionCounts=$counts
    releaseAuthorities=$authorities; artifactSha256=$artifactSha
    artifactBytes=$artifactBytes
    sourceProducerId='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
    sessionId=$session; nonceSha256=$nonce; producedUtc=$producedText
    expiresUtc=$expiresText; captureDigests=$digests
    captureArtifactContractPath=$captureArtifactContractPath
    captureArtifactContractSha256=$captureArtifactContractSha256
    captureArtifactContractId=$captureArtifactContractId
    captureArtifacts=@(
      [pscustomobject][ordered]@{
        role='cold_start_observation'; path=$coldCaptureRelative
        sha256=$coldCaptureSha
        bytes=(Get-Item -LiteralPath $coldCapturePath).Length
        mediaType='application/json'
      },
      [pscustomobject][ordered]@{
        role='retained_state_observation'; path=$retainedCaptureRelative
        sha256=$retainedCaptureSha
        bytes=(Get-Item -LiteralPath $retainedCapturePath).Length
        mediaType='application/json'
      }
    )
  }
  Write-C34LOppoTransactionJson $capturePath $capture
  $captureSha = Get-C34LOppoTransactionSha $capturePath
  $captureBytes = (Get-Item -LiteralPath $capturePath).Length
  $attestationRelative =
    "$evidenceRelative/attestations/source-attestation-oppo-attempt-1.json"
  $attestationPath = Join-Path $root $attestationRelative
  $attestation = [pscustomobject][ordered]@{
    schemaVersion=1
    attestationContractId='MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001'
    evidenceType='oppo_play_in_place_update_pair'; ticketId=$ticketId
    attempt=1; packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; preStateSha256=$stateSha
    preAggregateSha256=$aggregateSha; actionCounts=$counts
    releaseAuthorities=$authorities; artifactSha256=$artifactSha
    artifactBytes=$artifactBytes
    sourceProducerId='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
    sessionId=$session; nonceSha256=$nonce; producedUtc=$producedText
    expiresUtc=$expiresText; captureManifestPath=$captureRelative
    captureManifestSha256=$captureSha; captureManifestBytes=$captureBytes
    captureDigests=$digests
  }
  Write-C34LOppoTransactionJson $attestationPath $attestation
  return [pscustomobject][ordered]@{
    Root=$fixtureRoot; Relative=$relative; EvidenceRelative=$evidenceRelative
    EvidenceRoot=$evidenceRoot; StatePath=$statePath
    StateRelative=$stateRelative; AggregatePath=$aggregatePath
    ArtifactPath=$artifactPath; CapturePath=$capturePath
    CaptureRelative=$captureRelative; AttestationPath=$attestationPath
    AttestationRelative=$attestationRelative
    ColdCapturePath=$coldCapturePath; ColdCaptureRelative=$coldCaptureRelative
    RetainedCapturePath=$retainedCapturePath
    RetainedCaptureRelative=$retainedCaptureRelative
    ColdPath=(Join-Path $evidenceRoot `
      '08-oppo-play-in-place-update-cold-start-evidence.json')
    RetainedPath=(Join-Path $evidenceRoot `
      '09-oppo-in-place-retained-data-evidence.json')
    JournalPath=(Join-Path $evidenceRoot `
      'transactions/oppo-evidence-pair-attempt-1.json')
  }
}

function Get-C34LOppoWriterArguments(
  $Fixture,
  [string]$Boundary = 'none'
) {
  Assert-C34LOppoCaptureWireTokens $Fixture.CapturePath 'capture manifest'
  Assert-C34LOppoCaptureWireTokens $Fixture.AttestationPath `
    'source attestation'
  return @{
    Attempt=1; StatePath=$Fixture.StateRelative; ColdStartInteractive=$true
    BlankHierarchy=$false; Timeout=$false; FlutterFatalErrorCount=0
    AndroidRuntimeFatalCount=0; AnrCount=0; AppProcessErrorScanPassed=$true
    ArtifactRelationshipProved=$true; InPlaceUpdateProved=$true
    FirstInstallTimeMillis=1000; LastUpdateTimeMillis=2000
    FirstInstallTimePreserved=$true; RetainedDataContinuityProved=$true
    InPlacePlayUpdateProved=$true; UninstallPerformed=$false
    DataClearPerformed=$false; DowngradePerformed=$false
    AdbInstallPerformed=$false
    SourceAttestationPath=$Fixture.AttestationRelative
    SourceAttestationSha256=Get-C34LOppoTransactionSha $Fixture.AttestationPath
    SourceAttestationBytes=(Get-Item -LiteralPath $Fixture.AttestationPath).Length
    FixtureMode=$true; FixtureCrashBoundary=$Boundary; RepositoryRoot=$root
  }
}
function Invoke-C34LOppoWriterSuccess($Arguments) {
  $output = @(& $writer @Arguments)
  Assert-C34LOppoTransactionFixture ($output.Count -eq 1) `
    'writer success did not emit exactly one result.'
  try { return [string]$output[0] | ConvertFrom-Json }
  catch { throw 'C34L OPPO transaction fixture rejected: writer result is not valid JSON.' }
}
function Invoke-C34LOppoWriterFailure(
  $Arguments,
  [string]$ExpectedMessage
) {
  $failed = $false
  try { [void](& $writer @Arguments) }
  catch {
    $failed = $true
    Assert-C34LOppoTransactionFixture (
      $_.Exception.Message.Contains($ExpectedMessage)
    ) "wrong rejection class; expected $ExpectedMessage; observed $($_.Exception.Message)"
  }
  Assert-C34LOppoTransactionFixture $failed `
    "writer unexpectedly accepted: $ExpectedMessage"
}
function Assert-C34LOppoCrashState($Fixture, [string]$Boundary) {
  $journalExists = Test-Path -LiteralPath $Fixture.JournalPath -PathType Leaf
  $coldExists = Test-Path -LiteralPath $Fixture.ColdPath -PathType Leaf
  $retainedExists = Test-Path -LiteralPath $Fixture.RetainedPath -PathType Leaf
  switch ($Boundary) {
    'before-journal' {
      Assert-C34LOppoTransactionFixture (
        -not $journalExists -and -not $coldExists -and -not $retainedExists
      ) 'before-journal crash persisted transaction state.'
    }
    'prepared-none' {
      Assert-C34LOppoTransactionFixture (
        $journalExists -and -not $coldExists -and -not $retainedExists
      ) 'prepared-none crash boundary state changed.'
    }
    'cold-file-moved' {
      Assert-C34LOppoTransactionFixture (
        $journalExists -and $coldExists -and -not $retainedExists
      ) 'cold-file-moved crash boundary state changed.'
    }
    'cold-moved' {
      Assert-C34LOppoTransactionFixture (
        $journalExists -and $coldExists -and -not $retainedExists
      ) 'cold-moved crash boundary state changed.'
    }
    'retained-file-moved' {
      Assert-C34LOppoTransactionFixture (
        $journalExists -and $coldExists -and $retainedExists
      ) 'retained-file-moved crash boundary state changed.'
    }
    'both-moved' {
      Assert-C34LOppoTransactionFixture (
        $journalExists -and $coldExists -and $retainedExists
      ) 'both-moved crash boundary state changed.'
    }
    'committed' {
      Assert-C34LOppoTransactionFixture (
        $journalExists -and $coldExists -and $retainedExists
      ) 'committed crash boundary state changed.'
    }
  }
  if ($journalExists) {
    $journal = Get-Content -Raw -LiteralPath $Fixture.JournalPath |
      ConvertFrom-Json
    $expectedStatus = @{
      'prepared-none'='prepared'; 'cold-file-moved'='prepared'
      'cold-moved'='cold_moved'; 'retained-file-moved'='cold_moved'
      'both-moved'='both_moved'; 'committed'='committed'
    }[$Boundary]
    Assert-C34LOppoTransactionFixture (
      [string]$journal.status -ceq $expectedStatus
    ) "$Boundary journal status changed."
    Assert-C34LOppoJournalWireTokens $Fixture.JournalPath $expectedStatus
  }
}
function Update-C34LOppoAttestationIdentity($Fixture) {
  return [pscustomobject][ordered]@{
    Sha256=Get-C34LOppoTransactionSha $Fixture.AttestationPath
    Bytes=(Get-Item -LiteralPath $Fixture.AttestationPath).Length
  }
}
function Update-C34LOppoAttestationCaptureIdentity($Fixture) {
  $capture = Get-Content -Raw -LiteralPath $Fixture.CapturePath |
    ConvertFrom-Json
  $source = Get-Content -Raw -LiteralPath $Fixture.AttestationPath |
    ConvertFrom-Json
  $source.captureManifestSha256 =
    Get-C34LOppoTransactionSha $Fixture.CapturePath
  $source.captureManifestBytes =
    (Get-Item -LiteralPath $Fixture.CapturePath).Length
  $source.captureDigests = $capture.captureDigests
  Write-C34LOppoTransactionJson $Fixture.AttestationPath $source
  return Update-C34LOppoAttestationIdentity $Fixture
}
function Update-C34LOppoCaptureGraph($Fixture) {
  $capture = Get-Content -Raw -LiteralPath $Fixture.CapturePath |
    ConvertFrom-Json
  foreach ($entry in @($capture.captureArtifacts)) {
    $path = if ([string]$entry.role -ceq 'cold_start_observation') {
      $Fixture.ColdCapturePath
    } elseif ([string]$entry.role -ceq 'retained_state_observation') {
      $Fixture.RetainedCapturePath
    } else {
      throw 'C34L OPPO transaction fixture rejected: cannot refresh unknown capture role.'
    }
    $entry.sha256 = Get-C34LOppoTransactionSha $path
    $entry.bytes = (Get-Item -LiteralPath $path).Length
  }
  $coldEntry = @($capture.captureArtifacts | Where-Object {
    [string]$_.role -ceq 'cold_start_observation'
  })[0]
  $retainedEntry = @($capture.captureArtifacts | Where-Object {
    [string]$_.role -ceq 'retained_state_observation'
  })[0]
  $capture.captureDigests.packageStateDigestSha256 = [string]$coldEntry.sha256
  $capture.captureDigests.coldStartDigestSha256 = [string]$coldEntry.sha256
  $capture.captureDigests.retainedDataDigestSha256 =
    [string]$retainedEntry.sha256
  Write-C34LOppoTransactionJson $Fixture.CapturePath $capture
  return Update-C34LOppoAttestationCaptureIdentity $Fixture
}
function Assert-C34LOppoCommittedResult($Fixture, $Result) {
  Assert-C34LOppoJournalWireTokens $Fixture.JournalPath 'committed'
  Assert-C34LOppoTransactionFixture (
    [string]$Result.ticketId -ceq $ticketId -and
    [int]$Result.attempt -eq 1 -and
    [string]$Result.evidenceType -ceq 'oppo_play_in_place_update_pair' -and
    [string]$Result.sourceAttestation.path -ceq
      $Fixture.AttestationRelative -and
    [string]$Result.sourceAttestation.evidenceType -ceq
      'oppo_play_in_place_update_pair' -and
    [string]$Result.sourceAttestation.sourceProducerId -ceq
      'MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001' -and
    [string]$Result.transactionJournal.status -ceq 'committed' -and
    [string]$Result.deviceBindingSha256 -ceq $deviceBindingSha256 -and
    [int]$Result.externalActionsPerformed -eq 0 -and
    -not [bool]$Result.secretOrPrivateValuesRecorded
  ) 'committed writer result identity or zero-action claim changed.'
}
function Invoke-C34LOppoCrashMatrix {
  $boundaries = @(
    'before-journal','prepared-none','cold-file-moved','cold-moved',
    'retained-file-moved','both-moved','committed'
  )
  $recoveryCount = 0
  $idempotentCount = 0
  foreach ($boundary in $boundaries) {
    $fixture = New-C34LOppoTransactionFixture
    $crashArguments = Get-C34LOppoWriterArguments $fixture $boundary
    Invoke-C34LOppoWriterFailure $crashArguments `
      "injected fixture crash: $boundary"
    Assert-C34LOppoCrashState $fixture $boundary
    $arguments = Get-C34LOppoWriterArguments $fixture
    $result = Invoke-C34LOppoWriterSuccess $arguments
    Assert-C34LOppoCommittedResult $fixture $result
    $firstResult = $result | ConvertTo-Json -Depth 20 -Compress
    $replay = Invoke-C34LOppoWriterSuccess $arguments
    Assert-C34LOppoCommittedResult $fixture $replay
    Assert-C34LOppoTransactionFixture (
      ($replay | ConvertTo-Json -Depth 20 -Compress) -ceq $firstResult
    ) "$boundary recovery was not idempotent."
    $recoveryCount++
    $idempotentCount++
  }
  return [pscustomobject][ordered]@{
    CrashBoundaries=$boundaries.Count; Recoveries=$recoveryCount
    IdempotentReplays=$idempotentCount
  }
}

function Invoke-C34LOppoAttestationNegatives {
  $count = 0
  $fixture = New-C34LOppoTransactionFixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = 'F' * 64
  Invoke-C34LOppoWriterFailure $arguments `
    'source attestation SHA-256 or byte-length binding changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $source = Get-Content -Raw -LiteralPath $fixture.AttestationPath |
    ConvertFrom-Json
  $source.attempt = 2
  Write-C34LOppoTransactionJson $fixture.AttestationPath $source
  $identity = Update-C34LOppoAttestationIdentity $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'source attestation identity, type, producer, session, preimage or artifact changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $capture = Get-Content -Raw -LiteralPath $fixture.CapturePath |
    ConvertFrom-Json
  $capture.captureDigests.coldStartDigestSha256 = 'E' * 64
  Write-C34LOppoTransactionJson $fixture.CapturePath $capture
  $arguments = Get-C34LOppoWriterArguments $fixture
  Invoke-C34LOppoWriterFailure $arguments `
    'capture-manifest SHA-256 or byte-length binding changed.'
  $count++

  $sourceFixture = New-C34LOppoTransactionFixture
  $targetFixture = New-C34LOppoTransactionFixture
  $arguments = Get-C34LOppoWriterArguments $targetFixture
  $arguments.SourceAttestationPath = $sourceFixture.AttestationRelative
  $arguments.SourceAttestationSha256 =
    Get-C34LOppoTransactionSha $sourceFixture.AttestationPath
  $arguments.SourceAttestationBytes =
    (Get-Item -LiteralPath $sourceFixture.AttestationPath).Length
  Invoke-C34LOppoWriterFailure $arguments `
    'source attestation is not the exact immutable OPPO owner.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $source = Get-Content -Raw -LiteralPath $fixture.AttestationPath |
    ConvertFrom-Json
  $source | Add-Member -NotePropertyName unexpectedField -NotePropertyValue 'x'
  Write-C34LOppoTransactionJson $fixture.AttestationPath $source
  $identity = Update-C34LOppoAttestationIdentity $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'source attestation property count changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $source = Get-Content -Raw -LiteralPath $fixture.AttestationPath |
    ConvertFrom-Json
  $source.sessionId = 'person@example.com'
  Write-C34LOppoTransactionJson $fixture.AttestationPath $source
  $identity = Update-C34LOppoAttestationIdentity $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'source attestation contains a forbidden private value shape.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $source = Get-Content -Raw -LiteralPath $fixture.AttestationPath |
    ConvertFrom-Json
  $source.sessionId =
    'abcdefghijklmnop.qrstuvwxyzABCDEF.ghijklmnopqrstuv'
  Write-C34LOppoTransactionJson $fixture.AttestationPath $source
  $identity = Update-C34LOppoAttestationIdentity $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'source attestation contains a forbidden private value shape.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $coldArtifact = Get-Content -Raw -LiteralPath $fixture.ColdCapturePath |
    ConvertFrom-Json
  $coldArtifact.coldStartInteractive = $false
  Write-C34LOppoTransactionJson $fixture.ColdCapturePath $coldArtifact
  $arguments = Get-C34LOppoWriterArguments $fixture
  Invoke-C34LOppoWriterFailure $arguments `
    'capture artifact cold_start_observation SHA-256 or byte-length binding changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $coldArtifact = Get-Content -Raw -LiteralPath $fixture.ColdCapturePath |
    ConvertFrom-Json
  $coldArtifact | Add-Member -NotePropertyName deviceSerial `
    -NotePropertyValue 'forbidden-raw-device'
  Write-C34LOppoTransactionJson $fixture.ColdCapturePath $coldArtifact
  $identity = Update-C34LOppoCaptureGraph $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'capture artifact cold_start_observation contains forbidden private property deviceSerial.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $retainedArtifact = Get-Content -Raw -LiteralPath $fixture.RetainedCapturePath |
    ConvertFrom-Json
  $retainedArtifact.deviceBindingSha256 = 'E' * 64
  Write-C34LOppoTransactionJson $fixture.RetainedCapturePath $retainedArtifact
  $identity = Update-C34LOppoCaptureGraph $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'capture artifact retained_state_observation identity, device binding, producer or session changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $capture = Get-Content -Raw -LiteralPath $fixture.CapturePath |
    ConvertFrom-Json
  $capture.captureArtifacts[0].mediaType = 'text/plain'
  Write-C34LOppoTransactionJson $fixture.CapturePath $capture
  $identity = Update-C34LOppoAttestationCaptureIdentity $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'captureArtifacts cold_start_observation identity, path, hash, bytes or media type changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $capture = Get-Content -Raw -LiteralPath $fixture.CapturePath |
    ConvertFrom-Json
  $capture.captureArtifactContractSha256 = 'D' * 64
  Write-C34LOppoTransactionJson $fixture.CapturePath $capture
  $identity = Update-C34LOppoAttestationCaptureIdentity $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'capture-manifest identity, preimage, vector, artifact or session changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $capture = Get-Content -Raw -LiteralPath $fixture.CapturePath |
    ConvertFrom-Json
  $capture.captureArtifacts[0].role = 'retained_state_observation'
  Write-C34LOppoTransactionJson $fixture.CapturePath $capture
  $identity = Update-C34LOppoAttestationCaptureIdentity $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'capture manifest has an unknown, duplicate or cross-kind artifact role.'
  $count++
  return $count
}
function Invoke-C34LOppoTransactionNegatives {
  $count = 0
  $fixture = New-C34LOppoTransactionFixture
  $arguments = Get-C34LOppoWriterArguments $fixture 'prepared-none'
  Invoke-C34LOppoWriterFailure $arguments 'injected fixture crash: prepared-none'
  $journal = Get-Content -Raw -LiteralPath $fixture.JournalPath |
    ConvertFrom-Json
  $journal | Add-Member -NotePropertyName unexpectedField -NotePropertyValue 'x'
  Write-C34LOppoTransactionJson $fixture.JournalPath $journal
  $arguments = Get-C34LOppoWriterArguments $fixture
  Invoke-C34LOppoWriterFailure $arguments `
    'OPPO transaction journal property count changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $arguments = Get-C34LOppoWriterArguments $fixture 'prepared-none'
  Invoke-C34LOppoWriterFailure $arguments 'injected fixture crash: prepared-none'
  $journal = Get-Content -Raw -LiteralPath $fixture.JournalPath |
    ConvertFrom-Json
  $journal.coldStart.sha256 = 'D' * 64
  Write-C34LOppoTransactionJson $fixture.JournalPath $journal
  $arguments = Get-C34LOppoWriterArguments $fixture
  Invoke-C34LOppoWriterFailure $arguments `
    'OPPO transaction coldStart payload binding changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $arguments = Get-C34LOppoWriterArguments $fixture 'cold-moved'
  Invoke-C34LOppoWriterFailure $arguments 'injected fixture crash: cold-moved'
  $cold = Get-Content -Raw -LiteralPath $fixture.ColdPath | ConvertFrom-Json
  $cold | Add-Member -NotePropertyName unexpectedField -NotePropertyValue 'x'
  Write-C34LOppoTransactionJson $fixture.ColdPath $cold
  $arguments = Get-C34LOppoWriterArguments $fixture
  Invoke-C34LOppoWriterFailure $arguments `
    'cold OPPO evidence property count changed.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $arguments = Get-C34LOppoWriterArguments $fixture 'both-moved'
  Invoke-C34LOppoWriterFailure $arguments 'injected fixture crash: both-moved'
  $retained = Get-Content -Raw -LiteralPath $fixture.RetainedPath |
    ConvertFrom-Json
  $retained.installerPackage = 'https://private.example'
  Write-C34LOppoTransactionJson $fixture.RetainedPath $retained
  $arguments = Get-C34LOppoWriterArguments $fixture
  Invoke-C34LOppoWriterFailure $arguments `
    'retained OPPO evidence contains a forbidden private value shape.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $arguments = Get-C34LOppoWriterArguments $fixture 'both-moved'
  Invoke-C34LOppoWriterFailure $arguments 'injected fixture crash: both-moved'
  Remove-Item -LiteralPath $fixture.JournalPath -Force
  Remove-Item -LiteralPath $fixture.ColdPath -Force
  $arguments = Get-C34LOppoWriterArguments $fixture
  Invoke-C34LOppoWriterFailure $arguments `
    'untracked OPPO evidence exists without its transaction journal.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  [void](Invoke-C34LOppoWriterSuccess $arguments)
  Remove-Item -LiteralPath $fixture.RetainedPath -Force
  $arguments = Get-C34LOppoWriterArguments $fixture
  Invoke-C34LOppoWriterFailure $arguments `
    'committed OPPO transaction is missing evidence.'
  $count++

  $fixture = New-C34LOppoTransactionFixture
  $arguments = Get-C34LOppoWriterArguments $fixture 'prepared-none'
  Invoke-C34LOppoWriterFailure $arguments 'injected fixture crash: prepared-none'
  $sourceRaw = Get-Content -Raw -LiteralPath $fixture.AttestationPath
  Write-C34LOppoTransactionText $fixture.AttestationPath (
    $sourceRaw.TrimEnd([char[]]@("`r", "`n")) + " `r`n"
  )
  $identity = Update-C34LOppoAttestationIdentity $fixture
  $arguments = Get-C34LOppoWriterArguments $fixture
  $arguments.SourceAttestationSha256 = $identity.Sha256
  $arguments.SourceAttestationBytes = $identity.Bytes
  Invoke-C34LOppoWriterFailure $arguments `
    'OPPO transaction sourceAttestation changed at sha256.'
  $count++
  return $count
}

function Invoke-C34LOppoReparseNegative {
  $fixture = New-C34LOppoTransactionFixture
  $attestationDirectory = Split-Path -Parent $fixture.AttestationPath
  $backing = Join-Path $fixture.Root 'attestation-backing'
  Move-Item -LiteralPath $attestationDirectory -Destination $backing
  [void](New-Item -ItemType Junction -Path $attestationDirectory -Target $backing)
  $reparseOwners.Add($attestationDirectory)
  $arguments = Get-C34LOppoWriterArguments $fixture
  Invoke-C34LOppoWriterFailure $arguments `
    'OPPO source attestation contains a reparse-point ancestor.'
  $captureFixture = New-C34LOppoTransactionFixture
  $captureDirectory = Split-Path -Parent $captureFixture.CapturePath
  $captureBacking = Join-Path $captureFixture.Root 'oppo-capture-backing'
  Move-Item -LiteralPath $captureDirectory -Destination $captureBacking
  [void](New-Item -ItemType Junction -Path $captureDirectory `
    -Target $captureBacking)
  $reparseOwners.Add($captureDirectory)
  $arguments = Get-C34LOppoWriterArguments $captureFixture
  Invoke-C34LOppoWriterFailure $arguments `
    'OPPO capture manifest contains a reparse-point ancestor.'
  return 2
}
try {
  Assert-C34LOppoTransactionFixture (
    Test-Path -LiteralPath $writer -PathType Leaf
  ) 'OPPO evidence writer is missing.'
  $crash = Invoke-C34LOppoCrashMatrix
  $attestationNegatives = Invoke-C34LOppoAttestationNegatives
  $transactionNegatives = Invoke-C34LOppoTransactionNegatives
  $reparseNegatives = Invoke-C34LOppoReparseNegative
  if ($NestedInvocationChild) {
    $nestedQualification = 'child'
  } else {
    $attestationOutput = @(& $attestationChecker -RepositoryRoot $root)
    Assert-C34LOppoTransactionFixture (
      $attestationOutput.Count -eq 1 -and
      [string]$attestationOutput[0] -match '"externalActions":0'
    ) 'preceding source-attestation checker did not retain zero-action scope.'
    $nestedOutput = @(& $PSCommandPath -RepositoryRoot $root `
      -NestedInvocationChild)
    Assert-C34LOppoTransactionFixture (
      $nestedOutput.Count -eq 1 -and
      [string]$nestedOutput[0] -match 'journalWireTokens=true' -and
      [string]$nestedOutput[0] -match 'nestedInvocationQualification=child' -and
      [string]$nestedOutput[0] -match 'externalActions=0'
    ) 'nested checker invocation did not retain the journal wire contract.'
    $nestedQualification = 'passed'
  }
  Write-Output (
    'C34L OPPO evidence transaction fixture passed: ' +
    "crashBoundaries=$($crash.CrashBoundaries); " +
    "recoveries=$($crash.Recoveries); " +
    "idempotentReplays=$($crash.IdempotentReplays); " +
    "attestationNegatives=$attestationNegatives; " +
    "transactionTamperPrivacyNegatives=$transactionNegatives; " +
    "reparseAncestorNegatives=$reparseNegatives; " +
    "nestedInvocationQualification=$nestedQualification; " +
    'journalWireTokens=true; canonicalVersionAllowed=true; ' +
    'realStateWrites=0; externalActions=0; ' +
    'privateValuesObserved=0.'
  )
} finally {
  foreach ($reparseOwner in @($reparseOwners)) {
    if (Test-Path -LiteralPath $reparseOwner) {
      $resolvedOwner = [IO.Path]::GetFullPath($reparseOwner)
      Assert-C34LOppoTransactionFixture (
        $resolvedOwner.StartsWith($rootPrefix,
          [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedOwner) -cin @('attestations','oppo') -and
        ((Get-Item -LiteralPath $resolvedOwner -Force).Attributes -band
          [IO.FileAttributes]::ReparsePoint)
      ) 'reparse fixture cleanup owner escaped its exact root.'
      $junctionOwner = Get-Item -LiteralPath $resolvedOwner -Force
      $junctionOwner.Delete()
      Assert-C34LOppoTransactionFixture (
        -not (Test-Path -LiteralPath $resolvedOwner)
      ) 'reparse fixture junction cleanup was incomplete.'
    }
  }
  foreach ($fixtureRoot in @($fixtureRoots)) {
    if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
      $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
      Assert-C34LOppoTransactionFixture (
        $resolvedFixture.StartsWith($rootPrefix,
          [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedFixture) -cmatch
          '^c34l-retained-evidence-fixtures-[0-9a-f]{32}$'
      ) 'fixture cleanup root escaped the exact unique prefix.'
      $fixtureOwner = Get-Item -LiteralPath $resolvedFixture -Force
      $fixtureOwner.Delete($true)
      Assert-C34LOppoTransactionFixture (
        -not (Test-Path -LiteralPath $resolvedFixture)
      ) 'fixture cleanup root deletion was incomplete.'
    }
  }
}
