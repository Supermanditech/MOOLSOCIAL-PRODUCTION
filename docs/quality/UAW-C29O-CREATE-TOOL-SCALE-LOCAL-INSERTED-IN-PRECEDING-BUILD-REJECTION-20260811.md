# C29O Create tool scale local inserted in preceding build rejection

Date: 2026-08-11

The first tool-height patch used a generic `Widget build(BuildContext context)`
anchor. `apply_patch` placed the new scale locals in the preceding widget at
line 905 while the `_ToolAction` height referenced them at line 1030. Focused
analysis rejected the unused local and undefined identifier; tests did not
load.

Permanent prevention: repeated method signatures are never mutation anchors by
themselves. A patch includes the exact declaring class plus its method, then a
focused analysis precedes any test run.
