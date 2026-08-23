# REG3081 — OPPO package presence falsely classified from raw ADB count

- Date: 2026-08-21
- Status: registered before retry

The first device command treated any raw `pm list packages` record count other
than exactly one as package absence. A subsequent exact-line, primary-user
readback proved `com.moolsocial.app` remains installed. No uninstall or install
had occurred.

Prevention: normalize ADB output and count only the literal
`package:com.moolsocial.app` line. Never derive absence from the raw record
count.
