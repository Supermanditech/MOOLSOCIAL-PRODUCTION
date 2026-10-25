[CmdletBinding()]
param(
  [ValidateSet('general', 'implementation', 'build', 'device')]
  [string]$Phase = 'general',

  [ValidateSet('none', 'debug', 'profile', 'release')]
  [string]$BuildMode = 'none',

  [string]$RepositoryRoot,

  [string]$EvidenceArchiveRoot,

  [ValidateSet('none', 'attach', 'hotreload', 'hotrestart', 'inspect')]
  [string]$RuntimeAction = 'none',
  [string]$RuntimeContractPath,
  [string[]]$RuntimeArguments = @(),
  [int]$RuntimeProcessId = 0,
  [string]$RuntimeUiDumpPath,
  [string]$RuntimeLogPath,
  [string]$RuntimeExpectedScreen
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

# REG-20261023-4653, founder amendment 24 October: a draft preview must not
# qualify a different customer mapping, renderer, or personal persistence owner.
# Run real host regressions before device mutation/build; never inject fixtures
# into the phone or substitute a successful preview for publication readback.
function Assert-StorePublicPreviewParity {
  $flutter = Get-Command flutter -ErrorAction Stop
  $flutterBin = Split-Path -Parent $flutter.Source
  $dart = Join-Path $flutterBin 'cache/dart-sdk/bin/dart.exe'
  $runner = Join-Path $flutterBin 'cache/flutter_tools.snapshot'
  if (-not (Test-Path -LiteralPath $dart -PathType Leaf) -or
      -not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw 'Store/public parity gate requires the installed Flutter SDK runtime.'
  }
  $cases = @(
    'PUBLICPARITY Store submission and customer projection retail',
    'PUBLICPARITY Store submission and customer projection wholesale',
    'PUBLICPARITY Store submission and customer projection bulk',
    'PUBLICMAP preview inherits current Store context retail',
    'PUBLICMAP preview inherits current Store context wholesale',
    'PUBLICMAP preview inherits current Store context bulk',
    'PUBLICMAP unsupported trade preview is a safe unavailable state',
    'PUBLICMAP pending supplier photo never borrows category artwork',
    'PUBLICMAP Store address never crosses supplier identity',
    'PUBLICMAP original provider address reaches product and retires with source'
  )
  foreach ($scale in @('1.0', '2.0')) {
    $cases += "PUBLICMAP assurance controls fit card $scale"
    $cases += "PUBLICMAP pack tabs fit card $scale"
    $cases += "PUBLICMAP unavailable photo stays compact $scale"
  }
  foreach ($channel in @('retail', 'wholesale', 'bulk')) {
    foreach ($scale in @('1.0', '2.0')) { $cases += "PUBLICMAP descriptive fields fit $channel text$scale" }
  }
  $review = (Get-Content -Raw -LiteralPath (Join-Path $root 'docs/quality/LF-27-STORE-FEEDBACK-FRONTEND-20261016.json') -Encoding utf8 |
    ConvertFrom-Json).nativeRuntimeContract
  if ($null -eq $review -or $null -eq $review.defines) { throw 'Missing reviewed host-test configuration.' }
  $testArguments = @($runner, 'test', '--no-pub', '--concurrency=1', '--reporter=json',
    'test/work_workspace_layout_safety_test.dart',
    'test/work_catalogue_gateway_test.dart',
    'test/ui_v2/buy/buy_v2_product_content_test.dart', '--name=PUBLICPARITY|PUBLICMAP')
  foreach ($property in $review.defines.PSObject.Properties) { $testArguments += "--dart-define=$($property.Name)=$($property.Value)" }
  $receipt = Join-Path ([IO.Path]::GetTempPath()) ('moolsocial-preview-parity-' + [guid]::NewGuid().ToString('N') + '.jsonl')
  Push-Location (Join-Path $root 'apps/mobile')
  try {
    & $dart @testArguments *> $receipt
    $testExit = $LASTEXITCODE
  } finally { Pop-Location }
  $names = @{}; $passed = @{}; $done = $false
  foreach ($line in [IO.File]::ReadLines($receipt)) {
    try { $event = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
    if ($event.type -ceq 'testStart') { $names[[string]$event.test.id] = [string]$event.test.name }
    if ($event.type -ceq 'testDone' -and $event.result -ceq 'success' -and $event.skipped -eq $false) {
      $passed[[string]$event.testID] = $true
    }
    if ($event.type -ceq 'done' -and $event.success -eq $true) { $done = $true }
  }
  foreach ($case in $cases) {
    $matches = @($names.Keys | Where-Object { $names[$_] -ceq $case -and $passed.ContainsKey($_) })
    if ($matches.Count -ne 1) { throw "Store/public parity case missing, skipped or failed: $case. Evidence: $receipt" }
  }
  if ($testExit -ne 0 -or -not $done) { throw "Store/public parity tests failed. Evidence: $receipt" }
  Write-Output "Store/public preview parity passed: $($cases.Count) required cases; current-source host tests; receipt=$receipt"
}

# REG-20261023-4653: a passing registry read is not runtime qualification.
# Every debug device action names its reviewed launch contract; never infer
# evaluation defines from the installed APK or reuse an unverified attachment.
if ($Phase -eq 'device' -and $BuildMode -eq 'debug') {
  if ($RuntimeAction -eq 'none' -or -not $RuntimeContractPath) {
    throw 'REG-20261023-4653: debug device work requires an exact RuntimeAction and reviewed RuntimeContractPath.'
  }
  $contractFile = [IO.Path]::GetFullPath($RuntimeContractPath)
  if (-not (Test-Path -LiteralPath $contractFile -PathType Leaf)) { throw 'Runtime contract is missing.' }
  $contract = (Get-Content -Raw -LiteralPath $contractFile -Encoding utf8 | ConvertFrom-Json).nativeRuntimeContract
  if ($null -eq $contract -or $contract.schemaVersion -ne 1 -or
      $contract.profile -cnotin @('evaluation', 'production') -or
      [IO.Path]::GetFullPath([string]$contract.repositoryRoot).TrimEnd('\', '/') -ine $root.TrimEnd('\', '/') -or
      [string]::IsNullOrWhiteSpace([string]$contract.package) -or
      [string]::IsNullOrWhiteSpace([string]$contract.serial) -or
      [string]::IsNullOrWhiteSpace([string]$contract.entrypoint) -or
      [string]::IsNullOrWhiteSpace([string]$contract.candidateId)) { throw 'Runtime contract identity is incomplete or belongs to another checkout.' }
  if (-not [IO.Path]::IsPathRooted([string]$contract.entrypoint) -or
      -not [IO.Path]::GetFullPath([string]$contract.entrypoint).StartsWith($root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
      -not (Test-Path -LiteralPath $contract.entrypoint -PathType Leaf)) { throw 'Runtime entrypoint must be an existing absolute source path inside this checkout.' }
  if ($RuntimeAction -eq 'attach') {
    $arguments = @($RuntimeArguments)
  } else {
    if ($RuntimeProcessId -le 0) { throw 'Reload/restart/inspection requires the exact active Flutter attach process id.' }
    $runtimeProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$RuntimeProcessId" -ErrorAction Stop
    if ($null -eq $runtimeProcess -or $runtimeProcess.Name -notmatch '^dart(?:\.exe)?$') { throw 'Recorded Flutter attach process is no longer running.' }
    $arguments = @([regex]::Matches([string]$runtimeProcess.CommandLine, '(?:[^\s"]+|"[^"]*")+') |
      ForEach-Object { $_.Value.Trim('"') })
  }
  if ($arguments -cnotcontains 'attach' -or @($arguments | Where-Object { $_ -like '--dart-define-from-file*' }).Count) {
    throw 'Use an explicit Flutter attach command with reviewed defines; implicit define files are not accepted.'
  }
  if (@($arguments | Where-Object { $_ -cmatch '^--(?:no-)?(?:profile|release)(?:=|$)|^--debug=false$|^--no-debug$' }).Count) { throw 'The active attach mode is not the reviewed debug mode.' }
  if (@($arguments | Where-Object { $_ -ceq '--dart-define' -or $_ -cmatch '^-D' -or
      $_ -ceq '--DartDefines' -or $_.StartsWith('--DartDefines=', [StringComparison]::Ordinal) }).Count) { throw 'Use only explicit joined --dart-define=KEY=value arguments; alternative define forms require review.' }
  function Get-RuntimeArgument([string[]]$Names) {
    $found = @()
    for ($i = 0; $i -lt $arguments.Count; $i++) {
      foreach ($name in $Names) {
        if ($arguments[$i] -ceq $name -and $i + 1 -lt $arguments.Count) { $found += $arguments[$i + 1] }
        elseif ($arguments[$i].StartsWith($name + '=', [StringComparison]::Ordinal)) { $found += $arguments[$i].Substring($name.Length + 1) }
      }
    }
    if ($found.Count -ne 1) { throw "Runtime argument missing or duplicated: $($Names[0])" }
    return $found[0]
  }
  if ((Get-RuntimeArgument @('-d', '--device-id')) -cne [string]$contract.serial -or
      (Get-RuntimeArgument @('--app-id')) -cne [string]$contract.package -or
      (Get-RuntimeArgument @('--target', '-t')) -cne [string]$contract.entrypoint) { throw 'Runtime device, package or entrypoint differs from the reviewed contract.' }
  $defines = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
  foreach ($argument in $arguments) {
    if ($argument.StartsWith('--dart-define=', [StringComparison]::Ordinal)) {
      $parts = $argument.Substring(14).Split('=', 2)
      if ($parts.Count -ne 2 -or $defines.ContainsKey($parts[0])) { throw 'Runtime define is invalid or duplicated.' }
      $defines[$parts[0]] = $parts[1]
    }
  }
  $expected = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
  foreach ($property in $contract.defines.PSObject.Properties) { $expected[$property.Name] = [string]$property.Value }
  $evaluation = $contract.profile -ceq 'evaluation'
  if ($contract.expectedStartupAuthenticated -isnot [bool] -or $contract.expectedStartupSetupComplete -isnot [bool]) { throw 'Runtime contract must state exact startup authentication and setup status for this reviewed screen.' }
  foreach ($name in @('MOOLSOCIAL_UI_REVIEW_ONLY', 'MOOLSOCIAL_DEVICE_REVIEW')) {
    if ($expected[$name] -cne $evaluation.ToString().ToLowerInvariant()) { throw 'Runtime profile and review defines conflict.' }
  }
  if ($expected['MOOLSOCIAL_CANDIDATE_ID'] -cne [string]$contract.candidateId -or
      -not $expected.ContainsKey('MOOLSOCIAL_USE_EMULATORS') -or $defines.Count -ne $expected.Count) { throw 'Runtime candidate/define set is incomplete or has unreviewed additions.' }
  foreach ($name in $expected.Keys) {
    if (-not $defines.ContainsKey($name) -or $defines[$name] -cne $expected[$name]) { throw "Missing or mismatched runtime define: $name" }
  }
  if (-not $contract.sessionStatePath -or -not [IO.Path]::IsPathRooted([string]$contract.sessionStatePath) -or
      -not (Test-Path -LiteralPath (Split-Path -Parent $contract.sessionStatePath) -PathType Container)) { throw 'Runtime contract requires a durable session-state path in its existing evidence directory.' }
  $contractIdentity = ([string]$contract.repositoryRoot, [string]$contract.entrypoint, [string]$contract.package,
    [string]$contract.serial, [string]$contract.candidateId, [string]$contract.profile,
    [string]$contract.expectedStartupAuthenticated, [string]$contract.expectedStartupSetupComplete,
    (($expected.Keys | Sort-Object -CaseSensitive | ForEach-Object { $_ + '=' + $expected[$_] }) -join '|')) -join '|'
  $contractHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($contractIdentity)))
  $sessionState = if (Test-Path -LiteralPath $contract.sessionStatePath -PathType Leaf) {
    Get-Content -Raw -LiteralPath $contract.sessionStatePath -Encoding utf8 | ConvertFrom-Json
  } else { $null }
  if ($RuntimeAction -eq 'hotreload' -and ($null -eq $sessionState -or -not $sessionState.verified -or
      $sessionState.processId -ne $RuntimeProcessId -or $sessionState.contractHash -cne $contractHash)) { throw 'A new attach requires a gated hot restart and verified screen before hot reload.' }
  if ($RuntimeAction -eq 'inspect') {
    if ($null -eq $sessionState -or $sessionState.action -cne 'hotrestart' -or
        $sessionState.processId -ne $RuntimeProcessId -or $sessionState.contractHash -cne $contractHash) { throw 'Founder handoff requires a gated hot restart after the latest attach/reload and matching fresh evidence.' }
    try {
      $boundary = if ($sessionState.actionUtc -is [DateTimeOffset]) { $sessionState.actionUtc }
        elseif ($sessionState.actionUtc -is [DateTime]) { [DateTimeOffset]::new($sessionState.actionUtc.ToUniversalTime()) }
        else { [DateTimeOffset]::Parse([string]$sessionState.actionUtc, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind) }
    } catch { throw 'Runtime restart boundary is invalid; perform a new gated restart.' }
    if (-not $RuntimeUiDumpPath -or -not $RuntimeLogPath -or -not $RuntimeExpectedScreen) { throw 'Founder handoff requires fresh runtime log and exact-screen UI evidence.' }
    foreach ($path in @($RuntimeUiDumpPath, $RuntimeLogPath)) {
      if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
          (Get-Item -LiteralPath $path).LastWriteTimeUtc -lt $boundary.UtcDateTime) { throw 'Runtime evidence is missing or older than the latest gated restart.' }
    }
    $ui = Get-Content -Raw -LiteralPath $RuntimeUiDumpPath -Encoding utf8
    $runtime = Get-Content -Raw -LiteralPath $RuntimeLogPath -Encoding utf8
    $epochLines = @($runtime -split '\r?\n' | Where-Object { $_ -match '^\s*(\d{10}\.\d+)\s' -and
      [double]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture) -ge ($boundary.ToUnixTimeMilliseconds() / 1000.0) })
    $runtime = $epochLines -join "`n"
    if ($ui -notmatch '<node\b' -or $ui -notmatch [regex]::Escape($RuntimeExpectedScreen) -or
        $ui -match 'Lookup failed:|_CompileTimeError|ErrorWidget' -or
        $runtime -notmatch ('MOOLSOCIAL_CANDIDATE id=' + [regex]::Escape([string]$contract.candidateId) + '\s') -or
        $runtime -notmatch ('MOOLSOCIAL_STARTUP stage=ready .*setupComplete=' + $contract.expectedStartupSetupComplete.ToString().ToLowerInvariant() + ' .*authenticated=' +
          $contract.expectedStartupAuthenticated.ToString().ToLowerInvariant() + '(?:\s|$)') -or
        $runtime -match 'Lookup failed:|_CompileTimeError|EXCEPTION CAUGHT') { throw 'Runtime candidate, startup or requested screen is not qualified for founder review.' }
    $sessionState.verified = $true
    $sessionState | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $contract.sessionStatePath -Encoding utf8
  } else {
    Assert-StorePublicPreviewParity
    # Record the boundary BEFORE any device mutation. Inspection cannot reuse a
    # prior restart's startup or UI, even when the attach process is unchanged.
    [ordered]@{action=$RuntimeAction; actionUtc=[DateTimeOffset]::UtcNow.ToString('O');
      processId=$RuntimeProcessId; contractHash=$contractHash; verified=$false} |
      ConvertTo-Json | Set-Content -LiteralPath $contract.sessionStatePath -Encoding utf8
  }
  Write-Output "Runtime session gate passed: action=$RuntimeAction; profile=$($contract.profile); exact defines/device/package/entrypoint verified; no APK authority."
}
$registryPath = Join-Path $root 'config\codex-development-regression-registry.json'
$memoryPath = Join-Path $root 'docs\quality\CODEX-DEVELOPMENT-REGRESSION-MEMORY.md'
$coordinationPath = Join-Path $root 'config\codex-subagent-coordination-policy.json'
if (-not (Test-Path -LiteralPath $registryPath -PathType Leaf)) { throw 'Regression registry is missing.' }
if (-not (Test-Path -LiteralPath $memoryPath -PathType Leaf)) { throw 'Regression memory is missing.' }
$dependencyFallbackRoot = $root
if (Test-Path -LiteralPath $coordinationPath -PathType Leaf) {
  $coordination = Get-Content -Raw -LiteralPath $coordinationPath | ConvertFrom-Json
  $configuredProductionRoot = [string]$coordination.productionGitDiscipline.productionCheckout
  if (-not [string]::IsNullOrWhiteSpace($configuredProductionRoot)) {
    $candidateFallbackRoot = [IO.Path]::GetFullPath($configuredProductionRoot)
    if (Test-Path -LiteralPath $candidateFallbackRoot -PathType Container) {
      $dependencyFallbackRoot = $candidateFallbackRoot
    }
  }
}
$registry = Get-Content -Raw -LiteralPath $registryPath | ConvertFrom-Json
if ([int]$registry.schemaVersion -ne 1 -or [string]$registry.registryId -cne 'CODEX-DEVELOPMENT-REGRESSION-MEMORY-001') {
  throw 'Regression registry identity is invalid.'
}
if ([bool]$registry.policy.deleteResolvedEntries -or [bool]$registry.policy.retryBeforeRegistrationAllowed) {
  throw 'Regression registry weakened permanent founder rules.'
}
$entries = @($registry.entries)
$evidenceRoots = [Collections.Generic.List[string]]::new()
foreach ($candidateRoot in @($root, $dependencyFallbackRoot)) {
  $resolvedRoot = [IO.Path]::GetFullPath($candidateRoot).TrimEnd([char[]]@('\', '/'))
  if (-not $evidenceRoots.Contains($resolvedRoot)) {
    $evidenceRoots.Add($resolvedRoot)
  }
}
$workspaceRoot = [IO.Path]::GetFullPath((Split-Path -Parent $root)).TrimEnd(
  [char[]]@('\', '/'))
$worktreeLines = @(& git -C $root worktree list --porcelain)
if ($LASTEXITCODE -ne 0) { throw 'Registered worktree discovery failed.' }
foreach ($line in $worktreeLines) {
  if (-not $line.StartsWith('worktree ', [StringComparison]::Ordinal)) {
    continue
  }
  $candidateRoot = [IO.Path]::GetFullPath($line.Substring(9)).TrimEnd(
    [char[]]@('\', '/'))
  if (-not $candidateRoot.StartsWith(
      $workspaceRoot + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    )) {
    continue
  }
  if ((Test-Path -LiteralPath $candidateRoot -PathType Container) -and
      -not $evidenceRoots.Contains($candidateRoot)) {
    $evidenceRoots.Add($candidateRoot)
  }
}
if (-not [string]::IsNullOrWhiteSpace($EvidenceArchiveRoot)) {
  $resolvedArchiveRoot = [IO.Path]::GetFullPath($EvidenceArchiveRoot).TrimEnd(
    [char[]]@('\', '/'))
  if (-not $resolvedArchiveRoot.StartsWith(
      $workspaceRoot + [IO.Path]::DirectorySeparatorChar + 'MOOLSOCIAL-ARCHIVE-',
      [StringComparison]::OrdinalIgnoreCase
    ) -or -not (Test-Path -LiteralPath $resolvedArchiveRoot -PathType Container)) {
    throw 'Regression evidence archive root is invalid or unavailable.'
  }
  foreach ($archiveWorktree in @(Get-ChildItem -LiteralPath $resolvedArchiveRoot -Directory)) {
    $archivedUntrackedRoot = Join-Path $archiveWorktree.FullName 'untracked'
    $archiveMetadataPath = Join-Path $archiveWorktree.FullName 'archive-metadata.json'
    $archiveManifestPath = Join-Path $archiveWorktree.FullName 'untracked-sha256.csv'
    if ((Test-Path -LiteralPath $archivedUntrackedRoot -PathType Container) -and
        (Test-Path -LiteralPath $archiveMetadataPath -PathType Leaf) -and
        (Test-Path -LiteralPath $archiveManifestPath -PathType Leaf)) {
      $resolvedEvidenceRoot = [IO.Path]::GetFullPath($archivedUntrackedRoot)
      if (-not $evidenceRoots.Contains($resolvedEvidenceRoot)) {
        $evidenceRoots.Add($resolvedEvidenceRoot)
      }
    }
  }
}

function Test-RegistryOwnerExists([string]$Relative) {
  foreach ($candidateRoot in $evidenceRoots) {
    $resolved = [IO.Path]::GetFullPath((Join-Path $candidateRoot $Relative))
    if (-not $resolved.StartsWith(
        $candidateRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      )) {
      continue
    }
    if (Test-Path -LiteralPath $resolved) { return $true }
  }
  return $false
}

function Test-RepositoryPathGate([string]$Value) {
  return $Value -cmatch '^[A-Za-z0-9._-]+(?:[\\/][A-Za-z0-9._-]+)+$'
}

. (Join-Path $PSScriptRoot 'artifact-evidence-retention.ps1')
$retiredReferences = Get-RetiredRegressionArtifacts -RepositoryRoot $root -Registry $registry -EvidenceRoots $evidenceRoots.ToArray()

$ids = @($entries | ForEach-Object { [string]$_.id })
if ($entries.Count -eq 0 -or $ids.Count -ne @($ids | Select-Object -Unique).Count) {
  throw 'Regression registry entries are missing or duplicated.'
}
foreach ($entry in $entries) {
  foreach ($field in @('id', 'status', 'mistake', 'rootCause', 'prevention')) {
    if ([string]::IsNullOrWhiteSpace([string]$entry.$field)) { throw "Regression entry has blank $field." }
  }
  if (@($entry.appliesTo).Count -eq 0 -or @($entry.gates).Count -eq 0 -or @($entry.evidence).Count -eq 0) {
    throw "Regression entry $($entry.id) lacks phase, gate or evidence."
  }
  foreach ($relative in @($entry.evidence)) {
    if (-not (Test-RegistryOwnerExists ([string]$relative)) -and
        -not $retiredReferences.ContainsKey([string]$entry.id + '|' + [string]$relative)) {
      throw "Regression entry $($entry.id) references missing repository evidence: $relative"
    }
  }
  foreach ($gate in @($entry.gates)) {
    $gateValue = [string]$gate
    if ([string]::IsNullOrWhiteSpace($gateValue)) {
      throw "Regression entry $($entry.id) contains an empty gate."
    }
    if ((Test-RepositoryPathGate $gateValue) -and
        -not (Test-RegistryOwnerExists $gateValue)) {
      throw "Regression entry $($entry.id) references missing repository gate: $gateValue"
    }
  }
}
if ($Phase -eq 'build') {
  if ($BuildMode -eq 'none') { throw 'Build phase requires an exact build mode.' }
  Assert-StorePublicPreviewParity
  $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
  if ($null -eq $pwsh) { throw 'PowerShell 7 pwsh is required for Android build wrappers.' }
  $major = [int](& $pwsh.Source -NoProfile -Command '$PSVersionTable.PSVersion.Major')
  if ($major -lt 7) { throw 'PowerShell 7 or newer is required for Android build wrappers.' }
  if ($BuildMode -eq 'profile') {
    $main = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\main.dart')
    $journey = Get-Content -Raw -LiteralPath (Join-Path $root 'apps\mobile\lib\features\journey01\journey_session.dart')
    $candidateProfileSafe = $main -match 'if\s*\([^\)]*_deviceReviewMode[^\)]*\)\s*\{\s*debugPrint\('
    $startupProfileSafe = $journey -match "bool\.fromEnvironment\(\s*'MOOLSOCIAL_DEVICE_REVIEW'" -and $journey -match 'MOOLSOCIAL_STARTUP'
    if (-not $candidateProfileSafe -or -not $startupProfileSafe) {
      throw 'Profile review-build provenance remains kDebugMode-only; REG-20260806-006 blocks the build.'
    }
  }
}
$applicable = @($entries | Where-Object { $Phase -eq 'general' -or @($_.appliesTo) -contains $Phase })
Write-Output "Codex regression memory passed: entries=$($entries.Count); applicable=$($applicable.Count); phase=$Phase; buildMode=$BuildMode; retiredHistoricalArtifacts=3; exactRetiredReferences=$($retiredReferences.Count); noReleaseAuthority=true."
