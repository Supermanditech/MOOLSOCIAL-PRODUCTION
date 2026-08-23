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

function Assert-C33LFix3 {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) {
    throw "C33L FIX3 authoritative Flutter classification gate rejected: $Message"
  }
}

function Resolve-C33LFix3File {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C33LFix3 -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $resolved
}

function Get-C33LFix3GenericSuccessorMode {
  param(
    [Parameter(Mandatory)][object]$Scope,
    [Parameter(Mandatory)][string]$SelectedTicketSha256,
    [Parameter(Mandatory)][bool]$Fix3EvidenceExists
  )
  $checkpoint = $Scope.preTicketSelectionCheckpoint
  $selected = $checkpoint.selectedTicketAssessment
  $currentId = [string]$checkpoint.currentTicketId
  if (
    $currentId -cne [string]$Scope.ticket.id -or
    $currentId -cne [string]$selected.ticketId
  ) {
    throw 'C33L FIX3 generic successor current and selected identities differ.'
  }
  if ([string]$selected.manifestSha256 -cne $SelectedTicketSha256) {
    throw 'C33L FIX3 generic successor selected ticket hash changed.'
  }
  $qualifiedFix3 = $checkpoint.priorC33LFix3SelectedTicketAssessment
  if (
    [string]$qualifiedFix3.ticketId -cne
      'UAW-C33L-FIX3-AUTHORITATIVE-FLUTTER-NULL-EVENT-CLASSIFICATION' -or
    [string]$qualifiedFix3.manifestPath -cne
      'config/uaw-c33l-fix3-authoritative-flutter-null-event-classification-ticket.json' -or
    [string]$qualifiedFix3.manifestSha256 -cne
      '60FBA619B2DB3C71FF66208D4B8FA175CD13FC8A9344BCE85E9879F184C9B757' -or
    [string]$qualifiedFix3.implementationState -cne
      'runner_null_and_blank_classification_qualified_dual_host_behavioral_gate_passed_parent_reselection_and_new_source_seal_required' -or
    [string]$qualifiedFix3.evidencePath -cne
      'docs/quality/UAW-C33L-FIX3-AUTHORITATIVE-FLUTTER-NULL-EVENT-CLASSIFICATION-QUALIFICATION-20260816.md' -or
    -not $Fix3EvidenceExists
  ) {
    throw 'C33L FIX3 generic successor qualified FIX3 binding changed.'
  }
  return 'qualified_generic_successor_replay'
}

$ticketId = 'UAW-C33L-FIX3-AUTHORITATIVE-FLUTTER-NULL-EVENT-CLASSIFICATION'
$parentTicketId = 'UAW-C33L-R60-50-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE'
$ticketPath = Resolve-C33LFix3File `
  -Path 'config/uaw-c33l-fix3-authoritative-flutter-null-event-classification-ticket.json' `
  -Label 'FIX3 ticket'
Assert-C33LFix3 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $ticketPath).Hash -ceq
    '60FBA619B2DB3C71FF66208D4B8FA175CD13FC8A9344BCE85E9879F184C9B757'
) -Message 'FIX3 ticket bytes changed.'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C33LFix3 -Condition (
  [string]$ticket.ticketId -ceq $ticketId -and
  [string]$ticket.parentTicketId -ceq $parentTicketId -and
  [string]$ticket.findingId -ceq
    'REG-20260816-2546-C33L-AUTHORITATIVE-FLUTTER-RUNNER-NULL-EVENT-BINDING-CRASH' -and
  [string]$ticket.classification -ceq 'mvp_required' -and
  [bool]$ticket.robustnessAndReuseAssessment.reuseInventoryComplete -and
  [bool]$ticket.robustnessAndReuseAssessment.duplicateSearchComplete -and
  @($ticket.robustnessAndReuseAssessment.newScreens).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newRoutes).Count -eq 0 -and
  @($ticket.robustnessAndReuseAssessment.newBackendOwners).Count -eq 0 -and
  [bool]$ticket.authority.sourceTestAndGateRepairAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX3 identity, scope assessment or authority changed.'

$parserPath = Resolve-C33LFix3File `
  -Path 'scripts/c30y-flutter-json-event-shape-parser.ps1' `
  -Label 'Flutter event-shape parser'
$runnerPath = Resolve-C33LFix3File `
  -Path 'tmp/run-c30t-authoritative-flutter-manifest-audit.ps1' `
  -Label 'authoritative Flutter runner'
foreach ($owner in @($parserPath, $runnerPath)) {
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $owner, [ref]$tokens, [ref]$errors
  )
  Assert-C33LFix3 -Condition (@($errors).Count -eq 0) `
    -Message "PowerShell parser rejected: $owner"
}

$runner = Get-Content -Raw -LiteralPath $runnerPath
foreach ($required in @(
  'ConvertTo-C30YFlutterJsonLineClassification -RawLine $rawLine',
  "'blank' {",
  '$blankRawLines++',
  "'json_null' {",
  '$jsonNullObjects++',
  'blank_raw_lines=$blankRawLines',
  'json_null_objects=$jsonNullObjects',
  '$blankRawLines -ne 0',
  '$jsonNullObjects -ne 0'
)) {
  Assert-C33LFix3 -Condition (
    $runner.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "runner classification binding is missing: $required"
}
foreach ($forbidden in @('Write-Output $rawLine', 'Write-Host $rawLine', 'Write-Output $event', 'Write-Host $event')) {
  Assert-C33LFix3 -Condition (
    $runner.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -lt 0
  ) -Message "runner exposes a raw event value: $forbidden"
}

. $parserPath
$blankNull = ConvertTo-C30YFlutterJsonLineClassification -RawLine $null
$blankWhitespace = ConvertTo-C30YFlutterJsonLineClassification -RawLine '   '
$jsonNull = ConvertTo-C30YFlutterJsonLineClassification -RawLine 'null'
$nonJson = ConvertTo-C30YFlutterJsonLineClassification -RawLine 'not-json'
$typed = ConvertTo-C30YFlutterJsonLineClassification -RawLine '{"type":"testStart","private":"not_output"}'
$untyped = ConvertTo-C30YFlutterJsonLineClassification -RawLine '{"protocolVersion":"0.1.1"}'
Assert-C33LFix3 -Condition (
  [string]$blankNull.Kind -ceq 'blank' -and
  [string]$blankWhitespace.Kind -ceq 'blank' -and
  [string]$jsonNull.Kind -ceq 'json_null' -and
  [string]$nonJson.Kind -ceq 'non_json' -and
  [string]$typed.Kind -ceq 'object' -and
  (Get-C30YFlutterJsonEventType -Event $typed.Event) -ceq 'testStart' -and
  [string]$untyped.Kind -ceq 'object' -and
  $null -eq (Get-C30YFlutterJsonEventType -Event $untyped.Event) -and
  (Get-C30YFlutterJsonEventPropertyNames -Event $untyped.Event) -ceq 'protocolVersion'
) -Message 'blank, JSON null, non-JSON, typed or untyped behavioral classification changed.'

$scopePathResolved = Resolve-C33LFix3File -Path $ScopePath -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePathResolved | ConvertFrom-Json
$activeTicketId = [string]$scope.ticket.id
Assert-C33LFix3 -Condition (
  $activeTicketId -ceq [string]$scope.preTicketSelectionCheckpoint.currentTicketId -and
  $activeTicketId -ceq [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId
) -Message 'active, current and selected MVP ticket identities differ.'
$selectionMode = if ($activeTicketId -ceq $ticketId) {
  'fix3_child_active'
} elseif ($activeTicketId -ceq $parentTicketId) {
  $qualifiedFix3 = $scope.preTicketSelectionCheckpoint.priorC33LFix3SelectedTicketAssessment
  Assert-C33LFix3 -Condition (
    $null -ne $qualifiedFix3 -and
    [string]$qualifiedFix3.ticketId -ceq $ticketId -and
    [string]$qualifiedFix3.manifestPath -ceq
      'config/uaw-c33l-fix3-authoritative-flutter-null-event-classification-ticket.json' -and
    [string]$qualifiedFix3.manifestSha256 -ceq
      '60FBA619B2DB3C71FF66208D4B8FA175CD13FC8A9344BCE85E9879F184C9B757' -and
    [string]$qualifiedFix3.implementationState -ceq
      'runner_null_and_blank_classification_qualified_dual_host_behavioral_gate_passed_parent_reselection_and_new_source_seal_required' -and
    [string]$qualifiedFix3.evidencePath -ceq
      'docs/quality/UAW-C33L-FIX3-AUTHORITATIVE-FLUTTER-NULL-EVENT-CLASSIFICATION-QUALIFICATION-20260816.md'
  ) -Message 'parent replay lacks the exact qualified FIX3 assessment.'
  'c33l_parent_replay'
} else {
  $selectedManifest = Resolve-C33LFix3File `
    -Path ([string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.manifestPath) `
    -Label 'selected successor ticket'
  $selectedManifestSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $selectedManifest).Hash
  $fix3Evidence = Resolve-C33LFix3File `
    -Path 'docs/quality/UAW-C33L-FIX3-AUTHORITATIVE-FLUTTER-NULL-EVENT-CLASSIFICATION-QUALIFICATION-20260816.md' `
    -Label 'qualified FIX3 evidence'
  Get-C33LFix3GenericSuccessorMode `
    -Scope $scope `
    -SelectedTicketSha256 $selectedManifestSha256 `
    -Fix3EvidenceExists (Test-Path -LiteralPath $fix3Evidence -PathType Leaf)
}
$scopeGate = Resolve-C33LFix3File `
  -Path 'scripts/check-mvp-scope-gate-state.ps1' `
  -Label 'MVP scope gate'
& $scopeGate -StatePath $scopePathResolved -CandidateId $activeTicketId `
  -RequireExecutionAuthorized -RepositoryRoot $root | Out-Null
$memoryGate = Resolve-C33LFix3File `
  -Path 'scripts/check-codex-development-regression-memory.ps1' `
  -Label 'regression-memory gate'
& $memoryGate -Phase implementation -BuildMode none -RepositoryRoot $root | Out-Null

Write-Output (
  'C33L FIX3 authoritative Flutter classification gate passed: ' +
  'blank=true; jsonNull=true; nonJson=true; typed=true; untyped=true; ' +
  "selectionMode=$selectionMode; valuesExposed=false; buildPlayOppoExternal=false."
)
