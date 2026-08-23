# C29O share-proof scroll disturbed Details tap rejection

Date: 2026-08-11

The canonical-share proof called `ensureVisible` on the lower action row before
the pre-existing Details journey. The watch list then left the Details trigger
above the viewport; its later tap missed and the sheet assertion failed. The
cycle is rejected. Share proof must run after the navigation assertions whose
scroll position it can disturb, or the test must explicitly restore position.
