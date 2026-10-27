$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'ai-domain-batch-admission.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$n=0;function Check([bool]$c,[string]$m){if(!$c){throw $m};$script:n++}
$f=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-ai-domain-batch-20261028';Branch='work/codex-backend/ai-domain-batch-20261028';Lane='codex_backend';Role='primary';WorkId='ai-domain-batch-20261028';Ticket='AI-DOMAIN-BATCH-20';Task='/root/codex_backend_ai_domain_batch';Phase='implementation'}
Check (Test-AiDomainBatchIdentity $f) 'identity'
foreach($k in $f.Keys){$b=$f.Clone();$b[$k]='foreign';Check (!(Test-AiDomainBatchIdentity $b)) "foreign $k";$b=$f.Clone();$b.Remove($k);Check (!(Test-AiDomainBatchIdentity $b)) "missing $k"}
foreach($phase in @('build','deploy','ticket_acceptance','handoff')){$b=$f.Clone();$b.Phase=$phase;Check (!(Test-AiDomainBatchIdentity $b)) "forbidden $phase"}
Check (@(Get-AiDomainBatchRuntimeOwners).Count -eq 30) '30 exact runtime/test owners';Check (@(Get-AiDomainBatchMetadataOwners).Count -eq 10) 'ten exact metadata owners'
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
Write-Output "AI domain batch admission checks passed: $n."
