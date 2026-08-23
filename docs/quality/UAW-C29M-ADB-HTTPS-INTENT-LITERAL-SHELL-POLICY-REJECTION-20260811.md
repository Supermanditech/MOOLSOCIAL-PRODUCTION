# C29M ADB HTTPS intent literal shell-policy rejection

- Date: 2026-08-11
- Result: host blocked command before ADB; no device action

The isolated Android VIEW command still contained a raw HTTPS URI and was rejected by the host shell policy. The custom `moolsocial:` callback activity had already returned to the existing app route and is not a generic route launcher.

The HTTPS route is not retried or encoded around the policy. C29M uses the verified in-app create-gateway navigation and device taps.
