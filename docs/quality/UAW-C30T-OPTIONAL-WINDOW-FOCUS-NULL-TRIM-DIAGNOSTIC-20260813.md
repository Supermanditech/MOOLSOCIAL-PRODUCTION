# UAW C30T optional window-focus null Trim diagnostic — 13 August 2026

The primary read-only activity query proved `com.moolsocial.app/.MainActivity` was foreground. A secondary optional `mCurrentFocus` search returned no line, and the command incorrectly called `.Trim()` on null. Future optional dumpsys searches are materialized as arrays and explicitly report absent results. No device input or product state changed.
