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
$middle=$approval.scope03Through07Checkpoint
Check (Test-AiDomainMiddleCheckpoint $middle) 'exact tested partial integration recovery checkpoint'
Check (@(Get-AiDomainMiddleSealOwners).Count -eq 4) 'only four existing metadata owners for current partial checkpoint'
foreach($property in @('scope','baseline','branch','identitySha256')) {
 $bad=($middle.manifest|ConvertTo-Json -Depth 40)|ConvertFrom-Json;$bad.$property='foreign'
 Check (!(Test-AiDomainMiddleManifest $bad)) "reject changed middle manifest $property"
}
foreach($property in @('path','bytes','sha256','gitBlobOid')) {
 $bad=($middle.manifest|ConvertTo-Json -Depth 40)|ConvertFrom-Json
 $bad.owners[0].$property=if($property -eq 'bytes'){1}else{'foreign'}
 Check (!(Test-AiDomainMiddleManifest $bad)) "reject changed middle source $property"
}
$bad=($middle.manifest|ConvertTo-Json -Depth 40)|ConvertFrom-Json;$bad.changedOwners[0]='backend/functions/src/foreign.ts'
Check (!(Test-AiDomainMiddleManifest $bad)) 'reject expanded middle source owner'
$bad=($middle.manifest|ConvertTo-Json -Depth 40)|ConvertFrom-Json;$bad.owners=@($bad.owners)+@($bad.owners[0])
Check (!(Test-AiDomainMiddleManifest $bad)) 'reject duplicate middle owner'
foreach($property in @('sequence','baseline','namedBranchPushAuthorized','productionAcceptance')) {
 $bad=($middle|ConvertTo-Json -Depth 50)|ConvertFrom-Json
 $bad.$property=if($property -eq 'namedBranchPushAuthorized'){$false}elseif($property -eq 'productionAcceptance'){$true}else{'foreign'}
 Check (!(Test-AiDomainMiddleCheckpoint $bad)) "reject changed middle checkpoint $property"
}
foreach($property in @('noWholeScopeCompletionClaimed','noProductionAcceptance','noLiveEffectsOrCloudOrApk','goalRemainsActive')) {
 $bad=($middle|ConvertTo-Json -Depth 50)|ConvertFrom-Json;$bad.disposition.$property=$false
 Check (!(Test-AiDomainMiddleCheckpoint $bad)) "reject changed partial qualification limit $property"
}
$bad=($middle|ConvertTo-Json -Depth 50)|ConvertFrom-Json;$bad.disposition.oppo.populatedAgentRequestsVerified=$true
Check (!(Test-AiDomainMiddleCheckpoint $bad)) 'reject fabricated populated device qualification'
$bad=($middle|ConvertTo-Json -Depth 50)|ConvertFrom-Json;$bad.disposition.hostEvidence.nativeWork=999
Check (!(Test-AiDomainMiddleCheckpoint $bad)) 'reject changed host test count'
foreach($property in @('path','sha256')) {
 $bad=($middle|ConvertTo-Json -Depth 50)|ConvertFrom-Json;$bad.evidence[0].$property='foreign'
 Check (!(Test-AiDomainMiddleCheckpoint $bad)) "reject changed qualified evidence $property"
}
foreach($row in @(@(0,4),@(1,21),@(2,1),@(3,0))) {
 $stageOwners=@(Get-AiDomainMiddleStageOwners $row[0] $middle)
 Check ($stageOwners.Count -eq $row[1]) "middle checkpoint stage $($row[0]) retains exact array owner count"
}
$cache=$approval.scope07AddressCacheAdmission
Check (Test-AiDomainAddressCacheAdmission $cache) 'exact original address-cache owner admission'
Check (@(Get-AiDomainCurrentRuntimeOwners $cache).Count -eq 34) 'only one new current owner; historical33 remains unchanged'
Check (@(Get-AiDomainAddressCacheAdmissionOwners).Count -eq 5) 'only five existing metadata owners for cache admission'
foreach($property in @('sequence','baseline','contract','contractSha256')) {
 $bad=($cache|ConvertTo-Json -Depth 20)|ConvertFrom-Json;$bad.$property='foreign'
 Check (!(Test-AiDomainAddressCacheAdmission $bad)) "reject changed cache admission $property"
}
foreach($property in @('path','bytes','sha256','gitBlobOid')) {
 $bad=($cache|ConvertTo-Json -Depth 20)|ConvertFrom-Json
 $bad.unchangedOwner.$property=if($property -eq 'bytes'){1}else{'foreign'}
 Check (!(Test-AiDomainAddressCacheAdmission $bad)) "reject changed cache baseline $property"
}
foreach($property in @('sourceFeatureCommitsAuthorized','backendBranchPushAuthorized','productionAcceptance','newMasterOrMigration')) {
 $bad=($cache|ConvertTo-Json -Depth 20)|ConvertFrom-Json;$bad.$property=$true
 Check (!(Test-AiDomainAddressCacheAdmission $bad)) "reject cache expanded $property"
 $bad.$property=$null
 Check (!(Test-AiDomainAddressCacheAdmission $bad)) "reject cache missing $property"
}
$bad=($cache|ConvertTo-Json -Depth 20)|ConvertFrom-Json;$bad.newOwners=@($bad.newOwners)+@('backend/functions/src/foreign.ts')
Check (!(Test-AiDomainAddressCacheAdmission $bad)) 'reject unrelated cache owner'
$rejected=$false
try {Get-AiDomainCurrentRuntimeOwners $bad|Out-Null}catch{$rejected=$true}
Check $rejected 'current owner getter rejects invalid admission'
$cacheSeal=$approval.scope07AddressCacheCheckpoint
Check (Test-AiDomainAddressCacheCheckpoint $cacheSeal) 'exact qualified original address checkpoint'
Check (@(Get-AiDomainAddressCacheSealOwners).Count -eq 3) 'only three existing metadata owners for address seal'
foreach($property in @('sequence','baseline','namedBranchPushAuthorized','productionAcceptance')) {
 $bad=($cacheSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json
 $bad.$property=if($property -eq 'namedBranchPushAuthorized'){$false}elseif($property -eq 'productionAcceptance'){$true}else{'foreign'}
 Check (!(Test-AiDomainAddressCacheCheckpoint $bad)) "reject changed cache seal $property"
}
foreach($property in @('path','bytes','sha256','gitBlobOid')) {
 $bad=($cacheSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json
 $bad.manifest.owners[0].$property=if($property -eq 'bytes'){1}else{'foreign'}
 Check (!(Test-AiDomainAddressCacheCheckpoint $bad)) "reject changed cache qualified source $property"
}
$bad=($cacheSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.manifest.changedOwners+=@('backend/functions/src/foreign.ts')
Check (!(Test-AiDomainAddressCacheCheckpoint $bad)) 'reject cache source expansion'
foreach($property in @('wholeScopeClosed','founderApprovalClaimed','productionAcceptance','liveEffect','apkBuiltOrInstalled')) {
 $bad=($cacheSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.disposition.$property=$true
 Check (!(Test-AiDomainAddressCacheCheckpoint $bad)) "reject expanded cache qualification $property"
}
$bad=($cacheSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.disposition.oppo.populatedAgentJourneyQualified=$true
Check (!(Test-AiDomainAddressCacheCheckpoint $bad)) 'reject fabricated address device execution'
foreach($property in @('path','sha256')) {
 $bad=($cacheSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.evidence[0].$property='foreign'
 Check (!(Test-AiDomainAddressCacheCheckpoint $bad)) "reject changed cache evidence $property"
}
foreach($row in @(@(0,3),@(1,4),@(2,1),@(3,0))) {
 Check (@(Get-AiDomainAddressCacheStageOwners $row[0] $cacheSeal).Count -eq $row[1]) "cache checkpoint exact stage $($row[0]) owner count"
}
$orderSeal=$approval.scope09OrderOriginalCheckpoint
Check (Test-AiDomainOrderOriginalCheckpoint $orderSeal) 'exact qualified original-order checkpoint'
Check (@(Get-AiDomainOrderOriginalSealOwners).Count -eq 3) 'only three existing metadata owners for original-order seal'
foreach($property in @('sequence','baseline','namedBranchPushAuthorized','productionAcceptance')) {
 $bad=($orderSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json
 $bad.$property=if($property -eq 'namedBranchPushAuthorized'){$false}elseif($property -eq 'productionAcceptance'){$true}else{'foreign'}
 Check (!(Test-AiDomainOrderOriginalCheckpoint $bad)) "reject changed original-order seal $property"
}
foreach($property in @('path','bytes','sha256','gitBlobOid')) {
 $bad=($orderSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json
 $bad.manifest.owners[0].$property=if($property -eq 'bytes'){1}else{'foreign'}
 Check (!(Test-AiDomainOrderOriginalCheckpoint $bad)) "reject changed original-order qualified source $property"
}
$bad=($orderSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.manifest.changedOwners+=@('backend/functions/src/foreign.ts')
Check (!(Test-AiDomainOrderOriginalCheckpoint $bad)) 'reject original-order source expansion'
foreach($property in @('wholeScopeClosed','founderApprovalClaimed','productionAcceptance','liveEffect','apkBuiltOrInstalled')) {
 $bad=($orderSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.disposition.$property=$true
 Check (!(Test-AiDomainOrderOriginalCheckpoint $bad)) "reject expanded original-order qualification $property"
}
$bad=($orderSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.disposition.oppo.populatedAgentJourneyQualified=$true
Check (!(Test-AiDomainOrderOriginalCheckpoint $bad)) 'reject fabricated original-order device execution'
foreach($property in @('path','sha256')) {
 $bad=($orderSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.evidence[0].$property='foreign'
 Check (!(Test-AiDomainOrderOriginalCheckpoint $bad)) "reject changed original-order evidence $property"
}
foreach($row in @(@(0,3),@(1,12),@(2,1),@(3,0))) {
 Check (@(Get-AiDomainOrderOriginalStageOwners $row[0] $orderSeal).Count -eq $row[1]) "original-order checkpoint exact stage $($row[0]) owner count"
}
$privateStars=$approval.scope10PrivateStarsTestAdmission
Check (Test-AiDomainPrivateStarsTestAdmission $privateStars) 'exact existing native055 test admission'
Check (@(Get-AiDomainPrivateStarsRuntimeOwners $privateStars $cache).Count -eq 35) 'only one existing native055 test added; historical34 unchanged'
foreach($property in @('sequence','baseline','contract')) {
 $bad=($privateStars|ConvertTo-Json -Depth 20)|ConvertFrom-Json;$bad.$property='foreign'
 Check (!(Test-AiDomainPrivateStarsTestAdmission $bad)) "reject changed private stars admission $property"
}
foreach($property in @('path','bytes','sha256','gitBlobOid')) {
 $bad=($privateStars|ConvertTo-Json -Depth 20)|ConvertFrom-Json
 $bad.unchangedOwner.$property=if($property -eq 'bytes'){1}else{'foreign'}
 Check (!(Test-AiDomainPrivateStarsTestAdmission $bad)) "reject changed private stars test baseline $property"
}
foreach($property in @('sourceFeatureCommitsAuthorized','backendBranchPushAuthorized','productionAcceptance','newMasterOrMigration')) {
 $bad=($privateStars|ConvertTo-Json -Depth 20)|ConvertFrom-Json;$bad.$property=$true
 Check (!(Test-AiDomainPrivateStarsTestAdmission $bad)) "reject expanded private stars authority $property"
}
$bad=($privateStars|ConvertTo-Json -Depth 20)|ConvertFrom-Json;$bad.newOwners+=@('backend/functions/src/foreign.ts')
Check (!(Test-AiDomainPrivateStarsTestAdmission $bad)) 'reject unrelated private stars owner'
$starsSeal=$approval.scope10PrivateStarsCheckpoint
Check (Test-AiDomainPrivateStarsCheckpoint $starsSeal) 'exact qualified private-rating checkpoint'
Check (@(Get-AiDomainPrivateStarsSealOwners).Count -eq 3) 'only three existing metadata owners for private-rating seal'
foreach($property in @('sequence','baseline','namedBranchPushAuthorized','productionAcceptance')) {
 $bad=($starsSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json
 $bad.$property=if($property -eq 'namedBranchPushAuthorized'){$false}elseif($property -eq 'productionAcceptance'){$true}else{'foreign'}
 Check (!(Test-AiDomainPrivateStarsCheckpoint $bad)) "reject changed private-rating seal $property"
}
foreach($property in @('path','bytes','sha256','gitBlobOid')) {
 $bad=($starsSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json
 $bad.manifest.owners[0].$property=if($property -eq 'bytes'){1}else{'foreign'}
 Check (!(Test-AiDomainPrivateStarsCheckpoint $bad)) "reject changed private-rating qualified source $property"
}
$bad=($starsSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.manifest.changedOwners+=@('backend/functions/src/foreign.ts')
Check (!(Test-AiDomainPrivateStarsCheckpoint $bad)) 'reject private-rating source expansion'
foreach($property in @('wholeScopeClosed','founderApprovalClaimed','productionAcceptance','liveEffect','apkBuiltOrInstalled')) {
 $bad=($starsSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.disposition.$property=$true
 Check (!(Test-AiDomainPrivateStarsCheckpoint $bad)) "reject expanded private-rating qualification $property"
}
$bad=($starsSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.disposition.oppo.populatedAgentJourneyQualified=$true
Check (!(Test-AiDomainPrivateStarsCheckpoint $bad)) 'reject fabricated private-rating device execution'
foreach($property in @('path','sha256')) {
 $bad=($starsSeal|ConvertTo-Json -Depth 60)|ConvertFrom-Json;$bad.evidence[0].$property='foreign'
 Check (!(Test-AiDomainPrivateStarsCheckpoint $bad)) "reject changed private-rating evidence $property"
}
foreach($row in @(@(0,3),@(1,12),@(2,1),@(3,0))) {
 Check (@(Get-AiDomainPrivateStarsStageOwners $row[0] $starsSeal).Count -eq $row[1]) "private-rating checkpoint exact stage $($row[0]) owner count"
}
Write-Output "AI domain batch admission checks passed: $n."
