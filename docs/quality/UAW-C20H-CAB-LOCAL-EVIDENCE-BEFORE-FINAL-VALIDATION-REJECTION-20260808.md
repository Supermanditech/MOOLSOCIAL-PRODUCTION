# C20H Cab local evidence before final validation rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

The Cab sequence proved two consecutive `Cab, current` and `Ride, current. Hide
Ride options` hierarchies. State then moved before the final hierarchy, and the
helper rejected it. However, version one of the helper had already pulled the
PNG/XML into `13-ride-cab` local names. Those files are preserved with an
adjacent rejection marker and are excluded from accepted evidence.

## Prevention

The helper now keeps the screenshot and final hierarchy on remote temporary
paths, validates exact selected semantics from the remote XML, and only then
pulls both into new local filenames. The retry is named `13b-ride-cab` and local
evidence is file-atomic with respect to selected-state validation.
