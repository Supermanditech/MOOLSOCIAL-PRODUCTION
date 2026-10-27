$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'thin-b07-b04-admission.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$n=0;function Check([bool]$c,[string]$m){if(!$c){throw $m};$script:n++}
$f=@{Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-thin-b07-b04-20261027';Branch='work/codex-backend/thin-b07-b04-20261027';Lane='codex_backend';Role='primary';WorkId='thin-b07-b04-20261027';Ticket='THIN-B07-B04-PROFILE';Task='/root/codex_backend_thin_b07_b04';Phase='implementation'}
Check (Test-ThinB07B04Identity $f) 'identity'
foreach($k in $f.Keys){$b=$f.Clone();$b[$k]='foreign';Check (!(Test-ThinB07B04Identity $b)) "foreign $k";$b=$f.Clone();$b.Remove($k);Check (!(Test-ThinB07B04Identity $b)) "missing $k"}
foreach($phase in @('build','deploy','ticket_acceptance','handoff')){$b=$f.Clone();$b.Phase=$phase;Check (!(Test-ThinB07B04Identity $b)) "forbidden $phase"}
Check (@(Get-ThinB07B04RuntimeOwners).Count -eq 34) '34 exact runtime including erasure';Check (@(Get-ThinB07B04MetadataOwners).Count -eq 9) 'nine metadata'
$root=Split-Path -Parent $PSScriptRoot
Check ($root.Replace('\','/') -ceq $f.Root) 'actual checkout root matches identity'
Check ((Get-FileHash (Join-Path $root 'docs/quality/THIN-B07-B04-CONTRACT-20261027.md')).Hash -ceq '23B6413B17C57F2E9ABE7E03D16F916C32C27908E65BED900663E02D7F67E382') 'contract bytes'
$original=@(& git -C $root show '566c88f6b3698648a6f4facbdc01b86c5ecf42bb:scripts/check-codex-subagent-coordination-policy.ps1');if($LASTEXITCODE -ne 0){throw 'original missing'}
$current=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1'))
$pattern='(?ms)^# Founder-approved combined B07/B04 Profile-only local goal\.\r?\nif \(\$ProductionTicketId.*?^\}\r?\n\r?\n'
Check ([regex]::Matches($current,$pattern).Count -eq 1) 'one dispatch'
Check (([regex]::Replace($current,$pattern,'').Replace("`r`n","`n").TrimEnd()) -ceq (($original -join "`n").TrimEnd())) 'old gates unchanged'
$amend=Get-Content -Raw (Join-Path $root 'docs/quality/THIN-B07-B04-ERASURE-ACCEPTANCE-20261028.json')|ConvertFrom-Json
Check ($amend.runtimeOwner -ceq 'dataconnect/provider/youtube.gql' -and $amend.additionalMetadataCommits -eq 1 -and !$amend.sourceFeatureCommits -and !$amend.push -and $amend.scopeUnchanged) 'bounded erasure authority'
Check ((Get-FileHash (Join-Path $root $amend.addendum)).Hash -ceq 'EFAA6776F0B4F928FFE84A9162FCD42161C292432F608A575C382DDFA1034C1A') 'immutable erasure addendum'
Check ($amend.standingFounderMessage -ceq 'keep this standing authorisation or approval if needed while i am away') 'actual founder standing approval'
Write-Output "Combined admission checks passed: $n."
