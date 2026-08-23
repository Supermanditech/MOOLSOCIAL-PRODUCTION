# REG2787 — C34L readiness manifest-bound premature artifact gap

Date: 17 August 2026
State: registered next readiness negative failure; no external action

## Finding

After REG2785 correction, the fresh PS7 readiness self-test correctly rejected
premature counts and authorities but its injected premature artifact fixture
still passed in `prebuild_manifest_bound_two_fresh_cycles_required`. Artifact
path/SHA/bytes, release results and proof/evidence absence were enforced only by
the selection-state assertion and skipped after manifest binding. The agent
stopped; cleanup completed and WinPS did not run.

## Required correction

Create one common source-precycle invariant used by selection and manifest-bound
states. It must enforce zero counts, held authorities, no artifact/provenance,
no Play/OPPO/journey results, no retained browser binding or lifecycle proof,
no founder input and zero release actions while allowing only the exact source
manifest/cycle fields appropriate to that state. Add premature artifact,
evidence and proof negatives on both hosts.
