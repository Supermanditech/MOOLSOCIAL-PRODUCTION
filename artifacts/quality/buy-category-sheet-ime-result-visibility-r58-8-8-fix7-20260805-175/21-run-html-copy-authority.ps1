$ErrorActionPreference = 'Stop'
$outputRoot = $PSScriptRoot
$source = Join-Path $PSScriptRoot '..\buy-product-detail-compact-action-r59-1-fix7-20260804-137\30-run-html-copy-authority.ps1'
$expected = 'EFB54B7C77CA96172C0391BEBD53E4D9A4E261B51DD08EB23BC8ABFBBF896935'
if ((Get-FileHash $source -Algorithm SHA256).Hash -cne $expected) {
  throw 'Sealed HTML-copy harness changed.'
}
$scriptText = (Get-Content -Raw -Encoding utf8 $source).Replace(
  '$PSScriptRoot',
  '$outputRoot'
)
& ([scriptblock]::Create($scriptText))
