function Test-ThinB07B04Identity([hashtable]$Facts) {
 $exact=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-thin-b07-b04-20261027';Branch='work/codex-backend/thin-b07-b04-20261027';Lane='codex_backend';Role='primary';WorkId='thin-b07-b04-20261027';Ticket='THIN-B07-B04-PROFILE'}
 foreach($key in $exact.Keys){if(!$Facts.ContainsKey($key) -or $Facts[$key] -isnot [string] -or $Facts[$key] -cne $exact[$key]){return $false}}
 if(!$Facts.ContainsKey('Phase') -or $Facts.Phase -cnotin @('coordination_bootstrap','pre_commit','task_start','implementation')){return $false}
 $expected=if($Facts.Phase -ceq 'coordination_bootstrap'){'/root'}else{'/root/codex_backend_thin_b07_b04'}
 return $Facts.ContainsKey('Task') -and $Facts.Task -is [string] -and $Facts.Task -ceq $expected
}
function Get-ThinB07B04RuntimeOwners { @('backend/functions/src/assistant/model_contract.ts','backend/functions/src/assistant/model_contract.test.ts','backend/functions/src/assistant/model_service.ts','backend/functions/src/assistant/model_service.test.ts','backend/functions/src/assistant/model_http.ts','backend/functions/src/assistant/model_http.test.ts','backend/functions/src/assistant/preparation_dataconnect_store.ts','backend/functions/src/assistant/preparation_dataconnect_store.test.ts','backend/functions/src/assistant/usage_store.ts','backend/functions/src/assistant/usage_store.test.ts','backend/functions/src/assistant/profile_execution.ts','backend/functions/src/assistant/profile_execution.test.ts','backend/functions/src/account/profile_http.ts','backend/functions/src/account/profile_http.test.ts','backend/functions/src/index.ts','dataconnect/schema/assistant.gql','apps/mobile/lib/features/assistant/model_gateway.dart','apps/mobile/lib/features/assistant/preparation_pending_store.dart','apps/mobile/lib/features/assistant/profile_context.dart','apps/mobile/lib/features/assistant/mool_assistant.dart','apps/mobile/lib/features/journey01/account_profile_gateway.dart','apps/mobile/lib/features/journey01/journey_session.dart','apps/mobile/lib/ui_v2/assistant/profile_context_adapter.dart','apps/mobile/lib/ui_v2/profile/global_personal_profile_v2.dart','apps/mobile/lib/features/buy/buy_v2_session.dart','apps/mobile/lib/ui_v2/buy/buy_v2_views.dart','apps/mobile/test/assistant_model_gateway_test.dart','apps/mobile/test/assistant_model_flow_test.dart','apps/mobile/test/assistant_profile_context_test.dart','apps/mobile/test/assistant_preparation_recovery_test.dart','apps/mobile/test/account_profile_gateway_test.dart','apps/mobile/test/journey_session_test.dart','apps/mobile/test/mool_assistant_test.dart','dataconnect/provider/youtube.gql') }
function Get-ThinB07B04MetadataOwners { @('.gitattributes','config/codex-subagent-coordination-policy.json','config/cross-agent-incremental-ticket-gate.json','docs/quality/THIN-B07-B04-BACKEND-20261027.json','docs/quality/THIN-B07-B04-ACCEPTANCE-20261027.json','docs/quality/THIN-B07-B04-CONTRACT-20261027.md','scripts/check-codex-subagent-coordination-policy.ps1','scripts/thin-b07-b04-admission.ps1','scripts/test-thin-b07-b04-admission.ps1') }
function Assert-ThinB07B04Owners([string[]]$Actual,[string[]]$Allowed){foreach($owner in $Actual){Assert-Coordination ($owner -cin $Allowed) "Combined goal unadmitted owner: $owner"}}
function Invoke-ThinB07B04Admission {
 $base='566c88f6b3698648a6f4facbdc01b86c5ecf42bb';$contract='docs/quality/THIN-B07-B04-CONTRACT-20261027.md';$hash='23B6413B17C57F2E9ABE7E03D16F916C32C27908E65BED900663E02D7F67E382';$recordOwner='docs/quality/THIN-B07-B04-BACKEND-20261027.json'
 $runtime=@(Get-ThinB07B04RuntimeOwners);$metadata=@(Get-ThinB07B04MetadataOwners);$owners=$runtime+$metadata
 $amendPath='docs/quality/THIN-B07-B04-ERASURE-ACCEPTANCE-20261028.json';$amend=Get-Content -Raw (Join-Path $root $amendPath)|ConvertFrom-Json;$amendOwners=@($amend.metadataOwners)
 Assert-Coordination ($amend.standingFounderMessage -ceq 'keep this standing authorisation or approval if needed while i am away' -and $amend.runtimeOwner -ceq 'dataconnect/provider/youtube.gql' -and $amend.additionalMetadataCommits -eq 1 -and !$amend.sourceFeatureCommits -and !$amend.push -and $amend.scopeUnchanged -and $amendOwners.Count -eq 7 -and (Get-Sha256 (Join-Path $root $amend.addendum)) -ceq 'EFAA6776F0B4F928FFE84A9162FCD42161C292432F608A575C382DDFA1034C1A') 'Exact bounded erasure amendment authority differs.'
 $owners=$owners+@($amend.addendum,$amendPath)
 $branch=@(Get-OctoberCompatibilityGitLines @('branch','--show-current'))[0]
 Assert-Coordination (Test-ThinB07B04Identity @{Root=$root.Replace('\','/');Branch=$branch;Lane=$ProductionLane;Role=$AgentRole;Task=$AgentTask;WorkId=$ProductionWorkId;Ticket=$ProductionTicketId;Phase=$ProductionPhase}) 'Combined exact identity/phase required.'
 Assert-Coordination ((Get-Sha256 (Join-Path $root $contract)) -ceq $hash) 'Accepted combined contract changed.'
 $record=Get-Content -Raw (Join-Path $root $recordOwner)|ConvertFrom-Json;$binding=$record.backendAdmission.binding
 Assert-Coordination ($binding.baselineHead -ceq $base -and $binding.branch -ceq $branch -and $binding.task -ceq '/root/codex_backend_thin_b07_b04' -and $binding.worktreePath -ceq 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-thin-b07-b04-20261027' -and $binding.bootstrapCommitSubject -ceq 'coordination(thin-b07-b04-20261027): record exact combined admission' -and (@($binding.bootstrapOwners|Sort-Object)-join '|') -ceq (@($metadata|Sort-Object)-join '|') -and (@($record.backendAdmission.runtimeOwners|Sort-Object)-join '|') -ceq (@($runtime|Sort-Object)-join '|')) 'Exact combined owner binding changed.'
 $approval=Get-Content -Raw (Join-Path $root 'docs/quality/THIN-B07-B04-ACCEPTANCE-20261027.json')|ConvertFrom-Json
 Assert-Coordination ($approval.acceptedUiCommit -ceq $base -and $approval.uiContractSha256 -ceq $hash -and $approval.founderAnswer -ceq 'Approve exact combined contract and 33-file admission' -and $approval.localMetadataCommits -eq 1 -and !$approval.sourceFeatureCommits -and !$approval.backendBranchPush -and !$approval.deployment -and !$approval.productionAcceptance) 'Exact acceptance/authority differs.'
 $expected=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/codex-subagent-coordination-policy.json"))-join "`n")|ConvertFrom-Json
 foreach($claim in @($expected.activeClaims)){$claim.owners=@($claim.owners|Where-Object {$_ -cnotin $owners})}
 $expected.activeClaims=@($expected.activeClaims)+@([pscustomobject]@{task='/root/codex_backend_thin_b07_b04';role='primary';owners=$owners})
 $expected.productionGitDiscipline.continuationBindings=@($expected.productionGitDiscipline.continuationBindings)+@($binding)
 $policy=Get-Content -Raw (Join-Path $root 'config/codex-subagent-coordination-policy.json')|ConvertFrom-Json
 Assert-Coordination (($policy|ConvertTo-Json -Depth 100 -Compress) -ceq ($expected|ConvertTo-Json -Depth 100 -Compress)) 'Unrelated policy changed.'
 $inc=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/cross-agent-incremental-ticket-gate.json"))-join "`n")|ConvertFrom-Json
 $inc.uiFounderReview.acceptedScopes=@($inc.uiFounderReview.acceptedScopes)+@([pscustomobject]@{id='assistant.profile_durable_recovery';uiCommit=$base;contractPath=$contract;contractSha256=$hash})
 $actual=Get-Content -Raw (Join-Path $root 'config/cross-agent-incremental-ticket-gate.json')|ConvertFrom-Json
 Assert-Coordination (($actual|ConvertTo-Json -Depth 100 -Compress) -ceq ($inc|ConvertTo-Json -Depth 100 -Compress)) 'Unrelated incremental gate changed.'
 Assert-Coordination ($ExpectedRegistryEntryCount -eq 4624 -and $ExpectedRegistrySha256 -ceq '333A27362EB36CF334397E70EF58745494286D4EFA93A5AEC21C93AF28922C11' -and (Get-Sha256 (Join-Path $root 'config/codex-development-regression-registry.json')) -ceq $ExpectedRegistrySha256) 'Regression pin changed.'
 $head=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))[0];Get-OctoberCompatibilityGitLines @('merge-base','--is-ancestor',$base,$head)|Out-Null
 $commits=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"$base..$head"))
 Assert-Coordination ($commits.Count -le 2 -and @(Get-OctoberCompatibilityGitLines @('rev-list','--merges',"$base..$head")).Count -eq 0 -and @(Get-OctoberCompatibilityGitLines @('for-each-ref','--format=%(refname)','refs/replace')).Count -eq 0 -and @(Get-OctoberCompatibilityGitLines @('ls-files','-v')|Where-Object {$_ -cmatch '^[a-zS] '}).Count -eq 0) 'Only one metadata checkpoint; no history/index overrides.'
 $changed=@(@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base))+@(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')))|Sort-Object -Unique
 Assert-ThinB07B04Owners $changed $owners
 if($head -ceq $base){Assert-Coordination ($ProductionPhase -cin @('coordination_bootstrap','pre_commit')) 'Recorded clean admission required.';Assert-ThinB07B04Owners $changed $metadata}
 else {
  $bootstrap=$commits[0]
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$bootstrap))[0]) -ceq $base -and (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$bootstrap))[0]) -ceq 'coordination(thin-b07-b04-20261027): record exact combined admission' -and (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base,$bootstrap)|Sort-Object)-join '|') -ceq (@($metadata|Sort-Object)-join '|')) 'Original metadata parent/subject/owners differ.'
  foreach($owner in @($metadata|Where-Object {$_ -cnotin $amendOwners})){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$bootstrap,'--',$owner)|Out-Null}
  if($commits.Count -eq 2){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$head))[0]) -ceq $bootstrap -and (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$head))[0]) -ceq 'coordination(thin-b07-b04-20261027): admit existing account erasure linkage' -and (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$bootstrap,$head)|Sort-Object)-join '|') -ceq (@($amendOwners|Sort-Object)-join '|')) 'Exact erasure amendment history differs.'
   foreach($owner in $amendOwners){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$head,'--',$owner)|Out-Null}
  }
 }
 if($ProductionPhase -ceq 'pre_commit'){
  $staged=@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only'))
  Assert-Coordination ($commits.Count -eq 1 -and (@($staged|Sort-Object)-join '|') -ceq (@($amendOwners|Sort-Object)-join '|')) 'Only exact seven-owner erasure metadata amendment may commit.'
 }
 if($ProductionPhase -cin @('coordination_bootstrap','task_start')){$remote=@(Get-OctoberCompatibilityGitLines @('ls-remote','--heads','origin','refs/heads/work/codex-backend/thin-b03-20261027'));Assert-Coordination ($remote.Count -eq 1 -and ($remote[0] -split '\s+')[0] -ceq $base) 'Origin-exact sealed baseline required.'}
 if($ProductionPhase -ceq 'task_start'){Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('status','--porcelain')).Count -eq 0) 'Task start not clean.'}
 & (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -RepositoryRoot $root -StatePath $recordOwner -CandidateId THIN-B07-B04-PROFILE -RequireExecutionAuthorized
 & (Join-Path $root 'scripts/check-cross-agent-incremental-ticket-gate.ps1') -RepositoryRoot $root -Phase implementation -Lane codex_backend -TicketId THIN-B07-B04-PROFILE -UiScope assistant.profile_durable_recovery -CandidateVersionName '1.0.0-r67.11' -CandidateVersionCode 2026102707 -PackageId com.moolsocial.app.runtime -AcceptedUiCommit $base -UiContractPath $contract -UiContractSha256 $hash
 Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head
 Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head -IndexOnly
 Write-Output 'Combined B07/B04 admission passed; 34 runtime/test owners; no source feature commit/push, cloud or APK authority.'
}
