$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'ai-history-admission.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$n=0;function Check([bool]$c,[string]$m){if(!$c){throw $m};$script:n++}
$f=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-ai-history-20261028';Branch='work/codex-backend/ai-history-20261028';Lane='codex_backend';Role='primary';WorkId='ai-history-20261028';Ticket='AI-HISTORY-01';Task='/root/codex_backend_ai_history';Phase='implementation'}
Check (Test-AiHistoryIdentity $f) 'identity'
foreach($k in $f.Keys){$b=$f.Clone();$b[$k]='foreign';Check (!(Test-AiHistoryIdentity $b)) "foreign $k";$b=$f.Clone();$b.Remove($k);Check (!(Test-AiHistoryIdentity $b)) "missing $k"}
foreach($phase in @('build','deploy','ticket_acceptance','handoff')){$b=$f.Clone();$b.Phase=$phase;Check (!(Test-AiHistoryIdentity $b)) "forbidden $phase"}
Check (@(Get-AiHistoryRuntimeOwners).Count -eq 21) '33 runtime';Check (@(Get-AiHistoryMetadataOwners).Count -eq 9) 'nine metadata'
$root=Split-Path -Parent $PSScriptRoot
Check ($root.Replace('\','/') -ceq $f.Root) 'actual checkout root matches identity'
Check ((Get-FileHash (Join-Path $root 'docs/quality/AI-HISTORY-CONTRACT-20261028.md')).Hash -ceq '39CDABA8770338E6D370C92445A77D8702E0FAABDACEBA9EA51536EC25963965') 'contract bytes'
$original=@(& git -C $root show '9499d740a5171d892702387ceb1e5f6a413a336a:scripts/check-codex-subagent-coordination-policy.ps1');if($LASTEXITCODE -ne 0){throw 'original missing'}
$current=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1'))
$pattern='(?ms)^# Founder-delegated bounded text History goal\.\r?\nif \(\$ProductionTicketId.*?^\}\r?\n\r?\n'
Check ([regex]::Matches($current,$pattern).Count -eq 1) 'one dispatch'
Check (([regex]::Replace($current,$pattern,'').Replace("`r`n","`n").TrimEnd()) -ceq (($original -join "`n").TrimEnd())) 'old gates unchanged'
Write-Output "AI History admission checks passed: $n."
