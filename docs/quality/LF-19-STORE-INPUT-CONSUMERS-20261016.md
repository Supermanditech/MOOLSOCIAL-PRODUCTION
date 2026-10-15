# LF-19 — Initialize saved selling-Store inputs before dependent consumers

Exact actor: Retailer/Grocery Store owner using the same saved defaults after
restart without first visiting their editor. MVP-required continuation of LF18;
overnight implementation authorized, morning acceptance pending.

Concrete source gap: _createInvoice snapshots seller name/address from session
publication details, while LF18 loads those inputs only on editor entry. Public
Store projection/readiness has the same unchecked source. Reuse the scoped,
coalesced loader on active-Store selection; no second preference source or whole
Store blocking screen. Distinguish unchecked/loading, checked absence, loaded and
failed records. Missing record permits existing defaults, unreadable/corrupt does
not silently become absence. Preserve LF18 scope/newer-input/verification rules.

Only dependent consumers are held: new Counter invoice submission must load the
inputs before journal/Stock/order/money mutation and recheck scope/review/busy.
Direct synchronous creation must refuse unchecked inputs before side effects;
existing immutable invoice snapshots remain accessible. Counter draft preparation,
history and unrelated Store actions remain available. Public projection/readiness
must disclose unchecked inputs rather than fabricate a Store or publication.
Keep visibility requests labelled as session preferences, not public confirmation.

Focused fresh-session-without-editor consumer regression; missing/corrupt/delayed/
scope failure, no premature invoice/Stock mutation, preserved drafts/history and
unchanged legacy session-only behavior. Existing counter/recovery/publication and
preference regressions. OPPO hot restart then inspect a dependent non-transaction
screen before the publication editor; no new native invoice/payment/Stock action.
No backend/new API, live publication, eligibility grant, native dependency, APK,
push, other tree, redesign, registry/policy expansion or new framework. Other
defaults/customer exceptions/provider contracts remain open.

## Implemented checkpoint evidence — morning review pending

Fresh-session host Counter invoice reproduced an empty seller legal name before
the correction. Eight new cases cover initialization, actual seller snapshot,
pending/absent/unreadable records, preserved immutable history and draft/Stock,
concurrent submissions and Store-change/ABA guards. Final89 settings/publication
checks passed,96 Counter checks passed;11 conditional Counter review cases were
then run with their actual review flags and all11 passed. Focused Dart analysis
has no issues. These host fixtures are not runtime evaluation transactions.

Candidate compile/test errors were corrected rather than counted: nullable
profileId, the existing noticeMessage API and current saved Stock row identity.
A Windows batch command containing a pipe in its regex ran no tests; its safe
character-class replacement produced the recorded terminal Counter results.

OPPO source hot restart5270ms, then Shop -> Work -> Workspace -> profile ->
Operations -> Store settings -> Delivery & pickup, without entering publication
settings. Existing pickup Pune/411001/Evaluation pickup lane remained. The
Use saved Store address action was available; selecting it populated Evaluation
Store lane from the recovered LF18 inputs. No Save was pressed. Back and reopen
restored the separate original pickup lane. Screenshot in the task outputs:
lf19-input-consumer-20261016.png, visually inspected. No native invoice/payment/
Stock/order mutation, provider success or new APK is claimed.

That inspection found a follow-up existing form defect: its saved caption remains
visible after an unsaved address copy. Keep this explicit for the next supported
settings correction; it does not mean the copied form values were persisted.
Architect context review found no further bounded LF19 blocker. Public projection
readiness is a hook/test seam, not a newly connected public provider consumer.
Other defaults/hours/private exceptions, sync, provider contracts and full mapped
frontend completion remain open. Founder morning acceptance is still pending.

## Dependent pickup form follow-up

The observed unsaved-copy caption is corrected in the same existing consumer.
Its current text/toggle values qualify the existing confirmed saved-state flag;
controller equality never creates a new device-saved claim. Error and in-flight
save states retain precedence. Copy, text edits and toggle remain unsaved until
explicit Save; no storage write or new route/state owner was introduced.

Two new full-editor cases reproduced the missing Unsaved changes caption before
the correction. Normal and200% small-viewport cases now pass: copy/edit/toggle,
revert and Back/reopen preserve original saved values and stored bytes. Three
LF16 full-editor recovery/failure/retry cases also pass:5 total,0fail/skip. Their
generic reveal helper lost the lazy Save row after large-text error layout;
the test now settles and exposes the actual form bottom with a bounded extent
recheck and explicit hit-test requirement. Failed-save and stored-data assertions
were retained. Removed a redundant test teardown already owned by mount.
Focused analysis has0errors/warnings,9 unrelated pre-existing style infos.

OPPO hot reload3276ms; copy saved Store address displayed Unsaved changes and
Evaluation Store lane. Screenshot lf19-unsaved-pickup-20261016.png inspected.
Back/reopen without Save returned Saved on this device and Evaluation pickup
lane/Pune/411001. No commerce/provider/Stock action or APK. Architect review
confirmed that the existing persisted-state flag, not equality alone, must be
retained; current implementation does so. Morning acceptance remains pending.
