[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'FIX11 local signer preflight requires PowerShell 7.'
}

$repositoryRoot = [IO.Path]::GetFullPath(
  (Split-Path -Parent $PSScriptRoot)
).TrimEnd([char[]]@(
  [IO.Path]::DirectorySeparatorChar,
  [IO.Path]::AltDirectorySeparatorChar
))
$statePath = Join-Path $repositoryRoot 'config\apk-regression-gate-state.json'
$expectedManifestPath = (
  'artifacts/quality/' +
  'uaw-c34p-fix11-google-sign-in-final-r60-87-20260823-01/' +
  'source-aggregate-manifest.txt'
)
$candidateId = 'UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR'
$expectedHead = 'f6dfe7587aa02d782e94282d14af8bafff48ded0'

function Assert-Fix11Preflight([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "FIX11 local signer preflight rejected: $Message"
  }
}

Remove-Item Env:\MOOLSOCIAL_FIX11_LOCAL_PREFLIGHT_QUALIFIED `
  -ErrorAction SilentlyContinue

$branch = (git -C $repositoryRoot branch --show-current).Trim()
$head = (git -C $repositoryRoot rev-parse HEAD).Trim()
Assert-Fix11Preflight ($branch -ceq
  'remediation/prototype-conformance-2026-07-20') 'branch changed.'
Assert-Fix11Preflight ($head -ceq $expectedHead) 'HEAD changed.'

& (Join-Path $PSScriptRoot `
  'check-google-authentication-production-traceability-map.ps1') `
  -RepositoryRoot $repositoryRoot
$traceabilityPassed = $?
Assert-Fix11Preflight $traceabilityPassed `
  'the permanent Google authentication traceability gate failed.'

$machineState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
Assert-Fix11Preflight ($machineState.machineState -ceq 'prebuild_passed') `
  'machine state is not prebuild_passed.'
Assert-Fix11Preflight (
  $machineState.buildAuthorization -ceq 'approved_for_one_build'
) 'one-build authorization is absent.'
Assert-Fix11Preflight ($machineState.candidate.id -ceq $candidateId) `
  'candidate changed.'
Assert-Fix11Preflight ($machineState.candidate.versionName -ceq
  '1.0.0-r60.87') 'version name changed.'
Assert-Fix11Preflight ($machineState.candidate.versionCode -ceq
  '2026082387') 'version code changed.'
Assert-Fix11Preflight ($machineState.candidate.buildMode -ceq 'release') `
  'build mode changed.'
Assert-Fix11Preflight ($machineState.candidate.gateProfile -ceq
  'uaw_fix11_google_only_sideload_preflight') 'gate profile changed.'
Assert-Fix11Preflight (
  [bool]$machineState.fix11SuccessorPreflight.buildAuthorized -and
  -not [bool]$machineState.fix11SuccessorPreflight.installAuthorized -and
  -not [bool]$machineState.fix11SuccessorPreflight.signedApkCreated
) 'FIX11 build/install authorization facts changed.'
Assert-Fix11Preflight (
  [bool]$machineState.source.independentReplayPassed -and
  [string]$machineState.source.manifestPath -ceq $expectedManifestPath -and
  [string]$machineState.source.manifestSha256 -cmatch '^[0-9A-F]{64}$'
) 'final source seal is not independently qualified.'

$manifestFile = Join-Path $repositoryRoot $expectedManifestPath
Assert-Fix11Preflight (
  Test-Path -LiteralPath $manifestFile -PathType Leaf
) 'final source manifest is missing.'
Assert-Fix11Preflight (
  (Get-FileHash -LiteralPath $manifestFile -Algorithm SHA256).Hash -ceq
    [string]$machineState.source.manifestSha256
) 'final source manifest hash changed.'

Push-Location $repositoryRoot
try {
  . (Join-Path $PSScriptRoot `
    'prepare-moolsocial-sideload-build-environment.ps1') `
    -GoogleOnly `
    -CandidateId $candidateId
  Assert-Fix11Preflight (
    $env:MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED -ceq 'true'
  ) 'secure signing preparation did not pass.'

  $preflightOutput = @(
    & (Join-Path $PSScriptRoot 'build-buy-device-review.ps1') `
      -CandidateId $candidateId `
      -BuildName ([string]$machineState.candidate.versionName) `
      -BuildNumber ([string]$machineState.candidate.versionCode) `
      -SourceFingerprint ([string]$machineState.source.manifestSha256) `
      -ArtifactDirectory (Split-Path -Parent $manifestFile) `
      -BuildMode ([string]$machineState.candidate.buildMode) `
      -MachineStatePath $statePath `
      -RuntimeProfile PublicAuthSideloadPreflight `
      -PreflightOnly
  )
  Assert-Fix11Preflight ($?) 'build-wrapper preflight returned failure.'
  Assert-Fix11Preflight (
    @($preflightOutput | Where-Object {
      [string]$_ -like 'Device-review APK preflight passed without artifact build:*'
    }).Count -eq 1
  ) 'build-wrapper preflight success marker is absent or duplicated.'
  $env:MOOLSOCIAL_FIX11_LOCAL_PREFLIGHT_QUALIFIED = 'true'
  Write-Output 'FIX11_LOCAL_SIGNER_PREFLIGHT_PASSED'
  Write-Output 'Keep this PowerShell 7 window open; do not build until authorized.'
}
finally {
  Pop-Location
}
