[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'thin-b03-admission.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$cases=0
function Check([bool]$Condition,[string]$Name){if(!$Condition){throw "THIN-B03 admission regression: $Name"};$script:cases++}
$facts=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-thin-b03-20261027';
 Branch='work/codex-backend/thin-b03-20261027';Lane='codex_backend';Role='primary';
 Task='/root';WorkId='thin-b03-20261027';Ticket='THIN-B03';Phase='coordination_bootstrap'}
Check (Test-ThinB03Identity $facts) 'exact bootstrap'
foreach($phase in @('task_start','pre_commit','implementation')){
 $f=$facts.Clone();$f.Phase=$phase;$f.Task='/root/codex_backend_thin_b03'
 Check (Test-ThinB03Identity $f) "exact $phase"
}
foreach($key in @('Root','Branch','Lane','Role','Task','WorkId','Ticket','Phase')){
 $f=$facts.Clone();$f.Remove($key);Check (!(Test-ThinB03Identity $f)) "missing $key"
 $f=$facts.Clone();$f[$key]='foreign';Check (!(Test-ThinB03Identity $f)) "foreign $key"
 $f=$facts.Clone();$f[$key]=@($facts[$key]);Check (!(Test-ThinB03Identity $f)) "array $key"
}
foreach($phase in @('build','deployment','handoff','ticket_close','ticket_acceptance')){
 $f=$facts.Clone();$f.Phase=$phase;Check (!(Test-ThinB03Identity $f)) "unadmitted $phase"
}
$runtime=@(Get-ThinB03RuntimeOwners);$metadata=@(Get-ThinB03MetadataOwners)
Check ($runtime.Count -eq 28 -and @($runtime|Sort-Object -Unique).Count -eq 28) 'exact runtime count'
Check ($metadata.Count -eq 9 -and @($metadata|Sort-Object -Unique).Count -eq 9) 'exact metadata count'
foreach($owner in @('apps/mobile/lib/main.dart','backend/functions/package.json',
 'apps/admin/src/main.ts','config/mvp-scope-policy.json','dataconnect/schema/../schema/universal.gql')){
 $rejected=$false;try{Assert-ThinB03Owners @($owner) @($metadata+$runtime)}catch{$rejected=$true}
 Check $rejected "foreign owner $owner"
}
$root=Split-Path -Parent $PSScriptRoot
$base='da3333ed69bfb7c187320d2294b1e1953ee3bc60'
$original=@(& git -C $root show "${base}:scripts/check-codex-subagent-coordination-policy.ps1")
if($LASTEXITCODE -ne 0){throw 'Missing sealed original checker'}
$text=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1'))
$pattern='(?ms)^# Founder-approved THIN-B03: bounded local authorised Profile and Workspace context only\.\r?\nif \(\$ProductionTicketId.*?^\}\r?\n\r?\n'
Check ([regex]::Matches($text,$pattern).Count -eq 1) 'one THIN-B03 dispatch'
Check (([regex]::Replace($text,$pattern,'').Replace("`r`n","`n").TrimEnd()) -ceq (($original -join "`n").TrimEnd())) 'historical admission bodies unchanged'
$contract='docs/quality/THIN-B03-CONTRACT-20261027.md'
Check ((Get-FileHash (Join-Path $root $contract)).Hash -ceq '224C61B3546E7F0D3C81F55651C6207AE61D63CCCEC73F6A5A5BE7D30788456A') 'contract exact bytes'
$record=Get-Content -Raw (Join-Path $root 'docs/quality/THIN-B03-BACKEND-20261027.json')|ConvertFrom-Json
Check (!$record.execution.buildAuthorized -and !$record.execution.deviceInstallAuthorized -and
 !$record.execution.externalServiceWriteAuthorized -and !$record.backendAdmission.deployment -and
 !$record.backendAdmission.sqlProvisioning -and !$record.backendAdmission.backendBranchPush) 'release and billing limits'
Write-Output "THIN-B03 admission regression checks passed: $cases."
