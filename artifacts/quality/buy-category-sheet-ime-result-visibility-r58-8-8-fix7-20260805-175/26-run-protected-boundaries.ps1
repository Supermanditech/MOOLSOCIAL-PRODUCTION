$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$gates = @(
  [pscustomobject]@{
    gate = 'approved-ui'
    script = Join-Path $repo 'scripts/check-approved-ui-locks.ps1'
    log = Join-Path $PSScriptRoot '23-approved-ui-expected-rejection.log'
  },
  [pscustomobject]@{
    gate = 'social'
    script = Join-Path $repo 'scripts/check-social-protected-baseline.ps1'
    log = Join-Path $PSScriptRoot '24-social-expected-rejection.log'
  },
  [pscustomobject]@{
    gate = 'buy'
    script = Join-Path $repo 'scripts/check-buy-protected-baseline.ps1'
    log = Join-Path $PSScriptRoot '25-buy-expected-rejection.log'
  }
)

$records = foreach ($gate in $gates) {
  $ErrorActionPreference = 'Continue'
  $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $gate.script 2>&1
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  Set-Content -LiteralPath $gate.log -Value $output -Encoding utf8
  [pscustomobject]@{ gate = $gate.gate; exitCode = $exitCode }
}
$records | ConvertTo-Json | Set-Content -LiteralPath (
  Join-Path $PSScriptRoot '26-protected-boundary-raw-exit-codes.json'
) -Encoding utf8
