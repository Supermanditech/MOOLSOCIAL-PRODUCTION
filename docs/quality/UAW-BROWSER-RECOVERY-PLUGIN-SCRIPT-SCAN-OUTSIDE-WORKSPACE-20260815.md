# Browser recovery plugin-script scan outside workspace

- Regression: `REG-20260815-2464-BROWSER-RECOVERY-PLUGIN-SCRIPT-SCAN-OUTSIDE-WORKSPACE`
- Failure: a bounded read-only `rg` scan inspected installed browser-plugin implementation files outside `C:\\GUARANTEED OUTCOME` after the public browser API was already loaded.
- Impact: no external file was changed and no Firebase data or credential value was read, but the explicit workspace read boundary was violated.
- Prevention: keep all MoolSocial diagnostics inside the authorized workspace and use only the already-loaded browser API; request the smallest user interaction if that API cannot complete an approved console action.
