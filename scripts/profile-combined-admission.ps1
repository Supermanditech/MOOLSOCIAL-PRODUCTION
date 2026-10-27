# Exact founder-authorised COMBINED admission. This file grants no deployment,
# provisioning, APK, backend-branch publication or feature-commit authority.
function Get-ProfileCombinedBinding {
  [ordered]@{
    id='profile_combined_20261027'; state='founder_authorized_2026_10_27'
    lane='codex_backend'; role='primary'; task='/root/codex_backend_profile_combined'
    workId='profile-combined-20261027'; ticketId='PROFILE-INTEGRATION-01'
    worktreePath='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-profile-combined-20261027'
    branch='work/codex-backend/profile-combined-20261027'
    baselineHead='c9d03bb37b6115f7fe63f3f1dd819892dc037fc9'
    bootstrapCommitSubject='coordination(profile-combined-20261027): record exact combined admission'
    bootstrapOwners=@(
      '.gitattributes',
      'scripts/check-codex-subagent-coordination-policy.ps1',
      'scripts/profile-combined-admission.ps1',
      'scripts/test-profile-combined-admission.ps1',
      'config/codex-subagent-coordination-policy.json',
      'config/cross-agent-incremental-ticket-gate.json',
      'docs/quality/PROFILE-INTEGRATION-01-20261027.json',
      'docs/quality/PROFILE-INTEGRATION-01-ACCEPTANCE-20261027.json',
      'docs/quality/PROFILE-INTEGRATION-01-CONTRACT-20261027.md'
    )
  }
}
function Test-ProfileCombinedIdentity([hashtable]$Facts) {
  $binding=Get-ProfileCombinedBinding
  foreach($pair in @(@('Root','worktreePath'),@('Branch','branch'),@('Lane','lane'),
      @('WorkId','workId'),@('Ticket','ticketId'),@('Role','role'))) {
    if(!$Facts.ContainsKey($pair[0]) -or $Facts[$pair[0]] -isnot [string] -or
       $Facts[$pair[0]] -cne $binding[$pair[1]]) { return $false }
  }
  if(!$Facts.ContainsKey('Phase') -or $Facts.Phase -isnot [string] -or $Facts.Phase -cnotin
      @('coordination_bootstrap','task_start','implementation','pre_commit')) {return $false}
  $task=if($Facts.Phase -ceq 'coordination_bootstrap'){'/root'}else{$binding.task}
  return $Facts.ContainsKey('Task') -and $Facts.Task -is [string] -and $Facts.Task -ceq $task
}
function Get-ProfileCombinedRuntimeOwners {
  @(
    'apps/mobile/lib/features/buy/buy_v2_session.dart',
    'apps/mobile/lib/features/journey01/account_profile_gateway.dart',
    'apps/mobile/lib/features/journey01/journey_router.dart',
    'apps/mobile/lib/features/journey01/journey_session.dart',
    'apps/mobile/lib/features/journey01/review_journey_services.dart',
    'apps/mobile/lib/features/work/screens/work_onboarding_screens.dart',
    'apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart',
    'apps/mobile/lib/features/work/work_services.dart',
    'apps/mobile/lib/features/work/work_session.dart',
    'apps/mobile/lib/ui_v2/buy/buy_v2_views.dart',
    'apps/mobile/lib/ui_v2/profile/global_personal_profile_v2.dart',
    'apps/mobile/test/account_profile_gateway_test.dart',
    'apps/mobile/test/journey_session_test.dart',
    'apps/mobile/test/work_production_gateway_test.dart',
    'apps/mobile/test/work_workspace_layout_safety_test.dart',
    'backend/functions/src/account/profile_dataconnect_store.test.ts',
    'backend/functions/src/account/profile_dataconnect_store.ts',
    'backend/functions/src/account/profile_http.test.ts',
    'backend/functions/src/account/profile_http.ts',
    'backend/functions/src/account/profile_service.test.ts',
    'backend/functions/src/account/profile_service.ts',
    'backend/functions/src/index.ts',
    'backend/functions/src/workspace/workspace_profile_service.test.ts',
    'backend/functions/src/workspace/workspace_profile_service.ts',
    'dataconnect/mobile/universal.gql',
    'dataconnect/provider/youtube.gql',
    'dataconnect/schema/universal.gql'
  )
}
function Assert-ProfileCombinedOwners([string[]]$Actual,[string[]]$Allowed) {
  foreach($owner in $Actual) {
    Assert-Coordination ($owner -cin $Allowed) "COMBINED changed an unclaimed owner: $owner"
  }
}
function Invoke-ProfileCombinedAdmission {
  $binding=Get-ProfileCombinedBinding
  $branch=@(Get-OctoberCompatibilityGitLines @('branch','--show-current'))[0]
  Assert-Coordination (Test-ProfileCombinedIdentity @{
    Root=$root.Replace('\','/'); Branch=$branch; Lane=$ProductionLane
    WorkId=$ProductionWorkId; Ticket=$ProductionTicketId; Role=$AgentRole
    Task=$AgentTask; Phase=$ProductionPhase
  }) 'COMBINED requires its exact founder-approved backend identity and permitted phase.'
  $base=$binding.baselineHead
  $recordOwner='docs/quality/PROFILE-INTEGRATION-01-20261027.json'
  $record=Get-Content -Raw -LiteralPath (Join-Path $root $recordOwner)|ConvertFrom-Json
  $metadata=@($binding.bootstrapOwners)
  Assert-Coordination ((@($record.backendAdmission.runtimeOwners|Sort-Object)-join '|') -ceq
    (@(Get-ProfileCombinedRuntimeOwners|Sort-Object)-join '|')) 'COMBINED runtime admission exceeds exact source/test owners.'
  $owners=@($metadata)+@($record.backendAdmission.runtimeOwners)
  Assert-Coordination ($owners.Count -eq (@($owners|Sort-Object -Unique)).Count) 'COMBINED duplicate owner.'
  foreach($owner in $owners){Assert-Coordination ((Get-CanonicalOwner $owner) -ceq $owner) 'COMBINED noncanonical owner.'}
  $contract='docs/quality/PROFILE-INTEGRATION-01-CONTRACT-20261027.md'
  $acceptance='docs/quality/PROFILE-INTEGRATION-01-ACCEPTANCE-20261027.json'
  $expectedContract='41A13A42DEDB2BD7CEE8D116A0D81AE94CC8BE5FF70A44C88D8EDA23EECA5D14'
  Assert-Coordination ((Get-Sha256 (Join-Path $root $contract)) -ceq $expectedContract) 'COMBINED accepted contract changed.'
  $baseAttributes=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:.gitattributes"))-join "`n").TrimEnd()
  $attributes=[IO.File]::ReadAllText((Join-Path $root '.gitattributes')).Replace("`r`n","`n").TrimEnd()
  Assert-Coordination ($attributes -ceq ($baseAttributes+"`n`n# Preserve the exact founder-approved COMBINED interaction contract across checkouts.`ndocs/quality/PROFILE-INTEGRATION-01-CONTRACT-20261027.md text eol=lf")) 'COMBINED attributes change exceeds its exact contract line-ending pin.'
  $approval=Get-Content -Raw -LiteralPath (Join-Path $root $acceptance)|ConvertFrom-Json
  Assert-Coordination ($approval.acceptedUiCommit -ceq $base -and
    $approval.uiContractPath -ceq $contract -and $approval.uiContractSha256 -ceq $expectedContract -and
    $approval.founderDecision -ceq 'accepted_for_profile_combined_source_qualification_only' -and
    $approval.founderAnswer -ceq 'Approve exact combined contract and one metadata admission commit' -and
    $approval.backendBranchPush -eq $false -and $approval.deployment -eq $false -and
    $approval.productionAcceptance -eq $false) 'COMBINED approval exceeds exact baseline/Git amendment.'
  $livePolicy=Get-Content -Raw -LiteralPath (Join-Path $root 'config/codex-subagent-coordination-policy.json')|ConvertFrom-Json
  $basePolicy=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/codex-subagent-coordination-policy.json"))-join "`n")|ConvertFrom-Json
  $expectedPolicy=($basePolicy|ConvertTo-Json -Depth 100)|ConvertFrom-Json
  # Transfer only the exact COMBINED owners from inactive frontend claims. All
  # unrelated claims, historical continuation bodies and policy rules survive.
  foreach($claim in @($expectedPolicy.activeClaims)) {
    $claim.owners=@($claim.owners|Where-Object {$_ -cnotin $owners})
  }
  $expectedPolicy.activeClaims=@($expectedPolicy.activeClaims)+@([pscustomobject]@{
    task=$binding.task; role='primary'; owners=$owners})
  $expectedPolicy.productionGitDiscipline.continuationBindings=
    @($expectedPolicy.productionGitDiscipline.continuationBindings)+@([pscustomobject]$binding)
  Assert-Coordination (($livePolicy|ConvertTo-Json -Depth 100 -Compress) -ceq
    ($expectedPolicy|ConvertTo-Json -Depth 100 -Compress)) 'COMBINED policy changed beyond exact claim/binding reconciliation.'
  # Original source snapshots are immutable inputs, not closed Git tickets.
  foreach($snapshot in @($record.backendAdmission.sourceSnapshots)) {
    $sourceRoot=[string]$snapshot.root
    Assert-Coordination ($sourceRoot -cin @('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-profile-b01-20261027',
      'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-profile-b03-20261027')) 'Unknown original source root.'
    $sourceHead=@(& git -C $sourceRoot rev-parse HEAD)
    Assert-Coordination ($LASTEXITCODE -eq 0 -and $sourceHead.Count -eq 1 -and $sourceHead[0] -ceq $snapshot.head) 'Original source HEAD changed.'
    foreach($file in $snapshot.files.PSObject.Properties) {
      Assert-Coordination ($file.Name -cin $owners -and
        (Get-Sha256 (Join-Path $sourceRoot $file.Name)) -ceq $file.Value.ToUpperInvariant()) 'Original source fingerprint changed.'
    }
  }
  $registryOwner=Join-Path $root 'config/codex-development-regression-registry.json'
  Assert-Coordination ($ExpectedRegistryEntryCount -eq 4624 -and
    $ExpectedRegistrySha256 -ceq '333A27362EB36CF334397E70EF58745494286D4EFA93A5AEC21C93AF28922C11' -and
    (Get-Sha256 $registryOwner) -ceq $ExpectedRegistrySha256 -and
    $livePolicy.registryBinding.entryCount -eq $ExpectedRegistryEntryCount -and
    $livePolicy.registryBinding.sha256 -ceq $ExpectedRegistrySha256) 'COMBINED registry generation changed.'
  $head=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))[0]
  Get-OctoberCompatibilityGitLines @('merge-base','--is-ancestor',$base,$head)|Out-Null
  Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('rev-list','--merges',"$base..$head")).Count -eq 0 -and
    @(Get-OctoberCompatibilityGitLines @('for-each-ref','--format=%(refname)','refs/replace')).Count -eq 0 -and
    @(Get-OctoberCompatibilityGitLines @('rev-parse','--is-shallow-repository'))[0] -ceq 'false') 'COMBINED history override or merge.'
  foreach($operation in @('MERGE_HEAD','CHERRY_PICK_HEAD','REVERT_HEAD','rebase-merge','rebase-apply','info/grafts')){
    $op=@(Get-OctoberCompatibilityGitLines @('rev-parse','--git-path',$operation))[0]
    if(![IO.Path]::IsPathRooted($op)){$op=Join-Path $root $op}
    Assert-Coordination (!(Test-Path -LiteralPath $op)) 'COMBINED unresolved Git operation.'
  }
  Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('ls-files','-v')|Where-Object {$_ -cmatch '^[a-zS] '}).Count -eq 0) 'COMBINED hidden index flags.'
  $changed=@(@(Get-OctoberCompatibilityGitLines @('diff','--no-renames','--name-only',$base))+
    @(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')))|Sort-Object -Unique
  Assert-ProfileCombinedOwners $changed $owners
  if(!$UseRecordedClaim){
    Assert-Coordination ($ClaimedOwners.Count -gt 0) 'COMBINED requires a nonempty claim.'
    Assert-ProfileCombinedOwners $ClaimedOwners $owners
  }
  $commits=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"$base..$head"))
  Assert-Coordination ($commits.Count -le 1) 'COMBINED permits one exact local admission commit only; no feature commit.'
  if($head -ceq $base){
    Assert-Coordination ($ProductionPhase -cin @('coordination_bootstrap','pre_commit')) 'COMBINED needs its admission checkpoint before implementation.'
    Assert-ProfileCombinedOwners $changed $metadata
  }else{
    $parent=@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$head))[0]
    $subject=@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$head))[0]
    Assert-Coordination ($parent -ceq $base -and $subject -ceq $binding.bootstrapCommitSubject) 'COMBINED admission commit identity changed.'
    $admitted=@(Get-OctoberCompatibilityGitLines @('diff','--no-renames','--name-only',$base,$head))
    Assert-Coordination ((@($admitted|Sort-Object)-join '|') -ceq (@($metadata|Sort-Object)-join '|')) 'COMBINED admission commit changed runtime or omitted metadata.'
    foreach($owner in $metadata){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$head,'--',$owner)|Out-Null}
  }
  if($ProductionPhase -ceq 'task_start'){
    Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('status','--porcelain')).Count -eq 0) 'COMBINED task start is not clean.'
  }
  if($ProductionPhase -ceq 'pre_commit'){
    Assert-Coordination ($head -ceq $base -and
      @(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')).Count -gt 0 -and
      @(Get-OctoberCompatibilityGitLines @('diff','--name-only')).Count -eq 0 -and
      @(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')).Count -eq 0) 'COMBINED permits only fully staged admission metadata commit.'
  }
  & (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -RepositoryRoot $root -StatePath $recordOwner -CandidateId 'PROFILE-INTEGRATION-01' -RequireExecutionAuthorized
  & (Join-Path $root 'scripts/check-cross-agent-incremental-ticket-gate.ps1') -RepositoryRoot $root -Phase $(if($ProductionPhase -ceq 'task_start'){'ticket_start'}else{'implementation'}) -Lane codex_backend -TicketId PROFILE-INTEGRATION-01 -UiScope account.profile_workspace_combined -CandidateVersionName '1.0.0-r67.8' -CandidateVersionCode 2026102704 -PackageId com.moolsocial.app.runtime -AcceptedUiCommit $base -UiContractPath $contract -UiContractSha256 $expectedContract
  Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head
  Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head -IndexOnly
  Write-Output "PROFILE-INTEGRATION-01 admission passed: phase=$ProductionPhase; owners=$($owners.Count); no deployment/provisioning/APK/feature-commit/branch-push authority."
}
