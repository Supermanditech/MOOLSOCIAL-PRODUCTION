[CmdletBinding()]
param([string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'artifact-evidence-retention.ps1')
. (Join-Path $PSScriptRoot 'check-cleanup-artifact-retention.ps1')
$registry = Get-Content -Raw -LiteralPath (Join-Path $RepositoryRoot 'config/codex-development-regression-registry.json') | ConvertFrom-Json
$contractPath = 'docs/quality/CURSOR-BUY-ARTIFACT-RETENTION-20261002.json'
$contract = Get-Content -Raw -LiteralPath (Join-Path $RepositoryRoot $contractPath) | ConvertFrom-Json
$fixture = Join-Path $RepositoryRoot ('apps/mobile/build/artifact-retention-tests-' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $fixture)
foreach ($relative in @($contractPath,'config/apk-regression-gate-state.json') + @($contract.artifacts.provenance.path | Select-Object -Unique)) {
  $destination = Join-Path $fixture $relative
  [void](New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force)
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot $relative) -Destination $destination
}
$passed = 0
$facts = @{
  Role='primary'; Task='/root'; ClaimTask='/root'; ClaimRole='primary'
  Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-buy-ready-20260921'
  Branch='work/cursor-ui/buy-ready-20260921'; Lane='cursor_ui'; WorkId='buy-ready-20260921'
  TicketId='UAW-CURSOR-BUY-READY-20260921'; Phase='implementation'
  Owner='scripts/check-codex-development-regression-memory.ps1'; GenerationVerified=$true
  AuthoritySha256='70F6FE4BAB84B29D9A0C323B6B48CC2CFC2515E25761431AEF2F69E186138370'
}
if (-not (Test-ArtifactRetentionMaintenanceOwner $facts)) { throw 'Exact maintenance admission rejected.' }
foreach ($key in @('Role','Task','ClaimTask','ClaimRole','Root','Branch','Lane','WorkId','TicketId','Phase','Owner','AuthoritySha256','GenerationVerified')) {
  $changed = $facts.Clone()
  $changed[$key] = if ($key -ceq 'GenerationVerified') { $false } elseif ($key -ceq 'Phase') { 'build' } else { 'wrong' }
  if (Test-ArtifactRetentionMaintenanceOwner $changed) { throw "Maintenance scope escaped: $key" }
  $passed++; Write-Output "PASS maintenance rejects wrong $key"
}
function Expect-Rejected([string]$Name, [scriptblock]$Action) {
  $rejected = $false
  try { & $Action | Out-Null } catch { $rejected = $true }
  if (-not $rejected) { throw "Negative test accepted: $Name" }
  $script:passed++; Write-Output "PASS $Name"
}
function Validate($Data = $registry) {
  Get-RetiredRegressionArtifacts -RepositoryRoot $fixture -Registry $Data -EvidenceRoots @($fixture,(Join-Path $fixture 'second-evidence-root'))
}
$approved = Validate
if ($approved.Count -ne 5 -or $approved.ContainsKey('unlisted|artifacts/quality/new-missing.apk')) { throw 'Retirement scope expanded.' }
$passed++; Write-Output 'PASS exact three historical artifacts / five consumers; unlisted evidence denied'
$candidateFile = Join-Path $fixture 'config/apk-regression-gate-state.json'
$candidateBytes = [IO.File]::ReadAllBytes($candidateFile)
$candidateData = [Text.Encoding]::UTF8.GetString($candidateBytes) | ConvertFrom-Json
$candidateData.candidate | Add-Member -NotePropertyName artifactPath -NotePropertyValue $contract.artifacts[0].path -Force
[IO.File]::WriteAllText($candidateFile, ($candidateData | ConvertTo-Json -Depth 100))
Expect-Rejected 'current candidate references retired artifact without registry or contract changes' { Validate }
$candidateData.candidate.artifactPath = Join-Path (Join-Path $fixture 'second-evidence-root') $contract.artifacts[0].path
[IO.File]::WriteAllText($candidateFile, ($candidateData | ConvertTo-Json -Depth 100))
Expect-Rejected 'absolute current candidate references retired artifact under another accepted evidence root' { Validate }
[IO.File]::WriteAllBytes($candidateFile, $candidateBytes)
$copy = $registry | ConvertTo-Json -Depth 100 | ConvertFrom-Json
$consumer = @($copy.entries | Where-Object { $_.id -ceq $contract.artifacts[0].registryEntryIds[0] })[0]
$consumer.evidence = @($consumer.evidence | Where-Object { $_ -cne $contract.artifacts[0].path })
Expect-Rejected 'changed registry path / unused retirement' { Validate $copy }
$copy = $registry | ConvertTo-Json -Depth 100 | ConvertFrom-Json
(@($copy.entries | Where-Object { $_.id -ceq $contract.artifacts[0].registryEntryIds[0] })[0]).id = 'changed-original-consumer'
Expect-Rejected 'changed registry consumer identity' { Validate $copy }
$original = [IO.File]::ReadAllBytes((Join-Path $fixture $contractPath))
Remove-Item -LiteralPath (Join-Path $fixture $contractPath)
Expect-Rejected 'missing retirement authority document' { Validate }
[IO.File]::WriteAllBytes((Join-Path $fixture $contractPath), $original)
foreach ($case in @('digest','duplicate','extra','current-candidate','deletion-evidence')) {
  $changed = [Text.Encoding]::UTF8.GetString($original) | ConvertFrom-Json
  switch ($case) {
    'digest' { $changed.artifacts[0].artifactSha256 = '0' * 64 }
    'duplicate' { $changed.artifacts += $changed.artifacts[0] }
    'extra' { $changed.artifactCount = 4 }
    'current-candidate' { $changed.artifacts[0].releaseAuthority = $true }
    'deletion-evidence' { $changed.artifacts[0].deletion.journalLine = 1 }
  }
  [IO.File]::WriteAllText((Join-Path $fixture $contractPath), ($changed | ConvertTo-Json -Depth 100))
  Expect-Rejected "tampered retirement $case" { Validate }
  [IO.File]::WriteAllBytes((Join-Path $fixture $contractPath), $original)
}
$source = Join-Path $fixture $contract.artifacts[0].provenance[0].path
$sourceBytes = [IO.File]::ReadAllBytes($source)
[IO.File]::AppendAllText($source, 'tampered')
Expect-Rejected 'changed independent original provenance' { Validate }
[IO.File]::WriteAllBytes($source, $sourceBytes)
$binary = Join-Path $fixture $contract.artifacts[0].path
[void](New-Item -ItemType Directory -Path (Split-Path -Parent $binary) -Force)
[IO.File]::WriteAllText($binary, 'wrong binary')
Expect-Rejected 'present binary with wrong identity' { Validate }
$binaryStream = [IO.File]::Open($binary, [IO.FileMode]::Create)
try { $binaryStream.SetLength($contract.artifacts[0].bytes) } finally { $binaryStream.Dispose() }
Expect-Rejected 'present same-size binary with wrong checksum' { Validate }
Remove-Item -LiteralPath $binary
$protected = Get-CleanupEvidenceProtection -RepositoryRoots @($RepositoryRoot)
foreach ($artifact in $contract.artifacts) {
  if (-not (Test-CleanupEvidenceProtected -Path (Join-Path $RepositoryRoot $artifact.path) -ProtectedEvidence $protected)) { throw 'Required evidence is deletable.' }
}
if (-not (Test-CleanupEvidenceProtected -Path (Join-Path $RepositoryRoot 'artifacts/quality/unindexed/candidate.apk') -ProtectedEvidence $protected) -or
    (Test-CleanupEvidenceProtected -Path (Join-Path $RepositoryRoot 'apps/mobile/build/generated-unused.apk') -ProtectedEvidence $protected)) {
  throw 'Cleanup audit/generated boundary is incorrect.'
}
$passed++; Write-Output 'PASS cleanup protects registry/manifests/audit roots and permits ordinary generated candidate'
$outsideAudit = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
[void]$outsideAudit.Add((Join-Path $RepositoryRoot 'cache/retained/evidence.apk'))
if (-not (Test-CleanupEvidenceProtected -Path (Join-Path $RepositoryRoot 'cache/retained') -ProtectedEvidence $outsideAudit) -or
    (Test-CleanupEvidenceProtected -Path (Join-Path $RepositoryRoot 'cache/retained-sibling') -ProtectedEvidence $outsideAudit)) { throw 'Recursive ancestor/sibling protection is incorrect.' }
$passed++; Write-Output 'PASS recursive ancestor protects referenced evidence outside audit roots; sibling remains eligible'
if (-not (Test-CleanupEvidenceProtected -Path (Join-Path $RepositoryRoot 'apps/mobile/build') -ProtectedEvidence $protected)) { throw 'Unindexed audit-root ancestor is deletable.' }
$passed++; Write-Output 'PASS recursive ancestor protects unindexed review candidates'
Expect-Rejected 'cleanup inventory outside authorized workspace' { Get-CleanupEvidenceProtection -RepositoryRoots @('C:\Windows') }
$inventory = @(Get-CleanupActiveRepositoryRoots -ProductionRoot 'C:\GUARANTEED OUTCOME\production-fixture' -InactiveRemovalRoots @('C:\GUARANTEED OUTCOME\inactive-fixture') -ReadGit {
  "worktree C:/GUARANTEED OUTCOME/production-fixture`nHEAD one`n`nworktree C:/GUARANTEED OUTCOME/active-fixture`nHEAD two`n`nworktree C:/GUARANTEED OUTCOME/inactive-fixture`nHEAD three`n"
})
if ($inventory.Count -ne 2 -or $inventory -notcontains 'C:\GUARANTEED OUTCOME\active-fixture') { throw 'Complete registered active inventory was not captured.' }
$passed++; Write-Output 'PASS live registered inventory includes production and active roots, excludes explicit inactive removal'
$heads = @{ 'test-root'='original-head' }; $statuses = @{ 'test-root'='original-status' }
Expect-Rejected 'missing active snapshot inventory' { Assert-CleanupActiveSnapshots -Heads @{} -Statuses @{} -ExpectedRoots @('test-root') -ReadGit {} }
Expect-Rejected 'mismatched active snapshot roots' { Assert-CleanupActiveSnapshots -Heads $heads -Statuses @{} -ExpectedRoots @('test-root') -ReadGit {} }
Expect-Rejected 'active root omitted from both snapshots' { Assert-CleanupActiveSnapshots -Heads $heads -Statuses $statuses -ExpectedRoots @('test-root','omitted-root') -ReadGit {} }
Expect-Rejected 'newly registered active root after capture' { Assert-CleanupActiveSnapshots -Heads $heads -Statuses $statuses -ExpectedRoots @('test-root','new-root') -ReadGit {} }
$sameGit = { param($Repository,$Arguments) if ($Arguments[0] -eq 'rev-parse') { 'original-head' } else { 'original-status' } }
Assert-CleanupActiveSnapshots -Heads $heads -Statuses $statuses -ExpectedRoots @('test-root') -ReadGit $sameGit
$passed++; Write-Output 'PASS unchanged active snapshot'
Expect-Rejected 'active HEAD changed during cleanup' {
  Assert-CleanupActiveSnapshots -Heads $heads -Statuses $statuses -ExpectedRoots @('test-root') -ReadGit { param($Repository,$Arguments) if ($Arguments[0] -eq 'rev-parse') { 'changed-head' } else { 'original-status' } }
}
Expect-Rejected 'active status changed during cleanup' {
  Assert-CleanupActiveSnapshots -Heads $heads -Statuses $statuses -ExpectedRoots @('test-root') -ReadGit { param($Repository,$Arguments) if ($Arguments[0] -eq 'rev-parse') { 'original-head' } else { 'changed-status' } }
}
# Load only the pure Store admission predicate, not the validator's main action.
$parseTokens = $null; $parseErrors = $null
$coordinationAst = [Management.Automation.Language.Parser]::ParseFile(
  (Join-Path $RepositoryRoot 'scripts/check-codex-subagent-coordination-policy.ps1'),
  [ref]$parseTokens, [ref]$parseErrors)
if ($parseErrors.Count -ne 0) { throw 'Store coordination source does not parse.' }
$storeFunction = @($coordinationAst.FindAll({ param($node)
  $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Test-StoreRetentionMaintenanceOwner'
}, $true))
if ($storeFunction.Count -ne 1) { throw 'Store maintenance predicate missing or duplicated.' }
. ([scriptblock]::Create($storeFunction[0].Extent.Text))
$storeFacts = @{
  Role='primary'; Task='/root'; ClaimTask='/root'; ClaimRole='primary'
  Root='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CODEX-add-product-screen1-20260920'
  Branch='work/codex-ui/add-product-screen1-20260920'; Lane='codex_ui'
  WorkId='add-product-screen1-20260920'; TicketId='UAW-ADD-PRODUCT-SCREEN1-20260920'
  AdmissionSha256='1EFBB8814D7372032AEDA16238D1C71A7FE91D4A5091DFF4AB06E12C340ADE50'
  ProofSha256='70F6FE4BAB84B29D9A0C323B6B48CC2CFC2515E25761431AEF2F69E186138370'
  HelperSha256='4B2DBB76952E2A2B826CB3D267FA9CE3ABF3663055111843E1176DAC4B0C1A00'
  PublishedCommit='1a66f12c4153d98962cc639945af215d44b1d7c1'
  GenerationVerified=$true; BaselineVerified=$true; Phase='implementation'
  Owner='scripts/check-codex-development-regression-memory.ps1'
}
if (-not (Test-StoreRetentionMaintenanceOwner $storeFacts)) { throw 'Exact Store admission rejected.' }
$passed++; Write-Output 'PASS exact Store admission, independent of Cursor'
foreach ($key in @($storeFacts.Keys)) {
  $changed = $storeFacts.Clone()
  $changed[$key] = if ($key -cin @('GenerationVerified','BaselineVerified')) { $false } else { 'wrong' }
  if (Test-StoreRetentionMaintenanceOwner $changed) { throw "Store maintenance escaped: $key" }
  $passed++; Write-Output "PASS Store rejects wrong $key"
}
foreach ($owner in @('apps/mobile/lib/features/work/work_session.dart',
  'apps/mobile/lib/ui_v2/buy/buy_v2_cart.dart', 'config/mvp-scope-gate-state.json',
  '../scripts/check-codex-development-regression-memory.ps1',
  'C:/Windows/outside.ps1', 'scripts/unlisted-retention-helper.ps1')) {
  $changed = $storeFacts.Clone(); $changed.Owner = $owner
  if (Test-StoreRetentionMaintenanceOwner $changed) { throw 'Store admitted unrelated or escaping owner.' }
  $passed++; Write-Output "PASS Store rejects unrelated owner $owner"
}
foreach ($phase in @('build','device','ticket_close','founder_acceptance','task_start')) {
  $changed = $storeFacts.Clone(); $changed.Phase = $phase
  if (Test-StoreRetentionMaintenanceOwner $changed) { throw "Maintenance admitted $phase." }
  $passed++; Write-Output "PASS Store maintenance rejects phase $phase"
}
$cursorMixed = $facts.Clone(); $cursorMixed.Root = $storeFacts.Root
if (Test-ArtifactRetentionMaintenanceOwner $cursorMixed) { throw 'Cursor admitted mixed Store root.' }
$storeMixed = $storeFacts.Clone(); $storeMixed.Branch = $facts.Branch
if (Test-StoreRetentionMaintenanceOwner $storeMixed) { throw 'Store admitted mixed Cursor branch.' }
$passed++; Write-Output 'PASS mixed Store/Cursor conjunctions rejected; original Cursor controls retained'
foreach ($format in @('CRLF','BOM')) {
  $changedBytes = if ($format -ceq 'CRLF') {
    [Text.Encoding]::UTF8.GetBytes([Text.Encoding]::UTF8.GetString($original).Replace("`n", "`r`n"))
  } else { [byte[]](@(239,187,191) + @($original)) }
  [IO.File]::WriteAllBytes((Join-Path $fixture $contractPath), $changedBytes)
  Expect-Rejected "raw proof $format mutation" { Validate }
  [IO.File]::WriteAllBytes((Join-Path $fixture $contractPath), $original)
}
Write-Output "Artifact evidence retention tests passed: $passed; fixtures retained: $fixture"
