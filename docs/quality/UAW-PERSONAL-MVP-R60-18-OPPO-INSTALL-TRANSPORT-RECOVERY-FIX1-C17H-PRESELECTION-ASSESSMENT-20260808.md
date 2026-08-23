# C17H r60.18 OPPO install-transport recovery preselection

State: `selected_install_recovery_preflight_pending`

C17H is an MVP-required device-evidence recovery. C17G successfully built and validated one r60.18 APK, but its install command failed at local Windows path stat before device mutation. C17H adds no build, source, screen, route, feature or state owner.

It reuses the exact 134,427,417-byte r60.18 candidate. The path-safe generated output is admissible only if its SHA-256 equals the reserved artifact's `88F82D203E1C8C565BE5DEBB61E6C1EF1F9E588017EADB9120D97B4B3081ED2C`, package/version/signature remain valid, source fingerprint remains `04FB5C9DD229666CF6302C42EF5B4760A1255474ED84519D3D9A1FE4A7C420FD`, and the unlocked OPPO still contains checksum-matched r60.16.

After those gates, exactly one path-safe `adb install -r` is authorized. Success must preserve first-install time and prove the installed base equals the candidate checksum. Founder acceptance remains pending through the six-family device review.
