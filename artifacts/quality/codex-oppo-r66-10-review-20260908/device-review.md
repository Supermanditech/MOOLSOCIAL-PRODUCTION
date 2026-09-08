# r66.10 OPPO review

## Installed and checksum verified

r66.10 is installed on OPPO 2b3e0f71, package com.moolsocial.app.runtime, versionCode 2026090805, versionName 1.0.0-r66.10-runtime. The installed base.apk SHA-256 equals the saved review APK: 8973A2655DD26DD7F9DC7B373B264DDD84638164EC2EEF58812037841773CAE7. Independent checksum/launch transcript SHA-256 94B0FD4F444273F2B24D0CC20C681E75DBC374AB75DDB10D6B0F277194B0C95D at C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6610-oppo-checksum-launch-20260909.log. Cold launch returned Status ok. No reinstall or data clearance was needed.

Captures 001 retained launch, 002 Mool menu and 003 Work entry are saved in the r66.10 device directory. These establish launch/navigation only, not complete Workspace or Dashboard child closure. OPPO remains at Work entry for continuation.

## Future installed-APK path prevention

Verification complete: 3 valid-path cases and 12 rejection cases passed, followed by a live read-only OPPO path/checksum check using this retained helper. All passed, exit 0. Exact command/helper/results: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6610-installed-path-prevention-20260909.log; SHA-256 EE23818CA5D71ABEDD1BB1945C87ADA091CD3ADC6E6814AFC2AECA4DB98B7D45. The actual installed checksum still equals the qualified APK. No reinstallation, app edit or rebuild.

Founder requires this correction in future APK checks. Always obtain the path from adb -s <exact serial> shell pm path <exact candidate package>, require native exit 0, and use the validated helper below. Do not hard-code Android-generated directory names or assume the ~~ prefix is absent. Never switch device/package, reinstall or clear data merely because a verification parser stopped.

The helper accepts current Android ~~ directories and older package directories, binds the requested MoolSocial package and requires exactly one base APK. Malformed/traversal/wrong-package/multiple-path output must stop verification. Split APK/AAB installs require their own artifact manifest and checksums; comparing an AAB hash with an installed base APK is not valid.

After resolving the path, run sha256sum on that exact path, require native exit 0 and one 64-hex hash, and compare it with Get-FileHash -Algorithm SHA256 of the exact locally qualified APK. The new regex is not a waiver of checksum, version, signer, source, package or release checks.

<!-- installed-base-apk-path-helper:start -->
```powershell
function Resolve-InstalledBaseApkPath {
  param(
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Lines,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^com\.moolsocial\.app(?:\.(?:runtime|cursorreview))?$')]
    [string]$PackageId
  )
  if ($Lines.Count -ne 1) {
    throw 'Expected one installed base APK. Split or ambiguous packages require separate qualification.'
  }
  $packagePattern = [regex]::Escape($PackageId)
  $pattern = '^package:(/data/app/(?:~~[A-Za-z0-9_+=-]+/)?' +
    $packagePattern + '-[A-Za-z0-9_+=-]+/base\.apk)$'
  $match = [regex]::Match($Lines[0], $pattern)
  if (-not $match.Success) {
    throw 'Installed path is malformed or does not belong to the requested package.'
  }
  return $match.Groups[1].Value
}
```
<!-- installed-base-apk-path-helper:end -->

Historical reservation: build/install/native replay had not occurred when this file was created. Current installation and smoke status are recorded above. Re-test the corrected Workspace entry, new application/approved Store switching, contact/details keyboard, documents, correction drafts, support return and approved Dashboard before further founder first-tap review. Use only labelled review fixtures; no live submission, OTP, payment, WhatsApp or admin approval. Store statement remains the next separate founder-review destination.
# Installation verification continuation

9 September 2026: adb install -r succeeded on OPPO 2b3e0f71; package com.moolsocial.app.runtime reports versionCode 2026090805 and versionName 1.0.0-r66.10-runtime, lastUpdateTime 2026-09-09 01:00:41. App data was not cleared.

The combined install/verification command then exited 1 because its package-path regex omitted Android's observed ~~ install-directory prefix. No launch or checksum pass was claimed from that attempt. Exact transcript C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6610-oppo-install-20260909.log, SHA-256 7127759DB124B2C55D3A7F934111D1DDA6EB1174DF38BD275C8BAF76569F15F4. This is an existing command-reconstruction incident, not an APK failure. The read-only pm path returned exactly one base.apk for the intended package. Continue checksum verification against that exact observed path; do not reinstall, clear data, rebuild or broaden the package target.
