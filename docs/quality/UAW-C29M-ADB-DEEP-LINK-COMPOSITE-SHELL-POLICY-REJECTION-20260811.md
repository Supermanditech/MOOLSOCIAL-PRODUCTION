# C29M ADB deep-link composite shell-policy rejection

- Date: 2026-08-11
- Result: command blocked before execution; no device mutation

The intended YouTube creator deep link was bundled with screenshot capture and cleanup using mixed PowerShell quoting. The safety parser rejected the composite command.

The corrected flow isolates the Android route launch from evidence capture, uses a literal URI argument, checks the launch result, and performs capture separately.
