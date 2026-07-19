$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$sourceSets = @(
  @{
    Path = Join-Path $root "apps\mobile\lib"
    Extensions = @(".dart")
  },
  @{
    Path = Join-Path $root "apps\admin\components"
    Extensions = @(".ts", ".tsx", ".js", ".jsx")
  },
  @{
    Path = Join-Path $root "apps\admin\lib"
    Extensions = @(".ts", ".tsx", ".js", ".jsx")
  }
)
$blocked = @(
  "local review",
  "production cloud",
  "next production",
  "intent result",
  "test action",
  "state machine",
  "user scrolls",
  "buying remains contextual",
  "retailer will confirm stock",
  "fulfilment mode enabled",
  "test without camera permission",
  "test without microphone permission",
  "to test this path",
  "scan test barcode",
  "for example",
  "example net",
  "small test group",
  "isolated review data",
  "sampled playback",
  "action_tapped",
  "run safe test",
  "safe test completed",
  "for this reviewed journey",
  "access production services",
  "location, shop photo and scan test",
  "qr scan test"
)
$blockedQuotedWords = @(
  "bootstrap",
  "endpoint",
  "payload",
  "handoff",
  "mock",
  "internal",
  "placeholder"
)

$violations = [System.Collections.Generic.List[string]]::new()
$files = foreach ($sourceSet in $sourceSets) {
  Get-ChildItem -LiteralPath $sourceSet.Path -Recurse -File |
    Where-Object { $sourceSet.Extensions -contains $_.Extension }
}

foreach ($file in $files) {
  $lineNumber = 0
  foreach ($line in Get-Content -LiteralPath $file.FullName) {
    $lineNumber += 1
    $lower = $line.ToLowerInvariant()
    foreach ($phrase in $blocked) {
      if ($lower.Contains($phrase)) {
        $relative = $file.FullName.Substring($root.Length + 1)
        $violations.Add("${relative}:${lineNumber}: prohibited phrase '$phrase'")
      }
    }
    foreach ($word in $blockedQuotedWords) {
      if ($line -match "['`"][^'`"]*\b$word\b[^'`"]*['`"]") {
        $relative = $file.FullName.Substring($root.Length + 1)
        $violations.Add("${relative}:${lineNumber}: prohibited word '$word'")
      }
    }
  }
}

if ($violations.Count -gt 0) {
  $violations | ForEach-Object { Write-Error $_ }
  throw "User-facing copy gate failed with $($violations.Count) violation(s)."
}

Write-Output "User-facing copy gate passed."
