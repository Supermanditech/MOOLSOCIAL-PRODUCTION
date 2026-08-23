# UAW AAB C30Y parallel gate sibling evidence assumption

Date: 2026-08-15
Regression: `REG-20260815-2198-AAB-C30Y-PARALLEL-GATE-SIBLING-EVIDENCE-ASSUMPTION`
Status: registered before retry

## Finding

A four-child gate batch rejected when the first binder child failed. The
follow-up diagnostic incorrectly assumed all requested siblings had completed
and required all four planned log pairs. It stopped on the absent Windows
PowerShell binder log.

No missing file was read or created, and no release action occurred.

## Prevention

- Run these authoritative dual-host gates sequentially.
- After an orchestration rejection, inventory every planned exact path as a
  labeled present-or-absent scalar before reading any file.
- Read only proven-present evidence; a requested sibling is not a completed
  sibling.

## Resolution

The four planned paths were inventoried individually as labeled present or
absent scalars. Only proven-present files were read. The binder retry then ran
sequentially and passed under both PowerShell hosts.
