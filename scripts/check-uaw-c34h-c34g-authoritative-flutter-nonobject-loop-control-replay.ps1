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

function Assert-C34HReplayLoopControl {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C34HReplay authoritative Flutter loop-control gate rejected: $Message"
  }
}

function Resolve-C34HReplayFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C34HReplayLoopControl -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

$ticketId = 'UAW-C34H-R60-72-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE'
$qualifiedTicketId = 'UAW-C34G-R60-71-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE'
$runnerPath = Resolve-C34HReplayFile `
  -Path 'tmp/run-c30t-authoritative-flutter-manifest-audit.ps1' `
  -Label 'authoritative Flutter audit'
$parserPath = Resolve-C34HReplayFile `
  -Path 'scripts/c30y-flutter-json-event-shape-parser.ps1' `
  -Label 'Flutter JSON event-shape parser'
$ticketPath = Resolve-C34HReplayFile `
  -Path 'config/uaw-c34h-r60-72-authentication-no-regression-play-oppo-acceptance-ticket.json' `
  -Label 'C34H ticket'
$qualifiedTicketPath = Resolve-C34HReplayFile `
  -Path 'config/uaw-c34g-r60-71-authentication-no-regression-play-oppo-acceptance-ticket.json' `
  -Label 'qualified C34G ticket'
$scopePathResolved = Resolve-C34HReplayFile -Path $ScopePath -Label 'MVP scope state'

foreach ($owner in @($runnerPath, $parserPath, $ticketPath, $qualifiedTicketPath, $scopePathResolved)) {
  if ([IO.Path]::GetExtension($owner) -cne '.ps1') { continue }
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $owner, [ref]$tokens, [ref]$errors
  )
  Assert-C34HReplayLoopControl -Condition (@($errors).Count -eq 0) `
    -Message "PowerShell parser rejected: $owner"
}

$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
$qualifiedTicket = Get-Content -Raw -LiteralPath $qualifiedTicketPath | ConvertFrom-Json
$scope = Get-Content -Raw -LiteralPath $scopePathResolved | ConvertFrom-Json
Assert-C34HReplayLoopControl -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  @($ticket.robustnessAndReuseAssessment.newScreens).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newRoutes).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newBackendOwners).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newNecessarySharedOwners) -contains
    'scripts/check-uaw-c34h-c34g-authoritative-flutter-nonobject-loop-control-replay.ps1' -and
  (Get-FileHash -Algorithm SHA256 -LiteralPath $qualifiedTicketPath).Hash -ceq
    '9C0AF2BE02014179F9D6D2A85D397633D85BB65E933292F6727C324AECB84669' -and
  [string]$qualifiedTicket.ticketId -ceq $qualifiedTicketId -and
  [string]$qualifiedTicket.classification -ceq 'mvp_required' -and
  [string]$scope.ticket.id -ceq $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.currentTicketId -ceq $ticketId -and
  [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq $ticketId -and
  [string]$scope.priorC34GTicket.id -ceq $qualifiedTicketId -and
  [string]$scope.preTicketSelectionCheckpoint.priorC34GSelectedTicketAssessment.ticketId -ceq
    $qualifiedTicketId
) -Message 'C34H selection or immutable qualified C34G ticket/reuse binding changed.'

$runner = Get-Content -Raw -LiteralPath $runnerPath
Assert-C34HReplayLoopControl -Condition (
  $runner.IndexOf(
    ':eventLine foreach ($rawLine in $rawLines) {',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'the authoritative audit lacks the explicit outer event-loop label.'
$labeledContinueMatches = @(
  [regex]::Matches($runner, '(?m)^\s+continue eventLine\s*$')
)
Assert-C34HReplayLoopControl -Condition ($labeledContinueMatches.Count -eq 3) `
  -Message 'the authoritative audit must contain exactly three labeled non-object skips.'
foreach ($kind in @('blank', 'non_json', 'json_null')) {
  $pattern = "(?ms)'$([regex]::Escape($kind))'\s*\{.*?continue eventLine\s*\}"
  Assert-C34HReplayLoopControl -Condition ([regex]::IsMatch($runner, $pattern)) `
    -Message "$kind does not skip the explicit outer event loop."
}
Assert-C34HReplayLoopControl -Condition (
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
      throw 'C34H successor replay probe received an unsupported classification.'
    }
  }
  $eventType = Get-C30YFlutterJsonEventType -Event $event
  if ([string]::IsNullOrWhiteSpace($eventType)) {
    $untyped++
  } else {
    $typed++
  }
}
Assert-C34HReplayLoopControl -Condition (
  $blank -eq 2 -and
  $nonJson -eq 1 -and
  $jsonNull -eq 1 -and
  $object -eq 2 -and
  $typed -eq 1 -and
  $untyped -eq 1
) -Message 'the executable non-object, typed or untyped loop-control probe failed.'

$scopeGate = Resolve-C34HReplayFile `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate -StatePath $scopePathResolved -CandidateId $ticketId `
  -RequireExecutionAuthorized -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C34HReplayFile `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression-memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root | Out-Null

Write-Output (
  'C34H C34G authoritative Flutter loop-control replay gate passed: ' +
  'blank=2; nonJson=1; jsonNull=1; object=2; typed=1; untyped=1; ' +
  'valuesExposed=false; buildPlayOppoExternal=false.'
)
