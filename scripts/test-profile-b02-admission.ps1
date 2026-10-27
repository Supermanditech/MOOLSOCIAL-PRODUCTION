[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'profile-b02-admission.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$cases=0
function Check([bool]$Condition,[string]$Name){if(!$Condition){throw "B02 admission regression: $Name"};$script:cases++}
$facts=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-profile-b02-20261027';
 Branch='work/codex-backend/profile-b02-20261027';Lane='codex_backend';Role='primary';
 Task='/root';WorkId='profile-b02-20261027';Ticket='PROFILE-B02';Phase='coordination_bootstrap'}
Check (Test-ProfileB02Identity $facts) 'exact bootstrap'
foreach($phase in @('task_start','pre_commit','implementation')){
 $f=$facts.Clone();$f.Phase=$phase;$f.Task='/root/codex_backend_profile_b02'
 Check (Test-ProfileB02Identity $f) "exact $phase"
}
foreach($key in @('Root','Branch','Lane','Role','Task','WorkId','Ticket','Phase')){
 $f=$facts.Clone();$f.Remove($key);Check (!(Test-ProfileB02Identity $f)) "missing $key"
 $f=$facts.Clone();$f[$key]='foreign';Check (!(Test-ProfileB02Identity $f)) "foreign $key"
 $f=$facts.Clone();$f[$key]=@($facts[$key]);Check (!(Test-ProfileB02Identity $f)) "array $key"
}
foreach($phase in @('build','deployment','handoff','ticket_close','ticket_acceptance')){
 $f=$facts.Clone();$f.Phase=$phase;Check (!(Test-ProfileB02Identity $f)) "unadmitted $phase"
}
$runtime=@(Get-ProfileB02RuntimeOwners);$metadata=@(Get-ProfileB02MetadataOwners)
Check ($runtime.Count -eq 21 -and @($runtime|Sort-Object -Unique).Count -eq 21) 'exact runtime count'
Check ($metadata.Count -eq 9 -and @($metadata|Sort-Object -Unique).Count -eq 9) 'exact metadata count'
foreach($owner in @('apps/mobile/lib/main.dart','backend/functions/package.json',
 'apps/admin/src/main.ts','config/mvp-scope-policy.json','dataconnect/schema/../schema/universal.gql')){
 $rejected=$false;try{Assert-ProfileB02Owners @($owner) @($metadata+$runtime)}catch{$rejected=$true}
 Check $rejected "foreign owner $owner"
}
$root=Split-Path -Parent $PSScriptRoot
$base='955f793dcfc593b603797d9e960925f774a6c2c2'
$original=@(& git -C $root show "${base}:scripts/check-codex-subagent-coordination-policy.ps1")
if($LASTEXITCODE -ne 0){throw 'Missing sealed original checker'}
$text=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1'))
$pattern='(?ms)^# Founder-approved PROFILE-B02: exact local catalogue/entitlement continuation only\.\r?\nif \(\$ProductionTicketId.*?^\}\r?\n\r?\n'
Check ([regex]::Matches($text,$pattern).Count -eq 1) 'one B02 dispatch'
Check (([regex]::Replace($text,$pattern,'').Replace("`r`n","`n").TrimEnd()) -ceq (($original -join "`n").TrimEnd())) 'historical admission bodies unchanged'
$contract='docs/quality/PROFILE-B02-CONTRACT-20261027.md'
Check ((Get-FileHash (Join-Path $root $contract)).Hash -ceq '44233B52F1FE9371D37BDE8476D8B6FA18305E5CCD2B9F20AC110514B22E2F9A') 'contract exact bytes'
$record=Get-Content -Raw (Join-Path $root 'docs/quality/PROFILE-B02-BACKEND-20261027.json')|ConvertFrom-Json
Check (!$record.execution.buildAuthorized -and !$record.execution.deviceInstallAuthorized -and
 !$record.execution.externalServiceWriteAuthorized -and !$record.backendAdmission.deployment -and
 !$record.backendAdmission.sqlProvisioning -and !$record.backendAdmission.backendBranchPush) 'release and billing limits'
Write-Output "PROFILE-B02 admission regression checks passed: $cases."
