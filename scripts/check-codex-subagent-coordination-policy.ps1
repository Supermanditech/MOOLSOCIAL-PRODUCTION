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
  [ValidateSet('baseline','cursor_ui','codex_auth','codex_backend','integration')]
  [string]$ProductionLane = 'baseline',
  [ValidateSet(
    'baseline','governance_preflight','task_start','implementation','pre_commit','handoff',
    'founder_acceptance','ticket_acceptance','ticket_close',
    'integration_start','integration_verify','integration_close',
    'candidate_preflight'
  )]
  [string]$ProductionPhase = 'baseline',
  [string]$ProductionWorkId,
  [string]$ProductionTicketId,
  [string]$FounderAcceptanceEvidencePath,
  [string]$FounderAcceptanceEvidenceSha256,
  [string]$AcceptedUiCommit,
  [string]$UiContractPath,
  [string]$UiContractSha256,
  [string]$AcceptedTicketCommit,
  [string]$TicketRequirementEvidencePath,
  [string]$TicketRequirementEvidenceSha256,
  [string]$OppoAcceptanceEvidencePath,
  [string]$OppoAcceptanceEvidenceSha256,
  [string[]]$ApprovedFeatureCommits = @(),
  [string[]]$ApprovedFeatureBranches = @(),
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

function ConvertTo-ProductionForwardPath([string]$PathValue) {
  return [IO.Path]::GetFullPath($PathValue).Replace('\', '/').TrimEnd('/')
}

function Test-ProductionOwnerRoot(
  [string]$Owner,
  [string]$OwnerRoot
) {
  $normalizedOwner = (Get-CanonicalOwner $Owner).ToLowerInvariant()
  $normalizedRoot = $OwnerRoot.Replace('\', '/').Trim().ToLowerInvariant()
  Assert-Coordination (
    -not [string]::IsNullOrWhiteSpace($normalizedRoot) -and
    -not [IO.Path]::IsPathRooted($normalizedRoot) -and
    $normalizedRoot -notmatch '(^|/)[.][.]($|/)'
  ) "production owner root is invalid: $OwnerRoot"
  if ($normalizedRoot.EndsWith('/') -or
      [string]::IsNullOrEmpty([IO.Path]::GetExtension($normalizedRoot))) {
    return $normalizedOwner.StartsWith(
      $normalizedRoot,
      [StringComparison]::OrdinalIgnoreCase
    )
  }
  return $normalizedOwner.Equals(
    $normalizedRoot,
    [StringComparison]::OrdinalIgnoreCase
  )
}

function Resolve-ProductionEvidenceOwner([string]$RelativePath) {
  $owner = Get-CanonicalOwner $RelativePath
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $owner))
  Assert-Coordination (
    $resolved.StartsWith(
      $root + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) "production evidence owner is missing: $owner"
  return $resolved
}

function Get-ProductionChangedOwners(
  [string]$BaseCommit,
  [string]$HeadCommit
) {
  $changedOwners = @()
  $committed = @(& git -C $root diff --name-only --diff-filter=ACMRTUXBD `
      "$BaseCommit..$HeadCommit")
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'production committed-owner inventory failed.'
  $unstaged = @(& git -C $root diff --name-only --diff-filter=ACMRTUXBD)
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'production unstaged-owner inventory failed.'
  $staged = @(& git -C $root diff --cached --name-only --diff-filter=ACMRTUXBD)
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'production staged-owner inventory failed.'
  $untracked = @(& git -C $root ls-files --others --exclude-standard)
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'production untracked-owner inventory failed.'
  foreach ($candidateOwner in @($committed) + @($unstaged) + @($staged) +
      @($untracked)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$candidateOwner)) {
      $changedOwners += Get-CanonicalOwner ([string]$candidateOwner)
    }
  }
  return @($changedOwners | Sort-Object -Unique)
}

function Test-ProductionWorktreeClean {
  $worktreeStatus = @(& git -C $root status --porcelain=v1 `
      --untracked-files=normal)
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'production worktree cleanliness check failed.'
  return $worktreeStatus.Count -eq 0
}

function Get-ProductionRemoteBranchHead([string]$BranchName) {
  Assert-Coordination (
    $BranchName -cmatch '^(?:work/(?:cursor-ui|codex-auth|codex-backend)/|integration/moolsocial/)[a-z0-9][a-z0-9-]{2,48}$'
  ) 'production remote branch name is invalid.'
  $remoteRef = 'refs/heads/' + $BranchName
  $remoteOutput = @(& git -C $root ls-remote --exit-code --heads origin `
      $remoteRef 2>$null)
  $remoteExit = $LASTEXITCODE
  Assert-Coordination ($remoteExit -eq 0 -and $remoteOutput.Count -eq 1) `
    "production remote branch is missing or unreadable: $BranchName"
  $remoteParts = @([string]$remoteOutput[0] -split '\s+')
  Assert-Coordination (
    $remoteParts.Count -eq 2 -and
    $remoteParts[0] -cmatch '^[0-9a-f]{40}$' -and
    $remoteParts[1] -ceq $remoteRef
  ) "production remote branch readback is invalid: $BranchName"
  return [string]$remoteParts[0]
}

function Assert-ProductionManagedWorktreesClean {
  $worktreeInventory = @(& git -C $root worktree list --porcelain)
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'managed production worktree inventory failed.'
  $managedPaths = @()
  $workspaceParentForward = [string]$gitDiscipline.workspaceIsolation.workspaceParent
  $managedPrefixes = @(
    [string]$gitDiscipline.workspaceIsolation.cursorWorktreePrefix,
    [string]$gitDiscipline.workspaceIsolation.codexWorktreePrefix,
    [string]$gitDiscipline.workspaceIsolation.integrationWorktreePrefix
  )
  foreach ($inventoryLine in $worktreeInventory) {
    if ([string]$inventoryLine -notmatch '^worktree (.+)$') { continue }
    $candidatePath = ConvertTo-ProductionForwardPath ([string]$Matches[1])
    $managed = $candidatePath -ceq [string]$gitDiscipline.productionCheckout
    foreach ($managedPrefix in $managedPrefixes) {
      if ($candidatePath.StartsWith(
          $workspaceParentForward + '/' + $managedPrefix,
          [StringComparison]::OrdinalIgnoreCase)) {
        $managed = $true
      }
    }
    Assert-Coordination $managed `
      "unauthorized production repository worktree is registered: $candidatePath"
    $managedPaths += $candidatePath
  }
  Assert-Coordination (
    @($managedPaths | Select-Object -Unique).Count -eq $managedPaths.Count -and
    $managedPaths -ccontains [string]$gitDiscipline.productionCheckout
  ) 'managed production worktree inventory is incomplete or duplicated.'
  foreach ($managedPath in $managedPaths) {
    Assert-Coordination (Test-Path -LiteralPath $managedPath -PathType Container) `
      "managed production worktree is unavailable: $managedPath"
    $managedStatus = @(& git -C $managedPath status --porcelain=v1 `
        --untracked-files=normal)
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      "managed production worktree status failed: $managedPath"
    Assert-Coordination ($managedStatus.Count -eq 0) `
      "managed production worktree is dirty: $managedPath"
  }
}

function Assert-ProductionSecretSafe(
  [string]$BaseCommit,
  [string]$HeadCommit,
  [switch]$IndexOnly
) {
  if ($IndexOnly) {
    $secretCandidateOwners = @(& git -C $root diff --cached --name-only `
        --diff-filter=ACMRTUXB)
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'staged secret-owner inventory failed.'
  } else {
    $secretCandidateOwners = @(& git -C $root diff --name-only `
        --diff-filter=ACMRTUXB "$BaseCommit..$HeadCommit")
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'committed secret-owner inventory failed.'
  }
  $secretPathPattern = (
    '(?i)(^|/)(google-services[.]json|[^/]*service[-_]?account[^/]*[.]json|' +
    '[.]env(?:[.][^/]*)?|[^/]*[.](?:jks|keystore|p12|pfx|pem|key))$|' +
    '(?i)(^|/)(?:secrets?|credentials?)/'
  )
  $secretValuePatterns = @(
    'AIza[0-9A-Za-z_-]{30,}',
    '-----BEGIN(?: [A-Z]+)? PRIVATE KEY-----',
    '(?i)\bgh[pousr]_[0-9A-Za-z]{20,}\b',
    '(?i)\bxox[baprs]-[0-9A-Za-z-]{20,}\b',
    '(?i)"private_key"\s*:\s*"[^\"]{20,}',
    '(?i)"client_secret"\s*:\s*"(?![$][{]|<|REDACTED|redacted|absent|present|[*])[^\"]{8,}'
  )
  foreach ($secretCandidate in $secretCandidateOwners) {
    $secretOwner = Get-CanonicalOwner ([string]$secretCandidate)
    Assert-Coordination ($secretOwner -cnotmatch $secretPathPattern) `
      "secret-bearing path is forbidden in production Git: $secretOwner"
    $extension = [IO.Path]::GetExtension($secretOwner).ToLowerInvariant()
    if ($extension -notin @(
      '.json','.yaml','.yml','.xml','.properties','.gradle','.kts','.dart',
      '.ts','.js','.ps1','.md','.txt','.html','.gql','.toml','.cfg','.ini'
    )) {
      continue
    }
    $blobSpec = if ($IndexOnly) {
      ':' + $secretOwner
    } else {
      '{0}:{1}' -f $HeadCommit,$secretOwner
    }
    $blobOutput = @(& git -C $root show --no-textconv $blobSpec 2>$null)
    $blobExit = $LASTEXITCODE
    Assert-Coordination ($blobExit -eq 0) `
      "changed production owner could not be secret-scanned: $secretOwner"
    $blobText = [string]::Join("`n",$blobOutput)
    foreach ($secretValuePattern in $secretValuePatterns) {
      Assert-Coordination ($blobText -cnotmatch $secretValuePattern) `
        "secret-value classification rejected changed owner: $secretOwner"
    }
  }
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
  'generationRules','productionGitDiscipline','releaseSerialization',
  'requiredPreventionClasses'
) 'coordination policy'
Assert-Coordination (
  [int]$policy.schemaVersion -eq 1 -and
  [string]$policy.policyId -ceq 'MOOLSOCIAL-CODEX-SUBAGENT-COORDINATION-001' -and
  [string]$policy.state -ceq 'mandatory_before_every_subagent_action'
) 'policy identity or state changed.'
$gitDiscipline = $policy.productionGitDiscipline
Assert-ExactNames $gitDiscipline @(
  'state','productionCheckout','acceptedRuntimeBaseline','workStart',
  'workspaceIsolation','cleanGitState','ticketClosure','agentTicketQueues',
  'lanes','founderAcceptance','atomicCommits','integration','promotion'
) 'production Git discipline'
Assert-Coordination (
  [string]$gitDiscipline.state -ceq 'founder_mandated_fail_closed' -and
  [string]$gitDiscipline.productionCheckout -ceq
    'C:/GUARANTEED OUTCOME/MOOLSOCIAL-PRODUCTION'
) 'production Git discipline identity or checkout changed.'
Assert-ExactNames $gitDiscipline.acceptedRuntimeBaseline @(
  'branch','head','tag','mainHead'
) 'accepted runtime baseline'
Assert-Coordination (
  [string]$gitDiscipline.acceptedRuntimeBaseline.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$gitDiscipline.acceptedRuntimeBaseline.head -ceq
    'f105195ba505dcc9f25a35ab64aab104dadb47c2' -and
  [string]$gitDiscipline.acceptedRuntimeBaseline.tag -ceq
    'moolsocial-google-auth-r60.87-accepted-20260823' -and
  [string]$gitDiscipline.acceptedRuntimeBaseline.mainHead -ceq
    'ed2a44d59efd51d7d4ff09fab5feb940d5798d5c'
) 'accepted runtime baseline changed.'
Assert-ExactNames $gitDiscipline.workStart @(
  'annotatedTag','mustDescendFromAcceptedRuntimeBaseline',
  'featureBranchesMustStartAtTag'
) 'production work start'
Assert-Coordination (
  [string]$gitDiscipline.workStart.annotatedTag -ceq
    'moolsocial-parallel-production-discipline-20260824-v15' -and
  [bool]$gitDiscipline.workStart.mustDescendFromAcceptedRuntimeBaseline -and
  [bool]$gitDiscipline.workStart.featureBranchesMustStartAtTag
) 'production work-start contract changed.'
Assert-ExactNames $gitDiscipline.workspaceIsolation @(
  'parallelMutationInOneWorktreeAllowed','replacementRepositoryAllowed',
  'worktreesRequiredForParallelWork','workspaceParent','parentAgentsPath',
  'cursorWorktreePrefix','codexWorktreePrefix','integrationWorktreePrefix'
) 'production workspace isolation'
Assert-Coordination (
  -not [bool]$gitDiscipline.workspaceIsolation.parallelMutationInOneWorktreeAllowed -and
  -not [bool]$gitDiscipline.workspaceIsolation.replacementRepositoryAllowed -and
  [bool]$gitDiscipline.workspaceIsolation.worktreesRequiredForParallelWork -and
  [string]$gitDiscipline.workspaceIsolation.workspaceParent -ceq
    'C:/GUARANTEED OUTCOME' -and
  [string]$gitDiscipline.workspaceIsolation.parentAgentsPath -ceq
    'C:/GUARANTEED OUTCOME/AGENTS.md'
) 'production workspace isolation weakened.'
Assert-ExactNames $gitDiscipline.cleanGitState @(
  'effectiveAfterGovernanceBaseline',
  'governancePreflightRequiredBeforeWorkStartTag',
  'trackedSourceAndEvidenceRequired',
  'stagedFilesAllowedAtBoundary','unstagedFilesAllowedAtBoundary',
  'untrackedFilesAllowedAtBoundary','agentOwnWorktreeResponsibility',
  'integrationOwnerAllManagedWorktreesResponsibility',
  'secureLocalInputsOutsideRepositoryOrIgnored',
  'userEvidenceDeletionForCleanlinessAllowed'
) 'clean Git state discipline'
Assert-Coordination (
  [bool]$gitDiscipline.cleanGitState.effectiveAfterGovernanceBaseline -and
  [bool]$gitDiscipline.cleanGitState.governancePreflightRequiredBeforeWorkStartTag -and
  [bool]$gitDiscipline.cleanGitState.trackedSourceAndEvidenceRequired -and
  -not [bool]$gitDiscipline.cleanGitState.stagedFilesAllowedAtBoundary -and
  -not [bool]$gitDiscipline.cleanGitState.unstagedFilesAllowedAtBoundary -and
  -not [bool]$gitDiscipline.cleanGitState.untrackedFilesAllowedAtBoundary -and
  [bool]$gitDiscipline.cleanGitState.agentOwnWorktreeResponsibility -and
  [bool]$gitDiscipline.cleanGitState.integrationOwnerAllManagedWorktreesResponsibility -and
  [bool]$gitDiscipline.cleanGitState.secureLocalInputsOutsideRepositoryOrIgnored -and
  -not [bool]$gitDiscipline.cleanGitState.userEvidenceDeletionForCleanlinessAllowed
) 'clean Git state discipline weakened.'
Assert-ExactNames $gitDiscipline.ticketClosure @(
  'founderRequirementAcceptanceRequired','oppoAcceptanceRequired',
  'acceptedCommitShaRequired','evidencePathAndSha256Required',
  'founderEvidenceSchema','oppoEvidenceSchema',
  'evidenceOnlyClosureCommitRequired',
  'acceptedImplementationCommitMustBeClosureParent','cleanWorktreeRequired',
  'atomicHistoryRequired','secretSafetyRequired','remoteName',
  'remoteFeatureBranchMustEqualHead','newTicketBeforeClosureAllowed',
  'worktreeRemovalBeforeIntegrationVerificationAllowed'
) 'ticket closure discipline'
Assert-Coordination (
  [bool]$gitDiscipline.ticketClosure.founderRequirementAcceptanceRequired -and
  [bool]$gitDiscipline.ticketClosure.oppoAcceptanceRequired -and
  [bool]$gitDiscipline.ticketClosure.acceptedCommitShaRequired -and
  [bool]$gitDiscipline.ticketClosure.evidencePathAndSha256Required -and
  [string]$gitDiscipline.ticketClosure.founderEvidenceSchema -ceq
    'moolsocial_ticket_founder_acceptance_v1' -and
  [string]$gitDiscipline.ticketClosure.oppoEvidenceSchema -ceq
    'moolsocial_ticket_oppo_acceptance_v1' -and
  [bool]$gitDiscipline.ticketClosure.evidenceOnlyClosureCommitRequired -and
  [bool]$gitDiscipline.ticketClosure.acceptedImplementationCommitMustBeClosureParent -and
  [bool]$gitDiscipline.ticketClosure.cleanWorktreeRequired -and
  [bool]$gitDiscipline.ticketClosure.atomicHistoryRequired -and
  [bool]$gitDiscipline.ticketClosure.secretSafetyRequired -and
  [string]$gitDiscipline.ticketClosure.remoteName -ceq 'origin' -and
  [bool]$gitDiscipline.ticketClosure.remoteFeatureBranchMustEqualHead -and
  -not [bool]$gitDiscipline.ticketClosure.newTicketBeforeClosureAllowed -and
  -not [bool]$gitDiscipline.ticketClosure.worktreeRemovalBeforeIntegrationVerificationAllowed
) 'ticket closure discipline weakened.'
Assert-ExactNames $gitDiscipline.agentTicketQueues @(
  'cursorUiMaximumOpenTickets','codexAuthMaximumOpenTickets',
  'codexBackendMaximumOpenTickets','priorTicketClosureRequired',
  'founderSelectsExactNextTicket','crossLaneImplementationAllowed',
  'plannedCodexAuthenticationProviders'
) 'agent ticket queue discipline'
$plannedCodexAuthenticationProviders = @(
  $gitDiscipline.agentTicketQueues.plannedCodexAuthenticationProviders |
    ForEach-Object { [string]$_ }
)
Assert-Coordination (
  [int]$gitDiscipline.agentTicketQueues.cursorUiMaximumOpenTickets -eq 1 -and
  [int]$gitDiscipline.agentTicketQueues.codexAuthMaximumOpenTickets -eq 1 -and
  [int]$gitDiscipline.agentTicketQueues.codexBackendMaximumOpenTickets -eq 1 -and
  [bool]$gitDiscipline.agentTicketQueues.priorTicketClosureRequired -and
  [bool]$gitDiscipline.agentTicketQueues.founderSelectsExactNextTicket -and
  -not [bool]$gitDiscipline.agentTicketQueues.crossLaneImplementationAllowed -and
  (@($plannedCodexAuthenticationProviders) -join '|') -ceq
    'email_link|facebook|instagram|youtube_connect|x'
) 'agent ticket queue discipline weakened.'

$productionLanes = @($gitDiscipline.lanes)
$expectedLaneIds = @('cursor_ui','codex_auth','codex_backend','integration')
Assert-Coordination (
  $productionLanes.Count -eq $expectedLaneIds.Count -and
  (@($productionLanes.id | Sort-Object) -join '|') -ceq
    (@($expectedLaneIds | Sort-Object) -join '|')
) 'production lane inventory changed.'
$expectedLaneContracts = @{
  cursor_ui = @{
    role = 'subagent'; task = '/root/cursor_'; branch = 'work/cursor-ui/'
    worktree = 'MOOLSOCIAL-WORKTREE-CURSOR-'; commit = 'ui'
    base = 'governance_tag'
  }
  codex_auth = @{
    role = 'primary'; task = '/root/codex_auth_'; branch = 'work/codex-auth/'
    worktree = 'MOOLSOCIAL-WORKTREE-CODEX-'; commit = 'auth'
    base = 'governance_tag'
  }
  codex_backend = @{
    role = 'primary'; task = '/root/codex_backend_'; branch = 'work/codex-backend/'
    worktree = 'MOOLSOCIAL-WORKTREE-CODEX-'; commit = 'backend'
    base = 'founder_accepted_ui_commit'
  }
  integration = @{
    role = 'primary'; task = '/root/integration_'; branch = 'integration/moolsocial/'
    worktree = 'MOOLSOCIAL-WORKTREE-INTEGRATION-'; commit = 'merge'
    base = 'governance_tag'
  }
}
foreach ($productionLaneContract in $productionLanes) {
  Assert-ExactNames $productionLaneContract @(
    'id','agentRole','taskPrefix','branchPrefix','worktreePrefix',
    'commitPrefix','baseRule','allowedOwnerRoots','forbiddenOwnerRoots'
  ) 'production lane'
  $laneId = [string]$productionLaneContract.id
  $expectedLane = $expectedLaneContracts[$laneId]
  Assert-Coordination ($null -ne $expectedLane) `
    "production lane is not recognized: $laneId"
  Assert-Coordination (
    [string]$productionLaneContract.agentRole -ceq [string]$expectedLane.role -and
    [string]$productionLaneContract.taskPrefix -ceq [string]$expectedLane.task -and
    [string]$productionLaneContract.branchPrefix -ceq [string]$expectedLane.branch -and
    [string]$productionLaneContract.worktreePrefix -ceq [string]$expectedLane.worktree -and
    [string]$productionLaneContract.commitPrefix -ceq [string]$expectedLane.commit -and
    [string]$productionLaneContract.baseRule -ceq [string]$expectedLane.base -and
    @($productionLaneContract.allowedOwnerRoots).Count -gt 0
  ) "production lane contract changed: $laneId"
}
$cursorLane = @($productionLanes | Where-Object { [string]$_.id -ceq 'cursor_ui' })[0]
foreach ($cursorForbiddenRoot in @(
  'apps/mobile/lib/core/auth/','apps/mobile/lib/features/journey01/',
  'apps/mobile/lib/ui_v2/screens/screen01',
  'apps/mobile/lib/ui_v2/screens/screen02',
  'apps/mobile/lib/ui_v2/screens/screen03','apps/mobile/android/',
  'apps/mobile/ios/','apps/mobile/pubspec.yaml','apps/mobile/pubspec.lock',
  'backend/','config/','scripts/'
)) {
  Assert-Coordination (
    @($cursorLane.forbiddenOwnerRoots) -ccontains $cursorForbiddenRoot
  ) "Cursor forbidden production root is missing: $cursorForbiddenRoot"
}
Assert-ExactNames $gitDiscipline.founderAcceptance @(
  'cursorUiRequiredBeforeCodexBackend','evidencePathAndSha256Required',
  'acceptedUiCommitRequired','interactionBusinessContractPathAndSha256Required',
  'chatApprovalAloneAccepted'
) 'founder acceptance dependency'
Assert-Coordination (
  [bool]$gitDiscipline.founderAcceptance.cursorUiRequiredBeforeCodexBackend -and
  [bool]$gitDiscipline.founderAcceptance.evidencePathAndSha256Required -and
  [bool]$gitDiscipline.founderAcceptance.acceptedUiCommitRequired -and
  [bool]$gitDiscipline.founderAcceptance.interactionBusinessContractPathAndSha256Required -and
  -not [bool]$gitDiscipline.founderAcceptance.chatApprovalAloneAccepted
) 'founder acceptance dependency weakened.'
Assert-ExactNames $gitDiscipline.atomicCommits @(
  'featureMergeCommitsAllowed','subjectFormat','rebaseAllowed','squashAllowed',
  'forcePushAllowed','historyRewriteAllowed','changedOwnersMustBeClaimed',
  'workingTreeCleanAtHandoff','secretsAllowed'
) 'atomic commit discipline'
Assert-Coordination (
  -not [bool]$gitDiscipline.atomicCommits.featureMergeCommitsAllowed -and
  [string]$gitDiscipline.atomicCommits.subjectFormat -ceq
    '<commitPrefix>(<work-id>): <outcome>' -and
  -not [bool]$gitDiscipline.atomicCommits.rebaseAllowed -and
  -not [bool]$gitDiscipline.atomicCommits.squashAllowed -and
  -not [bool]$gitDiscipline.atomicCommits.forcePushAllowed -and
  -not [bool]$gitDiscipline.atomicCommits.historyRewriteAllowed -and
  [bool]$gitDiscipline.atomicCommits.changedOwnersMustBeClaimed -and
  [bool]$gitDiscipline.atomicCommits.workingTreeCleanAtHandoff -and
  -not [bool]$gitDiscipline.atomicCommits.secretsAllowed
) 'atomic commit discipline weakened.'
Assert-ExactNames $gitDiscipline.integration @(
  'branchPrefix','worktreePrefix','startsAtGovernanceTag','strategy',
  'approvedFeatureCommitShasRequired','approvedFeatureRemoteReadbackRequired',
  'firstParentDirectCommitsAllowed','conflictSourceEditsAllowed',
  'allManagedWorktreesCleanRequired','remoteIntegrationBranchMustEqualHeadAtClose',
  'cleanIntegratedWorktreeRemovalAllowed','combinedRegressionRequired',
  'candidateBuildRequiresSeparateAuthorization','integrationOwnerGitClosureResponsible'
) 'integration discipline'
Assert-Coordination (
  [string]$gitDiscipline.integration.strategy -ceq 'no_ff_merge_commit' -and
  [bool]$gitDiscipline.integration.startsAtGovernanceTag -and
  [bool]$gitDiscipline.integration.approvedFeatureCommitShasRequired -and
  [bool]$gitDiscipline.integration.approvedFeatureRemoteReadbackRequired -and
  -not [bool]$gitDiscipline.integration.firstParentDirectCommitsAllowed -and
  -not [bool]$gitDiscipline.integration.conflictSourceEditsAllowed -and
  [bool]$gitDiscipline.integration.allManagedWorktreesCleanRequired -and
  [bool]$gitDiscipline.integration.remoteIntegrationBranchMustEqualHeadAtClose -and
  [bool]$gitDiscipline.integration.cleanIntegratedWorktreeRemovalAllowed -and
  [bool]$gitDiscipline.integration.combinedRegressionRequired -and
  [bool]$gitDiscipline.integration.candidateBuildRequiresSeparateAuthorization -and
  [bool]$gitDiscipline.integration.integrationOwnerGitClosureResponsible
) 'integration discipline weakened.'
Assert-ExactNames $gitDiscipline.promotion @(
  'directFeatureToRemediationAllowed','mainFrozen','founderAuthorizationRequired',
  'newAnnotatedAcceptanceTagRequired','productionCheckoutCleanRequired',
  'remoteRemediationReadbackRequired'
) 'promotion discipline'
Assert-Coordination (
  -not [bool]$gitDiscipline.promotion.directFeatureToRemediationAllowed -and
  [bool]$gitDiscipline.promotion.mainFrozen -and
  [bool]$gitDiscipline.promotion.founderAuthorizationRequired -and
  [bool]$gitDiscipline.promotion.newAnnotatedAcceptanceTagRequired -and
  [bool]$gitDiscipline.promotion.productionCheckoutCleanRequired -and
  [bool]$gitDiscipline.promotion.remoteRemediationReadbackRequired
) 'promotion discipline weakened.'
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
  'digest output allowlist is',
  'Mandatory Codex/Cursor isolated production Git discipline',
  'moolsocial-parallel-production-discipline-20260824-v15',
  'Parallel mutation in one checkout is forbidden',
  'codex-cursor-baseline-reconciliation',
  '`governance_preflight`',
  'Cursor may hold at most one open UI/UX ticket',
  'zero Git dirt is mandatory',
  'ticket_acceptance',
  'whole batch',
  '`-ProductionLane` and `-ProductionPhase`'
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
  'suppress helper return objects',
  'Codex and Cursor isolated production Git discipline',
  'codex-cursor-baseline-reconciliation',
  'primary runs `governance_preflight`',
  'Each lane holds at most one open ticket',
  'integration/moolsocial/<work-id>',
  '`--no-ff` merge commits',
  'zero staged, unstaged and untracked files',
  '`ticket_acceptance` phase before push and `ticket_close`',
  'integration owner owns batch-wide Git closure',
  'moolsocial_ticket_founder_acceptance_v1',
  'moolsocial_ticket_oppo_acceptance_v1',
  'The machine policy is the authoritative lane, root, branch, owner, dependency, commit and integration contract'
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
$cursorUiOpenTasks = @($taskNames | Where-Object {
  $_.StartsWith('/root/cursor_', [StringComparison]::Ordinal)
})
$codexAuthOpenTasks = @($taskNames | Where-Object {
  $_.StartsWith('/root/codex_auth_', [StringComparison]::Ordinal)
})
$codexBackendOpenTasks = @($taskNames | Where-Object {
  $_.StartsWith('/root/codex_backend_', [StringComparison]::Ordinal)
})
Assert-Coordination (
  $cursorUiOpenTasks.Count -le
    [int]$gitDiscipline.agentTicketQueues.cursorUiMaximumOpenTickets -and
  $codexAuthOpenTasks.Count -le
    [int]$gitDiscipline.agentTicketQueues.codexAuthMaximumOpenTickets -and
  $codexBackendOpenTasks.Count -le
    [int]$gitDiscipline.agentTicketQueues.codexBackendMaximumOpenTickets
) 'an agent lane has more than one open production ticket.'
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
$runtimeBaselineHead = [string]$gitDiscipline.acceptedRuntimeBaseline.head
$runtimeBaselineBranch = [string]$gitDiscipline.acceptedRuntimeBaseline.branch
$runtimeBaselineTag = [string]$gitDiscipline.acceptedRuntimeBaseline.tag
$governanceTag = [string]$gitDiscipline.workStart.annotatedTag
$rootForward = ConvertTo-ProductionForwardPath $root
$productionCheckoutForward = [string]$gitDiscipline.productionCheckout

$runtimeTagCommitOutput = @(& git -C $root rev-parse `
    "$runtimeBaselineTag^{commit}" 2>$null)
$runtimeTagCommitExit = $LASTEXITCODE
Assert-Coordination (
  $runtimeTagCommitExit -eq 0 -and $runtimeTagCommitOutput.Count -eq 1 -and
  [string]$runtimeTagCommitOutput[0] -ceq $runtimeBaselineHead
) 'accepted runtime tag does not resolve to the accepted r60.87 commit.'
$runtimeTagTypeOutput = @(& git -C $root cat-file -t $runtimeBaselineTag 2>$null)
$runtimeTagTypeExit = $LASTEXITCODE
Assert-Coordination (
  $runtimeTagTypeExit -eq 0 -and $runtimeTagTypeOutput.Count -eq 1 -and
  [string]$runtimeTagTypeOutput[0] -ceq 'tag'
) 'accepted runtime tag is missing or not annotated.'

if ($ProductionLane -ceq 'baseline') {
  Assert-Coordination (
    $ProductionPhase -cin @('baseline','governance_preflight')
  ) 'baseline lane requires baseline or governance-preflight phase.'
  Assert-Coordination (
    $rootForward -ceq $productionCheckoutForward -and
    $branch -ceq $runtimeBaselineBranch
  ) 'production checkout branch or root changed.'
  if ($ProductionPhase -ceq 'governance_preflight') {
    & git -C $root merge-base --is-ancestor $runtimeBaselineHead $head
    $runtimeAncestorExit = $LASTEXITCODE
    Assert-Coordination ($runtimeAncestorExit -eq 0) `
      'governance preflight HEAD does not descend from accepted r60.87.'
    Assert-Coordination (Test-ProductionWorktreeClean) `
      'governance preflight requires zero staged, unstaged and untracked files.'
    Assert-ProductionManagedWorktreesClean
    $governanceMergeCommits = @(& git -C $root rev-list --merges `
        "$runtimeBaselineHead..$head")
    Assert-Coordination (
      $LASTEXITCODE -eq 0 -and $governanceMergeCommits.Count -eq 0
    ) 'governance preflight history contains a merge commit.'
    Assert-ProductionSecretSafe -BaseCommit $runtimeBaselineHead `
      -HeadCommit $head
  } else {
    $baselineHeadAccepted = $head -ceq $runtimeBaselineHead
    if (-not $baselineHeadAccepted) {
      $governanceTagOutput = @(& git -C $root rev-parse `
          "$governanceTag^{commit}" 2>$null)
      $governanceTagExit = $LASTEXITCODE
      $governanceTypeOutput = @(& git -C $root cat-file -t `
          $governanceTag 2>$null)
      $governanceTypeExit = $LASTEXITCODE
      & git -C $root merge-base --is-ancestor $runtimeBaselineHead $head
      $runtimeAncestorExit = $LASTEXITCODE
      $baselineHeadAccepted = (
        $governanceTagExit -eq 0 -and $governanceTagOutput.Count -eq 1 -and
        [string]$governanceTagOutput[0] -ceq $head -and
        $governanceTypeExit -eq 0 -and $governanceTypeOutput.Count -eq 1 -and
        [string]$governanceTypeOutput[0] -ceq 'tag' -and
        $runtimeAncestorExit -eq 0
      )
    }
    Assert-Coordination $baselineHeadAccepted `
      'production checkout HEAD is not the accepted runtime or governance tag.'
    if ($head -cne $runtimeBaselineHead) {
      Assert-Coordination (Test-ProductionWorktreeClean) `
        'production checkout must remain clean after the governance baseline.'
    }
  }
} else {
  Assert-Coordination (
    $ProductionPhase -cnotin @('baseline','governance_preflight')
  ) 'a production feature lane cannot use a baseline phase.'
  Assert-Coordination (
    $ProductionWorkId -cmatch '^[a-z0-9][a-z0-9-]{2,48}$'
  ) 'production work ID is missing or invalid.'
  Assert-Coordination (
    $ProductionTicketId -cmatch '^[A-Z0-9][A-Z0-9-]{4,159}$'
  ) 'production ticket ID is missing or invalid.'
  $selectedLane = @($productionLanes | Where-Object {
    [string]$_.id -ceq $ProductionLane
  })
  Assert-Coordination ($selectedLane.Count -eq 1) `
    'production lane has no exact machine contract.'
  $selectedLane = $selectedLane[0]
  Assert-Coordination (
    [string]$selectedLane.agentRole -ceq $AgentRole -and
    $AgentTask.StartsWith(
      [string]$selectedLane.taskPrefix,
      [StringComparison]::Ordinal
    )
  ) 'agent role or task does not match the selected production lane.'

  $workspaceParentForward = [string]$gitDiscipline.workspaceIsolation.workspaceParent
  $expectedWorktreeForward = (
    $workspaceParentForward + '/' + [string]$selectedLane.worktreePrefix +
    $ProductionWorkId
  )
  $parentAgentsForward = [string]$gitDiscipline.workspaceIsolation.parentAgentsPath
  Assert-Coordination (
    $rootForward -ceq $expectedWorktreeForward -and
    $rootForward -cne $productionCheckoutForward -and
    (Test-Path -LiteralPath $parentAgentsForward -PathType Leaf)
  ) 'production feature worktree root or parent AGENTS owner is invalid.'
  $expectedBranch = [string]$selectedLane.branchPrefix + $ProductionWorkId
  Assert-Coordination ($branch -ceq $expectedBranch) `
    'production feature branch does not match its lane and work ID.'

  $workStartCommitOutput = @(& git -C $root rev-parse `
      "$governanceTag^{commit}" 2>$null)
  $workStartCommitExit = $LASTEXITCODE
  Assert-Coordination (
    $workStartCommitExit -eq 0 -and $workStartCommitOutput.Count -eq 1 -and
    [string]$workStartCommitOutput[0] -cmatch '^[0-9a-f]{40}$'
  ) 'production governance work-start tag is missing.'
  $workStartCommit = [string]$workStartCommitOutput[0]
  $workStartTypeOutput = @(& git -C $root cat-file -t $governanceTag 2>$null)
  $workStartTypeExit = $LASTEXITCODE
  Assert-Coordination (
    $workStartTypeExit -eq 0 -and $workStartTypeOutput.Count -eq 1 -and
    [string]$workStartTypeOutput[0] -ceq 'tag'
  ) 'production governance work-start tag is not annotated.'
  & git -C $root merge-base --is-ancestor $runtimeBaselineHead $workStartCommit
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'production governance work-start does not descend from r60.87.'

  $baseCommit = $workStartCommit
  if ([string]$selectedLane.baseRule -ceq 'founder_accepted_ui_commit') {
    Assert-Coordination (
      $AcceptedUiCommit -cmatch '^[0-9a-f]{40}$' -and
      $FounderAcceptanceEvidenceSha256 -cmatch '^[0-9A-F]{64}$' -and
      $UiContractSha256 -cmatch '^[0-9A-F]{64}$'
    ) 'Codex backend requires exact accepted UI commit and evidence hashes.'
    $founderAcceptanceOwner = Resolve-ProductionEvidenceOwner `
      $FounderAcceptanceEvidencePath
    $uiContractOwner = Resolve-ProductionEvidenceOwner $UiContractPath
    Assert-Coordination (
      $founderAcceptanceOwner -cne $uiContractOwner -and
      (Get-Sha256 $founderAcceptanceOwner) -ceq
        $FounderAcceptanceEvidenceSha256 -and
      (Get-Sha256 $uiContractOwner) -ceq $UiContractSha256
    ) 'founder UI acceptance evidence or interaction contract hash differs.'
    $acceptedUiTypeOutput = @(& git -C $root cat-file -t `
        $AcceptedUiCommit 2>$null)
    $acceptedUiTypeExit = $LASTEXITCODE
    Assert-Coordination (
      $acceptedUiTypeExit -eq 0 -and $acceptedUiTypeOutput.Count -eq 1 -and
      [string]$acceptedUiTypeOutput[0] -ceq 'commit'
    ) 'accepted UI commit is not available in the repository.'
    & git -C $root merge-base --is-ancestor $workStartCommit $AcceptedUiCommit
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'accepted UI commit does not descend from the governance tag.'
    $baseCommit = $AcceptedUiCommit
  }
  & git -C $root merge-base --is-ancestor $baseCommit $head
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'production lane HEAD does not descend from its exact required base.'

  foreach ($effectiveOwner in $effectiveOwners) {
    $allowedOwner = $false
    foreach ($allowedRoot in @($selectedLane.allowedOwnerRoots)) {
      if (Test-ProductionOwnerRoot $effectiveOwner ([string]$allowedRoot)) {
        $allowedOwner = $true
        break
      }
    }
    Assert-Coordination $allowedOwner `
      "production lane claims an owner outside its allowlist: $effectiveOwner"
    foreach ($forbiddenRoot in @($selectedLane.forbiddenOwnerRoots)) {
      Assert-Coordination (
        -not (Test-ProductionOwnerRoot $effectiveOwner ([string]$forbiddenRoot))
      ) "production lane claims a forbidden owner: $effectiveOwner"
    }
  }

  $validPhases = switch ($ProductionLane) {
    'cursor_ui' {
      @(
        'task_start','implementation','pre_commit','handoff',
        'founder_acceptance','ticket_acceptance','ticket_close'
      )
    }
    'codex_auth' {
      @('task_start','implementation','pre_commit','handoff','ticket_acceptance','ticket_close')
    }
    'codex_backend' {
      @('task_start','implementation','pre_commit','handoff','ticket_acceptance','ticket_close')
    }
    'integration' {
      @('integration_start','integration_verify','integration_close','candidate_preflight')
    }
  }
  Assert-Coordination (@($validPhases) -ccontains $ProductionPhase) `
    'production phase is invalid for its selected lane.'

  if ($ProductionLane -cne 'integration') {
    $changedOwners = @(Get-ProductionChangedOwners $baseCommit $head)
    $effectiveOwnerKeys = @($effectiveOwners | ForEach-Object {
      $_.ToLowerInvariant()
    })
    foreach ($changedOwner in $changedOwners) {
      Assert-Coordination (
        $effectiveOwnerKeys.Contains($changedOwner.ToLowerInvariant())
      ) "production feature changed an owner outside its claim: $changedOwner"
    }
  }

  if ($ProductionPhase -ceq 'pre_commit') {
    $preCommitStagedOwners = @(& git -C $root diff --cached --name-only `
        --diff-filter=ACMRTUXBD)
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'production pre-commit staged-owner inventory failed.'
    $preCommitUnstagedOwners = @(& git -C $root diff --name-only `
        --diff-filter=ACMRTUXBD)
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'production pre-commit unstaged-owner inventory failed.'
    $preCommitUntrackedOwners = @(& git -C $root ls-files --others `
        --exclude-standard)
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'production pre-commit untracked-owner inventory failed.'
    Assert-Coordination (
      $preCommitStagedOwners.Count -gt 0 -and
      $preCommitUnstagedOwners.Count -eq 0 -and
      $preCommitUntrackedOwners.Count -eq 0
    ) 'production pre-commit requires one fully staged atomic change set.'
    Assert-ProductionSecretSafe -BaseCommit $baseCommit -HeadCommit $head `
      -IndexOnly
  }

  if ($ProductionPhase -ceq 'task_start') {
    Assert-Coordination (
      $head -ceq $baseCommit -and (Test-ProductionWorktreeClean)
    ) 'production task start must be clean at its exact required base.'
  }

  if ($ProductionPhase -cin @(
      'handoff','founder_acceptance','ticket_acceptance','ticket_close'
    )) {
    Assert-Coordination ($head -cne $baseCommit) `
      'production handoff contains no feature commit.'
    Assert-Coordination (Test-ProductionWorktreeClean) `
      'production handoff worktree is not clean.'
    $featureMergeCommits = @(& git -C $root rev-list --merges `
        "$baseCommit..$head")
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'production feature merge inventory failed.'
    Assert-Coordination ($featureMergeCommits.Count -eq 0) `
      'production feature branch contains a merge commit.'
    $featureCommits = @(& git -C $root rev-list --reverse `
        "$baseCommit..$head")
    Assert-Coordination ($LASTEXITCODE -eq 0 -and $featureCommits.Count -gt 0) `
      'production feature commit inventory is empty or failed.'
    $subjectPattern = (
      '^' + [regex]::Escape([string]$selectedLane.commitPrefix) + '\(' +
      [regex]::Escape($ProductionWorkId) + '\): .+'
    )
    foreach ($featureCommit in $featureCommits) {
      $subjectOutput = @(& git -C $root show -s --format='%s' $featureCommit)
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $subjectOutput.Count -eq 1 -and
        [string]$subjectOutput[0] -cmatch $subjectPattern
      ) "production feature commit subject is not atomic: $featureCommit"
    }
    Assert-ProductionSecretSafe -BaseCommit $baseCommit -HeadCommit $head
  }

  if ($ProductionPhase -ceq 'founder_acceptance') {
    Assert-Coordination ($ProductionLane -ceq 'cursor_ui') `
      'founder UI acceptance phase is valid only for Cursor UI.'
    Assert-Coordination (
      $AcceptedUiCommit -ceq $head -and
      $FounderAcceptanceEvidenceSha256 -cmatch '^[0-9A-F]{64}$' -and
      $UiContractSha256 -cmatch '^[0-9A-F]{64}$'
    ) 'founder UI acceptance lacks exact commit or evidence hashes.'
    $founderAcceptanceOwner = Resolve-ProductionEvidenceOwner `
      $FounderAcceptanceEvidencePath
    $uiContractOwner = Resolve-ProductionEvidenceOwner $UiContractPath
    Assert-Coordination (
      $founderAcceptanceOwner -cne $uiContractOwner -and
      (Get-Sha256 $founderAcceptanceOwner) -ceq
        $FounderAcceptanceEvidenceSha256 -and
      (Get-Sha256 $uiContractOwner) -ceq $UiContractSha256
    ) 'founder UI acceptance evidence or interaction contract is not sealed.'
  }

  if ($ProductionPhase -cin @('ticket_acceptance','ticket_close')) {
    Assert-Coordination (
      $AcceptedTicketCommit -cmatch '^[0-9a-f]{40}$' -and
      $AcceptedTicketCommit -cne $head -and
      $TicketRequirementEvidenceSha256 -cmatch '^[0-9A-F]{64}$' -and
      $OppoAcceptanceEvidenceSha256 -cmatch '^[0-9A-F]{64}$'
    ) 'ticket closure lacks the exact accepted commit or evidence hashes.'
    $acceptedTicketTypeOutput = @(& git -C $root cat-file -t `
        $AcceptedTicketCommit 2>$null)
    Assert-Coordination (
      $LASTEXITCODE -eq 0 -and $acceptedTicketTypeOutput.Count -eq 1 -and
      [string]$acceptedTicketTypeOutput[0] -ceq 'commit'
    ) 'ticket accepted implementation commit is unavailable.'
    $closureParentOutput = @(& git -C $root show -s --format='%P' $head)
    Assert-Coordination (
      $LASTEXITCODE -eq 0 -and $closureParentOutput.Count -eq 1 -and
      @([string]$closureParentOutput[0] -split ' ').Count -eq 1 -and
      [string]$closureParentOutput[0] -ceq $AcceptedTicketCommit
    ) 'ticket closure HEAD is not one evidence-only child of the accepted implementation commit.'
    $ticketRequirementEvidenceRelative = Get-CanonicalOwner `
      $TicketRequirementEvidencePath
    $oppoAcceptanceEvidenceRelative = Get-CanonicalOwner `
      $OppoAcceptanceEvidencePath
    $ticketRequirementEvidenceOwner = Resolve-ProductionEvidenceOwner `
      $ticketRequirementEvidenceRelative
    $oppoAcceptanceEvidenceOwner = Resolve-ProductionEvidenceOwner `
      $oppoAcceptanceEvidenceRelative
    $closureOwners = @(& git -C $root diff --name-only `
        --diff-filter=ACMRTUXBD "$AcceptedTicketCommit..$head")
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'ticket evidence-only closure owner inventory failed.'
    Assert-Coordination (
      $closureOwners.Count -eq 2 -and
      (@($closureOwners | Sort-Object) -join '|') -ceq
        ((@(
            $ticketRequirementEvidenceRelative,
            $oppoAcceptanceEvidenceRelative
          ) | Sort-Object) -join '|')
    ) 'ticket closure commit contains a non-evidence owner.'
    Assert-Coordination (
      $ticketRequirementEvidenceOwner -cne $oppoAcceptanceEvidenceOwner -and
      (Get-Sha256 $ticketRequirementEvidenceOwner) -ceq
        $TicketRequirementEvidenceSha256 -and
      (Get-Sha256 $oppoAcceptanceEvidenceOwner) -ceq
        $OppoAcceptanceEvidenceSha256
    ) 'ticket founder or OPPO acceptance evidence hash differs.'
    try {
      $ticketRequirementEvidence = Get-Content -Raw -LiteralPath `
        $ticketRequirementEvidenceOwner | ConvertFrom-Json
    } catch {
      throw 'Codex subagent coordination gate rejected: ticket founder acceptance evidence JSON is invalid.'
    }
    try {
      $oppoAcceptanceEvidence = Get-Content -Raw -LiteralPath `
        $oppoAcceptanceEvidenceOwner | ConvertFrom-Json
    } catch {
      throw 'Codex subagent coordination gate rejected: ticket OPPO acceptance evidence JSON is invalid.'
    }
    Assert-ExactNames $ticketRequirementEvidence @(
      'schema','ticketId','workId','lane','acceptedCommit',
      'requirementsSatisfied','founderDecision','acceptedAtIst',
      'privateValuesEmitted'
    ) 'ticket founder acceptance evidence'
    Assert-ExactNames $oppoAcceptanceEvidence @(
      'schema','ticketId','workId','lane','acceptedCommit','deviceClass',
      'ticketRequirementTested','result','testedAtIst','privateValuesEmitted'
    ) 'ticket OPPO acceptance evidence'
    $istTimestampPattern = (
      '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:' +
      '[0-9]{2}(?:[.][0-9]+)?[+]05:30$'
    )
    Assert-Coordination (
      [string]$ticketRequirementEvidence.schema -ceq
        [string]$gitDiscipline.ticketClosure.founderEvidenceSchema -and
      [string]$ticketRequirementEvidence.ticketId -ceq $ProductionTicketId -and
      [string]$ticketRequirementEvidence.workId -ceq $ProductionWorkId -and
      [string]$ticketRequirementEvidence.lane -ceq $ProductionLane -and
      [string]$ticketRequirementEvidence.acceptedCommit -ceq
        $AcceptedTicketCommit -and
      $ticketRequirementEvidence.requirementsSatisfied -is [bool] -and
      [bool]$ticketRequirementEvidence.requirementsSatisfied -and
      [string]$ticketRequirementEvidence.founderDecision -ceq 'accepted' -and
      [string]$ticketRequirementEvidence.acceptedAtIst -cmatch
        $istTimestampPattern -and
      $ticketRequirementEvidence.privateValuesEmitted -is [bool] -and
      -not [bool]$ticketRequirementEvidence.privateValuesEmitted
    ) 'ticket founder acceptance evidence does not prove acceptance.'
    Assert-Coordination (
      [string]$oppoAcceptanceEvidence.schema -ceq
        [string]$gitDiscipline.ticketClosure.oppoEvidenceSchema -and
      [string]$oppoAcceptanceEvidence.ticketId -ceq $ProductionTicketId -and
      [string]$oppoAcceptanceEvidence.workId -ceq $ProductionWorkId -and
      [string]$oppoAcceptanceEvidence.lane -ceq $ProductionLane -and
      [string]$oppoAcceptanceEvidence.acceptedCommit -ceq
        $AcceptedTicketCommit -and
      [string]$oppoAcceptanceEvidence.deviceClass -ceq 'OPPO' -and
      $oppoAcceptanceEvidence.ticketRequirementTested -is [bool] -and
      [bool]$oppoAcceptanceEvidence.ticketRequirementTested -and
      [string]$oppoAcceptanceEvidence.result -ceq 'passed' -and
      [string]$oppoAcceptanceEvidence.testedAtIst -cmatch
        $istTimestampPattern -and
      $oppoAcceptanceEvidence.privateValuesEmitted -is [bool] -and
      -not [bool]$oppoAcceptanceEvidence.privateValuesEmitted
    ) 'ticket OPPO acceptance evidence does not prove the requirement passed.'
    if ($ProductionPhase -ceq 'ticket_close') {
      $remoteTicketHead = Get-ProductionRemoteBranchHead $branch
      Assert-Coordination ($remoteTicketHead -ceq $head) `
        'ticket remote branch does not equal the accepted clean HEAD.'
    }
  }

  if ($ProductionPhase -ceq 'integration_start') {
    Assert-Coordination (
      $head -ceq $workStartCommit -and (Test-ProductionWorktreeClean)
    ) 'integration must start clean at the governance tag.'
    Assert-ProductionManagedWorktreesClean
  }

  if ($ProductionPhase -cin @(
      'integration_verify','integration_close','candidate_preflight'
    )) {
    Assert-Coordination (Test-ProductionWorktreeClean) `
      'integration verification requires a clean worktree.'
    Assert-ProductionManagedWorktreesClean
    $approvedCommits = @($ApprovedFeatureCommits | ForEach-Object {
      [string]$_
    })
    $approvedBranches = @($ApprovedFeatureBranches | ForEach-Object {
      [string]$_
    })
    Assert-Coordination (
      $approvedCommits.Count -gt 0 -and
      @($approvedCommits | Select-Object -Unique).Count -eq
        $approvedCommits.Count -and
      $approvedBranches.Count -eq $approvedCommits.Count -and
      @($approvedBranches | Select-Object -Unique).Count -eq
        $approvedBranches.Count
    ) 'integration requires unique approved feature commits and branches.'
    $firstParentDirectCommits = @(& git -C $root rev-list --first-parent `
        --no-merges "$workStartCommit..$head")
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'integration first-parent direct-commit inventory failed.'
    Assert-Coordination ($firstParentDirectCommits.Count -eq 0) `
      'integration contains a forbidden direct first-parent commit.'
    $integrationMerges = @(& git -C $root rev-list --first-parent --merges `
        "$workStartCommit..$head")
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'integration merge inventory failed.'
    Assert-Coordination ($integrationMerges.Count -eq $approvedCommits.Count) `
      'integration merge count differs from approved feature commit count.'
    $mergedFeatureTips = @()
    foreach ($integrationMerge in $integrationMerges) {
      $parentOutput = @(& git -C $root show -s --format='%P' $integrationMerge)
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $parentOutput.Count -eq 1
      ) "integration merge parent read failed: $integrationMerge"
      $parentCommits = @([string]$parentOutput[0] -split ' ')
      Assert-Coordination ($parentCommits.Count -eq 2) `
        "integration commit is not one exact two-parent merge: $integrationMerge"
      $expectedMergeTreeOutput = @(& git -C $root merge-tree --write-tree `
          $parentCommits[0] $parentCommits[1] 2>$null)
      $expectedMergeTreeExit = $LASTEXITCODE
      Assert-Coordination (
        $expectedMergeTreeExit -eq 0 -and
        $expectedMergeTreeOutput.Count -ge 1 -and
        [string]$expectedMergeTreeOutput[0] -cmatch '^[0-9a-f]{40}$'
      ) "integration feature commit does not merge cleanly: $integrationMerge"
      $actualMergeTreeOutput = @(& git -C $root show -s --format='%T' `
          $integrationMerge)
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $actualMergeTreeOutput.Count -eq 1 -and
        [string]$actualMergeTreeOutput[0] -ceq
          [string]$expectedMergeTreeOutput[0]
      ) "integration merge contains forbidden source edits: $integrationMerge"
      $integrationSubjectOutput = @(& git -C $root show -s --format='%s' `
          $integrationMerge)
      $integrationSubjectPattern = (
        '^' + [regex]::Escape([string]$selectedLane.commitPrefix) + '\(' +
        [regex]::Escape($ProductionWorkId) + '\): .+'
      )
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $integrationSubjectOutput.Count -eq 1 -and
        [string]$integrationSubjectOutput[0] -cmatch $integrationSubjectPattern
      ) "integration merge subject is not atomic: $integrationMerge"
      $mergedFeatureTips += $parentCommits[1]
    }
    Assert-Coordination (
      (@($mergedFeatureTips | Sort-Object) -join '|') -ceq
        (@($approvedCommits | Sort-Object) -join '|')
    ) 'integration merge parents differ from approved feature commits.'
    for ($approvedIndex = 0; $approvedIndex -lt $approvedCommits.Count;
        $approvedIndex++) {
      $approvedCommit = [string]$approvedCommits[$approvedIndex]
      $approvedBranch = [string]$approvedBranches[$approvedIndex]
      Assert-Coordination ($approvedCommit -cmatch '^[0-9a-f]{40}$') `
        'approved feature commit SHA is invalid.'
      $approvedTypeOutput = @(& git -C $root cat-file -t `
          $approvedCommit 2>$null)
      $approvedTypeExit = $LASTEXITCODE
      Assert-Coordination (
        $approvedTypeExit -eq 0 -and $approvedTypeOutput.Count -eq 1 -and
        [string]$approvedTypeOutput[0] -ceq 'commit'
      ) "approved feature commit is unavailable: $approvedCommit"
      & git -C $root merge-base --is-ancestor $workStartCommit $approvedCommit
      Assert-Coordination ($LASTEXITCODE -eq 0) `
        "approved feature commit does not descend from governance: $approvedCommit"
      & git -C $root merge-base --is-ancestor $approvedCommit $head
      Assert-Coordination ($LASTEXITCODE -eq 0) `
        "approved feature commit is not integrated: $approvedCommit"
      $approvedRemoteHead = Get-ProductionRemoteBranchHead $approvedBranch
      Assert-Coordination ($approvedRemoteHead -ceq $approvedCommit) `
        "approved feature remote branch differs from its accepted commit: $approvedBranch"
    }
    Assert-ProductionSecretSafe -BaseCommit $workStartCommit -HeadCommit $head
    if ($ProductionPhase -cin @('integration_close','candidate_preflight')) {
      $remoteIntegrationHead = Get-ProductionRemoteBranchHead $branch
      Assert-Coordination ($remoteIntegrationHead -ceq $head) `
        'integration remote branch does not equal its clean verified HEAD.'
    }
  }
}

$resultLine = (
  (
    'Codex subagent coordination policy passed: policy={0}; role={1}; ' +
    'task={2}; claims={3}; activeTasks={4}; registry={5}; ' +
    'numericPrefixesUnique=true; branchHead=true; productionLane={6}; ' +
    'productionPhase={7}; releaseActionOwner=primary.'
  ) -f
    $policy.policyId,$AgentRole,$AgentTask,$effectiveOwners.Count,$claims.Count,
    $registryEntries.Count,$ProductionLane,$ProductionPhase
)
Assert-Coordination ($resultLine -cnotmatch '\{[0-9]+\}') `
  'coordination pass output retained an unresolved format placeholder.'
Write-Output $resultLine
