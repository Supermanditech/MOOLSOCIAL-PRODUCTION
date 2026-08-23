# Backend evidence output escaped the production repository

Date: 2026-08-14
Incident: `REG-20260814-2169-AAB-BACKEND-EVIDENCE-OUTDIR-ESCAPED-PRODUCTION-REPO`
State: registered before retry

From `backend/functions`, the relative output `..\\..\\..\\artifacts` resolved
to `C:\\GUARANTEED OUTCOME\\artifacts`, one directory above the production
repository. This remained within the founder-authorized workspace, but it is
not valid durable production-repository evidence.

The escaped directory is preserved and will not be deleted, moved, reused or
claimed. The retry must construct its output from the exact absolute
`C:\\GUARANTEED OUTCOME\\MOOLSOCIAL-PRODUCTION` root, assert containment and
absence before writing, and keep the complete log in the same in-repository
evidence root. No release action occurred.

## Resolution

The retry constructed all paths from the exact absolute production repository
root, asserted the root-plus-separator containment prefix and target absence,
and wrote only to the C30X in-repository quality evidence root. The escaped
first-attempt directory remains preserved and unclaimed.
