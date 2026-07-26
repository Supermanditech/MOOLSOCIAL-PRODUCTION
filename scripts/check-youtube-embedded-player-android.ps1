Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$bridgePath = Join-Path $repositoryRoot `
    'apps/mobile/lib/core/youtube/youtube_embedded_player_bridge.dart'
$contractPath = Join-Path $repositoryRoot `
    'apps/mobile/lib/core/youtube/youtube_embedded_player_contract.dart'
$dartAdapterPath = Join-Path $repositoryRoot `
    'apps/mobile/lib/core/youtube/youtube_embedded_player_android.dart'
$nativePath = Join-Path $repositoryRoot `
    'apps/mobile/packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/com/moolsocial/app/youtube/YouTubeEmbeddedPlayerPlatformView.kt'
$factoryPath = Join-Path $repositoryRoot `
    'apps/mobile/packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/com/moolsocial/app/youtube/YouTubeEmbeddedPlayerPlatformViewFactory.kt'
$activityPath = Join-Path $repositoryRoot `
    'apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt'
$debugRegistrarPath = Join-Path $repositoryRoot `
    'apps/mobile/packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/com/moolsocial/youtube_embedded_player_private_dev/YouTubeEmbeddedPlayerPrivateDevRegistrar.kt'
$releaseRegistrarPath = Join-Path $repositoryRoot `
    'apps/mobile/packages/youtube_embedded_player_private_dev/android/src/release/kotlin/com/moolsocial/youtube_embedded_player_private_dev/YouTubeEmbeddedPlayerPrivateDevRegistrar.kt'
$profileRegistrarPath = Join-Path $repositoryRoot `
    'apps/mobile/packages/youtube_embedded_player_private_dev/android/src/profile/kotlin/com/moolsocial/youtube_embedded_player_private_dev/YouTubeEmbeddedPlayerPrivateDevRegistrar.kt'

$utf8 = [System.Text.UTF8Encoding]::new($false)
$bridgeSource = [System.IO.File]::ReadAllText($bridgePath, $utf8)
$contractSource = [System.IO.File]::ReadAllText($contractPath, $utf8)
$dartAdapterSource = [System.IO.File]::ReadAllText($dartAdapterPath, $utf8)
$nativeSource = [System.IO.File]::ReadAllText($nativePath, $utf8)
$factorySource = [System.IO.File]::ReadAllText($factoryPath, $utf8)
$activitySource = [System.IO.File]::ReadAllText($activityPath, $utf8)
$debugRegistrarSource = [System.IO.File]::ReadAllText(
    $debugRegistrarPath,
    $utf8
)
$releaseRegistrarSource = [System.IO.File]::ReadAllText(
    $releaseRegistrarPath,
    $utf8
)
$profileRegistrarSource = [System.IO.File]::ReadAllText(
    $profileRegistrarPath,
    $utf8
)

$literal = [regex]::Match(
    $bridgeSource,
    "static const html = r'''(?<html>[\s\S]*?)''';"
)
if (-not $literal.Success) {
    throw 'The provider bootstrap literal was not found.'
}

$bootstrap = $literal.Groups['html'].Value
$nonceMarker = '__MOOLSOCIAL_NATIVE_PORT_NONCE__'
if (([regex]::Matches($bootstrap, [regex]::Escape($nonceMarker))).Count -ne 1) {
    throw 'The provider bootstrap must contain exactly one nonce marker.'
}

$sha256 = [System.Security.Cryptography.SHA256]::Create()
$digestBytes = $null
try {
    $digestBytes = $sha256.ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($bootstrap)
    )
    $digest = ([BitConverter]::ToString($digestBytes)).Replace('-', '')
}
finally {
    if ($null -ne $digestBytes) {
        [Array]::Clear($digestBytes, 0, $digestBytes.Length)
    }
    $sha256.Dispose()
}

$pinned = [regex]::Match(
    $nativeSource,
    'EXPECTED_BOOTSTRAP_SHA256\s*=\s*"(?<digest>[A-F0-9]{64})"'
)
if (-not $pinned.Success -or $pinned.Groups['digest'].Value -ne $digest) {
    throw "The native bootstrap digest does not match $digest."
}

$combined = "$nativeSource`n$factorySource"
foreach ($forbidden in @(
    'addJavascriptInterface(',
    'addWebMessageListener(',
    'evaluateJavascript(',
    'javascript:',
    'Uri.parse("*")'
)) {
    if ($combined.Contains($forbidden)) {
        throw "Forbidden Android bridge surface found: $forbidden"
    }
}

if (-not $nativeSource.Contains('Uri.parse("https://com.moolsocial.app")')) {
    throw 'The exact provider target origin is missing.'
}
if ($activitySource.Contains('YouTubeEmbeddedPlayer')) {
    throw 'The accepted MainActivity contains private-Dev player wiring.'
}
if (-not $debugRegistrarSource.Contains('registerViewFactory(')) {
    throw 'The private-Dev factory is not registered.'
}
if ($releaseRegistrarSource.Contains('registerViewFactory(')) {
    throw 'The private-Dev factory is registered in release.'
}
if ($profileRegistrarSource.Contains('registerViewFactory(')) {
    throw 'The private-Dev factory is registered in profile.'
}
if (-not $contractSource.Contains('kDebugMode &&')) {
    throw 'The private-Dev build define is not hard-gated to debug builds.'
}
if (-not $dartAdapterSource.Contains('if (!kDebugMode ||')) {
    throw 'The private-Dev Android surface is not hard-gated to debug builds.'
}

Write-Output "YouTube Android private-Dev source gate passed: $digest"
