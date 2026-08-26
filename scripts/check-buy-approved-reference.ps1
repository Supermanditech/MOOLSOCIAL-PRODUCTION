$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$referenceRoot = Join-Path $root "approved-references\screens\09-buy-complete\v1"
$checksumsPath = Join-Path $referenceRoot "SHA256SUMS"
$manifestPath = Join-Path $root "approved-references\manifest.json"

if (-not (Test-Path -LiteralPath $referenceRoot -PathType Container)) {
  throw "Founder FINAL Buy reference is missing: $referenceRoot"
}

if (-not (Test-Path -LiteralPath $checksumsPath -PathType Leaf)) {
  throw "Founder FINAL Buy checksum file is missing: $checksumsPath"
}

function Get-BuyReferenceSha256 {
  param([Parameter(Mandatory = $true)][byte[]]$Bytes)
  return [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData($Bytes)
  ).ToLowerInvariant()
}

function Test-BuyReferenceBytes {
  param(
    [Parameter(Mandatory = $true)][byte[]]$Bytes,
    [Parameter(Mandatory = $true)][string]$Expected
  )
  $expectedLower = $Expected.ToLowerInvariant()
  if ((Get-BuyReferenceSha256 $Bytes) -ceq $expectedLower) { return $true }
  try {
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    $text = $utf8.GetString($Bytes)
    $canonical = $utf8.GetBytes($text.Replace("`r`n", "`n"))
    return (Get-BuyReferenceSha256 $canonical) -ceq $expectedLower
  } catch {
    return $false
  }
}

$fixtureUtf8 = [Text.UTF8Encoding]::new($false)
$fixtureLf = $fixtureUtf8.GetBytes("locked`n")
$fixtureCrlf = $fixtureUtf8.GetBytes("locked`r`n")
$fixtureChanged = $fixtureUtf8.GetBytes("changed`n")
$fixtureExpected = Get-BuyReferenceSha256 $fixtureLf
if (
  -not (Test-BuyReferenceBytes $fixtureLf $fixtureExpected) -or
  -not (Test-BuyReferenceBytes $fixtureCrlf $fixtureExpected) -or
  (Test-BuyReferenceBytes $fixtureChanged $fixtureExpected)
) {
  throw 'Buy approved sealed-parallel fixture failed.'
}

$expected = @{}
foreach ($line in Get-Content -LiteralPath $checksumsPath) {
  if ($line -notmatch '^([0-9a-f]{64})  (.+)$') {
    throw "Invalid Buy checksum line: $line"
  }

  $hash = $Matches[1]
  $relative = $Matches[2]
  if ($expected.ContainsKey($relative)) {
    throw "Duplicate Buy checksum entry: $relative"
  }
  $expected[$relative] = $hash
}

$actualFiles = Get-ChildItem -LiteralPath $referenceRoot -Recurse -File |
  Where-Object { $_.FullName -ne $checksumsPath } |
  ForEach-Object {
    $_.FullName.Substring($referenceRoot.Length + 1).Replace('\', '/')
  } |
  Sort-Object

$expectedFiles = @($expected.Keys | Sort-Object)
$missingFromChecksums = @($actualFiles | Where-Object { $_ -notin $expectedFiles })
$missingFromReference = @($expectedFiles | Where-Object { $_ -notin $actualFiles })

if ($missingFromChecksums.Count -gt 0) {
  throw "Unregistered file(s) added to immutable Buy reference: $($missingFromChecksums -join ', ')"
}
if ($missingFromReference.Count -gt 0) {
  throw "File(s) removed from immutable Buy reference: $($missingFromReference -join ', ')"
}

foreach ($relative in $expectedFiles) {
  $path = Join-Path $referenceRoot ($relative -replace '/', '\')
  $actualBytes = [IO.File]::ReadAllBytes($path)
  $actualHash = Get-BuyReferenceSha256 $actualBytes
  if (-not (Test-BuyReferenceBytes $actualBytes $expected[$relative])) {
    throw "Immutable Buy reference changed: $relative expected=$($expected[$relative]) actual=$actualHash"
  }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$entries = @(
  $manifest.screens |
    Where-Object { $_.screenNumber -eq 9 -and $_.screenId -eq "buy-complete" -and $_.version -eq "v1" }
)
if ($entries.Count -ne 1) {
  throw "Manifest must contain exactly one buy-complete/v1 entry; found $($entries.Count)."
}

$entry = $entries[0]
if ($entry.status -ne "founder-final-html-locked") {
  throw "Buy reference manifest status changed: $($entry.status)"
}
if ($entry.root -ne "screens/09-buy-complete/v1") {
  throw "Buy reference manifest root changed: $($entry.root)"
}

$manifestFiles = @{}
foreach ($file in $entry.files) {
  if ($manifestFiles.ContainsKey($file.path)) {
    throw "Duplicate Buy manifest file entry: $($file.path)"
  }
  $manifestFiles[$file.path] = $file.sha256
}

foreach ($relative in $expectedFiles) {
  if (-not $manifestFiles.ContainsKey($relative)) {
    throw "Buy manifest is missing immutable file: $relative"
  }
  if ($manifestFiles[$relative] -ne $expected[$relative]) {
    throw "Buy manifest hash mismatch for $relative"
  }
}

if ($manifestFiles.Count -ne $expectedFiles.Count) {
  throw "Buy manifest file count $($manifestFiles.Count) does not match checksum count $($expectedFiles.Count)."
}

Write-Output "Founder FINAL Buy reference lock passed ($($expectedFiles.Count) immutable files)."
