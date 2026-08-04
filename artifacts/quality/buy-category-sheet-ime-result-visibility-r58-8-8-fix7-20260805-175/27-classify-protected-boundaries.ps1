$ErrorActionPreference = 'Stop'
$outputRoot = $PSScriptRoot
$source = Join-Path $PSScriptRoot '..\buy-product-detail-compact-action-r59-1-fix7-20260804-137\37b-classify-protected-boundaries.ps1'
$expected = 'F955BFBE014D5E60A705017963534D49F8D769698871BC11D6ADCC062FF491F3'
if ((Get-FileHash $source -Algorithm SHA256).Hash -cne $expected) {
  throw 'Sealed protected-boundary classifier changed.'
}
$scriptText = (Get-Content -Raw -Encoding utf8 $source).
  Replace('$PSScriptRoot', '$outputRoot').
  Replace('36b-protected-boundary-raw-exit-codes.json', '26-protected-boundary-raw-exit-codes.json').
  Replace('33b-approved-ui-expected-rejection.log', '23-approved-ui-expected-rejection.log').
  Replace('34b-social-expected-rejection.log', '24-social-expected-rejection.log').
  Replace('35b-buy-expected-rejection.log', '25-buy-expected-rejection.log')
& ([scriptblock]::Create($scriptText))
