[CmdletBinding()]
param([Parameter(Mandatory)][string]$ExpectedHead)
$ErrorActionPreference = 'Stop'
$root = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913'
$evidence = $PSScriptRoot
$relative = 'apps/mobile/build/cursor-review-r66.22'
$outputRoot = Join-Path $root $relative
$branch = 'work/cursor-ui/redmi-v6-audit-20260913'
$candidate = 'UAW-CURSOR-REDMI-RV6-LANGUAGE-20260914'
function Assert-Prepared([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Git-Lines([string[]]$Arguments) {
  $lines = @(& git -C $root @Arguments)
  if ($LASTEXITCODE -ne 0) { throw "Git failed: $($Arguments[0])" }
  return $lines
}
Assert-Prepared (@(Git-Lines @('rev-parse','HEAD'))[0] -ceq $ExpectedHead) 'Unexpected source HEAD'
Assert-Prepared (@(Git-Lines @('branch','--show-current'))[0] -ceq $branch) 'Wrong branch'
Assert-Prepared (@(Git-Lines @('status','--porcelain=v1')).Count -eq 0) 'Source must be clean'
$remote = @(Git-Lines @('ls-remote','--heads','origin',"refs/heads/$branch"))
Assert-Prepared ($remote.Count -eq 1 -and $remote[0].Split("`t")[0] -ceq $ExpectedHead) 'Live remote differs'
Assert-Prepared (-not (Test-Path -LiteralPath $outputRoot)) 'Candidate output already exists'
foreach ($cycle in @('combined-cycle1.log','combined-cycle2.log')) {
  $last = (Get-Content -LiteralPath (Join-Path $evidence $cycle) -Tail 1)
  Assert-Prepared ($last -match 'All tests passed!') "$cycle has no terminal pass"
}
Assert-Prepared ((Get-Content -Raw -LiteralPath (Join-Path $evidence 'analysis-01.log')) -match 'No issues found!') 'Analysis not qualified'
$owners = @(Git-Lines @('ls-files','--','apps/mobile/lib','apps/mobile/android','apps/mobile/assets','apps/mobile/pubspec.yaml','apps/mobile/pubspec.lock'))
$prior = @(Get-Content -LiteralPath (Join-Path $root 'apps/mobile/build/cursor-review-r66.21/source-manifest.txt') | ForEach-Object { $_.Substring(66) })
$delta = @(Compare-Object $prior $owners)
Assert-Prepared ($owners.Count -eq 326 -and $delta.Count -eq 1 -and $delta[0].InputObject -ceq 'apps/mobile/lib/app/ui_review_language_store.dart' -and $delta[0].SideIndicator -ceq '=>') 'Unexpected runtime inventory delta'
$rows = @($owners | Sort-Object | ForEach-Object { '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root $_)).Hash, $_ })
New-Item -ItemType Directory -Path $outputRoot | Out-Null
$manifestPath = Join-Path $outputRoot 'source-manifest.txt'
[IO.File]::WriteAllLines($manifestPath, $rows, [Text.UTF8Encoding]::new($false))
$manifestHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash
$logRoot = Join-Path $outputRoot 'evidence'
New-Item -ItemType Directory -Path $logRoot | Out-Null
$receipts = @()
foreach ($file in Get-ChildItem -LiteralPath $evidence -File -Filter '*.log') {
  $destination = Join-Path $logRoot $file.Name
  Copy-Item -LiteralPath $file.FullName -Destination $destination
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
  Assert-Prepared ((Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash -ceq $hash) 'Evidence copy differs'
  $receipts += [ordered]@{ file=$file.Name; sha256=$hash; bytes=$file.Length }
}
$state = Get-Content -Raw -LiteralPath (Join-Path $root 'apps/mobile/build/cursor-review-r66.21/machine-state.json') | ConvertFrom-Json
$state.candidate.id = $candidate
$state.candidate.head = $ExpectedHead
$state.candidate.versionName = '1.0.0-r66.22'
$state.candidate.versionCode = 2026091403
$state.source.fileCount = $owners.Count
$state.source.manifestPath = "$relative/source-manifest.txt"
$state.source.manifestSha256 = $manifestHash
$state.requiredRuntimeDefines.MOOLSOCIAL_CANDIDATE_ID = $candidate
$state.machineState = 'prebuild_passed'
$state.buildAuthorization = 'approved_for_one_build'
$state.preBuildValidation.state = 'passed'
$prebuild = 'docs/quality/cursor-redmi-v6-audit-20260913/PREBUILD.md'
$state.preBuildValidation.evidence = $prebuild
foreach ($gate in $state.preBuildGates) {
  $gate.evidence = @($prebuild)
  if ($gate.id -ceq 'buy-regression-1') { $gate.evidence += "$relative/evidence/combined-cycle1.log" }
  if ($gate.id -ceq 'buy-regression-2') { $gate.evidence += "$relative/evidence/combined-cycle2.log" }
  if ($gate.id -ceq 'format-analysis') { $gate.evidence += "$relative/evidence/analysis-01.log" }
  if ($gate.id -ceq 'clean-state-regression') { $gate.evidence += "$relative/evidence/clean-support-01.log" }
  if ($gate.id -cin @('wrapper-self-test','package-isolation')) { $gate.evidence += "$relative/evidence/build-profile-01.log" }
}
$state.premiumMotionPolicy.applied = @('no_new_motion_in_language_only_persistence_correction')
$state.premiumMotionPolicy.state = 'local_source_checks_passed_device_acceptance_preserved_separately'
$state.qualificationLimits = @(
  '18_original_device_closures_preserved_on_prior_recorded_APKs',
  'D005_C01_locally_qualified_device_open_subsequent_instruction_required',
  'D009_D010_D014_native_link_delivery_unverified_approval_rejection_not_bypassed',
  '27_inherited_capture_skips_are_not_passes',
  'host_Hindi_glyph_qualification_unavailable',
  'review_only_no_production_provider_backend_or_integration_qualification',
  'one_final_build_and_Redmi_data_preserving_install_then_stop'
)
foreach ($gate in $state.postBuildGates) {
  $gate.state = 'pending'
  $gate.evidence = @('docs/quality/cursor-redmi-v6-audit-20260913/UAT.md')
}
[IO.File]::WriteAllText((Join-Path $outputRoot 'machine-state.json'), ($state | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $outputRoot 'evidence-copy-receipt.json'), ($receipts | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
Assert-Prepared (@(Git-Lines @('status','--porcelain=v1')).Count -eq 0) 'Preparation changed tracked source or created untracked owners'
Write-Output "Prepared $candidate; source=$ExpectedHead; owners=$($owners.Count); manifest=$manifestHash"
