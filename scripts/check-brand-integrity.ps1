param(
  [ValidateSet("App", "Website", "All")]
  [string]$Surface = "App",
  [string]$ScreenbookRoot = "",
  [switch]$RequireScreenbook
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$contractPath = Join-Path $root "config\brand-integrity.json"

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )

  if (-not $Condition) {
    throw "Brand integrity gate failed: $Message"
  }
}

function Assert-Contains {
  param(
    [string]$Text,
    [string]$Expected,
    [string]$Message
  )

  Assert-True -Condition $Text.Contains($Expected) -Message $Message
}

Assert-True -Condition (Test-Path -LiteralPath $contractPath) `
  -Message "machine-readable contract is missing: $contractPath"

$contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
Assert-True -Condition ($contract.schemaVersion -eq 1) `
  -Message "unsupported brand contract schema"
Assert-True -Condition ($contract.wordmark -ceq "MoolSocial") `
  -Message "wordmark must be exactly MoolSocial"
Assert-True -Condition ($contract.colours.navy -ceq "#000080") `
  -Message "navy must be #000080"
Assert-True -Condition ($contract.colours.saffron -ceq "#FF9933") `
  -Message "saffron must be #FF9933"
Assert-True -Condition ($contract.colours.white -ceq "#FFFFFF") `
  -Message "white must be #FFFFFF"
Assert-True -Condition ($contract.colours.green -ceq "#138808") `
  -Message "green must be #138808"
Assert-True -Condition (($contract.identityLineOrder -join ",") -ceq "saffron,white,green") `
  -Message "identity-line order must be saffron, white, green"
Assert-True -Condition ($contract.moolNavigation.flutterGlyph -ceq "Icons.grid_view_rounded") `
  -Message "Flutter Mool glyph must be Icons.grid_view_rounded"

$colourPath = Join-Path $root "apps\mobile\lib\core\design\mool_colors.dart"
$designPath = Join-Path $root "apps\mobile\lib\core\design\mool_design_system.dart"
$chatPath = Join-Path $root "apps\mobile\lib\features\chat\screens\chat_inbox_screen.dart"
$socialRailPath = Join-Path $root "apps\mobile\lib\ui_v2\social\screen04_universal_components.dart"
$creatorRailPath = Join-Path $root "apps\mobile\lib\ui_v2\social\social_v2_creator.dart"

foreach ($path in @($colourPath, $designPath, $chatPath, $socialRailPath, $creatorRailPath)) {
  Assert-True -Condition (Test-Path -LiteralPath $path) `
    -Message "required Flutter brand source is missing: $path"
}

$colourSource = Get-Content -LiteralPath $colourPath -Raw
Assert-Contains $colourSource "Color(0xFF000080)" "Flutter navy token changed"
Assert-Contains $colourSource "Color(0xFFFF9933)" "Flutter saffron token changed"
Assert-Contains $colourSource "Color(0xFF138808)" "Flutter green token changed"

$designSource = Get-Content -LiteralPath $designPath -Raw
Assert-Contains $designSource "static const String wordmark = 'MoolSocial';" `
  "Flutter canonical wordmark is missing"
Assert-Contains $designSource "static const IconData moolLauncherIcon = Icons.grid_view_rounded;" `
  "Flutter canonical Mool launcher is missing"
Assert-Contains $designSource "MoolBrand.moolLauncherIcon" `
  "shared outcome dock does not render the canonical Mool launcher"

$chatSource = Get-Content -LiteralPath $chatPath -Raw
Assert-Contains $chatSource "icon: const Icon(MoolBrand.moolLauncherIcon)" `
  "Chat Mool entry does not use the canonical launcher"

foreach ($path in @($socialRailPath, $creatorRailPath)) {
  $source = Get-Content -LiteralPath $path -Raw
  Assert-True -Condition (
    $source -match "(?s)label:\s*'Mool'.{0,160}icon:\s*Icons\.grid_view_rounded"
  ) -Message "protected Social Mool entry changed in $path"
}

$flutterRoot = Join-Path $root "apps\mobile\lib"
$forbiddenMoolPattern = "(?s)label:\s*['`"]Mool['`"].{0,240}icon:\s*Icons\.(blur_circular_rounded|circle)\b"
foreach ($file in Get-ChildItem -LiteralPath $flutterRoot -Recurse -File -Filter "*.dart") {
  $source = Get-Content -LiteralPath $file.FullName -Raw
  Assert-True -Condition (-not [regex]::IsMatch($source, $forbiddenMoolPattern)) `
    -Message "placeholder Mool glyph remains in $($file.FullName)"
}

if ([string]::IsNullOrWhiteSpace($ScreenbookRoot)) {
  $ScreenbookRoot = Join-Path (Split-Path -Parent $root) "supermandi-uiux-screenbook"
}

if (Test-Path -LiteralPath $ScreenbookRoot) {
  $buyHtmlPath = Join-Path $ScreenbookRoot "screens\09-buy.html"
  $buyCssPath = Join-Path $ScreenbookRoot "shared\moolsocial-buy-v2.css"
  $foundationPath = Join-Path $ScreenbookRoot "shared\moolsocial-ui-foundation.css"
  $socialBatchPath = Join-Path $ScreenbookRoot "shared\moolsocial-social-batch.js"
  $socialCssPath = Join-Path $ScreenbookRoot "shared\moolsocial-social-batch.css"

  foreach ($path in @(
    $buyHtmlPath,
    $buyCssPath,
    $foundationPath,
    $socialBatchPath,
    $socialCssPath
  )) {
    Assert-True -Condition (Test-Path -LiteralPath $path) `
      -Message "required HTML brand source is missing: $path"
  }

  $foundation = Get-Content -LiteralPath $foundationPath -Raw
  Assert-Contains $foundation "--ms-navy: #000080;" "HTML navy token changed"
  Assert-Contains $foundation "--ms-saffron: #FF9933;" "HTML saffron token changed"
  Assert-Contains $foundation "--ms-white: #FFFFFF;" "HTML white token changed"
  Assert-Contains $foundation "--ms-green: #138808;" "HTML green token changed"

  $buyHtml = Get-Content -LiteralPath $buyHtmlPath -Raw
  Assert-Contains $buyHtml "<strong>MoolSocial</strong>" `
    "Buy wordmark is missing or changed"
  Assert-True -Condition (-not $buyHtml.Contains('class="brand-mark"')) `
    -Message "Buy still contains a module-specific brand mark"
  foreach ($cell in @(
    '<rect x="3" y="3" width="7" height="7" rx="1.5" />',
    '<rect x="14" y="3" width="7" height="7" rx="1.5" />',
    '<rect x="3" y="14" width="7" height="7" rx="1.5" />',
    '<rect x="14" y="14" width="7" height="7" rx="1.5" />'
  )) {
    Assert-Contains $buyHtml $cell "Buy Mool launcher is not the four-cell grid"
  }

  $buyCss = Get-Content -LiteralPath $buyCssPath -Raw
  Assert-True -Condition (-not $buyCss.Contains(".brand-mark")) `
    -Message "Buy CSS still supports the removed module-specific mark"
  Assert-True -Condition ($buyCss -match "(?i)--navy:\s*#000080;") `
    -Message "Buy navy token changed"
  Assert-True -Condition ($buyCss -match "(?i)--saffron:\s*#ff9933;") `
    -Message "Buy saffron token changed"
  Assert-True -Condition ($buyCss -match "(?i)--green:\s*#138808;") `
    -Message "Buy green token changed"

  $socialBatch = Get-Content -LiteralPath $socialBatchPath -Raw
  Assert-Contains $socialBatch "<strong>MoolSocial</strong>" `
    "Social wordmark is missing or changed"
  Assert-Contains $socialBatch '["Mool", "04-universal-focus-shell.html?openMool=1&world=social&rail=capability", "grid"]' `
    "Social navigation no longer uses the grid launcher"

  $socialCss = Get-Content -LiteralPath $socialCssPath -Raw
  Assert-True -Condition ($socialCss -match "(?i)--navy:\s*#000080;") `
    -Message "Social navy token changed"
  Assert-True -Condition ($socialCss -match "(?i)--saffron:\s*#ff9933;") `
    -Message "Social saffron token changed"
  Assert-True -Condition ($socialCss -match "(?i)--white:\s*#fff(?:fff)?;") `
    -Message "Social white token changed"
  Assert-True -Condition ($socialCss -match "(?i)--green:\s*#138808;") `
    -Message "Social green token changed"
  Assert-Contains $socialCss ".brand-line i:nth-child(1) { background: var(--saffron); }" `
    "Social identity-line saffron position changed"
  Assert-Contains $socialCss ".brand-line i:nth-child(2) { background: var(--white); }" `
    "Social identity-line white position changed"
  Assert-Contains $socialCss ".brand-line i:nth-child(3) { background: var(--green); }" `
    "Social identity-line green position changed"

  foreach ($editableRoot in @(
    (Join-Path $ScreenbookRoot "screens"),
    (Join-Path $ScreenbookRoot "shared")
  )) {
    foreach ($file in Get-ChildItem -LiteralPath $editableRoot -Recurse -File |
      Where-Object { $_.Extension -in @(".html", ".css", ".js") }) {
      $source = Get-Content -LiteralPath $file.FullName -Raw
      foreach ($forbiddenMark in $contract.forbiddenAppMarks) {
        Assert-True -Condition (-not $source.Contains([string]$forbiddenMark)) `
          -Message "forbidden one-off M mark remains in $($file.FullName)"
      }
    }
  }
} elseif ($RequireScreenbook) {
  throw "Brand integrity gate failed: screenbook is required but unavailable: $ScreenbookRoot"
} else {
  Write-Output "Screenbook not present; repository-owned Flutter and contract checks completed."
}

if ($Surface -in @("Website", "All")) {
  Assert-True -Condition (
    $contract.surfaces.website.status -ne "pending-alignment" -and
    -not $contract.surfaces.website.blockNextWebsiteReleaseUntilAligned
  ) -Message "website alignment is founder-recorded as pending; the next website release is blocked"
}

Write-Output "Brand integrity gate passed for surface: $Surface"
