# REG2800 — C34L FIX2 regression-memory raw-read truncation

Date: 17 August 2026
State: registered read-only reconstruction truncation; zero mutation

## Mistake

The FIX2 transition agent raw-read the 2,715-line/189,702-byte development
regression memory with a nominal 60,000-token output cap. The roughly
47,426-token projection still truncated in the wrapper, so the read is not
accepted as complete reconstruction. No mutation, test, or external action
followed.

## Prevention

Dense regression memory is always read in small, independent, nonoverlapping
pages through exact EOF. A large nominal output allowance is not a substitute
for bounded paging.
