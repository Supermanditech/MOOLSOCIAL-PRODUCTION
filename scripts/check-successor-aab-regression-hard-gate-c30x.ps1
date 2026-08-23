[CmdletBinding()]
param(
  [ValidateSet(
    'reconcile',
    'build',
    'postbuild',
    'preupload',
    'postupload',
    'preinstall',
    'postinstall',
    'journey'
  )]
  [string]$Phase = 'reconcile',

  [string]$StatePath,

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) {
  $StatePath =
    'config/successor-aab-regression-hard-gate-state-c30x.json'
}

function Assert-C30X {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30X successor AAB hard gate rejected: $Message"
  }
}

function Resolve-C30XFile {
  param(
    [Parameter(Mandatory)][AllowEmptyString()][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C30X -Condition (-not [string]::IsNullOrWhiteSpace($Path)) `
    -Message "$Label path is empty."
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  Assert-C30X -Condition (
    $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
    (Test-Path -LiteralPath $resolved -PathType Leaf)
  ) -Message "$Label is missing or escaped the repository: $Path"
  return $resolved
}

function Read-C30XJson {
  param(
    [Parameter(Mandatory)][AllowEmptyString()][string]$Path,
    [Parameter(Mandatory)][string]$Label,
    [switch]$RejectCredentialShapes
  )
  $resolved = Resolve-C30XFile -Path $Path -Label $Label
  $raw = Get-Content -Raw -LiteralPath $resolved
  if ($RejectCredentialShapes) {
    Assert-C30X -Condition (-not [regex]::IsMatch(
      $raw,
      'AIza[0-9A-Za-z_-]{35}|(?i)\b[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com\b|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----'
    )) -Message "$Label contains credential-shaped material."
  }
  return $raw | ConvertFrom-Json
}

function Assert-C30XProperty {
  param(
    [Parameter(Mandatory)][object]$Object,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Label
  )
  Assert-C30X -Condition ($null -ne $Object.PSObject.Properties[$Name]) `
    -Message "$Label is missing property '$Name'."
}

function Assert-C30XSourceManifestCurrent {
  param([Parameter(Mandatory)][object]$State)
  $manifest = Resolve-C30XFile `
    -Path ([string]$State.sourceQualification.manifestPath) `
    -Label 'qualified source manifest'
  Assert-C30X -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $manifest).Hash -ceq
      ([string]$State.sourceQualification.manifestSha256).ToUpperInvariant()
  ) -Message 'qualified source-manifest file changed.'
  $rows = 0
  foreach ($line in Get-Content -LiteralPath $manifest) {
    $match = [regex]::Match($line, '^([0-9A-F]{64})  (.+)$')
    Assert-C30X -Condition $match.Success `
      -Message 'qualified source-manifest row is malformed.'
    $owner = Resolve-C30XFile `
      -Path $match.Groups[2].Value `
      -Label 'qualified source owner'
    Assert-C30X -Condition (
      (Get-FileHash -Algorithm SHA256 -LiteralPath $owner).Hash -ceq
        $match.Groups[1].Value
    ) -Message "qualified source owner changed: $($match.Groups[2].Value)"
    $rows++
  }
  Assert-C30X -Condition (
    $rows -eq [int]$State.sourceQualification.fileCount
  ) -Message 'qualified source-manifest file count changed.'
}

function Assert-C30XHistoricalFailurePreserved {
  param([Parameter(Mandatory)][object]$State)
  $failed = Read-C30XJson `
    -Path ([string]$State.historicalFailedCandidate.statePath) `
    -Label 'failed r60.47 state'
  $aggregate = Read-C30XJson `
    -Path ([string]$State.historicalFailedCandidate.aggregatePath) `
    -Label 'failed r60.47 aggregate'
  Assert-C30X -Condition (
    [string]$failed.candidate.id -ceq
      'UAW-C30V-R60-47-SEAL-RECOVERY-PLAY-INTERNAL-ACCEPTANCE' -and
    [string]$failed.candidate.versionName -ceq '1.0.0-r60.47' -and
    [string]$failed.candidate.versionCode -ceq '2026081347' -and
    [string]$failed.machineState -ceq
      'acceptance_failed_r60_47_cold_start_release_config_successor_required' -and
    [string]$aggregate.machineState -ceq
      'acceptance_failed_r60_47_cold_start_release_config_successor_required' -and
    [int]$aggregate.candidate.buildCount -eq 1 -and
    [int]$aggregate.candidate.uploadCount -eq 1 -and
    [int]$aggregate.candidate.installCount -eq 1 -and
    [bool]$failed.sourceQualification.analyzerPassed -and
    -not [bool]$aggregate.sourceQualification.wholeMobileAnalyzerClean -and
    -not [bool]$State.historicalFailedCandidate.successClaimed
  ) -Message 'failed r60.47 identity, counts or failure state changed.'
}

function Assert-C30XScope {
  $scope = Read-C30XJson `
    -Path 'config/mvp-scope-gate-state.json' `
    -Label 'MVP scope state'
  $activeTicketId = [string]$scope.ticket.id
  $preparationContext =
    $activeTicketId -ceq
      'UAW-C30X-SUCCESSOR-AAB-PREPARATION-REGRESSION-HARD-GATE' -and
    -not [bool]$scope.execution.buildAuthorized
  $candidateContext =
    $activeTicketId -ceq
      'UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE'
  Assert-C30X -Condition (
    ($preparationContext -or $candidateContext) -and
    -not [bool]$scope.execution.referenceWriteAuthorized -and
    -not [bool]$scope.execution.runtimeWriteAuthorized -and
    [bool]$scope.execution.testOrGateWriteAuthorized -and
    -not [bool]$scope.execution.backendWriteAuthorized -and
    -not [bool]$scope.execution.deviceInstallAuthorized -and
    -not [bool]$scope.execution.externalServiceWriteAuthorized -and
    -not [bool]$scope.execution.secretValueAccessAuthorized
  ) -Message 'C30X preparation or exact C30Y candidate scope changed.'
}

function Assert-C30XArtifactBinding {
  param([Parameter(Mandatory)][object]$State)
  $artifact = Resolve-C30XFile `
    -Path ([string]$State.buildResult.artifactPath) `
    -Label 'sealed successor AAB'
  $provenancePath = Resolve-C30XFile `
    -Path ([string]$State.buildResult.provenance) `
    -Label 'successor AAB provenance'
  $provenanceRaw = Get-Content -Raw -LiteralPath $provenancePath
  Assert-C30X -Condition (-not [regex]::IsMatch(
    $provenanceRaw,
    'AIza[0-9A-Za-z_-]{35}|(?i)\b[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com\b|Bearer\s+[A-Za-z0-9._~+/-]+=*|-----BEGIN .*PRIVATE KEY-----'
  )) -Message 'AAB provenance contains credential-shaped material.'
  $provenance = $provenanceRaw | ConvertFrom-Json
  $artifactHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifact).Hash
  $artifactBytes = (Get-Item -LiteralPath $artifact).Length
  $expectedSigner = (
    [string]$State.signingQualification.uploadCertificateSha256
  ).Replace(':', '').ToUpperInvariant()
  foreach ($name in @(
    'candidateId', 'versionName', 'versionCode', 'packageName',
    'artifactPath', 'artifactSha256', 'artifactBytes',
    'uploadSignerSha256', 'releaseRegistrantPluginCount'
  )) {
    Assert-C30XProperty -Object $provenance -Name $name -Label 'AAB provenance'
  }
  Assert-C30X -Condition (
    $artifactHash -ceq ([string]$State.buildResult.artifactSha256).ToUpperInvariant() -and
    $artifactHash -ceq ([string]$provenance.artifactSha256).ToUpperInvariant() -and
    $artifactBytes -eq [long]$State.buildResult.artifactBytes -and
    $artifactBytes -eq [long]$provenance.artifactBytes -and
    [string]$provenance.artifactPath -ceq [string]$State.buildResult.artifactPath -and
    [string]$provenance.candidateId -ceq [string]$State.candidate.id -and
    [string]$provenance.versionName -ceq [string]$State.candidate.versionName -and
    [string]$provenance.versionCode -ceq [string]$State.candidate.versionCode -and
    [string]$provenance.packageName -ceq 'com.moolsocial.app' -and
    ([string]$provenance.uploadSignerSha256).Replace(':', '').ToUpperInvariant() -ceq
      $expectedSigner -and
    [int]$provenance.releaseRegistrantPluginCount -eq
      [int]$State.toolingQualification.releaseRegistrantPluginCount -and
    [bool]$provenance.packageVersionManifestProved -and
    [bool]$provenance.googleAppIdResourceProved -and
    [bool]$provenance.crashlyticsBuildIdResourceProved -and
    [bool]$provenance.splitAndArm64PayloadProved -and
    -not [bool]$provenance.secretValuesRecorded
  ) -Message 'AAB bytes, identity, signer, plugin count or provenance do not rebind.'

  $keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
  $java = 'C:\Program Files\Android\Android Studio\jbr\bin\java.exe'
  Assert-C30X -Condition (
    (Test-Path -LiteralPath $keytool -PathType Leaf) -and
    (Test-Path -LiteralPath $java -PathType Leaf)
  ) -Message 'Android Studio keytool or Java is unavailable.'
  $certificateOutput = & $keytool -printcert -jarfile $artifact 2>&1
  Assert-C30X -Condition ($LASTEXITCODE -eq 0) `
    -Message 'AAB signer certificate is unreadable.'
  $signerMatch = [regex]::Match(
    ($certificateOutput -join [Environment]::NewLine),
    'SHA256:\s*([0-9A-Fa-f:]{64,95})'
  )
  Assert-C30X -Condition (
    $signerMatch.Success -and
    $signerMatch.Groups[1].Value.Replace(':', '').ToUpperInvariant() -ceq
      $expectedSigner
  ) -Message 'current AAB signer differs from the founder upload certificate.'
  $certificateOutput = $null

  $bundletool = Resolve-C30XFile `
    -Path ([string]$State.toolingQualification.standaloneBundletoolPath) `
    -Label 'standalone bundletool'
  Assert-C30X -Condition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $bundletool).Hash -ceq
      ([string]$State.toolingQualification.standaloneBundletoolSha256).ToUpperInvariant()
  ) -Message 'standalone bundletool identity changed.'
  $package = & $java -jar $bundletool dump manifest `
    "--bundle=$artifact" '--xpath=/manifest/@package' 2>&1
  Assert-C30X -Condition (
    $LASTEXITCODE -eq 0 -and ($package -join '').Trim() -ceq 'com.moolsocial.app'
  ) -Message 'current AAB package proof failed.'
  $versionCode = & $java -jar $bundletool dump manifest `
    "--bundle=$artifact" '--xpath=/manifest/@android:versionCode' 2>&1
  Assert-C30X -Condition (
    $LASTEXITCODE -eq 0 -and
    ($versionCode -join '').Trim() -ceq [string]$State.candidate.versionCode
  ) -Message 'current AAB versionCode proof failed.'
  $versionName = & $java -jar $bundletool dump manifest `
    "--bundle=$artifact" '--xpath=/manifest/@android:versionName' 2>&1
  Assert-C30X -Condition (
    $LASTEXITCODE -eq 0 -and
    ($versionName -join '').Trim() -ceq [string]$State.candidate.versionName
  ) -Message 'current AAB versionName proof failed.'

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [IO.Compression.ZipFile]::OpenRead($artifact)
  try {
    $entries = @($archive.Entries | ForEach-Object { $_.FullName })
    Assert-C30X -Condition (
      $entries -contains 'base/lib/arm64-v8a/libapp.so' -and
      $entries -contains 'base/lib/arm64-v8a/libflutter.so' -and
      $entries -contains 'base/resources.pb' -and
      $entries -contains 'base/manifest/AndroidManifest.xml'
    ) -Message 'current AAB base resources, manifest or arm64 payload is incomplete.'
  } finally {
    $archive.Dispose()
  }
  Assert-C30XSourceManifestCurrent -State $State
}

$statePathResolved = Resolve-C30XFile -Path $StatePath -Label 'C30X state'
$state = Get-Content -Raw -LiteralPath $statePathResolved | ConvertFrom-Json
Assert-C30X -Condition (
  [int]$state.schemaVersion -eq 1 -and
  [string]$state.contractId -ceq
    'SUCCESSOR-AAB-REGRESSION-HARD-GATE-C30X-001' -and
  [string]$state.ticketId -ceq
    'UAW-C30X-SUCCESSOR-AAB-PREPARATION-REGRESSION-HARD-GATE'
) -Message 'state schema, contract or ticket identity changed.'
Assert-C30XScope
Assert-C30XHistoricalFailurePreserved -State $state

$aggregate = Read-C30XJson `
  -Path ([string]$state.aggregateStatePath) `
  -Label 'C30X aggregate state'
Assert-C30X -Condition (
  [string]$aggregate.contractId -ceq
    'SUCCESSOR-AAB-REGRESSION-HARD-GATE-AGGREGATE-C30X-001' -and
  [string]$aggregate.ticketId -ceq [string]$state.ticketId -and
  [string]$aggregate.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$aggregate.candidate.track -ceq 'internal' -and
  [int]$aggregate.historicalFailedCandidate.buildCount -eq 1 -and
  [int]$aggregate.historicalFailedCandidate.uploadCount -eq 1 -and
  [int]$aggregate.historicalFailedCandidate.installCount -eq 1 -and
  -not [bool]$aggregate.historicalFailedCandidate.acceptanceSucceeded
) -Message 'aggregate or failed r60.47 preservation binding changed.'
Assert-C30X -Condition (
  [string]$state.candidate.packageName -ceq 'com.moolsocial.app' -and
  [string]$state.candidate.buildMode -ceq 'release' -and
  [string]$state.candidate.artifactType -ceq 'AAB' -and
  [string]$state.candidate.authorizedTrack -ceq 'internal' -and
  [string]$state.candidate.branch -ceq
    'remediation/prototype-conformance-2026-07-20' -and
  [string]$state.candidate.head -ceq
    'f6dfe7587aa02d782e94282d14af8bafff48ded0' -and
  -not [bool]$state.authority.backendOrHostingDeploymentAuthorized -and
  -not [bool]$state.authority.providerDeploymentAuthorized -and
  -not [bool]$state.authority.emailOrQuotaSubmissionAuthorized -and
  -not [bool]$state.authority.secretValueAccessAuthorized -and
  -not [bool]$state.signingQualification.agentSecretValueAccessAuthorized -and
  -not [bool]$state.runtimeConfiguration.secretDefineFileReadByAgent -and
  -not [bool]$state.runtimeConfiguration.googleServicesFileReadByAgent
) -Message 'package, branch, HEAD or protected authority boundary changed.'
[void](Resolve-C30XFile `
  -Path ([string]$state.founderAuthorization.evidence) `
  -Label 'founder end-to-end authorization evidence')
Assert-C30X -Condition (
  [bool]$state.founderAuthorization.oneSuccessorAabBuildApprovedAfterAllGates -and
  [bool]$state.founderAuthorization.oneInternalTestingUploadAndActivationApprovedAfterPostbuildGate -and
  [bool]$state.founderAuthorization.oneInPlaceOppoPlayUpdateApprovedAfterPostuploadGate -and
  -not [bool]$state.founderAuthorization.productionOpenClosedPublicOrOtherTrackAuthorized -and
  -not [bool]$state.founderAuthorization.adbInstallUninstallDataClearDowngradeOrSideloadAuthorized -and
  -not [bool]$state.founderAuthorization.deploymentAuthorized -and
  -not [bool]$state.founderAuthorization.secretValueAccessAuthorized
) -Message 'founder end-to-end authority or its locked boundaries changed.'
foreach ($requiredPromotionRule in @(
  'allRegressionGatesMustPassBeforeBuild',
  'exactArtifactMustRebindAfterBuildAndImmediatelyBeforeUpload',
  'zeroNewIssuesAfterBuildRequired',
  'zeroNewDefectsAfterBuildRequired',
  'coldStartInteractiveRequired',
  'retainedDataInPlacePlayUpdateRequired',
  'zeroFlutterFatalRequired',
  'zeroAndroidRuntimeFatalRequired',
  'zeroAnrRequired',
  'allMandatoryJourneysRequired'
)) {
  Assert-C30XProperty `
    -Object $state.promotionRule `
    -Name $requiredPromotionRule `
    -Label 'promotion rule'
  Assert-C30X -Condition ([bool]$state.promotionRule.$requiredPromotionRule) `
    -Message "promotion rule weakened: $requiredPromotionRule"
}

$wrapperPath = Resolve-C30XFile `
  -Path 'scripts/invoke-play-internal-aab-build-c30t.ps1' `
  -Label 'single AAB wrapper'
$launcherPath = Resolve-C30XFile `
  -Path ([string]$state.runtimeConfiguration.founderLauncherPath) `
  -Label 'C30X founder launcher'
foreach ($powerShellPath in @($wrapperPath, $launcherPath, $PSCommandPath)) {
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $powerShellPath,
    [ref]$tokens,
    [ref]$errors
  )
  Assert-C30X -Condition (@($errors).Count -eq 0) `
    -Message "PowerShell parser rejected: $powerShellPath"
}
$wrapperSource = Get-Content -Raw -LiteralPath $wrapperPath
$launcherSource = Get-Content -Raw -LiteralPath $launcherPath
Assert-C30X -Condition (
  ([regex]::Matches($wrapperSource, "'appbundle'")).Count -eq 1
) -Message 'single AAB wrapper appbundle invocation count changed.'
foreach ($required in @(
  "'SUCCESSOR-AAB-REGRESSION-HARD-GATE-C30X-001'",
  "'check-successor-aab-regression-hard-gate-c30x.ps1'",
  '$expectedReleaseRegistrantPluginCount = 16',
  '.Count -eq $expectedReleaseRegistrantPluginCount',
  'releaseRegistrantPluginCount = $expectedReleaseRegistrantPluginCount',
  '-Phase build -StatePath $stateFile',
  '-Phase postbuild -StatePath $stateFile'
)) {
  Assert-C30X -Condition (
    $wrapperSource.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "single AAB wrapper binding is missing: $required"
}
Assert-C30X -Condition (
  ([regex]::Matches(
    $launcherSource,
    'Read-Host[^\r\n]*-AsSecureString'
  )).Count -eq 3
) -Message 'C30X launcher must contain exactly three hidden founder prompts.'
foreach ($required in @(
  'SUCCESSOR-AAB-REGRESSION-HARD-GATE-C30X-001',
  'source_qualified_founder_secret_prompt_required',
  'MOOLSOCIAL_FIREBASE_API_KEY',
  'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
  'googleServerClientIdQualifiedByFounder',
  'apps.googleusercontent.com',
  'ZeroFreeBSTR',
  'Remove-Item -LiteralPath $path -Force',
  'invoke-play-internal-aab-build-c30t.ps1'
)) {
  Assert-C30X -Condition (
    $launcherSource.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "C30X founder launcher binding is missing: $required"
}
foreach ($forbidden in @(
  'Write-Host $uploadPassword',
  'Write-Output $uploadPassword',
  'Write-Host $firebaseKey',
  'Write-Output $firebaseKey',
  'Write-Host $googleServerClientId',
  'Write-Output $googleServerClientId',
  'Set-Clipboard',
  'Get-Clipboard'
)) {
  Assert-C30X -Condition (
    $launcherSource.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -lt 0
  ) -Message "C30X founder launcher contains forbidden secret output: $forbidden"
}
Assert-C30X -Condition (-not [regex]::IsMatch(
  $launcherSource,
  '(?i)\b[0-9]{6,}-[0-9a-z_-]{8,}[.]apps[.]googleusercontent[.]com\b'
)) -Message 'C30X founder launcher contains an OAuth client-ID value literal.'

switch ($Phase) {
  'reconcile' {
    $initialAuditContext =
      [string]$state.machineState -ceq
        'prebuild_audit_blocked_no_candidate_no_authority' -and
      [string]$state.sourceQualification.state -ceq
        'fresh_successor_source_manifest_and_two_identical_cycles_pending' -and
      [string]::IsNullOrWhiteSpace(
        [string]$state.sourceQualification.manifestPath
      ) -and
      [string]::IsNullOrWhiteSpace(
        [string]$state.sourceQualification.manifestSha256
      ) -and
      [int]$state.sourceQualification.fileCount -eq 0 -and
      -not [bool]$state.sourceQualification.twoIdenticalCyclesPassed -and
      -not [bool]$state.sourceQualification.completeRegressionGatePassed -and
      -not [bool]$state.sourceQualification.sourceReleaseControlsPassed
    $sourceQualifiedContext =
      [string]$state.machineState -ceq
        'source_qualified_exact_successor_candidate_selection_pending' -and
      [string]$state.sourceQualification.state -ceq
        'two_identical_current_source_cycles_qualified' -and
      -not [string]::IsNullOrWhiteSpace(
        [string]$state.sourceQualification.manifestPath
      ) -and
      -not [string]::IsNullOrWhiteSpace(
        [string]$state.sourceQualification.manifestSha256
      ) -and
      [int]$state.sourceQualification.fileCount -gt 0 -and
      [bool]$state.sourceQualification.twoIdenticalCyclesPassed -and
      [bool]$state.sourceQualification.completeRegressionGatePassed -and
      [bool]$state.sourceQualification.sourceReleaseControlsPassed -and
      -not [bool]$state.sourceQualification.releasePreflightPassed -and
      [string]$aggregate.sourceQualification.state -ceq
        [string]$state.sourceQualification.state -and
      [string]$aggregate.sourceQualification.manifestPath -ceq
        [string]$state.sourceQualification.manifestPath -and
      [string]$aggregate.sourceQualification.manifestSha256 -ceq
        [string]$state.sourceQualification.manifestSha256 -and
      [int]$aggregate.sourceQualification.fileCount -eq
        [int]$state.sourceQualification.fileCount -and
      [int]$aggregate.sourceQualification.identicalQualifyingCycles -eq 2 -and
      [bool]$aggregate.sourceQualification.allRegressionGatesPassed -and
      [bool]$aggregate.sourceQualification.sourceReleaseControlsPassed -and
      -not [bool]$aggregate.sourceQualification.releasePreflightPassed
    Assert-C30X -Condition (
      ($initialAuditContext -or $sourceQualifiedContext) -and
      [string]::IsNullOrWhiteSpace([string]$state.candidate.id) -and
      [string]::IsNullOrWhiteSpace([string]$state.candidate.versionName) -and
      [string]::IsNullOrWhiteSpace([string]$state.candidate.versionCode) -and
      [string]$state.buildAuthorization -ceq 'not_available' -and
      [string]$state.uploadAuthorization -ceq 'not_available' -and
      [string]$state.installAuthorization -ceq 'not_available' -and
      [string]$state.deviceAuthorization -ceq 'not_available' -and
      -not [bool]$state.authority.candidateIdentityApproved -and
      -not [bool]$state.authority.buildAuthorized -and
      -not [bool]$state.authority.uploadAndInternalActivationAuthorized -and
      -not [bool]$state.authority.inPlacePlayUpdateAuthorized -and
      -not [bool]$state.authority.deviceMutationAuthorized -and
      [int]$state.buildResult.buildCount -eq 0 -and
      [int]$state.playResult.uploadCount -eq 0 -and
      [int]$state.installResult.installCount -eq 0 -and
      @($state.regressionQualification.openReleaseBlockers).Count -gt 0
    ) -Message 'initial or source-qualified preparation state must retain no candidate and no release authority.'
    if ($sourceQualifiedContext) {
      Assert-C30XSourceManifestCurrent -State $state
    }
  }
  'build' {
    Assert-C30X -Condition ($PSVersionTable.PSVersion.Major -ge 7) `
      -Message 'build phase requires PowerShell 7.'
    Assert-C30X -Condition (
      [bool]$state.authority.candidateIdentityApproved -and
      [bool]$state.authority.buildAuthorized -and
      [bool]$state.founderAuthorization.candidateIdentitySealed -and
      [bool]$state.founderAuthorization.hiddenFounderInputsEntered -and
      [string]$state.buildAuthorization -ceq 'available_once' -and
      -not [string]::IsNullOrWhiteSpace([string]$state.candidate.id) -and
      [string]$state.candidate.id -cne
        'UAW-C30V-R60-47-SEAL-RECOVERY-PLAY-INTERNAL-ACCEPTANCE' -and
      [string]$state.candidate.versionName -notin @('1.0.0-r60.46', '1.0.0-r60.47') -and
      [string]$state.candidate.versionCode -notin @('2026081346', '2026081347') -and
      [string]$state.runtimeConfiguration.requiredNonSecretDefines.MOOLSOCIAL_CANDIDATE_ID -ceq
        [string]$state.candidate.id -and
      [bool]$state.runtimeConfiguration.secretDefineFileQualifiedByFounder -and
      [bool]$state.runtimeConfiguration.googleServicesFileQualifiedByFounder -and
      [bool]$state.runtimeConfiguration.googleServerClientIdQualifiedByFounder -and
      [bool]$state.sourceQualification.twoIdenticalCyclesPassed -and
      [bool]$state.sourceQualification.completeRegressionGatePassed -and
      [bool]$state.sourceQualification.backendVerifyPassed -and
      [bool]$state.sourceQualification.hostingVerifyPassed -and
      [int]$state.sourceQualification.hostingPassed -eq 8 -and
      [int]$aggregate.sourceQualification.hostingPassed -eq 8 -and
      [int]$state.sourceQualification.hostingPassed -eq
        [int]$aggregate.sourceQualification.hostingPassed -and
      [bool]$state.sourceQualification.focusedSocialSuitePassed -and
      [bool]$state.sourceQualification.analyzerPassed -and
      [bool]$state.sourceQualification.deploymentPassed -and
      [bool]$state.sourceQualification.sourceReleaseControlsPassed -and
      [string]$aggregate.sourceQualification.manifestPath -ceq
        [string]$state.sourceQualification.manifestPath -and
      [string]$aggregate.sourceQualification.manifestSha256 -ceq
        [string]$state.sourceQualification.manifestSha256 -and
      [int]$aggregate.sourceQualification.fileCount -eq
        [int]$state.sourceQualification.fileCount -and
      [int]$aggregate.sourceQualification.identicalQualifyingCycles -eq 2 -and
      [bool]$aggregate.sourceQualification.wholeMobileAnalyzerClean -eq
        [bool]$state.sourceQualification.analyzerPassed -and
      [bool]$aggregate.sourceQualification.sourceReleaseControlsPassed -and
      [bool]$aggregate.sourceQualification.allRegressionGatesPassed -and
      [bool]$state.regressionQualification.approvedUiLocksPassed -and
      @($state.regressionQualification.openReleaseBlockers).Count -eq 0 -and
      [int]$state.regressionQualification.newIssueCountAfterBuild -eq 0 -and
      [int]$state.regressionQualification.newDefectCountAfterBuild -eq 0 -and
      [int]$state.buildResult.buildCount -eq 0 -and
      [int]$aggregate.candidate.buildCount -eq 0
    ) -Message 'candidate identity, authority or all-regression source qualification is incomplete.'
    Assert-C30XSourceManifestCurrent -State $state
    & (Join-Path $root 'scripts/check-codex-development-regression-memory.ps1') `
      -Phase build -BuildMode release -RepositoryRoot $root
    & (Join-Path $root 'scripts/check-mvp-scope-gate-state.ps1') `
      -RequireExecutionAuthorized -RepositoryRoot $root
    & (Join-Path $root 'scripts/check-approved-ui-locks.ps1')
    & (Join-Path $root 'scripts/check-uaw-c31c-chat-forward-recipient-contract.ps1') `
      -RepositoryRoot $root
    & (Join-Path $root 'scripts/check-release-runtime-configuration-c30w.ps1') `
      -Phase build -StatePath $statePathResolved -RepositoryRoot $root
    & (Join-Path $root 'scripts/check-play-internal-aab-build-wrapper-c30v.ps1') `
      -RepositoryRoot $root
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
      (Join-Path $root 'scripts/check-play-internal-aab-build-wrapper-c30v.ps1') `
      -RepositoryRoot $root
    Assert-C30X -Condition ($LASTEXITCODE -eq 0) `
      -Message 'Windows PowerShell wrapper static gate failed.'
    & (Join-Path $root 'scripts/check-c30x-fix2-preflight-order-contract.ps1') `
      -RepositoryRoot $root
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
      (Join-Path $root 'scripts/check-c30x-fix2-preflight-order-contract.ps1') `
      -RepositoryRoot $root
    Assert-C30X -Condition ($LASTEXITCODE -eq 0) `
      -Message 'Windows PowerShell FIX2 preflight-order gate failed.'
  }
  { $_ -in @('postbuild', 'preupload') } {
    Assert-C30X -Condition (
      [string]$state.machineState -ceq
        'single_release_AAB_succeeded_authority_consumed' -and
      [string]$state.buildAuthorization -ceq 'consumed' -and
      [int]$state.buildResult.buildCount -eq 1 -and
      [int]$aggregate.candidate.buildCount -eq 1 -and
      [bool]$state.sourceQualification.releasePreflightPassed -and
      [bool]$aggregate.sourceQualification.releasePreflightPassed -and
      [int]$state.regressionQualification.newIssueCountAfterBuild -eq 0 -and
      [int]$state.regressionQualification.newDefectCountAfterBuild -eq 0
    ) -Message 'postbuild state, count or zero-new-defect rule failed.'
    Assert-C30XArtifactBinding -State $state
    if ($Phase -ceq 'preupload') {
      Assert-C30X -Condition (
        [bool]$state.authority.uploadAndInternalActivationAuthorized -and
        [string]$state.uploadAuthorization -ceq 'available_once' -and
        [int]$state.playResult.uploadCount -eq 0 -and
        [int]$aggregate.candidate.uploadCount -eq 0
      ) -Message 'one Internal Testing upload/activation authority is unavailable.'
    }
  }
  'postupload' {
    Assert-C30X -Condition (
      [string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and
      [string]$state.uploadAuthorization -ceq 'consumed' -and
      [int]$state.playResult.uploadCount -eq 1 -and
      [int]$state.playResult.internalActivationCount -eq 1 -and
      [int]$aggregate.candidate.uploadCount -eq 1
    ) -Message 'postupload state, count or one-upload rule failed.'
    Assert-C30XArtifactBinding -State $state
    $play = Read-C30XJson `
      -Path ([string]$state.playResult.evidencePath) `
      -Label 'Internal Testing activation evidence' `
      -RejectCredentialShapes
    foreach ($name in @(
      'candidateId', 'packageName', 'versionName', 'versionCode',
      'artifactSha256', 'track', 'internalReleaseActive', 'uploadCount',
      'otherTrackChanged'
    )) {
      Assert-C30XProperty -Object $play -Name $name `
        -Label 'Internal Testing activation evidence'
    }
    Assert-C30X -Condition (
      [string]$play.candidateId -ceq [string]$state.candidate.id -and
      [string]$play.packageName -ceq 'com.moolsocial.app' -and
      [string]$play.versionName -ceq [string]$state.candidate.versionName -and
      [string]$play.versionCode -ceq [string]$state.candidate.versionCode -and
      ([string]$play.artifactSha256).ToUpperInvariant() -ceq
        ([string]$state.buildResult.artifactSha256).ToUpperInvariant() -and
      [string]$play.track -ceq 'internal' -and
      [bool]$play.internalReleaseActive -and
      [int]$play.uploadCount -eq 1 -and
      -not [bool]$play.otherTrackChanged
    ) -Message 'Internal Testing activation identity or one-upload rule failed.'
  }
  'preinstall' {
    Assert-C30X -Condition (
      [string]$state.machineState -ceq 'internal_release_active_upload_consumed' -and
      [bool]$state.authority.inPlacePlayUpdateAuthorized -and
      [bool]$state.authority.deviceMutationAuthorized -and
      [string]$state.installAuthorization -ceq 'available_once' -and
      [string]$state.deviceAuthorization -ceq 'available_once' -and
      [int]$state.playResult.uploadCount -eq 1 -and
      [int]$state.installResult.installCount -eq 0 -and
      [int]$aggregate.candidate.installCount -eq 0
    ) -Message 'one in-place OPPO Play-update authority is unavailable.'
  }
  'postinstall' {
    Assert-C30X -Condition (
      [string]$state.machineState -ceq
        'Play_installed_identity_sealed_journeys_pending' -and
      [string]$state.installAuthorization -ceq 'consumed' -and
      [string]$state.deviceAuthorization -ceq 'consumed' -and
      [int]$state.installResult.installCount -eq 1 -and
      [int]$aggregate.candidate.installCount -eq 1 -and
      [int]$state.regressionQualification.newIssueCountAfterBuild -eq 0 -and
      [int]$state.regressionQualification.newDefectCountAfterBuild -eq 0
    ) -Message 'postinstall count, identity state or zero-new-defect rule failed.'
    & (Join-Path $root 'scripts/check-release-runtime-configuration-c30w.ps1') `
      -Phase postinstall `
      -StatePath $statePathResolved `
      -AcceptanceEvidencePath ([string]$state.installResult.coldStartEvidencePath) `
      -RepositoryRoot $root
    $retained = Read-C30XJson `
      -Path ([string]$state.installResult.retainedDataEvidencePath) `
      -Label 'retained-data Play-update evidence' `
      -RejectCredentialShapes
    foreach ($name in @(
      'packageName', 'versionCode', 'installerPackage',
      'firstInstallTimeMillis', 'lastUpdateTimeMillis',
      'firstInstallTimePreserved', 'retainedDataContinuityProved',
      'inPlacePlayUpdateProved', 'uninstallPerformed', 'dataClearPerformed',
      'downgradePerformed', 'adbInstallPerformed'
    )) {
      Assert-C30XProperty -Object $retained -Name $name `
        -Label 'retained-data Play-update evidence'
    }
    Assert-C30X -Condition (
      [string]$retained.packageName -ceq 'com.moolsocial.app' -and
      [string]$retained.versionCode -ceq [string]$state.candidate.versionCode -and
      [string]$retained.installerPackage -ceq 'com.android.vending' -and
      [long]$retained.firstInstallTimeMillis -lt [long]$retained.lastUpdateTimeMillis -and
      [bool]$retained.firstInstallTimePreserved -and
      [bool]$retained.retainedDataContinuityProved -and
      [bool]$retained.inPlacePlayUpdateProved -and
      -not [bool]$retained.uninstallPerformed -and
      -not [bool]$retained.dataClearPerformed -and
      -not [bool]$retained.downgradePerformed -and
      -not [bool]$retained.adbInstallPerformed
    ) -Message 'retained-data in-place Play update proof failed.'
  }
  'journey' {
    $journey = Read-C30XJson `
      -Path ([string]$state.installResult.journeyEvidencePath) `
      -Label 'mandatory whole-app journey evidence' `
      -RejectCredentialShapes
    foreach ($name in @(
      'candidateId', 'versionCode', 'allMandatoryJourneysPassed',
      'newIssueCount', 'newDefectCount', 'blankScreenCount',
      'flutterFatalErrorCount', 'androidRuntimeFatalCount', 'anrCount',
      'evidenceComplete'
    )) {
      Assert-C30XProperty -Object $journey -Name $name `
        -Label 'mandatory whole-app journey evidence'
    }
    Assert-C30X -Condition (
      [string]$state.machineState -ceq
        'acceptance_passed_zero_new_issue_or_defect_promotion_eligible' -and
      [string]$journey.candidateId -ceq [string]$state.candidate.id -and
      [string]$journey.versionCode -ceq [string]$state.candidate.versionCode -and
      [bool]$journey.allMandatoryJourneysPassed -and
      [bool]$journey.evidenceComplete -and
      [int]$journey.newIssueCount -eq 0 -and
      [int]$journey.newDefectCount -eq 0 -and
      [int]$journey.blankScreenCount -eq 0 -and
      [int]$journey.flutterFatalErrorCount -eq 0 -and
      [int]$journey.androidRuntimeFatalCount -eq 0 -and
      [int]$journey.anrCount -eq 0 -and
      [int]$state.regressionQualification.newIssueCountAfterBuild -eq 0 -and
      [int]$state.regressionQualification.newDefectCountAfterBuild -eq 0
    ) -Message 'mandatory journey or zero-new-issue/defect acceptance failed.'
  }
}

Write-Output (
  "C30X successor AAB hard gate passed: phase=$Phase; " +
  "candidateSelected=$(-not [string]::IsNullOrWhiteSpace([string]$state.candidate.id)); " +
  "buildCount=$([int]$state.buildResult.buildCount); " +
  "uploadCount=$([int]$state.playResult.uploadCount); " +
  "installCount=$([int]$state.installResult.installCount); " +
  'historicalR60_47=failed_preserved; secretsRead=false.'
)
