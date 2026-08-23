[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C30YFix2 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30Y FIX2 transaction contract rejected: $Message"
  }
}

function Resolve-C30YFix2File {
  param(
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Label
  )
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C30YFix2 -Condition (
    $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $path -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $path
}

function ConvertTo-C30YFix2RelativePath {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $fullPath = [IO.Path]::GetFullPath($Path)
  Assert-C30YFix2 -Condition (
    $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
  ) -Message "$Label escaped the repository."
  return $fullPath.Substring($prefix.Length).Replace('\', '/')
}

$ticketPath = Resolve-C30YFix2File `
  -RelativePath 'config/uaw-c30y-fix2-mutation-safe-release-preflight-source-transaction-ticket.json' `
  -Label 'FIX2 ticket'
$wrapperPath = Resolve-C30YFix2File `
  -RelativePath 'scripts/invoke-play-internal-aab-build-c30t.ps1' `
  -Label 'single-AAB wrapper'
$restorePath = Resolve-C30YFix2File `
  -RelativePath 'scripts/restore-qualified-generated-owner-c30y-fix2.ps1' `
  -Label 'qualified-owner restore gate'

foreach ($path in @($PSCommandPath, $wrapperPath, $restorePath)) {
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $path,
    [ref]$tokens,
    [ref]$errors
  )
  Assert-C30YFix2 -Condition (@($errors).Count -eq 0) `
    -Message "PowerShell parser rejected: $path"
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C30YFix2 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C30Y-FIX2-MUTATION-SAFE-RELEASE-PREFLIGHT-SOURCE-TRANSACTION' -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceMutationAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX2 ticket identity or authority boundary changed.'

$wrapper = Get-Content -Raw -LiteralPath $wrapperPath
$requiredNeedles = @(
  '03b-qualified-registrant-snapshot',
  '03c-qualified-local-properties-snapshot',
  'scripts/restore-qualified-generated-owner-c30y-fix2.ps1',
  '# C30Y FIX2: begin mutation-safe preflight transaction.',
  '# C30Y FIX2: restore full qualified source before authority consumption.',
  '# C30Y FIX2: begin mutation-safe AAB transaction.',
  '# C30Y FIX2: restore full qualified source before postbuild rebind.',
  'qualifiedRegistrantSnapshot = $registrantSnapshotRelative',
  'qualifiedLocalPropertiesSnapshot = $localPropertiesSnapshotRelative'
)
foreach ($needle in $requiredNeedles) {
  Assert-C30YFix2 -Condition (
    $wrapper.IndexOf($needle, [StringComparison]::Ordinal) -ge 0
  ) -Message "wrapper transaction binding is missing: $needle"
}
Assert-C30YFix2 -Condition (
  ([regex]::Matches(
    $wrapper,
    'Restore-C30TQualifiedGeneratedOwners'
  )).Count -eq 3 -and
  ([regex]::Matches($wrapper, "'appbundle'")).Count -eq 1
) -Message 'restore call count or single appbundle invocation changed.'

$snapshotIndex = $wrapper.IndexOf(
  'Copy-Item -LiteralPath ([string]$owner.ownerPath)',
  [StringComparison]::Ordinal
)
$preflightIndex = $wrapper.IndexOf(
  '# C30Y FIX2: begin mutation-safe preflight transaction.',
  [StringComparison]::Ordinal
)
$preflightRestoreIndex = $wrapper.IndexOf(
  '# C30Y FIX2: restore full qualified source before authority consumption.',
  [StringComparison]::Ordinal
)
$authorityIndex = $wrapper.IndexOf(
  '$state.machineState = ''release_config_manifest_and_single_AAB_build_in_progress_authority_consumed''',
  [StringComparison]::Ordinal
)
$aabIndex = $wrapper.IndexOf("'appbundle'", [StringComparison]::Ordinal)
$postbuildRestoreIndex = $wrapper.IndexOf(
  '# C30Y FIX2: restore full qualified source before postbuild rebind.',
  [StringComparison]::Ordinal
)
$postbuildGateIndex = $wrapper.IndexOf(
  '& $gate -Phase postbuild',
  [StringComparison]::Ordinal
)
Assert-C30YFix2 -Condition (
  $snapshotIndex -ge 0 -and
  $snapshotIndex -lt $preflightIndex -and
  $preflightIndex -lt $preflightRestoreIndex -and
  $preflightRestoreIndex -lt $authorityIndex -and
  $authorityIndex -lt $aabIndex -and
  $aabIndex -lt $postbuildRestoreIndex -and
  $postbuildRestoreIndex -lt $postbuildGateIndex
) -Message 'snapshot, preflight, authority, AAB, restore or postbuild order changed.'

$probeParent = Join-Path $root `
  'artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-fix2-transaction-probes'
[void][IO.Directory]::CreateDirectory($probeParent)
$probe = Join-Path $probeParent ([guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($probe)
Assert-C30YFix2 -Condition (
  $probe.StartsWith(
    $probeParent + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  )
) -Message 'transaction probe escaped its exact evidence parent.'
$snapshotProbe = Join-Path $probe 'qualified.snapshot'
$ownerProbe = Join-Path $probe 'generated.owner'
try {
  [IO.File]::WriteAllText(
    $snapshotProbe,
    'qualified-owner-exact-bytes',
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText(
    $ownerProbe,
    'mutated-generated-bytes',
    [Text.UTF8Encoding]::new($false)
  )
  $expected = (Get-FileHash -Algorithm SHA256 -LiteralPath $snapshotProbe).Hash
  $snapshotRelative = ConvertTo-C30YFix2RelativePath `
    -Path $snapshotProbe `
    -Label 'qualified snapshot probe'
  $ownerRelative = ConvertTo-C30YFix2RelativePath `
    -Path $ownerProbe `
    -Label 'generated owner probe'
  & $restorePath `
    -SnapshotPath $snapshotRelative `
    -OwnerPath $ownerRelative `
    -ExpectedSha256 $expected `
    -RepositoryRoot $root | Out-Null
  Assert-C30YFix2 -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $ownerProbe).Hash -ceq
      $expected
  ) -Message 'positive transaction probe did not restore exact bytes.'

  [IO.File]::WriteAllText(
    $ownerProbe,
    'second-mutated-generated-bytes',
    [Text.UTF8Encoding]::new($false)
  )
  $mutatedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ownerProbe).Hash
  $negativeRejected = $false
  try {
    & $restorePath `
      -SnapshotPath $snapshotRelative `
      -OwnerPath $ownerRelative `
      -ExpectedSha256 ('0' * 64) `
      -RepositoryRoot $root | Out-Null
  } catch {
    $negativeRejected = $_.Exception.Message -ceq
      'C30Y FIX2 qualified-owner restore rejected: qualified snapshot hash changed.'
  }
  Assert-C30YFix2 -Condition (
    $negativeRejected -and
    (Get-FileHash -Algorithm SHA256 -LiteralPath $ownerProbe).Hash -ceq
      $mutatedHash
  ) -Message 'negative transaction probe changed the owner or wrong error owner fired.'
} finally {
  if (Test-Path -LiteralPath $probe) {
    Remove-Item -LiteralPath $probe -Recurse -Force
  }
}

Write-Output (
  'C30Y FIX2 mutation-safe preflight contract passed: snapshots=2; ' +
  'preflightRestore=true; postbuildRestore=true; positiveProbe=true; ' +
  'negativeProbe=true; appbundleInvocations=1.'
)
