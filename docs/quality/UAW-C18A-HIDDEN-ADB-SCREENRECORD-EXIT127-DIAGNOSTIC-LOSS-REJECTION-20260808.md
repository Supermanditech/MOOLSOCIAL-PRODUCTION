# UAW C18A hidden ADB screenrecord exit-127 diagnostic-loss rejection — 2026-08-08

## Rejected attempt

The first C18A bounded recording orchestration launched ADB through a hidden
Windows process, then launched the installed app. The ADB process had already
exited when `Wait-Process` ran and reported exit code 127. Its standard output
and error were not retained, so the command cannot establish why recording
failed and no video was pulled or admitted.

No APK build, install, uninstall, data clear, downgrade, source, golden or
accepted-reference mutation occurred.

## Prevention

Before another recording, C18A must run a foreground device-side
`screenrecord` capability check with its own exit status. The qualified capture
must start recording in the Android shell, independently verify the remote
file after the time limit, then pull and hash it. A hidden local process without
retained diagnostics is prohibited for device-motion evidence.
