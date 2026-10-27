[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'ai-b01-admission.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$cases=0
function Check([bool]$Condition,[string]$Name){if(!$Condition){throw "AI-B01 admission regression: $Name"};$script:cases++}
$facts=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-ai-b01-20261027';
 Branch='work/codex-backend/ai-b01-20261027';Lane='codex_backend';Role='primary';
 Task='/root';WorkId='ai-b01-20261027';Ticket='AI-B01';Phase='coordination_bootstrap'}
Check (Test-AiB01Identity $facts) 'exact bootstrap'
foreach($phase in @('task_start','pre_commit','implementation')){
 $f=$facts.Clone();$f.Phase=$phase;$f.Task='/root/codex_backend_ai_b01'
 Check (Test-AiB01Identity $f) "exact $phase"
}
foreach($key in @('Root','Branch','Lane','Role','Task','WorkId','Ticket','Phase')){
 $f=$facts.Clone();$f.Remove($key);Check (!(Test-AiB01Identity $f)) "missing $key"
 $f=$facts.Clone();$f[$key]='foreign';Check (!(Test-AiB01Identity $f)) "foreign $key"
 $f=$facts.Clone();$f[$key]=@($facts[$key]);Check (!(Test-AiB01Identity $f)) "array $key"
}
foreach($phase in @('build','deployment','handoff','ticket_close','ticket_acceptance')){
 $f=$facts.Clone();$f.Phase=$phase;Check (!(Test-AiB01Identity $f)) "unadmitted $phase"
}
$runtime=@(Get-AiB01RuntimeOwners);$metadata=@(Get-AiB01MetadataOwners)
Check ($runtime.Count -eq 18 -and @($runtime|Sort-Object -Unique).Count -eq 18) 'exact runtime count'
Check ($metadata.Count -eq 9 -and @($metadata|Sort-Object -Unique).Count -eq 9) 'exact metadata count'
foreach($owner in @('apps/mobile/lib/main.dart','backend/functions/package.json',
 'apps/admin/src/main.ts','config/mvp-scope-policy.json','dataconnect/schema/../schema/universal.gql')){
 $rejected=$false;try{Assert-AiB01Owners @($owner) @($metadata+$runtime)}catch{$rejected=$true}
 Check $rejected "foreign owner $owner"
}
$root=Split-Path -Parent $PSScriptRoot
$base='88e53a271dafe8eec839c80eaa9e96ee56cf9466'
$original=@(& git -C $root show "${base}:scripts/check-codex-subagent-coordination-policy.ps1")
if($LASTEXITCODE -ne 0){throw 'Missing sealed original checker'}
$text=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1'))
$pattern='(?ms)^# Founder-approved AI-B01: bounded local typed model preparation only\.\r?\nif \(\$ProductionTicketId.*?^\}\r?\n\r?\n'
Check ([regex]::Matches($text,$pattern).Count -eq 1) 'one AI-B01 dispatch'
Check (([regex]::Replace($text,$pattern,'').Replace("`r`n","`n").TrimEnd()) -ceq (($original -join "`n").TrimEnd())) 'historical admission bodies unchanged'
$contract='docs/quality/AI-B01-CONTRACT-20261027.md'
Check ((Get-FileHash (Join-Path $root $contract)).Hash -ceq '310A623C6C83603918C00FA73971A1C8C86AE8C50131DBE3912DF0B6D7B3787E') 'contract exact bytes'
$record=Get-Content -Raw (Join-Path $root 'docs/quality/AI-B01-BACKEND-20261027.json')|ConvertFrom-Json
Check (!$record.execution.buildAuthorized -and !$record.execution.deviceInstallAuthorized -and
 !$record.execution.externalServiceWriteAuthorized -and !$record.backendAdmission.deployment -and
 !$record.backendAdmission.sqlProvisioning -and !$record.backendAdmission.backendBranchPush) 'release and billing limits'
Write-Output "AI-B01 admission regression checks passed: $cases."
