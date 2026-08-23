# UAW AAB C30Y Play upload-evidence patch stale document anchor

Date: 2026-08-15
Regression: `REG-20260815-2212-AAB-C30Y-PLAY-UPLOAD-EVIDENCE-PATCH-STALE-DOC-ANCHOR`
Status: resolved; exact document-tail patch and evidence verification passed

The first attempt to record Play's successful one-file upload selection used a
nonexistent prose anchor in the REG-2211 document. `apply_patch` rejected the
entire patch atomically; no evidence, registry status or document was changed.
The Play Internal Testing draft remained open with the sole r60.48 artifact.

The retry reads the exact document tail first, uses exact bounded hunks, and
verifies the safe upload-selection evidence JSON plus all three registry
statuses after the patch.

## Resolution

The exact document tails were read before retry. The bounded patch created the
safe upload-selection evidence and resolved REG-2210/2211; JSON identity,
internal track, one-file selection and inactive-draft state all verified.
