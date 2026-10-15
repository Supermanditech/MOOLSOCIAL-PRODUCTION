# LF-18 — Selling Store owner's details and commercial-default input recovery

MVP-required enter-once/update-at-source correction in existing Store details /
Payments & returns editor. Founder authorized supported pending settings and
verified defects overnight; morning acceptance pending. Preserve LF16/LF17.

Recover only this editor's explicit owner fields: business type, two channel
preferences, street/city/state/PIN/public contact, legal name/billing address,
PAN/CIN/FSSAI/signatory, wholesale default payment terms, return summary/window/
conditions/remedies and dispatch days. Private encrypted account+Store record,
strict version/field validation and existing secure-write queue. Exclude resolved
shoppingArea, verification/approval/publication/serviceability, trading-hours
screen fields, payment-method selections and private customer-specific exceptions.
Do not serialize/replay operational state or implicitly copy pickup settings.

Use current typed input validation, preserve newer edits and unknown/corrupt
records, load before editor/controller initialization, retain failure inputs and
show pending/error/device-saved status distinct from public synchronization.
Reject wrong account/Store/navigation/disposal results and duplicate pending
saves. Restore only allowed fields, preserving excluded current fields; an address
change must invalidate any current resolved location reference, never grant it.
No restore operational command, Stock/order/money rewrite or live publication.

Demonstrate current restart loss; test independent persisted-store/new-session
roundtrip, private/excluded fields, corrupt/future/missing/unknown data, delayed
read/write, failure/retry, scope changes, existing input saves and large text.
Hot-reload OPPO and perform an evaluation owner-preference save/reopen/restart
through actual UI where available, preserving Cart/Stock. Host fixtures are not
runtime records. No backend/new API, native dependency, APK/install, live commerce,
push/another tree or policy/registry expansion. Other settings and synchronized
inheritance/consumers remain open until their applicable checks are complete.

## Implemented checkpoint — 16 October 2026

Existing secure owner adds a distinct publication-inputs key, preserving all
previous key formats and raw-write queue protections. WorkSession reuses LF16's
per-owner input-recovery state;20 explicit fields only are persisted. Strict
typed normalization rejects unknown nested terms or excluded keys. Recovery is
editor-triggered, before controllers are initialized; it does not automatically
hydrate every consumer. Per-account caches live inside per-Store data. Excluded
current customer terms/hours/methods remain untouched; changed address clears
only its local shoppingArea. Verified account contact stays bound to its original
number, not the recovered public contact. No restore operational command or
authority grant. Saving remains a frontend preference operation through existing
callers; a device acknowledgement is never public/provider acknowledgement.

Observed failing-before: saved legal name/return window/dispatch defaults empty in
a fresh session. Final64 settings/form cases passed,0 failures/skips, including
24 LF18 cases. Additional12 shared secure-offer checks and9 LF15/LF16/LF17 widget
checks passed. Focused analysis of all4 changed app/test owners reports no issues.
Coverage includes actual plugin serialization/new-session recovery,10 malformed
records, excluded/private data, failed-read retry, failed-save retained input and
same-value retry, pending-save disabled controls, Store/account/ABA/disposal,
normal/200% editors and customer-exception save before default load preserving
unread bytes. Last case proves no device-saved claim or defaults overwrite from
that path; it does not establish customer-exception durability.

Candidate regressions were caught and corrected: asynchronous loader delayed the
legacy session-only editor, so retain immediate initialization only when scoped
storage is unavailable; stale retained Save silently returned, so restore explicit
context-change feedback; retry arrow returned a Future inside setState, so use a
void assignment block. No assertions were removed. An earlier combined run output
truncated and failed; reran serially with adequate output and read final results.
These failed candidate runs are not passes. Existing source gates retained; no
registry/policy expansion or new recovery framework.

Actual OPPO2b3e0f71, TEST Store · product entry: hot restart5613ms. Through existing
Business details → Address & invoicing, entered TEST Store Evaluation /Evaluation
Store lane /Pune /Maharashtra /411001, leaving public contact and optional business
references blank. Pressed Apply Store details; confirmed Saved on this device.
No main Apply settings/availability action. Detached, force-stopped/relaunched
only installedr67.3, reattached this source and hot-restarted3831ms. Reopened the
same editor: all5 entered values restored; device-only status and location
confirmation still required. Observed retained Cart1item₹164/payment hold and
Stock cost29550,24available/6unavailable/18low after restart.

Then through Payments & returns saved evaluation summary "Unopened goods: Store
review required", window7days, kept dispatch0, conditions/options/wholesale terms
unchanged. Apply terms and confirmed device-save status observed. Current-source
hot restart3507ms; reopened the form and verified exact summary/7/0 restored.
Viewed task outputs lf18-defaults-before/saved/restored-20261016.png and
lf18-terms-saved/restored-20261016.png for the respective visible states.
Phone remains on restored terms for morning review. No commerce write, runtime
seed, provider query, refund/payment/order/Stock/PDF action, new APK/install or
push. This is reattached-source device evidence, not updated standalone-APK
qualification. Actual multi-account authentication-epoch replacement and backend
reuse/import/synchronization remain unverified.

Architect context review supported the bounded recovery after verification,
private-exception and scope checks; morning founder acceptance remains pending.
Other Store settings, private exceptions, automatic consumer initialization and
authoritative revision/conflict/readback/sync remain unfinished. No whole mapped
frontend/MVP, public publication or payment/delivery completion claim.
