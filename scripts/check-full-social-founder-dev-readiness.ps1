[CmdletBinding()]
param(
  [string]$StatePath =
    'config/public-auth-live-provider-readiness-state-c34p-fix5.json',

  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$prefix = $root + [IO.Path]::DirectorySeparatorChar
$resolvedState = if ([IO.Path]::IsPathRooted($StatePath)) {
  [IO.Path]::GetFullPath($StatePath)
} else {
  [IO.Path]::GetFullPath((Join-Path $root $StatePath))
}

function Assert-FullSocialReadiness([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Full-social founder Dev readiness rejected: $Message"
  }
}

Assert-FullSocialReadiness (
  $resolvedState.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
  (Test-Path -LiteralPath $resolvedState -PathType Leaf)
) 'state is missing or escaped the production repository.'

try {
  $state = Get-Content -LiteralPath $resolvedState -Raw | ConvertFrom-Json
} catch {
  throw 'Full-social founder Dev readiness rejected: state JSON is invalid.'
}

$acceptance = $state.founderDevProviderAcceptance
Assert-FullSocialReadiness ($null -ne $acceptance) `
  'explicit founder Dev provider acceptance is absent.'
Assert-FullSocialReadiness (
  [string]$acceptance.ticketId -ceq
    'UAW-C34P-FIX9-CROSS-PROVIDER-RETURN-TRUTH-HARD-GATE' -and
  [string]$acceptance.scope -ceq
    'founder_private_dev_sideload_not_public_release' -and
  [bool]$acceptance.brokerFunctionReadbackQualified -and
  [bool]$acceptance.xRoleAcceptanceQualified -and
  [bool]$acceptance.instagramRoleAcceptanceQualified -and
  [bool]$acceptance.facebookRoleAcceptanceQualified -and
  [bool]$acceptance.facebookBuildInputsPresenceQualified -and
  [bool]$acceptance.facebookSideloadKeyHashQualifiedByFounder -and
  [bool]$acceptance.youtubeSharedGoogleIdentityBridgeQualified -and
  -not [bool]$acceptance.publicReleaseOrAppReviewQualified -and
  -not [bool]$acceptance.secretValuesObserved -and
  [int]$acceptance.agentPrivateLoginCount -eq 0 -and
  [int]$acceptance.buildCountSinceAcceptance -eq 0 -and
  [int]$acceptance.installCountSinceAcceptance -eq 0
) 'one or more explicit founder Dev provider facts are not qualified.'

[pscustomobject]@{
  state = 'FULL_SOCIAL_FOUNDER_DEV_READINESS_QUALIFIED'
  scope = 'founder_private_dev_sideload_not_public_release'
  providers = 3
  brokerReadback = $true
  youtubeSharedGoogleIdentityBridge = $true
  youtubeFix7AccountErasureBindings =
    [bool]$acceptance.youtubeFix7AccountErasureBindingsQualified
  secretValuesEmitted = $false
  buildCount = 0
  installCount = 0
} | ConvertTo-Json -Compress
