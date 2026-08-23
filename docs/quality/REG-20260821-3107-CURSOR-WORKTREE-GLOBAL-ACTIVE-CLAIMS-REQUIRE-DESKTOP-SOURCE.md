# REG-20260821-3107 — Cursor worktree global active claims require Desktop source

Date: 21 August 2026
State: registered; retry blocked pending worktree-scoped policy projection

## Failure

After the isolated Cursor regression-memory gate passed with every one of
3,679 registered gate/evidence paths present, its coordination gate rejected
because a Desktop-primary active-claim owner was absent from the separate
baseline worktree:

`apps/mobile/android/app/src/main/res/xml/data_extraction_rules.xml`

## Impact

- No Cursor audit read, test, source edit, build, provider, Play or OPPO action
  ran after the rejection.
- No Desktop auth/source owner was copied into the isolated baseline as a
  workaround.
- Cursor's existing B1/B2 outputs remain preserved.

## Root cause

The global coordination policy includes all active Desktop and subagent claims.
The checker validates every recorded owner in its current repository root, so
an exact global-policy copy cannot qualify an intentionally isolated worktree
that does not inherit Desktop's uncommitted source changes.

## Prevention

The primary must create a worktree-scoped policy projection that retains the
current registry binding, mandatory reads, prevention rules, release
serialization and Cursor's exact single report owner while excluding unrelated
Desktop/source claims from that worktree only. The production policy remains
unchanged and authoritative. The projected policy must parse, retain one exact
Cursor claim, contain no authentication/build/Play/provider/OPPO owner, and
pass the isolated coordination self-check before Cursor resumes.
