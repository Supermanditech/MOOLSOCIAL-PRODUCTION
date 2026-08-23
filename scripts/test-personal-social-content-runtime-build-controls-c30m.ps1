[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$baseStatePath = Join-Path `
  $repositoryRoot `
  'config/apk-regression-gate-state-c30l.json'
$gatePath = Join-Path `
  $repositoryRoot `
  'scripts/check-apk-regression-gate-state.ps1'
$probeStatePath = Join-Path `
  $repositoryRoot `
  'artifacts/quality/c30m-social-content-runtime-contract-probe.json'
$mvpScopeStatePath = Join-Path `
  $repositoryRoot `
  'config/mvp-scope-gate-state.json'
$mvpScopeState = Get-Content -Raw -LiteralPath $mvpScopeStatePath |
  ConvertFrom-Json
$candidateId = [string]$mvpScopeState.ticket.id
if ([string]::IsNullOrWhiteSpace($candidateId)) {
  throw 'C30M build controls require an active MVP successor ticket.'
}
$expectedEndpoint = (
  'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/' +
  'moolSocialContent'
)

if (Test-Path -LiteralPath $probeStatePath) {
  throw "C30M probe state already exists: $probeStatePath"
}

function New-C30MProbeState {
  param([AllowNull()][string]$Endpoint, [switch]$OmitEndpoint)

  $probeState = Get-Content -Raw -LiteralPath $baseStatePath |
    ConvertFrom-Json
  $probeState.machineState = 'prebuild_passed'
  $probeState.buildAuthorization = 'approved_for_one_build'
  $probeState.candidate.id = $candidateId
  $probeState.requiredRuntimeDefines.MOOLSOCIAL_CANDIDATE_ID = $candidateId
  if (-not $OmitEndpoint) {
    $probeState.requiredRuntimeDefines | Add-Member `
      -NotePropertyName 'MOOLSOCIAL_SOCIAL_CONTENT_URL' `
      -NotePropertyValue $Endpoint `
      -Force
  }
  return $probeState
}

function Get-C30MRuntimeDefines {
  param([Parameter(Mandatory)]$ProbeState, [switch]$OmitActualEndpoint)

  $runtimeDefines = @(
    $ProbeState.requiredRuntimeDefines.PSObject.Properties |
      ForEach-Object { "$($_.Name)=$($_.Value)" }
  )
  if ($OmitActualEndpoint) {
    $runtimeDefines = @(
      $runtimeDefines | Where-Object {
        -not $_.StartsWith(
          'MOOLSOCIAL_SOCIAL_CONTENT_URL=',
          [StringComparison]::Ordinal
        )
      }
    )
  }
  $runtimeDefines += 'MOOLSOCIAL_FIREBASE_API_KEY=contract-probe-nonsecret'
  return $runtimeDefines
}

function Write-C30MProbeState {
  param([Parameter(Mandatory)]$ProbeState)

  [IO.File]::WriteAllText(
    $probeStatePath,
    ($ProbeState | ConvertTo-Json -Depth 32),
    [Text.UTF8Encoding]::new($false)
  )
}

function Invoke-C30MGate {
  param(
    [Parameter(Mandatory)]$ProbeState,
    [switch]$OmitActualEndpoint
  )

  Write-C30MProbeState -ProbeState $ProbeState
  $runtimeDefines = Get-C30MRuntimeDefines `
    -ProbeState $ProbeState `
    -OmitActualEndpoint:$OmitActualEndpoint
  & $gatePath `
    -StatePath $probeStatePath `
    -CandidateId $candidateId `
    -BuildName ([string]$ProbeState.candidate.versionName) `
    -BuildNumber ([string]$ProbeState.candidate.versionCode) `
    -BuildMode ([string]$ProbeState.candidate.buildMode) `
    -SourceFingerprint ([string]$ProbeState.source.manifestSha256) `
    -RuntimeDefine $runtimeDefines | Out-Null
}

function Assert-C30MRejection {
  param(
    [Parameter(Mandatory)]$ProbeState,
    [Parameter(Mandatory)][string]$ExpectedMessage,
    [switch]$OmitActualEndpoint
  )

  try {
    Invoke-C30MGate `
      -ProbeState $ProbeState `
      -OmitActualEndpoint:$OmitActualEndpoint
  } catch {
    if (-not $_.Exception.Message.Contains(
        $ExpectedMessage,
        [StringComparison]::Ordinal
      )) {
      throw (
        "Expected rejection containing '$ExpectedMessage', received: " +
        $_.Exception.Message
      )
    }
    return
  }
  throw "Expected C30M runtime-define rejection: $ExpectedMessage"
}

try {
  Assert-C30MRejection `
    -ProbeState (New-C30MProbeState -OmitEndpoint) `
    -ExpectedMessage 'Social content endpoint is missing from machine state.'
  Assert-C30MRejection `
    -ProbeState (New-C30MProbeState -Endpoint '') `
    -ExpectedMessage 'Social content endpoint differs from the registered environment.'
  Assert-C30MRejection `
    -ProbeState (New-C30MProbeState -Endpoint 'https://example.com/moolSocialContent') `
    -ExpectedMessage 'Social content endpoint differs from the registered environment.'
  Assert-C30MRejection `
    -ProbeState (New-C30MProbeState -Endpoint $expectedEndpoint) `
    -OmitActualEndpoint `
    -ExpectedMessage 'runtime define names differ from the exact registered allowlist.'
  Invoke-C30MGate `
    -ProbeState (New-C30MProbeState -Endpoint $expectedEndpoint)
} finally {
  if (Test-Path -LiteralPath $probeStatePath) {
    Remove-Item -LiteralPath $probeStatePath -Force
  }
}

Write-Output (
  'C30M Social content runtime build controls passed: ' +
  'missing, empty, wrong-environment and omitted-runtime values rejected; ' +
  'exact Dev endpoint accepted.'
)
