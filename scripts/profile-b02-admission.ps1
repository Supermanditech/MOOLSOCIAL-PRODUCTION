# Exact founder-approved B02 local implementation admission. No release authority.
function Test-ProfileB02Identity([hashtable]$Facts) {
  $exact=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-profile-b02-20261027';
    Branch='work/codex-backend/profile-b02-20261027';Lane='codex_backend';Role='primary';
    WorkId='profile-b02-20261027';Ticket='PROFILE-B02'}
  foreach($key in $exact.Keys){
    if(!$Facts.ContainsKey($key) -or $Facts[$key] -isnot [string] -or $Facts[$key] -cne $exact[$key]){return $false}
  }
  if(!$Facts.ContainsKey('Phase') -or $Facts.Phase -isnot [string] -or
    $Facts.Phase -cnotin @('coordination_bootstrap','pre_commit','task_start','implementation')){return $false}
  $task=if($Facts.Phase -ceq 'coordination_bootstrap'){'/root'}else{'/root/codex_backend_profile_b02'}
  return $Facts.ContainsKey('Task') -and $Facts.Task -is [string] -and $Facts.Task -ceq $task
}
function Get-ProfileB02RuntimeOwners {
  @(
    'apps/mobile/lib/features/journey01/account_plans_gateway.dart',
    'apps/mobile/lib/features/journey01/journey_session.dart',
    'apps/mobile/lib/features/journey01/review_journey_services.dart',
    'apps/mobile/lib/features/journey01/journey_router.dart',
    'apps/mobile/lib/app/moolsocial_app.dart',
    'apps/mobile/lib/features/assistant/mool_assistant.dart',
    'apps/mobile/lib/ui_v2/profile/global_account_plans_v2.dart',
    'apps/mobile/test/account_plans_gateway_test.dart',
    'apps/mobile/test/account_plans_flow_test.dart',
    'apps/mobile/test/journey_session_test.dart',
    'apps/mobile/test/mool_assistant_test.dart',
    'apps/mobile/test/ui_v2/profile/global_account_plans_v2_test.dart',
    'backend/functions/src/index.ts',
    'backend/functions/src/account/plans_service.ts',
    'backend/functions/src/account/plans_service.test.ts',
    'backend/functions/src/account/plans_http.ts',
    'backend/functions/src/account/plans_http.test.ts',
    'backend/functions/src/account/plans_dataconnect_store.ts',
    'backend/functions/src/account/plans_dataconnect_store.test.ts',
    'apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart',
    'dataconnect/schema/universal.gql',
    'dataconnect/mobile/universal.gql'
  )
}
function Get-ProfileB02MetadataOwners {
  @('.gitattributes','config/codex-subagent-coordination-policy.json',
    'config/cross-agent-incremental-ticket-gate.json',
    'docs/quality/PROFILE-B02-BACKEND-20261027.json',
    'docs/quality/PROFILE-B02-ACCEPTANCE-20261027.json',
    'docs/quality/PROFILE-B02-CONTRACT-20261027.md',
    'scripts/check-codex-subagent-coordination-policy.ps1',
    'scripts/profile-b02-admission.ps1','scripts/test-profile-b02-admission.ps1')
}
function Assert-ProfileB02Owners([string[]]$Actual,[string[]]$Allowed){
  foreach($owner in $Actual){Assert-Coordination ($owner -cin $Allowed) "B02 unadmitted owner: $owner"}
}
function Invoke-ProfileB02Admission {
  if(Test-Path (Join-Path $root 'docs/quality/PROFILE-B02-SOURCE-SEAL-20261027.json')){
    . (Join-Path $root 'scripts/profile-b02-source-seal.ps1')
    Invoke-ProfileB02SourceSeal
    return
  }
  $base='955f793dcfc593b603797d9e960925f774a6c2c2'
  $contract='docs/quality/PROFILE-B02-CONTRACT-20261027.md'
  $hash='44233B52F1FE9371D37BDE8476D8B6FA18305E5CCD2B9F20AC110514B22E2F9A'
  $recordOwner='docs/quality/PROFILE-B02-BACKEND-20261027.json'
  $record=Get-Content -Raw (Join-Path $root $recordOwner)|ConvertFrom-Json
  $binding=$record.backendAdmission.binding
  $branch=@(Get-OctoberCompatibilityGitLines @('branch','--show-current'))[0]
  Assert-Coordination (Test-ProfileB02Identity @{Root=$root.Replace('\','/');Branch=$branch;Lane=$ProductionLane;
    Role=$AgentRole;Task=$AgentTask;WorkId=$ProductionWorkId;Ticket=$ProductionTicketId;Phase=$ProductionPhase}) 'B02 exact identity/phase required.'
  $bootstrap=@(Get-ProfileB02MetadataOwners);$metadata=$bootstrap+@('docs/quality/PROFILE-B02-WORKSPACE-PLACEMENT-20261027.md');$runtime=@(Get-ProfileB02RuntimeOwners);$owners=$metadata+$runtime
  Assert-Coordination ($binding.baselineHead -ceq $base -and $binding.branch -ceq $branch -and
    $binding.worktreePath -ceq $root.Replace('\','/') -and $binding.task -ceq '/root/codex_backend_profile_b02' -and
    $binding.lane -ceq 'codex_backend' -and $binding.ticketId -ceq 'PROFILE-B02' -and
    $binding.workId -ceq 'profile-b02-20261027' -and $binding.role -ceq 'primary' -and
    $binding.bootstrapCommitSubject -ceq 'coordination(profile-b02-20261027): record exact Plans admission' -and
    (@($binding.bootstrapOwners|Sort-Object)-join '|') -ceq (@($bootstrap|Sort-Object)-join '|') -and
    (@($record.backendAdmission.runtimeOwners|Sort-Object)-join '|') -ceq (@($runtime|Sort-Object)-join '|')) 'B02 owner/baseline binding changed.'
  foreach($owner in $owners){Assert-Coordination ((Get-CanonicalOwner $owner) -ceq $owner) 'B02 noncanonical owner.'}
  Assert-Coordination ((Get-Sha256 (Join-Path $root $contract)) -ceq $hash) 'B02 contract changed.'
  $approval=Get-Content -Raw (Join-Path $root 'docs/quality/PROFILE-B02-ACCEPTANCE-20261027.json')|ConvertFrom-Json
  Assert-Coordination ($approval.acceptedUiCommit -ceq $base -and $approval.uiContractPath -ceq $contract -and
    $approval.uiContractSha256 -ceq $hash -and $approval.founderDecision -ceq 'accepted_for_b02_local_implementation_with_retained_limits' -and
    $approval.founderAnswer -ceq 'Approve exact B02 baseline, contract and one metadata admission commit' -and
    $approval.localMetadataCommits -eq 1 -and !$approval.sourceFeatureCommits -and !$approval.backendBranchPush -and
    !$approval.deployment -and !$approval.productionAcceptance) 'B02 exact founder acceptance required.'
  $placementPath='docs/quality/PROFILE-B02-WORKSPACE-PLACEMENT-20261027.md'
  $placementHash='2DE1F3E33A4D404B457FF806F3A9158B932FBC09EDFDFF683E42936E56596AE0'
  Assert-Coordination ((Get-Sha256 (Join-Path $root $placementPath)) -ceq $placementHash -and
    $record.placementAmendment.sha256 -ceq $placementHash -and $approval.placementAmendment.sha256 -ceq $placementHash -and
    $approval.placementAmendment.founderAdmissionAnswer -ceq 'Approve exact placement admission and one metadata amendment commit' -and
    $record.placementAmendment.additionalRuntimeOwner -ceq 'apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart' -and
    $record.placementAmendment.additionalLocalMetadataCommits -eq 1 -and
    !$record.placementAmendment.sourceFeatureCommits -and !$record.placementAmendment.backendBranchPush) 'B02 exact placement amendment required.'
  $placementMetadata=@(Get-ProfileB02PlacementMetadataOwners)
  Assert-Coordination ((@($record.placementAmendment.metadataOwners|Sort-Object)-join '|') -ceq
    (@($placementMetadata|Sort-Object)-join '|')) 'B02 placement metadata scope differs.'
  $policy=Get-Content -Raw (Join-Path $root 'config/codex-subagent-coordination-policy.json')|ConvertFrom-Json
  $expected=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/codex-subagent-coordination-policy.json"))-join "`n")|ConvertFrom-Json
  foreach($claim in @($expected.activeClaims)){$claim.owners=@($claim.owners|Where-Object {$_ -cnotin $owners})}
  $expected.activeClaims=@($expected.activeClaims)+@([pscustomobject]@{task='/root/codex_backend_profile_b02';role='primary';owners=$owners})
  $expected.productionGitDiscipline.continuationBindings=@($expected.productionGitDiscipline.continuationBindings)+@($binding)
  Assert-Coordination (($policy|ConvertTo-Json -Depth 100 -Compress) -ceq ($expected|ConvertTo-Json -Depth 100 -Compress)) 'B02 unrelated policy changed.'
  $incremental=Get-Content -Raw (Join-Path $root 'config/cross-agent-incremental-ticket-gate.json')|ConvertFrom-Json
  $expectedIncremental=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/cross-agent-incremental-ticket-gate.json"))-join "`n")|ConvertFrom-Json
  $expectedIncremental.uiFounderReview.acceptedScopes=@($expectedIncremental.uiFounderReview.acceptedScopes)+@([pscustomobject]@{
    id='account.plans_entitlements';uiCommit=$base;contractPath=$contract;contractSha256=$hash})
  Assert-Coordination (($incremental|ConvertTo-Json -Depth 100 -Compress) -ceq ($expectedIncremental|ConvertTo-Json -Depth 100 -Compress)) 'B02 unrelated incremental admission changed.'
  Assert-Coordination ($ExpectedRegistryEntryCount -eq 4624 -and
    $ExpectedRegistrySha256 -ceq '333A27362EB36CF334397E70EF58745494286D4EFA93A5AEC21C93AF28922C11' -and
    (Get-Sha256 (Join-Path $root 'config/codex-development-regression-registry.json')) -ceq $ExpectedRegistrySha256) 'B02 regression pin changed.'
  $head=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))[0]
  Get-OctoberCompatibilityGitLines @('merge-base','--is-ancestor',$base,$head)|Out-Null
  $commits=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"$base..$head"))
  Assert-Coordination ($commits.Count -le 2 -and
    @(Get-OctoberCompatibilityGitLines @('rev-list','--merges',"$base..$head")).Count -eq 0 -and
    @(Get-OctoberCompatibilityGitLines @('for-each-ref','--format=%(refname)','refs/replace')).Count -eq 0 -and
    @(Get-OctoberCompatibilityGitLines @('ls-files','-v')|Where-Object {$_ -cmatch '^[a-zS] '}).Count -eq 0) 'B02 no feature commits/history overrides/hidden index.'
  $changed=@(@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base))+
    @(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')))|Sort-Object -Unique
  Assert-ProfileB02Owners $changed $owners
  $originalAdmission='3d2ea869bbfc82bd769dfdd3823ad095d7f9d891'
  Assert-Coordination ($commits.Count -ge 1 -and $commits[0] -ceq $originalAdmission) 'B02 original admission checkpoint changed.'
  $first=@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base,$originalAdmission))
  Assert-Coordination ((@($first|Sort-Object)-join '|') -ceq (@($bootstrap|Sort-Object)-join '|')) 'B02 original metadata delta changed.'
  if($commits.Count -eq 2){
    $parent=@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$head))[0]
    $subject=@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$head))[0]
    $admitted=@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$head))
    Assert-Coordination ($parent -ceq $originalAdmission -and
      $subject -ceq 'coordination(profile-b02-20261027): admit Workspace placement amendment' -and
      (@($admitted|Sort-Object)-join '|') -ceq (@($placementMetadata|Sort-Object)-join '|')) 'B02 amendment commit scope/history changed.'
    foreach($owner in $metadata){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$head,'--',$owner)|Out-Null}
  }else{
    foreach($owner in @($bootstrap|Where-Object {$_ -cnotin $placementMetadata})){
      Get-OctoberCompatibilityGitLines @('diff','--exit-code',$head,'--',$owner)|Out-Null
    }
  }
  if($ProductionPhase -ceq 'pre_commit'){
    $staged=@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only'))
    Assert-Coordination ($head -ceq $originalAdmission -and
      (@($staged|Sort-Object)-join '|') -ceq (@($placementMetadata|Sort-Object)-join '|')) 'B02 permits only the exact seven-file placement amendment commit.'
    foreach($owner in $placementMetadata){Get-OctoberCompatibilityGitLines @('diff','--exit-code','--',$owner)|Out-Null}
  }
  if($ProductionPhase -cin @('coordination_bootstrap','task_start')){
    $remote=@(Get-OctoberCompatibilityGitLines @('ls-remote','--heads','origin','refs/heads/work/codex-backend/profile-combined-20261027'))
    Assert-Coordination ($remote.Count -eq 1 -and ($remote[0] -split '\s+')[0] -ceq $base) 'B02 source baseline lacks exact origin readback.'
  }
  if($ProductionPhase -ceq 'task_start'){
    Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('status','--porcelain')).Count -eq 0) 'B02 task start is not clean.'
  }
  & (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -RepositoryRoot $root -StatePath $recordOwner -CandidateId PROFILE-B02 -RequireExecutionAuthorized
  # Existing tag/ancestry/contract checks remain. B02's exact branch-based clean
  # task-start above uses the newly accepted sealed combined checkpoint rather
  # than falsely claiming it is the older c9d03bb annotated tag.
  & (Join-Path $root 'scripts/check-cross-agent-incremental-ticket-gate.ps1') -RepositoryRoot $root -Phase implementation -Lane codex_backend -TicketId PROFILE-B02 -UiScope account.plans_entitlements -CandidateVersionName '1.0.0-r67.9' -CandidateVersionCode 2026102705 -PackageId com.moolsocial.app.runtime -AcceptedUiCommit $base -UiContractPath $contract -UiContractSha256 $hash
  Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head
  Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head -IndexOnly
  Write-Output "PROFILE-B02 admission passed: phase=$ProductionPhase; runtimeOwners=22; metadataOwners=10; no source commits/push/cloud/billing/APK authority."
}

function Get-ProfileB02PlacementMetadataOwners {
  @('.gitattributes','config/codex-subagent-coordination-policy.json',
    'docs/quality/PROFILE-B02-BACKEND-20261027.json','docs/quality/PROFILE-B02-ACCEPTANCE-20261027.json',
    'docs/quality/PROFILE-B02-WORKSPACE-PLACEMENT-20261027.md',
    'scripts/profile-b02-admission.ps1','scripts/test-profile-b02-admission.ps1')
}
