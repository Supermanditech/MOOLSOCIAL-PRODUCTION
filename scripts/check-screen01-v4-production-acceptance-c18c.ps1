[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)

function Assert-C18C {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw "Screen01 v4 C18C gate rejected: $Message" }
}

function Resolve-RepoFile {
  param([string]$RelativePath, [string]$Label)
  Assert-C18C (-not [string]::IsNullOrWhiteSpace($RelativePath)) "$Label path is blank."
  Assert-C18C (-not [IO.Path]::IsPathRooted($RelativePath)) "$Label path is not repository-relative."
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C18C ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) "$Label escaped repository."
  Assert-C18C (Test-Path -LiteralPath $path -PathType Leaf) "$Label is missing: $RelativePath"
  return $path
}

function Get-Sha256 {
  param([string]$RelativePath)
  $path = Resolve-RepoFile $RelativePath $RelativePath
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
}

$manifestPath = Resolve-RepoFile 'approved-references/manifest.json' 'approved-reference manifest'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$screen01 = @($manifest.screens | Where-Object { $_.screenId -ceq 'app-splash-first-open' })
Assert-C18C ($screen01.Count -eq 4) 'expected immutable Screen01 versions v1 through v4.'
Assert-C18C ((@($screen01.version) -join ',') -ceq 'v1,v2,v3,v4') 'Screen01 version order changed.'
$active = @($screen01 | Where-Object { $_.status -ceq 'production-accepted' })
Assert-C18C ($active.Count -eq 1) 'exactly one Screen01 version must be production-accepted.'
Assert-C18C ($active[0].version -ceq 'v4') 'Screen01 v4 is not the sole active production version.'
$v3 = @($screen01 | Where-Object { $_.version -ceq 'v3' })[0]
$v4 = $active[0]
Assert-C18C ($v3.status -ceq 'superseded-production-accepted') 'v3 must remain immutable superseded acceptance.'
Assert-C18C ($v4.supersedes -ceq 'v3') 'v4 does not declare v3 lineage.'
Assert-C18C ($v4.sourceType -ceq 'native-production-no-html-copy') 'v4 source boundary changed.'
Assert-C18C ((Get-Sha256 'approved-references/screens/01-app-splash-first-open/v3/production-acceptance.json') -ceq '8aa59820dbee38a8073f35dc242b10d7df09719efc4d727654f017f0bab3351e') 'immutable v3 production acceptance changed.'

$v4Root = Join-Path $root 'approved-references/screens/01-app-splash-first-open/v4'
$v4Files = @(Get-ChildItem -LiteralPath $v4Root -File | Sort-Object Name)
Assert-C18C ($v4Files.Count -eq 4) 'v4 package must contain exactly four text lock files.'
Assert-C18C ((@($v4Files.Name) -join ',') -ceq 'interaction-contract.json,production-acceptance.json,README.md,SHA256SUMS') 'v4 package inventory changed.'
$copiedWebFiles = @(Get-ChildItem -LiteralPath $v4Root -Recurse -File | Where-Object { $_.Extension -cin @('.html', '.css', '.js') })
Assert-C18C ($copiedWebFiles.Count -eq 0) 'v4 contains copied HTML, CSS or JavaScript.'

$contractPath = Resolve-RepoFile ('approved-references/' + [string]$v4.interactionContract) 'v4 interaction contract'
$acceptancePath = Resolve-RepoFile ('approved-references/' + [string]$v4.productionAcceptance) 'v4 production acceptance'
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$acceptance = Get-Content -Raw -LiteralPath $acceptancePath | ConvertFrom-Json
Assert-C18C ($contract.screen.approvalVersion -ceq 'native-production-v4') 'interaction version changed.'
Assert-C18C ($contract.screen.status -ceq 'Accepted') 'interaction is not accepted.'
Assert-C18C ($contract.motion.revealDurationMs -eq $null) 'unexpected legacy revealDuration field exists.'
Assert-C18C ($contract.states[0].revealDurationMs -eq 2400) 'progressive reveal duration changed.'
Assert-C18C (-not [bool]$contract.motion.perpetualMotionAllowed) 'perpetual launch motion is allowed.'
Assert-C18C ($contract.semanticDependency.enforcedBy -ceq 'scripts/check-brand-integrity.ps1') 'semantic brand dependency gate changed.'
Assert-C18C ($acceptance.status -ceq 'Accepted') 'v4 production acceptance is not Accepted.'
Assert-C18C ($acceptance.screen.referenceVersion -ceq 'v4') 'v4 acceptance version changed.'
Assert-C18C ([bool]$acceptance.lineage.v3FilesPreserved) 'v3 preservation is false.'
Assert-C18C ($acceptance.lineage.r50SourceManifestSha256 -ceq '7E9E76F2753D72E9034D68DD4825405D826D67065F77DFDACB808099689103D5') 'R50 source-manifest lineage changed.'
Assert-C18C ((Get-Sha256 'artifacts/quality/buy-fv2-139-progressive-lockup-r50-20260801-61/16-source-manifest-final-prebuild.txt') -ceq '7e9e76f2753d72e9034d68dd4825405d826d67065f77dfdacb808099689103d5') 'R50 immutable source manifest changed.'

$expectedLocks = [ordered]@{
  'apps/mobile/lib/ui_v2/launch/launch_presentation_gate.dart' = '24d41d7d62ae73d1df875f4b4f740bb79433badefc3b7b598f8f1f8925fe0ef0'
  'apps/mobile/lib/ui_v2/launch/launch_interruption_guard.dart' = '3e6f58220a6a3b646998562690574b6b91dba4e042ef22248bccb5aceb586824'
  'apps/mobile/lib/ui_v2/screens/screen01_app_splash/app_splash_screen_v2.dart' = 'd08dba928b884554984d28891f5e465b1f7fa910d3884ebe49b6466d199147be'
  'apps/mobile/android/app/src/main/res/drawable/launch_transparent.xml' = '517b2bc2d4d8c0ba64b4c1031c5f9b473b3855c965d03d0be8d7e6d2b4a977f0'
  'apps/mobile/android/app/src/main/res/values-v31/styles.xml' = '84c8a1013f5c8e650090ae80294f7b6663afdb0c8fbbd1cfea77661b3842bd71'
  'apps/mobile/android/app/src/main/res/values-night-v31/styles.xml' = '143cf58652d25013672c611fa1c47f54fc75048ca594435b1b82cd481dfa5222'
  'apps/mobile/test/ui_v2_screen01_app_splash_test.dart' = '39ddd73796415048784471d34612db8c575c85f48ac8c243b3f35f22fb78d3b8'
  'apps/mobile/test/ui_v2_screen01_golden_test.dart' = 'a9fc88904c3e32464a361ae51f02da184a5488bf08859bf968193ef0f34e08ec'
  'apps/mobile/test/ui_v2_first_open_interruption_test.dart' = '38036791d1ae9a82384171b0dd34ecdc9f0b58924b92615d38db495fea63d096'
  'apps/mobile/test/goldens/ui_v2_screen01_normal-motion-midpoint-360x720.png' = 'c5337f97e8f2c29bf9bbbe8e5c9eaf23ed4c40795621149336d15e035249312e'
  'apps/mobile/test/goldens/ui_v2_screen01_handoff-360x720.png' = '6d03bb0b1b617d8b03c7480b34acda59a230b76dbb2905a092bd6a1c3eed9eab'
  'apps/mobile/test/goldens/ui_v2_screen01_recovery-360x720.png' = '34edd779b58bb946d4b4a90d2dcef75e0160c5e8b95432b450c3232953a33959'
}
$actualLocks = @($acceptance.lockedFiles)
Assert-C18C ($actualLocks.Count -eq $expectedLocks.Count) 'v4 locked-file count changed.'
foreach ($pair in $expectedLocks.GetEnumerator()) {
  $lock = @($actualLocks | Where-Object { $_.path -ceq $pair.Key })
  Assert-C18C ($lock.Count -eq 1) "v4 lock missing or duplicated: $($pair.Key)"
  Assert-C18C (([string]$lock[0].sha256).ToLowerInvariant() -ceq $pair.Value) "v4 recorded hash changed: $($pair.Key)"
  Assert-C18C ((Get-Sha256 $pair.Key) -ceq $pair.Value) "v4 production owner changed: $($pair.Key)"
}

$ticket = Get-Content -Raw -LiteralPath (Resolve-RepoFile 'config/uaw-personal-mvp-protected-screen01-r50-approved-ui-lock-reconciliation-fix1-c18-ticket.json' 'C18 ticket') | ConvertFrom-Json
Assert-C18C ([bool]$ticket.c18bAuthorization.referenceWriteAuthorized) 'C18B reference authorization is false.'
Assert-C18C ([bool]$ticket.c18bAuthorization.testGoldenWriteAuthorized) 'C18B golden authorization is false.'
Assert-C18C (-not [bool]$ticket.c18bAuthorization.runtimeSourceWriteAuthorized) 'C18B runtime-source authorization expanded.'
Assert-C18C (-not [bool]$ticket.c18bAuthorization.buildAuthorized) 'C18B build authorization opened.'
Assert-C18C (-not [bool]$ticket.c18bAuthorization.installAuthorized) 'C18B install authorization opened.'

& (Join-Path $root 'scripts/check-approved-ui-locks.ps1')
& (Join-Path $root 'scripts/check-brand-integrity.ps1')

Write-Output 'Screen01 v4 production acceptance C18C gate passed: versions=4; active=v4; lockedFiles=12; htmlCopied=false; buildInstall=false.'
