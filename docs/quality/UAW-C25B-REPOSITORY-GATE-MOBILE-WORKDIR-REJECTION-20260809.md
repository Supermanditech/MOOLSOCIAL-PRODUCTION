# C25B repository gate invoked from mobile workdir — rejection

Date: 2026-08-09

The permanent regression gate was invoked with `./scripts/...` while the shell was rooted at `apps/mobile`. The gate path therefore did not resolve and the compound call stopped before the pubspec or adjacent test import was read.

Repository gates must run from `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`; Flutter commands may run from `apps/mobile` in separate calls.
