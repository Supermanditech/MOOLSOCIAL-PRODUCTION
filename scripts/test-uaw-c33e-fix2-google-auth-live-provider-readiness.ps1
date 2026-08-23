[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$gatePath = Join-Path $root `
  'scripts/check-uaw-c33e-fix2-google-auth-live-provider-readiness.ps1'
$baseStatePath = Join-Path $root `
  'config/google-auth-live-provider-readiness-state-c33e-fix2.json'
$baseScopePath = Join-Path $root 'config/mvp-scope-gate-state.json'
$fixtureRoot = Join-Path $root (
  'tmp/c33e-fix2-behavioral-' + [guid]::NewGuid().ToString('N')
)

function Assert-C33EFix2Test {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33E FIX2 behavioral checker rejected: $Message"
  }
}

function Copy-C33EFix2Json {
  param([Parameter(Mandatory)][object]$Value)
  return ($Value | ConvertTo-Json -Depth 40 | ConvertFrom-Json)
}

function Write-C33EFix2Json {
  param(
    [Parameter(Mandatory)][object]$Value,
    [Parameter(Mandatory)][string]$Path
  )
  $fullPath = [IO.Path]::GetFullPath($Path)
  Assert-C33EFix2Test -Condition (
    $fullPath.StartsWith(
      $fixtureRoot + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message 'fixture write escaped its exact temporary root.'
  [IO.File]::WriteAllText(
    $fullPath,
    (($Value | ConvertTo-Json -Depth 40) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
  )
}

function Invoke-C33EFix2Gate {
  param(
    [Parameter(Mandatory)][ValidateSet('implementation', 'build')]
    [string]$Phase,
    [Parameter(Mandatory)][string]$StatePath,
    [string]$ScopePath = $baseScopePath
  )
  & $gatePath `
    -Phase $Phase `
    -StatePath $StatePath `
    -ScopePath $ScopePath `
    -RepositoryRoot $root | Out-Null
}

function Assert-C33EFix2Rejected {
  param(
    [Parameter(Mandatory)][scriptblock]$Action,
    [Parameter(Mandatory)][string]$ExpectedMessage
  )
  $caughtMessage = $null
  try {
    & $Action
  } catch {
    $caughtMessage = $_.Exception.Message
  }
  Assert-C33EFix2Test -Condition (
    [string]$caughtMessage -ceq $ExpectedMessage
  ) -Message "unexpected rejection: $caughtMessage"
}

foreach ($required in @($gatePath, $baseStatePath, $baseScopePath)) {
  Assert-C33EFix2Test -Condition (Test-Path -LiteralPath $required -PathType Leaf) `
    -Message "required owner missing: $required"
}
Assert-C33EFix2Test -Condition (
  $fixtureRoot.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
  -not (Test-Path -LiteralPath $fixtureRoot)
) -Message 'fixture root is invalid or already exists.'
[void][IO.Directory]::CreateDirectory($fixtureRoot)

try {
  $baseState = Get-Content -Raw -LiteralPath $baseStatePath | ConvertFrom-Json
  $baseScope = Get-Content -Raw -LiteralPath $baseScopePath | ConvertFrom-Json

  $qualifiedState = Copy-C33EFix2Json -Value $baseState
  $qualifiedState.machineState =
    'qualified_sanitized_non_secret_evidence_release_gate_open_for_separately_authorized_candidate'
  foreach ($fact in @($qualifiedState.readinessFacts)) {
    $evidenceName = 'evidence-' + [string]$fact.id + '.json'
    $evidencePath = Join-Path $fixtureRoot $evidenceName
    $evidence = [ordered]@{
      schemaVersion = 1
      contractId = 'GOOGLE-AUTH-LIVE-READINESS-EVIDENCE-C33E-FIX2-001'
      factId = [string]$fact.id
      result = 'qualified'
      project = 'moolsocial-dev-503018'
      package = 'com.moolsocial.app'
      verificationMethod = 'sanitized_founder_visible_console_confirmation'
      verifiedAtUtc = '2026-08-15T00:00:00Z'
      secretValuesObserved = $false
      privateAccountIdentifiersObserved = $false
      oauthClientIdentifierValuesObserved = $false
    }
    Write-C33EFix2Json -Value $evidence -Path $evidencePath
    $fact.status = 'qualified_sanitized_non_secret_evidence'
    $fact.evidencePath = $evidencePath.Substring($prefix.Length).Replace('\', '/')
    $fact.evidenceSha256 = (
      Get-FileHash -Algorithm SHA256 -LiteralPath $evidencePath
    ).Hash
  }
  $qualifiedStatePath = Join-Path $fixtureRoot 'qualified-state.json'
  Write-C33EFix2Json -Value $qualifiedState -Path $qualifiedStatePath
  Invoke-C33EFix2Gate -Phase build -StatePath $qualifiedStatePath

  Assert-C33EFix2Rejected -Action {
    Invoke-C33EFix2Gate -Phase build -StatePath $baseStatePath
  } -ExpectedMessage (
    'C33E FIX2 Google auth readiness gate rejected: ' +
    'all four sanitized live-readiness facts must qualify before a build.'
  )

  for ($factIndex = 0; $factIndex -lt 4; $factIndex++) {
    $missingFactState = Copy-C33EFix2Json -Value $qualifiedState
    $missingFactState.machineState =
      'pending_sanitized_non_secret_console_evidence_release_blocked'
    $missingFactState.readinessFacts[$factIndex].status =
      'pending_sanitized_evidence'
    $missingFactState.readinessFacts[$factIndex].evidencePath = ''
    $missingFactState.readinessFacts[$factIndex].evidenceSha256 = ''
    $missingFactStatePath = Join-Path $fixtureRoot (
      'missing-fact-' + $factIndex + '.json'
    )
    Write-C33EFix2Json -Value $missingFactState -Path $missingFactStatePath
    Assert-C33EFix2Rejected -Action {
      Invoke-C33EFix2Gate -Phase build -StatePath $missingFactStatePath
    } -ExpectedMessage (
      'C33E FIX2 Google auth readiness gate rejected: ' +
      'all four sanitized live-readiness facts must qualify before a build.'
    )
  }

  $failedFactState = Copy-C33EFix2Json -Value $qualifiedState
  $failedFactState.machineState =
    'pending_sanitized_non_secret_console_evidence_release_blocked'
  $failedFactState.readinessFacts[0].status = 'failed_sanitized_evidence'
  $failedFactState.readinessFacts[0].evidencePath = ''
  $failedFactState.readinessFacts[0].evidenceSha256 = ''
  $failedFactStatePath = Join-Path $fixtureRoot 'failed-fact.json'
  Write-C33EFix2Json -Value $failedFactState -Path $failedFactStatePath
  Assert-C33EFix2Rejected -Action {
    Invoke-C33EFix2Gate -Phase build -StatePath $failedFactStatePath
  } -ExpectedMessage (
    'C33E FIX2 Google auth readiness gate rejected: ' +
    'all four sanitized live-readiness facts must qualify before a build.'
  )

  $authorityDriftState = Copy-C33EFix2Json -Value $qualifiedState
  $authorityDriftState.authority.buildAuthorized = $true
  $authorityDriftStatePath = Join-Path $fixtureRoot 'authority-drift-state.json'
  Write-C33EFix2Json -Value $authorityDriftState -Path $authorityDriftStatePath
  Assert-C33EFix2Rejected -Action {
    Invoke-C33EFix2Gate -Phase build -StatePath $authorityDriftStatePath
  } -ExpectedMessage (
    'C33E FIX2 Google auth readiness gate rejected: ' +
    'readiness state grants forbidden authority.'
  )

  $forbiddenPropertyPath = Join-Path $fixtureRoot 'forbidden-property-state.json'
  $forbiddenPropertyRaw = (
    Get-Content -Raw -LiteralPath $qualifiedStatePath
  ).TrimEnd() -replace '\}\s*$', ',"apiKey":"REDACTED"}'
  [IO.File]::WriteAllText(
    $forbiddenPropertyPath,
    ($forbiddenPropertyRaw + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
  )
  Assert-C33EFix2Rejected -Action {
    Invoke-C33EFix2Gate -Phase build -StatePath $forbiddenPropertyPath
  } -ExpectedMessage (
    'C33E FIX2 Google auth readiness gate rejected: ' +
    'readiness state contains a forbidden private-value property.'
  )

  $scopeDrift = Copy-C33EFix2Json -Value $baseScope
  $scopeDrift.execution.buildAuthorized = $true
  $scopeDriftPath = Join-Path $fixtureRoot 'scope-drift.json'
  Write-C33EFix2Json -Value $scopeDrift -Path $scopeDriftPath
  Assert-C33EFix2Rejected -Action {
    Invoke-C33EFix2Gate `
      -Phase implementation `
      -StatePath $baseStatePath `
      -ScopePath $scopeDriftPath
  } -ExpectedMessage (
    'C33E FIX2 Google auth readiness gate rejected: ' +
    'active FIX2/FIX3 lifecycle or authority boundary changed.'
  )
} finally {
  if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
    $fixtureFiles = @(Get-ChildItem -LiteralPath $fixtureRoot -File)
    foreach ($fixtureFile in $fixtureFiles) {
      Remove-Item -LiteralPath $fixtureFile.FullName -Force
    }
    Remove-Item -LiteralPath $fixtureRoot -Force
  }
}

Assert-C33EFix2Test -Condition (-not (Test-Path -LiteralPath $fixtureRoot)) `
  -Message 'temporary fixture residue remains.'
Write-Output (
  'C33E FIX2 Google auth readiness behavioral contract passed: ' +
  'qualified=1; pendingBuildReject=1; missingFactReject=4; ' +
  'failedFactReject=1; authorityReject=1; privatePropertyReject=1; ' +
  'scopeDriftReject=1; temporaryFixtureResidue=0.'
)
