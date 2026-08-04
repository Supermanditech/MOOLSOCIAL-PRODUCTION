[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$legacy = Get-Command powershell.exe -ErrorAction Stop

$forbiddenTokens = @(
  ('[System.IO.Path]::' + 'GetRelativePath'),
  ('[IO.Path]::' + 'GetRelativePath'),
  ('[Convert]::' + 'ToHexString'),
  ('[System.Convert]::' + 'ToHexString')
)
$violations = [System.Collections.Generic.List[string]]::new()
foreach ($file in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1' -File) {
  if ($file.FullName -eq $PSCommandPath) {
    continue
  }
  $source = Get-Content -LiteralPath $file.FullName -Raw
  foreach ($token in $forbiddenTokens) {
    if ($source.Contains($token)) {
      $violations.Add("$($file.Name): unsupported Windows PowerShell API $token")
    }
  }
}
if ($violations.Count -gt 0) {
  throw "Windows PowerShell compatibility static gate failed: $($violations -join '; ')"
}

function Invoke-LegacyGate {
  param(
    [Parameter(Mandatory)]
    [string]$Label,
    [Parameter(Mandatory)]
    [string]$Script,
    [string[]]$Arguments = @(),
    [string]$AllowedBusinessFailure = ""
  )

  $scriptPath = Join-Path $RepositoryRoot $Script
  # Windows PowerShell 5.1 promotes native stderr merged through 2>&1 to a
  # NativeCommandError record. These protected gates intentionally use stderr
  # for their expected fail-closed rejection. Capture that record without
  # allowing the host's Stop preference to terminate before classification.
  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $output = & $legacy.Source `
      -NoLogo `
      -NoProfile `
      -NonInteractive `
      -ExecutionPolicy Bypass `
      -File $scriptPath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  $text = ($output | Out-String)
  if ($text -match 'does not contain a method named|is not recognized as the name of a cmdlet|ParserError') {
    throw "$Label hit a Windows PowerShell compatibility failure: $text"
  }
  if ($exitCode -eq 0) {
    Write-Output "${Label}: compatible and passed."
    return
  }
  if (-not [string]::IsNullOrWhiteSpace($AllowedBusinessFailure) -and
      $text -match $AllowedBusinessFailure) {
    Write-Output "${Label}: compatible; expected business/protected rejection reached."
    return
  }
  throw "$Label failed under Windows PowerShell 5.1: $text"
}

Invoke-LegacyGate `
  -Label 'backend boundary' `
  -Script 'scripts\check-buy-backend-contract-boundary.ps1'
Invoke-LegacyGate `
  -Label 'backend boundary self-test' `
  -Script 'scripts\check-buy-backend-contract-boundary.ps1' `
  -Arguments @('-SelfTest')
Invoke-LegacyGate `
  -Label 'data-egress boundary' `
  -Script 'scripts\check-buy-data-egress-boundary.ps1'
Invoke-LegacyGate `
  -Label 'data-egress boundary self-test' `
  -Script 'scripts\check-buy-data-egress-boundary.ps1' `
  -Arguments @('-SelfTest')
Invoke-LegacyGate `
  -Label 'approved UI locks' `
  -Script 'scripts\check-approved-ui-locks.ps1' `
  -AllowedBusinessFailure 'Approved UI lock changed'
Invoke-LegacyGate `
  -Label 'protected Social baseline' `
  -Script 'scripts\check-social-protected-baseline.ps1' `
  -AllowedBusinessFailure 'Protected Social (inventory|tree) changed'
Invoke-LegacyGate `
  -Label 'protected Buy baseline' `
  -Script 'scripts\check-buy-protected-baseline.ps1' `
  -AllowedBusinessFailure 'Protected Buy (inventory|runtime tree) changed'

Write-Output (
  'Windows PowerShell 5.1 compatibility gate passed: no banned modern .NET ' +
  'path/hash APIs and all mandatory boundary/protected scripts reached their ' +
  'intended outcome.'
)

# The last protected baseline probe is expected to return non-zero. Do not
# leak that handled business rejection through $LASTEXITCODE to the invoking
# host after the compatibility gate itself has passed.
$global:LASTEXITCODE = 0
