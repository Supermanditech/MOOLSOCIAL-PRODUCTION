# REG2916 — C34L FIX3 multi-file contract propagation context mismatch

## Incident

On 2026-08-18, the FIX3 producer agent attempted one multi-file patch to propagate the v3 capture contract ID/hash/schema. Patch verification failed at `scripts/check-release-oppo-evidence-transaction-c34l.ps1` because the expected `$captureArtifactContractId = ...002` context did not match the live owner shape. The patch engine rejected the operation; no hunk was accepted.

## Impact

- The pre-existing FIX3 ticket, v3 contract and 645-line authoritative producer edits remain preserved.
- No contract propagation hunk, parser, behavior test, candidate, seal, cycle, build, Play, OPPO, browser, private/account, device, secret or external action followed.
- The agent stopped without inspection or retry.

## Root cause

A broad cross-owner propagation patch relied on one remembered contract-constant layout instead of independently rereading and patching each live owner with a small exact anchor.

## Prevention

- Inventory every target owner's literal contract ID/hash declaration and schema use before mutation.
- Patch one owner per bounded operation; parse and read back that owner before the next.
- Never combine existing writers, validators and fixture checkers in one propagation patch.
- Require the new subagent coordination policy and gate before resume.

## Disposition

Registered by the primary as the unique next ID. The failed patch performed zero writes.
