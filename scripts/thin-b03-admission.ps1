# Exact founder-approved THIN-B03 local implementation admission. No release authority.
function Test-ThinB03Identity([hashtable]$Facts) {
  $exact=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-thin-b03-20261027';
    Branch='work/codex-backend/thin-b03-20261027';Lane='codex_backend';Role='primary';
    WorkId='thin-b03-20261027';Ticket='THIN-B03'}
  foreach($key in $exact.Keys){
    if(!$Facts.ContainsKey($key) -or $Facts[$key] -isnot [string] -or $Facts[$key] -cne $exact[$key]){return $false}
  }
  if(!$Facts.ContainsKey('Phase') -or $Facts.Phase -isnot [string] -or
    $Facts.Phase -cnotin @('coordination_bootstrap','pre_commit','task_start','implementation')){return $false}
  $task=if($Facts.Phase -ceq 'coordination_bootstrap'){'/root'}else{'/root/codex_backend_thin_b03'}
  return $Facts.ContainsKey('Task') -and $Facts.Task -is [string] -and $Facts.Task -ceq $task
}
function Get-ThinB03RuntimeOwners {
  @(
    'backend/functions/src/assistant/context_contract.ts',
    'backend/functions/src/assistant/context_contract.test.ts',
    'backend/functions/src/assistant/profile_context.ts',
    'backend/functions/src/assistant/profile_context.test.ts',
    'backend/functions/src/assistant/model_contract.ts',
    'backend/functions/src/assistant/model_service.ts',
    'backend/functions/src/assistant/model_service.test.ts',
    'backend/functions/src/assistant/responses_transport.ts',
    'backend/functions/src/assistant/responses_transport.test.ts',
    'backend/functions/src/index.ts',
    'apps/mobile/lib/features/assistant/mool_assistant.dart',
    'apps/mobile/lib/features/assistant/model_gateway.dart',
    'apps/mobile/lib/features/assistant/profile_context.dart',
    'apps/mobile/lib/ui_v2/assistant/profile_context_adapter.dart',
    'apps/mobile/lib/features/journey01/journey_session.dart',
    'apps/mobile/lib/features/journey01/journey_router.dart',
    'apps/mobile/lib/app/moolsocial_app.dart',
    'apps/mobile/lib/ui_v2/assistant/mool_assistant_v2.dart',
    'apps/mobile/lib/ui_v2/profile/global_personal_profile_v2.dart',
    'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart',
    'apps/mobile/lib/features/work/screens/work_onboarding_screens.dart',
    'apps/mobile/test/assistant_profile_context_test.dart',
    'apps/mobile/test/assistant_workspace_context_test.dart',
    'apps/mobile/test/assistant_model_flow_test.dart',
    'apps/mobile/test/assistant_model_gateway_test.dart',
    'apps/mobile/test/ui_v2/profile/global_personal_profile_v2_test.dart',
    'apps/mobile/test/mool_assistant_test.dart',
    'apps/mobile/test/journey_session_test.dart',
    'apps/mobile/lib/features/journey01/account_profile_gateway.dart'
  )
}
function Get-ThinB03MetadataOwners {
  @(
    '.gitattributes',
    'config/codex-subagent-coordination-policy.json',
    'config/cross-agent-incremental-ticket-gate.json',
    'docs/quality/THIN-B03-BACKEND-20261027.json',
    'docs/quality/THIN-B03-ACCEPTANCE-20261027.json',
    'docs/quality/THIN-B03-CONTRACT-20261027.md',
    'scripts/check-codex-subagent-coordination-policy.ps1',
    'scripts/thin-b03-admission.ps1',
    'scripts/test-thin-b03-admission.ps1'
  )
}
function Assert-ThinB03Owners([string[]]$Actual,[string[]]$Allowed){
  foreach($owner in $Actual){Assert-Coordination ($owner -cin $Allowed) "THIN-B03 unadmitted owner: $owner"}
}
function Invoke-ThinB03Admission {
  $base='da3333ed69bfb7c187320d2294b1e1953ee3bc60'
  $contract='docs/quality/THIN-B03-CONTRACT-20261027.md'
  $hash='224C61B3546E7F0D3C81F55651C6207AE61D63CCCEC73F6A5A5BE7D30788456A'
  $recordOwner='docs/quality/THIN-B03-BACKEND-20261027.json'
  $record=Get-Content -Raw (Join-Path $root $recordOwner)|ConvertFrom-Json
  $binding=$record.backendAdmission.binding
  $branch=@(Get-OctoberCompatibilityGitLines @('branch','--show-current'))[0]
  Assert-Coordination (Test-ThinB03Identity @{Root=$root.Replace('\','/');Branch=$branch;Lane=$ProductionLane;
    Role=$AgentRole;Task=$AgentTask;WorkId=$ProductionWorkId;Ticket=$ProductionTicketId;Phase=$ProductionPhase}) 'THIN-B03 exact identity/phase required.'
  $metadata=@(Get-ThinB03MetadataOwners);$runtime=@(Get-ThinB03RuntimeOwners);$owners=$metadata+$runtime
  $amendPath='docs/quality/THIN-B03-READONLY-ACCEPTANCE-20261027.json'
  $amend=Get-Content -Raw (Join-Path $root $amendPath)|ConvertFrom-Json
  $amendOwners=@($amend.metadataOwners)
  Assert-Coordination ($amend.founderAnswer -ceq 'Approve exact read-only gateway admission' -and
    $amend.runtimeOwner -ceq 'apps/mobile/lib/features/journey01/account_profile_gateway.dart' -and
    $amend.additionalMetadataCommits -eq 1 -and !$amend.sourceCommits -and !$amend.push -and $amend.scopeUnchanged -and
    $amendOwners.Count -eq 7 -and (Get-Sha256 (Join-Path $root $amend.addendum)) -ceq 'B0156A3B3A164235073A419B227A0CD6D811227703204D6708DF2518FC3BFCF7') 'THIN-B03 exact read-only amendment acceptance required.'
  $owners=$owners+@($amend.addendum,$amendPath)

  Assert-Coordination ($binding.baselineHead -ceq $base -and $binding.branch -ceq $branch -and
    $binding.worktreePath -ceq $root.Replace('\','/') -and $binding.task -ceq '/root/codex_backend_thin_b03' -and
    $binding.lane -ceq 'codex_backend' -and $binding.ticketId -ceq 'THIN-B03' -and
    $binding.workId -ceq 'thin-b03-20261027' -and $binding.role -ceq 'primary' -and
    $binding.bootstrapCommitSubject -ceq 'coordination(thin-b03-20261027): record exact authorised context admission' -and
    (@($binding.bootstrapOwners|Sort-Object)-join '|') -ceq (@($metadata|Sort-Object)-join '|') -and
    (@($record.backendAdmission.runtimeOwners|Sort-Object)-join '|') -ceq (@($runtime|Sort-Object)-join '|')) 'THIN-B03 owner/baseline binding changed.'
  foreach($owner in $owners){Assert-Coordination ((Get-CanonicalOwner $owner) -ceq $owner) 'THIN-B03 noncanonical owner.'}
  Assert-Coordination ((Get-Sha256 (Join-Path $root $contract)) -ceq $hash) 'THIN-B03 contract changed.'
  $approval=Get-Content -Raw (Join-Path $root 'docs/quality/THIN-B03-ACCEPTANCE-20261027.json')|ConvertFrom-Json
  Assert-Coordination ($approval.acceptedUiCommit -ceq $base -and $approval.uiContractPath -ceq $contract -and
    $approval.uiContractSha256 -ceq $hash -and $approval.founderDecision -ceq 'accepted_for_thin_b03_local_implementation_with_retained_limits' -and
    $approval.founderAnswer -ceq 'Approve exact THIN-B03 contract and admission' -and
    $approval.localMetadataCommits -eq 1 -and !$approval.sourceFeatureCommits -and !$approval.backendBranchPush -and
    !$approval.deployment -and !$approval.productionAcceptance) 'THIN-B03 exact founder acceptance required.'
  $policy=Get-Content -Raw (Join-Path $root 'config/codex-subagent-coordination-policy.json')|ConvertFrom-Json
  $expected=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/codex-subagent-coordination-policy.json"))-join "`n")|ConvertFrom-Json
  foreach($claim in @($expected.activeClaims)){$claim.owners=@($claim.owners|Where-Object {$_ -cnotin $owners})}
  $expected.activeClaims=@($expected.activeClaims)+@([pscustomobject]@{task='/root/codex_backend_thin_b03';role='primary';owners=$owners})
  $expected.productionGitDiscipline.continuationBindings=@($expected.productionGitDiscipline.continuationBindings)+@($binding)
  Assert-Coordination (($policy|ConvertTo-Json -Depth 100 -Compress) -ceq ($expected|ConvertTo-Json -Depth 100 -Compress)) 'THIN-B03 unrelated policy changed.'
  $incremental=Get-Content -Raw (Join-Path $root 'config/cross-agent-incremental-ticket-gate.json')|ConvertFrom-Json
  $expectedIncremental=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/cross-agent-incremental-ticket-gate.json"))-join "`n")|ConvertFrom-Json
  $expectedIncremental.uiFounderReview.acceptedScopes=@($expectedIncremental.uiFounderReview.acceptedScopes)+@([pscustomobject]@{
    id='assistant.profile_workspace_context';uiCommit=$base;contractPath=$contract;contractSha256=$hash})
  Assert-Coordination (($incremental|ConvertTo-Json -Depth 100 -Compress) -ceq ($expectedIncremental|ConvertTo-Json -Depth 100 -Compress)) 'THIN-B03 unrelated incremental admission changed.'
  Assert-Coordination ($ExpectedRegistryEntryCount -eq 4624 -and
    $ExpectedRegistrySha256 -ceq '333A27362EB36CF334397E70EF58745494286D4EFA93A5AEC21C93AF28922C11' -and
    (Get-Sha256 (Join-Path $root 'config/codex-development-regression-registry.json')) -ceq $ExpectedRegistrySha256) 'THIN-B03 regression pin changed.'
  $head=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))[0]
  Get-OctoberCompatibilityGitLines @('merge-base','--is-ancestor',$base,$head)|Out-Null
  $commits=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"$base..$head"))
  Assert-Coordination ($commits.Count -le 2 -and
    @(Get-OctoberCompatibilityGitLines @('rev-list','--merges',"$base..$head")).Count -eq 0 -and
    @(Get-OctoberCompatibilityGitLines @('for-each-ref','--format=%(refname)','refs/replace')).Count -eq 0 -and
    @(Get-OctoberCompatibilityGitLines @('ls-files','-v')|Where-Object {$_ -cmatch '^[a-zS] '}).Count -eq 0) 'THIN-B03 no feature commits/history overrides/hidden index.'
  $changed=@(@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base))+
    @(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')))|Sort-Object -Unique
  Assert-ThinB03Owners $changed $owners
  if($head -ceq $base){
    Assert-Coordination ($ProductionPhase -cin @('coordination_bootstrap','pre_commit')) 'THIN-B03 recorded admission checkpoint required.'
    Assert-ThinB03Owners $changed $metadata
  }else{
    $bootstrap=$commits[0]
    $parent=@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$bootstrap))[0]
    $subject=@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$bootstrap))[0]
    $admitted=@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base,$bootstrap))
    Assert-Coordination ($parent -ceq $base -and $subject -ceq $binding.bootstrapCommitSubject -and
      (@($admitted|Sort-Object)-join '|') -ceq (@($metadata|Sort-Object)-join '|')) 'THIN-B03 metadata commit identity/scope differs.'
    foreach($owner in @($metadata|Where-Object {$_ -cnotin $amendOwners})){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$bootstrap,'--',$owner)|Out-Null}
    if($commits.Count -eq 2){
      Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$head))[0]) -ceq $bootstrap -and
        (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$head))[0]) -ceq 'coordination(thin-b03-20261027): admit read-only Profile refresh' -and
        (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$bootstrap,$head)|Sort-Object)-join '|') -ceq (@($amendOwners|Sort-Object)-join '|')) 'THIN-B03 amendment commit differs.'
      foreach($owner in $amendOwners){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$head,'--',$owner)|Out-Null}
    }

  }
  if($ProductionPhase -ceq 'pre_commit'){
    $staged=@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only'))
    Assert-Coordination ($commits.Count -eq 1 -and (@($staged|Sort-Object)-join '|') -ceq (@($amendOwners|Sort-Object)-join '|')) 'THIN-B03 only exact read-only metadata amendment may commit.'
    Assert-ThinB03Owners @(Get-OctoberCompatibilityGitLines @('diff','--name-only')) $runtime
  }
  if($ProductionPhase -cin @('coordination_bootstrap','task_start')){
    $remote=@(Get-OctoberCompatibilityGitLines @('ls-remote','--heads','origin','refs/heads/work/codex-backend/ai-b01-20261027'))
    Assert-Coordination ($remote.Count -eq 1 -and ($remote[0] -split '\s+')[0] -ceq $base) 'THIN-B03 source baseline lacks exact origin readback.'
  }
  if($ProductionPhase -ceq 'task_start'){
    Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('status','--porcelain')).Count -eq 0) 'THIN-B03 task start is not clean.'
  }
  & (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -RepositoryRoot $root -StatePath $recordOwner -CandidateId THIN-B03 -RequireExecutionAuthorized
  # Existing tag/ancestry/contract checks remain. THIN-B03's exact branch-based clean
  # task-start above uses the newly accepted sealed combined checkpoint rather
  # than falsely claiming it is the older c9d03bb annotated tag.
  & (Join-Path $root 'scripts/check-cross-agent-incremental-ticket-gate.ps1') -RepositoryRoot $root -Phase implementation -Lane codex_backend -TicketId THIN-B03 -UiScope assistant.profile_workspace_context -CandidateVersionName '1.0.0-r67.10' -CandidateVersionCode 2026102706 -PackageId com.moolsocial.app.runtime -AcceptedUiCommit $base -UiContractPath $contract -UiContractSha256 $hash
  Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head
  Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head -IndexOnly
  Write-Output "THIN-B03 admission passed: phase=$ProductionPhase; runtimeOwners=29; metadataOwners=9; no source commits/push/cloud/billing/APK authority."
}
