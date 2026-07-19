$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$violations = [System.Collections.Generic.List[string]]::new()

$mobileFiles = Get-ChildItem `
  -LiteralPath (Join-Path $root "apps\mobile\lib") `
  -Recurse `
  -Filter *.dart

$noOpPattern =
  "on(?:Pressed|Tap|LongPress|DoubleTap)\s*:\s*\(\s*\)\s*" +
  "(?:=>\s*(?:null|Future(?:<[^>]+>)?\.value\(\))|\{\s*\})"

foreach ($file in $mobileFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw
  if ($content -match $noOpPattern) {
    $relative = $file.FullName.Substring($root.Length + 1)
    $violations.Add("${relative}: visible control has an empty action callback")
  }
}

$adminFiles = @(
  Get-ChildItem `
    -LiteralPath (Join-Path $root "apps\admin\components") `
    -Recurse `
    -File
  Get-ChildItem `
    -LiteralPath (Join-Path $root "apps\admin\app") `
    -Recurse `
    -File
) | Where-Object { $_.Extension -in @(".ts", ".tsx", ".js", ".jsx") }

foreach ($file in $adminFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw
  $relative = $file.FullName.Substring($root.Length + 1)
  if ($content -match "onClick=\{\(\)\s*=>\s*(?:\{\s*\}|undefined|null)\}") {
    $violations.Add("${relative}: visible control has an empty click callback")
  }
  if ($content -match "href\s*=\s*['`"]#['`"]") {
    $violations.Add("${relative}: visible link uses a non-completing # target")
  }
  if ($content -match "disabled\s*=\s*\{\s*true\s*\}") {
    $violations.Add("${relative}: visible control is permanently disabled")
  }
}

$routerPath = Join-Path `
  $root `
  "apps\mobile\lib\features\journey01\journey_router.dart"
$routerContent = Get-Content -LiteralPath $routerPath -Raw
$routes = [regex]::Matches($routerContent, "path:\s*'([^']+)'") |
  ForEach-Object { $_.Groups[1].Value }

if ($routes.Count -lt 149) {
  $violations.Add(
    "apps\mobile\lib\features\journey01\journey_router.dart: " +
    "expected at least 149 navigable routes; found $($routes.Count)"
  )
}

$duplicateRoutes = $routes |
  Group-Object |
  Where-Object { $_.Count -gt 1 } |
  Select-Object -ExpandProperty Name

foreach ($route in $duplicateRoutes) {
  $violations.Add(
    "apps\mobile\lib\features\journey01\journey_router.dart: " +
    "duplicate route '$route'"
  )
}

$routePatterns = foreach ($route in $routes) {
  "^" + (
    [regex]::Escape($route) -replace
      ":([A-Za-z][A-Za-z0-9_]*)",
      "[^/]+"
  ) + "$"
}

foreach ($file in $mobileFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw
  $relative = $file.FullName.Substring($root.Length + 1)
  $targets = [regex]::Matches($content, "'(/app[^']*)'") |
    ForEach-Object { $_.Groups[1].Value } |
    Where-Object { $_ -ne "/app/" }

  foreach ($target in $targets) {
    $path = $target.Split("?")[0]
    $path = [regex]::Replace($path, "\$\{[^}]+\}", "dynamic")
    $matched = $false
    foreach ($pattern in $routePatterns) {
      if ($path -match $pattern) {
        $matched = $true
        break
      }
    }
    if (-not $matched) {
      $violations.Add(
        "${relative}: route target '$target' has no registered destination"
      )
    }
  }
}

if ($violations.Count -gt 0) {
  $violations | ForEach-Object { Write-Error $_ }
  throw "Interaction contract gate failed with $($violations.Count) violation(s)."
}

Write-Output (
  "Interaction contract gate passed: $($routes.Count) unique routes, all " +
  "literal app targets resolve and no static no-op controls remain."
)
