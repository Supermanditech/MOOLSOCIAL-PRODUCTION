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
  [ValidateSet('baseline','cursor_ui','codex_ui','codex_auth','codex_backend','integration_repair','integration')]
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

function Assert-R679OwnerAdmission($Before, $After) {
  # The founder authorized these two existing Buy dependencies on 11 September.
  # Compare the whole policy after removing only those additions; no wider
  # claim, registry, role, release or historical-policy change is admitted.
  $candidate = $After | ConvertTo-Json -Depth 100 -Compress | ConvertFrom-Json
  $claim = @($candidate.activeClaims | Where-Object {
    $_.task -ceq '/root/cursor_buy_redmi_fixes_v1_20260905'
  })
  $added = @(
    'apps/mobile/lib/ui_v2/buy/buy_v2_chat_route_adapter.dart',
    'apps/mobile/test/ui_v2/buy/buy_v2_address_form_sheet_motion_test.dart'
  )
  Assert-Coordination ($claim.Count -eq 1 -and $claim[0].owners.Count -eq 69) `
    'Redmi dependency admission requires its exact 69-owner claim.'
  foreach ($owner in $added) {
    Assert-Coordination (@($claim[0].owners | Where-Object {
      $_ -ceq $owner
    }).Count -eq 1) "Redmi dependency admission is missing or duplicates: $owner"
  }
  $claim[0].owners = @($claim[0].owners | Where-Object { $_ -cnotin $added })
  Assert-Coordination (
    ($Before | ConvertTo-Json -Depth 100 -Compress) -ceq
    ($candidate | ConvertTo-Json -Depth 100 -Compress)
  ) 'Redmi dependency admission changed unrelated ownership or policy.'
}

function Test-R66HistoricalCommitSubject([string]$Commit, [string]$Subject) {
  # R66-BUILD-003: retain two pushed label mistakes without rewriting history.
  # This is not an alternative prefix for any other task or future commit.
  if ($AgentRole -cne 'subagent' -or
      $AgentTask -cne '/root/cursor_buy_redmi_fixes_v1_20260905' -or
      $ProductionLane -cne 'cursor_ui' -or
      $ProductionWorkId -cne 'buy-redmi-fixes-v1-20260905' -or
      $ProductionTicketId -cne 'UAW-CURSOR-BUY-REDMI-FIXES-V1-20260905') {
    return $false
  }
  $dispositions = @(
    @{
      commit = 'be647d41d845b3f55c67603236696ef29ce81cdc'
      parent = 'd119c85eccc85af99c86c32ae526f57421855ff3'
      subject = 'chore(buy-redmi-fixes-v1-20260905): qualify tested r66.3 review source'
      owners = @(
        'docs/quality/cursor-buy-redmi-fixes-v1-20260905/RESULTS.md',
        'scripts/check-buy-protected-baseline.ps1'
      )
    },
    @{
      commit = 'ba7f7d382bdab771ee05cd94ea2963b6421c44ad'
      parent = 'be647d41d845b3f55c67603236696ef29ce81cdc'
      subject = 'docs(buy-redmi-fixes-v1-20260905): seal r66.3 local qualification'
      owners = @('docs/quality/cursor-buy-redmi-fixes-v1-20260905/RESULTS.md')
    }
  )
  $matches = @($dispositions | Where-Object {
    $_.commit -ceq $Commit -and $_.subject -ceq $Subject
  })
  if ($matches.Count -ne 1) { return $false }
  $disposition = $matches[0]
  $parents = @(& git -C $root show -s --format=%P $Commit)
  if ($LASTEXITCODE -ne 0 -or $parents.Count -ne 1 -or
      [string]$parents[0] -cne $disposition.parent) { return $false }
  $owners = @(& git -C $root diff-tree --no-commit-id --name-only -r $Commit)
  return ($LASTEXITCODE -eq 0 -and
    (@($owners | Sort-Object) -join '|') -ceq
    (@($disposition.owners | Sort-Object) -join '|'))
}

function Get-R66Utf8GitJson([string]$Commit, [string]$Owner, [switch]$AsText) {
  Assert-Coordination ($Commit -cmatch '^[0-9a-f]{40}$' -and
    $Owner -cmatch '^[A-Za-z0-9_./-]+$' -and -not $root.Contains('"')) `
    'Social repair historical JSON arguments are invalid.'
  $startInfo = New-Object Diagnostics.ProcessStartInfo
  $startInfo.FileName = 'git'
  $startInfo.Arguments = '-C "' + $root + '" show "' + $Commit + ':' + $Owner + '"'
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.StandardOutputEncoding = New-Object Text.UTF8Encoding($false, $true)
  $process = New-Object Diagnostics.Process
  $process.StartInfo = $startInfo
  try {
    [void]$process.Start()
    $errorRead = $process.StandardError.ReadToEndAsync()
    $jsonText = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    [void]$errorRead.GetAwaiter().GetResult()
    Assert-Coordination ($process.ExitCode -eq 0) 'Social repair historical JSON read failed.'
    if ($AsText) { return $jsonText }
    return ($jsonText | ConvertFrom-Json)
  } finally {
    $process.Dispose()
  }
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
    $BranchName -cmatch '^(?:work/(?:cursor-ui|codex-ui|codex-auth|codex-backend|integration-repair)/|integration/moolsocial/)[a-z0-9][a-z0-9-]{2,48}$'
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
    [string]$_.task -ceq '/root/repair_store_buy_conflict_v3_20260904'
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
    [string]$_.task -ceq '/root/repair_store_buy_conflict_v3_20260904'
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
        '^repair\(store-buy-conflict-repair-v3-20260904\): .+' -and
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
      '^repair\(store-buy-conflict-repair-v3-20260904\): .+'
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
          '^repair\(store-buy-conflict-repair-v3-20260904\): .+' -and
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
Assert-Coordination ($continuationBindings.Count -eq 69) `
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
    'codex_ui' { 'work/codex-ui/' }
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
      'founder_authorized_2026_09_02',
      'founder_authorized_2026_09_03',
      'founder_authorized_2026_09_04',
      'founder_authorized_2026_09_05'
    ) -and
    [string]$continuationBinding.lane -cin @('cursor_ui','codex_ui','codex_auth','integration_repair') -and
    [string]$continuationBinding.role -cin @('primary','subagent') -and
    [string]$continuationBinding.task -cmatch '^/root(?:/[a-z0-9_]+)?$' -and
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
  'cursorUiMaximumOpenTickets','codexUiMaximumOpenTickets','codexAuthMaximumOpenTickets',
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
  [int]$gitDiscipline.agentTicketQueues.codexUiMaximumOpenTickets -eq 1 -and
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
$expectedLaneIds = @('cursor_ui','codex_ui','codex_auth','codex_backend','integration_repair','integration')
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
  codex_ui = @{
    role = 'primary'; task = '/root'; branch = 'work/codex-ui/'
    worktree = 'MOOLSOCIAL-WORKTREE-CODEX-'; commit = 'ui'
    base = 'approved_codex_ui_checkpoint'
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
  'config/codex-development-regression-registry.json',
  'config/codex-subagent-coordination-policy.json',
  'scripts/check-codex-subagent-coordination-policy.ps1'
)
$expectedRepairUnmergedOwners = @($expectedRepairConflictOwners)
Assert-Coordination (
  [string]$integrationRepair.lane -ceq 'integration_repair' -and
  [string]$integrationRepair.requiredCodexCommit -ceq
    'f208fbef80303ad3c6b1bf41a385616adcc969b5' -and
  [string]$integrationRepair.requiredCodexBranch -ceq
    'work/codex-ui/universal-chat-boundary-contract-v1-20260904' -and
  [string]$integrationRepair.requiredCursorCommit -ceq
    'fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d' -and
  [string]$integrationRepair.requiredCursorBranch -ceq
    'work/cursor-ui/buy-mvp-ticket14-v1-20260902' -and
  [int]$integrationRepair.maximumMergeCommits -eq 1 -and
  [int]$integrationRepair.maximumPreMergeCoordinationCommits -eq 1 -and
  (@($integrationRepair.preMergeCoordinationOwners) -join '|') -ceq
    'docs/quality/UAW-INTEGRATION-REPAIR-STORE-BUY-V3-20260904.md' -and
  [int]$integrationRepair.maximumPostMergeClosureCommits -eq 3 -and
  (@($integrationRepair.postMergeClosureOwners) -join '|') -ceq
    'docs/quality/UAW-INTEGRATION-REPAIR-STORE-BUY-V3-20260904.md|config/codex-development-regression-registry.json|config/codex-subagent-coordination-policy.json|scripts/check-codex-development-regression-memory.ps1|scripts/check-codex-subagent-coordination-policy.ps1|scripts/test-codex-integration-repair-coordination-policy.ps1' -and
  -not [bool]$integrationRepair.directSourceCommitsAllowed -and
  [bool]$integrationRepair.conflictResolutionAllowed -and
  (@($integrationRepair.exactConflictOwners | Sort-Object) -join '|') -ceq
    (@($expectedRepairConflictOwners | Sort-Object) -join '|') -and
  [bool]$integrationRepair.remoteRepairBranchMustEqualHeadBeforeAdmission -and
  [string]$integrationRepair.freshIntegrationWorkId -ceq
    'work-store-buy-v4-20260904' -and
  [string]$integrationRepair.freshIntegrationTicketId -ceq
    'UAW-INTEGRATION-WORK-STORE-BUY-V4-20260904' -and
  [string]$integrationRepair.freshIntegrationBranch -ceq
    'integration/moolsocial/work-store-buy-v4-20260904' -and
  [string]$integrationRepair.freshIntegrationWorktreePath -ceq
    'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-INTEGRATION-work-store-buy-v4-20260904' -and
  [string]$integrationRepair.freshIntegrationMergeSubject -ceq
    'merge(work-store-buy-v4-20260904): integrate corrected Store Chat and Buy'
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
$codexUiOpenTasks = @($taskNames | Where-Object {
  $_ -ceq '/root'
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
  $codexUiOpenTasks.Count -le
    [int]$gitDiscipline.agentTicketQueues.codexUiMaximumOpenTickets -and
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
    $predeclaredR65FourEvidenceOwner = (
      [string]$claim.task -ceq
        '/root/cursor_shop_mvp_go_live_v1_20260829' -and
      $owner -cmatch
        '^artifacts/quality/buy-v2-r65-4-cursor-post-redmi-scanner-review-20260904/[^/]+$'
    )
    $predeclaredR65FiveEvidenceOwner = (
      [string]$claim.task -ceq
        '/root/cursor_shop_mvp_go_live_v1_20260829' -and
      $owner -cmatch
        '^artifacts/quality/buy-v2-r65-5-cursor-redmi-child-fixes-review-20260904/[^/]+$'
    )
    $predeclaredR65SixEvidenceOwner = (
      [string]$claim.task -ceq
        '/root/cursor_shop_mvp_go_live_v1_20260829' -and
      $owner -cmatch
        '^artifacts/quality/buy-v2-r65-6-cursor-scanner-a11y-fix-review-20260904/[^/]+$'
    )
    $predeclaredR65SevenEvidenceOwner = (
      [string]$claim.task -ceq
        '/root/cursor_shop_mvp_go_live_v1_20260829' -and
      $owner -cmatch
        '^artifacts/quality/buy-v2-r65-7-cursor-payment-prerequisite-review-20260904/[^/]+$'
    )
    $predeclaredR65EightEvidenceOwner = (
      [string]$claim.task -ceq
        '/root/cursor_shop_mvp_go_live_v1_20260829' -and
      $owner -cmatch
        '^artifacts/quality/buy-v2-r65-8-cursor-valid-payment-choice-review-20260904/[^/]+$'
    )
    $predeclaredR65NineEvidenceOwner = (
      [string]$claim.task -ceq
        '/root/cursor_shop_mvp_go_live_v1_20260829' -and
      $owner -cmatch
        '^artifacts/quality/buy-v2-r65-9-cursor-payment-brand-copy-review-20260904/[^/]+$'
    )
    $predeclaredR65TenEvidenceOwner = (
      [string]$claim.task -ceq
        '/root/cursor_shop_mvp_go_live_v1_20260829' -and
      $owner -cmatch
        '^artifacts/quality/buy-v2-r65-10-cursor-order-key-fix-review-20260904/[^/]+$'
    )
    $predeclaredR65ElevenEvidenceOwner = (
      [string]$claim.task -ceq
        '/root/cursor_shop_mvp_go_live_v1_20260829' -and
      $owner -cmatch
        '^artifacts/quality/buy-v2-r65-11-cursor-draggable-cart-review-20260904/[^/]+$'
    )
    $predeclaredR669PortableOwner = (
      [string]$claim.task -ceq '/root' -and
      $owner -ceq 'scripts/windows-powershell-portable-api.ps1' -and
      $root.Replace('\','/').TrimEnd('/') -ceq
        'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-buy-redmi-fixes-v1-20260905' -and
      $ProductionLane -ceq 'cursor_ui' -and
      $ProductionWorkId -ceq 'buy-redmi-fixes-v1-20260905' -and
      $ProductionPhase -cin @('implementation','pre_commit') -and
      (Get-Sha256 (Join-Path $root 'docs/quality/UAW-CURSOR-BUY-REDMI-FIXES-V1-20260905.md')) -ceq
        '0A63C6D63BB9AACC65BBB86F4CDE8BB0E71E64D1AC339BC9B6B6B0699C9B593B'
    )
    Assert-Coordination (
      $resolvedOwner.StartsWith(
        $root + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      ) -and
      ((Test-Path -LiteralPath $resolvedOwner -PathType Leaf) -or
        $predeclaredR65FourEvidenceOwner -or
        $predeclaredR65FiveEvidenceOwner -or
        $predeclaredR65SixEvidenceOwner -or
        $predeclaredR65SevenEvidenceOwner -or
        $predeclaredR65EightEvidenceOwner -or
        $predeclaredR65NineEvidenceOwner -or
        $predeclaredR65TenEvidenceOwner -or
        $predeclaredR65ElevenEvidenceOwner -or
        $predeclaredR669PortableOwner)
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
      (
        $AgentTask -ceq '/root' -or
        (
          $ProductionLane -ceq 'integration_repair' -and
          $AgentTask -ceq [string]$selectedContinuationBinding.task
        )
      )
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
          '^(?:artifacts/quality/buy-v2-r65-[123]-cursor-75-defect-review-20260903|artifacts/quality/buy-v2-r65-4-cursor-post-redmi-scanner-review-20260904|artifacts/quality/buy-v2-r65-5-cursor-redmi-child-fixes-review-20260904|artifacts/quality/buy-v2-r65-6-cursor-scanner-a11y-fix-review-20260904|artifacts/quality/buy-v2-r65-7-cursor-payment-prerequisite-review-20260904|artifacts/quality/buy-v2-r65-8-cursor-valid-payment-choice-review-20260904|artifacts/quality/buy-v2-r65-9-cursor-payment-brand-copy-review-20260904|artifacts/quality/buy-v2-r65-10-cursor-order-key-fix-review-20260904|artifacts/quality/buy-v2-r65-11-cursor-draggable-cart-review-20260904)/[^/]+$'
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
    'codex_ui' {
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
    $r66OwnerAmendmentPending = $false
    $r665CollectionAdmissionPending = $false
    $r678PersistenceAdmissionPending = $false
    if (
      $ProductionLane -ceq 'cursor_ui' -and
      $ProductionWorkId -ceq 'buy-redmi-fixes-v1-20260905' -and
      $ProductionTicketId -ceq 'UAW-CURSOR-BUY-REDMI-FIXES-V1-20260905'
    ) {
      # Founder-authorized primary correction: one added Buy test, not a
      # general permission for Cursor to edit coordination or preserve dirt.
      $r66AmendmentParent = 'c6ffece62a6e4dea0810b88eb7fc98775c832fe6'
      $r66AmendmentSubject =
        'ui(buy-redmi-fixes-v1-20260905): register honest order motion test ownership'
      $r66AddedTest =
        'apps/mobile/test/ui_v2/buy/buy_v2_honest_order_motion_test.dart'
      $r66CoordinationOwners = @(
        'config/codex-subagent-coordination-policy.json',
        'docs/quality/UAW-CURSOR-BUY-REDMI-FIXES-V1-20260905.md',
        'docs/quality/cursor-buy-redmi-fixes-v1-20260905/scope-state.json',
        'scripts/check-codex-subagent-coordination-policy.ps1'
      )
      $r664MenuAdmissionParent = '89c7970c77629b615a6cb08c9b51946fedcb8cea'
      $r665CollectionParent = '7ef7711e119a4c4d7691423538a91ecc0499c2f2'
      $r666AccessibilityParent = 'a201f8ed4e8ad6abc58e4f925791fa4db501317b'
      $r667DependenciesParent = '38fa1201488ae943487b58d4afe5d851f8b9fc37'
      $r670SourceParent = 'd7e7d04541e486f0b33a7b6fe3c15cbc9b533fc2'
      $r677SourceParent = '0c36d2201c43665d38e00173df7d2df63f690344'
      $r678PersistenceParent = 'e00a6981b92399f71c68233907bc79b6588c096c'
      $r680SourceParent = 'a18aa780c0e00497ef218025bc8473a32f50a084'
      & git -C $root merge-base --is-ancestor $r680SourceParent $head
      $r680SourceContext = $LASTEXITCODE -eq 0
      $r679FreezeHead = if ($r680SourceContext) { $r680SourceParent } else { $head }
      $r679DependencyParent = 'a71fc9732d54380eebd97abd57d1406f39ca19a7'
      & git -C $root merge-base --is-ancestor $r679DependencyParent $head
      $r679DependencyContext = $LASTEXITCODE -eq 0
      $r678FreezeHead = if ($r679DependencyContext) { $r679DependencyParent } else { $head }
      & git -C $root merge-base --is-ancestor $r678PersistenceParent $head
      $r678PersistenceContext = $LASTEXITCODE -eq 0
      $r677FreezeHead = if ($r678PersistenceContext) { $r678PersistenceParent } else { $head }
      & git -C $root merge-base --is-ancestor $r677SourceParent $head
      $r677SourceContext = $LASTEXITCODE -eq 0
      $r676FreezeHead = if ($r677SourceContext) { $r677SourceParent } else { $head }
      $r676CorrectionParent = '3542b02c914fd132e9b85a612edf7333c1db9de6'
      & git -C $root merge-base --is-ancestor $r676CorrectionParent $head
      $r676CorrectionContext = $LASTEXITCODE -eq 0
      $r675FreezeHead = if ($r676CorrectionContext) { $r676CorrectionParent } else { $head }
      $r675SourceParent = '6de5f0c82a57a66dd3172f0ad6080949ca09b5f0'
      & git -C $root merge-base --is-ancestor $r675SourceParent $head
      $r675SourceContext = $LASTEXITCODE -eq 0
      $r673FreezeHead = if ($r675SourceContext) { $r675SourceParent } else { $head }
      $r673SourceParent = '2a8c52472b19964ca6d0046d31827197a9e3f74b'
      & git -C $root merge-base --is-ancestor $r673SourceParent $head
      $r673SourceContext = $LASTEXITCODE -eq 0
      $r672FreezeHead = if ($r673SourceContext) { $r673SourceParent } else { $head }
      $r672RegressionParent = '4e5252de8dca9e02a49358e98d2e169acac3103b'
      & git -C $root merge-base --is-ancestor $r672RegressionParent $head
      $r672RegressionContext = $LASTEXITCODE -eq 0
      $r671FreezeHead = if ($r672RegressionContext) { $r672RegressionParent } else { $head }
      $r671CorrectionParent = 'a2c914539aad677f80b3a73562c3faa591e819e6'
      & git -C $root merge-base --is-ancestor $r671CorrectionParent $head
      $r671CorrectionContext = $LASTEXITCODE -eq 0
      $r670FreezeHead = if ($r671CorrectionContext) { $r671CorrectionParent } else { $head }
      & git -C $root merge-base --is-ancestor $r670SourceParent $head
      $r670SourceContext = $LASTEXITCODE -eq 0
      $r669FreezeHead = if ($r670SourceContext) { $r670SourceParent } else { $head }
      $r669RegressionParent = '99eeaabba897300320b2b19646d1efce44c57cba'
      & git -C $root merge-base --is-ancestor $r669RegressionParent $head
      $r669RegressionContext = $LASTEXITCODE -eq 0
      $r668FreezeHead = if ($r669RegressionContext) { $r669RegressionParent } else { $head }
      $r668FormattingParent = '30228bd6d102123c92bf9a05a8b58180e64bc45c'
      & git -C $root merge-base --is-ancestor $r668FormattingParent $head
      $r668FormattingContext = $LASTEXITCODE -eq 0
      $r667FreezeHead = if ($r668FormattingContext) { $r668FormattingParent } else { $head }
      & git -C $root merge-base --is-ancestor $r667DependenciesParent $head
      $r667DependenciesContext = $LASTEXITCODE -eq 0
      $r666FreezeHead = if ($r667DependenciesContext) { $r667DependenciesParent } else { $head }
      & git -C $root merge-base --is-ancestor $r666AccessibilityParent $head
      $r666AccessibilityContext = $LASTEXITCODE -eq 0
      $r665FreezeHead = if ($r666AccessibilityContext) { $r666AccessibilityParent } else { $head }
      & git -C $root merge-base --is-ancestor $r665CollectionParent $head
      $r665CollectionContext = $LASTEXITCODE -eq 0
      $r664MenuFreezeHead = if ($r665CollectionContext) { $r665CollectionParent } else { $head }
      & git -C $root merge-base --is-ancestor $r664MenuAdmissionParent $head
      $r664MenuAdmissionContext = $LASTEXITCODE -eq 0
      $r664LegacyFreezeHead = if ($r664MenuAdmissionContext) {
        $r664MenuAdmissionParent
      } else { $head }
      & git -C $root merge-base --is-ancestor $r66AmendmentParent $head
      Assert-Coordination ($LASTEXITCODE -eq 0) `
        'R66 owner amendment requires its exact preserved implementation parent.'
      if ($head -ceq $r66AmendmentParent) {
        $r66OwnerAmendmentPending = $true
        Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
          'pending R66 owner amendment is not a handoff or acceptance.'
        $r66PolicyBeforeText = @(& git -C $root show `
            "${r66AmendmentParent}:config/codex-subagent-coordination-policy.json")
        Assert-Coordination ($LASTEXITCODE -eq 0) 'R66 prior policy read failed.'
        $r66PolicyBefore = ($r66PolicyBeforeText -join "`n") | ConvertFrom-Json
        $r66PolicyAfter = Get-Content -Raw -LiteralPath `
          (Join-Path $root $r66CoordinationOwners[0]) | ConvertFrom-Json
        $r66Claim = @($r66PolicyAfter.activeClaims | Where-Object {
          $_.task -ceq '/root/cursor_buy_redmi_fixes_v1_20260905'
        })[0]
        Assert-Coordination (
          $r66Claim.owners.Count -eq 41 -and
          @($r66Claim.owners | Where-Object { $_ -ceq $r66AddedTest }).Count -eq 1
        ) 'R66 amendment must add exactly the existing honest-order-motion test.'
        $r66Claim.owners = @($r66Claim.owners | Where-Object { $_ -cne $r66AddedTest })
        Assert-Coordination (
          ($r66PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r66PolicyAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'R66 amendment changed policy beyond the single test claim.'
        $r66ManifestHash = '42334144C2611CDAF24CCB7F3E1FC60EA55DBE609E7A5CFC1B618F963328D3C8'
        Assert-Coordination (
          (Get-Sha256 (Join-Path $root $r66CoordinationOwners[1])) -ceq $r66ManifestHash
        ) 'R66 founder-authorized owner amendment manifest changed.'
        $r66ScopeBeforeText = @(& git -C $root show `
            "${r66AmendmentParent}:$($r66CoordinationOwners[2])")
        Assert-Coordination ($LASTEXITCODE -eq 0) 'R66 prior scope binding read failed.'
        $r66ScopeBefore = ($r66ScopeBeforeText -join "`n") | ConvertFrom-Json
        $r66ScopeAfter = Get-Content -Raw -LiteralPath `
          (Join-Path $root $r66CoordinationOwners[2]) | ConvertFrom-Json
        Assert-Coordination (
          $r66ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
          $r66ManifestHash
        ) 'R66 amended manifest is not bound to the current scope.'
        $r66ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 =
          $r66ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (
          ($r66ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r66ScopeAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'R66 amendment changed execution authority beyond the manifest hash.'
        $r66PreservedDrafts = @{
          'apps/mobile/lib/ui_v2/buy/buy_v2_design.dart' = 'F447A4E815DC94B33BAE953FCC8B8AD794080B28CDC6963F38F38ABFB2ACBBF0'
          'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart' = '4B47A393C5593991D576629C27675E50E8B04E36EBA65B950D56CACC881BF9B1'
          'apps/mobile/lib/ui_v2/buy/buy_v2_views.dart' = '3B8E49FFED925794633A622932D69AC49B9C4BBB2ACF27DB2722E6D678BEEC75'
          'apps/mobile/test/ui_v2/buy/buy_v2_order_delivery_address_context_test.dart' = 'D6A05F1F3FD957486702B074DA27EA6BB47967D8DE68FFEACDEC269C824B54BD'
          'apps/mobile/test/ui_v2/buy/buy_v2_order_progress_test.dart' = 'FEFDBF3095E8A776C3ABA47F95C619D83440499F6D51F252B587965C40622E13'
          'apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart' = '237ABD4CA564793B6D4C767B893B8BE81D16D10CA02881DBDC56EB57B00ABCC0'
          'docs/quality/cursor-buy-redmi-fixes-v1-20260905/RESULTS.md' = 'C12B5E5E4770C2D52061EA7D5E54DD62D5934B00531EF6246C5F52642D2FA82C'
        }
        foreach ($r66Draft in $r66PreservedDrafts.Keys) {
          Assert-Coordination (
            (Get-Sha256 (Join-Path $root $r66Draft)) -ceq $r66PreservedDrafts[$r66Draft]
          ) "R66 unfinished draft changed during coordination: $r66Draft"
        }
        $r66Dirty = @(& git -C $root diff HEAD --name-only)
        Assert-Coordination ($LASTEXITCODE -eq 0) 'R66 preservation inventory failed.'
        Assert-Coordination (
          (@($r66Dirty | Sort-Object) -join '|') -ceq
          (@(@($r66PreservedDrafts.Keys) + $r66CoordinationOwners | Sort-Object) -join '|')
        ) 'R66 coordination changed or lost an unexpected owner.'
      } else {
        $r66Following = @(& git -C $root rev-list --reverse --ancestry-path `
            "${r66AmendmentParent}..$head")
        Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66Following.Count -gt 0) `
          'R66 owner amendment ancestry read failed.'
        $r66CoordinationCommit = [string]$r66Following[0]
        $r66Parents = @(& git -C $root show -s --format=%P $r66CoordinationCommit)
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and $r66Parents.Count -eq 1 -and
          [string]$r66Parents[0] -ceq $r66AmendmentParent
        ) 'R66 owner amendment must have exactly its authorized parent.'
        $r66Subject = @(& git -C $root show -s --format=%s $r66CoordinationCommit)
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and $r66Subject.Count -eq 1 -and
          [string]$r66Subject[0] -ceq $r66AmendmentSubject
        ) 'R66 owner amendment subject changed.'
        $r66CommittedOwners = @(& git -C $root diff-tree --no-commit-id --name-only -r $r66CoordinationCommit)
        Assert-Coordination (
          $LASTEXITCODE -eq 0 -and
          (@($r66CommittedOwners | Sort-Object) -join '|') -ceq
          (@($r66CoordinationOwners | Sort-Object) -join '|')
        ) 'R66 owner amendment included source, evidence or another owner.'
        $r66GateRepairParent = '0dc950ff1ba41a5a50808c5905bb8dd88e52448a'
        & git -C $root merge-base --is-ancestor $r66GateRepairParent $head
        $r66GateRepairContext = $LASTEXITCODE -eq 0
        $r66FreezeCommit = $r66CoordinationCommit
        $r66FreezeOwners = $r66CoordinationOwners
        if ($r66GateRepairContext) {
          $r66PriorCoordination = @(& git -C $root log --format=%H `
              "${r66CoordinationCommit}..$r66GateRepairParent" -- @r66CoordinationOwners)
          Assert-Coordination (
            $LASTEXITCODE -eq 0 -and $r66PriorCoordination.Count -eq 0
          ) 'R66 prior coordination freeze changed before the authorized repair.'
          $r66SocialGate = 'scripts/check-social-protected-baseline.ps1'
          $r66RepairOwners = @($r66CoordinationOwners) + $r66SocialGate
          $r66RepairSubject =
            'ui(buy-redmi-fixes-v1-20260905): bind accepted Social protection baseline'
          if ($head -ceq $r66GateRepairParent) {
            Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
              'pending Social gate repair cannot be handed off or accepted.'
            $r66RepairDirty = @(& git -C $root diff HEAD --name-only)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r66RepairDirty | Sort-Object) -join '|') -ceq
              (@($r66RepairOwners | Sort-Object) -join '|')
            ) 'Social gate repair must change exactly its five coordination owners.'
            $r66RepairPolicyBefore = Get-R66Utf8GitJson `
              $r66GateRepairParent $r66CoordinationOwners[0]
            $r66RepairPolicyAfter = Get-Content -Encoding UTF8 -Raw -LiteralPath `
              (Join-Path $root $r66CoordinationOwners[0]) | ConvertFrom-Json
            $r66PrimaryClaim = @($r66RepairPolicyAfter.activeClaims | Where-Object {
              $_.task -ceq '/root'
            })[0]
            Assert-Coordination (
              $r66PrimaryClaim.owners.Count -eq 6 -and
              @($r66PrimaryClaim.owners | Where-Object { $_ -ceq $r66SocialGate }).Count -eq 1
            ) 'Social repair must add only its checker to primary coordination.'
            $r66PrimaryClaim.owners = @($r66PrimaryClaim.owners | Where-Object {
              $_ -cne $r66SocialGate
            })
            Assert-Coordination (
              ($r66RepairPolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
              ($r66RepairPolicyAfter | ConvertTo-Json -Depth 100 -Compress)
            ) 'Social repair changed policy beyond the one primary checker claim.'
            $r66RepairManifestHash = 'C0869A9788CFC7E3C773A5180656BB17E4E78383F7ED43B90914D262E13D64EB'
            Assert-Coordination (
              (Get-Sha256 (Join-Path $root $r66CoordinationOwners[1])) -ceq
                $r66RepairManifestHash -and
              (Get-Sha256 (Join-Path $root $r66SocialGate)) -ceq
                '47CBC31DCBAA058D5E6AC2E0AAC3F68DD8D76D0906FFDB4C1D7DBAE84811756D'
            ) 'Social repair differs from its reviewed manifest or exact checker.'
            $r66RepairScopeBefore = Get-R66Utf8GitJson `
              $r66GateRepairParent $r66CoordinationOwners[2]
            $r66RepairScopeAfter = Get-Content -Encoding UTF8 -Raw -LiteralPath `
              (Join-Path $root $r66CoordinationOwners[2]) | ConvertFrom-Json
            Assert-Coordination (
              $r66RepairScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
                $r66RepairManifestHash
            ) 'Social repair manifest is not bound to the ticket scope.'
            $r66RepairScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 =
              $r66RepairScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
            Assert-Coordination (
              ($r66RepairScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
              ($r66RepairScopeAfter | ConvertTo-Json -Depth 100 -Compress)
            ) 'Social repair changed execution authority beyond its manifest binding.'
            $r66FreezeCommit = $null
          } else {
            $r66RepairFollowing = @(& git -C $root rev-list --reverse --ancestry-path `
                "${r66GateRepairParent}..$head")
            Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66RepairFollowing.Count -gt 0) `
              'Social repair ancestry lookup failed.'
            $r66FreezeCommit = [string]$r66RepairFollowing[0]
            $r66RepairParents = @(& git -C $root show -s --format=%P $r66FreezeCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $r66RepairParents.Count -eq 1 -and
              [string]$r66RepairParents[0] -ceq $r66GateRepairParent
            ) 'Social repair must have exactly its authorized parent.'
            $r66RepairCommitSubject = @(& git -C $root show -s --format=%s $r66FreezeCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $r66RepairCommitSubject.Count -eq 1 -and
              [string]$r66RepairCommitSubject[0] -ceq $r66RepairSubject
            ) 'Social repair commit subject changed.'
            $r66RepairCommittedOwners = @(& git -C $root diff-tree --no-commit-id `
                --name-only -r $r66FreezeCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r66RepairCommittedOwners | Sort-Object) -join '|') -ceq
              (@($r66RepairOwners | Sort-Object) -join '|')
            ) 'Social repair commit changed an unexpected owner.'
          }
          $r66FreezeOwners = $r66RepairOwners
          $r66CoordinationOwners = $r66RepairOwners
        }
        $r66ReviewAdmissionParent = '3437dc9591256aabfd9c3fc6b3fb22cd0c6ccdba'
        & git -C $root merge-base --is-ancestor $r66ReviewAdmissionParent $head
        if ($LASTEXITCODE -eq 0) {
          $r66ReviewGates = @(
            'scripts/check-buy-protected-baseline.ps1',
            'scripts/check-buy-backend-contract-boundary.ps1',
            'scripts/check-buy-data-egress-boundary.ps1',
            'scripts/check-brand-integrity.ps1'
          )
          $r66ReviewAdmissionOwners = @(
            'config/codex-subagent-coordination-policy.json',
            'docs/quality/UAW-CURSOR-BUY-REDMI-FIXES-V1-20260905.md',
            'docs/quality/cursor-buy-redmi-fixes-v1-20260905/scope-state.json',
            'scripts/check-codex-subagent-coordination-policy.ps1'
          )
          $r66ReviewAdmissionSubject =
            'ui(buy-redmi-fixes-v1-20260905): admit bounded Redmi preflight checker repair'
          & git -C $root diff --quiet $r66FreezeCommit $r66ReviewAdmissionParent -- @r66FreezeOwners
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Redmi admission changed earlier frozen blobs.'
          $r66PriorReviewHistory = @(& git -C $root log --format=%H `
              "${r66FreezeCommit}..$r66ReviewAdmissionParent" -- @r66FreezeOwners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66PriorReviewHistory.Count -eq 0) `
            'Redmi admission cannot rewrite earlier coordination history.'
          $r66ReviewPolicyBefore = Get-R66Utf8GitJson `
            $r66ReviewAdmissionParent $r66ReviewAdmissionOwners[0]
          $r66ReviewPolicyAfter = if ($r664MenuAdmissionContext) {
            Get-R66Utf8GitJson $r664MenuAdmissionParent $r66ReviewAdmissionOwners[0]
          } else {
            Get-Content -Raw -Encoding UTF8 -LiteralPath `
              (Join-Path $root $r66ReviewAdmissionOwners[0]) | ConvertFrom-Json
          }
          $r66ReviewPrimaryClaims = @($r66ReviewPolicyAfter.activeClaims | Where-Object {
            $_.task -ceq '/root'
          })
          Assert-Coordination ($r66ReviewPrimaryClaims.Count -eq 1) 'Redmi primary claim is ambiguous.'
          $r66ReviewPrimary = $r66ReviewPrimaryClaims[0]
          Assert-Coordination (
            $r66ReviewPrimary.owners.Count -eq 10 -and
            @($r66ReviewPrimary.owners | Where-Object { $_ -cin $r66ReviewGates }).Count -eq 4
          ) 'Redmi admission must add exactly its four existing checkers.'
          $r66ReviewPrimary.owners = @($r66ReviewPrimary.owners | Where-Object {
            $_ -cnotin $r66ReviewGates
          })
          Assert-Coordination (
            ($r66ReviewPolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
            ($r66ReviewPolicyAfter | ConvertTo-Json -Depth 100 -Compress)
          ) 'Redmi admission changed another claim or policy field.'
          $r66ReviewManifestHash = 'C23DD7B871D174DCF50A9200C80382FE8D24C067CD1C4CC1CF7E7AAADF14EF89'
          if ($r664MenuAdmissionContext) {
            $r66ReviewManifestBlob = @(& git -C $root rev-parse `
                "${r664MenuAdmissionParent}:$($r66ReviewAdmissionOwners[1])")
            Assert-Coordination ($LASTEXITCODE -eq 0 -and
              $r66ReviewManifestBlob.Count -eq 1 -and
              [string]$r66ReviewManifestBlob[0] -ceq 'e059649e9371a19f3d9871fd978170f8c53694b2') `
              'Historical Redmi review admission manifest changed.'
          } else {
            Assert-Coordination (
              (Get-Sha256 (Join-Path $root $r66ReviewAdmissionOwners[1])) -ceq $r66ReviewManifestHash
            ) 'Redmi review admission manifest changed.'
          }
          $r66ReviewScopeBefore = Get-R66Utf8GitJson `
            $r66ReviewAdmissionParent $r66ReviewAdmissionOwners[2]
          $r66ReviewScopeAfter = if ($r664MenuAdmissionContext) {
            Get-R66Utf8GitJson $r664MenuAdmissionParent $r66ReviewAdmissionOwners[2]
          } else {
            Get-Content -Raw -Encoding UTF8 -LiteralPath `
              (Join-Path $root $r66ReviewAdmissionOwners[2]) | ConvertFrom-Json
          }
          Assert-Coordination (
            $r66ReviewScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
            $r66ReviewManifestHash
          ) 'Redmi review scope is not bound to its admission.'
          $r66ReviewScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 =
            $r66ReviewScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
          Assert-Coordination (
            ($r66ReviewScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
            ($r66ReviewScopeAfter | ConvertTo-Json -Depth 100 -Compress)
          ) 'Redmi admission changed execution authority beyond its manifest hash.'
          if ($head -ceq $r66ReviewAdmissionParent) {
            Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
              'Pending Redmi admission is not handoff or acceptance.'
            $r66ReviewAdmissionDirty = @(& git -C $root diff HEAD --name-only)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r66ReviewAdmissionDirty | Sort-Object) -join '|') -ceq
              (@($r66ReviewAdmissionOwners | Sort-Object) -join '|')
            ) 'Pending Redmi admission must change exactly four coordination owners.'
            $r66FreezeCommit = $null
          } else {
            $r66ReviewFollowing = @(& git -C $root rev-list --reverse --ancestry-path `
                "${r66ReviewAdmissionParent}..$head")
            Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66ReviewFollowing.Count -gt 0) `
              'Redmi admission ancestry lookup failed.'
            $r66FreezeCommit = [string]$r66ReviewFollowing[0]
            $r66ReviewParents = @(& git -C $root show -s --format=%P $r66FreezeCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $r66ReviewParents.Count -eq 1 -and
              [string]$r66ReviewParents[0] -ceq $r66ReviewAdmissionParent
            ) 'Redmi admission must have its exact single parent.'
            $r66ReviewSubject = @(& git -C $root show -s --format=%s $r66FreezeCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $r66ReviewSubject.Count -eq 1 -and
              [string]$r66ReviewSubject[0] -ceq $r66ReviewAdmissionSubject
            ) 'Redmi admission subject changed.'
            $r66ReviewCommitted = @(& git -C $root diff-tree --no-commit-id --name-only -r $r66FreezeCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r66ReviewCommitted | Sort-Object) -join '|') -ceq
              (@($r66ReviewAdmissionOwners | Sort-Object) -join '|')
            ) 'Redmi admission included a source, test, gate implementation or evidence owner.'
          }
          $r66CoordinationOwners = @($r66FreezeOwners) + $r66ReviewGates
        }
        if ($null -ne $r66FreezeCommit) {
          $r66SubjectRepairParent = 'ba7f7d382bdab771ee05cd94ea2963b6421c44ad'
          & git -C $root merge-base --is-ancestor $r66SubjectRepairParent $head
          if ($LASTEXITCODE -eq 0) {
            $r66SubjectGate = 'scripts/check-codex-subagent-coordination-policy.ps1'
            $r66SubjectOwners = @(
              'docs/quality/cursor-buy-redmi-fixes-v1-20260905/RESULTS.md',
              $r66SubjectGate
            )
            $r66SubjectRepairSubject =
              'ui(buy-redmi-fixes-v1-20260905): register exact historical checkpoint label dispositions'
            & git -C $root diff --quiet $r66FreezeCommit $r66SubjectRepairParent -- @r66FreezeOwners
            Assert-Coordination ($LASTEXITCODE -eq 0) 'R66 subject repair changed earlier frozen blobs.'
            $r66SubjectPriorHistory = @(& git -C $root log --format=%H `
                "${r66FreezeCommit}..$r66SubjectRepairParent" -- @r66FreezeOwners)
            Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66SubjectPriorHistory.Count -eq 0) `
              'R66 subject repair cannot revise earlier frozen history.'
            if ($head -ceq $r66SubjectRepairParent) {
              Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
                'Pending R66 subject repair is not a handoff or acceptance.'
              $r66SubjectDirty = @(& git -C $root diff HEAD --name-only)
              Assert-Coordination (
                $LASTEXITCODE -eq 0 -and
                (@($r66SubjectDirty | Sort-Object) -join '|') -ceq
                (@($r66SubjectOwners | Sort-Object) -join '|')
              ) 'Pending R66 subject repair must change only its gate and results.'
            } else {
              $r66SubjectFollowing = @(& git -C $root rev-list --reverse --ancestry-path `
                  "${r66SubjectRepairParent}..$head")
              Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66SubjectFollowing.Count -gt 0) `
                'R66 subject repair ancestry lookup failed.'
              $r66SubjectCommit = [string]$r66SubjectFollowing[0]
              $r66SubjectParents = @(& git -C $root show -s --format=%P $r66SubjectCommit)
              Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66SubjectParents.Count -eq 1 -and
                [string]$r66SubjectParents[0] -ceq $r66SubjectRepairParent) `
                'R66 subject repair requires its exact single parent.'
              $r66SubjectText = @(& git -C $root show -s --format=%s $r66SubjectCommit)
              Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66SubjectText.Count -eq 1 -and
                [string]$r66SubjectText[0] -ceq $r66SubjectRepairSubject) `
                'R66 subject repair commit subject changed.'
              $r66SubjectCommittedOwners = @(& git -C $root diff-tree --no-commit-id `
                  --name-only -r $r66SubjectCommit)
              Assert-Coordination ($LASTEXITCODE -eq 0 -and
                (@($r66SubjectCommittedOwners | Sort-Object) -join '|') -ceq
                (@($r66SubjectOwners | Sort-Object) -join '|')) `
                'R66 subject repair changed an unexpected owner.'
              if ($r664MenuAdmissionContext) {
                & git -C $root diff --quiet $r66SubjectCommit $r664LegacyFreezeHead -- $r66SubjectGate
              } else {
                & git -C $root diff --quiet $r66SubjectCommit -- $r66SubjectGate
              }
              Assert-Coordination ($LASTEXITCODE -eq 0) 'R66 repaired subject gate changed after its checkpoint.'
              $r66SubjectLaterHistory = @(& git -C $root log --format=%H `
                  "${r66SubjectCommit}..$r664LegacyFreezeHead" -- $r66SubjectGate)
              Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66SubjectLaterHistory.Count -eq 0) `
                'R66 subject repair cannot be replayed or revised.'
            }
            # The one separately verified gate is frozen above; all other
            # coordination, policy, scope, manifest and Social owners stay frozen here.
            $r66FreezeOwners = @($r66FreezeOwners | Where-Object { $_ -cne $r66SubjectGate })
          }
          if ($r664MenuAdmissionContext) {
            & git -C $root diff --quiet $r66FreezeCommit $r664LegacyFreezeHead -- @r66FreezeOwners
          } else {
            & git -C $root diff --quiet $r66FreezeCommit -- @r66FreezeOwners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'R66 coordination blobs changed after admission.'
          $r66LaterCoordination = @(& git -C $root log --format=%H `
              "${r66FreezeCommit}..$r664LegacyFreezeHead" -- @r66FreezeOwners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r66LaterCoordination.Count -eq 0) `
            'R66 coordination amendment cannot be replayed or revised by later feature commits.'
        }
      }
      if ($r664MenuAdmissionContext) {
        # One founder-authorized shared menu owner, with the prior freezes
        # proven through its exact parent and the new admission frozen below.
        $r664MenuOwners = @(
          'config/codex-subagent-coordination-policy.json',
          'docs/quality/UAW-CURSOR-BUY-REDMI-FIXES-V1-20260905.md',
          'docs/quality/cursor-buy-redmi-fixes-v1-20260905/scope-state.json',
          'scripts/check-codex-subagent-coordination-policy.ps1'
        )
        $r664MenuOwner = 'apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart'
        $r664MenuSubject =
          'ui(buy-redmi-fixes-v1-20260905): admit landscape Mool menu repair'
        $r664MenuPolicyBefore = Get-R66Utf8GitJson $r664MenuAdmissionParent $r664MenuOwners[0]
        $r664MenuPolicyAfter = if ($r665CollectionContext) {
          Get-R66Utf8GitJson $r665CollectionParent $r664MenuOwners[0]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath `
            (Join-Path $root $r664MenuOwners[0]) | ConvertFrom-Json
        }
        $r664MenuClaims = @($r664MenuPolicyAfter.activeClaims | Where-Object {
          $_.task -ceq '/root/cursor_buy_redmi_fixes_v1_20260905'
        })
        Assert-Coordination ($r664MenuClaims.Count -eq 1) 'R664 menu claim is ambiguous.'
        $r664MenuClaim = $r664MenuClaims[0]
        Assert-Coordination ($r664MenuClaim.owners.Count -eq 42 -and
          @($r664MenuClaim.owners | Where-Object { $_ -ceq $r664MenuOwner }).Count -eq 1) `
          'R664 menu admission must add exactly its single shared navigation owner.'
        $r664MenuClaim.owners = @($r664MenuClaim.owners | Where-Object { $_ -cne $r664MenuOwner })
        Assert-Coordination (
          ($r664MenuPolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r664MenuPolicyAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'R664 menu admission changed another claim or policy field.'
        $r664MenuManifestHash = '998678329583C21D9C02E85A1DE3CA085DCC3430140D14D27F47EA2729E41F42'
        if ($r665CollectionContext) {
          $r664PriorManifest = @(& git -C $root rev-parse "${r665CollectionParent}:$($r664MenuOwners[1])")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r664PriorManifest.Count -eq 1 -and
            [string]$r664PriorManifest[0] -ceq 'b1baeb81b4d12e48f30e8abff6f5f1fdb3003971') `
            'R664 historical menu manifest changed.'
        } else {
          Assert-Coordination (
            (Get-Sha256 (Join-Path $root $r664MenuOwners[1])) -ceq $r664MenuManifestHash
          ) 'R664 menu admission manifest differs from its reviewed owner scope.'
        }
        $r664MenuScopeBefore = Get-R66Utf8GitJson $r664MenuAdmissionParent $r664MenuOwners[2]
        $r664MenuScopeAfter = if ($r665CollectionContext) {
          Get-R66Utf8GitJson $r665CollectionParent $r664MenuOwners[2]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath `
            (Join-Path $root $r664MenuOwners[2]) | ConvertFrom-Json
        }
        Assert-Coordination (
          $r664MenuScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
            $r664MenuManifestHash
        ) 'R664 menu scope is not bound to its admission manifest.'
        $r664MenuScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 =
          $r664MenuScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (
          ($r664MenuScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r664MenuScopeAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'R664 menu admission changed execution authority beyond its manifest binding.'
        $r664MenuUnchangedOwners = @($r66FreezeOwners | Where-Object { $_ -cnotin $r664MenuOwners })
        if ($r664MenuUnchangedOwners.Count -gt 0) {
          & git -C $root diff --quiet $r664MenuAdmissionParent -- @r664MenuUnchangedOwners
          Assert-Coordination ($LASTEXITCODE -eq 0) 'R664 menu admission changed another frozen owner.'
          $r664MenuUnchangedHistory = @(& git -C $root log --format=%H `
              "${r664MenuAdmissionParent}..$head" -- @r664MenuUnchangedOwners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r664MenuUnchangedHistory.Count -eq 0) `
            'R664 menu admission cannot unfreeze or revise unrelated coordination owners.'
        }
        if ($head -ceq $r664MenuAdmissionParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
            'Pending R664 menu admission is not a handoff or acceptance.'
          $r664MenuDirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r664MenuDirty | Sort-Object) -join '|') -ceq
            (@($r664MenuOwners | Sort-Object) -join '|')) `
            'Pending R664 menu admission must change exactly four coordination owners.'
        } else {
          $r664MenuFollowing = @(& git -C $root rev-list --reverse --ancestry-path `
              "${r664MenuAdmissionParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r664MenuFollowing.Count -gt 0) `
            'R664 menu admission ancestry lookup failed.'
          $r664MenuCommit = [string]$r664MenuFollowing[0]
          $r664MenuParents = @(& git -C $root show -s --format=%P $r664MenuCommit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r664MenuParents.Count -eq 1 -and
            [string]$r664MenuParents[0] -ceq $r664MenuAdmissionParent) `
            'R664 menu admission requires its exact single parent.'
          $r664MenuCommittedSubject = @(& git -C $root show -s --format=%s $r664MenuCommit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r664MenuCommittedSubject.Count -eq 1 -and
            [string]$r664MenuCommittedSubject[0] -ceq $r664MenuSubject) `
            'R664 menu admission subject changed.'
          $r664MenuCommittedOwners = @(& git -C $root diff-tree --no-commit-id --name-only -r $r664MenuCommit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r664MenuCommittedOwners | Sort-Object) -join '|') -ceq
            (@($r664MenuOwners | Sort-Object) -join '|')) `
            'R664 menu admission changed a runtime, test, evidence or unexpected owner.'
          if ($r665CollectionContext) {
            & git -C $root diff --quiet $r664MenuCommit $r664MenuFreezeHead -- @r664MenuOwners
          } else {
            & git -C $root diff --quiet $r664MenuCommit -- @r664MenuOwners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'R664 menu coordination changed after admission.'
          $r664MenuLaterHistory = @(& git -C $root log --format=%H `
              "${r664MenuCommit}..$r664MenuFreezeHead" -- @r664MenuOwners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r664MenuLaterHistory.Count -eq 0) `
            'R664 menu admission cannot be replayed or revised by later feature commits.'
        }
      }
      if ($r665CollectionContext) {
        # Single immutable dependency admission; never grant Cursor a Work write claim.
        $r665Contract = 'apps/mobile/lib/features/work/scan_and_pick_contract.dart'
        $r665Owners = @($r664MenuOwners) + $r665Contract
        $r665Subject = 'ui(buy-redmi-fixes-v1-20260905): admit immutable Scan and Pick contract'
        $r665ManifestHash = '820F22A4AF11ABE8E070750F59B250A01E7AB4A083B073620EBB03D6FE5A066E'
        $r665MergePath = (& git -C $root rev-parse --git-path MERGE_HEAD).Trim()
        Assert-Coordination ($LASTEXITCODE -eq 0 -and
          -not (Test-Path -LiteralPath $r665MergePath)) 'Collection admission cannot run during a merge.'
        $r665PolicyBefore = Get-R66Utf8GitJson $r665CollectionParent $r665Owners[0]
        $r665PolicyAfter = if ($r666AccessibilityContext) {
          Get-R66Utf8GitJson $r666AccessibilityParent $r665Owners[0]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath `
            (Join-Path $root $r665Owners[0]) | ConvertFrom-Json
        }
        $r665Primary = @($r665PolicyAfter.activeClaims | Where-Object { $_.task -ceq '/root' })[0]
        Assert-Coordination ($r665Primary.owners.Count -eq 11 -and
          @($r665Primary.owners | Where-Object { $_ -ceq $r665Contract }).Count -eq 1) `
          'Collection definition must have exactly its single Codex owner.'
        $r665Primary.owners = @($r665Primary.owners | Where-Object { $_ -cne $r665Contract })
        Assert-Coordination (
          ($r665PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r665PolicyAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'Collection admission changed another claim, registry binding or policy.'
        if (-not $r666AccessibilityContext) {
          Assert-Coordination (
            (Get-Sha256 (Join-Path $root $r665Owners[1])) -ceq $r665ManifestHash
          ) 'Collection dependency manifest changed.'
        }
        $r665ScopeBefore = Get-R66Utf8GitJson $r665CollectionParent $r665Owners[2]
        $r665ScopeAfter = if ($r666AccessibilityContext) {
          Get-R66Utf8GitJson $r666AccessibilityParent $r665Owners[2]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath `
            (Join-Path $root $r665Owners[2]) | ConvertFrom-Json
        }
        Assert-Coordination (
          $r665ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r665ManifestHash
        ) 'Collection dependency scope binding changed.'
        $r665ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 =
          $r665ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (
          ($r665ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r665ScopeAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'Collection admission changed execution authority beyond its manifest binding.'
        $r665SourceBlob = @(& git -C $root rev-parse "6ea045b3243c5b06f5eeb28c9aa12670f8ff1156:$r665Contract")
        Assert-Coordination ($LASTEXITCODE -eq 0 -and $r665SourceBlob.Count -eq 1 -and
          [string]$r665SourceBlob[0] -ceq 'aad041323be2b987f28d00438fd98d96bc5b0ea2' -and
          (Get-Sha256 (Join-Path $root $r665Contract)) -ceq
            '4F51CB811007F838DE517CDF49970ABCC8F6434B16B3BA78069B10AB8A904993') `
          'Collection dependency differs from the sealed Codex blob.'
        if ($head -ceq $r665CollectionParent) {
          $r665CollectionAdmissionPending = $true
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
            'Pending collection admission is not a handoff or acceptance.'
          $r665Drafts = @{
            'apps/mobile/lib/features/buy/buy_v2_session.dart' = 'CCFF7FD8CA50B4F29FDD9EE57419A65FA6875465EC8AE67F6AFC6496CBE45A47'
            'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart' = '74DF3C1D38E9C788ACB59A2A3B0F90393EBABE1E8AE2F3E0E5BE74E92D0400A2'
            'apps/mobile/test/ui_v2/buy/buy_v2_session_test.dart' = '7806C599B20F3BD7260028D27F1BAF9B0B59AA81CF884D3FA259BDBEFB05223F'
            'apps/mobile/test/ui_v2/buy/buy_v2_scoped_cart_checkout_dock_continuity_test.dart' = 'DE4375E287F1301DE11BD8B37854D39EF47A97020F02491D0EB4D2CF0604349F'
          }
          foreach ($r665Draft in $r665Drafts.Keys) {
            Assert-Coordination (
              (Get-Sha256 (Join-Path $root $r665Draft)) -ceq $r665Drafts[$r665Draft]
            ) "Collection admission modified a preserved draft: $r665Draft"
          }
          $r665Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Collection admission dirty inventory failed.'
          $r665Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@(@($r665Dirty) + @($r665Untracked) | Sort-Object -Unique) -join '|') -ceq
            (@(@($r665Drafts.Keys) + $r665Owners | Sort-Object) -join '|')) `
            'Collection admission must preserve exactly four drafts and add only five admitted owners.'
        } else {
          $r665Following = @(& git -C $root rev-list --first-parent --reverse "${r665CollectionParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r665Following.Count -gt 0) `
            'Collection admission commit is missing.'
          $r665Commit = [string]$r665Following[0]
          $r665Parents = @(& git -C $root show -s --format=%P $r665Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r665Parents.Count -eq 1 -and
            [string]$r665Parents[0] -ceq $r665CollectionParent) 'Collection admission parent changed.'
          $r665ActualSubject = @(& git -C $root show -s --format=%s $r665Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r665ActualSubject.Count -eq 1 -and
            [string]$r665ActualSubject[0] -ceq $r665Subject) 'Collection admission subject changed.'
          $r665Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r665Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r665Committed | Sort-Object) -join '|') -ceq
            (@($r665Owners | Sort-Object) -join '|')) 'Collection admission committed an unexpected owner or draft.'
          if ($r666AccessibilityContext) {
            & git -C $root diff --quiet $r665Commit $r665FreezeHead -- @r665Owners
          } else {
            & git -C $root diff --quiet $r665Commit -- @r665Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Collection dependency or admission binding changed after sealing.'
          $r665Later = @(& git -C $root log --format=%H "${r665Commit}..$r665FreezeHead" -- @r665Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r665Later.Count -eq 0) `
            'Collection dependency admission cannot be reused or changed by later feature commits.'
        }
        $r66CoordinationOwners = @($r66CoordinationOwners) + $r665Contract
      }
      if ($r666AccessibilityContext) {
        # The founder authorises A11Y-001; preserve the previous dependency
        # admission through its exact parent and add no general native claim.
        $r666Owners = @($r664MenuOwners)
        $r666UiOwners = @(
          'apps/mobile/lib/ui_v2/profile/global_privacy_preferences_v2.dart',
          'apps/mobile/lib/ui_v2/profile/global_security_v2.dart',
          'apps/mobile/test/ui_v2/profile/global_privacy_preferences_v2_test.dart'
        )
        $r666Native = 'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt'
        $r666Subject = 'ui(buy-redmi-fixes-v1-20260905): admit global accessibility dependency'
        $r666ManifestHash = '18F5195AAB125587F11B8E3E84FEF7A2544BE82013BF874C9CA0823931BF791C'
        $r666PolicyBefore = Get-R66Utf8GitJson $r666AccessibilityParent $r666Owners[0]
        $r666PolicyAfter = if ($r667DependenciesContext) {
          Get-R66Utf8GitJson $r667DependenciesParent $r666Owners[0]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath `
            (Join-Path $root $r666Owners[0]) | ConvertFrom-Json
        }
        $r666Cursor = @($r666PolicyAfter.activeClaims | Where-Object {
          $_.task -ceq '/root/cursor_buy_redmi_fixes_v1_20260905'
        })[0]
        $r666Primary = @($r666PolicyAfter.activeClaims | Where-Object { $_.task -ceq '/root' })[0]
        Assert-Coordination ($r666Cursor.owners.Count -eq 45 -and
          $r666Primary.owners.Count -eq 12 -and
          @($r666Primary.owners | Where-Object { $_ -ceq $r666Native }).Count -eq 1) `
          'Accessibility admission requires exactly three UI owners and one primary native owner.'
        foreach ($r666UiOwner in $r666UiOwners) {
          Assert-Coordination (@($r666Cursor.owners | Where-Object { $_ -ceq $r666UiOwner }).Count -eq 1) `
            "Accessibility UI owner is missing or duplicated: $r666UiOwner"
        }
        $r666Cursor.owners = @($r666Cursor.owners | Where-Object { $_ -cnotin $r666UiOwners })
        $r666Primary.owners = @($r666Primary.owners | Where-Object { $_ -cne $r666Native })
        Assert-Coordination (
          ($r666PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r666PolicyAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'Accessibility admission changed another claim, policy or registry binding.'
        if (-not $r667DependenciesContext) {
          Assert-Coordination (
            (Get-Sha256 (Join-Path $root $r666Owners[1])) -ceq $r666ManifestHash
          ) 'Accessibility admission manifest changed.'
        }
        $r666ScopeBefore = Get-R66Utf8GitJson $r666AccessibilityParent $r666Owners[2]
        $r666ScopeAfter = if ($r667DependenciesContext) {
          Get-R66Utf8GitJson $r667DependenciesParent $r666Owners[2]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath `
            (Join-Path $root $r666Owners[2]) | ConvertFrom-Json
        }
        Assert-Coordination (
          $r666ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq
            $r666ManifestHash
        ) 'Accessibility scope is not bound to its exact manifest.'
        $r666ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 =
          $r666ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (
          ($r666ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r666ScopeAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'Accessibility admission changed execution authority beyond its manifest binding.'
        $r666NativeHash = Get-Sha256 (Join-Path $root $r666Native)
        Assert-Coordination ($r666NativeHash -cin @(
          '91CA404E173CC60E16D1223CD097F7586862ADE8FA62BDBF9208F0B624047BAC',
          '4150F3FC71BFC1A924B7A5597C4CBFFC35D5AA42851CEFAB60B71F151FF471A1'
        )) 'Accessibility native bridge changed unrelated source or differs from its bounded implementation.'
        if ($head -ceq $r666AccessibilityParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
            'Pending accessibility admission is not a handoff or acceptance.'
          $r666Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r666Dirty | Sort-Object) -join '|') -ceq
            (@($r666Owners | Sort-Object) -join '|')) `
            'Pending accessibility admission must change exactly four coordination owners.'
          $r666Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r666Untracked.Count -eq 0 -and
            $r666NativeHash -ceq '91CA404E173CC60E16D1223CD097F7586862ADE8FA62BDBF9208F0B624047BAC') `
            'Accessibility admission cannot include untracked or native implementation drafts.'
        } else {
          $r666Following = @(& git -C $root rev-list --first-parent --reverse "${r666AccessibilityParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r666Following.Count -gt 0) `
            'Accessibility admission commit is missing.'
          $r666Commit = [string]$r666Following[0]
          $r666Parents = @(& git -C $root show -s --format=%P $r666Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r666Parents.Count -eq 1 -and
            [string]$r666Parents[0] -ceq $r666AccessibilityParent) 'Accessibility admission parent changed.'
          $r666ActualSubject = @(& git -C $root show -s --format=%s $r666Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r666ActualSubject.Count -eq 1 -and
            [string]$r666ActualSubject[0] -ceq $r666Subject) 'Accessibility admission subject changed.'
          $r666Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r666Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r666Committed | Sort-Object) -join '|') -ceq
            (@($r666Owners | Sort-Object) -join '|')) 'Accessibility admission committed an unexpected owner.'
          if ($r667DependenciesContext) {
            & git -C $root diff --quiet $r666Commit $r666FreezeHead -- @r666Owners
          } else {
            & git -C $root diff --quiet $r666Commit -- @r666Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Accessibility ownership binding changed after admission.'
          $r666Later = @(& git -C $root log --format=%H "${r666Commit}..$r666FreezeHead" -- @r666Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r666Later.Count -eq 0) `
            'Accessibility admission cannot be replayed or revised.'
        }
        $r66CoordinationOwners = @($r66CoordinationOwners) + $r666Native
      }
      if ($r667DependenciesContext) {
        # Exact local verification dependencies; preserve all earlier admissions.
        $r667Owners = @($r664MenuOwners)
        $r667UiOwners = @(
          'apps/mobile/test/ui_v2/profile/global_help_support_v2_test.dart',
          'apps/mobile/test/ui_v2/profile/global_security_v2_test.dart',
          'apps/mobile/lib/features/work/screens/work_onboarding_screens.dart',
          'apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart'
        )
        $r667PrimaryOwners = @(
          'apps/mobile/.flutter-plugins-dependencies',
          'scripts/check-approved-ui-locks.ps1'
        )
        $r667Subject = 'ui(buy-redmi-fixes-v1-20260905): admit local verification dependencies'
        $r667ManifestHash = '6BC23AEDE475C2A4259BF2630EDBC14533D0ECECD9D7125504CCC3D065D101DD'
        $r667PolicyBefore = Get-R66Utf8GitJson $r667DependenciesParent $r667Owners[0]
        $r667PolicyAfter = if ($r669RegressionContext) {
          Get-R66Utf8GitJson $r669RegressionParent $r667Owners[0]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r667Owners[0]) | ConvertFrom-Json
        }
        $r667Cursor = @($r667PolicyAfter.activeClaims | Where-Object {
          $_.task -ceq '/root/cursor_buy_redmi_fixes_v1_20260905'
        })[0]
        $r667Primary = @($r667PolicyAfter.activeClaims | Where-Object { $_.task -ceq '/root' })[0]
        Assert-Coordination ($r667Cursor.owners.Count -eq 49 -and $r667Primary.owners.Count -eq 14) `
          'Local verification admission requires exactly four UI/test and two primary owners.'
        foreach ($r667Owner in $r667UiOwners) {
          Assert-Coordination (@($r667Cursor.owners | Where-Object { $_ -ceq $r667Owner }).Count -eq 1) `
            "Local verification UI/test owner is missing or duplicated: $r667Owner"
        }
        foreach ($r667Owner in $r667PrimaryOwners) {
          Assert-Coordination (@($r667Primary.owners | Where-Object { $_ -ceq $r667Owner }).Count -eq 1) `
            "Local verification primary owner is missing or duplicated: $r667Owner"
        }
        $r667Cursor.owners = @($r667Cursor.owners | Where-Object { $_ -cnotin $r667UiOwners })
        $r667Primary.owners = @($r667Primary.owners | Where-Object { $_ -cnotin $r667PrimaryOwners })
        Assert-Coordination (
          ($r667PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r667PolicyAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'Local verification admission changed another claim, policy or registry binding.'
        if (-not $r668FormattingContext) {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r667Owners[1])) -ceq $r667ManifestHash) `
            'Local verification admission manifest changed.'
        }
        $r667ScopeBefore = Get-R66Utf8GitJson $r667DependenciesParent $r667Owners[2]
        $r667ScopeAfter = if ($r668FormattingContext) {
          Get-R66Utf8GitJson $r668FormattingParent $r667Owners[2]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r667Owners[2]) | ConvertFrom-Json
        }
        Assert-Coordination (
          $r667ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r667ManifestHash
        ) 'Local verification scope is not bound to its exact manifest.'
        $r667ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 =
          $r667ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (
          ($r667ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r667ScopeAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'Local verification admission changed execution authority beyond its manifest binding.'
        $r667CopyHashes = @{
          $r667UiOwners[2] = @(
            'BB6E832A9B1BB032BF9B49B4D603A35A9FDE5B1BF08D7D39CCE86E96F3E354EC',
            '08F7006B371E1939E3B525CC375427C57C7A489C2F792AA4FD20CD8B86E85709'
          )
          $r667UiOwners[3] = @(
            'C30C896CAA9A2560091B000B6D4859C1DE27971332BC526F5A4C930BD4E89C92',
            '971518A7D413D6D6DB7148678BB33E5896E5E4BF9690326CE82FD8480EC31742'
          )
        }
        foreach ($r667Owner in $r667CopyHashes.Keys) {
          $r667AllowedCopyHashes = $r667CopyHashes[$r667Owner]
          if ($r668FormattingContext -and $r667Owner -ceq $r667UiOwners[3]) {
            $r667AllowedCopyHashes = @(
              '971518A7D413D6D6DB7148678BB33E5896E5E4BF9690326CE82FD8480EC31742',
              '31CEDA835734EA697CDC570C4741968629825198F9008EED5E8E668BE19C1D9F'
            )
          }
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r667Owner)) -cin $r667AllowedCopyHashes) `
            "Local verification permits only the seven recorded Work copy substitutions: $r667Owner"
        }
        Assert-Coordination ((Get-Sha256 (Join-Path $root $r666Native)) -ceq
          '4150F3FC71BFC1A924B7A5597C4CBFFC35D5AA42851CEFAB60B71F151FF471A1') `
          'Local verification cannot change or remove the sealed Accessibility native bridge.'
        $r667Packages = @{
          'apps/mobile/pubspec.yaml' = 'FA2E683195273EE02DBFB315F88569FD2638C3FDE4E2B82B032EBC4BBE31DBB9'
          'apps/mobile/pubspec.lock' = '4DE45D3DD966862B160102C682DA52A61213CE70B50BC90C82CC69F203E8589D'
        }
        foreach ($r667Owner in $r667Packages.Keys) {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r667Owner)) -ceq $r667Packages[$r667Owner]) `
            "Local verification cannot change dependency versions: $r667Owner"
        }
        $r667MetadataBefore = Get-R66Utf8GitJson $r667DependenciesParent $r667PrimaryOwners[0]
        $r667MetadataAfter = Get-Content -Raw -Encoding UTF8 -LiteralPath `
          (Join-Path $root $r667PrimaryOwners[0]) | ConvertFrom-Json
        $r667ExpectedPath = (Join-Path $root 'apps/mobile/packages/youtube_embedded_player_private_dev').Replace('\','/').TrimEnd('/')
        $r667PathStates = @()
        foreach ($r667Platform in @('android','ios')) {
          $r667OldPlugin = @($r667MetadataBefore.plugins.$r667Platform | Where-Object name -ceq 'youtube_embedded_player_private_dev')
          $r667NewPlugin = @($r667MetadataAfter.plugins.$r667Platform | Where-Object name -ceq 'youtube_embedded_player_private_dev')
          Assert-Coordination ($r667OldPlugin.Count -eq 1 -and $r667NewPlugin.Count -eq 1) `
            'Local verification private-player plugin identity changed.'
          $r667NewPath = ([string]$r667NewPlugin[0].path).Replace('\','/').TrimEnd('/')
          $r667OldPath = ([string]$r667OldPlugin[0].path).Replace('\','/').TrimEnd('/')
          Assert-Coordination ($r667NewPath -ceq $r667OldPath -or $r667NewPath -ceq $r667ExpectedPath) `
            'Local verification plugin path points outside its exact current package.'
          $r667PathStates += ($r667NewPath -ceq $r667ExpectedPath)
          $r667NewPlugin[0].path = $r667OldPlugin[0].path
        }
        Assert-Coordination ($r667PathStates[0] -eq $r667PathStates[1]) `
          'Local verification plugin paths must be refreshed together.'
        $r667PluginDate = [DateTime]::MinValue
        Assert-Coordination ([DateTime]::TryParse([string]$r667MetadataAfter.date_created,[ref]$r667PluginDate)) `
          'Local verification metadata creation time is invalid.'
        $r667MetadataAfter.date_created = $r667MetadataBefore.date_created
        Assert-Coordination (
          ($r667MetadataBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r667MetadataAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'Local verification metadata changed beyond the two paths and creation time.'
        if ($head -ceq $r667DependenciesParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
            'Pending local verification admission is not a handoff or acceptance.'
          $r667Preimages = @{
            $r667UiOwners[0] = 'F2783DC78EC2AA5ADF48045DFFCD2123B5EE42C95519BD420B1C156954D12762'
            $r667UiOwners[1] = '681D37E1813DEE79042C92BA93E32C0B26E3DC64C567D04F278C12BFC99FE395'
            $r667UiOwners[2] = $r667CopyHashes[$r667UiOwners[2]][0]
            $r667UiOwners[3] = $r667CopyHashes[$r667UiOwners[3]][0]
            $r667PrimaryOwners[0] = 'FD3BC97BAA35F8C3F272C8D31370F0545EC598FE9A28A73654ADAEFD02C0C4F5'
            $r667PrimaryOwners[1] = '61632B18856985D52228196EB720D7FB52297F0FE8E3078A37552611936F5C28'
          }
          foreach ($r667Owner in $r667Preimages.Keys) {
            Assert-Coordination ((Get-Sha256 (Join-Path $root $r667Owner)) -ceq $r667Preimages[$r667Owner]) `
              "Local verification implementation cannot precede admission: $r667Owner"
          }
          $r667Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r667Dirty | Sort-Object) -join '|') -ceq (@($r667Owners | Sort-Object) -join '|')) `
            'Pending local verification admission must change exactly four coordination owners.'
          $r667Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r667Untracked.Count -eq 0) `
            'Local verification admission cannot include untracked implementation drafts.'
        } else {
          $r667Following = @(& git -C $root rev-list --first-parent --reverse "${r667DependenciesParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r667Following.Count -gt 0) 'Local verification admission is missing.'
          $r667Commit = [string]$r667Following[0]
          $r667Parents = @(& git -C $root show -s --format=%P $r667Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r667Parents.Count -eq 1 -and
            [string]$r667Parents[0] -ceq $r667DependenciesParent) 'Local verification admission parent changed.'
          $r667ActualSubject = @(& git -C $root show -s --format=%s $r667Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r667ActualSubject.Count -eq 1 -and
            [string]$r667ActualSubject[0] -ceq $r667Subject) 'Local verification admission subject changed.'
          $r667Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r667Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r667Committed | Sort-Object) -join '|') -ceq (@($r667Owners | Sort-Object) -join '|')) `
            'Local verification admission committed an unexpected owner.'
          if ($r668FormattingContext) {
            & git -C $root diff --quiet $r667Commit $r667FreezeHead -- @r667Owners
          } else {
            & git -C $root diff --quiet $r667Commit -- @r667Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Local verification ownership binding changed after admission.'
          $r667Later = @(& git -C $root log --format=%H "${r667Commit}..$r667FreezeHead" -- @r667Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r667Later.Count -eq 0) `
            'Local verification admission cannot be replayed or revised.'
        }
        $r66CoordinationOwners = @($r66CoordinationOwners) + $r667PrimaryOwners
      }
      if ($r668FormattingContext) {
        # A single formatter-only source binding; no additional ownership.
        $r668Owners = @($r667Owners[1], $r667Owners[2], $r667Owners[3])
        $r668ManifestHash = '899DD6F57BFA33EA7180C4CBA4C92CF023A08A9BBFEE3A4E1ED5F1E0DC4E13BF'
        $r668Subject = 'ui(buy-redmi-fixes-v1-20260905): admit exact dashboard formatting'
        if (-not $r669RegressionContext) {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r668Owners[0])) -ceq $r668ManifestHash) `
            'Dashboard formatting manifest changed.'
        }
        $r668ScopeBefore = Get-R66Utf8GitJson $r668FormattingParent $r668Owners[1]
        $r668ScopeAfter = if ($r669RegressionContext) {
          Get-R66Utf8GitJson $r669RegressionParent $r668Owners[1]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r668Owners[1]) | ConvertFrom-Json
        }
        Assert-Coordination (
          $r668ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r668ManifestHash
        ) 'Dashboard formatting scope has the wrong manifest binding.'
        $r668ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 =
          $r668ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (
          ($r668ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r668ScopeAfter | ConvertTo-Json -Depth 100 -Compress)
        ) 'Dashboard formatting changed execution authority.'
        if ($r669RegressionContext) {
          & git -C $root diff --quiet $r668FormattingParent $r668FreezeHead -- $r667Owners[0]
        } else {
          & git -C $root diff --quiet $r668FormattingParent -- $r667Owners[0]
        }
        Assert-Coordination ($LASTEXITCODE -eq 0) 'Dashboard formatting changed ownership policy.'
        $r668PolicyHistory = @(& git -C $root log --format=%H "${r668FormattingParent}..$r668FreezeHead" -- $r667Owners[0])
        Assert-Coordination ($LASTEXITCODE -eq 0 -and $r668PolicyHistory.Count -eq 0) `
          'Dashboard formatting cannot revise ownership history.'
        if ($head -ceq $r668FormattingParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
            'Pending dashboard formatting admission is not a handoff or acceptance.'
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r667UiOwners[3])) -ceq
            '971518A7D413D6D6DB7148678BB33E5896E5E4BF9690326CE82FD8480EC31742') `
            'Dashboard formatting cannot precede its admission.'
          $r668Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r668Dirty | Sort-Object) -join '|') -ceq (@($r668Owners | Sort-Object) -join '|')) `
            'Pending dashboard formatting must change exactly three coordination owners.'
          $r668Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r668Untracked.Count -eq 0) `
            'Dashboard formatting admission cannot include untracked drafts.'
        } else {
          $r668Following = @(& git -C $root rev-list --first-parent --reverse "${r668FormattingParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r668Following.Count -gt 0) `
            'Dashboard formatting admission is missing.'
          $r668Commit = [string]$r668Following[0]
          $r668Parents = @(& git -C $root show -s --format=%P $r668Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r668Parents.Count -eq 1 -and
            [string]$r668Parents[0] -ceq $r668FormattingParent) 'Dashboard formatting admission parent changed.'
          $r668ActualSubject = @(& git -C $root show -s --format=%s $r668Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r668ActualSubject.Count -eq 1 -and
            [string]$r668ActualSubject[0] -ceq $r668Subject) 'Dashboard formatting admission subject changed.'
          $r668Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r668Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r668Committed | Sort-Object) -join '|') -ceq (@($r668Owners | Sort-Object) -join '|')) `
            'Dashboard formatting admission committed an unexpected owner.'
          if ($r669RegressionContext) {
            & git -C $root diff --quiet $r668Commit $r668FreezeHead -- @r668Owners
          } else {
            & git -C $root diff --quiet $r668Commit -- @r668Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Dashboard formatting binding changed after admission.'
          $r668Later = @(& git -C $root log --format=%H "${r668Commit}..$r668FreezeHead" -- @r668Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r668Later.Count -eq 0) `
            'Dashboard formatting admission cannot be replayed or revised.'
        }
      }

      if ($r669RegressionContext) {
        $r669Owners = @($r667Owners)
        $r669ManifestHash = '0A63C6D63BB9AACC65BBB86F4CDE8BB0E71E64D1AC339BC9B6B6B0699C9B593B'
        $r669Subject = 'ui(buy-redmi-fixes-v1-20260905): admit full regression and portable tooling'
        if (-not $r670SourceContext) {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r669Owners[1])) -ceq $r669ManifestHash) 'Full regression manifest changed.'
        }
        $r669Manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r669Owners[1])
        $r669Match = [regex]::Matches($r669Manifest, '(?s)<!-- R669-DATA-BEGIN -->\s*(.*?)\s*<!-- R669-DATA-END -->')
        Assert-Coordination ($r669Match.Count -eq 1) 'Full regression exact owner data is missing or duplicated.'
        $r669Data = $r669Match[0].Groups[1].Value | ConvertFrom-Json
        Assert-Coordination ($r669Data.parent -ceq $r669RegressionParent -and $r669Data.tests.Count -eq 16 -and $r669Data.tools.Count -eq 30) 'Full regression owner data changed.'
        $r669Before = Get-R66Utf8GitJson $r669RegressionParent $r669Owners[0]
        $r669After = if ($r670SourceContext) {
          Get-R66Utf8GitJson $r670SourceParent $r669Owners[0]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r669Owners[0]) | ConvertFrom-Json
        }
        $r669Ui = @($r669After.activeClaims | Where-Object task -ceq '/root/cursor_buy_redmi_fixes_v1_20260905')[0]
        $r669Primary = @($r669After.activeClaims | Where-Object task -ceq '/root')[0]
        Assert-Coordination ($r669Ui.owners.Count -eq 65 -and $r669Primary.owners.Count -eq 44) 'Full regression ownership counts changed.'
        foreach ($item in $r669Data.tests) {
          Assert-Coordination (@($r669Ui.owners | Where-Object { $_ -ceq $item.path }).Count -eq 1) 'Full regression test owner missing or duplicated.'
        }
        foreach ($item in $r669Data.tools) {
          Assert-Coordination (@($r669Primary.owners | Where-Object { $_ -ceq $item.path }).Count -eq 1) 'Portable tool owner missing or duplicated.'
        }
        $r669Ui.owners = @($r669Ui.owners | Where-Object { $_ -cnotin @($r669Data.tests.path) })
        $r669Primary.owners = @($r669Primary.owners | Where-Object { $_ -cnotin @($r669Data.tools.path) })
        Assert-Coordination (($r669Before | ConvertTo-Json -Depth 100 -Compress) -ceq ($r669After | ConvertTo-Json -Depth 100 -Compress)) 'Full regression admission changed unrelated policy.'
        $r669ScopeBefore = Get-R66Utf8GitJson $r669RegressionParent $r669Owners[2]
        $r669ScopeAfter = if ($r670SourceContext) {
          Get-R66Utf8GitJson $r670SourceParent $r669Owners[2]
        } else {
          Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r669Owners[2]) | ConvertFrom-Json
        }
        Assert-Coordination ($r669ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r669ManifestHash) 'Full regression scope hash changed.'
        $r669ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 = $r669ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (($r669ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r669ScopeAfter | ConvertTo-Json -Depth 100 -Compress)) 'Full regression admission changed execution authority.'
        foreach ($item in $r669Data.tools) {
          $path = Join-Path $root $item.path
          $exists = Test-Path -LiteralPath $path -PathType Leaf
          $allowed = @($item.beforeSha256)
          if ($head -cne $r669RegressionParent) { $allowed += $item.proposedSha256 }
          if ($exists) {
            Assert-Coordination ((Get-Sha256 $path) -cin $allowed) "Portable tool differs from exact reviewed proposal: $($item.path)"
          } else {
            Assert-Coordination ([string]::IsNullOrEmpty($item.beforeSha256)) "Existing portable tool is missing: $($item.path)"
          }
        }
        if ($head -ceq $r669RegressionParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending full regression admission is not a handoff.'
          foreach ($item in $r669Data.tests) {
            Assert-Coordination ((Get-Sha256 (Join-Path $root $item.path)) -ceq $item.beforeSha256) 'Test implementation cannot precede exact admission.'
          }
          $r669Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r669Dirty | Sort-Object) -join '|') -ceq (@($r669Owners | Sort-Object) -join '|')) 'Pending full regression admission must change exactly four coordination owners.'
          $r669Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r669Untracked.Count -eq 0) 'Full regression admission cannot include untracked drafts.'
        } else {
          $r669Following = @(& git -C $root rev-list --first-parent --reverse "${r669RegressionParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r669Following.Count -gt 0) 'Full regression admission missing.'
          $r669Commit = [string]$r669Following[0]
          $r669Parents = @(& git -C $root show -s --format=%P $r669Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r669Parents.Count -eq 1 -and [string]$r669Parents[0] -ceq $r669RegressionParent) 'Full regression admission parent changed.'
          $r669ActualSubject = @(& git -C $root show -s --format=%s $r669Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r669ActualSubject.Count -eq 1 -and [string]$r669ActualSubject[0] -ceq $r669Subject) 'Full regression admission subject changed.'
          $r669Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r669Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r669Committed | Sort-Object) -join '|') -ceq (@($r669Owners | Sort-Object) -join '|')) 'Full regression admission committed an unexpected owner.'
          if ($r670SourceContext) {
            & git -C $root diff --quiet $r669Commit $r669FreezeHead -- @r669Owners
          } else {
            & git -C $root diff --quiet $r669Commit -- @r669Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Full regression coordination changed after admission.'
          $r669Later = @(& git -C $root log --format=%H "${r669Commit}..$r669FreezeHead" -- @r669Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r669Later.Count -eq 0) 'Full regression admission cannot be replayed or revised.'
        }
        $r66CoordinationOwners = @($r66CoordinationOwners) + @($r669Data.tools.path)
      }

      if ($r670SourceContext) {
        $r670Owners = @($r667Owners)
        $r670ManifestHash = '12EE0EDB708E805E6E2129BDD5C98B66397E7512C3B0F842C35C6AAA24AAB35D'
        if ($r671CorrectionContext) {
          $r670Manifest = Get-R66Utf8GitJson $r671CorrectionParent $r670Owners[1] -AsText
        } else {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r670Owners[1])) -ceq $r670ManifestHash) 'Qualified source manifest changed.'
          $r670Manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r670Owners[1])
        }
        $r670Match = [regex]::Matches($r670Manifest, '(?s)<!-- R670-DATA-BEGIN -->\s*(.*?)\s*<!-- R670-DATA-END -->')
        Assert-Coordination ($r670Match.Count -eq 1) 'Qualified source data missing or duplicated.'
        $r670Data = $r670Match[0].Groups[1].Value | ConvertFrom-Json
        Assert-Coordination ($r670Data.parent -ceq $r670SourceParent -and $r670Data.implementation.Count -eq 2 -and $r670Data.runtimeDelta.Count -eq 16 -and $r670Data.additionalPrimaryOwner -ceq 'scripts/check-windows-powershell-compatibility.ps1') 'Qualified source data changed.'
        $r670EvidencePath = 'C:\GUARANTEED OUTCOME\MOOLSOCIAL-CURSOR-BUY-UAT-20260905\SINGLECHAT-FULL-REGRESSION-BINDING-V1.json'
        Assert-Coordination ($r670Data.fullRegressionEvidence.path -ceq $r670EvidencePath -and $r670Data.fullRegressionEvidence.cycles -eq 2 -and $r670Data.fullRegressionEvidence.passedPerCycle -eq 1640 -and $r670Data.fullRegressionEvidence.skippedPerCycle -eq 27 -and (Get-Sha256 $r670EvidencePath) -ceq $r670Data.fullRegressionEvidence.sha256) 'Qualified source regression evidence changed.'
        $r670Before = Get-R66Utf8GitJson $r670SourceParent $r670Owners[0]
        $r670After = if ($r671CorrectionContext) { Get-R66Utf8GitJson $r671CorrectionParent $r670Owners[0] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r670Owners[0]) | ConvertFrom-Json }
        $r670Primary = @($r670After.activeClaims | Where-Object task -ceq '/root')[0]
        $r670Ui = @($r670After.activeClaims | Where-Object task -ceq '/root/cursor_buy_redmi_fixes_v1_20260905')[0]
        Assert-Coordination ($r670Ui.owners.Count -eq 65 -and $r670Primary.owners.Count -eq 45 -and @($r670Primary.owners | Where-Object { $_ -ceq $r670Data.additionalPrimaryOwner }).Count -eq 1) 'Qualified source ownership changed.'
        $r670Primary.owners = @($r670Primary.owners | Where-Object { $_ -cne $r670Data.additionalPrimaryOwner })
        Assert-Coordination (($r670Before | ConvertTo-Json -Depth 100 -Compress) -ceq ($r670After | ConvertTo-Json -Depth 100 -Compress)) 'Qualified source changed unrelated policy.'
        $r670ScopeBefore = Get-R66Utf8GitJson $r670SourceParent $r670Owners[2]
        $r670ScopeAfter = if ($r671CorrectionContext) { Get-R66Utf8GitJson $r671CorrectionParent $r670Owners[2] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r670Owners[2]) | ConvertFrom-Json }
        Assert-Coordination ($r670ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r670ManifestHash) 'Qualified source scope hash changed.'
        $r670ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 = $r670ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (($r670ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r670ScopeAfter | ConvertTo-Json -Depth 100 -Compress)) 'Qualified source changed execution authority.'
        foreach ($item in $r670Data.implementation) {
          $allowed = @($item.beforeSha256)
          if ($head -cne $r670SourceParent) { $allowed += $item.proposedSha256 }
          if ($r673SourceContext -and $head -cne $r673SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += 'E9CC76AADEB0592D1C0DF3055E0D5039D563C6F7796F555098E90EF83A6A8E11'
          }
          if ($r675SourceContext -and $head -cne $r675SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += '4565F7095F1DC6D3DACCC1BBD478E2697A2536F9A449B2F654B27CA581755DA2'
          }
          if ($r677SourceContext -and $head -cne $r677SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += 'E5E95B276A8B3C0CEDBD921A43B020450095F633371FF44D52823367AEDD529D'
          }
          if ($r680SourceContext -and $head -cne $r680SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += '0E63D1E4AAD91B84E3DB2F0307269C61828838CD45882A85B24BB1EEEAD23CE1'
          }
          if ($r680SourceContext -and $head -cne $r680SourceParent -and $item.path -ceq 'scripts/check-buy-backend-contract-boundary.ps1') {
            $allowed += 'D91884A35072440F516AB3EA3D817B4C1CA61C1FF6577D9DD3FB9B1016374A5D'
          }
          Assert-Coordination ((Get-Sha256 (Join-Path $root $item.path)) -cin $allowed) 'Qualified checker differs from exact reviewed proposal.'
        }
        if ($head -ceq $r670SourceParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending qualified source admission is not a handoff.'
          $r670Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r670Dirty | Sort-Object) -join '|') -ceq (@($r670Owners | Sort-Object) -join '|')) 'Pending qualified source must change exactly four coordination owners.'
          $r670Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r670Untracked.Count -eq 0) 'Qualified source admission cannot include untracked drafts.'
        } else {
          $r670Following = @(& git -C $root rev-list --first-parent --reverse "${r670SourceParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r670Following.Count -gt 0) 'Qualified source admission missing.'
          $r670Commit = [string]$r670Following[0]
          $r670Parents = @(& git -C $root show -s --format=%P $r670Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r670Parents.Count -eq 1 -and [string]$r670Parents[0] -ceq $r670SourceParent) 'Qualified source admission parent changed.'
          $r670Subject = @(& git -C $root show -s --format=%s $r670Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r670Subject.Count -eq 1 -and [string]$r670Subject[0] -ceq 'ui(buy-redmi-fixes-v1-20260905): admit qualified Redmi build checks') 'Qualified source admission subject changed.'
          $r670Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r670Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r670Committed | Sort-Object) -join '|') -ceq (@($r670Owners | Sort-Object) -join '|')) 'Qualified source admission committed an unexpected owner.'
          if ($r671CorrectionContext) {
            & git -C $root diff --quiet $r670Commit $r670FreezeHead -- @r670Owners
          } else {
            & git -C $root diff --quiet $r670Commit -- @r670Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Qualified source coordination changed after admission.'
          $r670Later = @(& git -C $root log --format=%H "${r670Commit}..$r670FreezeHead" -- @r670Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r670Later.Count -eq 0) 'Qualified source admission cannot be replayed or revised.'
        }
        $r66CoordinationOwners = @($r66CoordinationOwners) + @($r670Data.additionalPrimaryOwner)
      }
      if ($r671CorrectionContext) {
        # Keep r66.5 qualification immutable in its historical tree. The founder
        # authorized this one successor correction pass after device replay.
        $r671Owners = @($r670Owners) + @('config/codex-development-regression-registry.json')
        $r671ManifestHash = '3146E4A559B8821D98DBEF38CEF1B19A761BC9335F9647E060424306B01E9DE7'
        if ($r672RegressionContext) {
          $r671Manifest = Get-R66Utf8GitJson $r672RegressionParent $r670Owners[1] -AsText
        } else {
        Assert-Coordination ((Get-Sha256 (Join-Path $root $r670Owners[1])) -ceq $r671ManifestHash) 'Device correction manifest changed.'
        $r671Manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r670Owners[1])
        }
        Assert-Coordination ($r671Manifest.Replace("`r`n","`n").StartsWith($r670Manifest.Replace("`r`n","`n").TrimEnd())) 'Device correction removed historical manifest evidence.'
        $r671Match = [regex]::Matches($r671Manifest, '(?s)<!-- R671-DATA-BEGIN -->\s*(.*?)\s*<!-- R671-DATA-END -->')
        Assert-Coordination ($r671Match.Count -eq 1) 'Device correction data missing or duplicated.'
        $r671Data = $r671Match[0].Groups[1].Value | ConvertFrom-Json
        $r671RegistryFull = if ($r676CorrectionContext) { Get-R66Utf8GitJson $r676CorrectionParent 'config/codex-development-regression-registry.json' } else { Get-Content -Raw -Encoding UTF8 -LiteralPath $registryPath | ConvertFrom-Json }
        $r671RegistryEntries = @($r671RegistryFull.entries)
        Assert-Coordination ($r671Data.parent -ceq $r671CorrectionParent -and $r671Data.registryCount -eq 4513 -and $r671RegistryEntries.Count -eq 4513 -and $r671Data.registrySha256 -ceq '651C8FBB852F6D26857318173C991F95A1267B88AB9D2991E1D6DB124714292C') 'Device correction registry generation changed.'
        if (-not $r676CorrectionContext) { Assert-Coordination ($registrySha -ceq $r671Data.registrySha256) 'Device correction live registry changed.' }
        Assert-Coordination ((Get-Sha256 $r671Data.reportPath) -ceq $r671Data.reportSha256 -and (Get-Sha256 $r671Data.matrixPath) -ceq $r671Data.matrixSha256) 'Device correction evidence changed.'
        $r671RegistryBefore = Get-R66Utf8GitJson $r671CorrectionParent $r671Owners[4]
        Assert-Coordination ($r671RegistryBefore.entries.Count -eq 4502 -and $r671RegistryEntries[4502].id -ceq $r671Data.firstAddedId -and $r671RegistryEntries[-1].id -ceq $r671Data.lastAddedId) 'Device correction registry append boundary changed.'
        $r671RegistryAfter = $r671RegistryFull
        $r671RegistryAfter.entries = @($r671RegistryAfter.entries | Select-Object -First 4502)
        Assert-Coordination (($r671RegistryBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r671RegistryAfter | ConvertTo-Json -Depth 100 -Compress)) 'Device correction changed existing registry evidence.'
        $r671PolicyBefore = Get-R66Utf8GitJson $r671CorrectionParent $r670Owners[0]
        $r671PolicyAfter = if ($r672RegressionContext) { Get-R66Utf8GitJson $r672RegressionParent $r670Owners[0] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath $policyPath | ConvertFrom-Json }
        $r671PolicyAfter.registryBinding = $r671PolicyBefore.registryBinding
        Assert-Coordination (($r671PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r671PolicyAfter | ConvertTo-Json -Depth 100 -Compress)) 'Device correction changed owner claims or unrelated policy.'
        $r671ScopeBefore = Get-R66Utf8GitJson $r671CorrectionParent $r670Owners[2]
        $r671ScopeAfter = if ($r672RegressionContext) { Get-R66Utf8GitJson $r672RegressionParent $r670Owners[2] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r670Owners[2]) | ConvertFrom-Json }
        Assert-Coordination ($r671ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r671ManifestHash) 'Device correction scope hash changed.'
        $r671ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 = $r671ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (($r671ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r671ScopeAfter | ConvertTo-Json -Depth 100 -Compress)) 'Device correction changed execution authority.'
        if ($head -ceq $r671CorrectionParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending device correction admission is not a handoff.'
          $r671Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r671Dirty | Sort-Object) -join '|') -ceq (@($r671Owners | Sort-Object) -join '|')) 'Pending device correction must change exactly five coordination owners.'
          $r671Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r671Untracked.Count -eq 0) 'Device correction admission cannot include untracked drafts.'
        } else {
          $r671Following = @(& git -C $root rev-list --first-parent --reverse "${r671CorrectionParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r671Following.Count -gt 0) 'Device correction admission missing.'
          $r671Commit = [string]$r671Following[0]
          $r671Parents = @(& git -C $root show -s --format=%P $r671Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r671Parents.Count -eq 1 -and [string]$r671Parents[0] -ceq $r671CorrectionParent) 'Device correction admission parent changed.'
          $r671Subject = @(& git -C $root show -s --format=%s $r671Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r671Subject.Count -eq 1 -and [string]$r671Subject[0] -ceq 'ui(buy-redmi-fixes-v1-20260905): admit r66.5 device corrections') 'Device correction admission subject changed.'
          $r671Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r671Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r671Committed | Sort-Object) -join '|') -ceq (@($r671Owners | Sort-Object) -join '|')) 'Device correction admission committed an unexpected owner.'
          if ($r672RegressionContext) {
            & git -C $root diff --quiet $r671Commit $r671FreezeHead -- @r671Owners
          } else {
            & git -C $root diff --quiet $r671Commit -- @r671Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Device correction coordination changed after admission.'
          $r671Later = @(& git -C $root log --format=%H "${r671Commit}..$r671FreezeHead" -- @r671Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r671Later.Count -eq 0) 'Device correction admission cannot be replayed or revised.'
        }
        $r66CoordinationOwners = @($r66CoordinationOwners) + @($r671Owners[4])
      }

      if ($r672RegressionContext) {
        $r672Owners = @($r670Owners)
        $r672ManifestHash = '0FC04E35EF36E039EA10F38C90B80FAB2B8FB680A6E8787834B9DCC912C94511'
        if ($r673SourceContext) {
          $r672Manifest = Get-R66Utf8GitJson $r673SourceParent $r672Owners[1] -AsText
        } else {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r672Owners[1])) -ceq $r672ManifestHash) 'Product regression manifest changed.'
          $r672Manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r672Owners[1])
        }
        Assert-Coordination ($r672Manifest.Replace("`r`n","`n").StartsWith($r671Manifest.Replace("`r`n","`n").TrimEnd())) 'Product regression removed historical manifest evidence.'
        $r672Match = [regex]::Matches($r672Manifest, '(?s)<!-- R672-DATA-BEGIN -->\s*(.*?)\s*<!-- R672-DATA-END -->')
        Assert-Coordination ($r672Match.Count -eq 1) 'Product regression data missing or duplicated.'
        $r672Data = $r672Match[0].Groups[1].Value | ConvertFrom-Json
        Assert-Coordination ($r672Data.parent -ceq $r672RegressionParent -and $r672Data.additionalUiOwner -ceq 'apps/mobile/test/ui_v2/buy/buy_v2_product_content_test.dart' -and $r672Data.testRepair.path -ceq $r672Data.additionalUiOwner) 'Product regression owner changed.'
        Assert-Coordination ($r672Data.failureEvidence.passed -eq 1656 -and $r672Data.failureEvidence.skipped -eq 27 -and $r672Data.failureEvidence.failed -eq 8 -and (Get-Sha256 $r672Data.failureEvidence.path) -ceq $r672Data.failureEvidence.sha256) 'Product regression failed evidence changed.'
        $r672PolicyBefore = Get-R66Utf8GitJson $r672RegressionParent $r672Owners[0]
        $r672PolicyAfter = if ($r676CorrectionContext) { Get-R66Utf8GitJson $r676CorrectionParent $r670Owners[0] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath $policyPath | ConvertFrom-Json }
        $r672Ui = @($r672PolicyAfter.activeClaims | Where-Object task -ceq '/root/cursor_buy_redmi_fixes_v1_20260905')[0]
        $r672Primary = @($r672PolicyAfter.activeClaims | Where-Object task -ceq '/root')[0]
        Assert-Coordination ($r672Ui.owners.Count -eq 66 -and $r672Primary.owners.Count -eq 45 -and @($r672Ui.owners | Where-Object { $_ -ceq $r672Data.additionalUiOwner }).Count -eq 1) 'Product regression owner claim changed.'
        $r672Ui.owners = @($r672Ui.owners | Where-Object { $_ -cne $r672Data.additionalUiOwner })
        Assert-Coordination (($r672PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r672PolicyAfter | ConvertTo-Json -Depth 100 -Compress)) 'Product regression changed unrelated policy.'
        $r672ScopeBefore = Get-R66Utf8GitJson $r672RegressionParent $r672Owners[2]
        $r672ScopeAfter = if ($r673SourceContext) { Get-R66Utf8GitJson $r673SourceParent $r672Owners[2] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r672Owners[2]) | ConvertFrom-Json }
        Assert-Coordination ($r672ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r672ManifestHash) 'Product regression scope hash changed.'
        $r672ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 = $r672ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (($r672ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r672ScopeAfter | ConvertTo-Json -Depth 100 -Compress)) 'Product regression changed execution authority.'
        $r672AllowedTestHashes = @($r672Data.testRepair.beforeSha256)
        if ($head -cne $r672RegressionParent) { $r672AllowedTestHashes += $r672Data.testRepair.proposedSha256 }
        Assert-Coordination ((Get-Sha256 (Join-Path $root $r672Data.additionalUiOwner)) -cin $r672AllowedTestHashes) 'Product regression test differs from exact proposal.'
        if ($head -ceq $r672RegressionParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending product regression admission is not a handoff.'
          $r672Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r672Dirty | Sort-Object) -join '|') -ceq (@($r672Owners | Sort-Object) -join '|')) 'Pending product regression must change exactly four coordination owners.'
          $r672Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r672Untracked.Count -eq 0) 'Product regression admission cannot include untracked drafts.'
        } else {
          $r672Following = @(& git -C $root rev-list --first-parent --reverse "${r672RegressionParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r672Following.Count -gt 0) 'Product regression admission missing.'
          $r672Commit = [string]$r672Following[0]
          $r672Parents = @(& git -C $root show -s --format=%P $r672Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r672Parents.Count -eq 1 -and [string]$r672Parents[0] -ceq $r672RegressionParent) 'Product regression admission parent changed.'
          $r672Subject = @(& git -C $root show -s --format=%s $r672Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r672Subject.Count -eq 1 -and [string]$r672Subject[0] -ceq 'ui(buy-redmi-fixes-v1-20260905): admit product fact regression update') 'Product regression admission subject changed.'
          $r672Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r672Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r672Committed | Sort-Object) -join '|') -ceq (@($r672Owners | Sort-Object) -join '|')) 'Product regression admission committed an unexpected owner.'
          if ($r673SourceContext) {
            & git -C $root diff --quiet $r672Commit $r672FreezeHead -- @r672Owners
          } else {
            & git -C $root diff --quiet $r672Commit -- @r672Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Product regression coordination changed after admission.'
          $r672Later = @(& git -C $root log --format=%H "${r672Commit}..$r672FreezeHead" -- @r672Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r672Later.Count -eq 0) 'Product regression admission cannot be replayed or revised.'
        }
      }

      if ($r673SourceContext) {
        $r673Owners = @($r670Owners[1],$r670Owners[2],$r670Owners[3])
        $r673ManifestHash = '36E7273C1CD367873E2F59A5883A679BE4B94F3FFAFA16A786285D98DB513273'
        if ($r675SourceContext) {
          $r673Manifest = Get-R66Utf8GitJson $r675SourceParent $r673Owners[0] -AsText
        } else {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r673Owners[0])) -ceq $r673ManifestHash) 'r66.6 source manifest changed.'
          $r673Manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r673Owners[0])
        }
        Assert-Coordination ($r673Manifest.Replace("`r`n","`n").StartsWith($r672Manifest.Replace("`r`n","`n").TrimEnd())) 'r66.6 source removed historical manifest evidence.'
        $r673Match = [regex]::Matches($r673Manifest, '(?s)<!-- R673-DATA-BEGIN -->\s*(.*?)\s*<!-- R673-DATA-END -->')
        Assert-Coordination ($r673Match.Count -eq 1) 'r66.6 source data missing or duplicated.'
        $r673Data = $r673Match[0].Groups[1].Value | ConvertFrom-Json
        Assert-Coordination ($r673Data.parent -ceq $r673SourceParent -and $r673Data.implementation.Count -eq 2 -and $r673Data.runtimeDelta.Count -eq 16 -and $r673Data.correctionRuntimeDelta.Count -eq 5) 'r66.6 source boundary changed.'
        Assert-Coordination (($r673Data.implementation.path -join '|') -ceq 'scripts/check-buy-protected-baseline.ps1|scripts/check-buy-backend-contract-boundary.ps1') 'r66.6 checker owners changed.'
        Assert-Coordination ((Get-Sha256 $r673Data.proposalBinding.path) -ceq $r673Data.proposalBinding.sha256) 'r66.6 source proposal changed.'
        Assert-Coordination ($r673Data.fullRegressionEvidence.cycles -eq 2 -and $r673Data.fullRegressionEvidence.passedPerCycle -eq 1664 -and $r673Data.fullRegressionEvidence.skippedPerCycle -eq 27 -and $r673Data.fullRegressionEvidence.sourceCommit -ceq $r673SourceParent -and (Get-Sha256 $r673Data.fullRegressionEvidence.path) -ceq $r673Data.fullRegressionEvidence.sha256) 'r66.6 full regression evidence changed.'
        Assert-Coordination ($r673Data.sourceBoundaryProposalEvidence.Count -eq 2) 'r66.6 boundary proposal evidence missing.'
        foreach ($evidence in $r673Data.sourceBoundaryProposalEvidence) {
          Assert-Coordination ($evidence.cases -eq 63 -and (Get-Sha256 $evidence.path) -ceq $evidence.sha256) 'r66.6 boundary proposal evidence changed.'
        }
        $r673PolicyBefore = Get-R66Utf8GitJson $r673SourceParent $r670Owners[0]
        $r673PolicyAfter = if ($r676CorrectionContext) { Get-R66Utf8GitJson $r676CorrectionParent $r670Owners[0] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath $policyPath | ConvertFrom-Json }
        Assert-Coordination (($r673PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r673PolicyAfter | ConvertTo-Json -Depth 100 -Compress)) 'r66.6 source changed policy or owner claims.'
        $r673ScopeBefore = Get-R66Utf8GitJson $r673SourceParent $r673Owners[1]
        $r673ScopeAfter = if ($r675SourceContext) { Get-R66Utf8GitJson $r675SourceParent $r673Owners[1] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r673Owners[1]) | ConvertFrom-Json }
        Assert-Coordination ($r673ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r673ManifestHash) 'r66.6 source scope hash changed.'
        $r673ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 = $r673ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (($r673ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r673ScopeAfter | ConvertTo-Json -Depth 100 -Compress)) 'r66.6 source changed execution authority.'
        foreach ($item in $r673Data.implementation) {
          $allowed = @($item.beforeSha256)
          if ($head -cne $r673SourceParent) { $allowed += $item.proposedSha256 }
          if ($r675SourceContext -and $head -cne $r675SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += '4565F7095F1DC6D3DACCC1BBD478E2697A2536F9A449B2F654B27CA581755DA2'
          }
          if ($r677SourceContext -and $head -cne $r677SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += 'E5E95B276A8B3C0CEDBD921A43B020450095F633371FF44D52823367AEDD529D'
          }
          if ($r680SourceContext -and $head -cne $r680SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += '0E63D1E4AAD91B84E3DB2F0307269C61828838CD45882A85B24BB1EEEAD23CE1'
          }
          if ($r680SourceContext -and $head -cne $r680SourceParent -and $item.path -ceq 'scripts/check-buy-backend-contract-boundary.ps1') {
            $allowed += 'D91884A35072440F516AB3EA3D817B4C1CA61C1FF6577D9DD3FB9B1016374A5D'
          }
          Assert-Coordination ((Get-Sha256 (Join-Path $root $item.path)) -cin $allowed) 'r66.6 checker differs from exact proposal.'
        }
        if ($head -ceq $r673SourceParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending r66.6 source admission is not a handoff.'
          $r673Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r673Dirty | Sort-Object) -join '|') -ceq (@($r673Owners | Sort-Object) -join '|')) 'Pending r66.6 source must change exactly three coordination owners.'
          $r673Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r673Untracked.Count -eq 0) 'r66.6 source admission cannot include untracked drafts.'
        } else {
          $r673Following = @(& git -C $root rev-list --first-parent --reverse "${r673SourceParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r673Following.Count -gt 0) 'r66.6 source admission missing.'
          $r673Commit = [string]$r673Following[0]
          $r673Parents = @(& git -C $root show -s --format=%P $r673Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r673Parents.Count -eq 1 -and [string]$r673Parents[0] -ceq $r673SourceParent) 'r66.6 source admission parent changed.'
          $r673Subject = @(& git -C $root show -s --format=%s $r673Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r673Subject.Count -eq 1 -and [string]$r673Subject[0] -ceq 'ui(buy-redmi-fixes-v1-20260905): admit r66.6 qualified review source') 'r66.6 source admission subject changed.'
          $r673Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r673Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r673Committed | Sort-Object) -join '|') -ceq (@($r673Owners | Sort-Object) -join '|')) 'r66.6 source admission committed an unexpected owner.'
          if ($r675SourceContext) {
            & git -C $root diff --quiet $r673Commit $r673FreezeHead -- @r673Owners
          } else {
            & git -C $root diff --quiet $r673Commit -- @r673Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'r66.6 source coordination changed after admission.'
          $r673Later = @(& git -C $root log --format=%H "${r673Commit}..$r673FreezeHead" -- @r673Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r673Later.Count -eq 0) 'r66.6 source admission cannot be replayed or revised.'
        }
      }
      if ($r675SourceContext) {
        $r675Owners = @($r670Owners[1],$r670Owners[2],$r670Owners[3])
        $r675ManifestHash = '1E6632993A7F0E470785B828EEFC05028CE53D89A79F6E301FE6B0D786254858'
        if ($r676CorrectionContext) {
          $r675Manifest = Get-R66Utf8GitJson $r676CorrectionParent $r675Owners[0] -AsText
        } else {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r675Owners[0])) -ceq $r675ManifestHash) 'r66.7 source manifest changed.'
          $r675Manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r675Owners[0])
        }
        Assert-Coordination ($r675Manifest.Replace("`r`n","`n").StartsWith($r673Manifest.Replace("`r`n","`n").TrimEnd())) 'r66.7 source removed historical manifest evidence.'
        $r675Match = [regex]::Matches($r675Manifest, '(?s)<!-- R675-DATA-BEGIN -->\s*(.*?)\s*<!-- R675-DATA-END -->')
        Assert-Coordination ($r675Match.Count -eq 1) 'r66.7 source data missing or duplicated.'
        $r675Data = $r675Match[0].Groups[1].Value | ConvertFrom-Json
        Assert-Coordination ($r675Data.parent -ceq $r675SourceParent -and $r675Data.implementation.Count -eq 1 -and $r675Data.runtimeDelta.Count -eq 16 -and $r675Data.correctionRuntimeDelta.Count -eq 1) 'r66.7 source boundary changed.'
        Assert-Coordination (($r675Data.implementation.path -join '|') -ceq 'scripts/check-buy-protected-baseline.ps1') 'r66.7 checker owners changed.'
        Assert-Coordination ((Get-Sha256 $r675Data.proposalBinding.path) -ceq $r675Data.proposalBinding.sha256) 'r66.7 source proposal changed.'
        Assert-Coordination ($r675Data.fullRegressionEvidence.cycles -eq 2 -and $r675Data.fullRegressionEvidence.passedPerCycle -eq 1666 -and $r675Data.fullRegressionEvidence.skippedPerCycle -eq 27 -and $r675Data.fullRegressionEvidence.sourceCommit -ceq $r675SourceParent -and (Get-Sha256 $r675Data.fullRegressionEvidence.path) -ceq $r675Data.fullRegressionEvidence.sha256) 'r66.7 full regression evidence changed.'
        Assert-Coordination ($r675Data.sourceBoundaryProposalEvidence.Count -eq 2) 'r66.7 boundary proposal evidence missing.'
        foreach ($evidence in $r675Data.sourceBoundaryProposalEvidence) {
          Assert-Coordination ($evidence.cases -eq 64 -and (Get-Sha256 $evidence.path) -ceq $evidence.sha256) 'r66.7 boundary proposal evidence changed.'
        }
        $r675PolicyBefore = Get-R66Utf8GitJson $r675SourceParent $r670Owners[0]
        $r675PolicyAfter = if ($r676CorrectionContext) { Get-R66Utf8GitJson $r676CorrectionParent $r670Owners[0] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath $policyPath | ConvertFrom-Json }
        Assert-Coordination (($r675PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r675PolicyAfter | ConvertTo-Json -Depth 100 -Compress)) 'r66.7 source changed policy or owner claims.'
        $r675ScopeBefore = Get-R66Utf8GitJson $r675SourceParent $r675Owners[1]
        $r675ScopeAfter = if ($r676CorrectionContext) { Get-R66Utf8GitJson $r676CorrectionParent $r675Owners[1] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r675Owners[1]) | ConvertFrom-Json }
        Assert-Coordination ($r675ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r675ManifestHash) 'r66.7 source scope hash changed.'
        $r675ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 = $r675ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (($r675ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r675ScopeAfter | ConvertTo-Json -Depth 100 -Compress)) 'r66.7 source changed execution authority.'
        foreach ($item in $r675Data.implementation) {
          $allowed = @($item.beforeSha256)
          if ($head -cne $r675SourceParent) { $allowed += $item.proposedSha256 }
          if ($r677SourceContext -and $head -cne $r677SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += 'E5E95B276A8B3C0CEDBD921A43B020450095F633371FF44D52823367AEDD529D'
          }
          if ($r680SourceContext -and $head -cne $r680SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += '0E63D1E4AAD91B84E3DB2F0307269C61828838CD45882A85B24BB1EEEAD23CE1'
          }
          if ($r680SourceContext -and $head -cne $r680SourceParent -and $item.path -ceq 'scripts/check-buy-backend-contract-boundary.ps1') {
            $allowed += 'D91884A35072440F516AB3EA3D817B4C1CA61C1FF6577D9DD3FB9B1016374A5D'
          }
          Assert-Coordination ((Get-Sha256 (Join-Path $root $item.path)) -cin $allowed) 'r66.7 checker differs from exact proposal.'
        }
        if ($head -ceq $r675SourceParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending r66.7 source admission is not a handoff.'
          $r675Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r675Dirty | Sort-Object) -join '|') -ceq (@($r675Owners | Sort-Object) -join '|')) 'Pending r66.7 source must change exactly three coordination owners.'
          $r675Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r675Untracked.Count -eq 0) 'r66.7 source admission cannot include untracked drafts.'
        } else {
          $r675Following = @(& git -C $root rev-list --first-parent --reverse "${r675SourceParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r675Following.Count -gt 0) 'r66.7 source admission missing.'
          $r675Commit = [string]$r675Following[0]
          $r675Parents = @(& git -C $root show -s --format=%P $r675Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r675Parents.Count -eq 1 -and [string]$r675Parents[0] -ceq $r675SourceParent) 'r66.7 source admission parent changed.'
          $r675Subject = @(& git -C $root show -s --format=%s $r675Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r675Subject.Count -eq 1 -and [string]$r675Subject[0] -ceq 'ui(buy-redmi-fixes-v1-20260905): admit r66.7 qualified review source') 'r66.7 source admission subject changed.'
          $r675Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r675Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r675Committed | Sort-Object) -join '|') -ceq (@($r675Owners | Sort-Object) -join '|')) 'r66.7 source admission committed an unexpected owner.'
          if ($r676CorrectionContext) {
            & git -C $root diff --quiet $r675Commit $r675FreezeHead -- @r675Owners
          } else {
            & git -C $root diff --quiet $r675Commit -- @r675Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'r66.7 source coordination changed after admission.'
          $r675Later = @(& git -C $root log --format=%H "${r675Commit}..$r675FreezeHead" -- @r675Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r675Later.Count -eq 0) 'r66.7 source admission cannot be replayed or revised.'
        }
      }
      if ($r676CorrectionContext) {
        $r676Owners = @($r670Owners) + @('config/codex-development-regression-registry.json')
        $r676ManifestHash = '786BE82526D1668098389ECC14849EEA7AABE7A3C3EDAED6D52FDABBAA049EA4'
        if ($r677SourceContext) {
          $r676Manifest = Get-R66Utf8GitJson $r677SourceParent $r676Owners[1] -AsText
        } else {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r676Owners[1])) -ceq $r676ManifestHash) 'Featured return manifest changed.'
          $r676Manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r676Owners[1])
        }
        Assert-Coordination ($r676Manifest.Replace("`r`n","`n").StartsWith($r675Manifest.Replace("`r`n","`n").TrimEnd())) 'Featured return removed historical manifest evidence.'
        $r676Match = [regex]::Matches($r676Manifest, '(?s)<!-- R676-DATA-BEGIN -->\s*(.*?)\s*<!-- R676-DATA-END -->')
        Assert-Coordination ($r676Match.Count -eq 1) 'Featured return data missing or duplicated.'
        $r676Data = $r676Match[0].Groups[1].Value | ConvertFrom-Json
        Assert-Coordination ($r676Data.parent -ceq $r676CorrectionParent -and $r676Data.registryCount -eq 4514 -and $registryEntries.Count -eq 4514 -and $registrySha -ceq $r676Data.registrySha256 -and $r676Data.ticketId -ceq 'R66-UAT-023-R667-FEATURED-RETURN-001') 'Featured return registry generation changed.'
        Assert-Coordination ($r676Data.evidence.Count -eq 3) 'Featured return evidence missing.'
        foreach ($evidence in $r676Data.evidence) { Assert-Coordination ((Get-Sha256 $evidence.path) -ceq $evidence.sha256) 'Featured return device evidence changed.' }
        $r676RegistryBefore = Get-R66Utf8GitJson $r676CorrectionParent $r676Owners[4]
        Assert-Coordination ($r676RegistryBefore.entries.Count -eq 4513 -and $registryEntries[-1].id -ceq 'REG-20260909-4548-CURSOR-R667-FEATURED-RETURN-OFFSET') 'Featured return append boundary changed.'
        $r676RegistryAfter = Get-Content -Raw -Encoding UTF8 -LiteralPath $registryPath | ConvertFrom-Json
        $r676RegistryAfter.entries = @($r676RegistryAfter.entries | Select-Object -First 4513)
        Assert-Coordination (($r676RegistryBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r676RegistryAfter | ConvertTo-Json -Depth 100 -Compress)) 'Featured return changed historical registry.'
        $r676PolicyBefore = Get-R66Utf8GitJson $r676CorrectionParent $r676Owners[0]
        $r676PolicyAfter = if ($r678PersistenceContext) { Get-R66Utf8GitJson $r678PersistenceParent $r676Owners[0] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath $policyPath | ConvertFrom-Json }
        Assert-Coordination ($r676PolicyAfter.registryBinding.entryCount -eq 4514 -and $r676PolicyAfter.registryBinding.sha256 -ceq $registrySha) 'Featured return policy registry changed.'
        $r676PolicyAfter.registryBinding = $r676PolicyBefore.registryBinding
        Assert-Coordination (($r676PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r676PolicyAfter | ConvertTo-Json -Depth 100 -Compress)) 'Featured return changed owner claims or unrelated policy.'
        $r676ScopeBefore = Get-R66Utf8GitJson $r676CorrectionParent $r676Owners[2]
        $r676ScopeAfter = if ($r677SourceContext) { Get-R66Utf8GitJson $r677SourceParent $r676Owners[2] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r676Owners[2]) | ConvertFrom-Json }
        Assert-Coordination ($r676ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r676ManifestHash) 'Featured return scope hash changed.'
        $r676ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 = $r676ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (($r676ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r676ScopeAfter | ConvertTo-Json -Depth 100 -Compress)) 'Featured return changed execution authority.'
        if ($head -ceq $r676CorrectionParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending featured return admission is not a handoff.'
          $r676Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r676Dirty | Sort-Object) -join '|') -ceq (@($r676Owners | Sort-Object) -join '|')) 'Pending featured return must change exactly five coordination owners.'
          $r676Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r676Untracked.Count -eq 0) 'Featured return admission cannot include untracked drafts.'
        } else {
          $r676Following = @(& git -C $root rev-list --first-parent --reverse "${r676CorrectionParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r676Following.Count -gt 0) 'Featured return admission missing.'
          $r676Commit = [string]$r676Following[0]
          $r676Parents = @(& git -C $root show -s --format=%P $r676Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r676Parents.Count -eq 1 -and [string]$r676Parents[0] -ceq $r676CorrectionParent) 'Featured return admission parent changed.'
          $r676Subject = @(& git -C $root show -s --format=%s $r676Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r676Subject.Count -eq 1 -and [string]$r676Subject[0] -ceq 'ui(buy-redmi-fixes-v1-20260905): register featured return continuity child') 'Featured return admission subject changed.'
          $r676Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r676Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r676Committed | Sort-Object) -join '|') -ceq (@($r676Owners | Sort-Object) -join '|')) 'Featured return admission committed an unexpected owner.'
          if ($r677SourceContext) {
            & git -C $root diff --quiet $r676Commit $r676FreezeHead -- @r676Owners
          } else {
            & git -C $root diff --quiet $r676Commit -- @r676Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Featured return coordination changed after admission.'
          $r676Later = @(& git -C $root log --format=%H "${r676Commit}..$r676FreezeHead" -- @r676Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r676Later.Count -eq 0) 'Featured return admission cannot be replayed or revised.'
        }
      }
      if ($r677SourceContext) {
        $r677Owners = @($r670Owners[1],$r670Owners[2],$r670Owners[3])
        $r677ManifestHash = '4A8194DC4C06303455E549D56BA9D6D908522FB52971A266E2C64E44096B75D9'
        if ($r680SourceContext) {
          $r677Manifest = Get-R66Utf8GitJson $r680SourceParent $r677Owners[0] -AsText
        } else {
          Assert-Coordination ((Get-Sha256 (Join-Path $root $r677Owners[0])) -ceq $r677ManifestHash) 'r66.8 source manifest changed.'
          $r677Manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r677Owners[0])
        }
        Assert-Coordination ($r677Manifest.Replace("`r`n","`n").StartsWith($r676Manifest.Replace("`r`n","`n").TrimEnd())) 'r66.8 source removed historical manifest evidence.'
        $r677Match = [regex]::Matches($r677Manifest, '(?s)<!-- R677-DATA-BEGIN -->\s*(.*?)\s*<!-- R677-DATA-END -->')
        Assert-Coordination ($r677Match.Count -eq 1) 'r66.8 source data missing or duplicated.'
        $r677Data = $r677Match[0].Groups[1].Value | ConvertFrom-Json
        Assert-Coordination ($r677Data.parent -ceq $r677SourceParent -and $r677Data.implementation.Count -eq 1 -and $r677Data.runtimeDelta.Count -eq 16 -and $r677Data.correctionRuntimeDelta.Count -eq 1) 'r66.8 source boundary changed.'
        Assert-Coordination (($r677Data.implementation.path -join '|') -ceq 'scripts/check-buy-protected-baseline.ps1') 'r66.8 checker owners changed.'
        Assert-Coordination ((Get-Sha256 $r677Data.proposalBinding.path) -ceq $r677Data.proposalBinding.sha256) 'r66.8 source proposal changed.'
        Assert-Coordination ($r677Data.fullRegressionEvidence.cycles -eq 2 -and $r677Data.fullRegressionEvidence.passedPerCycle -eq 1678 -and $r677Data.fullRegressionEvidence.skippedPerCycle -eq 27 -and $r677Data.fullRegressionEvidence.sourceCommit -ceq $r677SourceParent -and (Get-Sha256 $r677Data.fullRegressionEvidence.path) -ceq $r677Data.fullRegressionEvidence.sha256) 'r66.8 full regression evidence changed.'
        Assert-Coordination ($r677Data.sourceBoundaryProposalEvidence.Count -eq 2) 'r66.8 boundary proposal evidence missing.'
        foreach ($evidence in $r677Data.sourceBoundaryProposalEvidence) {
          Assert-Coordination ($evidence.cases -eq 65 -and (Get-Sha256 $evidence.path) -ceq $evidence.sha256) 'r66.8 boundary proposal evidence changed.'
        }
        $r677PolicyBefore = Get-R66Utf8GitJson $r677SourceParent $r670Owners[0]
        $r677PolicyAfter = if ($r678PersistenceContext) { Get-R66Utf8GitJson $r678PersistenceParent $r670Owners[0] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath $policyPath | ConvertFrom-Json }
        Assert-Coordination (($r677PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r677PolicyAfter | ConvertTo-Json -Depth 100 -Compress)) 'r66.8 source changed policy or owner claims.'
        $r677ScopeBefore = Get-R66Utf8GitJson $r677SourceParent $r677Owners[1]
        $r677ScopeAfter = if ($r680SourceContext) { Get-R66Utf8GitJson $r680SourceParent $r677Owners[1] } else { Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r677Owners[1]) | ConvertFrom-Json }
        Assert-Coordination ($r677ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r677ManifestHash) 'r66.8 source scope hash changed.'
        $r677ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 = $r677ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (($r677ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r677ScopeAfter | ConvertTo-Json -Depth 100 -Compress)) 'r66.8 source changed execution authority.'
        foreach ($item in $r677Data.implementation) {
          $allowed = @($item.beforeSha256)
          if ($head -cne $r677SourceParent) { $allowed += $item.proposedSha256 }
          if ($r680SourceContext -and $head -cne $r680SourceParent -and $item.path -ceq 'scripts/check-buy-protected-baseline.ps1') {
            $allowed += '0E63D1E4AAD91B84E3DB2F0307269C61828838CD45882A85B24BB1EEEAD23CE1'
          }
          if ($r680SourceContext -and $head -cne $r680SourceParent -and $item.path -ceq 'scripts/check-buy-backend-contract-boundary.ps1') {
            $allowed += 'D91884A35072440F516AB3EA3D817B4C1CA61C1FF6577D9DD3FB9B1016374A5D'
          }
          Assert-Coordination ((Get-Sha256 (Join-Path $root $item.path)) -cin $allowed) 'r66.8 checker differs from exact proposal.'
        }
        if ($head -ceq $r677SourceParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending r66.8 source admission is not a handoff.'
          $r677Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r677Dirty | Sort-Object) -join '|') -ceq (@($r677Owners | Sort-Object) -join '|')) 'Pending r66.8 source must change exactly three coordination owners.'
          $r677Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r677Untracked.Count -eq 0) 'r66.8 source admission cannot include untracked drafts.'
        } else {
          $r677Following = @(& git -C $root rev-list --first-parent --reverse "${r677SourceParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r677Following.Count -gt 0) 'r66.8 source admission missing.'
          $r677Commit = [string]$r677Following[0]
          $r677Parents = @(& git -C $root show -s --format=%P $r677Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r677Parents.Count -eq 1 -and [string]$r677Parents[0] -ceq $r677SourceParent) 'r66.8 source admission parent changed.'
          $r677Subject = @(& git -C $root show -s --format=%s $r677Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r677Subject.Count -eq 1 -and [string]$r677Subject[0] -ceq 'ui(buy-redmi-fixes-v1-20260905): admit r66.8 qualified review source') 'r66.8 source admission subject changed.'
          $r677Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r677Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r677Committed | Sort-Object) -join '|') -ceq (@($r677Owners | Sort-Object) -join '|')) 'r66.8 source admission committed an unexpected owner.'
          & git -C $root diff --quiet $r677Commit $r677FreezeHead -- @r677Owners
          Assert-Coordination ($LASTEXITCODE -eq 0) 'r66.8 source coordination changed after admission.'
          $r677Later = @(& git -C $root log --format=%H "${r677Commit}..$r677FreezeHead" -- @r677Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r677Later.Count -eq 0) 'r66.8 source admission cannot be replayed or revised.'
        }
      }
      if ($r678PersistenceContext) {
        # Founder-authorized STORE-PROCUREMENT-ELIGIBILITY-01 admission only.
        # No runtime/test edit, generic dirty allowance or historical rewrite.
        $r678Owners = @('config/codex-subagent-coordination-policy.json',
          'scripts/check-codex-subagent-coordination-policy.ps1')
        $r678SourceOwner = 'apps/mobile/lib/features/buy/buy_v2_saved_products_store.dart'
        $r678Subject = 'ui(buy-redmi-fixes-v1-20260905): admit procurement persistence owner'
        $r678Before = Get-R66Utf8GitJson $r678PersistenceParent $r678Owners[0]
        $r678After = if ($r679DependencyContext) {
          Get-R66Utf8GitJson $r679DependencyParent $r678Owners[0]
        } else { Get-Content -Raw -Encoding UTF8 -LiteralPath $policyPath | ConvertFrom-Json }
        $r678Claim = @($r678After.activeClaims | Where-Object task -ceq '/root/cursor_buy_redmi_fixes_v1_20260905')
        Assert-Coordination ($r678Claim.Count -eq 1 -and $r678Claim[0].owners.Count -eq 67 -and
          @($r678Claim[0].owners | Where-Object { $_ -ceq $r678SourceOwner }).Count -eq 1) 'Procurement admission must add only its persistence owner.'
        $r678Claim[0].owners = @($r678Claim[0].owners | Where-Object { $_ -cne $r678SourceOwner })
        Assert-Coordination (($r678Before | ConvertTo-Json -Depth 100 -Compress) -ceq
          ($r678After | ConvertTo-Json -Depth 100 -Compress)) 'Procurement admission changed unrelated policy or registry binding.'
        if ($head -ceq $r678PersistenceParent) {
          $r678PersistenceAdmissionPending = $true
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending procurement admission is not qualification.'
          $r678CheckpointPath = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/singlechat-r669-paused-preservation-1789053028136.json'
          Assert-Coordination ((Get-Sha256 $r678CheckpointPath) -ceq 'A0F212E311F369C0092C90CD2A249A44D1202996B90D3B120833D625930591E2') 'Paused procurement checkpoint changed.'
          $r678Checkpoint = Get-Content -Raw -Encoding UTF8 -LiteralPath $r678CheckpointPath | ConvertFrom-Json
          Assert-Coordination ($r678Checkpoint.head -ceq $head -and $r678Checkpoint.files.Count -eq 16 -and
            $r678Checkpoint.worktree -ceq $rootForward -and $r678Checkpoint.branch -ceq $branch) 'Paused procurement identity changed.'
          foreach ($draft in $r678Checkpoint.files) {
            Assert-Coordination ((Get-Sha256 (Join-Path $root $draft.path)) -ieq $draft.sha256) "Paused draft changed: $($draft.path)"
          }
          $r678Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r678Dirty | Sort-Object) -join '|') -ceq
            (@(@($r678Owners) + @($r678Checkpoint.files.path) | Sort-Object) -join '|')) 'Procurement admission changed an extra owner.'
          $r678Merge = @(& git -C $root rev-parse --verify --quiet MERGE_HEAD)
          Assert-Coordination ($LASTEXITCODE -eq 1 -and $r678Merge.Count -eq 0) 'Procurement admission cannot run during a merge.'
        } else {
          $r678Following = @(& git -C $root rev-list --first-parent --reverse "${r678PersistenceParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r678Following.Count -gt 0) 'Procurement admission commit missing.'
          $r678Commit = [string]$r678Following[0]
          $r678Parents = @(& git -C $root show -s --format=%P $r678Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r678Parents.Count -eq 1 -and $r678Parents[0] -ceq $r678PersistenceParent) 'Procurement admission parent changed.'
          $r678Text = @(& git -C $root show -s --format=%s $r678Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r678Text.Count -eq 1 -and $r678Text[0] -ceq $r678Subject) 'Procurement admission subject changed.'
          $r678Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r678Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r678Committed | Sort-Object) -join '|') -ceq (@($r678Owners | Sort-Object) -join '|')) 'Procurement admission committed extra owners.'
          if ($r679DependencyContext) {
            & git -C $root diff --quiet $r678Commit $r678FreezeHead -- @r678Owners
          } else {
            & git -C $root diff --quiet $r678Commit -- @r678Owners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Procurement coordination changed after admission.'
          $r678Later = @(& git -C $root log --format=%H "${r678Commit}..$r678FreezeHead" -- @r678Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r678Later.Count -eq 0) 'Procurement admission cannot be reused.'
        }
      }
      if ($r679DependencyContext) {
        $r679Owners = @(
          'config/codex-subagent-coordination-policy.json',
          'scripts/check-codex-subagent-coordination-policy.ps1',
          'docs/quality/cursor-buy-redmi-uat-v1-20260905/UAT.md'
        )
        $r679Subject = 'ui(buy-redmi-fixes-v1-20260905): admit founder-authorized share and address owners'
        $r679Before = Get-R66Utf8GitJson $r679DependencyParent $r679Owners[0]
        $r679After = Get-Content -Raw -Encoding UTF8 -LiteralPath $policyPath | ConvertFrom-Json
        Assert-R679OwnerAdmission $r679Before $r679After
        if ($head -ceq $r679DependencyParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) `
            'Pending Redmi dependency admission is not qualification.'
          $r679Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r679Dirty | Sort-Object) -join '|') -ceq
            (@($r679Owners | Sort-Object) -join '|')) `
            'Redmi dependency admission must contain only its three coordination owners.'
          $r679Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r679Untracked.Count -eq 0) `
            'Redmi dependency admission cannot include untracked files.'
        } else {
          $r679Following = @(& git -C $root rev-list --first-parent --reverse "${r679DependencyParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r679Following.Count -gt 0) `
            'Redmi dependency admission commit is missing.'
          $r679Commit = [string]$r679Following[0]
          $r679Parents = @(& git -C $root show -s --format=%P $r679Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r679Parents.Count -eq 1 -and
            $r679Parents[0] -ceq $r679DependencyParent) 'Redmi dependency admission parent changed.'
          $r679Text = @(& git -C $root show -s --format=%s $r679Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r679Text.Count -eq 1 -and
            $r679Text[0] -ceq $r679Subject) 'Redmi dependency admission subject changed.'
          $r679Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r679Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and
            (@($r679Committed | Sort-Object) -join '|') -ceq
            (@($r679Owners | Sort-Object) -join '|')) 'Redmi dependency admission committed extra owners.'
          $r679FrozenOwners = @($r679Owners[0], $r679Owners[1])
          if ($r680SourceContext) {
            & git -C $root diff --quiet $r679Commit $r679FreezeHead -- @r679FrozenOwners
          } else {
            & git -C $root diff --quiet $r679Commit -- @r679FrozenOwners
          }
          Assert-Coordination ($LASTEXITCODE -eq 0) 'Redmi dependency coordination changed after admission.'
          $r679Later = @(& git -C $root log --format=%H "${r679Commit}..$r679FreezeHead" -- @r679FrozenOwners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r679Later.Count -eq 0) `
            'Redmi dependency admission cannot be replayed or revised.'
        }
      }
      if ($r680SourceContext) {
        $r680Owners = @($r670Owners[1],$r670Owners[2],$r670Owners[3])
        $r680ManifestHash = 'DB60323398209B5C6B3E4007C6D1FE396ABD87EBB7216843A66C99062EE82F2F'
        Assert-Coordination ((Get-Sha256 (Join-Path $root $r680Owners[0])) -ceq $r680ManifestHash) 'r66.9 source manifest changed.'
        $r680Manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r680Owners[0])
        Assert-Coordination ($r680Manifest.Replace("`r`n","`n").StartsWith($r677Manifest.Replace("`r`n","`n").TrimEnd())) 'r66.9 source removed historical manifest evidence.'
        $r680Match = [regex]::Matches($r680Manifest, '(?s)<!-- R680-DATA-BEGIN -->\s*(.*?)\s*<!-- R680-DATA-END -->')
        Assert-Coordination ($r680Match.Count -eq 1) 'r66.9 source data missing or duplicated.'
        $r680Data = $r680Match[0].Groups[1].Value | ConvertFrom-Json
        Assert-Coordination ($r680Data.parent -ceq $r680SourceParent -and $r680Data.implementation.Count -eq 2 -and $r680Data.runtimeDelta.Count -eq 18 -and $r680Data.correctionRuntimeDelta.Count -eq 9) 'r66.9 source boundary changed.'
        Assert-Coordination (($r680Data.implementation.path -join '|') -ceq 'scripts/check-buy-protected-baseline.ps1|scripts/check-buy-backend-contract-boundary.ps1') 'r66.9 checker owners changed.'
        Assert-Coordination ((Get-Sha256 $r680Data.proposalBinding.path) -ceq $r680Data.proposalBinding.sha256) 'r66.9 source proposal changed.'
        Assert-Coordination ($r680Data.fullRegressionEvidence.cycles -eq 2 -and $r680Data.fullRegressionEvidence.passedPerCycle -eq 1882 -and $r680Data.fullRegressionEvidence.skippedPerCycle -eq 11 -and $r680Data.fullRegressionEvidence.suites -eq 51 -and $r680Data.fullRegressionEvidence.sourceCommit -ceq $r680SourceParent -and (Get-Sha256 $r680Data.fullRegressionEvidence.path) -ceq $r680Data.fullRegressionEvidence.sha256) 'r66.9 full regression evidence changed.'
        Assert-Coordination ($r680Data.sourceBoundaryProposalEvidence.Count -eq 2) 'r66.9 boundary proposal evidence missing.'
        foreach ($evidence in $r680Data.sourceBoundaryProposalEvidence) {
          Assert-Coordination ($evidence.cases -eq 68 -and (Get-Sha256 $evidence.path) -ceq $evidence.sha256) 'r66.9 boundary proposal evidence changed.'
        }
        $r680PolicyBefore = Get-R66Utf8GitJson $r680SourceParent $r670Owners[0]
        $r680PolicyAfter = Get-Content -Raw -Encoding UTF8 -LiteralPath $policyPath | ConvertFrom-Json
        Assert-Coordination (($r680PolicyBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r680PolicyAfter | ConvertTo-Json -Depth 100 -Compress)) 'r66.9 source changed policy or owner claims.'
        $r680ScopeBefore = Get-R66Utf8GitJson $r680SourceParent $r680Owners[1]
        $r680ScopeAfter = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $r680Owners[1]) | ConvertFrom-Json
        Assert-Coordination ($r680ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 -ceq $r680ManifestHash) 'r66.9 source scope hash changed.'
        $r680ScopeAfter.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256 = $r680ScopeBefore.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestSha256
        Assert-Coordination (($r680ScopeBefore | ConvertTo-Json -Depth 100 -Compress) -ceq ($r680ScopeAfter | ConvertTo-Json -Depth 100 -Compress)) 'r66.9 source changed execution authority.'
        foreach ($item in $r680Data.implementation) {
          $allowed = @($item.beforeSha256)
          if ($head -cne $r680SourceParent) { $allowed += $item.proposedSha256 }
          Assert-Coordination ((Get-Sha256 (Join-Path $root $item.path)) -cin $allowed) 'r66.9 checker differs from exact proposal.'
        }
        if ($head -ceq $r680SourceParent) {
          Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'Pending r66.9 source admission is not a handoff.'
          $r680Dirty = @(& git -C $root diff HEAD --name-only)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r680Dirty | Sort-Object) -join '|') -ceq (@($r680Owners | Sort-Object) -join '|')) 'Pending r66.9 source must change exactly three coordination owners.'
          $r680Untracked = @(& git -C $root ls-files --others --exclude-standard)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r680Untracked.Count -eq 0) 'r66.9 source admission cannot include untracked drafts.'
        } else {
          $r680Following = @(& git -C $root rev-list --first-parent --reverse "${r680SourceParent}..$head")
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r680Following.Count -gt 0) 'r66.9 source admission missing.'
          $r680Commit = [string]$r680Following[0]
          $r680Parents = @(& git -C $root show -s --format=%P $r680Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r680Parents.Count -eq 1 -and [string]$r680Parents[0] -ceq $r680SourceParent) 'r66.9 source admission parent changed.'
          $r680Subject = @(& git -C $root show -s --format=%s $r680Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r680Subject.Count -eq 1 -and [string]$r680Subject[0] -ceq 'ui(buy-redmi-fixes-v1-20260905): admit r66.9 qualified review source') 'r66.9 source admission subject changed.'
          $r680Committed = @(& git -C $root diff-tree --no-commit-id --name-only -r $r680Commit)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and (@($r680Committed | Sort-Object) -join '|') -ceq (@($r680Owners | Sort-Object) -join '|')) 'r66.9 source admission committed an unexpected owner.'
          & git -C $root diff --quiet $r680Commit -- @r680Owners
          Assert-Coordination ($LASTEXITCODE -eq 0) 'r66.9 source coordination changed after admission.'
          $r680Later = @(& git -C $root log --format=%H "${r680Commit}..$head" -- @r680Owners)
          Assert-Coordination ($LASTEXITCODE -eq 0 -and $r680Later.Count -eq 0) 'r66.9 source admission cannot be replayed or revised.'
        }
      }
      $primaryEvidenceCoordinationOwnerKeys = @($r66CoordinationOwners | ForEach-Object {
        $_.ToLowerInvariant()
      })
    }
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
          $r65FourEvidenceSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit r65.4 review evidence owners'
          $matchingR65FourEvidenceCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.4 evidence coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $r65FourEvidenceSubject) {
              $matchingR65FourEvidenceCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingR65FourEvidenceCommits.Count -le 1) `
            'r65.4 evidence coordination commit is duplicated.'
          if ($matchingR65FourEvidenceCommits.Count -eq 1) {
            $r65FourEvidenceCommit =
              [string]$matchingR65FourEvidenceCommits[0]
            $r65FourEvidenceParent = @(& git -C $root show -s --format=%P `
                $r65FourEvidenceCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingScannerTestCommits.Count -eq 1 -and
              $r65FourEvidenceParent.Count -eq 1 -and
              [string]$r65FourEvidenceParent[0] -ceq $scannerTestCommit
            ) 'r65.4 evidence coordination parent changed.'
            $r65FourEvidenceOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $r65FourEvidenceCommit)
            $expectedR65FourEvidenceOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r65FourEvidenceOwners | Sort-Object) -join '|') -ceq
              (@($expectedR65FourEvidenceOwners | Sort-Object) -join '|')
            ) 'r65.4 evidence coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $r65FourEvidenceCommit
          }
          $r65FourSlotSubject =
            'ui(buy-mvp-ticket14-v1-20260902): permit predeclared r65.4 evidence slots'
          $matchingR65FourSlotCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.4 evidence-slot coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $r65FourSlotSubject) {
              $matchingR65FourSlotCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingR65FourSlotCommits.Count -le 1) `
            'r65.4 evidence-slot coordination commit is duplicated.'
          if ($matchingR65FourSlotCommits.Count -eq 1) {
            $r65FourSlotCommit = [string]$matchingR65FourSlotCommits[0]
            $r65FourSlotParent = @(& git -C $root show -s --format=%P `
                $r65FourSlotCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingR65FourEvidenceCommits.Count -eq 1 -and
              $r65FourSlotParent.Count -eq 1 -and
              [string]$r65FourSlotParent[0] -ceq $r65FourEvidenceCommit
            ) 'r65.4 evidence-slot coordination parent changed.'
            $r65FourSlotOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $r65FourSlotCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $r65FourSlotOwners.Count -eq 1 -and
              [string]$r65FourSlotOwners[0] -ceq
                'scripts/check-codex-subagent-coordination-policy.ps1'
            ) 'r65.4 evidence-slot coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $r65FourSlotCommit
          }
          $goldenFailureEvidenceSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit retained golden failure evidence'
          $matchingGoldenFailureEvidenceCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'golden-failure evidence subject read failed.'
            if ([string]$candidateSubject[0] -ceq
                $goldenFailureEvidenceSubject) {
              $matchingGoldenFailureEvidenceCommits +=
                [string]$candidateCommit
            }
          }
          Assert-Coordination (
            $matchingGoldenFailureEvidenceCommits.Count -le 1
          ) 'golden-failure evidence coordination commit is duplicated.'
          if ($matchingGoldenFailureEvidenceCommits.Count -eq 1) {
            $goldenFailureEvidenceCommit =
              [string]$matchingGoldenFailureEvidenceCommits[0]
            $goldenFailureEvidenceParent = @(& git -C $root show -s `
                --format=%P $goldenFailureEvidenceCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingR65FourSlotCommits.Count -eq 1 -and
              $goldenFailureEvidenceParent.Count -eq 1 -and
              [string]$goldenFailureEvidenceParent[0] -ceq
                $r65FourSlotCommit
            ) 'golden-failure evidence coordination parent changed.'
            $goldenFailureEvidenceOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $goldenFailureEvidenceCommit)
            $expectedGoldenFailureEvidenceOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($goldenFailureEvidenceOwners | Sort-Object) -join '|') -ceq
              (@($expectedGoldenFailureEvidenceOwners | Sort-Object) -join '|')
            ) 'golden-failure evidence coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $goldenFailureEvidenceCommit
          }
          $r65FiveEvidenceSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit r65.5 review evidence owners'
          $matchingR65FiveEvidenceCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.5 evidence coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $r65FiveEvidenceSubject) {
              $matchingR65FiveEvidenceCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingR65FiveEvidenceCommits.Count -le 1) `
            'r65.5 evidence coordination commit is duplicated.'
          if ($matchingR65FiveEvidenceCommits.Count -eq 1) {
            $r65FiveEvidenceCommit =
              [string]$matchingR65FiveEvidenceCommits[0]
            $r65FiveEvidenceParent = @(& git -C $root show -s --format=%P `
                $r65FiveEvidenceCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingGoldenFailureEvidenceCommits.Count -eq 1 -and
              $r65FiveEvidenceParent.Count -eq 1 -and
              [string]$r65FiveEvidenceParent[0] -ceq
                $goldenFailureEvidenceCommit
            ) 'r65.5 evidence coordination parent changed.'
            $r65FiveEvidenceOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $r65FiveEvidenceCommit)
            $expectedR65FiveEvidenceOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r65FiveEvidenceOwners | Sort-Object) -join '|') -ceq
              (@($expectedR65FiveEvidenceOwners | Sort-Object) -join '|')
            ) 'r65.5 evidence coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $r65FiveEvidenceCommit
          }
          $r65SixEvidenceSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit r65.6 review evidence owners'
          $matchingR65SixEvidenceCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.6 evidence coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $r65SixEvidenceSubject) {
              $matchingR65SixEvidenceCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingR65SixEvidenceCommits.Count -le 1) `
            'r65.6 evidence coordination commit is duplicated.'
          if ($matchingR65SixEvidenceCommits.Count -eq 1) {
            $r65SixEvidenceCommit =
              [string]$matchingR65SixEvidenceCommits[0]
            $r65SixEvidenceParent = @(& git -C $root show -s --format=%P `
                $r65SixEvidenceCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingR65FiveEvidenceCommits.Count -eq 1 -and
              $r65SixEvidenceParent.Count -eq 1 -and
              [string]$r65SixEvidenceParent[0] -ceq $r65FiveEvidenceCommit
            ) 'r65.6 evidence coordination parent changed.'
            $r65SixEvidenceOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $r65SixEvidenceCommit)
            $expectedR65SixEvidenceOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r65SixEvidenceOwners | Sort-Object) -join '|') -ceq
              (@($expectedR65SixEvidenceOwners | Sort-Object) -join '|')
            ) 'r65.6 evidence coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $r65SixEvidenceCommit
          }
          $r65SevenEvidenceSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit r65.7 review evidence owners'
          $matchingR65SevenEvidenceCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.7 evidence coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $r65SevenEvidenceSubject) {
              $matchingR65SevenEvidenceCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingR65SevenEvidenceCommits.Count -le 1) `
            'r65.7 evidence coordination commit is duplicated.'
          if ($matchingR65SevenEvidenceCommits.Count -eq 1) {
            $r65SevenEvidenceCommit =
              [string]$matchingR65SevenEvidenceCommits[0]
            $r65SevenEvidenceParent = @(& git -C $root show -s --format=%P `
                $r65SevenEvidenceCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingR65SixEvidenceCommits.Count -eq 1 -and
              $r65SevenEvidenceParent.Count -eq 1 -and
              [string]$r65SevenEvidenceParent[0] -ceq $r65SixEvidenceCommit
            ) 'r65.7 evidence coordination parent changed.'
            $r65SevenEvidenceOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $r65SevenEvidenceCommit)
            $expectedR65SevenEvidenceOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r65SevenEvidenceOwners | Sort-Object) -join '|') -ceq
              (@($expectedR65SevenEvidenceOwners | Sort-Object) -join '|')
            ) 'r65.7 evidence coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $r65SevenEvidenceCommit
          }
          $r65EightEvidenceSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit r65.8 review evidence owners'
          $matchingR65EightEvidenceCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.8 evidence coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $r65EightEvidenceSubject) {
              $matchingR65EightEvidenceCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingR65EightEvidenceCommits.Count -le 1) `
            'r65.8 evidence coordination commit is duplicated.'
          if ($matchingR65EightEvidenceCommits.Count -eq 1) {
            $r65EightEvidenceCommit =
              [string]$matchingR65EightEvidenceCommits[0]
            $r65EightEvidenceParent = @(& git -C $root show -s --format=%P `
                $r65EightEvidenceCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingR65SevenEvidenceCommits.Count -eq 1 -and
              $r65EightEvidenceParent.Count -eq 1 -and
              [string]$r65EightEvidenceParent[0] -ceq $r65SevenEvidenceCommit
            ) 'r65.8 evidence coordination parent changed.'
            $r65EightEvidenceOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $r65EightEvidenceCommit)
            $expectedR65EightEvidenceOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r65EightEvidenceOwners | Sort-Object) -join '|') -ceq
              (@($expectedR65EightEvidenceOwners | Sort-Object) -join '|')
            ) 'r65.8 evidence coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $r65EightEvidenceCommit
          }
          $r65NineEvidenceSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit r65.9 review evidence owners'
          $matchingR65NineEvidenceCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.9 evidence coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $r65NineEvidenceSubject) {
              $matchingR65NineEvidenceCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingR65NineEvidenceCommits.Count -le 1) `
            'r65.9 evidence coordination commit is duplicated.'
          if ($matchingR65NineEvidenceCommits.Count -eq 1) {
            $r65NineEvidenceCommit =
              [string]$matchingR65NineEvidenceCommits[0]
            $r65NineEvidenceParent = @(& git -C $root show -s --format=%P `
                $r65NineEvidenceCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingR65EightEvidenceCommits.Count -eq 1 -and
              $r65NineEvidenceParent.Count -eq 1 -and
              [string]$r65NineEvidenceParent[0] -ceq $r65EightEvidenceCommit
            ) 'r65.9 evidence coordination parent changed.'
            $r65NineEvidenceOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $r65NineEvidenceCommit)
            $expectedR65NineEvidenceOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r65NineEvidenceOwners | Sort-Object) -join '|') -ceq
              (@($expectedR65NineEvidenceOwners | Sort-Object) -join '|')
            ) 'r65.9 evidence coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $r65NineEvidenceCommit
          }
          $r65TenEvidenceSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit r65.10 review evidence owners'
          $matchingR65TenEvidenceCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.10 evidence coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $r65TenEvidenceSubject) {
              $matchingR65TenEvidenceCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination ($matchingR65TenEvidenceCommits.Count -le 1) `
            'r65.10 evidence coordination commit is duplicated.'
          if ($matchingR65TenEvidenceCommits.Count -eq 1) {
            $r65TenEvidenceCommit = [string]$matchingR65TenEvidenceCommits[0]
            $r65TenEvidenceParent = @(& git -C $root show -s --format=%P `
                $r65TenEvidenceCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingR65NineEvidenceCommits.Count -eq 1 -and
              $r65TenEvidenceParent.Count -eq 1 -and
              [string]$r65TenEvidenceParent[0] -ceq $r65NineEvidenceCommit
            ) 'r65.10 evidence coordination parent changed.'
            $r65TenEvidenceOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $r65TenEvidenceCommit)
            $expectedR65TenEvidenceOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r65TenEvidenceOwners | Sort-Object) -join '|') -ceq
              (@($expectedR65TenEvidenceOwners | Sort-Object) -join '|')
            ) 'r65.10 evidence coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $r65TenEvidenceCommit
          }
          $r65ElevenEvidenceSubject =
            'ui(buy-mvp-ticket14-v1-20260902): admit r65.11 review evidence owners'
          $matchingR65ElevenEvidenceCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.11 evidence coordination subject read failed.'
            if ([string]$candidateSubject[0] -ceq $r65ElevenEvidenceSubject) {
              $matchingR65ElevenEvidenceCommits += [string]$candidateCommit
            }
          }
          Assert-Coordination (
            $matchingR65ElevenEvidenceCommits.Count -le 1
          ) 'r65.11 evidence coordination commit is duplicated.'
          if ($matchingR65ElevenEvidenceCommits.Count -eq 1) {
            $r65ElevenEvidenceCommit =
              [string]$matchingR65ElevenEvidenceCommits[0]
            $r65ElevenExpectedParent =
              '600dba97be8027de95e0ccbb89471f27aeb97529'
            $r65ElevenEvidenceParent = @(& git -C $root show -s --format=%P `
                $r65ElevenEvidenceCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $r65ElevenEvidenceParent.Count -eq 1 -and
              [string]$r65ElevenEvidenceParent[0] -ceq
                $r65ElevenExpectedParent
            ) 'r65.11 evidence coordination parent changed.'
            $r65ElevenEvidenceOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r $r65ElevenEvidenceCommit)
            $expectedR65ElevenEvidenceOwners = @(
              'config/codex-subagent-coordination-policy.json',
              'scripts/check-codex-subagent-coordination-policy.ps1'
            )
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              (@($r65ElevenEvidenceOwners | Sort-Object) -join '|') -ceq
              (@($expectedR65ElevenEvidenceOwners | Sort-Object) -join '|')
            ) 'r65.11 evidence coordination changed an unexpected owner.'
            $sealedCoordinationCommit = $r65ElevenEvidenceCommit
          }
          $r65ElevenParentCorrectionSubject =
            'ui(buy-mvp-ticket14-v1-20260902): correct r65.11 parent binding'
          $matchingR65ElevenParentCorrectionCommits = @()
          foreach ($candidateCommit in $continuationFeatureCommits) {
            $candidateSubject = @(& git -C $root show -s --format=%s `
                $candidateCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and $candidateSubject.Count -eq 1
            ) 'r65.11 parent-correction subject read failed.'
            if ([string]$candidateSubject[0] -ceq
                $r65ElevenParentCorrectionSubject) {
              $matchingR65ElevenParentCorrectionCommits +=
                [string]$candidateCommit
            }
          }
          Assert-Coordination (
            $matchingR65ElevenParentCorrectionCommits.Count -le 1
          ) 'r65.11 parent-correction commit is duplicated.'
          if ($matchingR65ElevenParentCorrectionCommits.Count -eq 1) {
            $r65ElevenParentCorrectionCommit =
              [string]$matchingR65ElevenParentCorrectionCommits[0]
            $r65ElevenParentCorrectionParent = @(& git -C $root show -s `
                --format=%P $r65ElevenParentCorrectionCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $matchingR65ElevenEvidenceCommits.Count -eq 1 -and
              $r65ElevenParentCorrectionParent.Count -eq 1 -and
              [string]$r65ElevenParentCorrectionParent[0] -ceq
                $r65ElevenEvidenceCommit
            ) 'r65.11 parent-correction parent changed.'
            $r65ElevenParentCorrectionOwners = @(& git -C $root diff-tree `
                --no-commit-id --name-only -r `
                $r65ElevenParentCorrectionCommit)
            Assert-Coordination (
              $LASTEXITCODE -eq 0 -and
              $r65ElevenParentCorrectionOwners.Count -eq 1 -and
              [string]$r65ElevenParentCorrectionOwners[0] -ceq
                'scripts/check-codex-subagent-coordination-policy.ps1'
            ) 'r65.11 parent-correction changed an unexpected owner.'
            $sealedCoordinationCommit = $r65ElevenParentCorrectionCommit
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
      if ($ProductionLane -cne 'codex_ui') {
        foreach ($bootstrapOwner in $expectedBootstrapOwners) {
          Assert-Coordination (
            $ownerToTask.ContainsKey($bootstrapOwner.ToLowerInvariant())
          ) "continuation bootstrap owner is unclaimed: $bootstrapOwner"
        }
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
    if ($r66OwnerAmendmentPending) {
      Assert-Coordination (
        (@($preCommitStagedOwners | Sort-Object) -join '|') -ceq
        (@($r66CoordinationOwners | Sort-Object) -join '|') -and
        (@($preCommitUnstagedOwners | Sort-Object) -join '|') -ceq
        (@($r66PreservedDrafts.Keys | Sort-Object) -join '|')
      ) 'R66 coordination must stage only four owners and leave all seven drafts unstaged.'
    }
    if ($r665CollectionAdmissionPending) {
      Assert-Coordination (
        (@($preCommitStagedOwners | Sort-Object) -join '|') -ceq
        (@($r665Owners | Sort-Object) -join '|') -and
        (@($preCommitUnstagedOwners | Sort-Object) -join '|') -ceq
        (@($r665Drafts.Keys | Sort-Object) -join '|')
      ) 'Collection admission must stage only five owners and preserve all four unstaged drafts.'
    }
    if ($r678PersistenceAdmissionPending) {
      Assert-Coordination (
        (@($preCommitStagedOwners | Sort-Object) -join '|') -ceq (@($r678Owners | Sort-Object) -join '|') -and
        (@($preCommitUnstagedOwners | Sort-Object) -join '|') -ceq (@($r678Checkpoint.files.path | Sort-Object) -join '|')
      ) 'Procurement admission must stage only its two controls and preserve all 16 unstaged drafts.'
    }
    Assert-Coordination (
      $preCommitStagedOwners.Count -gt 0 -and
      ($preCommitUnstagedOwners.Count -eq 0 -or $r66OwnerAmendmentPending -or $r665CollectionAdmissionPending -or $r678PersistenceAdmissionPending) -and
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
          $singleUseEvidenceOwners = @(
            'config/codex-development-regression-registry.json',
            'config/codex-subagent-coordination-policy.json',
            'scripts/check-codex-subagent-coordination-policy.ps1',
            'scripts/run-store-buy-diagnostic-evidence.ps1'
          )
          $singleUseDiagnosticEvidenceOwners = @(
            'config/codex-development-regression-registry.json',
            'config/codex-subagent-coordination-policy.json',
            'docs/quality/store-buy-diagnostic-evidence-v2-20260904/serialized-repair-expanded-attempt1.result.json',
            'docs/quality/store-buy-diagnostic-evidence-v2-20260904/serialized-repair-expanded-attempt1.stderr.log',
            'docs/quality/store-buy-diagnostic-evidence-v2-20260904/serialized-repair-expanded-attempt1.stdout.log',
            'docs/quality/store-buy-diagnostic-evidence-v2-20260904/toolchain-and-dependency-hashes.json',
            'scripts/check-codex-subagent-coordination-policy.ps1',
            'scripts/run-store-buy-diagnostic-evidence.ps1'
          )
          $singleUseEvidenceCorrection = (
            [string]$selectedContinuationBinding.id -ceq
              'integration_repair_store_buy_diagnostic_evidence_v2_20260904' -and
            $branch -ceq
              'work/integration-repair/store-buy-diagnostic-evidence-v2-20260904' -and
            $head -ceq 'e1f5d6f060b9466c9efebec51d1b4e5b6c9932ea' -and
            $AgentTask -ceq
              '/root/repair_store_buy_diagnostic_evidence_v2_20260904' -and
            $ProductionWorkId -ceq
              'store-buy-diagnostic-evidence-v2-20260904' -and
            $ProductionTicketId -ceq
              'UAW-INTEGRATION-REPAIR-STORE-BUY-DIAGNOSTIC-EVIDENCE-V2-20260904' -and
            [string]$selectedContinuationBinding.baselineHead -ceq
              'c48e4ecc5c3ccc7a3079d3f64988437599cc78de' -and
            $existingCoordinationCommits.Count -eq 0 -and
            $existingRepairMerges.Count -eq 0
          )
          $singleUseDiagnosticEvidenceCapture = (
            [string]$selectedContinuationBinding.id -ceq
              'integration_repair_store_buy_diagnostic_evidence_v2_20260904' -and
            $branch -ceq
              'work/integration-repair/store-buy-diagnostic-evidence-v2-20260904' -and
            $head -ceq 'd9d8fa3fe43c75330a834a598f691aeab52f88ac' -and
            $AgentTask -ceq
              '/root/repair_store_buy_diagnostic_evidence_v2_20260904' -and
            $ProductionWorkId -ceq
              'store-buy-diagnostic-evidence-v2-20260904' -and
            $ProductionTicketId -ceq
              'UAW-INTEGRATION-REPAIR-STORE-BUY-DIAGNOSTIC-EVIDENCE-V2-20260904' -and
            [string]$selectedContinuationBinding.baselineHead -ceq
              'c48e4ecc5c3ccc7a3079d3f64988437599cc78de' -and
            $existingCoordinationCommits.Count -eq 1 -and
            $existingRepairMerges.Count -eq 0 -and
            -not $repairMergeActive
          )
          if ($singleUseDiagnosticEvidenceCapture) {
            $bootstrapParentOutput = @(& git -C $root show -s --format='%P' `
                'e1f5d6f060b9466c9efebec51d1b4e5b6c9932ea')
            $bootstrapParentExit = $LASTEXITCODE
            $bootstrapSubjectOutput = @(& git -C $root show -s --format='%s' `
                'e1f5d6f060b9466c9efebec51d1b4e5b6c9932ea')
            $bootstrapSubjectExit = $LASTEXITCODE
            $bootstrapOwnerOutput = @(& git -C $root diff-tree --no-commit-id `
                --name-only -r 'e1f5d6f060b9466c9efebec51d1b4e5b6c9932ea')
            $bootstrapOwnerExit = $LASTEXITCODE
            $correctionParentOutput = @(& git -C $root show -s --format='%P' `
                'd9d8fa3fe43c75330a834a598f691aeab52f88ac')
            $correctionParentExit = $LASTEXITCODE
            $correctionSubjectOutput = @(& git -C $root show -s --format='%s' `
                'd9d8fa3fe43c75330a834a598f691aeab52f88ac')
            $correctionSubjectExit = $LASTEXITCODE
            $correctionOwnerOutput = @(& git -C $root diff-tree --no-commit-id `
                --name-only -r 'd9d8fa3fe43c75330a834a598f691aeab52f88ac')
            $correctionOwnerExit = $LASTEXITCODE
            Assert-Coordination (
              $bootstrapParentExit -eq 0 -and
              $bootstrapSubjectExit -eq 0 -and
              $bootstrapOwnerExit -eq 0 -and
              $correctionParentExit -eq 0 -and
              $correctionSubjectExit -eq 0 -and
              $correctionOwnerExit -eq 0 -and
              $bootstrapParentOutput.Count -eq 1 -and
              [string]$bootstrapParentOutput[0] -ceq
                'c48e4ecc5c3ccc7a3079d3f64988437599cc78de' -and
              $bootstrapSubjectOutput.Count -eq 1 -and
              [string]$bootstrapSubjectOutput[0] -ceq
                'coordination(store-buy-diagnostic-evidence-v2-20260904): bind serialized regression evidence' -and
              (@($bootstrapOwnerOutput | Sort-Object) -join '|') -ceq
                (@($selectedContinuationBinding.bootstrapOwners | Sort-Object) -join '|') -and
              $correctionParentOutput.Count -eq 1 -and
              [string]$correctionParentOutput[0] -ceq
                'e1f5d6f060b9466c9efebec51d1b4e5b6c9932ea' -and
              $correctionSubjectOutput.Count -eq 1 -and
              [string]$correctionSubjectOutput[0] -ceq
                'repair(store-buy-diagnostic-evidence-v2-20260904): correct serialized evidence path' -and
              (@($correctionOwnerOutput | Sort-Object) -join '|') -ceq
                (@($singleUseEvidenceOwners | Sort-Object) -join '|')
            ) 'single-use v2 evidence lineage changed.'
            Assert-Coordination (
              (@($preCommitStagedOwners | Sort-Object) -join '|') -ceq
                (@($singleUseDiagnosticEvidenceOwners | Sort-Object) -join '|')
            ) 'single-use v2 diagnostic evidence owner set changed.'
          } elseif ($singleUseEvidenceCorrection) {
            Assert-Coordination (
              (@($preCommitStagedOwners | Sort-Object) -join '|') -ceq
                (@($singleUseEvidenceOwners | Sort-Object) -join '|')
            ) 'single-use v2 evidence correction owner set changed.'
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
        ([string]$subjectOutput[0] -cmatch $subjectPattern -or
          (Test-R66HistoricalCommitSubject $featureCommit ([string]$subjectOutput[0])))
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
    Assert-Coordination ($ProductionLane -cin @('cursor_ui','codex_ui')) `
      'founder UI acceptance phase is valid only for a UI lane.'
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
          'work/integration-repair/store-buy-conflict-repair-v3-20260904') {
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
