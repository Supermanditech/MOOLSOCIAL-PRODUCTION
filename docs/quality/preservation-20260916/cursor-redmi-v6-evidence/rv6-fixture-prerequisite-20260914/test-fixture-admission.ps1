$ErrorActionPreference = 'Stop'
$repository = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$checker = [IO.File]::ReadAllText((Join-Path $repository 'scripts/check-codex-subagent-coordination-policy.ps1')).Replace("`r`n", "`n")
$start = $checker.IndexOf('      # Founder-approved RV6 fixture prerequisite:')
$end = $checker.IndexOf('      if ($head -ceq $successorParent)', $start)
if ($start -lt 0 -or $end -le $start) { throw 'Exact fixture guard not found.' }
$guard = [scriptblock]::Create($checker.Substring($start, $end - $start))
$owners = @('apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart', 'apps/mobile/test/ui_v2/buy/buy_v2_partner_catalogue_test.dart')
$successorParent = '9018535597239296871f9cf026e1e2a7328aca50'
$head = 'b437a216b3c61db9a7ef67968828b71ef7243474'
function Assert-Coordination([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
# Only Git discovery is stubbed; each case executes the actual source hash
# guard on independent copied files. No repository file or policy is modified.
function git {
  if ($args -contains '--name-only') {
    $global:LASTEXITCODE = 0
    return $script:caseDelta
  }
  if ($args -contains '--is-ancestor') {
    $global:LASTEXITCODE = $script:ancestorExit
    return
  }
  throw 'Unexpected Git operation in isolated fixture guard.'
}
$cases = @(
  @{name='exact'; pass=$true},
  @{name='changed-catalogue'; pass=$false; corrupt=0},
  @{name='changed-test'; pass=$false; corrupt=1},
  @{name='extra-owner'; pass=$false},
  @{name='missing-owner'; pass=$false},
  @{name='duplicate-owner'; pass=$false},
  @{name='wrong-ancestor'; pass=$false}
)
$runRoot = Join-Path $PSScriptRoot ('guard-cases-' + [guid]::NewGuid().ToString('N'))
$results = @()
foreach ($case in $cases) {
  $root = Join-Path $runRoot $case.name
  foreach ($owner in $owners) {
    $destination = Join-Path $root $owner
    $null = [IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
    [IO.File]::WriteAllBytes($destination, [IO.File]::ReadAllBytes((Join-Path $repository $owner)))
  }
  $script:caseDelta = @($owners)
  $script:ancestorExit = 0
  if ($case.ContainsKey('corrupt')) {
    [IO.File]::AppendAllText((Join-Path $root $owners[$case.corrupt]), "`n// negative fixture`n")
  }
  switch ($case.name) {
    'extra-owner' { $script:caseDelta += 'apps/mobile/lib/main.dart' }
    'missing-owner' { $script:caseDelta = @($owners[0]) }
    'duplicate-owner' { $script:caseDelta += $owners[0] }
    'wrong-ancestor' { $script:ancestorExit = 1 }
  }
  $accepted = $true
  $reason = ''
  try { & $guard } catch { $accepted = $false; $reason = $_.Exception.Message }
  if ($accepted -ne $case.pass) { throw "Unexpected admission outcome: $($case.name): $reason" }
  $results += [ordered]@{case=$case.name; accepted=$accepted; expected=$case.pass; reason=$reason}
}
$results | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $runRoot 'results.json') -Encoding utf8
Write-Output "Fixture admission: $($cases.Count) positive/negative cases passed. Evidence: $runRoot/results.json"
