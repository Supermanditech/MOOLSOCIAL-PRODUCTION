[CmdletBinding()]
param(
  [ValidateSet('Validate', 'Deploy', 'Recover')]
  [string]$Mode = 'Validate',
  [string]$RepositoryRoot,
  [string]$StatePath,
  [string]$Confirmation = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
if (-not $StatePath) {
  $StatePath = Join-Path $root `
    'config\social-runtime-deployment-execution-r60-92.json'
}
$statePathFull = [IO.Path]::GetFullPath($StatePath)
$project = 'moolsocial-dev-503018'
$region = 'asia-south1'
$firebaseOnlyTarget = 'functions:provider:youtubeProvider,functions:provider:youtubeOAuthCallback'
$expectedRuntimeTuple = @{
  MOOLSOCIAL_PROVIDER_ENV = 'dev'
  YOUTUBE_OAUTH_REDIRECT_URI = 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeOAuthCallback'
  YOUTUBE_SOCIAL_AUTH_RUNTIME_ENABLED = 'true'
  YOUTUBE_SOCIAL_RUNTIME_MODE = 'accepted'
}

function Assert-Deploy([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "Social runtime deploy rejected: $Message" }
}

function Get-TextSha256([string]$Text) {
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString(
      $sha.ComputeHash([Text.UTF8Encoding]::new($false).GetBytes($Text))
    )).Replace('-', '')
  } finally {
    $sha.Dispose()
  }
}

function Get-CanonicalFileSha256([string]$Path) {
  $text = [IO.File]::ReadAllText($Path)
  return Get-TextSha256 ($text.Replace("`r`n", "`n").Replace("`r", "`n"))
}

function Invoke-Checked([scriptblock]$Action, [string]$Message) {
  $previous = $ErrorActionPreference
  $native = Get-Variable PSNativeCommandUseErrorActionPreference `
    -ErrorAction SilentlyContinue
  $nativePrevious = if ($null -ne $native) { $native.Value } else { $null }
  try {
    $ErrorActionPreference = 'Continue'
    if ($null -ne $native) { $PSNativeCommandUseErrorActionPreference = $false }
    & $Action
    $exitCode = $LASTEXITCODE
  } finally {
    if ($null -ne $native) {
      $PSNativeCommandUseErrorActionPreference = $nativePrevious
    }
    $ErrorActionPreference = $previous
  }
  Assert-Deploy ($exitCode -eq 0) $Message
}

function Read-GcloudJson([string[]]$Arguments, [string]$Label) {
  $previous = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $rows = @(& gcloud @Arguments --quiet --format=json 2>$null)
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previous
  }
  Assert-Deploy ($exitCode -eq 0) "$Label readback failed."
  try { return (($rows | Out-String).Trim() | ConvertFrom-Json -Depth 100) }
  catch { throw "Social runtime deploy rejected: $Label readback was invalid." }
}

function Read-LiveFunction($Record) {
  $name = [string]$Record.function
  $functionState = Read-GcloudJson @(
    'functions','describe',$name,'--gen2',"--region=$region","--project=$project"
  ) "$name Function"
  $runState = Read-GcloudJson @(
    'run','services','describe',([string]$Record.service),
    "--region=$region","--project=$project"
  ) "$name Cloud Run"
  return [pscustomobject]@{ Record = $Record; Function = $functionState; Run = $runState }
}

function Get-SecretBindingDetails($FunctionState) {
  $bindings = @()
  if ($null -ne $FunctionState.serviceConfig.PSObject.Properties[
      'secretEnvironmentVariables'
    ]) {
    $bindings = @(
      $FunctionState.serviceConfig.secretEnvironmentVariables |
        Where-Object { $null -ne $_ }
    )
  }
  $keys = @($bindings | ForEach-Object { [string]$_.key } | Sort-Object -Unique)
  Assert-Deploy ($keys.Count -eq $bindings.Count) `
    'secret binding contains an empty or duplicate environment key.'
  $resourceLines = @($bindings | ForEach-Object {
    'key=' + [string]$_.key +
      '|project=' + [string]$_.projectId +
      '|secret=' + [string]$_.secret +
      '|version=' + [string]$_.version
  } | Sort-Object)
  $volumes = @()
  if ($null -ne $FunctionState.serviceConfig.PSObject.Properties[
      'secretVolumes'
    ]) {
    $volumes = @($FunctionState.serviceConfig.secretVolumes |
      Where-Object { $null -ne $_ })
  }
  return [pscustomobject]@{
    Count = $bindings.Count
    KeySetSha256 = Get-TextSha256 ($keys -join "`n")
    ResourceSetSha256 = Get-TextSha256 ($resourceLines -join "`n")
    SecretVolumeCount = $volumes.Count
  }
}

function Get-TupleSha256($FunctionState, [bool]$Required) {
  if (-not $Required) { return $null }
  $lines = @()
  foreach ($key in @($expectedRuntimeTuple.Keys | Sort-Object)) {
    $actual = [string]$FunctionState.serviceConfig.environmentVariables.$key
    Assert-Deploy ($actual -ceq [string]$expectedRuntimeTuple[$key]) `
      'accepted non-secret runtime tuple changed.'
    $lines += "$key=$actual"
  }
  return Get-TextSha256 ($lines -join "`n")
}

function Get-LiveFingerprint($Snapshot, [bool]$TupleRequired) {
  $record = $Snapshot.Record
  $functionState = $Snapshot.Function
  $runState = $Snapshot.Run
  $traffic = @($runState.status.traffic)
  $tagCount = @($traffic | Where-Object {
    -not [string]::IsNullOrEmpty([string]$_.tag)
  }).Count
  $secretDetails = Get-SecretBindingDetails $functionState
  $serviceAccountHash = Get-TextSha256 `
    ([string]$functionState.serviceConfig.serviceAccountEmail)
  $tupleHash = Get-TupleSha256 $functionState $TupleRequired
  $invokerDisabled = (
    [string]$runState.metadata.annotations.'run.googleapis.com/invoker-iam-disabled' `
      -ceq 'true'
  )
  $lines = @(
    "function=$([string]$record.function)",
    "revision=$([string]$runState.status.latestReadyRevisionName)",
    "generation=$([string]$functionState.buildConfig.source.storageSource.generation)",
    "runtime=$([string]$functionState.buildConfig.runtime)",
    "traffic=$([int]$traffic[0].percent)",
    "tags=$tagCount",
    "serviceAccountSha256=$serviceAccountHash",
    "timeout=$([int]$functionState.serviceConfig.timeoutSeconds)",
    "memory=$([string]$functionState.serviceConfig.availableMemory)",
    "maxInstances=$([int]$functionState.serviceConfig.maxInstanceCount)",
    "concurrency=$([int]$functionState.serviceConfig.maxInstanceRequestConcurrency)",
    "tupleSha256=$(if ($TupleRequired) { $tupleHash } else { 'NONE' })",
    "secretBindingCount=$($secretDetails.Count)",
    "secretBindingSetSha256=$($secretDetails.KeySetSha256)",
    "invokerIamCheckDisabled=$($invokerDisabled.ToString().ToLowerInvariant())"
  )
  return [pscustomobject]@{
    Fingerprint = Get-TextSha256 ($lines -join "`n")
    ServiceAccountSha256 = $serviceAccountHash
    SecretBindingSetSha256 = $secretDetails.KeySetSha256
    SecretBindingResourceSetSha256 = $secretDetails.ResourceSetSha256
    SecretBindingCount = $secretDetails.Count
    SecretVolumeCount = $secretDetails.SecretVolumeCount
    TupleSha256 = $tupleHash
    TrafficTagCount = $tagCount
    InvokerIamCheckDisabled = $invokerDisabled
  }
}

function Test-Memory([string]$Actual, [int]$MiB) {
  return $Actual -cin @("${MiB}M","${MiB}Mi","${MiB}MiB",[string]($MiB * 1MB))
}

function Assert-LivePosture(
  $Snapshot,
  [string]$Revision,
  [string]$Generation,
  [bool]$TupleRequired,
  [bool]$RequirePredecessorFingerprint
) {
  $record = $Snapshot.Record
  $functionState = $Snapshot.Function
  $runState = $Snapshot.Run
  $traffic = @($runState.status.traffic)
  $fingerprint = Get-LiveFingerprint $Snapshot $TupleRequired
  $secretPosture = @($state.secretBindingPosture | Where-Object {
    $_.function -ceq $record.function
  })[0]
  Assert-Deploy (
    $functionState.state -ceq [string]$record.functionState -and
    $functionState.buildConfig.runtime -ceq [string]$record.runtime -and
    $functionState.buildConfig.source.storageSource.bucket -ceq
      [string]$record.sourceBucket -and
    $functionState.buildConfig.source.storageSource.object -ceq
      [string]$record.sourceObject -and
    [string]$functionState.buildConfig.source.storageSource.generation -ceq
      $Generation -and
    $runState.status.latestCreatedRevisionName -ceq $Revision -and
    $runState.status.latestReadyRevisionName -ceq $Revision -and
    $traffic.Count -eq 1 -and [int]$traffic[0].percent -eq 100 -and
    $traffic[0].revisionName -ceq $Revision -and
    $fingerprint.TrafficTagCount -eq 0 -and
    $fingerprint.ServiceAccountSha256 -ceq [string]$record.serviceAccountSha256 -and
    [int]$functionState.serviceConfig.timeoutSeconds -eq
      [int]$record.timeoutSeconds -and
    (Test-Memory ([string]$functionState.serviceConfig.availableMemory) `
      ([int]$record.memoryMiB)) -and
    [int]$functionState.serviceConfig.maxInstanceCount -eq
      [int]$record.maxInstances -and
    [int]$functionState.serviceConfig.maxInstanceRequestConcurrency -eq
      [int]$record.concurrency -and
    $fingerprint.SecretBindingCount -eq [int]$record.secretBindingCount -and
    $fingerprint.SecretBindingSetSha256 -ceq
      [string]$record.secretBindingIdentitySetSha256 -and
    $fingerprint.SecretBindingResourceSetSha256 -ceq
      [string]$secretPosture.bindingResourceSetSha256 -and
    $fingerprint.SecretVolumeCount -eq [int]$secretPosture.secretVolumeCount -and
    $fingerprint.InvokerIamCheckDisabled -eq
      [bool]$record.invokerIamCheckDisabled -and
    ((-not $TupleRequired) -or
      $fingerprint.TupleSha256 -ceq [string]$record.acceptedNonSecretTupleSha256) -and
    ((-not $RequirePredecessorFingerprint) -or
      $fingerprint.Fingerprint -ceq [string]$record.runtimeFingerprintSha256)
  ) "$($record.function) live source/runtime fingerprint changed."
  return $fingerprint
}

function Read-AllPredecessors($State) {
  $snapshots = @{}
  foreach ($record in @($State.predecessors)) {
    $snapshot = Read-LiveFunction $record
    [void](Assert-LivePosture $snapshot ([string]$record.revision) `
      ([string]$record.sourceGeneration) ([bool]$record.deployTarget) $true)
    $snapshots[[string]$record.function] = $snapshot
  }
  return $snapshots
}

function Assert-LocalRuntimeFile {
  $path = Join-Path $root 'backend\functions\.env.moolsocial-dev-503018'
  Assert-Deploy (Test-Path -LiteralPath $path -PathType Leaf) `
    'ignored deployment runtime file is missing.'
  $text = [IO.File]::ReadAllText($path)
  $normalized = $text.Replace("`r`n", "`n").Replace("`r", "`n")
  $values = @{}
  foreach ($line in @($normalized -split "`n" | Where-Object {
      -not [string]::IsNullOrWhiteSpace($_)
    })) {
    Assert-Deploy ($line -cmatch '^([A-Z][A-Z0-9_]*)=(.*)$') `
      'ignored runtime contains a malformed line.'
    $key = [string]$Matches[1]
    Assert-Deploy (-not $values.ContainsKey($key)) `
      'ignored runtime contains a duplicate key.'
    $values[$key] = [string]$Matches[2]
  }
  Assert-Deploy (
    $values.Count -eq [int]$state.runtimePackage.runtimeFileExactKeyCount -and
    (@($values.Keys | Sort-Object) -join '|') -ceq
      (@($expectedRuntimeTuple.Keys | Sort-Object) -join '|') -and
    (Get-TextSha256 ((@($values.Keys | Sort-Object)) -join "`n")) -ceq
      [string]$state.runtimePackage.runtimeKeySetSha256
  ) 'ignored runtime key inventory changed.'
  foreach ($entry in $expectedRuntimeTuple.GetEnumerator()) {
    Assert-Deploy (
      $values[[string]$entry.Key] -ceq [string]$entry.Value
    ) 'ignored runtime is missing an accepted non-secret value.'
  }
  $materialized = @($values.Keys | Sort-Object | ForEach-Object {
    "$_=$($values[$_])"
  }) -join "`n"
  Assert-Deploy (
    (Get-TextSha256 ($materialized + "`n")) -ceq
      [string]$state.runtimePackage.runtimeMaterializationSha256
  ) 'ignored runtime materialization hash changed.'
  return [IO.File]::ReadAllBytes($path)
}

function Assert-CliAccountBinding($State) {
  $firebaseVersion = (& firebase --version 2>$null | Out-String).Trim()
  $gcloudVersionRows = @(& gcloud version 2>$null)
  $gcloudVersionLine = @($gcloudVersionRows | Where-Object {
    [string]$_ -cmatch '^Google Cloud SDK ([0-9]+[.][0-9]+[.][0-9]+)$'
  })
  Assert-Deploy (
    $firebaseVersion -ceq [string]$State.runtimePackage.firebaseCliVersion -and
    $gcloudVersionLine.Count -eq 1 -and
    ([regex]::Match([string]$gcloudVersionLine[0],
      '([0-9]+[.][0-9]+[.][0-9]+)$').Groups[1].Value) -ceq
      [string]$State.runtimePackage.gcloudCliVersion
  ) 'Firebase or gcloud CLI version changed.'
  $gcloudAccount = (& gcloud config get-value account 2>$null | Out-String).Trim()
  Assert-Deploy ($LASTEXITCODE -eq 0 -and $gcloudAccount.Length -gt 0) `
    'gcloud account readback failed.'
  $firebaseRaw = (& firebase login:list --json 2>$null | Out-String)
  Assert-Deploy ($LASTEXITCODE -eq 0) 'Firebase account readback failed.'
  $firebaseState = $firebaseRaw | ConvertFrom-Json -Depth 20
  $firebaseAccounts = @(
    $firebaseState.result |
      ForEach-Object { [string]$_.user.email } |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
      Sort-Object -Unique
  )
  Assert-Deploy (
    $firebaseAccounts.Count -eq 1 -and
    (Get-TextSha256 $gcloudAccount) -ceq
      [string]$State.runtimePackage.cliAccountSha256 -and
    (Get-TextSha256 $firebaseAccounts[0]) -ceq
      [string]$State.runtimePackage.cliAccountSha256
  ) 'Firebase and gcloud account binding changed.'
}

function New-VerifiedNode22Runtime {
  $version = '22.23.2'
  $archive = "node-v$version-win-x64.zip"
  $expected = '1177B4137BA5ADAA56354AE40F1080C7450E8AE09CECB47DA459D1C52AC99F97'
  $base = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
    [char[]]@('\', '/')
  )
  $temporary = [IO.Path]::GetFullPath((Join-Path $base (
    'moolsocial-node22-deploy-' + [Guid]::NewGuid().ToString('N')
  )))
  Assert-Deploy (
    $temporary.StartsWith($base + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase) -and
    [IO.Path]::GetFileName($temporary).StartsWith('moolsocial-node22-deploy-')
  ) 'Node 22 temporary root escaped.'
  New-Item -ItemType Directory -Path $temporary | Out-Null
  try {
    $archivePath = Join-Path $temporary $archive
    Invoke-WebRequest -UseBasicParsing `
      -Uri "https://nodejs.org/dist/v$version/$archive" -OutFile $archivePath
    Assert-Deploy (
      (Get-FileHash $archivePath -Algorithm SHA256).Hash -ceq $expected
    ) 'Node 22 archive hash changed.'
    Expand-Archive -LiteralPath $archivePath -DestinationPath $temporary
    $nodeRoot = Join-Path $temporary "node-v$version-win-x64"
    Assert-Deploy (
      (& (Join-Path $nodeRoot 'node.exe') --version).Trim() -ceq "v$version"
    ) 'Node 22 runtime identity changed.'
    return [pscustomobject]@{ TemporaryRoot = $temporary; NodeRoot = $nodeRoot }
  } catch {
    Remove-Item -LiteralPath $temporary -Recurse -Force
    throw
  }
}

function Remove-VerifiedNode22Runtime($Runtime) {
  $base = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
    [char[]]@('\', '/')
  )
  $resolved = [IO.Path]::GetFullPath([string]$Runtime.TemporaryRoot)
  Assert-Deploy (
    $resolved.StartsWith($base + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase) -and
    [IO.Path]::GetFileName($resolved).StartsWith('moolsocial-node22-deploy-')
  ) 'Node 22 cleanup target changed.'
  if (Test-Path -LiteralPath $resolved -PathType Container) {
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}

function Write-ReceiptCreate($Receipt, [string]$Path) {
  $json = ($Receipt | ConvertTo-Json -Depth 100) + "`n"
  $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
  $stream = [IO.FileStream]::new(
    $Path,
    [IO.FileMode]::CreateNew,
    [IO.FileAccess]::Write,
    [IO.FileShare]::None
  )
  try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) }
  finally { $stream.Dispose() }
}

function Write-ReceiptReplace($Receipt, [string]$Path) {
  $temporary = $Path + '.tmp-' + [Guid]::NewGuid().ToString('N')
  try {
    [IO.File]::WriteAllText(
      $temporary,
      (($Receipt | ConvertTo-Json -Depth 100) + "`n"),
      [Text.UTF8Encoding]::new($false)
    )
    Move-Item -LiteralPath $temporary -Destination $Path -Force
  } finally {
    if (Test-Path -LiteralPath $temporary -PathType Leaf) {
      Remove-Item -LiteralPath $temporary -Force
    }
  }
}

function Assert-Receipt($Receipt, $State) {
  $names = @($Receipt.PSObject.Properties.Name)
  $expectedNames = @(
    'schema','state','projectId','region','integrationHead',
    'executionStateSha256','confirmationSha256','onlyTargetSha256',
    'authorizationId','authorizationNonceSha256','issuedAtUtc','expiresAtUtc',
    'maxDeployAttempts','firebaseDryRunCommandCount','firebaseDeployCommandCount',
    'rollbackTrafficCommandCount','metadataRestoreCommandCount',
    'cloudWriteActionCount',
    'providerMetadataRestoreClaimed','callbackMetadataRestoreClaimed',
    'providerTrafficRestoreClaimed','callbackTrafficRestoreClaimed',
    'predecessorProviderRevision','predecessorCallbackRevision',
    'newProviderRevision','newProviderSourceGeneration','newCallbackRevision',
    'newCallbackSourceGeneration','preservedFunctionFingerprintSetSha256',
    'postdeployRuntimeFingerprintSetSha256','rollbackTrafficFingerprintSetSha256',
    'updatedAtUtc','privateValuesEmitted'
  )
  Assert-Deploy (
    $names.Count -eq $expectedNames.Count -and
    (@($names | Sort-Object) -join '|') -ceq
      (@($expectedNames | Sort-Object) -join '|')
  ) 'attempt receipt schema changed.'
  $issued = [DateTimeOffset]::MinValue
  $expires = [DateTimeOffset]::MinValue
  $issuedValid = [DateTimeOffset]::TryParseExact(
    [string]$Receipt.issuedAtUtc,
    'yyyy-MM-ddTHH:mm:ss.fffZ',
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal,
    [ref]$issued
  )
  $expiresValid = [DateTimeOffset]::TryParseExact(
    [string]$Receipt.expiresAtUtc,
    'yyyy-MM-ddTHH:mm:ss.fffZ',
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::AssumeUniversal,
    [ref]$expires
  )
  $provider = @($State.predecessors | Where-Object function -eq
    'youtubeProvider')[0]
  $callback = @($State.predecessors | Where-Object function -eq
    'youtubeOAuthCallback')[0]
  Assert-Deploy (
    $Receipt.schema -ceq 'moolsocial_social_runtime_deploy_attempt_v1' -and
    $Receipt.projectId -ceq $project -and $Receipt.region -ceq $region -and
    $Receipt.integrationHead -ceq [string]$State.source.finalIntegrationHead -and
    $Receipt.executionStateSha256 -ceq
      (Get-CanonicalFileSha256 $statePathFull) -and
    $Receipt.confirmationSha256 -ceq
      [string]$State.authority.requiredConfirmationSha256 -and
    $Receipt.onlyTargetSha256 -ceq
      [string]$State.authority.authorizedOnlyTargetSha256 -and
    [string]$Receipt.authorizationId -cmatch
      '^SOCIAL-R60-92-[0-9]{8}T[0-9]{6}Z-[0-9A-F]{8}$' -and
    [string]$Receipt.authorizationNonceSha256 -cmatch '^[0-9A-F]{64}$' -and
    $issuedValid -and $expiresValid -and $expires -gt $issued -and
    ($expires - $issued).TotalMinutes -eq 15 -and
    [int]$Receipt.maxDeployAttempts -eq 1 -and
    [int]$Receipt.firebaseDryRunCommandCount -eq 1 -and
    [int]$Receipt.firebaseDeployCommandCount -in @(0, 1) -and
    [int]$Receipt.rollbackTrafficCommandCount -in @(0, 1, 2) -and
    [int]$Receipt.metadataRestoreCommandCount -in @(0, 1, 2) -and
    [int]$Receipt.cloudWriteActionCount -eq (
      [int]$Receipt.firebaseDeployCommandCount +
      [int]$Receipt.metadataRestoreCommandCount +
      [int]$Receipt.rollbackTrafficCommandCount
    ) -and
    $Receipt.predecessorProviderRevision -ceq [string]$provider.revision -and
    $Receipt.predecessorCallbackRevision -ceq [string]$callback.revision -and
    $Receipt.privateValuesEmitted -eq $false
  ) 'attempt receipt authority, time, count or predecessor binding changed.'
  $metadataClaims = @(
    [bool]$Receipt.providerMetadataRestoreClaimed,
    [bool]$Receipt.callbackMetadataRestoreClaimed
  )
  $trafficClaims = @(
    [bool]$Receipt.providerTrafficRestoreClaimed,
    [bool]$Receipt.callbackTrafficRestoreClaimed
  )
  Assert-Deploy (
    [int]$Receipt.metadataRestoreCommandCount -eq
      @($metadataClaims | Where-Object { $_ }).Count -and
    [int]$Receipt.rollbackTrafficCommandCount -eq
      @($trafficClaims | Where-Object { $_ }).Count
  ) 'attempt receipt per-target command claims do not match counts.'
  if ($Receipt.state -ceq 'attempt_claimed') {
    Assert-Deploy ([int]$Receipt.firebaseDeployCommandCount -eq 0) `
      'unstarted attempt receipt claims a Firebase deploy.'
  } elseif ($Receipt.state -cin @(
      'deployment_started','completed','failed_contained','containment_critical'
    )) {
    Assert-Deploy ([int]$Receipt.firebaseDeployCommandCount -eq 1) `
      'started attempt receipt lacks its one Firebase deploy claim.'
  } elseif ($Receipt.state -cne 'abandoned_before_deploy') {
    throw 'Social runtime deploy rejected: attempt receipt state is invalid.'
  }
}

function Invoke-InvokerPostureRestoration($State, $Receipt, [string]$ReceiptPath) {
  $errors = @()
  foreach ($record in @($State.predecessors | Where-Object deployTarget)) {
    $claimName = if ($record.function -ceq 'youtubeProvider') {
      'providerMetadataRestoreClaimed'
    } else {
      'callbackMetadataRestoreClaimed'
    }
    if ([bool]$Receipt.$claimName) { continue }
    $Receipt.$claimName = $true
    $Receipt.metadataRestoreCommandCount = @(
      [bool]$Receipt.providerMetadataRestoreClaimed,
      [bool]$Receipt.callbackMetadataRestoreClaimed
    ) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
    $Receipt.cloudWriteActionCount = [int]$Receipt.firebaseDeployCommandCount +
      [int]$Receipt.metadataRestoreCommandCount +
      [int]$Receipt.rollbackTrafficCommandCount
    $Receipt.updatedAtUtc = [DateTimeOffset]::UtcNow.ToString(
      'yyyy-MM-ddTHH:mm:ss.fffZ'
    )
    Write-ReceiptReplace $Receipt $ReceiptPath
    try {
      Invoke-Checked {
        & gcloud run services update ([string]$record.service) `
          "--region=$region" "--project=$project" `
          --no-invoker-iam-check --quiet *> $null
      } "Unable to restore $($record.function) invoker posture."
    } catch { $errors += $_.Exception.Message }
  }
  Assert-Deploy ($errors.Count -eq 0) `
    'both invoker-posture restorations were attempted but one or more failed.'
}

function Invoke-TrafficContainment($State, $Receipt, [string]$ReceiptPath) {
  $errors = @()
  try { Invoke-InvokerPostureRestoration $State $Receipt $ReceiptPath }
  catch { $errors += $_.Exception.Message }
  foreach ($record in @($State.predecessors | Where-Object deployTarget)) {
    $claimName = if ($record.function -ceq 'youtubeProvider') {
      'providerTrafficRestoreClaimed'
    } else {
      'callbackTrafficRestoreClaimed'
    }
    if ([bool]$Receipt.$claimName) { continue }
    $Receipt.$claimName = $true
    $Receipt.rollbackTrafficCommandCount = @(
      [bool]$Receipt.providerTrafficRestoreClaimed,
      [bool]$Receipt.callbackTrafficRestoreClaimed
    ) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
    $Receipt.cloudWriteActionCount = [int]$Receipt.firebaseDeployCommandCount +
      [int]$Receipt.metadataRestoreCommandCount +
      [int]$Receipt.rollbackTrafficCommandCount
    $Receipt.updatedAtUtc = [DateTimeOffset]::UtcNow.ToString(
      'yyyy-MM-ddTHH:mm:ss.fffZ'
    )
    Write-ReceiptReplace $Receipt $ReceiptPath
    try {
      Invoke-Checked {
        & gcloud run services update-traffic ([string]$record.service) `
          "--region=$region" "--project=$project" --clear-tags `
          --to-revisions "$([string]$record.revision)=100" --quiet *> $null
      } "Unable to restore $($record.function) predecessor traffic."
    } catch { $errors += $_.Exception.Message }
  }
  $fingerprints = @()
  foreach ($record in @($State.predecessors | Where-Object deployTarget)) {
    try {
      $restored = Read-LiveFunction $record
      $traffic = @($restored.Run.status.traffic)
      $tagCount = @($traffic | Where-Object {
        -not [string]::IsNullOrEmpty([string]$_.tag)
      }).Count
      Assert-Deploy (
        $traffic.Count -eq 1 -and [int]$traffic[0].percent -eq 100 -and
        $traffic[0].revisionName -ceq [string]$record.revision -and
        $tagCount -eq 0
      ) "$($record.function) predecessor traffic was not exclusively restored."
      $fingerprint = Get-LiveFingerprint $restored $true
      Assert-Deploy (
        $fingerprint.ServiceAccountSha256 -ceq
          [string]$record.serviceAccountSha256 -and
        $fingerprint.SecretBindingCount -eq [int]$record.secretBindingCount -and
        $fingerprint.SecretBindingSetSha256 -ceq
          [string]$record.secretBindingIdentitySetSha256 -and
        $fingerprint.SecretBindingResourceSetSha256 -ceq
          [string](@($State.secretBindingPosture | Where-Object {
            $_.function -ceq $record.function
          })[0].bindingResourceSetSha256) -and
        $fingerprint.SecretVolumeCount -eq 0 -and
        $fingerprint.TupleSha256 -ceq
          [string]$record.acceptedNonSecretTupleSha256 -and
        $fingerprint.InvokerIamCheckDisabled -eq $true
      ) "$($record.function) sealed service posture was not restored."
      $fingerprints += "$($record.function)=$($record.revision)=100=tags0"
    } catch { $errors += $_.Exception.Message }
  }
  $Receipt.state = if ($errors.Count -eq 0) { 'failed_contained' } else {
    'containment_critical'
  }
  $Receipt.rollbackTrafficFingerprintSetSha256 = Get-TextSha256 (
    @($fingerprints | Sort-Object) -join "`n"
  )
  $Receipt.updatedAtUtc = [DateTimeOffset]::UtcNow.ToString(
    'yyyy-MM-ddTHH:mm:ss.fffZ'
  )
  Write-ReceiptReplace $Receipt $ReceiptPath
  Assert-Deploy ($errors.Count -eq 0) `
    'both predecessor traffic restorations were attempted but containment is incomplete.'
}

function Test-BoundedRejection([string]$Uri, [ValidateSet('GET','POST')]$Method) {
  try {
    if ($Method -ceq 'POST') {
      Invoke-WebRequest -UseBasicParsing -Method Post -Uri $Uri `
        -ContentType 'application/json' -Body '{}' -MaximumRedirection 0 | Out-Null
    } else {
      Invoke-WebRequest -UseBasicParsing -Method Get -Uri $Uri `
        -MaximumRedirection 0 | Out-Null
    }
    return $false
  } catch {
    return [int]$_.Exception.Response.StatusCode -in @(400, 401, 403, 405)
  }
}

function Assert-IntegrationStillExact($State) {
  $head = (& git -C $root rev-parse HEAD).Trim()
  $branch = (& git -C $root branch --show-current).Trim()
  $ref = 'refs/heads/' + [string]$State.source.finalIntegrationBranch
  $remoteRows = @(& git -C $root ls-remote --exit-code --heads origin $ref `
    2>$null)
  $remoteHead = if ($remoteRows.Count -eq 1) {
    ([string]$remoteRows[0] -split '\s+')[0]
  } else { '' }
  $dirt = @(& git -C $root status --porcelain=v1 --untracked-files=normal)
  $tree = @(& git -C $root rev-parse ($head + ':backend/functions') 2>$null)
  Assert-Deploy (
    $branch -ceq [string]$State.source.finalIntegrationBranch -and
    $head -ceq [string]$State.source.finalIntegrationHead -and
    $head -ceq [string]$State.source.finalIntegrationRemoteHead -and
    $head -ceq $remoteHead -and
    $dirt.Count -eq 0 -and
    $tree.Count -eq 1 -and
    [string]$tree[0] -ceq [string]$State.source.backendFunctionsTree -and
    (Get-CanonicalFileSha256 $statePathFull) -ceq
      (Get-CanonicalFileSha256 (Join-Path $root `
        'config\social-runtime-deployment-execution-r60-92.json'))
  ) 'integration HEAD, remote, clean state or backend tree changed during preflight.'
}

Assert-Deploy (
  $statePathFull.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
  (Test-Path -LiteralPath $statePathFull -PathType Leaf)
) 'execution state is missing or outside the repository.'
$state = Get-Content -LiteralPath $statePathFull -Raw | ConvertFrom-Json -Depth 100
$checker = Join-Path $root `
  'scripts\check-social-runtime-deployment-execution-r60-92.ps1'
$receiptPath = [IO.Path]::GetFullPath((Join-Path $root `
  ([string]$state.authority.attemptReceiptPath)))

if ($Mode -ceq 'Recover') {
  & $checker -RepositoryRoot $root -StatePath $statePathFull -Phase Recovery |
    Out-Null
  $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json -Depth 100
  Assert-Receipt $receipt $state
  if ($receipt.state -ceq 'attempt_claimed') {
    $receipt.state = 'abandoned_before_deploy'
    $receipt.updatedAtUtc = [DateTimeOffset]::UtcNow.ToString(
      'yyyy-MM-ddTHH:mm:ss.fffZ'
    )
    Write-ReceiptReplace $receipt $receiptPath
    Write-Output 'Social runtime recovery found no started deploy; cloudWrites=0.'
    return
  }
  Assert-Deploy ($receipt.state -cin @('deployment_started','containment_critical')) `
    'recovery is allowed only for a started uncontained deployment.'
  Invoke-TrafficContainment $state $receipt $receiptPath
  Write-Output 'Social runtime deployment recovery contained both predecessor traffic routes.'
  return
}

& $checker -RepositoryRoot $root -StatePath $statePathFull -Phase $(
  if ($Mode -ceq 'Deploy') { 'RemoteReady' } else { 'Prepared' }
) | Out-Null
$runtimeBytes = $null
if ($Mode -ceq 'Deploy') { $runtimeBytes = Assert-LocalRuntimeFile }
$scriptText = [IO.File]::ReadAllText($MyInvocation.MyCommand.Path)
Assert-Deploy (
  [regex]::Matches($scriptText, [regex]::Escape($firebaseOnlyTarget)).Count -eq 1 -and
  $scriptText.Contains('--clear-tags', [StringComparison]::Ordinal) -and
  $scriptText.Contains("[ValidateSet('Validate', 'Deploy', 'Recover')]",
    [StringComparison]::Ordinal)
) 'executor source no longer binds exact target, recovery and clear-tags rollback.'

if ($Mode -ceq 'Validate') {
  Write-Output (
    'Social runtime deployment executor validation passed: deployFunctions=2; ' +
    'preserveFunctions=3; dryRuns=0; deploys=0; cloudWrites=0; authorityHeld=true.'
  )
  return
}

Assert-Deploy ($Confirmation -ceq [string]$state.authority.requiredConfirmation) `
  'exact one-use founder confirmation is missing.'
Assert-Deploy (
  (Get-TextSha256 $Confirmation) -ceq
    [string]$state.authority.requiredConfirmationSha256 -and
  (Get-TextSha256 $firebaseOnlyTarget) -ceq
    [string]$state.authority.authorizedOnlyTargetSha256 -and
  -not (Test-Path -LiteralPath $receiptPath)
) 'confirmation, target binding or one-use receipt state changed.'
Assert-CliAccountBinding $state

$nodeRuntime = New-VerifiedNode22Runtime
$previousPath = $env:PATH
$deploymentAttempted = $false
$deploymentVerified = $false
$primaryFailure = $null
$receipt = $null
$rollbackFailure = $null
$cleanupFailures = @()
try {
  $env:PATH = [string]$nodeRuntime.NodeRoot + [IO.Path]::PathSeparator +
    $previousPath
  Push-Location (Join-Path $root 'backend\functions')
  try {
    Invoke-Checked { & npm.cmd ci --ignore-scripts --no-audit --fund=false } `
      'Node 22 locked dependency install failed.'
    Invoke-Checked { & npm.cmd run verify } 'Node 22 backend verification failed.'
  } finally { Pop-Location }

  Invoke-Checked {
    & firebase deploy --only $firebaseOnlyTarget --project $project `
      --message 'R60.92 provider and callback atomic-quota dry run' --dry-run
  } 'exact two-function Firebase dry run failed.'
  & (Join-Path $root 'scripts\check-social-runtime-deployment-map-r60-92.ps1') `
    -RepositoryRoot $root -VerifyLiveSource | Out-Null
  $before = Read-AllPredecessors $state
  & $checker -RepositoryRoot $root -StatePath $statePathFull `
    -Phase RemoteReady | Out-Null
  Assert-IntegrationStillExact $state

  $now = [DateTimeOffset]::UtcNow
  $nonceBytes = [byte[]]::new(32)
  [Security.Cryptography.RandomNumberGenerator]::Fill($nonceBytes)
  $nonceHash = Get-TextSha256 ([Convert]::ToBase64String($nonceBytes))
  $receipt = [ordered]@{
    schema = 'moolsocial_social_runtime_deploy_attempt_v1'
    state = 'attempt_claimed'
    projectId = $project
    region = $region
    integrationHead = [string]$state.source.finalIntegrationHead
    executionStateSha256 = Get-CanonicalFileSha256 $statePathFull
    confirmationSha256 = Get-TextSha256 $Confirmation
    onlyTargetSha256 = Get-TextSha256 $firebaseOnlyTarget
    authorizationId = 'SOCIAL-R60-92-' + $now.ToString('yyyyMMddTHHmmssZ') +
      '-' + $nonceHash.Substring(0, 8)
    authorizationNonceSha256 = $nonceHash
    issuedAtUtc = $now.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    expiresAtUtc = $now.AddMinutes(15).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    maxDeployAttempts = 1
    firebaseDryRunCommandCount = 1
    firebaseDeployCommandCount = 0
    rollbackTrafficCommandCount = 0
    metadataRestoreCommandCount = 0
    cloudWriteActionCount = 0
    providerMetadataRestoreClaimed = $false
    callbackMetadataRestoreClaimed = $false
    providerTrafficRestoreClaimed = $false
    callbackTrafficRestoreClaimed = $false
    predecessorProviderRevision = [string](
      @($state.predecessors | Where-Object function -eq 'youtubeProvider')[0].revision
    )
    predecessorCallbackRevision = [string](
      @($state.predecessors | Where-Object function -eq 'youtubeOAuthCallback')[0].revision
    )
    newProviderRevision = ''
    newProviderSourceGeneration = ''
    newCallbackRevision = ''
    newCallbackSourceGeneration = ''
    preservedFunctionFingerprintSetSha256 = ''
    postdeployRuntimeFingerprintSetSha256 = ''
    rollbackTrafficFingerprintSetSha256 = ''
    updatedAtUtc = $now.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    privateValuesEmitted = $false
  }
  Write-ReceiptCreate $receipt $receiptPath
  Assert-Receipt $receipt $state
  Assert-Deploy (
    [DateTimeOffset]::ParseExact(
      [string]$receipt.expiresAtUtc,
      'yyyy-MM-ddTHH:mm:ss.fffZ',
      [Globalization.CultureInfo]::InvariantCulture
    ) -gt [DateTimeOffset]::UtcNow
  ) 'one-use authority expired before deployment start.'

  $receipt.state = 'deployment_started'
  $receipt.firebaseDeployCommandCount = 1
  $receipt.cloudWriteActionCount = 1
  $receipt.updatedAtUtc = [DateTimeOffset]::UtcNow.ToString(
    'yyyy-MM-ddTHH:mm:ss.fffZ'
  )
  Write-ReceiptReplace $receipt $receiptPath
  Assert-Receipt $receipt $state
  $deploymentAttempted = $true
  Invoke-Checked {
    & firebase deploy --only $firebaseOnlyTarget --project $project `
      --message 'R60.92 provider and callback atomic quota runtime only'
  } 'exact two-function Firebase deployment failed.'
  Invoke-InvokerPostureRestoration $state $receipt $receiptPath

  $after = @{}
  $postFingerprints = @()
  $preservedFingerprints = @()
  foreach ($record in @($state.predecessors)) {
    $snapshot = Read-LiveFunction $record
    $after[[string]$record.function] = $snapshot
    if ([bool]$record.deployTarget) {
      $revision = [string]$snapshot.Run.status.latestReadyRevisionName
      $generation = [string]$snapshot.Function.buildConfig.source.storageSource.generation
      Assert-Deploy (
        $revision -cne [string]$record.revision -and
        $generation -cne [string]$record.sourceGeneration
      ) "$($record.function) did not advance revision and source."
      $fingerprint = Assert-LivePosture $snapshot $revision $generation $true $false
      $postFingerprints += "$($record.function)=$($fingerprint.Fingerprint)"
      if ($record.function -ceq 'youtubeProvider') {
        $receipt.newProviderRevision = $revision
        $receipt.newProviderSourceGeneration = $generation
      } else {
        $receipt.newCallbackRevision = $revision
        $receipt.newCallbackSourceGeneration = $generation
      }
    } else {
      $fingerprint = Assert-LivePosture $snapshot ([string]$record.revision) `
        ([string]$record.sourceGeneration) $false $true
      $preservedFingerprints += "$($record.function)=$($fingerprint.Fingerprint)"
    }
  }

  $temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
    [char[]]@('\', '/')
  )
  $temporaryRoot = [IO.Path]::GetFullPath((Join-Path $temporaryBase (
    'moolsocial-postdeploy-source-audit-' + [Guid]::NewGuid().ToString('N')
  )))
  try {
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    $dynamicMap = Get-Content -LiteralPath (
      Join-Path $root 'config\social-runtime-deployment-map-r60-92.json'
    ) -Raw | ConvertFrom-Json -Depth 100
    foreach ($name in @('youtubeProvider','youtubeOAuthCallback')) {
      $function = @($dynamicMap.functions | Where-Object name -eq $name)[0]
      $snapshot = $after[$name]
      $function.source.generation = [string]$snapshot.Function.buildConfig.source.storageSource.generation
      $function.latestReadyRevision = [string]$snapshot.Run.status.latestReadyRevisionName
      $function.sourceAudit.requiredModuleMatchCount =
        [int]$function.sourceAudit.requiredModuleCount
      $function.sourceAudit.mismatchedModules = @()
    }
    $dynamicMapPath = Join-Path $temporaryRoot 'deployment-map.json'
    [IO.File]::WriteAllText(
      $dynamicMapPath,
      (($dynamicMap | ConvertTo-Json -Depth 100) + "`n"),
      [Text.UTF8Encoding]::new($false)
    )
    foreach ($name in @('youtubeProvider','youtubeOAuthCallback')) {
      $auditRaw = (& (Join-Path $root `
          'scripts\audit-deployed-social-function-source-r60-92.ps1') `
        -RepositoryRoot $root -DeploymentMapPath $dynamicMapPath `
        -FunctionName $name | Out-String)
      $audit = $auditRaw | ConvertFrom-Json -Depth 100
      $result = @($audit.results)[0]
      Assert-Deploy (
        $result.indexSliceMatches -eq $true -and
        $result.allRequiredModulesMatch -eq $true -and
        $result.requiredContractMarkersPresent -eq $true -and
        [int]$result.privateCredentialEntryCount -eq 0 -and
        $result.liveIdentityMatches -eq $true -and
        $result.runtimeConfiguration.acceptedNonSecretRuntimeTupleMatches -eq $true
      ) "$name deployed source differs from final integration."
    }
  } finally {
    if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
      $resolved = [IO.Path]::GetFullPath($temporaryRoot)
      Assert-Deploy (
        $resolved.StartsWith($temporaryBase + [IO.Path]::DirectorySeparatorChar,
          [StringComparison]::OrdinalIgnoreCase) -and
        [IO.Path]::GetFileName($resolved).StartsWith(
          'moolsocial-postdeploy-source-audit-')
      ) 'postdeploy audit cleanup target changed.'
      Remove-Item -LiteralPath $resolved -Recurse -Force
    }
  }

  Assert-Deploy (
    (Test-BoundedRejection ([string]$after.youtubeProvider.Function.serviceConfig.uri) `
      'POST') -and
    (Test-BoundedRejection ([string]$after.youtubeOAuthCallback.Function.serviceConfig.uri) `
      'GET')
  ) 'bounded postdeploy route smoke failed.'
  $receipt.preservedFunctionFingerprintSetSha256 = Get-TextSha256 (
    @($preservedFingerprints | Sort-Object) -join "`n"
  )
  $receipt.postdeployRuntimeFingerprintSetSha256 = Get-TextSha256 (
    @($postFingerprints | Sort-Object) -join "`n"
  )
  Assert-IntegrationStillExact $state
  $receipt.state = 'completed'
  $receipt.updatedAtUtc = [DateTimeOffset]::UtcNow.ToString(
    'yyyy-MM-ddTHH:mm:ss.fffZ'
  )
  Write-ReceiptReplace $receipt $receiptPath
  Assert-Receipt $receipt $state
  $deploymentVerified = $true
} catch {
  $primaryFailure = $_
} finally {
  if ($deploymentAttempted -and -not $deploymentVerified) {
    try { Invoke-TrafficContainment $state $receipt $receiptPath }
    catch { $rollbackFailure = $_ }
  }
  $env:PATH = $previousPath
  try { Remove-VerifiedNode22Runtime $nodeRuntime }
  catch { $cleanupFailures += $_.Exception.Message }
  try {
    $runtimePath = Join-Path $root `
      'backend\functions\.env.moolsocial-dev-503018'
    [IO.File]::WriteAllBytes($runtimePath, [byte[]]$runtimeBytes)
    Assert-Deploy (
      [Convert]::ToBase64String([IO.File]::ReadAllBytes($runtimePath)) -ceq
        [Convert]::ToBase64String([byte[]]$runtimeBytes)
    ) 'ignored deployment runtime was not restored byte-for-byte.'
  } catch { $cleanupFailures += $_.Exception.Message }
}

if ($null -ne $rollbackFailure) {
  throw 'Deployment failed and dual predecessor traffic containment is incomplete.'
}
if ($cleanupFailures.Count -gt 0) {
  throw 'Deployment runtime cleanup or byte restoration failed after containment.'
}
if ($null -ne $primaryFailure) { throw $primaryFailure }

Write-Output (
  'Social runtime deployment completed: deployFunctions=2; preserveFunctions=3; ' +
  'firebaseDeploys=1; rollbackCommands=0; privateValuesEmitted=false.'
)
