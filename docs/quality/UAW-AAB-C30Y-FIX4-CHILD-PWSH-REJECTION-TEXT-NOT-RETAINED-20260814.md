# C30Y FIX4 child-pwsh rejection text not retained

- Incident: `REG-20260814-2184-AAB-C30Y-FIX4-CHILD-PWSH-REJECTION-TEXT-NOT-RETAINED`
- Checker: `scripts/check-c30y-fix4-c30x-negative-build-rejection-classifier-truth.ps1`

The first FIX4 checker execution reached its child C30X probe and then failed closed because the normalized child text did not match the assumed incomplete-qualification expression. The checker emitted only its own rejection, not the child exit/text, so the first failure does not contain enough retained detail to distinguish active-scope rejection, native error formatting, ANSI normalization or reason-text mismatch.

No state, aggregate, source manifest, count, authority, build, upload or device action changed. Before retry, the checker must accept a unique repository-contained diagnostic evidence path, refuse overwrite, write the child native exit plus normalized bounded text before classification, and preserve that attempt even when classification fails. The corrected diagnostic attempt must be registered and inspected before changing the expected classifier.

Resolution: the classifier now requires a unique file under the exact C30X evidence root, refuses occupied or escaped paths, and writes native exit, ANSI-normalized text and semantic text before asserting the expected rejection. Diagnostics from attempts 01 through 06 remain retained; the final two candidate-context host runs passed.
