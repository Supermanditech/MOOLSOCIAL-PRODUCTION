# C17G adb install reserved-artifact long-path stat failure

The single authorized C17G `adb install -r` command used the deeply nested descriptive reserved artifact path. Windows adb returned `failed to stat ... No such file or directory` before transmitting the package. The command output contained only `Performing Streamed Install`; it never returned Android package-manager success or failure.

Immediate live verification proved OPPO CPH2375 still has `1.0.0-r60.16` (`2026080816`), unchanged first/last install times and SHA-256 `1CC2A0186CA5DC8C9A09D0B4CC949B94CEE91DE6C70246A4B0168ADE6255150D`. No package bytes, install, uninstall, data clear or downgrade occurred.

C17G's install command is consumed. The same command is not repeated. The founder's continuing-through-OPPO authority permits a separately selected install-recovery ticket using the shorter generated APK only after its exact identity with the reserved r60.18 artifact is re-proven and all device gates pass again.
