# REG2826 — C34L retained builtAt valid-offset rejection

Date: 17 August 2026
State: registered fresh WinPS compatibility failure; diagnosis pending

## Mistake

The fresh Windows PowerShell retained run rejected valid authoritative-wrapper
round-trip timestamp `2026-08-17T05:30:00.0000000+05:30` as not one semantically
valid instant before negative fixtures began. The agent stopped immediately;
no diagnostic, retry, later mutation, or external action followed.

## Prevention

After registration, inspect the exact parser helper and overload once. Prove
the invariant `DateTimeOffset` round-trip grammar and parse behavior directly on
both hosts, then keep separate valid `+05:30`, valid `Z`, malformed, and
ambiguous-offset fixtures before rerunning the retained suite.
