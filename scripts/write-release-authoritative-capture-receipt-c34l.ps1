[CmdletBinding(DefaultParameterSetName = 'Production')]
param(
  [Parameter(Mandatory)]
  [ValidateSet(
    'play_internal_testing_activation',
    'oppo_play_in_place_update_pair',
    'mandatory_whole_app_journey_acceptance'
  )]
  [string]$EvidenceType,
  [ValidateRange(1, 5)][int]$Attempt = 1,
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34l.json',
  [Parameter(Mandatory, ParameterSetName = 'Fixture')]
  [switch]$FixtureMode,
  [Parameter(Mandatory, ParameterSetName = 'Fixture')]
  [string]$FixtureRunRoot,
  [Parameter(Mandatory, ParameterSetName = 'Fixture')]
  [string]$FixtureAdapterPath,
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
$deviceBindingSha256 =
  '97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF'
$deviceModel = 'CPH2375'
$contractRelative = 'config/release-evidence-capture-artifact-contract-c34l.json'
$producerRelative = 'scripts/write-release-authoritative-capture-receipt-c34l.ps1'
$receiptContractId = 'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-RECEIPT-001'
$producerId = 'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-PRODUCER-001'
$journalContractId = 'MOOLSOCIAL-C34L-AUTHORITATIVE-CAPTURE-JOURNAL-001'
$countNames = @(
  'build','upload','install','deviceAcceptance','passwordlessEmailSend',
  'realSmsSend','otherTrack','backendHostingProviderOrProductionDeployment'
)
$authorityNames = @(
  'build','uploadAndInternalActivation','inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)
$utf8 = [Text.UTF8Encoding]::new($false)

function Assert-C34LProducer([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "C34L authoritative capture producer rejected: $Message"
  }
}

function Get-C34LSha([string]$Path) {
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-C34LTextSha([string]$Text) {
  $algorithm = [Security.Cryptography.SHA256]::Create()
  try { $bytes = $algorithm.ComputeHash($utf8.GetBytes($Text)) }
  finally { $algorithm.Dispose() }
  return ([BitConverter]::ToString($bytes)).Replace('-', '')
}

function Assert-C34LNoReparse([string]$Resolved, [string]$Label) {
  $current = if (Test-Path -LiteralPath $Resolved) {
    [IO.Path]::GetFullPath($Resolved)
  } else {
    [IO.Path]::GetFullPath((Split-Path -Parent $Resolved))
  }
  while ($true) {
    Assert-C34LProducer (
      $current.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
      $current.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) "$Label ancestor escaped the repository."
    Assert-C34LProducer (Test-Path -LiteralPath $current) `
      "$Label ancestor is missing."
    Assert-C34LProducer (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $current = [IO.Path]::GetFullPath((Split-Path -Parent $current))
  }
}

function Resolve-C34LRelative(
  [string]$Path,
  [string]$Label,
  [switch]$AllowMissing
) {
  Assert-C34LProducer (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path) -and
    -not $Path.Contains('\') -and -not $Path.Contains('?') -and
    -not $Path.Contains('#')
  ) "$Label must be one normalized repository-relative path."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LProducer (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) "$Label escaped the repository."
  Assert-C34LNoReparse $resolved $Label
  if (-not $AllowMissing) {
    Assert-C34LProducer (Test-Path -LiteralPath $resolved -PathType Leaf) `
      "$Label is missing."
    Assert-C34LProducer (
      -not ((Get-Item -LiteralPath $resolved -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) "$Label is a reparse point."
  } else {
    Assert-C34LProducer (-not (Test-Path -LiteralPath $resolved)) `
      "$Label immutable target already exists."
  }
  return $resolved
}

function Get-C34LRelative([string]$Path) {
  return ([IO.Path]::GetFullPath($Path)).Substring($rootPrefix.Length).
    Replace('\', '/')
}

function Get-C34LBinding([string]$Path) {
  return [pscustomobject][ordered]@{
    path = Get-C34LRelative $Path
    sha256 = Get-C34LSha $Path
    bytes = [int64](Get-Item -LiteralPath $Path).Length
  }
}

function Assert-C34LExactNames($Value, [string[]]$Names, [string]$Label) {
  $actual = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LProducer ($actual.Count -eq $Names.Count) `
    "$Label property count changed."
  foreach ($name in $Names) {
    Assert-C34LProducer ($actual -ccontains $name) `
      "$Label is missing or has an unknown property at $name."
  }
}

function Assert-C34LPrivacy($Value, [string]$Label, [string]$Path = '$') {
  if ($null -eq $Value) { return }
  $forbiddenName =
    '(?i)(email|phone|private|url|link|identifier|exception|stack|credential|secret|token|key|rawnonce|account|^(deviceSerial|serial|androidId|imei|imsi|advertisingId)$)'
  $forbiddenValue =
    '(?i)([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|https?://|www\.|(?:Bearer|Basic)\s+|AIza[0-9A-Za-z_-]{35}|-----BEGIN|Exception(?:\s*:|\r|\n)|StackTrace|Traceback\s*\(|(?<![A-Za-z0-9])2b3e0f71(?![A-Za-z0-9])|[?&][A-Za-z0-9_.%+-]+=|#[A-Za-z0-9_.%+-]+)'
  if ($Value -is [string]) {
    Assert-C34LProducer (-not [regex]::IsMatch([string]$Value, $forbiddenValue)) `
      "$Label contains a forbidden private value at $Path."
    return
  }
  if ($Value -is [Collections.IEnumerable] -and
      $Value -isnot [Management.Automation.PSCustomObject] -and
      $Value -isnot [Collections.IDictionary]) {
    $index = 0
    foreach ($item in $Value) {
      Assert-C34LPrivacy $item $Label "$Path[$index]"
      $index++
    }
    return
  }
  if ($Value -isnot [Management.Automation.PSCustomObject] -and
      $Value -isnot [Collections.IDictionary]) { return }
  foreach ($property in @($Value.PSObject.Properties)) {
    $schemaNameAllowed =
      ($Path -ceq '$.actionCounts' -and
        $countNames -ccontains $property.Name) -or
      ($Path -ceq '$.releaseAuthorities' -and
        $authorityNames -ccontains $property.Name)
    $allowed = $property.Name -cin @(
      'sourceManifest','sourceManifestPath','sourceManifestSha256',
      'sourceManifestBytes','deviceBindingSha256'
    )
    Assert-C34LProducer (
      $schemaNameAllowed -or $allowed -or
      -not [regex]::IsMatch($property.Name, $forbiddenName)
    ) "$Label contains forbidden property $($property.Name)."
    Assert-C34LPrivacy $property.Value $Label "$Path.$($property.Name)"
  }
}

function Write-C34LAtomic([string]$Path, [string]$Text, [switch]$CreateOnly) {
  $directory = Split-Path -Parent $Path
  Assert-C34LProducer (Test-Path -LiteralPath $directory -PathType Container) `
    'atomic output directory is not an existing producer-owned directory.'
  Assert-C34LNoReparse $directory 'atomic output directory'
  if ($CreateOnly) {
    Assert-C34LProducer (-not (Test-Path -LiteralPath $Path)) `
      'immutable output already exists.'
  }
  $temporary = Join-Path $directory (
    '.' + [IO.Path]::GetFileName($Path) + '.' + [Guid]::NewGuid().ToString('N') +
    '.tmp'
  )
  try {
    [IO.File]::WriteAllText($temporary, $Text, $utf8)
    if ($CreateOnly) {
      Assert-C34LProducer (-not (Test-Path -LiteralPath $Path)) `
        'immutable output appeared before commit.'
    }
    Move-Item -LiteralPath $temporary -Destination $Path -Force
  } finally {
    if (Test-Path -LiteralPath $temporary) {
      Remove-Item -LiteralPath $temporary -Force
    }
  }
}

function Initialize-C34LProducerDirectory(
  [string]$Path,
  [string]$AllowedBase,
  [string]$Label
) {
  $resolved = [IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\','/'))
  $base = [IO.Path]::GetFullPath($AllowedBase).TrimEnd([char[]]@('\','/'))
  $basePrefix = $base + [IO.Path]::DirectorySeparatorChar
  Assert-C34LProducer (
    $resolved.StartsWith($basePrefix,[StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $base -PathType Container)
  ) "$Label escaped or lost its exact existing base."
  Assert-C34LNoReparse $base "$Label base"
  $relative = $resolved.Substring($basePrefix.Length)
  $segments = @($relative.Split(
    [IO.Path]::DirectorySeparatorChar,
    [StringSplitOptions]::RemoveEmptyEntries
  ))
  Assert-C34LProducer (
    $segments.Count -gt 0 -and -not ($segments -ccontains '..') -and
    -not ($segments -ccontains '.')
  ) "$Label has an invalid producer-owned component chain."
  $current = $base
  foreach ($segment in $segments) {
    Assert-C34LProducer (
      -not [string]::IsNullOrWhiteSpace($segment) -and
      $segment -cnotmatch '[\\/:*?"<>|]'
    ) "$Label has a noncanonical component."
    $current = Join-Path $current $segment
    if (Test-Path -LiteralPath $current) {
      Assert-C34LProducer (Test-Path -LiteralPath $current -PathType Container) `
        "$Label has an existing file where a directory is required."
      Assert-C34LProducer (
        -not ((Get-Item -LiteralPath $current -Force).Attributes -band
          [IO.FileAttributes]::ReparsePoint)
      ) "$Label contains a reparse-point component."
    } else {
      [void](New-Item -ItemType Directory -Path $current)
      Assert-C34LProducer (
        (Test-Path -LiteralPath $current -PathType Container) -and
        -not ((Get-Item -LiteralPath $current -Force).Attributes -band
          [IO.FileAttributes]::ReparsePoint)
      ) "$Label component creation failed confinement."
    }
  }
  Assert-C34LProducer (
    [IO.Path]::GetFullPath($current).Equals(
      $resolved,[StringComparison]::OrdinalIgnoreCase)
  ) "$Label final directory identity changed."
  Assert-C34LNoReparse $resolved $Label
  return $resolved
}

function ConvertTo-C34LJson($Value) {
  return ($Value | ConvertTo-Json -Depth 50) + [Environment]::NewLine
}

function Get-C34LLatestJournal(
  $State,
  [string]$StateRelative,
  [string]$AggregateRelative,
  [string]$StateSha,
  [string]$AggregateSha,
  [string]$FixtureRootRelative
) {
  $proofs = @($State.lifecycleTransactionProofs)
  Assert-C34LProducer ($proofs.Count -gt 0) `
    'missing_authoritative_adapter: committed_transition_challenge'
  $journalRootRelative = if ($FixtureMode) {
    "$FixtureRootRelative/journals"
  } else {
    ([string]$State.evidenceRoot).TrimEnd('/') + '/release-transaction-journals'
  }
  $journalRoot = [IO.Path]::GetFullPath((Join-Path $root $journalRootRelative))
  Assert-C34LNoReparse $journalRoot 'transition journal root'
  Assert-C34LProducer (Test-Path -LiteralPath $journalRoot -PathType Container) `
    'missing_authoritative_adapter: committed_transition_challenge'
  $journals = @(Get-ChildItem -LiteralPath $journalRoot -Filter '*.json' -File)
  Assert-C34LProducer ($journals.Count -eq $proofs.Count) `
    'transition journal and proof history cardinality changed.'
  $rows = foreach ($file in $journals) {
    $raw = Get-Content -Raw -LiteralPath $file.FullName
    try { $value = $raw | ConvertFrom-Json }
    catch { throw 'C34L authoritative capture producer rejected: transition journal is not valid JSON.' }
    Assert-C34LProducer (
      [int]$value.schemaVersion -eq 1 -and
      [string]$value.ticketId -ceq $ticketId -and
      [int]$value.attempt -eq $Attempt -and
      [string]$value.statePath -ceq $StateRelative -and
      [string]$value.aggregateStatePath -ceq $AggregateRelative -and
      [string]$value.status -cin @('committed','reconciled_committed') -and
      [int]$value.sequence -gt 0
    ) 'transition journal identity, status or sequence changed.'
    [pscustomobject]@{ File=$file; Value=$value; Sequence=[int]$value.sequence }
  }
  $ordered = @($rows | Sort-Object Sequence)
  for ($index = 0; $index -lt $ordered.Count; $index++) {
    Assert-C34LProducer ($ordered[$index].Sequence -eq ($index + 1)) `
      'transition journal sequence has a gap or reset.'
  }
  Assert-C34LProducer (
    [string]$ordered[-1].Value.stateAfterSha256 -ceq $StateSha -and
    [string]$ordered[-1].Value.aggregateAfterSha256 -ceq $AggregateSha
  ) 'newest transition journal current postimage changed.'
  return $ordered[-1]
}

function Invoke-C34LFixtureAdapter(
  [string]$AdapterPath,
  [string]$OutputPath,
  [string]$Challenge,
  [string]$FixtureRoot
) {
  & $AdapterPath -EvidenceType $EvidenceType -Attempt $Attempt `
    -StatePath $StatePath -ChallengeSha256 $Challenge `
    -OutputPath (Get-C34LRelative $OutputPath) -FixtureMode `
    -FixtureRunRoot $FixtureRoot -RepositoryRoot $root
  Assert-C34LProducer (Test-Path -LiteralPath $OutputPath -PathType Leaf) `
    'fixture observation adapter did not create its exact output.'
}

function Invoke-C34LProductionAdapter(
  [string]$OutputPath,
  [string]$Challenge
) {
  if ($EvidenceType -ceq 'play_internal_testing_activation') {
    $workflow = $state.presealUploadWorkflow
    $browserGate = Resolve-C34LRelative `
      'scripts/check-release-blocker-browser-proof-integration-c34l.ps1' `
      'Play browser proof validator'
    & $browserGate -Phase preupload -StatePath $StatePath `
      -SourceManifestPath ([string]$workflow.sourceManifestPath) `
      -SourceManifestSha256 ([string]$workflow.sourceManifestSha256) `
      -SourceManifestBytes ([int64]$workflow.sourceManifestBytes) `
      -BlockerLedgerPath ([string]$workflow.blockerLedgerPath) `
      -BlockerLedgerSha256 ([string]$workflow.blockerLedgerSha256) `
      -BlockerLedgerBytes ([int64]$workflow.blockerLedgerBytes) `
      -BrowserProofPath ([string]$workflow.browserEvidencePath) `
      -BrowserProofSha256 ([string]$workflow.browserEvidenceSha256) `
      -BrowserProofBytes ([int64]$workflow.browserEvidenceBytes) `
      -Attempt $Attempt -RequirePersistedBrowserBinding -RepositoryRoot $root | Out-Null
    throw ('C34L authoritative capture producer rejected: ' +
      'missing_authoritative_adapter: ' +
      'MOOLSOCIAL-C34L-PLAY-INTERNAL-TRANSACTION-OBSERVATION-001')
  }
  if ($EvidenceType -ceq 'oppo_play_in_place_update_pair') {
    throw ('C34L authoritative capture producer rejected: ' +
      'missing_authoritative_adapter: ' +
      'MOOLSOCIAL-C34L-OPPO-READONLY-INTERACTIVE-RETENTION-ADAPTER-001')
  }
  $journeyAdapterRelative =
    'scripts/read-release-authoritative-journey-source-c34l.ps1'
  if (-not (Test-Path -LiteralPath (Join-Path $root $journeyAdapterRelative))) {
    throw ('C34L authoritative capture producer rejected: ' +
      'missing_authoritative_adapter: ' +
      'MOOLSOCIAL-C34L-JOURNEY-GATE-OUTPUT-ADAPTER-001')
  }
  $adapter = Resolve-C34LRelative $journeyAdapterRelative `
    'authoritative journey adapter'
  & $adapter -Attempt $Attempt -StatePath $StatePath `
    -ChallengeSha256 $Challenge -OutputPath (Get-C34LRelative $OutputPath) `
    -RepositoryRoot $root
}

$contractFile = Resolve-C34LRelative $contractRelative 'capture contract'
$contract = Get-Content -Raw -LiteralPath $contractFile | ConvertFrom-Json
Assert-C34LProducer (
  [int]$contract.schemaVersion -eq 3 -and
  [string]$contract.contractId -ceq
    'MOOLSOCIAL-C34L-CAPTURE-ARTIFACT-CONTRACT-003' -and
  [string]$contract.productionProducer.producerId -ceq $producerId -and
  [string]$contract.productionProducer.ownerPath -ceq $producerRelative -and
  [string]$contract.productionProducer.receiptContractId -ceq $receiptContractId
) 'capture producer contract identity changed.'
$contractBinding = Get-C34LBinding $contractFile
$producerFile = Resolve-C34LRelative $producerRelative 'capture producer owner'
$producerBinding = Get-C34LBinding $producerFile

$stateFile = Resolve-C34LRelative $StatePath 'detailed candidate state'
$stateRelative = Get-C34LRelative $stateFile
$fixtureRootRelative = $null
if ($FixtureMode) {
  Assert-C34LProducer (
    $FixtureRunRoot -cmatch '^tmp/c34l-authoritative-capture-fixtures-[0-9a-f]{32}$'
  ) 'fixture run root is not one exact unique confined root.'
  $fixtureRoot = [IO.Path]::GetFullPath((Join-Path $root $FixtureRunRoot))
  Assert-C34LNoReparse $fixtureRoot 'fixture run root'
  Assert-C34LProducer (Test-Path -LiteralPath $fixtureRoot -PathType Container) `
    'fixture run root is missing.'
  $fixtureRootRelative = $FixtureRunRoot
  Assert-C34LProducer ($stateRelative -ceq "$FixtureRunRoot/state.json") `
    'fixture state escaped the exact fixture run root.'
  $adapterFile = Resolve-C34LRelative $FixtureAdapterPath 'fixture adapter'
  Assert-C34LProducer (
    (Get-C34LRelative $adapterFile) -ceq "$FixtureRunRoot/adapters/$EvidenceType.ps1"
  ) 'fixture adapter escaped its exact type-owned path.'
} else {
  Assert-C34LProducer (
    $PSCmdlet.ParameterSetName -ceq 'Production' -and
    $stateRelative -ceq
      'config/successor-aab-regression-hard-gate-state-c34l.json'
  ) 'production producer requires the exact production parameter set and state.'
  if ($EvidenceType -ceq 'play_internal_testing_activation') {
    throw ('C34L authoritative capture producer rejected: ' +
      'missing_authoritative_adapter: ' +
      'MOOLSOCIAL-C34L-PLAY-INTERNAL-TRANSACTION-OBSERVATION-001')
  }
  if ($EvidenceType -ceq 'oppo_play_in_place_update_pair') {
    throw ('C34L authoritative capture producer rejected: ' +
      'missing_authoritative_adapter: ' +
      'MOOLSOCIAL-C34L-OPPO-READONLY-INTERACTIVE-RETENTION-ADAPTER-001')
  }
}

$stateRaw = Get-Content -Raw -LiteralPath $stateFile
$state = $stateRaw | ConvertFrom-Json
$aggregateFile = Resolve-C34LRelative ([string]$state.aggregateStatePath) `
  'aggregate candidate state'
$aggregateRelative = Get-C34LRelative $aggregateFile
if ($FixtureMode) {
  Assert-C34LProducer ($aggregateRelative -ceq "$FixtureRunRoot/aggregate.json") `
    'fixture aggregate escaped the exact fixture run root.'
} else {
  Assert-C34LProducer (
    $aggregateRelative -ceq
      'config/successor-aab-regression-hard-gate-aggregate-c34l.json'
  ) 'production aggregate owner changed.'
}
$aggregateRaw = Get-Content -Raw -LiteralPath $aggregateFile
$aggregate = $aggregateRaw | ConvertFrom-Json
$stateSha = Get-C34LSha $stateFile
$aggregateSha = Get-C34LSha $aggregateFile
Assert-C34LExactNames $state.actionCounts $countNames 'state actionCounts'
Assert-C34LExactNames $aggregate.actionCounts $countNames `
  'aggregate actionCounts'
Assert-C34LExactNames $state.releaseAuthorities $authorityNames `
  'state releaseAuthorities'
Assert-C34LExactNames $aggregate.releaseAuthorities $authorityNames `
  'aggregate releaseAuthorities'
Assert-C34LProducer (
  [string]$state.ticketId -ceq $ticketId -and
  [string]$aggregate.ticketId -ceq $ticketId -and
  [string]$state.candidate.id -ceq $ticketId -and
  [string]$aggregate.candidate.id -ceq $ticketId -and
  [string]$state.candidate.packageName -ceq $packageName -and
  [string]$state.candidate.versionName -ceq $versionName -and
  [string]$state.candidate.versionCode -ceq $versionCode -and
  [string]$aggregate.candidate.versionName -ceq $versionName -and
  [string]$aggregate.candidate.versionCode -ceq $versionCode -and
  (ConvertTo-Json $state.actionCounts -Compress) -ceq
    (ConvertTo-Json $aggregate.actionCounts -Compress) -and
  (ConvertTo-Json $state.releaseAuthorities -Compress) -ceq
    (ConvertTo-Json $aggregate.releaseAuthorities -Compress)
) 'candidate identity or detailed/aggregate vector changed.'

$manifestFile = Resolve-C34LRelative ([string]$state.sourceQualification.manifestPath) `
  'sealed source manifest'
$manifestBinding = Get-C34LBinding $manifestFile
Assert-C34LProducer (
  [string]$state.sourceQualification.manifestSha256 -ceq
    [string]$manifestBinding.sha256 -and
  [int64]$state.sourceQualification.manifestBytes -eq
    [int64]$manifestBinding.bytes
) 'sealed source manifest binding changed.'
$artifactFile = Resolve-C34LRelative ([string]$state.buildResult.artifactPath) `
  'sealed AAB artifact'
$artifactBinding = Get-C34LBinding $artifactFile
Assert-C34LProducer (
  [string]$state.buildResult.artifactSha256 -ceq [string]$artifactBinding.sha256 -and
  [int64]$state.buildResult.artifactBytes -eq [int64]$artifactBinding.bytes -and
  [int64]$artifactBinding.bytes -gt 0
) 'sealed AAB artifact binding changed.'

$latest = Get-C34LLatestJournal $state $stateRelative $aggregateRelative `
  $stateSha $aggregateSha $fixtureRootRelative
$latestBinding = Get-C34LBinding $latest.File.FullName
$challengeMaterial = @(
  $journalContractId, $ticketId, [string]$Attempt,
  [string]$latestBinding.path, [string]$latestBinding.sha256,
  [string]$latest.Value.transactionId, [string]$latest.Value.sequence,
  [string]$latest.Value.stateAfterSha256,
  [string]$latest.Value.aggregateAfterSha256,
  [string]$producerBinding.sha256, [string]$manifestBinding.sha256
) -join '|'
$challengeSha = Get-C34LTextSha $challengeMaterial
$sessionHash = Get-C34LTextSha (
  "$challengeSha|$($producerBinding.sha256)|$($manifestBinding.sha256)"
)
$sessionId = 'c34l-authoritative-session-' +
  $sessionHash.Substring(0, 24).ToLowerInvariant()

$evidenceRootRelative = if ($FixtureMode) {
  "$FixtureRunRoot/evidence"
} else {
  [string]$state.evidenceRoot
}
$journalRootRelative =
  "$evidenceRootRelative/authoritative-capture-journals/attempt-$Attempt"
$journalRoot = [IO.Path]::GetFullPath((Join-Path $root $journalRootRelative))
$previousRows = @()
if (Test-Path -LiteralPath $journalRoot -PathType Container) {
  Assert-C34LNoReparse $journalRoot 'authoritative capture journal root'
  foreach ($previousFile in @(
      Get-ChildItem -LiteralPath $journalRoot -Filter '*.json' -File
    )) {
    $previousRaw = Get-Content -Raw -LiteralPath $previousFile.FullName
    try { $previousValue = $previousRaw | ConvertFrom-Json }
    catch {
      throw 'C34L authoritative capture producer rejected: prior capture journal is not valid JSON.'
    }
    Assert-C34LProducer (
      [int]$previousValue.schemaVersion -eq 1 -and
      [string]$previousValue.journalContractId -ceq $journalContractId -and
      [string]$previousValue.ticketId -ceq $ticketId -and
      [int]$previousValue.attempt -eq $Attempt -and
      [int]$previousValue.sequence -gt 0 -and
      [string]$previousValue.status -ceq 'committed' -and
      [string]$previousValue.challengeSha256 -cne $challengeSha
    ) 'prior capture journal identity, status or single-use challenge changed.'
    $previousRows += [pscustomobject]@{
      File=$previousFile;Value=$previousValue
      Sequence=[int]$previousValue.sequence
    }
  }
}
$orderedPrevious = @($previousRows | Sort-Object Sequence)
$expectedPreviousHead = '0' * 64
for ($index = 0; $index -lt $orderedPrevious.Count; $index++) {
  Assert-C34LProducer (
    $orderedPrevious[$index].Sequence -eq ($index + 1) -and
    [string]$orderedPrevious[$index].Value.previousJournalHeadSha256 -ceq
      $expectedPreviousHead
  ) 'prior capture journal sequence or hash chain changed.'
  $expectedPreviousHead = Get-C34LSha $orderedPrevious[$index].File.FullName
}
$previousHead = $expectedPreviousHead
$kind = [string]$contract.evidenceTypes.$EvidenceType.kind
Assert-C34LProducer ($kind -cin @('play','oppo','journey')) `
  'capture contract evidence kind changed.'
$captureRootRelative = "$evidenceRootRelative/captures/attempt-$Attempt/$kind"
$adapterOutputRelative = if ($FixtureMode) {
  "$FixtureRunRoot/adapter-output/$EvidenceType.json"
} else {
  "$evidenceRootRelative/observation-sources/attempt-$Attempt/$kind.json"
}
$adapterOutput = [IO.Path]::GetFullPath((Join-Path $root $adapterOutputRelative))
Assert-C34LProducer (
  $adapterOutput.StartsWith($rootPrefix,[StringComparison]::OrdinalIgnoreCase) -and
  -not (Test-Path -LiteralPath $adapterOutput)
) 'observation adapter output escaped or already exists.'
$adapterOutputBase = if ($FixtureMode) {
  [IO.Path]::GetFullPath((Join-Path $root $FixtureRunRoot))
} else {
  [IO.Path]::GetFullPath((Join-Path $root $evidenceRootRelative))
}
Assert-C34LNoReparse $adapterOutputBase 'observation adapter output base'
if ($FixtureMode) {
  Invoke-C34LFixtureAdapter $adapterFile $adapterOutput $challengeSha $FixtureRunRoot
} else {
  Invoke-C34LProductionAdapter $adapterOutput $challengeSha
}
$adapterOutput = Resolve-C34LRelative $adapterOutputRelative `
  'observation adapter output'
$adapterRaw = Get-Content -Raw -LiteralPath $adapterOutput
try { $adapter = $adapterRaw | ConvertFrom-Json }
catch { throw 'C34L authoritative capture producer rejected: observation adapter output is not valid JSON.' }
if ($EvidenceType -ceq 'mandatory_whole_app_journey_acceptance') {
  Assert-C34LExactNames $adapter @(
    'schemaVersion','adapterContractId','adapterId','evidenceType','ticketId',
    'attempt','packageName','versionName','versionCode','challengeSha256',
    'preStateSha256','preAggregateSha256','artifactSha256','artifactBytes',
    'sourceOwner','sourceSealManifest','gates','producedUtc'
  ) 'journey observation adapter receipt'
  $adapterSeal = $adapter.sourceSealManifest
} else {
  Assert-C34LExactNames $adapter @(
    'schemaVersion','adapterId','evidenceType','ticketId','attempt',
    'challengeSha256','sourceOwner','sealedSourceManifest','artifacts','producedUtc'
  ) 'observation adapter receipt'
  $adapterSeal = $adapter.sealedSourceManifest
}
Assert-C34LPrivacy $adapter 'observation adapter receipt'
$producedUtcMatch = [regex]::Matches(
  $adapterRaw,
  '"producedUtc"\s*:\s*"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[.]\d{3}Z)"'
)
Assert-C34LProducer (
  [int]$adapter.schemaVersion -eq 1 -and
  [string]$adapter.adapterId -ceq
    [string]$contract.evidenceTypes.$EvidenceType.productionAdapterId -and
  [string]$adapter.evidenceType -ceq $EvidenceType -and
  [string]$adapter.ticketId -ceq $ticketId -and
  [int]$adapter.attempt -eq $Attempt -and
  [string]$adapter.challengeSha256 -ceq $challengeSha -and
  $producedUtcMatch.Count -eq 1 -and
  [string]$adapterSeal.path -ceq [string]$manifestBinding.path -and
  [string]$adapterSeal.sha256 -ceq [string]$manifestBinding.sha256 -and
  [int64]$adapterSeal.bytes -eq [int64]$manifestBinding.bytes
) 'observation adapter identity, challenge or sealed source changed.'
$adapterOwner = Resolve-C34LRelative ([string]$adapter.sourceOwner.path) `
  'observation adapter source owner'
$adapterOwnerBinding = Get-C34LBinding $adapterOwner
Assert-C34LProducer (
  [string]$adapter.sourceOwner.sha256 -ceq [string]$adapterOwnerBinding.sha256 -and
  [int64]$adapter.sourceOwner.bytes -eq [int64]$adapterOwnerBinding.bytes
) 'observation adapter source-owner binding changed.'
if ($FixtureMode) {
  Assert-C34LProducer (
    ([string]$adapterOwnerBinding.path).StartsWith(
      "$FixtureRunRoot/adapters/", [StringComparison]::Ordinal
    )
  ) 'fixture adapter source owner escaped the exact fixture root.'
}

$expectedRoles = @($contract.evidenceTypes.$EvidenceType.roles)
$observationSourceBindings = @((Get-C34LBinding $adapterOutput))
if ($EvidenceType -ceq 'mandatory_whole_app_journey_acceptance') {
  Assert-C34LProducer (
    [string]$adapter.adapterContractId -ceq
      'MOOLSOCIAL-C34L-JOURNEY-GATE-OUTPUT-ADAPTER-001' -and
    [string]$adapter.packageName -ceq $packageName -and
    [string]$adapter.versionName -ceq $versionName -and
    [string]$adapter.versionCode -ceq $versionCode -and
    [string]$adapter.preStateSha256 -ceq $stateSha -and
    [string]$adapter.preAggregateSha256 -ceq $aggregateSha -and
    [string]$adapter.artifactSha256 -ceq [string]$artifactBinding.sha256 -and
    [int64]$adapter.artifactBytes -eq [int64]$artifactBinding.bytes
  ) 'journey adapter candidate preimage or artifact binding changed.'
  $journeyIds = @(
    'publicGuest','protectedGateway','supportedAuthentication',
    'social','wholeApp','c33gBlocker'
  )
  $gates = @($adapter.gates)
  Assert-C34LProducer (
    $gates.Count -eq $journeyIds.Count -and
    (@($gates.journeyId) -join ',') -ceq ($journeyIds -join ',')
  ) 'journey adapter gate set or order changed.'
  foreach ($gate in $gates) {
    Assert-C34LExactNames $gate @('journeyId','owner','receipt','passed') `
      'journey adapter gate row'
    Assert-C34LExactNames $gate.owner @('path','sha256','bytes') `
      'journey gate owner binding'
    Assert-C34LExactNames $gate.receipt @('path','sha256','bytes') `
      'journey gate receipt binding'
    Assert-C34LProducer ([bool]$gate.passed) `
      "journey gate did not pass at $($gate.journeyId)."
    $gateBindings = @($gate.owner, $gate.receipt)
    for ($bindingIndex = 0; $bindingIndex -lt $gateBindings.Count;
        $bindingIndex++) {
      $binding = $gateBindings[$bindingIndex]
      $sourceFile = Resolve-C34LRelative ([string]$binding.path) `
        'journey gate source binding'
      $actualBinding = Get-C34LBinding $sourceFile
      Assert-C34LProducer (
        [string]$binding.sha256 -ceq [string]$actualBinding.sha256 -and
        [int64]$binding.bytes -eq [int64]$actualBinding.bytes
      ) 'journey gate source SHA-256 or byte length changed.'
      if ($FixtureMode) {
        Assert-C34LProducer (
          ([string]$actualBinding.path).StartsWith(
            "$FixtureRunRoot/", [StringComparison]::Ordinal
          )
        ) 'fixture journey gate source escaped the exact fixture run root.'
      }
      if ($bindingIndex -eq 1) {
        $observationSourceBindings += $actualBinding
      }
    }
  }
  $artifactRows = @()
} else {
  $artifactRows = @($adapter.artifacts)
}
$captureRoot = [IO.Path]::GetFullPath((Join-Path $root $captureRootRelative))
$evidenceRoot = [IO.Path]::GetFullPath((Join-Path $root $evidenceRootRelative))
$captureRoot = Initialize-C34LProducerDirectory $captureRoot $evidenceRoot `
  'capture output root'
if ($EvidenceType -ceq 'mandatory_whole_app_journey_acceptance') {
  $journeyRoot = Join-Path $captureRoot 'journeys'
  $journeyRoot = Initialize-C34LProducerDirectory $journeyRoot $captureRoot `
    'journey capture output root'
}
$artifactBindings = @()
$digestMap = [ordered]@{}
if ($EvidenceType -ceq 'mandatory_whole_app_journey_acceptance') {
  $journeyRows = @()
  foreach ($gate in $gates) {
    $journeyRelative =
      "$captureRootRelative/journeys/$($gate.journeyId).json"
    $journeyFile = Resolve-C34LRelative $journeyRelative `
      "journey capture $($gate.journeyId)" -AllowMissing
    $journeyPayload = [pscustomobject][ordered]@{
      schemaVersion=1;journeyId=[string]$gate.journeyId;ticketId=$ticketId
      attempt=$Attempt;packageName=$packageName;versionName=$versionName
      versionCode=$versionCode;artifactSha256=[string]$artifactBinding.sha256
      artifactBytes=[int64]$artifactBinding.bytes
      deviceBindingSha256=$deviceBindingSha256;passed=[bool]$gate.passed
      newIssueCount=0;newDefectCount=0;blankScreenCount=0
      flutterFatalErrorCount=0;androidRuntimeFatalCount=0;anrCount=0
      sourceProducerId=$producerId;sessionId=$sessionId
      nonceSha256=$challengeSha
    }
    Assert-C34LPrivacy $journeyPayload `
      "journey capture $($gate.journeyId)"
    Write-C34LAtomic $journeyFile (ConvertTo-C34LJson $journeyPayload) `
      -CreateOnly
    $journeyBinding = Get-C34LBinding $journeyFile
    $journeyRows += [pscustomobject][ordered]@{
      journeyId=[string]$gate.journeyId;path=[string]$journeyBinding.path
      sha256=[string]$journeyBinding.sha256;bytes=[int64]$journeyBinding.bytes
      passed=$true
    }
    $digestMap[([string]$gate.journeyId + 'DigestSha256')] =
      [string]$journeyBinding.sha256
  }
  $manifestRole = 'journey_acceptance_manifest'
  $manifestLeaf = [string]$contract.evidenceTypes.$EvidenceType.
    leafByRole.$manifestRole
  $manifestArtifactRelative = "$captureRootRelative/$manifestLeaf"
  $manifestArtifactFile = Resolve-C34LRelative $manifestArtifactRelative `
    'journey acceptance manifest artifact' -AllowMissing
  Write-C34LAtomic $manifestArtifactFile (ConvertTo-C34LJson $journeyRows) `
    -CreateOnly
  $manifestArtifactBinding = Get-C34LBinding $manifestArtifactFile
  $artifactBindings = @([pscustomobject][ordered]@{
    role=$manifestRole;path=[string]$manifestArtifactBinding.path
    sha256=[string]$manifestArtifactBinding.sha256
    bytes=[int64]$manifestArtifactBinding.bytes;mediaType='application/json'
  })
} else {
  Assert-C34LProducer (
    $artifactRows.Count -eq $expectedRoles.Count -and
    (@($artifactRows.role) -join ',') -ceq ($expectedRoles -join ',')
  ) 'observation adapter artifact role set or order changed.'
  foreach ($row in $artifactRows) {
    Assert-C34LExactNames $row @('role','mediaType','payload') `
      'observation adapter artifact row'
    Assert-C34LProducer (
      [string]$row.mediaType -ceq 'application/json' -and
      $expectedRoles -ccontains [string]$row.role
    ) 'observation adapter artifact role or media type changed.'
    Assert-C34LPrivacy $row.payload "observation payload $($row.role)"
    $leaf = [string]$contract.evidenceTypes.$EvidenceType.
      leafByRole.([string]$row.role)
    $relative = "$captureRootRelative/$leaf"
    $file = Resolve-C34LRelative $relative "capture artifact $($row.role)" `
      -AllowMissing
    if ($EvidenceType -ceq 'play_internal_testing_activation') {
      $payload = [ordered]@{
        schemaVersion=1;captureRole=[string]$row.role;ticketId=$ticketId
        attempt=$Attempt;packageName=$packageName;versionName=$versionName
        versionCode=$versionCode;artifactSha256=[string]$artifactBinding.sha256
        artifactBytes=[int64]$artifactBinding.bytes
      }
    } else {
      $payload = [ordered]@{
        schemaVersion=1;captureArtifactContractId=[string]$contract.contractId
        evidenceType=$EvidenceType;role=[string]$row.role;ticketId=$ticketId
        attempt=$Attempt;packageName=$packageName;versionName=$versionName
        versionCode=$versionCode;artifactSha256=[string]$artifactBinding.sha256
        artifactBytes=[int64]$artifactBinding.bytes
        deviceBindingSha256=$deviceBindingSha256;deviceModel=$deviceModel
        installerPackage='com.android.vending'
      }
    }
    $payload.sourceProducerId=$producerId;$payload.sessionId=$sessionId
    $payload.nonceSha256=$challengeSha
    foreach ($property in @($row.payload.PSObject.Properties)) {
      $payload[$property.Name]=$property.Value
    }
    $payloadObject = [pscustomobject]$payload
    Assert-C34LPrivacy $payloadObject "capture artifact $($row.role)"
    Write-C34LAtomic $file (ConvertTo-C34LJson $payloadObject) -CreateOnly
    $binding = Get-C34LBinding $file
    $artifactBindings += [pscustomobject][ordered]@{
      role=[string]$row.role;path=[string]$binding.path
      sha256=[string]$binding.sha256;bytes=[int64]$binding.bytes
      mediaType='application/json'
    }
  }
  if ($EvidenceType -ceq 'play_internal_testing_activation') {
    $digestMap.internalTestingRouteDigestSha256=
      [string]$artifactBindings[0].sha256
    $digestMap.uploadReceiptDigestSha256=[string]$artifactBindings[0].sha256
    $digestMap.activationStateDigestSha256=[string]$artifactBindings[1].sha256
  } else {
    $digestMap.packageStateDigestSha256=[string]$artifactBindings[0].sha256
    $digestMap.coldStartDigestSha256=[string]$artifactBindings[0].sha256
    $digestMap.retainedDataDigestSha256=[string]$artifactBindings[1].sha256
  }
}

$manifestRelative = "$captureRootRelative/capture-manifest.json"
$manifestOutput = Resolve-C34LRelative $manifestRelative 'capture manifest' -AllowMissing
$captureProduced = [DateTime]::UtcNow
$utcFormat = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
$captureManifest = [pscustomobject][ordered]@{
  schemaVersion = 1
  captureContractId = 'MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001'
  evidenceType = $EvidenceType
  ticketId = $ticketId
  attempt = $Attempt
  packageName = $packageName
  versionName = $versionName
  versionCode = $versionCode
  preStateSha256 = $stateSha
  preAggregateSha256 = $aggregateSha
  actionCounts = $state.actionCounts
  releaseAuthorities = $state.releaseAuthorities
  artifactSha256 = [string]$artifactBinding.sha256
  artifactBytes = [int64]$artifactBinding.bytes
  sourceProducerId = $producerId
  sessionId = $sessionId
  nonceSha256 = $challengeSha
  producedUtc = $captureProduced.AddSeconds(-1).ToString(
    $utcFormat,[Globalization.CultureInfo]::InvariantCulture)
  expiresUtc = $captureProduced.AddMinutes(10).ToString(
    $utcFormat,[Globalization.CultureInfo]::InvariantCulture)
  captureDigests = [pscustomobject]$digestMap
  captureArtifactContractPath = [string]$contractBinding.path
  captureArtifactContractSha256 = [string]$contractBinding.sha256
  captureArtifactContractId = [string]$contract.contractId
  captureArtifacts = $artifactBindings
}
Assert-C34LExactNames $captureManifest @(
  'schemaVersion','captureContractId','evidenceType','ticketId','attempt',
  'packageName','versionName','versionCode','preStateSha256',
  'preAggregateSha256','actionCounts','releaseAuthorities','artifactSha256',
  'artifactBytes','sourceProducerId','sessionId','nonceSha256','producedUtc',
  'expiresUtc','captureDigests','captureArtifactContractPath',
  'captureArtifactContractSha256','captureArtifactContractId','captureArtifacts'
) 'capture manifest'
Assert-C34LPrivacy $captureManifest 'capture manifest'
Write-C34LAtomic $manifestOutput (ConvertTo-C34LJson $captureManifest) -CreateOnly
$manifestOutputBinding = Get-C34LBinding $manifestOutput

$journalRoot = Initialize-C34LProducerDirectory $journalRoot $evidenceRoot `
  'authoritative capture journal root'
$journalRelative = "$journalRootRelative/$EvidenceType.json"
$journalFile = Resolve-C34LRelative $journalRelative `
  'authoritative capture journal' -AllowMissing
$receiptRelative = "$captureRootRelative/authoritative-capture-receipt.json"
$receiptFile = Resolve-C34LRelative $receiptRelative `
  'authoritative capture receipt' -AllowMissing
$producedUtc = [DateTime]::UtcNow.ToString(
  "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
  [Globalization.CultureInfo]::InvariantCulture
)
$receipt = [pscustomobject][ordered]@{
  schemaVersion = 1
  receiptContractId = $receiptContractId
  producerId = $producerId
  evidenceType = $EvidenceType
  ticketId = $ticketId
  attempt = $Attempt
  packageName = $packageName
  versionName = $versionName
  versionCode = $versionCode
  challengeSha256 = $challengeSha
  sessionId = $sessionId
  captureArtifactContract = $contractBinding
  producerOwner = $producerBinding
  sealedSourceManifest = $manifestBinding
  detailedState = Get-C34LBinding $stateFile
  aggregateState = Get-C34LBinding $aggregateFile
  artifact = $artifactBinding
  actionCounts = $state.actionCounts
  releaseAuthorities = $state.releaseAuthorities
  transitionJournal = $latestBinding
  observationAdapter = [pscustomobject][ordered]@{
    adapterId=[string]$adapter.adapterId
    ownerPath=[string]$adapterOwnerBinding.path
    ownerSha256=[string]$adapterOwnerBinding.sha256
    ownerBytes=[int64]$adapterOwnerBinding.bytes
  }
  observationSources = $observationSourceBindings
  captureManifest = $manifestOutputBinding
  previousJournalHeadSha256 = $previousHead
  producedUtc = $producedUtc
}
Assert-C34LExactNames $receipt `
  @($contract.authoritativeReceipt.topLevelFields) `
  'authoritative capture receipt'
Assert-C34LPrivacy $receipt 'authoritative capture receipt'
$receiptText = ConvertTo-C34LJson $receipt
$receiptIdentity = [pscustomobject]@{
  sha256=Get-C34LTextSha $receiptText;bytes=[int64]$utf8.GetByteCount($receiptText)
}
$journal = [pscustomobject][ordered]@{
  schemaVersion=1;journalContractId=$journalContractId;ticketId=$ticketId
  attempt=$Attempt;sequence=($orderedPrevious.Count + 1)
  evidenceType=$EvidenceType;challengeSha256=$challengeSha
  sessionId=$sessionId;transitionJournal=$latestBinding
  previousJournalHeadSha256=$previousHead;captureManifest=$manifestOutputBinding
  receipt=[pscustomobject][ordered]@{
    path=$receiptRelative;sha256=$receiptIdentity.sha256;bytes=$receiptIdentity.bytes
  }
  status='committed';committedUtc=$producedUtc
}
Write-C34LAtomic $receiptFile $receiptText -CreateOnly
Write-C34LAtomic $journalFile (ConvertTo-C34LJson $journal) -CreateOnly
Assert-C34LProducer (
  (Get-C34LSha $receiptFile) -ceq $receiptIdentity.sha256 -and
  (Get-Item -LiteralPath $receiptFile).Length -eq $receiptIdentity.bytes
) 'persisted authoritative receipt identity changed.'

Write-Output ([pscustomobject][ordered]@{
  receiptPath=$receiptRelative
  receiptSha256=$receiptIdentity.sha256
  receiptBytes=$receiptIdentity.bytes
  captureManifestPath=$manifestOutputBinding.path
  captureManifestSha256=$manifestOutputBinding.sha256
  captureManifestBytes=$manifestOutputBinding.bytes
  journalPath=$journalRelative
  challengeSha256=$challengeSha
  sessionId=$sessionId
})
