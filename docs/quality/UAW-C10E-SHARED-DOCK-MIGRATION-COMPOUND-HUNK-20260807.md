# UAW C10E Shared dock migration compound hunk

- Registry: `REG-20260807-219-C10E-SHARED-MIGRATION-COMPOUND-PATCH-USED-STALE-TAIL-CONTEXT`
- State: resolved before retry; rejected patch changed no Shared source
- Detection: `apply_patch` rejected the combined import, scaffold, local-rail and `_SharedDock` removal patch.
- Root cause: a terminal class deletion was coupled to several valid earlier changes using context copied from a prior compound view rather than a fresh exact tail.
- Durable prevention: patch the import, global bottom owner, in-content local rail and obsolete terminal class as four independent hunks, verifying source after each.
