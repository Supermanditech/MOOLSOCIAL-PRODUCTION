# REG2906 — C34L primary identifier search yielded-session handle loss

## Incident

On 2026-08-17, the primary agent launched a repository-wide fixed-string `rg -l` inventory for the Play capture producer identifier with a 10-second yield. The orchestration wrapper emitted only `r.output` instead of preserving/printing the complete `exec_command` result. The visible result was empty after about 10.2 seconds, so a possible yielded session identifier and exit metadata were discarded.

## Impact

- The identifier inventory is zero qualification evidence.
- The command was read-only, but its completion state was ambiguous at detection time.
- No repository mutation, recovery, candidate, seal, cycle, launcher, build, Play, OPPO, browser, private/account, device, secret, or external write was initiated.

## Root cause

The wrapper assumed the bounded search would finish inside the initial yield and projected only output text, discarding `session_id`, `exit_code`, and elapsed metadata.

## Prevention

- Always serialize or explicitly preserve the full `exec_command` result for any command that may yield.
- Search only explicitly scoped relevant owners, not the complete huge workspace tree.
- If a session yields, poll or terminate only the exact returned session; never launch a duplicate search.
- Register the handle loss before a bounded exact-process recovery check or any retry.

## Disposition

Registered truthfully. No empty output is interpreted as identifier absence.
