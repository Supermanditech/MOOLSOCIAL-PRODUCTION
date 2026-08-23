[CmdletBinding()]
param(
  [ValidateSet('reconcile', 'preinstall', 'postinstall', 'journey')]
  [string]$Phase = 'reconcile',
  [string]$StatePath,
  [string]$CandidateId = 'UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-INSTALL-RECOVERY-C30R',
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) { $StatePath = Join-Path $root 'config/play-internal-install-recovery-gate-state-c30r.json' }

function Assert-C30R {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30R Play install recovery gate rejected: $Message" }
}
function Resolve-RepoFile {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  Assert-C30R -Condition (-not [string]::IsNullOrWhiteSpace($Path)) -Message "$Label path missing."
  Assert-C30R -Condition (-not [IO.Path]::IsPathRooted($Path)) -Message "$Label path must be repository-relative."
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $Path))
  Assert-C30R -Condition ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message "$Label escaped repository."
  Assert-C30R -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) -Message "$Label missing."
  return $resolved
}

$stateFile = [IO.Path]::GetFullPath($StatePath)
Assert-C30R -Condition ($stateFile.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -Message 'state escaped repository.'
Assert-C30R -Condition (Test-Path -LiteralPath $stateFile -PathType Leaf) -Message 'state missing.'
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
Assert-C30R -Condition ([int]$state.schemaVersion -eq 1 -and [string]$state.contractId -ceq 'PLAY-INTERNAL-INSTALL-RECOVERY-GATES-C30R-001') -Message 'state contract changed.'
Assert-C30R -Condition ([string]$state.ticketId -ceq $CandidateId) -Message 'candidate changed.'

$branch = (& git -C $root branch --show-current).Trim()
$head = (& git -C $root rev-parse HEAD).Trim()
Assert-C30R -Condition ($branch -ceq [string]$state.branch -and $head -ceq [string]$state.head) -Message 'branch or HEAD changed.'

& (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') -Phase device
& (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') -CandidateId $CandidateId -RequireExecutionAuthorized -RepositoryRoot $root

$artifact = Resolve-RepoFile -Path ([string]$state.candidate.artifactPath) -Label 'C30Q AAB'
Assert-C30R -Condition ((Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash -ceq [string]$state.candidate.artifactSha256) -Message 'C30Q AAB hash changed.'
[void](Resolve-RepoFile -Path ([string]$state.predecessor.preservationEvidence) -Label 'predecessor preservation evidence')
[void](Resolve-RepoFile -Path ([string]$state.predecessor.removalEvidence) -Label 'predecessor removal evidence')
[void](Resolve-RepoFile -Path ([string]$state.communicationHold.reviewerPackage) -Label 'reviewer package')

Assert-C30R -Condition (
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.versionName -ceq '1.0.0-r60.43' -and
  [string]$state.candidate.versionCode -ceq '2026081243' -and
  [string]$state.candidate.playAppSigningSha256 -ceq '47B28C7DDE2B61CAB6A7748C9019A3B57376B3BE1DC163D48253BBA35B63CDD9'
) -Message 'candidate identity changed.'
Assert-C30R -Condition (
  [string]$state.distribution.track -ceq 'internal' -and
  [bool]$state.distribution.releaseActive -and
  [int]$state.distribution.buildCount -eq 1 -and
  [int]$state.distribution.uploadCount -eq 1 -and
  -not [bool]$state.distribution.newBuildAuthorized -and
  -not [bool]$state.distribution.newUploadAuthorized -and
  -not [bool]$state.distribution.productionRolloutAuthorized -and
  -not [bool]$state.distribution.openTestingAuthorized -and
  -not [bool]$state.distribution.publicListingAuthorized
) -Message 'distribution boundary changed.'
Assert-C30R -Condition (
  [bool]$state.predecessor.founderRemoved -and
  [bool]$state.predecessor.packageAbsentReadback -and
  -not [bool]$state.predecessor.privateLocalDataRecoverable
) -Message 'predecessor removal truth changed.'
Assert-C30R -Condition (
  [int]$state.installResult.candidateInstallCount -le 1 -and
  -not [bool]$state.installResult.adbInstallPerformed -and
  -not [bool]$state.installResult.secondInstallPerformed -and
  -not [bool]$state.communicationHold.emailSent -and
  -not [bool]$state.communicationHold.quotaSubmitted
) -Message 'single Play install or communication boundary changed.'

if ($Phase -eq 'preinstall') {
  Assert-C30R -Condition (
    [string]$state.machineState -ceq 'package_absent_one_existing_Play_release_install_authorized' -and
    [string]$state.installResult.installAuthority -ceq 'available_not_consumed' -and
    [int]$state.installResult.candidateInstallCount -eq 0 -and
    [string]$state.installResult.state -ceq 'not_started'
  ) -Message 'install authority unavailable.'
  $adb = (Get-Command adb -ErrorAction Stop).Source
  $deviceLine = (& $adb devices -l | Select-String "^$([regex]::Escape([string]$state.device.serial))\s+device\s" | Select-Object -First 1).Line
  Assert-C30R -Condition (-not [string]::IsNullOrWhiteSpace($deviceLine)) -Message 'exact OPPO not connected.'
  $packagePath = @(& $adb -s ([string]$state.device.serial) shell pm path ([string]$state.candidate.packageName))
  Assert-C30R -Condition ($packagePath.Count -eq 0) -Message 'candidate package is already present before the one Play install.'
}

if ($Phase -in @('postinstall', 'journey')) {
  Assert-C30R -Condition (
    [string]$state.installResult.installAuthority -ceq 'consumed' -and
    [int]$state.installResult.candidateInstallCount -eq 1 -and
    [string]$state.installResult.installerPackageName -ceq 'com.android.vending' -and
    [string]$state.installResult.installedVersionName -ceq '1.0.0-r60.43' -and
    [string]$state.installResult.installedVersionCode -ceq '2026081243' -and
    [string]$state.installResult.installedSignerSha256 -ceq [string]$state.candidate.playAppSigningSha256 -and
    [bool]$state.installResult.playArtifactRelationshipProved
  ) -Message 'Play-installed candidate identity not sealed.'
  [void](Resolve-RepoFile -Path ([string]$state.installResult.postinstallEvidence) -Label 'postinstall evidence')
}

if ($Phase -eq 'journey') {
  Assert-C30R -Condition (
    [string]$state.machineState -ceq 'Play_installed_identity_sealed_runtime_testing_authorized' -and
    [string]$state.journeyResult.state -ceq 'runtime_testing_authorized'
  ) -Message 'runtime is not authorized for journey execution.'
}

Write-Output "C30R Play install recovery gate passed: phase=$Phase; buildCount=$($state.distribution.buildCount); uploadCount=$($state.distribution.uploadCount); installCount=$($state.installResult.candidateInstallCount)."
