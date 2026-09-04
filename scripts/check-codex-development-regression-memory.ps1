[CmdletBinding()]
param(
  [ValidateSet('general', 'implementation', 'build', 'device')]
  [string]$Phase = 'general',

  [ValidateSet('none', 'debug', 'profile', 'release')]
  [string]$BuildMode = 'none',

  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
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
    if (-not (Test-RegistryOwnerExists ([string]$relative))) {
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
Write-Output "Codex regression memory passed: entries=$($entries.Count); applicable=$($applicable.Count); phase=$Phase; buildMode=$BuildMode."
