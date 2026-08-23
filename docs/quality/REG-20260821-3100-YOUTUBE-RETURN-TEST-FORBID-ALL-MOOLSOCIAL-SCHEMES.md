# REG3100 — YouTube return test forbade all MoolSocial schemes

- Date: 2026-08-21
- Status: registered before retry

The Android YouTube return isolation test failed after the canonical authority
fix because it asserted MainActivity contained no `moolsocial` scheme at all.
MainActivity legitimately owns distinct `moolsocial://auth/x` and
`moolsocial://auth/instagram` returns. No build or device action followed.

Prevention: forbid only the YouTube-specific host/path in MainActivity and
require it exactly once in `YouTubeConnectReturnActivity`; preserve the X and
Instagram owners.
