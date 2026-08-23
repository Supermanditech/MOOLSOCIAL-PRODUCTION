[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$contractPath = Join-Path $RepositoryRoot 'config\mvp-personal-domain-navigation-projection-c25.json'
if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) { throw 'C25 domain navigation projection is missing.' }
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json

if ([int]$contract.schemaVersion -ne 1 -or [string]$contract.contractId -cne 'UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-PROJECTION-FIX8-C25') { throw 'C25 projection identity changed.' }
$presentation = $contract.presentation
if ([string]$presentation.brandLabel -cne 'MoolSocial' -or
    -not [bool]$presentation.mainMenuMainActionsOnly -or
    [bool]$presentation.mainMenuSubactionsAllowed -or
    [int]$presentation.defaultDestinationTapCount -ne 1 -or
    -not [bool]$presentation.destinationLocalSubactionsRequired -or
    [int]$presentation.destinationSubactionTapCount -ne 1 -or
    -not [bool]$presentation.backAndForwardRequired -or
    [int]$presentation.maximumTapTargetOcclusion -ne 0 -or
    [bool]$presentation.horizontalActionScrollAllowed -or
    [bool]$presentation.fullWidthOpaqueBottomStripeAllowed -or
    [int]$presentation.minimumTapTarget -ne 44 -or
    [int]$presentation.finiteMotionMillisecondsMinimum -ne 180 -or
    [int]$presentation.finiteMotionMillisecondsMaximum -ne 320 -or
    -not [bool]$presentation.reducedMotionImmediate) { throw 'C25 presentation contract changed.' }

$expected = [ordered]@{
  social = @{ Label='Social'; Default='/app/social'; Actions=@('shorts|Shorts|/app/social?sub=shorts|social_v2_shorts','videos|Videos|/app/social?sub=videos|social_v2_videos','feed|Feed|/app/social?sub=feed|social_v2_feed','create|Create|/app/social?sub=create|social_v2_create') }
  buy = @{ Label='Shop'; Default='/app/buy?sub=shop'; Actions=@('shop|Products|/app/buy?sub=shop|buy_v2_shop','wholesale|Wholesale|/app/buy?sub=wholesale|buy_v2_wholesale','orders|Orders|/app/buy?sub=orders|buy_v2_orders') }
  eat = @{ Label='Food'; Default='/app/eat/home'; Actions=@('order|Order Food|/app/eat/home|eat_order_food','table|Book Table|/app/eat/table|eat_book_table') }
  ride = @{ Label='Travel'; Default='/app/ride/book?type=bike'; Actions=@('bike|Bike|/app/ride/book?type=bike|ride_bike','auto|Auto|/app/ride/book?type=auto|ride_auto','cab|Cab|/app/ride/book?type=cab|ride_cab','bus|Bus|/app/book/bus|book_bus_existing_owner') }
  book = @{ Label='Care'; Default='/app/book/doctor'; Actions=@('doctor|Doctor|/app/book/doctor|book_doctor','medicine|Medicine|/app/buy?sub=medicine|buy_v2_medicine','salon|Salon|/app/book/salon|book_salon') }
  work = @{ Label='Work'; Default='/app/work/earn'; Actions=@('earn|Earn Today|/app/work/earn|work_earn_today','workspace|Workspace|/app/work/my-work|workspace_routing_owner') }
}
$domains = @($contract.domains)
if (($domains.id -join ',') -cne ($expected.Keys -join ',')) { throw 'C25 domain order or ids changed.' }
foreach ($domain in $domains) {
  $spec = $expected[[string]$domain.id]
  if ([string]$domain.label -cne $spec.Label -or [string]$domain.defaultRoute -cne $spec.Default) { throw "C25 domain label/default changed: $($domain.id)." }
  $actualActions = @($domain.actions | ForEach-Object { '{0}|{1}|{2}|{3}' -f $_.id,$_.label,$_.route,$_.routeOwner })
  if (($actualActions -join ',') -cne (@($spec.Actions) -join ',')) { throw "C25 domain actions changed: $($domain.id)." }
}
$allActions = @($domains | ForEach-Object { $_.actions })
if (@($allActions | Where-Object { $_.id -eq 'medicine' }).Count -ne 1 -or
    @($allActions | Where-Object { $_.id -eq 'bus' }).Count -ne 1) { throw 'C25 Medicine or Bus is duplicated.' }
if ([int]$contract.reuse.newScreens -ne 0 -or [int]$contract.reuse.newRoutes -ne 0 -or [int]$contract.reuse.newBackendOwners -ne 0 -or [int]$contract.reuse.newStateOwners -ne 0) { throw 'C25A introduced a new implementation owner.' }
if ([bool]$contract.execution.runtimeWriteAuthorized -or [bool]$contract.execution.backendWriteAuthorized -or [bool]$contract.execution.buildAuthorized -or [bool]$contract.execution.installAuthorized -or [bool]$contract.execution.externalServiceWriteAuthorized) { throw 'C25A execution boundary widened.' }

Write-Output 'C25A domain navigation contract passed: domains=6; actions=18; Medicine=Care/Buy-owner; Bus=Travel/Book-owner; newOwners=0.'
