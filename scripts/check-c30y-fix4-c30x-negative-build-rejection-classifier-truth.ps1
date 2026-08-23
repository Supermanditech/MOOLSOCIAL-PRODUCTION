[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$StatePath = 'config/successor-aab-regression-hard-gate-state-c30x.json',
  [Parameter(Mandatory)]
  [ValidateSet('fix4_scope', 'candidate_incomplete')]
  [string]$ExpectedContext,
  [Parameter(Mandatory)][string]$DiagnosticEvidencePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C30YFix4 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30Y FIX4 negative classifier rejected: $Message"
  }
}

function Resolve-C30YFix4File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $candidate = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  }
  else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C30YFix4 -Condition (
    $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $candidate -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository."
  return $candidate
}

function Resolve-C30YFix4NewEvidenceFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  $candidate = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  }
  else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  $evidenceRoot = [IO.Path]::GetFullPath((Join-Path $root `
    'artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01'))
  Assert-C30YFix4 -Condition (
    $candidate.StartsWith(
      $evidenceRoot + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath (Split-Path -Parent $candidate) -PathType Container) -and
    -not (Test-Path -LiteralPath $candidate)
  ) -Message "$Label is occupied, missing its exact parent or escaped the evidence root."
  return $candidate
}

function Assert-C30YFix4ManifestCurrent {
  param([Parameter(Mandatory)][object]$State)
  $manifest = Resolve-C30YFix4File `
    -Path ([string]$State.sourceQualification.manifestPath) `
    -Label 'current source manifest'
  Assert-C30YFix4 -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $manifest).Hash -ceq
      [string]$State.sourceQualification.manifestSha256
  ) -Message 'source manifest file seal changed.'
  $lines = @(Get-Content -LiteralPath $manifest)
  Assert-C30YFix4 -Condition (
    $lines.Count -eq [int]$State.sourceQualification.fileCount
  ) -Message 'source manifest file count changed.'
  foreach ($line in $lines) {
    Assert-C30YFix4 -Condition (
      [string]$line -cmatch '^([A-F0-9]{64})  (.+)$'
    ) -Message 'source manifest row shape changed.'
    $owner = Resolve-C30YFix4File -Path $Matches[2] -Label "manifest owner $($Matches[2])"
    Assert-C30YFix4 -Condition (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq $Matches[1]
    ) -Message "source manifest owner changed: $($Matches[2])"
  }
  return $manifest
}

$ticketPath = Resolve-C30YFix4File `
  -Path 'config/uaw-c30y-fix4-c30x-negative-build-rejection-classifier-truth-ticket.json' `
  -Label 'FIX4 ticket'
$ticket = Get-Content -Raw -LiteralPath $ticketPath | ConvertFrom-Json
Assert-C30YFix4 -Condition (
  [string]$ticket.ticketId -ceq
    'UAW-C30Y-FIX4-C30X-NEGATIVE-BUILD-REJECTION-CLASSIFIER-TRUTH' -and
  [bool]$ticket.authority.testAndGateWriteAuthorized -and
  -not [bool]$ticket.authority.buildAuthorized -and
  -not [bool]$ticket.authority.uploadAuthorized -and
  -not [bool]$ticket.authority.deviceMutationAuthorized -and
  -not [bool]$ticket.authority.externalServiceWriteAuthorized -and
  -not [bool]$ticket.authority.secretValueAccessAuthorized
) -Message 'FIX4 ticket identity or authority boundary changed.'

$gatePath = Resolve-C30YFix4File `
  -Path 'scripts/check-successor-aab-regression-hard-gate-c30x.ps1' `
  -Label 'C30X gate'
$gateSource = Get-Content -Raw -LiteralPath $gatePath
Assert-C30YFix4 -Condition (
  $gateSource.IndexOf(
    'throw "C30X successor AAB hard gate rejected: $Message"',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $gateSource.IndexOf(
    ') -Message ''candidate identity, authority or all-regression source qualification is incomplete.''',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $gateSource.IndexOf(
    ') -Message ''C30X preparation or exact C30Y candidate scope changed.''',
    [StringComparison]::Ordinal
  ) -ge 0
) -Message 'exact C30X rejection owner or expected context reason changed.'

$scopePath = Resolve-C30YFix4File `
  -Path 'config/mvp-scope-gate-state.json' `
  -Label 'MVP scope state'
$scope = Get-Content -Raw -LiteralPath $scopePath | ConvertFrom-Json
$expectedReasonPattern = if ($ExpectedContext -ceq 'fix4_scope') {
  Assert-C30YFix4 -Condition (
    [string]$scope.ticket.id -ceq
      'UAW-C30Y-FIX4-C30X-NEGATIVE-BUILD-REJECTION-CLASSIFIER-TRUTH' -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
      'UAW-C30Y-FIX4-C30X-NEGATIVE-BUILD-REJECTION-CLASSIFIER-TRUTH'
  ) -Message 'fix4_scope classification requires FIX4 to be selected.'
  'C30X preparation or exact C30Y candidate scope changed\.'
}
else {
  Assert-C30YFix4 -Condition (
    [string]$scope.ticket.id -ceq
      'UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE' -and
    [string]$scope.preTicketSelectionCheckpoint.selectedTicketAssessment.ticketId -ceq
      'UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
  ) -Message 'candidate_incomplete classification requires C30Y to be selected.'
  'candidate identity, authority or all-regression source qualification is\s+incomplete\.'
}

$stateFile = Resolve-C30YFix4File -Path $StatePath -Label 'C30X state'
$stateBefore = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$aggregateFile = Resolve-C30YFix4File `
  -Path ([string]$stateBefore.aggregateStatePath) `
  -Label 'C30X aggregate'
$stateHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $stateFile).Hash
$aggregateHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $aggregateFile).Hash
$manifestFile = Assert-C30YFix4ManifestCurrent -State $stateBefore
$manifestHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestFile).Hash

$aggregateBefore = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
Assert-C30YFix4 -Condition (
  -not [bool]$stateBefore.authority.buildAuthorized -and
  [string]$stateBefore.buildAuthorization -ceq 'not_available' -and
  [int]$stateBefore.buildResult.buildCount -eq 0 -and
  [int]$stateBefore.playResult.uploadCount -eq 0 -and
  [int]$stateBefore.installResult.installCount -eq 0 -and
  -not [bool]$aggregateBefore.authority.buildAuthorized -and
  [int]$aggregateBefore.candidate.buildCount -eq 0 -and
  [int]$aggregateBefore.candidate.uploadCount -eq 0 -and
  [int]$aggregateBefore.candidate.installCount -eq 0
) -Message 'negative probe requires no build authority and zero release actions.'

$pwsh = Get-Command pwsh -ErrorAction Stop
$priorErrorPreference = $ErrorActionPreference
try {
  $ErrorActionPreference = 'Continue'
  $output = @(& $pwsh.Source `
    -NoLogo `
    -NoProfile `
    -NonInteractive `
    -ExecutionPolicy Bypass `
    -File $gatePath `
    -Phase build `
    -StatePath $stateFile `
    -RepositoryRoot $root 2>&1)
  $exitCode = $LASTEXITCODE
}
finally {
  $ErrorActionPreference = $priorErrorPreference
}
$text = $output | Out-String
$ansiPattern = [string][char]27 + '\[[0-?]*[ -/]*[@-~]'
$plainText = [regex]::Replace($text, $ansiPattern, '')
$semanticText = [regex]::Replace($plainText, '(?m)^\s*\|\s?', '')
$diagnosticFile = Resolve-C30YFix4NewEvidenceFile `
  -Path $DiagnosticEvidencePath `
  -Label 'child C30X diagnostic evidence'
[IO.File]::WriteAllLines(
  $diagnosticFile,
  @(
    "nativeExitCode=$exitCode",
    'normalizedChildTextBegin',
    $plainText.TrimEnd(),
    'normalizedChildTextEnd',
    'semanticChildTextBegin',
    $semanticText.TrimEnd(),
    'semanticChildTextEnd'
  ),
  [Text.UTF8Encoding]::new($false)
)
Assert-C30YFix4 -Condition (
  $exitCode -ne 0 -and
  $semanticText.IndexOf(
    'C30X successor AAB hard gate rejected:',
    [StringComparison]::Ordinal
  ) -ge 0 -and
  $semanticText -match $expectedReasonPattern
) -Message "C30X did not emit the exact expected $ExpectedContext rejection."

$stateAfter = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
$aggregateAfter = Get-Content -Raw -LiteralPath $aggregateFile | ConvertFrom-Json
Assert-C30YFix4 -Condition (
  (Get-FileHash -Algorithm SHA256 -LiteralPath $stateFile).Hash -ceq $stateHashBefore -and
  (Get-FileHash -Algorithm SHA256 -LiteralPath $aggregateFile).Hash -ceq $aggregateHashBefore -and
  (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestFile).Hash -ceq $manifestHashBefore -and
  [int]$stateAfter.buildResult.buildCount -eq 0 -and
  [int]$stateAfter.playResult.uploadCount -eq 0 -and
  [int]$stateAfter.installResult.installCount -eq 0 -and
  [int]$aggregateAfter.candidate.buildCount -eq 0 -and
  [int]$aggregateAfter.candidate.uploadCount -eq 0 -and
  [int]$aggregateAfter.candidate.installCount -eq 0 -and
  -not [bool]$stateAfter.authority.buildAuthorized -and
  -not [bool]$aggregateAfter.authority.buildAuthorized
) -Message 'negative C30X probe changed state, aggregate, manifest, authority or counts.'
Assert-C30YFix4ManifestCurrent -State $stateAfter | Out-Null

Write-Output (
  'C30Y FIX4 C30X negative classifier passed: ' +
  "context=$ExpectedContext; exitNonzero=true; exactHardGateOwner=true; " +
  'stateAggregateManifestUnchanged=true; actions=0/0/0.'
)
