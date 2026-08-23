# UAW C10 parameterized chooser test stale dock keys

## Incident

The combined C10B affected run reported nine failures from one parameterized
FIX2 block. It still tapped `mvp-action-<section>-<subaction>` keys that belonged
to the retired destination-owned chooser dock. C10B intentionally keeps those
subactions as local content cards under `mvp-action-choice-<id>`.

The new C10B invariant test, R06, R15 and C07 checks passed in the same run. The
failure was therefore a stale test owner, not evidence that the content choices
or routes were missing.

## Prevention

Retiring a navigation owner requires a complete-file key inventory before the
next run. Subaction route tests use content-card keys; only Social, Buy, Eat,
Ride, Book and Work use global `mool-action-<section>` keys.

No APK or OPPO mutation occurred.
