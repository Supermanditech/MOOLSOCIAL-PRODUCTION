# LF-23 — Retailer/Grocery Store preparation and fulfilment preferences

MVP-supporting enter-once outcome: recover the two existing private owner inputs
Preparation (extra preparation minutes, not a countdown) and Fulfilment preference
without re-entry after restart. Demonstrate current new-session loss first.
Reuse Settings, the same private Store-preference record and scoped loader/writer;
no new route, source of authority, service or recovery framework.

Read exact versions1/2 unchanged and without claiming absent readiness fields
were saved. Explicit version3 saves add a separately typed readinessPreferences
sibling; preserve five trading and three product defaults from either editor.
Cache private groups by account/Store. Late reads cannot overwrite newer inputs;
scope/ABA/write/failure guards remain. The global Apply action passes its two
draft inputs to the existing private writer, but does not apply them to session
values or change Store status/visibility until confirmed device save. Failure
keeps the form and retry. Product-controls saves retain accepted readiness inputs,
never another editor's draft. No old-writer/downgrade qualification is claimed.

Preserve existing units, default0/Delivery and pickup and supported custom stored
mode labels. These are private planning preferences, not public open/orderable
state, collection eligibility, serviceability, slots, Quick promises, dispatch or
provider verification. Do not persist Open/Paused/Off, public visibility,
accepting-orders result, pause/reopensAt or operational transactions here. Do not
silently couple pickup-address preference to a fulfilment choice.

Focused model/migration/owner/failure/interleaving tests; existing settings and
new-product paths retain values. Actual OPPO evaluation-Store preference save,
source restart and recovery only; no Stock/order/invoice/payment, native provider,
APK/install, backend, Cursor/other tree or push. Founder overnight authority
allows implementation while morning acceptance stays pending. Keep all original
product/offer/quote/order/after-sales/feedback/analytics dependencies explicit.

## Implemented — morning founder review pending

Failing-before host case reproduced15 extra minutes returning to0 after a fresh
session. The same private key now reads exactv1/v2 unchanged and writes explicit
v3 with readinessPreferences, while preserving five trading/three product inputs.
Legacy absence is not falsely shown as readiness saved. All groups are validated
before restoration; malformedv3 cannot partially replace defaults. Existing
custom mode labels and valid45-minute values remain private input, not provider
capability. Account cache, newer-input and scope/write guards are retained.

Global Apply passes its readiness draft explicitly; the two session values change
only after confirmed private storage. Failed writes keep readiness and requested
pause/visibility unapplied, with form input retained. Retry preserves both other
groups. Product-controls/hour saves capture accepted readiness, never local form
drafts. Copy distinguishes unsaved preferences, saving and actual device recovery;
legacy records still describe only their saved hours/alerts. No approved layout,
Store-public state, paused clock or operational transaction was serialized.

152 distinct selected host cases pass:121 settings/model (15 LF23),23 publication/
settings widgets,6 LF21 new-entry/default/CSV consumers and2 extended LF20 global
Apply normal/200% cases. The two extended cases also preserve pause/visibility,
failed-save drafts, all groups, Stock and empty invoice history. Focused analysis:
0errors/warnings,8 existing dashboard brace infos and1 existing test brace info.
No whole-project/APK or provider qualification is claimed.

Candidate test errors are retained, not counted as passes: initial test assumed
a non-Off default instead of capturing the actual baseline; another registered
and manually performed disposal; lazy Settings controls required resetting the
known vertical list before inspecting Sound after dropdown scrolling. The corrected
full-file and normal/200% runs pass. No reference/golden was rewritten.

Actual OPPO evaluation Store: existing legacyv2 showed only Hours and alerts
saved; chose15 min/Pickup only, observed Unsaved Store preferences, tapped Apply
once. Reopening showed the broader device-saved caption and both choices, with
21:30/05:15/Unlimited/sound off/vibration off retained. Source restart4011ms,
then settled same TEST Store -> Settings, restored15/Pickup only and the caption.
Viewed task screenshots lf23-readiness-saved-20261016.png and
lf23-readiness-restored-20261016.png. Expanded Product controls without editing:
low-stock13 and device-saved defaults remained. No native product/order/invoice/
payment save, provider action, injected records, APK or install.

Entry timing limit: first Workspace tap after restart preceded completed feed/
saved-review-Store recovery; personal Profile had no Operations target and the
fresh-label guard refused it. After settled entry, the correct TEST Store and
Stock29550/18low/24available/6unavailable were observed. This is registered under
existing LF01 for a focused entry-timing assessment; not clean one-tap acceptance,
not proof of lost auth/data, and not silently fixed within LF23. Fresh UI dump/
scroll guards rejected transient or nonunique surfaces before any follow-up tap/
swipe; only the observed vertical Store ScrollView was later used.

Full mapped/frontend provider requirements and morning acceptance remain open.
Readiness synchronization, Quick/Scheduled/serviceability and order admission
are not implemented by local preference recovery. No downgrade guarantee or
founder approval is inferred from these host/source-attached checks.

## Restart-entry follow-up assessment — LF01 cross-reference

Reuse the admitted layout test and its approved-Store feed fixture to exercise
one ordinary Workspace rail tap before the feed completes, at normal and200%
text. Assert loading rather than onboarding, one feed call despite a repeated
tap, automatic entry to the exact approved Store, and no late redirect after
the user returns to Earn. Also assess an already-running feed. This is focused
verification of the restart-entry observation above, not permission to change
onboarding/router/session behaviour under a readiness-preference outcome. If a
defect reproduces, record it under LF01 and select only the bounded correction;
passing tests do not explain the original native observation or prove cold APK
entry. No app edits, native actions or new acceptance are implied by this plan.

First assessment run: four existing R669 neighbours passed; all six new cases
stopped at the second tap because the test used an unfiltered rail-key finder
while the pushed page and retained Earn page both contained that key. The first
tap and loading assertions had succeeded. This is a test-target ambiguity, not
an application navigation defect or successful new case. Retry must assert and
tap the single hit-testable rail target, preserving all original outcome checks.
Focused analysis had no errors/warnings and one existing brace-style info.

Corrected focused run: all10 cases passed (six delayed-entry cases and four
existing R669 approved/retry neighbours). Normal/200% early taps show loading,
then automatically open approved-store/Approved Kirana after exactly one feed;
already-running feed also succeeds. Back before completion leaves Earn visible,
with no late redirect; a later deliberate tap opens the same recovered Store.
The captured initial settlement balance is unchanged. No navigation/application
fix is justified by these outcomes. The original OPPO observation is still not
explained: these use an approved-feed host fixture, not the native saved-review-
selection path, payment/data recovery, cold launch or a newly installed APK.
This follow-up changes tests and their existing evidence only, not Store UI.
