# C24D Social test-discovery absolute-path rejection

- Observed: 2026-08-09 before the protected successor seal.
- Rejected command: matching `social|youtube|screen04` against absolute paths selected all 223 tests because `MOOLSOCIAL-PRODUCTION` appears in every path, then exceeded the Windows command-line limit.
- Correction: match only the path relative to `apps/mobile/test` and report the qualifying count before invocation.
