# C30N Flutter compact/Tee stdout truncation rejection

- ID: `REG-20260812-1472-C30N-FLUTTER-COMPACT-TEE-STDOUT-TRUNCATION-REJECTION`
- Date: 2026-08-12
- Scope: local C30N source-qualification cycle 1rr
- Result: analysis and 168 tests passed, but the tool transcript truncated; no APK build, install, cloud, device or content mutation occurred

The complete cycle captured full logs and exited successfully, but Flutter's
compact reporter emitted carriage-return status through `Tee-Object` to the
tool transcript, which exceeded the output bound. The logs are preserved but
the cycle is not sealed. The complete cycle restarts under new filenames with
the same output written to evidence and piped to `Out-Null`; only immediate
exit status, hashes and bounded tails are returned.
