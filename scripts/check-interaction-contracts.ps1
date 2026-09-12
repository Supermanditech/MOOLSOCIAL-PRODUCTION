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

function Test-InterpolatedRouteTarget {
  param([Parameter(Mandatory = $true)][string]$Target)
  return $Target -match '\$(?:\{[^}]+\}|[A-Za-z_][A-Za-z0-9_]*)'
}

function ConvertTo-InteractionRouteProbe {
  param([Parameter(Mandatory = $true)][string]$Path)
  $probe = [regex]::Replace($Path, '\$\{[^}]+\}', 'dynamic')
  return [regex]::Replace(
    $probe,
    '\$[A-Za-z_][A-Za-z0-9_]*',
    'dynamic'
  )
}

function Test-ExternalAuthCallbackTemplate {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter(Mandatory = $true)][string]$Content
  )
  $owner = $RelativePath.Replace('\', '/')
  return (
    $owner -ceq
      'apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart' -and
    $Target -ceq '/app/auth/$operationPath' -and
    $Content.Contains("callbackUri.path != '/app/auth/`$operationPath'") -and
    $Content.Contains("operationPath: 'x'")
  )
}

function Test-EmailContinuePathContract {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter(Mandatory = $true)][string]$Content
  )
  $owner = $RelativePath.Replace('\', '/')
  return (
    $owner -ceq
      'apps/mobile/lib/core/config/email_link_runtime_configuration.dart' -and
    $Target -ceq '/app' -and
    $Content.Contains('bool _isMoolSocialAppPath(String path)') -and
    $Content.Contains("path == '/app' || path.startsWith('/app/')")
  )
}

function Test-RoutePredicateLiteral {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter(Mandatory = $true)][string]$Content
  )
  $owner = $RelativePath.Replace('\', '/')
  $predicateOwner = $owner -cin @(
    'apps/mobile/lib/features/journey01/journey_session.dart',
    'apps/mobile/lib/ui_v2/universal/legacy_route_containment_screen_v2.dart'
  )
  return (
    $predicateOwner -and
    (
      $Content.Contains("path.startsWith('$Target')") -or
      $Content.Contains("path == '$Target'")
    )
  )
}

function Test-NavigatorRouteSettingsName {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter(Mandatory = $true)][string]$Content
  )
  $owner = $RelativePath.Replace('\', '/')
  return (
    $owner -ceq 'apps/mobile/lib/ui_v2/buy/buy_v2_invoice.dart' -and
    $Target -ceq '/app/buy/order/${order.id}/invoice' -and
    $Content.Contains("settings: RouteSettings(name: '$Target')")
  )
}

if (
  -not (Test-InterpolatedRouteTarget '/app/auth/$operationPath') -or
  -not (Test-InterpolatedRouteTarget '/app/item/${itemId}') -or
  (Test-InterpolatedRouteTarget '/app/social') -or
  (ConvertTo-InteractionRouteProbe '/app/auth/$operationPath') -cne
    '/app/auth/dynamic' -or
  (ConvertTo-InteractionRouteProbe '/app/item/${itemId}') -cne
    '/app/item/dynamic' -or
  (ConvertTo-InteractionRouteProbe '/app/social') -cne '/app/social' -or
  -not (Test-ExternalAuthCallbackTemplate `
      'apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart' `
      '/app/auth/$operationPath' `
      "callbackUri.path != '/app/auth/`$operationPath'; operationPath: 'x'") -or
  (Test-ExternalAuthCallbackTemplate `
      'apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart' `
      '/app/$operationPath' `
      "callbackUri.path != '/app/auth/`$operationPath'; operationPath: 'x'") -or
  -not (Test-EmailContinuePathContract `
      'apps/mobile/lib/core/config/email_link_runtime_configuration.dart' `
      '/app' `
      "bool _isMoolSocialAppPath(String path); path == '/app' || path.startsWith('/app/')") -or
  (Test-EmailContinuePathContract `
      'apps/mobile/lib/core/config/other.dart' `
      '/app' `
      "bool _isMoolSocialAppPath(String path); path == '/app' || path.startsWith('/app/')") -or
  -not (Test-RoutePredicateLiteral `
      'apps/mobile/lib/features/journey01/journey_session.dart' `
      '/app/chat/thread/' `
      "path.startsWith('/app/chat/thread/')") -or
  (Test-RoutePredicateLiteral `
      'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart' `
      '/app/chat/thread/' `
      "path.startsWith('/app/chat/thread/')") -or
  -not (Test-NavigatorRouteSettingsName `
      'apps/mobile/lib/ui_v2/buy/buy_v2_invoice.dart' `
      '/app/buy/order/${order.id}/invoice' `
      "settings: RouteSettings(name: '/app/buy/order/`${order.id}/invoice')")
) {
  throw 'Interaction contract interpolated-route fixture failed.'
}

foreach ($file in $mobileFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw
  $relative = $file.FullName.Substring($root.Length + 1)
  $targets = [regex]::Matches($content, "'(/app[^']*)'") |
    ForEach-Object { $_.Groups[1].Value } |
    Where-Object { $_ -ne "/app/" }

  foreach ($target in $targets) {
    if (Test-ExternalAuthCallbackTemplate $relative $target $content) {
      continue
    }
    if (Test-EmailContinuePathContract $relative $target $content) {
      continue
    }
    if (Test-RoutePredicateLiteral $relative $target $content) {
      continue
    }
    if (Test-NavigatorRouteSettingsName $relative $target $content) {
      continue
    }
    $path = $target.Split("?")[0]
    $path = ConvertTo-InteractionRouteProbe $path
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
  $violations | ForEach-Object { Write-Output $_ }
  throw "Interaction contract gate failed with $($violations.Count) violation(s)."
}

Write-Output (
  "Interaction contract gate passed: $($routes.Count) unique routes, all " +
  "literal app targets resolve and no static no-op controls remain."
)
