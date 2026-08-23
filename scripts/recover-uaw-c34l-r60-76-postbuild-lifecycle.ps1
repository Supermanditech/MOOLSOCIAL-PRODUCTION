[CmdletBinding()]
param(
  [ValidateSet('audit', 'apply')]
  [string]$Mode = 'audit',
  [ValidateRange(1, 5)]
  [int]$Attempt = 1,
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34l.json',
  [switch]$FixtureMode,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$ticketId =
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE'
$versionName = '1.0.0-r60.76'
$versionCode = '2026081376'
$packageName = 'com.moolsocial.app'
$deviceBindingSha256 =
  '97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF'
$productionEvidenceRoot =
  'artifacts/quality/uaw-c34l-r60-76-consolidated-release-transaction-evidence-preparation-20260817-01'

function Assert-C34LRecovery([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C34L existing-AAB recovery rejected: $Message" }
}
function Resolve-C34LRecoveryFile([string]$Path, [string]$Label, [switch]$AllowMissing) {
  Assert-C34LRecovery (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path) -and
    -not $Path.Contains('\') -and -not $Path.Contains('?') -and
    -not $Path.Contains('#')
  ) "$Label must be one normalized repository-relative path."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LRecovery ($resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) `
    "$Label escaped the production repository."
  $current = if (Test-Path -LiteralPath $resolved) {
    $resolved
  } else {
    [IO.Path]::GetFullPath((Split-Path -Parent $resolved))
  }
  while ($true) {
    Assert-C34LRecovery (
      $current.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
      $current.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) "$Label ancestor escaped the production repository."
    Assert-C34LRecovery (Test-Path -LiteralPath $current) `
      "$Label ancestor is missing."
    Assert-C34LRecovery (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $current = [IO.Path]::GetFullPath((Split-Path -Parent $current))
  }
  if (-not $AllowMissing) {
    Assert-C34LRecovery (Test-Path -LiteralPath $resolved -PathType Leaf) "$Label is missing."
  }
  return $resolved
}
function Assert-C34LRecoveryProperties($Object, [string]$Label, [string[]]$Names) {
  foreach ($name in $Names) {
    Assert-C34LRecovery ($null -ne $Object.PSObject.Properties[$name]) `
      "$Label is missing property $name."
  }
}
function Assert-C34LRecoveryExactNames($Object, [string]$Label, [string[]]$Names) {
  $actual = @($Object.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LRecovery ($actual.Count -eq $Names.Count) `
    "$Label property count changed."
  foreach ($name in $Names) {
    Assert-C34LRecovery ($actual -ccontains $name) `
      "$Label is missing or has an unknown property at $name."
  }
}
function Assert-C34LRecoveryPrivacy(
  $Value,
  [string]$Label,
  [string]$PropertyPath = ''
) {
  if ($Value -is [System.Collections.IDictionary]) {
    foreach ($key in @($Value.Keys)) {
      $name = [string]$key
      $path = if ($PropertyPath) { "$PropertyPath.$name" } else { $name }
      Assert-C34LRecoveryPrivacyPropertyName $name $Label $path
      Assert-C34LRecoveryPrivacy $Value[$key] $Label $path
    }
    return
  }
  if ($Value -is [System.Management.Automation.PSCustomObject]) {
    foreach ($property in @($Value.PSObject.Properties)) {
      $path = if ($PropertyPath) { "$PropertyPath.$($property.Name)" } else { $property.Name }
      Assert-C34LRecoveryPrivacyPropertyName $property.Name $Label $path
      Assert-C34LRecoveryPrivacy $property.Value $Label $path
    }
    return
  }
  if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
    foreach ($item in @($Value)) {
      Assert-C34LRecoveryPrivacy $item $Label $PropertyPath
    }
    return
  }
  if ($null -eq $Value -or $Value -isnot [string]) { return }
  $privateShape =
    '(?i)([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|https?://|www\.|' +
    '(?:Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+|(?:access|refresh|id)[_-]?token\s*[:=]|' +
    'authorization\s*[:=]|(?:set-)?cookie\s*[:=]|session[_-]?cookie|' +
    'AIza[0-9A-Za-z_-]{35}|-----BEGIN(?: [A-Z]+)* PRIVATE KEY-----|' +
    'Exception(?:\s*:|\r|\n)|StackTrace|Traceback\s*\(|' +
    '[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com|' +
    '^[A-Za-z0-9_-]{16,}[.][A-Za-z0-9_-]{16,}[.][A-Za-z0-9_-]{16,}$|' +
    '[?&][A-Za-z0-9_.%+-]+=[^\s]*|#[A-Za-z0-9_.%+-]+)'
  Assert-C34LRecovery (-not [regex]::IsMatch([string]$Value,$privateShape)) `
    "$Label contains a forbidden private value shape at $PropertyPath."
}
function Assert-C34LRecoveryPrivacyPropertyName(
  [string]$Name,
  [string]$Label,
  [string]$PropertyPath
) {
  $approvedSensitiveNames = @(
    'passwordlessEmailSend','sourceAttestation','sourceProducerId',
    'sourceManifest','sourceManifestSha256','sourceManifestBytes',
    'deviceBindingSha256','browserSessionId','sessionId','nonceSha256',
    'browserSessionNonceSha256','secretDefineFileReadByAgent',
    'secretOrPrivateValuesRecorded','secretValuesRecorded',
    'agentSecretValueAccessAuthorized'
  )
  $rawDeviceNames = @(
    'deviceSerial','serial','androidId','imei','imsi','advertisingId'
  )
  Assert-C34LRecovery ($rawDeviceNames -cnotcontains $Name) `
    "$Label contains forbidden raw device property $PropertyPath."
  if ($approvedSensitiveNames -ccontains $Name) { return }
  Assert-C34LRecovery (
    $Name -cnotmatch
      '(?i)(?:password|credential|secret|private|access.?token|refresh.?token|' +
      'id.?token|authorization|cookie|exception|stack.?trace|traceback|' +
      'device.?serial|android.?id|imei|imsi|advertising.?id|phone|mobile|' +
      'e.?mail|private.?url|private.?uri|query.?value|fragment.?value)'
  ) "$Label contains a forbidden private property name at $PropertyPath."
}
function Get-C34LAttemptLeaf([string]$Stem, [string]$Extension, [int]$Number = $Attempt) {
  if ($Number -eq 1) { return "$Stem$Extension" }
  return "$Stem-attempt-$Number$Extension"
}
function Assert-C34LExactEvidencePath([string]$Actual, [string]$Leaf, [string]$Label) {
  $expected = "$evidenceRoot/$Leaf"
  Assert-C34LRecovery ([string]$Actual -ceq $expected) `
    "$Label is not the exact attempt-$Attempt candidate evidence owner."
  return Resolve-C34LRecoveryFile $Actual $Label
}
function Assert-C34LRecoveryFixturePath([string]$Resolved,[string]$Label) {
  if (-not $FixtureMode) { return }
  Assert-C34LRecovery (
    -not [string]::IsNullOrWhiteSpace([string]$script:recoveryFixtureRootFull)
  ) 'FixtureMode exact state run root is not initialized.'
  $prefix = $script:recoveryFixtureRootFull +
    [IO.Path]::DirectorySeparatorChar
  Assert-C34LRecovery (
    [IO.Path]::GetFullPath($Resolved).StartsWith(
      $prefix,[StringComparison]::OrdinalIgnoreCase)
  ) "$Label escaped the exact FixtureMode state run root."
}

$stateFile = Resolve-C34LRecoveryFile $StatePath 'detailed state'
$stateRelative = $stateFile.Substring($rootPrefix.Length).Replace('\','/')
if ($FixtureMode) {
  Assert-C34LRecovery (
    $stateRelative -cmatch
      '^tmp/c34l-release-transaction-fixtures/recovery-[0-9A-Za-z_-]+/state[.]json$'
  ) 'FixtureMode recovery is outside an exact unique transaction run root.'
  $fixtureRoot = (Split-Path -Parent $stateRelative).Replace('\','/')
  $fixturePrefix = "$fixtureRoot/"
  $script:recoveryFixtureRootFull =
    [IO.Path]::GetFullPath((Split-Path -Parent $stateFile)).TrimEnd(
      [char[]]@('\','/')
    )
  $evidenceRoot = "$fixtureRoot/evidence"
} else {
  Assert-C34LRecovery (
    $stateRelative -ceq
      'config/successor-aab-regression-hard-gate-state-c34l.json'
  ) 'recovery is confined to the exact production C34L state.'
  $evidenceRoot = $productionEvidenceRoot
}
$stateSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $stateFile).Hash
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C34LRecoveryProperties $state 'detailed state' @(
  'ticketId','candidate','aggregateStatePath','sourceQualification','buildAuthorization',
  'releaseAuthorities','actionCounts','buildResult','signingQualification',
  'lifecycleTransactionProofs'
)
$aggregateFile = Resolve-C34LRecoveryFile ([string]$state.aggregateStatePath) 'aggregate state'
Assert-C34LRecoveryFixturePath $aggregateFile 'fixture aggregate state'
$aggregateRelative = $aggregateFile.Substring($rootPrefix.Length).Replace('\','/')
if ($FixtureMode) {
  Assert-C34LRecovery (
    $aggregateRelative -ceq "$fixtureRoot/aggregate.json" -and
    $aggregateRelative.StartsWith($fixturePrefix,[StringComparison]::Ordinal)
  ) 'FixtureMode aggregate escaped the exact recovery run root.'
} else {
  Assert-C34LRecovery (
    $aggregateRelative -ceq
      'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
  ) 'recovery is confined to the exact production C34L aggregate state.'
}
$aggregateSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $aggregateFile).Hash
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
Assert-C34LRecoveryProperties $aggregate 'aggregate state' @(
  'ticketId','candidate','releaseAuthorities','actionCounts',
  'lifecycleTransactionProofs'
)
$inProgress = 'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
$recovered = 'single_release_AAB_succeeded_authority_consumed'
$isInterrupted =
  [string]$state.machineState -ceq $inProgress -and
  [string]$aggregate.machineState -ceq $inProgress
$isRecovered =
  [string]$state.machineState -ceq $recovered -and
  [string]$aggregate.machineState -ceq $recovered
Assert-C34LRecovery (
  [string]$state.ticketId -ceq $ticketId -and
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$state.candidate.versionName -ceq $versionName -and
  [string]$aggregate.candidate.versionName -ceq $versionName -and
  [string]$state.candidate.versionCode -ceq $versionCode -and
  [string]$aggregate.candidate.versionCode -ceq $versionCode -and
  [string]$state.candidate.packageName -ceq $packageName -and
  [string]$state.candidate.deviceBindingSha256 -ceq $deviceBindingSha256 -and
  $null -eq $state.candidate.PSObject.Properties['deviceSerial'] -and
  ($isInterrupted -or $isRecovered) -and
  [string]$state.buildAuthorization -ceq 'consumed' -and
  [string]$state.releaseAuthorities.build -ceq 'consumed' -and
  [string]$aggregate.releaseAuthorities.build -ceq 'consumed' -and
  [int]$state.actionCounts.build -eq 1 -and [int]$aggregate.actionCounts.build -eq 1 -and
  [int]$aggregate.candidate.buildCount -eq 1 -and
  [int]$state.actionCounts.upload -eq 0 -and [int]$state.actionCounts.install -eq 0 -and
  [int]$state.actionCounts.deviceAcceptance -eq 0 -and
  (
    ($isInterrupted -and
      [string]::IsNullOrWhiteSpace([string]$state.buildResult.artifactSha256)) -or
    ($isRecovered -and
      [string]$state.buildResult.artifactSha256 -cmatch '^[0-9A-F]{64}$')
  )
) 'supported interrupted postbuild state or 1/0/0/0 mirror changed.'
$stateHistory = @($state.lifecycleTransactionProofs)
$aggregateHistory = @($aggregate.lifecycleTransactionProofs)
Assert-C34LRecovery (
  $stateHistory.Count -eq $aggregateHistory.Count -and
  ($stateHistory | ConvertTo-Json -Depth 60 -Compress) -ceq
    ($aggregateHistory | ConvertTo-Json -Depth 60 -Compress)
) 'detailed and aggregate lifecycle histories are not exactly equal.'
foreach ($historyRecord in $stateHistory) {
  Assert-C34LRecoveryExactNames $historyRecord 'lifecycle proof record' @(
    'ticketId','attempt','transition','phase','evidencePath','sha256',
    'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
    'browserEvidence'
  )
  Assert-C34LRecoveryPrivacy $historyRecord 'lifecycle proof record'
  Assert-C34LRecoveryExactNames $historyRecord.actionCounts `
    'lifecycle proof actionCounts' @(
      'build','upload','install','deviceAcceptance','passwordlessEmailSend',
      'realSmsSend','otherTrack','backendHostingProviderOrProductionDeployment'
    )
  Assert-C34LRecoveryExactNames $historyRecord.releaseAuthorities `
    'lifecycle proof releaseAuthorities' @(
      'build','uploadAndInternalActivation','inPlaceOppoPlayUpdate',
      'postinstallAcceptance'
    )
  Assert-C34LRecovery (
    [string]$historyRecord.ticketId -ceq $ticketId -and
    [int]$historyRecord.attempt -eq $Attempt -and
    [string]$historyRecord.evidencePath -cmatch '^[^\\?#]+$' -and
    [string]$historyRecord.sha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$historyRecord.preStateSha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$historyRecord.preAggregateSha256 -cmatch '^[0-9A-F]{64}$'
  ) 'lifecycle proof identity or binding shape changed.'
}
$countNames = @(
  'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
  'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
)
$authorityNames = @(
  'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)
foreach ($name in $countNames) {
  Assert-C34LRecovery (
    $null -ne $state.actionCounts.PSObject.Properties[$name] -and
    $null -ne $aggregate.actionCounts.PSObject.Properties[$name] -and
    [int]$state.actionCounts.$name -eq [int]$aggregate.actionCounts.$name
  ) "current action-count parity changed at $name."
}
foreach ($name in $authorityNames) {
  Assert-C34LRecovery (
    $null -ne $state.releaseAuthorities.PSObject.Properties[$name] -and
    $null -ne $aggregate.releaseAuthorities.PSObject.Properties[$name] -and
    [string]$state.releaseAuthorities.$name -ceq
      [string]$aggregate.releaseAuthorities.$name
  ) "current release-authority parity changed at $name."
}

# Exactly one completed provenance owner may exist, and it must match the selected attempt.
$selectedProvenanceLeaf = Get-C34LAttemptLeaf '06-release-aab-provenance' '.json'
$selectedProvenanceRelative = "$evidenceRoot/$selectedProvenanceLeaf"
$completed = @()
foreach ($number in 1..5) {
  $candidate = "$evidenceRoot/$(Get-C34LAttemptLeaf '06-release-aab-provenance' '.json' $number)"
  $candidateFile = Resolve-C34LRecoveryFile $candidate "provenance attempt $number" -AllowMissing
  if (Test-Path -LiteralPath $candidateFile -PathType Leaf) { $completed += $candidate }
}
Assert-C34LRecovery (
  $completed.Count -eq 1 -and [string]$completed[0] -ceq $selectedProvenanceRelative
) 'exactly one completed provenance owner for the selected attempt is required.'
$provenanceFile = Resolve-C34LRecoveryFile $selectedProvenanceRelative 'selected AAB provenance'
Assert-C34LRecoveryFixturePath $provenanceFile 'fixture AAB provenance'
$provenanceRaw = Get-Content -Raw -LiteralPath $provenanceFile
Assert-C34LRecovery (-not [regex]::IsMatch(
  $provenanceRaw,
  'AIza[0-9A-Za-z_-]{35}|(?i)Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----|\b[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com\b'
)) 'provenance contains secret- or private-identifier-shaped material.'
$provenance = $provenanceRaw | ConvertFrom-Json
Assert-C34LRecoveryExactNames $provenance 'AAB provenance' @(
  'schemaVersion','candidateId','preflightAttempt','versionName','versionCode',
  'packageName','buildMode','artifactType','authorizedTrack','branch','head',
  'powerShellMajor','providerRevisions','releaseConfigOnly',
  'qualifiedRegistrantSnapshot','qualifiedLocalPropertiesSnapshot',
  'releaseManifestPreflight','mergedReleaseManifest',
  'releaseManifestMergerBlame','releaseConfigOnlyProducedApkOrAab',
  'releaseRegistrantPluginCount','googleServicesGradlePlugin',
  'crashlyticsGradlePlugin','crashlyticsMappingUploadEnabled',
  'sourceManifest','sourceManifestSha256','sourceFiles','artifactPath',
  'artifactSha256','artifactBytes','uploadSignerSha256',
  'packageVersionManifestProved','googleAppIdResourceProved',
  'crashlyticsBuildIdResourceProved','splitAndArm64PayloadProved',
  'bundletoolPath','bundletoolSha256','bundletoolVersion','buildLog',
  'secretDefineFileReadByAgent','googleServicesFileReadByAgent',
  'secretValuesRecorded','builtAt'
)
Assert-C34LRecoveryPrivacy $provenance 'AAB provenance'
$artifactRelative = "$evidenceRoot/MoolSocial-$versionName-$versionCode-release.aab"
$artifactFile = Resolve-C34LRecoveryFile $artifactRelative 'sealed C34L AAB'
Assert-C34LRecoveryFixturePath $artifactFile 'fixture sealed AAB'
$artifactSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactFile).Hash
$artifactBytes = (Get-Item -LiteralPath $artifactFile).Length
if ($isRecovered) {
  Assert-C34LRecovery (
    [string]$state.buildResult.artifactPath -ceq $artifactRelative -and
    [string]$state.buildResult.artifactSha256 -ceq $artifactSha -and
    [int64]$state.buildResult.artifactBytes -eq $artifactBytes -and
    [string]$state.buildResult.provenance -ceq $selectedProvenanceRelative
  ) 'recovered state artifact or provenance binding changed.'
}
Assert-C34LRecovery (
  [int]$provenance.schemaVersion -eq 1 -and
  [string]$provenance.candidateId -ceq $ticketId -and [int]$provenance.preflightAttempt -eq $Attempt -and
  [string]$provenance.versionName -ceq $versionName -and [string]$provenance.versionCode -ceq $versionCode -and
  [string]$provenance.packageName -ceq $packageName -and [string]$provenance.buildMode -ceq 'release' -and
  [string]$provenance.artifactType -ceq 'AAB' -and [string]$provenance.authorizedTrack -ceq 'internal' -and
  [string]$provenance.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$provenance.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  [int]$provenance.powerShellMajor -ge 7 -and
  [string]$provenance.artifactPath -ceq $artifactRelative -and
  [string]$provenance.artifactSha256 -ceq $artifactSha -and
  [int64]$provenance.artifactBytes -eq $artifactBytes -and $artifactBytes -gt 0 -and
  [string]$provenance.uploadSignerSha256 -cmatch '^[0-9A-F]{64}$' -and
  -not [bool]$provenance.releaseConfigOnlyProducedApkOrAab -and
  [int]$provenance.releaseRegistrantPluginCount -gt 0 -and
  [string]$provenance.googleServicesGradlePlugin -ceq '4.5.0' -and
  [string]$provenance.crashlyticsGradlePlugin -ceq '3.0.7' -and
  -not [bool]$provenance.crashlyticsMappingUploadEnabled -and
  [bool]$provenance.packageVersionManifestProved -and [bool]$provenance.googleAppIdResourceProved -and
  [bool]$provenance.crashlyticsBuildIdResourceProved -and [bool]$provenance.splitAndArm64PayloadProved -and
  [string]$provenance.bundletoolVersion -ceq '1.18.3' -and
  -not [bool]$provenance.secretDefineFileReadByAgent -and
  -not [bool]$provenance.googleServicesFileReadByAgent -and
  -not [bool]$provenance.secretValuesRecorded
) 'artifact or provenance identity, attempt, payload or privacy proof changed.'

# Reverify the current source, not only the provenance booleans.
Assert-C34LRecovery (
  [string]$provenance.sourceManifest -ceq [string]$state.sourceQualification.manifestPath -and
  [string]$provenance.sourceManifestSha256 -ceq [string]$state.sourceQualification.manifestSha256
) 'provenance source seal does not match current candidate state.'
$sourceManifest = Resolve-C34LRecoveryFile ([string]$provenance.sourceManifest) 'sealed source manifest'
Assert-C34LRecoveryFixturePath $sourceManifest 'fixture source manifest'
Assert-C34LRecovery (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceManifest).Hash -ceq
    [string]$provenance.sourceManifestSha256
) 'sealed source-manifest bytes changed.'
$sourceRows = @(Get-Content -LiteralPath $sourceManifest)
Assert-C34LRecovery ($sourceRows.Count -eq [int]$provenance.sourceFiles -and $sourceRows.Count -gt 0) `
  'source-manifest file count changed.'
foreach ($row in $sourceRows) {
  $match = [regex]::Match($row, '^([0-9A-F]{64})  (.+)$')
  Assert-C34LRecovery $match.Success 'source-manifest row is malformed.'
  $owner = Resolve-C34LRecoveryFile $match.Groups[2].Value 'sealed source owner'
  Assert-C34LRecoveryFixturePath $owner 'fixture sealed source owner'
  Assert-C34LRecovery (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq $match.Groups[1].Value
  ) "source owner changed after seal: $($match.Groups[2].Value)"
}

# Every build-stage retained owner must be exact for this attempt.
$bindings = @(
  @('releaseConfigOnly',(Get-C34LAttemptLeaf '03-release-config-only' '.log')),
  @('releaseManifestPreflight',(Get-C34LAttemptLeaf '04-release-manifest-preflight' '.log')),
  @('mergedReleaseManifest',(Get-C34LAttemptLeaf '04a-merged-release-manifest' '.xml')),
  @('releaseManifestMergerBlame',(Get-C34LAttemptLeaf '04b-release-manifest-merger-blame' '.txt')),
  @('buildLog',(Get-C34LAttemptLeaf '05-release-aab-build' '.log'))
)
foreach ($binding in $bindings) {
  [void](Assert-C34LExactEvidencePath ([string]$provenance.($binding[0])) $binding[1] $binding[0])
}
$buildLog = Resolve-C34LRecoveryFile ([string]$provenance.buildLog) 'release build log'
Assert-C34LRecovery (
  @(Select-String -LiteralPath $buildLog -Pattern 'Built build[\\/]app[\\/]outputs[\\/]bundle[\\/]release[\\/]app-release[.]aab').Count -eq 1 -and
  @(Select-String -LiteralPath $buildLog -Pattern 'BUILD FAILED|FAILURE:|Exception:').Count -eq 0
) 'build log does not prove one successful failure-free AAB build.'

$expectedSigner =
  ([string]$state.signingQualification.uploadCertificateSha256).Replace(':','').ToUpperInvariant()
if ($FixtureMode) {
  Assert-C34LRecovery (
    [string]$provenance.uploadSignerSha256 -ceq $expectedSigner -and
    [string]$provenance.bundletoolPath -ceq 'tmp/bundletool-all-1.18.3.jar' -and
    [string]$provenance.bundletoolSha256 -cmatch '^[0-9A-F]{64}$'
  ) 'fixture provenance signer or bundletool identity changed.'
} else {
$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
$java = 'C:\Program Files\Android\Android Studio\jbr\bin\java.exe'
Assert-C34LRecovery (
  (Test-Path -LiteralPath $keytool -PathType Leaf) -and (Test-Path -LiteralPath $java -PathType Leaf)
) 'Android Studio keytool or Java is unavailable.'
$certificateOutput = & $keytool -printcert -jarfile $artifactFile 2>&1
Assert-C34LRecovery ($LASTEXITCODE -eq 0) 'current AAB signer certificate is unreadable.'
$signerMatch = [regex]::Match(($certificateOutput -join [Environment]::NewLine), 'SHA256:\s*([0-9A-Fa-f:]{64,95})')
Assert-C34LRecovery (
  $signerMatch.Success -and
  $signerMatch.Groups[1].Value.Replace(':','').ToUpperInvariant() -ceq $expectedSigner -and
  [string]$provenance.uploadSignerSha256 -ceq $expectedSigner
) 'current AAB signer does not match the qualified upload certificate.'
$certificateOutput = $null

Assert-C34LRecovery ([string]$provenance.bundletoolPath -ceq 'tmp/bundletool-all-1.18.3.jar') `
  'bundletool path is not the qualified standalone owner.'
$bundletool = Resolve-C34LRecoveryFile ([string]$provenance.bundletoolPath) 'standalone bundletool'
Assert-C34LRecovery (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $bundletool).Hash -ceq
    [string]$provenance.bundletoolSha256
) 'bundletool identity changed.'
function Invoke-C34LBundletool([string[]]$Arguments, [string]$Label) {
  $output = & $java -jar $bundletool @Arguments 2>&1
  Assert-C34LRecovery ($LASTEXITCODE -eq 0) "$Label failed."
  return ($output -join [Environment]::NewLine)
}
$package = (Invoke-C34LBundletool @('dump','manifest',"--bundle=$artifactFile",'--xpath=/manifest/@package') 'package proof').Trim()
$code = (Invoke-C34LBundletool @('dump','manifest',"--bundle=$artifactFile",'--xpath=/manifest/@android:versionCode') 'versionCode proof').Trim()
$name = (Invoke-C34LBundletool @('dump','manifest',"--bundle=$artifactFile",'--xpath=/manifest/@android:versionName') 'versionName proof').Trim()
Assert-C34LRecovery ($package -ceq $packageName -and $code -ceq $versionCode -and $name -ceq $versionName) `
  'current AAB package or version identity failed.'
$googleApp = Invoke-C34LBundletool @('dump','resources',"--bundle=$artifactFile",'--resource=string/google_app_id','--values') 'Google app ID proof'
Assert-C34LRecovery (
  $googleApp.Contains('google_app_id',[StringComparison]::Ordinal) -and
  [regex]::IsMatch($googleApp, '(?m)\[STR\]\s+"1:[0-9]+:android:[0-9a-f]+"')
) 'current AAB Google app ID resource is absent or malformed.'
$crashlytics = Invoke-C34LBundletool @('dump','resources',"--bundle=$artifactFile",'--resource=string/com.google.firebase.crashlytics.mapping_file_id','--values') 'Crashlytics proof'
Assert-C34LRecovery (
  $crashlytics.Contains('com.google.firebase.crashlytics.mapping_file_id',[StringComparison]::Ordinal) -and
  [regex]::IsMatch($crashlytics, '(?m)\[STR\]\s+"[0-9A-Fa-f]{32}"')
) 'current AAB Crashlytics build-ID resource is absent or malformed.'
$googleApp = $null; $crashlytics = $null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($artifactFile)
try {
  $entries = @($archive.Entries | ForEach-Object FullName)
  Assert-C34LRecovery (
    $entries -contains 'base/lib/arm64-v8a/libapp.so' -and
    $entries -contains 'base/lib/arm64-v8a/libflutter.so' -and
    $entries -contains 'base/resources.pb' -and
    $entries -contains 'base/manifest/AndroidManifest.xml'
  ) 'current AAB split/resource/manifest/arm64 payload is incomplete.'
} finally { $archive.Dispose() }

$mergedManifest = Assert-C34LExactEvidencePath ([string]$provenance.mergedReleaseManifest) `
  (Get-C34LAttemptLeaf '04a-merged-release-manifest' '.xml') 'merged release manifest'
[xml]$manifestXml = Get-Content -Raw -LiteralPath $mergedManifest
Assert-C34LRecovery ([string]$manifestXml.manifest.package -ceq $packageName) `
  'retained merged manifest package changed.'
$namespace = [Xml.XmlNamespaceManager]::new($manifestXml.NameTable)
$namespace.AddNamespace('android','http://schemas.android.com/apk/res/android')
$exported = @($manifestXml.SelectNodes('//*[@android:exported="true"]',$namespace) | ForEach-Object {
  $_.GetAttribute('name','http://schemas.android.com/apk/res/android')
})
$expectedExported = @(
  'com.moolsocial.app.MainActivity','com.moolsocial.app.YouTubeConnectReturnActivity',
  'com.google.firebase.auth.internal.GenericIdpActivity','com.google.firebase.auth.internal.RecaptchaActivity',
  'com.google.android.gms.auth.api.signin.RevocationBoundService','androidx.profileinstaller.ProfileInstallReceiver'
)
Assert-C34LRecovery (
  $exported.Count -eq $expectedExported.Count -and
  @($expectedExported | Where-Object { $exported -notcontains $_ }).Count -eq 0
) 'retained merged-manifest exported surface changed.'
}

# The non-mutating gate writes this proof before the missing transition. Recovery
# derives that immutable attempt owner directly; no post-transition state binding
# can exist at this crash boundary.
$resolvedEvidenceRoot = [IO.Path]::GetFullPath((Join-Path $root $evidenceRoot))
Assert-C34LRecovery (
  $resolvedEvidenceRoot.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
  (Test-Path -LiteralPath $resolvedEvidenceRoot -PathType Container) -and
  -not ((Get-Item -LiteralPath $resolvedEvidenceRoot -Force).Attributes -band
    [IO.FileAttributes]::ReparsePoint)
) 'approved C34L evidence root is missing, outside the repository or a reparse point.'
$expectedProofLeaf = "11b-build-succeeded-proof-attempt-$Attempt.json"
$proofOwners = @(Get-ChildItem -LiteralPath $resolvedEvidenceRoot -File `
  -Filter '11b-build-succeeded-proof-attempt-*.json')
Assert-C34LRecovery (
  $proofOwners.Count -eq 1 -and
  [string]$proofOwners[0].Name -ceq $expectedProofLeaf
) 'exactly one immutable build-succeeded proof owner for the selected attempt is required.'
$proofRelative = "$evidenceRoot/$expectedProofLeaf"
$proofFile = Resolve-C34LRecoveryFile $proofRelative 'build-succeeded prerequisite proof'
Assert-C34LRecoveryFixturePath $proofFile 'fixture prerequisite proof'
Assert-C34LRecovery (
  [string]$proofOwners[0].FullName -ceq [string]$proofFile
) 'build-succeeded prerequisite proof resolved to an alternate owner.'
$proofSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $proofFile).Hash
Assert-C34LRecovery ($proofSha -cmatch '^[0-9A-F]{64}$') `
  'build-succeeded prerequisite proof hash changed.'
$proof = Get-Content -Raw -LiteralPath $proofFile | ConvertFrom-Json
Assert-C34LRecoveryExactNames $proof 'build-succeeded prerequisite proof' @(
  'ticketId','attempt','versionName','versionCode','transition','phase','passed',
  'stateSha256','aggregateSha256','actionCounts','releaseAuthorities'
)
Assert-C34LRecoveryPrivacy $proof 'build-succeeded prerequisite proof'
$expectedProofStateSha256 = if ($isInterrupted) {
  $stateSha256
} else {
  [string]$proof.stateSha256
}
$expectedProofAggregateSha256 = if ($isInterrupted) {
  $aggregateSha256
} else {
  [string]$proof.aggregateSha256
}
Assert-C34LRecovery (
  [string]$proof.ticketId -ceq $ticketId -and [int]$proof.attempt -eq $Attempt -and
  [string]$proof.versionName -ceq $versionName -and
  [string]$proof.versionCode -ceq $versionCode -and [string]$proof.transition -ceq 'build-succeeded' -and
  [string]$proof.phase -ceq 'build' -and [bool]$proof.passed -and
  [string]$proof.stateSha256 -ceq $expectedProofStateSha256 -and
  [string]$proof.aggregateSha256 -ceq $expectedProofAggregateSha256 -and
  [string]$proof.stateSha256 -cmatch '^[0-9A-F]{64}$' -and
  [string]$proof.aggregateSha256 -cmatch '^[0-9A-F]{64}$'
) 'build-succeeded prerequisite proof identity, attempt, phase or current preimage changed.'
$expectedCounts = @(1,0,0,0,0,0,0,0)
$expectedAuthorities = @(
  'consumed','held_postbuild_qualification','held_postupload_qualification',
  'held_postinstall_journey_qualification'
)
Assert-C34LRecoveryExactNames $proof.actionCounts `
  'build-succeeded prerequisite proof actionCounts' $countNames
Assert-C34LRecoveryExactNames $proof.releaseAuthorities `
  'build-succeeded prerequisite proof releaseAuthorities' $authorityNames
for ($index = 0; $index -lt $countNames.Count; $index++) {
  $name = $countNames[$index]
  Assert-C34LRecovery (
    $null -ne $proof.actionCounts.PSObject.Properties[$name] -and
    [int]$proof.actionCounts.$name -eq $expectedCounts[$index] -and
    [int]$proof.actionCounts.$name -eq [int]$state.actionCounts.$name -and
    [int]$proof.actionCounts.$name -eq [int]$aggregate.actionCounts.$name
  ) "build-succeeded prerequisite proof count changed at $name."
}
for ($index = 0; $index -lt $authorityNames.Count; $index++) {
  $name = $authorityNames[$index]
  Assert-C34LRecovery (
    $null -ne $proof.releaseAuthorities.PSObject.Properties[$name] -and
    [string]$proof.releaseAuthorities.$name -ceq $expectedAuthorities[$index] -and
    [string]$proof.releaseAuthorities.$name -ceq
      [string]$state.releaseAuthorities.$name -and
    [string]$proof.releaseAuthorities.$name -ceq
      [string]$aggregate.releaseAuthorities.$name
  ) "build-succeeded prerequisite proof authority changed at $name."
}
if ($isRecovered) {
  Assert-C34LRecovery ($stateHistory.Count -gt 0) `
    'recovered state has no lifecycle transaction proof.'
  $newestProof = $stateHistory[-1]
  Assert-C34LRecoveryExactNames $newestProof `
    'newest recovered lifecycle proof' @(
      'ticketId','attempt','transition','phase','evidencePath','sha256',
      'preStateSha256','preAggregateSha256','actionCounts',
      'releaseAuthorities','browserEvidence'
    )
  Assert-C34LRecoveryPrivacy $newestProof 'newest recovered lifecycle proof'
  Assert-C34LRecovery (
    [string]$newestProof.ticketId -ceq $ticketId -and
    [int]$newestProof.attempt -eq $Attempt -and
    [string]$newestProof.transition -ceq 'build-succeeded' -and
    [string]$newestProof.phase -ceq 'build' -and
    [string]$newestProof.evidencePath -ceq $proofRelative -and
    [string]$newestProof.sha256 -ceq $proofSha -and
    [string]$newestProof.preStateSha256 -ceq [string]$proof.stateSha256 -and
    [string]$newestProof.preAggregateSha256 -ceq
      [string]$proof.aggregateSha256 -and
    $null -eq $newestProof.browserEvidence
  ) 'newest recovered lifecycle proof ticket, attempt, transition, phase, evidence, browser or preimage binding changed.'
  Assert-C34LRecovery (
    ($newestProof.actionCounts | ConvertTo-Json -Depth 10 -Compress) -ceq
      ($proof.actionCounts | ConvertTo-Json -Depth 10 -Compress) -and
    ($newestProof.releaseAuthorities | ConvertTo-Json -Depth 10 -Compress) -ceq
      ($proof.releaseAuthorities | ConvertTo-Json -Depth 10 -Compress)
  ) 'newest recovered lifecycle proof vector changed.'
}

if ($Mode -ceq 'apply') {
  if ($isInterrupted) {
    $transition = Resolve-C34LRecoveryFile `
      'scripts/invoke-release-lifecycle-transition-c34l.ps1' 'C34L lifecycle transition owner'
    & $transition -Transition build-succeeded -StatePath $StatePath `
      -ArtifactPath $artifactRelative -ArtifactSha256 $artifactSha `
      -ArtifactBytes $artifactBytes -UploadSignerSha256 $expectedSigner `
      -ArtifactProvenance $selectedProvenanceRelative `
      -PrerequisiteGateEvidencePath $proofRelative `
      -PrerequisiteGateEvidenceSha256 $proofSha -PrerequisiteGatePhase build `
      -Attempt $Attempt -FixtureMode:$FixtureMode `
      -RepositoryRoot $root | Out-Null
  }
  $retainedArguments = @{
    Phase='build'; Attempt=$Attempt; StatePath=$StatePath; RepositoryRoot=$root
  }
  if ($FixtureMode) { $retainedArguments.FixtureMode = $true }
  & (Join-Path $root 'scripts/check-release-retained-evidence-c34l.ps1') `
    @retainedArguments
  if (-not $FixtureMode) {
    $candidateGate = Join-Path $root `
      'scripts/check-uaw-c34l-r60-76-consolidated-release-transaction-evidence-readiness.ps1'
    if (Test-Path -LiteralPath $candidateGate -PathType Leaf) {
      & $candidateGate -Phase postbuild -StatePath $StatePath -RepositoryRoot $root
    }
  }
}

Write-Output (
  'C34L existing-AAB postbuild recovery passed: ' +
  "mode=$Mode; attempt=$Attempt; sha256=$artifactSha; bytes=$artifactBytes; " +
  "fixtureMode=$([bool]$FixtureMode); idempotent=$([bool]$isRecovered); " +
  'currentSource=true; artifactAudit=true; ' +
  'secondBuild=false; upload=0; install=0; OPPO=untouched.'
)
