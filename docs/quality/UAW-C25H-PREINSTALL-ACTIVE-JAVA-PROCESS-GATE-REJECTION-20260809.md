# C25H preinstall active Java process gate rejection

Date: 2026-08-09

The unique r60.24 profile APK passed build validation, but the separate
immediate install gate detected one active Java process. Under the founder's
fail-closed machine/device rule, install authority remains closed.

The process was not killed or assumed harmless. No uninstall, data clear,
downgrade or `adb install` occurred. OPPO remains on checksum-proven r60.23;
the r60.24 candidate is preserved at checksum
`4B261C09AA771CDEBFCEA201A1D198EA01B6E46522826C4202A9D83150DE3BF5`.

Future continuation must begin with a fresh process/device audit. A second APK
build is permanently forbidden.
