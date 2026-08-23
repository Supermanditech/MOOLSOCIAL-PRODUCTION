# C30T Feed shared-link route-order continuity finding — 2026-08-13

## Finding

Shared Feed link pagination used one boolean resolving guard. If the app route
changed to a different `item=` while the first link was loading a later page,
the new resolution returned immediately. The older request could then promote
its post and finish without ever resolving the newest route.

## Correction

Each shared-item resolution now owns a generation. Completion checks reject an
older owner before resolved/unavailable state changes, and the finishing owner
restarts resolution for the newest Feed route when it was superseded.

## Verification

A delayed-page widget test changes from one shared item to another while the
first later page is pending. The new route loads its next page and promotes the
correct card above the latest Feed card. The complete Social publication suite,
including all five MoolSocial-hosted formats, passed `14` tests. Evidence
SHA-256: `17C1FD620C6F8DF4610AD869387FBD68EDEED383BD559E138D7208E1BC2E4122`.

No backend/provider, Hosting, AAB, Play, OPPO or communication action occurred.
