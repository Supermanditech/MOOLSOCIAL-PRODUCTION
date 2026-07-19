$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root "apps\mobile"
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue

& (Join-Path $PSScriptRoot "check-user-facing-copy.ps1")
& (Join-Path $PSScriptRoot "check-interaction-contracts.ps1")

if ($flutterCommand) {
  $flutterExecutable = $flutterCommand.Source
} else {
  $flutterPath = "C:\Users\jisal\develop\flutter\bin\flutter.bat"
  if (-not (Test-Path -LiteralPath $flutterPath)) {
    throw "Flutter was not found."
  }
  $flutterExecutable = $flutterPath
}

if (Get-Command firebase -ErrorAction SilentlyContinue) {
  if (-not $env:JAVA_HOME -or -not (Test-Path -LiteralPath $env:JAVA_HOME)) {
    $androidStudioJava = "C:\Program Files\Android\Android Studio\jbr"
    if (Test-Path -LiteralPath $androidStudioJava) {
      $env:JAVA_HOME = $androidStudioJava
    }
  }
  Push-Location $root
  try {
    firebase dataconnect:sdk:generate --project demo-moolsocial-local
  } finally {
    Pop-Location
  }
}

Push-Location $mobile
try {
  & $flutterExecutable pub get
  & $flutterExecutable analyze --fatal-infos
  & $flutterExecutable test
} finally {
  Pop-Location
}

Write-Output "Local quality gate passed."
