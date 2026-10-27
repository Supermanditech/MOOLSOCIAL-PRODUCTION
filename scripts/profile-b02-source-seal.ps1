# Narrow founder-approved B02 source sealing; no release/acceptance authority.
function Get-B02SealDigest([string]$Path){
  $bytes=[Text.Encoding]::UTF8.GetBytes([IO.File]::ReadAllText($Path).Replace("`r`n","`n"))
  [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
}
function Test-B02SealSet([object[]]$Actual,[object[]]$Expected){
  return (@($Actual|Sort-Object)-join '|') -ceq (@($Expected|Sort-Object)-join '|')
}
function Get-B02SealStage([int]$Count){
  switch($Count){0 {'metadata'};1 {'runtime'};2 {'evidence'};3 {'sealed'};default {throw 'B02 source-seal history is outside the exact three-commit sequence.'}}
}
function Invoke-ProfileB02SourceSeal {
  $start='f46d6a1300ec26f021248499e86e1ad9d9e74c8c'
  $recordPath='docs/quality/PROFILE-B02-SOURCE-SEAL-20261027.json'
  Assert-Coordination ((Get-B02SealDigest (Join-Path $root $recordPath)) -ceq '20B3EFF3347DDBA6DCE5DDEC151E34F4CAB2C6A950B9C83438D3A9395DC016D3') 'B02 source-seal authorization/manifest changed.'
  $seal=Get-Content -Raw (Join-Path $root $recordPath)|ConvertFrom-Json
  $branch=@(Get-OctoberCompatibilityGitLines @('branch','--show-current'))[0]
  Assert-Coordination (Test-ProfileB02Identity @{Root=$root.Replace('\','/');Branch=$branch;Lane=$ProductionLane;Role=$AgentRole;Task=$AgentTask;WorkId=$ProductionWorkId;Ticket=$ProductionTicketId;Phase=$ProductionPhase}) 'B02 sealing identity differs.'
  Assert-Coordination ($ProductionPhase -cin @('implementation','pre_commit')) 'B02 sealing cannot assert task/OPPO/founder/production acceptance.'
  Assert-Coordination ($seal.approval -ceq 'approved' -and $seal.startHead -ceq $start -and $seal.remoteRef -ceq 'refs/heads/work/codex-backend/profile-b02-20261027') 'B02 sealing authority differs.'
  Assert-Coordination ((Get-B02SealDigest (Join-Path $root 'docs/quality/PROFILE-B02-SOURCE-SEAL-SCOPE-20261027.md')) -ceq $seal.scopeSha256) 'B02 sealing scope changed.'
  $metadata=@($seal.metadataOwners);$runtime=@(Get-ProfileB02RuntimeOwners);$evidence=@($seal.evidenceOwners)
  Assert-Coordination (Test-B02SealSet $runtime $seal.runtimeOwners) 'B02 sealing runtime owners changed.'
  Assert-Coordination ($metadata.Count -eq 7 -and $evidence.Count -eq 2 -and $runtime.Count -eq 22) 'B02 sealing owner counts changed.'
  $policy=Get-Content -Raw (Join-Path $root 'config/codex-subagent-coordination-policy.json')|ConvertFrom-Json
  $prior=(@(Get-OctoberCompatibilityGitLines @('show',"${start}:config/codex-subagent-coordination-policy.json"))-join "`n")|ConvertFrom-Json
  foreach($claim in $prior.activeClaims){if($claim.task -ceq '/root/codex_backend_profile_b02'){$claim.owners=@($claim.owners)+@(($metadata+$evidence)|Where-Object {$_ -cnotin $claim.owners})}}
  Assert-Coordination (($policy|ConvertTo-Json -Depth 100 -Compress) -ceq ($prior|ConvertTo-Json -Depth 100 -Compress)) 'B02 unrelated policy changed.'
  foreach($file in $seal.files){Assert-Coordination ((Get-B02SealDigest (Join-Path $root $file.path)) -ceq $file.sha256Lf) "B02 tested source changed: $($file.path)"}
  $head=@(Get-OctoberCompatibilityGitLines @('rev-parse','HEAD'))[0]
  Get-OctoberCompatibilityGitLines @('merge-base','--is-ancestor',$start,$head)|Out-Null
  $commits=@(Get-OctoberCompatibilityGitLines @('rev-list','--reverse',"$start..$head"))
  $stage=Get-B02SealStage $commits.Count
  Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('rev-list','--merges',"$start..$head")).Count -eq 0 -and @(Get-OctoberCompatibilityGitLines @('for-each-ref','--format=%(refname)','refs/replace')).Count -eq 0 -and @(Get-OctoberCompatibilityGitLines @('ls-files','-v')|Where-Object {$_ -cmatch '^[a-zS] '}).Count -eq 0) 'B02 history/index override.'
  $sets=@($metadata,$runtime,$evidence)
  $subjects=@('coordination(profile-b02-20261027): admit exact source sealing','codex-backend(profile-b02-20261027): connect scoped Plans readback','evidence(profile-b02-20261027): record source checkpoint and limits')
  $parent=$start
  for($i=0;$i -lt $commits.Count;$i++){
    $commit=$commits[$i]
    Assert-Coordination ((@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%P',$commit))[0]) -ceq $parent -and (@(Get-OctoberCompatibilityGitLines @('show','-s','--format=%s',$commit))[0]) -ceq $subjects[$i]) 'B02 seal commit parent/subject differs.'
    Assert-Coordination (Test-B02SealSet @(Get-OctoberCompatibilityGitLines @('diff','--name-only',$parent,$commit)) $sets[$i]) 'B02 seal commit owner set differs.'
    $parent=$commit
  }
  $oldOwners=@(Get-OctoberCompatibilityGitLines @('diff','--name-only','955f793dcfc593b603797d9e960925f774a6c2c2',$start))
  $allowed=@($oldOwners+$metadata+$runtime+$evidence)|Sort-Object -Unique
  $changed=@(@(Get-OctoberCompatibilityGitLines @('diff','--name-only','955f793dcfc593b603797d9e960925f774a6c2c2'))+@(Get-OctoberCompatibilityGitLines @('ls-files','--others','--exclude-standard')))|Sort-Object -Unique
  Assert-ProfileB02Owners $changed $allowed
  foreach($owner in @($oldOwners|Where-Object {$_ -cnotin $metadata -and $_ -cnotin $runtime})){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$start,'--',$owner)|Out-Null}
  if($commits.Count -ge 1){foreach($owner in $metadata){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$commits[0],'--',$owner)|Out-Null}}
  if($commits.Count -ge 2){foreach($owner in $runtime){Get-OctoberCompatibilityGitLines @('diff','--exit-code',$commits[1],'--',$owner)|Out-Null}}
  if($commits.Count -ge 3){
    Assert-Coordination (@(Get-OctoberCompatibilityGitLines @('status','--porcelain')).Count -eq 0) 'B02 source seal is not clean.'
    $result=Get-Content -Raw (Join-Path $root $evidence[0])|ConvertFrom-Json
    Assert-Coordination ($result.sourceCommit -ceq $commits[1] -and !$result.productionAcceptance -and !$result.formalTicketClose) 'B02 source evidence changed or overclaims acceptance.'
  }
  if($ProductionPhase -ceq 'pre_commit'){
    Assert-Coordination ($commits.Count -lt 3) 'B02 source sealing is already complete.'
    Assert-Coordination (Test-B02SealSet @(Get-OctoberCompatibilityGitLines @('diff','--cached','--name-only')) $sets[$commits.Count]) 'B02 staged scope differs.'
    foreach($owner in $sets[$commits.Count]){Get-OctoberCompatibilityGitLines @('diff','--exit-code','--',$owner)|Out-Null}
  }
  Assert-Coordination ($ExpectedRegistryEntryCount -eq 4624 -and $ExpectedRegistrySha256 -ceq '333A27362EB36CF334397E70EF58745494286D4EFA93A5AEC21C93AF28922C11' -and (Get-Sha256 (Join-Path $root 'config/codex-development-regression-registry.json')) -ceq $ExpectedRegistrySha256) 'B02 regression pin changed.'
  & (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -RepositoryRoot $root -StatePath docs/quality/PROFILE-B02-BACKEND-20261027.json -CandidateId PROFILE-B02 -RequireExecutionAuthorized
  & (Join-Path $root 'scripts/check-cross-agent-incremental-ticket-gate.ps1') -RepositoryRoot $root -Phase implementation -Lane codex_backend -TicketId PROFILE-B02 -UiScope account.plans_entitlements -CandidateVersionName '1.0.0-r67.9' -CandidateVersionCode 2026102705 -PackageId com.moolsocial.app.runtime -AcceptedUiCommit '955f793dcfc593b603797d9e960925f774a6c2c2' -UiContractPath docs/quality/PROFILE-B02-CONTRACT-20261027.md -UiContractSha256 '44233B52F1FE9371D37BDE8476D8B6FA18305E5CCD2B9F20AC110514B22E2F9A'
  Assert-ProductionSecretSafe -BaseCommit $start -HeadCommit $head
  Assert-ProductionSecretSafe -BaseCommit $start -HeadCommit $head -IndexOnly
  Write-Output "PROFILE-B02 source-sealing admission passed: phase=$ProductionPhase; stage=$stage; no release/formal acceptance authority."
}
