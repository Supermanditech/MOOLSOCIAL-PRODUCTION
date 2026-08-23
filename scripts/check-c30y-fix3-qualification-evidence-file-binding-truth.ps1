[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$SummaryPath,
  [ValidateSet(0, 1, 2)]
  [int]$ExpectedCycle = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$evidenceRelative = 'artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01'
$evidenceRoot = [IO.Path]::GetFullPath((Join-Path $root $evidenceRelative))

function Assert-C30YFix3 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30Y FIX3 evidence binding rejected: $Message"
  }
}

function Resolve-C30YFix3Path {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label,
    [switch]$AllowMissing
  )
  $candidate = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  }
  else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C30YFix3 -Condition (
    $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  if (-not $AllowMissing) {
    Assert-C30YFix3 -Condition (
      Test-Path -LiteralPath $candidate -PathType Leaf
    ) -Message "$Label is missing."
  }
  return $candidate
}

function ConvertTo-C30YFix3RelativePath {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $fullPath = [IO.Path]::GetFullPath($Path)
  Assert-C30YFix3 -Condition (
    $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  return $fullPath.Substring($prefix.Length).Replace('\', '/')
}

function Assert-C30YFix3ExitFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $lines = @(Get-Content -LiteralPath $Path)
  Assert-C30YFix3 -Condition (
    $lines.Count -eq 1 -and [string]$lines[0] -ceq '0'
  ) -Message "$Label does not contain the exact native exit code 0."
}

function Assert-C30YFix3ManifestCurrent {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][int]$ExpectedFiles
  )
  $lines = @(Get-Content -LiteralPath $Path)
  Assert-C30YFix3 -Condition ($lines.Count -eq $ExpectedFiles) `
    -Message 'source manifest file count changed.'
  $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach ($line in $lines) {
    Assert-C30YFix3 -Condition (
      [string]$line -cmatch '^([A-F0-9]{64})  (.+)$'
    ) -Message 'source manifest row shape changed.'
    $expectedHash = [string]$Matches[1]
    $relative = [string]$Matches[2]
    Assert-C30YFix3 -Condition ($seen.Add($relative)) `
      -Message "source manifest contains duplicate path: $relative"
    $owner = Resolve-C30YFix3Path -Path $relative -Label "manifest owner $relative"
    Assert-C30YFix3 -Condition (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq $expectedHash
    ) -Message "source manifest owner changed: $relative"
  }
}

function Assert-C30YFix3LogScalar {
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][string]$Pattern,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C30YFix3 -Condition ($Text -match $Pattern) `
    -Message "$Label scalar is missing or changed."
}

function Assert-C30YFix3Summary {
  param(
    [Parameter(Mandatory)][object]$Summary,
    [Parameter(Mandatory)][int]$Cycle,
    [switch]$Probe
  )
  $generation = [string]$Summary.qualificationGeneration
  $expectedRepairTicket = if ($generation -ceq 'post_C30Y_FIX3') {
    'UAW-C30Y-FIX3-QUALIFICATION-EVIDENCE-FILE-BINDING-TRUTH'
  }
  elseif ($generation -ceq 'post_C30Y_FIX4') {
    'UAW-C30Y-FIX4-C30X-NEGATIVE-BUILD-REJECTION-CLASSIFIER-TRUTH'
  }
  elseif ($generation -ceq 'post_C30Y_FIX5') {
    'UAW-C30Y-FIX5-FLUTTER-JSON-EVENT-SHAPE-CLASSIFIER-TRUTH'
  }
  else {
    ''
  }
  Assert-C30YFix3 -Condition (
    [string]$Summary.ticketId -ceq
      'UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE' -and
    -not [string]::IsNullOrWhiteSpace($expectedRepairTicket) -and
    [string]$Summary.repairTicket -ceq $expectedRepairTicket -and
    [int]$Summary.cycle -eq $Cycle -and
    [string]$Summary.state -ceq 'passed'
  ) -Message 'summary identity, cycle, generation or state changed.'

  $manifest = Resolve-C30YFix3Path `
    -Path ([string]$Summary.sourceManifest.path) `
    -Label 'source manifest'
  Assert-C30YFix3 -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $manifest).Hash -ceq
      [string]$Summary.sourceManifest.sha256 -and
    [bool]$Summary.sourceManifest.currentBefore -and
    [bool]$Summary.sourceManifest.currentAfter
  ) -Message 'source manifest seal or before/after truth changed.'
  Assert-C30YFix3ManifestCurrent `
    -Path $manifest `
    -ExpectedFiles ([int]$Summary.sourceManifest.files)

  $requiredGateProperties = @(
    'regressionMemory',
    'mvpScopeAndDeliveryLock',
    'approvedUiLocks',
    'screen03V4BothHosts',
    'c31cInheritedChat',
    'c30wReleaseRuntimeBothHosts',
    'wrapperStaticBothHosts',
    'fix2OrderBothHosts',
    'c30yFix1BothHosts',
    'c30yFix2BothHosts',
    'c30yFix3BothHosts',
    'c30yFix4BothHosts',
    'c30xUnauthorizedBuildRejected'
  )
  if ($generation -ceq 'post_C30Y_FIX5') {
    $requiredGateProperties += 'c30yFix5BothHosts'
  }
  foreach ($property in $requiredGateProperties) {
    $value = $Summary.gates.PSObject.Properties[$property]
    Assert-C30YFix3 -Condition (
      $null -ne $value -and [bool]$value.Value
    ) -Message "required gate result is not true: $property"
  }

  $evidenceProperties = @(
    @{ Name = 'staticLog'; Label = 'static gate log'; Exit = $false },
    @{ Name = 'staticExit'; Label = 'static gate exit'; Exit = $true },
    @{ Name = 'flutterLog'; Label = 'Flutter log'; Exit = $false },
    @{ Name = 'flutterExit'; Label = 'Flutter exit'; Exit = $true },
    @{ Name = 'analyzerLog'; Label = 'analyzer log'; Exit = $false },
    @{ Name = 'analyzerExit'; Label = 'analyzer exit'; Exit = $true },
    @{ Name = 'backendCompileLog'; Label = 'backend compile log'; Exit = $false },
    @{ Name = 'backendCompileExit'; Label = 'backend compile exit'; Exit = $true },
    @{ Name = 'backendTestLog'; Label = 'backend test log'; Exit = $false },
    @{ Name = 'backendTestExit'; Label = 'backend test exit'; Exit = $true },
    @{ Name = 'hostingLog'; Label = 'Hosting log'; Exit = $false },
    @{ Name = 'hostingExit'; Label = 'Hosting exit'; Exit = $true }
  )
  $resolved = @{}
  $unique = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
  )
  $generationSegment = switch ($generation) {
    'post_C30Y_FIX3' { 'post-fix3'; break }
    'post_C30Y_FIX4' { 'post-fix4'; break }
    'post_C30Y_FIX5' { 'post-fix5'; break }
    default { '' }
  }
  $cyclePrefix = "$evidenceRelative/c30y-$generationSegment-cycle-$($Cycle.ToString('00'))-"
  foreach ($entry in $evidenceProperties) {
    $property = $Summary.evidence.PSObject.Properties[[string]$entry.Name]
    Assert-C30YFix3 -Condition ($null -ne $property) `
      -Message "evidence property is missing: $($entry.Name)"
    $relative = [string]$property.Value
    if (-not $Probe) {
      Assert-C30YFix3 -Condition (
        $relative.StartsWith($cyclePrefix, [StringComparison]::Ordinal)
      ) -Message "$($entry.Label) is not owned by the exact cycle."
    }
    $path = Resolve-C30YFix3Path -Path $relative -Label ([string]$entry.Label)
    Assert-C30YFix3 -Condition ($unique.Add($path)) `
      -Message "evidence path was reused: $relative"
    $resolved[[string]$entry.Name] = $path
    if ([bool]$entry.Exit) {
      Assert-C30YFix3ExitFile -Path $path -Label ([string]$entry.Label)
    }
  }

  $staticText = [string](Get-Content -Raw -LiteralPath $resolved.staticLog)
  $requiredStaticSentinels = @(
    'C30Y_FIX3_STATIC_REGRESSION_MEMORY=passed',
    'C30Y_FIX3_STATIC_MVP_SCOPE=passed',
    'C30Y_FIX3_STATIC_APPROVED_UI=passed',
    'C30Y_FIX3_STATIC_SCREEN03_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_C31C=passed',
    'C30Y_FIX3_STATIC_C30W_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_WRAPPER_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX2_ORDER_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX1_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX2_TRANSACTION_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX3_EVIDENCE_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX4_CLASSIFIER_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_C30X_UNAUTHORIZED=passed'
  )
  if ($generation -ceq 'post_C30Y_FIX5') {
    $requiredStaticSentinels +=
      'C30Y_FIX3_STATIC_FIX5_CLASSIFIER_BOTH_HOSTS=passed'
  }
  foreach ($sentinel in $requiredStaticSentinels) {
    Assert-C30YFix3 -Condition (
      $staticText.IndexOf($sentinel, [StringComparison]::Ordinal) -ge 0
    ) -Message "static gate sentinel is missing: $sentinel"
  }

  $flutterText = [string](Get-Content -Raw -LiteralPath $resolved.flutterLog)
  Assert-C30YFix3LogScalar `
    -Text $flutterText `
    -Pattern 'authoritative_manifest_files=59 raw_test_done=479 authored_passed=417 authored_skipped=3 authored_failed=0 error_events=0 non_json_lines=0 flutter_exit=0' `
    -Label 'Flutter authoritative summary'
  if ($generation -ceq 'post_C30Y_FIX5') {
    Assert-C30YFix3LogScalar `
      -Text $flutterText `
      -Pattern 'untyped_json_objects=0' `
      -Label 'Flutter untyped JSON object summary'
  }
  Assert-C30YFix3 -Condition (
    [int]$Summary.flutter.manifestFiles -eq 59 -and
    [int]$Summary.flutter.rawTestDone -eq 479 -and
    [int]$Summary.flutter.authoredPassed -eq 417 -and
    [int]$Summary.flutter.declaredSkipped -eq 3 -and
    [int]$Summary.flutter.failed -eq 0 -and
    [int]$Summary.flutter.errorEvents -eq 0 -and
    [int]$Summary.flutter.nonJsonLines -eq 0 -and
    [int]$Summary.flutter.exitCode -eq 0
  ) -Message 'Flutter summary scalars changed.'
  if ($generation -ceq 'post_C30Y_FIX5') {
    Assert-C30YFix3 -Condition (
      $null -ne $Summary.flutter.PSObject.Properties['untypedJsonObjects'] -and
      [int]$Summary.flutter.untypedJsonObjects -eq 0
    ) -Message 'Flutter untyped JSON object summary scalar changed.'
  }

  $analyzerText = [string](Get-Content -Raw -LiteralPath $resolved.analyzerLog)
  Assert-C30YFix3LogScalar `
    -Text $analyzerText `
    -Pattern 'No issues found!' `
    -Label 'whole-mobile analyzer'
  Assert-C30YFix3 -Condition (
    [int]$Summary.flutter.analyzerIssues -eq 0
  ) -Message 'analyzer issue count changed.'

  $backendText = [string](Get-Content -Raw -LiteralPath $resolved.backendTestLog)
  Assert-C30YFix3LogScalar -Text $backendText -Pattern '(?m)^\s*(?:ℹ\s*)?tests\s+528\s*$' -Label 'backend tests'
  Assert-C30YFix3LogScalar -Text $backendText -Pattern '(?m)^\s*(?:ℹ\s*)?pass\s+528\s*$' -Label 'backend passes'
  Assert-C30YFix3LogScalar -Text $backendText -Pattern '(?m)^\s*(?:ℹ\s*)?fail\s+0\s*$' -Label 'backend failures'
  Assert-C30YFix3 -Condition (
    [bool]$Summary.backend.typecheckPassed -and
    [int]$Summary.backend.compiledTestFiles -eq 53 -and
    [int]$Summary.backend.tests -eq 528 -and
    [int]$Summary.backend.passed -eq 528 -and
    [int]$Summary.backend.failed -eq 0
  ) -Message 'backend summary scalars changed.'

  $hostingText = [string](Get-Content -Raw -LiteralPath $resolved.hostingLog)
  Assert-C30YFix3LogScalar -Text $hostingText -Pattern '(?m)^\s*(?:ℹ\s*)?tests\s+8\s*$' -Label 'Hosting tests'
  Assert-C30YFix3LogScalar -Text $hostingText -Pattern '(?m)^\s*(?:ℹ\s*)?pass\s+8\s*$' -Label 'Hosting passes'
  Assert-C30YFix3LogScalar -Text $hostingText -Pattern '(?m)^\s*(?:ℹ\s*)?fail\s+0\s*$' -Label 'Hosting failures'
  Assert-C30YFix3 -Condition (
    [int]$Summary.hosting.tests -eq 8 -and
    [int]$Summary.hosting.passed -eq 8 -and
    [int]$Summary.hosting.failed -eq 0
  ) -Message 'Hosting summary scalars changed.'

  Assert-C30YFix3 -Condition (
    [int]$Summary.releaseActions.builds -eq 0 -and
    [int]$Summary.releaseActions.uploads -eq 0 -and
    [int]$Summary.releaseActions.installs -eq 0 -and
    [int]$Summary.newIssues -eq 0 -and
    [int]$Summary.newDefects -eq 0
  ) -Message 'release actions, new issue count or new defect count is nonzero.'
}

$ticket = Get-Content -Raw -LiteralPath (
  Resolve-C30YFix3Path `
    -Path 'config/uaw-c30y-fix3-qualification-evidence-file-binding-truth-ticket.json' `
    -Label 'FIX3 ticket'
) | ConvertFrom-Json
Assert-C30YFix3 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C30Y-FIX3-QUALIFICATION-EVIDENCE-FILE-BINDING-TRUTH' -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceMutationAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX3 ticket identity or authority boundary changed.'

if ($SummaryPath) {
  Assert-C30YFix3 -Condition ($ExpectedCycle -in @(1, 2)) `
    -Message 'real summary validation requires ExpectedCycle 1 or 2.'
  $summaryFile = Resolve-C30YFix3Path -Path $SummaryPath -Label 'cycle summary'
  $summary = Get-Content -Raw -LiteralPath $summaryFile | ConvertFrom-Json
  Assert-C30YFix3Summary -Summary $summary -Cycle $ExpectedCycle
  Write-Output (
    'C30Y FIX3 qualification evidence binding passed: ' +
    "cycle=$ExpectedCycle; manifestFiles=$($summary.sourceManifest.files); " +
    'Flutter=417/3; analyzer=clean; backend=528; Hosting=8; releaseActions=0/0/0.'
  )
  exit 0
}

$probeParent = Join-Path $evidenceRoot 'c30y-fix3-evidence-binding-probes'
[void][IO.Directory]::CreateDirectory($probeParent)
$probe = Join-Path $probeParent ([guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($probe)
Assert-C30YFix3 -Condition (
  $probe.StartsWith(
    $probeParent + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  )
) -Message 'self-test probe escaped its exact parent.'

try {
  $probeFiles = @{}
  foreach ($name in @(
    'static.log', 'static.exit.txt',
    'flutter.log', 'flutter.exit.txt',
    'analyzer.log', 'analyzer.exit.txt',
    'backend-compile.log', 'backend-compile.exit.txt',
    'backend-tests.log', 'backend-tests.exit.txt',
    'hosting.log', 'hosting.exit.txt'
  )) {
    $probeFiles[$name] = Join-Path $probe $name
  }
  $staticSentinels = @(
    'C30Y_FIX3_STATIC_REGRESSION_MEMORY=passed',
    'C30Y_FIX3_STATIC_MVP_SCOPE=passed',
    'C30Y_FIX3_STATIC_APPROVED_UI=passed',
    'C30Y_FIX3_STATIC_SCREEN03_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_C31C=passed',
    'C30Y_FIX3_STATIC_C30W_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_WRAPPER_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX2_ORDER_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX1_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX2_TRANSACTION_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX3_EVIDENCE_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_FIX4_CLASSIFIER_BOTH_HOSTS=passed',
    'C30Y_FIX3_STATIC_C30X_UNAUTHORIZED=passed'
  )
  [IO.File]::WriteAllLines(
    $probeFiles['static.log'],
    $staticSentinels,
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText(
    $probeFiles['flutter.log'],
    'authoritative_manifest_files=59 raw_test_done=479 authored_passed=417 authored_skipped=3 authored_failed=0 error_events=0 non_json_lines=0 flutter_exit=0',
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText(
    $probeFiles['analyzer.log'],
    'No issues found!',
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText(
    $probeFiles['backend-compile.log'],
    '',
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText(
    $probeFiles['backend-tests.log'],
    "tests 528`npass 528`nfail 0",
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText(
    $probeFiles['hosting.log'],
    "tests 8`npass 8`nfail 0",
    [Text.UTF8Encoding]::new($false)
  )
  foreach ($name in @(
    'static.exit.txt', 'flutter.exit.txt', 'analyzer.exit.txt',
    'backend-compile.exit.txt', 'backend-tests.exit.txt', 'hosting.exit.txt'
  )) {
    [IO.File]::WriteAllText(
      $probeFiles[$name],
      "0`r`n",
      [Text.UTF8Encoding]::new($false)
    )
  }

  $probeOwnerRelative =
    'config/uaw-c30y-fix3-qualification-evidence-file-binding-truth-ticket.json'
  $probeOwner = Resolve-C30YFix3Path `
    -Path $probeOwnerRelative `
    -Label 'probe manifest owner'
  $probeManifest = Join-Path $probe 'source-manifest.txt'
  [IO.File]::WriteAllText(
    $probeManifest,
    "$((Get-FileHash -Algorithm SHA256 -LiteralPath $probeOwner).Hash)  " +
      "$probeOwnerRelative`n",
    [Text.UTF8Encoding]::new($false)
  )
  $probeManifestRelative = ConvertTo-C30YFix3RelativePath `
    -Path $probeManifest `
    -Label 'probe source manifest'
  $relativeEvidence = @{}
  foreach ($name in $probeFiles.Keys) {
    $relativeEvidence[$name] = ConvertTo-C30YFix3RelativePath `
      -Path $probeFiles[$name] `
      -Label "probe evidence $name"
  }
  $probeSummary = [ordered]@{
    schemaVersion = 1
    ticketId = 'UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
    repairTicket = 'UAW-C30Y-FIX3-QUALIFICATION-EVIDENCE-FILE-BINDING-TRUTH'
    cycle = 1
    qualificationGeneration = 'post_C30Y_FIX3'
    state = 'passed'
    sourceManifest = [ordered]@{
      path = $probeManifestRelative
      sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $probeManifest).Hash
      files = @(Get-Content -LiteralPath $probeManifest).Count
      currentBefore = $true
      currentAfter = $true
    }
    gates = [ordered]@{
      regressionMemory = $true
      mvpScopeAndDeliveryLock = $true
      approvedUiLocks = $true
      screen03V4BothHosts = $true
      c31cInheritedChat = $true
      c30wReleaseRuntimeBothHosts = $true
      wrapperStaticBothHosts = $true
      fix2OrderBothHosts = $true
      c30yFix1BothHosts = $true
      c30yFix2BothHosts = $true
      c30yFix3BothHosts = $true
      c30yFix4BothHosts = $true
      c30xUnauthorizedBuildRejected = $true
    }
    evidence = [ordered]@{
      staticLog = $relativeEvidence['static.log']
      staticExit = $relativeEvidence['static.exit.txt']
      flutterLog = $relativeEvidence['flutter.log']
      flutterExit = $relativeEvidence['flutter.exit.txt']
      analyzerLog = $relativeEvidence['analyzer.log']
      analyzerExit = $relativeEvidence['analyzer.exit.txt']
      backendCompileLog = $relativeEvidence['backend-compile.log']
      backendCompileExit = $relativeEvidence['backend-compile.exit.txt']
      backendTestLog = $relativeEvidence['backend-tests.log']
      backendTestExit = $relativeEvidence['backend-tests.exit.txt']
      hostingLog = $relativeEvidence['hosting.log']
      hostingExit = $relativeEvidence['hosting.exit.txt']
    }
    flutter = [ordered]@{
      manifestFiles = 59
      rawTestDone = 479
      authoredPassed = 417
      declaredSkipped = 3
      failed = 0
      errorEvents = 0
      nonJsonLines = 0
      exitCode = 0
      analyzerIssues = 0
    }
    backend = [ordered]@{
      typecheckPassed = $true
      compiledTestFiles = 53
      tests = 528
      passed = 528
      failed = 0
    }
    hosting = [ordered]@{ tests = 8; passed = 8; failed = 0 }
    releaseActions = [ordered]@{ builds = 0; uploads = 0; installs = 0 }
    newIssues = 0
    newDefects = 0
  }
  $positive = $probeSummary | ConvertTo-Json -Depth 12 | ConvertFrom-Json
  Assert-C30YFix3Summary -Summary $positive -Cycle 1 -Probe

  $negative = $probeSummary | ConvertTo-Json -Depth 12 | ConvertFrom-Json
  $negative.evidence.backendCompileLog = ConvertTo-C30YFix3RelativePath `
    -Path (Join-Path $probe 'missing-backend-compile.log') `
    -Label 'negative missing compile path'
  $missingCompileRejected = $false
  try {
    Assert-C30YFix3Summary -Summary $negative -Cycle 1 -Probe
  }
  catch {
    $missingCompileRejected =
      [string]$_.Exception.Message -like '*backend compile log is missing*'
  }
  Assert-C30YFix3 -Condition $missingCompileRejected `
    -Message 'negative missing backend compile evidence was not rejected.'
}
finally {
  if (Test-Path -LiteralPath $probe -PathType Container) {
    [IO.Directory]::Delete($probe, $true)
  }
}

Write-Output (
  'C30Y FIX3 qualification evidence binding contract passed: ' +
  'positiveProbe=true; missingCompileRejected=true; Flutter=417/3; ' +
  'analyzer=clean; backend=528; Hosting=8; releaseActions=0/0/0.'
)
