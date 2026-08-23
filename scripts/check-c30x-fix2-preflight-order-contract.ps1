[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))

function Assert-C30XFix2 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30X FIX2 preflight-order contract rejected: $Message"
  }
}

function Read-Owner {
  param([Parameter(Mandatory)][string]$RelativePath)
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C30XFix2 -Condition (
    $path.StartsWith(
      $root + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath $path -PathType Leaf)
  ) -Message "required owner is missing or escaped the repository: $RelativePath"
  return Get-Content -Raw -LiteralPath $path
}

function Find-Required {
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][string]$Needle,
    [Parameter(Mandatory)][string]$Label
  )
  $index = $Text.IndexOf($Needle, [StringComparison]::Ordinal)
  Assert-C30XFix2 -Condition ($index -ge 0) -Message "$Label is missing."
  return $index
}

$wrapper = Read-Owner 'scripts/invoke-play-internal-aab-build-c30t.ps1'
$gate = Read-Owner 'scripts/check-successor-aab-regression-hard-gate-c30x.ps1'
$launcher = Read-Owner 'tmp/run-c30x-successor-single-aab-founder.ps1'
$state = Read-Owner 'config/successor-aab-regression-hard-gate-state-c30x.json' |
  ConvertFrom-Json
$aggregate = Read-Owner 'config/successor-aab-regression-hard-gate-aggregate-c30x.json' |
  ConvertFrom-Json

$phaseGateIndex = Find-Required $wrapper '& $gate -Phase build' 'build phase gate'
$configIndex = Find-Required $wrapper '$releaseConfigExitCode = Invoke-NativeCaptured' 'release config-only preflight'
$manifestIndex = Find-Required $wrapper '$manifestExitCode = Invoke-NativeCaptured' 'release manifest preflight'
$preflightPassIndex = Find-Required $wrapper '$state.sourceQualification.releasePreflightPassed = $true' 'current-invocation preflight result'
$aggregatePreflightPassIndex = Find-Required $wrapper '$aggregate.sourceQualification.releasePreflightPassed = $true' 'aggregate current-invocation preflight result'
$consumeIndex = Find-Required $wrapper '$state.buildAuthorization = ''consumed''' 'single build authority consumption'
$appBundleIndex = Find-Required $wrapper '$buildArguments = @(''build'', ''appbundle''' 'single AAB build'
Assert-C30XFix2 -Condition (
  $phaseGateIndex -lt $configIndex -and
  $configIndex -lt $manifestIndex -and
  $manifestIndex -lt $preflightPassIndex -and
  $preflightPassIndex -lt $aggregatePreflightPassIndex -and
  $aggregatePreflightPassIndex -lt $consumeIndex -and
  $consumeIndex -lt $appBundleIndex
) -Message 'gate, generated preflights, authority consumption and AAB build ordering changed.'
Assert-C30XFix2 -Condition (
  [regex]::Matches(
    $wrapper,
    '\$state[.]sourceQualification[.]releasePreflightPassed\s*=\s*\$true'
  ).Count -eq 1 -and
  [regex]::Matches(
    $wrapper,
    '\$aggregate[.]sourceQualification[.]releasePreflightPassed\s*=\s*\$true'
  ).Count -eq 1
) -Message 'current-invocation preflight success must have one exact wrapper owner.'

$buildStart = Find-Required $gate "'build' {" 'C30X build block'
$postbuildStart = Find-Required $gate '{ $_ -in @(''postbuild'', ''preupload'') }' 'C30X postbuild block'
Assert-C30XFix2 -Condition ($buildStart -lt $postbuildStart) `
  -Message 'C30X build and postbuild block ordering changed.'
$buildBlock = $gate.Substring($buildStart, $postbuildStart - $buildStart)
$postbuildBlock = $gate.Substring($postbuildStart)
Assert-C30XFix2 -Condition (
  $buildBlock.IndexOf(
    '[bool]$state.sourceQualification.sourceReleaseControlsPassed',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $buildBlock.IndexOf(
    '[bool]$state.sourceQualification.releasePreflightPassed',
    [StringComparison]::Ordinal
  ) -lt 0 -and
  $postbuildBlock.IndexOf(
    '[bool]$state.sourceQualification.releasePreflightPassed',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'source/static controls and current-invocation preflight facts are conflated.'
Assert-C30XFix2 -Condition (
  (
    $launcher.IndexOf(
      '[bool]$preState.sourceQualification.sourceReleaseControlsPassed',
      [StringComparison]::Ordinal
    ) -ge 0 -or
    (
      $launcher.IndexOf(
        '[int]$preState.sourceQualification.completedIdenticalCycles -eq 2',
        [StringComparison]::Ordinal
      ) -ge 0 -and
      $launcher.IndexOf(
        '[bool]$preState.sourceQualification.wholeMobileAnalyzerPassed',
        [StringComparison]::Ordinal
      ) -ge 0
    )
  ) -and
  $launcher.IndexOf(
    '[bool]$preState.sourceQualification.releasePreflightPassed',
    [StringComparison]::Ordinal
  ) -lt 0
) -Message 'founder launcher source proof is missing or still requires a downstream generated preflight result.'
Assert-C30XFix2 -Condition (
  $null -ne $state.sourceQualification.PSObject.Properties[
    'sourceReleaseControlsPassed'
  ] -and
  $null -ne $state.sourceQualification.PSObject.Properties[
    'releasePreflightPassed'
  ] -and
  $null -ne $aggregate.sourceQualification.PSObject.Properties[
    'sourceReleaseControlsPassed'
  ] -and
  $null -ne $aggregate.sourceQualification.PSObject.Properties[
    'releasePreflightPassed'
  ]
) -Message 'state and aggregate do not distinguish source/static and generated preflight facts.'

Write-Output (
  'C30X FIX2 preflight-order contract passed: ' +
  'sourceControlsBeforeWrapper=true; configAndManifestBeforeConsume=true; ' +
  'releasePreflightOwnedByWrapper=true; AABAfterConsume=true.'
)
