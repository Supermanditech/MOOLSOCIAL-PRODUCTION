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

function Remove-DartInterpolationForCustomerCopy {
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Line
  )
  return [regex]::Replace($Line, '\$\{[^{}\r\n]*\}', '')
}

$interpolationFixture = 'https://graph.facebook.com${endpoint.path}'
$literalFixture = 'Endpoint unavailable'
$renderedInterpolationFixture = (
  Remove-DartInterpolationForCustomerCopy $interpolationFixture
).ToLowerInvariant()
$renderedLiteralFixture = $literalFixture.ToLowerInvariant()
if (
  $renderedInterpolationFixture.Contains('endpoint') -or
  -not $renderedLiteralFixture.Contains('endpoint') -or
  (Remove-DartInterpolationForCustomerCopy '') -cne ''
) {
  throw 'User-facing copy interpolation fixture failed.'
}

function Test-NonVisibleDartCopyLine {
  param(
    [Parameter(Mandatory = $true)][string]$Extension,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Line,
    [AllowEmptyString()][string]$RelativePath = ''
  )
  $trimmed = $Line.Trim()
  return (
    $Extension -eq '.dart' -and
    (
      $Line -match '\b(?:Key|ValueKey|ObjectKey)\s*\(' -or
      $Line -match '\bsafeCode\s*:' -or
      (
        $Line -match '\bcode\s*:' -and
        $Line.Contains("'auth-")
      ) -or
      $Line -match '\bArgumentError\.value\s*\(' -or
      $trimmed.EndsWith('=>') -or
      (
        $Line.Contains("=> 'auth-") -and
        $Line.TrimEnd().EndsWith("',")
      ) -or
      (
        $RelativePath.EndsWith(
          'core/auth/x_oauth2_pkce_network_adapter.dart',
          [StringComparison]::OrdinalIgnoreCase
        ) -and
        $trimmed -ceq "'internal',"
      )
    )
  )
}

$safeCodeFixture = "safeCode: 'auth-callback-payload-invalid',"
$safeCodeMapFixture = "'internal' => 'auth-broker-internal',"
$brokerSetFixture = "'internal',"
$argumentFixture = "throw ArgumentError.value(value, name, 'Invalid HTTPS endpoint.');"
$switchCodeFixture = "'internal-error' || 'web-internal-error' =>"
$authCodeFixture = "code: 'auth-account-bootstrap-fatal',"
$visiblePayloadFixture = "Text('Payload invalid')"
if (
  -not (Test-NonVisibleDartCopyLine '.dart' $safeCodeFixture) -or
  -not (Test-NonVisibleDartCopyLine '.dart' $safeCodeMapFixture) -or
  -not (Test-NonVisibleDartCopyLine '.dart' $brokerSetFixture `
      'apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart') -or
  -not (Test-NonVisibleDartCopyLine '.dart' $argumentFixture) -or
  -not (Test-NonVisibleDartCopyLine '.dart' $switchCodeFixture) -or
  -not (Test-NonVisibleDartCopyLine '.dart' $authCodeFixture) -or
  (Test-NonVisibleDartCopyLine '.dart' $visiblePayloadFixture)
) {
  throw 'User-facing copy non-visible Dart metadata fixture failed.'
}

$violations = [System.Collections.Generic.List[string]]::new()
$files = foreach ($sourceSet in $sourceSets) {
  Get-ChildItem -LiteralPath $sourceSet.Path -Recurse -File |
    Where-Object { $sourceSet.Extensions -contains $_.Extension }
}

foreach ($file in $files) {
  $relative = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
  $lineNumber = 0
  foreach ($line in Get-Content -LiteralPath $file.FullName) {
    $lineNumber += 1
    $lower = $line.ToLowerInvariant()
    $customerCopyLine = Remove-DartInterpolationForCustomerCopy $line
    $nonVisibleDartCopy = Test-NonVisibleDartCopyLine `
      $file.Extension $line $relative
    foreach ($phrase in $blocked) {
      if ($lower.Contains($phrase)) {
        $violations.Add("${relative}:${lineNumber}: prohibited phrase '$phrase'")
      }
    }
    foreach ($word in $blockedQuotedWords) {
      if (
        -not $nonVisibleDartCopy -and
        $customerCopyLine -match "['`"][^'`"]*\b$word\b[^'`"]*['`"]"
      ) {
        $violations.Add("${relative}:${lineNumber}: prohibited word '$word'")
      }
    }
  }
}

if ($violations.Count -gt 0) {
  $violations | ForEach-Object { Write-Output $_ }
  throw "User-facing copy gate failed with $($violations.Count) violation(s)."
}

Write-Output "User-facing copy gate passed."
