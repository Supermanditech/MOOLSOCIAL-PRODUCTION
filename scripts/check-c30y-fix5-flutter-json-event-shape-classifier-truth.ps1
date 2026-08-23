[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$parserPath = Join-Path $root 'scripts/c30y-flutter-json-event-shape-parser.ps1'
$runnerPath = Join-Path $root 'tmp/run-c30t-authoritative-flutter-manifest-audit.ps1'

function Assert-C30YFix5 {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30Y FIX5 Flutter JSON classifier rejected: $Message"
  }
}

foreach ($path in @($parserPath, $runnerPath)) {
  Assert-C30YFix5 -Condition (Test-Path -LiteralPath $path -PathType Leaf) `
    -Message "owner is missing: $path"
  $tokens = $null
  $errors = $null
  [void][Management.Automation.Language.Parser]::ParseFile(
    $path, [ref]$tokens, [ref]$errors
  )
  Assert-C30YFix5 -Condition (@($errors).Count -eq 0) `
    -Message "PowerShell parser rejected: $path"
}

$runner = Get-Content -Raw -LiteralPath $runnerPath
foreach ($required in @(
  'c30y-flutter-json-event-shape-parser.ps1',
  'Get-C30YFlutterJsonEventType',
  'Get-C30YFlutterJsonEventPropertyNames',
  '$untypedJsonObjects++',
  'authoritative_untyped_json_object',
  'untyped_json_objects=$untypedJsonObjects',
  '$untypedJsonObjects -ne 0',
  '$nonJsonLines -ne 0'
)) {
  Assert-C30YFix5 -Condition (
    $runner.IndexOf($required, [StringComparison]::Ordinal) -ge 0
  ) -Message "runner binding is missing: $required"
}
Assert-C30YFix5 -Condition (
  $runner.IndexOf('$event.type', [StringComparison]::Ordinal) -lt 0
) -Message 'runner still directly accesses event.type.'

. $parserPath
$typed = '{"type":"testStart","test":{"id":1}}' | ConvertFrom-Json
$untyped = '{"protocolVersion":"0.1.1","runnerVersion":"1"}' | ConvertFrom-Json
$blank = '{"type":"   ","safe_name":"value_not_emitted"}' | ConvertFrom-Json
Assert-C30YFix5 -Condition (
  (Get-C30YFlutterJsonEventType -Event $typed) -ceq 'testStart'
) -Message 'typed event was not classified exactly.'
Assert-C30YFix5 -Condition (
  $null -eq (Get-C30YFlutterJsonEventType -Event $untyped)
) -Message 'untyped object did not return null.'
Assert-C30YFix5 -Condition (
  $null -eq (Get-C30YFlutterJsonEventType -Event $blank)
) -Message 'blank event type did not return null.'
$names = Get-C30YFlutterJsonEventPropertyNames -Event $untyped
Assert-C30YFix5 -Condition (
  $names -ceq 'protocolVersion,runnerVersion'
) -Message 'shape-only property-name evidence changed.'
Assert-C30YFix5 -Condition (
  $names.IndexOf('0.1.1', [StringComparison]::Ordinal) -lt 0
) -Message 'shape evidence exposed a JSON value.'

Write-Output (
  'C30Y FIX5 Flutter JSON event-shape classifier passed: ' +
  'typed=true; untyped=null; blank=null; valuesExposed=false; ' +
  'runnerFailClosed=true.'
)
