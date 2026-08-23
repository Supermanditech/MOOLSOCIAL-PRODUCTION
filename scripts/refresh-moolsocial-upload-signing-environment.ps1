[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function ConvertFrom-MoolSocialSecureString {
  param(
    [Parameter(Mandatory)]
    [Security.SecureString]$Value
  )
  $pointer = [IntPtr]::Zero
  try {
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  } finally {
    if ($pointer -ne [IntPtr]::Zero) {
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
  }
}

$storeSecure = $null
$keySecure = $null
$storeText = $null
$keyText = $null
$helperPath = $null
try {
  $keystorePath = Join-Path $env:USERPROFILE (
    'Documents\MoolSocial-Signing\moolsocial-upload.jks'
  )
  $javaPath = Join-Path $env:JAVA_HOME 'bin\java.exe'
  if (
    -not (Test-Path -LiteralPath $keystorePath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $javaPath -PathType Leaf)
  ) {
    throw 'SIGNING_VALIDATOR_PREREQUISITE_MISSING'
  }

  $env:MOOLSOCIAL_UPLOAD_STORE_PASSWORD = $null
  $env:MOOLSOCIAL_UPLOAD_KEY_PASSWORD = $null
  $storeSecure = Read-Host 'Upload keystore password' -AsSecureString
  $keySecure = Read-Host 'Upload key password' -AsSecureString
  $storeText = ConvertFrom-MoolSocialSecureString $storeSecure
  $keyText = ConvertFrom-MoolSocialSecureString $keySecure
  if (
    [string]::IsNullOrWhiteSpace($storeText) -or
    [string]::IsNullOrWhiteSpace($keyText)
  ) {
    throw 'SIGNING_PASSWORD_EMPTY'
  }

  $helperPath = Join-Path ([IO.Path]::GetTempPath()) (
    'MoolSocialKeyValidation-' + [Guid]::NewGuid().ToString('N') + '.java'
  )
  $javaSource = @'
import java.io.File;
import java.security.Key;
import java.security.KeyStore;

class MoolSocialKeyValidation {
  public static void main(String[] args) throws Exception {
    String storePassword = System.getenv("MOOLSOCIAL_VALIDATION_STORE_PASSWORD");
    String keyPassword = System.getenv("MOOLSOCIAL_VALIDATION_KEY_PASSWORD");
    if (storePassword == null || keyPassword == null || args.length != 2) {
      System.exit(2);
    }
    KeyStore keyStore = KeyStore.getInstance(
      new File(args[0]),
      storePassword.toCharArray()
    );
    Key key = keyStore.getKey(args[1], keyPassword.toCharArray());
    if (key == null) {
      System.exit(3);
    }
    System.out.print("MOOLSOCIAL_KEY_VALID");
  }
}
'@
  [IO.File]::WriteAllText(
    $helperPath,
    $javaSource,
    [Text.UTF8Encoding]::new($false)
  )
  $env:MOOLSOCIAL_VALIDATION_STORE_PASSWORD = $storeText
  $env:MOOLSOCIAL_VALIDATION_KEY_PASSWORD = $keyText
  $validation = & $javaPath $helperPath $keystorePath 'moolsocial-upload' `
    2>$null
  if (
    $LASTEXITCODE -ne 0 -or
    ($validation -join '') -cne 'MOOLSOCIAL_KEY_VALID'
  ) {
    throw 'SIGNING_PASSWORD_VALIDATION_FAILED'
  }

  $env:MOOLSOCIAL_UPLOAD_STORE_FILE = $keystorePath
  $env:MOOLSOCIAL_UPLOAD_KEY_ALIAS = 'moolsocial-upload'
  $env:MOOLSOCIAL_UPLOAD_STORE_PASSWORD = $storeText
  $env:MOOLSOCIAL_UPLOAD_KEY_PASSWORD = $keyText
  Clear-Host
  Write-Host 'UPLOAD_SIGNING_ENV_VALIDATED' -ForegroundColor Green
  Write-Host 'Keep this PowerShell window open.'
} catch {
  $env:MOOLSOCIAL_UPLOAD_STORE_PASSWORD = $null
  $env:MOOLSOCIAL_UPLOAD_KEY_PASSWORD = $null
  Clear-Host
  Write-Host 'UPLOAD_SIGNING_ENV_VALIDATION_FAILED' -ForegroundColor Red
} finally {
  $env:MOOLSOCIAL_VALIDATION_STORE_PASSWORD = $null
  $env:MOOLSOCIAL_VALIDATION_KEY_PASSWORD = $null
  if ($helperPath -and (Test-Path -LiteralPath $helperPath)) {
    Remove-Item -LiteralPath $helperPath -Force -ErrorAction SilentlyContinue
  }
  Remove-Variable storeSecure, keySecure, storeText, keyText, validation,
    javaSource, helperPath, keystorePath, javaPath -ErrorAction SilentlyContinue
}

