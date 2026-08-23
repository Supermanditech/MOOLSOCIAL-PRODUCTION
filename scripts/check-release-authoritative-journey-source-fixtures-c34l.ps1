[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$adapterRelative = 'scripts/read-release-authoritative-journey-source-c34l.ps1'
$adapterFile = Join-Path $root $adapterRelative
$utf8 = [Text.UTF8Encoding]::new($false)
$ticketId =
  'UAW-C34L-R60-76-CONSOLIDATED-RELEASE-TRANSACTION-EVIDENCE-PLAY-OPPO-ACCEPTANCE'
$challenge = 'A' * 64
$tmpRoot = [IO.Path]::GetFullPath((Join-Path $root 'tmp')).TrimEnd('\', '/')
$fixtureNamePattern = '^c34l-authoritative-capture-fixtures-[0-9a-f]{32}$'
$createdFixtureRoots = [Collections.Generic.List[string]]::new()
$cleanupInventories = [Collections.Generic.List[object]]::new()

function Assert-C34LJourneyFixture([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "C34L journey source fixture failed: $Message" }
}

function Get-C34LJourneyFixtureSha([string]$Path) {
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Write-C34LJourneyFixtureJson([string]$Path, $Value) {
  [IO.File]::WriteAllText(
    $Path, (($Value | ConvertTo-Json -Depth 30) + [Environment]::NewLine), $utf8
  )
}

function Remove-C34LJourneyFixtureRoot([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
  Assert-C34LJourneyFixture (
    [IO.Path]::GetDirectoryName($full).Equals(
      $tmpRoot, [StringComparison]::OrdinalIgnoreCase
    ) -and [IO.Path]::GetFileName($full) -cmatch $fixtureNamePattern
  ) 'cleanup target is not one exact checker-owned tmp child.'
  if (-not (Test-Path -LiteralPath $full)) { return }
  $attributes = [IO.File]::GetAttributes($full)
  Assert-C34LJourneyFixture (
    -not ($attributes -band [IO.FileAttributes]::ReparsePoint)
  ) 'cleanup target root is an unexpected reparse point.'
  $inventory = [Collections.Generic.List[object]]::new()
  $privatePattern =
    '(?i)([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|(?<![A-Za-z0-9])2b3e0f71(?![A-Za-z0-9])|deviceSerial|androidId|imei|imsi|advertisingId|(?:Bearer|Basic)\s+|-----BEGIN)'
  if (-not ($attributes -band [IO.FileAttributes]::Directory)) {
    $text = [IO.File]::ReadAllText($full)
    Assert-C34LJourneyFixture (
      -not [regex]::IsMatch([IO.Path]::GetFileName($full), $privatePattern) -and
      -not [regex]::IsMatch($text, $privatePattern)
    ) 'cleanup target file contains private or raw-device material.'
    [void]$inventory.Add([pscustomobject][ordered]@{
      path = [IO.Path]::GetFileName($full)
      sha256 = Get-C34LJourneyFixtureSha $full
      bytes = [int64](Get-Item -LiteralPath $full).Length
    })
    [IO.File]::Delete($full)
  } else {
    $pending = [Collections.Generic.Stack[string]]::new()
    $reparseDirectories = [Collections.Generic.List[string]]::new()
    $pending.Push($full)
    while ($pending.Count -gt 0) {
      $directory = $pending.Pop()
      foreach ($entry in [IO.Directory]::EnumerateFileSystemEntries($directory)) {
        $entryFull = [IO.Path]::GetFullPath($entry)
        Assert-C34LJourneyFixture (
          $entryFull.StartsWith($full + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase)
        ) 'cleanup inventory entry escaped its exact fixture root.'
        $relative = $entryFull.Substring($full.Length + 1).Replace('\', '/')
        Assert-C34LJourneyFixture (
          -not [regex]::IsMatch($relative, $privatePattern)
        ) 'cleanup inventory name contains private or raw-device material.'
        $entryAttributes = [IO.File]::GetAttributes($entryFull)
        if ($entryAttributes -band [IO.FileAttributes]::Directory) {
          if ($entryAttributes -band [IO.FileAttributes]::ReparsePoint) {
            Assert-C34LJourneyFixture ($relative -ceq 'adapter-source-alias') `
              'cleanup inventory contains an unexpected reparse directory.'
            [void]$reparseDirectories.Add($entryFull)
          } else {
            $pending.Push($entryFull)
          }
        } else {
          Assert-C34LJourneyFixture (
            -not ($entryAttributes -band [IO.FileAttributes]::ReparsePoint)
          ) 'cleanup inventory contains an unexpected reparse file.'
          $text = [IO.File]::ReadAllText($entryFull)
          Assert-C34LJourneyFixture (-not [regex]::IsMatch($text, $privatePattern)) `
            'cleanup inventory contains private or raw-device material.'
          [void]$inventory.Add([pscustomobject][ordered]@{
            path = $relative
            sha256 = Get-C34LJourneyFixtureSha $entryFull
            bytes = [int64](Get-Item -LiteralPath $entryFull).Length
          })
        }
      }
    }
    foreach ($reparseDirectory in $reparseDirectories) {
      ([IO.DirectoryInfo]::new($reparseDirectory)).Delete()
      Assert-C34LJourneyFixture (-not (Test-Path -LiteralPath $reparseDirectory)) `
        'checker-owned reparse directory unlink was incomplete.'
    }
    [IO.Directory]::Delete($full, $true)
  }
  Assert-C34LJourneyFixture (-not (Test-Path -LiteralPath $full)) `
    'exact checker-owned cleanup target remains.'
  $rows = @($inventory.ToArray() | Sort-Object path)
  $inventoryJson = $rows | ConvertTo-Json -Depth 5 -Compress
  $hashProvider = [Security.Cryptography.SHA256]::Create()
  try {
    $inventorySha = [BitConverter]::ToString(
      $hashProvider.ComputeHash([Text.Encoding]::UTF8.GetBytes($inventoryJson))
    ).Replace('-', '')
  } finally {
    $hashProvider.Dispose()
  }
  [void]$cleanupInventories.Add([pscustomobject][ordered]@{
    root = [IO.Path]::GetFileName($full)
    files = $rows.Count
    inventorySha256 = $inventorySha
  })
}

function New-C34LJourneyFixture([string]$Mode, [switch]$ReparseAdapter) {
  $name = 'c34l-authoritative-capture-fixtures-' +
    [Guid]::NewGuid().ToString('N')
  $relative = 'tmp/' + $name
  $file = Join-Path $root $relative
  $null = New-Item -ItemType Directory -Path $file
  [void]$createdFixtureRoots.Add($file)
  $null = New-Item -ItemType Directory -Path (Join-Path $file 'output')
  $null = New-Item -ItemType Directory -Path (Join-Path $file 'gate-receipts')
  $null = New-Item -ItemType Directory -Path (Join-Path $file 'adapter-source-real')
  $artifactRelative = "$relative/fixture.aab"
  $artifactFile = Join-Path $root $artifactRelative
  [IO.File]::WriteAllText($artifactFile, 'fixture-artifact', $utf8)
  $sealRelative = "$relative/source-seal-manifest.txt"
  $sealFile = Join-Path $root $sealRelative
  [IO.File]::WriteAllText($sealFile, "fixture-source-seal`n", $utf8)
  $aggregateRelative = "$relative/aggregate.json"
  $aggregateFile = Join-Path $root $aggregateRelative
  Write-C34LJourneyFixtureJson $aggregateFile ([pscustomobject][ordered]@{
    ticketId = $ticketId
    candidate = [pscustomobject][ordered]@{
      id = $ticketId; versionName = '1.0.0-r60.76'; versionCode = '2026081376'
    }
  })
  $stateRelative = "$relative/state.json"
  $stateFile = Join-Path $root $stateRelative
  Write-C34LJourneyFixtureJson $stateFile ([pscustomobject][ordered]@{
    ticketId = $ticketId
    candidate = [pscustomobject][ordered]@{
      id = $ticketId; packageName = 'com.moolsocial.app'
      versionName = '1.0.0-r60.76'; versionCode = '2026081376'
    }
    aggregateStatePath = $aggregateRelative
    sourceQualification = [pscustomobject][ordered]@{
      manifestPath = $sealRelative
      manifestSha256 = Get-C34LJourneyFixtureSha $sealFile
      manifestBytes = (Get-Item -LiteralPath $sealFile).Length
    }
    buildResult = [pscustomobject][ordered]@{
      artifactPath = $artifactRelative
      artifactSha256 = Get-C34LJourneyFixtureSha $artifactFile
      artifactBytes = (Get-Item -LiteralPath $artifactFile).Length
    }
  })
  $gateAdapterRelative = "$relative/adapter-source-real/gate-adapter.ps1"
  $gateAdapterFile = Join-Path $root $gateAdapterRelative
  $gateAdapterSource = @'
[CmdletBinding()]
param(
  [string]$JourneyId, [int]$Attempt, [string]$StatePath,
  [string]$ChallengeSha256, [string]$OutputPath, [string]$RepositoryRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$mode='__MODE__'
$utf8=[Text.UTF8Encoding]::new($false)
$stateFile=Join-Path $RepositoryRoot $StatePath
$state=Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
$aggregateFile=Join-Path $RepositoryRoot ([string]$state.aggregateStatePath)
$artifactFile=Join-Path $RepositoryRoot ([string]$state.buildResult.artifactPath)
$shaState=(Get-FileHash -LiteralPath $stateFile -Algorithm SHA256).Hash.ToUpperInvariant()
$shaAggregate=(Get-FileHash -LiteralPath $aggregateFile -Algorithm SHA256).Hash.ToUpperInvariant()
$shaArtifact=(Get-FileHash -LiteralPath $artifactFile -Algorithm SHA256).Hash.ToUpperInvariant()
if($mode -ceq 'missing' -and $JourneyId -ceq 'social'){ return }
$receipt=[ordered]@{
  schemaVersion=1
  receiptContractId='MOOLSOCIAL-C34L-EXECUTABLE-JOURNEY-GATE-RECEIPT-001'
  journeyId=$JourneyId
  ticketId=[string]$state.ticketId
  attempt=$Attempt
  packageName=[string]$state.candidate.packageName
  versionName=[string]$state.candidate.versionName
  versionCode=[string]$state.candidate.versionCode
  challengeSha256=$ChallengeSha256
  preStateSha256=$shaState
  preAggregateSha256=$shaAggregate
  artifactSha256=$shaArtifact
  artifactBytes=[int64](Get-Item -LiteralPath $artifactFile).Length
  gateOutcome='qualified'
  exitCode=0
  producedUtc=[DateTimeOffset]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'",[Globalization.CultureInfo]::InvariantCulture)
}
if($mode -ceq 'challenge' -and $JourneyId -ceq 'social'){
  $receipt.challengeSha256='0'*64
}
if($mode -ceq 'privacy' -and $JourneyId -ceq 'social'){
  $receipt.gateOutcome='https://fixture.invalid'
}
if($mode -ceq 'selfdeclared' -and $JourneyId -ceq 'social'){
  $receipt.passed=$true
}
if($mode -ceq 'schema' -and $JourneyId -ceq 'social'){
  $receipt.unexpected='schema-drift'
}
if($mode -ceq 'stale' -and $JourneyId -ceq 'social'){
  $receipt.producedUtc=[DateTimeOffset]::UtcNow.AddMinutes(-10).ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'",[Globalization.CultureInfo]::InvariantCulture)
}
$target=Join-Path $RepositoryRoot $OutputPath
$json=$receipt|ConvertTo-Json -Depth 20 -Compress
if($mode -ceq 'rawwire' -and $JourneyId -ceq 'social'){
  $wire=[string]$receipt.producedUtc
  $escaped=$wire.Substring(0,$wire.Length-1)+'\u005A'
  $json=$json.Replace('"producedUtc":"'+$wire+'"','"producedUtc":"'+$escaped+'"')
}
if($mode -ceq 'precision' -and $JourneyId -ceq 'social'){
  $wire=[string]$receipt.producedUtc
  $millisecondDigit=$wire.Substring($wire.Length-4,1)
  $escaped=$wire.Substring(0,$wire.Length-4)+'\u003'+$millisecondDigit+
    $wire.Substring($wire.Length-3)
  $json=$json.Replace('"producedUtc":"'+$wire+'"','"producedUtc":"'+$escaped+'"')
}
if($mode -ceq 'duplicate' -and $JourneyId -ceq 'social'){
  $duplicate=',"producedUtc":"'+[string]$receipt.producedUtc+'"}'
  $json=$json.Substring(0,$json.Length-1)+$duplicate
}
[IO.File]::WriteAllText($target,($json+[Environment]::NewLine),$utf8)
$hash=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant()
if($mode -ceq 'wronghash' -and $JourneyId -ceq 'social'){ $hash='0'*64 }
$binding=[pscustomobject][ordered]@{path=$OutputPath;sha256=$hash;bytes=[int64](Get-Item -LiteralPath $target).Length}
$binding|ConvertTo-Json -Compress
if($mode -ceq 'multioutput' -and $JourneyId -ceq 'social'){
  $binding|ConvertTo-Json -Compress
}
'@
  $gateAdapterSource = $gateAdapterSource.Replace('__MODE__', $Mode)
  [IO.File]::WriteAllText($gateAdapterFile, $gateAdapterSource, $utf8)
  if ($ReparseAdapter) {
    $aliasFile = Join-Path $file 'adapter-source-alias'
    $null = New-Item -ItemType Junction -Path $aliasFile `
      -Target (Join-Path $file 'adapter-source-real')
    $gateAdapterRelative = "$relative/adapter-source-alias/gate-adapter.ps1"
  }
  return [pscustomobject]@{
    RootRelative = $relative
    StateRelative = $stateRelative
    GateAdapterRelative = $gateAdapterRelative
    OutputRelative =
      "$relative/output/authoritative-journey-source-receipt.json"
  }
}

function Invoke-C34LJourneyFixture($Fixture) {
  return @(& $adapterFile -FixtureMode -FixtureRunRoot $Fixture.RootRelative `
    -FixtureGateAdapterPath $Fixture.GateAdapterRelative -Attempt 1 `
    -StatePath $Fixture.StateRelative -ChallengeSha256 $challenge `
    -OutputPath $Fixture.OutputRelative -RepositoryRoot $root)
}

function Assert-C34LJourneyFixtureReject(
  [string]$Mode,
  [string]$Expected,
  [switch]$ReparseAdapter
) {
  $fixture = New-C34LJourneyFixture $Mode -ReparseAdapter:$ReparseAdapter
  $rejected = $false
  try { $null = Invoke-C34LJourneyFixture $fixture } catch {
    $rejected = [string]$_.Exception.Message -like "*$Expected*"
  }
  Assert-C34LJourneyFixture $rejected `
    "$Mode did not fail closed with the expected sanitized class."
}

try {
Assert-C34LJourneyFixture (Test-Path -LiteralPath $adapterFile -PathType Leaf) `
  'authoritative journey adapter is missing.'
$parameterNames = @((Get-Command $adapterFile).Parameters.Keys)
Assert-C34LJourneyFixture (
  @($parameterNames | Where-Object { $_ -match '(?i)(pass|success|count)' }).Count -eq 0
) 'production adapter exposes a pass, success or count input.'

$productionRejected = $false
try {
  $null = & $adapterFile -Attempt 1 `
    -StatePath 'config/successor-aab-regression-hard-gate-state-c34l.json' `
    -ChallengeSha256 $challenge `
    -OutputPath 'artifacts/quality/uaw-c34l-r60-76-consolidated-release-transaction-evidence-preparation-20260817-01/captures/attempt-1/journey/authoritative-source-receipt.json' `
    -RepositoryRoot $root
} catch {
  $message = [string]$_.Exception.Message
  $productionRejected = $true
  foreach ($journeyId in @(
    'publicGuest', 'protectedGateway', 'supportedAuthentication', 'social',
    'wholeApp', 'c33gBlocker'
  )) {
    if ($message -notlike
      "*MOOLSOCIAL-C34L-JOURNEY-GATE-OUTPUT-ADAPTER-001:$journeyId*") {
      $productionRejected = $false
    }
  }
}
Assert-C34LJourneyFixture $productionRejected `
  'production did not fail closed with all exact missing adapter IDs.'

$valid = New-C34LJourneyFixture 'valid'
$validOutput = @(Invoke-C34LJourneyFixture $valid)
Assert-C34LJourneyFixture ($validOutput.Count -eq 1) `
  'valid fixture did not emit one binding.'
$validBinding = [string]$validOutput[0] | ConvertFrom-Json
$validFile = Join-Path $root ([string]$validBinding.path)
Assert-C34LJourneyFixture (
  (Get-C34LJourneyFixtureSha $validFile) -ceq [string]$validBinding.sha256 -and
  (Get-Item -LiteralPath $validFile).Length -eq [int64]$validBinding.bytes
) 'valid fixture receipt binding changed.'
$validReceipt = Get-Content -LiteralPath $validFile -Raw | ConvertFrom-Json
Assert-C34LJourneyFixture (
  @($validReceipt.gates).Count -eq 6 -and
  @($validReceipt.gates | Where-Object { -not [bool]$_.passed }).Count -eq 0
) 'valid fixture did not derive six qualified rows.'

$replayRejected = $false
try { $null = Invoke-C34LJourneyFixture $valid } catch {
  $replayRejected = [string]$_.Exception.Message -like '*immutable raw journey receipt already exists*'
}
Assert-C34LJourneyFixture $replayRejected `
  'same-challenge same-output replay did not fail closed.'

Assert-C34LJourneyFixtureReject 'wronghash' 'gate receipt hash or bytes changed at social'
Assert-C34LJourneyFixtureReject 'selfdeclared' 'property count changed'
Assert-C34LJourneyFixtureReject 'missing' 'missing executable journey gate receipt at social'
Assert-C34LJourneyFixtureReject 'multioutput' 'missing executable journey gate receipt at social'
Assert-C34LJourneyFixtureReject 'challenge' 'did not derive a qualified outcome at social'
Assert-C34LJourneyFixtureReject 'privacy' 'contains private, secret, URL, exception or raw-device material'
Assert-C34LJourneyFixtureReject 'schema' 'property count changed'
Assert-C34LJourneyFixtureReject 'rawwire' 'must have one exact raw .fffZ UTC token'
Assert-C34LJourneyFixtureReject 'precision' 'must have one exact raw .fffZ UTC token'
Assert-C34LJourneyFixtureReject 'duplicate' 'must have one exact raw .fffZ UTC token'
Assert-C34LJourneyFixtureReject 'stale' 'did not derive a qualified outcome at social'
Assert-C34LJourneyFixtureReject 'valid' 'contains a reparse point' -ReparseAdapter

$fileRootName = 'c34l-authoritative-capture-fixtures-' +
  [Guid]::NewGuid().ToString('N')
$fileRootRelative = 'tmp/' + $fileRootName
[IO.File]::WriteAllText((Join-Path $root $fileRootRelative), 'not-a-directory', $utf8)
[void]$createdFixtureRoots.Add((Join-Path $root $fileRootRelative))
$fileRootRejected = $false
try {
  $null = & $adapterFile -FixtureMode -FixtureRunRoot $fileRootRelative `
    -FixtureGateAdapterPath "$fileRootRelative/gate-adapter.ps1" -Attempt 1 `
    -StatePath "$fileRootRelative/state.json" -ChallengeSha256 $challenge `
    -OutputPath "$fileRootRelative/output/authoritative-journey-source-receipt.json" `
    -RepositoryRoot $root
} catch {
  $fileRootRejected = [string]$_.Exception.Message -like
    '*fixture run root is not a directory*'
}
Assert-C34LJourneyFixture $fileRootRejected `
  'file-as-fixture-root did not fail closed.'

$directoryStateName = 'c34l-authoritative-capture-fixtures-' +
  [Guid]::NewGuid().ToString('N')
$directoryStateRelative = 'tmp/' + $directoryStateName
$directoryStateFile = Join-Path $root $directoryStateRelative
$null = New-Item -ItemType Directory -Path $directoryStateFile
[void]$createdFixtureRoots.Add($directoryStateFile)
$null = New-Item -ItemType Directory -Path (Join-Path $directoryStateFile 'output')
$null = New-Item -ItemType Directory -Path (Join-Path $directoryStateFile 'state.json')
$dummyGateRelative = "$directoryStateRelative/gate-adapter.ps1"
[IO.File]::WriteAllText((Join-Path $root $dummyGateRelative), 'param()', $utf8)
$directoryStateRejected = $false
try {
  $null = & $adapterFile -FixtureMode -FixtureRunRoot $directoryStateRelative `
    -FixtureGateAdapterPath $dummyGateRelative -Attempt 1 `
    -StatePath "$directoryStateRelative/state.json" -ChallengeSha256 $challenge `
    -OutputPath "$directoryStateRelative/output/authoritative-journey-source-receipt.json" `
    -RepositoryRoot $root
} catch {
  $directoryStateRejected = [string]$_.Exception.Message -like
    '*detailed candidate state is missing*'
}
Assert-C34LJourneyFixture $directoryStateRejected `
  'directory-as-state-leaf did not fail closed.'
} finally {
  for ($index = $createdFixtureRoots.Count - 1; $index -ge 0; $index--) {
    Remove-C34LJourneyFixtureRoot $createdFixtureRoots[$index]
  }
}

$newResidue = @(Get-ChildItem -LiteralPath $tmpRoot -Force | Where-Object {
  $_.Name -cmatch $fixtureNamePattern
})
Assert-C34LJourneyFixture ($newResidue.Count -eq 0) `
  'checker-owned fixture residue remains after finally cleanup.'
Assert-C34LJourneyFixture (
  $cleanupInventories.Count -eq $createdFixtureRoots.Count -and
  $createdFixtureRoots.Count -eq 15
) 'cleanup inventory cardinality changed.'
Write-Output (
  'C34L authoritative journey source fixtures passed: ' +
  'productionMissingAdapters=6; derivedRows=6; negatives=15; ' +
  'cleanupVerified=true; newResidue=0; ' +
  'externalActions=0; browserActions=0; deviceActions=0; privateValues=0.'
)
