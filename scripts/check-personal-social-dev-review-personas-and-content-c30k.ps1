[CmdletBinding()]
param(
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

if (-not $RepositoryRoot) {
  $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$prefix = $root + [IO.Path]::DirectorySeparatorChar

function Assert-C30K {
  param(
    [Parameter(Mandatory)][bool]$Condition,
    [Parameter(Mandatory)][string]$Message
  )
  if (-not $Condition) {
    throw "C30K review corpus gate rejected: $Message"
  }
}

function Resolve-C30KFile {
  param([Parameter(Mandatory)][string]$RelativePath)
  Assert-C30K (-not [IO.Path]::IsPathRooted($RelativePath)) 'path must be repository-relative'
  $resolved = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
  Assert-C30K ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) 'path escaped repository'
  Assert-C30K (Test-Path -LiteralPath $resolved -PathType Leaf) "missing file: $RelativePath"
  return $resolved
}

function Assert-C30KHash {
  param(
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Expected
  )
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-C30KFile $RelativePath)).Hash
  Assert-C30K ($actual -ceq $Expected) "source seal changed: $RelativePath"
}

$ticket = Get-Content -Raw -LiteralPath (
  Resolve-C30KFile 'config/uaw-personal-mvp-social-dev-review-personas-and-content-c30k-ticket.json'
) | ConvertFrom-Json
Assert-C30K (
  [string]$ticket.ticketId -ceq 'UAW-PERSONAL-MVP-SOCIAL-DEV-REVIEW-PERSONAS-AND-CONTENT-C30K'
) 'unexpected ticket id'
Assert-C30K (
  [string]$ticket.state -in @(
    'source_implementation_authorized_external_Dev_data_write_held_until_ADC_and_source_qualification',
    'source_qualified_external_Dev_data_write_held_until_ADC',
    'source_qualified_external_Dev_data_apply_authorized',
    'Dev_review_corpus_applied_and_verified_APK_and_deployment_held'
  )
) 'unsupported ticket state'
Assert-C30K ([bool]$ticket.authority.sourceImplementationAuthorized) 'source authority missing'
$externalApplyAuthorized = (
  [string]$ticket.state -ceq 'source_qualified_external_Dev_data_apply_authorized'
)
Assert-C30K (
  [bool]$ticket.authority.externalServiceWriteAuthorizedNow -eq $externalApplyAuthorized
) 'external write authority does not match the exact apply state'
Assert-C30K (-not [bool]$ticket.authority.secretValueAccessAuthorized) 'secret value access must remain denied'
Assert-C30K (-not [bool]$ticket.authority.backendDeployAuthorized) 'backend deployment must remain denied'
Assert-C30K (-not [bool]$ticket.authority.buildAuthorized) 'APK build must remain denied'
Assert-C30K (-not [bool]$ticket.authority.deviceInstallAuthorized) 'device install must remain denied'

Assert-C30KHash `
  'backend/functions/src/social/dev_review_corpus.ts' `
  '42511E355FE6C50840ADFF86471B9C1C28AF110CB4DBF60BE5D2489B3AA6F3D4'
Assert-C30KHash `
  'backend/functions/src/social/dev_review_corpus_runner.ts' `
  '9F53F2586E243E70CFFCE008843CB614E04AB595A373088B5975E15FE7C72297'
Assert-C30KHash `
  'backend/functions/src/social/dev_review_corpus.test.ts' `
  'A3E204A56182A036067441FEFB16F08AA08879A8BCE5C8E16612087C7A5E644F'
Assert-C30KHash `
  'backend/functions/package.json' `
  '1FF43FADE438F735DC8580664397671579F3265105916C6C6CC76CC895F5727B'

$corpus = Get-Content -Raw -LiteralPath (
  Resolve-C30KFile 'backend/functions/src/social/dev_review_corpus.ts'
)
$runner = Get-Content -Raw -LiteralPath (
  Resolve-C30KFile 'backend/functions/src/social/dev_review_corpus_runner.ts'
)
Assert-C30K ($corpus.Contains('posts.length !== 36')) 'exact 36-post contract missing'
Assert-C30K ($corpus.Contains('DEV_REVIEW_PERSONAS.length !== 3')) 'exact three-persona contract missing'
Assert-C30K ($corpus.Contains('post.choices.length !== 4')) 'four-choice contract missing'
Assert-C30K ($runner.Contains('disabled: true')) 'disabled persona guard missing'
Assert-C30K ($runner.Contains('credential: applicationDefault()')) 'secure ADC owner missing'
Assert-C30K ($runner.Contains('project_not_allowed')) 'exact Dev project guard missing'
Assert-C30K ($runner.Contains('existing_persona_conflict')) 'existing identity conflict guard missing'
Assert-C30K (-not $runner.Contains('onRequest(')) 'review runner must not expose an HTTP surface'
Assert-C30K (-not $runner.Contains('password:')) 'review runner must not provision a password'
Assert-C30K (-not $runner.Contains('signInWithCustomToken')) 'review runner must not mint a client session'

$package = Get-Content -Raw -LiteralPath (
  Resolve-C30KFile 'backend/functions/package.json'
) | ConvertFrom-Json
Assert-C30K (
  [string]$package.scripts.'review-corpus:dev' -ceq `
    'npm run build && node lib/social/dev_review_corpus_runner.js'
) 'guarded review-corpus command changed'

Write-Output (
  'C30K Dev review personas/content gate passed: personas=3; posts=36; ' +
  "media=48; externalWrites=$($externalApplyAuthorized.ToString().ToLowerInvariant()); " +
  'APK=false; deployment=false.'
)
