[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$DeploymentMapPath,
  [ValidatePattern('^[A-Za-z][A-Za-z0-9]{2,63}$')]
  [string]$FunctionName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
if (-not $DeploymentMapPath) {
  $DeploymentMapPath = Join-Path $root 'config\social-runtime-deployment-map-r60-92.json'
}
$mapPath = [IO.Path]::GetFullPath($DeploymentMapPath)
$localLibRoot = Join-Path $root 'backend\functions'
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
  [char[]]@('\', '/')
)
$temporaryRoot = [IO.Path]::GetFullPath((Join-Path $temporaryBase (
  'moolsocial-deployed-source-audit-' + [Guid]::NewGuid().ToString('N')
)))

function Assert-SourceAudit([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "Deployed Social source audit rejected: $Message" }
}

function Get-ByteSha256([byte[]]$Bytes) {
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '')
  } finally {
    $sha.Dispose()
  }
}

function Get-GitBlobSha1([byte[]]$Bytes) {
  $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
  $gitBytes = [byte[]]::new($header.Length + $Bytes.Length)
  [Array]::Copy($header, 0, $gitBytes, 0, $header.Length)
  [Array]::Copy($Bytes, 0, $gitBytes, $header.Length, $Bytes.Length)
  $sha = [Security.Cryptography.SHA1]::Create()
  try {
    return ([BitConverter]::ToString($sha.ComputeHash($gitBytes))).Replace('-', '').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Get-NormalizedTextGitBlobSha1([byte[]]$Bytes) {
  $text = [Text.Encoding]::UTF8.GetString($Bytes)
  if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
    $text = $text.Substring(1)
  }
  $normalized = $text.Replace("`r`n", "`n").Replace("`r", "`n")
  return Get-GitBlobSha1 ([Text.UTF8Encoding]::new($false).GetBytes($normalized))
}

function Get-ExactStringSetSha256($Values, [string]$Label) {
  $items = @($Values | ForEach-Object { [string]$_ })
  Assert-SourceAudit ($items.Count -gt 0) "$Label is empty."
  $seen = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
  )
  foreach ($item in $items) {
    Assert-SourceAudit (
      -not [string]::IsNullOrWhiteSpace($item) -and $seen.Add($item)
    ) "$Label is empty or duplicated."
  }
  $sorted = [string[]]$items.Clone()
  [Array]::Sort($sorted, [StringComparer]::Ordinal)
  return Get-ByteSha256 (
    [Text.UTF8Encoding]::new($false).GetBytes(($sorted -join "`n"))
  )
}

function Get-GitTreeBlobSha1(
  [string]$Commit,
  [string]$RepositoryRelativePath
) {
  Assert-SourceAudit ($Commit -cmatch '^[0-9a-f]{40}$') `
    'Git attribution commit is invalid.'
  Assert-SourceAudit (
    $RepositoryRelativePath -cmatch '^[A-Za-z0-9._/-]+$' -and
    $RepositoryRelativePath -notmatch '(^|/)[.][.]($|/)'
  ) 'Git attribution path is invalid.'
  $row = @(& git -C $root ls-tree $Commit -- $RepositoryRelativePath 2>$null)
  $match = if ($row.Count -eq 1) {
    [regex]::Match([string]$row[0], '^100644 blob ([0-9a-f]{40})[\t ]+')
  } else {
    [Text.RegularExpressions.Match]::Empty
  }
  Assert-SourceAudit ($LASTEXITCODE -eq 0 -and $match.Success) `
    'Git attribution blob is missing.'
  return [string]$match.Groups[1].Value
}

function Get-StreamBytes(
  [IO.Stream]$Stream,
  [long]$ExpectedBytes,
  [long]$MaximumBytes
) {
  Assert-SourceAudit (
    $ExpectedBytes -ge 0 -and $ExpectedBytes -le $MaximumBytes
  ) 'archive entry exceeds its size ceiling.'
  $memory = [IO.MemoryStream]::new()
  try {
    $Stream.CopyTo($memory)
    $bytes = $memory.ToArray()
    Assert-SourceAudit ($bytes.Length -eq $ExpectedBytes) `
      'archive entry length differs after read.'
    return $bytes
  } finally {
    $memory.Dispose()
  }
}

function Get-LocalBytes([string]$RelativePath) {
  $path = [IO.Path]::GetFullPath((Join-Path $localLibRoot $RelativePath))
  Assert-SourceAudit (
    $path.StartsWith(
      $localLibRoot + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    ) -and
    (Test-Path -LiteralPath $path -PathType Leaf)
  ) "local compiled module is missing: $RelativePath"
  return [IO.File]::ReadAllBytes($path)
}

function Get-IndexSlice([string]$Text, [string]$FunctionName, [string[]]$AllNames) {
  $marker = "exports.$FunctionName ="
  $start = $Text.LastIndexOf($marker, [StringComparison]::Ordinal)
  Assert-SourceAudit ($start -ge 0) "compiled index omits $FunctionName."
  $end = $Text.Length
  foreach ($otherName in $AllNames) {
    if ($otherName -ceq $FunctionName) { continue }
    $candidate = $Text.LastIndexOf(
      "exports.$otherName =",
      [StringComparison]::Ordinal
    )
    if ($candidate -gt $start -and $candidate -lt $end) { $end = $candidate }
  }
  return $Text.Substring($start, $end - $start)
}

Assert-SourceAudit (Test-Path -LiteralPath $mapPath -PathType Leaf) `
  'deployment map is missing.'
$map = Get-Content -LiteralPath $mapPath -Raw | ConvertFrom-Json -Depth 100
Assert-SourceAudit ($map.schema -ceq 'moolsocial_social_runtime_deployment_map_v1') `
  'deployment map schema changed.'
Assert-SourceAudit (@($map.functions).Count -eq 5) 'exactly five functions are required.'
Assert-SourceAudit (
  $temporaryRoot.StartsWith(
    $temporaryBase + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
  ) -and
  [IO.Path]::GetFileName($temporaryRoot).StartsWith(
    'moolsocial-deployed-source-audit-',
    [StringComparison]::Ordinal
  )
) 'temporary root escaped the exact namespace.'

Add-Type -AssemblyName System.IO.Compression.FileSystem
$functionNames = @($map.functions | ForEach-Object { [string]$_.name })
$expectedRuntimeServiceAccount = @{
  moolSocialPublicAuth = 'public-auth-runtime@moolsocial-dev-503018.iam.gserviceaccount.com'
  youtubeProvider = 'youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com'
  moolSocialChat = 'social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com'
  moolSocialContent = 'social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com'
  youtubeOAuthCallback = 'youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com'
}
$expectedModulePathSetSha256 = @{
  moolSocialPublicAuth = '687612C8055F32B580A1F34641265C7DC5A231E7A69A6059530757A24C01A0EB'
  youtubeProvider = 'CC880CECFEEDA9CA0233BC84E1E7DDBEC28EF30BD965BDF73BCC8A836AA941B4'
  moolSocialChat = '68A46041C05714C59BF424BE8AF28F2F28035C0707E68A57F7EF3447C5FD7A17'
  moolSocialContent = '78CFE140B4A09398EBAF3413DCB5CDE42D6319E862592CC705006C68F8C9A61A'
  youtubeOAuthCallback = '6F5A6357DDCD112BE99FA7FBF38B657D644822FEAC982FF97E5453E4764D3FF7'
}
$expectedMarkerSetSha256 = @{
  moolSocialPublicAuth = 'D928B1C11351B7A92A41492FE0DB697F2645ED9C9AD9BF46D350A9E45901C42F'
  youtubeProvider = 'AF71D034AD76062439DEB24DEA634D33679B2D000170F4C21B6C9DEA36D70C4E'
  moolSocialChat = 'E32CD43F74D4954971D4200E6E6F065D615F845B55C32F73372267318EDA9114'
  moolSocialContent = '20D71D35B49B0C73034EAA82ABE7BF9B2992C422BB2DC34B9E50F160C2C7BCCC'
  youtubeOAuthCallback = 'A12B0B6A99B70F4156354EAD31F698EE30C0144EA1C4B6DF3526560D55925980'
}
$acceptedRuntimeTuple = @{
  MOOLSOCIAL_PROVIDER_ENV = 'dev'
  YOUTUBE_OAUTH_REDIRECT_URI = 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeOAuthCallback'
  YOUTUBE_SOCIAL_AUTH_RUNTIME_ENABLED = 'true'
  YOUTUBE_SOCIAL_RUNTIME_MODE = 'accepted'
}
$selectedFunctions = if ($FunctionName) {
  @($map.functions | Where-Object { [string]$_.name -ceq $FunctionName })
} else {
  @($map.functions)
}
Assert-SourceAudit ($selectedFunctions.Count -in @(1, 5)) `
  'function filter did not resolve exactly.'
$localIndexBytes = Get-LocalBytes 'lib/index.js'
$localIndexText = [Text.Encoding]::UTF8.GetString($localIndexBytes)
$results = @()

try {
  New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
  foreach ($function in $selectedFunctions) {
    $name = [string]$function.name
    $bucket = [string]$function.source.bucket
    $object = [string]$function.source.object
    $generation = [string]$function.source.generation
    Assert-SourceAudit ($name -cmatch '^[A-Za-z][A-Za-z0-9]{2,63}$') `
      'function name is invalid.'
    Assert-SourceAudit ($bucket -cmatch '^[a-z0-9][a-z0-9.-]{2,222}$') `
      'source bucket is invalid.'
    Assert-SourceAudit ($object -ceq "$name/function-source.zip") `
      'source object is not exact.'
    Assert-SourceAudit ($generation -cmatch '^[1-9][0-9]{10,24}$') `
      'source generation is invalid.'
    $moduleSetSha256 = Get-ExactStringSetSha256 `
      $function.requiredModules "$name required modules"
    $markerSetSha256 = Get-ExactStringSetSha256 `
      $function.requiredContractMarkers "$name required markers"
    Assert-SourceAudit (
      $moduleSetSha256 -ceq $expectedModulePathSetSha256[$name] -and
      $moduleSetSha256 -ceq [string]$function.requiredModulePathSetSha256 -and
      $markerSetSha256 -ceq $expectedMarkerSetSha256[$name] -and
      $markerSetSha256 -ceq [string]$function.requiredContractMarkerSetSha256
    ) "$name attestation target set changed."
    $archivePath = Join-Path $temporaryRoot "$name.zip"
    $sourceUri = "gs://$bucket/$object#$generation"
    & gcloud storage cp --quiet $sourceUri $archivePath 2>&1 | Out-Null
    Assert-SourceAudit ($LASTEXITCODE -eq 0) "$name source download failed."
    $generationReadback = @(
      & gcloud storage objects describe $sourceUri `
        --format='value(generation)' 2>$null
    )
    Assert-SourceAudit (
      $LASTEXITCODE -eq 0 -and
      $generationReadback.Count -eq 1 -and
      [string]$generationReadback[0] -ceq $generation
    ) "$name source generation readback differs."
    Assert-SourceAudit (Test-Path -LiteralPath $archivePath -PathType Leaf) `
      "$name source archive is missing."
    $archiveBytes = [IO.File]::ReadAllBytes($archivePath)
    Assert-SourceAudit ($archiveBytes.Length -gt 0 -and $archiveBytes.Length -le 100MB) `
      "$name source archive size is invalid."
    $archiveSha256 = Get-ByteSha256 $archiveBytes

    $zip = [IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
      Assert-SourceAudit ($zip.Entries.Count -gt 0 -and $zip.Entries.Count -le 10000) `
        "$name source entry count is invalid."
      $entryByName = @{}
      [long]$totalUncompressed = 0
      [int]$riskyEntryCount = 0
      [int]$dotenvEntryCount = 0
      [int]$privateCredentialEntryCount = 0
      foreach ($entry in $zip.Entries) {
        $normalized = $entry.FullName.Replace('\', '/').TrimStart('/')
        Assert-SourceAudit (
          -not [string]::IsNullOrWhiteSpace($normalized) -and
          $normalized -notmatch '(^|/)[.][.]($|/)'
        ) "$name contains an unsafe entry name."
        $key = $normalized.ToLowerInvariant()
        Assert-SourceAudit (-not $entryByName.ContainsKey($key)) `
          "$name contains duplicate entry names."
        $entryByName[$key] = $entry
        $totalUncompressed += $entry.Length
        Assert-SourceAudit ($entry.Length -le 100MB) `
          "$name contains an oversized entry."
        Assert-SourceAudit ($totalUncompressed -le 500MB) `
          "$name source archive exceeds its uncompressed ceiling."
        $unixMode = ($entry.ExternalAttributes -shr 16) -band 0xF000
        Assert-SourceAudit ($unixMode -ne 0xA000) `
          "$name contains a symbolic link entry."
        if ($entry.CompressedLength -gt 0) {
          Assert-SourceAudit (($entry.Length / $entry.CompressedLength) -le 200) `
            "$name contains an excessive compression ratio."
        }
        if ($normalized -cmatch '(^|/)(?:[.]env(?:[.]|$)|.*(?:secret|credential|private[-_]?key|service[-_]?account).*)') {
          $riskyEntryCount++
        }
        if ($normalized -cmatch '(^|/)[.]env(?:[.].*)?$') {
          $dotenvEntryCount++
        }
        if ($normalized -cmatch '(^|/)(?:credentials[.]json|service[-_]?account[.]json|.*[.](?:pem|key|p12))$') {
          $privateCredentialEntryCount++
        }
      }
      Assert-SourceAudit (
        $privateCredentialEntryCount -eq 0 -and
        $riskyEntryCount -eq $dotenvEntryCount -and
        $dotenvEntryCount -in @(1, 2)
      ) "$name source archive has an unsanctioned risky entry class."

      $indexKey = 'lib/index.js'
      Assert-SourceAudit ($entryByName.ContainsKey($indexKey)) `
        "$name deployed index is missing."
      $deployedIndexStream = $entryByName[$indexKey].Open()
      try {
        $deployedIndexBytes = Get-StreamBytes `
          $deployedIndexStream $entryByName[$indexKey].Length 10MB
      } finally {
        $deployedIndexStream.Dispose()
      }
      $deployedIndexText = [Text.Encoding]::UTF8.GetString($deployedIndexBytes)
      $localSlice = Get-IndexSlice $localIndexText $name $functionNames
      $deployedSlice = Get-IndexSlice $deployedIndexText $name $functionNames
      $indexSliceMatches = (
        (Get-ByteSha256 ([Text.Encoding]::UTF8.GetBytes($localSlice))) -ceq
        (Get-ByteSha256 ([Text.Encoding]::UTF8.GetBytes($deployedSlice)))
      )

      $moduleResults = @()
      $contractCorpus = $deployedSlice
      foreach ($module in @($function.requiredModules)) {
        $moduleName = [string]$module
        $moduleKey = $moduleName.ToLowerInvariant()
        Assert-SourceAudit ($entryByName.ContainsKey($moduleKey)) `
          "$name deployed module is missing: $moduleName"
        $deployedStream = $entryByName[$moduleKey].Open()
        try {
          $deployedBytes = Get-StreamBytes `
            $deployedStream $entryByName[$moduleKey].Length 10MB
        } finally {
          $deployedStream.Dispose()
        }
        $localBytes = Get-LocalBytes $moduleName
        $moduleResults += [ordered]@{
          path = $moduleName
          localSha256 = Get-ByteSha256 $localBytes
          deployedSha256 = Get-ByteSha256 $deployedBytes
          matches = (Get-ByteSha256 $localBytes) -ceq (Get-ByteSha256 $deployedBytes)
          sourceMatches = $null
          localSourceSha256 = $null
          deployedSourceSha256 = $null
          localSourceGitBlobSha1 = $null
          deployedSourceGitBlobSha1 = $null
          localSourceNormalizedGitBlobSha1 = $null
          deployedSourceNormalizedGitBlobSha1 = $null
        }
        $sourceName = $moduleName.Replace('lib/', 'src/')
        if ($sourceName.EndsWith('.js', [StringComparison]::Ordinal)) {
          $sourceName = $sourceName.Substring(0, $sourceName.Length - 3) + '.ts'
        }
        $sourceKey = $sourceName.ToLowerInvariant()
        if ($entryByName.ContainsKey($sourceKey)) {
          $sourceStream = $entryByName[$sourceKey].Open()
          try {
            $deployedSourceBytes = Get-StreamBytes `
              $sourceStream $entryByName[$sourceKey].Length 10MB
          } finally {
            $sourceStream.Dispose()
          }
          $localSourceBytes = Get-LocalBytes $sourceName
          $moduleResults[-1].sourceMatches = (
            (Get-ByteSha256 $localSourceBytes) -ceq
            (Get-ByteSha256 $deployedSourceBytes)
          )
          $moduleResults[-1].localSourceSha256 = Get-ByteSha256 $localSourceBytes
          $moduleResults[-1].deployedSourceSha256 = Get-ByteSha256 $deployedSourceBytes
          $moduleResults[-1].localSourceGitBlobSha1 = Get-GitBlobSha1 $localSourceBytes
          $moduleResults[-1].deployedSourceGitBlobSha1 = Get-GitBlobSha1 $deployedSourceBytes
          $moduleResults[-1].localSourceNormalizedGitBlobSha1 = `
            Get-NormalizedTextGitBlobSha1 $localSourceBytes
          $moduleResults[-1].deployedSourceNormalizedGitBlobSha1 = `
            Get-NormalizedTextGitBlobSha1 $deployedSourceBytes
        }
        $contractCorpus += [Text.Encoding]::UTF8.GetString($deployedBytes)
      }
      $markersPresent = $true
      foreach ($marker in @($function.requiredContractMarkers)) {
        $markersPresent = $markersPresent -and (
          $contractCorpus.IndexOf([string]$marker, [StringComparison]::Ordinal) -ge 0
        )
      }
      $gitAttributionMatches = $true
      $mismatchedResults = @($moduleResults | Where-Object { -not $_.matches })
      if ($mismatchedResults.Count -gt 0) {
        $deployedCommit = [string]$function.sourceAudit.mismatchedModuleSourceCommit
        $implementedCommit = [string]$function.sourceAudit.implementedModuleSourceCommit
        Assert-SourceAudit ($mismatchedResults.Count -eq 3) `
          "$name Git attribution requires exactly three mismatches."
        foreach ($moduleResult in $mismatchedResults) {
          $sourcePath = ([string]$moduleResult.path).Replace('lib/', 'src/')
          $sourcePath = $sourcePath.Substring(0, $sourcePath.Length - 3) + '.ts'
          $repositoryPath = 'backend/functions/' + $sourcePath
          $deployedBlob = Get-GitTreeBlobSha1 $deployedCommit $repositoryPath
          $implementedBlob = Get-GitTreeBlobSha1 $implementedCommit $repositoryPath
          $gitAttributionMatches = $gitAttributionMatches -and (
            [string]$moduleResult.deployedSourceNormalizedGitBlobSha1 -ceq
              $deployedBlob -and
            [string]$moduleResult.localSourceNormalizedGitBlobSha1 -ceq
              $implementedBlob
          )
        }
        Assert-SourceAudit $gitAttributionMatches `
          "$name deployed or implemented source no longer matches its Git tree."
      }
      $runtimeRaw = @(
        & gcloud functions describe $name --gen2 `
          --region=asia-south1 --project=moolsocial-dev-503018 `
          --format='json(state,buildConfig.runtime,buildConfig.source.storageSource.bucket,buildConfig.source.storageSource.object,buildConfig.source.storageSource.generation,serviceConfig.environmentVariables,serviceConfig.secretEnvironmentVariables,serviceConfig.serviceAccountEmail,serviceConfig.timeoutSeconds,serviceConfig.availableMemory,serviceConfig.maxInstanceCount,serviceConfig.maxInstanceRequestConcurrency)' `
          2>$null
      )
      Assert-SourceAudit ($LASTEXITCODE -eq 0) `
        "$name runtime configuration readback failed."
      $runtime = ($runtimeRaw | Out-String) | ConvertFrom-Json -Depth 30
      $serviceName = $name.ToLowerInvariant()
      $runRaw = @(
        & gcloud run services describe $serviceName `
          --region=asia-south1 --project=moolsocial-dev-503018 `
          --format='json(status.latestCreatedRevisionName,status.latestReadyRevisionName,status.traffic)' `
          2>$null
      )
      Assert-SourceAudit ($LASTEXITCODE -eq 0) `
        "$name Cloud Run revision readback failed."
      $run = ($runRaw | Out-String) | ConvertFrom-Json -Depth 30
      $traffic = @($run.status.traffic)
      $liveIdentityMatches = (
        [string]$runtime.state -ceq [string]$function.liveState -and
        [string]$runtime.buildConfig.runtime -ceq [string]$function.runtime -and
        [string]$runtime.buildConfig.source.storageSource.bucket -ceq $bucket -and
        [string]$runtime.buildConfig.source.storageSource.object -ceq $object -and
        [string]$runtime.buildConfig.source.storageSource.generation -ceq $generation -and
        [string]$run.status.latestCreatedRevisionName -ceq
          [string]$function.latestReadyRevision -and
        [string]$run.status.latestReadyRevisionName -ceq
          [string]$function.latestReadyRevision -and
        $traffic.Count -eq 1 -and
        [int]$traffic[0].percent -eq 100 -and
        [string]$traffic[0].revisionName -ceq
          [string]$function.latestReadyRevision
      )
      Assert-SourceAudit $liveIdentityMatches `
        "$name mapped generation is no longer the 100-percent ready runtime."
      $runtimeExpectation = $function.runtimeConfigurationAudit
      $memoryText = [string]$runtime.serviceConfig.availableMemory
      $expectedMemory = [int]$runtimeExpectation.memoryMiB
      $memoryMatches = $memoryText -cin @(
        "${expectedMemory}M",
        "${expectedMemory}Mi",
        "${expectedMemory}MiB",
        [string]($expectedMemory * 1MB)
      )
      $tupleMatches = $null
      if ([bool]$runtimeExpectation.acceptedNonSecretRuntimeTupleRequired) {
        $tupleMatches = $true
        foreach ($tupleName in $acceptedRuntimeTuple.Keys) {
          $tupleMatches = $tupleMatches -and (
            [string]$runtime.serviceConfig.environmentVariables.$tupleName -ceq
            [string]$acceptedRuntimeTuple[$tupleName]
          )
        }
      }
      $secretBindingValues = @()
      if ($null -ne $runtime.serviceConfig.PSObject.Properties[
          'secretEnvironmentVariables'
        ]) {
        $secretBindingValues = @(
          $runtime.serviceConfig.secretEnvironmentVariables |
            Where-Object { $null -ne $_ }
        )
      }
      $secretBindingCount = $secretBindingValues.Count
      $results += [ordered]@{
        name = $name
        archiveSha256 = $archiveSha256
        entryCount = $zip.Entries.Count
        riskyEntryCount = $riskyEntryCount
        dotenvEntryCount = $dotenvEntryCount
        privateCredentialEntryCount = $privateCredentialEntryCount
        indexSha256 = Get-ByteSha256 $deployedIndexBytes
        localIndexSha256 = Get-ByteSha256 $localIndexBytes
        indexSliceMatches = $indexSliceMatches
        allRequiredModulesMatch = @($moduleResults | Where-Object { -not $_.matches }).Count -eq 0
        requiredContractMarkersPresent = $markersPresent
        runtimeConfiguration = [ordered]@{
          secretBindingCount = $secretBindingCount
          serviceAccountMatches = (
            [string]$runtime.serviceConfig.serviceAccountEmail -ceq
            [string]$expectedRuntimeServiceAccount[$name]
          )
          resourceLimitsMatch = (
            [int]$runtime.serviceConfig.timeoutSeconds -eq
              [int]$runtimeExpectation.timeoutSeconds -and
            $memoryMatches -and
            [int]$runtime.serviceConfig.maxInstanceCount -eq
              [int]$runtimeExpectation.maxInstances -and
            [int]$runtime.serviceConfig.maxInstanceRequestConcurrency -eq
              [int]$runtimeExpectation.concurrency
          )
          acceptedNonSecretRuntimeTupleMatches = $tupleMatches
        }
        liveIdentityMatches = $liveIdentityMatches
        gitAttributionMatches = $gitAttributionMatches
        modules = $moduleResults
      }
    } finally {
      $zip.Dispose()
    }
  }
} finally {
  if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
    $resolved = [IO.Path]::GetFullPath($temporaryRoot)
    Assert-SourceAudit (
      $resolved.StartsWith(
        $temporaryBase + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      ) -and
      [IO.Path]::GetFileName($resolved).StartsWith(
        'moolsocial-deployed-source-audit-',
        [StringComparison]::Ordinal
      )
    ) 'cleanup target changed.'
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}

[ordered]@{
  schema = 'moolsocial_deployed_social_source_audit_result_v1'
  readinessContractId = [string]$map.readinessContractId
  functionCount = $results.Count
  cloudWriteActionCount = 0
  results = $results
} | ConvertTo-Json -Depth 20 -Compress
