# C31E attachment test metadata index optionality — 15 August 2026

The first typecheck after adding the attachment-store tests rejected one test
assignment. A custom-metadata map index is `string | undefined` under the
repository's `noUncheckedIndexedAccess` policy, but the negative test assigned
that value directly to a required string entry while restoring a deliberately
corrupted owner binding.

Production source remained type-correct. The test must retain and assert the
original required header value before corruption, then restore from that
definite local. No generated output or external state changed.

The test now asserts and retains the owner binding before mutation, and the
complete backend `tsc --noEmit` run passes.
