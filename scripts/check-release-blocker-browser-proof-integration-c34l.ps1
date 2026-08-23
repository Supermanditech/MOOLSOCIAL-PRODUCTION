[CmdletBinding()]
param(
  [ValidateSet('source', 'preupload')]
  [string]$Phase = 'preupload',
  [string]$StatePath =
    'config/successor-aab-regression-hard-gate-state-c34l.json',
  [string]$SourceManifestPath,
  [string]$SourceManifestSha256,
  [long]$SourceManifestBytes,
  [string]$BlockerLedgerPath,
  [string]$BlockerLedgerSha256,
  [long]$BlockerLedgerBytes,
  [string]$BrowserProofPath,
  [string]$BrowserProofSha256,
  [long]$BrowserProofBytes,
  [ValidateRange(1, 5)]
  [int]$Attempt = 1,
  [switch]$RequirePersistedBrowserBinding,
  [switch]$FixtureMode,
  [switch]$RunSelfTest,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$fixturePrefixRelative = 'tmp/c34l-blocker-browser-fixtures-'
$ticketId =
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE'
$versionName = '1.0.0-r60.76'
$versionCode = '2026081376'
$browserContractId =
  'MOOLSOCIAL-C34L-R60-76-PREUPLOAD-BROWSER-ROUTE-PROOF-001'
$browserProducerId = 'MOOLSOCIAL-C34L-BROWSER-QUALIFICATION-PRODUCER-001'
$browserSessionMaximumMinutes = 15
$browserClockSkewSeconds = 30
$browserUtcFormat = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
$ledgerContractId = 'MOOLSOCIAL-C33G-RELEASE-ACCEPTANCE-BLOCKER-LEDGER-001'
$expectedLedgerPath = 'config/release-acceptance-blocker-ledger-c33g.json'
$browserBindingNames = @(
  'browserEvidencePath', 'browserEvidenceSha256', 'browserEvidenceBytes',
  'browserEvidenceAttempt', 'browserEvidenceTransition',
  'browserEvidencePhase', 'browserEvidencePreStateSha256',
  'browserEvidencePreAggregateSha256', 'browserSessionId',
  'browserSessionNonceSha256', 'browserEvidenceProducerId',
  'browserEvidenceProducedUtc', 'browserEvidenceExpiresUtc',
  'sourceManifestPath', 'sourceManifestSha256', 'sourceManifestBytes',
  'blockerLedgerPath', 'blockerLedgerSha256', 'blockerLedgerBytes',
  'liveBrowserRouteQualified', 'signedInMoolSocialAppRouteProved',
  'internalTestingRouteProved', 'noPlayWritePerformed'
)
$utf8 = [Text.UTF8Encoding]::new($false)

function Assert-C34LBlockerBrowser {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34L blocker/browser integration rejected: $Message"
  }
}

function Get-C34LBlockerBrowserProperty {
  param(
    [Parameter(Mandatory)][object]$Object,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Label
  )
  $property = $Object.PSObject.Properties[$Name]
  Assert-C34LBlockerBrowser -Condition ($null -ne $property) `
    -Message "$Label is missing $Name."
  return $property.Value
}

function Resolve-C34LBlockerBrowserFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34LBlockerBrowser -Condition (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path)
  ) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LBlockerBrowser -Condition (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or outside the production repository."
  return $resolved
}

function ConvertTo-C34LBlockerBrowserRelativePath {
  param(
    [Parameter(Mandatory)][string]$Resolved,
    [Parameter(Mandatory)][string]$Label
  )
  $full = [IO.Path]::GetFullPath($Resolved)
  Assert-C34LBlockerBrowser -Condition (
    $full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the production repository."
  return $full.Substring($rootPrefix.Length).Replace('\', '/')
}

function Get-C34LBlockerBrowserSha256 {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Get-C34LBlockerBrowserTextSha256 {
  param([Parameter(Mandatory)][string]$Text)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString(
      $sha.ComputeHash($utf8.GetBytes($Text))
    )).Replace('-', '')
  } finally { $sha.Dispose() }
}

function Write-C34LBlockerBrowserJson {
  param(
    [Parameter(Mandatory)][object]$Value,
    [Parameter(Mandatory)][string]$Path
  )
  [IO.File]::WriteAllText(
    $Path,
    (($Value | ConvertTo-Json -Depth 60) + [Environment]::NewLine),
    $utf8
  )
}

function Copy-C34LBlockerBrowserObject {
  param([Parameter(Mandatory)][object]$Value)
  $copy = $Value | ConvertTo-Json -Depth 60 | ConvertFrom-Json
  foreach ($name in @('producedUtc', 'expiresUtc')) {
    if ($null -ne $Value.PSObject.Properties[$name]) {
      $copy.PSObject.Properties[$name].Value =
        ConvertTo-C34LBlockerBrowserCanonicalUtcText `
          $Value.PSObject.Properties[$name].Value "copied $name"
    }
  }
  return $copy
}

function Assert-C34LBlockerBrowserFixtureFile {
  param(
    [Parameter(Mandatory)][string]$Resolved,
    [Parameter(Mandatory)][string]$RunRoot,
    [Parameter(Mandatory)][string]$Label
  )
  $canonicalRoot = [IO.Path]::GetFullPath($RunRoot).TrimEnd([char[]]@('\', '/'))
  $canonicalPrefix = $canonicalRoot + [IO.Path]::DirectorySeparatorChar
  $canonicalFile = [IO.Path]::GetFullPath($Resolved)
  Assert-C34LBlockerBrowser -Condition (
    $canonicalFile.StartsWith(
      $canonicalPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message "$Label escaped the exact unique C34L blocker/browser fixture run root."
}

function ConvertTo-C34LBlockerBrowserUtc {
  param(
    [Parameter(Mandatory)][object]$Value,
    [Parameter(Mandatory)][string]$Label
  )
  $canonical = ConvertTo-C34LBlockerBrowserCanonicalUtcText $Value $Label
  $parsed = [DateTime]::MinValue
  $styles = [Globalization.DateTimeStyles]::AssumeUniversal -bor
    [Globalization.DateTimeStyles]::AdjustToUniversal
  Assert-C34LBlockerBrowser -Condition (
    [DateTime]::TryParseExact(
      $canonical,
      $browserUtcFormat,
      [Globalization.CultureInfo]::InvariantCulture,
      $styles,
      [ref]$parsed
    ) -and
    $parsed.ToUniversalTime().ToString(
      $browserUtcFormat,
      [Globalization.CultureInfo]::InvariantCulture
    ) -ceq $canonical
  ) -Message "$Label is not an exact UTC timestamp."
  return $parsed.ToUniversalTime()
}

function ConvertTo-C34LBlockerBrowserCanonicalUtcText {
  param(
    [Parameter(Mandatory)][object]$Value,
    [Parameter(Mandatory)][string]$Label
  )
  if ($Value -is [DateTime]) {
    return ConvertTo-C34LBlockerBrowserUtcText ([DateTime]$Value)
  }
  if ($Value -is [DateTimeOffset]) {
    $dateTimeOffset = [DateTimeOffset]$Value
    return ConvertTo-C34LBlockerBrowserUtcText $dateTimeOffset.UtcDateTime
  }
  Assert-C34LBlockerBrowser -Condition ($Value -is [string]) `
    -Message "$Label has an unsupported runtime shape."
  $text = [string]$Value
  $parsed = [DateTime]::MinValue
  $styles = [Globalization.DateTimeStyles]::AssumeUniversal -bor
    [Globalization.DateTimeStyles]::AdjustToUniversal
  Assert-C34LBlockerBrowser -Condition (
    [DateTime]::TryParseExact(
      $text,
      $browserUtcFormat,
      [Globalization.CultureInfo]::InvariantCulture,
      $styles,
      [ref]$parsed
    ) -and
    (ConvertTo-C34LBlockerBrowserUtcText $parsed) -ceq $text
  ) -Message "$Label is not an exact UTC timestamp."
  return $text
}

function ConvertTo-C34LBlockerBrowserUtcText {
  param([Parameter(Mandatory)][DateTime]$Value)
  return $Value.ToUniversalTime().ToString(
    $browserUtcFormat,
    [Globalization.CultureInfo]::InvariantCulture
  )
}

function Assert-C34LBlockerBrowserRawUtcTokens {
  param(
    [Parameter(Mandatory)][string]$JsonText,
    [Parameter(Mandatory)][string]$PropertyName,
    [Parameter(Mandatory)][string]$Expected,
    [Parameter(Mandatory)][int]$ExpectedCount,
    [Parameter(Mandatory)][string]$Label
  )
  $matches = [regex]::Matches(
    $JsonText,
    '"' + [regex]::Escape($PropertyName) + '"\s*:\s*"([^"]+)"'
  )
  Assert-C34LBlockerBrowser -Condition ($matches.Count -eq $ExpectedCount) `
    -Message "$Label must contain exactly $ExpectedCount $PropertyName strings."
  foreach ($match in $matches) {
    $raw = [string]$match.Groups[1].Value
    $canonical = ConvertTo-C34LBlockerBrowserCanonicalUtcText `
      $raw "$Label $PropertyName"
    Assert-C34LBlockerBrowser -Condition (
      $raw -ceq $canonical -and $raw -ceq $Expected
    ) -Message "$Label changed the exact $PropertyName wire value."
  }
}

function Assert-C34LBlockerBrowserFileIdentity {
  param(
    [Parameter(Mandatory)][string]$Resolved,
    [Parameter(Mandatory)][string]$Sha256,
    [Parameter(Mandatory)][long]$Bytes,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34LBlockerBrowser -Condition (
    $Sha256 -cmatch '^[0-9A-F]{64}$' -and
    $Bytes -gt 0 -and
    (Get-C34LBlockerBrowserSha256 $Resolved) -ceq $Sha256 -and
    (Get-Item -LiteralPath $Resolved).Length -eq $Bytes
  ) -Message "$Label SHA-256 or byte length changed."
}

function Assert-C34LBlockerBrowserVector {
  param(
    [Parameter(Mandatory)][object]$Proof,
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate
  )
  $counts = Get-C34LBlockerBrowserProperty $Proof 'actionCounts' 'browser proof'
  foreach ($name in @(
    'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
    'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
  )) {
    Assert-C34LBlockerBrowser -Condition (
      $null -ne $counts.PSObject.Properties[$name] -and
      [int]$counts.$name -eq [int]$State.actionCounts.$name -and
      [int]$counts.$name -eq [int]$Aggregate.actionCounts.$name
    ) -Message "browser proof action count changed at $name."
  }
  $authorities = Get-C34LBlockerBrowserProperty `
    $Proof 'releaseAuthorities' 'browser proof'
  foreach ($name in @(
    'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  )) {
    Assert-C34LBlockerBrowser -Condition (
      $null -ne $authorities.PSObject.Properties[$name] -and
      [string]$authorities.$name -ceq [string]$State.releaseAuthorities.$name -and
      [string]$authorities.$name -ceq [string]$Aggregate.releaseAuthorities.$name
    ) -Message "browser proof release authority changed at $name."
  }
}

function New-C34LBlockerBrowserBinding {
  param(
    [Parameter(Mandatory)][object]$Proof,
    [Parameter(Mandatory)][string]$ProofPath,
    [Parameter(Mandatory)][string]$ProofSha256,
    [Parameter(Mandatory)][long]$ProofBytes
  )
  return [pscustomobject][ordered]@{
    browserEvidencePath = $ProofPath
    browserEvidenceSha256 = $ProofSha256
    browserEvidenceBytes = $ProofBytes
    browserEvidenceAttempt = [int]$Proof.attempt
    browserEvidenceTransition = 'upload-authorized'
    browserEvidencePhase = 'preupload'
    browserEvidencePreStateSha256 = [string]$Proof.stateSha256
    browserEvidencePreAggregateSha256 = [string]$Proof.aggregateSha256
    browserSessionId = [string]$Proof.sessionId
    browserSessionNonceSha256 = [string]$Proof.sessionNonceSha256
    browserEvidenceProducerId = [string]$Proof.producerId
    browserEvidenceProducedUtc = [string]$Proof.producedUtc
    browserEvidenceExpiresUtc = [string]$Proof.expiresUtc
    sourceManifestPath = [string]$Proof.sourceManifest.path
    sourceManifestSha256 = [string]$Proof.sourceManifest.sha256
    sourceManifestBytes = [long]$Proof.sourceManifest.bytes
    blockerLedgerPath = [string]$Proof.blockerLedger.path
    blockerLedgerSha256 = [string]$Proof.blockerLedger.sha256
    blockerLedgerBytes = [long]$Proof.blockerLedger.bytes
    liveBrowserRouteQualified = [bool]$Proof.routes.liveBrowserRouteQualified
    signedInMoolSocialAppRouteProved =
      [bool]$Proof.routes.signedInMoolSocialAppRouteProved
    internalTestingRouteProved = [bool]$Proof.routes.internalTestingRouteProved
    noPlayWritePerformed = [bool]$Proof.noPlayWritePerformed
  }
}

function Assert-C34LBlockerBrowserBindingEquals {
  param(
    [Parameter(Mandatory)][object]$Actual,
    [Parameter(Mandatory)][object]$Expected,
    [Parameter(Mandatory)][string]$Label
  )
  $names = @($Expected.PSObject.Properties | ForEach-Object { $_.Name })
  $actualNames = @($Actual.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LBlockerBrowser -Condition (
    $names.Count -eq 23 -and
    (@($names | Sort-Object) -join ',') -ceq
      (@($browserBindingNames | Sort-Object) -join ',') -and
    (@($actualNames | Sort-Object) -join ',') -ceq
      (@($browserBindingNames | Sort-Object) -join ',')
  ) `
    -Message 'canonical browser binding definition is incomplete.'
  foreach ($name in $names) {
    Assert-C34LBlockerBrowser -Condition (
      $null -ne $Actual.PSObject.Properties[$name]
    ) -Message "$Label is missing $name."
    $expectedValue = $Expected.PSObject.Properties[$name].Value
    $actualValue = $Actual.PSObject.Properties[$name].Value
    $matches = if ($expectedValue -is [bool]) {
      [bool]$actualValue -eq [bool]$expectedValue
    } elseif ($expectedValue -is [int] -or $expectedValue -is [long]) {
      [long]$actualValue -eq [long]$expectedValue
    } elseif ($name -in @(
      'browserEvidenceProducedUtc', 'browserEvidenceExpiresUtc'
    )) {
      (ConvertTo-C34LBlockerBrowserCanonicalUtcText `
        $actualValue "$Label $name") -ceq
        (ConvertTo-C34LBlockerBrowserCanonicalUtcText `
          $expectedValue "expected $name")
    } else { [string]$actualValue -ceq [string]$expectedValue }
    Assert-C34LBlockerBrowser -Condition $matches `
      -Message "$Label changed at $name."
  }
}

function Assert-C34LBlockerBrowserPersistedPreimage {
  param(
    [Parameter(Mandatory)][object]$Proof,
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][string]$ProofPath,
    [Parameter(Mandatory)][string]$ProofSha256,
    [Parameter(Mandatory)][long]$ProofBytes
  )
  $stateHistory = @($State.lifecycleTransactionProofs)
  $aggregateHistory = @($Aggregate.lifecycleTransactionProofs)
  Assert-C34LBlockerBrowser -Condition (
    $stateHistory.Count -gt 0 -and
    $stateHistory.Count -eq $aggregateHistory.Count -and
    (ConvertTo-Json -InputObject $stateHistory -Depth 60 -Compress) -ceq
      (ConvertTo-Json -InputObject $aggregateHistory -Depth 60 -Compress)
  ) -Message 'persisted lifecycle proof histories are missing or divergent.'
  $newest = $stateHistory[-1]
  Assert-C34LBlockerBrowser -Condition (
    [string]$newest.ticketId -ceq $ticketId -and
    [int]$newest.attempt -eq [int]$Proof.attempt -and
    [string]$newest.transition -ceq 'upload-authorized' -and
    [string]$newest.phase -ceq 'preupload' -and
    [string]$newest.preStateSha256 -ceq [string]$Proof.stateSha256 -and
    [string]$newest.preAggregateSha256 -ceq [string]$Proof.aggregateSha256
  ) -Message 'newest lifecycle proof is not the exact browser pretransition.'
  $expectedBinding = New-C34LBlockerBrowserBinding `
    $Proof $ProofPath $ProofSha256 $ProofBytes
  Assert-C34LBlockerBrowserBindingEquals `
    $newest.browserEvidence $expectedBinding 'newest lifecycle browser binding'
  Assert-C34LBlockerBrowserVector $Proof $newest $newest

  $journalRoot = Join-Path (
    [IO.Path]::GetFullPath((Join-Path $root ([string]$State.evidenceRoot)))
  ) 'release-transaction-journals'
  Assert-C34LBlockerBrowser -Condition (
    Test-Path -LiteralPath $journalRoot -PathType Container
  ) -Message 'persisted browser transaction journal root is missing.'
  $journalRows = @()
  foreach ($file in @(Get-ChildItem -LiteralPath $journalRoot -Filter '*.json' -File)) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $value = $text | ConvertFrom-Json
    $journalRows += [pscustomobject]@{
      sequence=[int]$value.sequence; value=$value; text=$text
    }
  }
  Assert-C34LBlockerBrowser -Condition ($journalRows.Count -gt 0) `
    -Message 'persisted browser transaction journal is missing.'
  $newestJournalRow = @($journalRows | Sort-Object sequence)[-1]
  $journal = $newestJournalRow.value
  Assert-C34LBlockerBrowser -Condition (
    [string]$journal.ticketId -ceq $ticketId -and
    [int]$journal.attempt -eq [int]$Proof.attempt -and
    [string]$journal.transition -ceq 'upload-authorized' -and
    [string]$journal.prerequisiteGatePhase -ceq 'preupload' -and
    [string]$journal.stateBeforeSha256 -ceq [string]$Proof.stateSha256 -and
    [string]$journal.aggregateBeforeSha256 -ceq [string]$Proof.aggregateSha256
  ) -Message 'newest transaction journal is not the exact browser preimage.'
  Assert-C34LBlockerBrowserBindingEquals `
    $journal.browserEvidence $expectedBinding 'newest journal browser binding'
  Assert-C34LBlockerBrowserRawUtcTokens `
    $newestJournalRow.text 'browserEvidenceProducedUtc' `
    ([string]$expectedBinding.browserEvidenceProducedUtc) 1 `
    'newest transaction journal'
  Assert-C34LBlockerBrowserRawUtcTokens `
    $newestJournalRow.text 'browserEvidenceExpiresUtc' `
    ([string]$expectedBinding.browserEvidenceExpiresUtc) 1 `
    'newest transaction journal'
  $stateBeforeText = $utf8.GetString(
    [Convert]::FromBase64String([string]$journal.stateBeforeBase64)
  )
  $aggregateBeforeText = $utf8.GetString(
    [Convert]::FromBase64String([string]$journal.aggregateBeforeBase64)
  )
  Assert-C34LBlockerBrowser -Condition (
    (Get-C34LBlockerBrowserTextSha256 $stateBeforeText) -ceq
      [string]$journal.stateBeforeSha256 -and
    (Get-C34LBlockerBrowserTextSha256 $aggregateBeforeText) -ceq
      [string]$journal.aggregateBeforeSha256
  ) -Message 'persisted browser journal preimage payload hash changed.'
  $preState = $stateBeforeText | ConvertFrom-Json
  $preAggregate = $aggregateBeforeText | ConvertFrom-Json
  Assert-C34LBlockerBrowserVector $Proof $preState $preAggregate
}

function Get-C34LBlockerBrowserSession {
  param([Parameter(Mandatory)][object]$Proof)
  foreach ($name in @(
    'sessionId', 'sessionNonceSha256', 'producerId', 'producedUtc', 'expiresUtc'
  )) {
    [void](Get-C34LBlockerBrowserProperty $Proof $name 'browser proof session')
  }
  Assert-C34LBlockerBrowser -Condition (
    $null -eq $Proof.PSObject.Properties['nonce']
  ) -Message 'browser proof must never contain a raw session nonce.'
  Assert-C34LBlockerBrowser -Condition (
    [string]$Proof.sessionNonceSha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$Proof.sessionId -ceq (
      'c34l-browser-session-' +
        [string]$Proof.sessionNonceSha256.Substring(0, 16)
    ) -and
    [string]$Proof.producerId -ceq $browserProducerId
  ) -Message 'browser proof session id, nonce hash or producer identity changed.'
  $producedUtc = ConvertTo-C34LBlockerBrowserUtc `
    ([string]$Proof.producedUtc) 'browser proof producedUtc'
  $expiresUtc = ConvertTo-C34LBlockerBrowserUtc `
    ([string]$Proof.expiresUtc) 'browser proof expiresUtc'
  $now = [DateTime]::UtcNow
  Assert-C34LBlockerBrowser -Condition (
    $producedUtc -le $now.AddSeconds($browserClockSkewSeconds) -and
    $producedUtc -ge $now.AddMinutes(-$browserSessionMaximumMinutes) -and
    $expiresUtc -gt $now.AddSeconds(-$browserClockSkewSeconds) -and
    $expiresUtc -gt $producedUtc -and
    $expiresUtc -le $producedUtc.AddMinutes($browserSessionMaximumMinutes)
  ) -Message 'browser proof session timestamp is stale, future-dated or unbounded.'
  return [pscustomobject]@{
    id = [string]$Proof.sessionId
    nonceSha256 = [string]$Proof.sessionNonceSha256
    producerId = [string]$Proof.producerId
    producedUtc = ConvertTo-C34LBlockerBrowserUtcText $producedUtc
    expiresUtc = ConvertTo-C34LBlockerBrowserUtcText $expiresUtc
  }
}

function Assert-C34LBlockerBrowserStateBinding {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][object]$Proof,
    [Parameter(Mandatory)][object]$Session,
    [Parameter(Mandatory)][string]$ProofPath,
    [Parameter(Mandatory)][string]$ProofSha256,
    [Parameter(Mandatory)][long]$ProofBytes,
    [Parameter(Mandatory)][int]$ProofAttempt,
    [Parameter(Mandatory)][bool]$RequirePersisted
  )
  $expected = [ordered]@{
    browserEvidencePath = if ($RequirePersisted) { $ProofPath } else { $null }
    browserEvidenceSha256 = if ($RequirePersisted) { $ProofSha256 } else { $null }
    browserEvidenceBytes = if ($RequirePersisted) { $ProofBytes } else { 0 }
    browserEvidenceAttempt = if ($RequirePersisted) { $ProofAttempt } else { 0 }
    browserEvidenceTransition = if ($RequirePersisted) { 'upload-authorized' } else { $null }
    browserEvidencePhase = if ($RequirePersisted) { 'preupload' } else { $null }
    browserEvidencePreStateSha256 = if ($RequirePersisted) {
      [string]$Proof.stateSha256
    } else { $null }
    browserEvidencePreAggregateSha256 = if ($RequirePersisted) {
      [string]$Proof.aggregateSha256
    } else { $null }
    browserSessionId = if ($RequirePersisted) { [string]$Session.id } else { $null }
    browserSessionNonceSha256 = if ($RequirePersisted) {
      [string]$Session.nonceSha256
    } else { $null }
    browserEvidenceProducerId = if ($RequirePersisted) {
      [string]$Session.producerId
    } else { $null }
    browserEvidenceProducedUtc = if ($RequirePersisted) {
      [string]$Session.producedUtc
    } else { $null }
    browserEvidenceExpiresUtc = if ($RequirePersisted) {
      [string]$Session.expiresUtc
    } else { $null }
    sourceManifestPath = if ($RequirePersisted) {
      [string]$Proof.sourceManifest.path
    } else { $null }
    sourceManifestSha256 = if ($RequirePersisted) {
      [string]$Proof.sourceManifest.sha256
    } else { $null }
    sourceManifestBytes = if ($RequirePersisted) {
      [long]$Proof.sourceManifest.bytes
    } else { 0 }
    blockerLedgerPath = if ($RequirePersisted) {
      [string]$Proof.blockerLedger.path
    } else { $null }
    blockerLedgerSha256 = if ($RequirePersisted) {
      [string]$Proof.blockerLedger.sha256
    } else { $null }
    blockerLedgerBytes = if ($RequirePersisted) {
      [long]$Proof.blockerLedger.bytes
    } else { 0 }
    liveBrowserRouteQualified = $RequirePersisted
    signedInMoolSocialAppRouteProved = $RequirePersisted
    internalTestingRouteProved = $RequirePersisted
    noPlayWritePerformed = $true
  }
  foreach ($owner in @($State.presealUploadWorkflow, $Aggregate.presealUploadWorkflow)) {
    $ownerNames = @($owner.PSObject.Properties | ForEach-Object { $_.Name })
    Assert-C34LBlockerBrowser -Condition (
      (@($ownerNames | Sort-Object) -join ',') -ceq
        (@($browserBindingNames | Sort-Object) -join ',')
    ) -Message 'browser evidence state mirror exact 23-field schema changed.'
    foreach ($name in @($expected.Keys)) {
      Assert-C34LBlockerBrowser -Condition (
        $null -ne $owner.PSObject.Properties[$name]
      ) -Message "browser evidence state mirror is missing $name."
      $actual = $owner.PSObject.Properties[$name].Value
      $matches = if ($null -eq $expected[$name]) {
        $null -eq $actual -or [string]::IsNullOrWhiteSpace([string]$actual)
      } elseif ($expected[$name] -is [bool]) {
        [bool]$actual -eq [bool]$expected[$name]
      } elseif ($expected[$name] -is [int] -or $expected[$name] -is [long]) {
        [long]$actual -eq [long]$expected[$name]
      } elseif ($name -in @(
        'browserEvidenceProducedUtc', 'browserEvidenceExpiresUtc'
      )) {
        (ConvertTo-C34LBlockerBrowserCanonicalUtcText `
          $actual "browser evidence state mirror $name") -ceq
          (ConvertTo-C34LBlockerBrowserCanonicalUtcText `
            $expected[$name] "expected $name")
      } else { [string]$actual -ceq [string]$expected[$name] }
      Assert-C34LBlockerBrowser -Condition $matches `
        -Message "browser evidence state mirror changed at $name."
    }
  }
  if (-not $RequirePersisted) {
    Assert-C34LBlockerBrowser -Condition (
      [string]::IsNullOrWhiteSpace(
        [string]$State.presealUploadWorkflow.browserSessionId
      )
    ) -Message 'browser proof session was already consumed or replayed.'
  }
}

function Invoke-C34LBlockerBrowserValidation {
  param(
    [Parameter(Mandatory)][ValidateSet('source', 'preupload')][string]$ValidationPhase,
    [Parameter(Mandatory)][string]$ValidationStatePath,
    [Parameter(Mandatory)][string]$ValidationSourceManifestPath,
    [Parameter(Mandatory)][string]$ValidationSourceManifestSha256,
    [Parameter(Mandatory)][long]$ValidationSourceManifestBytes,
    [Parameter(Mandatory)][string]$ValidationBlockerLedgerPath,
    [Parameter(Mandatory)][string]$ValidationBlockerLedgerSha256,
    [Parameter(Mandatory)][long]$ValidationBlockerLedgerBytes,
    [string]$ValidationBrowserProofPath,
    [string]$ValidationBrowserProofSha256,
    [long]$ValidationBrowserProofBytes,
    [Parameter(Mandatory)][int]$ValidationAttempt,
    [Parameter(Mandatory)][bool]$ValidationRequirePersistedBrowserBinding,
    [Parameter(Mandatory)][bool]$ValidationFixtureMode
  )

  if (-not $ValidationFixtureMode) {
    Assert-C34LBlockerBrowser -Condition (
      $ValidationStatePath -ceq
        'config/successor-aab-regression-hard-gate-state-c34l.json' -and
      $ValidationBlockerLedgerPath -ceq $expectedLedgerPath
    ) -Message 'real validation is restricted to the exact C34L state and C33G ledger.'
  }

  $stateFile = Resolve-C34LBlockerBrowserFile $ValidationStatePath 'detailed state'
  $fixtureRunRoot = $null
  if ($ValidationFixtureMode) {
    $normalizedStatePath = $ValidationStatePath.Replace('\', '/')
    Assert-C34LBlockerBrowser -Condition (
      $normalizedStatePath -cmatch
        '^tmp/c34l-blocker-browser-fixtures-[A-Za-z0-9-]+/state\.json$'
    ) -Message 'fixture detailed state is not the exact unique run-root owner.'
    $fixtureRunRoot = Split-Path -Parent $stateFile
    Assert-C34LBlockerBrowserFixtureFile $stateFile $fixtureRunRoot `
      'fixture detailed state'
  }
  $stateText = Get-Content -Raw -LiteralPath $stateFile
  $state = $stateText | ConvertFrom-Json
  $aggregatePath = [string](
    Get-C34LBlockerBrowserProperty $state 'aggregateStatePath' 'detailed state'
  )
  $aggregateFile = Resolve-C34LBlockerBrowserFile $aggregatePath 'aggregate state'
  Assert-C34LBlockerBrowser -Condition (
    $aggregatePath.Replace('\', '/') -ceq
      (ConvertTo-C34LBlockerBrowserRelativePath $aggregateFile 'aggregate state')
  ) -Message 'aggregate state path is not canonical and exact.'
  if ($ValidationFixtureMode) {
    Assert-C34LBlockerBrowserFixtureFile $aggregateFile $fixtureRunRoot `
      'fixture aggregate state'
  }
  $aggregateText = Get-Content -Raw -LiteralPath $aggregateFile
  $aggregate = $aggregateText | ConvertFrom-Json
  Assert-C34LBlockerBrowser -Condition (
    [string]$state.ticketId -ceq $ticketId -and
    [string]$aggregate.ticketId -ceq $ticketId -and
    [string]$state.candidate.id -ceq $ticketId -and
    [string]$aggregate.candidate.id -ceq $ticketId -and
    [string]$state.candidate.versionName -ceq $versionName -and
    [string]$aggregate.candidate.versionName -ceq $versionName -and
    [string]$state.candidate.versionCode -ceq $versionCode -and
    [string]$aggregate.candidate.versionCode -ceq $versionCode
  ) -Message 'C34L detailed or aggregate candidate identity changed.'

  $manifestFile = Resolve-C34LBlockerBrowserFile `
    $ValidationSourceManifestPath 'source manifest'
  $ledgerFile = Resolve-C34LBlockerBrowserFile `
    $ValidationBlockerLedgerPath 'mutable C33G blocker ledger'
  $canonicalManifestPath = ConvertTo-C34LBlockerBrowserRelativePath `
    $manifestFile 'source manifest'
  $canonicalLedgerPath = ConvertTo-C34LBlockerBrowserRelativePath `
    $ledgerFile 'mutable C33G blocker ledger'
  Assert-C34LBlockerBrowser -Condition (
    $ValidationSourceManifestPath.Replace('\', '/') -ceq
      $canonicalManifestPath -and
    $ValidationBlockerLedgerPath.Replace('\', '/') -ceq $canonicalLedgerPath
  ) -Message 'source manifest or mutable ledger path is not canonical and exact.'
  if ($ValidationFixtureMode) {
    Assert-C34LBlockerBrowserFixtureFile $manifestFile $fixtureRunRoot `
      'fixture source manifest'
    Assert-C34LBlockerBrowserFixtureFile $ledgerFile $fixtureRunRoot `
      'fixture mutable C33G blocker ledger'
  }
  Assert-C34LBlockerBrowserFileIdentity $manifestFile `
    $ValidationSourceManifestSha256 $ValidationSourceManifestBytes 'source manifest'
  Assert-C34LBlockerBrowserFileIdentity $ledgerFile `
    $ValidationBlockerLedgerSha256 $ValidationBlockerLedgerBytes `
    'mutable C33G blocker ledger'

  Assert-C34LBlockerBrowser -Condition (
    [string]$state.sourceQualification.manifestPath -ceq
      $ValidationSourceManifestPath -and
    [string]$aggregate.sourceQualification.manifestPath -ceq
      $ValidationSourceManifestPath -and
    [string]$state.sourceQualification.manifestSha256 -ceq
      $ValidationSourceManifestSha256 -and
    [string]$aggregate.sourceQualification.manifestSha256 -ceq
      $ValidationSourceManifestSha256 -and
    [long]$state.sourceQualification.manifestBytes -eq
      $ValidationSourceManifestBytes -and
    [long]$aggregate.sourceQualification.manifestBytes -eq
      $ValidationSourceManifestBytes
  ) -Message 'source manifest path, SHA-256 or bytes are not mirrored exactly.'
  Assert-C34LBlockerBrowser -Condition (
    [string]$state.sourcePrerequisites.blockerLedgerPath -ceq
      $ValidationBlockerLedgerPath -and
    [string]$state.sourcePrerequisites.blockerLedgerPrebuildSha256 -ceq
      $ValidationBlockerLedgerSha256
  ) -Message 'detailed state does not bind the exact mutable C33G ledger prebuild hash.'

  $ledger = Get-Content -Raw -LiteralPath $ledgerFile | ConvertFrom-Json
  Assert-C34LBlockerBrowser -Condition (
    [int]$ledger.schemaVersion -eq 1 -and
    [string]$ledger.contractId -ceq $ledgerContractId -and
    [string]$ledger.scope -ceq 'candidate_independent_all_future_release_candidates'
  ) -Message 'mutable C33G blocker ledger schema, contract or scope changed.'

  $manifestLines = @(Get-Content -LiteralPath $manifestFile)
  Assert-C34LBlockerBrowser -Condition ($manifestLines.Count -gt 0) `
    -Message 'source manifest is empty.'
  $canonicalOwners = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
  )
  foreach ($line in $manifestLines) {
    $match = [regex]::Match([string]$line, '^([0-9A-F]{64})  (.+)$')
    Assert-C34LBlockerBrowser -Condition $match.Success `
      -Message 'source manifest contains a malformed owner row.'
    $ownerRelative = $match.Groups[2].Value.Replace('\', '/')
    $ownerFile = Resolve-C34LBlockerBrowserFile $ownerRelative 'sealed source owner'
    Assert-C34LBlockerBrowser -Condition (
      -not $ownerFile.Equals(
        $ledgerFile,
        [StringComparison]::OrdinalIgnoreCase
      )
    ) -Message 'mutable C33G blocker ledger must remain outside the source seal.'
    Assert-C34LBlockerBrowser -Condition ($canonicalOwners.Add($ownerFile)) `
      -Message 'source manifest contains a duplicate canonical owner or alias.'
    Assert-C34LBlockerBrowser -Condition (
      (Get-C34LBlockerBrowserSha256 $ownerFile) -ceq $match.Groups[1].Value
    ) -Message 'sealed source owner hash changed.'
  }

  if ($ValidationPhase -ceq 'source') {
    return [pscustomobject]@{
      phase = 'source'; manifestOwners = $manifestLines.Count
      browserProofValidated = $false
    }
  }

  if (-not $ValidationRequirePersistedBrowserBinding) {
    Assert-C34LBlockerBrowser -Condition (
      [string]::IsNullOrWhiteSpace(
        [string]$state.presealUploadWorkflow.browserSessionId
      ) -and
      [string]::IsNullOrWhiteSpace(
        [string]$aggregate.presealUploadWorkflow.browserSessionId
      )
    ) -Message 'browser proof session was already consumed or replayed.'
  }

  $expectedMachineState = if ($ValidationRequirePersistedBrowserBinding) {
    'postbuild_qualified_internal_testing_upload_authority_available_once'
  } else { 'single_release_AAB_succeeded_authority_consumed' }
  $expectedUploadAuthority = if ($ValidationRequirePersistedBrowserBinding) {
    'available_once'
  } else { 'held_postbuild_qualification' }
  Assert-C34LBlockerBrowser -Condition (
    [string]$state.machineState -ceq $expectedMachineState -and
    [string]$aggregate.machineState -ceq $expectedMachineState -and
    [string]$state.uploadAuthorization -ceq $expectedUploadAuthority -and
    [int]$state.actionCounts.build -eq 1 -and
    [int]$state.actionCounts.upload -eq 0 -and
    [int]$state.actionCounts.install -eq 0 -and
    [int]$state.actionCounts.deviceAcceptance -eq 0 -and
    [string]$state.releaseAuthorities.build -ceq 'consumed' -and
    [string]$state.releaseAuthorities.uploadAndInternalActivation -ceq
      $expectedUploadAuthority -and
    [string]$aggregate.releaseAuthorities.uploadAndInternalActivation -ceq
      $expectedUploadAuthority -and
    [string]$state.releaseAuthorities.inPlaceOppoPlayUpdate -ceq
      'held_postupload_qualification' -and
    [string]$state.releaseAuthorities.postinstallAcceptance -ceq
      'held_postinstall_journey_qualification'
  ) -Message 'preupload machine state, counts or future authority vector changed.'
  $proofFile = Resolve-C34LBlockerBrowserFile `
    $ValidationBrowserProofPath 'current-session browser proof'
  Assert-C34LBlockerBrowser -Condition (
    $ValidationBrowserProofPath.Replace('\', '/') -ceq
      (ConvertTo-C34LBlockerBrowserRelativePath `
        $proofFile 'current-session browser proof')
  ) -Message 'current-session browser proof path is not canonical and exact.'
  if ($ValidationFixtureMode) {
    Assert-C34LBlockerBrowserFixtureFile $proofFile $fixtureRunRoot `
      'fixture current-session browser proof'
  }
  Assert-C34LBlockerBrowserFileIdentity $proofFile `
    $ValidationBrowserProofSha256 $ValidationBrowserProofBytes `
    'current-session browser proof'
  $evidenceRoot = [string](
    Get-C34LBlockerBrowserProperty $state 'evidenceRoot' 'detailed state'
  )
  $evidenceRootFile = [IO.Path]::GetFullPath((Join-Path $root $evidenceRoot))
  $evidenceRootPrefix = $evidenceRootFile.TrimEnd([char[]]@('\', '/')) +
    [IO.Path]::DirectorySeparatorChar
  Assert-C34LBlockerBrowser -Condition (
    $evidenceRootFile.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message 'C34L evidence root escaped the production repository.'
  if ($ValidationFixtureMode) {
    Assert-C34LBlockerBrowser -Condition (
      $evidenceRootFile.Equals(
        $fixtureRunRoot,
        [StringComparison]::OrdinalIgnoreCase
      )
    ) -Message 'fixture evidence root is not the exact unique run root.'
  }
  Assert-C34LBlockerBrowser -Condition (
    $proofFile.StartsWith($evidenceRootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message 'current-session browser proof escaped the exact C34L evidence root.'

  $proofText = Get-Content -Raw -LiteralPath $proofFile
  $proof = $proofText | ConvertFrom-Json
  foreach ($timestampName in @('producedUtc', 'expiresUtc')) {
    $timestampMatches = [regex]::Matches(
      $proofText,
      '"' + $timestampName + '"\s*:\s*"([^"]+)"'
    )
    Assert-C34LBlockerBrowser -Condition ($timestampMatches.Count -eq 1) `
      -Message "browser proof must contain one exact $timestampName string."
    $proof.PSObject.Properties[$timestampName].Value =
      [string]$timestampMatches[0].Groups[1].Value
  }
  Assert-C34LBlockerBrowser -Condition (
    $null -eq $proof.PSObject.Properties['nonce']
  ) -Message 'browser proof must never contain a raw session nonce.'
  $proofNames = @(
    'schemaVersion', 'contractId', 'ticketId', 'attempt', 'versionName',
    'versionCode', 'transition', 'phase', 'stateSha256', 'aggregateSha256',
    'sourceManifest', 'blockerLedger', 'sessionId', 'sessionNonceSha256',
    'producerId', 'producedUtc', 'expiresUtc', 'routes', 'actionCounts',
    'releaseAuthorities', 'copiedFromPriorCandidate',
    'noPlayWritePerformed', 'uploadActionCount', 'activationActionCount',
    'otherTrackActionCount', 'privateValuesObserved'
  )
  $sourceManifestNames = @('path', 'sha256', 'bytes')
  $blockerLedgerNames = @('path', 'sha256', 'bytes', 'mutableOutsideSourceSeal')
  $routeNames = @(
    'liveBrowserRouteQualified', 'signedInMoolSocialAppRouteProved',
    'internalTestingRouteProved', 'sanitizedHost', 'sanitizedPath',
    'queryPresent', 'fragmentPresent'
  )
  $proofCountNames = @(
    'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
    'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
  )
  $proofAuthorityNames = @(
    'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  )
  Assert-C34LBlockerBrowser -Condition (
    (@($proof.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($proofNames | Sort-Object) -join ',') -and
    (@($proof.sourceManifest.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($sourceManifestNames | Sort-Object) -join ',') -and
    (@($proof.blockerLedger.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($blockerLedgerNames | Sort-Object) -join ',') -and
    (@($proof.routes.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($routeNames | Sort-Object) -join ',') -and
    (@($proof.actionCounts.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($proofCountNames | Sort-Object) -join ',') -and
    (@($proof.releaseAuthorities.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($proofAuthorityNames | Sort-Object) -join ',')
  ) -Message 'browser proof exact top-level or nested schema changed.'
  foreach ($name in $proofNames) {
    [void](Get-C34LBlockerBrowserProperty $proof $name 'browser proof')
  }
  Assert-C34LBlockerBrowser -Condition (
    [int]$proof.schemaVersion -eq 1 -and
    [string]$proof.contractId -ceq $browserContractId -and
    [string]$proof.ticketId -ceq $ticketId -and
    [int]$proof.attempt -eq $ValidationAttempt -and
    [string]$proof.versionName -ceq $versionName -and
    [string]$proof.versionCode -ceq $versionCode -and
    [string]$proof.transition -ceq 'upload-authorized' -and
    [string]$proof.phase -ceq 'preupload'
  ) -Message 'browser proof ticket, attempt, version, transition or phase changed.'
  $expectedPreStateSha256 = if ($ValidationRequirePersistedBrowserBinding) {
    [string]$state.presealUploadWorkflow.browserEvidencePreStateSha256
  } else { Get-C34LBlockerBrowserSha256 $stateFile }
  $expectedPreAggregateSha256 = if ($ValidationRequirePersistedBrowserBinding) {
    [string]$state.presealUploadWorkflow.browserEvidencePreAggregateSha256
  } else { Get-C34LBlockerBrowserSha256 $aggregateFile }
  Assert-C34LBlockerBrowser -Condition (
    [string]$proof.stateSha256 -ceq $expectedPreStateSha256 -and
    [string]$proof.aggregateSha256 -ceq $expectedPreAggregateSha256
  ) -Message 'browser proof is stale for the current detailed or aggregate state.'
  Assert-C34LBlockerBrowser -Condition (
    [string]$proof.sourceManifest.path -ceq $ValidationSourceManifestPath -and
    [string]$proof.sourceManifest.sha256 -ceq
      $ValidationSourceManifestSha256 -and
    [long]$proof.sourceManifest.bytes -eq $ValidationSourceManifestBytes -and
    [string]$proof.blockerLedger.path -ceq $ValidationBlockerLedgerPath -and
    [string]$proof.blockerLedger.sha256 -ceq
      $ValidationBlockerLedgerSha256 -and
    [long]$proof.blockerLedger.bytes -eq $ValidationBlockerLedgerBytes -and
    [bool]$proof.blockerLedger.mutableOutsideSourceSeal
  ) -Message 'browser proof source manifest or mutable ledger binding changed.'
  Assert-C34LBlockerBrowser -Condition (
    [bool]$proof.routes.liveBrowserRouteQualified -and
    [bool]$proof.routes.signedInMoolSocialAppRouteProved -and
    [bool]$proof.routes.internalTestingRouteProved -and
    [string]$proof.routes.sanitizedHost -ceq 'play.google.com' -and
    [string]$proof.routes.sanitizedPath -ceq '/console/app/internal-testing' -and
    -not [bool]$proof.routes.queryPresent -and
    -not [bool]$proof.routes.fragmentPresent
  ) -Message 'browser proof routes or sanitized host/path changed.'
  $session = Get-C34LBlockerBrowserSession $proof
  Assert-C34LBlockerBrowser -Condition (
    -not [bool]$proof.copiedFromPriorCandidate -and
    [bool]$proof.noPlayWritePerformed -and
    [int]$proof.uploadActionCount -eq 0 -and
    [int]$proof.activationActionCount -eq 0 -and
    [int]$proof.otherTrackActionCount -eq 0 -and
    -not [bool]$proof.privateValuesObserved
  ) -Message 'browser proof freshness, privacy or zero-action truth changed.'
  if ($ValidationRequirePersistedBrowserBinding) {
    Assert-C34LBlockerBrowserRawUtcTokens `
      $stateText 'browserEvidenceProducedUtc' $session.producedUtc 2 `
      'persisted detailed state'
    Assert-C34LBlockerBrowserRawUtcTokens `
      $stateText 'browserEvidenceExpiresUtc' $session.expiresUtc 2 `
      'persisted detailed state'
    Assert-C34LBlockerBrowserRawUtcTokens `
      $aggregateText 'browserEvidenceProducedUtc' $session.producedUtc 2 `
      'persisted aggregate state'
    Assert-C34LBlockerBrowserRawUtcTokens `
      $aggregateText 'browserEvidenceExpiresUtc' $session.expiresUtc 2 `
      'persisted aggregate state'
    Assert-C34LBlockerBrowserPersistedPreimage `
      -Proof $proof -State $state -Aggregate $aggregate `
      -ProofPath $ValidationBrowserProofPath `
      -ProofSha256 $ValidationBrowserProofSha256 `
      -ProofBytes $ValidationBrowserProofBytes
  } else {
    Assert-C34LBlockerBrowserVector $proof $state $aggregate
  }
  Assert-C34LBlockerBrowserStateBinding `
    -State $state -Aggregate $aggregate -Proof $proof -Session $session `
    -ProofPath $ValidationBrowserProofPath `
    -ProofSha256 $ValidationBrowserProofSha256 `
    -ProofBytes $ValidationBrowserProofBytes `
    -ProofAttempt $ValidationAttempt `
    -RequirePersisted $ValidationRequirePersistedBrowserBinding

  return [pscustomobject]@{
    phase = 'preupload'; manifestOwners = $manifestLines.Count
    browserProofValidated = $true
    persistedBindingValidated = $ValidationRequirePersistedBrowserBinding
  }
}

function Invoke-C34LBlockerBrowserExpectedRejection {
  param(
    [Parameter(Mandatory)][scriptblock]$Action,
    [Parameter(Mandatory)][string]$Expected,
    [Parameter(Mandatory)][string]$Name
  )
  $caught = $null
  try { & $Action | Out-Null } catch { $caught = $_.Exception.Message }
  Assert-C34LBlockerBrowser -Condition (
    -not [string]::IsNullOrWhiteSpace([string]$caught) -and
    [string]$caught -clike "*$Expected*"
  ) -Message "negative fixture was not rejected as intended: $Name."
}

function Set-C34LBlockerBrowserPersistedFixture {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][object]$Proof,
    [Parameter(Mandatory)][string]$ProofPath,
    [Parameter(Mandatory)][string]$ProofSha256,
    [Parameter(Mandatory)][long]$ProofBytes,
    [Parameter(Mandatory)][string]$PreStateText,
    [Parameter(Mandatory)][string]$PreAggregateText
  )
  $binding = New-C34LBlockerBrowserBinding `
    $Proof $ProofPath $ProofSha256 $ProofBytes
  $record = [pscustomobject][ordered]@{
    ticketId = $ticketId; attempt = [int]$Proof.attempt
    transition = 'upload-authorized'; phase = 'preupload'
    evidencePath = $ProofPath; sha256 = $ProofSha256
    preStateSha256 = [string]$Proof.stateSha256
    preAggregateSha256 = [string]$Proof.aggregateSha256
    actionCounts = Copy-C34LBlockerBrowserObject $Proof.actionCounts
    releaseAuthorities = Copy-C34LBlockerBrowserObject $Proof.releaseAuthorities
    browserEvidence = $binding
  }
  foreach ($owner in @($State, $Aggregate)) {
    $owner | Add-Member -NotePropertyName lifecycleTransactionProofs `
      -NotePropertyValue @($record) -Force
  }
  $State.machineState =
    'postbuild_qualified_internal_testing_upload_authority_available_once'
  $Aggregate.machineState = $State.machineState
  $State.uploadAuthorization = 'available_once'
  $State.releaseAuthorities.uploadAndInternalActivation = 'available_once'
  $Aggregate.releaseAuthorities.uploadAndInternalActivation = 'available_once'
  foreach ($owner in @($State.presealUploadWorkflow, $Aggregate.presealUploadWorkflow)) {
    $owner.browserEvidencePath = $ProofPath
    $owner.browserEvidenceSha256 = $ProofSha256
    $owner.browserEvidenceBytes = $ProofBytes
    $owner.browserEvidenceAttempt = [int]$Proof.attempt
    $owner.browserEvidenceTransition = 'upload-authorized'
    $owner.browserEvidencePhase = 'preupload'
    $owner.browserEvidencePreStateSha256 = [string]$Proof.stateSha256
    $owner.browserEvidencePreAggregateSha256 = [string]$Proof.aggregateSha256
    $owner.browserSessionId = [string]$Proof.sessionId
    $owner.browserSessionNonceSha256 = [string]$Proof.sessionNonceSha256
    $owner.browserEvidenceProducerId = [string]$Proof.producerId
    $owner.browserEvidenceProducedUtc = [string]$Proof.producedUtc
    $owner.browserEvidenceExpiresUtc = [string]$Proof.expiresUtc
    $owner.sourceManifestPath = [string]$Proof.sourceManifest.path
    $owner.sourceManifestSha256 = [string]$Proof.sourceManifest.sha256
    $owner.sourceManifestBytes = [long]$Proof.sourceManifest.bytes
    $owner.blockerLedgerPath = [string]$Proof.blockerLedger.path
    $owner.blockerLedgerSha256 = [string]$Proof.blockerLedger.sha256
    $owner.blockerLedgerBytes = [long]$Proof.blockerLedger.bytes
    $owner.liveBrowserRouteQualified = [bool]$Proof.routes.liveBrowserRouteQualified
    $owner.signedInMoolSocialAppRouteProved =
      [bool]$Proof.routes.signedInMoolSocialAppRouteProved
    $owner.internalTestingRouteProved =
      [bool]$Proof.routes.internalTestingRouteProved
    $owner.noPlayWritePerformed = [bool]$Proof.noPlayWritePerformed
  }
  $journalRoot = Join-Path (
    [IO.Path]::GetFullPath((Join-Path $root ([string]$State.evidenceRoot)))
  ) 'release-transaction-journals'
  if (-not (Test-Path -LiteralPath $journalRoot -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $journalRoot)
  }
  $journal = [pscustomobject][ordered]@{
    sequence = 1; ticketId = $ticketId; attempt = [int]$Proof.attempt
    transition = 'upload-authorized'; prerequisiteGatePhase = 'preupload'
    stateBeforeSha256 = [string]$Proof.stateSha256
    aggregateBeforeSha256 = [string]$Proof.aggregateSha256
    stateBeforeBase64 = [Convert]::ToBase64String($utf8.GetBytes($PreStateText))
    aggregateBeforeBase64 =
      [Convert]::ToBase64String($utf8.GetBytes($PreAggregateText))
    browserEvidence = $binding
  }
  Write-C34LBlockerBrowserJson $journal (
    Join-Path $journalRoot 'transaction-browser-fixture.json'
  )
}

function Invoke-C34LBlockerBrowserSelfTest {
  $fixtureRootRelative = $fixturePrefixRelative + $PID + '-' +
    [Guid]::NewGuid().ToString('N')
  $fixtureRoot = Join-Path $root $fixtureRootRelative
  $siblingFixtureRootRelative = $fixtureRootRelative + '-sibling'
  $siblingFixtureRoot = Join-Path $root $siblingFixtureRootRelative
  [void](New-Item -ItemType Directory -Path $fixtureRoot)
  $stateRelative = "$fixtureRootRelative/state.json"
  $aggregateRelative = "$fixtureRootRelative/aggregate.json"
  $manifestRelative = "$fixtureRootRelative/source-manifest.txt"
  $ledgerRelative = "$fixtureRootRelative/blocker-ledger.json"
  $proofRelative = "$fixtureRootRelative/browser-proof.json"
  $sourceOwnerRelative = "$fixtureRootRelative/source-owner.txt"
  $stateFile = Join-Path $root $stateRelative
  $aggregateFile = Join-Path $root $aggregateRelative
  $manifestFile = Join-Path $root $manifestRelative
  $ledgerFile = Join-Path $root $ledgerRelative
  $proofFile = Join-Path $root $proofRelative
  $sourceOwnerFile = Join-Path $root $sourceOwnerRelative
  try {
    [IO.File]::WriteAllText($sourceOwnerFile, "fixture source owner`n", $utf8)
    $realLedger = Get-Content -Raw -LiteralPath (
      Join-Path $root $expectedLedgerPath
    ) | ConvertFrom-Json
    Write-C34LBlockerBrowserJson $realLedger $ledgerFile
    $ledgerHash = Get-C34LBlockerBrowserSha256 $ledgerFile
    $ledgerBytes = (Get-Item -LiteralPath $ledgerFile).Length
    $sourceOwnerHash = Get-C34LBlockerBrowserSha256 $sourceOwnerFile
    [IO.File]::WriteAllText(
      $manifestFile,
      "$sourceOwnerHash  $sourceOwnerRelative`n",
      $utf8
    )
    $manifestHash = Get-C34LBlockerBrowserSha256 $manifestFile
    $manifestBytes = (Get-Item -LiteralPath $manifestFile).Length
    $actionCounts = [pscustomobject][ordered]@{
      build = 1; upload = 0; install = 0; deviceAcceptance = 0
      passwordlessEmailSend = 0; realSmsSend = 0; otherTrack = 0
      backendHostingProviderOrProductionDeployment = 0
    }
    $releaseAuthorities = [pscustomobject][ordered]@{
      build = 'consumed'
      uploadAndInternalActivation = 'held_postbuild_qualification'
      inPlaceOppoPlayUpdate = 'held_postupload_qualification'
      postinstallAcceptance = 'held_postinstall_journey_qualification'
    }
    $sourceQualification = [pscustomobject][ordered]@{
      requiredIdenticalCycles = 2; completedIdenticalCycles = 2
      manifestPath = $manifestRelative; manifestSha256 = $manifestHash
      manifestBytes = $manifestBytes; fileCount = 1
    }
    $workflow = [pscustomobject][ordered]@{
      browserEvidencePath = $null; browserEvidenceSha256 = $null
      browserEvidenceBytes = 0; browserEvidenceAttempt = 0
      browserEvidenceTransition = $null; browserEvidencePhase = $null
      browserEvidencePreStateSha256 = $null
      browserEvidencePreAggregateSha256 = $null
      browserSessionId = $null; browserSessionNonceSha256 = $null
      browserEvidenceProducerId = $null; browserEvidenceProducedUtc = $null
      browserEvidenceExpiresUtc = $null
      sourceManifestPath = $null; sourceManifestSha256 = $null
      sourceManifestBytes = 0; blockerLedgerPath = $null
      blockerLedgerSha256 = $null; blockerLedgerBytes = 0
      liveBrowserRouteQualified = $false
      signedInMoolSocialAppRouteProved = $false
      internalTestingRouteProved = $false
      noPlayWritePerformed = $true
    }
    $candidate = [pscustomobject][ordered]@{
      id = $ticketId; versionName = $versionName; versionCode = $versionCode
    }
    $state = [pscustomobject][ordered]@{
      schemaVersion = 1; ticketId = $ticketId; candidate = $candidate
      aggregateStatePath = $aggregateRelative; evidenceRoot = $fixtureRootRelative
      machineState = 'single_release_AAB_succeeded_authority_consumed'
      uploadAuthorization = 'held_postbuild_qualification'
      actionCounts = $actionCounts
      releaseAuthorities = $releaseAuthorities
      sourcePrerequisites = [pscustomobject][ordered]@{
        blockerLedgerPath = $ledgerRelative
        blockerLedgerGatePath =
          'scripts/check-uaw-c33g-fix4-unresolved-acceptance-blocker-pre-aab-ledger.ps1'
        blockerLedgerPrebuildSha256 = $ledgerHash
      }
      sourceQualification = $sourceQualification
      presealUploadWorkflow = $workflow
    }
    $aggregate = [pscustomobject][ordered]@{
      schemaVersion = 1; ticketId = $ticketId
      candidate = Copy-C34LBlockerBrowserObject $candidate
      machineState = $state.machineState
      actionCounts = Copy-C34LBlockerBrowserObject $actionCounts
      releaseAuthorities = Copy-C34LBlockerBrowserObject $releaseAuthorities
      sourceQualification = Copy-C34LBlockerBrowserObject $sourceQualification
      presealUploadWorkflow = Copy-C34LBlockerBrowserObject $workflow
    }
    Write-C34LBlockerBrowserJson $state $stateFile
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    $stateHash = Get-C34LBlockerBrowserSha256 $stateFile
    $aggregateHash = Get-C34LBlockerBrowserSha256 $aggregateFile
    $sessionNonceSha256 = 'C' * 64
    $sessionProducedUtc = ConvertTo-C34LBlockerBrowserUtcText `
      ([DateTime]::UtcNow.AddMinutes(-1))
    $sessionExpiresUtc = ConvertTo-C34LBlockerBrowserUtcText `
      ([DateTime]::UtcNow.AddMinutes(9))
    $proof = [pscustomobject][ordered]@{
      schemaVersion = 1; contractId = $browserContractId; ticketId = $ticketId
      attempt = 1; versionName = $versionName; versionCode = $versionCode
      transition = 'upload-authorized'; phase = 'preupload'
      stateSha256 = $stateHash; aggregateSha256 = $aggregateHash
      sourceManifest = [pscustomobject][ordered]@{
        path = $manifestRelative; sha256 = $manifestHash; bytes = $manifestBytes
      }
      blockerLedger = [pscustomobject][ordered]@{
        path = $ledgerRelative; sha256 = $ledgerHash; bytes = $ledgerBytes
        mutableOutsideSourceSeal = $true
      }
      sessionId = 'c34l-browser-session-' + $sessionNonceSha256.Substring(0, 16)
      sessionNonceSha256 = $sessionNonceSha256
      producerId = $browserProducerId
      producedUtc = $sessionProducedUtc; expiresUtc = $sessionExpiresUtc
      routes = [pscustomobject][ordered]@{
        liveBrowserRouteQualified = $true
        signedInMoolSocialAppRouteProved = $true
        internalTestingRouteProved = $true
        sanitizedHost = 'play.google.com'
        sanitizedPath = '/console/app/internal-testing'
        queryPresent = $false; fragmentPresent = $false
      }
      actionCounts = Copy-C34LBlockerBrowserObject $actionCounts
      releaseAuthorities = Copy-C34LBlockerBrowserObject $releaseAuthorities
      copiedFromPriorCandidate = $false
      noPlayWritePerformed = $true; uploadActionCount = 0
      activationActionCount = 0; otherTrackActionCount = 0
      privateValuesObserved = $false
    }
    Write-C34LBlockerBrowserJson $proof $proofFile

    $common = @{
      ValidationStatePath = $stateRelative
      ValidationSourceManifestPath = $manifestRelative
      ValidationSourceManifestSha256 = $manifestHash
      ValidationSourceManifestBytes = $manifestBytes
      ValidationBlockerLedgerPath = $ledgerRelative
      ValidationBlockerLedgerSha256 = $ledgerHash
      ValidationBlockerLedgerBytes = $ledgerBytes
      ValidationBrowserProofPath = $proofRelative
      ValidationAttempt = 1
      ValidationRequirePersistedBrowserBinding = $false
      ValidationFixtureMode = $true
    }
    $sourceResult = Invoke-C34LBlockerBrowserValidation @common `
      -ValidationPhase source
    $proofHash = Get-C34LBlockerBrowserSha256 $proofFile
    $proofBytes = (Get-Item -LiteralPath $proofFile).Length
    $common.ValidationBrowserProofSha256 = $proofHash
    $common.ValidationBrowserProofBytes = $proofBytes
    $preuploadResult = Invoke-C34LBlockerBrowserValidation @common `
      -ValidationPhase preupload

    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofPath =
      "$fixtureRootRelative/missing-proof.json"
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'missing-proof' `
      -Expected 'current-session browser proof is missing' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 = 'F' * 64
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'wrong-hash' `
      -Expected 'current-session browser proof SHA-256 or byte length changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofBytes = $proofBytes + 1
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'wrong-bytes' `
      -Expected 'current-session browser proof SHA-256 or byte length changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $extraFreshness = Copy-C34LBlockerBrowserObject $proof
    $extraFreshness | Add-Member -NotePropertyName freshSessionProof `
      -NotePropertyValue $true
    Write-C34LBlockerBrowserJson $extraFreshness $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'extra-freshness-field' `
      -Expected 'exact top-level or nested schema changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $wrongPhase = Copy-C34LBlockerBrowserObject $proof
    $wrongPhase.phase = 'postbuild'
    Write-C34LBlockerBrowserJson $wrongPhase $proofFile
    $wrongPhaseHash = Get-C34LBlockerBrowserSha256 $proofFile
    $wrongPhaseBytes = (Get-Item -LiteralPath $proofFile).Length
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 = $wrongPhaseHash
    $caseParameters.ValidationBrowserProofBytes = $wrongPhaseBytes
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'wrong-phase' `
      -Expected 'ticket, attempt, version, transition or phase changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $wrongTransition = Copy-C34LBlockerBrowserObject $proof
    $wrongTransition.transition = 'upload-succeeded'
    Write-C34LBlockerBrowserJson $wrongTransition $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'wrong-transition' `
      -Expected 'ticket, attempt, version, transition or phase changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $wrongRoute = Copy-C34LBlockerBrowserObject $proof
    $wrongRoute.routes.internalTestingRouteProved = $false
    Write-C34LBlockerBrowserJson $wrongRoute $proofFile
    $wrongRouteHash = Get-C34LBlockerBrowserSha256 $proofFile
    $wrongRouteBytes = (Get-Item -LiteralPath $proofFile).Length
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 = $wrongRouteHash
    $caseParameters.ValidationBrowserProofBytes = $wrongRouteBytes
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'wrong-route' `
      -Expected 'routes or sanitized host/path changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $wrongSanitizedPath = Copy-C34LBlockerBrowserObject $proof
    $wrongSanitizedPath.routes.sanitizedPath = '/console/app/production'
    Write-C34LBlockerBrowserJson $wrongSanitizedPath $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'wrong-sanitized-path' `
      -Expected 'routes or sanitized host/path changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $queryPresent = Copy-C34LBlockerBrowserObject $proof
    $queryPresent.routes.queryPresent = $true
    Write-C34LBlockerBrowserJson $queryPresent $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'query-present' `
      -Expected 'routes or sanitized host/path changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $wrongSourceBinding = Copy-C34LBlockerBrowserObject $proof
    $wrongSourceBinding.sourceManifest.sha256 = 'E' * 64
    Write-C34LBlockerBrowserJson $wrongSourceBinding $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'source-binding-tamper' `
      -Expected 'source manifest or mutable ledger binding changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $wrongProducer = Copy-C34LBlockerBrowserObject $proof
    $wrongProducer.producerId = 'UNREGISTERED-BROWSER-PRODUCER'
    Write-C34LBlockerBrowserJson $wrongProducer $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'wrong-producer' `
      -Expected 'session id, nonce hash or producer identity changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $wrongNonce = Copy-C34LBlockerBrowserObject $proof
    $wrongNonce.sessionNonceSha256 = 'D' * 64
    Write-C34LBlockerBrowserJson $wrongNonce $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'wrong-nonce-hash' `
      -Expected 'session id, nonce hash or producer identity changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $expired = Copy-C34LBlockerBrowserObject $proof
    $expired.producedUtc = ConvertTo-C34LBlockerBrowserUtcText `
      ([DateTime]::UtcNow.AddMinutes(-31))
    $expired.expiresUtc = ConvertTo-C34LBlockerBrowserUtcText `
      ([DateTime]::UtcNow.AddMinutes(-16))
    Write-C34LBlockerBrowserJson $expired $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'expired-session' `
      -Expected 'session timestamp is stale, future-dated or unbounded' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $malformedTimestamp = Copy-C34LBlockerBrowserObject $proof
    $malformedTimestamp.producedUtc = 'not-a-timestamp'
    Write-C34LBlockerBrowserJson $malformedTimestamp $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'malformed-timestamp' `
      -Expected 'producedUtc is not an exact UTC timestamp' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $nonUtcTimestamp = Copy-C34LBlockerBrowserObject $proof
    $nonUtcTimestamp.producedUtc =
      ([string]$proof.producedUtc).Replace('Z', '+00:00')
    Write-C34LBlockerBrowserJson $nonUtcTimestamp $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'non-utc-timestamp' `
      -Expected 'producedUtc is not an exact UTC timestamp' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $extraPrecisionTimestamp = Copy-C34LBlockerBrowserObject $proof
    $extraPrecisionTimestamp.producedUtc =
      ([string]$proof.producedUtc).Replace('Z', '0Z')
    Write-C34LBlockerBrowserJson $extraPrecisionTimestamp $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'extra-precision-timestamp' `
      -Expected 'producedUtc is not an exact UTC timestamp' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $futureTimestamp = Copy-C34LBlockerBrowserObject $proof
    $futureTimestamp.producedUtc = ConvertTo-C34LBlockerBrowserUtcText `
      ([DateTime]::UtcNow.AddMinutes(5))
    $futureTimestamp.expiresUtc = ConvertTo-C34LBlockerBrowserUtcText `
      ([DateTime]::UtcNow.AddMinutes(10))
    Write-C34LBlockerBrowserJson $futureTimestamp $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'future-timestamp' `
      -Expected 'session timestamp is stale, future-dated or unbounded' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $rawNonce = Copy-C34LBlockerBrowserObject $proof
    $rawNonce | Add-Member -NotePropertyName nonce `
      -NotePropertyValue 'fixture-raw-nonce-must-never-be-read'
    Write-C34LBlockerBrowserJson $rawNonce $proofFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 =
      Get-C34LBlockerBrowserSha256 $proofFile
    $caseParameters.ValidationBrowserProofBytes =
      (Get-Item -LiteralPath $proofFile).Length
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'raw-nonce' `
      -Expected 'must never contain a raw session nonce' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $stale = Copy-C34LBlockerBrowserObject $proof
    $stale.stateSha256 = '0' * 64
    Write-C34LBlockerBrowserJson $stale $proofFile
    $staleHash = Get-C34LBlockerBrowserSha256 $proofFile
    $staleBytes = (Get-Item -LiteralPath $proofFile).Length
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 = $staleHash
    $caseParameters.ValidationBrowserProofBytes = $staleBytes
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'stale-proof' `
      -Expected 'stale for the current detailed or aggregate state' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $wrongAttempt = Copy-C34LBlockerBrowserObject $proof
    $wrongAttempt.attempt = 2
    Write-C34LBlockerBrowserJson $wrongAttempt $proofFile
    $wrongAttemptHash = Get-C34LBlockerBrowserSha256 $proofFile
    $wrongAttemptBytes = (Get-Item -LiteralPath $proofFile).Length
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofSha256 = $wrongAttemptHash
    $caseParameters.ValidationBrowserProofBytes = $wrongAttemptBytes
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'wrong-attempt' `
      -Expected 'ticket, attempt, version, transition or phase changed' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $ledgerRow = "$ledgerHash  $ledgerRelative`n"
    [IO.File]::WriteAllText(
      $manifestFile,
      "$sourceOwnerHash  $sourceOwnerRelative`n$ledgerRow",
      $utf8
    )
    $sealedManifestHash = Get-C34LBlockerBrowserSha256 $manifestFile
    $sealedManifestBytes = (Get-Item -LiteralPath $manifestFile).Length
    $state.sourceQualification.manifestSha256 = $sealedManifestHash
    $state.sourceQualification.manifestBytes = $sealedManifestBytes
    $aggregate.sourceQualification.manifestSha256 = $sealedManifestHash
    $aggregate.sourceQualification.manifestBytes = $sealedManifestBytes
    Write-C34LBlockerBrowserJson $state $stateFile
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationSourceManifestSha256 = $sealedManifestHash
    $caseParameters.ValidationSourceManifestBytes = $sealedManifestBytes
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'sealed-ledger' `
      -Expected 'mutable C33G blocker ledger must remain outside the source seal' `
      -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase source
      }

    $ledgerAlias = "$fixtureRootRelative/alias/../blocker-ledger.json"
    [IO.File]::WriteAllText(
      $manifestFile,
      "$sourceOwnerHash  $sourceOwnerRelative`n$ledgerHash  $ledgerAlias`n",
      $utf8
    )
    $aliasManifestHash = Get-C34LBlockerBrowserSha256 $manifestFile
    $aliasManifestBytes = (Get-Item -LiteralPath $manifestFile).Length
    $state.sourceQualification.manifestSha256 = $aliasManifestHash
    $state.sourceQualification.manifestBytes = $aliasManifestBytes
    $aggregate.sourceQualification.manifestSha256 = $aliasManifestHash
    $aggregate.sourceQualification.manifestBytes = $aliasManifestBytes
    Write-C34LBlockerBrowserJson $state $stateFile
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationSourceManifestSha256 = $aliasManifestHash
    $caseParameters.ValidationSourceManifestBytes = $aliasManifestBytes
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'ledger-alias' `
      -Expected 'mutable C33G blocker ledger must remain outside the source seal' `
      -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase source
      }

    $ownerAlias = "$fixtureRootRelative/alias/../source-owner.txt"
    [IO.File]::WriteAllText(
      $manifestFile,
      "$sourceOwnerHash  $sourceOwnerRelative`n$sourceOwnerHash  $ownerAlias`n",
      $utf8
    )
    $duplicateManifestHash = Get-C34LBlockerBrowserSha256 $manifestFile
    $duplicateManifestBytes = (Get-Item -LiteralPath $manifestFile).Length
    $state.sourceQualification.manifestSha256 = $duplicateManifestHash
    $state.sourceQualification.manifestBytes = $duplicateManifestBytes
    $aggregate.sourceQualification.manifestSha256 = $duplicateManifestHash
    $aggregate.sourceQualification.manifestBytes = $duplicateManifestBytes
    Write-C34LBlockerBrowserJson $state $stateFile
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    $caseParameters = $common.Clone()
    $caseParameters.ValidationSourceManifestSha256 = $duplicateManifestHash
    $caseParameters.ValidationSourceManifestBytes = $duplicateManifestBytes
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'duplicate-owner-alias' `
      -Expected 'duplicate canonical owner or alias' -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase source
      }

    [IO.File]::WriteAllText(
      $manifestFile,
      "$sourceOwnerHash  $sourceOwnerRelative`n",
      $utf8
    )
    $manifestHash = Get-C34LBlockerBrowserSha256 $manifestFile
    $manifestBytes = (Get-Item -LiteralPath $manifestFile).Length
    $state.sourceQualification.manifestSha256 = $manifestHash
    $state.sourceQualification.manifestBytes = $manifestBytes
    $aggregate.sourceQualification.manifestSha256 = $manifestHash
    $aggregate.sourceQualification.manifestBytes = $manifestBytes
    Write-C34LBlockerBrowserJson $state $stateFile
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    $proof.stateSha256 = Get-C34LBlockerBrowserSha256 $stateFile
    $proof.aggregateSha256 = Get-C34LBlockerBrowserSha256 $aggregateFile
    $proof.sourceManifest.sha256 = $manifestHash
    $proof.sourceManifest.bytes = $manifestBytes
    Write-C34LBlockerBrowserJson $proof $proofFile
    $proofHash = Get-C34LBlockerBrowserSha256 $proofFile
    $proofBytes = (Get-Item -LiteralPath $proofFile).Length
    $common.ValidationSourceManifestSha256 = $manifestHash
    $common.ValidationSourceManifestBytes = $manifestBytes
    $common.ValidationBrowserProofSha256 = $proofHash
    $common.ValidationBrowserProofBytes = $proofBytes

    [void](New-Item -ItemType Directory -Path $siblingFixtureRoot)
    $siblingProofRelative = "$siblingFixtureRootRelative/browser-proof.json"
    [IO.File]::WriteAllText(
      (Join-Path $root $siblingProofRelative),
      [IO.File]::ReadAllText($proofFile),
      $utf8
    )
    $caseParameters = $common.Clone()
    $caseParameters.ValidationBrowserProofPath = $siblingProofRelative
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'fixture-root-traversal' `
      -Expected 'escaped the exact unique C34L blocker/browser fixture run root' `
      -Action {
        Invoke-C34LBlockerBrowserValidation @caseParameters `
          -ValidationPhase preupload
      }

    $preStateText = [IO.File]::ReadAllText($stateFile)
    $preAggregateText = [IO.File]::ReadAllText($aggregateFile)
    Set-C34LBlockerBrowserPersistedFixture `
      -State $state -Aggregate $aggregate -Proof $proof `
      -ProofPath $proofRelative -ProofSha256 $proofHash -ProofBytes $proofBytes `
      -PreStateText $preStateText -PreAggregateText $preAggregateText
    Write-C34LBlockerBrowserJson $state $stateFile
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    $persistedParameters = $common.Clone()
    $persistedParameters.ValidationRequirePersistedBrowserBinding = $true
    $persistedResult = Invoke-C34LBlockerBrowserValidation `
      @persistedParameters -ValidationPhase preupload

    $aggregate.presealUploadWorkflow.browserEvidenceSha256 = 'F' * 64
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'state-mirror-mismatch' `
      -Expected 'browser evidence state mirror changed' -Action {
        Invoke-C34LBlockerBrowserValidation @persistedParameters `
          -ValidationPhase preupload
      }
    $aggregate.presealUploadWorkflow.browserEvidenceSha256 = $proofHash
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile

    $aggregate.presealUploadWorkflow.sourceManifestSha256 = 'F' * 64
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'source-mirror-mismatch' `
      -Expected 'browser evidence state mirror changed' -Action {
        Invoke-C34LBlockerBrowserValidation @persistedParameters `
          -ValidationPhase preupload
      }
    $aggregate.presealUploadWorkflow.sourceManifestSha256 = $manifestHash
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile

    $aggregate.presealUploadWorkflow | Add-Member `
      -NotePropertyName freshSessionProof -NotePropertyValue $true
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'workflow-extra-field' `
      -Expected 'exact 23-field schema changed' -Action {
        Invoke-C34LBlockerBrowserValidation @persistedParameters `
          -ValidationPhase preupload
      }
    [void]$aggregate.presealUploadWorkflow.PSObject.Properties.Remove(
      'freshSessionProof'
    )
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile

    $postAuthorityProof = Copy-C34LBlockerBrowserObject $proof
    $postAuthorityProof.releaseAuthorities.uploadAndInternalActivation =
      'available_once'
    Write-C34LBlockerBrowserJson $postAuthorityProof $proofFile
    $postAuthorityHash = Get-C34LBlockerBrowserSha256 $proofFile
    $postAuthorityBytes = (Get-Item -LiteralPath $proofFile).Length
    foreach ($owner in @($state, $aggregate)) {
      $owner.presealUploadWorkflow.browserEvidenceSha256 = $postAuthorityHash
      $owner.presealUploadWorkflow.browserEvidenceBytes = $postAuthorityBytes
      $owner.lifecycleTransactionProofs[-1].browserEvidence.browserEvidenceSha256 =
        $postAuthorityHash
      $owner.lifecycleTransactionProofs[-1].browserEvidence.browserEvidenceBytes =
        $postAuthorityBytes
    }
    Write-C34LBlockerBrowserJson $state $stateFile
    Write-C34LBlockerBrowserJson $aggregate $aggregateFile
    $journalFile = Join-Path (
      Join-Path $fixtureRoot 'release-transaction-journals'
    ) 'transaction-browser-fixture.json'
    $journal = Get-Content -Raw -LiteralPath $journalFile | ConvertFrom-Json
    $journal.browserEvidence.browserEvidenceSha256 = $postAuthorityHash
    $journal.browserEvidence.browserEvidenceBytes = $postAuthorityBytes
    $journal.browserEvidence.browserEvidenceProducedUtc =
      [string]$proof.producedUtc
    $journal.browserEvidence.browserEvidenceExpiresUtc =
      [string]$proof.expiresUtc
    Write-C34LBlockerBrowserJson $journal $journalFile
    $postAuthorityParameters = $persistedParameters.Clone()
    $postAuthorityParameters.ValidationBrowserProofSha256 = $postAuthorityHash
    $postAuthorityParameters.ValidationBrowserProofBytes = $postAuthorityBytes
    Invoke-C34LBlockerBrowserExpectedRejection -Name 'post-authority-substitution' `
      -Expected 'browser proof release authority changed at uploadAndInternalActivation' `
      -Action {
        Invoke-C34LBlockerBrowserValidation @postAuthorityParameters `
          -ValidationPhase preupload
      }

    Invoke-C34LBlockerBrowserExpectedRejection -Name 'replayed-session' `
      -Expected 'browser proof session was already consumed or replayed' -Action {
        Invoke-C34LBlockerBrowserValidation @common `
          -ValidationPhase preupload
      }

    Assert-C34LBlockerBrowser -Condition (
      [bool]$sourceResult -and [bool]$preuploadResult.browserProofValidated -and
      [bool]$persistedResult.persistedBindingValidated
    ) -Message 'positive source or preupload fixture did not complete.'
    Write-Output (
      'C34L blocker/browser integration fixtures passed: positive=3; ' +
      'negative=29; stale=1; missing=1; wrongRoute=1; wrongPhase=1; ' +
      'wrongTransition=1; wrongHash=1; wrongBytes=1; wrongAttempt=1; ' +
      'wrongProducer=1; wrongNonce=1; staleSession=1; malformedUtc=1; ' +
      'nonUtc=1; extraPrecisionUtc=1; futureIssued=1; rawNonce=1; ' +
      'sealedLedger=1; ledgerAlias=1; duplicateOwner=1; fixtureEscape=1; ' +
      'proofSchemaExtra=1; sanitizedPath=1; queryPresent=1; ' +
      'sourceBindingTamper=1; mirrorMismatch=2; workflowSchemaExtra=1; ' +
      'replayedSession=1; postAuthoritySubstitution=1; ' +
      'browserLaunches=0; providerActions=0; releaseActions=0; ' +
      'privateValuesObserved=false.'
    )
  } finally {
    foreach ($cleanupRoot in @($fixtureRoot, $siblingFixtureRoot)) {
      if (-not (Test-Path -LiteralPath $cleanupRoot -PathType Container)) {
        continue
      }
      $resolvedFixtureRoot = [IO.Path]::GetFullPath($cleanupRoot)
      $expectedFixturePrefix = [IO.Path]::GetFullPath(
        (Join-Path $root $fixturePrefixRelative)
      )
      Assert-C34LBlockerBrowser -Condition (
        $resolvedFixtureRoot.StartsWith(
          $expectedFixturePrefix,
          [StringComparison]::OrdinalIgnoreCase
        )
      ) -Message 'fixture cleanup escaped the exact C34L prefix.'
      Remove-Item -LiteralPath $resolvedFixtureRoot -Recurse -Force
    }
  }
}

if ($RunSelfTest) {
  Invoke-C34LBlockerBrowserSelfTest
  exit 0
}

$result = Invoke-C34LBlockerBrowserValidation `
  -ValidationPhase $Phase `
  -ValidationStatePath $StatePath `
  -ValidationSourceManifestPath $SourceManifestPath `
  -ValidationSourceManifestSha256 $SourceManifestSha256 `
  -ValidationSourceManifestBytes $SourceManifestBytes `
  -ValidationBlockerLedgerPath $BlockerLedgerPath `
  -ValidationBlockerLedgerSha256 $BlockerLedgerSha256 `
  -ValidationBlockerLedgerBytes $BlockerLedgerBytes `
  -ValidationBrowserProofPath $BrowserProofPath `
  -ValidationBrowserProofSha256 $BrowserProofSha256 `
  -ValidationBrowserProofBytes $BrowserProofBytes `
  -ValidationAttempt $Attempt `
  -ValidationRequirePersistedBrowserBinding `
    ([bool]$RequirePersistedBrowserBinding) `
  -ValidationFixtureMode ([bool]$FixtureMode)
Write-Output (
  "C34L blocker/browser integration passed: phase=$($result.phase); " +
  "manifestOwners=$($result.manifestOwners); " +
  "browserProofValidated=$($result.browserProofValidated); " +
  'browserLaunches=0; providerActions=0; releaseActions=0; ' +
  'privateValuesObserved=false.'
)
