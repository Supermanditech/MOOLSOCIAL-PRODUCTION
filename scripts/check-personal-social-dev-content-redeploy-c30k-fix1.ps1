[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C30KFix1 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30K-FIX1 content redeploy gate rejected: $Message"
  }
}

function Resolve-C30KFix1File {
  param([Parameter(Mandatory)][string]$RelativePath)
  Assert-C30KFix1 (-not [IO.Path]::IsPathRooted($RelativePath)) 'path must be repository-relative'
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C30KFix1 ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) 'path escaped repository'
  Assert-C30KFix1 (Test-Path -LiteralPath $resolved -PathType Leaf) "missing file: $RelativePath"
  return $resolved
}

function Get-C30KFix1SourceTree {
  $sourceRoot = Join-Path $root 'backend/functions/src'
  $rows = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
      Sort-Object FullName |
      ForEach-Object {
        $relative = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        "$hash $relative"
      }
  )
  $bytes = [Text.Encoding]::UTF8.GetBytes(($rows -join "`n") + "`n")
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $aggregate = [Convert]::ToHexString($sha.ComputeHash($bytes))
  } finally {
    $sha.Dispose()
  }
  return [pscustomobject]@{ Count = $rows.Count; Hash = $aggregate }
}

$ticketPath = Resolve-C30KFix1File 'config/uaw-personal-mvp-social-dev-content-redeploy-c30k-fix1-ticket.json'
$scopePath = Resolve-C30KFix1File 'config/mvp-scope-gate-state.json'
$protectedPath = Resolve-C30KFix1File 'config/apk-regression-gate-state-c30h.json'
$sealPath = Resolve-C30KFix1File 'config/uaw-personal-mvp-social-dev-content-redeploy-c30k-fix1-seal.json'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$protected = Get-Content -Raw -LiteralPath $protectedPath | ConvertFrom-Json
$seal = Get-Content -Raw -LiteralPath $sealPath | ConvertFrom-Json
$firebase = Get-Content -Raw -LiteralPath (Resolve-C30KFix1File 'firebase.json') | ConvertFrom-Json

$expectedTicket = 'UAW-PERSONAL-MVP-SOCIAL-DEV-CONTENT-REDEPLOY-C30K-FIX1'
Assert-C30KFix1 ([string]$ticket.ticketId -ceq $expectedTicket) 'unexpected ticket id'
Assert-C30KFix1 ([string]$ticket.state -ceq 'founder_authorized_predeployment_correction_and_qualification') 'ticket is not at the authorized predeployment state'
Assert-C30KFix1 ([string]$scope.ticket.id -ceq $expectedTicket) 'active MVP ticket differs'
Assert-C30KFix1 ([string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $expectedTicket) 'preselection ticket differs'
Assert-C30KFix1 ([bool]$scope.execution.backendWriteAuthorized) 'bounded source correction authority is closed'
Assert-C30KFix1 ([bool]$scope.execution.externalServiceWriteAuthorized) 'exact Dev function deployment authority is closed'
Assert-C30KFix1 (-not [bool]$scope.execution.buildAuthorized) 'APK build authority must remain closed'
Assert-C30KFix1 (-not [bool]$scope.execution.deviceInstallAuthorized) 'device install authority must remain closed'
Assert-C30KFix1 (-not [bool]$scope.execution.secretValueAccessAuthorized) 'secret value access must remain closed'

Assert-C30KFix1 ([string]$protected.machineState -ceq 'device_rejected_green_edge_focus_paint_preserved') 'protected r60.38 state changed'
Assert-C30KFix1 ([string]$protected.candidate.versionName -ceq '1.0.0-r60.38') 'protected version name changed'
Assert-C30KFix1 ([string]$protected.candidate.versionCode -ceq '2026081238') 'protected version code changed'
Assert-C30KFix1 ([string]$protected.qualificationResult.apkSha256 -ceq 'F47B7535F2083EA458FC146993987331ACA3AD29B6655ADAA83B1B4B009BF3EF') 'protected APK hash changed'

$functionConfig = $firebase.functions[0]
Assert-C30KFix1 ([string]$functionConfig.source -ceq 'backend/functions') 'Functions source changed'
Assert-C30KFix1 ([string]$functionConfig.codebase -ceq 'provider') 'Functions codebase changed'
Assert-C30KFix1 ([string]$functionConfig.runtime -ceq 'nodejs22') 'Functions runtime changed'
$ignore = @($functionConfig.ignore)
foreach ($requiredIgnore in @(
    'src/social/dev_review_corpus.ts',
    'src/social/dev_review_corpus_runner.ts',
    'lib/social/dev_review_corpus.js',
    'lib/social/dev_review_corpus.js.map',
    'lib/social/dev_review_corpus.d.ts',
    'lib/social/dev_review_corpus_runner.js',
    'lib/social/dev_review_corpus_runner.js.map',
    'lib/social/dev_review_corpus_runner.d.ts'
  )) {
  Assert-C30KFix1 ($ignore -ccontains $requiredIgnore) "operator upload exclusion missing: $requiredIgnore"
}

$index = Get-Content -Raw -LiteralPath (Resolve-C30KFix1File 'backend/functions/src/index.ts')
Assert-C30KFix1 ($index.Contains('export const moolSocialContent = onRequest(')) 'moolSocialContent export missing'
Assert-C30KFix1 (-not $index.Contains('dev_review_corpus')) 'operator tooling entered the HTTP runtime owner'
$firestoreRules = Get-Content -Raw -LiteralPath (Resolve-C30KFix1File 'backend/firestore/youtube-private-dev.rules')
$storageRules = Get-Content -Raw -LiteralPath (Resolve-C30KFix1File 'backend/storage/moolsocial-private-dev.rules')
Assert-C30KFix1 ($firestoreRules.Contains('allow read, write: if false;')) 'Firestore deny-all rule changed'
Assert-C30KFix1 ($storageRules.Contains('allow read, write: if false;')) 'Storage deny-all rule changed'

foreach ($entry in @($seal.files)) {
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-C30KFix1File ([string]$entry.path))).Hash
  Assert-C30KFix1 ($actual -ceq [string]$entry.sha256) "source seal changed: $($entry.path)"
}
$tree = Get-C30KFix1SourceTree
Assert-C30KFix1 ([int]$tree.Count -eq [int]$seal.sourceTree.fileCount) 'function source file count changed'
Assert-C30KFix1 ([string]$tree.Hash -ceq [string]$seal.sourceTree.aggregateSha256) 'function source aggregate changed'

Write-Output (
  'C30K-FIX1 content redeploy gate passed: project=moolsocial-dev-503018; ' +
  'target=functions:moolSocialContent; sourceFiles=' + $tree.Count + '; ' +
  'sourceAggregate=' + $tree.Hash + '; operatorUpload=false; rulesWrite=false; ' +
  'APK=false; Production=false.'
)
