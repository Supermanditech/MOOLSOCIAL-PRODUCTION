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
  [ValidateSet('baseline','cursor_ui','codex_auth','codex_backend','integration_repair','integration')]
  [string]$ProductionLane = 'baseline',
  [ValidateSet(
    'baseline','governance_preflight','coordination_bootstrap','task_start','implementation','pre_commit','handoff',
    'founder_acceptance','ticket_acceptance','ticket_close',
    'integration_start','integration_verify','integration_close','integration_admission_authorize',
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
  [string]$IntegrationTargetRoot,
  [string]$IntegrationTargetWorkId,
  [string]$IntegrationTargetTicketId,
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
    $BranchName -cmatch '^(?:work/(?:cursor-ui|codex-auth|codex-backend|integration-repair)/|integration/moolsocial/)[a-z0-9][a-z0-9-]{2,48}$'
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

function Assert-IntegrationRepairMerge(
  [string]$FirstParent,
  [string]$SecondParent,
  [string]$ActualTree
) {
  Assert-Coordination (
    $SecondParent -ceq [string]$integrationRepair.requiredCursorCommit
  ) 'integration repair merge second parent changed.'
  Assert-Coordination (
    $FirstParent -cmatch '^[0-9a-f]{40}$' -and
    $ActualTree -cmatch '^[0-9a-f]{40}$'
  ) 'integration repair parent or tree identity is invalid.'

  $mergeTreeOutput = @(& git -C $root merge-tree --write-tree `
      $FirstParent $SecondParent 2>&1)
  $mergeTreeExit = $LASTEXITCODE
  Assert-Coordination (
    $mergeTreeExit -eq 1 -and $mergeTreeOutput.Count -ge 1 -and
    [string]$mergeTreeOutput[0] -cmatch '^[0-9a-f]{40}$'
  ) 'integration repair no longer reproduces one bounded conflict merge.'
  $automaticTree = [string]$mergeTreeOutput[0]
  $actualConflictOwners = @()
  foreach ($mergeTreeLine in $mergeTreeOutput) {
    $mergeTreeText = [string]$mergeTreeLine
    if ($mergeTreeText -cmatch '^CONFLICT \(.+\): Merge conflict in (.+)$') {
      $actualConflictOwners += Get-CanonicalOwner $Matches[1]
    }
  }
  $actualConflictOwners = @($actualConflictOwners | Sort-Object -Unique)
  Assert-Coordination (
    (@($actualConflictOwners | Sort-Object) -join '|') -ceq
      (@($expectedRepairUnmergedOwners | Sort-Object) -join '|')
  ) 'integration repair conflict inventory changed.'

  $manualDeltaOwners = @(& git -C $root diff --name-only `
      $automaticTree $ActualTree)
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'integration repair automatic-tree comparison failed.'
  Assert-Coordination (
    (@($manualDeltaOwners | Sort-Object) -join '|') -ceq
      (@($expectedRepairConflictOwners | Sort-Object) -join '|')
  ) 'integration repair resolved delta does not equal every exact conflict owner.'
  $expectedRepairConflictKeys = @($expectedRepairConflictOwners |
    ForEach-Object { $_.ToLowerInvariant() })
  $repairOwnerClaim = @($claims | Where-Object {
    [string]$_.task -ceq '/root/repair_shop_chat_shared_v1_20260829'
  })
  Assert-Coordination ($repairOwnerClaim.Count -eq 1) `
    'integration repair exact owner claim is missing or ambiguous.'
  $repairOwnerClaimKeys = @($repairOwnerClaim[0].owners | ForEach-Object {
    ([string]$_).ToLowerInvariant()
  })
  foreach ($manualDeltaOwner in $manualDeltaOwners) {
    $canonicalManualOwner = Get-CanonicalOwner ([string]$manualDeltaOwner)
    Assert-Coordination (
      $expectedRepairConflictKeys.Contains(
        $canonicalManualOwner.ToLowerInvariant()
      ) -and
      $repairOwnerClaimKeys.Contains($canonicalManualOwner.ToLowerInvariant())
    ) "integration repair manually changed a non-conflict owner: $canonicalManualOwner"
    $resolvedBlobSpec = '{0}:{1}' -f $ActualTree,$canonicalManualOwner
    $resolvedBlobLines = @(& git -C $root show $resolvedBlobSpec)
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      "integration repair resolved blob is unreadable: $canonicalManualOwner"
    $resolvedMarkerLines = @($resolvedBlobLines | Where-Object {
      [string]$_ -cmatch '^(?:<<<<<<<|=======|>>>>>>>)'
    })
    Assert-Coordination ($resolvedMarkerLines.Count -eq 0) `
      "integration repair resolved blob retains conflict markers: $canonicalManualOwner"
  }
}

function Assert-QualifiedIntegrationRepairTip([string]$RepairCommit) {
  $repairType = @(& git -C $root cat-file -t $RepairCommit 2>$null)
  Assert-Coordination (
    $LASTEXITCODE -eq 0 -and $repairType.Count -eq 1 -and
    [string]$repairType[0] -ceq 'commit'
  ) 'qualified integration repair tip is unavailable.'
  $repairBinding = @($continuationBindings | Where-Object {
    [string]$_.lane -ceq 'integration_repair' -and
    [string]$_.task -ceq '/root/repair_shop_chat_shared_v1_20260829'
  })
  Assert-Coordination ($repairBinding.Count -eq 1) `
    'qualified integration repair continuation is missing or ambiguous.'
  $repairBaseline = [string]$repairBinding[0].baselineHead
  Assert-Coordination (
    $repairBaseline -ceq [string]$integrationRepair.requiredCodexCommit
  ) 'qualified integration repair baseline changed.'
  & git -C $root merge-base --is-ancestor $repairBaseline $RepairCommit
  Assert-Coordination ($LASTEXITCODE -eq 0) `
    'qualified integration repair does not descend from the sealed Codex tip.'

  $repairHistory = @(& git -C $root rev-list --first-parent --reverse `
      "$repairBaseline..$RepairCommit")
  Assert-Coordination ($LASTEXITCODE -eq 0 -and $repairHistory.Count -ge 4) `
    'qualified integration repair history is incomplete.'
  $repairBootstrap = [string]$repairHistory[0]
  $bootstrapParents = @(& git -C $root show -s --format='%P' $repairBootstrap)
  $bootstrapSubject = @(& git -C $root show -s --format='%s' $repairBootstrap)
  $bootstrapOwners = @(& git -C $root diff --name-only `
      "$repairBaseline..$repairBootstrap")
  Assert-Coordination (
    $LASTEXITCODE -eq 0 -and $bootstrapParents.Count -eq 1 -and
    [string]$bootstrapParents[0] -ceq $repairBaseline -and
    $bootstrapSubject.Count -eq 1 -and
    [string]$bootstrapSubject[0] -ceq
      [string]$repairBinding[0].bootstrapCommitSubject -and
    (@($bootstrapOwners | Sort-Object) -join '|') -ceq
      (@($repairBinding[0].bootstrapOwners | Sort-Object) -join '|')
  ) 'qualified integration repair bootstrap changed.'

  $repairMergeCommits = @(& git -C $root rev-list --first-parent --merges `
      "$repairBootstrap..$RepairCommit")
  Assert-Coordination (
    $LASTEXITCODE -eq 0 -and $repairMergeCommits.Count -eq
      [int]$integrationRepair.maximumMergeCommits
  ) 'qualified integration repair merge count changed.'
  $repairMergeCommit = [string]$repairMergeCommits[0]
  $repairMergeParentsOutput = @(& git -C $root show -s --format='%P' `
      $repairMergeCommit)
  Assert-Coordination (
    $LASTEXITCODE -eq 0 -and $repairMergeParentsOutput.Count -eq 1
  ) 'qualified integration repair merge parent read failed.'
  $repairMergeParents = @([string]$repairMergeParentsOutput[0] -split ' ')
  Assert-Coordination (
    $repairMergeParents.Count -eq 2 -and
    $repairMergeParents[1] -ceq [string]$integrationRepair.requiredCursorCommit
  ) 'qualified integration repair merge second parent changed.'

  $preMergeCommits = @(& git -C $root rev-list --reverse --no-merges `
      "$repairBootstrap..$($repairMergeParents[0])")
  $preMergeOwners = @(& git -C $root diff --name-only `
      "$repairBootstrap..$($repairMergeParents[0])")
  Assert-Coordination (
    $LASTEXITCODE -eq 0 -and $preMergeCommits.Count -eq
      [int]$integrationRepair.maximumPreMergeCoordinationCommits -and
    $preMergeCommits[-1] -ceq $repairMergeParents[0] -and
    (@($preMergeOwners | Sort-Object) -join '|') -ceq
      (@($integrationRepair.preMergeCoordinationOwners | Sort-Object) -join '|')
  ) 'qualified integration repair pre-merge correction changed.'
  $preMergeAllowedKeys = @($integrationRepair.preMergeCoordinationOwners |
    ForEach-Object { ([string]$_).ToLowerInvariant() })
  foreach ($preMergeCommit in $preMergeCommits) {
    $preMergeSubject = @(& git -C $root show -s --format='%s' $preMergeCommit)
    $preMergeCommitOwners = @(& git -C $root diff-tree --no-commit-id `
        --name-only -r $preMergeCommit)
    Assert-Coordination (
      $LASTEXITCODE -eq 0 -and $preMergeSubject.Count -eq 1 -and
      [string]$preMergeSubject[0] -cmatch
        '^repair\(shop-chat-shared-v1-20260829\): .+' -and
      @($preMergeCommitOwners | Where-Object {
        -not $preMergeAllowedKeys.Contains(([string]$_).ToLowerInvariant())
      }).Count -eq 0
    ) 'qualified integration repair contains a forbidden pre-merge commit.'
  }

  $repairMergeSubject = @(& git -C $root show -s --format='%s' `
      $repairMergeCommit)
  Assert-Coordination (
    $LASTEXITCODE -eq 0 -and $repairMergeSubject.Count -eq 1 -and
    [string]$repairMergeSubject[0] -cmatch
      '^repair\(shop-chat-shared-v1-20260829\): .+'
  ) 'qualified integration repair merge subject changed.'
  $repairMergeTree = (& git -C $root show -s --format='%T' `
      $repairMergeCommit).Trim()
  Assert-Coordination (
    $LASTEXITCODE -eq 0 -and $repairMergeTree -cmatch '^[0-9a-f]{40}$'
  ) 'qualified integration repair merge tree read failed.'
  Assert-IntegrationRepairMerge -FirstParent $repairMergeParents[0] `
    -SecondParent $repairMergeParents[1] -ActualTree $repairMergeTree

  $postMergeCommits = @(& git -C $root rev-list --reverse `
      "$repairMergeCommit..$RepairCommit")
  $postMergeMerges = @(& git -C $root rev-list --merges `
      "$repairMergeCommit..$RepairCommit")
  Assert-Coordination (
    $LASTEXITCODE -eq 0 -and $postMergeMerges.Count -eq 0 -and
    $postMergeCommits.Count -le
      [int]$integrationRepair.maximumPostMergeClosureCommits
  ) 'qualified integration repair post-merge history changed.'
  if ($postMergeCommits.Count -eq 0) {
    Assert-Coordination ($RepairCommit -ceq $repairMergeCommit) `
      'qualified integration repair tip moved beyond its merge unexpectedly.'
  } else {
    $postMergeOwners = @(& git -C $root diff --name-only `
        "$repairMergeCommit..$RepairCommit")
    Assert-Coordination (
      $LASTEXITCODE -eq 0 -and
      $postMergeCommits[-1] -ceq $RepairCommit -and
      (@($postMergeOwners | Sort-Object) -join '|') -ceq
        (@($integrationRepair.postMergeClosureOwners | Sort-Object) -join '|')
    ) 'qualified integration repair closure commit changed.'
    $postMergeAllowedKeys = @($integrationRepair.postMergeClosureOwners |
      ForEach-Object { ([string]$_).ToLowerInvariant() })
    foreach ($postMergeCommit in $postMergeCommits) {
      $postMergeSubject = @(& git -C $root show -s --format='%s' `
          $postMergeCommit)
      $postMergeCommitOwners = @(& git -C $root diff-tree --no-commit-id `
          --name-only -r $postMergeCommit)
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $postMergeSubject.Count -eq 1 -and
        [string]$postMergeSubject[0] -cmatch
          '^repair\(shop-chat-shared-v1-20260829\): .+' -and
        @($postMergeCommitOwners | Where-Object {
          -not $postMergeAllowedKeys.Contains(
            ([string]$_).ToLowerInvariant()
          )
        }).Count -eq 0
      ) 'qualified integration repair contains a forbidden closure commit.'
    }
  }

  $codexRemoteHead = Get-ProductionRemoteBranchHead `
    ([string]$integrationRepair.requiredCodexBranch)
  $cursorRemoteHead = Get-ProductionRemoteBranchHead `
    ([string]$integrationRepair.requiredCursorBranch)
  Assert-Coordination (
    $codexRemoteHead -ceq [string]$integrationRepair.requiredCodexCommit -and
    $cursorRemoteHead -ceq [string]$integrationRepair.requiredCursorCommit
  ) 'qualified integration repair sealed source remote changed.'
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
  'continuationBindings','workspaceIsolation','cleanGitState','ticketClosure','agentTicketQueues',
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
    'moolsocial-parallel-production-discipline-20260824-v86' -and
  [bool]$gitDiscipline.workStart.mustDescendFromAcceptedRuntimeBaseline -and
  [bool]$gitDiscipline.workStart.featureBranchesMustStartAtTag
) 'production work-start contract changed.'
$continuationBindings = @($gitDiscipline.continuationBindings)
Assert-Coordination ($continuationBindings.Count -eq 58) `
  'founder-authorized continuation binding inventory changed.'
$continuationBindingIds = @()
foreach ($continuationBinding in $continuationBindings) {
  Assert-ExactNames $continuationBinding @(
    'id','state','lane','role','task','workId','ticketId','worktreePath',
    'branch','baselineHead','bootstrapCommitSubject','bootstrapOwners',
    'cursorIndependent','integrationRequiredBeforeSuccessorApk'
  ) 'founder-authorized continuation binding'
  $continuationBranchPrefix = switch ([string]$continuationBinding.lane) {
    'cursor_ui' { 'work/cursor-ui/' }
    'codex_auth' { 'work/codex-auth/' }
    'integration_repair' { 'work/integration-repair/' }
    default { '' }
  }
  Assert-Coordination (
    [string]$continuationBinding.id -cmatch '^[a-z0-9][a-z0-9_]{4,79}$' -and
    [string]$continuationBinding.state -cin @(
      'founder_authorized_2026_08_25',
      'founder_authorized_2026_08_26',
      'founder_authorized_2026_08_28',
      'founder_authorized_2026_08_29',
      'founder_authorized_2026_09_02'
    ) -and
    [string]$continuationBinding.lane -cin @('cursor_ui','codex_auth','integration_repair') -and
    [string]$continuationBinding.role -cin @('primary','subagent') -and
    [string]$continuationBinding.task -cmatch '^/root/[a-z0-9_]+$' -and
    [string]$continuationBinding.workId -cmatch '^[a-z0-9][a-z0-9-]{2,48}$' -and
    [string]$continuationBinding.ticketId -cmatch '^[A-Z0-9][A-Z0-9-]{4,159}$' -and
    [string]$continuationBinding.branch -ceq
      ($continuationBranchPrefix + [string]$continuationBinding.workId) -and
    [string]$continuationBinding.baselineHead -cmatch '^[0-9a-f]{40}$' -and
    [string]$continuationBinding.bootstrapCommitSubject -cmatch
      '^coordination\([a-z0-9][a-z0-9-]{2,48}\): .+' -and
    @($continuationBinding.bootstrapOwners).Count -ge 2 -and
    (
      [bool]$continuationBinding.cursorIndependent -or
      [string]$continuationBinding.lane -ceq 'integration_repair'
    ) -and
    [bool]$continuationBinding.integrationRequiredBeforeSuccessorApk
  ) 'founder-authorized continuation binding is invalid or weakened.'
  $continuationBindingIds += [string]$continuationBinding.id
}
Assert-Coordination (
  @($continuationBindingIds | Select-Object -Unique).Count -eq
    $continuationBindingIds.Count
) 'founder-authorized continuation binding ID is duplicated.'
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
  'codexBackendMaximumOpenTickets','integrationRepairMaximumOpenTickets',
  'priorTicketClosureRequired',
  'founderSelectsExactNextTicket','crossLaneImplementationAllowed',
  'plannedCodexAuthenticationProviders','authPrebuildBatch'
) 'agent ticket queue discipline'
$plannedCodexAuthenticationProviders = @(
  $gitDiscipline.agentTicketQueues.plannedCodexAuthenticationProviders |
    ForEach-Object { [string]$_ }
)
Assert-Coordination (
  [int]$gitDiscipline.agentTicketQueues.cursorUiMaximumOpenTickets -eq 1 -and
  [int]$gitDiscipline.agentTicketQueues.codexAuthMaximumOpenTickets -eq 1 -and
  [int]$gitDiscipline.agentTicketQueues.codexBackendMaximumOpenTickets -eq 1 -and
  [int]$gitDiscipline.agentTicketQueues.integrationRepairMaximumOpenTickets -eq 1 -and
  [bool]$gitDiscipline.agentTicketQueues.priorTicketClosureRequired -and
  [bool]$gitDiscipline.agentTicketQueues.founderSelectsExactNextTicket -and
  -not [bool]$gitDiscipline.agentTicketQueues.crossLaneImplementationAllowed -and
  (@($plannedCodexAuthenticationProviders) -join '|') -ceq
    'email_link|facebook|instagram|youtube_connect|x'
) 'agent ticket queue discipline weakened.'
$authPrebuildBatch = $gitDiscipline.agentTicketQueues.authPrebuildBatch
Assert-ExactNames $authPrebuildBatch @(
  'state','orderedProviders','maximumActiveMutationTickets',
  'priorProviderImplementationAndQualificationCommitsRequired',
  'runtimeAcceptanceDeferredUntilOneCombinedApk','finalTicketCloseStillRequired',
  'currentProvider','completedPrebuildProviders'
) 'authentication prebuild batch'
$completedPrebuildProviders = @($authPrebuildBatch.completedPrebuildProviders)
Assert-Coordination (
  [string]$authPrebuildBatch.state -ceq
    'founder_authorized_runtime_acceptance_deferred_2026_08_24' -and
  (@($authPrebuildBatch.orderedProviders) -join '|') -ceq
    'email_link|facebook|youtube_connect|x|instagram' -and
  [int]$authPrebuildBatch.maximumActiveMutationTickets -eq 1 -and
  [bool]$authPrebuildBatch.priorProviderImplementationAndQualificationCommitsRequired -and
  [bool]$authPrebuildBatch.runtimeAcceptanceDeferredUntilOneCombinedApk -and
  [bool]$authPrebuildBatch.finalTicketCloseStillRequired -and
  [string]$authPrebuildBatch.currentProvider -ceq 'youtube_connect' -and
  $completedPrebuildProviders.Count -eq 2
) 'authentication prebuild batch weakened or changed.'
$emailLinkPrebuild = $completedPrebuildProviders[0]
Assert-ExactNames $emailLinkPrebuild @(
  'provider','ticketId','branch','implementationCommit','qualificationCommit',
  'remoteQualified','runtimeAcceptancePending'
) 'email-link prebuild qualification'
Assert-Coordination (
  [string]$emailLinkPrebuild.provider -ceq 'email_link' -and
  [string]$emailLinkPrebuild.ticketId -ceq
    'UAW-CODEX-EMAIL-LINK-AUTH-20260823' -and
  [string]$emailLinkPrebuild.branch -ceq
    'work/codex-auth/email-link-auth-20260823' -and
  [string]$emailLinkPrebuild.implementationCommit -ceq
    '883f1d06c315438823c801b184b990b672c77f85' -and
  [string]$emailLinkPrebuild.qualificationCommit -ceq
    '84ab8e55414d4b87b3442a3b9631fe058efc6efe' -and
  [bool]$emailLinkPrebuild.remoteQualified -and
  [bool]$emailLinkPrebuild.runtimeAcceptancePending
) 'email-link prebuild qualification changed.'
$facebookPrebuild = $completedPrebuildProviders[1]
Assert-ExactNames $facebookPrebuild @(
  'provider','ticketId','branch','implementationCommit','qualificationCommit',
  'remoteQualified','runtimeAcceptancePending'
) 'Facebook prebuild qualification'
Assert-Coordination (
  [string]$facebookPrebuild.provider -ceq 'facebook' -and
  [string]$facebookPrebuild.ticketId -ceq
    'UAW-CODEX-FACEBOOK-AUTH-PREBUILD-20260824' -and
  [string]$facebookPrebuild.branch -ceq
    'work/codex-auth/facebook-auth-prebuild-20260824' -and
  [string]$facebookPrebuild.implementationCommit -ceq
    '567168bb4814e0cfe2b7b7a3daac772e3f4bb64c' -and
  [string]$facebookPrebuild.qualificationCommit -ceq
    '2024c25690b81b438c8c08f0081c6b60bd104010' -and
  [bool]$facebookPrebuild.remoteQualified -and
  [bool]$facebookPrebuild.runtimeAcceptancePending
) 'Facebook prebuild qualification changed.'

$productionLanes = @($gitDiscipline.lanes)
$expectedLaneIds = @('cursor_ui','codex_auth','codex_backend','integration_repair','integration')
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
  integration_repair = @{
    role = 'primary'; task = '/root/repair_'; branch = 'work/integration-repair/'
    worktree = 'MOOLSOCIAL-WORKTREE-INTEGRATION-REPAIR-'; commit = 'repair'
    base = 'approved_codex_tip'
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
  'candidateBuildRequiresSeparateAuthorization','integrationOwnerGitClosureResponsible',
  'repair'
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
$integrationRepair = $gitDiscipline.integration.repair
Assert-ExactNames $integrationRepair @(
  'lane','requiredCodexCommit','requiredCodexBranch','requiredCursorCommit',
  'requiredCursorBranch','maximumMergeCommits',
  'maximumPreMergeCoordinationCommits','preMergeCoordinationOwners',
  'maximumPostMergeClosureCommits','postMergeClosureOwners',
  'directSourceCommitsAllowed',
  'conflictResolutionAllowed','exactConflictOwners',
  'remoteRepairBranchMustEqualHeadBeforeAdmission','freshIntegrationWorkId',
  'freshIntegrationTicketId','freshIntegrationBranch',
  'freshIntegrationWorktreePath','freshIntegrationMergeSubject'
) 'integration repair discipline'
$expectedRepairConflictOwners = @(
  'apps/mobile/lib/ui_v2/profile/global_profile_panel_v2.dart',
  'config/codex-development-regression-registry.json',
  'config/codex-subagent-coordination-policy.json',
  'scripts/check-codex-subagent-coordination-policy.ps1'
)
$expectedRepairUnmergedOwners = @(
  'config/codex-development-regression-registry.json',
  'config/codex-subagent-coordination-policy.json'
)
Assert-Coordination (
  $expectedRepairUnmergedOwners.Count -eq 2 -and
  @($expectedRepairUnmergedOwners | Where-Object {
    $expectedRepairConflictOwners -cnotcontains $_
  }).Count -eq 0
) 'integration repair unmerged owner contract changed.'
Assert-Coordination (
  [string]$integrationRepair.lane -ceq 'integration_repair' -and
  [string]$integrationRepair.requiredCodexCommit -ceq
    '011fd09d1d94fce02d0bbc9c7b94c90f742624e6' -and
  [string]$integrationRepair.requiredCodexBranch -ceq
    'work/integration-repair/shop-chat-shared-v1-base-20260829' -and
  [string]$integrationRepair.requiredCursorCommit -ceq
    '30f4614574aae3c315d586944636a35ba314873d' -and
  [string]$integrationRepair.requiredCursorBranch -ceq
    'work/cursor-ui/chat-shell-impl-v1-20260829' -and
  [int]$integrationRepair.maximumMergeCommits -eq 1 -and
  [int]$integrationRepair.maximumPreMergeCoordinationCommits -eq 1 -and
  (@($integrationRepair.preMergeCoordinationOwners) -join '|') -ceq
    'config/codex-development-regression-registry.json|config/codex-subagent-coordination-policy.json|docs/quality/UAW-INTEGRATION-REPAIR-SHOP-CHAT-SHARED-V1-20260829.md' -and
  [int]$integrationRepair.maximumPostMergeClosureCommits -eq 9 -and
  (@($integrationRepair.postMergeClosureOwners) -join '|') -ceq
    'apps/mobile/lib/features/chat/chat_entry_context.dart|apps/mobile/lib/features/chat/chat_session.dart|apps/mobile/lib/ui_v2/profile/global_profile_panel_v2.dart|apps/mobile/test/chat_flow_test.dart|apps/mobile/test/global_contextual_chat_shell_test.dart|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/clean-source-state.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/full-buy-cycle1.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/full-buy-cycle2.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/prebuild-validation.md|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/shop-chat-r61-7-redmi-launch.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/shop-chat-r61-7-redmi-launch.xml|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/shop-chat-r61-7-redmi-shared.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/shop-chat-r61-7-redmi-shared.xml|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/shop-chat-r61-7-source-manifest.txt|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/source-identity.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/uaw-shop-chat-shared-r61.7-cursor-ui-review-20260829-build-provenance.txt|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-7-20260829/uaw-shop-chat-shared-r61.7-cursor-ui-review-20260829-device-review-debug.apk|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-8-20260829/clean-source-state.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-8-20260829/full-buy-cycle1.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-8-20260829/full-buy-cycle2.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-8-20260829/prebuild-validation.md|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-8-20260829/shop-chat-r61-8-source-manifest.txt|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-8-20260829/source-identity.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/clean-source-state.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/founder-review.md|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/full-buy-cycle1.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/full-buy-cycle2.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/install-result.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/prebuild-validation.md|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-back.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-chats.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-chats.xml|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-context.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-founder.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-installed-base.apk|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-launch.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-offers-origin.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-offers.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-shared.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-shared.xml|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-redmi-wholesale.png|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/shop-chat-r61-9-source-manifest.txt|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/source-identity.json|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/uaw-shop-chat-context-r61.9-cursor-ui-review-20260829-build-provenance.txt|artifacts/quality/shop-v2-r61-5-cursor-review-20260828/shop-chat-r61-9-20260829/uaw-shop-chat-context-r61.9-cursor-ui-review-20260829-device-review-debug.apk|config/apk-regression-gate-state-shop-chat-r61-7.json|config/apk-regression-gate-state-shop-chat-r61-8.json|config/apk-regression-gate-state-shop-chat-r61-9.json|config/codex-development-regression-registry.json|config/codex-subagent-coordination-policy.json|docs/quality/UAW-INTEGRATION-REPAIR-SHOP-CHAT-SHARED-V1-20260829.md|scripts/check-codex-subagent-coordination-policy.ps1' -and
  -not [bool]$integrationRepair.directSourceCommitsAllowed -and
  [bool]$integrationRepair.conflictResolutionAllowed -and
  (@($integrationRepair.exactConflictOwners | Sort-Object) -join '|') -ceq
    (@($expectedRepairConflictOwners | Sort-Object) -join '|') -and
  [bool]$integrationRepair.remoteRepairBranchMustEqualHeadBeforeAdmission -and
  [string]$integrationRepair.freshIntegrationWorkId -ceq
    'shop-chat-shared-v1-20260829' -and
  [string]$integrationRepair.freshIntegrationTicketId -ceq
    'UAW-INTEGRATION-SHOP-CHAT-SHARED-V1-20260829' -and
  [string]$integrationRepair.freshIntegrationBranch -ceq
    'integration/moolsocial/shop-chat-shared-v1-20260829' -and
  [string]$integrationRepair.freshIntegrationWorktreePath -ceq
    'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-INTEGRATION-shop-chat-shared-v1-20260829' -and
  [string]$integrationRepair.freshIntegrationMergeSubject -ceq
    'merge(shop-chat-shared-v1-20260829): integrate shared Chat and Buy context'
) 'integration repair discipline weakened or changed.'
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
  'moolsocial-parallel-production-discipline-20260824-v86',
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
  'runtime acceptance may be deferred only under the founder-authorized authentication prebuild batch',
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
$integrationRepairOpenTasks = @($taskNames | Where-Object {
  $_.StartsWith('/root/repair_', [StringComparison]::Ordinal)
})
Assert-Coordination (
  $cursorUiOpenTasks.Count -le
    [int]$gitDiscipline.agentTicketQueues.cursorUiMaximumOpenTickets -and
  $codexAuthOpenTasks.Count -le
    [int]$gitDiscipline.agentTicketQueues.codexAuthMaximumOpenTickets -and
  $codexBackendOpenTasks.Count -le
    [int]$gitDiscipline.agentTicketQueues.codexBackendMaximumOpenTickets -and
  $integrationRepairOpenTasks.Count -le
    [int]$gitDiscipline.agentTicketQueues.integrationRepairMaximumOpenTickets
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
  $selectedContinuationBindings = @($continuationBindings | Where-Object {
    [string]$_.lane -ceq $ProductionLane -and
    [string]$_.workId -ceq $ProductionWorkId -and
    [string]$_.ticketId -ceq $ProductionTicketId
  })
  Assert-Coordination ($selectedContinuationBindings.Count -le 1) `
    'production continuation binding is ambiguous.'
  $hasContinuationBinding = $selectedContinuationBindings.Count -eq 1
  $selectedContinuationBinding = if ($hasContinuationBinding) {
    $selectedContinuationBindings[0]
  } else {
    $null
  }
  $isCoordinationBootstrap = $ProductionPhase -ceq 'coordination_bootstrap'
  if ($isCoordinationBootstrap) {
    Assert-Coordination (
      $hasContinuationBinding -and
      $AgentRole -ceq 'primary' -and
      $AgentTask -ceq '/root'
    ) 'continuation bootstrap requires the primary coordination owner.'
  } else {
    Assert-Coordination (
      [string]$selectedLane.agentRole -ceq $AgentRole -and
      $AgentTask.StartsWith(
        [string]$selectedLane.taskPrefix,
        [StringComparison]::Ordinal
      )
    ) 'agent role or task does not match the selected production lane.'
    if ($hasContinuationBinding) {
      Assert-Coordination (
        [string]$selectedContinuationBinding.role -ceq $AgentRole -and
        [string]$selectedContinuationBinding.task -ceq $AgentTask
      ) 'agent identity does not match the founder-authorized continuation.'
    }
  }

  $workspaceParentForward = [string]$gitDiscipline.workspaceIsolation.workspaceParent
  $defaultExpectedWorktreeForward = (
    $workspaceParentForward + '/' + [string]$selectedLane.worktreePrefix +
    $ProductionWorkId
  )
  $expectedWorktreeForward = if ($hasContinuationBinding) {
    [string]$selectedContinuationBinding.worktreePath
  } else {
    $defaultExpectedWorktreeForward
  }
  $parentAgentsForward = [string]$gitDiscipline.workspaceIsolation.parentAgentsPath
  Assert-Coordination (
    $rootForward -ceq $expectedWorktreeForward -and
    $rootForward -cne $productionCheckoutForward -and
    (Test-Path -LiteralPath $parentAgentsForward -PathType Leaf)
  ) 'production feature worktree root or parent AGENTS owner is invalid.'
  $expectedBranch = if ($hasContinuationBinding) {
    [string]$selectedContinuationBinding.branch
  } else {
    [string]$selectedLane.branchPrefix + $ProductionWorkId
  }
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
  if ($hasContinuationBinding) {
    $continuationBaseline = [string]$selectedContinuationBinding.baselineHead
    $continuationBaselineType = @(& git -C $root cat-file -t `
        $continuationBaseline 2>$null)
    $continuationBaselineTypeExit = $LASTEXITCODE
    Assert-Coordination (
      $continuationBaselineTypeExit -eq 0 -and
      $continuationBaselineType.Count -eq 1 -and
      [string]$continuationBaselineType[0] -ceq 'commit'
    ) 'production continuation baseline is unavailable.'
    & git -C $root merge-base --is-ancestor $workStartCommit `
      $continuationBaseline
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'production continuation baseline does not descend from the work-start tag.'
    & git -C $root merge-base --is-ancestor $continuationBaseline $head
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'production lane HEAD does not descend from its continuation baseline.'
    if ($isCoordinationBootstrap) {
      Assert-Coordination ($head -ceq $continuationBaseline) `
        'continuation bootstrap must run before its bootstrap commit.'
      $baseCommit = $continuationBaseline
    } else {
      $continuationCommits = @(& git -C $root rev-list --first-parent --reverse `
          "$continuationBaseline..$head")
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $continuationCommits.Count -ge 1
      ) 'production continuation bootstrap commit is missing.'
      $bootstrapCommit = [string]$continuationCommits[0]
      $bootstrapParents = @(& git -C $root rev-list --parents -n 1 `
          $bootstrapCommit)
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $bootstrapParents.Count -eq 1 -and
        [string]$bootstrapParents[0] -ceq
          ($bootstrapCommit + ' ' + $continuationBaseline)
      ) 'production continuation bootstrap has invalid parentage.'
      $bootstrapSubject = @(& git -C $root show -s --format=%s `
          $bootstrapCommit)
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $bootstrapSubject.Count -eq 1 -and
        [string]$bootstrapSubject[0] -ceq
          [string]$selectedContinuationBinding.bootstrapCommitSubject
      ) 'production continuation bootstrap subject is invalid.'
      $bootstrapChangedOwners = @(& git -C $root diff --name-only `
          --diff-filter=ACMRTUXBD "$continuationBaseline..$bootstrapCommit")
      Assert-Coordination ($LASTEXITCODE -eq 0) `
        'production continuation bootstrap owner inventory failed.'
      $expectedBootstrapOwners = @(
        $selectedContinuationBinding.bootstrapOwners | ForEach-Object {
          Get-CanonicalOwner ([string]$_)
        }
      )
      Assert-Coordination (
        (@($bootstrapChangedOwners | Sort-Object) -join '|') -ceq
        (@($expectedBootstrapOwners | Sort-Object) -join '|')
      ) 'production continuation bootstrap changed an unexpected owner.'
      $baseCommit = $bootstrapCommit
    }
  }
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

  if (-not $isCoordinationBootstrap) {
    foreach ($effectiveOwner in $effectiveOwners) {
      $shopCursorReviewAndroidOwner = (
        $hasContinuationBinding -and
        [string]$selectedContinuationBinding.id -ceq
          'integration_repair_shop_v2_r61_5_cursor_review_build_20260828' -and
        $effectiveOwner -ceq 'apps/mobile/android/app/build.gradle.kts'
      )
      $retainedBuyCandidateEvidenceOwner = (
        $hasContinuationBinding -and
        [string]$selectedContinuationBinding.id -ceq
          'cursor_buy_mvp_ticket14_v1_20260902' -and
        $effectiveOwner -cmatch
          '^artifacts/quality/buy-v2-r65-[123]-cursor-75-defect-review-20260903/[^/]+$'
      )
      $retainedBuyGeneratedPackageOwner = (
        $hasContinuationBinding -and
        [string]$selectedContinuationBinding.id -ceq
          'cursor_buy_mvp_ticket14_v1_20260902' -and
        $effectiveOwner -cin @(
          'apps/mobile/.dart_tool/package_config.json',
          'apps/mobile/.dart_tool/package_graph.json',
          'apps/mobile/.flutter-plugins-dependencies'
        )
      )
      $allowedOwner = $false
      foreach ($allowedRoot in @($selectedLane.allowedOwnerRoots)) {
        if (Test-ProductionOwnerRoot $effectiveOwner ([string]$allowedRoot)) {
          $allowedOwner = $true
          break
        }
      }
      if ($shopCursorReviewAndroidOwner -or
          $retainedBuyCandidateEvidenceOwner -or
          $retainedBuyGeneratedPackageOwner) {
        $allowedOwner = $true
      }
      Assert-Coordination $allowedOwner `
        "production lane claims an owner outside its allowlist: $effectiveOwner"
      foreach ($forbiddenRoot in @($selectedLane.forbiddenOwnerRoots)) {
        Assert-Coordination (
          $shopCursorReviewAndroidOwner -or
          $retainedBuyCandidateEvidenceOwner -or
          $retainedBuyGeneratedPackageOwner -or
          -not (Test-ProductionOwnerRoot $effectiveOwner ([string]$forbiddenRoot))
        ) "production lane claims a forbidden owner: $effectiveOwner"
      }
    }
  }

  $validPhases = switch ($ProductionLane) {
    'cursor_ui' {
      @(
        'coordination_bootstrap','task_start','implementation','pre_commit','handoff',
        'founder_acceptance','ticket_acceptance','ticket_close'
      )
    }
    'codex_auth' {
      @('coordination_bootstrap','task_start','implementation','pre_commit','handoff','ticket_acceptance','ticket_close')
    }
    'codex_backend' {
      @('task_start','implementation','pre_commit','handoff','ticket_acceptance','ticket_close')
    }
    'integration_repair' {
      @(
        'coordination_bootstrap','task_start','implementation','pre_commit',
        'handoff','integration_admission_authorize'
      )
    }
    'integration' {
      @('integration_start','integration_verify','integration_close','candidate_preflight')
    }
  }
  Assert-Coordination (@($validPhases) -ccontains $ProductionPhase) `
    'production phase is invalid for its selected lane.'

  if ($ProductionLane -cne 'integration') {
    $changedOwners = @(Get-ProductionChangedOwners $baseCommit $head)
    $primaryEvidenceCoordinationOwnerKeys = @()
    if (
      $ProductionLane -ceq 'cursor_ui' -and
      $ProductionWorkId -ceq 'buy-mvp-ticket14-v1-20260902' -and
      $ProductionTicketId -ceq 'UAW-CURSOR-BUY-MVP-CLOSE-T14-20260902'
    ) {
      $coordinationSubject =
        'ui(buy-mvp-ticket14-v1-20260902): register retained candidate evidence'
      $matchingCoordinationCommits = @()
      $continuationFeatureCommits = @(& git -C $root rev-list --reverse `
          "$baseCommit..$head")
      Assert-Coordination ($LASTEXITCODE -eq 0) `
        'retained-evidence coordination commit inventory failed.'
      foreach ($candidateCommit in $continuationFeatureCommits) {
        $candidateSubject = @(& git -C $root show -s --format=%s `
            $candidateCommit)
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
        ) 'retained-evidence coordination subject read failed.'
        if ([string]$candidateSubject[0] -ceq $coordinationSubject) {
          $matchingCoordinationCommits += [string]$candidateCommit
        }
      }
      Assert-Coordination ($matchingCoordinationCommits.Count -le 1) `
        'retained-evidence coordination commit is duplicated.'
      if ($matchingCoordinationCommits.Count -eq 1) {
        $coordinationCommit = [string]$matchingCoordinationCommits[0]
        $coordinationParent = @(& git -C $root show -s --format=%P `
            $coordinationCommit)
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and $coordinationParent.Count -eq 1 -and
          [string]$coordinationParent[0] -ceq
            'fbc39fb4d6bc5ce3fb3ffd33063c273084634dc5'
        ) 'retained-evidence coordination parent changed.'
        $coordinationOwners = @(& git -C $root diff-tree --no-commit-id `
            --name-only -r $coordinationCommit)
        Assert-Coordination ($LASTEXITCODE -eq 0) `
          'retained-evidence coordination owner inventory failed.'
        $expectedCoordinationOwners = @(
          'config/codex-subagent-coordination-policy.json',
          'scripts/check-codex-subagent-coordination-policy.ps1'
        )
        Assert-Coordination (
          (@($coordinationOwners | Sort-Object) -join '|') -ceq
          (@($expectedCoordinationOwners | Sort-Object) -join '|')
        ) 'retained-evidence coordination changed an unexpected owner.'
        $primaryEvidenceCoordinationOwnerKeys = @(
          $expectedCoordinationOwners | ForEach-Object {
            $_.ToLowerInvariant()
          }
        )
        $admissionSubject =
          'ui(buy-mvp-ticket14-v1-20260902): admit retained evidence owners'
        $matchingAdmissionCommits = @()
        foreach ($candidateCommit in $continuationFeatureCommits) {
          $candidateSubject = @(& git -C $root show -s --format=%s `
              $candidateCommit)
          Assert-Coordination (
            $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
          ) 'retained-evidence admission subject read failed.'
          if ([string]$candidateSubject[0] -ceq $admissionSubject) {
            $matchingAdmissionCommits += [string]$candidateCommit
          }
        }
        Assert-Coordination ($matchingAdmissionCommits.Count -le 1) `
          'retained-evidence admission commit is duplicated.'
        if ($matchingAdmissionCommits.Count -eq 1) {
          $admissionCommit = [string]$matchingAdmissionCommits[0]
          $admissionParent = @(& git -C $root show -s --format=%P `
              $admissionCommit)
          Assert-Coordination (
            $LASTEXITCODE -eq 0 -and $admissionParent.Count -eq 1 -and
            [string]$admissionParent[0] -ceq $coordinationCommit
          ) 'retained-evidence admission parent changed.'
          $admissionOwners = @(& git -C $root diff-tree --no-commit-id `
              --name-only -r $admissionCommit)
          Assert-Coordination (
            $LASTEXITCODE -eq 0 -and $admissionOwners.Count -eq 1 -and
            [string]$admissionOwners[0] -ceq
              'scripts/check-codex-subagent-coordination-policy.ps1'
          ) 'retained-evidence admission changed an unexpected owner.'
          $sealedCoordinationCommit = $admissionCommit
          $metadataSubject =
            'ui(buy-mvp-ticket14-v1-20260902): preserve generated package metadata'
          $matchingMetadataCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'generated-metadata coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $metadataSubject) {
              $matchingMetadataCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingMetadataCommits.Count -le 1) `
            'generated-metadata coordination commit is duplicated.'
          if ($matchingMetadataCommits.Count -eq 1) {
            $metadataCommit = [string]$matchingMetadataCommits[0]
            $metadataParent = @(& git -C $root show -s --format=%P `
                $metadataCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $metadataParent.Count -eq 1 -and
              [string]$metadataParent[0] -ceq $admissionCommit
            ) 'generated-metadata coordination parent changed.'
            $metadataOwners = @(& git -C $root diff-tree --no-commit-id `
                --name-only -r $metadataCommit)
            $expectedMetadataOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($metadataOwners | Sort-Object) -join '|') -ceq
              (@($expectedMetadataOwners | Sort-Object) -join '|')
            ) 'generated-metadata coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $metadataCommit
          }
          $pluginMetadataSubject =
            'ui(buy-mvp-ticket14-v1-20260902): preserve generated plugin metadata'
          $matchingPluginMetadataCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'generated-plugin coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $pluginMetadataSubject) {
              $matchingPluginMetadataCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingPluginMetadataCommits.Count -le 1) `
            'generated-plugin coordination commit is duplicated.'
          if ($matchingPluginMetadataCommits.Count -eq 1) {
            $pluginMetadataCommit = [string]$matchingPluginMetadataCommits[0]
            $pluginMetadataParent = @(& git -C $root show -s --format=%P `
                $pluginMetadataCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingMetadataCommits.Count -eq 1 -and
              $pluginMetadataParent.Count -eq 1 -and
              [string]$pluginMetadataParent[0] -ceq $metadataCommit
            ) 'generated-plugin coordination parent changed.'
            $pluginMetadataOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $pluginMetadataCommit)
            $expectedPluginMetadataOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($pluginMetadataOwners | Sort-Object) -join '|') -ceq
              (@($expectedPluginMetadataOwners | Sort-Object) -join '|')
            ) 'generated-plugin coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $pluginMetadataCommit
          }
          $scannerTestSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit focused scanner test owner'
          $matchingScannerTestCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'scanner-test coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $scannerTestSubject) {
              $matchingScannerTestCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingScannerTestCommits.Count -le 1) `
            'scanner-test coordination commit is duplicated.'
          if ($matchingScannerTestCommits.Count -eq 1) {
            $scannerTestCommit = [string]$matchingScannerTestCommits[0]
            $scannerTestParent = @(& git -C $root show -s --format=%P `
                $scannerTestCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingPluginMetadataCommits.Count -eq 1 -and
              $scannerTestParent.Count -eq 1 -and
              [string]$scannerTestParent[0] -ceq $pluginMetadataCommit
            ) 'scanner-test coordination parent changed.'
            $scannerTestOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $scannerTestCommit)
            $expectedScannerTestOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($scannerTestOwners | Sort-Object) -join '|') -ceq
              (@($expectedScannerTestOwners | Sort-Object) -join '|')
            ) 'scanner-test coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $scannerTestCommit
          }
          & git -C $root diff --quiet $sealedCoordinationCommit -- `
            'config/codex-subagent-coordination-policy.json' `
            'scripts/check-codex-subagent-coordination-policy.ps1'
          Assert-Coordination ($LASTEXITCODE -eq 0) `
            'retained-evidence coordination owners changed after admission.'
        }
      }
    }
    if ($isCoordinationBootstrap) {
      $expectedBootstrapOwners = @(
        $selectedContinuationBinding.bootstrapOwners | ForEach-Object {
          Get-CanonicalOwner ([string]$_)
        }
      )
      foreach ($bootstrapOwner in $expectedBootstrapOwners) {
        Assert-Coordination (
          $ownerToTask.ContainsKey($bootstrapOwner.ToLowerInvariant())
        ) "continuation bootstrap owner is unclaimed: $bootstrapOwner"
      }
      Assert-Coordination (
        (@($changedOwners | Sort-Object) -join '|') -ceq
        (@($expectedBootstrapOwners | Sort-Object) -join '|')
      ) 'continuation bootstrap dirt does not match its exact owner manifest.'
    } else {
      $effectiveOwnerKeys = @($effectiveOwners | ForEach-Object {
        $_.ToLowerInvariant()
      })
      foreach ($changedOwner in $changedOwners) {
        $changedOwnerKey = $changedOwner.ToLowerInvariant()
        $repairAutomaticOwner = (
          $ProductionLane -ceq 'integration_repair' -and
          -not @($expectedRepairConflictOwners | ForEach-Object {
            $_.ToLowerInvariant()
          }).Contains($changedOwnerKey)
        )
        $primaryEvidenceCoordinationOwner =
          $primaryEvidenceCoordinationOwnerKeys.Contains($changedOwnerKey)
        Assert-Coordination (
          $effectiveOwnerKeys.Contains($changedOwnerKey) -or
          $repairAutomaticOwner -or
          $primaryEvidenceCoordinationOwner
        ) "production feature changed an owner outside its claim: $changedOwner"
      }
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
    if ($ProductionLane -ceq 'integration_repair') {
      $repairMergeHeadPath = (& git -C $root rev-parse --git-path MERGE_HEAD).Trim()
      Assert-Coordination ($LASTEXITCODE -eq 0) `
        'integration repair merge-state path read failed.'
      $repairMergeActive = Test-Path -LiteralPath $repairMergeHeadPath -PathType Leaf
      $existingRepairMerges = @(& git -C $root rev-list --merges `
          "$baseCommit..$head")
      Assert-Coordination ($LASTEXITCODE -eq 0) `
        'integration repair existing merge inventory failed.'
      if ($repairMergeActive) {
        $preMergeDirectCommits = @(& git -C $root rev-list --no-merges `
            "$baseCommit..$head")
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and
          $existingRepairMerges.Count -eq 0 -and
          $preMergeDirectCommits.Count -eq
            [int]$integrationRepair.maximumPreMergeCoordinationCommits
        ) 'integration repair pre-merge coordination commit inventory changed.'
        $preMergeChangedOwners = @(& git -C $root diff --name-only `
            "$baseCommit..$head")
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and
          (@($preMergeChangedOwners | Sort-Object) -join '|') -ceq
            (@($integrationRepair.preMergeCoordinationOwners | Sort-Object) -join '|')
        ) 'integration repair pre-merge coordination owner set changed.'
        $repairMergeHead = (Get-Content -Raw -LiteralPath $repairMergeHeadPath).Trim()
        $repairUnmergedOwners = @(& git -C $root diff --name-only --diff-filter=U)
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and $repairUnmergedOwners.Count -eq 0
        ) 'integration repair pre-commit contains unresolved index entries.'
        $repairIndexTree = (& git -C $root write-tree).Trim()
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and $repairIndexTree -cmatch '^[0-9a-f]{40}$'
        ) 'integration repair staged tree could not be written.'
        Assert-IntegrationRepairMerge -FirstParent $head `
          -SecondParent $repairMergeHead -ActualTree $repairIndexTree
      } elseif ($existingRepairMerges.Count -eq 0) {
        $existingCoordinationCommits = @(& git -C $root rev-list --no-merges `
            "$baseCommit..$head")
        $existingCoordinationOwners = @(& git -C $root diff --name-only `
            "$baseCommit..$head")
        $isShopBuyRegressionRepair = (
          $hasContinuationBinding -and
          [string]$selectedContinuationBinding.id -cin @(
            'integration_repair_shop_v2_r61_5_buy_regression_fix_20260828',
            'integration_repair_shop_v2_r61_5_cursor_review_build_20260828'
          )
        )
        if ($isShopBuyRegressionRepair) {
          $shopRepairOwnerKeys = @($effectiveOwners | ForEach-Object {
              ([string]$_).ToLowerInvariant()
            })
          $shopRepairClosureOwnerKeys = @(
            'config/codex-development-regression-registry.json',
            'config/codex-subagent-coordination-policy.json',
            'docs/quality/UAW-CURSOR-UI-SHOP-LANDING-V2-CHILD8-BUY-GOLDEN-PATH-20260828.md',
            'docs/quality/UAW-INTEGRATION-REPAIR-SHOP-V2-R61-5-BUY-REGRESSION-FIX-20260828.md',
            'config/apk-regression-gate-state.json',
            'apps/mobile/android/app/build.gradle.kts',
            'docs/quality/UAW-PRIMARY-SHOP-V2-R61-5-CURSOR-REVIEW-BUILD-20260828.md',
            'docs/quality/UAW-INTEGRATION-REPAIR-SHOP-V2-R61-5-CURSOR-REVIEW-BUILD-20260828.md',
            'scripts/test-cursor-ui-review-build-profile.ps1',
            'scripts/check-apk-production-plugin-integrity.ps1',
            'scripts/test-release-production-plugin-integrity.ps1',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/build-attempt1-google-services-failure.md',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/branch.txt',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/head.txt',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/source-identity.json',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/clean-state.json',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/prebuild-validation.md',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/protected-boundary-disposition.md',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/rejected-candidate-preserved.md',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/startup-config-regression-registered.md',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/attempt2-manifest-application-id.txt',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/attempt2-package-identity-rejected-debug.apk',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/build-attempt2-package-identity-failure.md',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/clean-state-attempt2.json',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/head-attempt2.txt',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/package-isolation-attempt2.log',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/prebuild-validation-attempt2.md',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/source-identity-attempt2-final.json',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/source-identity-attempt2.json',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/source-manifest-attempt2.txt',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/source-manifest-attempt3.txt',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/plugin-integrity-attempt3.log',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/head-attempt3.txt',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/source-identity-attempt3.json',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/clean-state-attempt3.json',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/prebuild-validation-attempt3.md',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/uaw-shop-v2-r61.5-cursor-ui-review-20260828-device-review-debug.apk',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/uaw-shop-v2-r61.5-cursor-ui-review-20260828-build-provenance.txt',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/redmi-cold-launch.png',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/redmi-cold-launch-ui.xml',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/redmi-shop-profile.png',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/redmi-shop-back-recovery.png',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/redmi-installed-base.apk',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/redmi-install-result.json',
            'artifacts/quality/shop-v2-r61-5-cursor-review-20260828/founder-approval-with-successor.md',
            'scripts/check-codex-subagent-coordination-policy.ps1'
          ) | ForEach-Object { $_.ToLowerInvariant() }
          $shopRepairExistingSubjects = @(& git -C $root log --format=%s `
              "$baseCommit..$head")
          $shopRepairExistingCommitValid = (
            $existingCoordinationCommits.Count -eq 0 -or
            (
              $existingCoordinationCommits.Count -eq 1 -and
              $shopRepairExistingSubjects.Count -eq 1 -and
              [string]$shopRepairExistingSubjects[0] -cin @(
                'repair(shop-v2-r61-5-buy-regression-fix-20260828): restore complete c24f Buy regression',
                'repair(shop-v2-r61-5-cursor-review-build-20260828): authorize one Redmi review build'
              )
            ) -or
            (
              $existingCoordinationCommits.Count -eq 2 -and
              $shopRepairExistingSubjects.Count -eq 2 -and
              [string]$shopRepairExistingSubjects[0] -ceq
                'repair(shop-v2-r61-5-cursor-review-build-20260828): seal Cursor-only Google Services exclusion' -and
              [string]$shopRepairExistingSubjects[1] -ceq
                'repair(shop-v2-r61-5-cursor-review-build-20260828): authorize one Redmi review build'
            ) -or
            (
              $existingCoordinationCommits.Count -eq 3 -and
              $shopRepairExistingSubjects.Count -eq 3 -and
              [string]$shopRepairExistingSubjects[0] -ceq
                'repair(shop-v2-r61-5-cursor-review-build-20260828): fix Windows APK identity inspection' -and
              [string]$shopRepairExistingSubjects[1] -ceq
                'repair(shop-v2-r61-5-cursor-review-build-20260828): seal Cursor-only Google Services exclusion' -and
              [string]$shopRepairExistingSubjects[2] -ceq
                'repair(shop-v2-r61-5-cursor-review-build-20260828): authorize one Redmi review build'
            )
          )
          $shopRepairAllowedStagedOwnerKeys = if (
            $existingCoordinationCommits.Count -eq 0
          ) {
            $shopRepairOwnerKeys
          } else {
            $shopRepairClosureOwnerKeys
          }
          Assert-Coordination (
            $LASTEXITCODE -eq 0 -and
            $shopRepairExistingCommitValid -and
            @($preCommitStagedOwners | Where-Object {
              -not $shopRepairAllowedStagedOwnerKeys.Contains(
                ([string]$_).ToLowerInvariant()
              )
            }).Count -eq 0
          ) 'Shop Buy regression repair staged owner set changed.'
        } else {
          $preMergeCoordinationOwnerKeys = @(
            $integrationRepair.preMergeCoordinationOwners | ForEach-Object {
              ([string]$_).ToLowerInvariant()
            }
          )
          Assert-Coordination (
            $LASTEXITCODE -eq 0 -and
            $existingCoordinationCommits.Count -lt
              [int]$integrationRepair.maximumPreMergeCoordinationCommits -and
            (
              $existingCoordinationCommits.Count -eq 0 -or
              @($existingCoordinationOwners | Where-Object {
                -not $preMergeCoordinationOwnerKeys.Contains(
                  ([string]$_).ToLowerInvariant()
                )
              }).Count -eq 0
            ) -and
            @($preCommitStagedOwners | Where-Object {
              -not $preMergeCoordinationOwnerKeys.Contains(
                ([string]$_).ToLowerInvariant()
              )
            }).Count -eq 0
          ) 'integration repair coordination correction owner set changed.'
        }
      } else {
        $postMergeClosureOwnerKeys = @(
          $integrationRepair.postMergeClosureOwners | ForEach-Object {
            ([string]$_).ToLowerInvariant()
          }
        )
        Assert-Coordination (
          $existingRepairMerges.Count -eq 1 -and
          @($preCommitStagedOwners | Where-Object {
            -not $postMergeClosureOwnerKeys.Contains(
              ([string]$_).ToLowerInvariant()
            )
          }).Count -eq 0
        ) 'integration repair post-merge closure owner set changed.'
      }
    }
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
    if ($ProductionLane -ceq 'integration_repair') {
      $featureMergeCommits = @(& git -C $root rev-list --first-parent `
          --merges "$baseCommit..$head")
    } else {
      $featureMergeCommits = @(& git -C $root rev-list --merges `
          "$baseCommit..$head")
    }
    Assert-Coordination ($LASTEXITCODE -eq 0) `
      'production feature merge inventory failed.'
    if ($ProductionLane -ceq 'integration_repair') {
      Assert-Coordination (
        $featureMergeCommits.Count -eq
          [int]$integrationRepair.maximumMergeCommits
      ) 'integration repair merge count changed.'
    } else {
      Assert-Coordination ($featureMergeCommits.Count -eq 0) `
        'production feature branch contains a merge commit.'
    }
    if ($ProductionLane -ceq 'integration_repair') {
      $featureCommits = @(& git -C $root rev-list --first-parent --reverse `
          "$baseCommit..$head")
    } else {
      $featureCommits = @(& git -C $root rev-list --reverse `
          "$baseCommit..$head")
    }
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
    if ($ProductionLane -ceq 'integration_repair') {
      $repairMergeCommit = [string]$featureMergeCommits[0]
      $repairParentOutput = @(& git -C $root show -s --format='%P' `
          $repairMergeCommit)
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $repairParentOutput.Count -eq 1
      ) 'integration repair merge parent read failed.'
      $repairParents = @([string]$repairParentOutput[0] -split ' ')
      Assert-Coordination (
        $repairParents.Count -eq 2
      ) 'integration repair merge does not have two exact parents.'
      $preMergeDirectCommits = @(& git -C $root rev-list --no-merges `
          "$baseCommit..$($repairParents[0])")
      $preMergeChangedOwners = @(& git -C $root diff --name-only `
          "$baseCommit..$($repairParents[0])")
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and
        $preMergeDirectCommits.Count -eq
          [int]$integrationRepair.maximumPreMergeCoordinationCommits -and
        (@($preMergeChangedOwners | Sort-Object) -join '|') -ceq
          (@($integrationRepair.preMergeCoordinationOwners | Sort-Object) -join '|')
      ) 'integration repair merge first parent changed.'
      $postMergeCommits = @(& git -C $root rev-list --reverse `
          "$repairMergeCommit..$head")
      $postMergeMerges = @(& git -C $root rev-list --merges `
          "$repairMergeCommit..$head")
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $postMergeMerges.Count -eq 0 -and
        $postMergeCommits.Count -le
          [int]$integrationRepair.maximumPostMergeClosureCommits
      ) 'integration repair contains a forbidden direct commit.'
      if ($postMergeCommits.Count -eq 0) {
        Assert-Coordination ($head -ceq $repairMergeCommit) `
          'integration repair HEAD moved beyond its merge unexpectedly.'
      } else {
        $postMergeChangedOwners = @(& git -C $root diff --name-only `
            "$repairMergeCommit..$head")
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and $head -ceq $postMergeCommits[-1] -and
          (@($postMergeChangedOwners | Sort-Object) -join '|') -ceq
            (@($integrationRepair.postMergeClosureOwners | Sort-Object) -join '|')
        ) 'integration repair post-merge closure owner set changed.'
      }
      Assert-Coordination (
        $featureCommits.Count -eq
          (1 + [int]$integrationRepair.maximumPreMergeCoordinationCommits +
            $postMergeCommits.Count)
      ) 'integration repair commit inventory changed.'
      $repairActualTree = (& git -C $root show -s --format='%T' `
          $repairMergeCommit).Trim()
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $repairActualTree -cmatch '^[0-9a-f]{40}$'
      ) 'integration repair merge tree read failed.'
      Assert-IntegrationRepairMerge -FirstParent $repairParents[0] `
        -SecondParent $repairParents[1] -ActualTree $repairActualTree
      $codexRemoteHead = Get-ProductionRemoteBranchHead `
        ([string]$integrationRepair.requiredCodexBranch)
      $cursorRemoteHead = Get-ProductionRemoteBranchHead `
        ([string]$integrationRepair.requiredCursorBranch)
      Assert-Coordination (
        $codexRemoteHead -ceq [string]$integrationRepair.requiredCodexCommit -and
        $cursorRemoteHead -ceq [string]$integrationRepair.requiredCursorCommit
      ) 'integration repair sealed source remote changed.'
      Assert-QualifiedIntegrationRepairTip -RepairCommit $head
    }
    Assert-ProductionSecretSafe -BaseCommit $baseCommit -HeadCommit $head
  }

  if ($ProductionPhase -ceq 'integration_admission_authorize') {
    Assert-Coordination ($ProductionLane -ceq 'integration_repair') `
      'fresh integration admission is valid only from the repair lane.'
    Assert-Coordination (
      (Test-ProductionWorktreeClean) -and
      $IntegrationTargetWorkId -ceq
        [string]$integrationRepair.freshIntegrationWorkId -and
      $IntegrationTargetTicketId -ceq
        [string]$integrationRepair.freshIntegrationTicketId
    ) 'fresh integration admission identity or repair cleanliness changed.'
    Assert-QualifiedIntegrationRepairTip -RepairCommit $head
    $repairRemoteHead = Get-ProductionRemoteBranchHead $branch
    Assert-Coordination ($repairRemoteHead -ceq $head) `
      'fresh integration admission requires exact repair remote readback.'
    $targetRootForward = ConvertTo-ProductionForwardPath $IntegrationTargetRoot
    Assert-Coordination (
      $targetRootForward -ceq
        [string]$integrationRepair.freshIntegrationWorktreePath -and
      (Test-Path -LiteralPath $IntegrationTargetRoot -PathType Container)
    ) 'fresh integration target worktree path changed or is missing.'
    $targetBranch = (& git -C $IntegrationTargetRoot branch --show-current).Trim()
    $targetHead = (& git -C $IntegrationTargetRoot rev-parse HEAD).Trim()
    $targetStatus = @(& git -C $IntegrationTargetRoot status --porcelain=v1 `
        --untracked-files=normal)
    Assert-Coordination (
      $LASTEXITCODE -eq 0 -and
      $targetBranch -ceq [string]$integrationRepair.freshIntegrationBranch -and
      $targetHead -ceq $workStartCommit -and $targetStatus.Count -eq 0
    ) 'fresh integration target is not clean at the governance tag.'
    Assert-ProductionManagedWorktreesClean
    $targetRemoteRef = 'refs/heads/' + [string]$integrationRepair.freshIntegrationBranch
    $existingTargetRemote = @(& git -C $IntegrationTargetRoot ls-remote --heads `
        origin $targetRemoteRef 2>$null)
    Assert-Coordination (
      $LASTEXITCODE -eq 0 -and $existingTargetRemote.Count -eq 0
    ) 'fresh integration target remote branch already exists.'
    Write-Output ([string]$integrationRepair.freshIntegrationMergeSubject)
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
    if ($approvedBranches.Count -eq 1 -and
        [string]$approvedBranches[0] -ceq
          'work/integration-repair/shop-chat-shared-v1-20260829') {
      $qualifiedRepairCommit = [string]$approvedCommits[0]
      Assert-QualifiedIntegrationRepairTip `
        -RepairCommit $qualifiedRepairCommit
      & git -C $root merge-base --is-ancestor `
        ([string]$integrationRepair.requiredCodexCommit) $qualifiedRepairCommit
      $repairHasCodex = $LASTEXITCODE -eq 0
      & git -C $root merge-base --is-ancestor `
        ([string]$integrationRepair.requiredCursorCommit) $qualifiedRepairCommit
      $repairHasCursor = $LASTEXITCODE -eq 0
      $codexRemoteHead = Get-ProductionRemoteBranchHead `
        ([string]$integrationRepair.requiredCodexBranch)
      $cursorRemoteHead = Get-ProductionRemoteBranchHead `
        ([string]$integrationRepair.requiredCursorBranch)
      $repairRemoteHead = Get-ProductionRemoteBranchHead `
        ([string]$approvedBranches[0])
      Assert-Coordination (
        $repairHasCodex -and $repairHasCursor -and
        $codexRemoteHead -ceq [string]$integrationRepair.requiredCodexCommit -and
        $cursorRemoteHead -ceq [string]$integrationRepair.requiredCursorCommit -and
        $repairRemoteHead -ceq $qualifiedRepairCommit
      ) 'qualified repair ancestry or sealed remote readback changed.'
      Assert-Coordination ($integrationMerges.Count -eq 1) `
        'fresh integration must contain exactly one repair-tip merge.'
      $freshIntegrationSubject = @(& git -C $root show -s --format='%s' `
          $integrationMerges[0])
      Assert-Coordination (
        $LASTEXITCODE -eq 0 -and $freshIntegrationSubject.Count -eq 1 -and
        [string]$freshIntegrationSubject[0] -ceq
          [string]$integrationRepair.freshIntegrationMergeSubject
      ) 'fresh integration merge subject differs from the exact admission.'
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
