[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$StatePath,

  [Parameter(Mandatory)]
  [string]$CandidateId,

  [Parameter(Mandatory)]
  [string]$BuildName,

  [Parameter(Mandatory)]
  [string]$BuildNumber,

  [Parameter(Mandatory)]
  [ValidateSet('debug', 'profile', 'release')]
  [string]$BuildMode,

  [Parameter(Mandatory)]
  [string]$SourceFingerprint,

  [Parameter(Mandatory)]
  [string[]]$RuntimeDefine
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = [IO.Path]::GetFullPath(
  (Split-Path -Parent $PSScriptRoot)
)
$resolvedStatePath = [IO.Path]::GetFullPath($StatePath)

function Assert-Gate {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "APK regression pre-build gate rejected: $Message"
  }
}

Assert-Gate -Condition $resolvedStatePath.StartsWith(
  $repositoryRoot,
  [StringComparison]::OrdinalIgnoreCase
) -Message 'machine state must stay inside the production repository.'
Assert-Gate -Condition (Test-Path -LiteralPath $resolvedStatePath -PathType Leaf) `
  -Message "machine state is missing: $resolvedStatePath"

$state = Get-Content -Raw -LiteralPath $resolvedStatePath | ConvertFrom-Json
Assert-Gate -Condition ([int]$state.schemaVersion -eq 1) `
  -Message 'unsupported machine-state schema.'
Assert-Gate -Condition (
  [string]$state.contractId -ceq 'APK-BUILD-REGRESSION-GATES-001'
) -Message 'unexpected machine-state contract id.'

$motionPolicyGate = Join-Path `
  $PSScriptRoot `
  'check-buy-premium-motion-policy-state.ps1'
Assert-Gate -Condition (
  Test-Path -LiteralPath $motionPolicyGate -PathType Leaf
) -Message 'premium-motion policy machine gate is missing.'
& $motionPolicyGate `
  -StatePath $resolvedStatePath `
  -RepositoryRoot $repositoryRoot

Assert-Gate -Condition (
  [string]$state.machineState -ceq 'prebuild_passed'
) -Message "machine state is '$($state.machineState)', not 'prebuild_passed'."
Assert-Gate -Condition (
  [string]$state.buildAuthorization -ceq 'approved_for_one_build'
) -Message 'one-build authorization is not recorded.'
Assert-Gate -Condition (
  [string]$state.preBuildValidation.state -ceq 'passed'
) -Message 'pre-build validation result is not sealed as passed.'

$branch = (git -C $repositoryRoot branch --show-current).Trim()
Assert-Gate -Condition ($LASTEXITCODE -eq 0 -and $branch.Length -gt 0) `
  -Message 'current branch could not be identified.'
$head = (git -C $repositoryRoot rev-parse HEAD).Trim()
Assert-Gate -Condition ($LASTEXITCODE -eq 0 -and $head.Length -gt 0) `
  -Message 'current HEAD could not be identified.'
Assert-Gate -Condition ($branch -cne 'main') `
  -Message 'APK builds are forbidden on main.'
Assert-Gate -Condition ($branch -ceq [string]$state.candidate.branch) `
  -Message 'branch differs from the registered candidate.'
Assert-Gate -Condition ($head -ceq [string]$state.candidate.head) `
  -Message 'HEAD differs from the registered candidate.'

Assert-Gate -Condition ($CandidateId -ceq [string]$state.candidate.id) `
  -Message 'candidate id differs from machine state.'
Assert-Gate -Condition ($BuildName -ceq [string]$state.candidate.versionName) `
  -Message 'version name differs from machine state.'
Assert-Gate -Condition ($BuildNumber -ceq [string]$state.candidate.versionCode) `
  -Message 'version code differs from machine state.'
Assert-Gate -Condition ($BuildMode -ceq [string]$state.candidate.buildMode) `
  -Message 'build mode differs from machine state.'
Assert-Gate -Condition (
  $SourceFingerprint -ceq [string]$state.source.manifestSha256
) -Message 'source fingerprint differs from machine state.'

$manifestPath = [IO.Path]::GetFullPath(
  (Join-Path $repositoryRoot ([string]$state.source.manifestPath))
)
Assert-Gate -Condition $manifestPath.StartsWith(
  $repositoryRoot,
  [StringComparison]::OrdinalIgnoreCase
) -Message 'source manifest escaped the production repository.'
Assert-Gate -Condition (Test-Path -LiteralPath $manifestPath -PathType Leaf) `
  -Message "source manifest is missing: $manifestPath"
$manifestHash = (
  Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256
).Hash
Assert-Gate -Condition (
  $manifestHash -ceq [string]$state.source.manifestSha256
) -Message 'live source-manifest checksum differs from machine state.'
$manifestLines = @(Get-Content -LiteralPath $manifestPath)
Assert-Gate -Condition (
  $manifestLines.Count -eq [int]$state.source.fileCount
) -Message 'source-manifest file count differs from machine state.'

$requiredGateIds = @(
  'branch-head',
  'source-manifest',
  'format-analysis',
  'focused-tests',
  'buy-regression-1',
  'buy-regression-2',
  'positive-release-gates',
  'protected-boundary-disposition',
  'rejected-candidate-preserved',
  'startup-config-regression-registered'
)
$preBuildValidationEvidence = [IO.Path]::GetFullPath(
  (Join-Path $repositoryRoot ([string]$state.preBuildValidation.evidence))
)
Assert-Gate -Condition (Test-Path -LiteralPath $preBuildValidationEvidence -PathType Leaf) `
  -Message 'sealed pre-build validation evidence is missing.'
$registeredGateIds = @($state.preBuildGates | ForEach-Object { [string]$_.id })
Assert-Gate -Condition (
  $registeredGateIds.Count -eq (@($registeredGateIds | Select-Object -Unique)).Count
) -Message 'pre-build gate ids are not unique.'

foreach ($gateId in $requiredGateIds) {
  $gate = @($state.preBuildGates | Where-Object { $_.id -ceq $gateId })
  Assert-Gate -Condition ($gate.Count -eq 1) `
    -Message "required pre-build gate '$gateId' is missing or duplicated."
  Assert-Gate -Condition ([string]$gate[0].state -ceq 'passed') `
    -Message "required pre-build gate '$gateId' is not passed."
  $evidencePaths = @($gate[0].evidence)
  Assert-Gate -Condition ($evidencePaths.Count -gt 0) `
    -Message "required pre-build gate '$gateId' has no evidence."
  foreach ($evidencePath in $evidencePaths) {
    $resolvedEvidencePath = [IO.Path]::GetFullPath(
      (Join-Path $repositoryRoot ([string]$evidencePath))
    )
    Assert-Gate -Condition $resolvedEvidencePath.StartsWith(
      $repositoryRoot,
      [StringComparison]::OrdinalIgnoreCase
    ) -Message "evidence for '$gateId' escaped the repository."
    Assert-Gate -Condition (Test-Path -LiteralPath $resolvedEvidencePath) `
      -Message "evidence for '$gateId' is missing: $resolvedEvidencePath"
  }
}

$expectedDefines = @(
  $state.requiredRuntimeDefines.PSObject.Properties |
    ForEach-Object { "$($_.Name)=$($_.Value)" } |
    Sort-Object
)
$actualDefines = @($RuntimeDefine | Sort-Object)
Assert-Gate -Condition (
  ($expectedDefines -join ';') -ceq ($actualDefines -join ';')
) -Message 'runtime defines differ from the exact registered allowlist.'

$allowedDefineNames = @(
  'MOOLSOCIAL_CANDIDATE_ID',
  'MOOLSOCIAL_DEVICE_REVIEW',
  'MOOLSOCIAL_USE_EMULATORS'
)
foreach ($runtimeDefine in $actualDefines) {
  $defineName = $runtimeDefine.Split('=', 2)[0]
  Assert-Gate -Condition ($allowedDefineNames -ccontains $defineName) `
    -Message "runtime define '$defineName' is not allowed in device review."
}

Write-Output (
  "APK regression pre-build gate passed: candidate=$CandidateId; " +
  "mode=$BuildMode; source=$SourceFingerprint; gates=$($requiredGateIds.Count)."
)
