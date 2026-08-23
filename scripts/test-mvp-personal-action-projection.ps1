[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$repositoryRootFull = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
  [char[]]@('\', '/')
)
$validatorPath = Join-Path `
  $repositoryRootFull `
  'scripts/check-mvp-personal-action-projection.ps1'
. $validatorPath -RepositoryRoot $repositoryRootFull

function Get-RepositoryFixtureFile {
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath
  )

  if ([IO.Path]::IsPathRooted($RelativePath)) {
    throw "Projection self-test rejected rooted fixture path: $RelativePath"
  }
  $resolved = [IO.Path]::GetFullPath(
    (Join-Path $repositoryRootFull $RelativePath)
  )
  $prefix = $repositoryRootFull + [IO.Path]::DirectorySeparatorChar
  if (-not $resolved.StartsWith(
      $prefix,
      [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "Projection self-test fixture escaped repository: $RelativePath"
  }
  if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "Projection self-test fixture is missing: $resolved"
  }
  return $resolved
}

function Copy-JsonObject {
  param(
    [Parameter(Mandatory)]
    [object]$Value
  )

  return $Value | ConvertTo-Json -Depth 100 | ConvertFrom-Json
}

function Find-Action {
  param(
    [Parameter(Mandatory)]
    [object]$Projection,

    [Parameter(Mandatory)]
    [string]$MainActionId
  )

  $action = @($Projection.mainActions) |
    Where-Object { [string]$_.id -ceq $MainActionId } |
    Select-Object -First 1
  if ($null -eq $action) {
    throw "Projection self-test main action is missing: $MainActionId"
  }
  return $action
}

$canonicalPath = Get-RepositoryFixtureFile `
  -RelativePath 'config/mvp-personal-action-projection-v1.json'
$canonical = Get-Content -Raw -LiteralPath $canonicalPath | ConvertFrom-Json
[void](Test-MvpPersonalActionProjection -Projection $canonical)
Write-Output 'POSITIVE PASS: canonical Personal action projection.'

$fixtureDirectory = Join-Path `
  $repositoryRootFull `
  'tests/fixtures/mvp-personal-action-projection'
$fixtures = Get-ChildItem -LiteralPath $fixtureDirectory -Filter '*.json' |
  Sort-Object Name
foreach ($fixtureFile in $fixtures) {
  $fixture = Get-Content -Raw -LiteralPath $fixtureFile.FullName |
    ConvertFrom-Json
  $projectionPath = Get-RepositoryFixtureFile `
    -RelativePath ([string]$fixture.baseProjection)
  $projection = Get-Content -Raw -LiteralPath $projectionPath |
    ConvertFrom-Json
  $projection = Copy-JsonObject -Value $projection
  $mutation = $fixture.mutation

  switch ([string]$mutation.type) {
    'append_main_action' {
      $projection.mainActions = @(
        @($projection.mainActions) + (Copy-JsonObject -Value $mutation.action)
      )
    }
    'duplicate_sub_action' {
      $action = Find-Action `
        -Projection $projection `
        -MainActionId ([string]$mutation.mainActionId)
      $sourceIndex = [int]$mutation.sourceIndex
      $targetIndex = [int]$mutation.targetIndex
      $action.subActions[$targetIndex].id =
        [string]$action.subActions[$sourceIndex].id
    }
    'allow_local_capability_grant' {
      $projection.authority.localCapabilityGrantAllowed = $true
    }
    'clear_route_owner' {
      $action = Find-Action `
        -Projection $projection `
        -MainActionId ([string]$mutation.mainActionId)
      $subAction = @($action.subActions) |
        Where-Object {
          [string]$_.id -ceq [string]$mutation.subActionId
        } |
        Select-Object -First 1
      if ($null -eq $subAction) {
        throw "Projection self-test sub-action is missing: $($mutation.subActionId)"
      }
      $subAction.routeOwner = ''
    }
    'expire_before_effective' {
      $projection.validity.expiresAt = '2026-08-04T00:00:00+05:30'
    }
    'clear_dependencies' {
      $action = Find-Action `
        -Projection $projection `
        -MainActionId ([string]$mutation.mainActionId)
      $subAction = @($action.subActions) |
        Where-Object {
          [string]$_.id -ceq [string]$mutation.subActionId
        } |
        Select-Object -First 1
      if ($null -eq $subAction) {
        throw "Projection self-test sub-action is missing: $($mutation.subActionId)"
      }
      $subAction.dependencies = @()
    }
    default {
      throw "Projection self-test mutation is unsupported: $($mutation.type)"
    }
  }

  try {
    [void](Test-MvpPersonalActionProjection -Projection $projection)
    throw "Negative fixture unexpectedly passed: $($fixture.caseId)"
  } catch {
    $expected = [string]$fixture.expectedErrorContains
    if ($_.Exception.Message -notlike "*$expected*") {
      throw
    }
    Write-Output (
      "EXPECTED NEGATIVE PASS: $($fixture.caseId); $expected."
    )
  }
}

Write-Output (
  "Personal action projection self-test passed: positive=1; " +
  "negative=$($fixtures.Count)."
)
