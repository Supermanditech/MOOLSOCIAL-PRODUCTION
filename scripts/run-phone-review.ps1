param(
  [string]$EmulatorHost = "127.0.0.1",
  [switch]$KeepAppState
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$adb = "C:\Users\jisal\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$apk = Join-Path $root "apps\mobile\build\app\outputs\flutter-apk\app-debug.apk"
$packageName = "com.moolsocial.app"
$projectId = "demo-moolsocial-local"

if (-not (Test-Path -LiteralPath $adb)) {
  throw "ADB was not found at $adb"
}
if (-not (Test-Path -LiteralPath $apk)) {
  throw "Review APK was not found. Build it before running this script."
}

$deviceLines = & $adb devices
$serial = $deviceLines |
  Select-String "\tdevice$" |
  ForEach-Object { ($_ -split "\s+")[0] } |
  Select-Object -First 1

if (-not $serial) {
  throw @"
No authorized Android device is visible to ADB.
Unlock the phone, enable USB debugging, choose File transfer, and accept the
Allow USB debugging prompt for this computer.
"@
}

foreach ($port in 9099, 9399) {
  $listener = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
  if (-not $listener) {
    throw "The required local emulator is not listening on port $port."
  }
  if ($EmulatorHost -in @("127.0.0.1", "localhost")) {
    & $adb -s $serial reverse "tcp:$port" "tcp:$port" | Out-Null
  }
}

if (-not $KeepAppState) {
  Invoke-RestMethod `
    -Method Delete `
    -Uri "http://127.0.0.1:9099/emulator/v1/projects/$projectId/accounts" |
    Out-Null
}

if (-not $KeepAppState) {
  $uninstallOutput = (& $adb -s $serial uninstall $packageName) -join "`n"
  $uninstallExitCode = $LASTEXITCODE
  $remainingPackagePath = (
    (& $adb -s $serial shell pm path $packageName 2>$null) -join ""
  ).Trim()
  if ($remainingPackagePath) {
    throw "Existing review app could not be removed cleanly: $uninstallOutput"
  }
  if ($uninstallExitCode -ne 0 -or $uninstallOutput -notmatch "Success") {
    Write-Warning (
      "Android did not return a successful uninstall response, but package " +
      "$packageName is absent. Continuing from the verified clean state."
    )
  }
}

& $adb -s $serial install -r $apk
if ($LASTEXITCODE -ne 0) {
  throw "APK installation failed."
}

if (-not $KeepAppState) {
  # Some OPPO builds deny `pm clear` to the shell user. The review artifact is
  # debuggable, so clear only this package's private review data through
  # `run-as` and verify that no state-bearing directory remains.
  & $adb -s $serial shell run-as $packageName rm -rf `
    shared_prefs databases files no_backup app_flutter cache code_cache
  if ($LASTEXITCODE -ne 0) {
    throw "Installed review app data could not be cleared through run-as."
  }
  $remainingState = (
    (& $adb -s $serial shell run-as $packageName ls 2>$null) -join " "
  )
  if ($remainingState -match "\b(shared_prefs|databases|files|no_backup|app_flutter)\b") {
    throw "Installed review app retained state after cleanup: $remainingState"
  }
}

& $adb -s $serial shell am start -n "$packageName/.MainActivity" | Out-Null

$manufacturer = (& $adb -s $serial shell getprop ro.product.manufacturer).Trim()
$model = (& $adb -s $serial shell getprop ro.product.model).Trim()
$version = (& $adb -s $serial shell getprop ro.build.version.release).Trim()

Write-Output "MoolSocial review build opened successfully."
Write-Output "Device: $manufacturer $model / Android $version / $serial"
Write-Output "Package: $packageName"
Write-Output (
  $(if ($KeepAppState) {
      "Review preferences: preserved by request"
    } else {
      "Review preferences: package-private data cleared after install"
    })
)
Write-Output "Local Auth emulator: ${EmulatorHost}:9099"
Write-Output "Local Data Connect emulator: ${EmulatorHost}:9399"
Write-Output (
  "Account bootstrap mode is fixed when the APK is built; use " +
  "MOOLSOCIAL_DEVICE_REVIEW=true only for isolated physical-device review."
)
