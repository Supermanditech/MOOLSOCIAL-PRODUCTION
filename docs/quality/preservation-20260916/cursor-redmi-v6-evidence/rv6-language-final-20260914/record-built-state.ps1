$ErrorActionPreference = 'Stop'
$candidateRoot = 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913/apps/mobile/build/cursor-review-r66.22'
$receipt = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'apk-identity.json') | ConvertFrom-Json
$statePath = Join-Path $candidateRoot 'machine-state.json'
$originalPath = Join-Path $candidateRoot 'prebuild-machine-state.json'
$builtPath = Join-Path $candidateRoot 'built-machine-state.json'
if ((Test-Path -LiteralPath $originalPath) -or (Test-Path -LiteralPath $builtPath)) { throw 'Build-state receipts already exist' }
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
if ($state.candidate.head -cne $receipt.sourceHead -or $state.candidate.id -cne $receipt.candidate -or $state.buildAuthorization -cne 'approved_for_one_build') { throw 'Unexpected one-build source authorization state' }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $receipt.apk).Hash -cne $receipt.apkSha256) { throw 'Verified artifact changed' }
Copy-Item -LiteralPath $statePath -Destination $originalPath
$originalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $statePath).Hash
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $originalPath).Hash -cne $originalHash) { throw 'Prebuild state copy mismatch' }
$state.machineState = 'built_install_pending'
$state.buildAuthorization = 'consumed_one_build'
foreach ($gate in $state.postBuildGates) {
  if ($gate.id -ceq 'artifact-package-version-signer-checksum') { $gate.state='passed' }
}
[IO.File]::WriteAllText($builtPath, ($state | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath $builtPath -Destination $statePath
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $builtPath).Hash -cne (Get-FileHash -Algorithm SHA256 -LiteralPath $statePath).Hash) { throw 'Consumed state mismatch' }
Write-Output "One-build authorization consumed; exact prebuild state preserved SHA256=$originalHash; installation pending."
