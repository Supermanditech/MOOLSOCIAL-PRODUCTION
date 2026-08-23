[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$baselineRelative = 'artifacts/quality/social-protected-candidate-c30u-post-r60-45-social-repairs-20260814-01/BASELINE.json'
$predecessorRelative = 'artifacts/quality/social-protected-candidate-c29e-native-ownership-redesign-20260811-01/BASELINE.json'
$auditRelative = 'docs/quality/UAW-C30U-PROTECTED-SOCIAL-SUCCESSOR-SEAL-AUDIT-20260814.md'
$ticketRelative = 'config/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-ticket.json'
$baselinePath = Join-Path $root $baselineRelative
$predecessorPath = Join-Path $root $predecessorRelative
$auditPath = Join-Path $root $auditRelative
$ticketPath = Join-Path $root $ticketRelative

function Assert-C30USocialSeal {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30U protected Social successor rejected: $Message" }
}

foreach ($required in @($baselinePath, $predecessorPath, $auditPath, $ticketPath)) {
  Assert-C30USocialSeal -Condition (Test-Path -LiteralPath $required -PathType Leaf) -Message "required owner is missing: $required"
}

$baseline = Get-Content -Raw -LiteralPath $baselinePath | ConvertFrom-Json
$baselineHash = (Get-FileHash -LiteralPath $baselinePath -Algorithm SHA256).Hash
$predecessorHash = (Get-FileHash -LiteralPath $predecessorPath -Algorithm SHA256).Hash
$ticketHash = (Get-FileHash -LiteralPath $ticketPath -Algorithm SHA256).Hash
Assert-C30USocialSeal -Condition (
  $baselineHash -ceq '8E6BC23C1FAE8D59DF25E9C37AF0ACD1F74B0CEED5949AEBB8B2846DD2FC73C8'
) -Message 'C30U baseline file checksum changed.'
Assert-C30USocialSeal -Condition (
  [int]$baseline.schemaVersion -eq 1 -and
  [string]$baseline.baselineId -ceq 'social-protected-candidate-c30u-post-r60-45-social-repairs-20260814-01' -and
  [string]$baseline.state -ceq 'FOUNDER_AUTHORIZED_SUCCESSOR_PENDING_OPPO_ACCEPTANCE' -and
  [string]$baseline.branch -ceq 'remediation/prototype-conformance-2026-07-20' -and
  [string]$baseline.repositoryHeadAtAuthorization -ceq 'f6dfe7587aa02d782e94282d14af8bafff48ded0'
) -Message 'baseline identity, state, branch or HEAD changed.'
Assert-C30USocialSeal -Condition (
  [string]$baseline.predecessor.path -ceq $predecessorRelative -and
  [string]$baseline.predecessor.sha256 -ceq 'A4A22EB631522A9F15FB2D8A22EDA98C8F12FDF138A9B31ABA4C4EE25751E810' -and
  $predecessorHash -ceq [string]$baseline.predecessor.sha256 -and
  [bool]$baseline.predecessor.preserved
) -Message 'C29E predecessor identity or checksum changed.'
Assert-C30USocialSeal -Condition (
  [int]$baseline.protectedRuntime.fileCount -eq 206 -and
  [string]$baseline.protectedRuntime.portableTreeSha256 -ceq 'f0fa9d67b7fde975d544792d3194dbe457b2028750ee444b02a3c9cd98ef75db' -and
  [string]$baseline.protectedRuntime.auditedDelta -ceq $auditRelative
) -Message 'protected inventory, portable tree or audit owner changed.'
Assert-C30USocialSeal -Condition (
  [string]$baseline.candidate.id -ceq 'UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE' -and
  [string]$baseline.candidate.package -ceq 'com.moolsocial.app' -and
  [string]$baseline.candidate.versionName -ceq '1.0.0-r60.46' -and
  [int]$baseline.candidate.versionCode -eq 2026081346 -and
  [string]$baseline.candidate.oppoAcceptance -ceq 'pending'
) -Message 'candidate identity or pending OPPO state changed.'
Assert-C30USocialSeal -Condition (
  $ticketHash -ceq '3595A1A65D55991BAC8DAAD0D59584470140617FBF7C919CBC580B1E06C199C1' -and
  [string]$baseline.founderAuthority.evidence -ceq $ticketRelative -and
  -not [bool]$baseline.founderAuthority.finalAcceptanceGranted -and
  -not [bool]$baseline.founderAuthority.commitAuthorized -and
  -not [bool]$baseline.founderAuthority.promotionAuthorized
) -Message 'ticket checksum or authority boundary changed.'
Assert-C30USocialSeal -Condition (
  [string]$baseline.verification.authoritativeFlutterManifest -ceq '58_files_405_passed_3_declared_skips_0_failed' -and
  [string]$baseline.verification.backend -ceq '516_passed_0_failed' -and
  [string]$baseline.verification.hosting -ceq '7_passed_0_failed' -and
  [string]$baseline.verification.wholeMobileAnalyzer -ceq 'clean' -and
  [string]$baseline.verification.oppo -ceq 'pending'
) -Message 'qualification facts or pending device state changed.'

& (Join-Path $root 'scripts/check-social-protected-baseline.ps1') -RepositoryRoot $root -BaselinePath $baselinePath

Write-Output "C30U protected Social successor passed: files=206; tree=f0fa9d67b7fde975d544792d3194dbe457b2028750ee444b02a3c9cd98ef75db; predecessor=$predecessorHash; OPPO=pending."
