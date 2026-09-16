[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$candidateRoot = Join-Path $root 'apps/mobile/build/cursor-review-r66.22'
$receipt = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'apk-identity.json') | ConvertFrom-Json
$installLog = Join-Path $PSScriptRoot 'redmi-install-01.log'
if (-not (Test-Path -LiteralPath $installLog) -or (Get-Content -Raw -LiteralPath $installLog) -notmatch '(?m)^Success\s*$') { throw 'Successful install receipt missing' }
function Read-Redmi([string[]]$Arguments) {
  $lines = @(& adb -s TG8HCYTGGQT885OF @Arguments)
  if ($LASTEXITCODE -ne 0) { throw "Redmi readback failed: $($Arguments[0])" }
  return $lines
}
$paths = @(Read-Redmi @('shell','pm','path','com.moolsocial.app.cursorreview'))
if ($paths.Count -ne 1 -or $paths[0] -notmatch '^package:(/data/app/[^\s]+/base\.apk)$') { throw 'Unexpected installed package path set' }
$baseApk = $Matches[1]
$remoteHash = (@(Read-Redmi @('shell','sha256sum',$baseApk))[0] -split '\s+')[0].ToUpperInvariant()
if ($remoteHash -cne $receipt.apkSha256) { throw 'Installed APK checksum differs from qualified artifact' }
$packageLines = @(Read-Redmi @('shell','dumpsys','package','com.moolsocial.app.cursorreview'))
$packageText = $packageLines -join "`n"
if ($packageText -notmatch 'versionCode=2026091403\b' -or $packageText -notmatch 'versionName=1\.0\.0-r66\.22-cursorreview\b') { throw 'Installed package version mismatch' }
if ($packageText -notmatch 'firstInstallTime=2026-08-27 15:09:48') { throw 'Original package first-install timestamp not retained' }
$identityLines = @($packageLines | Where-Object { $_ -match 'versionCode=|versionName=|firstInstallTime=|lastUpdateTime=' })
$destination = Join-Path $PSScriptRoot 'delivery'
if (Test-Path -LiteralPath $destination) { throw 'Delivery archive already exists' }
New-Item -ItemType Directory -Path $destination | Out-Null
$statePath = Join-Path $candidateRoot 'machine-state.json'
$archiveFiles = @(
  [string]$receipt.apk,
  (Join-Path $candidateRoot 'artifacts/uaw-cursor-redmi-rv6-language-20260914-build-provenance.txt'),
  (Join-Path $candidateRoot 'source-manifest.txt'),
  (Join-Path $candidateRoot 'evidence-copy-receipt.json'),
  (Join-Path $candidateRoot 'built-machine-state.json'),
  (Join-Path $PSScriptRoot 'apk-identity.json'),
  (Join-Path $PSScriptRoot 'apk-signer.log'),
  $installLog
)
$copies = @()
foreach ($file in $archiveFiles) {
  $target = Join-Path $destination ([IO.Path]::GetFileName($file))
  Copy-Item -LiteralPath $file -Destination $target
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash
  if ((Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash -cne $hash) { throw 'Archive checksum differs' }
  $copies += [ordered]@{file=[IO.Path]::GetFileName($target);sha256=$hash;bytes=(Get-Item -LiteralPath $target).Length}
}
$originalStateArchive = Join-Path $destination 'prebuild-machine-state.json'
$originalStatePath = Join-Path $candidateRoot 'prebuild-machine-state.json'
Copy-Item -LiteralPath $originalStatePath -Destination $originalStateArchive
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $originalStatePath).Hash -cne (Get-FileHash -Algorithm SHA256 -LiteralPath $originalStateArchive).Hash) { throw 'Prebuild state archive differs' }
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
if ($state.buildAuthorization -cne 'consumed_one_build' -or $state.machineState -cne 'built_install_pending') { throw 'Build consumption receipt missing' }
$state.machineState = 'installed_remaining_device_qualification_pending'
$state.buildAuthorization = 'consumed_one_build'
foreach ($gate in $state.postBuildGates) {
  if ($gate.id -cin @('artifact-package-version-signer-checksum','installed-apk-checksum-equality','redmi-data-preserving-upgrade')) { $gate.state='passed' }
}
[IO.File]::WriteAllText($statePath, ($state | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath $statePath -Destination (Join-Path $destination 'installed-machine-state.json')
$installation = [ordered]@{
  device='TG8HCYTGGQT885OF'; sourceHead=$receipt.sourceHead; packageId=$receipt.packageId;
  versionName=$receipt.versionName; versionCode=$receipt.versionCode; apkSha256=$receipt.apkSha256;
  installedApkSha256=$remoteHash; signerSha256=$receipt.signerSha256; command='adb -s TG8HCYTGGQT885OF install -r <verified successor APK>';
  result='Success'; dataClearPerformed=$false; uninstallPerformed=$false; originalFirstInstallTimestampRetained=$true;
  userDataLimit='Data-preserving package upgrade and retained original installation identity; no full persisted-field audit claimed.';
  packageReadback=$identityLines; childDeviceVerification='not_performed_requires_subsequent_instruction';
  originalsClosed=18; originalsOpen=@('RV6-D005','RV6-D009','RV6-D010','RV6-D014'); childOpen='RV6-D005-C01';
  linkDeliveryBlocker='Prior automatic approval rejection retained; no bypass attempted'; productionReady=$false;
  createdAt=[DateTimeOffset]::Now.ToString('o'); archivedFiles=$copies
}
[IO.File]::WriteAllText((Join-Path $destination 'installation-receipt.json'), ($installation | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
Write-Output "Installed artifact equality verified: $remoteHash; original first-install timestamp retained; delivery=$destination"
