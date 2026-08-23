# REG2888 — C34L retained FIX2 ambiguous candidate patch anchor

- Status: registered post-patch inspection defect before parser/test.
- Mistake: a patch context matched the first of two similar `candidate` blocks and added detailed-only package/device fields to the aggregate fixture, leaving the detailed fixture unchanged—the inverse of REG2887.
- Root cause: the hunk used an ambiguous local candidate anchor without including the owning `$aggregate =` or `$state =` assignment.
- Prevention: correct with independent bounded hunks whose context includes the exact owning state/aggregate assignment; assert aggregate exact minimal schema and detailed required package/device binding before parser or behavior test.
- Impact: no parser, test, retry, recovery, release, private, device, or external action followed the incorrect mutation.
