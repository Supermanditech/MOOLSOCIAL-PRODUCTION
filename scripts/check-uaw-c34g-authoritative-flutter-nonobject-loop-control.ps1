[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$ScopePath = 'config/mvp-scope-gate-state.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C34GLoopControl {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34G authoritative Flutter loop-control gate rejected: $Message"
  }
}

function Resolve-C34GFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C34GLoopControl -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

$ticketId = 'UAW-C34G-R60-71-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE'
$runnerPath = Resolve-C34GFile `
  -Path 'tmp/run-c30t-authoritative-flutter-manifest-audit.ps1' `
  -Label 'authoritative Flutter audit'
$parserPath = Resolve-C34GFile `
  -Path 'scripts/c30y-flutter-json-event-shape-parser.ps1' `
  -Label 'Flutter JSON event-shape parser'
$ticketPath = Resolve-C34GFile `
  -Path 'config/uaw-c34g-r60-71-authentication-no-regression-play-oppo-acceptance-ticket.json' `
  -Label 'C34G ticket'
$scopePathResolved = Resolve-C34GFile -Path $ScopePath -Label 'MVP scope state'

foreach ($owner in @($runnerPath, $parserPath, $ticketPath, $scopePathResolved)) {
  if ([IO.Path]::GetExtension($owner) -cne '.ps1') { continue }
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $owner, [ref]$tokens, [ref]$errors
  )
  Assert-C34GLoopControl -Condition (@($errors).Count -eq 0) `
    -Message "PowerShell parser rejected: $owner"
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePathResolved | ConvertFrom-Json
Assert-C34GLoopControl -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  @($ticket.robustnessAndReuseAssessment.newScreens).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newRoutes).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newBackendOwners).Count -eq 0 -and
  [string]$scope.ticket.id -ceq $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq $ticketId
) -Message 'ticket identity, MVP classification, reuse assessment or scope selection changed.'

$runner = Get-Content -Raw -LiteralPath $runnerPath
Assert-C34GLoopControl -Condition (
  $runner.IndexOf(
    ':eventLine foreach ($rawLine in $rawLines) {',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'the authoritative audit lacks the explicit outer event-loop label.'
$labeledContinueMatches = @(
  [regex]::Matches($runner, '(?m)^\s+continue eventLine\s*$')
)
Assert-C34GLoopControl -Condition ($labeledContinueMatches.Count -eq 3) `
  -Message 'the authoritative audit must contain exactly three labeled non-object skips.'
foreach ($kind in @('blank', 'non_json', 'json_null')) {
  $pattern = "(?ms)'$([regex]::Escape($kind))'\s*\{.*?continue eventLine\s*\}"
  Assert-C34GLoopControl -Condition ([regex]::IsMatch($runner, $pattern)) `
    -Message "$kind does not skip the explicit outer event loop."
}
Assert-C34GLoopControl -Condition (
  [regex]::IsMatch(
    $runner,
    "(?ms)'object'\s*\{\s*\`$event\s*=\s*\`$classification\.Event\s*\}"
  ) -and
  $runner.IndexOf(
    '$eventType = Get-C30YFlutterJsonEventType -Event $event',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'object assignment or event access binding changed.'

. $parserPath
$blank = 0
$nonJson = 0
$jsonNull = 0
$object = 0
$typed = 0
$untyped = 0
$probeLines = @(
  $null,
  '   ',
  'not-json',
  'null',
  '{"protocolVersion":"0.1.1"}',
  '{"type":"testStart","test":{"id":1,"name":"probe"}}'
)
:eventLine foreach ($rawLine in $probeLines) {
  $classification = ConvertTo-C30YFlutterJsonLineClassification -RawLine $rawLine
  switch ([string]$classification.Kind) {
    'blank' {
      $blank++
      continue eventLine
    }
    'non_json' {
      $nonJson++
      continue eventLine
    }
    'json_null' {
      $jsonNull++
      continue eventLine
    }
    'object' {
      $event = $classification.Event
      $object++
    }
    default {
      throw 'C34G loop-control probe received an unsupported classification.'
    }
  }
  $eventType = Get-C30YFlutterJsonEventType -Event $event
  if ([string]::IsNullOrWhiteSpace($eventType)) {
    $untyped++
  } else {
    $typed++
  }
}
Assert-C34GLoopControl -Condition (
  $blank -eq 2 -and
  $nonJson -eq 1 -and
  $jsonNull -eq 1 -and
  $object -eq 2 -and
  $typed -eq 1 -and
  $untyped -eq 1
) -Message 'the executable non-object, typed or untyped loop-control probe failed.'

$scopeGate = Resolve-C34GFile `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate -StatePath $scopePathResolved -CandidateId $ticketId `
  -RequireExecutionAuthorized -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C34GFile `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression-memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root | Out-Null

Write-Output (
  'C34G authoritative Flutter loop-control gate passed: ' +
  'blank=2; nonJson=1; jsonNull=1; object=2; typed=1; untyped=1; ' +
  'valuesExposed=false; buildPlayOppoExternal=false.'
)
