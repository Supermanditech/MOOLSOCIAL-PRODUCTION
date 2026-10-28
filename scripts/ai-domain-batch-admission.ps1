function Test-AiDomainBatchIdentity([hashtable]$Facts) {
 $exact=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-ai-domain-batch-20261028';Branch='work/codex-backend/ai-domain-batch-20261028';Lane='codex_backend';Role='primary';WorkId='ai-domain-batch-20261028';Ticket='AI-DOMAIN-BATCH-20'}
 foreach($key in $exact.Keys){if(!$Facts.ContainsKey($key) -or $Facts[$key] -isnot [string] -or $Facts[$key] -cne $exact[$key]){return $false}}
 if(!$Facts.ContainsKey('Phase') -or $Facts.Phase -cnotin @('coordination_bootstrap','pre_commit','task_start','implementation')){return $false}
 $expected=if($Facts.Phase -ceq 'coordination_bootstrap'){'/root'}else{'/root/codex_backend_ai_domain_batch'}
 return $Facts.ContainsKey('Task') -and $Facts.Task -is [string] -and $Facts.Task -ceq $expected
}
function Get-AiDomainScopeOneRuntimeOwners { @('backend/functions/src/assistant/domain_context_contract.ts','backend/functions/src/assistant/domain_context_contract.test.ts','backend/functions/src/assistant/domain_context.ts','backend/functions/src/assistant/domain_context.test.ts','backend/functions/src/assistant/domain_context_http.ts','backend/functions/src/assistant/domain_context_http.test.ts','backend/functions/src/assistant/domain_context_integration.test.ts','backend/functions/src/index.ts','apps/mobile/lib/features/assistant/domain_context_gateway.dart','apps/mobile/lib/features/assistant/profile_context.dart','apps/mobile/lib/features/journey01/journey_session.dart','apps/mobile/lib/features/journey01/review_journey_services.dart','apps/mobile/lib/app/moolsocial_app.dart','apps/mobile/lib/ui_v2/assistant/profile_context_adapter.dart','apps/mobile/lib/ui_v2/buy/buy_v2_views.dart','apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart','apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart','apps/mobile/test/assistant_domain_context_gateway_test.dart','apps/mobile/test/assistant_domain_context_guard_test.dart','apps/mobile/test/assistant_domain_context_integration_test.dart','apps/mobile/test/assistant_profile_context_test.dart','apps/mobile/test/assistant_model_flow_test.dart','apps/mobile/test/mool_assistant_test.dart','backend/functions/src/assistant/model_contract.ts','backend/functions/src/assistant/model_contract.test.ts','backend/functions/src/assistant/model_service.ts','backend/functions/src/assistant/model_service.test.ts','apps/mobile/lib/features/assistant/model_gateway.dart','apps/mobile/test/assistant_model_gateway_test.dart','apps/mobile/lib/features/assistant/mool_assistant.dart','backend/functions/src/workspace/workspace_catalogue_service.test.ts') }
function Get-AiDomainBatchRuntimeOwners {
 @(Get-AiDomainScopeOneRuntimeOwners) + @('apps/mobile/lib/features/work/work_session.dart','apps/mobile/test/work_workspace_layout_safety_test.dart')
}
function Get-AiDomainCurrentRuntimeOwners($Admission) {
 Assert-Coordination (Test-AiDomainAddressCacheAdmission $Admission) 'Exact cache admission required before admitting its original owner.'
 @(Get-AiDomainBatchRuntimeOwners) + @('apps/mobile/lib/features/buy/buy_v2_session.dart')
}
function Get-AiDomainBatchMetadataOwners { @('.gitattributes','config/codex-subagent-coordination-policy.json','config/cross-agent-incremental-ticket-gate.json','docs/quality/AI-DOMAIN-BATCH-BACKEND-20261028.json','docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','docs/quality/AI-DOMAIN-BATCH-CONTRACT-20261028.md','scripts/check-codex-subagent-coordination-policy.ps1','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1','docs/quality/AI-DOMAIN-CATALOGUE-SELECTOR-20261028.md','config/codex-development-regression-registry.json','docs/quality/AI-DOMAIN-TOOL-READ-INCIDENT-20261028.md','docs/quality/AI-DOMAIN-ORIGINAL-PROVIDER-TEST-20261028.md') }
function Get-AiDomainBatchBootstrapOwners { @('.gitattributes','config/codex-subagent-coordination-policy.json','config/cross-agent-incremental-ticket-gate.json','docs/quality/AI-DOMAIN-BATCH-BACKEND-20261028.json','docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','docs/quality/AI-DOMAIN-BATCH-CONTRACT-20261028.md','scripts/check-codex-subagent-coordination-policy.ps1','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1') }
function Get-AiDomainBatchSelectorAmendOwners { @('.gitattributes','config/codex-subagent-coordination-policy.json','docs/quality/AI-DOMAIN-BATCH-BACKEND-20261028.json','docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1','docs/quality/AI-DOMAIN-CATALOGUE-SELECTOR-20261028.md') }
function Get-AiDomainBatchRecurrenceOwners { @('config/codex-development-regression-registry.json','docs/quality/AI-DOMAIN-TOOL-READ-INCIDENT-20261028.md','config/codex-subagent-coordination-policy.json','docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1') }
function Get-AiDomainBatchProviderTestOwners { @('.gitattributes','config/codex-subagent-coordination-policy.json','docs/quality/AI-DOMAIN-BATCH-BACKEND-20261028.json','docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1','docs/quality/AI-DOMAIN-ORIGINAL-PROVIDER-TEST-20261028.md') }
function Assert-AiDomainBatchOwners([string[]]$Actual,[string[]]$Allowed){foreach($owner in $Actual){Assert-Coordination ($owner -cin $Allowed) "Combined goal unadmitted owner: $owner"}}
function Get-AiDomainScopeOneSealOwners {
 @('config/codex-subagent-coordination-policy.json',
   'docs/quality/AI-DOMAIN-BATCH-BACKEND-20261028.json',
   'docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json',
   'scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainScopeOneManifest($Manifest) {
 try {
  if ($null -eq $Manifest -or $Manifest.scope -ne 1 -or
      $Manifest.baseline -cne '7ffe45ca11be6b99cfdb8ac8a7591ef352ff2e67' -or
      $Manifest.metadataHead -cne 'cb51815990f58f548d0db2c5ca815b95a527ff07' -or
      $Manifest.branch -cne 'work/codex-backend/ai-domain-batch-20261028' -or
      @($Manifest.owners).Count -ne 31 -or @($Manifest.changedOwners).Count -ne 27 -or
      (@($Manifest.owners.path) -join '|') -cne (@(Get-AiDomainScopeOneRuntimeOwners) -join '|')) {return $false}
  $lines = @('scope01',[string]$Manifest.baseline,[string]$Manifest.metadataHead,[string]$Manifest.branch)
  foreach ($row in $Manifest.owners) {
   if ($row.bytes -le 0 -or $row.sha256 -cnotmatch '^[A-F0-9]{64}$' -or $row.gitBlobOid -cnotmatch '^[a-f0-9]{40}$') {return $false}
   $lines += ('{0}|{1}|{2}|{3}' -f $row.path,$row.bytes,$row.sha256,$row.gitBlobOid)
  }
  $lines += @($Manifest.changedOwners)
  $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))))
  return $hash -ceq '1289B9D4D5FAE75561B858744993F386C9BA22E4E3B9C81E29C7AB3F559AD60B'
 } catch {return $false}
}
function Invoke-AiDomainScopeOneCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 $provider = 'cb51815990f58f548d0db2c5ca815b95a527ff07'
 $approvalOwner = 'docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $sealOwners = @(Get-AiDomainScopeOneSealOwners)
 Assert-Coordination ($Checkpoint.sequence -eq 1 -and $Checkpoint.namedBranchPushAuthorized -eq $true -and
   $Checkpoint.productionAcceptance -eq $false -and (Test-AiDomainScopeOneManifest $Checkpoint.manifest)) 'Only the exact qualified discovery manifest is admitted.'
 Assert-Coordination ($Checkpoint.disposition.state -ceq 'partial_named_original_source_dependencies' -and
   $Checkpoint.disposition.noWholeScopeCompletionClaimed -eq $true -and
   $Checkpoint.disposition.hostEvidence.backendCombined -eq 259 -and $Checkpoint.disposition.hostEvidence.backendFailures -eq 0 -and
   $Checkpoint.disposition.hostEvidence.originalPopulatedProviderCases -eq 3 -and $Checkpoint.disposition.hostEvidence.mobile -eq 73 -and
   $Checkpoint.disposition.hostEvidence.conditionalMobileSkips -eq 10 -and $Checkpoint.disposition.hostEvidence.nativeDiscovery -eq 38 -and
   $Checkpoint.disposition.oppo.exactVmOwners -eq 10 -and $Checkpoint.disposition.oppo.savedDataUnchanged -eq $true -and
   $Checkpoint.disposition.oppo.populatedAgentRequestsVerified -eq $false) 'Qualified portions and unavailable populated-device limits must remain explicit.'
 $chain = @(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${provider}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only metadata, exact source and sanitized evidence checkpoints are authorized.'
 $subjects = @('coordination(ai-domain-batch-20261028): admit exact discovery source checkpoint',
   'feat(ai-domain-batch-20261028): connect original discovery preparation',
   'test(ai-domain-batch-20261028): record discovery qualification and dependencies')
 for ($i=0; $i -lt $chain.Count; $i++) {
  $parent = if ($i -eq 0) {$provider} else {$chain[$i-1]}
  $expected = if ($i -eq 0) {$sealOwners} elseif ($i -eq 1) {@($Checkpoint.manifest.changedOwners)} else {@($approvalOwner)}
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
    (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
    (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object) -join '|') -ceq (@($expected|Sort-Object) -join '|')) 'Checkpoint parent, subject or exact owners differ.'
 }
 if ($chain.Count -eq 0) {
  foreach ($owner in @(Get-AiDomainBatchMetadataOwners)|Where-Object {$_ -cnotin $sealOwners}) {
   Get-OctoberCompatibilityGitLines @('diff','--exit-code',$provider,'--',$owner)|Out-Null
  }
 } else {
  $sealed = ((@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))) -join "`n")|ConvertFrom-Json
  Assert-Coordination (($sealed.scope01Checkpoint.manifest|ConvertTo-Json -Depth 30 -Compress) -ceq
    ($Checkpoint.manifest|ConvertTo-Json -Depth 30 -Compress) -and
    ($sealed.scope01Checkpoint.disposition|ConvertTo-Json -Depth 30 -Compress) -ceq
    ($Checkpoint.disposition|ConvertTo-Json -Depth 30 -Compress)) 'The qualified manifest or partial disposition changed after admission.'
  foreach ($owner in @(Get-AiDomainBatchMetadataOwners)) {
   if ($Continuation) {continue}
   if ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner) {continue}
   Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
  }
 }
 if ($chain.Count -ge 2) {
  foreach ($row in $Checkpoint.manifest.owners) {
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed source differs from the qualified manifest.'
  }
  if ($chain.Count -eq 3) {Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Evidence must name the original source checkpoint.'}
 }
 if ($Phase -ceq 'pre_commit') {
  Assert-Coordination ($chain.Count -lt 3) 'No additional source/evidence commits are admitted by this checkpoint.'
  $expected = if ($chain.Count -eq 0) {$sealOwners} elseif ($chain.Count -eq 1) {@($Checkpoint.manifest.changedOwners)} else {@($approvalOwner)}
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object) -join '|') -ceq (@($expected|Sort-Object) -join '|')) 'Only the current exact checkpoint owner set may be staged.'
  if ($chain.Count -le 1) {
   foreach ($row in $Checkpoint.manifest.owners) {
    Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256) 'Working source changed after qualification.'
    if ($chain.Count -eq 1) {Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged source differs from qualification.'}
   }
  }
 }
}
function Get-AiDomainScopeTwoAdmissionOwners {
 @('config/codex-subagent-coordination-policy.json','docs/quality/AI-DOMAIN-BATCH-BACKEND-20261028.json',
   'docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1',
   'scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainScopeTwoAdmission($Admission) {
 try {
  return $null -ne $Admission -and $Admission.sequence -eq 2 -and
   $Admission.baseline -ceq '785d375a6170e585d575d57c567e17573655e02f' -and
   (@($Admission.newOwners) -join '|') -ceq 'apps/mobile/lib/features/work/work_session.dart|apps/mobile/test/work_workspace_layout_safety_test.dart' -and
   [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$Admission.contract))) -ceq '9B40D98A512DC3AFA7F4CE8000292DEFBDB1FA9650AE9DA4AB3D74BB0053C34D' -and
   $Admission.sourceFeatureCommitsAuthorized -eq $false -and $Admission.backendBranchPushAuthorized -eq $false -and
   $Admission.productionAcceptance -eq $false -and $Admission.newMasterOrMigration -eq $false
 } catch {return $false}
}
function Invoke-AiDomainScopeTwoAdmission($Admission,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainScopeTwoAdmission $Admission) 'Only exact original acknowledgement/native bridge admission is allowed.'
 $base = '785d375a6170e585d575d57c567e17573655e02f'
 $metadata = @(Get-AiDomainScopeTwoAdmissionOwners)
 $chain = @(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 1) 'Scope02 admission permits one metadata commit, not source commits or pushes.'
 if ($chain.Count -eq 0) {
  foreach ($owner in $Admission.newOwners) {Get-OctoberCompatibilityGitLines @('diff','--exit-code',$base,'--',$owner)|Out-Null}
  foreach ($owner in @(Get-AiDomainBatchMetadataOwners)|Where-Object {$_ -cnotin $metadata}) {
   Get-OctoberCompatibilityGitLines @('diff','--exit-code',$base,'--',$owner)|Out-Null
  }
 } else {
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$Head))[0]) -ceq $base -and
    (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$Head))[0]) -ceq 'coordination(ai-domain-batch-20261028): admit original product acknowledgement bridge' -and
    (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base,$Head)|Sort-Object) -join '|') -ceq (@($metadata|Sort-Object) -join '|')) 'Only the exact scope02 metadata admission may follow the clean discovery checkpoint.'
  if (!$Continuation) {foreach ($owner in @(Get-AiDomainBatchMetadataOwners)) {Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null}}
 }
 if ($Phase -ceq 'pre_commit') {
  Assert-Coordination ($chain.Count -eq 0 -and
    (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object) -join '|') -ceq (@($metadata|Sort-Object) -join '|')) 'Only exact acknowledgement-bridge metadata may be staged; source qualification is still pending.'
 }
}
function Get-AiDomainScopeTwoSealOwners { @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1') }
function Get-AiDomainScopeTwoStageOwners([int]$Count,$Checkpoint) {
 switch($Count) {0 {Get-AiDomainScopeTwoSealOwners} 1 {$Checkpoint.manifest.changedOwners} 2 {Get-AiDomainScopeTwoSealOwners} 3 {'docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'} default {@()}}
}
function Test-AiDomainScopeTwoManifest($Manifest) {
 try {
  if ($null -eq $Manifest -or $Manifest.scope -ne 2 -or
      $Manifest.baseline -cne '9aa3c913876aa53e3f3da5559b5c7b9de43d6331' -or
      $Manifest.branch -cne 'work/codex-backend/ai-domain-batch-20261028' -or
      @($Manifest.owners).Count -ne 33 -or @($Manifest.changedOwners).Count -ne 22 -or
      (@($Manifest.owners.path) -join '|') -cne (@(Get-AiDomainBatchRuntimeOwners) -join '|')) {return $false}
  $lines = @('scope02',[string]$Manifest.baseline,[string]$Manifest.branch)
  foreach ($row in $Manifest.owners) {
   if ($row.bytes -le 0 -or $row.sha256 -cnotmatch '^[A-F0-9]{64}$' -or $row.gitBlobOid -cnotmatch '^[a-f0-9]{40}$') {return $false}
   $lines += ('{0}|{1}|{2}|{3}' -f $row.path,$row.bytes,$row.sha256,$row.gitBlobOid)
  }
  $lines += @($Manifest.changedOwners)
  return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($lines -join "`n")))) -ceq '1126F62DA12DBD0FA717DB4C69303DE709B1CCDA520F4C9E5C51A2D96840C3F4'
 } catch {return $false}
}
function Invoke-AiDomainScopeTwoCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 $base='9aa3c913876aa53e3f3da5559b5c7b9de43d6331';$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $metadata=@(Get-AiDomainScopeTwoSealOwners)
 Assert-Coordination ($Checkpoint.sequence -eq 2 -and $Checkpoint.namedBranchPushAuthorized -eq $true -and
   $Checkpoint.productionAcceptance -eq $false -and (Test-AiDomainScopeTwoManifest $Checkpoint.manifest)) 'Only the exact qualified original product source manifest is admitted.'
 $d=$Checkpoint.disposition
 Assert-Coordination ($d.state -ceq 'partial_original_identity_and_private_service_dependencies' -and
   $d.noWholeScopeCompletionClaimed -eq $true -and $d.noProductionAcceptance -eq $true -and
   $d.hostEvidence.originalStore -eq 21 -and $d.hostEvidence.combinedBackend -eq 262 -and
   $d.hostEvidence.mobile -eq 92 -and $d.hostEvidence.conditionalMobileSkipped -eq 10 -and $d.hostEvidence.nativeProduct -eq 19 -and
   $d.oppo.exactVmOwners -eq 12 -and $d.oppo.savedDataUnchanged -eq $true -and $d.oppo.populatedAgentRequestsVerified -eq $false) 'Product qualification limits must remain explicit.'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 4) 'Only exact product metadata, source, metadata type correction and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit exact product source checkpoint',
   'feat(ai-domain-batch-20261028): connect original product preparation',
   'coordination(ai-domain-batch-20261028): correct product evidence stage array handling',
   'test(ai-domain-batch-20261028): record product qualification and dependencies')
 for($i=0;$i -lt $chain.Count;$i++) {
  $parent=if($i -eq 0){$base}else{$chain[$i-1]}
  $expected=@(Get-AiDomainScopeTwoStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
    (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
    (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Product checkpoint parent, subject or owners changed.'
 }
 if($chain.Count -gt 0) {
  $sealed=((@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner")))-join "`n")|ConvertFrom-Json
  Assert-Coordination (($sealed.scope02Checkpoint.manifest|ConvertTo-Json -Depth 40 -Compress) -ceq ($Checkpoint.manifest|ConvertTo-Json -Depth 40 -Compress) -and
    ($sealed.scope02Checkpoint.disposition|ConvertTo-Json -Depth 40 -Compress) -ceq ($Checkpoint.disposition|ConvertTo-Json -Depth 40 -Compress)) 'Qualified product evidence changed after admission.'
 }
 foreach($row in $Checkpoint.manifest.owners) {
  if($chain.Count -lt 2) {Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working product source differs from tested manifest.'}
  else {Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed product source differs from tested manifest.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)) {
  if($Continuation){continue}
  if(($chain.Count -cin @(0,2) -and $owner -cin $metadata) -or ($chain.Count -eq 3 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($Phase -ceq 'pre_commit') {
  $expected=@(Get-AiDomainScopeTwoStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact qualified product checkpoint owners may be staged.'
 }
}
function Get-AiDomainMiddleSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','docs/quality/AI-DOMAIN-BATCH-BACKEND-20261028.json',
   'scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Get-AiDomainMiddleStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0 {Get-AiDomainMiddleSealOwners} 1 {$Checkpoint.manifest.changedOwners} 2 {'docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'} default {@()}}
}
function Test-AiDomainMiddleManifest($Manifest) {
 try {
  if($null -eq $Manifest -or $Manifest.scope -cne '03-through07' -or
    $Manifest.baseline -cne 'e9083ed57476a51a3a50e4f1d4dbb06dd99aaea7' -or
    $Manifest.branch -cne 'work/codex-backend/ai-domain-batch-20261028' -or
    @($Manifest.owners).Count -ne 33 -or @($Manifest.changedOwners).Count -ne 21 -or
    (@($Manifest.owners.path)-join '|') -cne (@(Get-AiDomainBatchRuntimeOwners)-join '|')){return $false}
  $lines=@('scope03-through07',[string]$Manifest.baseline,[string]$Manifest.branch)
  foreach($row in $Manifest.owners){
   if($row.bytes -le 0 -or $row.sha256 -cnotmatch '^[A-F0-9]{64}$' -or $row.gitBlobOid -cnotmatch '^[a-f0-9]{40}$'){return $false}
   $lines+=('{0}|{1}|{2}|{3}' -f $row.path,$row.bytes,$row.sha256,$row.gitBlobOid)
  }
  $lines+=@($Manifest.changedOwners)
  $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($lines-join "`n"))))
  return $hash -ceq '5D6CB7245B2189B39610EEE7739E1D542F545908084F519AD38C832DB93F91AF' -and $Manifest.identitySha256 -ceq $hash
 }catch{return $false}
}
function Test-AiDomainMiddleCheckpoint($Checkpoint) {
 try {
  return $null -ne $Checkpoint -and $Checkpoint.sequence -ceq '03-through07' -and
   $Checkpoint.baseline -ceq 'e9083ed57476a51a3a50e4f1d4dbb06dd99aaea7' -and
   $Checkpoint.namedBranchPushAuthorized -eq $true -and $Checkpoint.productionAcceptance -eq $false -and
   (Test-AiDomainMiddleManifest $Checkpoint.manifest) -and
   [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($Checkpoint.disposition|ConvertTo-Json -Depth 40 -Compress)))) -ceq '163300F88FC0EC94A91E4A40FC90641A039DA4205F2DEE31DFED613689C47227' -and
   [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($Checkpoint.evidence|ConvertTo-Json -Depth 20 -Compress)))) -ceq '2027583CBB86F5F31189AC265E58BC770C279E3D894BC4D2D3C77B7BDB9C366E'
 }catch{return $false}
}
function Invoke-AiDomainMiddleCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 $base='e9083ed57476a51a3a50e4f1d4dbb06dd99aaea7';$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 Assert-Coordination (Test-AiDomainMiddleCheckpoint $Checkpoint) 'Only the exact tested partial integration/recovery checkpoint is admitted.'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact middle-checkpoint metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit exact partial integration checkpoint',
   'feat(ai-domain-batch-20261028): connect original product stock restock and cart reviews',
   'test(ai-domain-batch-20261028): record partial integration qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainMiddleStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Middle checkpoint parent, subject or exact staged owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=((@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner")))-join "`n")|ConvertFrom-Json
  Assert-Coordination (($sealed.scope03Through07Checkpoint.manifest|ConvertTo-Json -Depth 40 -Compress) -ceq ($Checkpoint.manifest|ConvertTo-Json -Depth 40 -Compress) -and
   ($sealed.scope03Through07Checkpoint.disposition|ConvertTo-Json -Depth 40 -Compress) -ceq ($Checkpoint.disposition|ConvertTo-Json -Depth 40 -Compress)) 'Qualified middle source or partial dispositions changed after admission.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working middle source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed middle source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainMiddleSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3){Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Middle evidence must name the original qualified source commit.'}
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainMiddleStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only the exact middle-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged middle source differs from qualification.'
  }}
 }
}
function Get-AiDomainAddressCacheAdmissionOwners {
 @('config/codex-subagent-coordination-policy.json','docs/quality/AI-DOMAIN-BATCH-BACKEND-20261028.json',
   'docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainAddressCacheAdmission($Admission) {
 if($null -eq $Admission -or $Admission.sequence -cne '07-address-cache' -or
   $Admission.baseline -cne '1e34cdf9a2f643920b5cb9c421becb3e3f667080' -or
   (@($Admission.newOwners)-join '|') -cne 'apps/mobile/lib/features/buy/buy_v2_session.dart' -or
   $Admission.contractSha256 -cne '3FBF2343E201F542BAB65B2BC395820E4B261DD747CA1919FD32905468D3F17A' -or
   $Admission.contract -isnot [string]){return $false}
 $contractHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Admission.contract)))
 if($contractHash -cne $Admission.contractSha256 -or
   $Admission.unchangedOwner.path -cne $Admission.newOwners[0] -or
   $Admission.unchangedOwner.bytes -ne 863064 -or
   $Admission.unchangedOwner.sha256 -cne '7447F305311647689F6BC9AE6EAD6C76B8E152A93B78A772840390B1260FF1F3' -or
   $Admission.unchangedOwner.gitBlobOid -cne '3a858b6bb4f4569ad18adcc69236293e5a2c797c'){return $false}
 foreach($flag in @('sourceFeatureCommitsAuthorized','backendBranchPushAuthorized','productionAcceptance','newMasterOrMigration')){
  if($Admission.$flag -isnot [bool] -or $Admission.$flag){return $false}
 }
 return $true
}
function Invoke-AiDomainAddressCacheAdmission($Admission,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainAddressCacheAdmission $Admission) 'Only the exact original address-cache coherence admission is permitted.'
 $base=$Admission.baseline;$allowed=@(Get-AiDomainAddressCacheAdmissionOwners)
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 1) 'No address-cache source or evidence commit has been admitted yet.'
 if($chain.Count -eq 0){
  foreach($owner in @(Get-AiDomainCurrentRuntimeOwners $Admission)){
   Get-OctoberCompatibilityGitLines @('diff','--exit-code',$base,'--',$owner)|Out-Null
  }
  Assert-Coordination ((Get-Sha256 (Join-Path $root $Admission.unchangedOwner.path)) -ceq $Admission.unchangedOwner.sha256) 'Original Buy cache owner changed before clean admission.'
 }else{
  $commit=$chain[0]
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$commit))[0]) -ceq $base -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$commit))[0]) -ceq 'coordination(ai-domain-batch-20261028): admit original address cache coherence owner' -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base,$commit)|Sort-Object)-join '|') -ceq (@($allowed|Sort-Object)-join '|')) 'Address-cache admission parent, subject or exact owners changed.'
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"${commit}:$($Admission.unchangedOwner.path)"))[0]) -ceq $Admission.unchangedOwner.gitBlobOid) 'Admission must preserve original Buy source.'
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"${commit}:docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (($sealed.scope07AddressCacheAdmission|ConvertTo-Json -Depth 20 -Compress) -ceq ($Admission|ConvertTo-Json -Depth 20 -Compress)) 'Sealed cache admission changed.'
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if($chain.Count -eq 0 -and $owner -cin $allowed){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  Assert-Coordination ($chain.Count -eq 0 -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($allowed|Sort-Object)-join '|')) 'Only the exact five-file cache admission metadata commit is permitted.'
 }
}
function Get-AiDomainAddressCacheSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainAddressCacheCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '07-cache-source' -or
   $Checkpoint.baseline -cne 'd6b95fba5666f7c6abf6bad4dd2d0c344f6c7483' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='49084BE4F9BD3DD05808EECBE1366B69303B312BED9385B3516515E7A4F64EEA';
   disposition='20CAD9FEAC2423632FE22CE009CCA6EBBC4408EDAD3424947DAF9FDB9F8C2F5F';
   evidence='F1EB01B2673C8049645035FD5D75B10D5CCB2CED761F8B31442A9A85372D2623'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainAddressCacheStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainAddressCacheSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainAddressCacheCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainAddressCacheCheckpoint $Checkpoint) 'Only the exact tested four-owner address fix checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact address-cache metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified address cache checkpoint',
   'fix(ai-domain-batch-20261028): preserve original address coherence and review tokens',
   'test(ai-domain-batch-20261028): record address handoff qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainAddressCacheStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Address checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainAddressCacheCheckpoint $sealed.scope07AddressCacheCheckpoint) 'Committed address qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working address source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed address source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainAddressCacheSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Address evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainAddressCacheStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact address-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged address source differs from qualification.'
  }}
 }
}
function Get-AiDomainOrderOriginalSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainOrderOriginalCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '09-original-source' -or
   $Checkpoint.baseline -cne '9bea89409b1c1258929e172a6d3b4bbcc385a384' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='511DA15EAC0F7E31156635EF5EADE8BE667FC4738C4CB19CD961843D0728FC27';
   disposition='EC3A964738A323FBC969ECE8351D1204E95D2197B084E08D014EBB7FA0F49770';
   evidence='69A389D6B980E0D79A85B4CD2B3BF8C5ED690D0005EB2CF08CB7898433E328A9'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainOrderOriginalStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainOrderOriginalSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainOrderOriginalCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainOrderOriginalCheckpoint $Checkpoint) 'Only the exact tested twelve-owner original order checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact original-order metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original order checkpoint',
   'feat(ai-domain-batch-20261028): connect authenticated original order review',
   'test(ai-domain-batch-20261028): record original order qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainOrderOriginalStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Original-order checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainOrderOriginalCheckpoint $sealed.scope09OrderOriginalCheckpoint) 'Committed original-order qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working original-order source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed original-order source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainOrderOriginalSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Original-order evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainOrderOriginalStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact original-order-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged original-order source differs from qualification.'
  }}
 }
}
function Get-AiDomainPrivateStarsSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainPrivateStarsCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '10-private-stars-source' -or
   $Checkpoint.baseline -cne '47a64270dbd603c09ee0c0e8b908616332093187' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='1BED3780E494261AA899694D27C4BA5AC6169E9B8D72DD8B63BEB593D00AB02D';
   disposition='9D923EDD78393842B31BA207766099A9DF9EE9656894072886337D4B43589C08';
   evidence='FC4A6D6E08B208F2F80F079BA92BBF1F627E5A5FB0824EA48F4807FC5E231304'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainPrivateStarsStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainPrivateStarsSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainPrivateStarsCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainPrivateStarsCheckpoint $Checkpoint) 'Only the exact tested twelve-owner private rating checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact private-rating metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified private rating checkpoint',
   'feat(ai-domain-batch-20261028): connect original private purchased rating review',
   'test(ai-domain-batch-20261028): record private rating source and native qualification')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainPrivateStarsStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Private-rating checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainPrivateStarsCheckpoint $sealed.scope10PrivateStarsCheckpoint) 'Committed private-rating qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working private-rating source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed private-rating source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainPrivateStarsSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Private-rating evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainPrivateStarsStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact private-rating-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged private-rating source differs from qualification.'
  }}
 }
}
function Get-AiDomainSupplierDraftSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainSupplierDraftCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '11-supplier-draft-source' -or
   $Checkpoint.baseline -cne 'be023a1fe2a3ec3a79b0f436669bb498f5923d9f' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='20B965DF9A9C8D3666E39F57810FF18983334BF5B1B493747080B55C1E5F61F4';
   disposition='C87C32F746CA148A4A87DBA9B51F65C30D6E5E068D9713A59944782C42804F99';
   evidence='294F305711767CD11423A4EE3A0C7ED7EB037D62D91F3B8FC887D71D6F192D50'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainSupplierDraftStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainSupplierDraftSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainSupplierDraftCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainSupplierDraftCheckpoint $Checkpoint) 'Only the exact tested seven-owner supplier draft checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact supplier-draft metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified supplier draft checkpoint',
   'feat(ai-domain-batch-20261028): connect owned supplier drafts and search',
   'test(ai-domain-batch-20261028): record supplier draft qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainSupplierDraftStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Supplier-draft checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainSupplierDraftCheckpoint $sealed.scope11SupplierDraftCheckpoint) 'Committed supplier-draft qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working supplier-draft source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed supplier-draft source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainSupplierDraftSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Supplier-draft evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainSupplierDraftStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact supplier-draft-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged supplier-draft source differs from qualification.'
  }}
 }
}
function Get-AiDomainPurchaseRootSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainPurchaseRootCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '12-purchase-root-source' -or
   $Checkpoint.baseline -cne '910c6187b04ad4e6b13269a54c9c423d4fce7328' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='EFA2BA11DEBE5977B24FB25FC33CE017DCA064632CF05259BA443D6385B7E0BD';
   disposition='86B22BDB2CA58B2B73AAB830321421149F54F335BC22A3790CC2AE7753142133';
   evidence='B61952656D3FBF5EA8E585FDEDF98DF5A4340C9154D5FEC284D58985F03817EC'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainPurchaseRootStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainPurchaseRootSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainPurchaseRootCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainPurchaseRootCheckpoint $Checkpoint) 'Only the exact tested eight-owner purchase root checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact purchase-root metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified purchase root checkpoint',
   'feat(ai-domain-batch-20261028): connect purchase register roots and stable native reviews',
   'test(ai-domain-batch-20261028): record purchase root qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainPurchaseRootStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Purchase-root checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainPurchaseRootCheckpoint $sealed.scope12PurchaseRootCheckpoint) 'Committed purchase-root qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working purchase-root source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed purchase-root source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainPurchaseRootSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Purchase-root evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainPurchaseRootStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact purchase-root-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged purchase-root source differs from qualification.'
  }}
 }
}
function Get-AiDomainOriginalReceivingSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainOriginalReceivingCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '13-original-receiving-source' -or
   $Checkpoint.baseline -cne '49ed91d5df56976e7e8630daa342a28a8ee4acd0' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='FBA5856D125618D394184AF1EE2086EA8E8A6686EFA9D18F9CC8AF73A9137AA1';
   disposition='BE8D6F426A1C50D8EF961706A54ACBBE7A899AE5527F234A4B55C2744D182975';
   evidence='661F800ACEFCDCAF8353BF2D7D24617645E6C0432BF5ABB2D487AE77CED2FF92'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainOriginalReceivingStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainOriginalReceivingSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainOriginalReceivingCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainOriginalReceivingCheckpoint $Checkpoint) 'Only the exact tested thirteen-owner original receiving checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact original-receiving metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original receiving checkpoint',
   'feat(ai-domain-batch-20261028): connect original receiving source and native review',
   'test(ai-domain-batch-20261028): record original receiving qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainOriginalReceivingStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Original-receiving checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainOriginalReceivingCheckpoint $sealed.scope13OriginalReceivingCheckpoint) 'Committed original-receiving qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working original-receiving source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed original-receiving source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainOriginalReceivingSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Original-receiving evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainOriginalReceivingStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact original-receiving-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged original-receiving source differs from qualification.'
  }}
 }
}
function Get-AiDomainStoreOperationsSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainStoreOperationsCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '17-original-operational-source' -or
   $Checkpoint.baseline -cne '6651c66950e25abb7bf3e9b8e65625a342ca6de3' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='527F171A1E23AD3AD50579AF6DEEB6ED1F9C8C06C08C89CF9838BB5EEFE3D6EB';
   disposition='D614498198EF1F6DF01C52FCB9E1D9BD44534F4556C48D96271887D190EC1E4F';
   evidence='6535A9E073DAB66A9C45F88AA0EFD1E4D50B1140D507A5B66D176BA1B29752EE'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainStoreOperationsStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainStoreOperationsSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainStoreOperationsCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainStoreOperationsCheckpoint $Checkpoint) 'Only the exact tested fourteen-owner original order operational checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact original-operational metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original order operational checkpoint',
   'feat(ai-domain-batch-20261028): connect original order operational source and native review',
   'test(ai-domain-batch-20261028): record original order operational qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainStoreOperationsStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Original-operational checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainStoreOperationsCheckpoint $sealed.scope17StoreOperationsCheckpoint) 'Committed original-operational qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working original-operational source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed original-operational source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainStoreOperationsSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Original-operational evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainStoreOperationsStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact original-operational-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged original-operational source differs from qualification.'
  }}
 }
}
function Get-AiDomainStoreCouponsSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainStoreCouponsCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '18-original-coupon-source' -or
   $Checkpoint.baseline -cne '06a1abc4a04424d4a07a5d8117fe3f64a80bff75' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='A9FC424D72E0341D223D7DE730F447F3379A9582911E1D7FCE0E033E11F4BD8A';
   disposition='B9279F734BE05260A1E79A5F3009FC40619EDDD532944A6633FBC51022BA0FD9';
   evidence='B7A6149D2DEE6D46BF9B8827921235CD97F3E159F9590E8AD109E25D509F599C'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainStoreCouponsStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainStoreCouponsSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainStoreCouponsCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainStoreCouponsCheckpoint $Checkpoint) 'Only the exact tested twelve-owner original Store coupon checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact original-coupon metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original Store coupon checkpoint',
   'feat(ai-domain-batch-20261028): connect original Store coupon source and native review',
   'test(ai-domain-batch-20261028): record original Store coupon qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainStoreCouponsStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Original-coupon checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainStoreCouponsCheckpoint $sealed.scope18StoreCouponsCheckpoint) 'Committed original-coupon qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working original-coupon source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed original-coupon source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainStoreCouponsSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Original-coupon evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainStoreCouponsStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact original-coupon-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged original-coupon source differs from qualification.'
  }}
 }
}
function Get-AiDomainStoreReportsSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainStoreReportsCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '19-original-report-controls' -or
   $Checkpoint.baseline -cne '27302f4b5cf70f7b6aa78ec50301e71d143ee094' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='3154DAA8961FD33B5ED489EC227A8BDCE247DBB7DE8F018BEA247F00D2450645';
   disposition='F227BA0CC94303FEAC9BB5F1DF35D7CAB7E81B3D58254F3FC112AE2D4AEDD1DE';
   evidence='0CC77AB9083118F53F2DC8538EC744515E305F5D957B7E63B17CD909FBD8159B'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainStoreReportsStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainStoreReportsSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainStoreReportsCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainStoreReportsCheckpoint $Checkpoint) 'Only the exact tested ten-owner original Store report control checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact original-report-controls metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original Store report control checkpoint',
   'feat(ai-domain-batch-20261028): connect original Store report control source and native review',
   'test(ai-domain-batch-20261028): record original Store report control qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainStoreReportsStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Original-coupon checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainStoreReportsCheckpoint $sealed.scope19StoreReportsCheckpoint) 'Committed original-report-controls qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working original-report-controls source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed original-report-controls source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainStoreReportsSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Original-coupon evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainStoreReportsStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact original-report-controls-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged original-report-controls source differs from qualification.'
  }}
 }
}
function Get-AiDomainStoreSettingsSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainStoreSettingsCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '20-original-store-details' -or
   $Checkpoint.baseline -cne 'c05393e6cd24fd100fd3fb342d61c30a1389e3e6' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='14FC89DE89EA68100EAEB22BBBA49DB4DBD4ED4A745020954B2A9CBC9057B7F3';
   disposition='FDA282446291FFC901C0AF184940339F20F5C66C0A15E7046CE7011B059339B8';
   evidence='CFF43F09BFB34F2B5259393914C6C30A20EC1115B3F5DF57635BE042C8851004'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainStoreSettingsStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainStoreSettingsSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainStoreSettingsCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainStoreSettingsCheckpoint $Checkpoint) 'Only the exact tested ten-owner original Store public details checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact original-store-details metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original Store public details checkpoint',
   'feat(ai-domain-batch-20261028): connect original Store public details source and native review',
   'test(ai-domain-batch-20261028): record original Store public details qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainStoreSettingsStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Original-store-details checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainStoreSettingsCheckpoint $sealed.scope20StoreSettingsCheckpoint) 'Committed original-store-details qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working original-store-details source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed original-store-details source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainStoreSettingsSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Original-store-details evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainStoreSettingsStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact original-store-details-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged original-store-details source differs from qualification.'
  }}
 }
}
function Get-AiDomainStorePublicationReadySealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainStorePublicationReadyCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '20-publication-ready-correction' -or
   $Checkpoint.baseline -cne '1bf093d0a7c6c3764189204fa609335f764650f2' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='F64D6B761BFCFEF329052BA2983F8194A3D8E275608CB7944E51A865A9651DD4';
   disposition='6C6445AE2034BCE084B57B2D9F555929513F2B5AEA90B8E79F7DC2C8C42F4E62';
   evidence='3006CCE11837AE440AC8642487C9CE9EA07F7FC373C0E4F4F9D1DB96925D1E9F'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainStorePublicationReadyStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainStorePublicationReadySealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainStorePublicationReadyCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainStorePublicationReadyCheckpoint $Checkpoint) 'Only the exact tested two-owner original Store publication readiness checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact publication-ready metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original Store publication readiness checkpoint',
   'feat(ai-domain-batch-20261028): require saved original details before publication review',
   'test(ai-domain-batch-20261028): record original Store publication readiness qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainStorePublicationReadyStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Publication-ready checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainStorePublicationReadyCheckpoint $sealed.scope20PublicationReadyCheckpoint) 'Committed publication-ready qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working publication-ready source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed publication-ready source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainStorePublicationReadySealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Publication-ready evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainStorePublicationReadyStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact publication-ready-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged publication-ready source differs from qualification.'
  }}
 }
}
function Get-AiDomainPurchaseReferenceSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainPurchaseReferenceCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '05-original-purchase-reference' -or
   $Checkpoint.baseline -cne 'd67c3815c322eae562f6e00518712e3c204b1cec' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='761FC63DE52B357B43D4EA43DA54522F8A519CDEF148CD26323EE6B72E18D87C';
   disposition='148EDF914D59BF63851C28242E4B08D0C309FB13D1930F9FED8C64A6FD272F36';
   evidence='A3773CE8782DF2A46C242F6EEB85E24B2A1D117C444B3490A8F74671026FF847'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainPurchaseReferenceStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainPurchaseReferenceSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainPurchaseReferenceCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainPurchaseReferenceCheckpoint $Checkpoint) 'Only the exact tested four-owner original purchase reference checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact purchase-reference metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original purchase reference checkpoint',
   'feat(ai-domain-batch-20261028): connect original account owned purchase reference preparation',
   'test(ai-domain-batch-20261028): record original purchase reference qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainPurchaseReferenceStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Purchase-reference checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainPurchaseReferenceCheckpoint $sealed.scope05PurchaseReferenceCheckpoint) 'Committed purchase-reference qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working purchase-reference source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed purchase-reference source differs from qualification.'}
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainPurchaseReferenceSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Purchase-reference evidence must name its qualified source commit before closure.'
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  $expected=@(Get-AiDomainPurchaseReferenceStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact purchase-reference-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged purchase-reference source differs from qualification.'
  }}
 }
}
function Get-AiDomainCartClearSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainCartClearCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '06-original-cart-clear' -or
   $Checkpoint.baseline -cne 'af51db32eae8bbe483f660ac97c9e443c96b3356' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='A72C2BE166D26E35147FD2ACDAB3F6DF94BAB721607D435F67B0F1C11275CD0B';
   disposition='070A2C045B14F3139D575583E73094B6509BA9187E28417F4E6BD3E8513BB3BA';
   evidence='60A7A2BCDF42E74807E8F0EDABB11AD83FD562EC28D41B9710712DB774317035'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainCartClearStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainCartClearSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainCartClearCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainCartClearCheckpoint $Checkpoint) 'Only the exact tested four-owner original Cart clearing checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact cart-clear metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original Cart clearing checkpoint',
   'feat(ai-domain-batch-20261028): connect original account owned Cart clearing confirmation',
   'test(ai-domain-batch-20261028): record original Cart clearing qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainCartClearStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Cart-clear checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainCartClearCheckpoint $sealed.scope06CartClearCheckpoint) 'Committed cart-clear qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working cart-clear source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed cart-clear source differs from qualification.'}
 }
 if(!$Continuation){foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainCartClearSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Cart-clear evidence must name its qualified source commit before closure.'
 }
 if(!$Continuation -and $Phase -ceq 'pre_commit'){
  $expected=@(Get-AiDomainCartClearStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact cart-clear-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged cart-clear source differs from qualification.'
  }}
 }
}
function Get-AiDomainRetainedQuoteSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainRetainedQuoteCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '05-original-retained-supplier-quotes' -or
   $Checkpoint.baseline -cne 'a08d70baaaddb0bab76ea5df1bd917509941d3dd' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='5F5DBBB44613E1E7016BCE8DB3934F981F8206E6BF83199C1D07A87F8BA1A68A';
   disposition='5E32207ADBC505088946D0CDA1EEFDC8C35D023F73ED40F949233909ABD44538';
   evidence='208ED871553BF46F8EB1D2A542A668D13C7F375F121E4EE9EA01D339EB76A384'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainRetainedQuoteStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainRetainedQuoteSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainRetainedQuoteCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainRetainedQuoteCheckpoint $Checkpoint) 'Only the exact tested eleven-owner original retained quote checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact retained-quote metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original retained supplier quote checkpoint',
   'feat(ai-domain-batch-20261028): connect original retained supplier quote native handoff',
   'test(ai-domain-batch-20261028): record original retained supplier quote qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainRetainedQuoteStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Retained-quote checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainRetainedQuoteCheckpoint $sealed.scope05RetainedQuoteCheckpoint) 'Committed retained-quote qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working retained-quote source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed retained-quote source differs from qualification.'}
 }
 if(!$Continuation){foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainRetainedQuoteSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Retained-quote evidence must name its qualified source commit before closure.'
 }
 if(!$Continuation -and $Phase -ceq 'pre_commit'){
  $expected=@(Get-AiDomainRetainedQuoteStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact retained-quote-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged retained-quote source differs from qualification.'
  }}
 }
}
function Get-AiDomainSelectedRestockSealOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainSelectedRestockCheckpoint($Checkpoint) {
 if($null -eq $Checkpoint -or $Checkpoint.sequence -cne '05-original-selected-store-restock' -or
   $Checkpoint.baseline -cne 'fa6fe53f803a3ec63871a7253a48a23c44544d85' -or
   $Checkpoint.namedBranchPushAuthorized -isnot [bool] -or !$Checkpoint.namedBranchPushAuthorized -or
   $Checkpoint.productionAcceptance -isnot [bool] -or $Checkpoint.productionAcceptance){return $false}
 $pins=@{manifest='F362913CBCC68DBEF760255ADC1582E6DCAFC03DD663B4574138E3C947BF2F5A';
   disposition='60C560B4EC02E776AD499447E080E3411ADDD4F35853FECDA569CB6BB976A20D';
   evidence='7E5CD6D2FDE9D5878A0BC4E9F872C8C176225A5F4D3EF66E2B102D346C4EDC78'}
 foreach($part in $pins.Keys){
  $raw=$Checkpoint.$part|ConvertTo-Json -Depth 60 -Compress
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -cne $pins[$part]){return $false}
 }
 return $true
}
function Get-AiDomainSelectedRestockStageOwners([int]$Count,$Checkpoint) {
 switch($Count){0{@(Get-AiDomainSelectedRestockSealOwners)}1{@($Checkpoint.manifest.changedOwners)}2{@('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')}default{@()}}
}
function Invoke-AiDomainSelectedRestockCheckpoint($Checkpoint,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainSelectedRestockCheckpoint $Checkpoint) 'Only the exact tested nine-owner original selected Restock checkpoint is admitted.'
 $base=$Checkpoint.baseline;$approvalOwner='docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json'
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 3) 'Only exact selected-restock metadata, source and evidence commits are admitted.'
 $subjects=@('coordination(ai-domain-batch-20261028): admit qualified original selected Store Restock checkpoint',
   'feat(ai-domain-batch-20261028): connect original selected Store Restock native handoff',
   'test(ai-domain-batch-20261028): record original selected Store Restock qualification and limits')
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]};$expected=@(Get-AiDomainSelectedRestockStageOwners $i $Checkpoint)
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Selected-Restock checkpoint parent, subject or exact owners changed.'
 }
 if($chain.Count -gt 0){
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):$approvalOwner"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainSelectedRestockCheckpoint $sealed.scope05SelectedRestockCheckpoint) 'Committed selected-restock qualification changed.'
 }
 foreach($row in $Checkpoint.manifest.owners){
  if($chain.Count -lt 2){Assert-Coordination ((Get-Sha256 (Join-Path $root $row.path)) -ceq $row.sha256 -and
    (@(Get-OctoberCompatibilityGitLines @('hash-object',"--path=$($row.path)",$row.path))[0]) -ceq $row.gitBlobOid) 'Working selected-restock source differs from qualification.'}
  else{Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[1]):$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Committed selected-restock source differs from qualification.'}
 }
 if(!$Continuation){foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if(($chain.Count -eq 0 -and $owner -cin @(Get-AiDomainSelectedRestockSealOwners)) -or
    ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit' -and $owner -ceq $approvalOwner)){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 }
 if($chain.Count -eq 3 -or ($chain.Count -eq 2 -and $Phase -ceq 'pre_commit')){
  Assert-Coordination ($Checkpoint.sourceCommit -ceq $chain[1]) 'Selected-Restock evidence must name its qualified source commit before closure.'
 }
 if(!$Continuation -and $Phase -ceq 'pre_commit'){
  $expected=@(Get-AiDomainSelectedRestockStageOwners $chain.Count $Checkpoint)
  Assert-Coordination ($expected.Count -gt 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($expected|Sort-Object)-join '|')) 'Only exact selected-restock-checkpoint stage may be committed.'
  if($chain.Count -eq 1){foreach($row in $Checkpoint.manifest.owners){
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',":$($row.path)"))[0]) -ceq $row.gitBlobOid) 'Staged selected-restock source differs from qualification.'
  }}
 }
}
function Test-AiDomainPrivateStarsTestAdmission($Admission) {
 if($null -eq $Admission){return $false}
 $raw=$Admission|ConvertTo-Json -Depth 20 -Compress
 return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw))) -ceq '19136B3CF97288DDB8ABA9DE0D62872A87400B3C1928E258A9F4E416055DFA50'
}
function Get-AiDomainPrivateStarsRuntimeOwners($Admission,$Cache) {
 Assert-Coordination (Test-AiDomainPrivateStarsTestAdmission $Admission) 'Exact existing Buy test admission required.'
 @(Get-AiDomainCurrentRuntimeOwners $Cache)+@($Admission.newOwners)
}
function Invoke-AiDomainPrivateStarsTestAdmission($Admission,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainPrivateStarsTestAdmission $Admission) 'Only the exact existing native055 test owner is admitted.'
 $base=$Admission.baseline;$allowed=@(Get-AiDomainAddressCacheAdmissionOwners)
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -le 1) 'Only one exact native055 test admission metadata commit is admitted.'
 if($chain.Count -eq 0){
  Assert-Coordination ((Get-Sha256 (Join-Path $root $Admission.unchangedOwner.path)) -ceq $Admission.unchangedOwner.sha256) 'Native055 admission must preserve the existing test.'
 }else{
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[0]))[0]) -ceq $base -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[0]))[0]) -ceq 'coordination(ai-domain-batch-20261028): admit existing private stars native test owner' -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base,$chain[0])|Sort-Object)-join '|') -ceq (@($allowed|Sort-Object)-join '|')) 'Native055 admission parent, subject or owners changed.'
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('rev-parse',"$($chain[0]):$($Admission.unchangedOwner.path)"))[0]) -ceq $Admission.unchangedOwner.gitBlobOid) 'Native055 admission changed the original test source.'
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[0]):docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainPrivateStarsTestAdmission $sealed.scope10PrivateStarsTestAdmission) 'Committed native055 test admission changed.'
 }
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if($chain.Count -eq 0 -and $owner -cin $allowed){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if($Phase -ceq 'pre_commit' -and !$Continuation){
  Assert-Coordination ($chain.Count -eq 0 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($allowed|Sort-Object)-join '|')) 'Only exact five-file native055 test admission may be committed.'
 }
}

function Get-AiDomainQuoteRecurrenceAdmissionOwners {
 @('docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json','config/codex-development-regression-registry.json','scripts/ai-domain-batch-admission.ps1','scripts/test-ai-domain-batch-admission.ps1')
}
function Test-AiDomainQuoteRecurrenceAdmission($Admission,[switch]$Historical) {
 if($null -eq $Admission){return $false}
 $raw=$Admission|ConvertTo-Json -Depth 60 -Compress
 $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($raw)))
 return $hash -ceq 'E91BEB4632C544C0E61D7B23105A060DE2CB0F3D64B4A738415C04C15E17A05F' -or
   ($Historical -and $hash -ceq '4AEA64EC6CB51D0CEDE173ADD33FD8C69943C871FC08B4F474C04DA2EC573C38')
}
function Invoke-AiDomainQuoteRecurrenceAdmission($Admission,[string]$Head,[string]$Phase,[switch]$Continuation) {
 Assert-Coordination (Test-AiDomainQuoteRecurrenceAdmission $Admission) 'Exact corrected existing regression recurrence admission required.'
 $base=$Admission.baseline;$allowed=@(Get-AiDomainQuoteRecurrenceAdmissionOwners)
 $chain=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"${base}..${Head}"))
 Assert-Coordination ($chain.Count -ge 1 -and $chain.Count -le 2) 'Only exact registered recurrence and literal evidence-path correction admitted.'
 $subjects=@($Admission.metadataCommitSubject,$Admission.evidencePathCorrection.metadataCommitSubject)
 for($i=0;$i -lt $chain.Count;$i++){
  $parent=if($i -eq 0){$base}else{$chain[$i-1]}
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$chain[$i]))[0]) -ceq $parent -and
   (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$chain[$i]))[0]) -ceq $subjects[$i] -and
   (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$chain[$i])|Sort-Object)-join '|') -ceq (@($allowed|Sort-Object)-join '|')) 'Recurrence/correction parent, subject or exact owners changed.'
  $sealed=(@(Get-OctoberCompatibilityGitLines @('show',"$($chain[$i]):docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json"))-join "`n")|ConvertFrom-Json
  Assert-Coordination (Test-AiDomainQuoteRecurrenceAdmission $sealed.quoteImplementationRecurrence20261029 -Historical:($i -eq 0)) 'Committed recurrence admission changed.'
 }
 Assert-Coordination ((Get-Sha256 (Join-Path $root 'config/codex-development-regression-registry.json')) -ceq $Admission.registryAfterSha256) 'Registered recurrence bytes changed.'
 foreach($owner in @(Get-AiDomainBatchMetadataOwners)){
  if($Continuation){continue}
  if($chain.Count -eq 1 -and $owner -cin $allowed){continue}
  Get-OctoberCompatibilityGitLines @('diff','--exit-code',$Head,'--',$owner)|Out-Null
 }
 if(!$Continuation -and $Phase -ceq 'pre_commit'){
  Assert-Coordination ($chain.Count -eq 1 -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@($allowed|Sort-Object)-join '|')) 'Only exact recurrence evidence-path metadata correction may be committed.'
 }
}

function Invoke-AiDomainBatchAdmission {
 $base='7ffe45ca11be6b99cfdb8ac8a7591ef352ff2e67';$contract='docs/quality/AI-DOMAIN-BATCH-CONTRACT-20261028.md';$hash='9FCD190B22B9725CBE1BF2107708D6D2BE11E226CD606E218FD8B94D3A420382';$recordOwner='docs/quality/AI-DOMAIN-BATCH-BACKEND-20261028.json'
 $approval=Get-Content -Raw (Join-Path $root 'docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')|ConvertFrom-Json
 $cache=if($approval.PSObject.Properties.Name -ccontains 'scope07AddressCacheAdmission'){$approval.scope07AddressCacheAdmission}else{$null}
 $cacheCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope07AddressCacheCheckpoint'){$approval.scope07AddressCacheCheckpoint}else{$null}
 $orderCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope09OrderOriginalCheckpoint'){$approval.scope09OrderOriginalCheckpoint}else{$null}
 $privateStarsAdmission=if($approval.PSObject.Properties.Name -ccontains 'scope10PrivateStarsTestAdmission'){$approval.scope10PrivateStarsTestAdmission}else{$null}
 $privateStarsCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope10PrivateStarsCheckpoint'){$approval.scope10PrivateStarsCheckpoint}else{$null}
 $supplierDraftCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope11SupplierDraftCheckpoint'){$approval.scope11SupplierDraftCheckpoint}else{$null}
 $purchaseRootCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope12PurchaseRootCheckpoint'){$approval.scope12PurchaseRootCheckpoint}else{$null}
 $originalReceivingCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope13OriginalReceivingCheckpoint'){$approval.scope13OriginalReceivingCheckpoint}else{$null}
 $storeOperationsCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope17StoreOperationsCheckpoint'){$approval.scope17StoreOperationsCheckpoint}else{$null}
 $storeCouponsCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope18StoreCouponsCheckpoint'){$approval.scope18StoreCouponsCheckpoint}else{$null}
 $storeReportsCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope19StoreReportsCheckpoint'){$approval.scope19StoreReportsCheckpoint}else{$null}
 $storeSettingsCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope20StoreSettingsCheckpoint'){$approval.scope20StoreSettingsCheckpoint}else{$null}
 $publicationReadyCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope20PublicationReadyCheckpoint'){$approval.scope20PublicationReadyCheckpoint}else{$null}
 $purchaseReferenceCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope05PurchaseReferenceCheckpoint'){$approval.scope05PurchaseReferenceCheckpoint}else{$null}
 $cartClearCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope06CartClearCheckpoint'){$approval.scope06CartClearCheckpoint}else{$null}
 $quoteRecurrence=if($approval.PSObject.Properties.Name -ccontains 'quoteImplementationRecurrence20261029'){$approval.quoteImplementationRecurrence20261029}else{$null}
 $retainedQuoteCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope05RetainedQuoteCheckpoint'){$approval.scope05RetainedQuoteCheckpoint}else{$null}
 $selectedRestockCheckpoint=if($approval.PSObject.Properties.Name -ccontains 'scope05SelectedRestockCheckpoint'){$approval.scope05SelectedRestockCheckpoint}else{$null}
 $runtime=if($null -ne $privateStarsAdmission){@(Get-AiDomainPrivateStarsRuntimeOwners $privateStarsAdmission $cache)}elseif($null -ne $cache){@(Get-AiDomainCurrentRuntimeOwners $cache)}else{@(Get-AiDomainBatchRuntimeOwners)}
 $metadata=@(Get-AiDomainBatchMetadataOwners);$bootstrap=@(Get-AiDomainBatchBootstrapOwners);$amend=@(Get-AiDomainBatchSelectorAmendOwners);$owners=$runtime+$metadata
 $branch=@(Get-OctoberCompatibilityGitLines @('branch','--show-current'))[0]
 Assert-Coordination (Test-AiDomainBatchIdentity @{Root=$root.Replace('\','/');Branch=$branch;Lane=$ProductionLane;Role=$AgentRole;Task=$AgentTask;WorkId=$ProductionWorkId;Ticket=$ProductionTicketId;Phase=$ProductionPhase}) 'Combined exact identity/phase required.'
 Assert-Coordination ((Get-Sha256 (Join-Path $root $contract)) -ceq $hash) 'Accepted combined contract changed.'
 $record=Get-Content -Raw (Join-Path $root $recordOwner)|ConvertFrom-Json;$binding=$record.backendAdmission.binding
 Assert-Coordination ($binding.baselineHead -ceq $base -and $binding.branch -ceq $branch -and $binding.task -ceq '/root/codex_backend_ai_domain_batch' -and $binding.worktreePath -ceq 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-ai-domain-batch-20261028' -and $binding.bootstrapCommitSubject -ceq 'coordination(ai-domain-batch-20261028): record exact bounded domain batch admission' -and (@($binding.bootstrapOwners|Sort-Object)-join '|') -ceq (@($bootstrap|Sort-Object)-join '|') -and (@($record.backendAdmission.runtimeOwners|Sort-Object)-join '|') -ceq (@($runtime|Sort-Object)-join '|')) 'Exact combined owner binding changed.'
 $approval=Get-Content -Raw (Join-Path $root 'docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')|ConvertFrom-Json
 $checkpoint = $approval.scope01Checkpoint
 $scopeTwo = $approval.scope02Admission
 $scopeTwoCheckpoint = $approval.scope02Checkpoint
 $middle=if($approval.PSObject.Properties.Name -ccontains 'scope03Through07Checkpoint'){$approval.scope03Through07Checkpoint}else{$null}
 $metadataCount = if($null -ne $selectedRestockCheckpoint){28} elseif($null -ne $retainedQuoteCheckpoint){27} elseif($null -ne $quoteRecurrence){26} elseif($null -ne $cartClearCheckpoint){24} elseif($null -ne $purchaseReferenceCheckpoint){23} elseif($null -ne $publicationReadyCheckpoint){22} elseif($null -ne $storeSettingsCheckpoint){21} elseif($null -ne $storeReportsCheckpoint){20} elseif($null -ne $storeCouponsCheckpoint){19} elseif($null -ne $storeOperationsCheckpoint){18} elseif($null -ne $originalReceivingCheckpoint){17} elseif($null -ne $purchaseRootCheckpoint){16} elseif($null -ne $supplierDraftCheckpoint){15} elseif($null -ne $privateStarsCheckpoint){14} elseif($null -ne $privateStarsAdmission){13} elseif($null -ne $orderCheckpoint){12} elseif($null -ne $cacheCheckpoint){11} elseif($null -ne $cache){10} elseif($null -ne $middle){9} elseif ($null -ne $scopeTwoCheckpoint) {8} elseif ($null -ne $scopeTwo) {6} elseif ($null -ne $checkpoint) {5} else {4}
 Assert-Coordination ($approval.acceptedUiCommit -ceq $base -and $approval.uiContractSha256 -ceq $hash -and $approval.founderAnswer -ceq 'EXECUTE' -and $approval.localMetadataCommits -eq $metadataCount -and !$approval.sourceFeatureCommits -and !$approval.backendBranchPush -and !$approval.deployment -and !$approval.productionAcceptance) 'Exact acceptance/authority differs.'
 if ($null -ne $checkpoint) {Assert-Coordination ($binding.id -ceq 'ai_domain_batch_20261028' -and $binding.state -ceq 'founder_authorized_2026_10_28') 'Correct current batch identity required; no stale Profile or History binding.'}
 Assert-Coordination ((Get-Sha256 (Join-Path $root 'docs/quality/AI-DOMAIN-ORIGINAL-PROVIDER-TEST-20261028.md')) -ceq 'A378750F4EDC2235D61EDE50154D3E571BB5279E69693F5B0E5FE4C7978BCA22' -and $record.backendAdmission.originalProviderTestAddendum.sha256 -ceq 'A378750F4EDC2235D61EDE50154D3E571BB5279E69693F5B0E5FE4C7978BCA22' -and $approval.originalProviderTestAdmission.sha256 -ceq 'A378750F4EDC2235D61EDE50154D3E571BB5279E69693F5B0E5FE4C7978BCA22') 'Exact original-provider test boundary changed.'
 $expected=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/codex-subagent-coordination-policy.json"))-join "`n")|ConvertFrom-Json
 foreach($claim in @($expected.activeClaims)){$claim.owners=@($claim.owners|Where-Object {$_ -cnotin $owners})}
 $expected.activeClaims=@($expected.activeClaims)+@([pscustomobject]@{task='/root/codex_backend_ai_domain_batch';role='primary';owners=$owners})
 $expected.productionGitDiscipline.continuationBindings=@($expected.productionGitDiscipline.continuationBindings)+@($binding)
 $policy=Get-Content -Raw (Join-Path $root 'config/codex-subagent-coordination-policy.json')|ConvertFrom-Json
 Assert-Coordination (($policy|ConvertTo-Json -Depth 100 -Compress) -ceq ($expected|ConvertTo-Json -Depth 100 -Compress)) 'Unrelated policy changed.'
 $inc=(@(Get-OctoberCompatibilityGitLines @('show',"${base}:config/cross-agent-incremental-ticket-gate.json"))-join "`n")|ConvertFrom-Json
 $inc.uiFounderReview.acceptedScopes=@($inc.uiFounderReview.acceptedScopes)+@([pscustomobject]@{id='assistant.domains';uiCommit=$base;contractPath=$contract;contractSha256=$hash})
 $actual=Get-Content -Raw (Join-Path $root 'config/cross-agent-incremental-ticket-gate.json')|ConvertFrom-Json
 Assert-Coordination (($actual|ConvertTo-Json -Depth 100 -Compress) -ceq ($inc|ConvertTo-Json -Depth 100 -Compress)) 'Unrelated incremental gate changed.'
 Assert-Coordination ($ExpectedRegistryEntryCount -eq 4624 -and $ExpectedRegistrySha256 -ceq $(if($null -ne $quoteRecurrence){'99877C81D4B09BA26DDF2C24E307D027A258E9A26C87E0C0BE9A499B2981842B'}else{'4B3DF3778AC782C95C287D209493C91052F7497C92CEB700FAC40ABF0DA30F2A'}) -and (Get-Sha256 (Join-Path $root 'config/codex-development-regression-registry.json')) -ceq $ExpectedRegistrySha256) 'Regression pin changed.'
 $head=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))[0];Get-OctoberCompatibilityGitLines @('merge-base','--is-ancestor',$base,$head)|Out-Null
 $commits=@(Get-OctoberCompatibilityGitLines @('rev-list',"$base..$head"))
 if($null -ne $middle){
  Assert-Coordination (Test-AiDomainMiddleCheckpoint $middle) 'Exact middle checkpoint is required before any later history is admitted.'
  Assert-Coordination ($record.scope03Through07SourceCheckpoint.baseline -ceq 'e9083ed57476a51a3a50e4f1d4dbb06dd99aaea7' -and
   $record.scope03Through07SourceCheckpoint.manifestIdentitySha256 -ceq $middle.manifest.identitySha256 -and
   $record.scope03Through07SourceCheckpoint.qualifiedRuntimeOwners -eq 33 -and
   $record.scope03Through07SourceCheckpoint.changedRuntimeOwners -eq 21 -and
   $record.scope03Through07SourceCheckpoint.originalBuyCacheOwnerAdmissionStillPending -eq $true -and
   $record.scope03Through07SourceCheckpoint.noDeploymentOrApk -eq $true) 'Current source-record binding or qualification boundary changed.'
 }
 if($null -ne $cache){Assert-Coordination (($record.scope07AddressCacheAdmission|ConvertTo-Json -Depth 20 -Compress) -ceq ($cache|ConvertTo-Json -Depth 20 -Compress)) 'Current exact cache-owner admission binding changed.'}
 if($null -ne $cacheCheckpoint){Assert-Coordination ($null -ne $cache -and (Test-AiDomainAddressCacheCheckpoint $cacheCheckpoint)) 'Exact prior cache admission and tested checkpoint are required.'}
 if($null -ne $privateStarsAdmission){Assert-Coordination ($null -ne $orderCheckpoint -and ($record.scope10PrivateStarsTestAdmission|ConvertTo-Json -Depth 20 -Compress) -ceq ($privateStarsAdmission|ConvertTo-Json -Depth 20 -Compress)) 'Exact source checkpoint and matching native055 owner admission required.'}
 if($null -ne $privateStarsCheckpoint){Assert-Coordination ($null -ne $privateStarsAdmission -and (Test-AiDomainPrivateStarsCheckpoint $privateStarsCheckpoint)) 'Exact existing test admission and qualified private-rating checkpoint required.'}
 if($null -ne $supplierDraftCheckpoint){Assert-Coordination ($null -ne $privateStarsCheckpoint -and (Test-AiDomainSupplierDraftCheckpoint $supplierDraftCheckpoint)) 'Exact existing private-rating checkpoint and qualified supplier draft checkpoint required.'}
 if($null -ne $purchaseRootCheckpoint){Assert-Coordination ($null -ne $supplierDraftCheckpoint -and (Test-AiDomainPurchaseRootCheckpoint $purchaseRootCheckpoint)) 'Exact existing supplier checkpoint and qualified purchase root checkpoint required.'}
 if($null -ne $originalReceivingCheckpoint){Assert-Coordination ($null -ne $purchaseRootCheckpoint -and (Test-AiDomainOriginalReceivingCheckpoint $originalReceivingCheckpoint)) 'Exact prior purchase checkpoint and qualified original receiving checkpoint required.'}
 if($null -ne $storeOperationsCheckpoint){Assert-Coordination ($null -ne $originalReceivingCheckpoint -and (Test-AiDomainStoreOperationsCheckpoint $storeOperationsCheckpoint)) 'Exact prior receiving checkpoint and qualified original operational checkpoint required.'}
 if($null -ne $storeCouponsCheckpoint){Assert-Coordination ($null -ne $storeOperationsCheckpoint -and (Test-AiDomainStoreCouponsCheckpoint $storeCouponsCheckpoint)) 'Exact prior operational checkpoint and qualified original coupon checkpoint required.'}
 if($null -ne $storeReportsCheckpoint){Assert-Coordination ($null -ne $storeCouponsCheckpoint -and (Test-AiDomainStoreReportsCheckpoint $storeReportsCheckpoint)) 'Exact prior coupon checkpoint and qualified original report-controls checkpoint required.'}
 if($null -ne $storeSettingsCheckpoint){Assert-Coordination ($null -ne $storeReportsCheckpoint -and (Test-AiDomainStoreSettingsCheckpoint $storeSettingsCheckpoint)) 'Exact prior report checkpoint and qualified original Store-details checkpoint required.'}
 if($null -ne $publicationReadyCheckpoint){Assert-Coordination ($null -ne $storeSettingsCheckpoint -and (Test-AiDomainStorePublicationReadyCheckpoint $publicationReadyCheckpoint)) 'Exact prior Store-details checkpoint and qualified publication-ready correction required.'}
 if($null -ne $purchaseReferenceCheckpoint){Assert-Coordination ($null -ne $publicationReadyCheckpoint -and (Test-AiDomainPurchaseReferenceCheckpoint $purchaseReferenceCheckpoint)) 'Exact prior publication-ready checkpoint and qualified purchase-reference integration required.'}
 if($null -ne $cartClearCheckpoint){Assert-Coordination ($null -ne $purchaseReferenceCheckpoint -and (Test-AiDomainCartClearCheckpoint $cartClearCheckpoint)) 'Exact prior reference checkpoint and qualified original Cart clearing required.'}
 if($null -ne $retainedQuoteCheckpoint){Assert-Coordination ($null -ne $quoteRecurrence -and (Test-AiDomainRetainedQuoteCheckpoint $retainedQuoteCheckpoint)) 'Exact corrected recurrence and qualified original retained quote checkpoint required.'}
 if($null -ne $selectedRestockCheckpoint){Assert-Coordination ($null -ne $retainedQuoteCheckpoint -and (Test-AiDomainSelectedRestockCheckpoint $selectedRestockCheckpoint)) 'Exact preserved predecessor and selected Restock checkpoint required.'}
 $maximumCommits = if($null -ne $selectedRestockCheckpoint){64} elseif($null -ne $retainedQuoteCheckpoint){61} elseif($null -ne $quoteRecurrence){58} elseif($null -ne $cartClearCheckpoint){56} elseif($null -ne $purchaseReferenceCheckpoint){53} elseif($null -ne $publicationReadyCheckpoint){50} elseif($null -ne $storeSettingsCheckpoint){47} elseif($null -ne $storeReportsCheckpoint){44} elseif($null -ne $storeCouponsCheckpoint){41} elseif($null -ne $storeOperationsCheckpoint){38} elseif($null -ne $originalReceivingCheckpoint){35} elseif($null -ne $purchaseRootCheckpoint){32} elseif($null -ne $supplierDraftCheckpoint){29} elseif($null -ne $privateStarsCheckpoint){26} elseif($null -ne $privateStarsAdmission){23} elseif($null -ne $orderCheckpoint){22} elseif($null -ne $cacheCheckpoint){19} elseif($null -ne $cache){16} elseif($null -ne $middle){15} elseif ($null -ne $scopeTwoCheckpoint) {12} elseif ($null -ne $scopeTwo) {8} elseif ($null -ne $checkpoint) {7} else {4}
 Assert-Coordination ($commits.Count -le $maximumCommits -and @(Get-OctoberCompatibilityGitLines @('rev-list','--merges',"$base..$head")).Count -eq 0 -and @(Get-OctoberCompatibilityGitLines @('for-each-ref','--format=%(refname)','refs/replace')).Count -eq 0 -and @(Get-OctoberCompatibilityGitLines @('ls-files','-v')|Where-Object {$_ -cmatch '^[a-zS] '}).Count -eq 0) 'Only exact admitted checkpoint history; no history/index overrides.'
 $changed=@(@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base))+@(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')))|Sort-Object -Unique
 Assert-AiDomainBatchOwners $changed $owners
 if($head -ceq $base){Assert-Coordination ($ProductionPhase -cin @('coordination_bootstrap','pre_commit')) 'Recorded clean admission required.';Assert-AiDomainBatchOwners $changed $metadata}
 else {
  $boot='fdff6be4d58e9979e076b5feac2fc5bc42aa62a4'
  Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$boot))[0]) -ceq $base -and (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$boot))[0]) -ceq 'coordination(ai-domain-batch-20261028): record exact bounded domain batch admission' -and (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$base,$boot)|Sort-Object)-join '|') -ceq (@($bootstrap|Sort-Object)-join '|')) 'Original bootstrap changed.'
  Assert-Coordination ((Get-Sha256 (Join-Path $root 'docs/quality/AI-DOMAIN-CATALOGUE-SELECTOR-20261028.md')) -ceq '925A65AF2FD4AC01837A08EB6493D8DF77EE6637CA4EE0679175BBDFA0376F69' -and $record.backendAdmission.catalogueSelectorAddendum.sha256 -ceq '925A65AF2FD4AC01837A08EB6493D8DF77EE6637CA4EE0679175BBDFA0376F69') 'Exact original-catalogue selector addendum changed.'
  if($head -ceq $boot){Assert-Coordination ($commits.Count -eq 1) 'Only bootstrap precedes selector amendment.';foreach($owner in $metadata|Where-Object {$_ -cnotin $amend}){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$boot,'--',$owner)|Out-Null}}
  else {
   $selector='2e517bb337c510e30536043f0bcd9e359f12833e'
   Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$selector))[0]) -ceq $boot -and (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$selector))[0]) -ceq 'coordination(ai-domain-batch-20261028): admit catalogue selectors and typed target owners' -and (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$boot,$selector)|Sort-Object)-join '|') -ceq (@($amend|Sort-Object)-join '|')) 'Original selector checkpoint changed.'
   $recurrence=@(Get-AiDomainBatchRecurrenceOwners)
   if($head -ceq $selector){
    Assert-Coordination ($commits.Count -eq 2 -and $ProductionPhase -ceq 'pre_commit') 'Only exact recurrence checkpoint may follow selector metadata.'
    foreach($owner in $metadata|Where-Object {$_ -cnotin $recurrence}){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$head,'--',$owner)|Out-Null}
   } else {
    $recurrenceCommit='7c51462da9f5d06b076b05d473b81c2da24f5316'
    Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$recurrenceCommit))[0]) -ceq $selector -and (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$recurrenceCommit))[0]) -ceq 'coordination(ai-domain-batch-20261028): record bounded tooling read recurrence' -and (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$selector,$recurrenceCommit)|Sort-Object)-join '|') -ceq (@($recurrence|Sort-Object)-join '|')) 'Original recurrence checkpoint changed.'
    $providerOwners=@(Get-AiDomainBatchProviderTestOwners)
    if($head -ceq $recurrenceCommit){
     Assert-Coordination ($commits.Count -eq 3 -and $ProductionPhase -ceq 'pre_commit') 'Only exact provider-test admission follows recurrence metadata.'
     foreach($owner in $metadata|Where-Object {$_ -cnotin $providerOwners}){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$head,'--',$owner)|Out-Null}
    } else {
     $provider = 'cb51815990f58f548d0db2c5ca815b95a527ff07'
     Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$provider))[0]) -ceq $recurrenceCommit -and (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$provider))[0]) -ceq 'coordination(ai-domain-batch-20261028): admit original-provider integration tests' -and (@(Get-OctoberCompatibilityGitLines @('diff','--name-only',$recurrenceCommit,$provider)|Sort-Object)-join '|') -ceq (@($providerOwners|Sort-Object)-join '|')) 'Original provider-test metadata checkpoint changed.'
     if ($null -ne $scopeTwo) {
      if($null -ne $scopeTwoCheckpoint) {
       Invoke-AiDomainScopeTwoAdmission $scopeTwo '9aa3c913876aa53e3f3da5559b5c7b9de43d6331' 'implementation' -Continuation
       if($null -ne $middle){
        Invoke-AiDomainScopeTwoCheckpoint $scopeTwoCheckpoint 'e9083ed57476a51a3a50e4f1d4dbb06dd99aaea7' 'implementation' -Continuation
        if($null -ne $cache){
         Invoke-AiDomainMiddleCheckpoint $middle '1e34cdf9a2f643920b5cb9c421becb3e3f667080' 'implementation' -Continuation
         if($null -ne $cacheCheckpoint){
          Invoke-AiDomainAddressCacheAdmission $cache 'd6b95fba5666f7c6abf6bad4dd2d0c344f6c7483' 'implementation' -Continuation
          if($null -ne $orderCheckpoint){
           Invoke-AiDomainAddressCacheCheckpoint $cacheCheckpoint '9bea89409b1c1258929e172a6d3b4bbcc385a384' 'implementation' -Continuation
           if($null -ne $privateStarsAdmission){
            Invoke-AiDomainOrderOriginalCheckpoint $orderCheckpoint '2c969b300de91cfeb4efb4bbd7a2634741d1b6f0' 'implementation' -Continuation
            if($null -ne $privateStarsCheckpoint){
             Invoke-AiDomainPrivateStarsTestAdmission $privateStarsAdmission '47a64270dbd603c09ee0c0e8b908616332093187' 'implementation' -Continuation
             if($null -ne $supplierDraftCheckpoint){
              Invoke-AiDomainPrivateStarsCheckpoint $privateStarsCheckpoint 'be023a1fe2a3ec3a79b0f436669bb498f5923d9f' 'implementation' -Continuation
              if($null -ne $purchaseRootCheckpoint){
               Invoke-AiDomainSupplierDraftCheckpoint $supplierDraftCheckpoint '910c6187b04ad4e6b13269a54c9c423d4fce7328' 'implementation' -Continuation
               if($null -ne $originalReceivingCheckpoint){
                Invoke-AiDomainPurchaseRootCheckpoint $purchaseRootCheckpoint '49ed91d5df56976e7e8630daa342a28a8ee4acd0' 'implementation' -Continuation
                if($null -ne $storeOperationsCheckpoint){
                 Invoke-AiDomainOriginalReceivingCheckpoint $originalReceivingCheckpoint '6651c66950e25abb7bf3e9b8e65625a342ca6de3' 'implementation' -Continuation
                 if($null -ne $storeCouponsCheckpoint){
                  Invoke-AiDomainStoreOperationsCheckpoint $storeOperationsCheckpoint '06a1abc4a04424d4a07a5d8117fe3f64a80bff75' 'implementation' -Continuation
                  if($null -ne $storeReportsCheckpoint){
                   Invoke-AiDomainStoreCouponsCheckpoint $storeCouponsCheckpoint '27302f4b5cf70f7b6aa78ec50301e71d143ee094' 'implementation' -Continuation
                   if($null -ne $storeSettingsCheckpoint){
                    Invoke-AiDomainStoreReportsCheckpoint $storeReportsCheckpoint 'c05393e6cd24fd100fd3fb342d61c30a1389e3e6' 'implementation' -Continuation
                    if($null -ne $publicationReadyCheckpoint){
                     Invoke-AiDomainStoreSettingsCheckpoint $storeSettingsCheckpoint '1bf093d0a7c6c3764189204fa609335f764650f2' 'implementation' -Continuation
                     if($null -ne $purchaseReferenceCheckpoint){
                      Invoke-AiDomainStorePublicationReadyCheckpoint $publicationReadyCheckpoint 'd67c3815c322eae562f6e00518712e3c204b1cec' 'implementation' -Continuation
                      if($null -ne $cartClearCheckpoint){
                       Invoke-AiDomainPurchaseReferenceCheckpoint $purchaseReferenceCheckpoint 'af51db32eae8bbe483f660ac97c9e443c96b3356' 'implementation' -Continuation
                       if($null -ne $quoteRecurrence){
                        Invoke-AiDomainCartClearCheckpoint $cartClearCheckpoint '7eb5914fb8fb484eac9157da888cac6480b967b4' 'implementation' -Continuation
                        if($null -ne $retainedQuoteCheckpoint){
                         Invoke-AiDomainQuoteRecurrenceAdmission $quoteRecurrence 'a08d70baaaddb0bab76ea5df1bd917509941d3dd' 'implementation' -Continuation
                         if($null -ne $selectedRestockCheckpoint){
                          Invoke-AiDomainRetainedQuoteCheckpoint $retainedQuoteCheckpoint 'fa6fe53f803a3ec63871a7253a48a23c44544d85' 'implementation' -Continuation
                          Invoke-AiDomainSelectedRestockCheckpoint $selectedRestockCheckpoint $head $ProductionPhase
                         }else{Invoke-AiDomainRetainedQuoteCheckpoint $retainedQuoteCheckpoint $head $ProductionPhase}
                        }else{Invoke-AiDomainQuoteRecurrenceAdmission $quoteRecurrence $head $ProductionPhase}
                       }else{Invoke-AiDomainCartClearCheckpoint $cartClearCheckpoint $head $ProductionPhase}
                      }else{Invoke-AiDomainPurchaseReferenceCheckpoint $purchaseReferenceCheckpoint $head $ProductionPhase}
                     }else{Invoke-AiDomainStorePublicationReadyCheckpoint $publicationReadyCheckpoint $head $ProductionPhase}
                    }else{Invoke-AiDomainStoreSettingsCheckpoint $storeSettingsCheckpoint $head $ProductionPhase}
                   }else{Invoke-AiDomainStoreReportsCheckpoint $storeReportsCheckpoint $head $ProductionPhase}
                  }else{Invoke-AiDomainStoreCouponsCheckpoint $storeCouponsCheckpoint $head $ProductionPhase}
                 }else{Invoke-AiDomainStoreOperationsCheckpoint $storeOperationsCheckpoint $head $ProductionPhase}
                }else{Invoke-AiDomainOriginalReceivingCheckpoint $originalReceivingCheckpoint $head $ProductionPhase}
               }else{Invoke-AiDomainPurchaseRootCheckpoint $purchaseRootCheckpoint $head $ProductionPhase}
              }else{Invoke-AiDomainSupplierDraftCheckpoint $supplierDraftCheckpoint $head $ProductionPhase}
             }else{Invoke-AiDomainPrivateStarsCheckpoint $privateStarsCheckpoint $head $ProductionPhase}
            }else{Invoke-AiDomainPrivateStarsTestAdmission $privateStarsAdmission $head $ProductionPhase}
           }else{Invoke-AiDomainOrderOriginalCheckpoint $orderCheckpoint $head $ProductionPhase}
          }else{Invoke-AiDomainAddressCacheCheckpoint $cacheCheckpoint $head $ProductionPhase}
         }else{Invoke-AiDomainAddressCacheAdmission $cache $head $ProductionPhase}
        }else{Invoke-AiDomainMiddleCheckpoint $middle $head $ProductionPhase}
       }else{Invoke-AiDomainScopeTwoCheckpoint $scopeTwoCheckpoint $head $ProductionPhase}
      } else {Invoke-AiDomainScopeTwoAdmission $scopeTwo $head $ProductionPhase}
      Invoke-AiDomainScopeOneCheckpoint $checkpoint '785d375a6170e585d575d57c567e17573655e02f' 'implementation' -Continuation
     }
     elseif ($null -ne $checkpoint) {Invoke-AiDomainScopeOneCheckpoint $checkpoint $head $ProductionPhase}
     else {
      Assert-Coordination ($head -ceq $provider -and $commits.Count -eq 4) 'No source checkpoint admitted.'
      foreach($owner in $metadata){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$head,'--',$owner)|Out-Null}
     }
    }
   }
  }
 }
 if($ProductionPhase -ceq 'pre_commit' -and $null -eq $checkpoint){Assert-Coordination ($head -ceq '7c51462da9f5d06b076b05d473b81c2da24f5316' -and (@(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')|Sort-Object)-join '|') -ceq (@((Get-AiDomainBatchProviderTestOwners)|Sort-Object)-join '|')) 'Only exact original-provider test metadata amendment authorized.'}
 if($ProductionPhase -cin @('coordination_bootstrap','task_start')){$remote=@(Get-OctoberCompatibilityGitLines @('ls-remote','--heads','origin','refs/heads/work/codex-backend/ai-history-20261028'));Assert-Coordination ($remote.Count -eq 1 -and ($remote[0] -split '\s+')[0] -ceq $base) 'Origin-exact sealed baseline required.'}
 if($ProductionPhase -ceq 'task_start'){Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('status','--porcelain')).Count -eq 0) 'Task start not clean.'}
 & (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -RepositoryRoot $root -StatePath $recordOwner -CandidateId AI-DOMAIN-BATCH-20 -RequireExecutionAuthorized
 & (Join-Path $root 'scripts/check-cross-agent-incremental-ticket-gate.ps1') -RepositoryRoot $root -Phase implementation -Lane codex_backend -TicketId AI-DOMAIN-BATCH-20 -UiScope assistant.domains -CandidateVersionName '1.0.0-r67.13' -CandidateVersionCode 2026102802 -PackageId com.moolsocial.app.runtime -AcceptedUiCommit $base -UiContractPath $contract -UiContractSha256 $hash
 Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head
 Assert-ProductionSecretSafe -BaseCommit $base -HeadCommit $head -IndexOnly
 Write-Output "AI domain batch admission passed; $($runtime.Count) runtime/test owners; only exact admitted metadata/qualified source checkpoints; no cloud or APK authority."
}
