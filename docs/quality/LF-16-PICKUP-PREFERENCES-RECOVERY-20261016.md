# LF-16 — Device recovery of the owner's pickup preferences

Founder accepted3157e109 and requested remaining settings frontend under the
mapped MVP goal. First bounded recovery slice: existing Delivery & pickup form's
city, address/area, PIN and pickup preference. These are private owner inputs,
not approved location, serviceability or collection capability.

Reuse SecureWorkPendingProofStore with a distinct encrypted account+Store key,
strict version/field validation and existing serialized scoped-write mechanism.
Existing WorkSession/form owners load before editor initialization, preserve
newer session values and failed-save inputs, reject late account/Store/ABA results,
and show device save/loading/error status truthfully. Disable duplicate save;
read must wait for pending same-key writes. Do not replay WorkOperationalSnapshot,
restore orders/Stock/finance, delete corrupt evidence or infer server confirmation.

Failing-before actual supported save/new-session loss where practical; focused
storage/scope/corrupt/unknown-schema/read-error/write-error/concurrency tests and
normal/large-text existing settings regressions. Actual evaluation form save and
MoolSocial restart on OPPO, then founder review before another slice. No runtime
seed, commerce/payment/order/Stock/provider query, backend, native dependency,
APK/build/install, push or another tree. Existing approved layout retained.

Other Store defaults, authoritative settings readback/version/conflict rules,
cross-device sync, public eligibility and all other mapped dependencies remain
unfinished. Device recovery is not a replacement or whole-settings completion.

Founder subsequently authorized verified defects within the approved architecture
and supported pending tickets while sleeping, with review by morning. The earlier
per-slice wait above is superseded for this continuation only. Preserve tested
checkpoints for morning review, never mark founder acceptance automatically.
The original frontend/service/native boundaries remain unchanged.

Development checks: existing save/new-session test reproduced missing city before
implementation.17 initial recovery/scope/error/serialization cases pass. An added
queued-failure→newer-success test then caught stale error text in this candidate;
clear error on the latest confirmed write, not weaken its assertion. This is a
candidate regression, not an inherited frontend defect. The first session patch
was rejected atomically for an omitted context comment; exact source reread and
ordered hunks corrected it, no partial source mutation. Some readback searches
used the app cwd with root-relative paths; corrected to root-only readback calls.
No application state was inferred from those path errors. Keep all test failures
and limitations explicit; do not expand registry/policy work.

## Implemented checkpoint — 16 October 2026

Four-field recovery implemented in existing secure store/session/form owners.
The scoped raw platform-write queue now remains pending until actual platform
completion, even when its caller times out; a late old write cannot overtake a
newer one. A timeout remains unconfirmed, never described as cancellation. No
new native dependency, API or operational-data restore was introduced.

Final selected host results:18 LF16 storage/model/button cases plus22 existing
settings/form cases passed in the40-case run;12 existing LF04 secure-offer
consumer cases passed; all3 full pickup editor cases passed, including320-wide
200% text and unreadable-storage retry. No failures/skips in these final runs.
Full-editor candidate runs initially failed because error text moved the Save
target, then because the lazily disposed offscreen caption/Save was used as a
finder. Re-reveal Save before retry, then scroll the actual keyed form's own
Scrollable to its header before asserting the saved caption. Assertions on
saved data, retained input and visible status were preserved. These are test
traversal failures, not app regressions or successful runs. Closing analysis:
0 errors/warnings;9 pre-existing style infos outside this correction.

Actual OPPO2b3e0f71 evaluation Store TEST Store · product entry: existing form
was empty with pickup enabled. Entered Pune /411001 /Evaluation pickup lane
through normal UI, kept pickup enabled, pressed Save on this device and observed
the confirmed device-only caption. No runtime record injection. Detached debug
session, force-stopped only com.moolsocial.app.runtime, relaunched the existing
installedr67.3, reattached this feature tree and hot-restarted current Dart
source3981ms. Reopened the same Store/settings form through normal navigation:
all four values restored, confirmed caption visible. Images in the task outputs:
lf16-pickup-before-20261016.png, lf16-pickup-saved-20261016.png and
lf16-pickup-restored-20261016.png; each capture was visually inspected or its
saved/restored state checked from fresh UI. The restored capture was inspected.

After restart, Buy showed retained1soap Cart₹164 with existing controls held;
Store showed cost₹29550,24 available/6 unavailable and18 low-stock products.
This is process-stop plus reattached-source hot-restart recovery evidence, NOT
cold-launch qualification of a new APK. No new APK/build/install, commerce write,
query/payment/order/Stock/PDF action or push. Actual signed-in multi-account,
same-account authentication-epoch replacement and authoritative server freshness
remain unverified; host scoped/observed-account tests are not those live results.

Founder morning review pending. This checkpoint does not complete other settings,
authoritative readback/revision/conflict, public synchronization/eligibility or
the remaining mapped frontend goal. Continue authorized attention-screen defects
without an overnight founder pause, preserving this checkpoint and all data.
