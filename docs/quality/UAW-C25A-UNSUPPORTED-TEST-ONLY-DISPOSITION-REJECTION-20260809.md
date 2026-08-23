# C25A unsupported `test_only` disposition — rejection

Date: 2026-08-09

The first C25A scope selection was rejected before execution because its implementation disposition included `test_only`, which is not in the active delivery checker’s accepted enum. No runtime, build, install, backend or external mutation occurred.

The correction must use the checker’s exact enumerated vocabulary, update both manifest and scope assessment consistently, recompute the manifest SHA-256, and rerun the complete scope and regression gates.
