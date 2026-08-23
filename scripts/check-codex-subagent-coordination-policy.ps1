[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('primary', 'subagent')]
  [string]$AgentRole,
  [Parameter(Mandatory)]
  [string]$AgentTask,
  [string[]]$ClaimedOwners = @(),
  [switch]$UseRecordedClaim,
  [Parameter(Mandatory)]
  [ValidateRange(1, [int]::MaxValue)]
  [int]$ExpectedRegistryEntryCount,
  [Parameter(Mandatory)]
  [ValidatePattern('^[0-9A-F]{64}$')]
  [string]$ExpectedRegistrySha256,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$workspaceRoot = [IO.Path]::GetFullPath((Split-Path -Parent $root)).TrimEnd(
  [char[]]@('\', '/'))

function Assert-Coordination([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Codex subagent coordination gate rejected: $Message"
  }
}

function Get-ExactNames($Value) {
  return @($Value.PSObject.Properties.Name)
}

function Assert-ExactNames($Value, [string[]]$Expected, [string]$Label) {
  $actual = @(Get-ExactNames $Value)
  Assert-Coordination (
    $actual.Count -eq $Expected.Count -and
    (@($actual | Sort-Object) -join '|') -ceq
      (@($Expected | Sort-Object) -join '|')
  ) "$Label schema changed."
}

function Get-Sha256([string]$Path) {
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-CanonicalOwner([string]$Owner) {
  Assert-Coordination (-not [string]::IsNullOrWhiteSpace($Owner)) `
    'owner claim is empty.'
  $normalized = $Owner.Replace('\', '/').Trim()
  Assert-Coordination (
    -not [IO.Path]::IsPathRooted($normalized) -and
    $normalized -notmatch '(^|/)[.][.]($|/)' -and
    $normalized -notmatch '(^|/)[.]($|/)' -and
    -not $normalized.EndsWith('/')
  ) "owner claim is not one canonical repository-relative path: $Owner"
  return $normalized
}

$policyPath = Join-Path $root 'config/codex-subagent-coordination-policy.json'
$registryPath = Join-Path $root 'config/codex-development-regression-registry.json'
$agentsPath = Join-Path $root 'AGENTS.md'
$policyDocPath = Join-Path $root `
  'docs/quality/CODEX-SUBAGENT-MANDATORY-COORDINATION-POLICY-20260818.md'
foreach ($required in @($policyPath, $registryPath, $agentsPath, $policyDocPath)) {
  Assert-Coordination (Test-Path -LiteralPath $required -PathType Leaf) `
    "mandatory policy owner is missing: $required"
}

try { $policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json }
catch { throw 'Codex subagent coordination gate rejected: policy JSON is invalid.' }
try { $registry = Get-Content -Raw -LiteralPath $registryPath | ConvertFrom-Json }
catch { throw 'Codex subagent coordination gate rejected: registry JSON is invalid.' }

Assert-ExactNames $policy @(
  'schemaVersion','policyId','effectiveDate','state','registryBinding',
  'mandatoryReads','primaryOnlyOwners','activeClaims','incidentProtocol',
  'generationRules','releaseSerialization','requiredPreventionClasses'
) 'coordination policy'
Assert-Coordination (
  [int]$policy.schemaVersion -eq 1 -and
  [string]$policy.policyId -ceq 'MOOLSOCIAL-CODEX-SUBAGENT-COORDINATION-001' -and
  [string]$policy.state -ceq 'mandatory_before_every_subagent_action'
) 'policy identity or state changed.'
Assert-ExactNames $policy.incidentProtocol @(
  'subagentAllocatesRegressionId','subagentWritesRegistry',
  'stopAtFirstUnexpected','laterDiagnosticBeforeRegistration',
  'primaryProvidesLiteralIdPathAndGeneration',
  'externalHelpRequestedImmediately',
  'silentStandbyOrSidebyOnExternalBlockerAllowed'
) 'incident protocol'
Assert-Coordination (
  [bool]$policy.incidentProtocol.externalHelpRequestedImmediately -and
  -not [bool]$policy.incidentProtocol.silentStandbyOrSidebyOnExternalBlockerAllowed
) 'external-help blockers must be escalated immediately instead of left on standby or sideby.'
Assert-ExactNames $policy.registryBinding @('entryCount','sha256') `
  'registry binding'

$registryEntries = @($registry.entries)
$registrySha = Get-Sha256 $registryPath
Assert-Coordination ($registryEntries.Count -eq $ExpectedRegistryEntryCount) `
  'current registry entry count differs from the agent preflight generation.'
Assert-Coordination ($registrySha -ceq $ExpectedRegistrySha256) `
  'current registry SHA-256 differs from the agent preflight generation.'
Assert-Coordination (
  [int]$policy.registryBinding.entryCount -eq $ExpectedRegistryEntryCount -and
  [string]$policy.registryBinding.sha256 -ceq $ExpectedRegistrySha256
) 'machine policy registry binding is stale.'

$fullIds = @($registryEntries | ForEach-Object { [string]$_.id })
Assert-Coordination (
  @($fullIds | Select-Object -Unique).Count -eq $fullIds.Count
) 'registry contains a duplicate full regression ID.'
$numericIds = @()
foreach ($id in $fullIds) {
  Assert-Coordination ($id -cmatch '^REG-[0-9]{8}-([0-9]+)-') `
    "registry ID has no canonical numeric prefix: $id"
  $numericIds += [int]$Matches[1]
}
Assert-Coordination (
  @($numericIds | Select-Object -Unique).Count -eq $numericIds.Count
) 'registry contains a duplicate numeric regression prefix.'

$agentsText = Get-Content -Raw -LiteralPath $agentsPath
$agentsNormalized = [regex]::Replace($agentsText, '\s+', ' ')
foreach ($token in @(
  'CODEX-SUBAGENT-MANDATORY-COORDINATION-POLICY-20260818.md',
  'Only the primary agent allocates regression numbers',
  'check-codex-subagent-coordination-policy.ps1',
  'do **not** emit full `git status --short --branch`',
  'git status --porcelain=v1 -z',
  'non-overlapping pages of at most 250 lines',
  'first two `^## ` heading line numbers',
  'Never raw-read or fully emit the complete MVP scope state',
  'never enumerate all historical assessment properties',
  'digest output allowlist is'
)) {
  $normalizedToken = [regex]::Replace($token, '\s+', ' ')
  Assert-Coordination ($agentsNormalized.Contains($normalizedToken)) `
    "AGENTS.md is missing mandatory coordination token: $token"
}

$policyText = Get-Content -Raw -LiteralPath $policyDocPath
$policyNormalized = [regex]::Replace($policyText, '\s+', ' ')
foreach ($token in @(
  'Primary-only coordination authority',
  'Exclusive owner protocol',
  'Generation and test serialization',
  'Outage and ambiguous-session recovery',
  'Immediate external-help escalation',
  'never silently leaves the task on standby or `sideby`',
  'Release-action single owner',
  'full dirty-tree status output is prohibited',
  'Regression memory is read only in non-overlapping pages of at most 250 lines',
  'discover only the first two `^## ` heading line numbers',
  'Never raw-read the full owner',
  'never enumerate all historical assessment properties',
  'suppress helper return objects'
)) {
  $normalizedToken = [regex]::Replace($token, '\s+', ' ')
  Assert-Coordination ($policyNormalized.Contains($normalizedToken)) `
    "coordination policy document is missing section: $token"
}

$expectedClasses = @(
  'regression_number_collision','duplicate_registry_numeric_prefix',
  'stale_registry_generation','overlapping_owner_claim',
  'primary_only_owner_violation','stale_patch_context',
  'cross_owner_schema_drift','guessed_path_property_or_schema',
  'output_truncation_or_semantic_incompleteness',
  'yielded_session_handle_loss_or_orphan',
  'power_outage_or_ambiguous_session',
  'file_directory_or_reparse_confinement',
  'fixture_root_collision_or_cleanup_gap',
  'powershell_quoting_pipeline_or_host_coercion',
  'false_oracle_or_validation_order_masking',
  'caller_authored_evidence_or_replay',
  'secret_private_or_account_surface',
  'duplicate_or_out_of_order_release_action',
  'branch_head_workspace_or_git_drift'
)
$actualClasses = @($policy.requiredPreventionClasses | ForEach-Object { [string]$_ })
Assert-Coordination (
  $actualClasses.Count -eq $expectedClasses.Count -and
  (@($actualClasses | Sort-Object) -join '|') -ceq
    (@($expectedClasses | Sort-Object) -join '|')
) 'required prevention-class inventory changed.'

$mandatoryReads = @($policy.mandatoryReads | ForEach-Object { [string]$_ })
foreach ($readOwner in $mandatoryReads) {
  $candidate = [IO.Path]::GetFullPath((Join-Path $root $readOwner))
  Assert-Coordination (
    $candidate -ceq $workspaceRoot -or
    $candidate.StartsWith(
      $workspaceRoot + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase)
  ) "mandatory read escaped the workspace: $readOwner"
  Assert-Coordination (Test-Path -LiteralPath $candidate -PathType Leaf) `
    "mandatory read is missing: $readOwner"
}

$claims = @($policy.activeClaims)
Assert-Coordination ($claims.Count -ge 1) 'active claim inventory is empty.'
$missingOwnerNegativeFixture = Join-Path $root `
  '.codex-coordination-missing-owner-negative-fixture'
Assert-Coordination (
  -not (Test-Path -LiteralPath $missingOwnerNegativeFixture)
) 'missing-owner negative fixture unexpectedly exists.'
$taskNames = @($claims | ForEach-Object { [string]$_.task })
Assert-Coordination (
  @($taskNames | Select-Object -Unique).Count -eq $taskNames.Count
) 'active claim inventory contains a duplicate task.'
$ownerToTask = @{}
foreach ($claim in $claims) {
  Assert-ExactNames $claim @('task','role','owners') 'active claim'
  Assert-Coordination (
    [string]$claim.role -cin @('primary','subagent') -and
    [string]$claim.task -cmatch '^/root(?:/[a-z0-9_]+)*$'
  ) 'active claim task or role is invalid.'
  $localOwners = @()
  foreach ($ownerValue in @($claim.owners)) {
    $owner = Get-CanonicalOwner ([string]$ownerValue)
    $resolvedOwner = [IO.Path]::GetFullPath((Join-Path $root $owner))
    Assert-Coordination (
      $resolvedOwner.StartsWith(
        $root + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      ) -and
      (Test-Path -LiteralPath $resolvedOwner -PathType Leaf)
    ) "recorded owner is missing: $owner"
    $key = $owner.ToLowerInvariant()
    Assert-Coordination (-not $localOwners.Contains($key)) `
      "task $($claim.task) claims one owner twice: $owner"
    Assert-Coordination (-not $ownerToTask.ContainsKey($key)) `
      "owner is claimed by more than one active task: $owner"
    $localOwners += $key
    $ownerToTask[$key] = [string]$claim.task
  }
}

$currentClaim = @($claims | Where-Object { [string]$_.task -ceq $AgentTask })
Assert-Coordination ($currentClaim.Count -eq 1) `
  'agent task has no single active owner claim.'
Assert-Coordination ([string]$currentClaim[0].role -ceq $AgentRole) `
  'agent role differs from its active claim.'
$recordedOwners = @($currentClaim[0].owners | ForEach-Object {
  Get-CanonicalOwner ([string]$_)
})
if ($UseRecordedClaim) {
  Assert-Coordination ($ClaimedOwners.Count -eq 0) `
    'UseRecordedClaim cannot be combined with explicit ClaimedOwners.'
  $effectiveOwners = $recordedOwners
} else {
  $effectiveOwners = @($ClaimedOwners | ForEach-Object {
    Get-CanonicalOwner ([string]$_)
  })
  Assert-Coordination ($effectiveOwners.Count -gt 0) `
    'explicit ClaimedOwners are required when UseRecordedClaim is absent.'
}
$recordedKeys = @($recordedOwners | ForEach-Object { $_.ToLowerInvariant() })
$primaryOnlyKeys = @($policy.primaryOnlyOwners | ForEach-Object {
  (Get-CanonicalOwner ([string]$_)).ToLowerInvariant()
})
foreach ($owner in $effectiveOwners) {
  $key = $owner.ToLowerInvariant()
  Assert-Coordination ($recordedKeys.Contains($key)) `
    "agent requested an owner outside its recorded claim: $owner"
  if ($AgentRole -ceq 'subagent') {
    Assert-Coordination (-not $primaryOnlyKeys.Contains($key)) `
      "subagent requested a primary-only owner: $owner"
  }
}

$branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim()
Assert-Coordination ($LASTEXITCODE -eq 0) 'git branch check failed.'
$head = (& git -C $root rev-parse HEAD).Trim()
Assert-Coordination ($LASTEXITCODE -eq 0) 'git HEAD check failed.'
$buildAnchor = 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
$acceptedTagName = 'moolsocial-google-auth-r60.87-accepted-20260823'
$headAccepted = $head -ceq $buildAnchor
if (-not $headAccepted) {
  $taggedHead = (& git -C $root rev-parse "$acceptedTagName^{commit}" 2>$null).Trim()
  $tagResolved = $LASTEXITCODE -eq 0 -and $taggedHead -ceq $head
  $tagType = (& git -C $root cat-file -t $acceptedTagName 2>$null).Trim()
  $tagAnnotated = $LASTEXITCODE -eq 0 -and $tagType -ceq 'tag'
  & git -C $root merge-base --is-ancestor $buildAnchor $head
  $anchorIsAncestor = $LASTEXITCODE -eq 0
  $headAccepted = $tagResolved -and $tagAnnotated -and $anchorIsAncestor
}
Assert-Coordination (
  $branch -ceq 'remediation/prototype-conformance-2026-07-20' -and
  $headAccepted
) 'branch or HEAD changed.'

$resultLine = (
  (
    'Codex subagent coordination policy passed: policy={0}; role={1}; ' +
    'task={2}; claims={3}; activeTasks={4}; registry={5}; ' +
    'numericPrefixesUnique=true; branchHead=true; releaseActionOwner=primary.'
  ) -f
    $policy.policyId,$AgentRole,$AgentTask,$effectiveOwners.Count,$claims.Count,
    $registryEntries.Count
)
Assert-Coordination ($resultLine -cnotmatch '\{[0-9]+\}') `
  'coordination pass output retained an unresolved format placeholder.'
Write-Output $resultLine
