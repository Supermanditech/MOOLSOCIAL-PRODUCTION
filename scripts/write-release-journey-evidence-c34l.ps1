[CmdletBinding(DefaultParameterSetName='ProductionReceipt')]
param(
  [ValidateRange(1, 5)]
  [int]$Attempt = 1,
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34l.json',
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$PublicGuestJourneyPassed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$ProtectedGatewayJourneyPassed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$SupportedAuthenticationJourneysPassed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$SocialJourneysPassed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$WholeAppJourneysPassed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$C33gBlockerJourneysPassed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$AllMandatoryJourneysPassed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$EvidenceComplete,
  [ValidateRange(0, 1000)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$NewIssueCount = 0,
  [ValidateRange(0, 1000)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$NewDefectCount = 0,
  [ValidateRange(0, 1000)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$BlankScreenCount = 0,
  [ValidateRange(0, 1000)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$FlutterFatalErrorCount = 0,
  [ValidateRange(0, 1000)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$AndroidRuntimeFatalCount = 0,
  [ValidateRange(0, 1000)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$AnrCount = 0,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$AcceptanceSucceeded,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$SuccessClaimed,
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
$deviceBindingSha256 =
  '97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF'
$deviceModel = 'CPH2375'
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

function Assert-C34LJourneyWriter([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34L journey evidence writer rejected: $Message"
  }
}
function Resolve-C34LJourneyRelative(
  [string]$Path,
  [string]$Label,
  [switch]$AllowMissing
) {
  Assert-C34LJourneyWriter (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LJourneyWriter (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) "$Label escaped the production repository."
  $current = if (Test-Path -LiteralPath $resolved) {
    $resolved
  } else {
    Split-Path -Parent $resolved
  }
  while ($true) {
    Assert-C34LJourneyWriter (
      $current.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
      $current.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) "$Label ancestor escaped the production repository."
    Assert-C34LJourneyWriter (Test-Path -LiteralPath $current) `
      "$Label ancestor is missing."
    Assert-C34LJourneyWriter (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $current = Split-Path -Parent $current
  }
  if (-not $AllowMissing) {
    Assert-C34LJourneyWriter (Test-Path -LiteralPath $resolved -PathType Leaf) `
      "$Label is missing."
    Assert-C34LJourneyWriter (
      -not ((Get-Item -LiteralPath $resolved -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label must not be a reparse point."
  }
  return $resolved
}
function Get-C34LJourneyRelative([string]$Resolved) {
  $full = [IO.Path]::GetFullPath($Resolved)
  Assert-C34LJourneyWriter (
    $full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) 'resolved path escaped the production repository.'
  return $full.Substring($rootPrefix.Length).Replace('\', '/')
}
function Assert-C34LJourneyDirectory([string]$Path, [string]$Label) {
  Assert-C34LJourneyWriter (Test-Path -LiteralPath $Path -PathType Container) `
    "$Label is missing."
  $current = [IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\', '/'))
  while ($current.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
    Assert-C34LJourneyWriter (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $parent = Split-Path -Parent $current
    Assert-C34LJourneyWriter (-not [string]::IsNullOrWhiteSpace($parent)) `
      "$Label parent chain is incomplete."
    $current = $parent.TrimEnd([char[]]@('\', '/'))
  }
}
function Assert-C34LJourneyProperties($Value, [string]$Label, [string[]]$Names) {
  foreach ($name in $Names) {
    Assert-C34LJourneyWriter ($null -ne $Value.PSObject.Properties[$name]) `
      "$Label is missing property $name."
  }
}
function Assert-C34LJourneyExactNames($Value, [string]$Label, [string[]]$Names) {
  $actual = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LJourneyWriter ($actual.Count -eq $Names.Count) `
    "$Label property count changed."
  foreach ($name in $Names) {
    Assert-C34LJourneyWriter ($actual -ccontains $name) `
      "$Label is missing or has an unknown property at $name."
  }
}
function Assert-C34LJourneyPrivacy(
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
    Assert-C34LJourneyWriter (-not [regex]::IsMatch([string]$Value,$forbiddenValue)) `
      "$Label contains a forbidden private value at $PropertyPath."
    return
  }
  if ($Value -is [Collections.IEnumerable] -and
      $Value -isnot [Management.Automation.PSCustomObject] -and
      $Value -isnot [Collections.IDictionary]) {
    $index=0
    foreach($item in $Value){
      Assert-C34LJourneyPrivacy $item $Label "$PropertyPath[$index]"
      $index++
    }
    return
  }
  if ($Value -isnot [Management.Automation.PSCustomObject] -and
      $Value -isnot [Collections.IDictionary]) {
    Assert-C34LJourneyWriter (
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
    Assert-C34LJourneyWriter (
      $schemaNameAllowed -or -not [regex]::IsMatch($property.Name,$forbiddenName)
    ) `
      "$Label contains forbidden private property $($property.Name)."
    Assert-C34LJourneyPrivacy $property.Value $Label `
      "$PropertyPath.$($property.Name)"
  }
}
function ConvertTo-C34LJourneyUtc($Value, [string]$Label) {
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
  Assert-C34LJourneyWriter (
    $ok -and $parsed.ToUniversalTime().Offset -eq [TimeSpan]::Zero
  ) "$Label must be canonical UTC with milliseconds."
  return $parsed.ToUniversalTime()
}
function Assert-C34LJourneyRawUtc(
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
  Assert-C34LJourneyWriter (
    $matches.Count -eq 1 -and $matches[0].Groups[1].Value -ceq $canonical
  ) "$Name raw JSON token is not one exact canonical UTC string."
}
function Get-C34LJourneySha([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}
function ConvertTo-C34LJourneyRows($Parsed, [string]$Label) {
  Assert-C34LJourneyWriter ($null -ne $Parsed -and $Parsed -is [Array]) `
    "$Label must be one top-level JSON array."
  $rows=[Collections.Generic.List[object]]::new()
  foreach($item in [Array]$Parsed){ [void]$rows.Add($item) }
  return $rows.ToArray()
}
function Assert-C34LJourneyVector($State, $Aggregate) {
  $expectedCounts = @(1, 1, 1, 0, 0, 0, 0, 0)
  $expectedAuthorities = @(
    'consumed', 'consumed', 'consumed',
    'held_postinstall_journey_qualification'
  )
  for ($index = 0; $index -lt $countNames.Count; $index++) {
    $name = $countNames[$index]
    Assert-C34LJourneyWriter (
      $null -ne $State.actionCounts.PSObject.Properties[$name] -and
      $null -ne $Aggregate.actionCounts.PSObject.Properties[$name] -and
      [int]$State.actionCounts.$name -eq $expectedCounts[$index] -and
      [int]$Aggregate.actionCounts.$name -eq $expectedCounts[$index]
    ) "journey preimage action count changed at $name."
  }
  for ($index = 0; $index -lt $authorityNames.Count; $index++) {
    $name = $authorityNames[$index]
    Assert-C34LJourneyWriter (
      $null -ne $State.releaseAuthorities.PSObject.Properties[$name] -and
      $null -ne $Aggregate.releaseAuthorities.PSObject.Properties[$name] -and
      [string]$State.releaseAuthorities.$name -ceq $expectedAuthorities[$index] -and
      [string]$Aggregate.releaseAuthorities.$name -ceq $expectedAuthorities[$index]
    ) "journey preimage release authority changed at $name."
  }
}
function Write-C34LJourneyImmutableJson([string]$Target, [string]$Text) {
  Assert-C34LJourneyWriter (-not (Test-Path -LiteralPath $Target)) `
    'the immutable journey evidence owner already exists.'
  $parent = Split-Path -Parent $Target
  Assert-C34LJourneyDirectory $parent 'journey evidence directory'
  $temporary = $Target + '.tmp-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
  try {
    [IO.File]::WriteAllText($temporary, $Text, $utf8)
    Assert-C34LJourneyWriter ((Get-Item -LiteralPath $temporary).Length -gt 0) `
      'journey evidence temporary write was incomplete.'
    [IO.File]::Move($temporary, $Target)
  } finally {
    if (Test-Path -LiteralPath $temporary -PathType Leaf) {
      Remove-Item -LiteralPath $temporary -Force
    }
  }
  Assert-C34LJourneyWriter (Test-Path -LiteralPath $Target -PathType Leaf) `
    'journey evidence immutable move was incomplete.'
}
function Read-C34LJourneyCaptureArtifacts(
  [string]$CaptureFile,
  [string]$ExpectedEvidenceRoot,
  $Attestation,
  $State
) {
  $contractFile=Resolve-C34LJourneyRelative $captureArtifactContractPath `
    'capture-artifact contract'
  Assert-C34LJourneyWriter (
    (Get-C34LJourneySha $contractFile) -ceq $captureArtifactContractSha256
  ) 'capture-artifact contract SHA-256 changed.'
  $contract=Get-Content -Raw -LiteralPath $contractFile | ConvertFrom-Json
  Assert-C34LJourneyExactNames $contract 'capture-artifact contract' @(
    'schemaVersion','contractId','ticketId','productionProducer',
    'authoritativeReceipt','captureAttemptRootPattern',
    'captureManifestPathPattern','captureArtifactPathPattern',
    'captureArtifactFields','mediaType','evidenceTypes','deviceBinding','privacy'
  )
  Assert-C34LJourneyWriter (
    [int]$contract.schemaVersion -eq 3 -and
    [string]$contract.contractId -ceq $captureArtifactContractId -and
    [string]$contract.mediaType -ceq 'application/json' -and
    [string]$contract.deviceBinding.expectedSha256 -ceq $deviceBindingSha256
  ) 'capture-artifact contract or device binding identity changed.'
  $capture=Get-Content -Raw -LiteralPath $CaptureFile | ConvertFrom-Json
  Assert-C34LJourneyExactNames $capture 'journey capture manifest' @(
    'schemaVersion','captureContractId','evidenceType','ticketId','attempt',
    'packageName','versionName','versionCode','preStateSha256',
    'preAggregateSha256','actionCounts','releaseAuthorities','artifactSha256',
    'artifactBytes','sourceProducerId','sessionId','nonceSha256','producedUtc',
    'expiresUtc','captureDigests','captureArtifactContractPath',
    'captureArtifactContractSha256','captureArtifactContractId','captureArtifacts'
  )
  Assert-C34LJourneyPrivacy $capture 'journey capture manifest'
  Assert-C34LJourneyWriter (
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
    [string]$capture.sourceProducerId -ceq [string]$Attestation.sourceProducerId -and
    [string]$capture.sessionId -ceq [string]$Attestation.sessionId -and
    [string]$capture.nonceSha256 -ceq [string]$Attestation.nonceSha256
  ) 'journey capture-manifest contract, preimage or session changed.'
  $artifacts=@($capture.captureArtifacts)
  Assert-C34LJourneyWriter (
    $artifacts.Count -eq 1 -and
    [string]$artifacts[0].role -ceq 'journey_acceptance_manifest'
  ) 'journey capture-artifact role set changed.'
  $manifestBinding=$artifacts[0]
  Assert-C34LJourneyExactNames $manifestBinding 'journey capture artifact' @(
    'role','path','sha256','bytes','mediaType'
  )
  $manifestPath=
    "$ExpectedEvidenceRoot/captures/attempt-$Attempt/journey/journey-acceptance-manifest.json"
  Assert-C34LJourneyWriter (
    [string]$manifestBinding.path -ceq $manifestPath -and
    [string]$manifestBinding.mediaType -ceq 'application/json' -and
    [string]$manifestBinding.sha256 -cmatch '^[0-9A-F]{64}$' -and
    [int64]$manifestBinding.bytes -gt 0
  ) 'journey acceptance-manifest artifact binding changed.'
  $manifestFile=Resolve-C34LJourneyRelative ([string]$manifestBinding.path) `
    'journey acceptance-manifest artifact'
  Assert-C34LJourneyWriter (
    (Get-C34LJourneySha $manifestFile) -ceq [string]$manifestBinding.sha256 -and
    (Get-Item -LiteralPath $manifestFile).Length -eq [int64]$manifestBinding.bytes
  ) 'journey acceptance-manifest artifact SHA-256 or bytes changed.'
  $parsedRows=Get-Content -Raw -LiteralPath $manifestFile | ConvertFrom-Json
  $rows=@(ConvertTo-C34LJourneyRows $parsedRows `
    'journey acceptance manifest')
  $journeyIds=@(
    'publicGuest','protectedGateway','supportedAuthentication','social',
    'wholeApp','c33gBlocker'
  )
  Assert-C34LJourneyWriter (
    $rows.Count -eq $journeyIds.Count -and
    @($rows.journeyId | Select-Object -Unique).Count -eq $rows.Count -and
    (@($rows.journeyId) -join ',') -ceq (@($journeyIds) -join ',')
  ) 'journey acceptance-manifest row set changed.'
  $rowFiles=@()
  $values=@{}
  foreach($row in $rows){
    Assert-C34LJourneyExactNames $row 'journey acceptance-manifest row' @(
      'journeyId','path','sha256','bytes','passed'
    )
    $journeyId=[string]$row.journeyId
    $expectedPath=
      "$ExpectedEvidenceRoot/captures/attempt-$Attempt/journey/journeys/$journeyId.json"
    Assert-C34LJourneyWriter (
      [bool]$row.passed -and [string]$row.path -ceq $expectedPath -and
      [string]$row.sha256 -cmatch '^[0-9A-F]{64}$' -and [int64]$row.bytes -gt 0
    ) "journey capture row path or result changed at $journeyId."
    $rowFile=Resolve-C34LJourneyRelative ([string]$row.path) `
      "journey capture artifact $journeyId"
    Assert-C34LJourneyWriter (
      (Get-C34LJourneySha $rowFile) -ceq [string]$row.sha256 -and
      (Get-Item -LiteralPath $rowFile).Length -eq [int64]$row.bytes
    ) "journey capture artifact SHA-256 or bytes changed at $journeyId."
    $value=Get-Content -Raw -LiteralPath $rowFile | ConvertFrom-Json
    Assert-C34LJourneyPrivacy $value "journey capture artifact $journeyId"
    Assert-C34LJourneyExactNames $value "journey capture artifact $journeyId" @(
      'schemaVersion','journeyId','ticketId','attempt','packageName',
      'versionName','versionCode','artifactSha256','artifactBytes',
      'deviceBindingSha256','passed','newIssueCount','newDefectCount',
      'blankScreenCount','flutterFatalErrorCount','androidRuntimeFatalCount',
      'anrCount','sourceProducerId','sessionId','nonceSha256'
    )
    Assert-C34LJourneyWriter (
      [int]$value.schemaVersion -eq 1 -and
      [string]$value.journeyId -ceq $journeyId -and
      [string]$value.ticketId -ceq $ticketId -and [int]$value.attempt -eq $Attempt -and
      [string]$value.packageName -ceq $packageName -and
      [string]$value.versionName -ceq $versionName -and
      [string]$value.versionCode -ceq $versionCode -and
      [string]$value.artifactSha256 -ceq [string]$State.buildResult.artifactSha256 -and
      [int64]$value.artifactBytes -eq [int64]$State.buildResult.artifactBytes -and
      [string]$value.deviceBindingSha256 -ceq $deviceBindingSha256 -and
      [bool]$value.passed -and [int]$value.newIssueCount -eq 0 -and
      [int]$value.newDefectCount -eq 0 -and [int]$value.blankScreenCount -eq 0 -and
      [int]$value.flutterFatalErrorCount -eq 0 -and
      [int]$value.androidRuntimeFatalCount -eq 0 -and [int]$value.anrCount -eq 0 -and
      [string]$value.sourceProducerId -ceq [string]$Attestation.sourceProducerId -and
      [string]$value.sessionId -ceq [string]$Attestation.sessionId -and
      [string]$value.nonceSha256 -ceq [string]$Attestation.nonceSha256
    ) "journey authoritative capture payload changed at $journeyId."
    $digestName=$journeyId + 'DigestSha256'
    Assert-C34LJourneyWriter (
      $null -ne $capture.captureDigests.PSObject.Properties[$digestName] -and
      [string]$capture.captureDigests.$digestName -ceq [string]$row.sha256
    ) "journey capture digest is not bound at $journeyId."
    $rowFiles += [pscustomobject]@{File=$rowFile;Sha256=[string]$row.sha256}
    $values[$journeyId]=$value
  }
  return [pscustomobject]@{
    Rows=$rows; ManifestFile=$manifestFile
    ManifestSha256=[string]$manifestBinding.sha256; RowFiles=$rowFiles
    Values=$values
  }
}

$receiptMode = $PSCmdlet.ParameterSetName -cin @(
  'ProductionReceipt','FixtureReceipt'
)
if (-not $receiptMode) {
Assert-C34LJourneyWriter (
  [bool]$PublicGuestJourneyPassed -and
  [bool]$ProtectedGatewayJourneyPassed -and
  [bool]$SupportedAuthenticationJourneysPassed -and
  [bool]$SocialJourneysPassed -and [bool]$WholeAppJourneysPassed -and
  [bool]$C33gBlockerJourneysPassed -and [bool]$AllMandatoryJourneysPassed -and
  [bool]$EvidenceComplete -and [bool]$AcceptanceSucceeded -and
  [bool]$SuccessClaimed -and $NewIssueCount -eq 0 -and
  $NewDefectCount -eq 0 -and $BlankScreenCount -eq 0 -and
  $FlutterFatalErrorCount -eq 0 -and $AndroidRuntimeFatalCount -eq 0 -and
  $AnrCount -eq 0
) 'complete defect-free mandatory journey acceptance is required.'
}

$stateFile = Resolve-C34LJourneyRelative $StatePath 'detailed candidate state'
$stateRelative = Get-C34LJourneyRelative $stateFile
if ($FixtureMode) {
  Assert-C34LJourneyWriter (
    $stateRelative -cmatch
      '^tmp/(c34l-retained-evidence-fixtures-[0-9A-Za-z_-]+|c34l-authoritative-capture-fixtures-[0-9a-f]{32})/state[.]json$'
  ) 'fixture state is outside the exact C34L evidence-producer root.'
  $fixtureRoot = (Split-Path -Parent $stateRelative).Replace('\', '/')
  $expectedEvidenceRoot = "$fixtureRoot/evidence"
} else {
  Assert-C34LJourneyWriter (
    $stateRelative -ceq 'config/successor-aab-regression-hard-gate-state-c34l.json'
  ) 'production writing requires the exact C34L detailed state.'
  $expectedEvidenceRoot = $productionEvidenceRoot
}
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C34LJourneyProperties $state 'detailed candidate state' @(
  'ticketId', 'candidate', 'aggregateStatePath', 'machineState', 'evidenceRoot',
  'actionCounts', 'releaseAuthorities', 'buildResult'
)
$aggregateFile = Resolve-C34LJourneyRelative ([string]$state.aggregateStatePath) `
  'aggregate candidate state'
$aggregateRelative = Get-C34LJourneyRelative $aggregateFile
if ($FixtureMode) {
  Assert-C34LJourneyWriter ($aggregateRelative -ceq "$fixtureRoot/aggregate.json") `
    'fixture aggregate escaped the exact fixture root.'
} else {
  Assert-C34LJourneyWriter (
    $aggregateRelative -ceq
      'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
  ) 'production writing requires the exact C34L aggregate state.'
}
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
Assert-C34LJourneyProperties $aggregate 'aggregate candidate state' @(
  'ticketId', 'candidate', 'machineState', 'actionCounts', 'releaseAuthorities'
)
Assert-C34LJourneyWriter (
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
  [string]$state.candidate.deviceBindingSha256 -ceq $deviceBindingSha256 -and
  [string]$state.candidate.deviceModel -ceq $deviceModel -and
  [string]$state.machineState -ceq
    'oppo_play_in_place_update_succeeded_postinstall_acceptance_held' -and
  [string]$aggregate.machineState -ceq [string]$state.machineState -and
  [string]$state.evidenceRoot -ceq $expectedEvidenceRoot
) 'candidate identity, phase, device or evidence root changed.'
Assert-C34LJourneyVector $state $aggregate
Assert-C34LJourneyProperties $state.buildResult 'build result' @(
  'artifactPath', 'artifactSha256', 'artifactBytes'
)
$artifactFile = Resolve-C34LJourneyRelative ([string]$state.buildResult.artifactPath) `
  'sealed C34L AAB'
$expectedArtifact =
  "$expectedEvidenceRoot/MoolSocial-$versionName-$versionCode-release.aab"
Assert-C34LJourneyWriter (
  [string]$state.buildResult.artifactPath -ceq $expectedArtifact -and
  [string]$state.buildResult.artifactSha256 -cmatch '^[0-9A-F]{64}$' -and
  (Get-C34LJourneySha $artifactFile) -ceq
    [string]$state.buildResult.artifactSha256 -and
  (Get-Item -LiteralPath $artifactFile).Length -eq
    [int64]$state.buildResult.artifactBytes -and
  [int64]$state.buildResult.artifactBytes -gt 0
) 'sealed artifact path, SHA-256 or byte length changed.'

$stateSha = Get-C34LJourneySha $stateFile
$aggregateSha = Get-C34LJourneySha $aggregateFile
$expectedAttestation =
  "$expectedEvidenceRoot/attestations/source-attestation-journey-attempt-$Attempt.json"
if ($receiptMode) {
  $expectedReceipt =
    "$expectedEvidenceRoot/captures/attempt-$Attempt/journey/authoritative-capture-receipt.json"
  Assert-C34LJourneyWriter (
    $AuthoritativeReceiptPath -ceq $expectedReceipt -and
    $AuthoritativeReceiptSha256 -cmatch '^[0-9A-F]{64}$' -and
    $AuthoritativeReceiptBytes -gt 0
  ) 'exact authoritative journey receipt path, SHA-256 and bytes are required.'
  $receiptFile=Resolve-C34LJourneyRelative $AuthoritativeReceiptPath `
    'authoritative journey receipt'
  Assert-C34LJourneyWriter (
    (Get-C34LJourneySha $receiptFile) -ceq $AuthoritativeReceiptSha256 -and
    (Get-Item -LiteralPath $receiptFile).Length -eq $AuthoritativeReceiptBytes
  ) 'authoritative journey receipt SHA-256 or bytes changed.'
  $receipt=Get-Content -Raw -LiteralPath $receiptFile|ConvertFrom-Json
  Assert-C34LJourneyWriter (
    [string]$receipt.receiptContractId -ceq
      'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-RECEIPT-001' -and
    [string]$receipt.producerId -ceq $authoritativeProducerId -and
    [string]$receipt.evidenceType -ceq
      'mandatory_whole_app_journey_acceptance' -and
    [string]$receipt.ticketId -ceq $ticketId -and
    [int]$receipt.attempt -eq $Attempt -and
    [string]$receipt.detailedState.sha256 -ceq $stateSha -and
    [string]$receipt.aggregateState.sha256 -ceq $aggregateSha -and
    [string]$receipt.artifact.sha256 -ceq
      [string]$state.buildResult.artifactSha256
  ) 'authoritative journey receipt identity or preimage changed.'
  $SourceAttestationPath=$expectedAttestation
  $derivedSource=Resolve-C34LJourneyRelative $SourceAttestationPath `
    'derived journey source attestation'
  $SourceAttestationSha256=Get-C34LJourneySha $derivedSource
  $SourceAttestationBytes=[int64](Get-Item -LiteralPath $derivedSource).Length
}
Assert-C34LJourneyWriter (
  $SourceAttestationPath -ceq $expectedAttestation -and
  $SourceAttestationSha256 -cmatch '^[0-9A-F]{64}$' -and
  $SourceAttestationBytes -gt 0
) 'exact source-attestation path, SHA-256 and bytes are required.'
$attestationFile = Resolve-C34LJourneyRelative $SourceAttestationPath `
  'journey source attestation'
Assert-C34LJourneyWriter (
  (Get-C34LJourneySha $attestationFile) -ceq $SourceAttestationSha256 -and
  (Get-Item -LiteralPath $attestationFile).Length -eq $SourceAttestationBytes
) 'journey source-attestation SHA-256 or bytes changed.'
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
  'publicGuestDigestSha256','protectedGatewayDigestSha256',
  'supportedAuthenticationDigestSha256','socialDigestSha256',
  'wholeAppDigestSha256','c33gBlockerDigestSha256'
)
Assert-C34LJourneyExactNames $attestation 'journey source attestation' `
  $attestationNames
Assert-C34LJourneyExactNames $attestation.captureDigests `
  'journey source-attestation digests' $digestNames
Assert-C34LJourneyWriter (
  [int]$attestation.schemaVersion -eq 1 -and
  [string]$attestation.attestationContractId -ceq
    'MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001' -and
  [string]$attestation.evidenceType -ceq
    'mandatory_whole_app_journey_acceptance' -and
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
    'MOOLSOCIAL-C34L-JOURNEY-CAPTURE-PRODUCER-001'
  }) -and
  [string]$attestation.sessionId -cmatch '^[a-z0-9][a-z0-9_-]{15,95}$' -and
  [string]$attestation.nonceSha256 -cmatch '^[0-9A-F]{64}$'
) 'journey source attestation has wrong type, identity, preimage, artifact or session.'
Assert-C34LJourneyVector $attestation $attestation
foreach ($name in $digestNames) {
  Assert-C34LJourneyWriter (
    [string]$attestation.captureDigests.$name -cmatch '^[0-9A-F]{64}$'
  ) "journey source-attestation digest changed at $name."
}
$produced = ConvertTo-C34LJourneyUtc $attestation.producedUtc `
  'producedUtc'
$expires = ConvertTo-C34LJourneyUtc $attestation.expiresUtc `
  'expiresUtc'
Assert-C34LJourneyRawUtc $attestationRaw 'producedUtc' $produced
Assert-C34LJourneyRawUtc $attestationRaw 'expiresUtc' $expires
Assert-C34LJourneyWriter (
  $expires -gt $produced -and $expires -le $produced.AddMinutes(15) -and
  $expires -gt [DateTimeOffset]::UtcNow.AddSeconds(-30)
) 'journey source-attestation session is expired or invalid.'
$captureFile = Resolve-C34LJourneyRelative `
  ([string]$attestation.captureManifestPath) 'journey capture manifest'
Assert-C34LJourneyWriter (
  [string]$attestation.captureManifestPath -ceq
    "$expectedEvidenceRoot/captures/attempt-$Attempt/journey/capture-manifest.json" -and
  [string]$attestation.captureManifestSha256 -cmatch '^[0-9A-F]{64}$' -and
  (Get-C34LJourneySha $captureFile) -ceq
    [string]$attestation.captureManifestSha256 -and
  [int64]$attestation.captureManifestBytes -gt 0 -and
  (Get-Item -LiteralPath $captureFile).Length -eq
    [int64]$attestation.captureManifestBytes
) 'journey capture-manifest binding changed.'
$captureValues=Read-C34LJourneyCaptureArtifacts $captureFile `
  $expectedEvidenceRoot $attestation $state
$allCapturedPassed=@($captureValues.Rows | Where-Object { -not [bool]$_.passed }).Count -eq 0
if ($receiptMode) {
  $PublicGuestJourneyPassed=[bool]$captureValues.Values.publicGuest.passed
  $ProtectedGatewayJourneyPassed=[bool]$captureValues.Values.protectedGateway.passed
  $SupportedAuthenticationJourneysPassed=
    [bool]$captureValues.Values.supportedAuthentication.passed
  $SocialJourneysPassed=[bool]$captureValues.Values.social.passed
  $WholeAppJourneysPassed=[bool]$captureValues.Values.wholeApp.passed
  $C33gBlockerJourneysPassed=[bool]$captureValues.Values.c33gBlocker.passed
  $AllMandatoryJourneysPassed=$allCapturedPassed
  $EvidenceComplete=$allCapturedPassed;$AcceptanceSucceeded=$allCapturedPassed
  $SuccessClaimed=$allCapturedPassed
  $NewIssueCount=0;$NewDefectCount=0;$BlankScreenCount=0
  $FlutterFatalErrorCount=0;$AndroidRuntimeFatalCount=0;$AnrCount=0
} else {
Assert-C34LJourneyWriter (
  [bool]$PublicGuestJourneyPassed -eq
    [bool]$captureValues.Values.publicGuest.passed -and
  [bool]$ProtectedGatewayJourneyPassed -eq
    [bool]$captureValues.Values.protectedGateway.passed -and
  [bool]$SupportedAuthenticationJourneysPassed -eq
    [bool]$captureValues.Values.supportedAuthentication.passed -and
  [bool]$SocialJourneysPassed -eq [bool]$captureValues.Values.social.passed -and
  [bool]$WholeAppJourneysPassed -eq [bool]$captureValues.Values.wholeApp.passed -and
  [bool]$C33gBlockerJourneysPassed -eq
    [bool]$captureValues.Values.c33gBlocker.passed -and
  [bool]$AllMandatoryJourneysPassed -eq $allCapturedPassed -and
  [bool]$EvidenceComplete -eq $allCapturedPassed -and
  [bool]$AcceptanceSucceeded -eq $allCapturedPassed -and
  [bool]$SuccessClaimed -eq $allCapturedPassed
) 'fixture journey result does not match the retained capture artifacts.'
}
$evidence = [pscustomobject][ordered]@{
  schemaVersion = 1
  evidenceContractId = 'MOOLSOCIAL-C34L-JOURNEY-EVIDENCE-001'
  evidenceType = 'mandatory_whole_app_journey_acceptance'
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
  deviceBindingSha256 = $deviceBindingSha256
  deviceModel = $deviceModel
  installerPackage = 'com.android.vending'
  publicGuestJourneyPassed = [bool]$captureValues.Values.publicGuest.passed
  protectedGatewayJourneyPassed = [bool]$captureValues.Values.protectedGateway.passed
  supportedAuthenticationJourneysPassed =
    [bool]$captureValues.Values.supportedAuthentication.passed
  socialJourneysPassed = [bool]$captureValues.Values.social.passed
  wholeAppJourneysPassed = [bool]$captureValues.Values.wholeApp.passed
  c33gBlockerJourneysPassed = [bool]$captureValues.Values.c33gBlocker.passed
  allMandatoryJourneysPassed = $allCapturedPassed
  evidenceComplete = $allCapturedPassed
  newIssueCount = [int]$captureValues.Values.wholeApp.newIssueCount
  newDefectCount = [int]$captureValues.Values.wholeApp.newDefectCount
  blankScreenCount = [int]$captureValues.Values.wholeApp.blankScreenCount
  flutterFatalErrorCount = [int]$captureValues.Values.wholeApp.flutterFatalErrorCount
  androidRuntimeFatalCount =
    [int]$captureValues.Values.wholeApp.androidRuntimeFatalCount
  anrCount = [int]$captureValues.Values.wholeApp.anrCount
  acceptanceSucceeded = $allCapturedPassed
  successClaimed = $allCapturedPassed
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
Assert-C34LJourneyWriter (-not [regex]::IsMatch(
  $json,
  'AIza[0-9A-Za-z_-]{35}|(?i)Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----|\b[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com\b'
)) 'generated evidence contains secret- or private-identifier-shaped material.'
$targetRelative =
  "$expectedEvidenceRoot/10-mandatory-whole-app-journey-evidence.json"
$targetFile = Resolve-C34LJourneyRelative $targetRelative `
  'mandatory journey evidence target' -AllowMissing
foreach($rowFile in $captureValues.RowFiles){
  Assert-C34LJourneyWriter (
    (Get-C34LJourneySha $rowFile.File) -ceq [string]$rowFile.Sha256
  ) 'journey capture artifact changed before evidence persistence.'
}
Assert-C34LJourneyWriter (
  (Get-C34LJourneySha $stateFile) -ceq $stateSha -and
  (Get-C34LJourneySha $aggregateFile) -ceq $aggregateSha -and
  (Get-C34LJourneySha $artifactFile) -ceq
    [string]$state.buildResult.artifactSha256 -and
  (Get-C34LJourneySha $attestationFile) -ceq $SourceAttestationSha256 -and
  (Get-C34LJourneySha $captureFile) -ceq
    [string]$attestation.captureManifestSha256 -and
  (Get-C34LJourneySha $captureValues.ManifestFile) -ceq
    [string]$captureValues.ManifestSha256
) 'candidate preimage or artifact changed before evidence persistence.'
Write-C34LJourneyImmutableJson $targetFile $json
$evidenceSha = Get-C34LJourneySha $targetFile
$evidenceBytes = (Get-Item -LiteralPath $targetFile).Length
Assert-C34LJourneyWriter (
  (Get-C34LJourneySha $stateFile) -ceq $stateSha -and
  (Get-C34LJourneySha $aggregateFile) -ceq $aggregateSha -and
  $evidenceSha -cmatch '^[0-9A-F]{64}$' -and $evidenceBytes -gt 0
) 'candidate preimage changed during persistence or evidence identity is invalid.'
Write-Output (([pscustomobject][ordered]@{
  ticketId = $ticketId
  attempt = $Attempt
  evidenceType = 'mandatory_whole_app_journey_acceptance'
  path = $targetRelative
  sha256 = $evidenceSha
  bytes = $evidenceBytes
  preStateSha256 = $stateSha
  preAggregateSha256 = $aggregateSha
  externalActionsPerformed = 0
  secretOrPrivateValuesRecorded = $false
}) | ConvertTo-Json -Compress)
