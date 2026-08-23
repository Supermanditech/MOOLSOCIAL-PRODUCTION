# C30K-FIX1 backend evidence workdir-anchor rejection

- Scope: local backend verification evidence.
- Result: the complete backend suite passed 499/499, but its relative log path resolved under `backend/functions/artifacts` because npm ran from that directory.
- Root cause: the evidence directory was not converted to an absolute repository-root path before changing workdir.
- Prevention: pre-resolve all evidence paths from the repository root and repeat the same qualifying suite into the canonical `artifacts/quality` owner.
- Runtime impact: none. No cloud or device mutation occurred.
