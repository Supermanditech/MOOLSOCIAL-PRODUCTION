[CmdletBinding()]
param(
  [string]$RepositoryRoot
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
