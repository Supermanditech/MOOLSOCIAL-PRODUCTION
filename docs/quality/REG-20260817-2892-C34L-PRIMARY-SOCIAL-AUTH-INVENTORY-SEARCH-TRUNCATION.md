# REG2892 — C34L primary social-auth inventory search truncation

- Status: registered read-only planning reconstruction failure.
- Mistake: a broad `rg --files docs config` social/auth/provider filter returned 513 lines and was truncated at roughly 10,613 tokens, so it is not admissible as a complete inventory.
- Root cause: provider/auth terms were combined across all docs/config instead of querying the already-known exact ticket families and bounded directories separately.
- Prevention: inventory exact `uaw-c30t` auth tickets and current C33E/C33G/C33H/C33J/C33K/C34H owners with independent fixed-string or filename-prefix searches; cap each projection and treat exit 1 as expected only when explicitly guarded.
- Impact: read-only; no provider, login, device, private, release, or external action.
