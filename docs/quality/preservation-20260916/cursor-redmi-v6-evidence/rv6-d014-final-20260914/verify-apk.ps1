[CmdletBinding()]
param([Parameter(Mandatory)][string]$ExpectedSourceHead)
$ErrorActionPreference = 'Stop'
$root = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$candidate = 'UAW-CURSOR-REDMI-RV6-D014-20260914'
$folder = Join-Path $root 'apps/mobile/build/cursor-review-r66.23'
$apk = Join-Path $folder 'artifacts/uaw-cursor-redmi-rv6-d014-20260914-device-review-debug.apk'
$provenance = Join-Path $folder 'artifacts/uaw-cursor-redmi-rv6-d014-20260914-build-provenance.txt'
$sdk = 'C:/Users/jisal/AppData/Local/Android/Sdk'
$analyzer = Join-Path $sdk 'cmdline-tools/latest/bin/apkanalyzer.bat'
$signer = Join-Path $sdk 'build-tools/36.0.0/apksigner.bat'
$expectedSigner = 'CBDFC5969AD51ED570AFB1CF2FE60377E559D43F59D59E2AB66CCAF78EA9AC25'
function Invoke-ApkTool([string]$Tool, [string[]]$Arguments) {
  $lines = @(& $Tool @Arguments 2>&1 | ForEach-Object { $_.ToString() })
  if ($LASTEXITCODE -ne 0) { throw "APK identity tool failed: $Tool; $($lines -join ' ')" }
  return $lines
}
$metadataOutput = [Collections.Generic.List[string]]::new()
function Read-ApkScalar([string]$Field, [string]$Pattern) {
  $lines = @(Invoke-ApkTool $analyzer @('manifest',$Field,$apk))
  $metadataOutput.Add("Field=$Field")
  foreach($line in $lines){$metadataOutput.Add($line)}
  $values = @($lines | ForEach-Object {$_.Trim()} | Where-Object {$_ -cmatch $Pattern})
  if($values.Count -ne 1){throw "Expected exactly one typed APK value for $Field"}
  return $values[0]
}
# SDK batch launchers echo command scaffolding in this environment. Require one
# actual typed output line, then compare its exact value below; preserve raw text.
$id = Read-ApkScalar 'application-id' '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'
$name = Read-ApkScalar 'version-name' '^\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?$'
$code = Read-ApkScalar 'version-code' '^\d+$'
$metadataPath=Join-Path $PSScriptRoot 'apk-metadata-verified.log'
if(Test-Path -LiteralPath $metadataPath){throw 'Refusing to overwrite metadata readback'}
[IO.File]::WriteAllLines($metadataPath,$metadataOutput,[Text.UTF8Encoding]::new($false))
if ($id -cne 'com.moolsocial.app.cursorreview' -or $name -cne '1.0.0-r66.23-cursorreview' -or $code -cne '2026091404') { throw 'Package/version differs from authorized candidate' }
$signature = @(Invoke-ApkTool $signer @('verify','--print-certs',$apk))
$digestLine = @($signature | Where-Object { $_ -match '^Signer #1 certificate SHA-256 digest:' })
if ($digestLine.Count -ne 1) { throw 'Expected exactly one primary signer digest' }
$digest = ($digestLine[0] -split ': ',2)[1].Trim().ToUpperInvariant()
if ($digest -cne $expectedSigner) { throw 'Signer differs from preserved installed review signer' }
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $apk).Hash
$sourceManifest = Join-Path $folder 'source-manifest.txt'
$sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceManifest).Hash
$meta = @{}
foreach ($line in Get-Content -LiteralPath $provenance) { $parts = $line.Split('=',2); if($parts.Count -eq 2){$meta[$parts[0]]=$parts[1]} }
if ($meta.HEAD -cne $ExpectedSourceHead -or $meta.CandidateId -cne $candidate -or $meta.SHA256 -cne $hash -or $meta.SourceFingerprint -cne $sourceHash -or $meta.RuntimeProfile -cne 'CursorUiReview' -or $meta.BuildMode -cne 'debug') { throw 'Build provenance mismatch' }
$receipt = [ordered]@{
  candidate=$candidate; sourceHead=$ExpectedSourceHead; applicationSource='4221158fead95a89047e3408aaeb11c9a12dd135';
  apk=$apk; packageId=$id; versionName=$name; versionCode=[int64]$code; signerSha256=$digest;
  apkSha256=$hash; bytes=(Get-Item -LiteralPath $apk).Length; sourceManifestSha256=$sourceHash;
  runtimeProfile='CursorUiReview'; buildMode='debug'; promotable=$false;
  permittedDevice='TG8HCYTGGQT885OF'; installation='not_yet_performed'; deviceVerification='D014_pending_under_active_founder_goal'
}
$receiptPath=Join-Path $PSScriptRoot 'apk-identity.json'
if(Test-Path -LiteralPath $receiptPath){throw 'Refusing to overwrite artifact receipt'}
[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'apk-signer.log'),$signature,[Text.UTF8Encoding]::new($false))
$receipt | ConvertTo-Json -Depth 5
