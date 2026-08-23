# UAW C30V OPPO unsupported get-install-source shell subcommand — 2026-08-14

The read-only OPPO preinstall identity check called `cmd package get-install-source`, which is unsupported by this CPH2375 firmware and returned exit 255. The same read proved the device connected and MoolSocial remained r60.45/2026081345.

No install, uninstall, data clear, downgrade, or device mutation occurred. Installer identity must be proved with the supported `pm list packages -i com.moolsocial.app` output and an exact `installer=com.android.vending` row.
