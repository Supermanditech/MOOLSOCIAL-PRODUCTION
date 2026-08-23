# C22C overbroad patch-context rejection

The first combined C22C patch grouped distant layout, scrolling and capsule-body owners and expected a `-65` callback in the wrong adjacency. `apply_patch` rejected the operation before changing source. The retry uses separate exact hunks from the current file.
