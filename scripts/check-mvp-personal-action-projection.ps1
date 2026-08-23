[CmdletBinding()]
param(
  [string]$ProjectionPath,

  [string]$SchemaPath,

  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$repositoryRootFull = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$repositoryPrefix = $repositoryRootFull + [IO.Path]::DirectorySeparatorChar
if (-not $ProjectionPath) {
  $ProjectionPath = Join-Path `
    $repositoryRootFull `
    'config/mvp-personal-action-projection-v1.json'
}
if (-not $SchemaPath) {
  $SchemaPath = Join-Path `
    $repositoryRootFull `
    'contracts/journeys/uaw-r01-personal-action-projection-v1.schema.json'
}

function Assert-PersonalActionProjection {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) {
    throw "Personal action projection rejected: $Message"
  }
}

function Resolve-ProjectionRepositoryFile {
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Label
  )

  Assert-PersonalActionProjection `
    -Condition (-not [string]::IsNullOrWhiteSpace($Path)) `
    -Message "$Label path is missing."
  $resolved = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $repositoryRootFull $Path))
  }
  Assert-PersonalActionProjection -Condition (
    $resolved.StartsWith(
      $repositoryPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )
  ) -Message "$Label escaped the production repository."
  Assert-PersonalActionProjection `
    -Condition (Test-Path -LiteralPath $resolved -PathType Leaf) `
    -Message "$Label is missing: $resolved"
  return $resolved
}

function Assert-ExactIdSequence {
  param(
    [Parameter(Mandatory)]
    [object[]]$Items,

    [Parameter(Mandatory)]
    [string[]]$Expected,

    [Parameter(Mandatory)]
    [string]$Label
  )

  $actual = @($Items | ForEach-Object { [string]$_.id })
  Assert-PersonalActionProjection -Condition (
    ($actual -join '|') -ceq ($Expected -join '|')
  ) -Message "$Label ids differ; expected '$($Expected -join ',')', got '$($actual -join ',')'."
}

function Assert-ActionNode {
  param(
    [Parameter(Mandatory)]
    [object]$Action,

    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [System.Collections.Generic.HashSet[string]]$SeenIds
  )

  $id = [string]$Action.id
  Assert-PersonalActionProjection `
    -Condition (-not [string]::IsNullOrWhiteSpace($id)) `
    -Message 'an action id is missing.'
  Assert-PersonalActionProjection `
    -Condition ($SeenIds.Add($id)) `
    -Message "duplicate action id '$id'."
  Assert-PersonalActionProjection `
    -Condition (-not [string]::IsNullOrWhiteSpace([string]$Action.label)) `
    -Message "label is missing for '$id'."
  Assert-PersonalActionProjection `
    -Condition (-not [string]::IsNullOrWhiteSpace([string]$Action.routeOwner)) `
    -Message "route owner is missing for '$id'."
  Assert-PersonalActionProjection -Condition (
    [string]$Action.disposition -cin @('active', 'dependency_held')
  ) -Message "unsupported disposition for '$id'."
  if ([string]$Action.disposition -ceq 'dependency_held') {
    Assert-PersonalActionProjection `
      -Condition (@($Action.dependencies).Count -gt 0) `
      -Message "held action '$id' has no dependency."
  }
  foreach ($dependency in @($Action.dependencies)) {
    Assert-PersonalActionProjection -Condition (
      -not [string]::IsNullOrWhiteSpace([string]$dependency)
    ) -Message "action '$id' has an empty dependency."
  }
}

function ConvertTo-ProjectionDateTimeOffset {
  param(
    [Parameter(Mandatory)]
    [object]$Value
  )

  if ($Value -is [DateTimeOffset]) {
    return [DateTimeOffset]$Value
  }
  if ($Value -is [DateTime]) {
    return [DateTimeOffset]([DateTime]$Value)
  }
  return [DateTimeOffset]::Parse(
    [string]$Value,
    [Globalization.CultureInfo]::InvariantCulture,
    [Globalization.DateTimeStyles]::RoundtripKind
  )
}

function Test-MvpPersonalActionProjection {
  param(
    [Parameter(Mandatory)]
    [object]$Projection,

    [string]$ResolvedSchemaPath
  )

  Assert-PersonalActionProjection -Condition (
    [int]$Projection.schemaVersion -eq 1
  ) -Message 'unsupported schema version.'
  Assert-PersonalActionProjection -Condition (
    [string]$Projection.contractId -ceq
      'UAW-R01-PERSONAL-ACTION-PROJECTION-CONTRACT-V1'
  ) -Message 'unexpected contract id.'
  Assert-PersonalActionProjection -Condition (
    [string]$Projection.projectionId -ceq 'personal_user_mvp_launch'
  ) -Message 'unexpected projection id.'
  Assert-PersonalActionProjection -Condition (
    [string]$Projection.projectionVersion -cmatch
      '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.[0-9]+$'
  ) -Message 'projection version is invalid.'
  Assert-PersonalActionProjection -Condition (
    [string]$Projection.projectionState -ceq
      'static_reference_fixture_not_runtime_authority'
  ) -Message 'checked-in projection incorrectly claims runtime authority.'

  Assert-PersonalActionProjection -Condition (
    [string]$Projection.authority.owner -ceq 'launch_policy_owner' -and
    [string]$Projection.authority.accountBaseline -ceq 'personal_user' -and
    [string]$Projection.authority.capabilityGrantAuthority -ceq 'server_only'
  ) -Message 'authority owner or Personal-user boundary changed.'
  Assert-PersonalActionProjection -Condition (
    -not [bool]$Projection.authority.localCapabilityGrantAllowed
  ) -Message 'local capability grants are forbidden.'

  try {
    $effectiveAt = ConvertTo-ProjectionDateTimeOffset `
      -Value $Projection.validity.effectiveAt
    $expiresAt = ConvertTo-ProjectionDateTimeOffset `
      -Value $Projection.validity.expiresAt
  } catch {
    throw 'Personal action projection rejected: validity timestamp is invalid.'
  }
  Assert-PersonalActionProjection -Condition ($expiresAt -gt $effectiveAt) `
    -Message 'expiry must be after effective time.'
  Assert-PersonalActionProjection -Condition (
    [string]$Projection.validity.staleRecovery -ceq
      'retain_last_safe_context_and_request_fresh_projection'
  ) -Message 'stale projection recovery changed.'

  $manifestPath = Resolve-ProjectionRepositoryFile `
    -Path ([string]$Projection.sourceManifest.path) `
    -Label 'source manifest'
  $manifestHash = (
    Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath
  ).Hash
  Assert-PersonalActionProjection -Condition (
    $manifestHash -ceq
      ([string]$Projection.sourceManifest.sha256).ToUpperInvariant()
  ) -Message 'source manifest hash changed.'

  if (-not [string]::IsNullOrWhiteSpace($ResolvedSchemaPath)) {
    $schema = Get-Content -Raw -LiteralPath $ResolvedSchemaPath |
      ConvertFrom-Json
    Assert-PersonalActionProjection -Condition (
      [string]$schema.'$schema' -ceq
        'https://json-schema.org/draft/2020-12/schema' -and
      [string]$schema.'$id' -ceq
        'https://moolsocial.com/contracts/uaw-r01-personal-action-projection-v1.schema.json'
    ) -Message 'structural schema identity changed.'
  }

  $mainActions = @($Projection.mainActions)
  $globalActions = @($Projection.globalActions)
  Assert-ExactIdSequence `
    -Items $mainActions `
    -Expected @('social', 'buy', 'eat', 'ride', 'book', 'work') `
    -Label 'main action'
  Assert-ExactIdSequence `
    -Items $globalActions `
    -Expected @('chat') `
    -Label 'global action'

  $expectedSubActions = @{
    social = @('shorts', 'videos', 'feed', 'create')
    buy = @('shop', 'wholesale', 'medicine', 'orders')
    eat = @('order-food', 'book-table')
    ride = @('bike', 'auto', 'cab')
    book = @('doctor', 'salon')
    work = @('earn-today', 'workspace')
  }
  $seenIds = New-Object 'System.Collections.Generic.HashSet[string]' (
    [StringComparer]::Ordinal
  )
  foreach ($action in @($mainActions + $globalActions)) {
    Assert-ActionNode -Action $action -SeenIds $seenIds
    $subActions = @($action.subActions)
    if ($expectedSubActions.ContainsKey([string]$action.id)) {
      Assert-ExactIdSequence `
        -Items $subActions `
        -Expected $expectedSubActions[[string]$action.id] `
        -Label "sub-action ids for '$($action.id)'"
    } else {
      Assert-PersonalActionProjection -Condition ($subActions.Count -eq 0) `
        -Message "global action '$($action.id)' contains sub-actions."
    }
    foreach ($subAction in $subActions) {
      Assert-ActionNode -Action $subAction -SeenIds $seenIds
    }
  }

  $prohibitedVisibleIds = @(
    'pay',
    'recharge',
    'bills',
    'scan-pay',
    'receipts',
    'tiffin',
    'get-done',
    'delivery',
    'onboard',
    'verify'
  )
  foreach ($id in $prohibitedVisibleIds) {
    Assert-PersonalActionProjection -Condition (-not $seenIds.Contains($id)) `
      -Message "prohibited action '$id' is visible."
  }

  $removedActions = @($Projection.removedActions)
  Assert-ExactIdSequence `
    -Items $removedActions `
    -Expected $prohibitedVisibleIds `
    -Label 'removed action'
  foreach ($removed in $removedActions) {
    Assert-PersonalActionProjection -Condition (
      [string]$removed.disposition -ceq 'removed_from_universal'
    ) -Message "removed action '$($removed.id)' has the wrong disposition."
    Assert-PersonalActionProjection -Condition (
      -not [string]::IsNullOrWhiteSpace([string]$removed.recovery)
    ) -Message "removed action '$($removed.id)' has no recovery."
  }

  return $true
}

if ($MyInvocation.InvocationName -ne '.') {
  $resolvedProjectionPath = Resolve-ProjectionRepositoryFile `
    -Path $ProjectionPath `
    -Label 'projection'
  $resolvedSchemaPath = Resolve-ProjectionRepositoryFile `
    -Path $SchemaPath `
    -Label 'projection schema'
  $projection = Get-Content -Raw -LiteralPath $resolvedProjectionPath |
    ConvertFrom-Json
  [void](Test-MvpPersonalActionProjection `
    -Projection $projection `
    -ResolvedSchemaPath $resolvedSchemaPath)
  Write-Output (
    'Personal action projection passed: version=' +
    "$($projection.projectionVersion); mainActions=6; globalActions=1; " +
    'removedActions=10; localCapabilityGrant=false.'
  )
}
