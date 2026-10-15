# LF-20 — Retailer/Grocery Store trading preference recovery

MVP-required owner outcome: reopening the existing Store settings restores the
saved opening/closing times, order-planning limit, sound and vibration without
re-entering them. First reproduce the loss in a fresh host session. Reuse the
existing settings form, validations, scoped recovery state and encrypted writer.
Five explicit private inputs only, separately keyed from LF18's accepted record;
preserve its schema, pickup records, offers, saved Stock, Cart and immutable bills.

Keep overnight hours and 0=Unlimited semantics. Restored hours are owner inputs,
not actual ordering availability, a schedule executor, public publication or
order-admission authority. Do not restore Open/Paused/Off, visibility, reopening
commands or provider decisions. Missing record retains existing session defaults;
corrupt/unreadable record is not absence and must not be overwritten blindly.
Before editor initialization load/join scoped recovery; reject changed Store/
account/ABA or disposed callbacks. Do not block unrelated Store actions. Keep
entries on read/write failure, allow retry and identify device-save versus public
synchronization. Only confirmed writes justify a saved claim.

Host tests: fresh-session recovery, absent/corrupt records, overnight times,
zero-limit, duplicate/coalesced access, delayed read/write and scope/newer-input
guards; relevant existing settings/counter/publication consumers. Native OPPO
real settings save and source restart/reopen, with no invoice/payment/order/Stock
transaction. Founder overnight correction authority applies; morning review is
pending. No backend/API/provider query, APK/native dependency, Cursor/other tree,
push, redesign, registry/policy expansion or new recovery framework.

## Implemented local checkpoint — morning acceptance pending

Fresh-session host regression reproduced opening21:30 returning to8:00AM.
Separate five-field account+Store recovery reuses the existing raw encrypted
write queue and _OwnerInputRecovery; LF18's20-field schema1 and all other saved
purposes remain unchanged. Strict typed records distinguish absent from corrupt.
Dependent settings initialization joins the scoped load before capturing drafts,
with duplicate-opening and changed owner/context/view guards; no-storage callers
keep immediate behavior. Save awaits private write confirmation before leaving.
Failed private writes keep form entries and do not apply requested pause or
visibility changes; confirmed retry applies them through existing guards. Public
visibility refusal is checked before effects. Local publication hours and trading
inputs stay consistent in either loader order; missing records do not create
explicit public hours from defaults. No public synchronization is implemented.

Final89 settings/model checks passed (23 LF20), plus23 neighbouring publication/
settings-widget checks and14 full-editor/dispatch checks. New form cases cover
normal/200% small view, pending and failed saves, retained draft and mixed
preference changes, retry, confirmation and reopen. Focused analysis:0errors/
warnings;9 unchanged unrelated style infos remain. Earlier dispatch expectations
were stale against LF15/LF19's truthful preference wording; exact copy assertions
were updated while preserving dispatch counts, saved data and scope checks. An
earlier109-case run failed the raw-channel timeout fixture after a global plugin
mock ran first; registration order was corrected, not production timeout logic.
The final bounded outputs were read through terminal success; the failed run is
not counted as passed. Architect context review found no remaining bounded code
blocker after both loader orders and mixed-save failure protection were tested.

Actual OPPO evaluation Store used the existing time picker:21:30 opening,05:15
closing, Unlimited, sound off and vibration off. Apply settings confirmed the
device save. Source hot restart4162ms and normal navigation back to the existing
settings restored all five, including checked/selected accessibility values and
the saved caption. Before/saved/restored screenshots in task outputs:
lf20-hours-before-save-20261016.png, lf20-hours-saved-20261016.png and
lf20-hours-restored-20261016.png, visually inspected. One post-restart guarded tap
refused a transient unavailable target without tapping; a fresh capture preceded
the retry. Cart1item₹164 and displayed Stock29550/24available/6unavailable/18low
were retained. No commerce mutation, injected runtime data, provider query or APK.

This is source-attached preference recovery, not cold-launch new-APK validation,
cross-device sync, operating-hour automation, sound/vibration delivery or actual
order-limit enforcement. No native failure injection/account-switch qualification.
Other status/product defaults/private exceptions, connected product/channel/
campaign/policy/checkout/order/recovery/feedback/analytics obligations remain open.
Founder morning acceptance remains pending; no push or ticket-close claim.
