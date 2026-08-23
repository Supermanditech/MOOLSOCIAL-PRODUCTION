[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$recoveryPath = Join-Path $root 'scripts/recover-play-internal-aab-postbuild-c30s.ps1'
if (-not (Test-Path -LiteralPath $recoveryPath -PathType Leaf)) { throw 'C30S post-build recovery gate rejected: recovery verifier is missing.' }
$script = Get-Content -Raw -LiteralPath $recoveryPath
foreach ($required in @('$expectedArtifactSha256', '2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55', 'source-aggregate-manifest-accepted-r7.txt', 'attempt-3', '-printcert', 'dump manifest', 'string/google_app_id', 'string/com.google.firebase.crashlytics.mapping_file_id', '[0-9a-f]{32}', '\[STR\]\s+"[^"]+"', 'base/lib/arm64-v8a/libapp.so', 'releaseManifestMergerBlame', 'secondBuildPerformed = $false', '-Phase postbuild')) {
  if (-not $script.Contains($required, [StringComparison]::Ordinal)) { throw "C30S post-build recovery gate rejected: missing $required" }
}
foreach ($forbidden in @('Invoke-Flutter', 'Invoke-Gradle', 'flutter build', 'gradlew', "'appbundle'", "'apk'", 'Copy-Item -LiteralPath $generatedPath', 'MOOLSOCIAL_UPLOAD_STORE_PASSWORD', 'Read-Host')) {
  if ($script.Contains($forbidden, [StringComparison]::OrdinalIgnoreCase)) { throw "C30S post-build recovery gate rejected: build or secret-input capability present: $forbidden" }
}
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($recoveryPath, [ref]$tokens, [ref]$errors)
if (@($errors).Count -ne 0) { throw 'C30S post-build recovery gate rejected: recovery verifier does not parse.' }
$commands = $ast.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] }, $true)
foreach ($command in $commands) {
  $parameters = @($command.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] } | ForEach-Object { $_.ParameterName })
  $duplicates = @($parameters | Group-Object | Where-Object { $_.Count -gt 1 })
  if ($duplicates.Count -gt 0) { throw "C30S post-build recovery gate rejected: duplicated parameters in $($command.Extent.Text)" }
}
Write-Output 'C30S build-forbidden existing-AAB post-build recovery gate passed.'
