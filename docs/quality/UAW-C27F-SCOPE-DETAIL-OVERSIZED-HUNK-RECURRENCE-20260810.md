# C27F scope-detail oversized-hunk recurrence

After the C27F identity fields transitioned successfully, a second patch still
coupled assessment and ticket list sections. One current string differed, so
`apply_patch` rejected the complete detail mutation before any list changed.

This repeats the C27E oversized-hunk boundary class. Each array must be changed
in its own exact-context patch and validated immediately.
