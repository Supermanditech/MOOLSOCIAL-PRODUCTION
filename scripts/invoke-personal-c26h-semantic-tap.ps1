[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[A-Za-z0-9._-]+$')]
  [string]$Serial,

  [Parameter(Mandatory = $true)]
  [string]$EvidenceDirectory,

  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[A-Za-z0-9._-]+$')]
  [string]$Stem,

  [Parameter(Mandatory = $true)]
  [string]$Semantic
)

$ErrorActionPreference = 'Stop'
$adb = (Get-Command adb -ErrorAction Stop).Source
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
if (-not (Test-Path -LiteralPath $evidenceRoot -PathType Container)) {
  throw "Evidence directory does not exist: $evidenceRoot"
}
$inputMethodState = & $adb -s $Serial shell dumpsys input_method 2>&1
if ($LASTEXITCODE -ne 0) { throw "Unable to read input-method state: $inputMethodState" }
if (($inputMethodState -join "`n") -match 'mInputShown=true') {
  throw 'Visible input method covers native navigation; dismiss it and prove route continuity before semantic tap.'
}
$xmlPath = Join-Path $evidenceRoot "$Stem-tap-pre.xml"
if (Test-Path -LiteralPath $xmlPath) { throw "Refusing to overwrite tap evidence: $xmlPath" }
$remote = "/sdcard/Download/codex-c26h-$Stem-tap-pre.xml"
try {
  $dump = & $adb -s $Serial shell uiautomator dump $remote 2>&1
  if ($LASTEXITCODE -ne 0 -or ($dump -join "`n") -notmatch 'UI hierchary dumped to|UI hierarchy dumped to') {
    throw "UI hierarchy dump failed: $dump"
  }
  $pull = & $adb -s $Serial pull $remote $xmlPath 2>&1
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $xmlPath -PathType Leaf)) {
    throw "UI hierarchy pull failed: $pull"
  }
} finally {
  & $adb -s $Serial shell rm -f $remote *> $null
}

[xml]$hierarchy = Get-Content -Raw -LiteralPath $xmlPath
$matches = @($hierarchy.SelectNodes('//node[@clickable="true"]') | Where-Object {
  ([string]$_.'content-desc' -ceq $Semantic) -or ([string]$_.text -ceq $Semantic)
})
if ($matches.Count -ne 1) {
  throw "Expected exactly one clickable exact semantic '$Semantic'; found $($matches.Count)."
}
$bounds = [string]$matches[0].bounds
if ($bounds -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') {
  throw "Semantic has invalid bounds: $bounds"
}
$left = [int]$Matches[1]
$top = [int]$Matches[2]
$right = [int]$Matches[3]
$bottom = [int]$Matches[4]
if ($right -le $left -or $bottom -le $top) { throw "Semantic has empty bounds: $bounds" }
$x = [int][Math]::Floor(($left + $right) / 2)
$y = [int][Math]::Floor(($top + $bottom) / 2)
& $adb -s $Serial shell input tap $x $y *> $null
if ($LASTEXITCODE -ne 0) { throw "Semantic tap failed at $x,$y." }
Write-Output "Semantic tap invoked: semantic=$Semantic; bounds=$bounds; center=[$x,$y]"
