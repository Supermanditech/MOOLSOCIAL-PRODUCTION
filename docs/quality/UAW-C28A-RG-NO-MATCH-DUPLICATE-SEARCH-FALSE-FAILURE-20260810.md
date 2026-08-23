# C28A duplicate-search false failure

- Date: 2026-08-10
- Phase: pre-ticket shared-owner audit
- Mutation before failure: none
- Device effect: none; installed r60.26 remained unchanged
- Observation: the combined MainActivity read and `rg` duplicate-search returned exit code 1 solely because no `SystemChrome`, `WindowCompat`, or edge-to-edge override existed, although the requested source file was read successfully.
- Root cause: an expected no-match duplicate-search was allowed to determine the whole shell command exit status.
- Prevention: normalize `rg` exit code 1 to a successful no-match result when absence is an expected audited outcome; preserve exit code 2 and other real failures.
