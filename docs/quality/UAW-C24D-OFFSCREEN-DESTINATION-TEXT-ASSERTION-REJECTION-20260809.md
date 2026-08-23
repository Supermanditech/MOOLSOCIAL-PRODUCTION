# C24D off-screen destination-text assertion rejection — 2026-08-09

The saved-place test performed a real tap and `RideSession.drop` correctly
became `Sardarpura, Jodhpur`. It then searched the entire widget tree for that
text while the destination surface was off-screen after scrolling to the saved
place, creating a false failure.

The permanent correction retains the domain-state assertion, scrolls back to
`ride-destination-search-surface`, and requires its selected-destination
semantic label to contain the exact new destination.
