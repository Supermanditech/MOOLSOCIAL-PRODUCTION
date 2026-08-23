# C25F Social Chat wrapper semantics-node assertion rejection

- Date: 2026-08-09
- Status: registered before focused test retry

The first real-route Chat test requested semantics from the keyed Social styling wrapper. The actual tap semantics belong to its descendant IconButton, so the wrapper node did not advertise `SemanticsAction.tap` even though the control was visible and tappable.

The corrected gate resolves the unique `Open Chat` tooltip/semantic button and validates that interactive node while continuing to measure the keyed outer hit target.
