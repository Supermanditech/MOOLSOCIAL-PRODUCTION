$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'ai-domain-batch-admission.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$n=0;function Check([bool]$c,[string]$m){if(!$c){throw $m};$script:n++}
$f=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-ai-domain-batch-20261028';Branch='work/codex-backend/ai-domain-batch-20261028';Lane='codex_backend';Role='primary';WorkId='ai-domain-batch-20261028';Ticket='AI-DOMAIN-BATCH-20';Task='/root/codex_backend_ai_domain_batch';Phase='implementation'}
Check (Test-AiDomainBatchIdentity $f) 'identity'
foreach($k in $f.Keys){$b=$f.Clone();$b[$k]='foreign';Check (!(Test-AiDomainBatchIdentity $b)) "foreign $k";$b=$f.Clone();$b.Remove($k);Check (!(Test-AiDomainBatchIdentity $b)) "missing $k"}
foreach($phase in @('build','deploy','ticket_acceptance','handoff')){$b=$f.Clone();$b.Phase=$phase;Check (!(Test-AiDomainBatchIdentity $b)) "forbidden $phase"}
Check (@(Get-AiDomainBatchRuntimeOwners).Count -eq 33) '33 exact runtime/test owners';Check (@(Get-AiDomainBatchMetadataOwners).Count -eq 13) 'thirteen exact metadata owners'
Check (@(Get-AiDomainScopeOneRuntimeOwners).Count -eq 31) 'the sealed scope01 manifest retains its original31 owners'
$root=Split-Path -Parent $PSScriptRoot
Check ($root.Replace('\','/') -ceq $f.Root) 'actual checkout root matches identity'
Check ((Get-FileHash (Join-Path $root 'docs/quality/AI-DOMAIN-BATCH-CONTRACT-20261028.md')).Hash -ceq '9FCD190B22B9725CBE1BF2107708D6D2BE11E226CD606E218FD8B94D3A420382') 'contract bytes'
$original=@(& git -C $root show '7ffe45ca11be6b99cfdb8ac8a7591ef352ff2e67:scripts/check-codex-subagent-coordination-policy.ps1');if($LASTEXITCODE -ne 0){throw 'original missing'}
$current=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1'))
$pattern='(?ms)^# Founder-approved bounded existing-domain integration goal\.\r?\nif \(\$ProductionTicketId.*?^\}\r?\n\r?\n'
Check ([regex]::Matches($current,$pattern).Count -eq 1) 'one dispatch'
Check (([regex]::Replace($current,$pattern,'').Replace("`r`n","`n").TrimEnd()) -ceq (($original -join "`n").TrimEnd())) 'old gates unchanged'
Check (@(Get-AiDomainBatchBootstrapOwners).Count -eq 9) 'original nine bootstrap owners'
Check (@(Get-AiDomainBatchSelectorAmendOwners).Count -eq 7) 'exact seven selector amendment owners'
Check ((Get-FileHash (Join-Path $root 'docs/quality/AI-DOMAIN-CATALOGUE-SELECTOR-20261028.md')).Hash -ceq '925A65AF2FD4AC01837A08EB6493D8DF77EE6637CA4EE0679175BBDFA0376F69') 'exact selector contract'
Check (@(Get-AiDomainBatchRecurrenceOwners).Count -eq 6) 'exact six recurrence owners'
Check (@(Get-AiDomainBatchProviderTestOwners).Count -eq 7) 'exact seven original-provider metadata owners'
Check ((Get-FileHash (Join-Path $root 'docs/quality/AI-DOMAIN-ORIGINAL-PROVIDER-TEST-20261028.md')).Hash -ceq 'A378750F4EDC2235D61EDE50154D3E571BB5279E69693F5B0E5FE4C7978BCA22') 'exact original-provider test boundary'
Check (@(Get-AiDomainScopeOneSealOwners).Count -eq 5) 'only five existing metadata owners for the discovery checkpoint'
$approval=Get-Content -Raw (Join-Path $root 'docs/quality/AI-DOMAIN-BATCH-ACCEPTANCE-20261028.json')|ConvertFrom-Json
$manifest=$approval.scope01Checkpoint.manifest
Check (Test-AiDomainScopeOneManifest $manifest) 'exact qualified discovery source manifest'
foreach($property in @('scope','baseline','metadataHead','branch')) {
 $bad=($manifest|ConvertTo-Json -Depth 30)|ConvertFrom-Json
 $bad.$property=if($property -eq 'scope'){2}else{'foreign'}
 Check (!(Test-AiDomainScopeOneManifest $bad)) "reject changed manifest $property"
}
foreach($property in @('path','bytes','sha256','gitBlobOid')) {
 $bad=($manifest|ConvertTo-Json -Depth 30)|ConvertFrom-Json
 $bad.owners[0].$property=if($property -eq 'bytes'){1}else{'foreign'}
 Check (!(Test-AiDomainScopeOneManifest $bad)) "reject changed qualified $property"
}
$bad=($manifest|ConvertTo-Json -Depth 30)|ConvertFrom-Json
$bad.changedOwners[0]='backend/functions/src/foreign.ts'
Check (!(Test-AiDomainScopeOneManifest $bad)) 'reject unrelated source owner'
$bad=($manifest|ConvertTo-Json -Depth 30)|ConvertFrom-Json
$bad.owners=@($bad.owners)+@($bad.owners[0])
Check (!(Test-AiDomainScopeOneManifest $bad)) 'reject duplicate or expanded runtime manifest'
Check (!$approval.sourceFeatureCommits -and !$approval.backendBranchPush -and !$approval.deployment -and !$approval.productionAcceptance) 'no broad source/push/deployment or production authority'
Check (@(Get-AiDomainScopeTwoAdmissionOwners).Count -eq 5) 'only existing five metadata owners for scope02 admission'
$scopeTwo=$approval.scope02Admission
Check (Test-AiDomainScopeTwoAdmission $scopeTwo) 'exact original acknowledgement bridge admission'
foreach($property in @('baseline','contract')) {
 $bad=($scopeTwo|ConvertTo-Json -Depth 10)|ConvertFrom-Json;$bad.$property='foreign'
 Check (!(Test-AiDomainScopeTwoAdmission $bad)) "reject scope02 changed $property"
}
foreach($property in @('sourceFeatureCommitsAuthorized','backendBranchPushAuthorized','productionAcceptance','newMasterOrMigration')) {
 $bad=($scopeTwo|ConvertTo-Json -Depth 10)|ConvertFrom-Json;$bad.$property=$true
 Check (!(Test-AiDomainScopeTwoAdmission $bad)) "reject scope02 expanded $property"
}
$bad=($scopeTwo|ConvertTo-Json -Depth 10)|ConvertFrom-Json;$bad.newOwners=@($bad.newOwners)+@('backend/functions/src/foreign.ts')
Check (!(Test-AiDomainScopeTwoAdmission $bad)) 'reject scope02 unrelated owner expansion'
Check (@(Get-AiDomainScopeTwoSealOwners).Count -eq 3) 'only three existing owners for qualified product seal'
$productManifest=$approval.scope02Checkpoint.manifest
Check (Test-AiDomainScopeTwoManifest $productManifest) 'exact qualified product manifest'
foreach($property in @('scope','baseline','branch')) {
 $bad=($productManifest|ConvertTo-Json -Depth 40)|ConvertFrom-Json
 $bad.$property=if($property -eq 'scope'){3}else{'foreign'}
 Check (!(Test-AiDomainScopeTwoManifest $bad)) "reject changed product manifest $property"
}
foreach($property in @('path','bytes','sha256','gitBlobOid')) {
 $bad=($productManifest|ConvertTo-Json -Depth 40)|ConvertFrom-Json
 $bad.owners[0].$property=if($property -eq 'bytes'){1}else{'foreign'}
 Check (!(Test-AiDomainScopeTwoManifest $bad)) "reject changed product source $property"
}
$bad=($productManifest|ConvertTo-Json -Depth 40)|ConvertFrom-Json;$bad.changedOwners[0]='backend/functions/src/foreign.ts'
Check (!(Test-AiDomainScopeTwoManifest $bad)) 'reject unrelated product source owner'
foreach($row in @(@(0,3),@(1,22),@(2,3),@(3,1),@(4,0))) {
 $stageOwners=@(Get-AiDomainScopeTwoStageOwners $row[0] $approval.scope02Checkpoint)
 Check ($stageOwners.Count -eq $row[1]) "product checkpoint stage $($row[0]) retains exact array owner count"
}
Write-Output "AI domain batch admission checks passed: $n."
