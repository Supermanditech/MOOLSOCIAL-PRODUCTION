[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [switch]$RequireCompatibilityProbes
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
  $result = @(& git -C $Root @Arguments 2>&1)
  if ($LASTEXITCODE -ne 0) {
    throw "Fixture Git failed: git $($Arguments -join ' ') :: $result"
  }
}

function Assert-GateFails([scriptblock]$Invocation, [string]$Expected) {
  $failed = $false
  try {
    $null = & $Invocation
  } catch {
    $failed = $_.Exception.Message.Contains(
      $Expected,
      [StringComparison]::Ordinal
    )
  }
  Assert-Fixture $failed "negative fixture did not fail with: $Expected"
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
  } 'backend work is blocked until founder UI acceptance.'

  Invoke-FixtureGit $fixtureRoot @(
    'switch', '-c', 'work/cursor-ui/fixture', $baselineTag
  )
  $cursorPositive = @(& $gate `
    -Phase ticket_start `
    -Lane cursor_ui `
    -TicketId 'UAW-FIXTURE-CURSOR-UI-001' `
    -UiScope 'buy.consumer_cart' `
    -CandidateVersionName '1.0.0-r60.96' `
    -CandidateVersionCode 2026082799 `
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
