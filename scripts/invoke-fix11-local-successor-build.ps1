[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'FIX11 local successor build requires PowerShell 7.'
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

function Assert-Fix11Build([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "FIX11 local successor build rejected: $Message"
  }
}

Assert-Fix11Build (
  $env:MOOLSOCIAL_FIX11_LOCAL_PREFLIGHT_QUALIFIED -ceq 'true'
) 'same-session local signer preflight marker is absent.'
Assert-Fix11Build (
  $env:MOOLSOCIAL_GOOGLE_SIDELOAD_SIGNING_QUALIFIED -ceq 'true'
) 'same-session secure signing marker is absent.'

$branch = (git -C $repositoryRoot branch --show-current).Trim()
$head = (git -C $repositoryRoot rev-parse HEAD).Trim()
Assert-Fix11Build ($branch -ceq
  'remediation/prototype-conformance-2026-07-20') 'branch changed.'
Assert-Fix11Build ($head -ceq $expectedHead) 'HEAD changed.'

& (Join-Path $PSScriptRoot `
  'check-google-authentication-production-traceability-map.ps1') `
  -RepositoryRoot $repositoryRoot
$traceabilityPassed = $?
Assert-Fix11Build $traceabilityPassed `
  'the permanent Google authentication traceability gate failed.'

$machineState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
Assert-Fix11Build ($machineState.machineState -ceq 'prebuild_passed') `
  'machine state is not prebuild_passed.'
Assert-Fix11Build (
  $machineState.buildAuthorization -ceq 'approved_for_one_build'
) 'one-build authorization is absent.'
Assert-Fix11Build ($machineState.candidate.id -ceq $candidateId) `
  'candidate changed.'
Assert-Fix11Build ($machineState.candidate.versionName -ceq
  '1.0.0-r60.87') 'version name changed.'
Assert-Fix11Build ($machineState.candidate.versionCode -ceq
  '2026082387') 'version code changed.'
Assert-Fix11Build ($machineState.candidate.buildMode -ceq 'release') `
  'build mode changed.'
Assert-Fix11Build ($machineState.candidate.gateProfile -ceq
  'uaw_fix11_google_only_sideload_preflight') 'gate profile changed.'
Assert-Fix11Build (
  [bool]$machineState.fix11SuccessorPreflight.buildAuthorized -and
  -not [bool]$machineState.fix11SuccessorPreflight.installAuthorized -and
  -not [bool]$machineState.fix11SuccessorPreflight.signedApkCreated
) 'FIX11 build/install authorization facts changed.'
Assert-Fix11Build (
  [bool]$machineState.source.independentReplayPassed -and
  [string]$machineState.source.manifestPath -ceq $expectedManifestPath -and
  [string]$machineState.source.manifestSha256 -cmatch '^[0-9A-F]{64}$'
) 'final source seal is not independently qualified.'

$manifestFile = Join-Path $repositoryRoot $expectedManifestPath
Assert-Fix11Build (
  Test-Path -LiteralPath $manifestFile -PathType Leaf
) 'final source manifest is missing.'
Assert-Fix11Build (
  (Get-FileHash -LiteralPath $manifestFile -Algorithm SHA256).Hash -ceq
    [string]$machineState.source.manifestSha256
) 'final source manifest hash changed.'

Remove-Item Env:\MOOLSOCIAL_FIX11_LOCAL_PREFLIGHT_QUALIFIED `
  -ErrorAction Stop
Push-Location $repositoryRoot
try {
  & (Join-Path $PSScriptRoot 'build-buy-device-review.ps1') `
    -CandidateId $candidateId `
    -BuildName ([string]$machineState.candidate.versionName) `
    -BuildNumber ([string]$machineState.candidate.versionCode) `
    -SourceFingerprint ([string]$machineState.source.manifestSha256) `
    -ArtifactDirectory (Split-Path -Parent $manifestFile) `
    -BuildMode ([string]$machineState.candidate.buildMode) `
    -MachineStatePath $statePath `
    -RuntimeProfile PublicAuthSideloadPreflight
  Assert-Fix11Build ($?) 'authorized build wrapper returned failure.'
  Write-Output 'FIX11_LOCAL_SUCCESSOR_BUILD_PASSED'
}
finally {
  Pop-Location
}
