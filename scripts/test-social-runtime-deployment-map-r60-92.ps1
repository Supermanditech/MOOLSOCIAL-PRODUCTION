[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$checker = Join-Path $root 'scripts\check-social-runtime-deployment-map-r60-92.ps1'
$live = Join-Path $root 'config\social-runtime-deployment-map-r60-92.json'
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
  [char[]]@('\', '/')
)
$temporaryRoot = [IO.Path]::GetFullPath((Join-Path $temporaryBase (
  'moolsocial-deployment-map-test-' + [Guid]::NewGuid().ToString('N')
)))

function Assert-MapTest([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "Social deployment-map test failed: $Message" }
}

function Invoke-NegativeFixture([scriptblock]$Mutation, [string]$Name) {
  $state = Get-Content -LiteralPath $live -Raw | ConvertFrom-Json -Depth 100
  & $Mutation $state
  $fixture = Join-Path $temporaryRoot "$Name.json"
  [IO.File]::WriteAllText(
    $fixture,
    ($state | ConvertTo-Json -Depth 100),
    [Text.UTF8Encoding]::new($false)
  )
  $rejected = $false
  try {
    & $checker -RepositoryRoot $root -StatePath $fixture | Out-Null
  } catch {
    $rejected = $_.Exception.Message.StartsWith(
      'Social runtime deployment map rejected:',
      [StringComparison]::Ordinal
    )
  }
  Assert-MapTest $rejected "$Name was not rejected."
}

Assert-MapTest (
  $temporaryRoot.StartsWith(
    $temporaryBase + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  ) -and
  [IO.Path]::GetFileName($temporaryRoot).StartsWith(
    'moolsocial-deployment-map-test-',
    [StringComparison]::Ordinal
  )
) 'temporary root escaped the exact namespace.'

try {
  New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
  & $checker -RepositoryRoot $root -StatePath $live | Out-Null
  Invoke-NegativeFixture { param($s) $s.cloudWriteAuthorized = $true } `
    'cloud-write-authority'
  Invoke-NegativeFixture {
    param($s)
    $s.deploymentPolicy.approvedDeploymentAllowlist += 'youtubeProvider'
  } 'overbroad-allowlist'
  Invoke-NegativeFixture {
    param($s)
    $s.dependencyAudit.productionHigh = 1
  } 'high-advisory'
  Invoke-NegativeFixture {
    param($s)
    $s.functions[0].sourceAudit.privateCredentialEntryCount = 1
  } 'private-credential-entry'
  Invoke-NegativeFixture {
    param($s)
    $s.functions[4].sourceAudit.requiredModuleMatchCount = 30
  } 'callback-module-drift'
  Invoke-NegativeFixture {
    param($s)
    $s.functions[4].deploymentQualification.focusedMobileTestsPassed = 134
  } 'callback-mobile-underproof'
  Invoke-NegativeFixture {
    param($s)
    $s.functions[1].runtimeConfigurationAudit.acceptedNonSecretRuntimeTupleMatches = $false
  } 'provider-runtime-tuple-drift'
  Invoke-NegativeFixture {
    param($s)
    $s.functions[2].requiredModules[1] = $s.functions[2].requiredModules[0]
  } 'duplicate-attestation-module'
  Invoke-NegativeFixture {
    param($s)
    $s.functions[0].requiredContractMarkers = @()
  } 'empty-attestation-marker-set'
  Invoke-NegativeFixture {
    param($s)
    $s.functions[3].sourceAudit.riskyEntryCount = 3
  } 'unsanctioned-risky-entry-count'
  Invoke-NegativeFixture {
    param($s)
    $s.functions[4].trafficPercent = 99
  } 'nonexclusive-live-traffic'
  Invoke-NegativeFixture {
    param($s)
    $s.functions[4].sourceAudit.implementedModuleSourceCommit = ('0' * 40)
  } 'untrusted-source-commit-attribution'
} finally {
  if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
    $resolved = [IO.Path]::GetFullPath($temporaryRoot)
    Assert-MapTest (
      $resolved.StartsWith(
        $temporaryBase + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      ) -and
      [IO.Path]::GetFileName($resolved).StartsWith(
        'moolsocial-deployment-map-test-',
        [StringComparison]::Ordinal
      )
    ) 'cleanup target changed.'
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}

Write-Output (
  'Social runtime deployment map self-test passed: live=1; negative=12; ' +
  'cloudWrites=0.'
)
