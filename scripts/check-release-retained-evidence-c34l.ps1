[CmdletBinding()]
param(
  [ValidateSet('build', 'play', 'oppo', 'journey', 'all')]
  [string]$Phase = 'all',
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
$deviceModel = 'CPH2375'
$captureArtifactContractPath =
  'config/release-evidence-capture-artifact-contract-c34l.json'
$captureArtifactContractSha256 =
  'D7B8DE822D709F25CEB1AEFFFF4093260B3EFB83DCADE1F632309026ECC0B9D2'
$captureArtifactContractId = 'MOOLSOCIAL-C34L-CAPTURE-ARTIFACT-CONTRACT-003'
$productionEvidenceRoot =
  'artifacts/quality/uaw-c34l-r60-76-consolidated-release-transaction-evidence-preparation-20260817-01'
$countNames = @(
  'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
  'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
)
$authorityNames = @(
  'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)
$sourceAttestationNames = @(
  'schemaVersion','attestationContractId','evidenceType','ticketId','attempt',
  'packageName','versionName','versionCode','preStateSha256',
  'preAggregateSha256','actionCounts','releaseAuthorities','artifactSha256',
  'artifactBytes','sourceProducerId','sessionId','nonceSha256','producedUtc',
  'expiresUtc','captureManifestPath','captureManifestSha256',
  'captureManifestBytes','captureDigests'
)
$captureManifestNames = @(
  'schemaVersion','captureContractId','evidenceType','ticketId','attempt',
  'packageName','versionName','versionCode','preStateSha256',
  'preAggregateSha256','actionCounts','releaseAuthorities','artifactSha256',
  'artifactBytes','sourceProducerId','sessionId','nonceSha256','producedUtc',
  'expiresUtc','captureDigests','captureArtifactContractPath',
  'captureArtifactContractSha256','captureArtifactContractId','captureArtifacts'
)
$sourceBindingNames = @(
  'path','sha256','bytes','evidenceType','sourceProducerId','sessionId',
  'nonceSha256','producedUtc','expiresUtc','captureManifestPath',
  'captureManifestSha256','captureManifestBytes','captureDigests'
)

function Assert-C34LEvidence([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C34L retained-evidence gate rejected: $Message" }
}
function Resolve-C34LRelativeFile([string]$Path, [string]$Label) {
  Assert-C34LEvidence (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path) -and
    -not $Path.Contains('\') -and -not $Path.Contains('?') -and
    -not $Path.Contains('#')
  ) "$Label must be one normalized repository-relative path."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LEvidence (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) "$Label is missing or outside the production repository."
  $current = $resolved
  while ($true) {
    Assert-C34LEvidence (
      $current.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
      $current.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) "$Label ancestor escaped the production repository."
    Assert-C34LEvidence (Test-Path -LiteralPath $current) `
      "$Label ancestor is missing."
    Assert-C34LEvidence (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $current = [IO.Path]::GetFullPath((Split-Path -Parent $current))
  }
  return $resolved
}
function Assert-C34LExactNames($Object, [string]$Label, [string[]]$Names) {
  Assert-C34LEvidence ($null -ne $Object) "$Label is missing."
  $actual = @($Object.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LEvidence ($actual.Count -eq $Names.Count) `
    "$Label property count changed."
  foreach ($name in $Names) {
    Assert-C34LEvidence ($actual -ccontains $name) `
      "$Label is missing or has an unknown property at $name."
  }
}
function Assert-C34LProperties($Object, [string]$Label, [string[]]$Names) {
  foreach ($name in $Names) {
    Assert-C34LEvidence ($null -ne $Object.PSObject.Properties[$name]) `
      "$Label is missing property $name."
  }
}
function Assert-C34LPrivacy($Value, [string]$Label, [string]$PropertyPath = '') {
  if ($Value -is [System.Collections.IDictionary]) {
    foreach ($key in @($Value.Keys)) {
      $name = [string]$key
      $path = if ($PropertyPath) { "$PropertyPath.$name" } else { $name }
      Assert-C34LPrivacyPropertyName $name $Label $path
      Assert-C34LPrivacy $Value[$key] $Label $path
    }
    return
  }
  if ($Value -is [System.Management.Automation.PSCustomObject]) {
    foreach ($property in @($Value.PSObject.Properties)) {
      $path = if ($PropertyPath) { "$PropertyPath.$($property.Name)" } else { $property.Name }
      Assert-C34LPrivacyPropertyName $property.Name $Label $path
      Assert-C34LPrivacy $property.Value $Label $path
    }
    return
  }
  if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
    foreach ($item in @($Value)) { Assert-C34LPrivacy $item $Label $PropertyPath }
    return
  }
  if ($null -eq $Value -or $Value -isnot [string]) { return }
  $text = [string]$Value
  $privateShape =
    '(?i)([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|https?://|www\.|' +
    '(?:Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+|(?:access|refresh|id)[_-]?token\s*[:=]|' +
    'authorization\s*[:=]|(?:set-)?cookie\s*[:=]|session[_-]?cookie|' +
    'AIza[0-9A-Za-z_-]{35}|-----BEGIN(?: [A-Z]+)* PRIVATE KEY-----|' +
    'Exception(?:\s*:|\r|\n)|StackTrace|Traceback\s*\(|' +
    '[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com|' +
    '^[A-Za-z0-9_-]{16,}[.][A-Za-z0-9_-]{16,}[.][A-Za-z0-9_-]{16,}$|' +
    '[?&][A-Za-z0-9_.%+-]+=[^\s]*|#[A-Za-z0-9_.%+-]+)'
  Assert-C34LEvidence (-not [regex]::IsMatch($text, $privateShape)) `
    "$Label contains a forbidden private value shape at $PropertyPath."
  $publicNumericPaths = @(
    'versionCode','artifactBytes','bytes','captureManifestBytes',
    'firstInstallTimeMillis','lastUpdateTimeMillis','attempt'
  )
  $publicPathLeaves = @(
    'path','artifactPath','captureManifestPath','sourceManifest','provenance',
    'releaseConfigOnly','releaseManifestPreflight','mergedReleaseManifest',
    'releaseManifestMergerBlame','buildLog','bundletoolPath'
  )
  $leaf = ($PropertyPath -split '[.]')[-1]
  if ($publicNumericPaths -notcontains $leaf -and
      $leaf -notmatch '(?:Count|Sha256)$' -and
      $leaf -notin @('producedUtc','expiresUtc','preparedUtc','committedUtc',
        'ticketId','branch','builtAt',
        'sourceProducerId','evidencePairId','deviceBindingSha256','deviceModel',
        'packageName','versionName','installerPackage') -and
      $publicPathLeaves -notcontains $leaf) {
    Assert-C34LEvidence (
      -not [regex]::IsMatch($text,
        '(?<![A-Za-z0-9])(?:[+]?[1-9][0-9]{0,2}[ ().-]*)?(?:[0-9][ ().-]*){7,15}(?![A-Za-z0-9])')
    ) "$Label contains a forbidden phone-shaped value at $PropertyPath."
  }
}
function Assert-C34LPrivacyPropertyName(
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
    'agentSecretValueAccessAuthorized','privateValuesAllowed',
    'rawDeviceIdentifierAllowed','rawExceptionOrStackAllowed'
  )
  $rawDeviceNames = @(
    'deviceSerial','serial','androidId','imei','imsi','advertisingId'
  )
  Assert-C34LEvidence ($rawDeviceNames -cnotcontains $Name) `
    "$Label contains forbidden raw device property $PropertyPath."
  if ($approvedSensitiveNames -ccontains $Name) { return }
  Assert-C34LEvidence (
    $Name -cnotmatch
      '(?i)(?:password|credential|secret|private|access.?token|refresh.?token|' +
      'id.?token|authorization|cookie|exception|stack.?trace|traceback|' +
      'device.?serial|android.?id|imei|imsi|advertising.?id|phone|mobile|' +
      'e.?mail|private.?url|private.?uri|query.?value|fragment.?value)'
  ) "$Label contains a forbidden private property name at $PropertyPath."
}
function Assert-C34LBuiltAtRaw([string]$Raw, [string]$Label) {
  $matches = [regex]::Matches(
    $Raw,
    '"builtAt"\s*:\s*"([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[.][0-9]{7}(?:Z|[+-][0-9]{2}:[0-9]{2}))"'
  )
  Assert-C34LEvidence ($matches.Count -eq 1) `
    "$Label builtAt raw JSON token must be exact invariant round-trip ISO-8601."
  $wire = [string]$matches[0].Groups[1].Value
  $parsed = [DateTimeOffset]::MinValue
  $format = "yyyy-MM-dd'T'HH:mm:ss.fffffffzzz"
  $styles = [Globalization.DateTimeStyles]::None
  if ($wire.EndsWith('Z', [StringComparison]::Ordinal)) {
    $format = "yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'"
    $styles = [Globalization.DateTimeStyles]::AssumeUniversal -bor
      [Globalization.DateTimeStyles]::AdjustToUniversal
  }
  $ok = [DateTimeOffset]::TryParseExact(
    $wire, $format, [Globalization.CultureInfo]::InvariantCulture,
    $styles, [ref]$parsed
  )
  Assert-C34LEvidence $ok `
    "$Label builtAt is not one semantically valid round-trip instant."
  return $parsed.ToUniversalTime()
}
function ConvertTo-C34LUtcText($Value, [string]$Label) {
  $parsed = [DateTimeOffset]::MinValue
  $ok = $true
  if ($Value -is [DateTimeOffset]) {
    $parsed = ([DateTimeOffset]$Value).ToUniversalTime()
  } elseif ($Value -is [DateTime]) {
    $parsed = [DateTimeOffset]::new(([DateTime]$Value).ToUniversalTime())
  } else {
    $ok = [DateTimeOffset]::TryParseExact(
      [string]$Value, "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
      [Globalization.CultureInfo]::InvariantCulture,
      [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed
    )
  }
  Assert-C34LEvidence $ok "$Label must be canonical UTC with milliseconds."
  return $parsed.ToUniversalTime().ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'", [Globalization.CultureInfo]::InvariantCulture
  )
}
function Assert-C34LRawUtc([string]$Raw, [string]$Name, [string]$Expected, [string]$Label) {
  $matches = [regex]::Matches(
    $Raw, '"' + [regex]::Escape($Name) + '"\s*:\s*"([^"]+)"'
  )
  Assert-C34LEvidence (
    $matches.Count -eq 1 -and $matches[0].Groups[1].Value -ceq $Expected
  ) "$Label raw $Name is not one exact canonical UTC string."
}
function Read-C34LJson([string]$Path, [string]$Label) {
  $resolved = Resolve-C34LRelativeFile $Path $Label
  $raw = Get-Content -Raw -LiteralPath $resolved
  try { $value = $raw | ConvertFrom-Json } catch {
    throw "C34L retained-evidence gate rejected: $Label is not valid JSON."
  }
  if ($null -ne $value.PSObject.Properties['builtAt']) {
    [void](Assert-C34LBuiltAtRaw $raw $Label)
  }
  Assert-C34LPrivacy $value $Label
  return $value
}
function Get-C34LAttemptLeaf([string]$Stem, [string]$Extension) {
  if ($Attempt -eq 1) { return "$Stem$Extension" }
  return "$Stem-attempt-$Attempt$Extension"
}
function Get-C34LRepositoryRelativePath([string]$Resolved) {
  $rootUri = [Uri]::new($rootPrefix)
  $resolvedUri = [Uri]::new($Resolved)
  return [Uri]::UnescapeDataString(
    $rootUri.MakeRelativeUri($resolvedUri).ToString()
  ).Replace('\', '/')
}

$stateFile = Resolve-C34LRelativeFile $StatePath 'detailed candidate state'
$stateRelative = Get-C34LRepositoryRelativePath $stateFile
if ($FixtureMode) {
  Assert-C34LEvidence (
    $stateRelative -cmatch
      '^(?:tmp/c34l-retained-evidence-fixtures-[0-9A-Za-z_-]+|tmp/c34l-release-transaction-fixtures/recovery-[0-9A-Za-z_-]+)/state[.]json$'
  ) 'FixtureMode is confined to an exact C34L temporary fixture root.'
  $fixtureRoot = (Split-Path -Parent $stateRelative).Replace('\', '/')
  $fixturePrefix = "$fixtureRoot/"
  Assert-C34LEvidence (
    $stateRelative.StartsWith($fixturePrefix, [StringComparison]::Ordinal) -and
    -not $fixtureRoot.Contains('\')
  ) 'fixture detailed state does not share one normalized fixture prefix.'
  $expectedEvidenceRoot = "$fixtureRoot/evidence"
  Assert-C34LEvidence (
    $expectedEvidenceRoot.StartsWith($fixturePrefix, [StringComparison]::Ordinal) -and
    -not $expectedEvidenceRoot.Contains('\')
  ) 'fixture evidence root does not share one normalized fixture prefix.'
} else {
  Assert-C34LEvidence (
    $stateRelative -ceq 'config/successor-aab-regression-hard-gate-state-c34l.json'
  ) 'production validation requires the exact C34L candidate state.'
  $expectedEvidenceRoot = $productionEvidenceRoot
}
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C34LProperties $state 'detailed candidate state' @(
  'ticketId', 'candidate', 'aggregateStatePath', 'sourceQualification',
  'buildResult', 'playResult', 'installResult', 'actionCounts',
  'releaseAuthorities', 'lifecycleTransactionProofs'
)
Assert-C34LProperties $state.candidate 'candidate' @(
  'id','packageName','versionName','versionCode','deviceBindingSha256','deviceModel'
)
Assert-C34LEvidence (
  [string]$state.ticketId -ceq $ticketId -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$state.candidate.packageName -ceq $packageName -and
  [string]$state.candidate.versionName -ceq $versionName -and
  [string]$state.candidate.versionCode -ceq $versionCode -and
  [string]$state.candidate.deviceBindingSha256 -ceq $deviceBindingSha256 -and
  [string]$state.candidate.deviceModel -ceq $deviceModel -and
  $null -eq $state.candidate.PSObject.Properties['deviceSerial']
) 'candidate or version identity changed.'
$aggregateFile = Resolve-C34LRelativeFile ([string]$state.aggregateStatePath) `
  'aggregate candidate state'
$aggregateRelative = Get-C34LRepositoryRelativePath $aggregateFile
if ($FixtureMode) {
  Assert-C34LEvidence (
    $aggregateRelative -ceq "$fixtureRoot/aggregate.json" -and
    $aggregateRelative.StartsWith($fixturePrefix, [StringComparison]::Ordinal) -and
    -not $aggregateRelative.Contains('\')
  ) `
    'fixture aggregate state escaped the exact fixture root.'
} else {
  Assert-C34LEvidence (
    $aggregateRelative -ceq
      'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
  ) 'production validation requires the exact C34L aggregate state.'
}
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
Assert-C34LProperties $aggregate 'aggregate candidate state' @(
  'ticketId', 'candidate', 'actionCounts', 'releaseAuthorities',
  'lifecycleTransactionProofs'
)
Assert-C34LProperties $aggregate.candidate 'aggregate candidate' @(
  'id','versionName','versionCode'
)
Assert-C34LEvidence (
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.versionName -ceq $versionName -and
  [string]$aggregate.candidate.versionCode -ceq $versionCode
) 'aggregate candidate or version identity changed.'

Assert-C34LExactNames $state.actionCounts 'detailed state actionCounts' $countNames
Assert-C34LExactNames $aggregate.actionCounts 'aggregate state actionCounts' $countNames
Assert-C34LExactNames $state.releaseAuthorities `
  'detailed state releaseAuthorities' $authorityNames
Assert-C34LExactNames $aggregate.releaseAuthorities `
  'aggregate state releaseAuthorities' $authorityNames
foreach ($name in $countNames) {
  Assert-C34LEvidence (
    $null -ne $state.actionCounts.PSObject.Properties[$name] -and
    $null -ne $aggregate.actionCounts.PSObject.Properties[$name] -and
    [int]$state.actionCounts.$name -eq [int]$aggregate.actionCounts.$name
  ) "current action-count parity changed at $name."
}
foreach ($name in $authorityNames) {
  Assert-C34LEvidence (
    $null -ne $state.releaseAuthorities.PSObject.Properties[$name] -and
    $null -ne $aggregate.releaseAuthorities.PSObject.Properties[$name] -and
    [string]$state.releaseAuthorities.$name -ceq
      [string]$aggregate.releaseAuthorities.$name
  ) "current release-authority parity changed at $name."
}

function Assert-C34LExactPath([string]$Actual, [string]$Leaf, [string]$Label) {
  $expected = "$expectedEvidenceRoot/$Leaf"
  if ($FixtureMode) {
    Assert-C34LEvidence (
      $Actual.StartsWith($fixturePrefix, [StringComparison]::Ordinal) -and
      -not $Actual.Contains('\')
    ) "$Label does not share one normalized fixture prefix."
  }
  Assert-C34LEvidence ([string]$Actual -ceq $expected) `
    "$Label is not the exact candidate evidence owner."
  return Resolve-C34LRelativeFile $Actual $Label
}
function Assert-C34LEvidenceFileBinding(
  [string]$ActualPath,
  [string]$ActualSha256,
  [long]$ActualBytes,
  [string]$Leaf,
  [string]$Label
) {
  $resolved = Assert-C34LExactPath $ActualPath $Leaf $Label
  $observedSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolved).Hash
  $observedBytes = (Get-Item -LiteralPath $resolved).Length
  Assert-C34LEvidence (
    $ActualSha256 -cmatch '^[0-9A-F]{64}$' -and
    $observedSha256 -ceq $ActualSha256 -and
    $ActualBytes -gt 0 -and $observedBytes -eq $ActualBytes
  ) "$Label SHA-256 or byte-length binding changed."
  return $resolved
}
function Assert-C34LVector(
  $Value,
  [int[]]$ExpectedCounts,
  [string[]]$ExpectedAuthorities,
  [string]$Label
) {
  Assert-C34LExactNames $Value.actionCounts "$Label actionCounts" $countNames
  Assert-C34LExactNames $Value.releaseAuthorities `
    "$Label releaseAuthorities" $authorityNames
  Assert-C34LEvidence (
    $ExpectedCounts.Count -eq $countNames.Count -and
    $ExpectedAuthorities.Count -eq $authorityNames.Count
  ) "$Label expected release vector is incomplete."
  for ($index = 0; $index -lt $countNames.Count; $index++) {
    $name = $countNames[$index]
    Assert-C34LEvidence (
      [int]$Value.actionCounts.$name -eq $ExpectedCounts[$index]
    ) "$Label action count changed at $name."
  }
  for ($index = 0; $index -lt $authorityNames.Count; $index++) {
    $name = $authorityNames[$index]
    Assert-C34LEvidence (
      [string]$Value.releaseAuthorities.$name -ceq $ExpectedAuthorities[$index]
    ) "$Label release authority changed at $name."
  }
}
function Get-C34LSourceSpec([ValidateSet('play','oppo','journey')][string]$Kind) {
  switch ($Kind) {
    'play' {
      return [pscustomobject]@{
        EvidenceType='play_internal_testing_activation'; Short='play'
        Producer='MOOLSOCIAL-C34L-PLAY-CAPTURE-PRODUCER-001'
        Digests=@('internalTestingRouteDigestSha256','uploadReceiptDigestSha256',
          'activationStateDigestSha256')
        Counts=@(1,0,0,0,0,0,0,0)
        Authorities=@('consumed','available_once',
          'held_postupload_qualification','held_postinstall_journey_qualification')
      }
    }
    'oppo' {
      return [pscustomobject]@{
        EvidenceType='oppo_play_in_place_update_pair'; Short='oppo'
        Producer='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
        Digests=@('packageStateDigestSha256','coldStartDigestSha256',
          'retainedDataDigestSha256')
        Counts=@(1,1,0,0,0,0,0,0)
        Authorities=@('consumed','consumed','available_once',
          'held_postinstall_journey_qualification')
      }
    }
    'journey' {
      return [pscustomobject]@{
        EvidenceType='mandatory_whole_app_journey_acceptance'; Short='journey'
        Producer='MOOLSOCIAL-C34L-JOURNEY-CAPTURE-PRODUCER-001'
        Digests=@('publicGuestDigestSha256','protectedGatewayDigestSha256',
          'supportedAuthenticationDigestSha256','socialDigestSha256',
          'wholeAppDigestSha256','c33gBlockerDigestSha256')
        Counts=@(1,1,1,0,0,0,0,0)
        Authorities=@('consumed','consumed','consumed',
          'held_postinstall_journey_qualification')
      }
    }
  }
}
function Read-C34LCaptureArtifactContract {
  $contractFile = Resolve-C34LRelativeFile $captureArtifactContractPath `
    'capture-artifact contract'
  Assert-C34LEvidence (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $contractFile).Hash -ceq
      $captureArtifactContractSha256
  ) 'capture-artifact contract SHA-256 changed.'
  try { $contract = Get-Content -Raw -LiteralPath $contractFile |
      ConvertFrom-Json } catch {
    throw 'C34L retained-evidence gate rejected: capture-artifact contract is not valid JSON.'
  }
  Assert-C34LExactNames $contract 'capture-artifact contract' @(
    'schemaVersion','contractId','ticketId','productionProducer',
    'authoritativeReceipt','captureAttemptRootPattern',
    'captureManifestPathPattern','captureArtifactPathPattern',
    'captureArtifactFields','mediaType','evidenceTypes','deviceBinding','privacy'
  )
  Assert-C34LExactNames $contract.deviceBinding `
    'capture-artifact contract deviceBinding' @(
      'derivationId','derivationPattern','expectedSha256','retainedField',
      'forbiddenRawFields'
    )
  Assert-C34LEvidence (
    [int]$contract.schemaVersion -eq 3 -and
    [string]$contract.contractId -ceq $captureArtifactContractId -and
    [string]$contract.ticketId -ceq
      'UAW-C34L-PRE-AAB-2-FIX3-AUTHORITATIVE-CAPTURE-PRODUCER-RECEIPT' -and
    [string]$contract.mediaType -ceq 'application/json' -and
    (@($contract.captureArtifactFields) -join '|') -ceq
      'role|path|sha256|bytes|mediaType' -and
    [string]$contract.deviceBinding.expectedSha256 -ceq
      $deviceBindingSha256 -and
    [string]$contract.deviceBinding.retainedField -ceq 'deviceBindingSha256' -and
    (@($contract.deviceBinding.forbiddenRawFields) -join '|') -ceq
      'deviceSerial|serial|androidId|imei|imsi|advertisingId'
  ) 'capture-artifact contract identity, media type or device binding changed.'
  return $contract
}
function Assert-C34LCaptureArtifactPayload(
  [string]$Kind,
  [string]$Role,
  $Value,
  $Attestation,
  $Artifact,
  [string]$Label
) {
  Assert-C34LPrivacy $Value $Label
  if ($Kind -ceq 'play') {
    $names = if ($Role -ceq 'internal_testing_release_receipt') {
      @(
        'schemaVersion','captureRole','ticketId','attempt','packageName',
        'versionName','versionCode','artifactSha256','artifactBytes','track',
        'uploadCount','otherTrackChanged','sourceProducerId','sessionId','nonceSha256'
      )
    } else {
      @(
        'schemaVersion','captureRole','ticketId','attempt','packageName',
        'versionName','versionCode','artifactSha256','artifactBytes','track',
        'internalReleaseActive','internalActivationCount','sourceProducerId',
        'sessionId','nonceSha256'
      )
    }
    Assert-C34LExactNames $Value $Label $names
    Assert-C34LEvidence (
      [int]$Value.schemaVersion -eq 1 -and
      [string]$Value.captureRole -ceq $Role -and
      [string]$Value.ticketId -ceq $ticketId -and
      [int]$Value.attempt -eq $Attempt -and
      [string]$Value.packageName -ceq $packageName -and
      [string]$Value.versionName -ceq $versionName -and
      [string]$Value.versionCode -ceq $versionCode -and
      [string]$Value.artifactSha256 -ceq $Artifact.Sha -and
      [int64]$Value.artifactBytes -eq $Artifact.Bytes -and
      [string]$Value.track -ceq 'internal' -and
      [string]$Value.sourceProducerId -ceq [string]$Attestation.sourceProducerId -and
      [string]$Value.sessionId -ceq [string]$Attestation.sessionId -and
      [string]$Value.nonceSha256 -ceq [string]$Attestation.nonceSha256
    ) "$Label identity, artifact or session changed."
    if ($Role -ceq 'internal_testing_release_receipt') {
      Assert-C34LEvidence (
        [int]$Value.uploadCount -eq 1 -and -not [bool]$Value.otherTrackChanged
      ) "$Label upload or track result changed."
    } else {
      Assert-C34LEvidence (
        [bool]$Value.internalReleaseActive -and
        [int]$Value.internalActivationCount -eq 1
      ) "$Label activation result changed."
    }
    return
  }
  if ($Kind -ceq 'oppo') {
    $common = @(
      'schemaVersion','captureArtifactContractId','evidenceType','role','ticketId',
      'attempt','packageName','versionName','versionCode','artifactSha256',
      'artifactBytes','deviceBindingSha256','deviceModel','installerPackage',
      'sourceProducerId','sessionId','nonceSha256'
    )
    $specific = if ($Role -ceq 'cold_start_observation') {
      @(
        'coldStartInteractive','blankHierarchy','timeout','flutterFatalErrorCount',
        'androidRuntimeFatalCount','anrCount','appProcessErrorScanPassed',
        'artifactRelationshipProved','inPlaceUpdateProved'
      )
    } else {
      @(
        'firstInstallTimeMillis','lastUpdateTimeMillis','firstInstallTimePreserved',
        'retainedDataContinuityProved','inPlacePlayUpdateProved',
        'uninstallPerformed','dataClearPerformed','downgradePerformed',
        'adbInstallPerformed'
      )
    }
    Assert-C34LExactNames $Value $Label ($common + $specific)
    Assert-C34LEvidence (
      [int]$Value.schemaVersion -eq 1 -and
      [string]$Value.captureArtifactContractId -ceq $captureArtifactContractId -and
      [string]$Value.evidenceType -ceq 'oppo_play_in_place_update_pair' -and
      [string]$Value.role -ceq $Role -and
      [string]$Value.ticketId -ceq $ticketId -and [int]$Value.attempt -eq $Attempt -and
      [string]$Value.packageName -ceq $packageName -and
      [string]$Value.versionName -ceq $versionName -and
      [string]$Value.versionCode -ceq $versionCode -and
      [string]$Value.artifactSha256 -ceq $Artifact.Sha -and
      [int64]$Value.artifactBytes -eq $Artifact.Bytes -and
      [string]$Value.deviceBindingSha256 -ceq $deviceBindingSha256 -and
      [string]$Value.deviceModel -ceq $deviceModel -and
      [string]$Value.installerPackage -ceq 'com.android.vending' -and
      [string]$Value.sourceProducerId -ceq [string]$Attestation.sourceProducerId -and
      [string]$Value.sessionId -ceq [string]$Attestation.sessionId -and
      [string]$Value.nonceSha256 -ceq [string]$Attestation.nonceSha256
    ) "$Label identity, artifact, device binding or session changed."
    if ($Role -ceq 'cold_start_observation') {
      Assert-C34LEvidence (
        [bool]$Value.coldStartInteractive -and -not [bool]$Value.blankHierarchy -and
        -not [bool]$Value.timeout -and [int]$Value.flutterFatalErrorCount -eq 0 -and
        [int]$Value.androidRuntimeFatalCount -eq 0 -and [int]$Value.anrCount -eq 0 -and
        [bool]$Value.appProcessErrorScanPassed -and
        [bool]$Value.artifactRelationshipProved -and [bool]$Value.inPlaceUpdateProved
      ) "$Label cold-start result changed."
    } else {
      Assert-C34LEvidence (
        [int64]$Value.firstInstallTimeMillis -gt 0 -and
        [int64]$Value.lastUpdateTimeMillis -gt [int64]$Value.firstInstallTimeMillis -and
        [bool]$Value.firstInstallTimePreserved -and
        [bool]$Value.retainedDataContinuityProved -and
        [bool]$Value.inPlacePlayUpdateProved -and
        -not [bool]$Value.uninstallPerformed -and -not [bool]$Value.dataClearPerformed -and
        -not [bool]$Value.downgradePerformed -and -not [bool]$Value.adbInstallPerformed
      ) "$Label retained-state result changed."
    }
  }
}
function Assert-C34LCaptureGraph(
  $Capture,
  [string]$CaptureRaw,
  [ValidateSet('play','oppo','journey')][string]$Kind,
  $Attestation,
  $Artifact,
  [string]$Label
) {
  $spec = Get-C34LSourceSpec $Kind
  $contract = Read-C34LCaptureArtifactContract
  Assert-C34LExactNames $Capture "$Label capture manifest" $captureManifestNames
  Assert-C34LExactNames $Capture.captureDigests `
    "$Label capture-manifest captureDigests" $spec.Digests
  Assert-C34LPrivacy $Capture "$Label capture manifest"
  Assert-C34LVector $Capture $spec.Counts $spec.Authorities "$Label capture manifest"
  $captureProduced = ConvertTo-C34LUtcText $Capture.producedUtc `
    "$Label capture manifest producedUtc"
  $captureExpires = ConvertTo-C34LUtcText $Capture.expiresUtc `
    "$Label capture manifest expiresUtc"
  Assert-C34LRawUtc $CaptureRaw 'producedUtc' $captureProduced "$Label capture manifest"
  Assert-C34LRawUtc $CaptureRaw 'expiresUtc' $captureExpires "$Label capture manifest"
  Assert-C34LEvidence (
    [int]$Capture.schemaVersion -eq 1 -and
    [string]$Capture.captureContractId -ceq
      'MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001' -and
    [string]$Capture.evidenceType -ceq [string]$Attestation.evidenceType -and
    [string]$Capture.ticketId -ceq [string]$Attestation.ticketId -and
    [int]$Capture.attempt -eq [int]$Attestation.attempt -and
    [string]$Capture.packageName -ceq [string]$Attestation.packageName -and
    [string]$Capture.versionName -ceq [string]$Attestation.versionName -and
    [string]$Capture.versionCode -ceq [string]$Attestation.versionCode -and
    [string]$Capture.preStateSha256 -ceq [string]$Attestation.preStateSha256 -and
    [string]$Capture.preAggregateSha256 -ceq [string]$Attestation.preAggregateSha256 -and
    [string]$Capture.artifactSha256 -ceq $Artifact.Sha -and
    [int64]$Capture.artifactBytes -eq $Artifact.Bytes -and
    [string]$Capture.sourceProducerId -ceq [string]$Attestation.sourceProducerId -and
    [string]$Capture.sessionId -ceq [string]$Attestation.sessionId -and
    [string]$Capture.nonceSha256 -ceq [string]$Attestation.nonceSha256 -and
    $captureProduced -ceq (ConvertTo-C34LUtcText $Attestation.producedUtc 'attestation producedUtc') -and
    $captureExpires -ceq (ConvertTo-C34LUtcText $Attestation.expiresUtc 'attestation expiresUtc') -and
    [string]$Capture.captureArtifactContractPath -ceq $captureArtifactContractPath -and
    [string]$Capture.captureArtifactContractSha256 -ceq
      $captureArtifactContractSha256 -and
    [string]$Capture.captureArtifactContractId -ceq $captureArtifactContractId
  ) "$Label capture-manifest identity, preimage, artifact, session or contract changed."
  foreach ($name in $spec.Digests) {
    Assert-C34LEvidence (
      [string]$Capture.captureDigests.$name -ceq
        [string]$Attestation.captureDigests.$name
    ) "$Label capture-manifest digest changed at $name."
  }
  $contractSpec = $contract.evidenceTypes.($spec.EvidenceType)
  $expectedRoles = @($contractSpec.roles)
  $bindings = @($Capture.captureArtifacts)
  Assert-C34LEvidence (
    $bindings.Count -eq $expectedRoles.Count -and
    @($bindings.role | Select-Object -Unique).Count -eq $bindings.Count -and
    (@($bindings.role | Sort-Object) -join '|') -ceq
      (@($expectedRoles | Sort-Object) -join '|')
  ) "$Label capture-artifact role set changed."
  $byRole = @{}
  foreach ($binding in $bindings) {
    Assert-C34LExactNames $binding "$Label capture artifact binding" `
      @('role','path','sha256','bytes','mediaType')
    $role = [string]$binding.role
    $leaf = [string]$contractSpec.leafByRole.$role
    $expectedPath =
      "$expectedEvidenceRoot/captures/attempt-$Attempt/$Kind/$leaf"
    Assert-C34LEvidence (
      -not [string]::IsNullOrWhiteSpace($leaf) -and
      [string]$binding.path -ceq $expectedPath -and
      [string]$binding.mediaType -ceq 'application/json'
    ) "$Label capture artifact path, role or media type changed at $role."
    $file = Assert-C34LEvidenceFileBinding ([string]$binding.path) `
      ([string]$binding.sha256) ([int64]$binding.bytes) `
      "captures/attempt-$Attempt/$Kind/$leaf" `
      "$Label capture artifact $role"
    try { $value = Get-Content -Raw -LiteralPath $file | ConvertFrom-Json } catch {
      throw "C34L retained-evidence gate rejected: $Label capture artifact $role is not valid JSON."
    }
    $byRole[$role] = [pscustomobject]@{ Binding=$binding; Value=$value }
    if ($Kind -cne 'journey') {
      Assert-C34LCaptureArtifactPayload $Kind $role $value $Attestation $Artifact `
        "$Label capture artifact $role"
    }
  }
  if ($Kind -ceq 'play') {
    $receiptSha = [string]$byRole.internal_testing_release_receipt.Binding.sha256
    $statusSha = [string]$byRole.internal_testing_status_observation.Binding.sha256
    Assert-C34LEvidence (
      [string]$Capture.captureDigests.internalTestingRouteDigestSha256 -ceq $receiptSha -and
      [string]$Capture.captureDigests.uploadReceiptDigestSha256 -ceq $receiptSha -and
      [string]$Capture.captureDigests.activationStateDigestSha256 -ceq $statusSha
    ) "$Label Play digests are not bound to exact capture artifacts."
  } elseif ($Kind -ceq 'oppo') {
    $coldSha = [string]$byRole.cold_start_observation.Binding.sha256
    $retainedSha = [string]$byRole.retained_state_observation.Binding.sha256
    Assert-C34LEvidence (
      [string]$Capture.captureDigests.packageStateDigestSha256 -ceq $coldSha -and
      [string]$Capture.captureDigests.coldStartDigestSha256 -ceq $coldSha -and
      [string]$Capture.captureDigests.retainedDataDigestSha256 -ceq $retainedSha
    ) "$Label OPPO digests are not bound to exact capture artifacts."
  } else {
    $rows = @($byRole.journey_acceptance_manifest.Value)
    $journeyIds = @(
      'publicGuest','protectedGateway','supportedAuthentication','social',
      'wholeApp','c33gBlocker'
    )
    Assert-C34LEvidence (
      $rows.Count -eq $journeyIds.Count -and
      @($rows.journeyId | Select-Object -Unique).Count -eq $rows.Count -and
      (@($rows.journeyId) -join '|') -ceq ($journeyIds -join '|')
    ) "$Label journey acceptance-manifest row set changed."
    foreach ($row in $rows) {
      Assert-C34LExactNames $row "$Label journey row" `
        @('journeyId','path','sha256','bytes','passed')
      $journeyId = [string]$row.journeyId
      $expectedPath =
        "$expectedEvidenceRoot/captures/attempt-$Attempt/journey/journeys/$journeyId.json"
      Assert-C34LEvidence ([bool]$row.passed -and [string]$row.path -ceq $expectedPath) `
        "$Label journey row path or result changed at $journeyId."
      $rowFile = Assert-C34LEvidenceFileBinding ([string]$row.path) `
        ([string]$row.sha256) ([int64]$row.bytes) `
        "captures/attempt-$Attempt/journey/journeys/$journeyId.json" `
        "$Label journey capture artifact $journeyId"
      try { $value = Get-Content -Raw -LiteralPath $rowFile | ConvertFrom-Json } catch {
        throw "C34L retained-evidence gate rejected: $Label journey artifact $journeyId is not valid JSON."
      }
      Assert-C34LPrivacy $value "$Label journey artifact $journeyId"
      Assert-C34LExactNames $value "$Label journey artifact $journeyId" @(
        'schemaVersion','journeyId','ticketId','attempt','packageName',
        'versionName','versionCode','artifactSha256','artifactBytes',
        'deviceBindingSha256','passed','newIssueCount','newDefectCount',
        'blankScreenCount','flutterFatalErrorCount','androidRuntimeFatalCount',
        'anrCount','sourceProducerId','sessionId','nonceSha256'
      )
      Assert-C34LEvidence (
        [int]$value.schemaVersion -eq 1 -and [string]$value.journeyId -ceq $journeyId -and
        [string]$value.ticketId -ceq $ticketId -and [int]$value.attempt -eq $Attempt -and
        [string]$value.packageName -ceq $packageName -and
        [string]$value.versionName -ceq $versionName -and
        [string]$value.versionCode -ceq $versionCode -and
        [string]$value.artifactSha256 -ceq $Artifact.Sha -and
        [int64]$value.artifactBytes -eq $Artifact.Bytes -and
        [string]$value.deviceBindingSha256 -ceq $deviceBindingSha256 -and
        [bool]$value.passed -and [int]$value.newIssueCount -eq 0 -and
        [int]$value.newDefectCount -eq 0 -and [int]$value.blankScreenCount -eq 0 -and
        [int]$value.flutterFatalErrorCount -eq 0 -and
        [int]$value.androidRuntimeFatalCount -eq 0 -and [int]$value.anrCount -eq 0 -and
        [string]$value.sourceProducerId -ceq [string]$Attestation.sourceProducerId -and
        [string]$value.sessionId -ceq [string]$Attestation.sessionId -and
        [string]$value.nonceSha256 -ceq [string]$Attestation.nonceSha256 -and
        [string]$Capture.captureDigests.($journeyId + 'DigestSha256') -ceq
          [string]$row.sha256
      ) "$Label journey capture artifact changed at $journeyId."
    }
  }
}
function Assert-C34LSourceAttestation(
  $Evidence,
  [ValidateSet('play','oppo','journey')][string]$Kind,
  $Artifact,
  [string]$Label
) {
  $spec = Get-C34LSourceSpec $Kind
  Assert-C34LExactNames $Evidence.sourceAttestation `
    "$Label sourceAttestation" $sourceBindingNames
  $binding = $Evidence.sourceAttestation
  $expectedAttestation =
    "$expectedEvidenceRoot/attestations/source-attestation-$($spec.Short)-attempt-$Attempt.json"
  $attestationFile = Assert-C34LEvidenceFileBinding `
    ([string]$binding.path) ([string]$binding.sha256) ([int64]$binding.bytes) `
    "attestations/source-attestation-$($spec.Short)-attempt-$Attempt.json" `
    "$Label source attestation"
  $attestationRaw = Get-Content -Raw -LiteralPath $attestationFile
  try { $attestation = $attestationRaw | ConvertFrom-Json } catch {
    throw "C34L retained-evidence gate rejected: $Label source attestation is not valid JSON."
  }
  Assert-C34LExactNames $attestation "$Label source attestation" `
    $sourceAttestationNames
  Assert-C34LExactNames $attestation.captureDigests `
    "$Label source-attestation captureDigests" $spec.Digests
  Assert-C34LPrivacy $attestation "$Label source attestation"
  Assert-C34LVector $attestation $spec.Counts $spec.Authorities `
    "$Label source attestation"
  $producedUtc = ConvertTo-C34LUtcText $attestation.producedUtc `
    "$Label source attestation producedUtc"
  $expiresUtc = ConvertTo-C34LUtcText $attestation.expiresUtc `
    "$Label source attestation expiresUtc"
  Assert-C34LRawUtc $attestationRaw 'producedUtc' $producedUtc `
    "$Label source attestation"
  Assert-C34LRawUtc $attestationRaw 'expiresUtc' $expiresUtc `
    "$Label source attestation"
  $produced = [DateTimeOffset]::ParseExact(
    $producedUtc, "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal
  )
  $expires = [DateTimeOffset]::ParseExact(
    $expiresUtc, "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal
  )
  Assert-C34LEvidence (
    $expires -gt $produced -and $expires -le $produced.AddMinutes(15)
  ) "$Label source-attestation session window is invalid."
  Assert-C34LEvidence (
    [int]$attestation.schemaVersion -eq 1 -and
    [string]$attestation.attestationContractId -ceq
      'MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001' -and
    [string]$attestation.evidenceType -ceq $spec.EvidenceType -and
    [string]$attestation.ticketId -ceq $ticketId -and
    [int]$attestation.attempt -eq $Attempt -and
    [string]$attestation.packageName -ceq $packageName -and
    [string]$attestation.versionName -ceq $versionName -and
    [string]$attestation.versionCode -ceq $versionCode -and
    [string]$attestation.preStateSha256 -ceq [string]$Evidence.preStateSha256 -and
    [string]$attestation.preAggregateSha256 -ceq
      [string]$Evidence.preAggregateSha256 -and
    [string]$attestation.artifactSha256 -ceq $Artifact.Sha -and
    [int64]$attestation.artifactBytes -eq $Artifact.Bytes -and
    [string]$attestation.sourceProducerId -ceq $spec.Producer -and
    [string]$attestation.sessionId -cmatch '^[a-z0-9][a-z0-9_-]{15,95}$' -and
    [string]$attestation.nonceSha256 -cmatch '^[0-9A-F]{64}$'
  ) "$Label source-attestation identity, preimage, vector, artifact or session changed."
  foreach ($name in $spec.Digests) {
    Assert-C34LEvidence (
      [string]$attestation.captureDigests.$name -cmatch '^[0-9A-F]{64}$'
    ) "$Label source-attestation digest changed at $name."
  }
  foreach ($name in @(
    'evidenceType','sourceProducerId','sessionId','nonceSha256',
    'captureManifestPath','captureManifestSha256'
  )) {
    Assert-C34LEvidence ([string]$binding.$name -ceq [string]$attestation.$name) `
      "$Label sourceAttestation changed at $name."
  }
  foreach ($name in @('captureManifestBytes')) {
    Assert-C34LEvidence ([int64]$binding.$name -eq [int64]$attestation.$name) `
      "$Label sourceAttestation changed at $name."
  }
  Assert-C34LEvidence (
    (ConvertTo-C34LUtcText $binding.producedUtc "$Label binding producedUtc") -ceq
      $producedUtc -and
    (ConvertTo-C34LUtcText $binding.expiresUtc "$Label binding expiresUtc") -ceq
      $expiresUtc
  ) "$Label sourceAttestation UTC binding changed."
  Assert-C34LExactNames $binding.captureDigests `
    "$Label sourceAttestation captureDigests" $spec.Digests
  foreach ($name in $spec.Digests) {
    Assert-C34LEvidence (
      [string]$binding.captureDigests.$name -ceq
        [string]$attestation.captureDigests.$name
    ) "$Label sourceAttestation capture digest changed at $name."
  }
  $expectedCapture =
    "$expectedEvidenceRoot/captures/attempt-$Attempt/$($spec.Short)/capture-manifest.json"
  Assert-C34LEvidence (
    [string]$attestation.captureManifestPath -ceq $expectedCapture
  ) "$Label capture manifest is not the exact immutable candidate owner."
  $captureFile = Assert-C34LEvidenceFileBinding `
    ([string]$attestation.captureManifestPath) `
    ([string]$attestation.captureManifestSha256) `
    ([int64]$attestation.captureManifestBytes) `
    "captures/attempt-$Attempt/$($spec.Short)/capture-manifest.json" `
    "$Label capture manifest"
  $captureRaw = Get-Content -Raw -LiteralPath $captureFile
  try { $capture = $captureRaw | ConvertFrom-Json } catch {
    throw "C34L retained-evidence gate rejected: $Label capture manifest is not valid JSON."
  }
  Assert-C34LCaptureGraph $capture $captureRaw $Kind $attestation $Artifact $Label
  return $binding
}
function Assert-C34LFinalProofSchema(
  $Evidence,
  [int[]]$ExpectedCounts,
  [string[]]$ExpectedAuthorities,
  [string]$ExpectedTransition,
  [string]$ExpectedPhase,
  [string]$ExpectedEvidencePath,
  [string]$ExpectedEvidenceSha256,
  [string]$Label
) {
  Assert-C34LProperties $Evidence $Label @(
    'ticketId', 'attempt', 'preStateSha256', 'preAggregateSha256',
    'actionCounts', 'releaseAuthorities'
  )
  Assert-C34LEvidence (
    [string]$Evidence.ticketId -ceq $ticketId -and
    [int]$Evidence.attempt -eq $Attempt -and
    [string]$Evidence.preStateSha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$Evidence.preAggregateSha256 -cmatch '^[0-9A-F]{64}$' -and
    $ExpectedCounts.Count -eq 8 -and $ExpectedAuthorities.Count -eq 4
  ) "$Label ticket, attempt or preimage identity changed."
  Assert-C34LVector $Evidence $ExpectedCounts $ExpectedAuthorities $Label
  $stateHistory = @($state.lifecycleTransactionProofs)
  $aggregateHistory = @($aggregate.lifecycleTransactionProofs)
  Assert-C34LEvidence (
    $stateHistory.Count -gt 0 -and
    $stateHistory.Count -eq $aggregateHistory.Count -and
    ($stateHistory | ConvertTo-Json -Depth 60 -Compress) -ceq
      ($aggregateHistory | ConvertTo-Json -Depth 60 -Compress)
  ) "$Label detailed and aggregate lifecycle histories are not exactly equal."
  foreach ($proofRecord in $stateHistory) {
    Assert-C34LPrivacy $proofRecord "$Label transaction-proof record"
    Assert-C34LExactNames $proofRecord "$Label transaction-proof record" @(
      'ticketId','attempt','transition','phase','evidencePath','sha256',
      'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
      'browserEvidence'
    )
    Assert-C34LExactNames $proofRecord.actionCounts `
      "$Label transaction-proof actionCounts" $countNames
    Assert-C34LExactNames $proofRecord.releaseAuthorities `
      "$Label transaction-proof releaseAuthorities" $authorityNames
    Assert-C34LEvidence (
      [string]$proofRecord.ticketId -ceq $ticketId -and
      [int]$proofRecord.attempt -eq $Attempt -and
      [string]$proofRecord.preStateSha256 -cmatch '^[0-9A-F]{64}$' -and
      [string]$proofRecord.preAggregateSha256 -cmatch '^[0-9A-F]{64}$' -and
      [string]$proofRecord.evidencePath -cmatch '^[^\\?#]+$' -and
      [string]$proofRecord.sha256 -cmatch '^[0-9A-F]{64}$'
    ) "$Label transaction-proof identity or binding shape changed."
  }
  $matchingProofs = @($stateHistory | Where-Object {
    [string]$_.transition -ceq $ExpectedTransition -and
    [string]$_.phase -ceq $ExpectedPhase -and
    [string]$_.evidencePath -ceq $ExpectedEvidencePath -and
    [string]$_.sha256 -ceq $ExpectedEvidenceSha256 -and
    [string]$_.preStateSha256 -ceq [string]$Evidence.preStateSha256 -and
    [string]$_.preAggregateSha256 -ceq [string]$Evidence.preAggregateSha256
  })
  Assert-C34LEvidence ($matchingProofs.Count -eq 1) `
    "$Label is not bound once to its exact newest lifecycle proof."
  $newest = $matchingProofs[0]
  Assert-C34LEvidence (
    [string]$newest.ticketId -ceq [string]$Evidence.ticketId -and
    [int]$newest.attempt -eq [int]$Evidence.attempt -and
    [string]$newest.transition -ceq $ExpectedTransition -and
    [string]$newest.phase -ceq $ExpectedPhase -and
    [string]$newest.evidencePath -ceq $ExpectedEvidencePath -and
    [string]$newest.sha256 -ceq $ExpectedEvidenceSha256 -and
    [string]$newest.preStateSha256 -ceq [string]$Evidence.preStateSha256 -and
    [string]$newest.preAggregateSha256 -ceq
      [string]$Evidence.preAggregateSha256 -and
    $null -eq $newest.browserEvidence
  ) "$Label newest lifecycle proof transition, phase, evidence, browser or preimage binding changed."
  foreach ($name in $countNames) {
    Assert-C34LEvidence (
      [int]$newest.actionCounts.$name -eq [int]$Evidence.actionCounts.$name
    ) "$Label newest lifecycle proof count changed at $name."
  }
  foreach ($name in $authorityNames) {
    Assert-C34LEvidence (
      [string]$newest.releaseAuthorities.$name -ceq
        [string]$Evidence.releaseAuthorities.$name
    ) "$Label newest lifecycle proof authority changed at $name."
  }
}
function Assert-C34LArtifactIdentity {
  Assert-C34LProperties $state.buildResult 'build result' @(
    'artifactPath','artifactSha256','artifactBytes','uploadSignerSha256','provenance'
  )
  $artifactLeaf = "MoolSocial-$versionName-$versionCode-release.aab"
  $artifactFile = Assert-C34LExactPath `
    ([string]$state.buildResult.artifactPath) $artifactLeaf 'sealed C34L AAB'
  $sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactFile).Hash
  $bytes = (Get-Item -LiteralPath $artifactFile).Length
  Assert-C34LEvidence (
    [string]$state.buildResult.artifactSha256 -cmatch '^[0-9A-F]{64}$' -and
    $sha -ceq [string]$state.buildResult.artifactSha256 -and
    $bytes -gt 0 -and $bytes -eq [int64]$state.buildResult.artifactBytes -and
    [string]$state.buildResult.uploadSignerSha256 -cmatch '^[0-9A-F]{64}$'
  ) 'artifact hash, bytes or signer identity changed.'
  return [pscustomobject]@{ Path=$artifactFile; Relative=[string]$state.buildResult.artifactPath; Sha=$sha; Bytes=$bytes }
}
function Assert-C34LBuildEvidence {
  $artifact = Assert-C34LArtifactIdentity
  $provenanceLeaf = Get-C34LAttemptLeaf '06-release-aab-provenance' '.json'
  [void](Assert-C34LExactPath ([string]$state.buildResult.provenance) `
    $provenanceLeaf 'C34L AAB provenance')
  $provenance = Read-C34LJson ([string]$state.buildResult.provenance) 'C34L AAB provenance'
  Assert-C34LExactNames $provenance 'C34L AAB provenance' @(
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
  $configLeaf = Get-C34LAttemptLeaf '03-release-config-only' '.log'
  $manifestLeaf = Get-C34LAttemptLeaf '04-release-manifest-preflight' '.log'
  $mergedLeaf = Get-C34LAttemptLeaf '04a-merged-release-manifest' '.xml'
  $blameLeaf = Get-C34LAttemptLeaf '04b-release-manifest-merger-blame' '.txt'
  $buildLeaf = Get-C34LAttemptLeaf '05-release-aab-build' '.log'
  foreach ($binding in @(
    @('releaseConfigOnly',$configLeaf), @('releaseManifestPreflight',$manifestLeaf),
    @('mergedReleaseManifest',$mergedLeaf), @('releaseManifestMergerBlame',$blameLeaf),
    @('buildLog',$buildLeaf)
  )) { [void](Assert-C34LExactPath ([string]$provenance.($binding[0])) $binding[1] $binding[0]) }
  Assert-C34LProperties $state.sourceQualification 'source qualification' @('manifestPath','manifestSha256')
  Assert-C34LEvidence (
    [int]$provenance.schemaVersion -eq 1 -and
    [string]$provenance.candidateId -ceq $ticketId -and
    [int]$provenance.preflightAttempt -eq $Attempt -and
    [string]$provenance.versionName -ceq $versionName -and
    [string]$provenance.versionCode -ceq $versionCode -and
    [string]$provenance.packageName -ceq $packageName -and
    [string]$provenance.buildMode -ceq 'release' -and
    [string]$provenance.artifactType -ceq 'AAB' -and
    [string]$provenance.authorizedTrack -ceq 'internal' -and
    [string]$provenance.branch -ceq
      'remediation/prototype-conformance-2026-07-20' -and
    [string]$provenance.head -ceq
      'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
    [int]$provenance.powerShellMajor -ge 7 -and
    [string]$provenance.sourceManifest -ceq [string]$state.sourceQualification.manifestPath -and
    [string]$provenance.sourceManifestSha256 -ceq [string]$state.sourceQualification.manifestSha256 -and
    [string]$provenance.artifactPath -ceq $artifact.Relative -and
    [string]$provenance.artifactSha256 -ceq $artifact.Sha -and
    [int64]$provenance.artifactBytes -eq $artifact.Bytes -and
    [string]$provenance.uploadSignerSha256 -ceq [string]$state.buildResult.uploadSignerSha256 -and
    -not [bool]$provenance.releaseConfigOnlyProducedApkOrAab -and
    [int]$provenance.releaseRegistrantPluginCount -gt 0 -and
    [string]$provenance.googleServicesGradlePlugin -ceq '4.5.0' -and
    [string]$provenance.crashlyticsGradlePlugin -ceq '3.0.7' -and
    -not [bool]$provenance.crashlyticsMappingUploadEnabled -and
    [bool]$provenance.packageVersionManifestProved -and
    [bool]$provenance.googleAppIdResourceProved -and
    [bool]$provenance.crashlyticsBuildIdResourceProved -and
    [bool]$provenance.splitAndArm64PayloadProved -and
    [string]$provenance.bundletoolVersion -ceq '1.18.3' -and
    -not [bool]$provenance.secretDefineFileReadByAgent -and
    -not [bool]$provenance.googleServicesFileReadByAgent -and
    -not [bool]$provenance.secretValuesRecorded
  ) 'build provenance identity, source, artifact, payload or privacy proof failed.'
  $sourceManifest = Resolve-C34LRelativeFile `
    ([string]$state.sourceQualification.manifestPath) 'sealed source manifest'
  Assert-C34LEvidence (
    [string]$state.sourceQualification.manifestSha256 -cmatch '^[0-9A-F]{64}$' -and
    (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceManifest).Hash -ceq
      [string]$state.sourceQualification.manifestSha256
  ) 'sealed source-manifest bytes changed.'
  foreach ($row in @(Get-Content -LiteralPath $sourceManifest)) {
    $match = [regex]::Match($row, '^([0-9A-F]{64})  (.+)$')
    Assert-C34LEvidence $match.Success 'source-manifest row is malformed.'
    $owner = Resolve-C34LRelativeFile $match.Groups[2].Value 'sealed source owner'
    Assert-C34LEvidence (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq $match.Groups[1].Value
    ) "source changed after seal: $($match.Groups[2].Value)"
  }
  $buildLog = Resolve-C34LRelativeFile ([string]$provenance.buildLog) 'release build log'
  Assert-C34LEvidence (
    @(Select-String -LiteralPath $buildLog -Pattern 'Built build[\\/]app[\\/]outputs[\\/]bundle[\\/]release[\\/]app-release[.]aab').Count -eq 1 -and
    @(Select-String -LiteralPath $buildLog -Pattern 'BUILD FAILED|FAILURE:|Exception:').Count -eq 0
  ) 'build log does not prove one successful failure-free AAB build.'
  return $artifact
}
function Assert-C34LPlayEvidence {
  $artifact = Assert-C34LArtifactIdentity
  Assert-C34LProperties $state.playResult 'Play result' @(
    'evidencePath', 'evidenceSha256', 'evidenceBytes'
  )
  [void](Assert-C34LEvidenceFileBinding `
    ([string]$state.playResult.evidencePath) `
    ([string]$state.playResult.evidenceSha256) `
    ([int64]$state.playResult.evidenceBytes) `
    '07-play-internal-testing-activation-evidence.json' 'Internal Testing evidence')
  $play = Read-C34LJson ([string]$state.playResult.evidencePath) 'Internal Testing evidence'
  Assert-C34LExactNames $play 'Internal Testing evidence' @(
    'schemaVersion','evidenceContractId','evidenceType','ticketId','attempt',
    'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
    'packageName','versionName','versionCode','artifactSha256','artifactBytes',
    'track','internalReleaseActive','uploadCount','internalActivationCount',
    'otherTrackChanged','sourceAttestation'
  )
  Assert-C34LEvidence (
    [int]$play.schemaVersion -eq 1 -and
    [string]$play.evidenceContractId -ceq 'MOOLSOCIAL-C34L-PLAY-EVIDENCE-001' -and
    [string]$play.evidenceType -ceq 'play_internal_testing_activation' -and
    [string]$play.ticketId -ceq $ticketId -and [string]$play.packageName -ceq $packageName -and
    [string]$play.versionName -ceq $versionName -and [string]$play.versionCode -ceq $versionCode -and
    [string]$play.artifactSha256 -ceq $artifact.Sha -and [int64]$play.artifactBytes -eq $artifact.Bytes -and
    [string]$play.track -ceq 'internal' -and [bool]$play.internalReleaseActive -and
    [int]$play.uploadCount -eq 1 -and [int]$play.internalActivationCount -eq 1 -and
    -not [bool]$play.otherTrackChanged
  ) 'Internal Testing evidence does not bind the exact one-upload artifact.'
  Assert-C34LFinalProofSchema $play @(1,0,0,0,0,0,0,0) @(
    'consumed','available_once','held_postupload_qualification',
    'held_postinstall_journey_qualification'
  ) 'upload-succeeded' 'preupload' ([string]$state.playResult.evidencePath) `
    ([string]$state.playResult.evidenceSha256) 'Internal Testing evidence'
  [void](Assert-C34LSourceAttestation $play play $artifact `
    'Internal Testing evidence')
}
function Assert-C34LOppoEvidence {
  $artifact = Assert-C34LArtifactIdentity
  Assert-C34LProperties $state.installResult 'install result' @(
    'coldStartEvidencePath','coldStartEvidenceSha256','coldStartEvidenceBytes',
    'retainedDataEvidencePath','retainedDataEvidenceSha256',
    'retainedDataEvidenceBytes'
  )
  [void](Assert-C34LEvidenceFileBinding `
    ([string]$state.installResult.coldStartEvidencePath) `
    ([string]$state.installResult.coldStartEvidenceSha256) `
    ([int64]$state.installResult.coldStartEvidenceBytes) `
    '08-oppo-play-in-place-update-cold-start-evidence.json' `
    'OPPO cold-start evidence')
  [void](Assert-C34LEvidenceFileBinding `
    ([string]$state.installResult.retainedDataEvidencePath) `
    ([string]$state.installResult.retainedDataEvidenceSha256) `
    ([int64]$state.installResult.retainedDataEvidenceBytes) `
    '09-oppo-in-place-retained-data-evidence.json' `
    'OPPO retained-data evidence')
  $cold = Read-C34LJson ([string]$state.installResult.coldStartEvidencePath) 'OPPO cold-start evidence'
  $retained = Read-C34LJson ([string]$state.installResult.retainedDataEvidencePath) 'OPPO retained-data evidence'
  $identityNames = @(
    'schemaVersion','evidenceContractId','evidencePairId','ticketId','attempt',
    'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
    'packageName','versionName','versionCode','artifactSha256','artifactBytes',
    'deviceBindingSha256','deviceModel','installerPackage','sourceAttestation','evidenceType'
  )
  Assert-C34LExactNames $cold 'OPPO cold-start evidence' ($identityNames + @(
    'coldStartInteractive','blankHierarchy','timeout','flutterFatalErrorCount',
    'androidRuntimeFatalCount','anrCount','appProcessErrorScanPassed',
    'artifactRelationshipProved','inPlaceUpdateProved'
  ))
  Assert-C34LExactNames $retained 'OPPO retained-data evidence' ($identityNames + @(
    'firstInstallTimeMillis','lastUpdateTimeMillis','firstInstallTimePreserved',
    'retainedDataContinuityProved','inPlacePlayUpdateProved','uninstallPerformed',
    'dataClearPerformed','downgradePerformed','adbInstallPerformed'
  ))
  foreach ($item in @($cold,$retained)) {
    Assert-C34LEvidence (
      [int]$item.schemaVersion -eq 1 -and
      [string]$item.evidenceContractId -ceq 'MOOLSOCIAL-C34L-OPPO-EVIDENCE-001' -and
      [string]$item.evidencePairId -ceq [string]$cold.evidencePairId -and
      [string]$item.ticketId -ceq $ticketId -and [string]$item.packageName -ceq $packageName -and
      [string]$item.versionName -ceq $versionName -and [string]$item.versionCode -ceq $versionCode -and
      [string]$item.artifactSha256 -ceq $artifact.Sha -and [int64]$item.artifactBytes -eq $artifact.Bytes -and
      [string]$item.deviceBindingSha256 -ceq $deviceBindingSha256 -and
      [string]$item.deviceModel -ceq $deviceModel -and
      [string]$item.installerPackage -ceq 'com.android.vending'
    ) 'OPPO evidence identity does not bind the exact Play-installed artifact.'
  }
  Assert-C34LEvidence (
    [string]$cold.evidenceType -ceq 'oppo_play_in_place_update_cold_start' -and
    [bool]$cold.coldStartInteractive -and -not [bool]$cold.blankHierarchy -and -not [bool]$cold.timeout -and
    [int]$cold.flutterFatalErrorCount -eq 0 -and [int]$cold.androidRuntimeFatalCount -eq 0 -and
    [int]$cold.anrCount -eq 0 -and [bool]$cold.appProcessErrorScanPassed -and
    [bool]$cold.artifactRelationshipProved -and [bool]$cold.inPlaceUpdateProved
  ) 'OPPO cold start, fatal/ANR, artifact or in-place-update proof failed.'
  Assert-C34LEvidence (
    [string]$retained.evidenceType -ceq 'oppo_in_place_retained_data' -and
    [int64]$retained.firstInstallTimeMillis -lt [int64]$retained.lastUpdateTimeMillis -and
    [bool]$retained.firstInstallTimePreserved -and [bool]$retained.retainedDataContinuityProved -and
    [bool]$retained.inPlacePlayUpdateProved -and -not [bool]$retained.uninstallPerformed -and
    -not [bool]$retained.dataClearPerformed -and -not [bool]$retained.downgradePerformed -and
    -not [bool]$retained.adbInstallPerformed
  ) 'OPPO retained-data or Play-only in-place update proof failed.'
  foreach ($item in @($cold,$retained)) {
    Assert-C34LFinalProofSchema $item @(1,1,0,0,0,0,0,0) @(
      'consumed','consumed','available_once',
      'held_postinstall_journey_qualification'
    ) 'install-succeeded' 'preinstall' `
      ([string]$state.installResult.coldStartEvidencePath) `
      ([string]$state.installResult.coldStartEvidenceSha256) `
      'OPPO install evidence'
  }
  $coldSource = Assert-C34LSourceAttestation $cold oppo $artifact `
    'OPPO cold-start evidence'
  $retainedSource = Assert-C34LSourceAttestation $retained oppo $artifact `
    'OPPO retained-data evidence'
  Assert-C34LEvidence (
    ($coldSource | ConvertTo-Json -Depth 20 -Compress) -ceq
      ($retainedSource | ConvertTo-Json -Depth 20 -Compress)
  ) 'OPPO cold and retained evidence source-attestation bindings differ.'
  Assert-C34LEvidence (
    [string]$cold.evidencePairId -ceq "oppo-$Attempt-$($cold.preStateSha256)"
  ) 'OPPO evidence-pair identity changed.'
  $journalRelative =
    "$expectedEvidenceRoot/transactions/oppo-evidence-pair-attempt-$Attempt.json"
  $journalFile = Resolve-C34LRelativeFile $journalRelative `
    'OPPO evidence transaction journal'
  $journalRaw = Get-Content -Raw -LiteralPath $journalFile
  try { $journal = $journalRaw | ConvertFrom-Json } catch {
    throw 'C34L retained-evidence gate rejected: OPPO evidence transaction journal is not valid JSON.'
  }
  Assert-C34LPrivacy $journal 'OPPO evidence transaction journal'
  Assert-C34LExactNames $journal 'OPPO evidence transaction journal' @(
    'schemaVersion','transactionContractId','transactionId','ticketId','attempt',
    'status','preStateSha256','preAggregateSha256','artifactSha256',
    'artifactBytes','deviceBindingSha256','coldStart','retainedData',
    'sourceAttestation','preparedUtc',
    'committedUtc'
  )
  Assert-C34LExactNames $journal.coldStart 'OPPO journal coldStart' `
    @('path','sha256','bytes')
  Assert-C34LExactNames $journal.retainedData 'OPPO journal retainedData' `
    @('path','sha256','bytes')
  Assert-C34LExactNames $journal.sourceAttestation `
    'OPPO journal sourceAttestation' $sourceBindingNames
  Assert-C34LEvidence (
    [int]$journal.schemaVersion -eq 1 -and
    [string]$journal.transactionContractId -ceq
      'MOOLSOCIAL-C34L-OPPO-EVIDENCE-TRANSACTION-001' -and
    [string]$journal.transactionId -ceq
      "oppo-evidence-$Attempt-$($cold.preStateSha256)-$($cold.preAggregateSha256)" -and
    [string]$journal.ticketId -ceq $ticketId -and
    [int]$journal.attempt -eq $Attempt -and
    [string]$journal.status -ceq 'committed' -and
    [string]$journal.preStateSha256 -ceq [string]$cold.preStateSha256 -and
    [string]$journal.preAggregateSha256 -ceq
      [string]$cold.preAggregateSha256 -and
    [string]$journal.artifactSha256 -ceq $artifact.Sha -and
    [int64]$journal.artifactBytes -eq $artifact.Bytes -and
    [string]$journal.deviceBindingSha256 -ceq $deviceBindingSha256
  ) 'OPPO evidence transaction identity, status, preimage or artifact changed.'
  foreach ($tuple in @(
    @($journal.coldStart,$state.installResult.coldStartEvidencePath,
      $state.installResult.coldStartEvidenceSha256,
      $state.installResult.coldStartEvidenceBytes,'coldStart'),
    @($journal.retainedData,$state.installResult.retainedDataEvidencePath,
      $state.installResult.retainedDataEvidenceSha256,
      $state.installResult.retainedDataEvidenceBytes,'retainedData')
  )) {
    Assert-C34LEvidence (
      [string]$tuple[0].path -ceq [string]$tuple[1] -and
      [string]$tuple[0].sha256 -ceq [string]$tuple[2] -and
      [int64]$tuple[0].bytes -eq [int64]$tuple[3]
    ) "OPPO journal $($tuple[4]) payload binding changed."
  }
  Assert-C34LEvidence (
    ($journal.sourceAttestation | ConvertTo-Json -Depth 20 -Compress) -ceq
      ($coldSource | ConvertTo-Json -Depth 20 -Compress)
  ) 'OPPO journal source-attestation binding changed.'
  $preparedUtc = ConvertTo-C34LUtcText $journal.preparedUtc `
    'OPPO journal preparedUtc'
  $committedUtc = ConvertTo-C34LUtcText $journal.committedUtc `
    'OPPO journal committedUtc'
  Assert-C34LRawUtc $journalRaw 'preparedUtc' $preparedUtc 'OPPO journal'
  Assert-C34LRawUtc $journalRaw 'committedUtc' $committedUtc 'OPPO journal'
  $sourceProducedUtc = ConvertTo-C34LUtcText $coldSource.producedUtc `
    'OPPO source producedUtc'
  $sourceExpiresUtc = ConvertTo-C34LUtcText $coldSource.expiresUtc `
    'OPPO source expiresUtc'
  Assert-C34LEvidence (
    [string]::CompareOrdinal($preparedUtc,$sourceProducedUtc) -ge 0 -and
    [string]::CompareOrdinal($preparedUtc,$sourceExpiresUtc) -le 0 -and
    [string]::CompareOrdinal($committedUtc,$preparedUtc) -ge 0
  ) 'OPPO journal UTC order escaped the attested session.'
}
function Assert-C34LJourneyEvidence {
  $artifact = Assert-C34LArtifactIdentity
  Assert-C34LProperties $state.installResult 'install result' @(
    'journeyEvidencePath','journeyEvidenceSha256','journeyEvidenceBytes'
  )
  [void](Assert-C34LEvidenceFileBinding `
    ([string]$state.installResult.journeyEvidencePath) `
    ([string]$state.installResult.journeyEvidenceSha256) `
    ([int64]$state.installResult.journeyEvidenceBytes) `
    '10-mandatory-whole-app-journey-evidence.json' 'mandatory journey evidence')
  $journey = Read-C34LJson ([string]$state.installResult.journeyEvidencePath) 'mandatory journey evidence'
  Assert-C34LExactNames $journey 'mandatory journey evidence' @(
    'schemaVersion','evidenceContractId','evidenceType','ticketId','attempt',
    'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
    'packageName','versionName','versionCode','artifactSha256','artifactBytes',
    'track','deviceBindingSha256','deviceModel','installerPackage','publicGuestJourneyPassed',
    'protectedGatewayJourneyPassed','supportedAuthenticationJourneysPassed','socialJourneysPassed',
    'wholeAppJourneysPassed','c33gBlockerJourneysPassed','allMandatoryJourneysPassed',
    'evidenceComplete','newIssueCount','newDefectCount','blankScreenCount',
    'flutterFatalErrorCount','androidRuntimeFatalCount','anrCount','acceptanceSucceeded',
    'successClaimed','sourceAttestation'
  )
  Assert-C34LEvidence (
    [int]$journey.schemaVersion -eq 1 -and
    [string]$journey.evidenceContractId -ceq 'MOOLSOCIAL-C34L-JOURNEY-EVIDENCE-001' -and
    [string]$journey.evidenceType -ceq 'mandatory_whole_app_journey_acceptance' -and
    [string]$journey.ticketId -ceq $ticketId -and [string]$journey.packageName -ceq $packageName -and
    [string]$journey.versionName -ceq $versionName -and [string]$journey.versionCode -ceq $versionCode -and
    [string]$journey.artifactSha256 -ceq $artifact.Sha -and [int64]$journey.artifactBytes -eq $artifact.Bytes -and
    [string]$journey.track -ceq 'internal' -and
    [string]$journey.deviceBindingSha256 -ceq $deviceBindingSha256 -and
    [string]$journey.deviceModel -ceq $deviceModel -and [string]$journey.installerPackage -ceq 'com.android.vending' -and
    [bool]$journey.publicGuestJourneyPassed -and [bool]$journey.protectedGatewayJourneyPassed -and
    [bool]$journey.supportedAuthenticationJourneysPassed -and [bool]$journey.socialJourneysPassed -and
    [bool]$journey.wholeAppJourneysPassed -and [bool]$journey.c33gBlockerJourneysPassed -and
    [bool]$journey.allMandatoryJourneysPassed -and [bool]$journey.evidenceComplete -and
    [int]$journey.newIssueCount -eq 0 -and [int]$journey.newDefectCount -eq 0 -and
    [int]$journey.blankScreenCount -eq 0 -and [int]$journey.flutterFatalErrorCount -eq 0 -and
    [int]$journey.androidRuntimeFatalCount -eq 0 -and [int]$journey.anrCount -eq 0 -and
    [bool]$journey.acceptanceSucceeded -and [bool]$journey.successClaimed
  ) 'mandatory journey evidence is incomplete, unrelated or reports a defect.'
  Assert-C34LFinalProofSchema $journey @(1,1,1,0,0,0,0,0) @(
    'consumed','consumed','consumed',
    'held_postinstall_journey_qualification'
  ) 'device-accepted' 'journey' `
    ([string]$state.installResult.journeyEvidencePath) `
    ([string]$state.installResult.journeyEvidenceSha256) `
    'mandatory journey evidence'
  [void](Assert-C34LSourceAttestation $journey journey $artifact `
    'mandatory journey evidence')
}

if ($Phase -in @('build','play','oppo','journey','all')) { [void](Assert-C34LBuildEvidence) }
if ($Phase -in @('play','oppo','journey','all')) { Assert-C34LPlayEvidence }
if ($Phase -in @('oppo','journey','all')) { Assert-C34LOppoEvidence }
if ($Phase -in @('journey','all')) { Assert-C34LJourneyEvidence }
Write-Output "C34L retained-evidence gate passed: phase=$Phase; attempt=$Attempt; candidate=$ticketId; unrelatedFilesAccepted=false."
