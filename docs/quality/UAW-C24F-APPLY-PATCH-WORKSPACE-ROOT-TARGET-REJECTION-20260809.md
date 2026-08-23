# C24F apply-patch workspace-root target rejection — 2026-08-09

The first successor-manifest patch used repository-relative paths while the
patch tool was rooted at `C:\\GUARANTEED OUTCOME`, one directory above the
production repository. It created four new evidence files under the wrong
workspace-level `artifacts` directory. No predecessor or user file was
overwritten. The four files were removed with the same patch mechanism and
recreated under `MOOLSOCIAL-PRODUCTION/artifacts/quality`; the incorrect
paths no longer exist.

All later repository patches include the explicit `MOOLSOCIAL-PRODUCTION/`
prefix and are verified from the exact repository root before another
mutation.
