[CmdletBinding(DefaultParameterSetName = 'ProductionReceipt')]
param(
  [ValidateSet(
    'play_internal_testing_activation', 'oppo_play_in_place_update_pair',
    'mandatory_whole_app_journey_acceptance'
  )]
  [string]$EvidenceType,
  [ValidateRange(1, 5)][int]$Attempt = 1,
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34l.json',
  [Parameter(Mandatory, ParameterSetName='FixtureCapture')]
  [string]$CaptureManifestPath,
  [Parameter(Mandatory, ParameterSetName='FixtureCapture')]
  [string]$CaptureManifestSha256,
  [Parameter(Mandatory, ParameterSetName='FixtureCapture')]
  [long]$CaptureManifestBytes,
  [Parameter(Mandatory, ParameterSetName='ProductionReceipt')]
  [Parameter(Mandatory, ParameterSetName='FixtureReceipt')]
  [string]$AuthoritativeReceiptPath,
  [Parameter(Mandatory, ParameterSetName='ProductionReceipt')]
  [Parameter(Mandatory, ParameterSetName='FixtureReceipt')]
  [string]$AuthoritativeReceiptSha256,
  [Parameter(Mandatory, ParameterSetName='ProductionReceipt')]
  [Parameter(Mandatory, ParameterSetName='FixtureReceipt')]
  [long]$AuthoritativeReceiptBytes,
  [Parameter(Mandatory, ParameterSetName='FixtureCapture')]
  [Parameter(Mandatory, ParameterSetName='FixtureReceipt')]
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
$packageName = 'com.moolsocial.app'
$versionName = '1.0.0-r60.76'
$versionCode = '2026081376'
$productionEvidenceRoot =
  'artifacts/quality/uaw-c34l-r60-76-consolidated-release-transaction-evidence-preparation-20260817-01'
$attestationContractId = 'MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001'
$captureContractId = 'MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001'
$captureArtifactContractPath =
  'config/release-evidence-capture-artifact-contract-c34l.json'
$captureArtifactContractSha256 =
  'D7B8DE822D709F25CEB1AEFFFF4093260B3EFB83DCADE1F632309026ECC0B9D2'
$captureArtifactContractId = 'MOOLSOCIAL-C34L-CAPTURE-ARTIFACT-CONTRACT-003'
$authoritativeProducerId =
  'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-PRODUCER-001'
$authoritativeProducerPath =
  'scripts/write-release-authoritative-capture-receipt-c34l.ps1'
$authoritativeReceiptContractId =
  'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-RECEIPT-001'
$authoritativeJournalContractId =
  'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-JOURNAL-001'
$countNames = @(
  'build','upload','install','deviceAcceptance','passwordlessEmailSend',
  'realSmsSend','otherTrack','backendHostingProviderOrProductionDeployment'
)
$authorityNames = @(
  'build','uploadAndInternalActivation','inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)
$utf8 = [Text.UTF8Encoding]::new($false)

function Assert-C34LAttestation([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C34L source-attestation writer rejected: $Message" }
}
function Assert-C34LExactNames($Value, [string[]]$Names, [string]$Label) {
  $actual = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LAttestation ($actual.Count -eq $Names.Count) `
    "$Label property count changed."
  foreach ($name in $Names) {
    Assert-C34LAttestation ($actual -ccontains $name) `
      "$Label is missing or has an unknown property at $name."
  }
}
function Assert-C34LNoReparseChain([string]$Resolved, [string]$Label) {
  $current = if (Test-Path -LiteralPath $Resolved) {
    [IO.Path]::GetFullPath($Resolved)
  } else {
    [IO.Path]::GetFullPath((Split-Path -Parent $Resolved))
  }
  while ($true) {
    Assert-C34LAttestation (
      $current.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
      $current.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) "$Label ancestor escaped the production repository."
    Assert-C34LAttestation (Test-Path -LiteralPath $current) `
      "$Label ancestor is missing."
    Assert-C34LAttestation (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $parent = Split-Path -Parent $current
    Assert-C34LAttestation (-not [string]::IsNullOrWhiteSpace($parent)) `
      "$Label ancestor chain is incomplete."
    $current = [IO.Path]::GetFullPath($parent)
  }
}
function Resolve-C34LRelative(
  [string]$Path,
  [string]$Label,
  [switch]$AllowMissing
) {
  Assert-C34LAttestation (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path) -and
    -not $Path.Contains('\') -and -not $Path.Contains('?') -and
    -not $Path.Contains('#')
  ) "$Label must be one normalized repository-relative path."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LAttestation (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) "$Label escaped the production repository."
  Assert-C34LNoReparseChain $resolved $Label
  if (-not $AllowMissing) {
    Assert-C34LAttestation (Test-Path -LiteralPath $resolved -PathType Leaf) `
      "$Label is missing."
  } else {
    Assert-C34LAttestation (-not (Test-Path -LiteralPath $resolved)) `
      "$Label immutable owner already exists."
  }
  return $resolved
}
function Get-C34LRelative([string]$Resolved) {
  return ([IO.Path]::GetFullPath($Resolved)).Substring($rootPrefix.Length).
    Replace('\', '/')
}
function Get-C34LSha([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}
function Get-C34LTextSha([string]$Text) {
  $algorithm = [Security.Cryptography.SHA256]::Create()
  try { $bytes = $algorithm.ComputeHash($utf8.GetBytes($Text)) }
  finally { $algorithm.Dispose() }
  return ([BitConverter]::ToString($bytes)).Replace('-', '')
}
function ConvertTo-C34LUtc($Value, [string]$Label) {
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
  Assert-C34LAttestation (
    $ok -and $parsed.ToUniversalTime().Offset -eq [TimeSpan]::Zero
  ) "$Label must be canonical UTC with milliseconds."
  return $parsed.ToUniversalTime()
}
function Assert-C34LRawUtcToken(
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
  Assert-C34LAttestation (
    $matches.Count -eq 1 -and $matches[0].Groups[1].Value -ceq $canonical
  ) "$Name raw JSON token is not one exact canonical UTC string."
}
function Assert-C34LPrivacy($Value, [string]$Label, [string]$PropertyPath = '$') {
  $forbiddenName =
    '(?i)(email|phone|private|url|link|identifier|exception|stack|credential|secret|token|key|rawnonce|account|^(deviceSerial|serial|androidId|imei|imsi|advertisingId)$)'
  $forbiddenValue =
    '(?i)([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|https?://|www\.|(?:Bearer|Basic)\s+|AIza[0-9A-Za-z_-]{35}|-----BEGIN|Exception(?:\s*:|\r|\n)|StackTrace|Traceback\s*\(|[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}|(?<![A-Za-z0-9])2b3e0f71(?![A-Za-z0-9])|[?&][A-Za-z0-9_.%+-]+=|#[A-Za-z0-9_.%+-]+)'
  if ($null -eq $Value) { return }
  if ($Value -is [string]) {
    Assert-C34LAttestation (-not [regex]::IsMatch([string]$Value, $forbiddenValue)) `
      "$Label contains a forbidden private value shape at $PropertyPath."
    return
  }
  if ($Value -is [Collections.IEnumerable] -and
      $Value -isnot [Management.Automation.PSCustomObject] -and
      $Value -isnot [Collections.IDictionary]) {
    $index = 0
    foreach ($item in $Value) {
      Assert-C34LPrivacy $item $Label "$PropertyPath[$index]"
      $index++
    }
    return
  }
  if ($Value -isnot [Management.Automation.PSCustomObject] -and
      $Value -isnot [Collections.IDictionary]) {
    Assert-C34LAttestation (
      -not [regex]::IsMatch([string]$Value, $forbiddenValue)
    ) "$Label contains a forbidden private scalar shape at $PropertyPath."
    return
  }
  foreach ($property in @($Value.PSObject.Properties)) {
    $schemaNameAllowed =
      ($PropertyPath -ceq '$.actionCounts' -and
        $countNames -ccontains $property.Name) -or
      ($PropertyPath -ceq '$.releaseAuthorities' -and
        $authorityNames -ccontains $property.Name)
    Assert-C34LAttestation (
      $schemaNameAllowed -or -not [regex]::IsMatch($property.Name, $forbiddenName)
    ) `
      "$Label contains forbidden private property $($property.Name)."
    Assert-C34LPrivacy $property.Value $Label "$PropertyPath.$($property.Name)"
  }
}
function Assert-C34LVector($Value, [int[]]$Counts, [string[]]$Authorities,
  [string]$Label) {
  Assert-C34LExactNames $Value.actionCounts $countNames "$Label actionCounts"
  Assert-C34LExactNames $Value.releaseAuthorities $authorityNames `
    "$Label releaseAuthorities"
  for ($index = 0; $index -lt $countNames.Count; $index++) {
    $name = $countNames[$index]
    Assert-C34LAttestation ([int]$Value.actionCounts.$name -eq $Counts[$index]) `
      "$Label action count changed at $name."
  }
  for ($index = 0; $index -lt $authorityNames.Count; $index++) {
    $name = $authorityNames[$index]
    Assert-C34LAttestation (
      [string]$Value.releaseAuthorities.$name -ceq $Authorities[$index]
    ) "$Label release authority changed at $name."
  }
}

$specs = @{
  play_internal_testing_activation = [pscustomobject]@{
    Short='play'; FixtureProducer='MOOLSOCIAL-C34L-PLAY-CAPTURE-PRODUCER-001'
    CaptureRoles=@(
      'internal_testing_release_receipt','internal_testing_status_observation'
    )
    Counts=@(1,0,0,0,0,0,0,0)
    Authorities=@('consumed','available_once','held_postupload_qualification',
      'held_postinstall_journey_qualification')
    Digests=@('internalTestingRouteDigestSha256','uploadReceiptDigestSha256',
      'activationStateDigestSha256')
  }
  oppo_play_in_place_update_pair = [pscustomobject]@{
    Short='oppo'; FixtureProducer='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
    CaptureRoles=@('cold_start_observation','retained_state_observation')
    Counts=@(1,1,0,0,0,0,0,0)
    Authorities=@('consumed','consumed','available_once',
      'held_postinstall_journey_qualification')
    Digests=@('packageStateDigestSha256','coldStartDigestSha256',
      'retainedDataDigestSha256')
  }
  mandatory_whole_app_journey_acceptance = [pscustomobject]@{
    Short='journey'; FixtureProducer='MOOLSOCIAL-C34L-JOURNEY-CAPTURE-PRODUCER-001'
    CaptureRoles=@('journey_acceptance_manifest')
    Counts=@(1,1,1,0,0,0,0,0)
    Authorities=@('consumed','consumed','consumed',
      'held_postinstall_journey_qualification')
    Digests=@('publicGuestDigestSha256','protectedGatewayDigestSha256',
      'supportedAuthenticationDigestSha256','socialDigestSha256',
      'wholeAppDigestSha256','c33gBlockerDigestSha256')
  }
}
$spec = $specs[$EvidenceType]
$expectedCaptureProducer = if (
  $PSCmdlet.ParameterSetName -ceq 'FixtureCapture'
) { [string]$spec.FixtureProducer } else { $authoritativeProducerId }
function Assert-C34LCaptureArtifacts($Capture, $Spec, [string]$EvidenceRoot) {
  $contractFile = Resolve-C34LRelative $captureArtifactContractPath `
    'capture-artifact contract'
  Assert-C34LAttestation (
    (Get-C34LSha $contractFile) -ceq $captureArtifactContractSha256
  ) 'capture-artifact contract SHA-256 changed.'
  $contract = Get-Content -Raw -LiteralPath $contractFile | ConvertFrom-Json
  Assert-C34LExactNames $contract @(
    'schemaVersion','contractId','ticketId','productionProducer',
    'authoritativeReceipt','captureAttemptRootPattern',
    'captureManifestPathPattern','captureArtifactPathPattern',
    'captureArtifactFields','mediaType','evidenceTypes','deviceBinding','privacy'
  ) 'capture-artifact contract'
  Assert-C34LExactNames $contract.deviceBinding @(
    'derivationId','derivationPattern','expectedSha256','retainedField',
    'forbiddenRawFields'
  ) 'capture-artifact device binding'
  Assert-C34LAttestation (
    [int]$contract.schemaVersion -eq 3 -and
    [string]$contract.contractId -ceq $captureArtifactContractId -and
    [string]$Capture.captureArtifactContractPath -ceq
      $captureArtifactContractPath -and
    [string]$Capture.captureArtifactContractSha256 -ceq
      $captureArtifactContractSha256 -and
    [string]$Capture.captureArtifactContractId -ceq
      $captureArtifactContractId -and
    [string]$contract.mediaType -ceq 'application/json' -and
    [string]$contract.deviceBinding.expectedSha256 -ceq
      '97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF'
  ) 'capture-artifact contract identity or binding changed.'
  $contractSpec = $contract.evidenceTypes.($EvidenceType)
  Assert-C34LAttestation ($null -ne $contractSpec) `
    'capture evidence type is absent from the exact artifact contract.'
  $artifacts = @($Capture.captureArtifacts)
  Assert-C34LAttestation (
    $artifacts.Count -eq $Spec.CaptureRoles.Count -and
    @($artifacts.role | Select-Object -Unique).Count -eq $artifacts.Count -and
    (@($artifacts.role | Sort-Object) -join ',') -ceq
      (@($Spec.CaptureRoles | Sort-Object) -join ',')
  ) 'capture-artifact role set changed.'
  $artifactByRole = @{}
  foreach ($artifact in $artifacts) {
    Assert-C34LExactNames $artifact @('role','path','sha256','bytes','mediaType') `
      'capture artifact'
    $role = [string]$artifact.role
    $leaf = [string]$contractSpec.leafByRole.$role
    $expectedPath =
      "$EvidenceRoot/captures/attempt-$Attempt/$($Spec.Short)/$leaf"
    Assert-C34LAttestation (
      -not [string]::IsNullOrWhiteSpace($leaf) -and
      [string]$artifact.path -ceq $expectedPath -and
      [string]$artifact.mediaType -ceq 'application/json' -and
      [string]$artifact.sha256 -cmatch '^[0-9A-F]{64}$' -and
      [int64]$artifact.bytes -gt 0
    ) "capture artifact path, role, identity or media type changed at $role."
    $artifactFile = Resolve-C34LRelative ([string]$artifact.path) `
      "capture artifact $role"
    Assert-C34LAttestation (
      (Get-C34LSha $artifactFile) -ceq [string]$artifact.sha256 -and
      (Get-Item -LiteralPath $artifactFile).Length -eq [int64]$artifact.bytes
    ) "capture artifact SHA-256 or bytes changed at $role."
    try { $artifactValue = Get-Content -Raw -LiteralPath $artifactFile |
        ConvertFrom-Json } catch {
      throw "C34L source-attestation writer rejected: capture artifact $role is not valid JSON."
    }
    Assert-C34LPrivacy $artifactValue "capture artifact $role"
    $artifactByRole[$role] = [pscustomobject]@{
      Binding=$artifact; Value=$artifactValue
    }
  }
  if ($Spec.Short -ceq 'play') {
    $receiptSha = [string]$artifactByRole.internal_testing_release_receipt.Binding.sha256
    $statusSha = [string]$artifactByRole.internal_testing_status_observation.Binding.sha256
    Assert-C34LAttestation (
      [string]$Capture.captureDigests.internalTestingRouteDigestSha256 -ceq
        $receiptSha -and
      [string]$Capture.captureDigests.uploadReceiptDigestSha256 -ceq
        $receiptSha -and
      [string]$Capture.captureDigests.activationStateDigestSha256 -ceq
        $statusSha
    ) 'Play capture digests are not bound to the exact capture artifacts.'
  } elseif ($Spec.Short -ceq 'oppo') {
    $coldSha = [string]$artifactByRole.cold_start_observation.Binding.sha256
    $retainedSha = [string]$artifactByRole.retained_state_observation.Binding.sha256
    Assert-C34LAttestation (
      [string]$Capture.captureDigests.packageStateDigestSha256 -ceq $coldSha -and
      [string]$Capture.captureDigests.coldStartDigestSha256 -ceq $coldSha -and
      [string]$Capture.captureDigests.retainedDataDigestSha256 -ceq $retainedSha
    ) 'OPPO capture digests are not bound to the exact capture artifacts.'
  } else {
    $journeyRows = @($artifactByRole.journey_acceptance_manifest.Value)
    $journeyIds = @(
      'publicGuest','protectedGateway','supportedAuthentication','social',
      'wholeApp','c33gBlocker'
    )
    Assert-C34LAttestation (
      $journeyRows.Count -eq $journeyIds.Count -and
      @($journeyRows.journeyId | Select-Object -Unique).Count -eq
        $journeyRows.Count -and
      (@($journeyRows.journeyId) -join ',') -ceq
        (@($journeyIds) -join ',')
    ) 'journey capture-manifest row set changed.'
    foreach ($row in $journeyRows) {
      Assert-C34LExactNames $row @('journeyId','path','sha256','bytes','passed') `
        'journey capture-manifest row'
      $journeyId = [string]$row.journeyId
      $expectedPath =
        "$EvidenceRoot/captures/attempt-$Attempt/journey/journeys/$journeyId.json"
      Assert-C34LAttestation (
        [bool]$row.passed -and [string]$row.path -ceq $expectedPath -and
        [string]$row.sha256 -cmatch '^[0-9A-F]{64}$' -and
        [int64]$row.bytes -gt 0
      ) "journey capture row path or result changed at $journeyId."
      $journeyFile = Resolve-C34LRelative ([string]$row.path) `
        "journey capture artifact $journeyId"
      Assert-C34LAttestation (
        (Get-C34LSha $journeyFile) -ceq [string]$row.sha256 -and
        (Get-Item -LiteralPath $journeyFile).Length -eq [int64]$row.bytes
      ) "journey capture artifact SHA-256 or bytes changed at $journeyId."
      try { $journeyValue = Get-Content -Raw -LiteralPath $journeyFile |
          ConvertFrom-Json } catch {
        throw "C34L source-attestation writer rejected: journey capture artifact $journeyId is not valid JSON."
      }
      Assert-C34LPrivacy $journeyValue "journey capture artifact $journeyId"
      $digestName = $journeyId + 'DigestSha256'
      Assert-C34LAttestation (
        $null -ne $Capture.captureDigests.PSObject.Properties[$digestName] -and
        [string]$Capture.captureDigests.$digestName -ceq [string]$row.sha256
      ) "journey capture digest is not bound at $journeyId."
    }
  }
}
$stateFile = Resolve-C34LRelative $StatePath 'detailed candidate state'
$stateRelative = Get-C34LRelative $stateFile
if ($FixtureMode) {
  Assert-C34LAttestation (
    $stateRelative -cmatch
      '^tmp/(c34l-retained-evidence-fixtures-[0-9A-Za-z_-]+|c34l-authoritative-capture-fixtures-[0-9a-f]{32})/state[.]json$'
  ) 'fixture state is outside the exact C34L attestation root.'
  $fixtureRoot = (Split-Path -Parent $stateRelative).Replace('\', '/')
  $expectedEvidenceRoot = "$fixtureRoot/evidence"
} else {
  Assert-C34LAttestation (
    $stateRelative -ceq 'config/successor-aab-regression-hard-gate-state-c34l.json'
  ) 'production writing requires the exact C34L detailed state.'
  $expectedEvidenceRoot = $productionEvidenceRoot
}
$stateRaw = Get-Content -Raw -LiteralPath $stateFile
$state = $stateRaw | ConvertFrom-Json
Write-Verbose 'c34l-attestation-writer-progress=state-loaded'
Assert-C34LExactNames $state.actionCounts $countNames 'state actionCounts'
Assert-C34LExactNames $state.releaseAuthorities $authorityNames `
  'state releaseAuthorities'
$aggregateFile = Resolve-C34LRelative ([string]$state.aggregateStatePath) `
  'aggregate candidate state'
$aggregateRelative = Get-C34LRelative $aggregateFile
Assert-C34LAttestation (
  ($FixtureMode -and $aggregateRelative -ceq "$fixtureRoot/aggregate.json") -or
  (-not $FixtureMode -and $aggregateRelative -ceq
    'config/successor-aab-regression-hard-gate-aggregate-c34l.json')
) 'aggregate state escaped the exact candidate root.'
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
$stateSha = Get-C34LSha $stateFile
$aggregateSha = Get-C34LSha $aggregateFile
Assert-C34LAttestation (
  [string]$state.ticketId -ceq $ticketId -and
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$state.candidate.packageName -ceq $packageName -and
  [string]$state.candidate.versionName -ceq $versionName -and
  [string]$aggregate.candidate.versionName -ceq $versionName -and
  [string]$state.candidate.versionCode -ceq $versionCode -and
  [string]$aggregate.candidate.versionCode -ceq $versionCode -and
  [string]$state.evidenceRoot -ceq $expectedEvidenceRoot
) 'candidate identity, version or evidence root changed.'
Assert-C34LVector $state $spec.Counts $spec.Authorities 'state'
Assert-C34LVector $aggregate $spec.Counts $spec.Authorities 'aggregate'
Assert-C34LAttestation (
  [string]$state.buildResult.artifactSha256 -cmatch '^[0-9A-F]{64}$' -and
  [int64]$state.buildResult.artifactBytes -gt 0
) 'candidate artifact identity is incomplete.'
$artifactFile = Resolve-C34LRelative ([string]$state.buildResult.artifactPath) `
  'sealed candidate artifact'
Assert-C34LAttestation (
  (Get-C34LSha $artifactFile) -ceq [string]$state.buildResult.artifactSha256 -and
  (Get-Item -LiteralPath $artifactFile).Length -eq
    [int64]$state.buildResult.artifactBytes
) 'candidate artifact SHA-256 or bytes changed.'

$expectedCapture =
  "$expectedEvidenceRoot/captures/attempt-$Attempt/$($spec.Short)/capture-manifest.json"
$receiptMode = $PSCmdlet.ParameterSetName -cin @(
  'ProductionReceipt','FixtureReceipt'
)
if ($receiptMode) {
  $contractFile = Resolve-C34LRelative $captureArtifactContractPath `
    'capture-artifact contract'
  $contract = Get-Content -Raw -LiteralPath $contractFile | ConvertFrom-Json
  $expectedReceipt =
    "$expectedEvidenceRoot/captures/attempt-$Attempt/$($spec.Short)/authoritative-capture-receipt.json"
  Assert-C34LAttestation ($AuthoritativeReceiptPath -ceq $expectedReceipt) `
    'authoritative receipt is not the exact producer-owned candidate receipt.'
  $receiptFile = Resolve-C34LRelative $AuthoritativeReceiptPath `
    'authoritative capture receipt'
  Assert-C34LAttestation (
    $AuthoritativeReceiptSha256 -cmatch '^[0-9A-F]{64}$' -and
    (Get-C34LSha $receiptFile) -ceq $AuthoritativeReceiptSha256 -and
    $AuthoritativeReceiptBytes -gt 0 -and
    (Get-Item -LiteralPath $receiptFile).Length -eq
      $AuthoritativeReceiptBytes
  ) 'authoritative receipt SHA-256 or byte-length binding changed.'
  $receiptRaw = Get-Content -Raw -LiteralPath $receiptFile
  try { $receipt = $receiptRaw | ConvertFrom-Json } catch {
    throw 'C34L source-attestation writer rejected: authoritative receipt is not valid JSON.'
  }
  Assert-C34LExactNames $receipt `
    @($contract.authoritativeReceipt.topLevelFields) `
    'authoritative capture receipt'
  Assert-C34LPrivacy $receipt 'authoritative capture receipt'
  foreach ($bindingName in @(
      'captureArtifactContract','producerOwner','sealedSourceManifest',
      'detailedState','aggregateState','artifact','transitionJournal',
      'captureManifest'
    )) {
    Assert-C34LExactNames $receipt.$bindingName @('path','sha256','bytes') `
      "authoritative receipt $bindingName"
  }
  Assert-C34LAttestation (
    [int]$receipt.schemaVersion -eq 1 -and
    [string]$receipt.receiptContractId -ceq $authoritativeReceiptContractId -and
    [string]$receipt.producerId -ceq $authoritativeProducerId -and
    [string]$receipt.evidenceType -ceq $EvidenceType -and
    [string]$receipt.ticketId -ceq $ticketId -and
    [int]$receipt.attempt -eq $Attempt -and
    [string]$receipt.packageName -ceq $packageName -and
    [string]$receipt.versionName -ceq $versionName -and
    [string]$receipt.versionCode -ceq $versionCode -and
    [string]$receipt.challengeSha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$receipt.previousJournalHeadSha256 -cmatch '^[0-9A-F]{64}$'
  ) 'authoritative receipt identity, type, challenge or chain head changed.'
  $producerFile = Resolve-C34LRelative $authoritativeProducerPath `
    'authoritative capture producer owner'
  Assert-C34LAttestation (
    [string]$receipt.captureArtifactContract.path -ceq
      $captureArtifactContractPath -and
    [string]$receipt.captureArtifactContract.sha256 -ceq
      $captureArtifactContractSha256 -and
    [int64]$receipt.captureArtifactContract.bytes -eq
      (Get-Item -LiteralPath $contractFile).Length -and
    [string]$receipt.producerOwner.path -ceq $authoritativeProducerPath -and
    [string]$receipt.producerOwner.sha256 -ceq (Get-C34LSha $producerFile) -and
    [int64]$receipt.producerOwner.bytes -eq
      (Get-Item -LiteralPath $producerFile).Length -and
    [string]$receipt.detailedState.path -ceq $stateRelative -and
    [string]$receipt.detailedState.sha256 -ceq $stateSha -and
    [int64]$receipt.detailedState.bytes -eq
      (Get-Item -LiteralPath $stateFile).Length -and
    [string]$receipt.aggregateState.path -ceq $aggregateRelative -and
    [string]$receipt.aggregateState.sha256 -ceq $aggregateSha -and
    [int64]$receipt.aggregateState.bytes -eq
      (Get-Item -LiteralPath $aggregateFile).Length -and
    [string]$receipt.artifact.path -ceq
      [string]$state.buildResult.artifactPath -and
    [string]$receipt.artifact.sha256 -ceq
      [string]$state.buildResult.artifactSha256 -and
    [int64]$receipt.artifact.bytes -eq
      [int64]$state.buildResult.artifactBytes
  ) 'authoritative receipt contract, producer, state or artifact binding changed.'
  $sourceManifestFile = Resolve-C34LRelative `
    ([string]$receipt.sealedSourceManifest.path) 'sealed source manifest'
  Assert-C34LAttestation (
    [string]$receipt.sealedSourceManifest.path -ceq
      [string]$state.sourceQualification.manifestPath -and
    [string]$receipt.sealedSourceManifest.sha256 -ceq
      [string]$state.sourceQualification.manifestSha256 -and
    [int64]$receipt.sealedSourceManifest.bytes -eq
      [int64]$state.sourceQualification.manifestBytes -and
    (Get-C34LSha $sourceManifestFile) -ceq
      [string]$receipt.sealedSourceManifest.sha256 -and
    (Get-Item -LiteralPath $sourceManifestFile).Length -eq
      [int64]$receipt.sealedSourceManifest.bytes
  ) 'authoritative receipt sealed-source binding changed.'
  Assert-C34LAttestation (
    (ConvertTo-Json $receipt.actionCounts -Compress) -ceq
      (ConvertTo-Json $state.actionCounts -Compress) -and
    (ConvertTo-Json $receipt.releaseAuthorities -Compress) -ceq
      (ConvertTo-Json $state.releaseAuthorities -Compress)
  ) 'authoritative receipt action or authority vector changed.'
  $transitionFile = Resolve-C34LRelative `
    ([string]$receipt.transitionJournal.path) 'receipt transition journal'
  Assert-C34LAttestation (
    (Get-C34LSha $transitionFile) -ceq
      [string]$receipt.transitionJournal.sha256 -and
    (Get-Item -LiteralPath $transitionFile).Length -eq
      [int64]$receipt.transitionJournal.bytes
  ) 'authoritative receipt transition-journal binding changed.'
  $transition = Get-Content -Raw -LiteralPath $transitionFile | ConvertFrom-Json
  $challengeMaterial = @(
    $authoritativeJournalContractId,$ticketId,[string]$Attempt,
    [string]$receipt.transitionJournal.path,
    [string]$receipt.transitionJournal.sha256,
    [string]$transition.transactionId,[string]$transition.sequence,
    [string]$transition.stateAfterSha256,
    [string]$transition.aggregateAfterSha256,
    [string]$receipt.producerOwner.sha256,
    [string]$receipt.sealedSourceManifest.sha256
  ) -join '|'
  $expectedChallenge = Get-C34LTextSha $challengeMaterial
  $expectedSessionHash = Get-C34LTextSha (
    "$expectedChallenge|$($receipt.producerOwner.sha256)|$($receipt.sealedSourceManifest.sha256)"
  )
  Assert-C34LAttestation (
    [string]$receipt.challengeSha256 -ceq $expectedChallenge -and
    [string]$receipt.sessionId -ceq
      ('c34l-authoritative-session-' +
        $expectedSessionHash.Substring(0,24).ToLowerInvariant())
  ) 'authoritative receipt challenge or derived session changed.'
  foreach ($sourceBinding in @($receipt.observationSources)) {
    Assert-C34LExactNames $sourceBinding @('path','sha256','bytes') `
      'authoritative observation source'
    $sourceFile = Resolve-C34LRelative ([string]$sourceBinding.path) `
      'authoritative observation source'
    Assert-C34LAttestation (
      (Get-C34LSha $sourceFile) -ceq [string]$sourceBinding.sha256 -and
      (Get-Item -LiteralPath $sourceFile).Length -eq
        [int64]$sourceBinding.bytes
    ) 'authoritative observation source SHA-256 or bytes changed.'
  }
  Assert-C34LAttestation (
    [string]$receipt.captureManifest.path -ceq $expectedCapture
  ) 'authoritative receipt capture-manifest path changed.'
  $CaptureManifestPath = [string]$receipt.captureManifest.path
  $CaptureManifestSha256 = [string]$receipt.captureManifest.sha256
  $CaptureManifestBytes = [int64]$receipt.captureManifest.bytes
  $receiptProduced = ConvertTo-C34LUtc $receipt.producedUtc `
    'authoritative receipt producedUtc'
  Assert-C34LRawUtcToken $receiptRaw 'producedUtc' $receiptProduced
  $journalRelative =
    "$expectedEvidenceRoot/authoritative-capture-journals/attempt-$Attempt/$EvidenceType.json"
  $journalFile = Resolve-C34LRelative $journalRelative `
    'authoritative capture journal'
  $journal = Get-Content -Raw -LiteralPath $journalFile | ConvertFrom-Json
  Assert-C34LAttestation (
    [string]$journal.journalContractId -ceq $authoritativeJournalContractId -and
    [string]$journal.ticketId -ceq $ticketId -and
    [int]$journal.attempt -eq $Attempt -and
    [string]$journal.evidenceType -ceq $EvidenceType -and
    [string]$journal.challengeSha256 -ceq $expectedChallenge -and
    [string]$journal.sessionId -ceq [string]$receipt.sessionId -and
    [string]$journal.previousJournalHeadSha256 -ceq
      [string]$receipt.previousJournalHeadSha256 -and
    [string]$journal.receipt.path -ceq $AuthoritativeReceiptPath -and
    [string]$journal.receipt.sha256 -ceq $AuthoritativeReceiptSha256 -and
    [int64]$journal.receipt.bytes -eq $AuthoritativeReceiptBytes -and
    [string]$journal.status -ceq 'committed'
  ) 'authoritative capture journal receipt, challenge or chain binding changed.'
}
Assert-C34LAttestation ($CaptureManifestPath -ceq $expectedCapture) `
  'capture manifest is not the exact immutable candidate owner.'
$captureFile = Resolve-C34LRelative $CaptureManifestPath 'capture manifest'
Assert-C34LAttestation (
  $CaptureManifestSha256 -cmatch '^[0-9A-F]{64}$' -and
  (Get-C34LSha $captureFile) -ceq $CaptureManifestSha256 -and
  $CaptureManifestBytes -gt 0 -and
  (Get-Item -LiteralPath $captureFile).Length -eq $CaptureManifestBytes
) 'capture manifest SHA-256 or byte-length binding changed.'
$captureRaw = Get-Content -Raw -LiteralPath $captureFile
try { $capture = $captureRaw | ConvertFrom-Json } catch {
  throw 'C34L source-attestation writer rejected: capture manifest is not valid JSON.'
}
Write-Verbose 'c34l-attestation-writer-progress=capture-loaded'
$captureNames = @(
  'schemaVersion','captureContractId','evidenceType','ticketId','attempt',
  'packageName','versionName','versionCode','preStateSha256',
  'preAggregateSha256','actionCounts','releaseAuthorities','artifactSha256',
  'artifactBytes','sourceProducerId','sessionId','nonceSha256','producedUtc',
  'expiresUtc','captureDigests','captureArtifactContractPath',
  'captureArtifactContractSha256','captureArtifactContractId','captureArtifacts'
)
Assert-C34LExactNames $capture $captureNames 'capture manifest'
Assert-C34LExactNames $capture.captureDigests $spec.Digests `
  'capture manifest digests'
Write-Verbose 'c34l-attestation-writer-progress=capture-privacy-start'
Assert-C34LPrivacy $capture 'capture manifest'
Write-Verbose 'c34l-attestation-writer-progress=capture-privacy-complete'
Assert-C34LPrivacy $capture.captureDigests 'capture manifest digests'
Assert-C34LAttestation ([int]$capture.schemaVersion -eq 1) `
  'capture field schemaVersion changed.'
Assert-C34LAttestation (
  [string]$capture.captureContractId -ceq $captureContractId
) 'capture field captureContractId changed.'
Assert-C34LAttestation ([string]$capture.evidenceType -ceq $EvidenceType) `
  'capture field evidenceType changed.'
Assert-C34LAttestation ([string]$capture.ticketId -ceq $ticketId) `
  'capture field ticketId changed.'
Assert-C34LAttestation ([int]$capture.attempt -eq $Attempt) `
  'capture field attempt changed.'
Assert-C34LAttestation ([string]$capture.packageName -ceq $packageName) `
  'capture field packageName changed.'
Assert-C34LAttestation ([string]$capture.versionName -ceq $versionName) `
  'capture field versionName changed.'
Assert-C34LAttestation ([string]$capture.versionCode -ceq $versionCode) `
  'capture field versionCode changed.'
Assert-C34LAttestation ([string]$capture.preStateSha256 -ceq $stateSha) `
  'capture field preStateSha256 changed.'
Assert-C34LAttestation (
  [string]$capture.preAggregateSha256 -ceq $aggregateSha
) 'capture field preAggregateSha256 changed.'
Assert-C34LAttestation (
  [string]$capture.artifactSha256 -ceq
    [string]$state.buildResult.artifactSha256
) 'capture field artifactSha256 changed.'
Assert-C34LAttestation (
  [int64]$capture.artifactBytes -eq [int64]$state.buildResult.artifactBytes
) 'capture field artifactBytes changed.'
Assert-C34LAttestation (
  [string]$capture.sourceProducerId -ceq $expectedCaptureProducer
) 'capture field sourceProducerId contract class changed.'
Assert-C34LAttestation (
  (($receiptMode -and
    [string]$capture.sessionId -ceq [string]$receipt.sessionId) -or
   (-not $receiptMode -and
    [string]$capture.sessionId -cmatch '^[a-z0-9][a-z0-9_-]{15,95}$'))
) 'capture field sessionId contract class changed.'
Assert-C34LAttestation (
  (($receiptMode -and
    [string]$capture.nonceSha256 -ceq [string]$receipt.challengeSha256) -or
   (-not $receiptMode -and
    [string]$capture.nonceSha256 -cmatch '^[0-9A-F]{64}$'))
) 'capture field nonceSha256 contract class changed.'
Assert-C34LVector $capture $spec.Counts $spec.Authorities 'capture manifest'
foreach ($name in $spec.Digests) {
  Assert-C34LAttestation (
    [string]$capture.captureDigests.$name -cmatch '^[0-9A-F]{64}$'
  ) "capture manifest digest changed at $name."
}
Write-Verbose 'c34l-attestation-writer-progress=capture-artifacts-start'
Assert-C34LCaptureArtifacts $capture $spec $expectedEvidenceRoot
Write-Verbose 'c34l-attestation-writer-progress=capture-artifacts-complete'
$produced = ConvertTo-C34LUtc $capture.producedUtc 'producedUtc'
$expires = ConvertTo-C34LUtc $capture.expiresUtc 'expiresUtc'
Assert-C34LRawUtcToken $captureRaw 'producedUtc' $produced
Assert-C34LRawUtcToken $captureRaw 'expiresUtc' $expires
$now = [DateTimeOffset]::UtcNow
Assert-C34LAttestation (
  $expires -gt $produced -and $expires -le $produced.AddMinutes(15) -and
  $produced -le $now.AddSeconds(30) -and $expires -gt $now.AddSeconds(-30)
) 'capture session is expired, premature or exceeds the 15-minute window.'

$targetRelative =
  "$expectedEvidenceRoot/attestations/source-attestation-$($spec.Short)-attempt-$Attempt.json"
$targetFile = Resolve-C34LRelative $targetRelative 'source attestation target' `
  -AllowMissing
$attestation = [pscustomobject][ordered]@{
  schemaVersion = 1; attestationContractId = $attestationContractId
  evidenceType = $EvidenceType; ticketId = $ticketId; attempt = $Attempt
  packageName = $packageName; versionName = $versionName
  versionCode = $versionCode; preStateSha256 = $stateSha
  preAggregateSha256 = $aggregateSha; actionCounts = $capture.actionCounts
  releaseAuthorities = $capture.releaseAuthorities
  artifactSha256 = [string]$capture.artifactSha256
  artifactBytes = [int64]$capture.artifactBytes
  sourceProducerId = [string]$capture.sourceProducerId
  sessionId = [string]$capture.sessionId
  nonceSha256 = [string]$capture.nonceSha256
  producedUtc = $produced.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture)
  expiresUtc = $expires.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture)
  captureManifestPath = $CaptureManifestPath
  captureManifestSha256 = $CaptureManifestSha256
  captureManifestBytes = $CaptureManifestBytes
  captureDigests = $capture.captureDigests
}
$json = ($attestation | ConvertTo-Json -Depth 20) + [Environment]::NewLine
Write-Verbose 'c34l-attestation-writer-progress=persistence-start'
$temporary = $targetFile + '.tmp-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
try {
  Assert-C34LAttestation (
    (Get-C34LSha $stateFile) -ceq $stateSha -and
    (Get-C34LSha $aggregateFile) -ceq $aggregateSha -and
    (Get-C34LSha $captureFile) -ceq $CaptureManifestSha256
  ) 'candidate or capture preimage changed before attestation persistence.'
  [IO.File]::WriteAllText($temporary, $json, $utf8)
  [IO.File]::Move($temporary, $targetFile)
} finally {
  if (Test-Path -LiteralPath $temporary -PathType Leaf) {
    Remove-Item -LiteralPath $temporary -Force
  }
}
$sha = Get-C34LSha $targetFile
$bytes = (Get-Item -LiteralPath $targetFile).Length
Write-Verbose 'c34l-attestation-writer-progress=persistence-complete'
Assert-C34LAttestation ($sha -cmatch '^[0-9A-F]{64}$' -and $bytes -gt 0) `
  'persisted attestation identity is invalid.'
Write-Output (([pscustomobject][ordered]@{
  ticketId=$ticketId; attempt=$Attempt; evidenceType=$EvidenceType
  path=$targetRelative; sha256=$sha; bytes=$bytes
  sourceProducerId=[string]$capture.sourceProducerId
  sessionId=[string]$capture.sessionId; nonceSha256=[string]$capture.nonceSha256
  preStateSha256=$stateSha; preAggregateSha256=$aggregateSha
  externalActionsPerformed=0; secretOrPrivateValuesRecorded=$false
}) | ConvertTo-Json -Compress)
