# C21H compound ADB failure masked and empty input hashed — 2026-08-08

After the guessed package ID returned no path, the compound command attempted to call `.Trim()` on null and then invoked device `sha256sum` without an APK path, yielding the SHA-256 of empty input. A later successful machine-state read masked the native-command failure and the shell call ended at exit zero.

The output is rejected and is not installed-identity evidence. REG-20260808-493 requires separate exit/output assertions and an exact `/data/app/` package path before checksum comparison. No device mutation occurred.
