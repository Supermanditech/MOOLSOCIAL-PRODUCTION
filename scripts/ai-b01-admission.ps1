# Exact founder-approved AI-B01 local implementation admission. No release authority.
function Test-AiB01Identity([hashtable]$Facts) {
  $exact=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-ai-b01-20261027';
    Branch='work/codex-backend/ai-b01-20261027';Lane='codex_backend';Role='primary';
    WorkId='ai-b01-20261027';Ticket='AI-B01'}
  foreach($key in $exact.Keys){
    if(!$Facts.ContainsKey($key) -or $Facts[$key] -isnot [string] -or $Facts[$key] -cne $exact[$key]){return $false}
  }
  if(!$Facts.ContainsKey('Phase') -or $Facts.Phase -isnot [string] -or
    $Facts.Phase -cnotin @('coordination_bootstrap','pre_commit','task_start','implementation')){return $false}
  $task=if($Facts.Phase -ceq 'coordination_bootstrap'){'/root'}else{'/root/codex_backend_ai_b01'}
  return $Facts.ContainsKey('Task') -and $Facts.Task -is [string] -and $Facts.Task -ceq $task
}
function Get-AiB01RuntimeOwners {
  @(
    'backend/functions/src/assistant/model_contract.ts',
    'backend/functions/src/assistant/model_contract.test.ts',
    'backend/functions/src/assistant/model_service.ts',
    'backend/functions/src/assistant/model_service.test.ts',
    'backend/functions/src/assistant/model_http.ts',
    'backend/functions/src/assistant/model_http.test.ts',
    'backend/functions/src/assistant/responses_transport.ts',
    'backend/functions/src/assistant/responses_transport.test.ts',
    'backend/functions/src/index.ts',
    'apps/mobile/lib/features/assistant/mool_assistant.dart',
    'apps/mobile/lib/features/assistant/model_gateway.dart',
    'apps/mobile/lib/features/journey01/journey_session.dart',
    'apps/mobile/lib/features/journey01/review_journey_services.dart',
    'apps/mobile/lib/app/moolsocial_app.dart',
    'apps/mobile/lib/ui_v2/assistant/mool_assistant_v2.dart',
    'apps/mobile/test/assistant_model_gateway_test.dart',
    'apps/mobile/test/assistant_model_flow_test.dart',
    'apps/mobile/test/mool_assistant_test.dart'
  )
}
function Get-AiB01MetadataOwners {
  @('.gitattributes','config/codex-subagent-coordination-policy.json',
    'config/cross-agent-incremental-ticket-gate.json',
    'docs/quality/AI-B01-BACKEND-20261027.json',
    'docs/quality/AI-B01-ACCEPTANCE-20261027.json',
    'docs/quality/AI-B01-CONTRACT-20261027.md',
    'scripts/check-codex-subagent-coordination-policy.ps1',
    'scripts/ai-b01-admission.ps1','scripts/test-ai-b01-admission.ps1')
}
function Assert-AiB01Owners([string[]]$Actual,[string[]]$Allowed){
  foreach($owner in $Actual){Assert-Coordination ($owner -cin $Allowed) "AI-B01 unadmitted owner: $owner"}
}
function Invoke-AiB01Admission {
  $base='88e53a271dafe8eec839c80eaa9e96ee56cf9466'
  $contract='docs/quality/AI-B01-CONTRACT-20261027.md'
  $hash='310A623C6C83603918C00FA73971A1C8C86AE8C50131DBE3912DF0B6D7B3787E'
  $recordOwner='docs/quality/AI-B01-BACKEND-20261027.json'
  $record=Get-Content -Raw (Join-Path $root $recordOwner)|ConvertFrom-Json
  $binding=$record.backendAdmission.binding
  $branch=@(Get-OctoberCompatibilityGitLines @('branch','--show-current'))[0]
  Assert-Coordination (Test-AiB01Identity @{Root=$root.Replace('\','/');Branch=$branch;Lane=$ProductionLane;
    Role=$AgentRole;Task=$AgentTask;WorkId=$ProductionWorkId;Ticket=$ProductionTicketId;Phase=$ProductionPhase}) 'AI-B01 exact identity/phase required.'
  $metadata=@(Get-AiB01MetadataOwners);$runtime=@(Get-AiB01RuntimeOwners);$owners=$metadata+$runtime
  Assert-Coordination ($binding.baselineHead -ceq $base -and $binding.branch -ceq $branch -and
    $binding.worktreePath -ceq $root.Replace('\','/') -and $binding.task -ceq '/root/codex_backend_ai_b01' -and
    $binding.lane -ceq 'codex_backend' -and $binding.ticketId -ceq 'AI-B01' -and
    $binding.workId -ceq 'ai-b01-20261027' -and $binding.role -ceq 'primary' -and
    $binding.bootstrapCommitSubject -ceq 'coordination(ai-b01-20261027): record exact model gateway admission' -and
    (@($binding.bootstrapOwners|Sort-Object)-join '|') -ceq (@($metadata|Sort-Object)-join '|') -and
    (@($record.backendAdmission.runtimeOwners|Sort-Object)-join '|') -ceq (@($runtime|Sort-Object)-join '|')) 'AI-B01 owner/baseline binding changed.'
  foreach($owner in $owners){Assert-Coordination ((Get-CanonicalOwner $owner) -ceq $owner) 'AI-B01 noncanonical owner.'}
  Assert-Coordination ((Get-Sha256 (Join-Path $root $contract)) -ceq $hash) 'AI-B01 contract changed.'
  $approval=Get-Content -Raw (Join-Path $root 'docs/quality/AI-B01-ACCEPTANCE-20261027.json')|ConvertFrom-Json
  Assert-Coordination ($approval.acceptedUiCommit -ceq $base -and $approval.uiContractPath -ceq $contract -and
    $approval.uiContractSha256 -ceq $hash -and $approval.founderDecision -ceq 'accepted_for_ai_b01_local_implementation_with_retained_limits' -and
    $approval.founderAnswer -ceq 'approved' -and
    $approval.localMetadataCommits -eq 1 -and !$approval.sourceFeatureCommits -and !$approval.backendBranchPush -and
    !$approval.deployment -and !$approval.productionAcceptance) 'AI-B01 exact founder acceptance required.'
  $policy=Get-Content -Raw (Join-Path $root 'config/codex-subagent-coordination-policy.json')|ConvertFrom-Json
  $expected=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/codex-subagent-coordination-policy.json"))-join "`n")|ConvertFrom-Json
  foreach($claim in @($expected.activeClaims)){$claim.owners=@($claim.owners|Where-Object {$_ -cnotin $owners})}
  $expected.activeClaims=@($expected.activeClaims)+@([pscustomobject]@{task='/root/codex_backend_ai_b01';role='primary';owners=$owners})
  $expected.productionGitDiscipline.continuationBindings=@($expected.productionGitDiscipline.continuationBindings)+@($binding)
  Assert-Coordination (($policy|ConvertTo-Json -Depth 100 -Compress) -ceq ($expected|ConvertTo-Json -Depth 100 -Compress)) 'AI-B01 unrelated policy changed.'
  $incremental=Get-Content -Raw (Join-Path $root 'config/cross-agent-incremental-ticket-gate.json')|ConvertFrom-Json
  $expectedIncremental=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/cross-agent-incremental-ticket-gate.json"))-join "`n")|ConvertFrom-Json
  $expectedIncremental.uiFounderReview.acceptedScopes=@($expectedIncremental.uiFounderReview.acceptedScopes)+@([pscustomobject]@{
    id='assistant.model_preparation';uiCommit=$base;contractPath=$contract;contractSha256=$hash})
  Assert-Coordination (($incremental|ConvertTo-Json -Depth 100 -Compress) -ceq ($expectedIncremental|ConvertTo-Json -Depth 100 -Compress)) 'AI-B01 unrelated incremental admission changed.'
  Assert-Coordination ($ExpectedRegistryEntryCount -eq 4624 -and
    $ExpectedRegistrySha256 -ceq '333A27362EB36CF334397E70EF58745494286D4EFA93A5AEC21C93AF28922C11' -and
    (Get-Sha256 (Join-Path $root 'config/codex-development-regression-registry.json')) -ceq $ExpectedRegistrySha256) 'AI-B01 regression pin changed.'
  $head=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))[0]
  Get-OctoberCompatibilityGitLines @('merge-base','--is-ancestor',$base,$head)|Out-Null
  $commits=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"$base..$head"))
  Assert-Coordination ($commits.Count -le 1 -and
    @(Get-OctoberCompatibilityGitLines @('rev-list','--merges',"$base..$head")).Count -eq 0 -and
    @(Get-OctoberCompatibilityGitLines @('for-each-ref','--format=%(refname)','refs/replace')).Count -eq 0 -and
    @(Get-OctoberCompatibilityGitLines @('ls-files','-v')|Where-Object {$_ -cmatch '^[a-zS] '}).Count -eq 0) 'AI-B01 no feature commits/history overrides/hidden index.'
  $changed=@(@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base))+
    @(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')))|Sort-Object -Unique
  Assert-AiB01Owners $changed $owners
  if($head -ceq $base){
    Assert-Coordination ($ProductionPhase -cin @('coordination_bootstrap','pre_commit')) 'AI-B01 recorded admission checkpoint required.'
    Assert-AiB01Owners $changed $metadata
  }else{
    $parent=@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$head))[0]
    $subject=@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$head))[0]
    $admitted=@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base,$head))
    Assert-Coordination ($parent -ceq $base -and $subject -ceq $binding.bootstrapCommitSubject -and
      (@($admitted|Sort-Object)-join '|') -ceq (@($metadata|Sort-Object)-join '|')) 'AI-B01 metadata commit identity/scope differs.'
    foreach($owner in $metadata){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$head,'--',$owner)|Out-Null}
  }
  if($ProductionPhase -ceq 'pre_commit'){
    $staged=@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only'))
    Assert-Coordination ($head -ceq $base -and (@($staged|Sort-Object)-join '|') -ceq (@($metadata|Sort-Object)-join '|') -and
      @(Get-OctoberCompatibilityGitLines @('diff','--name-only')).Count -eq 0 -and
      @(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')).Count -eq 0) 'AI-B01 only fully staged exact metadata commit.'
  }
  if($ProductionPhase -cin @('coordination_bootstrap','task_start')){
    $remote=@(Get-OctoberCompatibilityGitLines @('ls-remote','--heads','origin','refs/heads/work/codex-backend/profile-b02-20261027'))
    Assert-Coordination ($remote.Count -eq 1 -and ($remote[0] -split '\s+')[0] -ceq $base) 'AI-B01 source baseline lacks exact origin readback.'
  }
  if($ProductionPhase -ceq 'task_start'){
    Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('status','--porcelain')).Count -eq 0) 'AI-B01 task start is not clean.'
  }
  & (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -RepositoryRoot $root -StatePath $recordOwner -CandidateId AI-B01 -RequireExecutionAuthorized
  # Existing tag/ancestry/contract checks remain. AI-B01's exact branch-based clean
  # task-start above uses the newly accepted sealed combined checkpoint rather
  # than falsely claiming it is the older c9d03bb annotated tag.
  & (Join-Path $root 'scripts/check-cross-agent-incremental-ticket-gate.ps1') -RepositoryRoot $root -Phase implementation -Lane codex_backend -TicketId AI-B01 -UiScope assistant.model_preparation -CandidateVersionName '1.0.0-r67.9' -CandidateVersionCode 2026102705 -PackageId com.moolsocial.app.runtime -AcceptedUiCommit $base -UiContractPath $contract -UiContractSha256 $hash
  Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head
  Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head -IndexOnly
  Write-Output "AI-B01 admission passed: phase=$ProductionPhase; runtimeOwners=18; metadataOwners=9; no source commits/push/cloud/billing/APK authority."
}
