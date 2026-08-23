# UAW C33G FIX3 format-stale patch context

A combined correction patch used the test layout from before `dart format`. The formatted loop no longer matched, so `apply_patch` rejected the entire patch and changed no intended file.

Every post-format change must begin from a fresh exact section read, and unrelated file patches must retain explicit per-file boundaries.
