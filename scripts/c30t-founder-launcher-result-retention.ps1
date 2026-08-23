Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Complete-C30TFounderLauncherResult {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('build_qualified', 'stopped_after_cleanup')]
    [string]$Result,

    [switch]$NoWait
  )

  Write-Host ''
  if ($Result -ceq 'build_qualified') {
    Write-Host 'AAB build and postbuild qualification completed.'
    Write-Host 'Play upload, OPPO update, device journeys and production readiness are not implied.'
    Write-Host 'Return to Codex and report the visible result before any next release action.'
  } else {
    Write-Host 'AAB launcher stopped after cleanup. No success is claimed.'
    Write-Host 'Return to Codex for repository reconciliation before any retry.'
  }

  if (-not $NoWait) {
    [void](Read-Host 'After reporting the result to Codex, press Enter to close this launcher')
  }
}
