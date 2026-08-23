# UAW C16H OPPO serial typo local-action rejection — 2026-08-08

## Rejection

The valid `09-eat-order-food` pair was admitted. The following Book Table tap used the mistyped serial `2b3e071`; adb reported that the device was not found, and the paired validator correctly rejected the still-selected Order Food state.

The existing `10-eat-book-table` files are preserved but excluded from the accepted matrix.

## Prevention

Remaining commands bind `2b3e0f71` once to a variable and reuse it. The Book Table retry uses a unique filename and must prove both Eat and Book Table selected semantics.
