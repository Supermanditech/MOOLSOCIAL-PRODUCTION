$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mobileSources = Join-Path $root "apps\mobile\lib"
$blocked = @(
  "local review",
  "production cloud",
  "next production",
  "placeholder",
  "intent result",
  "test action",
  "state machine",
  "user scrolls",
  "buying remains contextual",
  "retailer will confirm stock",
  "fulfilment mode enabled"
)
$blockedQuotedWords = @(
  "bootstrap",
  "endpoint",
  "payload",
  "handoff",
  "registry",
  "mock",
  "internal"
)

$violations = [System.Collections.Generic.List[string]]::new()
$files = Get-ChildItem -LiteralPath $mobileSources -Recurse -Filter *.dart

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
