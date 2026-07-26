Set-StrictMode -Version Latest

$script:YouTubePrivateDevProject = "moolsocial-dev-503018"
$script:YouTubePrivateDevRegion = "asia-south1"
$script:YouTubePrivateDevMaximumProofMinutes = 30
$script:YouTubePrivateDevAcceptedPublicReviewMode = "accepted"
$script:YouTubePrivateDevAcceptedPublicReviewConfirmation = (
  "KEEP_YOUTUBE_PUBLIC_DATA_REVIEW_LIVE_IN_DEV"
)
$script:YouTubePrivateDevFunctionNames = @(
  "youtubeProvider",
  "youtubeOAuthCallback"
)
$script:YouTubePrivateDevCapabilityKeys = @(
  "YOUTUBE_PUBLIC_DATA_ENABLED",
  "YOUTUBE_OWNER_CONNECT_ENABLED",
  "YOUTUBE_OWNER_ACTIONS_ENABLED",
  "YOUTUBE_CREATOR_ASSETS_ENABLED",
  "YOUTUBE_LIVE_ENABLED",
  "YOUTUBE_PRIVATE_UPLOAD_ENABLED",
  "YOUTUBE_OWNER_ANALYTICS_ENABLED"
)

function Get-YouTubePrivateDevProfile {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
      "Disabled",
      "PublicData",
      "OwnerConnect",
      "OwnerActions",
      "CreatorAssets",
      "Live",
      "PrivateUpload",
      "OwnerAnalytics"
    )]
    [string]$Name
  )

  $flags = [ordered]@{
    YOUTUBE_PUBLIC_DATA_ENABLED = "false"
    YOUTUBE_OWNER_CONNECT_ENABLED = "false"
    YOUTUBE_OWNER_ACTIONS_ENABLED = "false"
    YOUTUBE_CREATOR_ASSETS_ENABLED = "false"
    YOUTUBE_LIVE_ENABLED = "false"
    YOUTUBE_PRIVATE_UPLOAD_ENABLED = "false"
    YOUTUBE_OWNER_ANALYTICS_ENABLED = "false"
  }
  $runtimeName = $null
  $confirmation = "DISABLE_YOUTUBE_PRIVATE_DEV_CAPABILITIES"
  $completion = "END_DISABLED_PROFILE"

  switch ($Name) {
    "PublicData" {
      $flags.YOUTUBE_PUBLIC_DATA_ENABLED = "true"
      $runtimeName = "publicData"
      $confirmation = "PROVE_YOUTUBE_PUBLIC_DATA_PRIVATE_DEV_ONLY"
      $completion = "END_PUBLIC_DATA_PROOF_AND_DISABLE"
    }
    "OwnerConnect" {
      $flags.YOUTUBE_OWNER_CONNECT_ENABLED = "true"
      $runtimeName = "ownerConnect"
      $confirmation = "PROVE_YOUTUBE_OWNER_CONNECT_PRIVATE_DEV_ONLY"
      $completion = "END_OWNER_CONNECT_PROOF_AND_DISABLE"
    }
    "OwnerActions" {
      $flags.YOUTUBE_OWNER_ACTIONS_ENABLED = "true"
      $runtimeName = "ownerActions"
      $confirmation = "PROVE_YOUTUBE_OWNER_ACTIONS_PRIVATE_DEV_ONLY"
      $completion = "END_OWNER_ACTIONS_PROOF_AND_DISABLE"
    }
    "CreatorAssets" {
      $flags.YOUTUBE_CREATOR_ASSETS_ENABLED = "true"
      $runtimeName = "creatorAssets"
      $confirmation = "PROVE_YOUTUBE_CREATOR_ASSETS_PRIVATE_DEV_ONLY"
      $completion = "END_CREATOR_ASSETS_PROOF_AND_DISABLE"
    }
    "Live" {
      $flags.YOUTUBE_LIVE_ENABLED = "true"
      $runtimeName = "live"
      $confirmation = "PROVE_YOUTUBE_LIVE_PRIVATE_DEV_ONLY"
      $completion = "END_LIVE_PROOF_AND_DISABLE"
    }
    "PrivateUpload" {
      $flags.YOUTUBE_PRIVATE_UPLOAD_ENABLED = "true"
      $runtimeName = "privateUpload"
      $confirmation = "PROVE_YOUTUBE_PRIVATE_UPLOAD_PRIVATE_DEV_ONLY"
      $completion = "END_PRIVATE_UPLOAD_PROOF_AND_DISABLE"
    }
    "OwnerAnalytics" {
      $flags.YOUTUBE_OWNER_ANALYTICS_ENABLED = "true"
      $runtimeName = "ownerAnalytics"
      $confirmation = "PROVE_YOUTUBE_OWNER_ANALYTICS_PRIVATE_DEV_ONLY"
      $completion = "END_OWNER_ANALYTICS_PROOF_AND_DISABLE"
    }
  }

  return [pscustomobject]@{
    Name = $Name
    RuntimeName = $runtimeName
    Flags = $flags
    Confirmation = $confirmation
    Completion = $completion
  }
}

function Test-YouTubePrivateDevEffectiveFalse {
  param(
    [AllowNull()]
    [object]$Value
  )

  if ($null -eq $Value) {
    return $true
  }
  return ($Value -is [bool]) -and ($Value -eq $false)
}

function Get-YouTubePrivateDevProofExpiration {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 30)]
    [int]$ProofWindowMinutes,
    [datetimeoffset]$Now = [datetimeoffset]::UtcNow
  )

  if ($ProofWindowMinutes -gt $script:YouTubePrivateDevMaximumProofMinutes) {
    throw "The supervised proof window cannot exceed 30 minutes."
  }
  return $Now.ToUniversalTime().AddMinutes(
    $ProofWindowMinutes
  ).ToString("yyyy-MM-dd'T'HH:mm:ss'Z'")
}

function Test-YouTubePrivateDevProofExpiration {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value,
    [datetimeoffset]$Now = [datetimeoffset]::UtcNow
  )

  $parsed = [datetimeoffset]::MinValue
  $format = "yyyy-MM-dd'T'HH:mm:ss'Z'"
  $valid = [datetimeoffset]::TryParseExact(
    $Value,
    $format,
    [System.Globalization.CultureInfo]::InvariantCulture,
    [System.Globalization.DateTimeStyles]::AssumeUniversal,
    [ref]$parsed
  )
  if (-not $valid) {
    return $false
  }

  $remaining = $parsed.ToUniversalTime() - $Now.ToUniversalTime()
  return (
    $remaining.TotalSeconds -gt 0 -and
    $remaining.TotalMinutes -le $script:YouTubePrivateDevMaximumProofMinutes
  )
}

function Get-YouTubePrivateDevProfileEnvironmentContent {
  param(
    [Parameter(Mandatory = $true)]
    [string]$BaselineContent,
    [Parameter(Mandatory = $true)]
    [ValidateSet(
      "PublicData",
      "OwnerConnect",
      "OwnerActions",
      "CreatorAssets",
      "Live",
      "PrivateUpload",
      "OwnerAnalytics"
    )]
    [string]$Profile,
    [Parameter(Mandatory = $true)]
    [string]$Expiration,
    [datetimeoffset]$Now = [datetimeoffset]::UtcNow
  )

  if (
    -not (Test-YouTubePrivateDevProofExpiration `
      -Value $Expiration `
      -Now $Now)
  ) {
    throw "The supervised proof expiry is outside the safe window."
  }
  $profileContract = Get-YouTubePrivateDevProfile $Profile
  $content = $BaselineContent -replace "`r`n", "`n"
  if (
    $content -match (
      "(?m)^YOUTUBE_(PROOF_(PROFILE|EXPIRES_AT)|" +
      "PUBLIC_DATA_REVIEW_MODE)="
    )
  ) {
    throw "Review and proof controls are forbidden in the immutable baseline."
  }

  foreach ($flag in $script:YouTubePrivateDevCapabilityKeys) {
    $expectedLine = "$flag=false"
    if (
      @(
        [regex]::Matches(
          $content,
          "(?m)^" + [regex]::Escape($expectedLine) + "$"
        )
      ).Count -ne 1
    ) {
      throw "The immutable baseline must contain exactly one $expectedLine."
    }
    $content = $content -replace (
      "(?m)^" + [regex]::Escape($flag) + "=false$"
    ), "$flag=$($profileContract.Flags[$flag])"
  }

  foreach ($flag in $script:YouTubePrivateDevCapabilityKeys) {
    if (
      $content -notmatch (
        "(?m)^" + [regex]::Escape($flag) + "=" +
        [regex]::Escape($profileContract.Flags[$flag]) + "$"
      )
    ) {
      throw "The materialized runtime does not match the proof profile."
    }
  }

  return (
    $content.TrimEnd() +
    "`r`nYOUTUBE_PROOF_PROFILE=$($profileContract.RuntimeName)" +
    "`r`nYOUTUBE_PROOF_EXPIRES_AT=utc:$Expiration`r`n"
  )
}

function Get-YouTubePrivateDevAcceptedPublicReviewEnvironmentContent {
  param(
    [Parameter(Mandatory = $true)]
    [string]$BaselineContent
  )

  $content = $BaselineContent -replace "`r`n", "`n"
  if (
    $content -match (
      "(?m)^YOUTUBE_(PROOF_(PROFILE|EXPIRES_AT)|" +
      "PUBLIC_DATA_REVIEW_MODE)="
    )
  ) {
    throw "Review and proof controls are forbidden in the immutable baseline."
  }

  foreach ($flag in $script:YouTubePrivateDevCapabilityKeys) {
    $expectedLine = "$flag=false"
    if (
      @(
        [regex]::Matches(
          $content,
          "(?m)^" + [regex]::Escape($expectedLine) + "$"
        )
      ).Count -ne 1
    ) {
      throw "The immutable baseline must contain exactly one $expectedLine."
    }
  }

  $content = $content -replace (
    "(?m)^YOUTUBE_PUBLIC_DATA_ENABLED=false$"
  ), "YOUTUBE_PUBLIC_DATA_ENABLED=true"
  foreach ($flag in $script:YouTubePrivateDevCapabilityKeys) {
    $expected = if ($flag -eq "YOUTUBE_PUBLIC_DATA_ENABLED") {
      "true"
    } else {
      "false"
    }
    if ($content -notmatch "(?m)^$flag=$expected$") {
      throw "The accepted public review materialization is unsafe."
    }
  }

  return (
    $content.TrimEnd() +
    "`r`nYOUTUBE_PUBLIC_DATA_REVIEW_MODE=" +
    "$script:YouTubePrivateDevAcceptedPublicReviewMode`r`n"
  )
}
