# C26G empty second update hunk patch rejection

An attempted REG885 resolution patch included a second file-update header without any hunk content. `apply_patch` rejected the whole patch before mutation.

The registry status and documentation append are now applied as separate bounded patches after inspecting the exact evidence-file ending.
