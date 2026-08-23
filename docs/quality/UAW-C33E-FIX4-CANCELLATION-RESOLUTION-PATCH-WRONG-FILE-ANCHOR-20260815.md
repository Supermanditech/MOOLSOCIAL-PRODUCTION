# UAW C33E FIX4 cancellation-resolution patch wrong-file anchor

Date: 2026-08-15
Regression: `REG-20260815-2354-C33E-FIX4-CANCELLATION-RESOLUTION-PATCH-WRONG-FILE-ANCHOR`

The first correction patch tried to match registry JSON fields while the active patch target was the cancellation evidence Markdown file. `apply_patch` rejected the patch atomically before changing any file.

Recovery: use separate explicit update headers and file-local anchors for evidence, registry and Flutter owners, then validate each owner.
