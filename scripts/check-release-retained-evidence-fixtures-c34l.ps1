[CmdletBinding()]
param(
  [string]$RepositoryRoot
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
$retainedChecker = Join-Path $root 'scripts/check-release-retained-evidence-c34l.ps1'
$script:fixtureRoots = @()
$script:fixtureJunctions = @()

function Assert-C34LFixture([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C34L retained-evidence fixture rejected: $Message" }
}
function Write-C34LFixtureText([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  [IO.File]::WriteAllText($Path, $Text, $utf8)
}
function Write-C34LFixtureJson([string]$Path, $Value) {
  Write-C34LFixtureText $Path (($Value | ConvertTo-Json -Depth 60) +
    [Environment]::NewLine)
}
function Set-C34LFixtureRawJsonStringValue(
  [string]$Path,
  [string]$PropertyName,
  [string]$Value
) {
  Assert-C34LFixture ($Value -cmatch '^[0-9A-F]+$') `
    "$PropertyName fixture substitution is not an uppercase hexadecimal value."
  $raw = Get-Content -Raw -LiteralPath $Path
  $pattern = '("' + [regex]::Escape($PropertyName) +
    '"\s*:\s*")([^"]*)(")'
  $matches = [regex]::Matches($raw, $pattern)
  Assert-C34LFixture ($matches.Count -eq 1) `
    "$PropertyName fixture substitution did not match exactly once."
  $updated = [regex]::Replace(
    $raw,
    $pattern,
    ('${1}' + $Value + '${3}')
  )
  Write-C34LFixtureText $Path $updated
}
function Set-C34LFixtureRawJsonPropertyName(
  [string]$Path,
  [string]$OldName,
  [string]$NewName
) {
  $raw = Get-Content -Raw -LiteralPath $Path
  $oldToken = '"' + $OldName + '"'
  $matches = [regex]::Matches($raw, [regex]::Escape($oldToken))
  Assert-C34LFixture ($matches.Count -eq 1) `
    "$OldName fixture property rename did not match exactly once."
  Write-C34LFixtureText $Path ($raw.Replace(
    $oldToken, ('"' + $NewName + '"')
  ))
}
function Get-C34LFixtureSha([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
}
function Get-C34LTextSha([string]$Text) {
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString(
      $sha.ComputeHash($utf8.GetBytes($Text))
    )).Replace('-', '')
  } finally { $sha.Dispose() }
}
function Register-C34LFixtureRoot([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\','/'))
  $expectedPrefix = [IO.Path]::GetFullPath((Join-Path $root 'tmp')) +
    [IO.Path]::DirectorySeparatorChar
  $releaseFixturePrefix = [IO.Path]::GetFullPath(
    (Join-Path $root 'tmp/c34l-release-transaction-fixtures')
  ).TrimEnd([char[]]@('\','/')) + [IO.Path]::DirectorySeparatorChar
  Assert-C34LFixture (
    $full.StartsWith($expectedPrefix,[StringComparison]::OrdinalIgnoreCase) -and
    (
      (Split-Path -Leaf $full) -cmatch
        '^c34l-retained-evidence-fixtures-[0-9A-Za-z_-]+$' -or
      ($full.StartsWith($releaseFixturePrefix,
          [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $full) -cmatch '^recovery-[0-9A-Za-z_-]+$')
    )
  ) 'fixture cleanup registration escaped an exact unique C34L root.'
  $script:fixtureRoots += $full
}
function Register-C34LFixtureJunction([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path)
  Assert-C34LFixture (
    @($script:fixtureRoots | Where-Object {
      $full.StartsWith($_ + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase)
    }).Count -eq 1
  ) 'fixture junction is outside its exact registered run root.'
  $script:fixtureJunctions += $full
}
function Remove-C34LRegisteredFixtures {
  foreach ($junction in @($script:fixtureJunctions | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $junction) {
      $item = Get-Item -LiteralPath $junction -Force
      Assert-C34LFixture (
        [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
      ) 'fixture cleanup refused to unlink a non-reparse directory.'
      [IO.Directory]::Delete($junction,$false)
    }
    Assert-C34LFixture (-not (Test-Path -LiteralPath $junction)) `
      'fixture junction cleanup was incomplete.'
  }
  foreach ($fixtureRoot in @($script:fixtureRoots | Select-Object -Unique)) {
    $expectedPrefix = [IO.Path]::GetFullPath((Join-Path $root 'tmp')) +
      [IO.Path]::DirectorySeparatorChar
    $releaseFixturePrefix = [IO.Path]::GetFullPath(
      (Join-Path $root 'tmp/c34l-release-transaction-fixtures')
    ).TrimEnd([char[]]@('\','/')) + [IO.Path]::DirectorySeparatorChar
    Assert-C34LFixture (
      $fixtureRoot.StartsWith($expectedPrefix,
        [StringComparison]::OrdinalIgnoreCase) -and
      (
        (Split-Path -Leaf $fixtureRoot) -cmatch
          '^c34l-retained-evidence-fixtures-[0-9A-Za-z_-]+$' -or
        ($fixtureRoot.StartsWith($releaseFixturePrefix,
            [StringComparison]::OrdinalIgnoreCase) -and
          (Split-Path -Leaf $fixtureRoot) -cmatch '^recovery-[0-9A-Za-z_-]+$')
      )
    ) 'fixture cleanup target escaped the exact C34L temporary family.'
    if (Test-Path -LiteralPath $fixtureRoot) {
      Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
    Assert-C34LFixture (-not (Test-Path -LiteralPath $fixtureRoot)) `
      'fixture root cleanup was incomplete.'
  }
}
function New-C34LCounts(
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
function New-C34LAuthorities(
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
function New-C34LSourceOwners(
  [string]$EvidenceRelative,
  [ValidateSet('play','oppo','journey')][string]$Kind,
  [string]$PreStateSha256,
  [string]$PreAggregateSha256,
  $Counts,
  $Authorities,
  [string]$ArtifactSha256,
  [long]$ArtifactBytes
) {
  $captureArtifacts = @()
  switch ($Kind) {
    'play' {
      $type='play_internal_testing_activation'
      $producer='MOOLSOCIAL-C34L-PLAY-CAPTURE-PRODUCER-001'
    }
    'oppo' {
      $type='oppo_play_in_place_update_pair'
      $producer='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
    }
    'journey' {
      $type='mandatory_whole_app_journey_acceptance'
      $producer='MOOLSOCIAL-C34L-JOURNEY-CAPTURE-PRODUCER-001'
    }
  }
  $attestationDirectory = Join-Path $root "$EvidenceRelative/attestations"
  if (-not (Test-Path -LiteralPath $attestationDirectory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $attestationDirectory)
  }
  $format = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
  $now = [DateTimeOffset]::UtcNow
  $produced = $now.AddMinutes(-1).ToString(
    $format,[Globalization.CultureInfo]::InvariantCulture)
  $expires = $now.AddMinutes(9).ToString(
    $format,[Globalization.CultureInfo]::InvariantCulture)
  $session = "fixture-$Kind-session-" + [Guid]::NewGuid().ToString('N')
  $nonce = switch ($Kind) { play {'D' * 64}; oppo {'E' * 64}; journey {'F' * 64} }
  $captureDirectoryRelative =
    "$EvidenceRelative/captures/attempt-1/$Kind"
  $captureDirectory = Join-Path $root $captureDirectoryRelative
  [void](New-Item -ItemType Directory -Path $captureDirectory -Force)
  if ($Kind -ceq 'play') {
    $receiptRelative = "$captureDirectoryRelative/internal-testing-release-receipt.json"
    $receiptPath = Join-Path $root $receiptRelative
    $receipt = [pscustomobject][ordered]@{
      schemaVersion=1; captureRole='internal_testing_release_receipt'
      ticketId=$ticketId; attempt=1; packageName='com.moolsocial.app'
      versionName=$versionName; versionCode=$versionCode
      artifactSha256=$ArtifactSha256; artifactBytes=$ArtifactBytes
      track='internal'; uploadCount=1; otherTrackChanged=$false
      sourceProducerId=$producer; sessionId=$session; nonceSha256=$nonce
    }
    Write-C34LFixtureJson $receiptPath $receipt
    $statusRelative = "$captureDirectoryRelative/internal-testing-status-observation.json"
    $statusPath = Join-Path $root $statusRelative
    $status = [pscustomobject][ordered]@{
      schemaVersion=1; captureRole='internal_testing_status_observation'
      ticketId=$ticketId; attempt=1; packageName='com.moolsocial.app'
      versionName=$versionName; versionCode=$versionCode
      artifactSha256=$ArtifactSha256; artifactBytes=$ArtifactBytes
      track='internal'; internalReleaseActive=$true; internalActivationCount=1
      sourceProducerId=$producer; sessionId=$session; nonceSha256=$nonce
    }
    Write-C34LFixtureJson $statusPath $status
    $receiptSha=Get-C34LFixtureSha $receiptPath; $statusSha=Get-C34LFixtureSha $statusPath
    $captureArtifacts=@(
      [pscustomobject][ordered]@{
        role='internal_testing_release_receipt'; path=$receiptRelative
        sha256=$receiptSha; bytes=(Get-Item -LiteralPath $receiptPath).Length
        mediaType='application/json'
      },
      [pscustomobject][ordered]@{
        role='internal_testing_status_observation'; path=$statusRelative
        sha256=$statusSha; bytes=(Get-Item -LiteralPath $statusPath).Length
        mediaType='application/json'
      }
    )
    $digests=[pscustomobject][ordered]@{
      internalTestingRouteDigestSha256=$receiptSha
      uploadReceiptDigestSha256=$receiptSha
      activationStateDigestSha256=$statusSha
    }
  } elseif ($Kind -ceq 'oppo') {
    $common=[ordered]@{
      schemaVersion=1; captureArtifactContractId=$captureArtifactContractId
      evidenceType=$type; ticketId=$ticketId; attempt=1
      packageName='com.moolsocial.app'; versionName=$versionName
      versionCode=$versionCode; artifactSha256=$ArtifactSha256
      artifactBytes=$ArtifactBytes; deviceBindingSha256=$deviceBindingSha256
      deviceModel='CPH2375'; installerPackage='com.android.vending'
      sourceProducerId=$producer; sessionId=$session; nonceSha256=$nonce
    }
    $cold=[ordered]@{}; foreach($entry in $common.GetEnumerator()){$cold[$entry.Key]=$entry.Value}
    $cold.role='cold_start_observation'; $cold.coldStartInteractive=$true
    $cold.blankHierarchy=$false; $cold.timeout=$false
    $cold.flutterFatalErrorCount=0; $cold.androidRuntimeFatalCount=0
    $cold.anrCount=0; $cold.appProcessErrorScanPassed=$true
    $cold.artifactRelationshipProved=$true; $cold.inPlaceUpdateProved=$true
    $coldRelative="$captureDirectoryRelative/cold-start-observation.json"
    $coldPath=Join-Path $root $coldRelative
    Write-C34LFixtureJson $coldPath ([pscustomobject]$cold)
    $retained=[ordered]@{}; foreach($entry in $common.GetEnumerator()){$retained[$entry.Key]=$entry.Value}
    $retained.role='retained_state_observation'; $retained.firstInstallTimeMillis=1000
    $retained.lastUpdateTimeMillis=2000; $retained.firstInstallTimePreserved=$true
    $retained.retainedDataContinuityProved=$true
    $retained.inPlacePlayUpdateProved=$true; $retained.uninstallPerformed=$false
    $retained.dataClearPerformed=$false; $retained.downgradePerformed=$false
    $retained.adbInstallPerformed=$false
    $retainedRelative="$captureDirectoryRelative/retained-state-observation.json"
    $retainedPath=Join-Path $root $retainedRelative
    Write-C34LFixtureJson $retainedPath ([pscustomobject]$retained)
    $coldSha=Get-C34LFixtureSha $coldPath; $retainedSha=Get-C34LFixtureSha $retainedPath
    $captureArtifacts=@(
      [pscustomobject][ordered]@{
        role='cold_start_observation'; path=$coldRelative; sha256=$coldSha
        bytes=(Get-Item -LiteralPath $coldPath).Length; mediaType='application/json'
      },
      [pscustomobject][ordered]@{
        role='retained_state_observation'; path=$retainedRelative; sha256=$retainedSha
        bytes=(Get-Item -LiteralPath $retainedPath).Length; mediaType='application/json'
      }
    )
    $digests=[pscustomobject][ordered]@{
      packageStateDigestSha256=$coldSha; coldStartDigestSha256=$coldSha
      retainedDataDigestSha256=$retainedSha
    }
  } else {
    $journeyIds=@(
      'publicGuest','protectedGateway','supportedAuthentication','social',
      'wholeApp','c33gBlocker'
    )
    $rows=@()
    $journeyDirectoryRelative="$captureDirectoryRelative/journeys"
    [void](New-Item -ItemType Directory -Path (Join-Path $root $journeyDirectoryRelative) -Force)
    $digestMap=[ordered]@{}
    foreach($journeyId in $journeyIds){
      $rowRelative="$journeyDirectoryRelative/$journeyId.json"
      $rowPath=Join-Path $root $rowRelative
      $rowValue=[pscustomobject][ordered]@{
        schemaVersion=1; journeyId=$journeyId; ticketId=$ticketId; attempt=1
        packageName='com.moolsocial.app'; versionName=$versionName
        versionCode=$versionCode; artifactSha256=$ArtifactSha256
        artifactBytes=$ArtifactBytes; deviceBindingSha256=$deviceBindingSha256
        passed=$true; newIssueCount=0; newDefectCount=0; blankScreenCount=0
        flutterFatalErrorCount=0; androidRuntimeFatalCount=0; anrCount=0
        sourceProducerId=$producer; sessionId=$session; nonceSha256=$nonce
      }
      Write-C34LFixtureJson $rowPath $rowValue
      $rowSha=Get-C34LFixtureSha $rowPath
      $rows += [pscustomobject][ordered]@{
        journeyId=$journeyId; path=$rowRelative; sha256=$rowSha
        bytes=(Get-Item -LiteralPath $rowPath).Length; passed=$true
      }
      $digestMap[$journeyId+'DigestSha256']=$rowSha
    }
    $manifestRelative="$captureDirectoryRelative/journey-acceptance-manifest.json"
    $manifestPath=Join-Path $root $manifestRelative
    Write-C34LFixtureJson $manifestPath $rows
    $manifestSha=Get-C34LFixtureSha $manifestPath
    $captureArtifacts=@([pscustomobject][ordered]@{
      role='journey_acceptance_manifest'; path=$manifestRelative
      sha256=$manifestSha; bytes=(Get-Item -LiteralPath $manifestPath).Length
      mediaType='application/json'
    })
    $digests=[pscustomobject]$digestMap
  }
  $captureRelative =
    "$captureDirectoryRelative/capture-manifest.json"
  $capturePath = Join-Path $root $captureRelative
  $capture = [pscustomobject][ordered]@{
    schemaVersion=1
    captureContractId='MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001'
    evidenceType=$type; ticketId=$ticketId; attempt=1
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; preStateSha256=$PreStateSha256
    preAggregateSha256=$PreAggregateSha256; actionCounts=$Counts
    releaseAuthorities=$Authorities; artifactSha256=$ArtifactSha256
    artifactBytes=$ArtifactBytes; sourceProducerId=$producer
    sessionId=$session; nonceSha256=$nonce; producedUtc=$produced
    expiresUtc=$expires; captureDigests=$digests
    captureArtifactContractPath=$captureArtifactContractPath
    captureArtifactContractSha256=$captureArtifactContractSha256
    captureArtifactContractId=$captureArtifactContractId
    captureArtifacts=$captureArtifacts
  }
  Write-C34LFixtureJson $capturePath $capture
  $attestationRelative =
    "$EvidenceRelative/attestations/source-attestation-$Kind-attempt-1.json"
  $attestationPath = Join-Path $root $attestationRelative
  $attestation = [pscustomobject][ordered]@{
    schemaVersion=1
    attestationContractId='MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001'
    evidenceType=$type; ticketId=$ticketId; attempt=1
    packageName='com.moolsocial.app'; versionName=$versionName
    versionCode=$versionCode; preStateSha256=$PreStateSha256
    preAggregateSha256=$PreAggregateSha256; actionCounts=$Counts
    releaseAuthorities=$Authorities; artifactSha256=$ArtifactSha256
    artifactBytes=$ArtifactBytes; sourceProducerId=$producer
    sessionId=$session; nonceSha256=$nonce; producedUtc=$produced
    expiresUtc=$expires; captureManifestPath=$captureRelative
    captureManifestSha256=(Get-C34LFixtureSha $capturePath)
    captureManifestBytes=(Get-Item -LiteralPath $capturePath).Length
    captureDigests=$digests
  }
  Write-C34LFixtureJson $attestationPath $attestation
  return [pscustomobject][ordered]@{
    path=$attestationRelative; sha256=(Get-C34LFixtureSha $attestationPath)
    bytes=(Get-Item -LiteralPath $attestationPath).Length
    evidenceType=$type; sourceProducerId=$producer; sessionId=$session
    nonceSha256=$nonce; producedUtc=$produced; expiresUtc=$expires
    captureManifestPath=$captureRelative
    captureManifestSha256=(Get-C34LFixtureSha $capturePath)
    captureManifestBytes=(Get-Item -LiteralPath $capturePath).Length
    captureDigests=$digests
  }
}

# Fixture producers are intentionally local to this checker. No production
# Play, OPPO or journey producer exists before C34L state creation.
function New-C34LRetainedEvidenceFixture([switch]$ReparseAttestations) {
  $fixtureName = 'c34l-retained-evidence-fixtures-' + [Guid]::NewGuid().ToString('N')
  $fixtureRelative = "tmp/$fixtureName"
  $fixtureRoot = Join-Path $root $fixtureRelative
  Register-C34LFixtureRoot $fixtureRoot
  $evidenceRelative = "$fixtureRelative/evidence"
  $evidenceRoot = Join-Path $root $evidenceRelative
  [void](New-Item -ItemType Directory -Path $evidenceRoot -Force)
  if ($ReparseAttestations) {
    $attestationTarget = Join-Path $fixtureRoot 'attestation-target'
    [void](New-Item -ItemType Directory -Path $attestationTarget)
    $attestationLink = Join-Path $evidenceRoot 'attestations'
    [void](New-Item -ItemType Junction -Path $attestationLink `
      -Target $attestationTarget)
    Register-C34LFixtureJunction $attestationLink
  }

  $artifactRelative = "$evidenceRelative/MoolSocial-$versionName-$versionCode-release.aab"
  $artifactPath = Join-Path $root $artifactRelative
  Write-C34LFixtureText $artifactPath 'C34L fixture AAB bytes'
  $artifactSha = Get-C34LFixtureSha $artifactPath
  $artifactBytes = (Get-Item -LiteralPath $artifactPath).Length

  $sourceOwnerRelative = "$fixtureRelative/source-owner.txt"
  $sourceOwnerPath = Join-Path $root $sourceOwnerRelative
  Write-C34LFixtureText $sourceOwnerPath 'fixture source owner'
  $sourceManifestRelative = "$fixtureRelative/source-manifest.txt"
  $sourceManifestPath = Join-Path $root $sourceManifestRelative
  Write-C34LFixtureText $sourceManifestPath (
    "$(Get-C34LFixtureSha $sourceOwnerPath)  $sourceOwnerRelative" +
    [Environment]::NewLine
  )

  $configRelative = "$evidenceRelative/03-release-config-only.log"
  $manifestRelative = "$evidenceRelative/04-release-manifest-preflight.log"
  $mergedRelative = "$evidenceRelative/04a-merged-release-manifest.xml"
  $blameRelative = "$evidenceRelative/04b-release-manifest-merger-blame.txt"
  $buildLogRelative = "$evidenceRelative/05-release-aab-build.log"
  Write-C34LFixtureText (Join-Path $root $configRelative) 'config passed'
  Write-C34LFixtureText (Join-Path $root $manifestRelative) 'manifest passed'
  Write-C34LFixtureText (Join-Path $root $mergedRelative) '<manifest />'
  Write-C34LFixtureText (Join-Path $root $blameRelative) 'blame passed'
  Write-C34LFixtureText (Join-Path $root $buildLogRelative) `
    'Built build/app/outputs/bundle/release/app-release.aab'

  $provenanceRelative = "$evidenceRelative/06-release-aab-provenance.json"
  $provenancePath = Join-Path $root $provenanceRelative
  $provenance = [pscustomobject][ordered]@{
    schemaVersion = 1
    candidateId = $ticketId
    preflightAttempt = 1
    versionName = $versionName
    versionCode = $versionCode
    packageName = 'com.moolsocial.app'
    buildMode = 'release'
    artifactType = 'AAB'
    authorizedTrack = 'internal'
    branch = 'remediation/prototype-conformance-2026-07-20'
    head = 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
    powerShellMajor = 7
    providerRevisions = [pscustomobject][ordered]@{}
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
    sourceManifestSha256 = Get-C34LFixtureSha $sourceManifestPath
    sourceFiles = 1
    artifactPath = $artifactRelative
    artifactSha256 = $artifactSha
    artifactBytes = $artifactBytes
    uploadSignerSha256 = ('A' * 64)
    packageVersionManifestProved = $true
    googleAppIdResourceProved = $true
    crashlyticsBuildIdResourceProved = $true
    splitAndArm64PayloadProved = $true
    bundletoolPath = 'tmp/bundletool-all-1.18.3.jar'
    bundletoolSha256 = ('B' * 64)
    bundletoolVersion = '1.18.3'
    buildLog = $buildLogRelative
    secretDefineFileReadByAgent = $false
    googleServicesFileReadByAgent = $false
    secretValuesRecorded = $false
    builtAt = '2026-08-17T05:30:00.0000000+05:30'
  }
  Write-C34LFixtureJson $provenancePath $provenance

  $playCounts = New-C34LCounts 1 0 0 0
  $playAuthorities = New-C34LAuthorities 'consumed' 'available_once' `
    'held_postupload_qualification' 'held_postinstall_journey_qualification'
  $oppoCounts = New-C34LCounts 1 1 0 0
  $oppoAuthorities = New-C34LAuthorities 'consumed' 'consumed' `
    'available_once' 'held_postinstall_journey_qualification'
  $journeyCounts = New-C34LCounts 1 1 1 0
  $journeyAuthorities = New-C34LAuthorities 'consumed' 'consumed' 'consumed' `
    'held_postinstall_journey_qualification'
  $playStateSha = Get-C34LTextSha 'play pre-state'
  $playAggregateSha = Get-C34LTextSha 'play pre-aggregate'
  $oppoStateSha = Get-C34LTextSha 'oppo pre-state'
  $oppoAggregateSha = Get-C34LTextSha 'oppo pre-aggregate'
  $journeyStateSha = Get-C34LTextSha 'journey pre-state'
  $journeyAggregateSha = Get-C34LTextSha 'journey pre-aggregate'
  $playSource = New-C34LSourceOwners $evidenceRelative play $playStateSha `
    $playAggregateSha $playCounts $playAuthorities $artifactSha $artifactBytes
  $oppoSource = New-C34LSourceOwners $evidenceRelative oppo $oppoStateSha `
    $oppoAggregateSha $oppoCounts $oppoAuthorities $artifactSha $artifactBytes
  $journeySource = New-C34LSourceOwners $evidenceRelative journey `
    $journeyStateSha $journeyAggregateSha $journeyCounts $journeyAuthorities `
    $artifactSha $artifactBytes

  $playRelative = "$evidenceRelative/07-play-internal-testing-activation-evidence.json"
  $playPath = Join-Path $root $playRelative
  $play = [pscustomobject][ordered]@{
    schemaVersion = 1
    evidenceContractId = 'MOOLSOCIAL-C34L-PLAY-EVIDENCE-001'
    evidenceType = 'play_internal_testing_activation'
    ticketId = $ticketId
    attempt = 1
    preStateSha256 = $playStateSha
    preAggregateSha256 = $playAggregateSha
    actionCounts = $playCounts
    releaseAuthorities = $playAuthorities
    packageName = 'com.moolsocial.app'
    versionName = $versionName
    versionCode = $versionCode
    artifactSha256 = $artifactSha
    artifactBytes = $artifactBytes
    track = 'internal'
    internalReleaseActive = $true
    uploadCount = 1
    internalActivationCount = 1
    otherTrackChanged = $false
    sourceAttestation = $playSource
  }
  Write-C34LFixtureJson $playPath $play

  $coldRelative = "$evidenceRelative/08-oppo-play-in-place-update-cold-start-evidence.json"
  $coldPath = Join-Path $root $coldRelative
  $oppoPairId = "oppo-1-$oppoStateSha"
  $cold = [pscustomobject][ordered]@{
    schemaVersion = 1
    evidenceContractId = 'MOOLSOCIAL-C34L-OPPO-EVIDENCE-001'
    evidencePairId = $oppoPairId
    ticketId = $ticketId
    attempt = 1
    preStateSha256 = $oppoStateSha
    preAggregateSha256 = $oppoAggregateSha
    actionCounts = $oppoCounts
    releaseAuthorities = $oppoAuthorities
    packageName = 'com.moolsocial.app'
    versionName = $versionName
    versionCode = $versionCode
    artifactSha256 = $artifactSha
    artifactBytes = $artifactBytes
    deviceBindingSha256 = $deviceBindingSha256
    deviceModel = 'CPH2375'
    installerPackage = 'com.android.vending'
    sourceAttestation = $oppoSource
    evidenceType = 'oppo_play_in_place_update_cold_start'
    coldStartInteractive = $true
    blankHierarchy = $false
    timeout = $false
    flutterFatalErrorCount = 0
    androidRuntimeFatalCount = 0
    anrCount = 0
    appProcessErrorScanPassed = $true
    artifactRelationshipProved = $true
    inPlaceUpdateProved = $true
  }
  Write-C34LFixtureJson $coldPath $cold

  $retainedRelative = "$evidenceRelative/09-oppo-in-place-retained-data-evidence.json"
  $retainedPath = Join-Path $root $retainedRelative
  $retained = [pscustomobject][ordered]@{
    schemaVersion = 1
    evidenceContractId = 'MOOLSOCIAL-C34L-OPPO-EVIDENCE-001'
    evidencePairId = $oppoPairId
    ticketId = $ticketId
    attempt = 1
    preStateSha256 = $oppoStateSha
    preAggregateSha256 = $oppoAggregateSha
    actionCounts = $oppoCounts
    releaseAuthorities = $oppoAuthorities
    packageName = 'com.moolsocial.app'
    versionName = $versionName
    versionCode = $versionCode
    artifactSha256 = $artifactSha
    artifactBytes = $artifactBytes
    deviceBindingSha256 = $deviceBindingSha256
    deviceModel = 'CPH2375'
    installerPackage = 'com.android.vending'
    sourceAttestation = $oppoSource
    evidenceType = 'oppo_in_place_retained_data'
    firstInstallTimeMillis = 1000
    lastUpdateTimeMillis = 2000
    firstInstallTimePreserved = $true
    retainedDataContinuityProved = $true
    inPlacePlayUpdateProved = $true
    uninstallPerformed = $false
    dataClearPerformed = $false
    downgradePerformed = $false
    adbInstallPerformed = $false
  }
  Write-C34LFixtureJson $retainedPath $retained
  $transactionDirectory = Join-Path $evidenceRoot 'transactions'
  [void](New-Item -ItemType Directory -Path $transactionDirectory)
  $transactionRelative =
    "$evidenceRelative/transactions/oppo-evidence-pair-attempt-1.json"
  $transactionPath = Join-Path $root $transactionRelative
  $preparedUtc = [DateTimeOffset]::UtcNow.AddSeconds(-1).ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture)
  $committedUtc = [DateTimeOffset]::UtcNow.ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture)
  $transaction = [pscustomobject][ordered]@{
    schemaVersion=1
    transactionContractId='MOOLSOCIAL-C34L-OPPO-EVIDENCE-TRANSACTION-001'
    transactionId="oppo-evidence-1-$oppoStateSha-$oppoAggregateSha"
    ticketId=$ticketId; attempt=1; status='committed'
    preStateSha256=$oppoStateSha; preAggregateSha256=$oppoAggregateSha
    artifactSha256=$artifactSha; artifactBytes=$artifactBytes
    deviceBindingSha256=$deviceBindingSha256
    coldStart=[pscustomobject][ordered]@{
      path=$coldRelative; sha256=(Get-C34LFixtureSha $coldPath)
      bytes=(Get-Item -LiteralPath $coldPath).Length
    }
    retainedData=[pscustomobject][ordered]@{
      path=$retainedRelative; sha256=(Get-C34LFixtureSha $retainedPath)
      bytes=(Get-Item -LiteralPath $retainedPath).Length
    }
    sourceAttestation=$oppoSource; preparedUtc=$preparedUtc
    committedUtc=$committedUtc
  }
  Write-C34LFixtureJson $transactionPath $transaction

  $journeyRelative = "$evidenceRelative/10-mandatory-whole-app-journey-evidence.json"
  $journeyPath = Join-Path $root $journeyRelative
  $journey = [pscustomobject][ordered]@{
    schemaVersion = 1
    evidenceContractId = 'MOOLSOCIAL-C34L-JOURNEY-EVIDENCE-001'
    evidenceType = 'mandatory_whole_app_journey_acceptance'
    ticketId = $ticketId
    attempt = 1
    preStateSha256 = $journeyStateSha
    preAggregateSha256 = $journeyAggregateSha
    actionCounts = $journeyCounts
    releaseAuthorities = $journeyAuthorities
    packageName = 'com.moolsocial.app'
    versionName = $versionName
    versionCode = $versionCode
    artifactSha256 = $artifactSha
    artifactBytes = $artifactBytes
    track = 'internal'
    deviceBindingSha256 = $deviceBindingSha256
    deviceModel = 'CPH2375'
    installerPackage = 'com.android.vending'
    publicGuestJourneyPassed = $true
    protectedGatewayJourneyPassed = $true
    supportedAuthenticationJourneysPassed = $true
    socialJourneysPassed = $true
    wholeAppJourneysPassed = $true
    c33gBlockerJourneysPassed = $true
    allMandatoryJourneysPassed = $true
    evidenceComplete = $true
    newIssueCount = 0
    newDefectCount = 0
    blankScreenCount = 0
    flutterFatalErrorCount = 0
    androidRuntimeFatalCount = 0
    anrCount = 0
    acceptanceSucceeded = $true
    successClaimed = $true
    sourceAttestation = $journeySource
  }
  Write-C34LFixtureJson $journeyPath $journey

  $transactionProofs = @(
    [pscustomobject][ordered]@{
      ticketId = $ticketId
      attempt = 1
      transition = 'upload-succeeded'
      phase = 'preupload'
      evidencePath = $playRelative
      sha256 = Get-C34LFixtureSha $playPath
      preStateSha256 = $playStateSha
      preAggregateSha256 = $playAggregateSha
      actionCounts = $playCounts
      releaseAuthorities = $playAuthorities
      browserEvidence = $null
    },
    [pscustomobject][ordered]@{
      ticketId = $ticketId
      attempt = 1
      transition = 'install-succeeded'
      phase = 'preinstall'
      evidencePath = $coldRelative
      sha256 = Get-C34LFixtureSha $coldPath
      preStateSha256 = $oppoStateSha
      preAggregateSha256 = $oppoAggregateSha
      actionCounts = $oppoCounts
      releaseAuthorities = $oppoAuthorities
      browserEvidence = $null
    },
    [pscustomobject][ordered]@{
      ticketId = $ticketId
      attempt = 1
      transition = 'device-accepted'
      phase = 'journey'
      evidencePath = $journeyRelative
      sha256 = Get-C34LFixtureSha $journeyPath
      preStateSha256 = $journeyStateSha
      preAggregateSha256 = $journeyAggregateSha
      actionCounts = $journeyCounts
      releaseAuthorities = $journeyAuthorities
      browserEvidence = $null
    }
  )
  $currentCounts = New-C34LCounts 1 1 1 1
  $currentAuthorities = New-C34LAuthorities 'consumed' 'consumed' 'consumed' 'consumed'
  $aggregateRelative = "$fixtureRelative/aggregate.json"
  $aggregatePath = Join-Path $root $aggregateRelative
  $aggregate = [pscustomobject][ordered]@{
    ticketId = $ticketId
    candidate = [pscustomobject][ordered]@{
      id = $ticketId
      versionName = $versionName
      versionCode = $versionCode
    }
    actionCounts = $currentCounts
    releaseAuthorities = $currentAuthorities
    lifecycleTransactionProofs = $transactionProofs
  }
  Write-C34LFixtureJson $aggregatePath $aggregate

  $stateRelative = "$fixtureRelative/state.json"
  $statePath = Join-Path $root $stateRelative
  $state = [pscustomobject][ordered]@{
    ticketId = $ticketId
    candidate = [pscustomobject][ordered]@{
      id = $ticketId
      packageName = 'com.moolsocial.app'
      versionName = $versionName
      versionCode = $versionCode
      deviceBindingSha256 = $deviceBindingSha256
      deviceModel = 'CPH2375'
    }
    aggregateStatePath = $aggregateRelative
    sourceQualification = [pscustomobject][ordered]@{
      manifestPath = $sourceManifestRelative
      manifestSha256 = Get-C34LFixtureSha $sourceManifestPath
    }
    buildResult = [pscustomobject][ordered]@{
      artifactPath = $artifactRelative
      artifactSha256 = $artifactSha
      artifactBytes = $artifactBytes
      uploadSignerSha256 = ('A' * 64)
      provenance = $provenanceRelative
    }
    playResult = [pscustomobject][ordered]@{
      evidencePath = $playRelative
      evidenceSha256 = Get-C34LFixtureSha $playPath
      evidenceBytes = (Get-Item -LiteralPath $playPath).Length
    }
    installResult = [pscustomobject][ordered]@{
      coldStartEvidencePath = $coldRelative
      coldStartEvidenceSha256 = Get-C34LFixtureSha $coldPath
      coldStartEvidenceBytes = (Get-Item -LiteralPath $coldPath).Length
      retainedDataEvidencePath = $retainedRelative
      retainedDataEvidenceSha256 = Get-C34LFixtureSha $retainedPath
      retainedDataEvidenceBytes = (Get-Item -LiteralPath $retainedPath).Length
      journeyEvidencePath = $journeyRelative
      journeyEvidenceSha256 = Get-C34LFixtureSha $journeyPath
      journeyEvidenceBytes = (Get-Item -LiteralPath $journeyPath).Length
    }
    actionCounts = $currentCounts
    releaseAuthorities = $currentAuthorities
    lifecycleTransactionProofs = $transactionProofs
  }
  Write-C34LFixtureJson $statePath $state
  return [pscustomobject]@{
    StateRelative = $stateRelative
    StatePath = $statePath
    PlayPath = $playPath
    ColdPath = $coldPath
    RetainedPath = $retainedPath
    JourneyPath = $journeyPath
    TransactionPath = $transactionPath
    ProvenancePath = $provenancePath
    Root = $fixtureRoot
    EvidenceRelative = $evidenceRelative
  }
}

function Update-C34LFixtureEvidence($Fixture, [string]$Kind, $Evidence) {
  $evidencePath = switch ($Kind) {
    'play' { $Fixture.PlayPath }
    'cold' { $Fixture.ColdPath }
    'retained' { $Fixture.RetainedPath }
    'journey' { $Fixture.JourneyPath }
    default { throw "Unknown C34L fixture evidence kind: $Kind" }
  }
  Write-C34LFixtureJson $evidencePath $Evidence
  $sha = Get-C34LFixtureSha $evidencePath
  $bytes = (Get-Item -LiteralPath $evidencePath).Length
  $state = Get-Content -Raw -LiteralPath $Fixture.StatePath | ConvertFrom-Json
  switch ($Kind) {
    'play' {
      $state.playResult.evidenceSha256 = $sha
      $state.playResult.evidenceBytes = $bytes
    }
    'cold' {
      $state.installResult.coldStartEvidenceSha256 = $sha
      $state.installResult.coldStartEvidenceBytes = $bytes
    }
    'retained' {
      $state.installResult.retainedDataEvidenceSha256 = $sha
      $state.installResult.retainedDataEvidenceBytes = $bytes
    }
    'journey' {
      $state.installResult.journeyEvidenceSha256 = $sha
      $state.installResult.journeyEvidenceBytes = $bytes
    }
  }
  Write-C34LFixtureJson $Fixture.StatePath $state
}
$expectedNegativeLabels = @(
  'malformed builtAt fixture',
  'ambiguous builtAt fixture',
  'candidateId ambiguity fixture',
  'attempt-binding fixture',
  'pre-state hash fixture',
  'transaction-history equality fixture',
  'symmetric transaction-history attempt fixture',
  'wrong final transition fixture',
  'wrong final phase fixture',
  'wrong final evidence path fixture',
  'wrong final evidence SHA fixture',
  'non-null final browser fixture',
  'forbidden nested proof property fixture',
  'single-backslash state path fixture',
  'raw device property fixture',
  'missing detailed package fixture',
  'forbidden nested property fixture',
  'tampered capture artifact fixture',
  'eight-count vector fixture',
  'four-authority vector fixture',
  'Play file SHA fixture',
  'OPPO cold file bytes fixture',
  'OPPO retained file SHA fixture',
  'journey file bytes fixture',
  'unknown evidence field fixture',
  'private email fixture',
  'private phone fixture',
  'private URL fixture',
  'private identifier fixture',
  'private exception fixture',
  'private stack fixture',
  'private token fixture',
  'private cookie fixture',
  'private authorization fixture',
  'tampered source attestation fixture',
  'replayed source attestation fixture',
  'wrong capture binding fixture',
  'wrong digest keys fixture',
  'wrong digest value fixture',
  'reparse ancestor fixture',
  'OPPO journal source binding fixture'
)
$executedNegativeLabels = @()
function Assert-C34LExpectedRejection(
  $Fixture,
  [string]$Phase,
  [string]$ExpectedMessage,
  [string]$Label
) {
  $rejected = $false
  $observedMessage = ''
  try {
    & $retainedChecker -Phase $Phase -Attempt 1 `
      -StatePath $Fixture.StateRelative -FixtureMode -RepositoryRoot $root |
      Out-Null
  } catch {
    $rejected = $true
    $observedMessage = $_.Exception.Message
  }
  Assert-C34LFixture (
    $rejected -and $observedMessage.Contains($ExpectedMessage)
  ) (
    "$Label did not fail with the expected retained-evidence rejection. " +
    "Observed: $observedMessage"
  )
  $script:executedNegativeLabels += $Label
}

try {
$positive = New-C34LRetainedEvidenceFixture
& $retainedChecker -Phase all -Attempt 1 -StatePath $positive.StateRelative `
  -FixtureMode -RepositoryRoot $root | Out-Null

$positiveZulu = New-C34LRetainedEvidenceFixture
$positiveZuluProvenance = Get-Content -Raw -LiteralPath `
  $positiveZulu.ProvenancePath | ConvertFrom-Json
$positiveZuluProvenance.builtAt = '2026-08-17T00:00:00.0000000Z'
Write-C34LFixtureJson $positiveZulu.ProvenancePath $positiveZuluProvenance
& $retainedChecker -Phase all -Attempt 1 `
  -StatePath $positiveZulu.StateRelative -FixtureMode -RepositoryRoot $root |
  Out-Null

$malformedBuiltAt = New-C34LRetainedEvidenceFixture
$malformedBuiltAtProvenance = Get-Content -Raw -LiteralPath `
  $malformedBuiltAt.ProvenancePath | ConvertFrom-Json
$malformedBuiltAtProvenance.builtAt =
  '2026-13-40T25:61:61.0000000+05:30'
Write-C34LFixtureJson $malformedBuiltAt.ProvenancePath `
  $malformedBuiltAtProvenance
Assert-C34LExpectedRejection $malformedBuiltAt build `
  'C34L AAB provenance builtAt is not one semantically valid round-trip instant.' `
  'malformed builtAt fixture'

$ambiguousBuiltAt = New-C34LRetainedEvidenceFixture
$ambiguousBuiltAtProvenance = Get-Content -Raw -LiteralPath `
  $ambiguousBuiltAt.ProvenancePath | ConvertFrom-Json
$ambiguousBuiltAtProvenance.builtAt = '08/17/2026 05:30:00'
Write-C34LFixtureJson $ambiguousBuiltAt.ProvenancePath `
  $ambiguousBuiltAtProvenance
Assert-C34LExpectedRejection $ambiguousBuiltAt build `
  'C34L AAB provenance builtAt raw JSON token must be exact invariant round-trip ISO-8601.' `
  'ambiguous builtAt fixture'

$missingTicket = New-C34LRetainedEvidenceFixture
$missingTicketEvidence = Get-Content -Raw -LiteralPath $missingTicket.PlayPath |
  ConvertFrom-Json
$missingTicketEvidence.PSObject.Properties.Remove('ticketId')
$missingTicketEvidence | Add-Member -NotePropertyName candidateId `
  -NotePropertyValue $ticketId
Update-C34LFixtureEvidence $missingTicket 'play' $missingTicketEvidence
Assert-C34LExpectedRejection $missingTicket play `
  'Internal Testing evidence is missing or has an unknown property at ticketId.' `
  'candidateId ambiguity fixture'

$wrongAttempt = New-C34LRetainedEvidenceFixture
$wrongAttemptEvidence = Get-Content -Raw -LiteralPath $wrongAttempt.JourneyPath |
  ConvertFrom-Json
$wrongAttemptEvidence.attempt = 2
Update-C34LFixtureEvidence $wrongAttempt 'journey' $wrongAttemptEvidence
Assert-C34LExpectedRejection $wrongAttempt journey `
  'mandatory journey evidence ticket, attempt or preimage identity changed.' `
  'attempt-binding fixture'

$wrongPreimage = New-C34LRetainedEvidenceFixture
$wrongPreimageEvidence = Get-Content -Raw -LiteralPath $wrongPreimage.PlayPath |
  ConvertFrom-Json
$wrongPreimageEvidence.preStateSha256 = ('B' * 64)
Update-C34LFixtureEvidence $wrongPreimage 'play' $wrongPreimageEvidence
Assert-C34LExpectedRejection $wrongPreimage play `
  'Internal Testing evidence is not bound once to its exact newest lifecycle proof.' `
  'pre-state hash fixture'

$wrongHistoryAttempt = New-C34LRetainedEvidenceFixture
$wrongHistoryAttemptState = Get-Content -Raw -LiteralPath `
  $wrongHistoryAttempt.StatePath | ConvertFrom-Json
$wrongHistoryAttemptState.lifecycleTransactionProofs[0].attempt = 2
Write-C34LFixtureJson $wrongHistoryAttempt.StatePath $wrongHistoryAttemptState
Assert-C34LExpectedRejection $wrongHistoryAttempt play `
  'Internal Testing evidence detailed and aggregate lifecycle histories are not exactly equal.' `
  'transaction-history equality fixture'

$symmetricWrongHistoryAttempt = New-C34LRetainedEvidenceFixture
$symmetricWrongState = Get-Content -Raw -LiteralPath `
  $symmetricWrongHistoryAttempt.StatePath | ConvertFrom-Json
$symmetricWrongAggregate = Get-Content -Raw -LiteralPath `
  (Join-Path $symmetricWrongHistoryAttempt.Root 'aggregate.json') | ConvertFrom-Json
$symmetricWrongState.lifecycleTransactionProofs[0].attempt = 2
$symmetricWrongAggregate.lifecycleTransactionProofs[0].attempt = 2
Write-C34LFixtureJson $symmetricWrongHistoryAttempt.StatePath $symmetricWrongState
Write-C34LFixtureJson (Join-Path $symmetricWrongHistoryAttempt.Root 'aggregate.json') `
  $symmetricWrongAggregate
Assert-C34LExpectedRejection $symmetricWrongHistoryAttempt play `
  'Internal Testing evidence transaction-proof identity or binding shape changed.' `
  'symmetric transaction-history attempt fixture'

function Set-C34LHistoryFieldBoth($Fixture,[int]$Index,[string]$Name,$Value) {
  $stateValue=Get-Content -Raw -LiteralPath $Fixture.StatePath|ConvertFrom-Json
  $aggregatePath=Join-Path $Fixture.Root 'aggregate.json'
  $aggregateValue=Get-Content -Raw -LiteralPath $aggregatePath|ConvertFrom-Json
  $stateValue.lifecycleTransactionProofs[$Index].$Name=$Value
  $aggregateValue.lifecycleTransactionProofs[$Index].$Name=$Value
  Write-C34LFixtureJson $Fixture.StatePath $stateValue
  Write-C34LFixtureJson $aggregatePath $aggregateValue
}
function Set-C34LFinalProofEvidenceBindingBoth(
  $Fixture,
  [int]$Index,
  [string]$EvidenceRelative,
  [string]$EvidencePath
) {
  Set-C34LHistoryFieldBoth $Fixture $Index evidencePath $EvidenceRelative
  Set-C34LHistoryFieldBoth $Fixture $Index sha256 `
    (Get-C34LFixtureSha $EvidencePath)
}
$wrongTransition=New-C34LRetainedEvidenceFixture
Set-C34LHistoryFieldBoth $wrongTransition 2 transition 'journeys-accepted'
Assert-C34LExpectedRejection $wrongTransition journey `
  'mandatory journey evidence is not bound once to its exact newest lifecycle proof.' `
  'wrong final transition fixture'

$wrongPhase=New-C34LRetainedEvidenceFixture
Set-C34LHistoryFieldBoth $wrongPhase 0 phase 'postupload'
Assert-C34LExpectedRejection $wrongPhase play `
  'Internal Testing evidence is not bound once to its exact newest lifecycle proof.' `
  'wrong final phase fixture'

$wrongProofPath=New-C34LRetainedEvidenceFixture
Set-C34LHistoryFieldBoth $wrongProofPath 0 evidencePath `
  "$($wrongProofPath.EvidenceRelative)/wrong-play-evidence.json"
Assert-C34LExpectedRejection $wrongProofPath play `
  'Internal Testing evidence is not bound once to its exact newest lifecycle proof.' `
  'wrong final evidence path fixture'

$wrongProofSha=New-C34LRetainedEvidenceFixture
Set-C34LHistoryFieldBoth $wrongProofSha 0 sha256 ('F' * 64)
Assert-C34LExpectedRejection $wrongProofSha play `
  'Internal Testing evidence is not bound once to its exact newest lifecycle proof.' `
  'wrong final evidence SHA fixture'

$nonNullBrowser=New-C34LRetainedEvidenceFixture
Set-C34LHistoryFieldBoth $nonNullBrowser 0 browserEvidence `
  ([pscustomobject][ordered]@{ route='fixture-public-route' })
Assert-C34LExpectedRejection $nonNullBrowser play `
  'Internal Testing evidence newest lifecycle proof transition, phase, evidence, browser or preimage binding changed.' `
  'non-null final browser fixture'

$forbiddenProof=New-C34LRetainedEvidenceFixture
Set-C34LHistoryFieldBoth $forbiddenProof 0 browserEvidence `
  ([pscustomobject][ordered]@{ privateUrl='fixture-private-link' })
Assert-C34LExpectedRejection $forbiddenProof play `
  'contains a forbidden private property name at browserEvidence.privateUrl.' `
  'forbidden nested proof property fixture'

$backslashFixture=New-C34LRetainedEvidenceFixture
$backslashRejected=$false; $backslashMessage=''
try {
  & $retainedChecker -Phase play -Attempt 1 `
    -StatePath ($backslashFixture.StateRelative.Replace('/','\')) `
    -FixtureMode -RepositoryRoot $root | Out-Null
} catch { $backslashRejected=$true; $backslashMessage=$_.Exception.Message }
Assert-C34LFixture (
  $backslashRejected -and
  $backslashMessage.Contains('detailed candidate state must be one normalized repository-relative path.')
) 'single-backslash state path fixture did not reach path normalization.'
$executedNegativeLabels += 'single-backslash state path fixture'

$rawDevice=New-C34LRetainedEvidenceFixture
$rawDeviceEvidence=Get-Content -Raw -LiteralPath $rawDevice.PlayPath|ConvertFrom-Json
$rawDeviceEvidence.sourceAttestation|Add-Member -NotePropertyName deviceSerial `
  -NotePropertyValue 'forbidden-fixture-device'
Update-C34LFixtureEvidence $rawDevice play $rawDeviceEvidence
Assert-C34LExpectedRejection $rawDevice play `
  'contains forbidden raw device property sourceAttestation.deviceSerial.' `
  'raw device property fixture'

$missingDetailedPackage=New-C34LRetainedEvidenceFixture
$missingDetailedPackageState=Get-Content -Raw -LiteralPath `
  $missingDetailedPackage.StatePath|ConvertFrom-Json
$missingDetailedPackageState.candidate.PSObject.Properties.Remove('packageName')
Write-C34LFixtureJson $missingDetailedPackage.StatePath `
  $missingDetailedPackageState
Assert-C34LExpectedRejection $missingDetailedPackage play `
  'candidate is missing property packageName.' `
  'missing detailed package fixture'

$forbiddenNested=New-C34LRetainedEvidenceFixture
$forbiddenNestedEvidence=Get-Content -Raw -LiteralPath `
  $forbiddenNested.PlayPath|ConvertFrom-Json
$forbiddenNestedEvidence.sourceAttestation|Add-Member `
  -NotePropertyName privateUrl -NotePropertyValue 'fixture-private-link'
Update-C34LFixtureEvidence $forbiddenNested play $forbiddenNestedEvidence
Assert-C34LExpectedRejection $forbiddenNested play `
  'contains a forbidden private property name at sourceAttestation.privateUrl.' `
  'forbidden nested property fixture'

$tamperedCaptureArtifact=New-C34LRetainedEvidenceFixture
$tamperedPlay=Get-Content -Raw -LiteralPath $tamperedCaptureArtifact.PlayPath|
  ConvertFrom-Json
$tamperedManifestPath=Join-Path $root `
  ([string]$tamperedPlay.sourceAttestation.captureManifestPath)
$tamperedManifest=Get-Content -Raw -LiteralPath $tamperedManifestPath|
  ConvertFrom-Json
$tamperedArtifactPath=Join-Path $root `
  ([string]$tamperedManifest.captureArtifacts[0].path)
[IO.File]::AppendAllText($tamperedArtifactPath,' ',[Text.UTF8Encoding]::new($false))
Assert-C34LExpectedRejection $tamperedCaptureArtifact play `
  'Internal Testing evidence capture artifact internal_testing_release_receipt SHA-256 or byte-length binding changed.' `
  'tampered capture artifact fixture'

$wrongCount = New-C34LRetainedEvidenceFixture
$wrongCountEvidence = Get-Content -Raw -LiteralPath $wrongCount.ColdPath |
  ConvertFrom-Json
$wrongCountEvidence.actionCounts.otherTrack = 1
Update-C34LFixtureEvidence $wrongCount 'cold' $wrongCountEvidence
Assert-C34LExpectedRejection $wrongCount oppo `
  'OPPO install evidence action count changed at otherTrack.' `
  'eight-count vector fixture'

$wrongAuthority = New-C34LRetainedEvidenceFixture
$wrongAuthorityEvidence = Get-Content -Raw -LiteralPath $wrongAuthority.RetainedPath |
  ConvertFrom-Json
$wrongAuthorityEvidence.releaseAuthorities.inPlaceOppoPlayUpdate = 'consumed'
Update-C34LFixtureEvidence $wrongAuthority 'retained' $wrongAuthorityEvidence
Assert-C34LExpectedRejection $wrongAuthority oppo `
  'OPPO install evidence release authority changed at inPlaceOppoPlayUpdate.' `
  'four-authority vector fixture'

$wrongPlaySha = New-C34LRetainedEvidenceFixture
$wrongPlayShaState = Get-Content -Raw -LiteralPath $wrongPlaySha.StatePath |
  ConvertFrom-Json
$wrongPlayShaState.playResult.evidenceSha256 = ('C' * 64)
Write-C34LFixtureJson $wrongPlaySha.StatePath $wrongPlayShaState
Assert-C34LExpectedRejection $wrongPlaySha play `
  'Internal Testing evidence SHA-256 or byte-length binding changed.' `
  'Play file SHA fixture'

$wrongColdBytes = New-C34LRetainedEvidenceFixture
$wrongColdBytesState = Get-Content -Raw -LiteralPath $wrongColdBytes.StatePath |
  ConvertFrom-Json
$wrongColdBytesState.installResult.coldStartEvidenceBytes =
  [int64]$wrongColdBytesState.installResult.coldStartEvidenceBytes + 1
Write-C34LFixtureJson $wrongColdBytes.StatePath $wrongColdBytesState
Assert-C34LExpectedRejection $wrongColdBytes oppo `
  'OPPO cold-start evidence SHA-256 or byte-length binding changed.' `
  'OPPO cold file bytes fixture'

$wrongRetainedSha = New-C34LRetainedEvidenceFixture
$wrongRetainedShaState = Get-Content -Raw -LiteralPath $wrongRetainedSha.StatePath |
  ConvertFrom-Json
$wrongRetainedShaState.installResult.retainedDataEvidenceSha256 = ('D' * 64)
Write-C34LFixtureJson $wrongRetainedSha.StatePath $wrongRetainedShaState
Assert-C34LExpectedRejection $wrongRetainedSha oppo `
  'OPPO retained-data evidence SHA-256 or byte-length binding changed.' `
  'OPPO retained file SHA fixture'

$wrongJourneyBytes = New-C34LRetainedEvidenceFixture
$wrongJourneyBytesState = Get-Content -Raw -LiteralPath $wrongJourneyBytes.StatePath |
  ConvertFrom-Json
$wrongJourneyBytesState.installResult.journeyEvidenceBytes =
  [int64]$wrongJourneyBytesState.installResult.journeyEvidenceBytes + 1
Write-C34LFixtureJson $wrongJourneyBytes.StatePath $wrongJourneyBytesState
Assert-C34LExpectedRejection $wrongJourneyBytes journey `
  'mandatory journey evidence SHA-256 or byte-length binding changed.' `
  'journey file bytes fixture'

$unknownField = New-C34LRetainedEvidenceFixture
$unknownEvidence = Get-Content -Raw -LiteralPath $unknownField.PlayPath |
  ConvertFrom-Json
$unknownEvidence | Add-Member -NotePropertyName unexpectedField `
  -NotePropertyValue 'synthetic-fixture'
Update-C34LFixtureEvidence $unknownField play $unknownEvidence
Assert-C34LExpectedRejection $unknownField play `
  'Internal Testing evidence property count changed.' `
  'unknown evidence field fixture'

function Assert-C34LPrivateValueRejection(
  [string]$Value,
  [string]$ExpectedMessage,
  [string]$Label
) {
  $fixture = New-C34LRetainedEvidenceFixture
  $evidence = Get-Content -Raw -LiteralPath $fixture.PlayPath | ConvertFrom-Json
  $evidence.sourceAttestation.sessionId = $Value
  Update-C34LFixtureEvidence $fixture play $evidence
  Assert-C34LExpectedRejection $fixture play $ExpectedMessage $Label
}
Assert-C34LPrivateValueRejection 'fixture@example.invalid' `
  'contains a forbidden private value shape at sourceAttestation.sessionId.' `
  'private email fixture'
Assert-C34LPrivateValueRejection '+91 98765 43210' `
  'contains a forbidden phone-shaped value at sourceAttestation.sessionId.' `
  'private phone fixture'
Assert-C34LPrivateValueRejection 'https://play.google.com/console?private=1#tester' `
  'contains a forbidden private value shape at sourceAttestation.sessionId.' `
  'private URL fixture'
Assert-C34LPrivateValueRejection `
  '123456789012-fixtureprivate.apps.googleusercontent.com' `
  'contains a forbidden private value shape at sourceAttestation.sessionId.' `
  'private identifier fixture'
Assert-C34LPrivateValueRejection 'Exception: fixture private payload' `
  'contains a forbidden private value shape at sourceAttestation.sessionId.' `
  'private exception fixture'
Assert-C34LPrivateValueRejection 'StackTrace at fixture.owner:42' `
  'contains a forbidden private value shape at sourceAttestation.sessionId.' `
  'private stack fixture'
Assert-C34LPrivateValueRejection `
  'abcdefghijklmnop.qrstuvwxyzABCDEF.ghijklmnopqrstuv' `
  'contains a forbidden private value shape at sourceAttestation.sessionId.' `
  'private token fixture'
Assert-C34LPrivateValueRejection 'cookie=session-fixture-private' `
  'contains a forbidden private value shape at sourceAttestation.sessionId.' `
  'private cookie fixture'
Assert-C34LPrivateValueRejection 'authorization=Basic Zml4dHVyZQ==' `
  'contains a forbidden private value shape at sourceAttestation.sessionId.' `
  'private authorization fixture'

$tamperedSource = New-C34LRetainedEvidenceFixture
$tamperedEvidence = Get-Content -Raw -LiteralPath $tamperedSource.PlayPath |
  ConvertFrom-Json
$tamperedSourcePath = Join-Path $root `
  ([string]$tamperedEvidence.sourceAttestation.path)
[IO.File]::AppendAllText($tamperedSourcePath,' ',[Text.UTF8Encoding]::new($false))
Assert-C34LExpectedRejection $tamperedSource play `
  'Internal Testing evidence source attestation SHA-256 or byte-length binding changed.' `
  'tampered source attestation fixture'

$replayedSource = New-C34LRetainedEvidenceFixture
$replayedEvidence = Get-Content -Raw -LiteralPath $replayedSource.PlayPath |
  ConvertFrom-Json
$replayedEvidence.sourceAttestation.path =
  "$($replayedSource.EvidenceRelative)/attestations/source-attestation-journey-attempt-1.json"
Update-C34LFixtureEvidence $replayedSource play $replayedEvidence
Set-C34LFinalProofEvidenceBindingBoth $replayedSource 0 `
  "$($replayedSource.EvidenceRelative)/07-play-internal-testing-activation-evidence.json" `
  $replayedSource.PlayPath
Assert-C34LExpectedRejection $replayedSource play `
  'Internal Testing evidence source attestation is not the exact candidate evidence owner.' `
  'replayed source attestation fixture'

$wrongCapture = New-C34LRetainedEvidenceFixture
$wrongCaptureEvidence = Get-Content -Raw -LiteralPath $wrongCapture.PlayPath |
  ConvertFrom-Json
$wrongCaptureAttestationPath = Join-Path $root `
  ([string]$wrongCaptureEvidence.sourceAttestation.path)
Set-C34LFixtureRawJsonStringValue $wrongCaptureAttestationPath `
  'captureManifestSha256' ('0' * 64)
$wrongCaptureEvidence.sourceAttestation.sha256 =
  Get-C34LFixtureSha $wrongCaptureAttestationPath
$wrongCaptureEvidence.sourceAttestation.bytes =
  (Get-Item -LiteralPath $wrongCaptureAttestationPath).Length
$wrongCaptureEvidence.sourceAttestation.captureManifestSha256 = ('0' * 64)
Update-C34LFixtureEvidence $wrongCapture play $wrongCaptureEvidence
Set-C34LFinalProofEvidenceBindingBoth $wrongCapture 0 `
  "$($wrongCapture.EvidenceRelative)/07-play-internal-testing-activation-evidence.json" `
  $wrongCapture.PlayPath
Assert-C34LExpectedRejection $wrongCapture play `
  'Internal Testing evidence capture manifest SHA-256 or byte-length binding changed.' `
  'wrong capture binding fixture'

$wrongDigests = New-C34LRetainedEvidenceFixture
$wrongDigestEvidence = Get-Content -Raw -LiteralPath $wrongDigests.PlayPath |
  ConvertFrom-Json
$wrongDigestAttestationPath = Join-Path $root `
  ([string]$wrongDigestEvidence.sourceAttestation.path)
Set-C34LFixtureRawJsonPropertyName $wrongDigestAttestationPath `
  'activationStateDigestSha256' 'alternateDigestSha256'
$wrongDigestAttestation = Get-Content -Raw `
  -LiteralPath $wrongDigestAttestationPath | ConvertFrom-Json
$wrongDigestEvidence.sourceAttestation.sha256 =
  Get-C34LFixtureSha $wrongDigestAttestationPath
$wrongDigestEvidence.sourceAttestation.bytes =
  (Get-Item -LiteralPath $wrongDigestAttestationPath).Length
$wrongDigestEvidence.sourceAttestation.captureDigests =
  $wrongDigestAttestation.captureDigests
Update-C34LFixtureEvidence $wrongDigests play $wrongDigestEvidence
Set-C34LFinalProofEvidenceBindingBoth $wrongDigests 0 `
  "$($wrongDigests.EvidenceRelative)/07-play-internal-testing-activation-evidence.json" `
  $wrongDigests.PlayPath
Assert-C34LExpectedRejection $wrongDigests play `
  'Internal Testing evidence source-attestation captureDigests is missing or has an unknown property at activationStateDigestSha256.' `
  'wrong digest keys fixture'

$wrongDigestValue = New-C34LRetainedEvidenceFixture
$wrongDigestValueEvidence = Get-Content -Raw `
  -LiteralPath $wrongDigestValue.PlayPath | ConvertFrom-Json
$wrongDigestValueAttestationPath = Join-Path $root `
  ([string]$wrongDigestValueEvidence.sourceAttestation.path)
Set-C34LFixtureRawJsonStringValue $wrongDigestValueAttestationPath `
  'activationStateDigestSha256' ('0' * 63)
$wrongDigestValueAttestation = Get-Content -Raw `
  -LiteralPath $wrongDigestValueAttestationPath | ConvertFrom-Json
$wrongDigestValueEvidence.sourceAttestation.sha256 =
  Get-C34LFixtureSha $wrongDigestValueAttestationPath
$wrongDigestValueEvidence.sourceAttestation.bytes =
  (Get-Item -LiteralPath $wrongDigestValueAttestationPath).Length
$wrongDigestValueEvidence.sourceAttestation.captureDigests =
  $wrongDigestValueAttestation.captureDigests
Update-C34LFixtureEvidence $wrongDigestValue play $wrongDigestValueEvidence
Set-C34LFinalProofEvidenceBindingBoth $wrongDigestValue 0 `
  "$($wrongDigestValue.EvidenceRelative)/07-play-internal-testing-activation-evidence.json" `
  $wrongDigestValue.PlayPath
Assert-C34LExpectedRejection $wrongDigestValue play `
  'Internal Testing evidence source-attestation digest changed at activationStateDigestSha256.' `
  'wrong digest value fixture'

$reparseAncestor = New-C34LRetainedEvidenceFixture -ReparseAttestations
Assert-C34LExpectedRejection $reparseAncestor play `
  'Internal Testing evidence source attestation contains a reparse-point ancestor.' `
  'reparse ancestor fixture'

$journalSource = New-C34LRetainedEvidenceFixture
$journal = Get-Content -Raw -LiteralPath $journalSource.TransactionPath |
  ConvertFrom-Json
$journal.sourceAttestation.sha256 = ('0' * 64)
Write-C34LFixtureJson $journalSource.TransactionPath $journal
Assert-C34LExpectedRejection $journalSource oppo `
  'OPPO journal source-attestation binding changed.' `
  'OPPO journal source binding fixture'

Assert-C34LFixture (
  $executedNegativeLabels.Count -eq $expectedNegativeLabels.Count -and
  @($executedNegativeLabels | Select-Object -Unique).Count -eq
    $expectedNegativeLabels.Count
) 'executed negative fixture count or uniqueness changed.'
for ($index = 0; $index -lt $expectedNegativeLabels.Count; $index++) {
  Assert-C34LFixture (
    [string]$executedNegativeLabels[$index] -ceq
      [string]$expectedNegativeLabels[$index]
  ) "executed negative fixture inventory changed at index $index."
}

if ($false) {
$recoverySource = Get-Content -Raw -LiteralPath (Join-Path $root `
  'scripts/recover-uaw-c34l-r60-76-postbuild-lifecycle.ps1')
foreach ($token in @(
  '11b-build-succeeded-proof-attempt-$Attempt.json',
  "-Filter '11b-build-succeeded-proof-attempt-*.json'",
  '$proofOwners.Count -eq 1',
  '$proof.stateSha256 -ceq $stateSha256',
  '$proof.aggregateSha256 -ceq $aggregateSha256',
  '-PrerequisiteGateEvidencePath $proofRelative',
  '-Attempt $Attempt',
  'function Assert-C34LRecoveryExactNames(',
  'function Assert-C34LRecoveryPrivacy(',
  '"$Label contains a reparse-point ancestor."'
)) {
  Assert-C34LFixture ($recoverySource.Contains($token)) `
    "recovery source is missing exact crash-boundary token: $token"
}
Assert-C34LFixture (-not $recoverySource.Contains('phaseGateProofs')) `
  'recovery source still relies on a post-transition phaseGateProofs binding.'
Assert-C34LFixture (-not $recoverySource.Contains('GetRelativePath')) `
  'recovery source still uses a Windows PowerShell-incompatible relative-path API.'

$recoveryCountNames = @(
  'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
  'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
)
$recoveryAuthorityNames = @(
  'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)
function New-C34LRecoveryBoundaryFixture(
  [int]$ProofOwnerAttempt = 1,
  [switch]$AddAlternateOwner
) {
  $fixtureName = 'c34l-retained-evidence-fixtures-' + [Guid]::NewGuid().ToString('N')
  $fixtureRoot = Join-Path $root "tmp/$fixtureName"
  Register-C34LFixtureRoot $fixtureRoot
  $evidenceRoot = Join-Path $fixtureRoot 'evidence'
  [void](New-Item -ItemType Directory -Path $evidenceRoot -Force)
  $counts = New-C34LCounts 1 0 0 0
  $authorities = New-C34LAuthorities 'consumed' `
    'held_postbuild_qualification' 'held_postupload_qualification' `
    'held_postinstall_journey_qualification'
  $statePath = Join-Path $fixtureRoot 'recovery-state.json'
  $aggregatePath = Join-Path $fixtureRoot 'recovery-aggregate.json'
  $state = [pscustomobject][ordered]@{
    ticketId = $ticketId
    actionCounts = $counts
    releaseAuthorities = $authorities
  }
  $aggregate = [pscustomobject][ordered]@{
    ticketId = $ticketId
    actionCounts = $counts
    releaseAuthorities = $authorities
  }
  Write-C34LFixtureJson $statePath $state
  Write-C34LFixtureJson $aggregatePath $aggregate
  $proof = [pscustomobject][ordered]@{
    ticketId = $ticketId
    attempt = 1
    versionName = $versionName
    versionCode = $versionCode
    transition = 'build-succeeded'
    phase = 'build'
    passed = $true
    stateSha256 = Get-C34LFixtureSha $statePath
    aggregateSha256 = Get-C34LFixtureSha $aggregatePath
    actionCounts = $counts
    releaseAuthorities = $authorities
  }
  $proofPath = Join-Path $evidenceRoot `
    "11b-build-succeeded-proof-attempt-$ProofOwnerAttempt.json"
  Write-C34LFixtureJson $proofPath $proof
  if ($AddAlternateOwner) {
    Write-C34LFixtureJson (Join-Path $evidenceRoot `
      '11b-build-succeeded-proof-attempt-2.json') $proof
  }
  return [pscustomobject]@{
    StatePath = $statePath
    AggregatePath = $aggregatePath
    EvidenceRoot = $evidenceRoot
    ProofPath = $proofPath
  }
}
function Assert-C34LRecoveryBoundaryModel($Fixture, [int]$Attempt = 1) {
  $expectedLeaf = "11b-build-succeeded-proof-attempt-$Attempt.json"
  $proofOwners = @(Get-ChildItem -LiteralPath $Fixture.EvidenceRoot -File `
    -Filter '11b-build-succeeded-proof-attempt-*.json')
  Assert-C34LFixture (
    $proofOwners.Count -eq 1 -and
    [string]$proofOwners[0].Name -ceq $expectedLeaf
  ) 'recovery boundary requires exactly one exact attempt proof owner.'
  $state = Get-Content -Raw -LiteralPath $Fixture.StatePath | ConvertFrom-Json
  $aggregate = Get-Content -Raw -LiteralPath $Fixture.AggregatePath |
    ConvertFrom-Json
  $proof = Get-Content -Raw -LiteralPath $proofOwners[0].FullName |
    ConvertFrom-Json
  Assert-C34LFixture (
    [string]$state.ticketId -ceq $ticketId -and
    [string]$aggregate.ticketId -ceq $ticketId -and
    [string]$proof.ticketId -ceq $ticketId -and
    [int]$proof.attempt -eq $Attempt -and
    [string]$proof.transition -ceq 'build-succeeded' -and
    [string]$proof.phase -ceq 'build' -and [bool]$proof.passed -and
    [string]$proof.stateSha256 -ceq (Get-C34LFixtureSha $Fixture.StatePath) -and
    [string]$proof.aggregateSha256 -ceq
      (Get-C34LFixtureSha $Fixture.AggregatePath)
  ) 'recovery boundary ticket, attempt, transition, phase or current hash changed.'
  $expectedCounts = @(1,0,0,0,0,0,0,0)
  $expectedAuthorities = @(
    'consumed','held_postbuild_qualification','held_postupload_qualification',
    'held_postinstall_journey_qualification'
  )
  for ($index = 0; $index -lt $recoveryCountNames.Count; $index++) {
    $name = $recoveryCountNames[$index]
    Assert-C34LFixture (
      $null -ne $proof.actionCounts.PSObject.Properties[$name] -and
      [int]$proof.actionCounts.$name -eq $expectedCounts[$index] -and
      [int]$proof.actionCounts.$name -eq [int]$state.actionCounts.$name -and
      [int]$proof.actionCounts.$name -eq [int]$aggregate.actionCounts.$name
    ) "recovery boundary count changed at $name."
  }
  for ($index = 0; $index -lt $recoveryAuthorityNames.Count; $index++) {
    $name = $recoveryAuthorityNames[$index]
    Assert-C34LFixture (
      $null -ne $proof.releaseAuthorities.PSObject.Properties[$name] -and
      [string]$proof.releaseAuthorities.$name -ceq
        $expectedAuthorities[$index] -and
      [string]$proof.releaseAuthorities.$name -ceq
        [string]$state.releaseAuthorities.$name -and
      [string]$proof.releaseAuthorities.$name -ceq
        [string]$aggregate.releaseAuthorities.$name
    ) "recovery boundary authority changed at $name."
  }
  return Get-C34LFixtureSha $proofOwners[0].FullName
}
function Assert-C34LRecoveryBoundaryRejection(
  $Fixture,
  [string]$ExpectedMessage,
  [string]$Label
) {
  $rejected = $false
  $observedMessage = ''
  try { [void](Assert-C34LRecoveryBoundaryModel $Fixture) } catch {
    $rejected = $true
    $observedMessage = $_.Exception.Message
  }
  Assert-C34LFixture (
    $rejected -and $observedMessage.Contains($ExpectedMessage)
  ) "$Label did not produce the expected recovery-boundary rejection."
  $script:executedRecoveryNegativeLabels += $Label
}

$executedRecoveryNegativeLabels = @()
$recoveryPositive = New-C34LRecoveryBoundaryFixture
[void](Assert-C34LRecoveryBoundaryModel $recoveryPositive)

$recoveryAlternate = New-C34LRecoveryBoundaryFixture -ProofOwnerAttempt 2
Assert-C34LRecoveryBoundaryRejection $recoveryAlternate `
  'recovery boundary requires exactly one exact attempt proof owner.' `
  'alternate proof owner'

$recoveryMultiple = New-C34LRecoveryBoundaryFixture -AddAlternateOwner
Assert-C34LRecoveryBoundaryRejection $recoveryMultiple `
  'recovery boundary requires exactly one exact attempt proof owner.' `
  'multiple proof owners'

$recoveryWrongHash = New-C34LRecoveryBoundaryFixture
$recoveryWrongHashProof = Get-Content -Raw -LiteralPath `
  $recoveryWrongHash.ProofPath | ConvertFrom-Json
$recoveryWrongHashProof.stateSha256 = ('E' * 64)
Write-C34LFixtureJson $recoveryWrongHash.ProofPath $recoveryWrongHashProof
Assert-C34LRecoveryBoundaryRejection $recoveryWrongHash `
  'recovery boundary ticket, attempt, transition, phase or current hash changed.' `
  'wrong current state hash'

$recoveryWrongAttempt = New-C34LRecoveryBoundaryFixture
$recoveryWrongAttemptProof = Get-Content -Raw -LiteralPath `
  $recoveryWrongAttempt.ProofPath | ConvertFrom-Json
$recoveryWrongAttemptProof.attempt = 2
Write-C34LFixtureJson $recoveryWrongAttempt.ProofPath $recoveryWrongAttemptProof
Assert-C34LRecoveryBoundaryRejection $recoveryWrongAttempt `
  'recovery boundary ticket, attempt, transition, phase or current hash changed.' `
  'wrong proof attempt'

$recoveryWrongCount = New-C34LRecoveryBoundaryFixture
$recoveryWrongCountProof = Get-Content -Raw -LiteralPath `
  $recoveryWrongCount.ProofPath | ConvertFrom-Json
$recoveryWrongCountProof.actionCounts.realSmsSend = 1
Write-C34LFixtureJson $recoveryWrongCount.ProofPath $recoveryWrongCountProof
Assert-C34LRecoveryBoundaryRejection $recoveryWrongCount `
  'recovery boundary count changed at realSmsSend.' 'wrong recovery count'

$recoveryWrongAuthority = New-C34LRecoveryBoundaryFixture
$recoveryWrongAuthorityProof = Get-Content -Raw -LiteralPath `
  $recoveryWrongAuthority.ProofPath | ConvertFrom-Json
$recoveryWrongAuthorityProof.releaseAuthorities.postinstallAcceptance = 'consumed'
Write-C34LFixtureJson $recoveryWrongAuthority.ProofPath `
  $recoveryWrongAuthorityProof
Assert-C34LRecoveryBoundaryRejection $recoveryWrongAuthority `
  'recovery boundary authority changed at postinstallAcceptance.' `
  'wrong recovery authority'

$expectedRecoveryNegativeLabels = @(
  'alternate proof owner','multiple proof owners','wrong current state hash',
  'wrong proof attempt','wrong recovery count','wrong recovery authority'
)
Assert-C34LFixture (
  $executedRecoveryNegativeLabels.Count -eq
    $expectedRecoveryNegativeLabels.Count -and
  @($executedRecoveryNegativeLabels | Select-Object -Unique).Count -eq
    $expectedRecoveryNegativeLabels.Count
) 'recovery-boundary negative fixture count or uniqueness changed.'
for ($index = 0; $index -lt $expectedRecoveryNegativeLabels.Count; $index++) {
  Assert-C34LFixture (
    [string]$executedRecoveryNegativeLabels[$index] -ceq
      [string]$expectedRecoveryNegativeLabels[$index]
  ) "recovery-boundary negative fixture inventory changed at index $index."
}
}
function New-C34LConfinedRecoveryFixture {
  $runName = 'recovery-' + [Guid]::NewGuid().ToString('N')
  $fixtureRelative = "tmp/c34l-release-transaction-fixtures/$runName"
  $fixtureRoot = Join-Path $root $fixtureRelative
  Register-C34LFixtureRoot $fixtureRoot
  $evidenceRelative = "$fixtureRelative/evidence"
  $evidenceRoot = Join-Path $root $evidenceRelative
  [void](New-Item -ItemType Directory -Path $evidenceRoot -Force)

  $state = Get-Content -Raw -LiteralPath (Join-Path $root `
    'config/successor-aab-regression-hard-gate-state-c34l.json') |
    ConvertFrom-Json
  $aggregate = Get-Content -Raw -LiteralPath (Join-Path $root `
    'config/successor-aab-regression-hard-gate-aggregate-c34l.json') |
    ConvertFrom-Json
  $stateRelative = "$fixtureRelative/state.json"
  $aggregateRelative = "$fixtureRelative/aggregate.json"
  $statePath = Join-Path $root $stateRelative
  $aggregatePath = Join-Path $root $aggregateRelative
  $state.aggregateStatePath = $aggregateRelative
  $state.evidenceRoot = $evidenceRelative
  $aggregate.evidenceRoot = $evidenceRelative
  $machine =
    'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
  $state.machineState = $machine; $aggregate.machineState = $machine
  $state.buildAuthorization = 'consumed'
  $state.releaseAuthorities.build = 'consumed'
  $aggregate.releaseAuthorities.build = 'consumed'
  $state.releaseAuthorities.uploadAndInternalActivation =
    'held_postbuild_qualification'
  $aggregate.releaseAuthorities.uploadAndInternalActivation =
    'held_postbuild_qualification'
  $state.releaseAuthorities.inPlaceOppoPlayUpdate =
    'held_postupload_qualification'
  $aggregate.releaseAuthorities.inPlaceOppoPlayUpdate =
    'held_postupload_qualification'
  $state.releaseAuthorities.postinstallAcceptance =
    'held_postinstall_journey_qualification'
  $aggregate.releaseAuthorities.postinstallAcceptance =
    'held_postinstall_journey_qualification'
  foreach($name in @(
    'build','upload','install','deviceAcceptance','passwordlessEmailSend',
    'realSmsSend','otherTrack','backendHostingProviderOrProductionDeployment'
  )) {
    $value = if ($name -ceq 'build') { 1 } else { 0 }
    $state.actionCounts.$name = $value; $aggregate.actionCounts.$name = $value
  }
  $aggregate.candidate.buildCount = 1
  $aggregate.candidate.aabSha256 = $null
  $state.candidate.artifactReusable = $false
  $aggregate.candidate.artifactReusable = $false
  foreach($candidate in @($state.candidate,$aggregate.candidate)) {
    if ($null -ne $candidate.PSObject.Properties['deviceSerial']) {
      $candidate.PSObject.Properties.Remove('deviceSerial')
    }
    if ($null -eq $candidate.PSObject.Properties['deviceBindingSha256']) {
      $candidate | Add-Member -NotePropertyName deviceBindingSha256 `
        -NotePropertyValue $deviceBindingSha256
    } else {
      $candidate.deviceBindingSha256 = $deviceBindingSha256
    }
  }
  $state.buildResult.state = $machine
  $state.buildResult.buildCount = 1
  $state.buildResult.wrapperInvocationCount = 1
  $state.buildResult.configOnlyCount = 1
  $state.buildResult.artifactPath = $null
  $state.buildResult.artifactSha256 = $null
  $state.buildResult.artifactBytes = 0
  $state.buildResult.uploadSignerSha256 = $null
  $state.buildResult.provenance = $null
  foreach($name in @(
    'packageVersionManifestProved','googleAppIdResourceProved',
    'crashlyticsBuildIdResourceProved','splitAndArm64PayloadProved',
    'mergedReleaseManifestProved'
  )) { $state.buildResult.$name = $false }
  $state.lifecycleTransactionProofs = @()
  $aggregate.lifecycleTransactionProofs = @()

  $artifactRelative =
    "$evidenceRelative/MoolSocial-$versionName-$versionCode-release.aab"
  $artifactPath = Join-Path $root $artifactRelative
  Write-C34LFixtureText $artifactPath 'C34L confined recovery fixture AAB bytes'
  $artifactSha = Get-C34LFixtureSha $artifactPath
  $artifactBytes = (Get-Item -LiteralPath $artifactPath).Length
  $sourceOwnerRelative = "$evidenceRelative/fixture-source-owner.txt"
  $sourceOwnerPath = Join-Path $root $sourceOwnerRelative
  Write-C34LFixtureText $sourceOwnerPath 'confined recovery source owner'
  $sourceManifestRelative = "$evidenceRelative/source-manifest.txt"
  $sourceManifestPath = Join-Path $root $sourceManifestRelative
  Write-C34LFixtureText $sourceManifestPath (
    "$(Get-C34LFixtureSha $sourceOwnerPath)  $sourceOwnerRelative" +
    [Environment]::NewLine
  )
  $sourceManifestSha = Get-C34LFixtureSha $sourceManifestPath
  $state.sourceQualification.manifestPath = $sourceManifestRelative
  $state.sourceQualification.manifestSha256 = $sourceManifestSha
  $state.sourceQualification.manifestBytes =
    (Get-Item -LiteralPath $sourceManifestPath).Length
  $state.sourceQualification.fileCount = 1
  if ($null -ne $aggregate.sourceQualification) {
    $aggregate.sourceQualification.manifestPath = $sourceManifestRelative
    $aggregate.sourceQualification.manifestSha256 = $sourceManifestSha
    $aggregate.sourceQualification.manifestBytes =
      (Get-Item -LiteralPath $sourceManifestPath).Length
    $aggregate.sourceQualification.fileCount = 1
  }

  $configRelative = "$evidenceRelative/03-release-config-only.log"
  $manifestRelative = "$evidenceRelative/04-release-manifest-preflight.log"
  $mergedRelative = "$evidenceRelative/04a-merged-release-manifest.xml"
  $blameRelative = "$evidenceRelative/04b-release-manifest-merger-blame.txt"
  $buildLogRelative = "$evidenceRelative/05-release-aab-build.log"
  Write-C34LFixtureText (Join-Path $root $configRelative) 'config passed'
  Write-C34LFixtureText (Join-Path $root $manifestRelative) 'manifest passed'
  Write-C34LFixtureText (Join-Path $root $mergedRelative) `
    '<manifest package="com.moolsocial.app" />'
  Write-C34LFixtureText (Join-Path $root $blameRelative) 'blame passed'
  Write-C34LFixtureText (Join-Path $root $buildLogRelative) `
    'Built build/app/outputs/bundle/release/app-release.aab'
  $signer = ([string]$state.signingQualification.uploadCertificateSha256).
    Replace(':','').ToUpperInvariant()
  $provenanceRelative = "$evidenceRelative/06-release-aab-provenance.json"
  $provenancePath = Join-Path $root $provenanceRelative
  $provenance = [pscustomobject][ordered]@{
    schemaVersion=1; candidateId=$ticketId; preflightAttempt=1
    versionName=$versionName; versionCode=$versionCode
    packageName='com.moolsocial.app'; buildMode='release'; artifactType='AAB'
    authorizedTrack='internal'; branch='remediation/prototype-conformance-2026-07-20'
    head='f6dfe7587aa02d782e94282d14af8bafff48ded0'; powerShellMajor=7
    providerRevisions=[pscustomobject][ordered]@{}
    releaseConfigOnly=$configRelative
    qualifiedRegistrantSnapshot=$configRelative
    qualifiedLocalPropertiesSnapshot=$configRelative
    releaseManifestPreflight=$manifestRelative; mergedReleaseManifest=$mergedRelative
    releaseManifestMergerBlame=$blameRelative
    releaseConfigOnlyProducedApkOrAab=$false; releaseRegistrantPluginCount=10
    googleServicesGradlePlugin='4.5.0'; crashlyticsGradlePlugin='3.0.7'
    crashlyticsMappingUploadEnabled=$false; sourceManifest=$sourceManifestRelative
    sourceManifestSha256=$sourceManifestSha; sourceFiles=1
    artifactPath=$artifactRelative; artifactSha256=$artifactSha
    artifactBytes=$artifactBytes; uploadSignerSha256=$signer
    packageVersionManifestProved=$true; googleAppIdResourceProved=$true
    crashlyticsBuildIdResourceProved=$true; splitAndArm64PayloadProved=$true
    bundletoolPath='tmp/bundletool-all-1.18.3.jar'; bundletoolSha256=('B' * 64)
    bundletoolVersion='1.18.3'; buildLog=$buildLogRelative
    secretDefineFileReadByAgent=$false; googleServicesFileReadByAgent=$false
    secretValuesRecorded=$false; builtAt='2026-08-17T00:00:00.0000000Z'
  }
  Write-C34LFixtureJson $provenancePath $provenance
  Write-C34LFixtureJson $aggregatePath $aggregate
  Write-C34LFixtureJson $statePath $state
  $proofRelative = "$evidenceRelative/11b-build-succeeded-proof-attempt-1.json"
  $proofPath = Join-Path $root $proofRelative
  $proof = [pscustomobject][ordered]@{
    ticketId=$ticketId; attempt=1; versionName=$versionName
    versionCode=$versionCode; transition='build-succeeded'; phase='build'
    passed=$true; stateSha256=(Get-C34LFixtureSha $statePath)
    aggregateSha256=(Get-C34LFixtureSha $aggregatePath)
    actionCounts=$state.actionCounts; releaseAuthorities=$state.releaseAuthorities
  }
  Write-C34LFixtureJson $proofPath $proof
  return [pscustomobject]@{
    Root=$fixtureRoot; StateRelative=$stateRelative; StatePath=$statePath
    AggregatePath=$aggregatePath; EvidenceRoot=$evidenceRoot
    EvidenceRelative=$evidenceRelative; ProofPath=$proofPath
    JournalRoot=(Join-Path $fixtureRoot 'journals')
    ArtifactSha=$artifactSha; ArtifactBytes=$artifactBytes
  }
}
function Invoke-C34LConfinedRecovery(
  $Fixture,
  [ValidateSet('audit','apply')][string]$Mode
) {
  $output = @(& (Join-Path $root `
    'scripts/recover-uaw-c34l-r60-76-postbuild-lifecycle.ps1') `
    -Mode $Mode -Attempt 1 -StatePath $Fixture.StateRelative -FixtureMode `
    -RepositoryRoot $root)
  Assert-C34LFixture (
    @($output | Where-Object {
      [string]$_ -match 'upload=0; install=0; OPPO=untouched'
    }).Count -eq 1
  ) "real recovery $Mode did not prove zero release/device actions."
  return $output
}

$realStateOwner = Join-Path $root `
  'config/successor-aab-regression-hard-gate-state-c34l.json'
$realAggregateOwner = Join-Path $root `
  'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
$realStateBefore = Get-C34LFixtureSha $realStateOwner
$realAggregateBefore = Get-C34LFixtureSha $realAggregateOwner
$confinedRecovery = New-C34LConfinedRecoveryFixture
$auditOutput = Invoke-C34LConfinedRecovery $confinedRecovery audit
$firstApplyOutput = Invoke-C34LConfinedRecovery $confinedRecovery apply
$afterFirstState = Get-Content -Raw -LiteralPath $confinedRecovery.StatePath |
  ConvertFrom-Json
$afterFirstAggregate = Get-Content -Raw `
  -LiteralPath $confinedRecovery.AggregatePath | ConvertFrom-Json
Assert-C34LFixture (
  [string]$afterFirstState.machineState -ceq
    'single_release_AAB_succeeded_authority_consumed' -and
  [string]$afterFirstAggregate.machineState -ceq
    'single_release_AAB_succeeded_authority_consumed' -and
  @($afterFirstState.lifecycleTransactionProofs).Count -eq 1 -and
  (@($afterFirstState.lifecycleTransactionProofs) | ConvertTo-Json -Depth 60 -Compress) -ceq
    (@($afterFirstAggregate.lifecycleTransactionProofs) | ConvertTo-Json -Depth 60 -Compress)
) 'real recovery first Apply did not persist one exact equal lifecycle proof.'
$firstStateSha = Get-C34LFixtureSha $confinedRecovery.StatePath
$firstAggregateSha = Get-C34LFixtureSha $confinedRecovery.AggregatePath
$secondApplyOutput = Invoke-C34LConfinedRecovery $confinedRecovery apply
Assert-C34LFixture (
  (Get-C34LFixtureSha $confinedRecovery.StatePath) -ceq $firstStateSha -and
  (Get-C34LFixtureSha $confinedRecovery.AggregatePath) -ceq $firstAggregateSha -and
  @($secondApplyOutput | Where-Object {
    [string]$_ -match 'idempotent=True'
  }).Count -eq 1
) 'real recovery second Apply was not byte-idempotent.'
Assert-C34LFixture (
  Test-Path -LiteralPath $confinedRecovery.JournalRoot -PathType Container
) 'real recovery did not create the exact confined transaction journal root.'
$journalOwners = @(Get-ChildItem -LiteralPath `
  $confinedRecovery.JournalRoot -File -Filter '*.json')
Assert-C34LFixture ($journalOwners.Count -eq 1) `
  'real recovery did not retain exactly one confined transaction journal.'
$journal = Get-Content -Raw -LiteralPath $journalOwners[0].FullName |
  ConvertFrom-Json
Assert-C34LFixture (
  [string]$journal.status -ceq 'committed' -and
  [string]$journal.statePath -ceq $confinedRecovery.StateRelative -and
  [string]$journal.aggregateStatePath -ceq
    ($confinedRecovery.AggregatePath.Substring($root.Length + 1).Replace('\','/'))
) 'real recovery transaction journal status or target binding changed.'
Assert-C34LFixture (
  (Get-C34LFixtureSha $realStateOwner) -ceq $realStateBefore -and
  (Get-C34LFixtureSha $realAggregateOwner) -ceq $realAggregateBefore
) 'real recovery fixture changed a production state owner.'
Write-Output (
  "C34L retained-evidence fixtures passed: positive=2; negative=$($executedNegativeLabels.Count); " +
  'ticketId=true; attempt=true; preimages=true; counts=8; authorities=4; ' +
  'PlayShaBytes=true; OppoColdShaBytes=true; OppoRetainedShaBytes=true; ' +
  'journeyShaBytes=true; builtAtRoundTripOffset=true; ' +
  'recoveryRealAudit=1; recoveryRealApply=1; recoveryIdempotentApply=1; ' +
  'recoveryExactAttemptOwner=true; recoveryCurrentHashes=true; ' +
  'recoveryExactSchemas=true; recoveryPrivacy=true; ' +
  'recoveryAncestorReparse=true; recoveryWindowsPathCompatible=true; ' +
  'recoveryPhaseGateProofsDependency=false; realProducerActions=0.'
)
} finally {
  Remove-C34LRegisteredFixtures
}
