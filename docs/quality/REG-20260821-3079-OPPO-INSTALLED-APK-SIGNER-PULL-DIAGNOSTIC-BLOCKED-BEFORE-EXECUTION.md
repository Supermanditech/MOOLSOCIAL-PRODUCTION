# REG3079 — OPPO installed-APK signer pull diagnostic blocked before execution

- Date: 2026-08-21
- Status: registered; no retry

An optional read-only command intended to pull the installed base APK to a
temporary file and compare its signer locally was rejected by command policy
before process creation. No OPPO, filesystem, Play or external state changed.

The diagnostic is not retried because existing Play App Signing evidence and
the independently verified upload-key-signed candidate already establish that
an in-place update is impossible. The destructive uninstall boundary remains
subject to founder confirmation.
