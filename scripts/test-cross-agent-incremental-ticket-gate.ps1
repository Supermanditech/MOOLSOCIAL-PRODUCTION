[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireCompatibilityProbes,
  [switch]$RequireLf01Probes,
  [switch]$RequireLfPublicationProbes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$sourceRoot = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$gate = Join-Path $sourceRoot `
  'scripts\check-cross-agent-incremental-ticket-gate.ps1'
$state = Join-Path $sourceRoot `
  'config\cross-agent-incremental-ticket-gate.json'

function Assert-Fixture([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Incremental ticket fixture rejected: $Message"
  }
}

function Invoke-FixtureGit([string]$Root, [string[]]$Arguments) {
  # Windows PowerShell reports successful native stderr as ErrorRecord objects.
  # Capture it without treating a normal Git progress message as command failure.
  $previousPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $result = @(& git -C $Root @Arguments 2>&1)
    $nativeExit = $LASTEXITCODE
  } finally { $ErrorActionPreference = $previousPreference }
  if ($nativeExit -ne 0) {
    throw "Fixture Git failed: git $($Arguments -join ' ') :: $result"
  }
}

function Assert-GateFails([scriptblock]$Invocation, [string]$Expected) {
  $failed = $false
  try {
    $null = & $Invocation
  } catch {
    $failed = $_.Exception.Message.IndexOf(
      $Expected,
      [StringComparison]::Ordinal
    ) -ge 0
  }
  Assert-Fixture $failed "negative fixture did not fail with: $Expected"
}

if ($RequireLfPublicationProbes) {
  $checker = Join-Path $sourceRoot 'scripts/check-codex-subagent-coordination-policy.ps1'
  $tokens=$null; $errors=$null
  $ast=[Management.Automation.Language.Parser]::ParseFile($checker,[ref]$tokens,[ref]$errors)
  Assert-Fixture ($errors.Count -eq 0) 'publication checker has parse errors.'
  $identity=@($ast.FindAll({param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
      $node.Name -ceq 'Test-Lf01AdmissionIdentity'
  },$true))
  Assert-Fixture ($identity.Count -eq 1) 'LF identity predicate absent/duplicated.'
  . ([scriptblock]::Create($identity[0].Extent.Text))
  $facts=@{Root=$sourceRoot.Replace('\','/');Branch='work/codex-ui/last-frontend-lf01-20261015'
    Role='primary';Task='/root';Lane='codex_ui';WorkId='last-frontend-lf01-20261015'
    Ticket='LF-27';Phase='handoff'}
  Assert-Fixture (Test-Lf01AdmissionIdentity $facts) 'accepted LF27 publication identity rejected.'
  $cases=1
  foreach($key in @($facts.Keys)) {
    $probe=$facts.Clone();$probe[$key]='unrelated'
    Assert-Fixture (-not (Test-Lf01AdmissionIdentity $probe)) "publication changed $key admitted."
    $probe=$facts.Clone();$probe.Remove($key)
    Assert-Fixture (-not (Test-Lf01AdmissionIdentity $probe)) "publication missing $key admitted."
    $cases+=2
  }
  foreach($ticket in @('LF-01','LF-26')) {
    $probe=$facts.Clone();$probe.Ticket=$ticket
    Assert-Fixture (-not (Test-Lf01AdmissionIdentity $probe)) 'another ticket gained publication.'
    $cases++
  }
  $delta=@($ast.FindAll({param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
      $node.Name -ceq 'Test-Lf27PublicationDelta'
  },$true))
  Assert-Fixture ($delta.Count -eq 1) 'publication delta predicate absent/duplicated.'
  . ([scriptblock]::Create($delta[0].Extent.Text))
  $accepted='7d550665cff4a48d2f06735f6bc065008e82f8d5'
  $successor='1111111111111111111111111111111111111111'
  $metadata=@('scripts/check-codex-subagent-coordination-policy.ps1',
    'scripts/check-cross-agent-incremental-ticket-gate.ps1',
    'scripts/test-cross-agent-incremental-ticket-gate.ps1',
    'docs/quality/LF-27-STORE-FEEDBACK-FRONTEND-20261016.md',
    'docs/quality/LF-27-STORE-FEEDBACK-FRONTEND-20261016.json')
  Assert-Fixture (Test-Lf27PublicationDelta $accepted @() @()) 'accepted source rejected.'
  Assert-Fixture (Test-Lf27PublicationDelta $successor @($accepted) $metadata) 'one metadata-only successor rejected.'
  $cases+=2
  foreach($owner in @('apps/mobile/lib/features/work/work_session.dart',
      'apps/mobile/assets/changed.png','backend/functions/src/index.ts',
      'config/codex-subagent-coordination-policy.json','docs/quality/unrelated.md')) {
    Assert-Fixture (-not (Test-Lf27PublicationDelta $successor @($accepted) ($metadata+@($owner)))) "unaccepted publication owner admitted: $owner"
    $cases++
  }
  Assert-Fixture (-not (Test-Lf27PublicationDelta $successor @('2222222222222222222222222222222222222222') $metadata)) 'unapproved descendant admitted.'
  Assert-Fixture (-not (Test-Lf27PublicationDelta $successor @($accepted,$accepted) $metadata)) 'merge successor admitted.'
  Assert-Fixture (-not (Test-Lf27PublicationDelta $successor @($accepted) @())) 'unexplained empty successor admitted.'
  Assert-Fixture (-not (Test-Lf27PublicationDelta $accepted @() $metadata)) 'accepted SHA with changed content admitted.'
  $cases+=4
  Assert-GateFails { & $gate -RepositoryRoot $sourceRoot -Phase pre_build -Lane codex_ui -TicketId LF-27 -UiScope last-frontend-store-feedback-frontend -CandidateVersionName 1.0.0-r67.3 -CandidateVersionCode 2026101303 -PackageId com.moolsocial.app.runtime } 'no build/handoff'
  Assert-GateFails { & $gate -RepositoryRoot $sourceRoot -Phase handoff -Lane codex_ui -TicketId LF-26 -UiScope last-frontend-retail-facts-consistency -CandidateVersionName 1.0.0-r67.3 -CandidateVersionCode 2026101303 -PackageId com.moolsocial.app.runtime -AcceptedUiCommit $accepted } 'no build/handoff'
  Assert-GateFails { & $gate -RepositoryRoot $sourceRoot -Phase handoff -Lane codex_ui -TicketId LF-27 -UiScope last-frontend-store-feedback-frontend -CandidateVersionName 1.0.0-r67.3 -CandidateVersionCode 2026101303 -PackageId com.moolsocial.app.runtime -AcceptedUiCommit '3c5a454bf8af173d9736c75213cafb88e641765c' } 'no build/handoff'
  $cases+=3
  Write-Output "LF27 publication: $cases focused checks passed; no app/provider/APK acceptance."
  return
}

if ($RequireLf01Probes) {
  $checker = Join-Path $sourceRoot 'scripts/check-codex-subagent-coordination-policy.ps1'
  $tokens=$null; $errors=$null
  $ast=[Management.Automation.Language.Parser]::ParseFile($checker,[ref]$tokens,[ref]$errors)
  Assert-Fixture ($errors.Count -eq 0) 'coordination checker has parse errors.'
  $predicate=@($ast.FindAll({param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Test-Lf01AdmissionIdentity'
  },$true))
  Assert-Fixture ($predicate.Count -eq 1) 'LF-01 predicate absent/duplicated.'
  . ([scriptblock]::Create($predicate[0].Extent.Text))
  $facts=@{Root=$sourceRoot.Replace('\','/'); Branch='work/codex-ui/last-frontend-lf01-20261015'
    Role='primary'; Task='/root'; Lane='codex_ui'; WorkId='last-frontend-lf01-20261015'
    Ticket='LF-01'; Phase='coordination_bootstrap'}
  $cases=0
  foreach ($phase in @('coordination_bootstrap','task_start','implementation','pre_commit')) {
    $probe=$facts.Clone(); $probe.Phase=$phase
    Assert-Fixture (Test-Lf01AdmissionIdentity $probe) 'LF-01 exact identity rejected.'
    $cases++
  }
  foreach ($key in @($facts.Keys)) {
    $probe=$facts.Clone(); $probe[$key]='unrelated'
    Assert-Fixture (-not (Test-Lf01AdmissionIdentity $probe)) "LF-01 changed $key admitted."
    $probe=$facts.Clone(); $probe.Remove($key)
    Assert-Fixture (-not (Test-Lf01AdmissionIdentity $probe)) "LF-01 missing $key admitted."
    $cases+=2
  }
  $parameters=@{RepositoryRoot=$sourceRoot;AgentRole='primary';AgentTask='/root';UseRecordedClaim=$true
    ExpectedRegistryEntryCount=4623;ExpectedRegistrySha256='8092CF57C67E40EB09CC4244E70B84A03BA280DA89B03F133F3DED00F7D6D9B3'
    ProductionLane='codex_ui';ProductionPhase='coordination_bootstrap'
    ProductionWorkId='last-frontend-lf01-20261015';ProductionTicketId='LF-01'}
  $actual=@(& $checker @parameters)
  Assert-Fixture (@($actual | Where-Object { $_ -clike 'LF-01 admission passed:*' }).Count -eq 1) 'LF-01 actual bootstrap did not pass.'
  $cases++
  $probe=$parameters.Clone(); $probe.ProductionPhase='candidate_preflight'
  Assert-GateFails { & $checker @probe } 'exact authorized feature identity'
  $probe=$parameters.Clone(); $probe.ExpectedRegistryEntryCount=4624
  Assert-GateFails { & $checker @probe } 'registry generation changed'
  $probe=$parameters.Clone(); $probe.Remove('UseRecordedClaim'); $probe.ClaimedOwners=@('backend/functions/src/index.ts')
  Assert-GateFails { & $checker @probe } 'requested an unclaimed owner'
  $cases+=3
  Assert-GateFails { & $gate -RepositoryRoot $sourceRoot -Phase pre_build -Lane codex_ui -TicketId LF-01 -UiScope last-frontend-entry-recovery -CandidateVersionName 1.0.0-r67.3 -CandidateVersionCode 2026101303 -PackageId com.moolsocial.app.runtime } 'no build/handoff'
  $cases++
  Write-Output "LF-01 admission: $cases checks passed, including actual bootstrap and negative ownership/registry/build cases; no app/device qualification."
  return
}

if($RequireCompatibilityProbes) {
  $tokens=$null; $errors=$null
  $ast=[System.Management.Automation.Language.Parser]::ParseFile($gate,[ref]$tokens,[ref]$errors)
  Assert-Fixture ($errors.Count -eq 0) 'incremental checker has parse errors.'
  $functions=@($ast.FindAll({param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
      $node.Name -ceq 'Test-CompatibilityIncrementalIdentity'
  },$true))
  Assert-Fixture ($functions.Count -eq 1) 'compatibility predicate absent/duplicated.'
  . ([scriptblock]::Create($functions[0].Extent.Text))
  $facts=@{
    Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-INTEGRATION-REPAIR-store-buy-compatibility-20261008'
    Branch='work/integration-repair/store-buy-compatibility-20261008'; Lane='integration_repair'
    Ticket='UAW-INTEGRATION-REPAIR-STORE-BUY-COMPATIBILITY-20261008'
    Scope='store.buy_publication_compatibility'; Package='com.moolsocial.app.runtime'
    VersionName='1.0.0-r66.42'; VersionCode=2026100801; Phase='ticket_start'
  }
  $cases=0
  foreach($phase in @('ticket_start','implementation','handoff')) {
    $probe=$facts.Clone(); $probe.Phase=$phase
    Assert-Fixture (Test-CompatibilityIncrementalIdentity $probe) 'exact host identity rejected.'
    $cases++
  }
  foreach($key in @($facts.Keys)) {
    $altered=$facts.Clone(); $altered[$key]='altered'
    Assert-Fixture (-not (Test-CompatibilityIncrementalIdentity $altered)) "changed$key admitted."
    $missing=$facts.Clone(); $missing.Remove($key)
    Assert-Fixture (-not (Test-CompatibilityIncrementalIdentity $missing)) "missing$key admitted."
    $cases+=2
  }
  $build=$facts.Clone(); $build.Phase='pre_build'
  Assert-Fixture (-not (Test-CompatibilityIncrementalIdentity $build)) 'repair-lane APK build admitted.'
  $cases++
  Assert-Fixture ($cases -eq 22) 'compatibility identity probe count changed.'
  Write-Output "Compatibility incremental identity: $cases cases passed; no fixture repositories or APK authorization created."
  return
}

$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
  [char[]]@('\', '/')
)
$fixtureRoot = Join-Path $tempParent (
  'moolsocial-incremental-ticket-' + [guid]::NewGuid().ToString('N')
)
$remoteRoot = "$fixtureRoot-remote.git"

try {
  $null = New-Item -ItemType Directory -Path $fixtureRoot
  $null = & git init --bare $remoteRoot 2>&1
  Assert-Fixture ($LASTEXITCODE -eq 0) 'bare remote creation failed.'
  Invoke-FixtureGit $fixtureRoot @('init')
  Invoke-FixtureGit $fixtureRoot @('config', 'user.email', 'fixture@moolsocial.invalid')
  Invoke-FixtureGit $fixtureRoot @('config', 'user.name', 'MoolSocial Fixture')
  Invoke-FixtureGit $fixtureRoot @('switch', '-c', 'work/codex-ui/fixture')
  $fixtureConfig = Join-Path $fixtureRoot 'config'
  $null = New-Item -ItemType Directory -Path $fixtureConfig
  Copy-Item -LiteralPath $state -Destination (
    Join-Path $fixtureConfig 'cross-agent-incremental-ticket-gate.json'
  )
  Invoke-FixtureGit $fixtureRoot @('add', '--', 'config/cross-agent-incremental-ticket-gate.json')
  Invoke-FixtureGit $fixtureRoot @('commit', '-m', 'fixture baseline')
  $stateValue = Get-Content -LiteralPath $state -Raw | ConvertFrom-Json
  $baselineTag = [string]$stateValue.baselineTag
  Invoke-FixtureGit $fixtureRoot @(
    'tag', '-a', $baselineTag, '-m', 'fixture annotated baseline'
  )
  Invoke-FixtureGit $fixtureRoot @('remote', 'add', 'origin', $remoteRoot)
  Invoke-FixtureGit $fixtureRoot @('push', 'origin', "refs/tags/$baselineTag")

  $positive = @(& $gate `
    -Phase ticket_start `
    -Lane codex_ui `
    -TicketId 'UAW-FIXTURE-CODEX-UI-001' `
    -UiScope 'workspace.retailer_onboarding' `
    -CandidateVersionName '1.0.0-r60.96' `
    -CandidateVersionCode 2026082797 `
    -PackageId 'com.moolsocial.app.runtime' `
    -RepositoryRoot $fixtureRoot)
  Assert-Fixture (
    $positive.Count -eq 1 -and
    [string]$positive[0] -clike 'Incremental ticket gate passed:*'
  ) 'positive Codex UI ticket-start fixture failed.'

  Assert-GateFails {
    & $gate `
      -Phase ticket_start `
      -Lane codex_ui `
      -TicketId 'UAW-FIXTURE-CODEX-UI-001' `
      -UiScope 'workspace.retailer_onboarding' `
      -CandidateVersionName '1.0.0-r60.96' `
      -CandidateVersionCode 2026082796 `
      -PackageId 'com.moolsocial.app.runtime' `
      -RepositoryRoot $fixtureRoot
  } 'candidate version code is not incremental.'

  Assert-GateFails {
    & $gate `
      -Phase ticket_start `
      -Lane codex_ui `
      -TicketId 'UAW-FIXTURE-CODEX-UI-001' `
      -UiScope 'workspace.retailer_onboarding' `
      -CandidateVersionName '1.0.0-r60.96' `
      -CandidateVersionCode 2026082797 `
      -PackageId 'com.moolsocial.app.cursorreview' `
      -RepositoryRoot $fixtureRoot
  } 'package does not match the lane.'

  Invoke-FixtureGit $fixtureRoot @(
    'switch', '-c', 'work/codex-backend/fixture', $baselineTag
  )
  Assert-GateFails {
    & $gate `
      -Phase ticket_start `
      -Lane codex_backend `
      -TicketId 'UAW-FIXTURE-CODEX-BACKEND-001' `
      -UiScope 'buy.checkout' `
      -CandidateVersionName '1.0.0-r60.96' `
      -CandidateVersionCode 2026082797 `
      -PackageId 'com.moolsocial.app.runtime' `
      -RepositoryRoot $fixtureRoot
  } 'backend UI scope is not accepted or is duplicated.'

  # Isolated fixture states: never change the repository's accepted UI state.
  $fixtureStatePath = Join-Path $fixtureConfig 'cross-agent-incremental-ticket-gate.json'
  foreach ($reviewState in @('pending','accepted')) {
    $isolatedState = Get-Content -LiteralPath $state -Raw | ConvertFrom-Json
    $isolatedState.uiFounderReview.state = $reviewState
    $isolatedState.uiFounderReview.acceptedScopes = if ($reviewState -eq 'accepted') {
      @([pscustomobject]@{id='buy.checkout'}, [pscustomobject]@{id='buy.checkout'})
    } else { @() }
    $isolatedState | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $fixtureStatePath -Encoding UTF8
    $expected = if ($reviewState -eq 'pending') {
      'backend work is blocked until founder UI acceptance.'
    } else { 'backend UI scope is not accepted or is duplicated.' }
    Assert-GateFails {
      & $gate -Phase implementation -Lane codex_backend `
        -TicketId 'UAW-FIXTURE-CODEX-BACKEND-001' -UiScope 'buy.checkout' `
        -CandidateVersionName '1.0.0-r60.96' -CandidateVersionCode 2026082797 `
        -PackageId 'com.moolsocial.app.runtime' -RepositoryRoot $fixtureRoot
    } $expected
  }
  Copy-Item -LiteralPath $state -Destination $fixtureStatePath -Force

  Invoke-FixtureGit $fixtureRoot @(
    'switch', '-c', 'work/cursor-ui/fixture', $baselineTag
  )
  $cursorPositive = @(& $gate `
    -Phase ticket_start `
    -Lane cursor_ui `
    -TicketId 'UAW-FIXTURE-CURSOR-UI-001' `
    -UiScope 'buy.consumer_cart' `
    -CandidateVersionName '1.0.0-r60.96' `
    -CandidateVersionCode ([int](@($stateValue.lanes | Where-Object id -ceq 'cursor_ui')[0].minimumVersionCodeExclusive) + 1) `
    -PackageId 'com.moolsocial.app.cursorreview' `
    -RepositoryRoot $fixtureRoot)
  Assert-Fixture ($cursorPositive.Count -eq 1) `
    'positive Cursor UI ticket-start fixture failed.'

  Write-Output 'CROSS_AGENT_INCREMENTAL_TICKET_FIXTURES_PASSED'
} finally {
  foreach ($target in @($fixtureRoot, $remoteRoot)) {
    $resolved = [IO.Path]::GetFullPath($target)
    if ($resolved.StartsWith(
        $tempParent + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      ) -and (Test-Path -LiteralPath $resolved)) {
      Remove-Item -LiteralPath $resolved -Recurse -Force
    }
  }
}
