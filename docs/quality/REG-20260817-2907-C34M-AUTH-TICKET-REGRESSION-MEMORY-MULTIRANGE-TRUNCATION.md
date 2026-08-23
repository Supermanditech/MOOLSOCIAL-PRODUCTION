# REG2907 — C34M auth-ticket regression-memory multirange truncation

## Incident

On 2026-08-17, the queued authentication-ticket planner combined regression-memory ranges 1–420, 1780–1860, 1900–1935, and 2250–2305 in one read. The tool returned an explicit truncation warning with 10,327 original tokens and 597 output lines.

## Impact

- The grouped regression-memory reconstruction is inadmissible.
- No authentication ticket, active scope, runtime, provider, build, device, browser, private/account, secret, SMS, email, Play, OPPO, or external state was written or accessed.
- The planner stopped before mutation or retry.

## Root cause

Several dense, noncontiguous regression-memory windows were combined into one output rather than read in isolated bounded pages.

## Prevention

- Read regression memory in independent nonoverlapping windows of at most 100 lines.
- Accept only warning-free pages and verify requested start/end coverage.
- Never group distant dense windows in one command.
- Replay the implementation memory gate alone after registration before ticket planning resumes.

## Disposition

Registered truthfully before retry. No incomplete memory output is accepted as authorization or schema authority.
