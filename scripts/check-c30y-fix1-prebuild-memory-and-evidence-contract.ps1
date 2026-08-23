[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))

function Assert-C30YFix1 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30Y FIX1 prebuild contract rejected: $Message"
  }
}

function Resolve-C30YFix1File {
  param(
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Label
  )
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C30YFix1 -Condition (
    $path.StartsWith(
      $root + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath $path -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $path
}

$ticketPath = Resolve-C30YFix1File `
  -RelativePath 'config/uaw-c30y-fix1-prebuild-regression-memory-and-evidence-truth-ticket.json' `
  -Label 'FIX1 ticket'
$memoryPath = Resolve-C30YFix1File `
  -RelativePath 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression-memory gate'
$c30xPath = Resolve-C30YFix1File `
  -RelativePath 'scripts/check-successor-aab-regression-hard-gate-c30x.ps1' `
  -Label 'C30X successor gate'
$c31cPath = Resolve-C30YFix1File `
  -RelativePath 'scripts/check-uaw-c31c-chat-forward-recipient-contract.ps1' `
  -Label 'C31C chat gate'

foreach ($path in @($PSCommandPath, $memoryPath, $c30xPath, $c31cPath)) {
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $path,
    [ref]$tokens,
    [ref]$errors
  )
  Assert-C30YFix1 -Condition (@($errors).Count -eq 0) `
    -Message "PowerShell parser rejected: $path"
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C30YFix1 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C30Y-FIX1-PREBUILD-REGRESSION-MEMORY-AND-EVIDENCE-TRUTH' -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceMutationAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX1 ticket identity or authority boundary changed.'

$memorySource = Get-Content -Raw -LiteralPath $memoryPath
$c30xSource = Get-Content -Raw -LiteralPath $c30xPath
$c31cSource = Get-Content -Raw -LiteralPath $c31cPath
Assert-C30YFix1 -Condition (
  $memorySource.IndexOf(
    "[ValidateSet('none', 'debug', 'profile', 'release')]",
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $memorySource.IndexOf(
    "if (`$BuildMode -eq 'none') { throw 'Build phase requires an exact build mode.' }",
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'regression memory does not expose release while retaining the none fail-closed rule.'
Assert-C30YFix1 -Condition (
  $c30xSource.IndexOf(
    '-Phase build -BuildMode release -RepositoryRoot $root',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $c30xSource.IndexOf(
    '-Phase build -BuildMode none -RepositoryRoot $root',
    [StringComparison]::Ordinal
  ) -lt 0
) -Message 'C30X is not bound exclusively to the release regression-memory mode.'
Assert-C30YFix1 -Condition (
  $c31cSource.IndexOf(
    '$validatedBuildAuthorityLabel =',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $c31cSource.IndexOf(
    '$validatedBuildAuthorityLabel + ''; device=false.''',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $c31cSource.IndexOf(
    'liveWrites=false; deployment=false; build=false; device=false.',
    [StringComparison]::Ordinal
  ) -lt 0
) -Message 'C31C success evidence is not bound to the validated build-authority value.'

& $memoryPath -Phase build -BuildMode release -RepositoryRoot $root
$noneRejected = $false
try {
  & $memoryPath -Phase build -BuildMode none -RepositoryRoot $root
} catch {
  $noneRejected = $_.Exception.Message -ceq
    'Build phase requires an exact build mode.'
}
Assert-C30YFix1 -Condition $noneRejected `
  -Message 'regression memory did not reject BuildMode none with the exact owner message.'

Write-Output (
  'C30Y FIX1 prebuild contract passed: releaseMode=true; ' +
  'noneRejected=true; C30XReleaseBinding=true; C31CEvidenceDynamic=true.'
)
