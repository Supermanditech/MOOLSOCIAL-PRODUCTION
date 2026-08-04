[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$StatePath,

  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$repositoryRootFull = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$repositoryPrefix = (
  $repositoryRootFull + [IO.Path]::DirectorySeparatorChar
)

function Assert-MotionPolicyGate {
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

function Resolve-RepositoryFile {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath,

    [Parameter(Mandatory)]
    [string]$Label
  )

  Assert-MotionPolicyGate -Condition (
    -not [string]::IsNullOrWhiteSpace($RelativePath)
  ) -Message "$Label path is missing."
  Assert-MotionPolicyGate -Condition (
    -not [IO.Path]::IsPathRooted($RelativePath)
  ) -Message "$Label path must be repository-relative."

  $resolved = [IO.Path]::GetFullPath(
    (Join-Path $repositoryRootFull $RelativePath)
  )
  Assert-MotionPolicyGate -Condition (
    $resolved.StartsWith(
      $repositoryPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message "$Label escaped the production repository."
  Assert-MotionPolicyGate -Condition (
    Test-Path -LiteralPath $resolved -PathType Leaf
  ) -Message "$Label is missing: $resolved"
  return $resolved
}

$resolvedStatePath = [IO.Path]::GetFullPath($StatePath)
Assert-MotionPolicyGate -Condition (
  $resolvedStatePath.StartsWith(
    $repositoryPrefix,
    [StringComparison]::OrdinalIgnoreCase
  )
) -Message 'machine state must stay inside the production repository.'
Assert-MotionPolicyGate -Condition (
  Test-Path -LiteralPath $resolvedStatePath -PathType Leaf
) -Message "machine state is missing: $resolvedStatePath"

$state = Get-Content -Raw -LiteralPath $resolvedStatePath | ConvertFrom-Json
$motionProperty = $state.PSObject.Properties['premiumMotionPolicy']
Assert-MotionPolicyGate -Condition ($null -ne $motionProperty) `
  -Message 'premium-motion policy state is missing.'
$motionState = $motionProperty.Value

Assert-MotionPolicyGate -Condition (
  [string]$motionState.policy -ceq 'config/buy-premium-motion-policy.json'
) -Message 'candidate must reference the canonical premium-motion policy.'

$policyPath = Resolve-RepositoryFile `
  -RelativePath ([string]$motionState.policy) `
  -Label 'premium-motion policy'
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
Assert-MotionPolicyGate -Condition ([int]$policy.schemaVersion -eq 1) `
  -Message 'unsupported premium-motion policy schema.'
Assert-MotionPolicyGate -Condition (
  [string]$policy.policyId -ceq 'BUY-PREMIUM-MOTION-POLICY-20260802'
) -Message 'unexpected premium-motion policy id.'

$requiredRules = @(
  'whereAppropriateRequired',
  'finiteAndEventDriven',
  'reducedMotionResolvesStatic',
  'preserveSemanticsAndHitOwnership',
  'noInventedBusinessOrBackendState',
  'noPerpetualDecorativeLoop',
  'approvedOwnersRequireSuccessorForEnhancement'
)
foreach ($ruleName in $requiredRules) {
  $ruleProperty = $policy.rules.PSObject.Properties[$ruleName]
  Assert-MotionPolicyGate -Condition (
    $null -ne $ruleProperty -and [bool]$ruleProperty.Value
  ) -Message "required premium-motion rule '$ruleName' is not enabled."
}

Assert-MotionPolicyGate -Condition (
  [string]$motionState.coverage -ceq [string]$policy.authority
) -Message 'candidate coverage does not match the policy authority.'
[void](Resolve-RepositoryFile `
  -RelativePath ([string]$motionState.coverage) `
  -Label 'premium-motion coverage authority')
[void](Resolve-RepositoryFile `
  -RelativePath ([string]$motionState.candidateContract) `
  -Label 'premium-motion candidate contract')
[void](Resolve-RepositoryFile `
  -RelativePath ([string]$motionState.disposition) `
  -Label 'premium-motion disposition evidence')

Assert-MotionPolicyGate -Condition (
  -not [string]::IsNullOrWhiteSpace([string]$motionState.state)
) -Message 'premium-motion audit state is missing.'

$dispositionNames = @(
  'applied',
  'reused',
  'dependencyHeld',
  'inapplicable'
)
$dispositionCount = 0
foreach ($dispositionName in $dispositionNames) {
  $dispositionProperty = $motionState.PSObject.Properties[$dispositionName]
  Assert-MotionPolicyGate -Condition ($null -ne $dispositionProperty) `
    -Message "premium-motion disposition '$dispositionName' is missing."

  $values = @($dispositionProperty.Value)
  $seen = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
  )
  foreach ($value in $values) {
    $text = [string]$value
    Assert-MotionPolicyGate -Condition (
      -not [string]::IsNullOrWhiteSpace($text)
    ) -Message (
      "premium-motion disposition '$dispositionName' contains a blank value."
    )
    Assert-MotionPolicyGate -Condition ($seen.Add($text)) -Message (
      "premium-motion disposition '$dispositionName' contains duplicate " +
      "value '$text'."
    )
  }
  $dispositionCount += $values.Count
}
Assert-MotionPolicyGate -Condition ($dispositionCount -gt 0) `
  -Message 'premium-motion audit contains no effect disposition.'

Write-Output (
  'Premium-motion policy state passed: ' +
  "policy=$($policy.policyId); dispositions=$dispositionCount; " +
  "candidate=$($state.candidate.id)."
)
