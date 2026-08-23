[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C19 {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw "Screen03 v3 C19 gate rejected: $Message" }
}

function Resolve-C19RepoFile {
  param([string]$RelativePath, [string]$Label)
  Assert-C19 (-not [string]::IsNullOrWhiteSpace($RelativePath)) "$Label path is blank."
  Assert-C19 (-not [IO.Path]::IsPathRooted($RelativePath)) "$Label path is not repository-relative."
  $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C19 ($path.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) "$Label escaped repository."
  Assert-C19 (Test-Path -LiteralPath $path -PathType Leaf) "$Label is missing: $RelativePath"
  return $path
}

function Get-C19Sha256 {
  param([string]$RelativePath)
  $path = Resolve-C19RepoFile $RelativePath $RelativePath
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
}

$manifestPath = Resolve-C19RepoFile 'approved-references/manifest.json' 'approved-reference manifest'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$screen03 = @($manifest.screens | Where-Object { $_.screenId -ceq 'login-account-handoff' })
Assert-C19 ($screen03.Count -eq 3) 'expected immutable Screen03 versions v1 through v3.'
Assert-C19 ((@($screen03.version) -join ',') -ceq 'v1,v2,v3') 'Screen03 version order changed.'
$active = @($screen03 | Where-Object { $_.status -ceq 'production-accepted' })
Assert-C19 ($active.Count -eq 1) 'exactly one Screen03 version must be production-accepted.'
Assert-C19 ($active[0].version -ceq 'v3') 'Screen03 v3 is not the sole active production version.'
$v2 = @($screen03 | Where-Object { $_.version -ceq 'v2' })[0]
$v3 = $active[0]
Assert-C19 ($v2.status -ceq 'superseded-production-accepted') 'v2 must remain immutable superseded acceptance.'
Assert-C19 ($v3.supersedes -ceq 'v2') 'v3 does not declare v2 lineage.'
Assert-C19 ($v3.sourceType -ceq 'native-production-no-html-copy') 'v3 source boundary changed.'

$v2ImmutableHashes = [ordered]@{
  'approved-references/screens/03-login-account-handoff/v2/README.md' = 'e1235e47a2eac51faa286a7957e8ea66d7759af2a1356abf46f4cb72d94070c6'
  'approved-references/screens/03-login-account-handoff/v2/interaction-contract.json' = '05fb4086ea4601f1c09a3d1ffd3de0e036c58dea803d396172f0070c93e40413'
  'approved-references/screens/03-login-account-handoff/v2/production-acceptance.json' = 'e77c45d2ea5cea6c3f4d7f9e75d6c8c928826254ea9d9b2934e3964eb335baf1'
  'approved-references/screens/03-login-account-handoff/v2/SHA256SUMS' = '6457aa2361a819a3fe2d10f8dcf4a50dd1257b12d410256200568edca3c7a70b'
}
foreach ($pair in $v2ImmutableHashes.GetEnumerator()) {
  Assert-C19 ((Get-C19Sha256 $pair.Key) -ceq $pair.Value) "immutable v2 file changed: $($pair.Key)"
}

$v3Root = Join-Path $root 'approved-references/screens/03-login-account-handoff/v3'
$v3Files = @(Get-ChildItem -LiteralPath $v3Root -File | Sort-Object Name)
Assert-C19 ($v3Files.Count -eq 4) 'v3 package must contain exactly four text lock files.'
Assert-C19 ((@($v3Files.Name) -join ',') -ceq 'interaction-contract.json,production-acceptance.json,README.md,SHA256SUMS') 'v3 package inventory changed.'
$copiedWebFiles = @(Get-ChildItem -LiteralPath $v3Root -Recurse -File | Where-Object { $_.Extension -cin @('.html', '.css', '.js') })
Assert-C19 ($copiedWebFiles.Count -eq 0) 'v3 contains copied HTML, CSS or JavaScript.'
$copiedImages = @(Get-ChildItem -LiteralPath $v3Root -Recurse -File | Where-Object { $_.Extension -cin @('.png', '.jpg', '.jpeg', '.webp', '.svg') })
Assert-C19 ($copiedImages.Count -eq 0) 'v3 contains copied reference images or assets.'

$contractPath = 'approved-references/' + [string]$v3.interactionContract
$acceptancePath = 'approved-references/' + [string]$v3.productionAcceptance
$contract = Get-Content -Raw -LiteralPath (Resolve-C19RepoFile $contractPath 'v3 interaction contract') | ConvertFrom-Json
$acceptance = Get-Content -Raw -LiteralPath (Resolve-C19RepoFile $acceptancePath 'v3 production acceptance') | ConvertFrom-Json
Assert-C19 ($contract.screen.approvalVersion -ceq 'native-production-v3') 'interaction version changed.'
Assert-C19 ($contract.screen.status -ceq 'Accepted') 'interaction is not accepted.'
Assert-C19 (-not [bool]$contract.presentation.changedFromV2) 'presentation claims a v2 change.'
Assert-C19 ([bool]$contract.profileProvenance.requiredForProfileDeviceReview) 'profile provenance is not mandatory.'
Assert-C19 ($contract.profileProvenance.permanentRegression -ceq 'REG-20260806-006-PROFILE-RUNTIME-MARKER-SUPPRESSED') 'permanent regression lineage changed.'
Assert-C19 ($acceptance.status -ceq 'Accepted') 'v3 production acceptance is not Accepted.'
Assert-C19 ($acceptance.screen.referenceVersion -ceq 'v3') 'v3 acceptance version changed.'
Assert-C19 ([bool]$acceptance.lineage.v1AndV2FilesPreserved) 'v1/v2 preservation is false.'
Assert-C19 ([int]$acceptance.lineage.unchangedOwnerCount -eq 11) 'unchanged owner count changed.'
Assert-C19 ([int]$acceptance.lineage.changedOwnerCount -eq 1) 'changed owner count changed.'
Assert-C19 ($acceptance.lineage.changedOwner -ceq 'apps/mobile/test/platform_configuration_test.dart') 'changed owner is not the mandatory platform test.'
Assert-C19 (-not [bool]$acceptance.presentationEquivalence.runtimeSourceChanged) 'runtime source change was claimed.'
Assert-C19 (-not [bool]$acceptance.presentationEquivalence.goldenImagesChanged) 'golden change was claimed.'
Assert-C19 (-not [bool]$acceptance.presentationEquivalence.htmlCopied) 'HTML copy was claimed.'

$v2Acceptance = Get-Content -Raw -LiteralPath (Resolve-C19RepoFile 'approved-references/screens/03-login-account-handoff/v2/production-acceptance.json' 'v2 production acceptance') | ConvertFrom-Json
$expectedLocks = [ordered]@{
  'apps/mobile/lib/ui_v2/screens/screen03_login/screen03_frame_v2.dart' = '352c126b7ce8d65c6f3363c200f36559f61841693adda61e6ed81960adadfe95'
  'apps/mobile/lib/ui_v2/screens/screen03_login/login_screen_v2.dart' = '9f8f8a72aced405332920bc8f46b71b9907a14f6b440ad851abfd2a96bfcd28b'
  'apps/mobile/lib/ui_v2/screens/screen03_login/otp_screen_v2.dart' = '1913d3c1ee387a509d5035f3f894a850b653adcd979f00a0379b2a6fd96fe8e5'
  'apps/mobile/assets/prototype/provider-youtube.svg' = '34ded30aeb15e83c96015c925d472eacdbf2478c68cbaefe4b51c5b8a84a925a'
  'apps/mobile/test/ui_v2_screen03_login_test.dart' = 'a36a4fd2b6bdba9f0da4262eb360bb7885fb9e7270bec37cc50d5b75181a6c5a'
  'apps/mobile/test/ui_v2_screen03_golden_test.dart' = '26e70e444f455fc95def13d8b32eea91cf6d139981407096adea7128e6ec76cb'
  'apps/mobile/test/ui_v2_customer_copy_machine_gate_test.dart' = 'b07468f487a5c04286f0d228cdccf7ead373154c756600c58dc216a4edd2bd11'
  'apps/mobile/test/ui_v2_screen01_03_fitment_matrix_test.dart' = '8cce94ba9e7e508a2b449e8d73ce3eb60558ab3197951f862134ebc0b35e85f2'
  'apps/mobile/test/platform_configuration_test.dart' = 'deffe5cfd7cd7c1432d6057e5c045a1569dc3f71fbd5f9d8ef26251e984a68ca'
  'apps/mobile/test/goldens/ui_v2_screen03_login-360x720.png' = '4f0361824b6ce41905004e1bc4f13d213ce1eb78abf61dfc9ffcec3afd98e287'
  'apps/mobile/test/goldens/ui_v2_screen03_mobile-otp-360x720.png' = '714129642847519910a621124c5bcd8ae8c22ba1e894c0bf69517422b097e8d5'
  'apps/mobile/test/goldens/ui_v2_screen03_email-otp-360x720.png' = '66c34ad4646b24a7e74ff569f387e7c46bf66a053eb49da4775a45562690f43d'
}
$actualLocks = @($acceptance.lockedFiles)
Assert-C19 ($actualLocks.Count -eq $expectedLocks.Count) 'v3 locked-file count changed.'
foreach ($pair in $expectedLocks.GetEnumerator()) {
  $lock = @($actualLocks | Where-Object { $_.path -ceq $pair.Key })
  Assert-C19 ($lock.Count -eq 1) "v3 lock missing or duplicated: $($pair.Key)"
  Assert-C19 (([string]$lock[0].sha256).ToLowerInvariant() -ceq $pair.Value) "v3 recorded hash changed: $($pair.Key)"
  Assert-C19 ((Get-C19Sha256 $pair.Key) -ceq $pair.Value) "v3 production owner changed: $($pair.Key)"

  $v2Lock = @($v2Acceptance.lockedFiles | Where-Object { $_.path -ceq $pair.Key })
  Assert-C19 ($v2Lock.Count -eq 1) "v2 lineage lock missing or duplicated: $($pair.Key)"
  if ($pair.Key -ceq 'apps/mobile/test/platform_configuration_test.dart') {
    Assert-C19 (([string]$v2Lock[0].sha256).ToLowerInvariant() -ceq '490721029d88301e42dc593526618b4f94198ab586c1e55d709cae12776123bc') 'v2 platform-test lineage changed.'
  } else {
    Assert-C19 (([string]$v2Lock[0].sha256).ToLowerInvariant() -ceq $pair.Value) "non-platform owner differs from v2: $($pair.Key)"
  }
}

$ticket = Get-Content -Raw -LiteralPath (Resolve-C19RepoFile 'config/uaw-personal-mvp-screen03-profile-provenance-test-lock-reconciliation-fix1-c19-ticket.json' 'C19 ticket') | ConvertFrom-Json
Assert-C19 ([bool]$ticket.execution.referenceWriteAuthorized) 'C19 reference authorization is false.'
Assert-C19 (-not [bool]$ticket.execution.runtimeSourceWriteAuthorized) 'C19 runtime-source authorization expanded.'
Assert-C19 (-not [bool]$ticket.execution.buildAuthorized) 'C19 build authorization opened.'
Assert-C19 (-not [bool]$ticket.execution.installAuthorized) 'C19 install authorization opened.'

$scope = Get-Content -Raw -LiteralPath (Resolve-C19RepoFile 'config/mvp-scope-gate-state.json' 'MVP scope state') | ConvertFrom-Json
$allowedActiveTickets = @(
  [string]$ticket.ticketId,
  'UAW-PERSONAL-MVP-C17-HOST-QUALIFICATION-REFRESH-AFTER-SCREEN01-LOCK-FIX1-C18D'
)
Assert-C19 ($allowedActiveTickets -ccontains [string]$scope.ticket.id) 'Neither C19 nor its exact C18D successor qualification is the active MVP ticket.'
Assert-C19 ([bool]$scope.execution.referenceWriteAuthorized) 'MVP reference authorization is false.'
Assert-C19 (-not [bool]$scope.execution.runtimeWriteAuthorized) 'MVP runtime authorization expanded.'
Assert-C19 (-not [bool]$scope.execution.buildAuthorized) 'MVP build authorization opened.'
Assert-C19 (-not [bool]$scope.execution.deviceInstallAuthorized) 'MVP install authorization opened.'

Write-Output 'Screen03 v3 production acceptance C19 gate passed: versions=3; active=v3; lockedFiles=12; unchangedFromV2=11; mandatoryPlatformTestDelta=1; htmlCopied=false; buildInstall=false.'
