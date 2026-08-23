# UAW C18A device-precondition screencap nonzero rejection — 2026-08-08

## Rejected attempt

After waking the connected OPPO, a device-side
`screencap -p /sdcard/c18a-device-precondition.png` command returned nonzero.
The wrapper stopped before pull, so no successor screenshot was admitted. ADB
immediately continued to report the sole OPPO CPH2375 serial `2b3e0f71` in
`device` state.

No APK build, install, uninstall, data clear, downgrade, reference mutation or
app-data mutation occurred.

## Root cause and prevention

The failed command did not retain a useful device-side diagnostic and did not
verify remote-file creation independently. The retry must retain the raw
`screencap` output and exit status, then test the exact remote path before any
pull. The display/keyguard precondition must be resolved separately; no image
from a failed capture may establish Screen01 equivalence.
