# LF-15 — Store settings truthfulness follow-up

Founder accepted Batch14 c1c41dfe and requested continuation under the mapped
two-way MVP frontend goal and standing narrow-fix direction. One application
writer, current feature tree/base, no redesign or service implementation.

MVP-required supported correction: attention screen currently says customers
cannot place orders or can see a reopening time solely from a session-applied
Store preference. No authoritative settings readback or public acknowledgement
exists. Display the saved local intention and pending public confirmation, not a
claim about actual customer eligibility or visibility. Preserve values, actions,
Back route and layouts; no setting or business record is changed by reading it.

Demonstrate both paused-with-time and off-without-time cases in the existing
widget suite, normal and large text. Verify observed text and retained settings,
Store identity, orders/invoices/Stock; run affected attention/settings regressions.
Hot-reload and passively inspect OPPO, then stop for founder review. No native
setting save, provider query, order/payment/Stock action or runtime data injection.

Durable Store settings/readback and agreed revision/conflict contract remain
unimplemented, not fulfilled by this correction. No local persistence substitute,
new API/interface, server acknowledgement, delivery eligibility, operator screen,
backend, APK/build/install, publication/push, policy/registry expansion or another
tree. This follow-up does not close the full two-way frontend or go-live scope.

Scope includes the shared status-control accessibility label: it also claimed a
public storefront from local preference. Compact Open/Paused/Off visuals stay
unchanged; semantics must state selected preferences and unconfirmed public
ordering/visibility. Existing exact semantics expectations are updated to this
corrected contract, not removed.

Implementation observations: initial four attention tests reproduced old wording;
after the attention fix all four passed. Additional semantics assertions then
reproduced the unqualified public-storefront label in all four cases. The first
corrected-label test run exposed a test-only SemanticsHandle cleanup error:
addTearDown runs too late for the widget end-of-test handle check. Use the existing
try/finally disposal pattern before returning; retain all substantive assertions.
This is not an application regression or a passed test. Task-authority patch
context and an out-of-order metadata patch previously failed without changes;
exact reads/ordered hunks fixed those editing failures. No registry/policy bytes
changed and no failed run is reclassified as passing.

## Implemented / verified checkpoint — 16 October 2026

Only dashboard presentation copy changed: attention titles describe pause/off
preference; timed message says Requested reopening, not automatic reopening or
customer visibility. Both messages mark public ordering unconfirmed. Header
semantics state selected preferences/unconfirmed public ordering and visibility.
Existing read-only status popup replaces the obsolete profile-change hint with
the same session-only/unconfirmed disclosure; no new navigation or control.

Four new widget cases at320x740 and100%/200% text verify timed/untimed copy,
header semantics, popup disclosure and Back, preserving Store identity, local
settings/timestamp, Stock products, orders and invoices. The four tests failed
before the relevant attention/semantic corrections. Popup missing-disclosure
failure was independently read in expanded output before its correction.
Final four pass. Updated existing12 S09 controls/semantics/layout/Back cases pass
after the final caption, covering Open/Paused/Off, Public/Private,412px and320px.
Earlier affected settings/publication22 and truthful-attention2 cases also passed;
these unchanged behavioural assertions were not removed or weakened. Total40
distinct selected cases passed across this bounded correction,0 skips. No full
project/provider/restart-persistence qualification is claimed.

Targeted analysis has0 errors/warnings,9 existing curly-brace style infos
(8 dashboard,1 unrelated pre-existing test line); no unrelated formatting changes.
Diff check passes. Architect context-only review supports the wording boundaries;
it grants no service or device acceptance.

OPPO2b3e0f71 remained connected; attach7508 loaded each source correction,
latest reload3192ms. The already-open popup kept its old constructed widget after
reload, so it was closed using Android Back and reopened through its fresh current
status control. Fresh UI then contains the corrected caption. Screenshot
task outputs/lf15-status-20261016.png inspected: all text readable, existing
Open/Public local values retained and no new action. Current native Open case
only; paused/off and large-text cases remain host evidence, not native approval.
No settings apply, refresh/provider query, order/Stock/payment/PDF action, account
change, runtime injection or APK. Existing Cart/payment hold was not operated.
OPPO left on the read-only Store status popup for founder review.

The outstanding six mapped areas and all earlier provider/frontend obligations
remain open. In particular this is NOT durable settings persistence, confirmed
public availability, complete frontend/MVP, new baseline publication or APK parity.
Founder approval of this slice is pending before the next implementation slice.
