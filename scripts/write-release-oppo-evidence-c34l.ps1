[CmdletBinding(DefaultParameterSetName='ProductionReceipt')]
param(
  [ValidateRange(1, 5)]
  [int]$Attempt = 1,
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34l.json',
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$ColdStartInteractive,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$BlankHierarchy,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$Timeout,
  [ValidateRange(0, 1000)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$FlutterFatalErrorCount = 0,
  [ValidateRange(0, 1000)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$AndroidRuntimeFatalCount = 0,
  [ValidateRange(0, 1000)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [int]$AnrCount = 0,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$AppProcessErrorScanPassed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$ArtifactRelationshipProved,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$InPlaceUpdateProved,
  [ValidateRange(0, [long]::MaxValue)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [long]$FirstInstallTimeMillis = 0,
  [ValidateRange(0, [long]::MaxValue)]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [long]$LastUpdateTimeMillis = 0,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$FirstInstallTimePreserved,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$RetainedDataContinuityProved,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$InPlacePlayUpdateProved,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$UninstallPerformed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$DataClearPerformed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$DowngradePerformed,
  [Parameter(ParameterSetName='FixtureLegacy')][switch]$AdbInstallPerformed,
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
  [ValidateSet(
    'none', 'before-journal', 'prepared-none', 'cold-file-moved',
    'cold-moved', 'retained-file-moved', 'both-moved', 'committed'
  )]
  [Parameter(ParameterSetName='FixtureLegacy')]
  [string]$FixtureCrashBoundary = 'none',
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
$deviceModel = 'CPH2375'
$deviceBindingSha256 =
  '97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF'
$captureArtifactContractPath =
  'config/release-evidence-capture-artifact-contract-c34l.json'
$captureArtifactContractSha256 =
  'D7B8DE822D709F25CEB1AEFFFF4093260B3EFB83DCADE1F632309026ECC0B9D2'
$captureArtifactContractId =
  'MOOLSOCIAL-C34L-CAPTURE-ARTIFACT-CONTRACT-003'
$authoritativeProducerId =
  'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-PRODUCER-001'
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
$sourceBindingNames = @(
  'path','sha256','bytes','evidenceType','sourceProducerId','sessionId',
  'nonceSha256','producedUtc','expiresUtc','captureManifestPath',
  'captureManifestSha256','captureManifestBytes','captureDigests'
)
$oppoDigestNames = @(
  'packageStateDigestSha256','coldStartDigestSha256',
  'retainedDataDigestSha256'
)
$captureArtifactNames = @('role','path','sha256','bytes','mediaType')
$captureManifestNames = @(
  'schemaVersion','captureContractId','evidenceType','ticketId','attempt',
  'packageName','versionName','versionCode','preStateSha256',
  'preAggregateSha256','actionCounts','releaseAuthorities','artifactSha256',
  'artifactBytes','sourceProducerId','sessionId','nonceSha256','producedUtc',
  'expiresUtc','captureDigests','captureArtifactContractPath',
  'captureArtifactContractSha256','captureArtifactContractId',
  'captureArtifacts'
)
$capturePayloadCommonNames = @(
  'schemaVersion','captureArtifactContractId','evidenceType','role','ticketId',
  'attempt','packageName','versionName','versionCode','artifactSha256',
  'artifactBytes','deviceBindingSha256','deviceModel','installerPackage',
  'sourceProducerId','sessionId','nonceSha256'
)
$utf8 = [Text.UTF8Encoding]::new($false)

function Assert-C34LOppoWriter([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C34L OPPO evidence writer rejected: $Message" }
}
function Assert-C34LOppoExactNames($Value, [string]$Label, [string[]]$Names) {
  $actual = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LOppoWriter ($actual.Count -eq $Names.Count) `
    "$Label property count changed."
  foreach ($name in $Names) {
    Assert-C34LOppoWriter ($actual -ccontains $name) `
      "$Label is missing or has an unknown property at $name."
  }
}
function Assert-C34LOppoNoReparseChain([string]$Resolved, [string]$Label) {
  $current = if (Test-Path -LiteralPath $Resolved) {
    [IO.Path]::GetFullPath($Resolved)
  } else {
    [IO.Path]::GetFullPath((Split-Path -Parent $Resolved))
  }
  while ($true) {
    Assert-C34LOppoWriter (
      $current.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
      $current.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) "$Label ancestor escaped the production repository."
    Assert-C34LOppoWriter (Test-Path -LiteralPath $current) `
      "$Label ancestor is missing."
    Assert-C34LOppoWriter (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $parent = Split-Path -Parent $current
    Assert-C34LOppoWriter (-not [string]::IsNullOrWhiteSpace($parent)) `
      "$Label ancestor chain is incomplete."
    $current = [IO.Path]::GetFullPath($parent)
  }
}
function Resolve-C34LOppoRelative([string]$Path, [string]$Label, [switch]$AllowMissing) {
  Assert-C34LOppoWriter (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path) -and -not $Path.Contains('\') -and
    -not $Path.Contains('?') -and -not $Path.Contains('#')
  ) "$Label must be one normalized repository-relative path."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LOppoWriter (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) "$Label escaped the production repository."
  Assert-C34LOppoNoReparseChain $resolved $Label
  if (-not $AllowMissing) {
    Assert-C34LOppoWriter (Test-Path -LiteralPath $resolved -PathType Leaf) `
      "$Label is missing."
  }
  return $resolved
}
function Get-C34LOppoRelative([string]$Resolved) {
  $full = [IO.Path]::GetFullPath($Resolved)
  Assert-C34LOppoWriter (
    $full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) 'resolved path escaped the production repository.'
  return $full.Substring($rootPrefix.Length).Replace('\', '/')
}
function Assert-C34LOppoProperties($Value, [string]$Label, [string[]]$Names) {
  foreach ($name in $Names) {
    Assert-C34LOppoWriter ($null -ne $Value.PSObject.Properties[$name]) `
      "$Label is missing property $name."
  }
}
function Get-C34LOppoSha([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}
function Get-C34LOppoTextIdentity([string]$Text) {
  $bytes = $utf8.GetBytes($Text)
  $hasher = [Security.Cryptography.SHA256]::Create()
  try { $hashBytes = $hasher.ComputeHash($bytes) } finally { $hasher.Dispose() }
  return [pscustomobject][ordered]@{
    Sha256 = ([BitConverter]::ToString($hashBytes)).Replace('-', '')
    Bytes = [int64]$bytes.Length
  }
}
function ConvertTo-C34LOppoUtc([string]$Value, [string]$Label) {
  $parsed = [DateTimeOffset]::MinValue
  $ok = [DateTimeOffset]::TryParseExact(
    $Value, "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal,
    [ref]$parsed
  )
  Assert-C34LOppoWriter (
    $ok -and $parsed.Offset -eq [TimeSpan]::Zero -and
    $parsed.ToUniversalTime().ToString(
      "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
      [Globalization.CultureInfo]::InvariantCulture
    ) -ceq $Value
  ) "$Label must be canonical UTC with milliseconds."
  return $parsed.ToUniversalTime()
}
function Get-C34LOppoWireUtc(
  [string]$RawJson,
  [ValidateSet('producedUtc','expiresUtc','preparedUtc','committedUtc')]
  [string]$Name,
  [string]$Label
) {
  $pattern = '"' + $Name +
    '"\s*:\s*"([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[.][0-9]{3}Z)"'
  $matches = [regex]::Matches($RawJson, $pattern)
  Assert-C34LOppoWriter ($matches.Count -eq 1) `
    "$Label must contain one canonical $Name wire token."
  return [string]$matches[0].Groups[1].Value
}
function Get-C34LOppoRuntimeUtcText($Value, [string]$Label) {
  if ($Value -is [DateTimeOffset]) {
    $instant = ([DateTimeOffset]$Value).ToUniversalTime()
  } elseif ($Value -is [DateTime]) {
    $instant = [DateTimeOffset]::new(
      ([DateTime]$Value).ToUniversalTime(), [TimeSpan]::Zero
    )
  } else {
    $instant = ConvertTo-C34LOppoUtc ([string]$Value) $Label
  }
  return $instant.ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture
  )
}
function Assert-C34LOppoPrivacy($Value, [string]$Label) {
  $forbiddenName =
    '(?i)(email|phone|private|url|link|identifier|exception|stack|credential|secret|token|key|rawnonce|account|deviceserial|androidid|imei|imsi|advertisingid|^serial$)'
  $forbiddenValue =
    '(?i)([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|https?://|www\.|Bearer\s+|\+?[1-9][0-9][ -][0-9 ()-]{6,}[0-9]|AIza[0-9A-Za-z_-]{35}|-----BEGIN|Exception:|StackTrace)'
  $jwtValue =
    '^[A-Za-z0-9_-]{16,}[.][A-Za-z0-9_-]{16,}[.][A-Za-z0-9_-]{16,}$'
  if ($null -eq $Value) { return }
  if ($Value -is [System.Collections.IEnumerable] -and
      $Value -isnot [string] -and
      $Value -isnot [System.Management.Automation.PSCustomObject]) {
    $index = 0
    foreach ($item in @($Value)) {
      Assert-C34LOppoPrivacy $item "$Label[$index]"
      $index++
    }
    return
  }
  foreach ($property in @($Value.PSObject.Properties)) {
    $canonicalEmailCount =
      $property.Name -ceq 'passwordlessEmailSend' -and
      $Label.EndsWith('actionCounts', [StringComparison]::Ordinal)
    Assert-C34LOppoWriter (
      $canonicalEmailCount -or
      -not [regex]::IsMatch($property.Name, $forbiddenName)
    ) `
      "$Label contains forbidden private property $($property.Name)."
    if ($property.Value -is [System.Management.Automation.PSCustomObject] -or
        ($property.Value -is [System.Collections.IEnumerable] -and
         $property.Value -isnot [string])) {
      Assert-C34LOppoPrivacy $property.Value "$Label.$($property.Name)"
    } elseif ($null -ne $property.Value -and $property.Value -is [string]) {
      Assert-C34LOppoWriter (
        -not [regex]::IsMatch([string]$property.Value, $forbiddenValue) -and
        -not [regex]::IsMatch([string]$property.Value, $jwtValue)
      ) "$Label contains a forbidden private value shape."
    }
  }
}
function Assert-C34LOppoVector($State, $Aggregate) {
  $expectedCounts = @(1, 1, 0, 0, 0, 0, 0, 0)
  $expectedAuthorities = @(
    'consumed', 'consumed', 'available_once',
    'held_postinstall_journey_qualification'
  )
  for ($index = 0; $index -lt $countNames.Count; $index++) {
    $name = $countNames[$index]
    Assert-C34LOppoWriter (
      $null -ne $State.actionCounts.PSObject.Properties[$name] -and
      $null -ne $Aggregate.actionCounts.PSObject.Properties[$name] -and
      [int]$State.actionCounts.$name -eq $expectedCounts[$index] -and
      [int]$Aggregate.actionCounts.$name -eq $expectedCounts[$index]
    ) "OPPO preimage action count changed at $name."
  }
  for ($index = 0; $index -lt $authorityNames.Count; $index++) {
    $name = $authorityNames[$index]
    Assert-C34LOppoWriter (
      $null -ne $State.releaseAuthorities.PSObject.Properties[$name] -and
      $null -ne $Aggregate.releaseAuthorities.PSObject.Properties[$name] -and
      [string]$State.releaseAuthorities.$name -ceq $expectedAuthorities[$index] -and
      [string]$Aggregate.releaseAuthorities.$name -ceq $expectedAuthorities[$index]
    ) "OPPO preimage release authority changed at $name."
  }
}
function Write-C34LOppoAtomicText(
  [string]$Path,
  [string]$Text,
  [switch]$CreateOnly
) {
  $parent = Split-Path -Parent $Path
  Assert-C34LOppoNoReparseChain $parent 'atomic-write directory'
  $suffix = '.tmp-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
  $temporary = $Path + $suffix
  $backup = $Path + '.bak-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
  try {
    [IO.File]::WriteAllText($temporary, $Text, $utf8)
    Assert-C34LOppoWriter ((Get-Item -LiteralPath $temporary).Length -gt 0) `
      'atomic temporary write was incomplete.'
    if ($CreateOnly) {
      Assert-C34LOppoWriter (-not (Test-Path -LiteralPath $Path)) `
        'atomic create target already exists.'
      [IO.File]::Move($temporary, $Path)
    } else {
      Assert-C34LOppoWriter (Test-Path -LiteralPath $Path -PathType Leaf) `
        'atomic replace target is missing.'
      [IO.File]::Replace($temporary, $Path, $backup, $true)
      Assert-C34LOppoWriter (Test-Path -LiteralPath $backup -PathType Leaf) `
        'atomic replace backup was not retained.'
      Remove-Item -LiteralPath $backup -Force
    }
  } finally {
    foreach ($temporaryOwner in @($temporary, $backup)) {
      if (Test-Path -LiteralPath $temporaryOwner -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryOwner -Force
      }
    }
  }
}
function Write-C34LOppoImmutableText([string]$Path, [string]$Text) {
  Assert-C34LOppoWriter (-not (Test-Path -LiteralPath $Path)) `
    'immutable OPPO evidence owner already exists.'
  Write-C34LOppoAtomicText $Path $Text -CreateOnly
}
function Invoke-C34LOppoCrash([string]$Boundary) {
  if ($FixtureCrashBoundary -ceq $Boundary) {
    throw "C34L OPPO evidence writer injected fixture crash: $Boundary"
  }
}
function Assert-C34LOppoBinding($Actual, $Expected, [string]$Label) {
  Assert-C34LOppoExactNames $Actual $Label @('path','sha256','bytes')
  Assert-C34LOppoWriter (
    [string]$Actual.path -ceq [string]$Expected.path -and
    [string]$Actual.sha256 -ceq [string]$Expected.sha256 -and
    [int64]$Actual.bytes -eq [int64]$Expected.bytes
  ) "$Label payload binding changed."
}
function Assert-C34LOppoSourceBinding($Actual, $Expected, [string]$Label) {
  Assert-C34LOppoExactNames $Actual $Label $sourceBindingNames
  foreach ($name in @(
    'path','sha256','evidenceType','sourceProducerId','sessionId','nonceSha256',
    'captureManifestPath','captureManifestSha256'
  )) {
    Assert-C34LOppoWriter (
      [string]$Actual.$name -ceq [string]$Expected.$name
    ) "$Label changed at $name."
  }
  foreach ($name in @('bytes','captureManifestBytes')) {
    Assert-C34LOppoWriter (
      [int64]$Actual.$name -eq [int64]$Expected.$name
    ) "$Label changed at $name."
  }
  foreach ($name in @('producedUtc','expiresUtc')) {
    Assert-C34LOppoWriter (
      (Get-C34LOppoRuntimeUtcText $Actual.$name "$Label $name") -ceq
        (Get-C34LOppoRuntimeUtcText $Expected.$name "$Label expected $name")
    ) "$Label changed at $name."
  }
  Assert-C34LOppoExactNames $Actual.captureDigests `
    "$Label captureDigests" $oppoDigestNames
  foreach ($name in $oppoDigestNames) {
    Assert-C34LOppoWriter (
      [string]$Actual.captureDigests.$name -ceq
        [string]$Expected.captureDigests.$name
    ) "$Label capture digest changed at $name."
  }
}
function Assert-C34LOppoAttestationVector($Value, [string]$Label) {
  Assert-C34LOppoExactNames $Value.actionCounts "$Label actionCounts" `
    $countNames
  Assert-C34LOppoExactNames $Value.releaseAuthorities `
    "$Label releaseAuthorities" $authorityNames
  $expectedCounts = @(1, 1, 0, 0, 0, 0, 0, 0)
  $expectedAuthorities = @(
    'consumed', 'consumed', 'available_once',
    'held_postinstall_journey_qualification'
  )
  for ($index = 0; $index -lt $countNames.Count; $index++) {
    $name = $countNames[$index]
    Assert-C34LOppoWriter (
      [int]$Value.actionCounts.$name -eq $expectedCounts[$index]
    ) "$Label action count changed at $name."
  }
  for ($index = 0; $index -lt $authorityNames.Count; $index++) {
    $name = $authorityNames[$index]
    Assert-C34LOppoWriter (
      [string]$Value.releaseAuthorities.$name -ceq
        $expectedAuthorities[$index]
    ) "$Label release authority changed at $name."
  }
}
function Read-C34LOppoCaptureContract {
  $contractFile = Resolve-C34LOppoRelative $captureArtifactContractPath `
    'capture-artifact contract'
  Assert-C34LOppoWriter (
    (Get-C34LOppoSha $contractFile) -ceq $captureArtifactContractSha256
  ) 'capture-artifact contract SHA-256 changed.'
  try { $contract = Get-Content -Raw -LiteralPath $contractFile | ConvertFrom-Json }
  catch { throw 'C34L OPPO evidence writer rejected: capture-artifact contract is not valid JSON.' }
  Assert-C34LOppoExactNames $contract 'capture-artifact contract' @(
    'schemaVersion','contractId','ticketId','productionProducer',
    'authoritativeReceipt','captureAttemptRootPattern',
    'captureManifestPathPattern','captureArtifactPathPattern',
    'captureArtifactFields','mediaType','evidenceTypes','deviceBinding','privacy'
  )
  Assert-C34LOppoExactNames $contract.evidenceTypes.oppo_play_in_place_update_pair `
    'OPPO capture-artifact contract evidence type' @(
      'kind','productionAdapterId','productionSourceOwners',
      'forbiddenDeviceCommands','roles','leafByRole'
    )
  Assert-C34LOppoExactNames `
    $contract.evidenceTypes.oppo_play_in_place_update_pair.leafByRole `
    'OPPO capture-artifact leaves' @(
      'cold_start_observation','retained_state_observation'
    )
  Assert-C34LOppoExactNames $contract.deviceBinding `
    'capture-artifact device binding' @(
      'derivationId','derivationPattern','expectedSha256','retainedField',
      'forbiddenRawFields'
    )
  Assert-C34LOppoWriter (
    [int]$contract.schemaVersion -eq 3 -and
    [string]$contract.contractId -ceq $captureArtifactContractId -and
    [string]$contract.ticketId -ceq
      'UAW-C34L-PRE-AAB-2-FIX3-AUTHORITATIVE-CAPTURE-PRODUCER-RECEIPT' -and
    [string]$contract.captureAttemptRootPattern -ceq
      '<evidenceRoot>/captures/attempt-<attempt>' -and
    [string]$contract.captureManifestPathPattern -ceq
      '<evidenceRoot>/captures/attempt-<attempt>/<kind>/capture-manifest.json' -and
    [string]$contract.captureArtifactPathPattern -ceq
      '<evidenceRoot>/captures/attempt-<attempt>/<kind>/<leaf>' -and
    (@($contract.captureArtifactFields) -join '|') -ceq
      ($captureArtifactNames -join '|') -and
    [string]$contract.mediaType -ceq 'application/json' -and
    [string]$contract.evidenceTypes.oppo_play_in_place_update_pair.kind -ceq
      'oppo' -and
    (@($contract.evidenceTypes.oppo_play_in_place_update_pair.roles) -join '|') -ceq
      'cold_start_observation|retained_state_observation' -and
    [string]$contract.evidenceTypes.oppo_play_in_place_update_pair.leafByRole.cold_start_observation -ceq
      'cold-start-observation.json' -and
    [string]$contract.evidenceTypes.oppo_play_in_place_update_pair.leafByRole.retained_state_observation -ceq
      'retained-state-observation.json' -and
    [string]$contract.deviceBinding.expectedSha256 -ceq $deviceBindingSha256 -and
    [string]$contract.deviceBinding.retainedField -ceq 'deviceBindingSha256' -and
    (@($contract.deviceBinding.forbiddenRawFields) -join '|') -ceq
      'deviceSerial|serial|androidId|imei|imsi|advertisingId'
  ) 'capture-artifact contract identity, OPPO roles, paths, media type or device binding changed.'
  return [pscustomobject][ordered]@{
    Value=$contract; File=$contractFile
  }
}
function Read-C34LOppoCaptureArtifact(
  $Entry,
  [ValidateSet('cold_start_observation','retained_state_observation')]
  [string]$Role,
  [string]$ExpectedPath,
  $Capture,
  $State
) {
  Assert-C34LOppoPrivacy $Entry "captureArtifacts $Role binding"
  Assert-C34LOppoExactNames $Entry "captureArtifacts $Role binding" `
    $captureArtifactNames
  Assert-C34LOppoWriter (
    [string]$Entry.role -ceq $Role -and
    [string]$Entry.path -ceq $ExpectedPath -and
    [string]$Entry.sha256 -cmatch '^[0-9A-F]{64}$' -and
    [int64]$Entry.bytes -gt 0 -and
    [string]$Entry.mediaType -ceq 'application/json'
  ) "captureArtifacts $Role identity, path, hash, bytes or media type changed."
  $artifactFile = Resolve-C34LOppoRelative ([string]$Entry.path) `
    "capture artifact $Role"
  Assert-C34LOppoWriter (
    (Get-C34LOppoSha $artifactFile) -ceq [string]$Entry.sha256 -and
    (Get-Item -LiteralPath $artifactFile).Length -eq [int64]$Entry.bytes
  ) "capture artifact $Role SHA-256 or byte-length binding changed."
  try {
    $raw = Get-Content -Raw -LiteralPath $artifactFile
    $artifact = $raw | ConvertFrom-Json
  } catch {
    throw "C34L OPPO evidence writer rejected: capture artifact $Role is not valid JSON."
  }
  Assert-C34LOppoPrivacy $artifact "capture artifact $Role"
  $specificNames = if ($Role -ceq 'cold_start_observation') {
    @(
      'coldStartInteractive','blankHierarchy','timeout','flutterFatalErrorCount',
      'androidRuntimeFatalCount','anrCount','appProcessErrorScanPassed',
      'artifactRelationshipProved','inPlaceUpdateProved'
    )
  } else {
    @(
      'firstInstallTimeMillis','lastUpdateTimeMillis',
      'firstInstallTimePreserved','retainedDataContinuityProved',
      'inPlacePlayUpdateProved','uninstallPerformed','dataClearPerformed',
      'downgradePerformed','adbInstallPerformed'
    )
  }
  Assert-C34LOppoExactNames $artifact "capture artifact $Role" `
    ($capturePayloadCommonNames + $specificNames)
  Assert-C34LOppoWriter (
    [int]$artifact.schemaVersion -eq 1 -and
    [string]$artifact.captureArtifactContractId -ceq
      $captureArtifactContractId -and
    [string]$artifact.evidenceType -ceq 'oppo_play_in_place_update_pair' -and
    [string]$artifact.role -ceq $Role -and
    [string]$artifact.ticketId -ceq $ticketId -and
    [int]$artifact.attempt -eq $Attempt -and
    [string]$artifact.packageName -ceq $packageName -and
    [string]$artifact.versionName -ceq $versionName -and
    [string]$artifact.versionCode -ceq $versionCode -and
    [string]$artifact.artifactSha256 -ceq
      [string]$State.buildResult.artifactSha256 -and
    [int64]$artifact.artifactBytes -eq
      [int64]$State.buildResult.artifactBytes -and
    [string]$artifact.deviceBindingSha256 -ceq $deviceBindingSha256 -and
    [string]$artifact.deviceModel -ceq $deviceModel -and
    [string]$artifact.installerPackage -ceq 'com.android.vending' -and
    [string]$artifact.sourceProducerId -ceq [string]$Capture.sourceProducerId -and
    [string]$artifact.sessionId -ceq [string]$Capture.sessionId -and
    [string]$artifact.nonceSha256 -ceq [string]$Capture.nonceSha256
  ) "capture artifact $Role identity, device binding, producer or session changed."
  if ($Role -ceq 'cold_start_observation') {
    Assert-C34LOppoWriter (
      [bool]$artifact.coldStartInteractive -and
      -not [bool]$artifact.blankHierarchy -and -not [bool]$artifact.timeout -and
      [int]$artifact.flutterFatalErrorCount -eq 0 -and
      [int]$artifact.androidRuntimeFatalCount -eq 0 -and
      [int]$artifact.anrCount -eq 0 -and
      [bool]$artifact.appProcessErrorScanPassed -and
      [bool]$artifact.artifactRelationshipProved -and
      [bool]$artifact.inPlaceUpdateProved
    ) 'cold-start capture artifact semantic contract changed.'
  } else {
    Assert-C34LOppoWriter (
      [int64]$artifact.firstInstallTimeMillis -gt 0 -and
      [int64]$artifact.lastUpdateTimeMillis -gt
        [int64]$artifact.firstInstallTimeMillis -and
      [bool]$artifact.firstInstallTimePreserved -and
      [bool]$artifact.retainedDataContinuityProved -and
      [bool]$artifact.inPlacePlayUpdateProved -and
      -not [bool]$artifact.uninstallPerformed -and
      -not [bool]$artifact.dataClearPerformed -and
      -not [bool]$artifact.downgradePerformed -and
      -not [bool]$artifact.adbInstallPerformed
    ) 'retained-state capture artifact semantic contract changed.'
  }
  return [pscustomobject][ordered]@{
    Value=$artifact; File=$artifactFile; Binding=$Entry
  }
}
function Read-C34LOppoSourceAttestation(
  [string]$ExpectedEvidenceRoot,
  [string]$StateSha,
  [string]$AggregateSha,
  $State
) {
  $expectedPath =
    "$ExpectedEvidenceRoot/attestations/source-attestation-oppo-attempt-$Attempt.json"
  Assert-C34LOppoWriter ($SourceAttestationPath -ceq $expectedPath) `
    'source attestation is not the exact immutable OPPO owner.'
  $sourceFile = Resolve-C34LOppoRelative $SourceAttestationPath `
    'OPPO source attestation'
  Assert-C34LOppoWriter (
    $SourceAttestationSha256 -cmatch '^[0-9A-F]{64}$' -and
    (Get-C34LOppoSha $sourceFile) -ceq $SourceAttestationSha256 -and
    $SourceAttestationBytes -gt 0 -and
    (Get-Item -LiteralPath $sourceFile).Length -eq $SourceAttestationBytes
  ) 'source attestation SHA-256 or byte-length binding changed.'
  try {
    $sourceRaw = Get-Content -Raw -LiteralPath $sourceFile
    $source = $sourceRaw | ConvertFrom-Json
  } catch {
    throw 'C34L OPPO evidence writer rejected: source attestation is not valid JSON.'
  }
  Assert-C34LOppoExactNames $source 'source attestation' `
    $sourceAttestationNames
  Assert-C34LOppoExactNames $source.captureDigests `
    'source attestation captureDigests' $oppoDigestNames
  Assert-C34LOppoAttestationVector $source 'source attestation'
  Assert-C34LOppoPrivacy $source 'source attestation'
  Assert-C34LOppoWriter (
    [int]$source.schemaVersion -eq 1 -and
    [string]$source.attestationContractId -ceq
      'MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001' -and
    [string]$source.evidenceType -ceq 'oppo_play_in_place_update_pair' -and
    [string]$source.ticketId -ceq $ticketId -and
    [int]$source.attempt -eq $Attempt -and
    [string]$source.packageName -ceq $packageName -and
    [string]$source.versionName -ceq $versionName -and
    [string]$source.versionCode -ceq $versionCode -and
    [string]$source.preStateSha256 -ceq $StateSha -and
    [string]$source.preAggregateSha256 -ceq $AggregateSha -and
    [string]$source.artifactSha256 -ceq
      [string]$State.buildResult.artifactSha256 -and
    [int64]$source.artifactBytes -eq [int64]$State.buildResult.artifactBytes -and
    [string]$source.sourceProducerId -ceq $(if ($receiptMode) {
      $authoritativeProducerId
    } else {
      'MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
    }) -and
    [string]$source.sessionId -cmatch '^[a-z0-9][a-z0-9_-]{15,95}$' -and
    [string]$source.nonceSha256 -cmatch '^[0-9A-F]{64}$'
  ) 'source attestation identity, type, producer, session, preimage or artifact changed.'
  foreach ($name in $oppoDigestNames) {
    Assert-C34LOppoWriter (
      [string]$source.captureDigests.$name -cmatch '^[0-9A-F]{64}$'
    ) "source attestation capture digest changed at $name."
  }
  $sourceProducedText = Get-C34LOppoWireUtc $sourceRaw 'producedUtc' `
    'source attestation'
  $sourceExpiresText = Get-C34LOppoWireUtc $sourceRaw 'expiresUtc' `
    'source attestation'
  $produced = ConvertTo-C34LOppoUtc $sourceProducedText `
    'source attestation producedUtc'
  $expires = ConvertTo-C34LOppoUtc $sourceExpiresText `
    'source attestation expiresUtc'
  Assert-C34LOppoWriter (
    $expires -gt $produced -and $expires -le $produced.AddMinutes(15)
  ) 'source attestation session window is invalid.'

  $expectedCapture =
    "$ExpectedEvidenceRoot/captures/attempt-$Attempt/oppo/capture-manifest.json"
  Assert-C34LOppoWriter (
    [string]$source.captureManifestPath -ceq $expectedCapture -and
    [string]$source.captureManifestSha256 -cmatch '^[0-9A-F]{64}$' -and
    [int64]$source.captureManifestBytes -gt 0
  ) 'capture-manifest identity is not the exact OPPO owner.'
  $captureFile = Resolve-C34LOppoRelative `
    ([string]$source.captureManifestPath) 'OPPO capture manifest'
  Assert-C34LOppoWriter (
    (Get-C34LOppoSha $captureFile) -ceq
      [string]$source.captureManifestSha256 -and
    (Get-Item -LiteralPath $captureFile).Length -eq
      [int64]$source.captureManifestBytes
  ) 'capture-manifest SHA-256 or byte-length binding changed.'
  try {
    $captureRaw = Get-Content -Raw -LiteralPath $captureFile
    $capture = $captureRaw | ConvertFrom-Json
  } catch {
    throw 'C34L OPPO evidence writer rejected: capture manifest is not valid JSON.'
  }
  Assert-C34LOppoPrivacy $capture 'capture manifest'
  Assert-C34LOppoExactNames $capture 'capture manifest' $captureManifestNames
  Assert-C34LOppoExactNames $capture.captureDigests `
    'capture manifest captureDigests' $oppoDigestNames
  Assert-C34LOppoAttestationVector $capture 'capture manifest'
  $captureProducedText = Get-C34LOppoWireUtc $captureRaw 'producedUtc' `
    'capture manifest'
  $captureExpiresText = Get-C34LOppoWireUtc $captureRaw 'expiresUtc' `
    'capture manifest'
  Assert-C34LOppoWriter (
    [int]$capture.schemaVersion -eq 1 -and
    [string]$capture.captureContractId -ceq
      'MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001' -and
    [string]$capture.evidenceType -ceq [string]$source.evidenceType -and
    [string]$capture.ticketId -ceq [string]$source.ticketId -and
    [int]$capture.attempt -eq [int]$source.attempt -and
    [string]$capture.packageName -ceq [string]$source.packageName -and
    [string]$capture.versionName -ceq [string]$source.versionName -and
    [string]$capture.versionCode -ceq [string]$source.versionCode -and
    [string]$capture.preStateSha256 -ceq [string]$source.preStateSha256 -and
    [string]$capture.preAggregateSha256 -ceq
      [string]$source.preAggregateSha256 -and
    [string]$capture.artifactSha256 -ceq [string]$source.artifactSha256 -and
    [int64]$capture.artifactBytes -eq [int64]$source.artifactBytes -and
    [string]$capture.sourceProducerId -ceq [string]$source.sourceProducerId -and
    [string]$capture.sessionId -ceq [string]$source.sessionId -and
    [string]$capture.nonceSha256 -ceq [string]$source.nonceSha256 -and
    [string]$capture.captureArtifactContractPath -ceq
      $captureArtifactContractPath -and
    [string]$capture.captureArtifactContractSha256 -ceq
      $captureArtifactContractSha256 -and
    [string]$capture.captureArtifactContractId -ceq
      $captureArtifactContractId -and
    $captureProducedText -ceq $sourceProducedText -and
    $captureExpiresText -ceq $sourceExpiresText
  ) 'capture-manifest identity, preimage, vector, artifact or session changed.'
  foreach ($name in $oppoDigestNames) {
    Assert-C34LOppoWriter (
      [string]$capture.captureDigests.$name -ceq
        [string]$source.captureDigests.$name
    ) "capture-manifest digest changed at $name."
  }
  $contract = Read-C34LOppoCaptureContract
  Assert-C34LOppoWriter (@($capture.captureArtifacts).Count -eq 2) `
    'capture manifest must bind exactly two OPPO capture artifacts.'
  $expectedRoles = @('cold_start_observation','retained_state_observation')
  $artifactByRole = @{}
  foreach ($entry in @($capture.captureArtifacts)) {
    Assert-C34LOppoPrivacy $entry 'capture manifest artifact binding'
    Assert-C34LOppoExactNames $entry 'capture manifest artifact binding' `
      $captureArtifactNames
    $role = [string]$entry.role
    Assert-C34LOppoWriter (
      $expectedRoles -ccontains $role -and
      -not $artifactByRole.ContainsKey($role)
    ) 'capture manifest has an unknown, duplicate or cross-kind artifact role.'
    $artifactByRole[$role] = $entry
  }
  foreach ($role in $expectedRoles) {
    Assert-C34LOppoWriter $artifactByRole.ContainsKey($role) `
      "capture manifest is missing OPPO artifact role $role."
  }
  $captureRoot = "$ExpectedEvidenceRoot/captures/attempt-$Attempt/oppo"
  $coldArtifact = Read-C34LOppoCaptureArtifact `
    $artifactByRole.cold_start_observation 'cold_start_observation' `
    "$captureRoot/cold-start-observation.json" $capture $State
  $retainedArtifact = Read-C34LOppoCaptureArtifact `
    $artifactByRole.retained_state_observation 'retained_state_observation' `
    "$captureRoot/retained-state-observation.json" $capture $State
  Assert-C34LOppoWriter (
    [string]$capture.captureDigests.packageStateDigestSha256 -ceq
      [string]$coldArtifact.Binding.sha256 -and
    [string]$capture.captureDigests.coldStartDigestSha256 -ceq
      [string]$coldArtifact.Binding.sha256 -and
    [string]$capture.captureDigests.retainedDataDigestSha256 -ceq
      [string]$retainedArtifact.Binding.sha256
  ) 'capture manifest digest-to-artifact mapping changed.'
  return [pscustomobject][ordered]@{
    Binding = [pscustomobject][ordered]@{
      path = $SourceAttestationPath; sha256 = $SourceAttestationSha256
      bytes = $SourceAttestationBytes
      evidenceType = [string]$source.evidenceType
      sourceProducerId = [string]$source.sourceProducerId
      sessionId = [string]$source.sessionId
      nonceSha256 = [string]$source.nonceSha256
      producedUtc = $sourceProducedText
      expiresUtc = $sourceExpiresText
      captureManifestPath = [string]$source.captureManifestPath
      captureManifestSha256 = [string]$source.captureManifestSha256
      captureManifestBytes = [int64]$source.captureManifestBytes
      captureDigests = $source.captureDigests
    }
    Produced = $produced; Expires = $expires
    SourceFile = $sourceFile; CaptureFile = $captureFile
    ContractFile = $contract.File
    ColdArtifact = $coldArtifact; RetainedArtifact = $retainedArtifact
  }
}
function Assert-C34LOppoEvidenceDocument(
  $Value,
  [ValidateSet('cold','retained')][string]$Kind,
  [string]$PairId,
  [string]$StateSha,
  [string]$AggregateSha,
  $State,
  $SourceBinding
) {
  $commonNames = @(
    'schemaVersion','evidenceContractId','evidencePairId','ticketId','attempt',
    'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
    'packageName','versionName','versionCode','artifactSha256','artifactBytes',
    'deviceBindingSha256','deviceModel','installerPackage','sourceAttestation',
    'evidenceType'
  )
  $specificNames = if ($Kind -ceq 'cold') {
    @(
      'coldStartInteractive','blankHierarchy','timeout','flutterFatalErrorCount',
      'androidRuntimeFatalCount','anrCount','appProcessErrorScanPassed',
      'artifactRelationshipProved','inPlaceUpdateProved'
    )
  } else {
    @(
      'firstInstallTimeMillis','lastUpdateTimeMillis',
      'firstInstallTimePreserved','retainedDataContinuityProved',
      'inPlacePlayUpdateProved','uninstallPerformed','dataClearPerformed',
      'downgradePerformed','adbInstallPerformed'
    )
  }
  Assert-C34LOppoExactNames $Value "$Kind OPPO evidence" `
    ($commonNames + $specificNames)
  Assert-C34LOppoAttestationVector $Value "$Kind OPPO evidence"
  Assert-C34LOppoPrivacy $Value "$Kind OPPO evidence"
  Assert-C34LOppoSourceBinding $Value.sourceAttestation $SourceBinding `
    "$Kind OPPO evidence sourceAttestation"
  Assert-C34LOppoWriter (
    [int]$Value.schemaVersion -eq 1 -and
    [string]$Value.evidenceContractId -ceq
      'MOOLSOCIAL-C34L-OPPO-EVIDENCE-001' -and
    [string]$Value.evidencePairId -ceq $PairId -and
    [string]$Value.ticketId -ceq $ticketId -and
    [int]$Value.attempt -eq $Attempt -and
    [string]$Value.preStateSha256 -ceq $StateSha -and
    [string]$Value.preAggregateSha256 -ceq $AggregateSha -and
    [string]$Value.packageName -ceq $packageName -and
    [string]$Value.versionName -ceq $versionName -and
    [string]$Value.versionCode -ceq $versionCode -and
    [string]$Value.artifactSha256 -ceq
      [string]$State.buildResult.artifactSha256 -and
    [int64]$Value.artifactBytes -eq [int64]$State.buildResult.artifactBytes -and
    [string]$Value.deviceBindingSha256 -ceq $deviceBindingSha256 -and
    [string]$Value.deviceModel -ceq $deviceModel -and
    [string]$Value.installerPackage -ceq 'com.android.vending'
  ) "$Kind OPPO evidence identity, preimage, artifact or device binding changed."
  if ($Kind -ceq 'cold') {
    Assert-C34LOppoWriter (
      [string]$Value.evidenceType -ceq
        'oppo_play_in_place_update_cold_start' -and
      [bool]$Value.coldStartInteractive -and -not [bool]$Value.blankHierarchy -and
      -not [bool]$Value.timeout -and [int]$Value.flutterFatalErrorCount -eq 0 -and
      [int]$Value.androidRuntimeFatalCount -eq 0 -and
      [int]$Value.anrCount -eq 0 -and [bool]$Value.appProcessErrorScanPassed -and
      [bool]$Value.artifactRelationshipProved -and
      [bool]$Value.inPlaceUpdateProved
    ) 'cold OPPO evidence semantic contract changed.'
  } else {
    Assert-C34LOppoWriter (
      [string]$Value.evidenceType -ceq 'oppo_in_place_retained_data' -and
      [int64]$Value.firstInstallTimeMillis -gt 0 -and
      [int64]$Value.lastUpdateTimeMillis -gt
        [int64]$Value.firstInstallTimeMillis -and
      [bool]$Value.firstInstallTimePreserved -and
      [bool]$Value.retainedDataContinuityProved -and
      [bool]$Value.inPlacePlayUpdateProved -and
      -not [bool]$Value.uninstallPerformed -and
      -not [bool]$Value.dataClearPerformed -and
      -not [bool]$Value.downgradePerformed -and
      -not [bool]$Value.adbInstallPerformed
    ) 'retained OPPO evidence semantic contract changed.'
  }
}
function Read-C34LOppoJournal(
  [string]$Path,
  [string]$TransactionId,
  [string]$StateSha,
  [string]$AggregateSha,
  $State,
  $ColdBinding,
  $RetainedBinding,
  $SourceBinding,
  [DateTimeOffset]$Produced,
  [DateTimeOffset]$Expires
) {
  try {
    $journalRaw = Get-Content -Raw -LiteralPath $Path
    $journal = $journalRaw | ConvertFrom-Json
  }
  catch { throw 'C34L OPPO evidence writer rejected: transaction journal is not valid JSON.' }
  $journalNames = @(
    'schemaVersion','transactionContractId','transactionId','ticketId','attempt',
    'status','preStateSha256','preAggregateSha256','artifactSha256',
    'artifactBytes','deviceBindingSha256','coldStart','retainedData',
    'sourceAttestation','preparedUtc','committedUtc'
  )
  Assert-C34LOppoExactNames $journal 'OPPO transaction journal' $journalNames
  Assert-C34LOppoPrivacy $journal 'OPPO transaction journal'
  Assert-C34LOppoSourceBinding $journal.sourceAttestation $SourceBinding `
    'OPPO transaction sourceAttestation'
  Assert-C34LOppoBinding $journal.coldStart $ColdBinding `
    'OPPO transaction coldStart'
  Assert-C34LOppoBinding $journal.retainedData $RetainedBinding `
    'OPPO transaction retainedData'
  Assert-C34LOppoWriter (
    [int]$journal.schemaVersion -eq 1 -and
    [string]$journal.transactionContractId -ceq
      'MOOLSOCIAL-C34L-OPPO-EVIDENCE-TRANSACTION-001' -and
    [string]$journal.transactionId -ceq $TransactionId -and
    [string]$journal.ticketId -ceq $ticketId -and
    [int]$journal.attempt -eq $Attempt -and
    [string]$journal.status -cin @(
      'prepared','cold_moved','both_moved','committed'
    ) -and
    [string]$journal.preStateSha256 -ceq $StateSha -and
    [string]$journal.preAggregateSha256 -ceq $AggregateSha -and
    [string]$journal.artifactSha256 -ceq
      [string]$State.buildResult.artifactSha256 -and
    [int64]$journal.artifactBytes -eq [int64]$State.buildResult.artifactBytes -and
    [string]$journal.deviceBindingSha256 -ceq $deviceBindingSha256
  ) 'OPPO transaction identity, status, preimage or artifact changed.'
  $preparedText = Get-C34LOppoWireUtc $journalRaw 'preparedUtc' `
    'OPPO transaction journal'
  $prepared = ConvertTo-C34LOppoUtc $preparedText `
    'OPPO transaction preparedUtc'
  Assert-C34LOppoWriter (
    $prepared -ge $Produced -and $prepared -le $Expires
  ) 'OPPO transaction was not prepared inside the attested session.'
  if ([string]$journal.status -ceq 'committed') {
    $committedText = Get-C34LOppoWireUtc $journalRaw 'committedUtc' `
      'OPPO transaction journal'
    $committed = ConvertTo-C34LOppoUtc $committedText `
      'OPPO transaction committedUtc'
    Assert-C34LOppoWriter ($committed -ge $prepared) `
      'OPPO transaction committed before preparation.'
  } else {
    $nullCommitted = [regex]::Matches(
      $journalRaw, '"committedUtc"\s*:\s*null'
    )
    Assert-C34LOppoWriter (
      $null -eq $journal.committedUtc -and $nullCommitted.Count -eq 1 -and
      [regex]::Matches(
        $journalRaw,
        '"committedUtc"\s*:\s*"[^"]+"'
      ).Count -eq 0
    ) `
      'noncommitted OPPO transaction has committedUtc.'
  }
  return $journal
}

Assert-C34LOppoWriter (
  $FixtureMode -or $FixtureCrashBoundary -ceq 'none'
) 'crash injection is fixture-only.'
$receiptMode = $PSCmdlet.ParameterSetName -cin @(
  'ProductionReceipt','FixtureReceipt'
)

$stateFile = Resolve-C34LOppoRelative $StatePath 'detailed candidate state'
$stateRelative = Get-C34LOppoRelative $stateFile
if ($FixtureMode) {
  Assert-C34LOppoWriter (
    $stateRelative -cmatch
      '^tmp/(c34l-retained-evidence-fixtures-[0-9A-Za-z_-]+|c34l-authoritative-capture-fixtures-[0-9a-f]{32})/state[.]json$'
  ) 'fixture state is outside the exact C34L evidence-producer root.'
  $fixtureRoot = (Split-Path -Parent $stateRelative).Replace('\', '/')
  $expectedEvidenceRoot = "$fixtureRoot/evidence"
} else {
  Assert-C34LOppoWriter (
    $stateRelative -ceq 'config/successor-aab-regression-hard-gate-state-c34l.json'
  ) 'production writing requires the exact C34L detailed state.'
  $expectedEvidenceRoot = $productionEvidenceRoot
}
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C34LOppoProperties $state 'detailed candidate state' @(
  'ticketId', 'candidate', 'aggregateStatePath', 'machineState', 'evidenceRoot',
  'actionCounts', 'releaseAuthorities', 'buildResult'
)
$aggregateFile = Resolve-C34LOppoRelative ([string]$state.aggregateStatePath) `
  'aggregate candidate state'
$aggregateRelative = Get-C34LOppoRelative $aggregateFile
if ($FixtureMode) {
  Assert-C34LOppoWriter ($aggregateRelative -ceq "$fixtureRoot/aggregate.json") `
    'fixture aggregate escaped the exact fixture root.'
} else {
  Assert-C34LOppoWriter (
    $aggregateRelative -ceq
      'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
  ) 'production writing requires the exact C34L aggregate state.'
}
$aggregate = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
Assert-C34LOppoProperties $aggregate 'aggregate candidate state' @(
  'ticketId', 'candidate', 'machineState', 'actionCounts', 'releaseAuthorities'
)
Assert-C34LOppoWriter (
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
    'postupload_qualified_in_place_oppo_play_update_authority_available_once' -and
  [string]$aggregate.machineState -ceq [string]$state.machineState -and
  [string]$state.evidenceRoot -ceq $expectedEvidenceRoot
) 'candidate identity, phase, device binding or evidence root changed.'
Assert-C34LOppoVector $state $aggregate
Assert-C34LOppoProperties $state.buildResult 'build result' @(
  'artifactPath', 'artifactSha256', 'artifactBytes'
)
$artifactFile = Resolve-C34LOppoRelative ([string]$state.buildResult.artifactPath) `
  'sealed C34L AAB'
$expectedArtifact =
  "$expectedEvidenceRoot/MoolSocial-$versionName-$versionCode-release.aab"
Assert-C34LOppoWriter (
  [string]$state.buildResult.artifactPath -ceq $expectedArtifact -and
  [string]$state.buildResult.artifactSha256 -cmatch '^[0-9A-F]{64}$' -and
  (Get-C34LOppoSha $artifactFile) -ceq [string]$state.buildResult.artifactSha256 -and
  (Get-Item -LiteralPath $artifactFile).Length -eq
    [int64]$state.buildResult.artifactBytes -and
  [int64]$state.buildResult.artifactBytes -gt 0
) 'sealed artifact path, SHA-256 or byte length changed.'

$stateSha = Get-C34LOppoSha $stateFile
$aggregateSha = Get-C34LOppoSha $aggregateFile
if ($receiptMode) {
  $expectedReceipt =
    "$expectedEvidenceRoot/captures/attempt-$Attempt/oppo/authoritative-capture-receipt.json"
  Assert-C34LOppoWriter (
    $AuthoritativeReceiptPath -ceq $expectedReceipt -and
    $AuthoritativeReceiptSha256 -cmatch '^[0-9A-F]{64}$' -and
    $AuthoritativeReceiptBytes -gt 0
  ) 'exact authoritative OPPO receipt path, SHA-256 and bytes are required.'
  $receiptFile=Resolve-C34LOppoRelative $AuthoritativeReceiptPath `
    'authoritative OPPO receipt'
  Assert-C34LOppoWriter (
    (Get-C34LOppoSha $receiptFile) -ceq $AuthoritativeReceiptSha256 -and
    (Get-Item -LiteralPath $receiptFile).Length -eq $AuthoritativeReceiptBytes
  ) 'authoritative OPPO receipt SHA-256 or bytes changed.'
  $receipt=Get-Content -Raw -LiteralPath $receiptFile|ConvertFrom-Json
  Assert-C34LOppoWriter (
    [string]$receipt.receiptContractId -ceq
      'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-RECEIPT-001' -and
    [string]$receipt.producerId -ceq $authoritativeProducerId -and
    [string]$receipt.evidenceType -ceq 'oppo_play_in_place_update_pair' -and
    [string]$receipt.ticketId -ceq $ticketId -and
    [int]$receipt.attempt -eq $Attempt -and
    [string]$receipt.detailedState.sha256 -ceq $stateSha -and
    [string]$receipt.aggregateState.sha256 -ceq $aggregateSha -and
    [string]$receipt.artifact.sha256 -ceq
      [string]$state.buildResult.artifactSha256
  ) 'authoritative OPPO receipt identity or preimage changed.'
  $SourceAttestationPath=
    "$expectedEvidenceRoot/attestations/source-attestation-oppo-attempt-$Attempt.json"
  $derivedSource=Resolve-C34LOppoRelative $SourceAttestationPath `
    'derived OPPO source attestation'
  $SourceAttestationSha256=Get-C34LOppoSha $derivedSource
  $SourceAttestationBytes=[int64](Get-Item -LiteralPath $derivedSource).Length
}
$attestation = Read-C34LOppoSourceAttestation $expectedEvidenceRoot $stateSha `
  $aggregateSha $state
$sourceBinding = $attestation.Binding
$capturedCold = $attestation.ColdArtifact.Value
$capturedRetained = $attestation.RetainedArtifact.Value
if ($receiptMode) {
  $ColdStartInteractive=[bool]$capturedCold.coldStartInteractive
  $BlankHierarchy=[bool]$capturedCold.blankHierarchy
  $Timeout=[bool]$capturedCold.timeout
  $FlutterFatalErrorCount=[int]$capturedCold.flutterFatalErrorCount
  $AndroidRuntimeFatalCount=[int]$capturedCold.androidRuntimeFatalCount
  $AnrCount=[int]$capturedCold.anrCount
  $AppProcessErrorScanPassed=[bool]$capturedCold.appProcessErrorScanPassed
  $ArtifactRelationshipProved=[bool]$capturedCold.artifactRelationshipProved
  $InPlaceUpdateProved=[bool]$capturedCold.inPlaceUpdateProved
  $FirstInstallTimeMillis=[int64]$capturedRetained.firstInstallTimeMillis
  $LastUpdateTimeMillis=[int64]$capturedRetained.lastUpdateTimeMillis
  $FirstInstallTimePreserved=[bool]$capturedRetained.firstInstallTimePreserved
  $RetainedDataContinuityProved=[bool]$capturedRetained.retainedDataContinuityProved
  $InPlacePlayUpdateProved=[bool]$capturedRetained.inPlacePlayUpdateProved
  $UninstallPerformed=[bool]$capturedRetained.uninstallPerformed
  $DataClearPerformed=[bool]$capturedRetained.dataClearPerformed
  $DowngradePerformed=[bool]$capturedRetained.downgradePerformed
  $AdbInstallPerformed=[bool]$capturedRetained.adbInstallPerformed
} else {
Assert-C34LOppoWriter (
  [bool]$ColdStartInteractive -eq [bool]$capturedCold.coldStartInteractive -and
  [bool]$BlankHierarchy -eq [bool]$capturedCold.blankHierarchy -and
  [bool]$Timeout -eq [bool]$capturedCold.timeout -and
  $FlutterFatalErrorCount -eq [int]$capturedCold.flutterFatalErrorCount -and
  $AndroidRuntimeFatalCount -eq
    [int]$capturedCold.androidRuntimeFatalCount -and
  $AnrCount -eq [int]$capturedCold.anrCount -and
  [bool]$AppProcessErrorScanPassed -eq
    [bool]$capturedCold.appProcessErrorScanPassed -and
  [bool]$ArtifactRelationshipProved -eq
    [bool]$capturedCold.artifactRelationshipProved -and
  [bool]$InPlaceUpdateProved -eq [bool]$capturedCold.inPlaceUpdateProved -and
  $FirstInstallTimeMillis -eq [int64]$capturedRetained.firstInstallTimeMillis -and
  $LastUpdateTimeMillis -eq [int64]$capturedRetained.lastUpdateTimeMillis -and
  [bool]$FirstInstallTimePreserved -eq
    [bool]$capturedRetained.firstInstallTimePreserved -and
  [bool]$RetainedDataContinuityProved -eq
    [bool]$capturedRetained.retainedDataContinuityProved -and
  [bool]$InPlacePlayUpdateProved -eq
    [bool]$capturedRetained.inPlacePlayUpdateProved -and
  [bool]$UninstallPerformed -eq [bool]$capturedRetained.uninstallPerformed -and
  [bool]$DataClearPerformed -eq [bool]$capturedRetained.dataClearPerformed -and
  [bool]$DowngradePerformed -eq [bool]$capturedRetained.downgradePerformed -and
  [bool]$AdbInstallPerformed -eq [bool]$capturedRetained.adbInstallPerformed
) 'fixture OPPO observations do not equal the retained capture artifacts.'
}
$pairId = "oppo-$Attempt-$stateSha"
$common = [ordered]@{
  schemaVersion = 1
  evidenceContractId = 'MOOLSOCIAL-C34L-OPPO-EVIDENCE-001'
  evidencePairId = $pairId
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
  deviceBindingSha256 = $deviceBindingSha256
  deviceModel = $deviceModel
  installerPackage = 'com.android.vending'
  sourceAttestation = $sourceBinding
}
$cold = [ordered]@{}
foreach ($entry in $common.GetEnumerator()) { $cold[$entry.Key] = $entry.Value }
$cold.evidenceType = 'oppo_play_in_place_update_cold_start'
$cold.coldStartInteractive = [bool]$capturedCold.coldStartInteractive
$cold.blankHierarchy = [bool]$capturedCold.blankHierarchy
$cold.timeout = [bool]$capturedCold.timeout
$cold.flutterFatalErrorCount = [int]$capturedCold.flutterFatalErrorCount
$cold.androidRuntimeFatalCount = [int]$capturedCold.androidRuntimeFatalCount
$cold.anrCount = [int]$capturedCold.anrCount
$cold.appProcessErrorScanPassed = [bool]$capturedCold.appProcessErrorScanPassed
$cold.artifactRelationshipProved = [bool]$capturedCold.artifactRelationshipProved
$cold.inPlaceUpdateProved = [bool]$capturedCold.inPlaceUpdateProved
$retained = [ordered]@{}
foreach ($entry in $common.GetEnumerator()) { $retained[$entry.Key] = $entry.Value }
$retained.evidenceType = 'oppo_in_place_retained_data'
$retained.firstInstallTimeMillis = [int64]$capturedRetained.firstInstallTimeMillis
$retained.lastUpdateTimeMillis = [int64]$capturedRetained.lastUpdateTimeMillis
$retained.firstInstallTimePreserved =
  [bool]$capturedRetained.firstInstallTimePreserved
$retained.retainedDataContinuityProved =
  [bool]$capturedRetained.retainedDataContinuityProved
$retained.inPlacePlayUpdateProved =
  [bool]$capturedRetained.inPlacePlayUpdateProved
$retained.uninstallPerformed = [bool]$capturedRetained.uninstallPerformed
$retained.dataClearPerformed = [bool]$capturedRetained.dataClearPerformed
$retained.downgradePerformed = [bool]$capturedRetained.downgradePerformed
$retained.adbInstallPerformed = [bool]$capturedRetained.adbInstallPerformed
$coldObject = [pscustomobject]$cold
$retainedObject = [pscustomobject]$retained
Assert-C34LOppoEvidenceDocument $coldObject 'cold' $pairId $stateSha `
  $aggregateSha $state $sourceBinding
Assert-C34LOppoEvidenceDocument $retainedObject 'retained' $pairId $stateSha `
  $aggregateSha $state $sourceBinding
$coldJson = ($coldObject | ConvertTo-Json -Depth 30) + [Environment]::NewLine
$retainedJson = ($retainedObject | ConvertTo-Json -Depth 30) +
  [Environment]::NewLine
$coldIdentity = Get-C34LOppoTextIdentity $coldJson
$retainedIdentity = Get-C34LOppoTextIdentity $retainedJson
$coldRelative =
  "$expectedEvidenceRoot/08-oppo-play-in-place-update-cold-start-evidence.json"
$retainedRelative =
  "$expectedEvidenceRoot/09-oppo-in-place-retained-data-evidence.json"
$coldFile = Resolve-C34LOppoRelative $coldRelative 'OPPO cold evidence target' `
  -AllowMissing
$retainedFile = Resolve-C34LOppoRelative $retainedRelative `
  'OPPO retained evidence target' -AllowMissing
$coldBinding = [pscustomobject][ordered]@{
  path=$coldRelative; sha256=$coldIdentity.Sha256; bytes=$coldIdentity.Bytes
}
$retainedBinding = [pscustomobject][ordered]@{
  path=$retainedRelative; sha256=$retainedIdentity.Sha256
  bytes=$retainedIdentity.Bytes
}
$transactionDirectoryRelative = "$expectedEvidenceRoot/transactions"
$transactionDirectory = [IO.Path]::GetFullPath(
  (Join-Path $root $transactionDirectoryRelative)
)
Assert-C34LOppoWriter (
  $transactionDirectory.StartsWith($rootPrefix,
    [StringComparison]::OrdinalIgnoreCase)
) 'OPPO transaction directory escaped the production repository.'
if (-not (Test-Path -LiteralPath $transactionDirectory -PathType Container)) {
  $evidenceDirectory = Split-Path -Parent $coldFile
  Assert-C34LOppoNoReparseChain $evidenceDirectory 'OPPO evidence directory'
  [void](New-Item -ItemType Directory -Path $transactionDirectory)
}
Assert-C34LOppoNoReparseChain $transactionDirectory `
  'OPPO transaction directory'
$transactionRelative =
  "$transactionDirectoryRelative/oppo-evidence-pair-attempt-$Attempt.json"
$transactionFile = Resolve-C34LOppoRelative $transactionRelative `
  'OPPO evidence transaction journal' -AllowMissing
$transactionId = "oppo-evidence-$Attempt-$stateSha-$aggregateSha"

function Save-C34LOppoJournal($Value, [switch]$CreateOnly) {
  $wire = [pscustomobject][ordered]@{
    schemaVersion=[int]$Value.schemaVersion
    transactionContractId=[string]$Value.transactionContractId
    transactionId=[string]$Value.transactionId
    ticketId=[string]$Value.ticketId
    attempt=[int]$Value.attempt
    status=[string]$Value.status
    preStateSha256=[string]$Value.preStateSha256
    preAggregateSha256=[string]$Value.preAggregateSha256
    artifactSha256=[string]$Value.artifactSha256
    artifactBytes=[int64]$Value.artifactBytes
    deviceBindingSha256=[string]$Value.deviceBindingSha256
    coldStart=$Value.coldStart
    retainedData=$Value.retainedData
    sourceAttestation=$Value.sourceAttestation
    preparedUtc=Get-C34LOppoRuntimeUtcText $Value.preparedUtc `
      'OPPO transaction save preparedUtc'
    committedUtc=if ($null -eq $Value.committedUtc) {
      $null
    } else {
      Get-C34LOppoRuntimeUtcText $Value.committedUtc `
        'OPPO transaction save committedUtc'
    }
  }
  $text = ($wire | ConvertTo-Json -Depth 30) + [Environment]::NewLine
  if ($CreateOnly) {
    Write-C34LOppoAtomicText $transactionFile $text -CreateOnly
  } else {
    Write-C34LOppoAtomicText $transactionFile $text
  }
  $raw = Get-Content -Raw -LiteralPath $transactionFile
  [void](Get-C34LOppoWireUtc $raw 'preparedUtc' `
    'persisted OPPO transaction journal')
  if ([string]$wire.status -ceq 'committed') {
    [void](Get-C34LOppoWireUtc $raw 'committedUtc' `
      'persisted OPPO transaction journal')
  } else {
    Assert-C34LOppoWriter (
      [regex]::Matches($raw, '"committedUtc"\s*:\s*null').Count -eq 1 -and
      [regex]::Matches($raw, '"committedUtc"\s*:\s*"[^\"]+"').Count -eq 0
    ) 'persisted noncommitted OPPO transaction committedUtc wire token changed.'
  }
}
function Assert-C34LOppoPersistedEvidence(
  [string]$Path,
  [ValidateSet('cold','retained')][string]$Kind,
  $Binding
) {
  try { $value = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json }
  catch { throw "C34L OPPO evidence writer rejected: $Kind evidence is not valid JSON." }
  Assert-C34LOppoEvidenceDocument $value $Kind $pairId $stateSha `
    $aggregateSha $state $sourceBinding
  Assert-C34LOppoWriter (
    (Get-C34LOppoSha $Path) -ceq [string]$Binding.sha256 -and
    (Get-Item -LiteralPath $Path).Length -eq [int64]$Binding.bytes
  ) "$Kind evidence payload hash or byte length changed."
}

Assert-C34LOppoWriter (
  (Get-C34LOppoSha $stateFile) -ceq $stateSha -and
  (Get-C34LOppoSha $aggregateFile) -ceq $aggregateSha -and
  (Get-C34LOppoSha $artifactFile) -ceq
    [string]$state.buildResult.artifactSha256 -and
  (Get-C34LOppoSha $attestation.SourceFile) -ceq $SourceAttestationSha256 -and
  (Get-C34LOppoSha $attestation.CaptureFile) -ceq
    [string]$sourceBinding.captureManifestSha256 -and
  (Get-C34LOppoSha $attestation.ContractFile) -ceq
    $captureArtifactContractSha256 -and
  (Get-C34LOppoSha $attestation.ColdArtifact.File) -ceq
    [string]$attestation.ColdArtifact.Binding.sha256 -and
  (Get-C34LOppoSha $attestation.RetainedArtifact.File) -ceq
    [string]$attestation.RetainedArtifact.Binding.sha256
) 'candidate, artifact, source-attestation or capture-artifact preimage changed before persistence.'

$coldExists = Test-Path -LiteralPath $coldFile -PathType Leaf
$retainedExists = Test-Path -LiteralPath $retainedFile -PathType Leaf
$journalExists = Test-Path -LiteralPath $transactionFile -PathType Leaf
if (-not $journalExists) {
  Assert-C34LOppoWriter (-not $coldExists -and -not $retainedExists) `
    'untracked OPPO evidence exists without its transaction journal.'
  $now = [DateTimeOffset]::UtcNow
  Assert-C34LOppoWriter (
    $attestation.Produced -le $now.AddSeconds(30) -and
    $attestation.Expires -gt $now.AddSeconds(-30)
  ) 'fresh OPPO transaction requires a current attested session.'
  Invoke-C34LOppoCrash 'before-journal'
  $preparedUtc = $now.ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture
  )
  $journal = [pscustomobject][ordered]@{
    schemaVersion=1
    transactionContractId='MOOLSOCIAL-C34L-OPPO-EVIDENCE-TRANSACTION-001'
    transactionId=$transactionId; ticketId=$ticketId; attempt=$Attempt
    status='prepared'; preStateSha256=$stateSha
    preAggregateSha256=$aggregateSha
    artifactSha256=[string]$state.buildResult.artifactSha256
    artifactBytes=[int64]$state.buildResult.artifactBytes
    deviceBindingSha256=$deviceBindingSha256
    coldStart=$coldBinding; retainedData=$retainedBinding
    sourceAttestation=$sourceBinding; preparedUtc=$preparedUtc
    committedUtc=$null
  }
  Save-C34LOppoJournal $journal -CreateOnly
} else {
  $journal = Read-C34LOppoJournal $transactionFile $transactionId $stateSha `
    $aggregateSha $state $coldBinding $retainedBinding $sourceBinding `
    $attestation.Produced $attestation.Expires
}

$coldExists = Test-Path -LiteralPath $coldFile -PathType Leaf
$retainedExists = Test-Path -LiteralPath $retainedFile -PathType Leaf
Assert-C34LOppoWriter (-not $retainedExists -or $coldExists) `
  'retained OPPO evidence exists without cold-start evidence.'
if ($coldExists) {
  Assert-C34LOppoPersistedEvidence $coldFile 'cold' $coldBinding
}
if ($retainedExists) {
  Assert-C34LOppoPersistedEvidence $retainedFile 'retained' $retainedBinding
}
switch ([string]$journal.status) {
  'committed' {
    Assert-C34LOppoWriter ($coldExists -and $retainedExists) `
      'committed OPPO transaction is missing evidence.'
  }
  'both_moved' {
    Assert-C34LOppoWriter ($coldExists -and $retainedExists) `
      'both-moved OPPO transaction is missing evidence.'
  }
  'cold_moved' {
    Assert-C34LOppoWriter $coldExists `
      'cold-moved OPPO transaction is missing cold evidence.'
  }
}
if ([string]$journal.status -ceq 'prepared' -and
    -not $coldExists -and -not $retainedExists) {
  Invoke-C34LOppoCrash 'prepared-none'
}
if (-not $coldExists) {
  Write-C34LOppoImmutableText $coldFile $coldJson
  Assert-C34LOppoPersistedEvidence $coldFile 'cold' $coldBinding
  $coldExists = $true
  Invoke-C34LOppoCrash 'cold-file-moved'
}
if ([string]$journal.status -ceq 'prepared') {
  $journal.status = 'cold_moved'
  Save-C34LOppoJournal $journal
}
if (-not $retainedExists) { Invoke-C34LOppoCrash 'cold-moved' }
if (-not $retainedExists) {
  Write-C34LOppoImmutableText $retainedFile $retainedJson
  Assert-C34LOppoPersistedEvidence $retainedFile 'retained' $retainedBinding
  $retainedExists = $true
  Invoke-C34LOppoCrash 'retained-file-moved'
}
if ([string]$journal.status -in @('prepared','cold_moved')) {
  $journal.status = 'both_moved'
  Save-C34LOppoJournal $journal
}
if ([string]$journal.status -ceq 'both_moved') {
  Invoke-C34LOppoCrash 'both-moved'
  $journal.status = 'committed'
  $journal.committedUtc = [DateTimeOffset]::UtcNow.ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture
  )
  Save-C34LOppoJournal $journal
}
Invoke-C34LOppoCrash 'committed'
Assert-C34LOppoWriter (
  (Get-C34LOppoSha $stateFile) -ceq $stateSha -and
  (Get-C34LOppoSha $aggregateFile) -ceq $aggregateSha -and
  (Get-C34LOppoSha $attestation.SourceFile) -ceq $SourceAttestationSha256 -and
  (Get-C34LOppoSha $attestation.CaptureFile) -ceq
    [string]$sourceBinding.captureManifestSha256 -and
  (Get-C34LOppoSha $attestation.ContractFile) -ceq
    $captureArtifactContractSha256 -and
  (Get-C34LOppoSha $attestation.ColdArtifact.File) -ceq
    [string]$attestation.ColdArtifact.Binding.sha256 -and
  (Get-C34LOppoSha $attestation.RetainedArtifact.File) -ceq
    [string]$attestation.RetainedArtifact.Binding.sha256 -and
  (Get-C34LOppoSha $coldFile) -ceq $coldIdentity.Sha256 -and
  (Get-C34LOppoSha $retainedFile) -ceq $retainedIdentity.Sha256
) 'candidate, attestation, capture artifact or evidence identity changed during persistence.'
Write-Output (([pscustomobject][ordered]@{
  ticketId = $ticketId
  attempt = $Attempt
  evidenceType = 'oppo_play_in_place_update_pair'
  evidencePairId = $pairId
  coldStart = $coldBinding
  retainedData = $retainedBinding
  sourceAttestation = $sourceBinding
  transactionJournal = [pscustomobject][ordered]@{
    path=$transactionRelative; status='committed'
  }
  preStateSha256 = $stateSha
  preAggregateSha256 = $aggregateSha
  deviceBindingSha256 = $deviceBindingSha256
  externalActionsPerformed = 0
  secretOrPrivateValuesRecorded = $false
}) | ConvertTo-Json -Depth 8 -Compress)
