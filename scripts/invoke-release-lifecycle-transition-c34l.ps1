[CmdletBinding()]
param(
  [ValidateSet(
    'founder-inputs-validated', 'prebuild-failed', 'build-start',
    'build-failed', 'build-succeeded', 'upload-authorized',
    'upload-succeeded', 'install-authorized', 'install-succeeded',
    'device-accepted', 'reject'
  )]
  [string]$Transition,
  [Parameter(Mandatory)][string]$StatePath,
  [string]$PrerequisiteGateEvidencePath,
  [string]$PrerequisiteGateEvidenceSha256,
  [ValidateSet(
    'preprompt', 'prebuild', 'build', 'postbuild', 'preupload',
    'postupload', 'preinstall', 'postinstall', 'journey', 'rejection'
  )]
  [string]$PrerequisiteGatePhase,
  [string]$BrowserEvidencePath,
  [string]$BrowserEvidenceSha256,
  [long]$BrowserEvidenceBytes,
  [string]$BrowserSessionId,
  [string]$BrowserSessionNonceSha256,
  [string]$BrowserEvidenceProducerId,
  [string]$BrowserEvidenceProducedUtc,
  [string]$BrowserEvidenceExpiresUtc,
  [string]$SourceManifestPath,
  [string]$SourceManifestSha256,
  [long]$SourceManifestBytes,
  [string]$BlockerLedgerPath,
  [string]$BlockerLedgerSha256,
  [long]$BlockerLedgerBytes,
  [switch]$LiveBrowserRouteQualified,
  [switch]$SignedInMoolSocialAppRouteProved,
  [switch]$InternalTestingRouteProved,
  [switch]$NoPlayWritePerformed,
  [string]$ArtifactPath,
  [string]$ArtifactSha256,
  [long]$ArtifactBytes,
  [string]$UploadSignerSha256,
  [string]$ArtifactProvenance,
  [string]$EvidencePath,
  [string]$EvidenceSha256,
  [long]$EvidenceBytes,
  [string]$RetainedDataEvidencePath,
  [string]$RetainedDataEvidenceSha256,
  [long]$RetainedDataEvidenceBytes,
  [ValidateRange(1, 5)]
  [int]$Attempt = 1,
  [ValidatePattern('^[a-z0-9][a-z0-9_-]*$')][string]$FailureStage,
  [string]$RejectionMachineState,
  [string]$RejectionRegistryId,
  [switch]$FixtureMode,
  [switch]$ReconcileOnly,
  [ValidateSet(
    'none', 'before-journal-write', 'after-journal-write',
    'after-detailed-replace', 'after-aggregate-replace',
    'after-journal-commit'
  )]
  [string]$InjectCrashBoundary = 'none',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$fixtureFamilyRoot = [IO.Path]::GetFullPath(
  (Join-Path $root 'tmp/c34l-release-transaction-fixtures')
).TrimEnd([char[]]@('\', '/'))
$fixtureFamilyPrefix = $fixtureFamilyRoot + [IO.Path]::DirectorySeparatorChar
$script:fixtureStateRunRoot = $null
$ticketId =
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE'
$versionName = '1.0.0-r60.76'
$versionCode = '2026081376'
$realStateRelative = 'config/successor-aab-regression-hard-gate-state-c34l.json'
$contractId = 'MOOLSOCIAL-C34L-R60-76-RELEASE-LIFECYCLE-TRANSACTION-JOURNAL-001'
$browserContractId = 'MOOLSOCIAL-C34L-R60-76-PREUPLOAD-BROWSER-ROUTE-PROOF-001'
$browserProducerId = 'MOOLSOCIAL-C34L-BROWSER-QUALIFICATION-PRODUCER-001'
$browserMaximumMinutes = 15
$browserClockSkewSeconds = 30
$utcTimestampFormat = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'"
$packageName = 'com.moolsocial.app'
$productionEvidenceRoot =
  'artifacts/quality/uaw-c34l-r60-76-consolidated-release-transaction-evidence-preparation-20260817-01'
$sourceAttestationContractId = 'MOOLSOCIAL-C34L-SOURCE-ATTESTATION-001'
$captureManifestContractId = 'MOOLSOCIAL-C34L-SANITIZED-CAPTURE-MANIFEST-001'
$captureArtifactContractPath =
  'config/release-evidence-capture-artifact-contract-c34l.json'
$captureArtifactContractSha256 =
  'D7B8DE822D709F25CEB1AEFFFF4093260B3EFB83DCADE1F632309026ECC0B9D2'
$captureArtifactContractId = 'MOOLSOCIAL-C34L-CAPTURE-ARTIFACT-CONTRACT-003'
$deviceBindingSha256 =
  '97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF'
$evidenceCountNames = @(
  'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
  'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
)
$evidenceAuthorityNames = @(
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
$browserInvocationParameterNames = @(
  'BrowserEvidencePath', 'BrowserEvidenceSha256', 'BrowserEvidenceBytes',
  'BrowserSessionId', 'BrowserSessionNonceSha256', 'BrowserEvidenceProducerId',
  'BrowserEvidenceProducedUtc', 'BrowserEvidenceExpiresUtc',
  'SourceManifestPath', 'SourceManifestSha256', 'SourceManifestBytes',
  'BlockerLedgerPath', 'BlockerLedgerSha256', 'BlockerLedgerBytes',
  'LiveBrowserRouteQualified', 'SignedInMoolSocialAppRouteProved',
  'InternalTestingRouteProved', 'NoPlayWritePerformed'
)
$utf8 = [Text.UTF8Encoding]::new($false)

function Assert-C34LTransition {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C34L lifecycle transaction rejected: $Message" }
}

function Resolve-C34LRelativePath {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label,
    [switch]$AllowMissing
  )
  Assert-C34LTransition -Condition (
    -not [string]::IsNullOrWhiteSpace($Path) -and
    -not [IO.Path]::IsPathRooted($Path) -and
    -not $Path.Contains('\') -and -not $Path.Contains('?') -and
    -not $Path.Contains('#')
  ) -Message "$Label must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C34LTransition -Condition (
    $resolved.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the production repository."
  $current = if (Test-Path -LiteralPath $resolved) {
    $resolved
  } else {
    [IO.Path]::GetFullPath((Split-Path -Parent $resolved))
  }
  while ($true) {
    Assert-C34LTransition -Condition (
      $current.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
      $current.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    ) -Message "$Label ancestor escaped the production repository."
    Assert-C34LTransition -Condition (Test-Path -LiteralPath $current) `
      -Message "$Label ancestor is missing."
    Assert-C34LTransition -Condition (
      -not ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint)
    ) -Message "$Label contains a reparse-point ancestor."
    if ($current.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { break }
    $current = [IO.Path]::GetFullPath((Split-Path -Parent $current))
  }
  if (-not $AllowMissing) {
    Assert-C34LTransition -Condition (
      Test-Path -LiteralPath $resolved -PathType Leaf
    ) -Message "$Label is missing."
  }
  return $resolved
}

function ConvertTo-C34LRepositoryRelativePath {
  param([Parameter(Mandatory)][string]$Resolved, [Parameter(Mandatory)][string]$Label)
  $full = [IO.Path]::GetFullPath($Resolved)
  Assert-C34LTransition -Condition (
    $full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the production repository."
  return $full.Substring($rootPrefix.Length).Replace('\', '/')
}

function Assert-C34LFixturePath {
  param([Parameter(Mandatory)][string]$Resolved, [Parameter(Mandatory)][string]$Label)
  Assert-C34LTransition -Condition (
    -not [string]::IsNullOrWhiteSpace([string]$script:fixtureStateRunRoot)
  ) -Message 'exact fixture state run root is not initialized.'
  $full = [IO.Path]::GetFullPath($Resolved)
  $exactRunPrefix = $script:fixtureStateRunRoot +
    [IO.Path]::DirectorySeparatorChar
  Assert-C34LTransition -Condition (
    $full.StartsWith($exactRunPrefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label is outside the exact resolved fixture state run root."
}

function Initialize-C34LFixtureStateRunRoot {
  param([Parameter(Mandatory)][string]$StateFile)
  $stateParent = [IO.Path]::GetFullPath((Split-Path -Parent $StateFile)).TrimEnd(
    [char[]]@('\', '/')
  )
  Assert-C34LTransition -Condition (
    $stateParent.StartsWith(
      $fixtureFamilyPrefix,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    -not $stateParent.Equals(
      $fixtureFamilyRoot,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message 'fixture detailed state is outside the C34L fixture family.'
  $script:fixtureStateRunRoot = $stateParent
  Assert-C34LFixturePath $StateFile 'fixture detailed state'
}

function Assert-C34LProofConfinement {
  param(
    [Parameter(Mandatory)][string]$Resolved,
    [Parameter(Mandatory)][object]$PreState,
    [Parameter(Mandatory)][string]$Label
  )
  if ($FixtureMode) {
    Assert-C34LFixturePath $Resolved "fixture $Label"
    return
  }
  Assert-C34LTransition -Condition (
    -not [string]::IsNullOrWhiteSpace([string]$PreState.evidenceRoot) -and
    [string]$PreState.evidenceRoot -cmatch
      '^artifacts/quality/uaw-c34l-r60-76-consolidated-release-transaction-evidence-[a-z0-9-]+$'
  ) -Message 'real prerequisite proof evidence root changed.'
  $proofRoot = [IO.Path]::GetFullPath(
    (Join-Path $root ([string]$PreState.evidenceRoot))
  ).TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
  Assert-C34LTransition -Condition (
    $Resolved.StartsWith($proofRoot, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label is outside the exact retained C34L evidence root."
}

function ConvertTo-C34LCanonicalUtcTimestamp {
  param(
    [Parameter(Mandatory)][object]$Value,
    [Parameter(Mandatory)][string]$Label
  )
  $parsed = [DateTimeOffset]::MinValue
  if ($Value -is [DateTimeOffset]) {
    $parsed = ([DateTimeOffset]$Value).ToUniversalTime()
  } elseif ($Value -is [DateTime]) {
    $parsed = [DateTimeOffset]::new(([DateTime]$Value).ToUniversalTime())
  } elseif ($Value -is [string]) {
    $styles = [Globalization.DateTimeStyles]::AssumeUniversal -bor
      [Globalization.DateTimeStyles]::AdjustToUniversal
    Assert-C34LTransition -Condition (
      [DateTimeOffset]::TryParseExact(
        [string]$Value,
        $utcTimestampFormat,
        [Globalization.CultureInfo]::InvariantCulture,
        $styles,
        [ref]$parsed
      ) -and $parsed.Offset -eq [TimeSpan]::Zero
    ) -Message "$Label is not an exact UTC timestamp."
  } else {
    Assert-C34LTransition -Condition $false `
      -Message "$Label has an unsupported decoded JSON type."
  }
  return $parsed.ToUniversalTime().ToString(
    $utcTimestampFormat,
    [Globalization.CultureInfo]::InvariantCulture
  )
}

function ConvertTo-C34LUtcInstant {
  param(
    [Parameter(Mandatory)][object]$Value,
    [Parameter(Mandatory)][string]$Label
  )
  $canonical = ConvertTo-C34LCanonicalUtcTimestamp $Value $Label
  return [DateTimeOffset]::ParseExact(
    $canonical,
    $utcTimestampFormat,
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal -bor
      [Globalization.DateTimeStyles]::AdjustToUniversal
  )
}

function Assert-C34LRawJsonUtcToken {
  param(
    [Parameter(Mandatory)][string]$Json,
    [Parameter(Mandatory)][string]$PropertyName,
    [Parameter(Mandatory)][string]$Expected,
    [Parameter(Mandatory)][string]$Label
  )
  $pattern = '"' + [regex]::Escape($PropertyName) +
    '"\s*:\s*"(?<value>[^"\\]*)"'
  $matches = [regex]::Matches($Json, $pattern)
  Assert-C34LTransition -Condition (
    $matches.Count -eq 1 -and
    [string]$matches[0].Groups['value'].Value -ceq $Expected
  ) -Message "$Label raw JSON wire token changed."
}

function ConvertTo-C34LNormalizedBrowserBinding {
  param(
    [Parameter(Mandatory)][object]$Binding,
    [Parameter(Mandatory)][string]$Label
  )
  $normalized = ($Binding | ConvertTo-Json -Depth 20) | ConvertFrom-Json
  $normalized.browserEvidenceProducedUtc = ConvertTo-C34LCanonicalUtcTimestamp `
    $Binding.browserEvidenceProducedUtc "$Label producedUtc"
  $normalized.browserEvidenceExpiresUtc = ConvertTo-C34LCanonicalUtcTimestamp `
    $Binding.browserEvidenceExpiresUtc "$Label expiresUtc"
  return $normalized
}

function Read-C34LValidatedBrowserEvidence {
  param(
    [Parameter(Mandatory)][object]$Binding,
    [Parameter(Mandatory)][int]$ExpectedAttempt,
    [Parameter(Mandatory)][string]$ExpectedStateSha256,
    [Parameter(Mandatory)][string]$ExpectedAggregateSha256,
    [Parameter(Mandatory)][object]$PreState,
    [Parameter(Mandatory)][object]$PreAggregate,
    [Parameter(Mandatory)][DateTimeOffset]$ValidationInstantUtc
  )
  $bindingNames = @(
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
  $actualNames = @($Binding.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LTransition -Condition (
    (@($actualNames | Sort-Object) -join ',') -ceq
      (@($bindingNames | Sort-Object) -join ',')
  ) -Message 'browser prerequisite binding schema changed.'
  Assert-C34LTransition -Condition (
    [int]$Binding.browserEvidenceAttempt -eq $ExpectedAttempt -and
    [string]$Binding.browserEvidenceTransition -ceq 'upload-authorized' -and
    [string]$Binding.browserEvidencePhase -ceq 'preupload' -and
    [string]$Binding.browserEvidencePreStateSha256 -ceq $ExpectedStateSha256 -and
    [string]$Binding.browserEvidencePreAggregateSha256 -ceq
      $ExpectedAggregateSha256 -and
    [string]$Binding.browserSessionNonceSha256 -cmatch '^[0-9A-F]{64}$' -and
    [string]$Binding.browserSessionId -ceq (
      'c34l-browser-session-' +
        [string]$Binding.browserSessionNonceSha256.Substring(0, 16)
    ) -and
    [string]$Binding.browserEvidenceProducerId -ceq $browserProducerId -and
    [bool]$Binding.liveBrowserRouteQualified -and
    [bool]$Binding.signedInMoolSocialAppRouteProved -and
    [bool]$Binding.internalTestingRouteProved -and
    [bool]$Binding.noPlayWritePerformed
  ) -Message 'browser prerequisite tuple, preimage, session, producer or routes changed.'
  $producedCanonical = ConvertTo-C34LCanonicalUtcTimestamp `
    $Binding.browserEvidenceProducedUtc 'browser producedUtc'
  $expiresCanonical = ConvertTo-C34LCanonicalUtcTimestamp `
    $Binding.browserEvidenceExpiresUtc 'browser expiresUtc'
  $produced = ConvertTo-C34LUtcInstant $producedCanonical 'browser producedUtc'
  $expires = ConvertTo-C34LUtcInstant $expiresCanonical 'browser expiresUtc'
  Assert-C34LTransition -Condition (
    $expires -gt $produced -and
    $expires -le $produced.AddMinutes($browserMaximumMinutes) -and
    $produced -le $ValidationInstantUtc.AddSeconds($browserClockSkewSeconds) -and
    $expires -ge $ValidationInstantUtc
  ) -Message 'browser session was not current at transaction preparation.'
  $browserFile = Resolve-C34LRelativePath `
    ([string]$Binding.browserEvidencePath) 'browser evidence'
  Assert-C34LProofConfinement $browserFile $PreState 'browser evidence'
  Assert-C34LTransition -Condition (
    [string]$Binding.browserEvidenceSha256 -cmatch '^[0-9A-F]{64}$' -and
    [long]$Binding.browserEvidenceBytes -gt 0 -and
    (Get-C34LFileSha256 $browserFile) -ceq
      [string]$Binding.browserEvidenceSha256 -and
    (Get-Item -LiteralPath $browserFile).Length -eq
      [long]$Binding.browserEvidenceBytes
  ) -Message 'browser evidence SHA-256 or byte length changed.'
  $sourceManifestFile = Resolve-C34LRelativePath `
    ([string]$Binding.sourceManifestPath) 'browser source manifest'
  $blockerLedgerFile = Resolve-C34LRelativePath `
    ([string]$Binding.blockerLedgerPath) 'browser blocker ledger'
  if ($FixtureMode) {
    Assert-C34LFixturePath $sourceManifestFile 'fixture browser source manifest'
    Assert-C34LFixturePath $blockerLedgerFile 'fixture browser blocker ledger'
  } else {
    Assert-C34LTransition -Condition (
      [string]$PreState.sourceQualification.manifestPath -ceq
        [string]$Binding.sourceManifestPath -and
      [string]$PreState.sourceQualification.manifestSha256 -ceq
        [string]$Binding.sourceManifestSha256 -and
      [long]$PreState.sourceQualification.manifestBytes -eq
        [long]$Binding.sourceManifestBytes -and
      [string]$PreState.sourcePrerequisites.blockerLedgerPath -ceq
        [string]$Binding.blockerLedgerPath -and
      [string]$PreState.sourcePrerequisites.blockerLedgerPrebuildSha256 -ceq
        [string]$Binding.blockerLedgerSha256
    ) -Message 'browser source manifest or blocker ledger state owner changed.'
  }
  Assert-C34LTransition -Condition (
    [string]$Binding.sourceManifestSha256 -cmatch '^[0-9A-F]{64}$' -and
    [long]$Binding.sourceManifestBytes -gt 0 -and
    (Get-C34LFileSha256 $sourceManifestFile) -ceq
      [string]$Binding.sourceManifestSha256 -and
    (Get-Item -LiteralPath $sourceManifestFile).Length -eq
      [long]$Binding.sourceManifestBytes -and
    [string]$Binding.blockerLedgerSha256 -cmatch '^[0-9A-F]{64}$' -and
    [long]$Binding.blockerLedgerBytes -gt 0 -and
    (Get-C34LFileSha256 $blockerLedgerFile) -ceq
      [string]$Binding.blockerLedgerSha256 -and
    (Get-Item -LiteralPath $blockerLedgerFile).Length -eq
      [long]$Binding.blockerLedgerBytes
  ) -Message 'browser source manifest or blocker ledger SHA-256/bytes changed.'
  $browserText = Get-Content -Raw -LiteralPath $browserFile
  $browser = $browserText | ConvertFrom-Json
  $browserPropertyNames = @(
    'schemaVersion', 'contractId', 'ticketId', 'attempt', 'versionName',
    'versionCode', 'transition', 'phase', 'stateSha256', 'aggregateSha256',
    'sourceManifest', 'blockerLedger',
    'sessionId', 'sessionNonceSha256', 'producerId', 'producedUtc',
    'expiresUtc', 'routes', 'actionCounts', 'releaseAuthorities',
    'copiedFromPriorCandidate', 'noPlayWritePerformed',
    'uploadActionCount', 'activationActionCount', 'otherTrackActionCount',
    'privateValuesObserved'
  )
  $actualBrowserPropertyNames = @(
    $browser.PSObject.Properties | ForEach-Object { $_.Name }
  )
  Assert-C34LTransition -Condition (
    (@($actualBrowserPropertyNames | Sort-Object) -join ',') -ceq
      (@($browserPropertyNames | Sort-Object) -join ',')
  ) -Message 'browser evidence exact top-level schema changed.'
  foreach ($name in $browserPropertyNames) {
    Assert-C34LTransition -Condition ($null -ne $browser.PSObject.Properties[$name]) `
      -Message "browser evidence is missing $name."
  }
  $sourceManifestPropertyNames = @('path', 'sha256', 'bytes')
  $blockerLedgerPropertyNames = @(
    'path', 'sha256', 'bytes', 'mutableOutsideSourceSeal'
  )
  $routePropertyNames = @(
    'liveBrowserRouteQualified', 'signedInMoolSocialAppRouteProved',
    'internalTestingRouteProved', 'sanitizedHost', 'sanitizedPath',
    'queryPresent', 'fragmentPresent'
  )
  Assert-C34LTransition -Condition (
    (@($browser.sourceManifest.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($sourceManifestPropertyNames | Sort-Object) -join ',') -and
    (@($browser.blockerLedger.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($blockerLedgerPropertyNames | Sort-Object) -join ',') -and
    (@($browser.routes.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($routePropertyNames | Sort-Object) -join ',')
  ) -Message 'browser source manifest, blocker ledger or route schema changed.'
  Assert-C34LTransition -Condition (
    [int]$browser.schemaVersion -eq 1 -and
    [string]$browser.contractId -ceq $browserContractId -and
    [string]$browser.ticketId -ceq $ticketId -and
    [int]$browser.attempt -eq $ExpectedAttempt -and
    [string]$browser.versionName -ceq $versionName -and
    [string]$browser.versionCode -ceq $versionCode -and
    [string]$browser.transition -ceq 'upload-authorized' -and
    [string]$browser.phase -ceq 'preupload' -and
    [string]$browser.stateSha256 -ceq $ExpectedStateSha256 -and
    [string]$browser.aggregateSha256 -ceq $ExpectedAggregateSha256 -and
    [string]$browser.sourceManifest.path -ceq
      [string]$Binding.sourceManifestPath -and
    [string]$browser.sourceManifest.sha256 -ceq
      [string]$Binding.sourceManifestSha256 -and
    [long]$browser.sourceManifest.bytes -eq
      [long]$Binding.sourceManifestBytes -and
    [string]$browser.blockerLedger.path -ceq
      [string]$Binding.blockerLedgerPath -and
    [string]$browser.blockerLedger.sha256 -ceq
      [string]$Binding.blockerLedgerSha256 -and
    [long]$browser.blockerLedger.bytes -eq
      [long]$Binding.blockerLedgerBytes -and
    [bool]$browser.blockerLedger.mutableOutsideSourceSeal -and
    [string]$browser.sessionId -ceq [string]$Binding.browserSessionId -and
    [string]$browser.sessionNonceSha256 -ceq
      [string]$Binding.browserSessionNonceSha256 -and
    [string]$browser.producerId -ceq [string]$Binding.browserEvidenceProducerId -and
    (ConvertTo-C34LCanonicalUtcTimestamp `
      $browser.producedUtc 'retained browser producedUtc') -ceq $producedCanonical -and
    (ConvertTo-C34LCanonicalUtcTimestamp `
      $browser.expiresUtc 'retained browser expiresUtc') -ceq $expiresCanonical
  ) -Message 'browser evidence candidate, tuple, preimage or session identity changed.'
  Assert-C34LRawJsonUtcToken $browserText 'producedUtc' $producedCanonical `
    'retained browser producedUtc'
  Assert-C34LRawJsonUtcToken $browserText 'expiresUtc' $expiresCanonical `
    'retained browser expiresUtc'
  Assert-C34LTransition -Condition (
    [bool]$browser.routes.liveBrowserRouteQualified -and
    [bool]$browser.routes.signedInMoolSocialAppRouteProved -and
    [bool]$browser.routes.internalTestingRouteProved -and
    [string]$browser.routes.sanitizedHost -ceq 'play.google.com' -and
    [string]$browser.routes.sanitizedPath -ceq
      '/console/app/internal-testing' -and
    -not [bool]$browser.routes.queryPresent -and
    -not [bool]$browser.routes.fragmentPresent -and
    -not [bool]$browser.copiedFromPriorCandidate -and
    [bool]$browser.noPlayWritePerformed -and
    [int]$browser.uploadActionCount -eq 0 -and
    [int]$browser.activationActionCount -eq 0 -and
    [int]$browser.otherTrackActionCount -eq 0 -and
    -not [bool]$browser.privateValuesObserved
  ) -Message 'browser evidence route, freshness, no-write or privacy truth changed.'
  $expectedCountNames = @(
    'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
    'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
  )
  $expectedAuthorityNames = @(
    'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  )
  Assert-C34LTransition -Condition (
    (@($browser.actionCounts.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($expectedCountNames | Sort-Object) -join ',') -and
    (@($browser.releaseAuthorities.PSObject.Properties.Name | Sort-Object) -join ',') -ceq
      (@($expectedAuthorityNames | Sort-Object) -join ',')
  ) -Message 'browser action-count or release-authority schema changed.'
  foreach ($name in @(
    'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
    'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
  )) {
    Assert-C34LTransition -Condition (
      $null -ne $browser.actionCounts.PSObject.Properties[$name] -and
      [int]$browser.actionCounts.$name -eq [int]$PreState.actionCounts.$name -and
      [int]$browser.actionCounts.$name -eq [int]$PreAggregate.actionCounts.$name
    ) -Message "browser evidence action count changed at $name."
  }
  foreach ($name in @(
    'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  )) {
    Assert-C34LTransition -Condition (
      $null -ne $browser.releaseAuthorities.PSObject.Properties[$name] -and
      [string]$browser.releaseAuthorities.$name -ceq
        [string]$PreState.releaseAuthorities.$name -and
      [string]$browser.releaseAuthorities.$name -ceq
        [string]$PreAggregate.releaseAuthorities.$name
    ) -Message "browser evidence release authority changed at $name."
  }
  return ConvertTo-C34LNormalizedBrowserBinding $Binding 'browser binding'
}

function Read-C34LValidatedPrerequisiteProof {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Sha256,
    [Parameter(Mandatory)][int]$ExpectedAttempt,
    [Parameter(Mandatory)][string]$ExpectedTransition,
    [Parameter(Mandatory)][string]$ExpectedPhase,
    [Parameter(Mandatory)][string]$ExpectedStateSha256,
    [Parameter(Mandatory)][string]$ExpectedAggregateSha256,
    [Parameter(Mandatory)][object]$PreState,
    [Parameter(Mandatory)][object]$PreAggregate,
    [Parameter(Mandatory)][DateTimeOffset]$ValidationInstantUtc
  )
  $resolved = Resolve-C34LRelativePath $Path 'prerequisite gate proof'
  Assert-C34LProofConfinement $resolved $PreState 'prerequisite gate proof'
  Assert-C34LTransition -Condition (
    $Sha256 -cmatch '^[0-9A-F]{64}$' -and
    (Get-C34LFileSha256 $resolved) -ceq $Sha256
  ) -Message 'prerequisite gate proof hash is missing or changed.'
  $proofText = Get-Content -Raw -LiteralPath $resolved
  $proofValue = $proofText | ConvertFrom-Json
  foreach ($name in @(
    'ticketId', 'attempt', 'versionName', 'versionCode', 'transition', 'phase',
    'passed', 'stateSha256', 'aggregateSha256', 'actionCounts',
    'releaseAuthorities'
  )) {
    Assert-C34LTransition -Condition ($null -ne $proofValue.PSObject.Properties[$name]) `
      -Message "prerequisite gate proof is missing $name."
  }
  Assert-C34LTransition -Condition (
    [string]$proofValue.ticketId -ceq $ticketId -and
    [int]$proofValue.attempt -eq $ExpectedAttempt -and
    [string]$proofValue.versionName -ceq $versionName -and
    [string]$proofValue.versionCode -ceq $versionCode -and
    [string]$proofValue.transition -ceq $ExpectedTransition -and
    [string]$proofValue.phase -ceq $ExpectedPhase -and
    [bool]$proofValue.passed -and
    [string]$proofValue.stateSha256 -ceq $ExpectedStateSha256 -and
    [string]$proofValue.aggregateSha256 -ceq $ExpectedAggregateSha256
  ) -Message 'prerequisite proof ticket, attempt, phase, transition, pass or preimage changed.'
  foreach ($name in @(
    'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
    'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
  )) {
    Assert-C34LTransition -Condition (
      $null -ne $proofValue.actionCounts.PSObject.Properties[$name] -and
      [int]$proofValue.actionCounts.$name -eq [int]$PreState.actionCounts.$name -and
      [int]$proofValue.actionCounts.$name -eq [int]$PreAggregate.actionCounts.$name
    ) -Message "prerequisite proof action count changed at $name."
  }
  foreach ($name in @(
    'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  )) {
    Assert-C34LTransition -Condition (
      $null -ne $proofValue.releaseAuthorities.PSObject.Properties[$name] -and
      [string]$proofValue.releaseAuthorities.$name -ceq
        [string]$PreState.releaseAuthorities.$name -and
      [string]$proofValue.releaseAuthorities.$name -ceq
        [string]$PreAggregate.releaseAuthorities.$name
    ) -Message "prerequisite proof release authority changed at $name."
  }
  if ($ExpectedTransition -ceq 'upload-authorized') {
    Assert-C34LTransition -Condition (
      $null -ne $proofValue.PSObject.Properties['browserEvidence'] -and
      $null -ne $proofValue.browserEvidence
    ) -Message 'upload-authorized prerequisite proof is missing browser evidence.'
    $normalizedBrowserEvidence = Read-C34LValidatedBrowserEvidence `
      -Binding $proofValue.browserEvidence `
      -ExpectedAttempt $ExpectedAttempt `
      -ExpectedStateSha256 $ExpectedStateSha256 `
      -ExpectedAggregateSha256 $ExpectedAggregateSha256 `
      -PreState $PreState -PreAggregate $PreAggregate `
      -ValidationInstantUtc $ValidationInstantUtc
    Assert-C34LRawJsonUtcToken $proofText 'browserEvidenceProducedUtc' `
      ([string]$normalizedBrowserEvidence.browserEvidenceProducedUtc) `
      'prerequisite browser producedUtc'
    Assert-C34LRawJsonUtcToken $proofText 'browserEvidenceExpiresUtc' `
      ([string]$normalizedBrowserEvidence.browserEvidenceExpiresUtc) `
      'prerequisite browser expiresUtc'
    $proofValue.browserEvidence = $normalizedBrowserEvidence
  } else {
    Assert-C34LTransition -Condition (
      $null -eq $proofValue.PSObject.Properties['browserEvidence']
    ) -Message 'browser evidence is forbidden for this transition.'
  }
  return $proofValue
}

function Get-C34LTextSha256 {
  param([Parameter(Mandatory)][string]$Text)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = $utf8.GetBytes($Text)
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
  } finally { $sha.Dispose() }
}

function Get-C34LFileSha256 {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Write-C34LAtomicText {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Text)
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $parent -Force)
  }
  $temp = $Path + '.tmp-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
  $backup = $Path + '.backup-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
  Assert-C34LTransition -Condition (
    -not (Test-Path -LiteralPath $temp) -and
    -not (Test-Path -LiteralPath $backup)
  ) -Message 'atomic temp or backup path was not unique.'
  try {
    [IO.File]::WriteAllText($temp, $Text, $utf8)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
      [IO.File]::Replace($temp, $Path, $backup, $true)
      Assert-C34LTransition -Condition (
        (Test-Path -LiteralPath $Path -PathType Leaf) -and
        (Test-Path -LiteralPath $backup -PathType Leaf) -and
        -not (Test-Path -LiteralPath $temp)
      ) -Message 'atomic replacement did not retain one confirmed sibling backup.'
      Remove-Item -LiteralPath $backup -Force
      Assert-C34LTransition -Condition (-not (Test-Path -LiteralPath $backup)) `
        -Message 'confirmed atomic replacement backup was not removed.'
    } else {
      [IO.File]::Move($temp, $Path)
      Assert-C34LTransition -Condition (
        (Test-Path -LiteralPath $Path -PathType Leaf) -and
        -not (Test-Path -LiteralPath $temp) -and
        -not (Test-Path -LiteralPath $backup)
      ) -Message 'atomic new-file move did not finish without temp or backup residue.'
    }
  } finally {
    if (Test-Path -LiteralPath $temp -PathType Leaf) {
      Remove-Item -LiteralPath $temp -Force
    }
  }
}

function ConvertTo-C34LJson {
  param([Parameter(Mandatory)][object]$Value)
  return ($Value | ConvertTo-Json -Depth 60) + [Environment]::NewLine
}

function Set-C34LProperty {
  param([Parameter(Mandatory)][object]$Object, [Parameter(Mandatory)][string]$Name, $Value)
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
  } else { $property.Value = $Value }
}

function Get-C34LBrowserWorkflowProjection {
  param([Parameter(Mandatory)][object]$Workflow)
  $names = @(
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
  $actualNames = @($Workflow.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LTransition -Condition (
    (@($actualNames | Sort-Object) -join ',') -ceq
      (@($names | Sort-Object) -join ',')
  ) -Message 'preseal upload workflow exact 23-field schema changed.'
  $projection = [ordered]@{}
  foreach ($name in $names) {
    Assert-C34LTransition -Condition ($null -ne $Workflow.PSObject.Properties[$name]) `
      -Message "preseal upload workflow is missing $name."
    if ($name -in @('browserEvidenceProducedUtc', 'browserEvidenceExpiresUtc') -and
      $null -ne $Workflow.$name) {
      $projection[$name] = ConvertTo-C34LCanonicalUtcTimestamp `
        $Workflow.$name "preseal upload workflow $name"
    } else {
      $projection[$name] = $Workflow.$name
    }
  }
  return [pscustomobject]$projection
}

function Assert-C34LBrowserWorkflowParity {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate
  )
  Assert-C34LTransition -Condition (
    $null -ne $State.PSObject.Properties['presealUploadWorkflow'] -and
    $null -ne $Aggregate.PSObject.Properties['presealUploadWorkflow']
  ) -Message 'preseal upload workflow owner is missing.'
  $stateBrowser = Get-C34LBrowserWorkflowProjection $State.presealUploadWorkflow
  $aggregateBrowser = Get-C34LBrowserWorkflowProjection `
    $Aggregate.presealUploadWorkflow
  Assert-C34LTransition -Condition (
    (ConvertTo-Json -InputObject $stateBrowser -Depth 20 -Compress) -ceq
      (ConvertTo-Json -InputObject $aggregateBrowser -Depth 20 -Compress)
  ) -Message 'detailed and aggregate browser workflow binding changed.'
  return $stateBrowser
}

function Assert-C34LBrowserWorkflowUnbound {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate
  )
  $binding = Assert-C34LBrowserWorkflowParity $State $Aggregate
  Assert-C34LTransition -Condition (
    $null -eq $binding.browserEvidencePath -and
    $null -eq $binding.browserEvidenceSha256 -and
    [long]$binding.browserEvidenceBytes -eq 0 -and
    [int]$binding.browserEvidenceAttempt -eq 0 -and
    $null -eq $binding.browserEvidenceTransition -and
    $null -eq $binding.browserEvidencePhase -and
    $null -eq $binding.browserEvidencePreStateSha256 -and
    $null -eq $binding.browserEvidencePreAggregateSha256 -and
    $null -eq $binding.browserSessionId -and
    $null -eq $binding.browserSessionNonceSha256 -and
    $null -eq $binding.browserEvidenceProducerId -and
    $null -eq $binding.browserEvidenceProducedUtc -and
    $null -eq $binding.browserEvidenceExpiresUtc -and
    $null -eq $binding.sourceManifestPath -and
    $null -eq $binding.sourceManifestSha256 -and
    [long]$binding.sourceManifestBytes -eq 0 -and
    $null -eq $binding.blockerLedgerPath -and
    $null -eq $binding.blockerLedgerSha256 -and
    [long]$binding.blockerLedgerBytes -eq 0 -and
    -not [bool]$binding.liveBrowserRouteQualified -and
    -not [bool]$binding.signedInMoolSocialAppRouteProved -and
    -not [bool]$binding.internalTestingRouteProved -and
    [bool]$binding.noPlayWritePerformed
  ) -Message 'browser workflow was already bound or its defaults changed.'
}

function Set-C34LBrowserWorkflowBinding {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][object]$Binding
  )
  foreach ($target in @($State.presealUploadWorkflow, $Aggregate.presealUploadWorkflow)) {
    foreach ($property in $Binding.PSObject.Properties) {
      Set-C34LProperty $target $property.Name $property.Value
    }
  }
}

function Assert-C34LIdentityAndParity {
  param([Parameter(Mandatory)][object]$State, [Parameter(Mandatory)][object]$Aggregate)
  Assert-C34LEvidencePrivacy $State.candidate 'detailed candidate' 'candidate'
  Assert-C34LEvidencePrivacy $Aggregate.candidate 'aggregate candidate' 'candidate'
  Assert-C34LTransition -Condition (
    $null -ne $State.candidate.PSObject.Properties['deviceBindingSha256']
  ) -Message 'candidate device binding schema changed.'
  Assert-C34LTransition -Condition (
    [string]$State.ticketId -ceq $ticketId -and
    [string]$State.candidate.id -ceq $ticketId -and
    [string]$Aggregate.ticketId -ceq $ticketId -and
    [string]$Aggregate.candidate.id -ceq $ticketId -and
    [string]$State.candidate.versionName -ceq $versionName -and
    [string]$Aggregate.candidate.versionName -ceq $versionName -and
    [string]$State.candidate.versionCode -ceq $versionCode -and
    [string]$Aggregate.candidate.versionCode -ceq $versionCode -and
    [string]$State.candidate.packageName -ceq 'com.moolsocial.app' -and
    [string]$State.candidate.playTrack -ceq 'internal' -and
    [string]$State.candidate.deviceBindingSha256 -ceq $deviceBindingSha256 -and
    [string]$State.candidate.deviceModel -ceq 'CPH2375' -and
    [string]$State.machineState -ceq [string]$Aggregate.machineState -and
    [string]$State.candidate.disposition -ceq [string]$Aggregate.candidate.disposition -and
    [bool]$State.candidate.artifactReusable -eq [bool]$Aggregate.candidate.artifactReusable
  ) -Message 'candidate identity or detailed/aggregate common parity changed.'
  foreach ($name in @(
    'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
    'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
  )) {
    Assert-C34LTransition -Condition (
      [int]$State.actionCounts.$name -eq [int]$Aggregate.actionCounts.$name
    ) -Message "action count parity changed for $name."
  }
  foreach ($name in @(
    'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  )) {
    Assert-C34LTransition -Condition (
      [string]$State.releaseAuthorities.$name -ceq
        [string]$Aggregate.releaseAuthorities.$name
    ) -Message "future authority parity changed for $name."
  }
  Assert-C34LTransition -Condition (
    [int]$Aggregate.candidate.buildCount -eq [int]$State.actionCounts.build -and
    [int]$Aggregate.candidate.uploadCount -eq [int]$State.actionCounts.upload -and
    [int]$Aggregate.candidate.installCount -eq [int]$State.actionCounts.install -and
    [int]$Aggregate.candidate.deviceAcceptanceCount -eq
      [int]$State.actionCounts.deviceAcceptance
  ) -Message 'aggregate candidate counts changed.'
  [void](Assert-C34LBrowserWorkflowParity $State $Aggregate)
}

function Assert-C34LVector {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][int[]]$Counts,
    [Parameter(Mandatory)][string[]]$Authorities,
    [Parameter(Mandatory)][string]$Label
  )
  $countNames = @(
    'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
    'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
  )
  $authorityNames = @(
    'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  )
  Assert-C34LTransition -Condition ($Counts.Count -eq 8 -and $Authorities.Count -eq 4) `
    -Message "$Label vector definition is incomplete."
  for ($index = 0; $index -lt 8; $index++) {
    Assert-C34LTransition -Condition (
      [int]$State.actionCounts.($countNames[$index]) -eq $Counts[$index]
    ) -Message "$Label count vector changed at $($countNames[$index])."
  }
  for ($index = 0; $index -lt 4; $index++) {
    Assert-C34LTransition -Condition (
      [string]$State.releaseAuthorities.($authorityNames[$index]) -ceq
        $Authorities[$index]
    ) -Message "$Label future-authority vector changed at $($authorityNames[$index])."
  }
}

function Assert-C34LPostimageProofHistory {
  param(
    [Parameter(Mandatory)][object]$Journal,
    [Parameter(Mandatory)][object]$StateBefore,
    [Parameter(Mandatory)][object]$AggregateBefore,
    [Parameter(Mandatory)][object]$StateAfter,
    [Parameter(Mandatory)][object]$AggregateAfter,
    [Parameter(Mandatory)][object]$PrerequisiteProof
  )
  $stateBeforeHistory = @()
  if ($null -ne $StateBefore.PSObject.Properties['lifecycleTransactionProofs']) {
    $stateBeforeHistory = @($StateBefore.lifecycleTransactionProofs)
  }
  $aggregateBeforeHistory = @()
  if ($null -ne $AggregateBefore.PSObject.Properties['lifecycleTransactionProofs']) {
    $aggregateBeforeHistory = @($AggregateBefore.lifecycleTransactionProofs)
  }
  $stateAfterHistory = @()
  if ($null -ne $StateAfter.PSObject.Properties['lifecycleTransactionProofs']) {
    $stateAfterHistory = @($StateAfter.lifecycleTransactionProofs)
  }
  $aggregateAfterHistory = @()
  if ($null -ne $AggregateAfter.PSObject.Properties['lifecycleTransactionProofs']) {
    $aggregateAfterHistory = @($AggregateAfter.lifecycleTransactionProofs)
  }
  Assert-C34LTransition -Condition (
    $stateBeforeHistory.Count -eq $aggregateBeforeHistory.Count -and
    (ConvertTo-Json -InputObject $stateBeforeHistory -Depth 60 -Compress) -ceq
      (ConvertTo-Json -InputObject $aggregateBeforeHistory -Depth 60 -Compress) -and
    $stateAfterHistory.Count -eq ($stateBeforeHistory.Count + 1) -and
    $aggregateAfterHistory.Count -eq ($aggregateBeforeHistory.Count + 1) -and
    $stateAfterHistory.Count -eq $aggregateAfterHistory.Count -and
    (ConvertTo-Json -InputObject $stateAfterHistory -Depth 60 -Compress) -ceq
      (ConvertTo-Json -InputObject $aggregateAfterHistory -Depth 60 -Compress)
  ) -Message 'postimage lifecycle proof histories are not identical one-record appends.'
  $newest = $stateAfterHistory[-1]
  $proofNames = @(
    'ticketId', 'attempt', 'transition', 'phase', 'evidencePath', 'sha256',
    'preStateSha256', 'preAggregateSha256', 'actionCounts', 'releaseAuthorities',
    'browserEvidence'
  )
  Assert-C34LExactNames $newest $proofNames 'newest lifecycle proof record'
  $expectedProofEvidencePath = [string]$Journal.prerequisiteGateEvidencePath
  $expectedProofEvidenceSha256 = [string]$Journal.prerequisiteGateEvidenceSha256
  switch ([string]$Journal.transition) {
    'upload-succeeded' {
      $expectedProofEvidencePath = [string]$StateAfter.playResult.evidencePath
      $expectedProofEvidenceSha256 = [string]$StateAfter.playResult.evidenceSha256
    }
    'install-succeeded' {
      $expectedProofEvidencePath =
        [string]$StateAfter.installResult.coldStartEvidencePath
      $expectedProofEvidenceSha256 =
        [string]$StateAfter.installResult.coldStartEvidenceSha256
    }
    'device-accepted' {
      $expectedProofEvidencePath =
        [string]$StateAfter.installResult.journeyEvidencePath
      $expectedProofEvidenceSha256 =
        [string]$StateAfter.installResult.journeyEvidenceSha256
    }
  }
  Assert-C34LTransition -Condition (
    [string]$newest.ticketId -ceq $ticketId -and
    [int]$newest.attempt -eq [int]$Journal.attempt -and
    [string]$newest.transition -ceq [string]$Journal.transition -and
    [string]$newest.phase -ceq [string]$Journal.prerequisiteGatePhase -and
    [string]$newest.evidencePath -ceq $expectedProofEvidencePath -and
    [string]$newest.sha256 -ceq $expectedProofEvidenceSha256 -and
    [string]$newest.preStateSha256 -ceq [string]$Journal.stateBeforeSha256 -and
    [string]$newest.preAggregateSha256 -ceq [string]$Journal.aggregateBeforeSha256
  ) -Message 'newest lifecycle proof record does not match the journal tuple.'
  foreach ($name in @(
    'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
    'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
  )) {
    Assert-C34LTransition -Condition (
      [int]$newest.actionCounts.$name -eq [int]$StateBefore.actionCounts.$name -and
      [int]$newest.actionCounts.$name -eq [int]$AggregateBefore.actionCounts.$name
    ) -Message "newest lifecycle proof count changed at $name."
  }
  foreach ($name in @(
    'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  )) {
    Assert-C34LTransition -Condition (
      [string]$newest.releaseAuthorities.$name -ceq
        [string]$StateBefore.releaseAuthorities.$name -and
      [string]$newest.releaseAuthorities.$name -ceq
        [string]$AggregateBefore.releaseAuthorities.$name
    ) -Message "newest lifecycle proof authority changed at $name."
  }
  if ([string]$Journal.transition -ceq 'upload-authorized') {
    $newestBrowser = ConvertTo-C34LNormalizedBrowserBinding `
      $newest.browserEvidence 'lifecycle proof browser evidence'
    $journalBrowser = ConvertTo-C34LNormalizedBrowserBinding `
      $Journal.browserEvidence 'journal browser evidence'
    $prerequisiteBrowser = ConvertTo-C34LNormalizedBrowserBinding `
      $PrerequisiteProof.browserEvidence 'prerequisite browser evidence'
    Assert-C34LTransition -Condition (
      $null -ne $Journal.browserEvidence -and
      $null -ne $newest.browserEvidence -and
      $null -ne $PrerequisiteProof.browserEvidence -and
      (ConvertTo-Json -InputObject $newestBrowser -Depth 20 -Compress) -ceq
        (ConvertTo-Json -InputObject $journalBrowser -Depth 20 -Compress) -and
      (ConvertTo-Json -InputObject $prerequisiteBrowser `
        -Depth 20 -Compress) -ceq
        (ConvertTo-Json -InputObject $journalBrowser -Depth 20 -Compress) -and
      (ConvertTo-Json -InputObject (
        Get-C34LBrowserWorkflowProjection $StateAfter.presealUploadWorkflow
      ) -Depth 20 -Compress) -ceq
        (ConvertTo-Json -InputObject $journalBrowser -Depth 20 -Compress) -and
      (ConvertTo-Json -InputObject (
        Get-C34LBrowserWorkflowProjection $AggregateAfter.presealUploadWorkflow
      ) -Depth 20 -Compress) -ceq
        (ConvertTo-Json -InputObject $journalBrowser -Depth 20 -Compress)
    ) -Message 'browser binding changed across journal, proof history or postimages.'
  } else {
    Assert-C34LTransition -Condition (
      $null -eq $Journal.browserEvidence -and $null -eq $newest.browserEvidence -and
      $null -eq $PrerequisiteProof.PSObject.Properties['browserEvidence']
    ) -Message 'non-browser transition retained browser metadata.'
  }
}

function Assert-C34LExactNames {
  param(
    [Parameter(Mandatory)][object]$Value,
    [Parameter(Mandatory)][string[]]$Names,
    [Parameter(Mandatory)][string]$Label
  )
  $actual = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-C34LTransition -Condition (
    $actual.Count -eq $Names.Count -and
    (@($actual | Sort-Object) -join ',') -ceq (@($Names | Sort-Object) -join ',')
  ) -Message "$Label exact schema changed."
}

function Assert-C34LEvidencePrivacy {
  param(
    $Value,
    [Parameter(Mandatory)][string]$Label,
    [string]$PropertyPath = ''
  )
  if ($Value -is [System.Management.Automation.PSCustomObject]) {
    foreach ($property in @($Value.PSObject.Properties)) {
      $path = if ($PropertyPath) {
        "$PropertyPath.$($property.Name)"
      } else {
        [string]$property.Name
      }
      $forbiddenPropertyName =
        '(?i)(deviceSerial|(^|_)serial($|_)|androidId|imei|imsi|' +
        'advertisingId|email|phone|private|(^|_)url($|_)|link|identifier|' +
        'exception|stack|credential|secret|token|cookie|rawnonce|account)'
      $canonicalPasswordlessCount =
        $path -cmatch '(^|[.])actionCounts[.]passwordlessEmailSend$'
      Assert-C34LTransition -Condition (
        $canonicalPasswordlessCount -or
        -not [regex]::IsMatch([string]$property.Name, $forbiddenPropertyName)
      ) -Message "$Label contains forbidden private property $path."
      Assert-C34LEvidencePrivacy $property.Value $Label $path
    }
    return
  }
  if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
    foreach ($item in @($Value)) {
      Assert-C34LEvidencePrivacy $item $Label $PropertyPath
    }
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
    '(?<![A-Za-z0-9])2b3e0f71(?![A-Za-z0-9])|' +
    '[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com|' +
    '^[A-Za-z0-9_-]{16,}[.][A-Za-z0-9_-]{16,}[.][A-Za-z0-9_-]{16,}$|' +
    '[?&][A-Za-z0-9_.%+-]+=[^\s]*|#[A-Za-z0-9_.%+-]+)'
  Assert-C34LTransition -Condition (-not [regex]::IsMatch($text, $privateShape)) `
    -Message "$Label contains a forbidden private value shape at $PropertyPath."
  $leaf = ($PropertyPath -split '[.]')[-1]
  $approvedSessionId = $false
  if ($leaf -ceq 'sessionId') {
    $approvedSessionPosition =
      $PropertyPath -ceq 'sourceAttestation.sessionId' -or
      ($PropertyPath -ceq 'sessionId' -and (
        $Label.EndsWith(' source attestation',[StringComparison]::Ordinal) -or
        $Label.EndsWith(' capture manifest',[StringComparison]::Ordinal)
      ))
    Assert-C34LTransition -Condition $approvedSessionPosition `
      -Message "$Label sessionId is outside an approved public schema position."
    $approvedSessionId =
      $approvedSessionPosition -and
      $text -cmatch '^[a-z0-9][a-z0-9_-]{15,95}$'
    Assert-C34LTransition -Condition $approvedSessionId `
      -Message "$Label sessionId public grammar changed at $PropertyPath."
  }
  $publicNumericLeaves = @(
    'versionCode','artifactBytes','bytes','captureManifestBytes',
    'firstInstallTimeMillis','lastUpdateTimeMillis','attempt'
  )
  $publicPathLeaves = @(
    'path','artifactPath','captureManifestPath','sourceManifest','provenance',
    'releaseConfigOnly','releaseManifestPreflight','mergedReleaseManifest',
    'releaseManifestMergerBlame','buildLog','bundletoolPath'
  )
  if (-not $approvedSessionId -and $publicNumericLeaves -notcontains $leaf -and
      $leaf -notmatch '(?:Count|Sha256)$' -and
      $leaf -notin @(
        'producedUtc','expiresUtc','preparedUtc','committedUtc','ticketId',
        'branch','builtAt','sourceProducerId','evidencePairId',
        'deviceModel','packageName','versionName','installerPackage'
      ) -and $publicPathLeaves -notcontains $leaf) {
    Assert-C34LTransition -Condition (
      -not [regex]::IsMatch(
        $text,
        '(?<![A-Za-z0-9])(?:[+]?[1-9][0-9]{0,2}[ ().-]*)?(?:[0-9][ ().-]*){7,15}(?![A-Za-z0-9])'
      )
    ) -Message "$Label contains a forbidden phone-shaped value at $PropertyPath."
  }
}

function Assert-C34LEvidenceVector {
  param(
    [Parameter(Mandatory)][object]$Value,
    [Parameter(Mandatory)][int[]]$Counts,
    [Parameter(Mandatory)][string[]]$Authorities,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34LExactNames $Value.actionCounts $evidenceCountNames `
    "$Label actionCounts"
  Assert-C34LExactNames $Value.releaseAuthorities $evidenceAuthorityNames `
    "$Label releaseAuthorities"
  Assert-C34LTransition -Condition (
    $Counts.Count -eq $evidenceCountNames.Count -and
    $Authorities.Count -eq $evidenceAuthorityNames.Count
  ) -Message "$Label expected release vector is incomplete."
  for ($index = 0; $index -lt $evidenceCountNames.Count; $index++) {
    $name = $evidenceCountNames[$index]
    Assert-C34LTransition -Condition (
      [int]$Value.actionCounts.$name -eq $Counts[$index]
    ) -Message "$Label action count changed at $name."
  }
  for ($index = 0; $index -lt $evidenceAuthorityNames.Count; $index++) {
    $name = $evidenceAuthorityNames[$index]
    Assert-C34LTransition -Condition (
      [string]$Value.releaseAuthorities.$name -ceq $Authorities[$index]
    ) -Message "$Label release authority changed at $name."
  }
}

function Get-C34LEvidenceSpec {
  param([ValidateSet('play','oppo','journey')][string]$Kind)
  switch ($Kind) {
    'play' {
      return [pscustomobject]@{
        EvidenceType='play_internal_testing_activation'; Short='play'
        Producer='MOOLSOCIAL-C34L-PLAY-CAPTURE-PRODUCER-001'
        Digests=@(
          'internalTestingRouteDigestSha256','uploadReceiptDigestSha256',
          'activationStateDigestSha256'
        )
        CaptureRoles=@(
          'internal_testing_release_receipt',
          'internal_testing_status_observation'
        )
        Counts=@(1,0,0,0,0,0,0,0)
        Authorities=@(
          'consumed','available_once','held_postupload_qualification',
          'held_postinstall_journey_qualification'
        )
      }
    }
    'oppo' {
      return [pscustomobject]@{
        EvidenceType='oppo_play_in_place_update_pair'; Short='oppo'
        Producer='MOOLSOCIAL-C34L-OPPO-CAPTURE-PRODUCER-001'
        Digests=@(
          'packageStateDigestSha256','coldStartDigestSha256',
          'retainedDataDigestSha256'
        )
        CaptureRoles=@('cold_start_observation','retained_state_observation')
        Counts=@(1,1,0,0,0,0,0,0)
        Authorities=@(
          'consumed','consumed','available_once',
          'held_postinstall_journey_qualification'
        )
      }
    }
    'journey' {
      return [pscustomobject]@{
        EvidenceType='mandatory_whole_app_journey_acceptance'; Short='journey'
        Producer='MOOLSOCIAL-C34L-JOURNEY-CAPTURE-PRODUCER-001'
        Digests=@(
          'publicGuestDigestSha256','protectedGatewayDigestSha256',
          'supportedAuthenticationDigestSha256','socialDigestSha256',
          'wholeAppDigestSha256','c33gBlockerDigestSha256'
        )
        CaptureRoles=@('journey_acceptance_manifest')
        Counts=@(1,1,1,0,0,0,0,0)
        Authorities=@(
          'consumed','consumed','consumed',
          'held_postinstall_journey_qualification'
        )
      }
    }
  }
}

function Get-C34LEvidenceRoot {
  param([Parameter(Mandatory)][object]$State)
  $expectedRoot = if ($FixtureMode) {
    (ConvertTo-C34LRepositoryRelativePath $script:fixtureStateRunRoot `
      'fixture state run root') + '/evidence'
  } else {
    $productionEvidenceRoot
  }
  Assert-C34LTransition -Condition (
    [string]$State.evidenceRoot -ceq $expectedRoot
  ) -Message 'candidate evidence root changed.'
  return $expectedRoot
}

function Assert-C34LExactEvidenceFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Sha256,
    [Parameter(Mandatory)][long]$Bytes,
    [Parameter(Mandatory)][string]$ExpectedPath,
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C34LTransition -Condition ([string]$Path -ceq $ExpectedPath) `
    -Message "$Label is not the exact immutable candidate owner."
  $resolved = Resolve-C34LRelativePath $Path $Label
  Assert-C34LProofConfinement $resolved $State $Label
  Assert-C34LTransition -Condition (
    $Sha256 -cmatch '^[0-9A-F]{64}$' -and $Bytes -gt 0 -and
    (Get-C34LFileSha256 $resolved) -ceq $Sha256 -and
    (Get-Item -LiteralPath $resolved).Length -eq $Bytes
  ) -Message "$Label SHA-256 or byte-length binding changed."
  return $resolved
}

function Assert-C34LCaptureArtifacts {
  param(
    [Parameter(Mandatory)][object]$Capture,
    [Parameter(Mandatory)][object]$Spec,
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][string]$EvidenceRoot,
    [Parameter(Mandatory)][string]$Label
  )
  $contractFile = Resolve-C34LRelativePath $captureArtifactContractPath `
    'capture-artifact contract'
  Assert-C34LTransition -Condition (
    (Get-C34LFileSha256 $contractFile) -ceq $captureArtifactContractSha256
  ) -Message 'capture-artifact contract SHA-256 changed.'
  $contract = Get-Content -Raw -LiteralPath $contractFile | ConvertFrom-Json
  Assert-C34LExactNames $contract @(
    'schemaVersion','contractId','ticketId','productionProducer',
    'authoritativeReceipt','captureAttemptRootPattern',
    'captureManifestPathPattern','captureArtifactPathPattern',
    'captureArtifactFields','mediaType','evidenceTypes','deviceBinding','privacy'
  ) 'capture-artifact contract'
  Assert-C34LTransition -Condition (
    [int]$contract.schemaVersion -eq 3 -and
    [string]$contract.contractId -ceq $captureArtifactContractId -and
    [string]$Capture.captureArtifactContractPath -ceq
      $captureArtifactContractPath -and
    [string]$Capture.captureArtifactContractSha256 -ceq
      $captureArtifactContractSha256 -and
    [string]$Capture.captureArtifactContractId -ceq $captureArtifactContractId -and
    [string]$contract.mediaType -ceq 'application/json' -and
    [string]$contract.captureAttemptRootPattern -ceq
      '<evidenceRoot>/captures/attempt-<attempt>' -and
    [string]$contract.captureManifestPathPattern -ceq
      '<evidenceRoot>/captures/attempt-<attempt>/<kind>/capture-manifest.json' -and
    [string]$contract.captureArtifactPathPattern -ceq
      '<evidenceRoot>/captures/attempt-<attempt>/<kind>/<leaf>' -and
    (@($contract.captureArtifactFields) -join ',') -ceq
      'role,path,sha256,bytes,mediaType' -and
    [string]$contract.deviceBinding.expectedSha256 -ceq $deviceBindingSha256 -and
    [string]$contract.deviceBinding.derivationId -ceq
      'MOOLSOCIAL-C34L-DEVICE-BINDING-001'
  ) -Message 'capture-artifact contract identity or capture binding changed.'
  $contractSpec = $contract.evidenceTypes.($Spec.EvidenceType)
  Assert-C34LTransition -Condition (
    $null -ne $contractSpec -and
    [string]$contractSpec.kind -ceq [string]$Spec.Short -and
    (@($contractSpec.roles | Sort-Object) -join ',') -ceq
      (@($Spec.CaptureRoles | Sort-Object) -join ',')
  ) `
    -Message "$Label evidence type is absent from the capture-artifact contract."
  $artifacts = @($Capture.captureArtifacts)
  Assert-C34LTransition -Condition (
    $artifacts.Count -eq $Spec.CaptureRoles.Count -and
    @($artifacts.role | Select-Object -Unique).Count -eq $artifacts.Count -and
    (@($artifacts.role | Sort-Object) -join ',') -ceq
      (@($Spec.CaptureRoles | Sort-Object) -join ',')
  ) -Message "$Label capture-artifact role set changed."
  $artifactByRole = @{}
  foreach ($artifact in $artifacts) {
    Assert-C34LExactNames $artifact @('role','path','sha256','bytes','mediaType') `
      "$Label capture artifact"
    $role = [string]$artifact.role
    $leaf = [string]$contractSpec.leafByRole.$role
    Assert-C34LTransition -Condition (
      -not [string]::IsNullOrWhiteSpace($leaf) -and
      [string]$artifact.path -ceq
        "$EvidenceRoot/captures/attempt-$Attempt/$($Spec.Short)/$leaf" -and
      [string]$artifact.mediaType -ceq 'application/json'
    ) -Message "$Label capture artifact path, role or media type changed."
    $resolved = Assert-C34LExactEvidenceFile `
      -Path ([string]$artifact.path) -Sha256 ([string]$artifact.sha256) `
      -Bytes ([int64]$artifact.bytes) -ExpectedPath ([string]$artifact.path) `
      -State $State -Label "$Label capture artifact $role"
    $raw = Get-Content -Raw -LiteralPath $resolved
    try { $value = $raw | ConvertFrom-Json } catch {
      throw "C34L lifecycle transaction rejected: $Label capture artifact $role is not valid JSON."
    }
    Assert-C34LEvidencePrivacy $value "$Label capture artifact $role"
    $artifactByRole[$role] = [pscustomobject]@{
      Binding=$artifact; Raw=$raw; Value=$value
    }
  }
  if ($Spec.Short -ceq 'play') {
    $receiptSha = [string]$artifactByRole.internal_testing_release_receipt.Binding.sha256
    $statusSha = [string]$artifactByRole.internal_testing_status_observation.Binding.sha256
    Assert-C34LTransition -Condition (
      [string]$Capture.captureDigests.internalTestingRouteDigestSha256 -ceq
        $receiptSha -and
      [string]$Capture.captureDigests.uploadReceiptDigestSha256 -ceq $receiptSha -and
      [string]$Capture.captureDigests.activationStateDigestSha256 -ceq $statusSha
    ) -Message 'Play capture digests are not bound to the exact capture artifacts.'
  } elseif ($Spec.Short -ceq 'oppo') {
    $coldSha = [string]$artifactByRole.cold_start_observation.Binding.sha256
    $retainedSha = [string]$artifactByRole.retained_state_observation.Binding.sha256
    Assert-C34LTransition -Condition (
      [string]$Capture.captureDigests.packageStateDigestSha256 -ceq $coldSha -and
      [string]$Capture.captureDigests.coldStartDigestSha256 -ceq $coldSha -and
      [string]$Capture.captureDigests.retainedDataDigestSha256 -ceq $retainedSha
    ) -Message 'OPPO capture digests are not bound to the exact capture artifacts.'
  } else {
    $journeyRows = @($artifactByRole.journey_acceptance_manifest.Value)
    $expectedJourneyIds = @(
      'publicGuest','protectedGateway','supportedAuthentication','social',
      'wholeApp','c33gBlocker'
    )
    Assert-C34LTransition -Condition (
      $journeyRows.Count -eq $expectedJourneyIds.Count -and
      @($journeyRows.journeyId | Select-Object -Unique).Count -eq
        $journeyRows.Count -and
      (@($journeyRows.journeyId | Sort-Object) -join ',') -ceq
        (@($expectedJourneyIds | Sort-Object) -join ',')
    ) -Message 'journey capture manifest row set changed.'
    foreach ($row in $journeyRows) {
      Assert-C34LExactNames $row @('journeyId','path','sha256','bytes','passed') `
        'journey capture manifest row'
      $journeyId = [string]$row.journeyId
      $expectedJourneyPath =
        "$EvidenceRoot/captures/attempt-$Attempt/journey/journeys/$journeyId.json"
      Assert-C34LTransition -Condition (
        [bool]$row.passed -and [string]$row.path -ceq $expectedJourneyPath
      ) -Message "journey capture row path or result changed at $journeyId."
      $journeyFile = Assert-C34LExactEvidenceFile `
        -Path ([string]$row.path) -Sha256 ([string]$row.sha256) `
        -Bytes ([int64]$row.bytes) -ExpectedPath $expectedJourneyPath `
        -State $State -Label "journey capture artifact $journeyId"
      $journeyRaw = Get-Content -Raw -LiteralPath $journeyFile
      try { $journeyValue = $journeyRaw | ConvertFrom-Json } catch {
        throw "C34L lifecycle transaction rejected: journey capture artifact $journeyId is not valid JSON."
      }
      Assert-C34LEvidencePrivacy $journeyValue `
        "journey capture artifact $journeyId"
      $digestName = $journeyId + 'DigestSha256'
      Assert-C34LTransition -Condition (
        $null -ne $Capture.captureDigests.PSObject.Properties[$digestName] -and
        [string]$Capture.captureDigests.$digestName -ceq [string]$row.sha256
      ) -Message "journey capture digest is not bound at $journeyId."
    }
  }
}

function Assert-C34LSourceAttestation {
  param(
    [Parameter(Mandatory)][object]$Evidence,
    [ValidateSet('play','oppo','journey')][string]$Kind,
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][string]$ExpectedStateSha256,
    [Parameter(Mandatory)][string]$ExpectedAggregateSha256,
    [Parameter(Mandatory)][DateTimeOffset]$ValidationInstantUtc,
    [Parameter(Mandatory)][string]$Label
  )
  $spec = Get-C34LEvidenceSpec $Kind
  $evidenceRoot = Get-C34LEvidenceRoot $State
  Assert-C34LExactNames $Evidence.sourceAttestation $sourceBindingNames `
    "$Label sourceAttestation"
  $binding = $Evidence.sourceAttestation
  $expectedAttestation =
    "$evidenceRoot/attestations/source-attestation-$($spec.Short)-attempt-$Attempt.json"
  $attestationFile = Assert-C34LExactEvidenceFile `
    -Path ([string]$binding.path) -Sha256 ([string]$binding.sha256) `
    -Bytes ([int64]$binding.bytes) -ExpectedPath $expectedAttestation `
    -State $State -Label "$Label source attestation"
  $attestationRaw = Get-Content -Raw -LiteralPath $attestationFile
  try { $attestation = $attestationRaw | ConvertFrom-Json } catch {
    throw "C34L lifecycle transaction rejected: $Label source attestation is not valid JSON."
  }
  Assert-C34LExactNames $attestation $sourceAttestationNames `
    "$Label source attestation"
  Assert-C34LExactNames $attestation.captureDigests $spec.Digests `
    "$Label source-attestation captureDigests"
  Assert-C34LEvidencePrivacy $attestation "$Label source attestation"
  Assert-C34LEvidenceVector $State $spec.Counts $spec.Authorities `
    "$Label detailed preimage"
  Assert-C34LEvidenceVector $Aggregate $spec.Counts $spec.Authorities `
    "$Label aggregate preimage"
  Assert-C34LEvidenceVector $attestation $spec.Counts $spec.Authorities `
    "$Label source attestation"
  $producedUtc = ConvertTo-C34LCanonicalUtcTimestamp `
    $attestation.producedUtc "$Label source attestation producedUtc"
  $expiresUtc = ConvertTo-C34LCanonicalUtcTimestamp `
    $attestation.expiresUtc "$Label source attestation expiresUtc"
  Assert-C34LRawJsonUtcToken $attestationRaw 'producedUtc' $producedUtc `
    "$Label source attestation producedUtc"
  Assert-C34LRawJsonUtcToken $attestationRaw 'expiresUtc' $expiresUtc `
    "$Label source attestation expiresUtc"
  $produced = ConvertTo-C34LUtcInstant $producedUtc `
    "$Label source attestation producedUtc"
  $expires = ConvertTo-C34LUtcInstant $expiresUtc `
    "$Label source attestation expiresUtc"
  Assert-C34LTransition -Condition (
    $expires -gt $produced -and $expires -le $produced.AddMinutes(15) -and
    $produced -le $ValidationInstantUtc.AddSeconds(30) -and
    $expires -gt $ValidationInstantUtc.AddSeconds(-30)
  ) -Message "$Label source-attestation session is expired, premature or replayed."
  Assert-C34LTransition -Condition (
    [int]$attestation.schemaVersion -eq 1 -and
    [string]$attestation.attestationContractId -ceq
      $sourceAttestationContractId -and
    [string]$attestation.evidenceType -ceq $spec.EvidenceType -and
    [string]$attestation.ticketId -ceq $ticketId -and
    [int]$attestation.attempt -eq $Attempt -and
    [string]$attestation.packageName -ceq $packageName -and
    [string]$attestation.versionName -ceq $versionName -and
    [string]$attestation.versionCode -ceq $versionCode
  ) -Message "$Label source-attestation identity changed."
  Assert-C34LTransition -Condition (
    [string]$attestation.preStateSha256 -ceq $ExpectedStateSha256 -and
    [string]$attestation.preAggregateSha256 -ceq $ExpectedAggregateSha256
  ) -Message "$Label source-attestation transaction preimage changed."
  Assert-C34LTransition -Condition (
    [string]$attestation.artifactSha256 -ceq
      [string]$State.buildResult.artifactSha256 -and
    [int64]$attestation.artifactBytes -eq
      [int64]$State.buildResult.artifactBytes
  ) -Message "$Label source-attestation artifact binding changed."
  Assert-C34LTransition -Condition (
    [string]$attestation.sourceProducerId -ceq $spec.Producer -and
    [string]$attestation.sessionId -cmatch '^[a-z0-9][a-z0-9_-]{15,95}$' -and
    [string]$attestation.nonceSha256 -cmatch '^[0-9A-F]{64}$'
  ) -Message "$Label source-attestation producer or session binding changed."
  $artifactFile = Resolve-C34LRelativePath `
    ([string]$State.buildResult.artifactPath) "$Label sealed artifact"
  if ($FixtureMode) {
    Assert-C34LFixturePath $artifactFile "$Label fixture sealed artifact"
  }
  Assert-C34LTransition -Condition (
    [string]$State.buildResult.artifactSha256 -cmatch '^[0-9A-F]{64}$' -and
    [int64]$State.buildResult.artifactBytes -gt 0 -and
    (Get-C34LFileSha256 $artifactFile) -ceq
      [string]$State.buildResult.artifactSha256 -and
    (Get-Item -LiteralPath $artifactFile).Length -eq
      [int64]$State.buildResult.artifactBytes
  ) -Message "$Label sealed artifact SHA-256 or bytes changed."
  foreach ($name in $spec.Digests) {
    Assert-C34LTransition -Condition (
      [string]$attestation.captureDigests.$name -cmatch '^[0-9A-F]{64}$'
    ) -Message "$Label source-attestation digest changed at $name."
  }
  foreach ($name in @(
    'evidenceType','sourceProducerId','sessionId','nonceSha256',
    'captureManifestPath','captureManifestSha256'
  )) {
    Assert-C34LTransition -Condition (
      [string]$binding.$name -ceq [string]$attestation.$name
    ) -Message "$Label sourceAttestation changed at $name."
  }
  Assert-C34LTransition -Condition (
    [int64]$binding.captureManifestBytes -eq
      [int64]$attestation.captureManifestBytes -and
    (ConvertTo-C34LCanonicalUtcTimestamp `
      $binding.producedUtc "$Label binding producedUtc") -ceq $producedUtc -and
    (ConvertTo-C34LCanonicalUtcTimestamp `
      $binding.expiresUtc "$Label binding expiresUtc") -ceq $expiresUtc
  ) -Message "$Label sourceAttestation byte or UTC binding changed."
  Assert-C34LExactNames $binding.captureDigests $spec.Digests `
    "$Label sourceAttestation captureDigests"
  foreach ($name in $spec.Digests) {
    Assert-C34LTransition -Condition (
      [string]$binding.captureDigests.$name -ceq
        [string]$attestation.captureDigests.$name
    ) -Message "$Label sourceAttestation capture digest changed at $name."
  }
  $expectedCapture =
    "$evidenceRoot/captures/attempt-$Attempt/$($spec.Short)/capture-manifest.json"
  $captureFile = Assert-C34LExactEvidenceFile `
    -Path ([string]$attestation.captureManifestPath) `
    -Sha256 ([string]$attestation.captureManifestSha256) `
    -Bytes ([int64]$attestation.captureManifestBytes) `
    -ExpectedPath $expectedCapture -State $State `
    -Label "$Label capture manifest"
  $captureRaw = Get-Content -Raw -LiteralPath $captureFile
  try { $capture = $captureRaw | ConvertFrom-Json } catch {
    throw "C34L lifecycle transaction rejected: $Label capture manifest is not valid JSON."
  }
  Assert-C34LExactNames $capture $captureManifestNames `
    "$Label capture manifest"
  Assert-C34LExactNames $capture.captureDigests $spec.Digests `
    "$Label capture-manifest captureDigests"
  Assert-C34LEvidencePrivacy $capture "$Label capture manifest"
  Assert-C34LEvidenceVector $capture $spec.Counts $spec.Authorities `
    "$Label capture manifest"
  $captureProducedUtc = ConvertTo-C34LCanonicalUtcTimestamp `
    $capture.producedUtc "$Label capture manifest producedUtc"
  $captureExpiresUtc = ConvertTo-C34LCanonicalUtcTimestamp `
    $capture.expiresUtc "$Label capture manifest expiresUtc"
  Assert-C34LRawJsonUtcToken $captureRaw 'producedUtc' $captureProducedUtc `
    "$Label capture manifest producedUtc"
  Assert-C34LRawJsonUtcToken $captureRaw 'expiresUtc' $captureExpiresUtc `
    "$Label capture manifest expiresUtc"
  Assert-C34LTransition -Condition (
    [int]$capture.schemaVersion -eq 1 -and
    [string]$capture.captureContractId -ceq $captureManifestContractId -and
    [string]$capture.evidenceType -ceq [string]$attestation.evidenceType -and
    [string]$capture.ticketId -ceq [string]$attestation.ticketId -and
    [int]$capture.attempt -eq [int]$attestation.attempt -and
    [string]$capture.packageName -ceq [string]$attestation.packageName -and
    [string]$capture.versionName -ceq [string]$attestation.versionName -and
    [string]$capture.versionCode -ceq [string]$attestation.versionCode -and
    [string]$capture.preStateSha256 -ceq $ExpectedStateSha256 -and
    [string]$capture.preAggregateSha256 -ceq $ExpectedAggregateSha256 -and
    [string]$capture.artifactSha256 -ceq
      [string]$attestation.artifactSha256 -and
    [int64]$capture.artifactBytes -eq [int64]$attestation.artifactBytes -and
    [string]$capture.sourceProducerId -ceq
      [string]$attestation.sourceProducerId -and
    [string]$capture.sessionId -ceq [string]$attestation.sessionId -and
    [string]$capture.nonceSha256 -ceq [string]$attestation.nonceSha256 -and
    $captureProducedUtc -ceq $producedUtc -and
    $captureExpiresUtc -ceq $expiresUtc
  ) -Message "$Label capture-manifest identity, preimage, vector, artifact or session changed."
  foreach ($name in $spec.Digests) {
    Assert-C34LTransition -Condition (
      [string]$capture.captureDigests.$name -ceq
        [string]$attestation.captureDigests.$name
    ) -Message "$Label capture-manifest digest changed at $name."
  }
  Assert-C34LCaptureArtifacts -Capture $capture -Spec $spec -State $State `
    -EvidenceRoot $evidenceRoot -Label $Label
  return $binding
}

function Assert-C34LFinalEvidenceCommon {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][object]$Evidence,
    [ValidateSet('play','oppo','journey')][string]$Kind,
    [Parameter(Mandatory)][string]$ExpectedStateSha256,
    [Parameter(Mandatory)][string]$ExpectedAggregateSha256,
    [Parameter(Mandatory)][DateTimeOffset]$ValidationInstantUtc,
    [Parameter(Mandatory)][string]$Label
  )
  $spec = Get-C34LEvidenceSpec $Kind
  Assert-C34LEvidencePrivacy $Evidence $Label
  Assert-C34LEvidenceVector $Evidence $spec.Counts $spec.Authorities $Label
  Assert-C34LTransition -Condition (
    [int]$Evidence.schemaVersion -eq 1 -and
    [string]$Evidence.ticketId -ceq $ticketId -and
    [int]$Evidence.attempt -eq $Attempt -and
    [string]$Evidence.preStateSha256 -ceq $ExpectedStateSha256 -and
    [string]$Evidence.preAggregateSha256 -ceq $ExpectedAggregateSha256 -and
    [string]$Evidence.packageName -ceq $packageName -and
    [string]$Evidence.versionName -ceq $versionName -and
    [string]$Evidence.versionCode -ceq $versionCode -and
    [string]$Evidence.artifactSha256 -ceq
      [string]$State.buildResult.artifactSha256 -and
    [int64]$Evidence.artifactBytes -eq [int64]$State.buildResult.artifactBytes
  ) -Message "$Label ticket, attempt or transaction preimage changed."
  foreach ($name in $evidenceCountNames) {
    Assert-C34LTransition -Condition (
      [int]$Evidence.actionCounts.$name -eq [int]$State.actionCounts.$name -and
      [int]$Evidence.actionCounts.$name -eq [int]$Aggregate.actionCounts.$name
    ) -Message "$Label action count changed at $name."
  }
  foreach ($name in $evidenceAuthorityNames) {
    Assert-C34LTransition -Condition (
      [string]$Evidence.releaseAuthorities.$name -ceq
        [string]$State.releaseAuthorities.$name -and
      [string]$Evidence.releaseAuthorities.$name -ceq
        [string]$Aggregate.releaseAuthorities.$name
    ) -Message "$Label release authority changed at $name."
  }
  return Assert-C34LSourceAttestation -Evidence $Evidence -Kind $Kind `
    -State $State -Aggregate $Aggregate `
    -ExpectedStateSha256 $ExpectedStateSha256 `
    -ExpectedAggregateSha256 $ExpectedAggregateSha256 `
    -ValidationInstantUtc $ValidationInstantUtc -Label $Label
}

function Read-C34LFinalEvidenceFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Sha256,
    [Parameter(Mandatory)][long]$Bytes,
    [Parameter(Mandatory)][string]$ExpectedPath,
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = Assert-C34LExactEvidenceFile -Path $Path -Sha256 $Sha256 `
    -Bytes $Bytes -ExpectedPath $ExpectedPath -State $State -Label $Label
  $raw = Get-Content -Raw -LiteralPath $resolved
  try { $value = $raw | ConvertFrom-Json } catch {
    throw "C34L lifecycle transaction rejected: $Label is not valid JSON."
  }
  Assert-C34LEvidencePrivacy $value $Label
  return [pscustomobject]@{ Path=$resolved; Raw=$raw; Value=$value }
}

function Assert-C34LPlayFinalEvidence {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Sha256,
    [Parameter(Mandatory)][long]$Bytes,
    [Parameter(Mandatory)][string]$ExpectedStateSha256,
    [Parameter(Mandatory)][string]$ExpectedAggregateSha256,
    [Parameter(Mandatory)][DateTimeOffset]$ValidationInstantUtc
  )
  $evidenceRoot = Get-C34LEvidenceRoot $State
  $file = Read-C34LFinalEvidenceFile -Path $Path -Sha256 $Sha256 `
    -Bytes $Bytes `
    -ExpectedPath "$evidenceRoot/07-play-internal-testing-activation-evidence.json" `
    -State $State -Label 'Play transition evidence'
  $play = $file.Value
  Assert-C34LExactNames $play @(
    'schemaVersion','evidenceContractId','evidenceType','ticketId','attempt',
    'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
    'packageName','versionName','versionCode','artifactSha256','artifactBytes',
    'track','internalReleaseActive','uploadCount','internalActivationCount',
    'otherTrackChanged','sourceAttestation'
  ) 'Play transition evidence'
  Assert-C34LTransition -Condition (
    [string]$play.evidenceContractId -ceq 'MOOLSOCIAL-C34L-PLAY-EVIDENCE-001' -and
    [string]$play.evidenceType -ceq 'play_internal_testing_activation' -and
    [string]$play.track -ceq 'internal' -and
    [bool]$play.internalReleaseActive -and
    [int]$play.uploadCount -eq 1 -and
    [int]$play.internalActivationCount -eq 1 -and
    -not [bool]$play.otherTrackChanged
  ) -Message 'Play transition evidence success contract changed.'
  [void](Assert-C34LFinalEvidenceCommon -State $State -Aggregate $Aggregate `
    -Evidence $play -Kind play -ExpectedStateSha256 $ExpectedStateSha256 `
    -ExpectedAggregateSha256 $ExpectedAggregateSha256 `
    -ValidationInstantUtc $ValidationInstantUtc -Label 'Play transition evidence')
}

function Assert-C34LJourneyFinalEvidence {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Sha256,
    [Parameter(Mandatory)][long]$Bytes,
    [Parameter(Mandatory)][string]$ExpectedStateSha256,
    [Parameter(Mandatory)][string]$ExpectedAggregateSha256,
    [Parameter(Mandatory)][DateTimeOffset]$ValidationInstantUtc
  )
  $evidenceRoot = Get-C34LEvidenceRoot $State
  $file = Read-C34LFinalEvidenceFile -Path $Path -Sha256 $Sha256 `
    -Bytes $Bytes `
    -ExpectedPath "$evidenceRoot/10-mandatory-whole-app-journey-evidence.json" `
    -State $State -Label 'journey transition evidence'
  $journey = $file.Value
  Assert-C34LExactNames $journey @(
    'schemaVersion','evidenceContractId','evidenceType','ticketId','attempt',
    'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
    'packageName','versionName','versionCode','artifactSha256','artifactBytes',
    'track','deviceBindingSha256','deviceModel','installerPackage',
    'publicGuestJourneyPassed','protectedGatewayJourneyPassed',
    'supportedAuthenticationJourneysPassed','socialJourneysPassed',
    'wholeAppJourneysPassed','c33gBlockerJourneysPassed',
    'allMandatoryJourneysPassed','evidenceComplete','newIssueCount',
    'newDefectCount','blankScreenCount','flutterFatalErrorCount',
    'androidRuntimeFatalCount','anrCount','acceptanceSucceeded',
    'successClaimed','sourceAttestation'
  ) 'journey transition evidence'
  Assert-C34LTransition -Condition (
    [string]$journey.evidenceContractId -ceq
      'MOOLSOCIAL-C34L-JOURNEY-EVIDENCE-001' -and
    [string]$journey.evidenceType -ceq
      'mandatory_whole_app_journey_acceptance' -and
    [string]$journey.track -ceq 'internal' -and
    [string]$journey.deviceBindingSha256 -ceq $deviceBindingSha256 -and
    [string]$journey.deviceModel -ceq 'CPH2375' -and
    [string]$journey.installerPackage -ceq 'com.android.vending' -and
    [bool]$journey.publicGuestJourneyPassed -and
    [bool]$journey.protectedGatewayJourneyPassed -and
    [bool]$journey.supportedAuthenticationJourneysPassed -and
    [bool]$journey.socialJourneysPassed -and
    [bool]$journey.wholeAppJourneysPassed -and
    [bool]$journey.c33gBlockerJourneysPassed -and
    [bool]$journey.allMandatoryJourneysPassed -and
    [bool]$journey.evidenceComplete -and
    [int]$journey.newIssueCount -eq 0 -and
    [int]$journey.newDefectCount -eq 0 -and
    [int]$journey.blankScreenCount -eq 0 -and
    [int]$journey.flutterFatalErrorCount -eq 0 -and
    [int]$journey.androidRuntimeFatalCount -eq 0 -and
    [int]$journey.anrCount -eq 0 -and
    [bool]$journey.acceptanceSucceeded -and [bool]$journey.successClaimed
  ) -Message 'journey transition evidence success contract changed.'
  [void](Assert-C34LFinalEvidenceCommon -State $State -Aggregate $Aggregate `
    -Evidence $journey -Kind journey -ExpectedStateSha256 $ExpectedStateSha256 `
    -ExpectedAggregateSha256 $ExpectedAggregateSha256 `
    -ValidationInstantUtc $ValidationInstantUtc -Label 'journey transition evidence')
}

function Assert-C34LOppoFinalEvidence {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][string]$ColdPath,
    [Parameter(Mandatory)][string]$ColdSha256,
    [Parameter(Mandatory)][long]$ColdBytes,
    [Parameter(Mandatory)][string]$RetainedPath,
    [Parameter(Mandatory)][string]$RetainedSha256,
    [Parameter(Mandatory)][long]$RetainedBytes,
    [Parameter(Mandatory)][string]$ExpectedStateSha256,
    [Parameter(Mandatory)][string]$ExpectedAggregateSha256,
    [Parameter(Mandatory)][DateTimeOffset]$ValidationInstantUtc
  )
  $evidenceRoot = Get-C34LEvidenceRoot $State
  $coldFile = Read-C34LFinalEvidenceFile -Path $ColdPath `
    -Sha256 $ColdSha256 -Bytes $ColdBytes `
    -ExpectedPath "$evidenceRoot/08-oppo-play-in-place-update-cold-start-evidence.json" `
    -State $State -Label 'OPPO cold-start transition evidence'
  $retainedFile = Read-C34LFinalEvidenceFile -Path $RetainedPath `
    -Sha256 $RetainedSha256 -Bytes $RetainedBytes `
    -ExpectedPath "$evidenceRoot/09-oppo-in-place-retained-data-evidence.json" `
    -State $State -Label 'OPPO retained-data transition evidence'
  $cold = $coldFile.Value
  $retained = $retainedFile.Value
  $identityNames = @(
    'schemaVersion','evidenceContractId','evidencePairId','ticketId','attempt',
    'preStateSha256','preAggregateSha256','actionCounts','releaseAuthorities',
    'packageName','versionName','versionCode','artifactSha256','artifactBytes',
    'deviceBindingSha256','deviceModel','installerPackage','sourceAttestation','evidenceType'
  )
  Assert-C34LExactNames $cold ($identityNames + @(
    'coldStartInteractive','blankHierarchy','timeout','flutterFatalErrorCount',
    'androidRuntimeFatalCount','anrCount','appProcessErrorScanPassed',
    'artifactRelationshipProved','inPlaceUpdateProved'
  )) 'OPPO cold-start transition evidence'
  Assert-C34LExactNames $retained ($identityNames + @(
    'firstInstallTimeMillis','lastUpdateTimeMillis','firstInstallTimePreserved',
    'retainedDataContinuityProved','inPlacePlayUpdateProved',
    'uninstallPerformed','dataClearPerformed','downgradePerformed',
    'adbInstallPerformed'
  )) 'OPPO retained-data transition evidence'
  foreach ($item in @($cold,$retained)) {
    Assert-C34LTransition -Condition (
      [string]$item.evidenceContractId -ceq
        'MOOLSOCIAL-C34L-OPPO-EVIDENCE-001' -and
      [string]$item.evidencePairId -ceq [string]$cold.evidencePairId -and
      [string]$item.deviceBindingSha256 -ceq $deviceBindingSha256 -and
      [string]$item.deviceModel -ceq 'CPH2375' -and
      [string]$item.installerPackage -ceq 'com.android.vending'
    ) -Message 'OPPO transition evidence identity or pair changed.'
  }
  Assert-C34LTransition -Condition (
    [string]$cold.evidenceType -ceq
      'oppo_play_in_place_update_cold_start' -and
    [bool]$cold.coldStartInteractive -and -not [bool]$cold.blankHierarchy -and
    -not [bool]$cold.timeout -and [int]$cold.flutterFatalErrorCount -eq 0 -and
    [int]$cold.androidRuntimeFatalCount -eq 0 -and [int]$cold.anrCount -eq 0 -and
    [bool]$cold.appProcessErrorScanPassed -and
    [bool]$cold.artifactRelationshipProved -and [bool]$cold.inPlaceUpdateProved
  ) -Message 'OPPO cold-start transition evidence success contract changed.'
  Assert-C34LTransition -Condition (
    [string]$retained.evidenceType -ceq 'oppo_in_place_retained_data' -and
    [int64]$retained.firstInstallTimeMillis -lt
      [int64]$retained.lastUpdateTimeMillis -and
    [bool]$retained.firstInstallTimePreserved -and
    [bool]$retained.retainedDataContinuityProved -and
    [bool]$retained.inPlacePlayUpdateProved -and
    -not [bool]$retained.uninstallPerformed -and
    -not [bool]$retained.dataClearPerformed -and
    -not [bool]$retained.downgradePerformed -and
    -not [bool]$retained.adbInstallPerformed
  ) -Message 'OPPO retained-data transition evidence success contract changed.'
  $coldSource = Assert-C34LFinalEvidenceCommon -State $State `
    -Aggregate $Aggregate -Evidence $cold -Kind oppo `
    -ExpectedStateSha256 $ExpectedStateSha256 `
    -ExpectedAggregateSha256 $ExpectedAggregateSha256 `
    -ValidationInstantUtc $ValidationInstantUtc `
    -Label 'OPPO cold-start transition evidence'
  $retainedSource = Assert-C34LFinalEvidenceCommon -State $State `
    -Aggregate $Aggregate -Evidence $retained -Kind oppo `
    -ExpectedStateSha256 $ExpectedStateSha256 `
    -ExpectedAggregateSha256 $ExpectedAggregateSha256 `
    -ValidationInstantUtc $ValidationInstantUtc `
    -Label 'OPPO retained-data transition evidence'
  Assert-C34LTransition -Condition (
    (ConvertTo-Json -InputObject $coldSource -Depth 20 -Compress) -ceq
      (ConvertTo-Json -InputObject $retainedSource -Depth 20 -Compress) -and
    [string]$cold.evidencePairId -ceq "oppo-$Attempt-$ExpectedStateSha256"
  ) -Message 'OPPO transition evidence pair or source-attestation binding changed.'

  $journalPath =
    "$evidenceRoot/transactions/oppo-evidence-pair-attempt-$Attempt.json"
  $journalResolved = Resolve-C34LRelativePath $journalPath `
    'OPPO evidence transaction journal'
  Assert-C34LProofConfinement $journalResolved $State `
    'OPPO evidence transaction journal'
  $journalRaw = Get-Content -Raw -LiteralPath $journalResolved
  try { $journal = $journalRaw | ConvertFrom-Json } catch {
    throw 'C34L lifecycle transaction rejected: OPPO evidence transaction journal is not valid JSON.'
  }
  Assert-C34LEvidencePrivacy $journal 'OPPO evidence transaction journal'
  Assert-C34LExactNames $journal @(
    'schemaVersion','transactionContractId','transactionId','ticketId','attempt',
    'status','preStateSha256','preAggregateSha256','artifactSha256',
    'artifactBytes','coldStart','retainedData','sourceAttestation','preparedUtc',
    'committedUtc'
  ) 'OPPO evidence transaction journal'
  Assert-C34LExactNames $journal.coldStart @('path','sha256','bytes') `
    'OPPO journal coldStart'
  Assert-C34LExactNames $journal.retainedData @('path','sha256','bytes') `
    'OPPO journal retainedData'
  Assert-C34LExactNames $journal.sourceAttestation $sourceBindingNames `
    'OPPO journal sourceAttestation'
  Assert-C34LTransition -Condition (
    [int]$journal.schemaVersion -eq 1 -and
    [string]$journal.transactionContractId -ceq
      'MOOLSOCIAL-C34L-OPPO-EVIDENCE-TRANSACTION-001' -and
    [string]$journal.transactionId -ceq
      "oppo-evidence-$Attempt-$ExpectedStateSha256-$ExpectedAggregateSha256" -and
    [string]$journal.ticketId -ceq $ticketId -and
    [int]$journal.attempt -eq $Attempt -and
    [string]$journal.status -ceq 'committed' -and
    [string]$journal.preStateSha256 -ceq $ExpectedStateSha256 -and
    [string]$journal.preAggregateSha256 -ceq $ExpectedAggregateSha256 -and
    [string]$journal.artifactSha256 -ceq
      [string]$State.buildResult.artifactSha256 -and
    [int64]$journal.artifactBytes -eq [int64]$State.buildResult.artifactBytes
  ) -Message 'OPPO evidence transaction journal identity or status changed.'
  Assert-C34LTransition -Condition (
    [string]$journal.coldStart.path -ceq $ColdPath -and
    [string]$journal.coldStart.sha256 -ceq $ColdSha256 -and
    [int64]$journal.coldStart.bytes -eq $ColdBytes -and
    [string]$journal.retainedData.path -ceq $RetainedPath -and
    [string]$journal.retainedData.sha256 -ceq $RetainedSha256 -and
    [int64]$journal.retainedData.bytes -eq $RetainedBytes -and
    (ConvertTo-Json -InputObject $journal.sourceAttestation `
      -Depth 20 -Compress) -ceq
      (ConvertTo-Json -InputObject $coldSource -Depth 20 -Compress)
  ) -Message 'OPPO evidence transaction journal payload or attestation changed.'
  $preparedUtc = ConvertTo-C34LCanonicalUtcTimestamp $journal.preparedUtc `
    'OPPO evidence journal preparedUtc'
  $committedUtc = ConvertTo-C34LCanonicalUtcTimestamp $journal.committedUtc `
    'OPPO evidence journal committedUtc'
  Assert-C34LRawJsonUtcToken $journalRaw 'preparedUtc' $preparedUtc `
    'OPPO evidence journal preparedUtc'
  Assert-C34LRawJsonUtcToken $journalRaw 'committedUtc' $committedUtc `
    'OPPO evidence journal committedUtc'
  $sourceProducedUtc = ConvertTo-C34LCanonicalUtcTimestamp `
    $coldSource.producedUtc 'OPPO source producedUtc'
  $sourceExpiresUtc = ConvertTo-C34LCanonicalUtcTimestamp `
    $coldSource.expiresUtc 'OPPO source expiresUtc'
  Assert-C34LTransition -Condition (
    [string]::CompareOrdinal($preparedUtc,$sourceProducedUtc) -ge 0 -and
    [string]::CompareOrdinal($preparedUtc,$sourceExpiresUtc) -le 0 -and
    [string]::CompareOrdinal($committedUtc,$preparedUtc) -ge 0
  ) -Message 'OPPO evidence transaction UTC order escaped the attested session.'
}

function Assert-C34LJournalFinalEvidence {
  param(
    [Parameter(Mandatory)][object]$Journal,
    [Parameter(Mandatory)][object]$StateBefore,
    [Parameter(Mandatory)][object]$AggregateBefore,
    [Parameter(Mandatory)][object]$StateAfter,
    [Parameter(Mandatory)][DateTimeOffset]$ValidationInstantUtc
  )
  switch ([string]$Journal.transition) {
    'upload-succeeded' {
      Assert-C34LPlayFinalEvidence -State $StateBefore `
        -Aggregate $AggregateBefore `
        -Path ([string]$StateAfter.playResult.evidencePath) `
        -Sha256 ([string]$StateAfter.playResult.evidenceSha256) `
        -Bytes ([int64]$StateAfter.playResult.evidenceBytes) `
        -ExpectedStateSha256 ([string]$Journal.stateBeforeSha256) `
        -ExpectedAggregateSha256 ([string]$Journal.aggregateBeforeSha256) `
        -ValidationInstantUtc $ValidationInstantUtc
    }
    'install-succeeded' {
      Assert-C34LOppoFinalEvidence -State $StateBefore `
        -Aggregate $AggregateBefore `
        -ColdPath ([string]$StateAfter.installResult.coldStartEvidencePath) `
        -ColdSha256 ([string]$StateAfter.installResult.coldStartEvidenceSha256) `
        -ColdBytes ([int64]$StateAfter.installResult.coldStartEvidenceBytes) `
        -RetainedPath ([string]$StateAfter.installResult.retainedDataEvidencePath) `
        -RetainedSha256 `
          ([string]$StateAfter.installResult.retainedDataEvidenceSha256) `
        -RetainedBytes ([int64]$StateAfter.installResult.retainedDataEvidenceBytes) `
        -ExpectedStateSha256 ([string]$Journal.stateBeforeSha256) `
        -ExpectedAggregateSha256 ([string]$Journal.aggregateBeforeSha256) `
        -ValidationInstantUtc $ValidationInstantUtc
    }
    'device-accepted' {
      Assert-C34LJourneyFinalEvidence -State $StateBefore `
        -Aggregate $AggregateBefore `
        -Path ([string]$StateAfter.installResult.journeyEvidencePath) `
        -Sha256 ([string]$StateAfter.installResult.journeyEvidenceSha256) `
        -Bytes ([int64]$StateAfter.installResult.journeyEvidenceBytes) `
        -ExpectedStateSha256 ([string]$Journal.stateBeforeSha256) `
        -ExpectedAggregateSha256 ([string]$Journal.aggregateBeforeSha256) `
        -ValidationInstantUtc $ValidationInstantUtc
    }
  }
}

function Set-C34LMachine {
  param([object]$State, [object]$Aggregate, [string]$Value)
  $State.machineState = $Value
  $Aggregate.machineState = $Value
  $State.candidate.disposition = $Value
  $Aggregate.candidate.disposition = $Value
}

function Set-C34LRejected {
  param([object]$State, [object]$Aggregate)
  foreach ($name in @(
    'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
    'postinstallAcceptance'
  )) {
    if ([string]$State.releaseAuthorities.$name -cne 'consumed') {
      $State.releaseAuthorities.$name = 'rejected_candidate'
      $Aggregate.releaseAuthorities.$name = 'rejected_candidate'
    }
  }
  $State.buildAuthorization = if (
    [string]$State.releaseAuthorities.build -ceq 'consumed'
  ) { 'consumed' } else { 'rejected_candidate' }
  $State.uploadAuthorization = if (
    [string]$State.releaseAuthorities.uploadAndInternalActivation -ceq 'consumed'
  ) { 'consumed' } else { 'rejected_candidate' }
  $State.installAuthorization = if (
    [string]$State.releaseAuthorities.inPlaceOppoPlayUpdate -ceq 'consumed'
  ) { 'consumed' } else { 'rejected_candidate' }
  $State.deviceAuthorization = if (
    [string]$State.releaseAuthorities.postinstallAcceptance -ceq 'consumed'
  ) { 'consumed' } else { 'rejected_candidate' }
  $State.candidate.disposition = 'rejected'
  $Aggregate.candidate.disposition = 'rejected'
  $State.candidate.artifactReusable = $false
  $Aggregate.candidate.artifactReusable = $false
}

function Get-C34LJournalRoot {
  param([object]$State, [string]$StateFile)
  if ($FixtureMode) {
    $journalRoot = Join-Path (Split-Path -Parent $StateFile) 'journals'
    Assert-C34LFixturePath -Resolved $journalRoot -Label 'fixture journal root'
    return $journalRoot
  }
  Assert-C34LTransition -Condition (
    -not [string]::IsNullOrWhiteSpace([string]$State.evidenceRoot) -and
    [string]$State.evidenceRoot -cmatch
      '^artifacts/quality/uaw-c34l-r60-76-consolidated-release-transaction-evidence-[a-z0-9-]+$'
  ) -Message 'real transaction evidence root is not exact C34L retained evidence.'
  $journalRoot = [IO.Path]::GetFullPath(
    (Join-Path $root ([string]$State.evidenceRoot + '/release-transaction-journals'))
  )
  Assert-C34LTransition -Condition (
    $journalRoot.StartsWith(
      [IO.Path]::GetFullPath((Join-Path $root 'artifacts/quality')) +
        [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message 'real transaction journal escaped retained evidence.'
  return $journalRoot
}

function Get-C34LLifecycleHistoryCount {
  param(
    [Parameter(Mandatory)][object]$State,
    [Parameter(Mandatory)][object]$Aggregate,
    [Parameter(Mandatory)][string]$Label
  )
  $stateHistory = @()
  if ($null -ne $State.PSObject.Properties['lifecycleTransactionProofs']) {
    $stateHistory = @($State.lifecycleTransactionProofs)
  }
  $aggregateHistory = @()
  if ($null -ne $Aggregate.PSObject.Properties['lifecycleTransactionProofs']) {
    $aggregateHistory = @($Aggregate.lifecycleTransactionProofs)
  }
  Assert-C34LTransition -Condition (
    $stateHistory.Count -eq $aggregateHistory.Count -and
    (ConvertTo-Json -InputObject $stateHistory -Depth 60 -Compress) -ceq
      (ConvertTo-Json -InputObject $aggregateHistory -Depth 60 -Compress)
  ) -Message "$Label detailed/aggregate lifecycle history changed."
  return $stateHistory.Count
}

function Complete-C34LJournalReconciliation {
  param([string]$JournalRoot, [string]$ExpectedStateFile, [string]$ExpectedAggregateFile)
  if (-not (Test-Path -LiteralPath $JournalRoot -PathType Container)) {
    $stateWithoutJournal = Get-Content -Raw -LiteralPath $ExpectedStateFile |
      ConvertFrom-Json
    $aggregateWithoutJournal = Get-Content -Raw `
      -LiteralPath $ExpectedAggregateFile | ConvertFrom-Json
    $historyWithoutJournal = Get-C34LLifecycleHistoryCount `
      $stateWithoutJournal $aggregateWithoutJournal 'missing-journal'
    Assert-C34LTransition -Condition ($historyWithoutJournal -eq 0) `
      -Message 'transaction journal files are missing for retained lifecycle history.'
    return 0
  }
  $journalFiles = @(Get-ChildItem -LiteralPath $JournalRoot -Filter '*.json' -File)
  if ($journalFiles.Count -eq 0) {
    $stateWithoutJournal = Get-Content -Raw -LiteralPath $ExpectedStateFile |
      ConvertFrom-Json
    $aggregateWithoutJournal = Get-Content -Raw `
      -LiteralPath $ExpectedAggregateFile | ConvertFrom-Json
    $historyWithoutJournal = Get-C34LLifecycleHistoryCount `
      $stateWithoutJournal $aggregateWithoutJournal 'empty-journal'
    Assert-C34LTransition -Condition ($historyWithoutJournal -eq 0) `
      -Message 'transaction journal files are missing for retained lifecycle history.'
    return 0
  }
  $expectedProperties = @(
    'schemaVersion', 'contractId', 'ticketId', 'attempt', 'transactionId', 'sequence',
    'transition', 'status', 'statePath', 'aggregateStatePath',
    'prerequisiteGateEvidencePath', 'prerequisiteGateEvidenceSha256',
    'prerequisiteGatePhase', 'browserEvidence', 'stateBeforeSha256',
    'aggregateBeforeSha256',
    'stateAfterSha256', 'aggregateAfterSha256', 'stateBeforeBase64',
    'aggregateBeforeBase64', 'stateAfterBase64', 'aggregateAfterBase64',
    'preparedUtc', 'committedUtc', 'reconciledUtc', 'observedStateSha256',
    'observedAggregateSha256'
  )
  $journalRows = @()
  foreach ($journalFile in $journalFiles) {
    $journalText = Get-Content -Raw -LiteralPath $journalFile.FullName
    $journal = $journalText | ConvertFrom-Json
    $actualProperties = @($journal.PSObject.Properties | ForEach-Object { $_.Name })
    Assert-C34LTransition -Condition (
      (@($actualProperties | Sort-Object) -join ',') -ceq
        (@($expectedProperties | Sort-Object) -join ',') -and
      [int]$journal.schemaVersion -eq 1 -and
      [string]$journal.contractId -ceq $contractId -and
      [string]$journal.ticketId -ceq $ticketId -and
      [int]$journal.attempt -eq $Attempt -and
      [string]$journal.statePath -ceq $StatePath -and
      [string]$journal.aggregateStatePath -ceq
        (ConvertTo-C34LRepositoryRelativePath $ExpectedAggregateFile 'journal aggregate target') -and
      [int]$journal.sequence -gt 0 -and
      $journalFile.Name -ceq ('transaction-' + [string]$journal.transactionId + '.json')
    ) -Message 'transaction journal schema, identity, sequence, filename or target changed.'
    foreach ($timestampName in @('preparedUtc', 'committedUtc', 'reconciledUtc')) {
      if ($null -ne $journal.$timestampName) {
        $canonicalTimestamp = ConvertTo-C34LCanonicalUtcTimestamp `
          $journal.$timestampName "transaction $timestampName"
        Assert-C34LRawJsonUtcToken $journalText $timestampName `
          $canonicalTimestamp "transaction $timestampName"
        $journal.$timestampName = $canonicalTimestamp
      }
    }
    if ($null -ne $journal.browserEvidence) {
      $journal.browserEvidence = ConvertTo-C34LNormalizedBrowserBinding `
        $journal.browserEvidence 'journal browser evidence'
      Assert-C34LRawJsonUtcToken $journalText 'browserEvidenceProducedUtc' `
        ([string]$journal.browserEvidence.browserEvidenceProducedUtc) `
        'journal browser producedUtc'
      Assert-C34LRawJsonUtcToken $journalText 'browserEvidenceExpiresUtc' `
        ([string]$journal.browserEvidence.browserEvidenceExpiresUtc) `
        'journal browser expiresUtc'
    }
    $journalStatus = [string]$journal.status
    Assert-C34LTransition -Condition (
      $journalStatus -in @('prepared', 'committed', 'reconciled_committed')
    ) `
      -Message 'transaction journal has an unknown nonterminal status.'
    $stateBefore = $utf8.GetString([Convert]::FromBase64String([string]$journal.stateBeforeBase64))
    $stateAfter = $utf8.GetString([Convert]::FromBase64String([string]$journal.stateAfterBase64))
    $aggregateBefore = $utf8.GetString([Convert]::FromBase64String([string]$journal.aggregateBeforeBase64))
    $aggregateAfter = $utf8.GetString([Convert]::FromBase64String([string]$journal.aggregateAfterBase64))
    Assert-C34LTransition -Condition (
      (Get-C34LTextSha256 $stateBefore) -ceq [string]$journal.stateBeforeSha256 -and
      (Get-C34LTextSha256 $stateAfter) -ceq [string]$journal.stateAfterSha256 -and
      (Get-C34LTextSha256 $aggregateBefore) -ceq [string]$journal.aggregateBeforeSha256 -and
      (Get-C34LTextSha256 $aggregateAfter) -ceq [string]$journal.aggregateAfterSha256
    ) -Message 'transaction journal payload hash changed.'
    $stateBeforeObject = $stateBefore | ConvertFrom-Json
    $aggregateBeforeObject = $aggregateBefore | ConvertFrom-Json
    $stateAfterObject = $stateAfter | ConvertFrom-Json
    $aggregateAfterObject = $aggregateAfter | ConvertFrom-Json
    Assert-C34LIdentityAndParity $stateBeforeObject $aggregateBeforeObject
    Assert-C34LIdentityAndParity $stateAfterObject $aggregateAfterObject
    $preparedInstant = ConvertTo-C34LUtcInstant `
      $journal.preparedUtc 'transaction preparedUtc'
    Assert-C34LJournalFinalEvidence -Journal $journal `
      -StateBefore $stateBeforeObject -AggregateBefore $aggregateBeforeObject `
      -StateAfter $stateAfterObject -ValidationInstantUtc $preparedInstant
    $validatedPrerequisiteProof = Read-C34LValidatedPrerequisiteProof `
      -Path ([string]$journal.prerequisiteGateEvidencePath) `
      -Sha256 ([string]$journal.prerequisiteGateEvidenceSha256) `
      -ExpectedAttempt ([int]$journal.attempt) `
      -ExpectedTransition ([string]$journal.transition) `
      -ExpectedPhase ([string]$journal.prerequisiteGatePhase) `
      -ExpectedStateSha256 ([string]$journal.stateBeforeSha256) `
      -ExpectedAggregateSha256 ([string]$journal.aggregateBeforeSha256) `
      -PreState $stateBeforeObject -PreAggregate $aggregateBeforeObject `
      -ValidationInstantUtc $preparedInstant
    Assert-C34LPostimageProofHistory -Journal $journal `
      -StateBefore $stateBeforeObject -AggregateBefore $aggregateBeforeObject `
      -StateAfter $stateAfterObject -AggregateAfter $aggregateAfterObject `
      -PrerequisiteProof $validatedPrerequisiteProof
    if ($journalStatus -ceq 'prepared') {
      Assert-C34LTransition -Condition (
        [string]::IsNullOrWhiteSpace([string]$journal.committedUtc) -and
        [string]::IsNullOrWhiteSpace([string]$journal.reconciledUtc) -and
        [string]::IsNullOrWhiteSpace([string]$journal.observedStateSha256) -and
        [string]::IsNullOrWhiteSpace([string]$journal.observedAggregateSha256)
      ) -Message 'prepared journal populated terminal-only fields.'
    } elseif ($journalStatus -ceq 'committed') {
      Assert-C34LTransition -Condition (
        -not [string]::IsNullOrWhiteSpace([string]$journal.committedUtc) -and
        [string]::IsNullOrWhiteSpace([string]$journal.reconciledUtc) -and
        [string]$journal.observedStateSha256 -ceq [string]$journal.stateAfterSha256 -and
        [string]$journal.observedAggregateSha256 -ceq
          [string]$journal.aggregateAfterSha256
      ) -Message 'committed journal terminal fields changed.'
    } else {
      Assert-C34LTransition -Condition (
        [string]::IsNullOrWhiteSpace([string]$journal.committedUtc) -and
        -not [string]::IsNullOrWhiteSpace([string]$journal.reconciledUtc) -and
        [string]$journal.observedStateSha256 -ceq [string]$journal.stateAfterSha256 -and
        [string]$journal.observedAggregateSha256 -ceq
          [string]$journal.aggregateAfterSha256
      ) -Message 'reconciled journal terminal fields changed.'
    }
    $journalRows += [pscustomobject]@{
      Sequence=[int]$journal.sequence; TransactionId=[string]$journal.transactionId
      File=$journalFile; Journal=$journal; Status=$journalStatus
      StateAfter=$stateAfter; AggregateAfter=$aggregateAfter
    }
  }
  $orderedRows = @($journalRows | Sort-Object Sequence)
  Assert-C34LTransition -Condition (
    @($orderedRows | Select-Object -ExpandProperty Sequence -Unique).Count -eq
      $orderedRows.Count -and
    @($orderedRows | Select-Object -ExpandProperty TransactionId -Unique).Count -eq
      $orderedRows.Count
  ) -Message 'transaction journal has duplicate sequence or transaction identity.'
  for ($index = 0; $index -lt $orderedRows.Count; $index++) {
    $row = $orderedRows[$index]
    Assert-C34LTransition -Condition ($row.Sequence -eq ($index + 1)) `
      -Message 'transaction journal sequence has a gap.'
    if ($index -gt 0) {
      $previous = $orderedRows[$index - 1].Journal
      Assert-C34LTransition -Condition (
        [string]$previous.stateAfterSha256 -ceq [string]$row.Journal.stateBeforeSha256 -and
        [string]$previous.aggregateAfterSha256 -ceq
          [string]$row.Journal.aggregateBeforeSha256
      ) -Message 'transaction journal chain has a fork or preimage gap.'
    }
    if ($index -lt ($orderedRows.Count - 1)) {
      Assert-C34LTransition -Condition (
        $row.Status -in @('committed', 'reconciled_committed')
      ) -Message 'transaction journal has an unreconciled nonterminal before the chain head.'
    }
  }
  $newest = $orderedRows[-1]
  $currentStateHash = Get-C34LFileSha256 $ExpectedStateFile
  $currentAggregateHash = Get-C34LFileSha256 $ExpectedAggregateFile
  if ($newest.Status -in @('committed', 'reconciled_committed')) {
    Assert-C34LTransition -Condition (
      $currentStateHash -ceq [string]$newest.Journal.stateAfterSha256 -and
      $currentAggregateHash -ceq [string]$newest.Journal.aggregateAfterSha256
    ) -Message 'newest committed transaction does not match current targets.'
    $terminalState = Get-Content -Raw -LiteralPath $ExpectedStateFile |
      ConvertFrom-Json
    $terminalAggregate = Get-Content -Raw -LiteralPath $ExpectedAggregateFile |
      ConvertFrom-Json
    $terminalHistoryCount = Get-C34LLifecycleHistoryCount `
      $terminalState $terminalAggregate 'terminal-journal'
    Assert-C34LTransition -Condition (
      $terminalHistoryCount -eq $orderedRows.Count
    ) -Message 'transaction journal file/history cardinality changed.'
    return 0
  }
  Assert-C34LTransition -Condition (
    $currentStateHash -in @(
      [string]$newest.Journal.stateBeforeSha256,
      [string]$newest.Journal.stateAfterSha256
    ) -and
    $currentAggregateHash -in @(
      [string]$newest.Journal.aggregateBeforeSha256,
      [string]$newest.Journal.aggregateAfterSha256
    )
  ) -Message 'newest nonterminal transaction targets match neither preimage nor postimage.'
  if ($currentStateHash -cne [string]$newest.Journal.stateAfterSha256) {
    Write-C34LAtomicText -Path $ExpectedStateFile -Text $newest.StateAfter
  }
  if ($currentAggregateHash -cne [string]$newest.Journal.aggregateAfterSha256) {
    Write-C34LAtomicText -Path $ExpectedAggregateFile -Text $newest.AggregateAfter
  }
  $newest.Journal.status = 'reconciled_committed'
  $newest.Journal.reconciledUtc = [DateTime]::UtcNow.ToString(
    $utcTimestampFormat,
    [Globalization.CultureInfo]::InvariantCulture
  )
  $newest.Journal.observedStateSha256 = Get-C34LFileSha256 $ExpectedStateFile
  $newest.Journal.observedAggregateSha256 = Get-C34LFileSha256 $ExpectedAggregateFile
  Write-C34LAtomicText -Path $newest.File.FullName `
    -Text (ConvertTo-C34LJson $newest.Journal)
  Assert-C34LTransition -Condition (
    (Get-C34LFileSha256 $ExpectedStateFile) -ceq
      [string]$newest.Journal.stateAfterSha256 -and
    (Get-C34LFileSha256 $ExpectedAggregateFile) -ceq
      [string]$newest.Journal.aggregateAfterSha256
  ) -Message 'newest nonterminal transaction remained unreconciled.'
  $reconciledState = Get-Content -Raw -LiteralPath $ExpectedStateFile |
    ConvertFrom-Json
  $reconciledAggregate = Get-Content -Raw -LiteralPath $ExpectedAggregateFile |
    ConvertFrom-Json
  $reconciledHistoryCount = Get-C34LLifecycleHistoryCount `
    $reconciledState $reconciledAggregate 'reconciled-journal'
  Assert-C34LTransition -Condition (
    $reconciledHistoryCount -eq $orderedRows.Count
  ) -Message 'transaction journal file/history cardinality changed.'
  return 1
}

$stateFile = Resolve-C34LRelativePath -Path $StatePath -Label 'detailed state'
if ($FixtureMode) {
  Initialize-C34LFixtureStateRunRoot -StateFile $stateFile
} else {
  $expectedRealState = Resolve-C34LRelativePath -Path $realStateRelative -Label 'real detailed state'
  Assert-C34LTransition -Condition (
    $stateFile.Equals($expectedRealState, [StringComparison]::OrdinalIgnoreCase)
  ) -Message 'nonfixture operation is restricted to the exact C34L detailed state.'
}
if ($InjectCrashBoundary -cne 'none') {
  Assert-C34LTransition -Condition ([bool]$FixtureMode) `
    -Message 'crash injection is confined to fixture mode.'
}

$stateBootstrap = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$aggregateFile = Resolve-C34LRelativePath -Path ([string]$stateBootstrap.aggregateStatePath) `
  -Label 'aggregate state'
if ($FixtureMode) {
  Assert-C34LFixturePath -Resolved $aggregateFile -Label 'fixture aggregate state'
} else {
  $expectedAggregate = Resolve-C34LRelativePath `
    -Path 'config/successor-aab-regression-hard-gate-aggregate-c34l.json' `
    -Label 'real aggregate state'
  Assert-C34LTransition -Condition (
    $aggregateFile.Equals($expectedAggregate, [StringComparison]::OrdinalIgnoreCase)
  ) -Message 'real aggregate target changed.'
}
$journalRoot = Get-C34LJournalRoot -State $stateBootstrap -StateFile $stateFile
if ($ReconcileOnly) {
  $reconcileBrowserParameters = @($browserInvocationParameterNames | Where-Object {
    $PSBoundParameters.ContainsKey($_)
  }).Count
  Assert-C34LTransition -Condition ($reconcileBrowserParameters -eq 0) `
    -Message 'browser invocation metadata is forbidden for reconcile-only.'
}
$reconciledCount = Complete-C34LJournalReconciliation -JournalRoot $journalRoot `
  -ExpectedStateFile $stateFile -ExpectedAggregateFile $aggregateFile
if ($ReconcileOnly) {
  Write-Output "C34L transaction reconciliation passed: reconciled=$reconciledCount."
  exit 0
}
Assert-C34LTransition -Condition (-not [string]::IsNullOrWhiteSpace($Transition)) `
  -Message 'transition is required unless reconcile-only is selected.'

$stateOriginal = [IO.File]::ReadAllText($stateFile)
$aggregateOriginal = [IO.File]::ReadAllText($aggregateFile)
$state = $stateOriginal | ConvertFrom-Json
$aggregate = $aggregateOriginal | ConvertFrom-Json
Assert-C34LIdentityAndParity -State $state -Aggregate $aggregate

$proofCountNames = @(
  'build', 'upload', 'install', 'deviceAcceptance', 'passwordlessEmailSend',
  'realSmsSend', 'otherTrack', 'backendHostingProviderOrProductionDeployment'
)
$proofAuthorityNames = @(
  'build', 'uploadAndInternalActivation', 'inPlaceOppoPlayUpdate',
  'postinstallAcceptance'
)
$boundBrowserParameterCount = @($browserInvocationParameterNames | Where-Object {
  $PSBoundParameters.ContainsKey($_)
}).Count
if ($Transition -ceq 'upload-authorized') {
  Assert-C34LTransition -Condition (
    $boundBrowserParameterCount -eq $browserInvocationParameterNames.Count -and
    [bool]$LiveBrowserRouteQualified -and
    [bool]$SignedInMoolSocialAppRouteProved -and
    [bool]$InternalTestingRouteProved -and
    [bool]$NoPlayWritePerformed
  ) -Message 'upload-authorized requires the complete browser invocation binding.'
} else {
  Assert-C34LTransition -Condition ($boundBrowserParameterCount -eq 0) `
    -Message 'browser invocation metadata is forbidden for this transition.'
}
$preStateSha256 = Get-C34LFileSha256 $stateFile
$preAggregateSha256 = Get-C34LFileSha256 $aggregateFile
$proof = Read-C34LValidatedPrerequisiteProof `
  -Path $PrerequisiteGateEvidencePath `
  -Sha256 $PrerequisiteGateEvidenceSha256 `
  -ExpectedAttempt $Attempt `
  -ExpectedTransition $Transition `
  -ExpectedPhase $PrerequisiteGatePhase `
  -ExpectedStateSha256 $preStateSha256 `
  -ExpectedAggregateSha256 $preAggregateSha256 `
  -PreState $state -PreAggregate $aggregate `
  -ValidationInstantUtc ([DateTimeOffset]::UtcNow)

$browserBinding = $null
if ($Transition -ceq 'upload-authorized') {
  $browserBinding = [pscustomobject][ordered]@{
    browserEvidencePath = $BrowserEvidencePath
    browserEvidenceSha256 = $BrowserEvidenceSha256
    browserEvidenceBytes = $BrowserEvidenceBytes
    browserEvidenceAttempt = $Attempt
    browserEvidenceTransition = $Transition
    browserEvidencePhase = $PrerequisiteGatePhase
    browserEvidencePreStateSha256 = $preStateSha256
    browserEvidencePreAggregateSha256 = $preAggregateSha256
    browserSessionId = $BrowserSessionId
    browserSessionNonceSha256 = $BrowserSessionNonceSha256
    browserEvidenceProducerId = $BrowserEvidenceProducerId
    browserEvidenceProducedUtc = $BrowserEvidenceProducedUtc
    browserEvidenceExpiresUtc = $BrowserEvidenceExpiresUtc
    sourceManifestPath = $SourceManifestPath
    sourceManifestSha256 = $SourceManifestSha256
    sourceManifestBytes = $SourceManifestBytes
    blockerLedgerPath = $BlockerLedgerPath
    blockerLedgerSha256 = $BlockerLedgerSha256
    blockerLedgerBytes = $BlockerLedgerBytes
    liveBrowserRouteQualified = [bool]$LiveBrowserRouteQualified
    signedInMoolSocialAppRouteProved = [bool]$SignedInMoolSocialAppRouteProved
    internalTestingRouteProved = [bool]$InternalTestingRouteProved
    noPlayWritePerformed = [bool]$NoPlayWritePerformed
  }
  Assert-C34LTransition -Condition (
    (ConvertTo-Json -InputObject $browserBinding -Depth 20 -Compress) -ceq
      (ConvertTo-Json -InputObject $proof.browserEvidence -Depth 20 -Compress)
  ) -Message 'browser invocation and prerequisite proof binding changed.'
}

$phaseByTransition = @{
  'founder-inputs-validated' = 'preprompt'
  'prebuild-failed' = 'prebuild'
  'build-start' = 'build'
  'build-failed' = 'build'
  'build-succeeded' = 'build'
  'upload-authorized' = 'preupload'
  'upload-succeeded' = 'postupload'
  'install-authorized' = 'postupload'
  'install-succeeded' = 'postinstall'
  'device-accepted' = 'journey'
  'reject' = 'rejection'
}
Assert-C34LTransition -Condition (
  [string]$PrerequisiteGatePhase -ceq [string]$phaseByTransition[$Transition]
) -Message 'transition prerequisite phase changed.'

$evidenceValidationInstant = [DateTimeOffset]::UtcNow
if ($Transition -ceq 'upload-succeeded') {
  Assert-C34LPlayFinalEvidence -State $state -Aggregate $aggregate `
    -Path $EvidencePath -Sha256 $EvidenceSha256 -Bytes $EvidenceBytes `
    -ExpectedStateSha256 $preStateSha256 `
    -ExpectedAggregateSha256 $preAggregateSha256 `
    -ValidationInstantUtc $evidenceValidationInstant
} elseif ($Transition -ceq 'install-succeeded') {
  Assert-C34LOppoFinalEvidence -State $state -Aggregate $aggregate `
    -ColdPath $EvidencePath -ColdSha256 $EvidenceSha256 `
    -ColdBytes $EvidenceBytes -RetainedPath $RetainedDataEvidencePath `
    -RetainedSha256 $RetainedDataEvidenceSha256 `
    -RetainedBytes $RetainedDataEvidenceBytes `
    -ExpectedStateSha256 $preStateSha256 `
    -ExpectedAggregateSha256 $preAggregateSha256 `
    -ValidationInstantUtc $evidenceValidationInstant
} elseif ($Transition -ceq 'device-accepted') {
  Assert-C34LJourneyFinalEvidence -State $state -Aggregate $aggregate `
    -Path $EvidencePath -Sha256 $EvidenceSha256 -Bytes $EvidenceBytes `
    -ExpectedStateSha256 $preStateSha256 `
    -ExpectedAggregateSha256 $preAggregateSha256 `
    -ValidationInstantUtc $evidenceValidationInstant
}

$zeroCounts = @(0, 0, 0, 0, 0, 0, 0, 0)
$held = @(
  'available_once', 'held_postbuild_qualification',
  'held_postupload_qualification', 'held_postinstall_journey_qualification'
)
$buildConsumed = @(
  'consumed', 'held_postbuild_qualification',
  'held_postupload_qualification', 'held_postinstall_journey_qualification'
)
switch ($Transition) {
  'founder-inputs-validated' {
    Assert-C34LVector $state $zeroCounts $held 'founder-input'
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq
        'source_regression_memory_two_identical_cycles_qualified_founder_prompt_required' -and
      [string]$state.buildAuthorization -ceq 'available_once' -and
      [bool]$state.authority.founderHiddenInputEntryAuthorized -and
      -not [bool]$state.founderAuthorization.hiddenFounderInputsEntered
    ) -Message 'founder-input preconditions changed.'
    $state.founderAuthorization.hiddenFounderInputsEntered = $true
    $state.authority.founderHiddenInputEntryAuthorized = $false
    $state.runtimeConfiguration.secretDefineFileQualifiedByFounder = $true
    $state.runtimeConfiguration.googleServicesFileQualifiedByFounder = $true
    $state.runtimeConfiguration.googleServerClientIdQualifiedByFounder = $true
    Set-C34LMachine $state $aggregate 'founder_inputs_validated_single_aab_build_required'
  }
  'prebuild-failed' {
    Assert-C34LVector $state $zeroCounts $held 'prebuild-failure'
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq 'founder_inputs_validated_single_aab_build_required' -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath) -and
      -not [string]::IsNullOrWhiteSpace($FailureStage)
    ) -Message 'prebuild-failure preconditions changed.'
    Set-C34LMachine $state $aggregate 'founder_inputs_validated_prebuild_failed_successor_required'
    Set-C34LRejected $state $aggregate
  }
  'build-start' {
    Assert-C34LVector $state $zeroCounts $held 'build-start'
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq 'founder_inputs_validated_single_aab_build_required' -and
      [string]$state.buildAuthorization -ceq 'available_once' -and
      [bool]$state.founderAuthorization.hiddenFounderInputsEntered
    ) -Message 'build-start preconditions changed.'
    $value = 'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
    Set-C34LMachine $state $aggregate $value
    $state.buildAuthorization = 'consumed'
    $state.releaseAuthorities.build = 'consumed'
    $aggregate.releaseAuthorities.build = 'consumed'
    $state.actionCounts.build = 1; $aggregate.actionCounts.build = 1
    $aggregate.candidate.buildCount = 1
    $state.buildResult.state = $value; $state.buildResult.buildCount = 1
    $state.buildResult.wrapperInvocationCount = 1; $state.buildResult.configOnlyCount = 1
  }
  'build-failed' {
    Assert-C34LVector $state @(1,0,0,0,0,0,0,0) $buildConsumed 'build-failure'
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq
        'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed' -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath) -and
      -not [string]::IsNullOrWhiteSpace($FailureStage)
    ) -Message 'build-failure preconditions or failure stage changed.'
    $value = 'single_release_AAB_failed_authority_consumed_successor_required'
    Set-C34LMachine $state $aggregate $value; $state.buildResult.state = $value
    Set-C34LRejected $state $aggregate
  }
  'build-succeeded' {
    Assert-C34LVector $state @(1,0,0,0,0,0,0,0) $buildConsumed 'build-success'
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq
        'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed' -and
      [string]$ArtifactSha256 -cmatch '^[0-9A-F]{64}$' -and
      [string]$UploadSignerSha256 -cmatch '^[0-9A-F]{64}$' -and
      $ArtifactBytes -gt 0 -and
      -not [string]::IsNullOrWhiteSpace($ArtifactPath) -and
      -not [string]::IsNullOrWhiteSpace($ArtifactProvenance)
    ) -Message 'build-success identity or preconditions changed.'
    $artifactFile = Resolve-C34LRelativePath $ArtifactPath 'sealed AAB'
    $provenanceFile = Resolve-C34LRelativePath $ArtifactProvenance 'AAB provenance'
    if ($FixtureMode) {
      Assert-C34LFixturePath $artifactFile 'fixture AAB'
      Assert-C34LFixturePath $provenanceFile 'fixture provenance'
    }
    Assert-C34LTransition -Condition (
      (Get-C34LFileSha256 $artifactFile) -ceq $ArtifactSha256 -and
      (Get-Item -LiteralPath $artifactFile).Length -eq $ArtifactBytes
    ) -Message 'sealed AAB bytes changed.'
    $value = 'single_release_AAB_succeeded_authority_consumed'
    Set-C34LMachine $state $aggregate $value; $state.buildResult.state = $value
    $state.buildResult.artifactPath = $ArtifactPath
    $state.buildResult.artifactSha256 = $ArtifactSha256
    $state.buildResult.artifactBytes = $ArtifactBytes
    $state.buildResult.uploadSignerSha256 = $UploadSignerSha256
    $state.buildResult.provenance = $ArtifactProvenance
    foreach ($name in @(
      'packageVersionManifestProved', 'googleAppIdResourceProved',
      'crashlyticsBuildIdResourceProved', 'splitAndArm64PayloadProved',
      'mergedReleaseManifestProved'
    )) { $state.buildResult.$name = $true }
    $aggregate.candidate.aabSha256 = $ArtifactSha256
    $state.candidate.artifactReusable = $true; $aggregate.candidate.artifactReusable = $true
  }
  'upload-authorized' {
    Assert-C34LVector $state @(1,0,0,0,0,0,0,0) $buildConsumed 'upload-authority'
    Assert-C34LBrowserWorkflowUnbound $state $aggregate
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq 'single_release_AAB_succeeded_authority_consumed' -and
      [bool]$state.candidate.artifactReusable
    ) -Message 'upload authority preconditions changed.'
    Set-C34LBrowserWorkflowBinding $state $aggregate $browserBinding
    $value = 'postbuild_qualified_internal_testing_upload_authority_available_once'
    Set-C34LMachine $state $aggregate $value
    $state.uploadAuthorization = 'available_once'
    $state.releaseAuthorities.uploadAndInternalActivation = 'available_once'
    $aggregate.releaseAuthorities.uploadAndInternalActivation = 'available_once'
  }
  'upload-succeeded' {
    $vector = @('consumed','available_once','held_postupload_qualification','held_postinstall_journey_qualification')
    Assert-C34LVector $state @(1,0,0,0,0,0,0,0) $vector 'upload-success'
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq
        'postbuild_qualified_internal_testing_upload_authority_available_once' -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath)
    ) -Message 'upload-success preconditions changed.'
    $value = 'internal_testing_upload_activation_succeeded_authority_consumed'
    Set-C34LMachine $state $aggregate $value
    $state.uploadAuthorization = 'consumed'
    $state.releaseAuthorities.uploadAndInternalActivation = 'consumed'
    $aggregate.releaseAuthorities.uploadAndInternalActivation = 'consumed'
    $state.actionCounts.upload = 1; $aggregate.actionCounts.upload = 1
    $aggregate.candidate.uploadCount = 1
    $state.playResult.uploadCount = 1; $state.playResult.internalActivationCount = 1
    $state.playResult.evidencePath = $EvidencePath
    $state.playResult.evidenceSha256 = $EvidenceSha256
    $state.playResult.evidenceBytes = $EvidenceBytes
  }
  'install-authorized' {
    $vector = @('consumed','consumed','held_postupload_qualification','held_postinstall_journey_qualification')
    Assert-C34LVector $state @(1,1,0,0,0,0,0,0) $vector 'install-authority'
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq
        'internal_testing_upload_activation_succeeded_authority_consumed'
    ) -Message 'install authority preconditions changed.'
    $value = 'postupload_qualified_in_place_oppo_play_update_authority_available_once'
    Set-C34LMachine $state $aggregate $value
    $state.installAuthorization = 'available_once'
    $state.releaseAuthorities.inPlaceOppoPlayUpdate = 'available_once'
    $aggregate.releaseAuthorities.inPlaceOppoPlayUpdate = 'available_once'
  }
  'install-succeeded' {
    $vector = @('consumed','consumed','available_once','held_postinstall_journey_qualification')
    Assert-C34LVector $state @(1,1,0,0,0,0,0,0) $vector 'install-success'
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq
        'postupload_qualified_in_place_oppo_play_update_authority_available_once' -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath)
    ) -Message 'install-success preconditions changed.'
    $value = 'oppo_play_in_place_update_succeeded_postinstall_acceptance_held'
    Set-C34LMachine $state $aggregate $value
    $state.installAuthorization = 'consumed'
    $state.releaseAuthorities.inPlaceOppoPlayUpdate = 'consumed'
    $aggregate.releaseAuthorities.inPlaceOppoPlayUpdate = 'consumed'
    $state.actionCounts.install = 1; $aggregate.actionCounts.install = 1
    $aggregate.candidate.installCount = 1
    $state.installResult.installCount = 1
    $state.installResult.coldStartEvidencePath = $EvidencePath
    $state.installResult.coldStartEvidenceSha256 = $EvidenceSha256
    $state.installResult.coldStartEvidenceBytes = $EvidenceBytes
    $state.installResult.retainedDataEvidencePath = $RetainedDataEvidencePath
    $state.installResult.retainedDataEvidenceSha256 = $RetainedDataEvidenceSha256
    $state.installResult.retainedDataEvidenceBytes = $RetainedDataEvidenceBytes
  }
  'device-accepted' {
    $vector = @('consumed','consumed','consumed','held_postinstall_journey_qualification')
    Assert-C34LVector $state @(1,1,1,0,0,0,0,0) $vector 'device-acceptance'
    Assert-C34LTransition -Condition (
      [string]$state.machineState -ceq
        'oppo_play_in_place_update_succeeded_postinstall_acceptance_held' -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath)
    ) -Message 'device acceptance preconditions changed.'
    $value = 'internal_testing_oppo_device_acceptance_succeeded'
    Set-C34LMachine $state $aggregate $value
    $state.deviceAuthorization = 'consumed'
    $state.releaseAuthorities.postinstallAcceptance = 'consumed'
    $aggregate.releaseAuthorities.postinstallAcceptance = 'consumed'
    $state.actionCounts.deviceAcceptance = 1; $aggregate.actionCounts.deviceAcceptance = 1
    $aggregate.candidate.deviceAcceptanceCount = 1
    $state.installResult.journeyEvidencePath = $EvidencePath
    $state.installResult.journeyEvidenceSha256 = $EvidenceSha256
    $state.installResult.journeyEvidenceBytes = $EvidenceBytes
    $state.installResult.acceptanceSucceeded = $true
    $state.candidate.artifactReusable = $false; $aggregate.candidate.artifactReusable = $false
  }
  'reject' {
    Assert-C34LTransition -Condition (
      $RejectionMachineState -cmatch '^.+_successor_required$' -and
      $RejectionRegistryId -cmatch '^REG-[0-9]{8}-[0-9]+-.+$' -and
      -not [string]::IsNullOrWhiteSpace($EvidencePath)
    ) -Message 'rejection identity or evidence changed.'
    Set-C34LMachine $state $aggregate $RejectionMachineState
    Set-C34LRejected $state $aggregate
  }
}

if ($Transition -in @(
  'prebuild-failed','build-failed','upload-succeeded','install-succeeded',
  'device-accepted','reject'
)) {
  $evidenceFile = Resolve-C34LRelativePath $EvidencePath 'transition evidence'
  if ($FixtureMode) { Assert-C34LFixturePath $evidenceFile 'fixture transition evidence' }
}
if ($Transition -ceq 'install-succeeded') {
  $retainedEvidenceFile = Resolve-C34LRelativePath $RetainedDataEvidencePath `
    'retained-data transition evidence'
  if ($FixtureMode) {
    Assert-C34LFixturePath $retainedEvidenceFile 'fixture retained-data transition evidence'
  }
}

if ($Transition -in @('prebuild-failed','build-failed','reject')) {
  $reason = if ($Transition -ceq 'reject') { @($RejectionRegistryId) } else { @() }
  $rejection = [ordered]@{
    disposition = 'rejected'; reasonRegistryIds = $reason
    reason = if ($Transition -ceq 'build-failed') {
      'single_release_AAB_post_start_failure'
    } elseif ($Transition -ceq 'prebuild-failed') {
      'founder_inputs_validated_prebuild_failure'
    } else { 'registered_release_lifecycle_rejection' }
    failureStage = $FailureStage; evidencePath = $EvidencePath
    artifactReusable = $false; successorRequired = $true
    buildCount = [int]$state.actionCounts.build
    uploadCount = [int]$state.actionCounts.upload
    installCount = [int]$state.actionCounts.install
    deviceAcceptanceCount = [int]$state.actionCounts.deviceAcceptance
  }
  $state.rejection = [pscustomobject]$rejection
  $aggregate.rejection = [pscustomobject]$rejection
}

$proofEvidencePath = if ($Transition -in @(
  'upload-succeeded','install-succeeded','device-accepted'
)) { $EvidencePath } else { $PrerequisiteGateEvidencePath }
$proofEvidenceSha256 = if ($Transition -in @(
  'upload-succeeded','install-succeeded','device-accepted'
)) { $EvidenceSha256 } else { $PrerequisiteGateEvidenceSha256 }
$priorProofHistory = @()
if ($null -ne $state.PSObject.Properties['lifecycleTransactionProofs']) {
  $priorProofHistory = @($state.lifecycleTransactionProofs)
}
if ($Transition -in @('upload-succeeded','install-succeeded','device-accepted')) {
  Assert-C34LTransition -Condition (
    @($priorProofHistory | Where-Object {
      [string]$_.evidencePath -ceq [string]$proofEvidencePath -or
      [string]$_.sha256 -ceq [string]$proofEvidenceSha256
    }).Count -eq 0
  ) -Message 'final transition evidence was replayed from prior lifecycle history.'
}
$proofRecord = [pscustomobject][ordered]@{
  ticketId = $ticketId; attempt = $Attempt
  transition = $Transition; phase = $PrerequisiteGatePhase
  evidencePath = $proofEvidencePath
  sha256 = $proofEvidenceSha256
  preStateSha256 = Get-C34LFileSha256 $stateFile
  preAggregateSha256 = Get-C34LFileSha256 $aggregateFile
  actionCounts = $proof.actionCounts
  releaseAuthorities = $proof.releaseAuthorities
  browserEvidence = $browserBinding
}
foreach ($target in @($state, $aggregate)) {
  $records = @()
  if ($null -ne $target.PSObject.Properties['lifecycleTransactionProofs']) {
    $records = @($target.lifecycleTransactionProofs)
  }
  Set-C34LProperty $target 'lifecycleTransactionProofs' @($records + $proofRecord)
}
Assert-C34LIdentityAndParity -State $state -Aggregate $aggregate
$stateAfter = ConvertTo-C34LJson $state
$aggregateAfter = ConvertTo-C34LJson $aggregate
[void]($stateAfter | ConvertFrom-Json); [void]($aggregateAfter | ConvertFrom-Json)

if ($InjectCrashBoundary -ceq 'before-journal-write') {
  throw 'C34L fixture injected crash before journal write.'
}
if (-not (Test-Path -LiteralPath $journalRoot -PathType Container)) {
  [void](New-Item -ItemType Directory -Path $journalRoot -Force)
}
$transactionId = [Guid]::NewGuid().ToString('N')
$proofHistoryCount = Get-C34LLifecycleHistoryCount `
  $state $aggregate 'prepared-transaction'
$existingJournalCount = @(
  Get-ChildItem -LiteralPath $journalRoot -Filter '*.json' -File
).Count
Assert-C34LTransition -Condition (
  $existingJournalCount -eq ($proofHistoryCount - 1)
) -Message 'transaction journal file/history cardinality changed before append.'
$sequence = $proofHistoryCount
$relativeAggregate = ConvertTo-C34LRepositoryRelativePath $aggregateFile `
  'transaction aggregate target'
$journal = [pscustomobject][ordered]@{
  schemaVersion = 1; contractId = $contractId; ticketId = $ticketId
  attempt = $Attempt; transactionId = $transactionId; sequence = $sequence
  transition = $Transition; status = 'prepared'
  statePath = $StatePath; aggregateStatePath = $relativeAggregate
  prerequisiteGateEvidencePath = $PrerequisiteGateEvidencePath
  prerequisiteGateEvidenceSha256 = $PrerequisiteGateEvidenceSha256
  prerequisiteGatePhase = $PrerequisiteGatePhase
  browserEvidence = $browserBinding
  stateBeforeSha256 = Get-C34LTextSha256 $stateOriginal
  aggregateBeforeSha256 = Get-C34LTextSha256 $aggregateOriginal
  stateAfterSha256 = Get-C34LTextSha256 $stateAfter
  aggregateAfterSha256 = Get-C34LTextSha256 $aggregateAfter
  stateBeforeBase64 = [Convert]::ToBase64String($utf8.GetBytes($stateOriginal))
  aggregateBeforeBase64 = [Convert]::ToBase64String($utf8.GetBytes($aggregateOriginal))
  stateAfterBase64 = [Convert]::ToBase64String($utf8.GetBytes($stateAfter))
  aggregateAfterBase64 = [Convert]::ToBase64String($utf8.GetBytes($aggregateAfter))
  preparedUtc = [DateTime]::UtcNow.ToString(
    $utcTimestampFormat,
    [Globalization.CultureInfo]::InvariantCulture
  )
  committedUtc = $null
  reconciledUtc = $null
  observedStateSha256 = $null
  observedAggregateSha256 = $null
}
$journalFile = Join-Path $journalRoot ("transaction-$transactionId.json")
Write-C34LAtomicText $journalFile (ConvertTo-C34LJson $journal)
if ($InjectCrashBoundary -ceq 'after-journal-write') {
  throw 'C34L fixture injected crash after journal write.'
}
Write-C34LAtomicText $stateFile $stateAfter
if ($InjectCrashBoundary -ceq 'after-detailed-replace') {
  throw 'C34L fixture injected crash after detailed replace.'
}
Write-C34LAtomicText $aggregateFile $aggregateAfter
if ($InjectCrashBoundary -ceq 'after-aggregate-replace') {
  throw 'C34L fixture injected crash after aggregate replace.'
}
$journal.status = 'committed'
$journal.committedUtc = [DateTime]::UtcNow.ToString(
  $utcTimestampFormat,
  [Globalization.CultureInfo]::InvariantCulture
)
$journal.observedStateSha256 = Get-C34LFileSha256 $stateFile
$journal.observedAggregateSha256 = Get-C34LFileSha256 $aggregateFile
Write-C34LAtomicText $journalFile (ConvertTo-C34LJson $journal)
if ($InjectCrashBoundary -ceq 'after-journal-commit') {
  throw 'C34L fixture injected crash after journal commit.'
}

Write-Output (
  "C34L lifecycle transaction passed: transition=$Transition; " +
  "state=$($state.machineState); counts=$($state.actionCounts.build)/" +
  "$($state.actionCounts.upload)/$($state.actionCounts.install)/" +
  "$($state.actionCounts.deviceAcceptance); gate=$PrerequisiteGatePhase/" +
  "$PrerequisiteGateEvidenceSha256; journal=$transactionId; " +
  'detailedAggregateParity=true.'
)
