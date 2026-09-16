param([Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$source)
$ErrorActionPreference='Stop'
$repo='C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'

$receipt=Join-Path $PSScriptRoot 'navigation-admission-negative.result.json'
if(Test-Path -LiteralPath $receipt){throw 'Preserve existing test receipt'}
$backend=Join-Path $repo 'scripts/check-buy-backend-contract-boundary.ps1'
. $backend -RepositoryRoot $repo -IntegratedReviewSourceCommit $source -SelfTest
$owner='apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart'
$screen=[IO.File]::ReadAllText((Join-Path $repo $owner))
$cases=@(
  @{name='exact source and screen';source=$source;owner=$owner;content=$screen;qualified=$true;reject=$false},
  @{name='wrong source';source=('0'*40);owner=$owner;content=$screen;qualified=$true;reject=$true},
  @{name='changed content hash';source=$source;owner=$owner;content=($screen+"`n// intentional negative test`n");qualified=$true;reject=$true},
  @{name='wrong owner';source=$source;owner='apps/mobile/lib/ui_v2/buy/other.dart';content=$screen;qualified=$true;reject=$true},
  @{name='review admission absent';source=$source;owner=$owner;content=$screen;qualified=$false;reject=$true},
  @{name='direct network client added';source=$source;owner=$owner;content=($screen+"`nfinal forbiddenClient = HttpClient();`n");qualified=$true;reject=$true}
)
$results=@()
foreach($case in $cases){
  $IntegratedReviewSourceCommit=$case.source
  $findings=@(Get-MobileBoundaryViolations -Label $case.owner -Content $case.content -QualifiedRedmiReview:$case.qualified)
  $rejected=$findings.Count -gt 0
  if($rejected -ne $case.reject){throw "Unexpected boundary decision: $($case.name)"}
  $results += [ordered]@{name=$case.name;rejected=$rejected;findingCount=$findings.Count}
}
$IntegratedReviewSourceCommit=$source
& (Join-Path $repo 'scripts/check-buy-data-egress-boundary.ps1') -RepositoryRoot $repo -IntegratedReviewSourceCommit $source -SelfTest
$record=[ordered]@{source=$source;backendCheckerSha256=(Get-FileHash -LiteralPath $backend).Hash;cases=$results;existingBackendSelfTest='passed';existingEgressSelfTest='passed';appFilesMutated=$false;deviceClosureEstablished=$false}
[IO.File]::WriteAllText($receipt,($record|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
Write-Output 'SKU admission: exact source accepted; five negative cases rejected; existing backend/egress self-tests passed.'
