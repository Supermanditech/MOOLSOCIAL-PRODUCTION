# C30S OPPO uiautomator `/dev/tty` no-XML result — 2026-08-13

## Bounded event

The connected OPPO `2b3e0f71` was awake, unlocked and focused on `com.android.vending` for the exact package `com.moolsocial.app`. A read-only UI inspection requested `uiautomator dump /dev/tty`.

The command exited successfully but returned only `UI hierchary dumped to: /dev/tty`; it did not stream the XML hierarchy. Therefore no button label or coordinate was inferred and no tap occurred.

## Retry gate

Use the exact agent-owned temporary path `/data/local/tmp/moolsocial-c30s-ui.xml`, read only sanitized text/description/bounds needed to distinguish **Update**, **Open**, **Install**, **Pending** or **Cancel**, then remove only that exact temporary file. An in-place Play update may be tapped only from a parsed **Update** node on the exact MoolSocial Play Store page.

## Resolution

The bounded temporary-file method returned a 30,538-character hierarchy, the exact file was removed, and sanitized nodes proved the page title `com.moolsocial.app (unreviewed)`, an **Update** control at bounds `[486,440][582,480]`, the separate **Uninstall** control at `[129,440][243,480]`, and the r60.44 release notes. No coordinate was inferred before this proof.
