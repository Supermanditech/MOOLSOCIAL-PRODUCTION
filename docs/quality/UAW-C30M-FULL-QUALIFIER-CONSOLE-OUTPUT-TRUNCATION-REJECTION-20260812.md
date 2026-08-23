# C30M full-qualifier console-output truncation rejection

- ID: `REG-20260812-1456-C30M-FULL-QUALIFIER-CONSOLE-OUTPUT-TRUNCATION-REJECTION`
- Date: 2026-08-12
- Scope: local provider-only full qualification
- Result: output truncated; no cloud action occurred

The backend run reached 499/499 passing tests, but the spec reporter emitted
more than 500 lines and the tool truncated the complete qualifier output. The
run is not accepted as a sealed full qualifier. C30M retries the same complete
typecheck/build/test suite with Node's bounded dot reporter and preserves each
immediate exit status.
