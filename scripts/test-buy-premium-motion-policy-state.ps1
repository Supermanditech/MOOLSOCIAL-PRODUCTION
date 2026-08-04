[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = [IO.Path]::GetFullPath(
  (Split-Path -Parent $PSScriptRoot)
)
$validator = Join-Path `
  $PSScriptRoot `
  'check-buy-premium-motion-policy-state.ps1'
$canonicalPolicy = Join-Path `
  $repositoryRoot `
  'config\buy-premium-motion-policy.json'
$suiteRoot = Join-Path (
  [IO.Path]::GetTempPath()
) ("moolsocial-buy-pol-001-" + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $suiteRoot)

function New-Fixture {
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [scriptblock]$Mutate
  )

  $root = Join-Path $suiteRoot $Name
  foreach ($directory in @(
    'config',
    'docs\quality',
    'artifacts\quality\candidate'
  )) {
    [void](New-Item -ItemType Directory -Path (Join-Path $root $directory))
  }
  $policy = Get-Content -Raw -LiteralPath $canonicalPolicy | ConvertFrom-Json
  $coveragePath = Join-Path `
    $root `
    'docs\quality\BUY-PREMIUM-MOTION-SURFACE-COVERAGE-20260802.md'
  $contractPath = Join-Path `
    $root `
    'artifacts\quality\candidate\00-contract.md'
  $dispositionPath = Join-Path `
    $root `
    'artifacts\quality\candidate\01-disposition.md'
  Set-Content -LiteralPath $coveragePath -Value 'fixture coverage'
  Set-Content -LiteralPath $contractPath -Value 'fixture contract'
  Set-Content -LiteralPath $dispositionPath -Value 'fixture disposition'

  $state = [pscustomobject]@{
    candidate = [pscustomobject]@{
      id = 'BUY-POL-001-SELFTEST'
    }
    premiumMotionPolicy = [pscustomobject]@{
      state = 'prewrite_audited'
      policy = 'config/buy-premium-motion-policy.json'
      coverage = [string]$policy.authority
      candidateContract = 'artifacts/quality/candidate/00-contract.md'
      disposition = 'artifacts/quality/candidate/01-disposition.md'
      applied = @('finite_arrival')
      reused = @('approved_motion_tokens')
      dependencyHeld = @('real_async_loading')
      inapplicable = @('remote_video')
    }
  }

  if ($Mutate) {
    & $Mutate $state $policy $root
  }
  $policy | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (
    Join-Path $root 'config\buy-premium-motion-policy.json'
  )
  $statePath = Join-Path $root 'state.json'
  $state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $statePath
  return [pscustomobject]@{
    Root = $root
    StatePath = $statePath
  }
}

function Assert-Rejected {
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [scriptblock]$Mutate,

    [Parameter(Mandatory)]
    [string]$ExpectedMessage
  )

  $fixture = New-Fixture -Name $Name -Mutate $Mutate
  try {
    & $validator `
      -StatePath $fixture.StatePath `
      -RepositoryRoot $fixture.Root | Out-Null
    throw "Self-test '$Name' was unexpectedly accepted."
  } catch {
    if ($_.Exception.Message -notlike "*$ExpectedMessage*") {
      throw (
        "Self-test '$Name' returned an unexpected message: " +
        $_.Exception.Message
      )
    }
  }
}

try {
  $positive = New-Fixture -Name 'positive'
  & $validator `
    -StatePath $positive.StatePath `
    -RepositoryRoot $positive.Root | Out-Null

  Assert-Rejected `
    -Name 'missing-policy-state' `
    -ExpectedMessage 'premium-motion policy state is missing' `
    -Mutate {
      param($state, $policy, $root)
      [void]$policy
      [void]$root
      $state.PSObject.Properties.Remove('premiumMotionPolicy')
    }
  Assert-Rejected `
    -Name 'escaped-policy-path' `
    -ExpectedMessage 'canonical premium-motion policy' `
    -Mutate {
      param($state, $policy, $root)
      [void]$policy
      [void]$root
      $state.premiumMotionPolicy.policy = '../outside.json'
    }
  Assert-Rejected `
    -Name 'disabled-required-rule' `
    -ExpectedMessage "rule 'reducedMotionResolvesStatic' is not enabled" `
    -Mutate {
      param($state, $policy, $root)
      [void]$state
      [void]$root
      $policy.rules.reducedMotionResolvesStatic = $false
    }
  Assert-Rejected `
    -Name 'missing-disposition-category' `
    -ExpectedMessage "disposition 'applied' is missing" `
    -Mutate {
      param($state, $policy, $root)
      [void]$policy
      [void]$root
      $state.premiumMotionPolicy.PSObject.Properties.Remove('applied')
    }
  Assert-Rejected `
    -Name 'duplicate-disposition' `
    -ExpectedMessage "duplicate value 'finite_arrival'" `
    -Mutate {
      param($state, $policy, $root)
      [void]$policy
      [void]$root
      $state.premiumMotionPolicy.applied = @(
        'finite_arrival',
        'finite_arrival'
      )
    }
  Assert-Rejected `
    -Name 'missing-disposition-evidence' `
    -ExpectedMessage 'premium-motion disposition evidence is missing' `
    -Mutate {
      param($state, $policy, $root)
      [void]$policy
      [void]$root
      $state.premiumMotionPolicy.disposition = (
        'artifacts/quality/candidate/missing.md'
      )
    }

  Write-Output (
    'BUY-POL-001 self-test passed: one positive fixture and six fail-closed ' +
    'negative fixtures behaved as required.'
  )
} finally {
  $resolvedSuiteRoot = [IO.Path]::GetFullPath($suiteRoot)
  $tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
  if (
    $resolvedSuiteRoot.StartsWith(
      $tempPrefix,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Split-Path -Leaf $resolvedSuiteRoot) -like 'moolsocial-buy-pol-001-*'
  ) {
    Remove-Item -LiteralPath $resolvedSuiteRoot -Recurse -Force
  }
}
