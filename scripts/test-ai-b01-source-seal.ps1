[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'ai-b01-admission.ps1')
. (Join-Path $PSScriptRoot 'ai-b01-source-seal.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message) {if(!$Condition) {throw $Message}}
$cases=0
function Check([bool]$Condition,[string]$Name) {if(!$Condition) {throw "AI seal test: $Name"};$script:cases++}
$root=Split-Path -Parent $PSScriptRoot
$facts=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-ai-b01-20261027';Branch='work/codex-backend/ai-b01-20261027';Lane='codex_backend';Role='primary';Task='/root/codex_backend_ai_b01';WorkId='ai-b01-20261027';Ticket='AI-B01';Phase='implementation'}
Check (Test-AiB01Identity $facts) 'exact implementation'
foreach($key in $facts.Keys) {$bad=$facts.Clone();$bad[$key]='foreign';Check (!(Test-AiB01Identity $bad)) "foreign $key"}
foreach($phase in @('build','deployment','ticket_close','ticket_acceptance','handoff')) {$bad=$facts.Clone();$bad.Phase=$phase;Check (!(Test-AiB01Identity $bad)) "blocked $phase"}
Check ((Get-AiSealStage 0) -ceq 'metadata') 'metadata'
Check ((Get-AiSealStage 1) -ceq 'source') 'source'
Check ((Get-AiSealStage 2) -ceq 'evidence') 'evidence'
Check ((Get-AiSealStage 3) -ceq 'sealed') 'sealed'
foreach($count in @(-1,4,5)) {$rejected=$false;try {Get-AiSealStage $count|Out-Null}catch {$rejected=$true};Check $rejected "reject $count"}
$record=Get-Content -Raw (Join-Path $root 'docs/quality/AI-B01-SOURCE-SEAL-20261027.json')|ConvertFrom-Json
Check ((Get-AiSealDigest (Join-Path $root 'docs/quality/AI-B01-SOURCE-SEAL-20261027.json')) -ceq '40138E99169AE4FB2D106D023DA6B3EDBEFA6599C89CD1CAE2BF3DA41B59CDD9') 'bound record'
Check ($record.sourceOwners.Count -eq 17 -and $record.metadataOwners.Count -eq 5 -and $record.evidenceOwners.Count -eq 3) 'exact counts'
Check (Test-AiSealSet $record.sourceOwners $record.files.path) 'manifest set'
Check (!(Test-AiSealSet @($record.sourceOwners[0]) $record.sourceOwners)) 'missing source rejected'
Check (!(Test-AiSealSet @($record.sourceOwners+'main.dart') $record.sourceOwners)) 'extra source rejected'
Check (!$record.productionAcceptance -and !$record.formalTicketClose) 'no live acceptance'
Check ($record.remoteRef -ceq 'refs/heads/work/codex-backend/ai-b01-20261027') 'only named branch'
foreach($file in $record.files) {Check ((Get-AiSealDigest (Join-Path $root $file.path)) -ceq $file.normalizedSha256.ToUpperInvariant()) "exact source $($file.path)"}
$original=@(& git -C $root show 'c2a225c5463df4f71ed2ac905a0cb47ef4cf4611:scripts/check-codex-subagent-coordination-policy.ps1')
if($LASTEXITCODE -ne 0) {throw 'Missing original checker'}
# Literal comparison permits only the single dispatch; all historical bodies stay byte-equivalent after line-ending normalization.
$current=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1')).Replace("`r`n","`n")
$lines=@($current -split "`n"|Where-Object {$_ -notmatch '^  if\(Test-Path -LiteralPath .*AI-B01-SOURCE-SEAL-20261027.json'})
Check (($lines -join "`n").TrimEnd() -ceq ($original -join "`n").TrimEnd()) 'historical bodies preserved'
Write-Output "AI-B01 source-seal checks passed: $cases."
