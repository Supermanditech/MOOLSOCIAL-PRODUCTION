[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$mobile = Join-Path $root 'apps\mobile'
$evidence = Join-Path $root 'docs\quality\store-buy-diagnostic-evidence-v2-20260904'
$stdoutPath = Join-Path $evidence 'serialized-repair-expanded-attempt1.stdout.log'
$stderrPath = Join-Path $evidence 'serialized-repair-expanded-attempt1.stderr.log'
$resultPath = Join-Path $evidence 'serialized-repair-expanded-attempt1.result.json'
$toolchainPath = Join-Path $evidence 'toolchain-and-dependency-hashes.json'

foreach ($path in @($mobile, $evidence)) {
  if (-not (Test-Path -LiteralPath $path -PathType Container)) {
    throw "Required diagnostic directory is missing: $path"
  }
}

$testFiles = @(
  'test/work_store_atomic_operations_test.dart',
  'test/work_workspace_layout_safety_test.dart',
  'test/work_vertical_slice_test.dart',
  'test/work_production_gateway_test.dart',
  'test/ui_v2/work/work_main_v2_test.dart',
  'test/ui_v2/work/work_opportunity_home_c24g_test.dart',
  'test/ui_v2/universal/mool_care_work_navigation_conformance_c26f_test.dart',
  'test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart',
  'test/ui_v2/universal/uaw_personal_social_work_route_compatibility_test.dart',
  'test/ui_v2/universal/uaw_r10_personal_work_exposure_test.dart'
)
foreach ($testFile in $testFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $mobile $testFile) -PathType Leaf)) {
    throw "Required diagnostic test is missing: $testFile"
  }
}

function Invoke-CapturedProcess(
  [string]$FileName,
  [string[]]$Arguments,
  [string]$WorkingDirectory
) {
  $info = [Diagnostics.ProcessStartInfo]::new()
  $info.FileName = $FileName
  $info.WorkingDirectory = $WorkingDirectory
  $info.UseShellExecute = $false
  $info.RedirectStandardOutput = $true
  $info.RedirectStandardError = $true
  foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $info
  [void]$process.Start()
  $stdoutTask = $process.StandardOutput.ReadToEndAsync()
  $stderrTask = $process.StandardError.ReadToEndAsync()
  $process.WaitForExit()
  $stdout = $stdoutTask.GetAwaiter().GetResult()
  $stderr = $stderrTask.GetAwaiter().GetResult()
  return [pscustomobject]@{
    ExitCode = $process.ExitCode
    Stdout = $stdout
    Stderr = $stderr
  }
}

$flutterVersion = Invoke-CapturedProcess 'flutter' @('--version', '--machine') $mobile
if ($flutterVersion.ExitCode -ne 0) { throw 'Flutter version read failed.' }
$dartVersion = Invoke-CapturedProcess 'dart' @('--version') $mobile
if ($dartVersion.ExitCode -ne 0) { throw 'Dart version read failed.' }

$dependencyOwners = @(
  'apps/mobile/pubspec.yaml',
  'apps/mobile/pubspec.lock',
  'apps/mobile/.dart_tool/package_config.json',
  'apps/mobile/.dart_tool/package_graph.json',
  'apps/mobile/.flutter-plugins-dependencies'
)
$dependencyHashes = @()
foreach ($owner in $dependencyOwners) {
  $path = Join-Path $root $owner
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Dependency owner is missing: $owner"
  }
  $dependencyHashes += [ordered]@{
    owner = $owner
    bytes = (Get-Item -LiteralPath $path).Length
    sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  }
}
$toolchain = [ordered]@{
  schema = 'moolsocial_store_buy_diagnostic_toolchain_v2'
  failedRepair = 'c48e4ecc5c3ccc7a3079d3f64988437599cc78de'
  flutter = ($flutterVersion.Stdout.Trim() | ConvertFrom-Json)
  dart = $dartVersion.Stderr.Trim()
  dependencyHashes = $dependencyHashes
}
[IO.File]::WriteAllText(
  $toolchainPath,
  ($toolchain | ConvertTo-Json -Depth 20) + "`n",
  [Text.UTF8Encoding]::new($false)
)

$arguments = @('test', '--no-pub', '--reporter', 'expanded', '--concurrency=1') +
  $testFiles
$startedAt = [DateTimeOffset]::Now
$testRun = Invoke-CapturedProcess 'flutter' $arguments $mobile
$finishedAt = [DateTimeOffset]::Now
[IO.File]::WriteAllText(
  $stdoutPath,
  $testRun.Stdout,
  [Text.UTF8Encoding]::new($false)
)
[IO.File]::WriteAllText(
  $stderrPath,
  $testRun.Stderr,
  [Text.UTF8Encoding]::new($false)
)
$result = [ordered]@{
  schema = 'moolsocial_store_buy_serialized_diagnostic_v2'
  failedRepair = 'c48e4ecc5c3ccc7a3079d3f64988437599cc78de'
  command = @('flutter') + $arguments
  testFiles = $testFiles
  startedAt = $startedAt.ToString('o')
  finishedAt = $finishedAt.ToString('o')
  exitCode = $testRun.ExitCode
  stdoutBytes = [Text.Encoding]::UTF8.GetByteCount($testRun.Stdout)
  stderrBytes = [Text.Encoding]::UTF8.GetByteCount($testRun.Stderr)
  stdoutSha256 = (Get-FileHash -LiteralPath $stdoutPath -Algorithm SHA256).Hash
  stderrSha256 = (Get-FileHash -LiteralPath $stderrPath -Algorithm SHA256).Hash
}
[IO.File]::WriteAllText(
  $resultPath,
  ($result | ConvertTo-Json -Depth 20) + "`n",
  [Text.UTF8Encoding]::new($false)
)

Write-Output "diagnosticExit=$($testRun.ExitCode)"
Write-Output "stdoutBytes=$($result.stdoutBytes)"
Write-Output "stdoutSha256=$($result.stdoutSha256)"
Write-Output "stderrBytes=$($result.stderrBytes)"
Write-Output "stderrSha256=$($result.stderrSha256)"
exit $testRun.ExitCode
