[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$backendRoot = Join-Path $root 'backend\functions'
$nodeVersion = '22.23.2'
$archiveName = "node-v$nodeVersion-win-x64.zip"
$expectedSha256 = '1177B4137BA5ADAA56354AE40F1080C7450E8AE09CECB47DA459D1C52AC99F97'
$downloadUri = "https://nodejs.org/dist/v$nodeVersion/$archiveName"
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
  [char[]]@('\', '/')
)
$temporaryRoot = [IO.Path]::GetFullPath((Join-Path $temporaryBase (
  'moolsocial-node22-verify-' + [Guid]::NewGuid().ToString('N')
)))

function Assert-Node22([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "Backend Node 22 verification rejected: $Message" }
}

Assert-Node22 (
  $temporaryRoot.StartsWith(
    $temporaryBase + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  ) -and
  [IO.Path]::GetFileName($temporaryRoot).StartsWith(
    'moolsocial-node22-verify-',
    [StringComparison]::Ordinal
  )
) 'temporary root escaped the exact namespace.'
Assert-Node22 (Test-Path -LiteralPath $backendRoot -PathType Container) `
  'backend/functions is missing.'

try {
  New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
  $archivePath = Join-Path $temporaryRoot $archiveName
  Invoke-WebRequest -UseBasicParsing -Uri $downloadUri -OutFile $archivePath
  $actualSha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
  Assert-Node22 ($actualSha256 -ceq $expectedSha256) `
    'official Node archive SHA-256 differs.'
  Expand-Archive -LiteralPath $archivePath -DestinationPath $temporaryRoot
  $nodeRoot = Join-Path $temporaryRoot "node-v$nodeVersion-win-x64"
  $node = Join-Path $nodeRoot 'node.exe'
  $npm = Join-Path $nodeRoot 'npm.cmd'
  Assert-Node22 (
    (Test-Path -LiteralPath $node -PathType Leaf) -and
    (Test-Path -LiteralPath $npm -PathType Leaf)
  ) 'verified Node runtime is incomplete.'
  $reportedVersion = (& $node --version).Trim()
  Assert-Node22 ($reportedVersion -ceq "v$nodeVersion") `
    'verified Node executable reported a different version.'

  $priorPath = $env:PATH
  try {
    $env:PATH = $nodeRoot + [IO.Path]::PathSeparator + $priorPath
    Push-Location $backendRoot
    try {
      & $npm ci --ignore-scripts --no-audit --fund=false
      Assert-Node22 ($LASTEXITCODE -eq 0) 'npm ci failed under Node 22.'
      & $npm run verify
      Assert-Node22 ($LASTEXITCODE -eq 0) `
        'backend typecheck or tests failed under Node 22.'
    } finally {
      Pop-Location
    }
  } finally {
    $env:PATH = $priorPath
  }
} finally {
  if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
    $resolved = [IO.Path]::GetFullPath($temporaryRoot)
    Assert-Node22 (
      $resolved.StartsWith(
        $temporaryBase + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      ) -and
      [IO.Path]::GetFileName($resolved).StartsWith(
        'moolsocial-node22-verify-',
        [StringComparison]::Ordinal
      )
    ) 'cleanup target changed.'
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}

Write-Output (
  'Backend Node 22 verification passed: ' +
  "node=v$nodeVersion; archiveSha256=$expectedSha256; npmCi=true; verify=true."
)
