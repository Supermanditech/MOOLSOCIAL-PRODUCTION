[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C33FFix4 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C33F FIX4 hidden founder-input order test rejected: $Message"
  }
}

function Resolve-C33FFix4File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C33FFix4 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Assert-C33FFix4Parses {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $tokens = $null
  $errors = $null
  [Management.Automation.Language.Parser]::ParseFile(
    $Path,
    [ref]$tokens,
    [ref]$errors
  ) | Out-Null
  Assert-C33FFix4 -Condition (@($errors).Count -eq 0) `
    -Message "$Label does not parse on the current PowerShell host."
}

function Test-C33FFix4PreBuildEligibility {
  param([Parameter(Mandatory)]$State)
  return (
    [string]$State.buildAuthorization -ceq 'available_once' -and
    [string]$State.buildResult.state -ceq 'not_started' -and
    [int]$State.buildResult.buildCount -eq 0 -and
    -not [bool]$State.founderAuthorization.hiddenFounderInputsEntered
  )
}

$launcherPath = Resolve-C33FFix4File `
  -Path 'tmp/run-c30x-successor-single-aab-founder.ps1' `
  -Label 'founder launcher'
$wrapperPath = Resolve-C33FFix4File `
  -Path 'scripts/invoke-play-internal-aab-build-c30t.ps1' `
  -Label 'single-AAB wrapper'
Assert-C33FFix4Parses -Path $launcherPath -Label 'founder launcher'
Assert-C33FFix4Parses -Path $wrapperPath -Label 'single-AAB wrapper'

$launcher = Get-Content -Raw -LiteralPath $launcherPath
$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$markerPattern =
  '\$state[.]founderAuthorization[.]hiddenFounderInputsEntered\s*=\s*\$true'
Assert-C33FFix4 -Condition (
  [regex]::Matches($launcher, $markerPattern).Count -eq 0
) -Message 'launcher still consumes the founder-input marker before wrapper entry.'
Assert-C33FFix4 -Condition (
  [regex]::Matches($wrapper, $markerPattern).Count -eq 1
) -Message 'wrapper must own exactly one founder-input marker consumption.'

$gateIndex = $wrapper.IndexOf('& $gate -Phase build', [StringComparison]::Ordinal)
$configIndex = $wrapper.IndexOf(
  '$releaseConfigExitCode = Invoke-NativeCaptured',
  [StringComparison]::Ordinal
)
$manifestIndex = $wrapper.IndexOf(
  '$manifestExitCode = Invoke-NativeCaptured',
  [StringComparison]::Ordinal
)
$preflightIndex = $wrapper.IndexOf(
  '$state.sourceQualification.releasePreflightPassed = $true',
  [StringComparison]::Ordinal
)
$consumeIndex = $wrapper.IndexOf(
  '$state.buildAuthorization = ''consumed''',
  [StringComparison]::Ordinal
)
$markerIndex = $wrapper.IndexOf(
  '$state.founderAuthorization.hiddenFounderInputsEntered = $true',
  [StringComparison]::Ordinal
)
$stateWriteIndex = $wrapper.IndexOf(
  "Write-JsonState -State `$state -Path `$stateFile -Suffix '.c30t-build-write'",
  [StringComparison]::Ordinal
)
$appbundleIndex = $wrapper.IndexOf(
  '$buildArguments = @(''build'', ''appbundle''',
  [StringComparison]::Ordinal
)
Assert-C33FFix4 -Condition (
  $gateIndex -ge 0 -and
  $gateIndex -lt $configIndex -and
  $configIndex -lt $manifestIndex -and
  $manifestIndex -lt $preflightIndex -and
  $preflightIndex -lt $consumeIndex -and
  $consumeIndex -lt $markerIndex -and
  $markerIndex -lt $stateWriteIndex -and
  $stateWriteIndex -lt $appbundleIndex
) -Message 'wrapper gate/preflight/consumption/state-write/appbundle order changed.'

$eligible = [pscustomobject]@{
  buildAuthorization = 'available_once'
  buildResult = [pscustomobject]@{
    state = 'not_started'
    buildCount = 0
  }
  founderAuthorization = [pscustomobject]@{
    hiddenFounderInputsEntered = $false
  }
}
Assert-C33FFix4 -Condition (Test-C33FFix4PreBuildEligibility -State $eligible) `
  -Message 'eligible prebuild fixture was rejected.'

$premature = $eligible | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$premature.founderAuthorization.hiddenFounderInputsEntered = $true
Assert-C33FFix4 -Condition (-not (Test-C33FFix4PreBuildEligibility -State $premature)) `
  -Message 'premature founder-input marker was not rejected.'

$consumed = $eligible | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$consumed.buildAuthorization = 'consumed'
$consumed.founderAuthorization.hiddenFounderInputsEntered = $true
$consumed.buildResult.state =
  'release_config_manifest_and_single_AAB_build_in_progress_authority_consumed'
$consumed.buildResult.buildCount = 1
Assert-C33FFix4 -Condition (
  -not (Test-C33FFix4PreBuildEligibility -State $consumed) -and
  [string]$consumed.buildAuthorization -ceq 'consumed' -and
  [bool]$consumed.founderAuthorization.hiddenFounderInputsEntered -and
  [int]$consumed.buildResult.buildCount -eq 1
) -Message 'post-preflight atomic consumption projection changed.'

Write-Output (
  'C33F FIX4 hidden founder-input order test passed: ' +
  'launcherPreconsumeMarkers=0; wrapperConsumeMarkers=1; noBuild=true.'
)
