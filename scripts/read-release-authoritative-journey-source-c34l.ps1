[CmdletBinding(DefaultParameterSetName = 'Production')]
param(
  [ValidateRange(1, 5)]
  [int]$Attempt = 1,
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34l.json',
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[0-9A-F]{64}$')]
  [string]$ChallengeSha256,
  [Parameter(Mandatory = $true)]
  [string]$OutputPath,
  [string]$RepositoryRoot,
  [Parameter(Mandatory = $true, ParameterSetName = 'Fixture')]
  [switch]$FixtureMode,
  [Parameter(Mandatory = $true, ParameterSetName = 'Fixture')]
  [string]$FixtureRunRoot,
  [Parameter(Mandatory = $true, ParameterSetName = 'Fixture')]
  [string]$FixtureGateAdapterPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$utf8 = [Text.UTF8Encoding]::new($false)
$ticketId =
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE'
$adapterId = 'MOOLSOCIAL-C34L-JOURNEY-GATE-OUTPUT-ADAPTER-001'
$gateReceiptContractId =
  'MOOLSOCIAL-C34L-EXECUTABLE-JOURNEY-GATE-RECEIPT-001'
$evidenceType = 'mandatory_whole_app_journey_acceptance'
$packageName = 'com.moolsocial.app'
$versionName = '1.0.0-r60.76'
$versionCode = '2026081376'
$journeyIds = @(
  'publicGuest', 'protectedGateway', 'supportedAuthentication', 'social',
  'wholeApp', 'c33gBlocker'
)

function Assert-C34LJourneySource([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34L authoritative journey source rejected: $Message"
  }
}

function Resolve-C34LJourneySourcePath(
  [string]$Path,
  [string]$Label,
  [switch]$AllowMissing,
  [switch]$Directory
) {
  Assert-C34LJourneySource (-not ($AllowMissing -and $Directory)) `
    "$Label cannot be both missing and a directory."
  Assert-C34LJourneySource (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LJourneySource (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) "$Label escaped the repository."
  $current = $resolved
  if (-not (Test-Path -LiteralPath $current)) { $current = Split-Path -Parent $current }
  while ($true) {
    Assert-C34LJourneySource (Test-Path -LiteralPath $current) `
      "$Label has a missing ancestor."
    Assert-C34LJourneySource (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse point."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $current = Split-Path -Parent $current
  }
  if ($Directory) {
    Assert-C34LJourneySource (
      Test-Path -LiteralPath $resolved -PathType Container
    ) "$Label is not a directory."
  } elseif (-not $AllowMissing) {
    Assert-C34LJourneySource (Test-Path -LiteralPath $resolved -PathType Leaf) `
      "$Label is missing."
    Assert-C34LJourneySource (
      -not ((Get-Item -LiteralPath $resolved -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label is a reparse point."
  }
  return $resolved
}

function Get-C34LJourneySourceRelative([string]$Resolved) {
  $full = [IO.Path]::GetFullPath($Resolved)
  Assert-C34LJourneySource (
    $full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) 'resolved path escaped the repository.'
  return $full.Substring($rootPrefix.Length).Replace('\', '/')
}

function Get-C34LJourneySourceSha([string]$Path) {
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Assert-C34LJourneySourceExactNames(
  $Value,
  [string]$Label,
  [string[]]$Names
) {
  Assert-C34LJourneySource ($null -ne $Value) "$Label is null."
  $actual = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LJourneySource ($actual.Count -eq $Names.Count) `
    "$Label property count changed."
  foreach ($name in $Names) {
    Assert-C34LJourneySource ($actual -ccontains $name) `
      "$Label is missing or has an unknown property at $name."
  }
}

function Assert-C34LJourneySourcePrivacy($Value, [string]$Label) {
  $json = $Value | ConvertTo-Json -Depth 30 -Compress
  $forbidden =
    '(?i)([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|https?://|www\.|(?:Bearer|Basic)\s+|AIza[0-9A-Za-z_-]{35}|-----BEGIN|Exception(?:\s*:|\r|\n)|StackTrace|Traceback\s*\(|(?<![A-Za-z0-9])2b3e0f71(?![A-Za-z0-9])|[?&][A-Za-z0-9_.%+-]+=|#[A-Za-z0-9_.%+-]+)'
  Assert-C34LJourneySource (-not [regex]::IsMatch($json, $forbidden)) `
    "$Label contains private, secret, URL, exception or raw-device material."
}

function ConvertTo-C34LJourneySourceUtc($Value, [string]$Label) {
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
  Assert-C34LJourneySource (
    $ok -and $parsed.ToUniversalTime().Offset -eq [TimeSpan]::Zero
  ) `
    "$Label must be one canonical UTC value."
  return $parsed.ToUniversalTime()
}

function Assert-C34LJourneySourceRawUtc(
  [string]$Raw,
  [string]$Name,
  [DateTimeOffset]$Instant,
  [string]$Label
) {
  $matches = [regex]::Matches(
    $Raw, '"' + [regex]::Escape($Name) + '"\s*:\s*"([^"]+)"'
  )
  $canonical = $Instant.ToUniversalTime().ToString(
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    [Globalization.CultureInfo]::InvariantCulture
  )
  Assert-C34LJourneySource (
    $matches.Count -eq 1 -and
    $matches[0].Groups[1].Value -ceq $canonical
  ) "$Label must have one exact raw .fffZ UTC token."
}

function Write-C34LJourneySourceImmutable([string]$Target, [string]$Json) {
  Assert-C34LJourneySource (-not (Test-Path -LiteralPath $Target)) `
    'the immutable raw journey receipt already exists.'
  $parent = Split-Path -Parent $Target
  Assert-C34LJourneySource (Test-Path -LiteralPath $parent -PathType Container) `
    'the raw journey receipt parent is missing.'
  [IO.File]::WriteAllText($Target, $Json, $utf8)
  Assert-C34LJourneySource (Test-Path -LiteralPath $Target -PathType Leaf) `
    'the immutable raw journey receipt write was incomplete.'
}

$sourceOwnerFile = [IO.Path]::GetFullPath($PSCommandPath)
$sourceOwnerRelative = Get-C34LJourneySourceRelative $sourceOwnerFile
Assert-C34LJourneySource (
  $sourceOwnerRelative -ceq 'scripts/read-release-authoritative-journey-source-c34l.ps1'
) 'the authoritative journey adapter source owner path changed.'
$sourceOwnerSha = Get-C34LJourneySourceSha $sourceOwnerFile
$sourceOwnerBytes = (Get-Item -LiteralPath $sourceOwnerFile).Length

$productionGateOwners = [ordered]@{
  publicGuest = $null
  protectedGateway = $null
  supportedAuthentication = $null
  social = $null
  wholeApp = $null
  c33gBlocker = $null
}

if (-not $FixtureMode) {
  Assert-C34LJourneySource (
    $StatePath -ceq 'config/successor-aab-regression-hard-gate-state-c34l.json'
  ) 'production requires the exact C34L detailed state path.'
  $missing = [Collections.Generic.List[string]]::new()
  foreach ($journeyId in $journeyIds) {
    if ([string]::IsNullOrWhiteSpace([string]$productionGateOwners[$journeyId])) {
      [void]$missing.Add("$adapterId`:$journeyId")
    }
  }
  Assert-C34LJourneySource ($missing.Count -eq 0) `
    ('missing_authoritative_adapter: ' + ($missing -join ','))
}

$fixtureRootRelative = $null
$fixtureGateOwnerFile = $null
if ($FixtureMode) {
  Assert-C34LJourneySource (
    $FixtureRunRoot -cmatch
      '^tmp/c34l-authoritative-capture-fixtures-[0-9a-f]{32}$'
  ) 'fixture run root does not have the exact unique form.'
  $fixtureRootFile = Resolve-C34LJourneySourcePath $FixtureRunRoot `
    'fixture run root' -Directory
  Assert-C34LJourneySource (Test-Path -LiteralPath $fixtureRootFile -PathType Container) `
    'fixture run root is not a directory.'
  $fixtureRootRelative = Get-C34LJourneySourceRelative $fixtureRootFile
  Assert-C34LJourneySource ($StatePath -ceq "$fixtureRootRelative/state.json") `
    'fixture state is outside the exact fixture run root.'
  Assert-C34LJourneySource (
    $OutputPath -ceq
      "$fixtureRootRelative/output/authoritative-journey-source-receipt.json"
  ) 'fixture output is outside the exact fixture run root.'
  $fixtureGateOwnerFile = Resolve-C34LJourneySourcePath $FixtureGateAdapterPath `
    'fixture gate adapter'
  $fixtureGateOwnerRelative = Get-C34LJourneySourceRelative $fixtureGateOwnerFile
  Assert-C34LJourneySource (
    $fixtureGateOwnerRelative.StartsWith(
      $fixtureRootRelative + '/', [StringComparison]::Ordinal
    )
  ) 'fixture gate adapter escaped the exact fixture run root.'
}

$stateFile = Resolve-C34LJourneySourcePath $StatePath 'detailed candidate state'
$stateRelative = Get-C34LJourneySourceRelative $stateFile
$stateSha = Get-C34LJourneySourceSha $stateFile
$state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
foreach ($name in @(
  'ticketId', 'candidate', 'aggregateStatePath', 'sourceQualification',
  'buildResult'
)) {
  Assert-C34LJourneySource ($null -ne $state.PSObject.Properties[$name]) `
    "detailed state is missing property $name."
}
Assert-C34LJourneySource (
  [string]$state.ticketId -ceq $ticketId -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$state.candidate.packageName -ceq $packageName -and
  [string]$state.candidate.versionName -ceq $versionName -and
  [string]$state.candidate.versionCode -ceq $versionCode
) 'candidate identity changed.'

$aggregateFile = Resolve-C34LJourneySourcePath ([string]$state.aggregateStatePath) `
  'aggregate candidate state'
$aggregateRelative = Get-C34LJourneySourceRelative $aggregateFile
if ($FixtureMode) {
  Assert-C34LJourneySource (
    $aggregateRelative -ceq "$fixtureRootRelative/aggregate.json"
  ) 'fixture aggregate escaped the exact fixture run root.'
} else {
  Assert-C34LJourneySource (
    $aggregateRelative -ceq
      'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
  ) 'production aggregate path changed.'
}
$aggregateSha = Get-C34LJourneySourceSha $aggregateFile
$aggregate = Get-Content -LiteralPath $aggregateFile -Raw | ConvertFrom-Json
Assert-C34LJourneySource (
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.versionName -ceq $versionName -and
  [string]$aggregate.candidate.versionCode -ceq $versionCode
) 'aggregate candidate identity changed.'

$artifactFile = Resolve-C34LJourneySourcePath ([string]$state.buildResult.artifactPath) `
  'candidate artifact'
$artifactRelative = Get-C34LJourneySourceRelative $artifactFile
$artifactSha = Get-C34LJourneySourceSha $artifactFile
$artifactBytes = (Get-Item -LiteralPath $artifactFile).Length
Assert-C34LJourneySource (
  [string]$state.buildResult.artifactSha256 -ceq $artifactSha -and
  [int64]$state.buildResult.artifactBytes -eq $artifactBytes -and
  $artifactBytes -gt 0
) 'candidate artifact preimage changed.'
if ($FixtureMode) {
  Assert-C34LJourneySource (
    $artifactRelative.StartsWith($fixtureRootRelative + '/',
      [StringComparison]::Ordinal)
  ) 'fixture artifact escaped the exact fixture run root.'
}

$sealFile = Resolve-C34LJourneySourcePath `
  ([string]$state.sourceQualification.manifestPath) 'sealed source manifest'
$sealRelative = Get-C34LJourneySourceRelative $sealFile
$sealSha = Get-C34LJourneySourceSha $sealFile
$sealBytes = (Get-Item -LiteralPath $sealFile).Length
Assert-C34LJourneySource (
  [string]$state.sourceQualification.manifestSha256 -ceq $sealSha -and
  [int64]$state.sourceQualification.manifestBytes -eq $sealBytes -and
  $sealBytes -gt 0
) 'sealed source manifest binding changed.'
if ($FixtureMode) {
  Assert-C34LJourneySource (
    $sealRelative.StartsWith($fixtureRootRelative + '/',
      [StringComparison]::Ordinal)
  ) 'fixture source seal escaped the exact fixture run root.'
}

$outputFile = Resolve-C34LJourneySourcePath $OutputPath `
  'raw journey receipt output' -AllowMissing
if (-not $FixtureMode) {
  $expectedOutput =
    ([string]$state.evidenceRoot).TrimEnd('/') +
    "/captures/attempt-$Attempt/journey/authoritative-source-receipt.json"
  Assert-C34LJourneySource ($OutputPath -ceq $expectedOutput) `
    'production raw journey receipt output path changed.'
}
Assert-C34LJourneySource (-not (Test-Path -LiteralPath $outputFile)) `
  'the immutable raw journey receipt already exists.'

$gateRows = [Collections.Generic.List[object]]::new()
$gateBindings = [Collections.Generic.List[object]]::new()
foreach ($journeyId in $journeyIds) {
  $gateOwnerFile = $fixtureGateOwnerFile
  if (-not $FixtureMode) {
    $gateOwnerFile = Resolve-C34LJourneySourcePath `
      ([string]$productionGateOwners[$journeyId]) "production gate owner $journeyId"
  }
  $gateOwnerRelative = Get-C34LJourneySourceRelative $gateOwnerFile
  $gateOwnerSha = Get-C34LJourneySourceSha $gateOwnerFile
  $gateOwnerBytes = (Get-Item -LiteralPath $gateOwnerFile).Length
  $gateReceiptRelative = if ($FixtureMode) {
    "$fixtureRootRelative/gate-receipts/$journeyId.json"
  } else {
    ([string]$state.evidenceRoot).TrimEnd('/') +
      "/captures/attempt-$Attempt/journey/gate-receipts/$journeyId.json"
  }
  $gateReceiptFile = Resolve-C34LJourneySourcePath $gateReceiptRelative `
    "gate receipt $journeyId" -AllowMissing
  Assert-C34LJourneySource (-not (Test-Path -LiteralPath $gateReceiptFile)) `
    "gate receipt already exists at $journeyId."
  $started = [DateTimeOffset]::UtcNow
  try {
    $invocationOutput = @(& $gateOwnerFile -JourneyId $journeyId `
      -Attempt $Attempt -StatePath $stateRelative `
      -ChallengeSha256 $ChallengeSha256 -OutputPath $gateReceiptRelative `
      -RepositoryRoot $root)
  } catch {
    throw "C34L authoritative journey source rejected: executable gate invocation failed at $journeyId."
  }
  Assert-C34LJourneySource ($invocationOutput.Count -eq 1) `
    "missing executable journey gate receipt at $journeyId."
  try { $binding = [string]$invocationOutput[0] | ConvertFrom-Json } catch {
    throw "C34L authoritative journey source rejected: gate binding schema failed at $journeyId."
  }
  Assert-C34LJourneySourceExactNames $binding "gate binding $journeyId" @(
    'path', 'sha256', 'bytes'
  )
  Assert-C34LJourneySource (
    [string]$binding.path -ceq $gateReceiptRelative -and
    [string]$binding.sha256 -cmatch '^[0-9A-F]{64}$' -and
    [int64]$binding.bytes -gt 0 -and
    (Test-Path -LiteralPath $gateReceiptFile -PathType Leaf)
  ) "gate binding changed at $journeyId."
  Assert-C34LJourneySource (
    (Get-C34LJourneySourceSha $gateReceiptFile) -ceq [string]$binding.sha256 -and
    (Get-Item -LiteralPath $gateReceiptFile).Length -eq [int64]$binding.bytes
  ) "gate receipt hash or bytes changed at $journeyId."
  $receiptRaw = Get-Content -LiteralPath $gateReceiptFile -Raw
  $receipt = $receiptRaw | ConvertFrom-Json
  Assert-C34LJourneySourceExactNames $receipt "gate receipt $journeyId" @(
    'schemaVersion', 'receiptContractId', 'journeyId', 'ticketId', 'attempt',
    'packageName', 'versionName', 'versionCode', 'challengeSha256',
    'preStateSha256', 'preAggregateSha256', 'artifactSha256', 'artifactBytes',
    'gateOutcome', 'exitCode', 'producedUtc'
  )
  Assert-C34LJourneySourcePrivacy $receipt "gate receipt $journeyId"
  $gateProduced = ConvertTo-C34LJourneySourceUtc $receipt.producedUtc `
    "gate producedUtc $journeyId"
  Assert-C34LJourneySourceRawUtc $receiptRaw 'producedUtc' $gateProduced `
    "gate producedUtc $journeyId"
  Assert-C34LJourneySource (
    [int]$receipt.schemaVersion -eq 1 -and
    [string]$receipt.receiptContractId -ceq $gateReceiptContractId -and
    [string]$receipt.journeyId -ceq $journeyId -and
    [string]$receipt.ticketId -ceq $ticketId -and
    [int]$receipt.attempt -eq $Attempt -and
    [string]$receipt.packageName -ceq $packageName -and
    [string]$receipt.versionName -ceq $versionName -and
    [string]$receipt.versionCode -ceq $versionCode -and
    [string]$receipt.challengeSha256 -ceq $ChallengeSha256 -and
    [string]$receipt.preStateSha256 -ceq $stateSha -and
    [string]$receipt.preAggregateSha256 -ceq $aggregateSha -and
    [string]$receipt.artifactSha256 -ceq $artifactSha -and
    [int64]$receipt.artifactBytes -eq $artifactBytes -and
    [string]$receipt.gateOutcome -ceq 'qualified' -and
    [int]$receipt.exitCode -eq 0 -and
    $gateProduced -ge $started.AddSeconds(-2) -and
    $gateProduced -le [DateTimeOffset]::UtcNow.AddSeconds(2)
  ) "executable gate receipt did not derive a qualified outcome at $journeyId."
  Assert-C34LJourneySource (
    (Get-C34LJourneySourceSha $gateOwnerFile) -ceq $gateOwnerSha -and
    (Get-Item -LiteralPath $gateOwnerFile).Length -eq $gateOwnerBytes
  ) "gate owner changed during execution at $journeyId."
  [void]$gateRows.Add([pscustomobject][ordered]@{
    journeyId = $journeyId
    owner = [pscustomobject][ordered]@{
      path = $gateOwnerRelative; sha256 = $gateOwnerSha; bytes = $gateOwnerBytes
    }
    receipt = [pscustomobject][ordered]@{
      path = $gateReceiptRelative
      sha256 = [string]$binding.sha256
      bytes = [int64]$binding.bytes
    }
    passed = $true
  })
  [void]$gateBindings.Add([pscustomobject]@{
    File = $gateReceiptFile; Sha256 = [string]$binding.sha256
    Bytes = [int64]$binding.bytes; OwnerFile = $gateOwnerFile
    OwnerSha256 = $gateOwnerSha; OwnerBytes = $gateOwnerBytes
  })
}

$producedUtc = [DateTimeOffset]::UtcNow.ToString(
  "yyyy-MM-dd'T'HH:mm:ss.fff'Z'", [Globalization.CultureInfo]::InvariantCulture
)
$rawReceipt = [pscustomobject][ordered]@{
  schemaVersion = 1
  adapterContractId = $adapterId
  adapterId = $adapterId
  evidenceType = $evidenceType
  ticketId = $ticketId
  attempt = $Attempt
  packageName = $packageName
  versionName = $versionName
  versionCode = $versionCode
  challengeSha256 = $ChallengeSha256
  preStateSha256 = $stateSha
  preAggregateSha256 = $aggregateSha
  artifactSha256 = $artifactSha
  artifactBytes = $artifactBytes
  sourceOwner = [pscustomobject][ordered]@{
    path = $sourceOwnerRelative; sha256 = $sourceOwnerSha; bytes = $sourceOwnerBytes
  }
  sourceSealManifest = [pscustomobject][ordered]@{
    path = $sealRelative; sha256 = $sealSha; bytes = $sealBytes
  }
  gates = $gateRows.ToArray()
  producedUtc = $producedUtc
}
Assert-C34LJourneySourcePrivacy $rawReceipt 'raw journey receipt'
$rawJson = ($rawReceipt | ConvertTo-Json -Depth 30) + [Environment]::NewLine

Assert-C34LJourneySource (
  (Get-C34LJourneySourceSha $stateFile) -ceq $stateSha -and
  (Get-C34LJourneySourceSha $aggregateFile) -ceq $aggregateSha -and
  (Get-C34LJourneySourceSha $artifactFile) -ceq $artifactSha -and
  (Get-C34LJourneySourceSha $sealFile) -ceq $sealSha -and
  (Get-C34LJourneySourceSha $sourceOwnerFile) -ceq $sourceOwnerSha
) 'candidate, artifact, source seal or adapter preimage changed before persistence.'
foreach ($gateBinding in $gateBindings) {
  Assert-C34LJourneySource (
    (Get-C34LJourneySourceSha $gateBinding.File) -ceq $gateBinding.Sha256 -and
    (Get-Item -LiteralPath $gateBinding.File).Length -eq $gateBinding.Bytes -and
    (Get-C34LJourneySourceSha $gateBinding.OwnerFile) -ceq
      $gateBinding.OwnerSha256 -and
    (Get-Item -LiteralPath $gateBinding.OwnerFile).Length -eq
      $gateBinding.OwnerBytes
  ) 'gate owner or receipt changed before persistence.'
}
Write-C34LJourneySourceImmutable $outputFile $rawJson
$outputSha = Get-C34LJourneySourceSha $outputFile
$outputBytes = (Get-Item -LiteralPath $outputFile).Length
Write-Output (([pscustomobject][ordered]@{
  path = $OutputPath
  sha256 = $outputSha
  bytes = $outputBytes
  adapterId = $adapterId
  challengeSha256 = $ChallengeSha256
}) | ConvertTo-Json -Compress)
