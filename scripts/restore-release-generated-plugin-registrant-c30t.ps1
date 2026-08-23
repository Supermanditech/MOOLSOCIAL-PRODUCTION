[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char[]]@('\', '/'))
$metadataPath = Join-Path $root 'apps/mobile/.flutter-plugins-dependencies'
$registrantPath = Join-Path $root 'apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'

function Assert-C30TRegistrant {
  param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
  if (-not $Condition) { throw "C30T release registrant restore rejected: $Message" }
}

Assert-C30TRegistrant -Condition (Test-Path -LiteralPath $metadataPath -PathType Leaf) -Message 'Flutter plugin metadata is missing.'
Assert-C30TRegistrant -Condition (Test-Path -LiteralPath $registrantPath -PathType Leaf) -Message 'generated Android registrant is missing.'
$metadata = Get-Content -Raw -LiteralPath $metadataPath | ConvertFrom-Json
$androidPlugins = @($metadata.plugins.android)
$integration = @($androidPlugins | Where-Object { [string]$_.name -ceq 'integration_test' })
Assert-C30TRegistrant -Condition ($integration.Count -eq 1 -and [bool]$integration[0].dev_dependency) -Message 'integration_test is not one exact dev-only Android plugin.'
$releaseNativePlugins = @($androidPlugins | Where-Object { [bool]$_.native_build -and -not [bool]$_.dev_dependency })
Assert-C30TRegistrant -Condition ($releaseNativePlugins.Count -eq 16) -Message "release-native metadata count is $($releaseNativePlugins.Count), expected 16."

$expectedClasses = @(
  'FirebaseAppCheckPlugin', 'FlutterFirebaseAuthPlugin', 'FlutterFirebaseCorePlugin',
  'FlutterFirebaseCrashlyticsPlugin', 'FlutterAndroidLifecyclePlugin', 'GoogleSignInPlugin', 'ImagePickerPlugin',
  'JniPlugin', 'JniFlutterPlugin', 'MobileScannerPlugin', 'PermissionHandlerPlugin',
  'SharedPreferencesPlugin', 'SpeechToTextPlugin', 'UrlLauncherPlugin',
  'VideoPlayerPlugin', 'YouTubeEmbeddedPlayerPrivateDevPlugin'
)
$registrant = Get-Content -Raw -LiteralPath $registrantPath
$integrationBlock = '(?ms)^\s{4}try \{\r?\n\s{6}flutterEngine\.getPlugins\(\)\.add\(new dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\(\)\);\r?\n\s{4}\} catch \(Exception e\) \{\r?\n\s{6}Log\.e\(TAG, "Error registering plugin integration_test, dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin", e\);\r?\n\s{4}\}\r?\n'
$integrationMatches = [regex]::Matches($registrant, $integrationBlock)
Assert-C30TRegistrant -Condition ($integrationMatches.Count -le 1) -Message 'generated integration_test block is duplicated or ambiguous.'
$removed = $integrationMatches.Count -eq 1
if ($removed) {
  $registrant = [regex]::Replace($registrant, $integrationBlock, '', 1)
  $temporaryPath = $registrantPath + '.c30t-registrant-write'
  Assert-C30TRegistrant -Condition (-not (Test-Path -LiteralPath $temporaryPath)) -Message 'stale registrant temporary file exists.'
  [IO.File]::WriteAllText($temporaryPath, $registrant, [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporaryPath -Destination $registrantPath -Force
}

$restored = Get-Content -Raw -LiteralPath $registrantPath
$registrations = [regex]::Matches($restored, 'flutterEngine\.getPlugins\(\)\.add\(new\s+([^;]+)\(\)\);')
Assert-C30TRegistrant -Condition ($registrations.Count -eq 16) -Message "restored registrant count is $($registrations.Count), expected 16."
Assert-C30TRegistrant -Condition (-not $restored.Contains('IntegrationTestPlugin', [StringComparison]::Ordinal)) -Message 'dev-only IntegrationTestPlugin remains.'
foreach ($class in $expectedClasses) {
  Assert-C30TRegistrant -Condition $restored.Contains($class, [StringComparison]::Ordinal) -Message "required release plugin is missing: $class"
}
Write-Output "C30T release registrant restored: plugins=16; removedDevIntegrationTest=$($removed.ToString().ToLowerInvariant())."
