# Screen 03 local audit server shutdown reset noise regression

- Regression: `REG-20260815-2474-SCREEN03-LOCAL-AUDIT-SERVER-SHUTDOWN-RESET-NOISE`
- Failure: the 84-case Selenium audit passed but the temporary threaded server printed expected connection-reset tracebacks when Edge connections closed during teardown.
- Impact: page assertions remained 84/84 with zero UI errors; no repository, provider, email, Hosting or device state changed. The noisy run is not used as clean final evidence.
- Prevention: local browser-audit servers override `handle_error` for teardown-only disconnects while preserving fail-closed Selenium, browser-console and assertion handling.
