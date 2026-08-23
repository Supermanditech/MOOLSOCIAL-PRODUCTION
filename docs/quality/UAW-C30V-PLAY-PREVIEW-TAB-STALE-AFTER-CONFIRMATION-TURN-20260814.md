# UAW C30V Play preview tab stale after confirmation turn — 2026-08-14

After the founder explicitly confirmed `Save and publish`, the stored browser-client tab handle no longer existed because the prior agent tab had been cleaned up at the turn boundary. The click failed with `Tab not found` before reaching Google Play.

No publish, activation, second upload, install, other-track action, or machine-state transition occurred. Recovery is to discard the stale tab handle, open a fresh tab from the existing browser binding, navigate to the exact Internal Testing track, recover the already-uploaded r60.47 draft without choosing another file, and perform the founder-confirmed publish action.
