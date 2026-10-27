[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'profile-combined-admission.ps1')
function Assert-Coordination([bool]$Condition,[string]$Message){if(!$Condition){throw $Message}}
$cases=0
function Check([bool]$Condition,[string]$Name){
  if(!$Condition){throw "COMBINED admission regression: $Name"}; $script:cases++
}
$binding=Get-ProfileCombinedBinding
$facts=@{Root=$binding.worktreePath; Branch=$binding.branch; Lane=$binding.lane;
  WorkId=$binding.workId; Ticket=$binding.ticketId; Role='primary';
  Task='/root'; Phase='coordination_bootstrap'}
Check (Test-ProfileCombinedIdentity $facts) 'exact bootstrap accepted'
foreach($phase in @('task_start','implementation','pre_commit')){
  $f=$facts.Clone(); $f.Phase=$phase; $f.Task=$binding.task
  Check (Test-ProfileCombinedIdentity $f) "exact $phase accepted"
}
foreach($key in @('Root','Branch','Lane','WorkId','Ticket','Role','Task','Phase')){
  $f=$facts.Clone(); $f.Remove($key)
  Check (!(Test-ProfileCombinedIdentity $f)) "missing $key refused"
  $f=$facts.Clone(); $f[$key]='foreign'
  Check (!(Test-ProfileCombinedIdentity $f)) "foreign $key refused"
  $f=$facts.Clone(); $f[$key]=@($facts[$key],$facts[$key])
  Check (!(Test-ProfileCombinedIdentity $f)) "array $key refused"
}
foreach($phase in @('handoff','ticket_close','candidate_preflight','build','deployment')){
  $f=$facts.Clone(); $f.Phase=$phase
  Check (!(Test-ProfileCombinedIdentity $f)) "unapproved $phase refused"
}
$f=$facts.Clone(); $f.Task=$binding.task
Check (!(Test-ProfileCombinedIdentity $f)) 'bootstrap requires primary coordinator'
$f=$facts.Clone(); $f.Phase='implementation'
Check (!(Test-ProfileCombinedIdentity $f)) 'implementation requires exact backend claim'
$runtime=@(Get-ProfileCombinedRuntimeOwners)
Check ($runtime.Count -eq 27 -and @($runtime|Sort-Object -Unique).Count -eq 27) 'exact twenty-seven combined runtime owners'
Check (@($binding.bootstrapOwners).Count -eq 9) 'exact nine metadata owners including contract LF pin'
foreach($owner in @('apps/mobile/lib/main.dart','backend/functions/package.json',
    'backend/functions/src/account/unrelated_admin_command.ts',
    'apps/mobile/lib/ui_v2/profile/global_profile_panel_v2.dart',
    'dataconnect/schema/../provider_integrations.gql','config/mvp-scope-policy.json')){
  $rejected=$false
  try { Assert-ProfileCombinedOwners @($owner) @($runtime+$binding.bootstrapOwners) }catch{$rejected=$true}
  Check $rejected "unrelated owner $owner refused"
}
foreach($owner in $runtime){Assert-ProfileCombinedOwners @($owner) $runtime}
Check $true 'existing selected source/test owners accepted'
$root=Split-Path -Parent $PSScriptRoot
$baseScript=@(& git -C $root show "$($binding.baselineHead):scripts/check-codex-subagent-coordination-policy.ps1")
if($LASTEXITCODE -ne 0){throw 'Missing sealed checker'}
$actual=[IO.File]::ReadAllText((Join-Path $root 'scripts/check-codex-subagent-coordination-policy.ps1'))
$pattern='(?ms)^# Founder-approved PROFILE-INTEGRATION-01 follows the sealed Profile source, preserving\r?\n# the historical frontend/integration admission bodies unchanged\.\r?\nif \(\$ProductionTicketId.*?^\}\r?\n\r?\n'
$matches=[regex]::Matches($actual,$pattern)
Check ($matches.Count -eq 1) 'one exact COMBINED dispatch block'
$without=[regex]::Replace($actual,$pattern,'') -replace '\r\n',"`n"
Check ($without.TrimEnd() -ceq (($baseScript -join "`n").TrimEnd())) 'all historical checker lines unchanged'
$contract='docs/quality/PROFILE-INTEGRATION-01-CONTRACT-20261027.md'
$filtered=@(& git -C $root check-attr eol -- $contract)
Check ($LASTEXITCODE -eq 0 -and $filtered.Count -eq 1 -and $filtered[0] -ceq ($contract+': eol: lf')) 'approved contract checkout bytes pinned to LF'
$record=Get-Content -Raw -LiteralPath (Join-Path $root 'docs/quality/PROFILE-INTEGRATION-01-20261027.json')|ConvertFrom-Json
Check (!$record.execution.buildAuthorized -and !$record.execution.deviceInstallAuthorized -and
  !$record.execution.externalServiceWriteAuthorized -and !$record.backendAdmission.sqlProvisioning -and
  !$record.backendAdmission.sqlMigration -and !$record.backendAdmission.deployment -and
  !$record.backendAdmission.backendBranchPush) 'commercial/release/provisioning exclusions retained'
foreach($step in 0..2){
  $subject=@('coordination(profile-combined-20261027): admit exact source sealing',
    'codex_backend(profile-combined-20261027): seal tested B01 B03 source',
    'evidence(profile-combined-20261027): bind source checkpoint and limits')[$step]
  $owners=switch($step){0{Get-ProfileCombinedSealingMetadata};1{Get-ProfileCombinedRuntimeOwners};2{'docs/quality/PROFILE-INTEGRATION-01-20261027.json'}}
  Check (Test-ProfileCombinedSealingDelta $step $subject $owners) "exact sealing step $step"
  Check (!(Test-ProfileCombinedSealingDelta $step 'foreign' $owners)) "sealing subject $step isolation"
  Check (!(Test-ProfileCombinedSealingDelta $step $subject @($owners+'apps/mobile/lib/main.dart'))) "sealing owner $step isolation"
  Check (!(Test-ProfileCombinedSealingDelta $step $subject @($owners|Select-Object -Skip 1))) "sealing omission $step refused"
}
Check (!(Test-ProfileCombinedSealingDelta 3 'foreign' @())) 'extra sealing commit refused'
Write-Output "PROFILE-INTEGRATION-01 admission regression checks passed: $cases. No backend behaviour or device qualification is claimed."
