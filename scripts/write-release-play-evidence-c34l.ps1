[CmdletBinding(DefaultParameterSetName='ProductionReceipt')]
param(
  [ValidateRange(1, 5)]
  [int]$Attempt = 1,
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34l.json',
  [Parameter(ParameterSetName='FixtureLegacy')]
  [switch]$InternalReleaseActive,
  [ValidateRange(0, 1)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$UploadCount = 0,
  [ValidateRange(0, 1)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$InternalActivationCount = 0,
  [Parameter(ParameterSetName='FixtureLegacy')]
  [switch]$OtherTrackChanged,
  [Parameter(Mandatory,ParameterSetName='FixtureLegacy')]
  [string]$SourceAttestationPath,
  [Parameter(Mandatory,ParameterSetName='FixtureLegacy')]
  [string]$SourceAttestationSha256,
  [Parameter(Mandatory,ParameterSetName='FixtureLegacy')]
  [long]$SourceAttestationBytes,
  [Parameter(Mandatory,ParameterSetName='ProductionReceipt')]
  [Parameter(Mandatory,ParameterSetName='FixtureReceipt')]
  [string]$AuthoritativeReceiptPath,
  [Parameter(Mandatory,ParameterSetName='ProductionReceipt')]
  [Parameter(Mandatory,ParameterSetName='FixtureReceipt')]
  [string]$AuthoritativeReceiptSha256,
  [Parameter(Mandatory,ParameterSetName='ProductionReceipt')]
  [Parameter(Mandatory,ParameterSetName='FixtureReceipt')]
  [long]$AuthoritativeReceiptBytes,
  [Parameter(Mandatory,ParameterSetName='FixtureLegacy')]
  [Parameter(Mandatory,ParameterSetName='FixtureReceipt')]
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
$productionEvidenceRoot =
  'artifacts/quality/uaw-c34l-r60-76-consolidated-release-transaction-evidence-preparation-20260817-01'
$captureArtifactContractPath =
  'config/release-evidence-capture-artifact-contract-c34l.json'
$captureArtifactContractSha256 =
  'D7B8DE822D709F25CEB1AEFFFF4093260B3EFB83DCADE1F632309026ECC0B9D2'
$captureArtifactContractId = 'MOOLSOCIAL-C34L-CAPTURE-ARTIFACT-CONTRACT-003'
$authoritativeProducerId =
  'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-PRODUCER-001'
$countNames = @(
  'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
  'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
)
$authorityNames = @(
  'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)
$utf8 = [Text.UTF8Encoding]::new($false)

function Assert-C34LPlayWriter([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34L Play evidence writer rejected: $Message"
  }
}
function Resolve-C34LPlayRelative([string]$Path, [string]$Label, [switch]$AllowMissing) {
  Assert-C34LPlayWriter (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LPlayWriter (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) "$Label escaped the production repository."
  $current = if (Test-Path -LiteralPath $resolved) {
    $resolved
  } else {
    Split-Path -Parent $resolved
  }
  while ($true) {
    Assert-C34LPlayWriter (
      $current.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
      $current.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) "$Label ancestor escaped the production repository."
    Assert-C34LPlayWriter (Test-Path -LiteralPath $current) `
      "$Label ancestor is missing."
    Assert-C34LPlayWriter (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $current = Split-Path -Parent $current
  }
  if (-not $AllowMissing) {
    Assert-C34LPlayWriter (Test-Path -LiteralPath $resolved -PathType Leaf) `
      "$Label is missing."
    Assert-C34LPlayWriter (
      -not ((Get-Item -LiteralPath $resolved -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label must not be a reparse point."
  }
  return $resolved
}
function Get-C34LPlayRelative([string]$Resolved) {
  $full = [IO.Path]::GetFullPath($Resolved)
  Assert-C34LPlayWriter (
    $full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) 'resolved path escaped the production repository.'
  return $full.Substring($rootPrefix.Length).Replace('\', '/')
}
function Assert-C34LPlayDirectory([string]$Path, [string]$Label) {
  Assert-C34LPlayWriter (Test-Path -LiteralPath $Path -PathType Container) `
    "$Label is missing."
  $current = [IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\', '/'))
  while ($current.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
    Assert-C34LPlayWriter (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $parent = Split-Path -Parent $current
    Assert-C34LPlayWriter (-not [string]::IsNullOrWhiteSpace($parent)) `
      "$Label parent chain is incomplete."
    $current = $parent.TrimEnd([char[]]@('\', '/'))
  }
}
function Assert-C34LPlayProperties($Value, [string]$Label, [string[]]$Names) {
  foreach ($name in $Names) {
    Assert-C34LPlayWriter ($null -ne $Value.PSObject.Properties[$name]) `
      "$Label is missing property $name."
  }
}
function Assert-C34LPlayExactNames($Value, [string]$Label, [string[]]$Names) {
  $actual = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LPlayWriter ($actual.Count -eq $Names.Count) `
    "$Label property count changed."
  foreach ($name in $Names) {
    Assert-C34LPlayWriter ($actual -ccontains $name) `
      "$Label is missing or has an unknown property at $name."
  }
}
function Assert-C34LPlayPrivacy(
  $Value,
  [string]$Label,
  [string]$PropertyPath = '$'
) {
  if ($null -eq $Value) { return }
  $forbiddenName =
    '(?i)(email|phone|private|url|link|identifier|exception|stack|credential|secret|token|key|rawnonce|account|^(deviceSerial|serial|androidId|imei|imsi|advertisingId)$)'
  $forbiddenValue =
    '(?i)([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|https?://|www\.|(?:Bearer|Basic)\s+|AIza[0-9A-Za-z_-]{35}|-----BEGIN|Exception(?:\s*:|\r|\n)|StackTrace|Traceback\s*\(|(?<![A-Za-z0-9])2b3e0f71(?![A-Za-z0-9])|[?&][A-Za-z0-9_.%+-]+=|#[A-Za-z0-9_.%+-]+)'
  if ($Value -is [string]) {
    Assert-C34LPlayWriter (-not [regex]::IsMatch([string]$Value,$forbiddenValue)) `
      "$Label contains a forbidden private value at $PropertyPath."
    return
  }
  if ($Value -is [Collections.IEnumerable] -and
      $Value -isnot [Management.Automation.PSCustomObject] -and
      $Value -isnot [Collections.IDictionary]) {
    $index=0
    foreach($item in $Value){
      Assert-C34LPlayPrivacy $item $Label "$PropertyPath[$index]"
      $index++
    }
    return
  }
  if ($Value -isnot [Management.Automation.PSCustomObject] -and
      $Value -isnot [Collections.IDictionary]) {
    Assert-C34LPlayWriter (
      -not [regex]::IsMatch([string]$Value,$forbiddenValue)
    ) "$Label contains a forbidden private scalar at $PropertyPath."
    return
  }
  foreach($property in @($Value.PSObject.Properties)){
    $schemaNameAllowed=
      ($PropertyPath -ceq '$.actionCounts' -and
        $countNames -ccontains $property.Name) -or
      ($PropertyPath -ceq '$.releaseAuthorities' -and
        $authorityNames -ccontains $property.Name)
    Assert-C34LPlayWriter (
      $schemaNameAllowed -or -not [regex]::IsMatch($property.Name,$forbiddenName)
    ) `
      "$Label contains forbidden private property $($property.Name)."
    Assert-C34LPlayPrivacy $property.Value $Label `
      "$PropertyPath.$($property.Name)"
  }
}
function ConvertTo-C34LPlayUtc($Value, [string]$Label) {
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
      [Globalization.DateTimeStyles]::AssumeUniversal,
      [ref]$parsed
    )
  }
  Assert-C34LPlayWriter (
    $ok -and $parsed.ToUniversalTime().Offset -eq [TimeSpan]::Zero
  ) "$Label must be canonical UTC with milliseconds."
  return $parsed.ToUniversalTime()
}
function Assert-C34LPlayRawUtc(
  [string]$Raw,
  [string]$Name,
  [DateTimeOffset]$Instant
) {
  $matches = [regex]::Matches(
    $Raw,
    '"' + [regex]::Escape($Name) + '"\s*:\s*"([^"]+)"'
  )
  $canonical = $Instant.ToUniversalTime().ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture
  )
  Assert-C34LPlayWriter (
    $matches.Count -eq 1 -and $matches[0].Groups[1].Value -ceq $canonical
  ) "$Name raw JSON token is not one exact canonical UTC string."
}
function Get-C34LPlaySha([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}
function Assert-C34LPlayVector($State, $Aggregate) {
  $expectedCounts = @(1, 0, 0, 0, 0, 0, 0, 0)
  $expectedAuthorities = @(
    'consumed', 'available_once', 'held_postupload_qualification',
    'held_postinstall_journey_qualification'
  )
  for ($index = 0; $index -lt $countNames.Count; $index++) {
    $name = $countNames[$index]
    Assert-C34LPlayWriter (
      $null -ne $State.actionCounts.PSObject.Properties[$name] -and
      $null -ne $Aggregate.actionCounts.PSObject.Properties[$name] -and
      [int]$State.actionCounts.$name -eq $expectedCounts[$index] -and
      [int]$Aggregate.actionCounts.$name -eq $expectedCounts[$index]
    ) "Play preimage action count changed at $name."
  }
  for ($index = 0; $index -lt $authorityNames.Count; $index++) {
    $name = $authorityNames[$index]
    Assert-C34LPlayWriter (
      $null -ne $State.releaseAuthorities.PSObject.Properties[$name] -and
      $null -ne $Aggregate.releaseAuthorities.PSObject.Properties[$name] -and
      [string]$State.releaseAuthorities.$name -ceq $expectedAuthorities[$index] -and
      [string]$Aggregate.releaseAuthorities.$name -ceq $expectedAuthorities[$index]
    ) "Play preimage release authority changed at $name."
  }
}
function Write-C34LPlayImmutableJson([string]$Target, [string]$Text) {
  Assert-C34LPlayWriter (-not (Test-Path -LiteralPath $Target)) `
    'the immutable Play evidence owner already exists.'
  $parent = Split-Path -Parent $Target
  Assert-C34LPlayDirectory $parent 'Play evidence directory'
  $temporary = $Target + '.tmp-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
  Assert-C34LPlayWriter (-not (Test-Path -LiteralPath $temporary)) `
    'Play evidence temporary path was not unique.'
  try {
    [IO.File]::WriteAllText($temporary, $Text, $utf8)
    Assert-C34LPlayWriter (
      (Test-Path -LiteralPath $temporary -PathType Leaf) -and
      (Get-Item -LiteralPath $temporary).Length -gt 0
    ) 'Play evidence temporary write was incomplete.'
    [IO.File]::Move($temporary, $Target)
  } finally {
    if (Test-Path -LiteralPath $temporary -PathType Leaf) {
      Remove-Item -LiteralPath $temporary -Force
    }
  }
  Assert-C34LPlayWriter (Test-Path -LiteralPath $Target -PathType Leaf) `
    'Play evidence immutable move was incomplete.'
}
function Read-C34LPlayCaptureArtifacts(
  [string]$CaptureFile,
  [string]$ExpectedEvidenceRoot,
  $Attestation,
  $State
) {
  $contractFile = Resolve-C34LPlayRelative $captureArtifactContractPath `
    'capture-artifact contract'
  Assert-C34LPlayWriter (
    (Get-C34LPlaySha $contractFile) -ceq $captureArtifactContractSha256
  ) 'capture-artifact contract SHA-256 changed.'
  $contract = Get-Content -Raw -LiteralPath $contractFile | ConvertFrom-Json
  Assert-C34LPlayExactNames $contract 'capture-artifact contract' @(
    'schemaVersion','contractId','ticketId','productionProducer',
    'authoritativeReceipt','captureAttemptRootPattern',
    'captureManifestPathPattern','captureArtifactPathPattern',
    'captureArtifactFields','mediaType','evidenceTypes','deviceBinding','privacy'
  )
  Assert-C34LPlayWriter (
    [int]$contract.schemaVersion -eq 3 -and
    [string]$contract.contractId -ceq $captureArtifactContractId -and
    [string]$contract.mediaType -ceq 'application/json'
  ) 'capture-artifact contract identity changed.'
  $capture = Get-Content -Raw -LiteralPath $CaptureFile | ConvertFrom-Json
  Assert-C34LPlayExactNames $capture 'Play capture manifest' @(
    'schemaVersion','captureContractId','evidenceType','ticketId','attempt',
    'packageName','versionName','versionCode','preStateSha256',
    'preAggregateSha256','actionCounts','releaseAuthorities','artifactSha256',
    'artifactBytes','sourceProducerId','sessionId','nonceSha256','producedUtc',
    'expiresUtc','captureDigests','captureArtifactContractPath',
    'captureArtifactContractSha256','captureArtifactContractId','captureArtifacts'
  )
  Assert-C34LPlayPrivacy $capture 'Play capture manifest'
  Assert-C34LPlayWriter (
    [string]$capture.captureArtifactContractPath -ceq
      $captureArtifactContractPath -and
    [string]$capture.captureArtifactContractSha256 -ceq
      $captureArtifactContractSha256 -and
    [string]$capture.captureArtifactContractId -ceq $captureArtifactContractId -and
    [string]$capture.evidenceType -ceq [string]$Attestation.evidenceType -and
    [string]$capture.ticketId -ceq [string]$Attestation.ticketId -and
    [int]$capture.attempt -eq [int]$Attestation.attempt -and
    [string]$capture.preStateSha256 -ceq [string]$Attestation.preStateSha256 -and
    [string]$capture.preAggregateSha256 -ceq
      [string]$Attestation.preAggregateSha256 -and
    [string]$capture.sourceProducerId -ceq
      [string]$Attestation.sourceProducerId -and
    [string]$capture.sessionId -ceq [string]$Attestation.sessionId -and
    [string]$capture.nonceSha256 -ceq [string]$Attestation.nonceSha256
  ) 'Play capture-manifest contract, preimage or session changed.'
  $roles = @(
    'internal_testing_release_receipt','internal_testing_status_observation'
  )
  $artifacts = @($capture.captureArtifacts)
  Assert-C34LPlayWriter (
    $artifacts.Count -eq 2 -and
    @($artifacts.role | Select-Object -Unique).Count -eq 2 -and
    (@($artifacts.role | Sort-Object) -join ',') -ceq
      (@($roles | Sort-Object) -join ',')
  ) 'Play capture-artifact role set changed.'
  $values = @{}
  $contractSpec=$contract.evidenceTypes.play_internal_testing_activation
  foreach($artifact in $artifacts){
    Assert-C34LPlayExactNames $artifact 'Play capture artifact' @(
      'role','path','sha256','bytes','mediaType'
    )
    $role=[string]$artifact.role
    $leaf=[string]$contractSpec.leafByRole.$role
    $expectedPath=
      "$ExpectedEvidenceRoot/captures/attempt-$Attempt/play/$leaf"
    Assert-C34LPlayWriter (
      -not [string]::IsNullOrWhiteSpace($leaf) -and
      [string]$artifact.path -ceq $expectedPath -and
      [string]$artifact.mediaType -ceq 'application/json' -and
      [string]$artifact.sha256 -cmatch '^[0-9A-F]{64}$' -and
      [int64]$artifact.bytes -gt 0
    ) "Play capture artifact path, identity or media type changed at $role."
    $file=Resolve-C34LPlayRelative ([string]$artifact.path) `
      "Play capture artifact $role"
    Assert-C34LPlayWriter (
      (Get-C34LPlaySha $file) -ceq [string]$artifact.sha256 -and
      (Get-Item -LiteralPath $file).Length -eq [int64]$artifact.bytes
    ) "Play capture artifact SHA-256 or bytes changed at $role."
    try { $value=Get-Content -Raw -LiteralPath $file | ConvertFrom-Json } catch {
      throw "C34L Play evidence writer rejected: capture artifact $role is not valid JSON."
    }
    Assert-C34LPlayPrivacy $value "Play capture artifact $role"
    $values[$role]=[pscustomobject]@{Binding=$artifact;Value=$value;File=$file}
  }
  $receipt=$values.internal_testing_release_receipt.Value
  $status=$values.internal_testing_status_observation.Value
  Assert-C34LPlayExactNames $receipt 'Play release-receipt capture' @(
    'schemaVersion','captureRole','ticketId','attempt','packageName',
    'versionName','versionCode','artifactSha256','artifactBytes','track',
    'uploadCount','otherTrackChanged','sourceProducerId','sessionId','nonceSha256'
  )
  Assert-C34LPlayExactNames $status 'Play status-observation capture' @(
    'schemaVersion','captureRole','ticketId','attempt','packageName',
    'versionName','versionCode','artifactSha256','artifactBytes','track',
    'internalReleaseActive','internalActivationCount','sourceProducerId',
    'sessionId','nonceSha256'
  )
  foreach($value in @($receipt,$status)){
    Assert-C34LPlayWriter (
      [int]$value.schemaVersion -eq 1 -and [string]$value.ticketId -ceq $ticketId -and
      [int]$value.attempt -eq $Attempt -and [string]$value.packageName -ceq $packageName -and
      [string]$value.versionName -ceq $versionName -and
      [string]$value.versionCode -ceq $versionCode -and
      [string]$value.artifactSha256 -ceq [string]$State.buildResult.artifactSha256 -and
      [int64]$value.artifactBytes -eq [int64]$State.buildResult.artifactBytes -and
      [string]$value.sourceProducerId -ceq [string]$Attestation.sourceProducerId -and
      [string]$value.sessionId -ceq [string]$Attestation.sessionId -and
      [string]$value.nonceSha256 -ceq [string]$Attestation.nonceSha256 -and
      [string]$value.track -ceq 'internal'
    ) 'Play capture payload identity, artifact or session changed.'
  }
  Assert-C34LPlayWriter (
    [string]$receipt.captureRole -ceq 'internal_testing_release_receipt' -and
    [int]$receipt.uploadCount -eq 1 -and -not [bool]$receipt.otherTrackChanged -and
    [string]$status.captureRole -ceq 'internal_testing_status_observation' -and
    [bool]$status.internalReleaseActive -and
    [int]$status.internalActivationCount -eq 1
  ) 'Play authoritative capture payload does not prove exact activation success.'
  $receiptSha=[string]$values.internal_testing_release_receipt.Binding.sha256
  $statusSha=[string]$values.internal_testing_status_observation.Binding.sha256
  Assert-C34LPlayWriter (
    [string]$capture.captureDigests.internalTestingRouteDigestSha256 -ceq $receiptSha -and
    [string]$capture.captureDigests.uploadReceiptDigestSha256 -ceq $receiptSha -and
    [string]$capture.captureDigests.activationStateDigestSha256 -ceq $statusSha
  ) 'Play capture digests are not bound to exact artifacts.'
  return [pscustomobject]@{
    Receipt=$receipt; Status=$status
    ReceiptFile=$values.internal_testing_release_receipt.File
    ReceiptSha=$receiptSha
    StatusFile=$values.internal_testing_status_observation.File
    StatusSha=$statusSha
  }
}

$receiptMode = $PSCmdlet.ParameterSetName -cin @(
  'ProductionReceipt','FixtureReceipt'
)
if (-not $receiptMode) {
  Assert-C34LPlayWriter (
    [bool]$InternalReleaseActive -and $UploadCount -eq 1 -and
    $InternalActivationCount -eq 1 -and -not [bool]$OtherTrackChanged
  ) 'one active Internal Testing upload and zero other-track changes are required.'
}

$stateFile = Resolve-C34LPlayRelative $StatePath 'detailed candidate state'
$stateRelative = Get-C34LPlayRelative $stateFile
if ($FixtureMode) {
  Assert-C34LPlayWriter (
    $stateRelative -cmatch
      '^tmp/(c34l-retained-evidence-fixtures-[0-9A-Za-z_-]+|c34l-authoritative-capture-fixtures-[0-9a-f]{32})/state[.]json$'
  ) 'fixture state is outside the exact C34L evidence-producer root.'
  $fixtureRoot = (Split-Path -Parent $stateRelative).Replace('\', '/')
  $expectedEvidenceRoot = "$fixtureRoot/evidence"
} else {
  Assert-C34LPlayWriter (
    $stateRelative -ceq 'config/successor-aab-regression-hard-gate-state-c34l.json'
  ) 'production writing requires the exact C34L detailed state.'
  $expectedEvidenceRoot = $productionEvidenceRoot
}
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C34LPlayProperties $state 'detailed candidate state' @(
  'ticketId', 'candidate', 'aggregateStatePath', 'machineState', 'evidenceRoot',
  'actionCounts', 'releaseAuthorities', 'buildResult'
)
$aggregateFile = Resolve-C34LPlayRelative ([string]$state.aggregateStatePath) `
  'aggregate candidate state'
$aggregateRelative = Get-C34LPlayRelative $aggregateFile
if ($FixtureMode) {
  Assert-C34LPlayWriter ($aggregateRelative -ceq "$fixtureRoot/aggregate.json") `
    'fixture aggregate escaped the exact fixture root.'
} else {
  Assert-C34LPlayWriter (
    $aggregateRelative -ceq
      'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
  ) 'production writing requires the exact C34L aggregate state.'
}
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
Assert-C34LPlayProperties $aggregate 'aggregate candidate state' @(
  'ticketId', 'candidate', 'machineState', 'actionCounts', 'releaseAuthorities'
)
Assert-C34LPlayWriter (
  [string]$state.ticketId -ceq $ticketId -and
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$state.candidate.packageName -ceq $packageName -and
  [string]$state.candidate.versionName -ceq $versionName -and
  [string]$aggregate.candidate.versionName -ceq $versionName -and
  [string]$state.candidate.versionCode -ceq $versionCode -and
  [string]$aggregate.candidate.versionCode -ceq $versionCode -and
  [string]$state.candidate.playTrack -ceq 'internal' -and
  [string]$state.machineState -ceq
    'postbuild_qualified_internal_testing_upload_authority_available_once' -and
  [string]$aggregate.machineState -ceq [string]$state.machineState -and
  [string]$state.evidenceRoot -ceq $expectedEvidenceRoot
) 'candidate identity, phase or evidence root changed.'
Assert-C34LPlayVector $state $aggregate
Assert-C34LPlayProperties $state.buildResult 'build result' @(
  'artifactPath', 'artifactSha256', 'artifactBytes'
)
$artifactFile = Resolve-C34LPlayRelative ([string]$state.buildResult.artifactPath) `
  'sealed C34L AAB'
$expectedArtifact =
  "$expectedEvidenceRoot/MoolSocial-$versionName-$versionCode-release.aab"
Assert-C34LPlayWriter (
  [string]$state.buildResult.artifactPath -ceq $expectedArtifact -and
  [string]$state.buildResult.artifactSha256 -cmatch '^[0-9A-F]{64}$' -and
  (Get-C34LPlaySha $artifactFile) -ceq [string]$state.buildResult.artifactSha256 -and
  (Get-Item -LiteralPath $artifactFile).Length -eq
    [int64]$state.buildResult.artifactBytes -and
  [int64]$state.buildResult.artifactBytes -gt 0
) 'sealed artifact path, SHA-256 or byte length changed.'

$stateSha = Get-C34LPlaySha $stateFile
$aggregateSha = Get-C34LPlaySha $aggregateFile
$expectedAttestation =
  "$expectedEvidenceRoot/attestations/source-attestation-play-attempt-$Attempt.json"
if ($receiptMode) {
  $expectedReceipt =
    "$expectedEvidenceRoot/captures/attempt-$Attempt/play/authoritative-capture-receipt.json"
  Assert-C34LPlayWriter (
    $AuthoritativeReceiptPath -ceq $expectedReceipt -and
    $AuthoritativeReceiptSha256 -cmatch '^[0-9A-F]{64}$' -and
    $AuthoritativeReceiptBytes -gt 0
  ) 'exact authoritative receipt path, SHA-256 and bytes are required.'
  $receiptFile = Resolve-C34LPlayRelative $AuthoritativeReceiptPath `
    'authoritative Play receipt'
  Assert-C34LPlayWriter (
    (Get-C34LPlaySha $receiptFile) -ceq $AuthoritativeReceiptSha256 -and
    (Get-Item -LiteralPath $receiptFile).Length -eq $AuthoritativeReceiptBytes
  ) 'authoritative Play receipt SHA-256 or bytes changed.'
  $receipt = Get-Content -Raw -LiteralPath $receiptFile | ConvertFrom-Json
  Assert-C34LPlayWriter (
    [string]$receipt.receiptContractId -ceq
      'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-RECEIPT-001' -and
    [string]$receipt.producerId -ceq $authoritativeProducerId -and
    [string]$receipt.evidenceType -ceq 'play_internal_testing_activation' -and
    [string]$receipt.ticketId -ceq $ticketId -and
    [int]$receipt.attempt -eq $Attempt -and
    [string]$receipt.detailedState.sha256 -ceq $stateSha -and
    [string]$receipt.aggregateState.sha256 -ceq $aggregateSha -and
    [string]$receipt.artifact.sha256 -ceq
      [string]$state.buildResult.artifactSha256
  ) 'authoritative Play receipt identity or preimage changed.'
  $SourceAttestationPath=$expectedAttestation
  $derivedAttestationFile=Resolve-C34LPlayRelative $SourceAttestationPath `
    'derived Play source attestation'
  $SourceAttestationSha256=Get-C34LPlaySha $derivedAttestationFile
  $SourceAttestationBytes=[int64](Get-Item -LiteralPath $derivedAttestationFile).Length
}
Assert-C34LPlayWriter (
  $SourceAttestationPath -ceq $expectedAttestation -and
  $SourceAttestationSha256 -cmatch '^[0-9A-F]{64}$' -and
  $SourceAttestationBytes -gt 0
) 'exact source-attestation path, SHA-256 and bytes are required.'
$attestationFile = Resolve-C34LPlayRelative $SourceAttestationPath `
  'Play source attestation'
Assert-C34LPlayWriter (
  (Get-C34LPlaySha $attestationFile) -ceq $SourceAttestationSha256 -and
  (Get-Item -LiteralPath $attestationFile).Length -eq $SourceAttestationBytes
) 'Play source-attestation SHA-256 or bytes changed.'
$attestationRaw = Get-Content -Raw -LiteralPath $attestationFile
$attestation = $attestationRaw | ConvertFrom-Json
$attestationNames = @(
  'schemaVersion','attestationContractId','evidenceType','ticketId','attempt',
  'packageName','versionName','versionCode','preStateSha256',
  'preAggregateSha256','actionCounts','releaseAuthorities','artifactSha256',
  'artifactBytes','sourceProducerId','sessionId','nonceSha256','producedUtc',
  'expiresUtc','captureManifestPath','captureManifestSha256',
  'captureManifestBytes','captureDigests'
)
$digestNames = @(
  'internalTestingRouteDigestSha256','uploadReceiptDigestSha256',
  'activationStateDigestSha256'
)
Assert-C34LPlayExactNames $attestation 'Play source attestation' $attestationNames
Assert-C34LPlayExactNames $attestation.captureDigests `
  'Play source-attestation digests' $digestNames
Assert-C34LPlayWriter (
  [int]$attestation.schemaVersion -eq 1 -and
  [string]$attestation.attestationContractId -ceq
    'MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001' -and
  [string]$attestation.evidenceType -ceq 'play_internal_testing_activation' -and
  [string]$attestation.ticketId -ceq $ticketId -and
  [int]$attestation.attempt -eq $Attempt -and
  [string]$attestation.packageName -ceq $packageName -and
  [string]$attestation.versionName -ceq $versionName -and
  [string]$attestation.versionCode -ceq $versionCode -and
  [string]$attestation.preStateSha256 -ceq $stateSha -and
  [string]$attestation.preAggregateSha256 -ceq $aggregateSha -and
  [string]$attestation.artifactSha256 -ceq
    [string]$state.buildResult.artifactSha256 -and
  [int64]$attestation.artifactBytes -eq [int64]$state.buildResult.artifactBytes -and
  [string]$attestation.sourceProducerId -ceq $(if ($receiptMode) {
      $authoritativeProducerId
    } else {
      'MOOLSOCIAL-C34L-PLAY-CAPTURE-PRODUCER-001'
    }) -and
  [string]$attestation.sessionId -cmatch '^[a-z0-9][a-z0-9_-]{15,95}$' -and
  [string]$attestation.nonceSha256 -cmatch '^[0-9A-F]{64}$'
) 'Play source attestation has wrong type, identity, preimage, artifact or session.'
Assert-C34LPlayVector $attestation $attestation
foreach ($name in $digestNames) {
  Assert-C34LPlayWriter (
    [string]$attestation.captureDigests.$name -cmatch '^[0-9A-F]{64}$'
  ) "Play source-attestation digest changed at $name."
}
$produced = ConvertTo-C34LPlayUtc $attestation.producedUtc 'producedUtc'
$expires = ConvertTo-C34LPlayUtc $attestation.expiresUtc 'expiresUtc'
Assert-C34LPlayRawUtc $attestationRaw 'producedUtc' $produced
Assert-C34LPlayRawUtc $attestationRaw 'expiresUtc' $expires
Assert-C34LPlayWriter (
  $expires -gt $produced -and $expires -le $produced.AddMinutes(15) -and
  $expires -gt [DateTimeOffset]::UtcNow.AddSeconds(-30)
) 'Play source-attestation session is expired or invalid.'
$captureFile = Resolve-C34LPlayRelative `
  ([string]$attestation.captureManifestPath) 'Play capture manifest'
Assert-C34LPlayWriter (
  [string]$attestation.captureManifestPath -ceq
    "$expectedEvidenceRoot/captures/attempt-$Attempt/play/capture-manifest.json" -and
  [string]$attestation.captureManifestSha256 -cmatch '^[0-9A-F]{64}$' -and
  (Get-C34LPlaySha $captureFile) -ceq
    [string]$attestation.captureManifestSha256 -and
  [int64]$attestation.captureManifestBytes -gt 0 -and
  (Get-Item -LiteralPath $captureFile).Length -eq
    [int64]$attestation.captureManifestBytes
) 'Play capture-manifest binding changed.'
$captureValues = Read-C34LPlayCaptureArtifacts $captureFile `
  $expectedEvidenceRoot $attestation $state
if ($receiptMode) {
  $InternalReleaseActive=[bool]$captureValues.Status.internalReleaseActive
  $UploadCount=[int]$captureValues.Receipt.uploadCount
  $InternalActivationCount=[int]$captureValues.Status.internalActivationCount
  $OtherTrackChanged=[bool]$captureValues.Receipt.otherTrackChanged
} else {
  Assert-C34LPlayWriter (
    [bool]$InternalReleaseActive -eq
      [bool]$captureValues.Status.internalReleaseActive -and
    $UploadCount -eq [int]$captureValues.Receipt.uploadCount -and
    $InternalActivationCount -eq
      [int]$captureValues.Status.internalActivationCount -and
    [bool]$OtherTrackChanged -eq
      [bool]$captureValues.Receipt.otherTrackChanged
  ) 'fixture Play result does not match the retained capture artifacts.'
}
$evidence = [pscustomobject][ordered]@{
  schemaVersion = 1
  evidenceContractId = 'MOOLSOCIAL-C34L-PLAY-EVIDENCE-001'
  evidenceType = 'play_internal_testing_activation'
  ticketId = $ticketId
  attempt = $Attempt
  preStateSha256 = $stateSha
  preAggregateSha256 = $aggregateSha
  actionCounts = $state.actionCounts
  releaseAuthorities = $state.releaseAuthorities
  packageName = $packageName
  versionName = $versionName
  versionCode = $versionCode
  artifactSha256 = [string]$state.buildResult.artifactSha256
  artifactBytes = [int64]$state.buildResult.artifactBytes
  track = 'internal'
  internalReleaseActive = [bool]$captureValues.Status.internalReleaseActive
  uploadCount = [int]$captureValues.Receipt.uploadCount
  internalActivationCount = [int]$captureValues.Status.internalActivationCount
  otherTrackChanged = [bool]$captureValues.Receipt.otherTrackChanged
  sourceAttestation = [pscustomobject][ordered]@{
    path = $SourceAttestationPath; sha256 = $SourceAttestationSha256
    bytes = $SourceAttestationBytes
    evidenceType = [string]$attestation.evidenceType
    sourceProducerId = [string]$attestation.sourceProducerId
    sessionId = [string]$attestation.sessionId
    nonceSha256 = [string]$attestation.nonceSha256
    producedUtc = $produced.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
      [Globalization.CultureInfo]::InvariantCulture)
    expiresUtc = $expires.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
      [Globalization.CultureInfo]::InvariantCulture)
    captureManifestPath = [string]$attestation.captureManifestPath
    captureManifestSha256 = [string]$attestation.captureManifestSha256
    captureManifestBytes = [int64]$attestation.captureManifestBytes
    captureDigests = $attestation.captureDigests
  }
}
$json = ($evidence | ConvertTo-Json -Depth 20) + [Environment]::NewLine
Assert-C34LPlayWriter (-not [regex]::IsMatch(
  $json,
  'AIza[0-9A-Za-z_-]{35}|(?i)Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----|\b[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com\b'
)) 'generated evidence contains secret- or private-identifier-shaped material.'
$targetRelative = "$expectedEvidenceRoot/07-play-internal-testing-activation-evidence.json"
$targetFile = Resolve-C34LPlayRelative $targetRelative 'Play evidence target' -AllowMissing
Assert-C34LPlayWriter (
  (Get-C34LPlaySha $stateFile) -ceq $stateSha -and
  (Get-C34LPlaySha $aggregateFile) -ceq $aggregateSha -and
  (Get-C34LPlaySha $artifactFile) -ceq [string]$state.buildResult.artifactSha256 -and
  (Get-C34LPlaySha $attestationFile) -ceq $SourceAttestationSha256 -and
  (Get-C34LPlaySha $captureFile) -ceq
    [string]$attestation.captureManifestSha256 -and
  (Get-C34LPlaySha $captureValues.ReceiptFile) -ceq $captureValues.ReceiptSha -and
  (Get-C34LPlaySha $captureValues.StatusFile) -ceq $captureValues.StatusSha
) 'candidate preimage or artifact changed before evidence persistence.'
Write-C34LPlayImmutableJson $targetFile $json
$evidenceSha = Get-C34LPlaySha $targetFile
$evidenceBytes = (Get-Item -LiteralPath $targetFile).Length
Assert-C34LPlayWriter (
  (Get-C34LPlaySha $stateFile) -ceq $stateSha -and
  (Get-C34LPlaySha $aggregateFile) -ceq $aggregateSha -and
  $evidenceSha -cmatch '^[0-9A-F]{64}$' -and $evidenceBytes -gt 0
) 'candidate preimage changed during persistence or evidence identity is invalid.'
Write-Output (([pscustomobject][ordered]@{
  ticketId = $ticketId
  attempt = $Attempt
  evidenceType = 'play_internal_testing_activation'
  path = $targetRelative
  sha256 = $evidenceSha
  bytes = $evidenceBytes
  preStateSha256 = $stateSha
  preAggregateSha256 = $aggregateSha
  externalActionsPerformed = 0
  secretOrPrivateValuesRecorded = $false
}) | ConvertTo-Json -Compress)
