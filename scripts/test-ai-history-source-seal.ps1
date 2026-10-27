[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'ai-history-admission.ps1')
. (Join-Path $PSScriptRoot 'ai-history-source-seal.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message) {if(!$Condition) {throw $Message}}
$cases=0
function Check([bool]$Condition,[string]$Name) {if(!$Condition) {throw "AI seal test: $Name"};$script:cases++}
$root=Split-Path -Parent $PSScriptRoot
$facts=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-ai-history-20261028';Branch='work/codex-backend/ai-history-20261028';Lane='codex_backend';Role='primary';Task='/root/codex_backend_ai_history';WorkId='ai-history-20261028';Ticket='AI-HISTORY-01';Phase='implementation'}
Check (Test-AiHistoryIdentity $facts) 'exact implementation'
foreach($key in $facts.Keys) {$bad=$facts.Clone();$bad[$key]='foreign';Check (!(Test-AiHistoryIdentity $bad)) "foreign $key"}
foreach($phase in @('build','deployment','ticket_close','ticket_acceptance','handoff')) {$bad=$facts.Clone();$bad.Phase=$phase;Check (!(Test-AiHistoryIdentity $bad)) "blocked $phase"}
Check ((Get-HistorySealStage 0) -ceq 'metadata') 'metadata'
Check ((Get-HistorySealStage 1) -ceq 'source') 'source'
Check ((Get-HistorySealStage 2) -ceq 'evidence') 'evidence'
Check ((Get-HistorySealStage 3) -ceq 'sealed') 'sealed'
foreach($count in @(-1,4,5)) {$rejected=$false;try {Get-HistorySealStage $count|Out-Null}catch {$rejected=$true};Check $rejected "reject $count"}
$record=Get-Content -Raw (Join-Path $root 'docs/quality/AI-HISTORY-SOURCE-SEAL-20261028.json')|ConvertFrom-Json
Check ((Get-HistorySealDigest (Join-Path $root 'docs/quality/AI-HISTORY-SOURCE-SEAL-20261028.json')) -ceq '32D147CF73B9A6CD06C0EDADB8ED17A2A8C4C8926509D5D42E9B3E020C35D2F5') 'bound record'
Check ($record.sourceOwners.Count -eq 21 -and $record.metadataOwners.Count -eq 5 -and $record.evidenceOwners.Count -eq 3) 'exact counts'
Check (Test-HistorySealSet $record.sourceOwners $record.files.path) 'manifest set'
Check (!(Test-HistorySealSet @($record.sourceOwners[0]) $record.sourceOwners)) 'missing source rejected'
Check (!(Test-HistorySealSet @($record.sourceOwners+'main.dart') $record.sourceOwners)) 'extra source rejected'
Check (!$record.productionAcceptance -and !$record.formalTicketClose) 'no live acceptance'
Check ($record.remoteRef -ceq 'refs/heads/work/codex-backend/ai-history-20261028') 'only named branch'
foreach($file in $record.files) {Check ((Get-HistorySealDigest (Join-Path $root $file.path)) -ceq $file.normalizedSha256.ToUpperInvariant()) "exact source $($file.path)"}
$original=@(& git -C $root show '9fbf17f91f5df462c9bd7d6347e2a224cf956e7a:scripts/check-codex-subagent-coordination-policy.ps1')
if($LASTEXITCODE -ne 0) {throw 'Missing original checker'}
# Literal comparison permits only the single dispatch; all historical bodies stay byte-equivalent after line-ending normalization.
$current=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1')).Replace("`r`n","`n")
$lines=@($current -split "`n"|Where-Object {$_ -notmatch '^  if\(Test-Path -LiteralPath .*AI-HISTORY-SOURCE-SEAL-20261028.json'})
Check (($lines -join "`n").TrimEnd() -ceq ($original -join "`n").TrimEnd()) 'historical bodies preserved'
Write-Output "AI-HISTORY source-seal checks passed: $cases."
