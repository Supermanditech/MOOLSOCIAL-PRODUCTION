[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$checker = Join-Path $root `
  'scripts\check-social-runtime-deployment-execution-r60-92.ps1'
$executor = Join-Path $root `
  'scripts\invoke-social-runtime-deployment-r60-92.ps1'
$liveState = Join-Path $root `
  'config\social-runtime-deployment-execution-r60-92.json'
$fixture = Join-Path $root (
  'config\.social-runtime-deployment-execution-test-' +
  [Guid]::NewGuid().ToString('N') + '.json'
)
$receipt = Join-Path $root `
  'backend\functions\.env.social-runtime-deploy-r60-92-attempt.local'

function Assert-Test([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Social runtime deployment execution test failed: $Message"
  }
}

function Write-Fixture($State) {
  [IO.File]::WriteAllText(
    $fixture,
    (($State | ConvertTo-Json -Depth 100) + "`n"),
    [Text.UTF8Encoding]::new($false)
  )
}

function Assert-Rejected([string]$Label, [scriptblock]$Mutation) {
  $state = Get-Content -LiteralPath $liveState -Raw | ConvertFrom-Json -Depth 100
  & $Mutation $state
  Write-Fixture $state
  $rejected = $false
  try {
    & $checker -RepositoryRoot $root -StatePath $fixture -Phase Prepared |
      Out-Null
  } catch {
    $rejected = $_.Exception.Message.StartsWith(
      'Social runtime deployment execution rejected:',
      [StringComparison]::Ordinal
    )
  }
  Assert-Test $rejected "$Label was accepted."
}

Assert-Test (Test-Path -LiteralPath $checker -PathType Leaf) 'checker missing.'
Assert-Test (Test-Path -LiteralPath $executor -PathType Leaf) 'executor missing.'
Assert-Test (Test-Path -LiteralPath $liveState -PathType Leaf) 'state missing.'
Assert-Test (-not (Test-Path -LiteralPath $receipt)) `
  'attempt receipt already exists before the fixture run.'

try {
  & $checker -RepositoryRoot $root -StatePath $liveState -Phase Prepared |
    Out-Null
  & $executor -RepositoryRoot $root -StatePath $liveState -Mode Validate |
    Out-Null

  Assert-Rejected 'wrong project' { param($s) $s.projectId = 'wrong-project' }
  Assert-Rejected 'broadened deploy allowlist' {
    param($s)
    $s.plan.deployFunctions += 'moolSocialContent'
  }
  Assert-Rejected 'missing preserved function' {
    param($s)
    $s.plan.preserveFunctions = @('moolSocialPublicAuth','moolSocialChat')
  }
  Assert-Rejected 'backend tree drift' {
    param($s)
    $s.source.backendFunctionsTree = ('0' * 40)
  }
  Assert-Rejected 'map hash drift' {
    param($s)
    $s.eligibility.mapSha256 = ('0' * 64)
  }
  Assert-Rejected 'premature authority' {
    param($s)
    $s.authority.founderCloudDeploymentAuthorized = $true
  }
  Assert-Rejected 'premature command count' {
    param($s)
    $s.authority.deployCommandCount = 1
    $s.authority.cloudWriteActionCount = 1
  }
  Assert-Rejected 'secret resource binding drift' {
    param($s)
    $s.secretBindingPosture[0].bindingResourceSetSha256 = ('0' * 64)
  }
  Assert-Rejected 'runtime materialization drift' {
    param($s)
    $s.runtimePackage.runtimeMaterializationSha256 = ('0' * 64)
  }
  Assert-Rejected 'Firebase CLI version drift' {
    param($s)
    $s.runtimePackage.firebaseCliVersion = '99.0.0'
  }
  Assert-Rejected 'cloud write ceiling drift' {
    param($s)
    $s.authority.maximumContainedCloudWriteActionCount = 6
  }

  $receiptState = Get-Content -LiteralPath $liveState -Raw |
    ConvertFrom-Json -Depth 100
  Write-Fixture $receiptState
  [IO.File]::WriteAllText(
    $receipt,
    "{`"schema`":`"fixture`"}`n",
    [Text.UTF8Encoding]::new($false)
  )
  $receiptRejected = $false
  try {
    & $checker -RepositoryRoot $root -StatePath $fixture -Phase Prepared |
      Out-Null
  } catch { $receiptRejected = $true }
  Assert-Test $receiptRejected 'existing one-use receipt was accepted.'
  Remove-Item -LiteralPath $receipt -Force

  $source = [IO.File]::ReadAllText($executor)
  $checkerSource = [IO.File]::ReadAllText($checker)
  $recoverStart = $source.IndexOf("if (`$Mode -ceq 'Recover')",
    [StringComparison]::Ordinal)
  $recoverEndMarker = "`n}`n`n& `$checker -RepositoryRoot"
  $recoverEnd = $source.IndexOf(
    $recoverEndMarker,
    $recoverStart,
    [StringComparison]::Ordinal
  )
  Assert-Test ($recoverStart -ge 0 -and $recoverEnd -gt $recoverStart) `
    'Recover source boundary is missing.'
  $recoverSource = $source.Substring(
    $recoverStart,
    ($recoverEnd + 2) - $recoverStart
  )
  Assert-Test (
    [regex]::Matches(
      $source,
      '& firebase deploy --only \$firebaseOnlyTarget'
    ).Count -eq 2 -and
    [regex]::Matches($source, '--dry-run').Count -eq 1 -and
    $source.Contains('[IO.FileMode]::CreateNew', [StringComparison]::Ordinal) -and
    $source.Contains("[ValidateSet('Validate', 'Deploy', 'Recover')]",
      [StringComparison]::Ordinal) -and
    $source.Contains('--clear-tags', [StringComparison]::Ordinal) -and
    $source.Contains(
      '1177B4137BA5ADAA56354AE40F1080C7450E8AE09CECB47DA459D1C52AC99F97',
      [StringComparison]::Ordinal
    ) -and
    -not $source.Contains('--update-env-vars', [StringComparison]::Ordinal) -and
    -not $source.Contains('functions:artifacts:setpolicy',
      [StringComparison]::Ordinal) -and
    -not $source.Contains('firestore:rules', [StringComparison]::Ordinal) -and
    -not $source.Contains('functions:provider:moolSocial',
      [StringComparison]::Ordinal) -and
    $source.Contains('--no-invoker-iam-check', [StringComparison]::Ordinal) -and
    $source.Contains('metadataRestoreCommandCount = @(',
      [StringComparison]::Ordinal) -and
    $source.Contains('providerMetadataRestoreClaimed',
      [StringComparison]::Ordinal) -and
    $source.Contains('authorizationNonceSha256',
      [StringComparison]::Ordinal) -and
    $source.Contains('one-use authority expired before deployment start',
      [StringComparison]::Ordinal) -and
    $source.Contains('Assert-CliAccountBinding $state',
      [StringComparison]::Ordinal) -and
    $checkerSource.Contains('$localHead -ceq [string]$source.finalIntegrationHead',
      [StringComparison]::Ordinal) -and
    $checkerSource.Contains('$source.finalIntegrationHead -ceq $remoteHead',
      [StringComparison]::Ordinal) -and
    $checkerSource.Contains('$worktreeDirt.Count -eq 0',
      [StringComparison]::Ordinal) -and
    $checkerSource.Contains('(Get-CanonicalTextSha256 $sourceSealPath)',
      [StringComparison]::Ordinal) -and
    -not $recoverSource.Contains('firebase deploy', [StringComparison]::Ordinal)
  ) 'executor source target, receipt, Node or rollback guards changed.'
} finally {
  if (Test-Path -LiteralPath $receipt -PathType Leaf) {
    Remove-Item -LiteralPath $receipt -Force
  }
  if (Test-Path -LiteralPath $fixture -PathType Leaf) {
    Remove-Item -LiteralPath $fixture -Force
  }
}

Write-Output (
  'Social runtime deployment execution self-test passed: live=1; source=1; ' +
  'negative=12; dryRuns=0; deploys=0; cloudWrites=0.'
)
