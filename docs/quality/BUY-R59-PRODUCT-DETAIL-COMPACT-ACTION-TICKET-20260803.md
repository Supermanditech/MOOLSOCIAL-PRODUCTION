# Buy R59.1 product-detail compact action ticket

State: **FIX8 FOUNDER APPROVED/PROTECTED AFTER TECHNICAL/OPPO QUALIFICATION; PRIOR REJECTIONS IMMUTABLE**

Candidate: `BUY-R59-PRODUCT-DETAIL-COMPACT-ACTION-FIX1`

Founder finding: the navy product-detail `+`/quantity control spans almost the
entire width after opening a Shop, Wholesale or Medicine product, making a
single action visually dominant and consuming decision space.

Bounded outcome: retain the persistent safe action owner but reduce the navy
visual body to a trailing 44 px-target compact Add control; use a compact
three-owner stepper at real non-zero quantity and a truthful bounded
`Use prescription` control for blocked medicine. Preserve all arithmetic,
prescription, MOQ, route, Back, scroll, continuation and bottom-nav owners.

Registration, motion disposition, risks, protected scope and starting source:
`artifacts/quality/buy-product-detail-compact-action-r59-1-20260803-131`.

R58.6.1 is sealed separately. R58.7 remains queued until R59.1 is qualified.

## FIX1 rejection

FIX1 reduced the normal navy Add body to 56 × 44, but its icon-only `+` became
ambiguous when the product title scrolled offscreen. The founder rejected that
UX on the connected OPPO. Exact rejected source/APK/install and evidence remain
immutable in
`artifacts/quality/buy-product-detail-compact-action-r59-1-20260803-131`.

FIX2 must retain compact geometry while keeping the current product name/pack
visibly attached to the dock and using a small explicit `+ Add` pill. Quantity
and prescription states must retain the same product identity.

## FIX2 registered before runtime write

Candidate `BUY-R59-PRODUCT-DETAIL-COMPACT-ACTION-FIX2`, profile `1.0.0-r59.2`
(`2026080321`), starts from the exact rejected FIX1 2,423-file source manifest
SHA-256 `1B96473423D6B0CEA3A3E4B80110260DBEF7764D70BCDA267E8560D1DE2B8FA0`.
It permanently pairs compact actions with the visible current product title and
truthful pack/quantity/prescription context. The normal action is explicit
`+ Add`; FIX1 evidence remains unchanged.

Contract and evidence root:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix2-20260803-132`.

## FIX2 device rejection; FIX3 required

FIX2 restored visible product identity and explicit `+ Add`, but its OPPO
accessibility tree exposed the product-specific Button node as
`clickable="false"`. The custom label excluded child semantics without carrying
the real tap action. Exact rejection:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix2-20260803-132/57-fix2-device-accessibility-rejection.md`.

FIX3 must preserve all FIX2 visual/geometry behavior and restore one
product-specific accessibility tap owner. It requires a new profile/APK/source
identity and complete qualification; FIX2 evidence remains immutable.

## FIX3 registered before runtime write

`BUY-R59-PRODUCT-DETAIL-COMPACT-ACTION-FIX3`, profile `1.0.0-r59.3`
(`2026080322`), starts from the exact FIX2 2,423-file source SHA-256
`84F6E2336C1C41844C52887AD16421D5DE0337124E494A6CCCD98B7CE183792F`.
Before runtime write, the founder clarified that adjacent product context still
looks separate and can misguide the customer. FIX3 therefore requires one
bounded navy owner that visibly contains `+`, `Add`, and the current product
title, as well as carrying the existing callback on its product-specific
Semantics owner. Contract and evidence root:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix3-20260803-133`.

## FIX3 founder visual rejection; FIX4 required

FIX3 restored a real product-specific accessibility tap owner and passed its
technical/device subchecks, but the founder rejected the visual ownership on
the connected OPPO. Its persistent bottom product-action strip remains beside
Cart and therefore reads as a Cart-area/separate action. Repeating the product
name inside the 164 x 44 navy owner did not make it feel directly attached to
the selected product.

Exact rejected FIX3 source is 2,423 files / SHA-256
`67221A92060B3445216DA38C56734142F855FBEDD1EA371B6EFA716D62BC4DE7`.
Exact rejected APK and pulled install are 134,115,809 bytes / SHA-256
`4C82C1FB7194B3D8EA3385E897A095C890E78685398F6E252E6541A6303D4939`.
Rejection:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix3-20260803-133/87-founder-visual-rejection.md`.

FIX4 must remove the persistent product-action strip and place the compact
`+ Add`, real quantity or truthful prescription owner inside the selected
product's title/price content block. It must scroll with that product, must not
repeat the normal product name inside the button and must leave Cart visually
and semantically separate. It requires a unique source/APK/evidence identity
and complete host and OPPO qualification.

## FIX4 registered before runtime write

`BUY-R59-PRODUCT-DETAIL-COMPACT-ACTION-FIX4`, planned profile `1.0.0-r59.4`
(`2026080323`), starts from the exact rejected FIX3 2,423-file source SHA-256
`67221A92060B3445216DA38C56734142F855FBEDD1EA371B6EFA716D62BC4DE7`.
Its sole runtime scope is moving the established Add/real quantity/prescription
owner into the selected product's scrolling price block and removing the
separate sticky product strip/repeated title. Contract and evidence root:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix4-20260803-134`.

## FIX4 OPPO performance rejection; FIX5 required

FIX4 passed the founder-requested visual ownership, 88 x 44 visible `+ Add`,
product-specific clickable semantics, Shop/Wholesale/Medicine variants,
quantity/Cart separation, Back, lifecycle, process recreation and visible
reduced-motion checks on the OPPO. The founder's approval was conditional on
OPPO qualification and is not yet satisfied because its valid ten-cycle
SurfaceFlinger replay failed the registered threshold: p95 33.414 ms, p99
50.348 ms, max 50.543 ms and two intervals above 50 ms. Exact rejection:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix4-20260803-134/150-fix4-oppo-performance-rejection.md`.

FIX5 is a nonvisual geometry-stability correction. It must preserve the exact
approved product-owned panel and visible 88 x 44 `+ Add` while reserving one
stable 148 x 44 action slot for both Add and the real quantity stepper. This
prevents price/action row relayout during finite state replacement. It requires
a new exact source, profile, APK, install and complete qualification; no FIX4
evidence may be replaced.

## FIX5 registered before runtime write

`BUY-R59-PRODUCT-DETAIL-COMPACT-ACTION-FIX5`, planned profile `1.0.0-r59.5`
(`2026080324`), starts from the exact rejected FIX4 2,423-file source SHA-256
`53B6E805B7F73E479425BC592E471C96EFE07C705DEBD692C958C0CB714BD471`.
Its sole runtime scope is stabilizing the invisible action-layout slot while
leaving the visible Add, quantity, prescription, semantics and product-owned
panel unchanged. Contract and evidence root:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix5-20260803-135`.

## FIX5 OPPO performance rejection; FIX6 required

FIX5 held the action slot stable and its settled captures were byte-identical
to FIX4. It passed host, exact install and all affected OPPO journey,
accessibility, Back/lifecycle/process and visible reduced-motion checks. Its
performance replay improved p95 from 33.414 ms to 33.241 ms and reduced
intervals above 50 ms from two to one, but max 50.163 ms still failed the
unchanged no-over-50-ms rule. Exact rejection:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix5-20260803-135/133-fix5-oppo-performance-rejection.md`.

FIX6 preserves the stable slot and exact settled design but removes the
outgoing full-control subtree from the transition layout. The new real state
receives one lightweight finite incoming opacity acknowledgement; reduced
motion remains immediate/static. It requires a new source/profile/APK/install
and the complete qualification machine.

## FIX6 registered before runtime write

`BUY-R59-PRODUCT-DETAIL-COMPACT-ACTION-FIX6`, planned profile `1.0.0-r59.6`
(`2026080325`), starts from the exact rejected FIX5 2,423-file source SHA-256
`1EC322D091199C9E5B2CE719BCEB80B849F81F982DBBB3FAA8733977EE73315A`.
Contract and evidence root:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix6-20260803-136`.

## FIX6 host qualification and device reconnect status

FIX6 preserves the founder-reviewed settled visual byte-for-byte: the selected
product's price and compact action remain one directly owned panel; normal
state shows an 88 x 44 visible `+ Add` without repeating the product name;
quantity and truthful prescription states remain bounded inside the stable
148 x 44 slot. Only the incoming real state receives the finite opacity
acknowledgement; the outgoing subtree is removed from layout/paint immediately,
and reduced motion resolves static.

Host qualification passed: focused 4/4, related 81/81, responsive/reduced
captures 3/3, formatting and analysis, two complete Buy regressions at 316
active passes plus 15 established skips each, every positive release gate,
HTML customer-copy 9/9 and exact fail-closed protected-boundary classification.
The final and post-build 2,423-file source is SHA-256
`8CB4F2E00922E341AD6A3D4047D83ADF9EEE1FCC42BD6C329B321841D41C85F5`.

The mandatory wrapper produced profile `1.0.0-r59.6` (`2026080325`),
134,115,809 bytes, SHA-256
`F12E3E0174940CD1AFE948768C494F876CA3DF7994AF4217E716A4EC56E3100B`.
Signature and badging passed. The one-build authorization is consumed.

OPPO install/replay is pending because neither ADB nor Windows currently
enumerates the previously connected CPH2375 `2b3e0f71`, including after a
local ADB bridge restart, present-device scan and four bounded reconnect
observations. Exact blocker evidence:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix6-20260803-136/53-device-reconnect-blocker.md`.

Founder disposition is approved subject to OPPO testing, not final approval.
Do not rebuild, change source, start R58.7 or protect FIX6. Resume from install
of this exact checksum only when the physical OPPO reconnects, then require the
complete journey, semantics, Back, lifecycle/process, visible reduced-motion,
failure and unchanged performance gates.

## FIX6 OPPO rejection; conditional approval not satisfied

The exact wrapper APK was installed on OPPO CPH2375 and pulled back with
checksum equality. Direct product ownership across Shop, Wholesale and
Medicine, 88 x 44 logical Add geometry, stable quantity replacement, Cart
separation, Back, hot resume, keyboard/semantics, process recreation, visible
reduced motion and final 1/1/1 system restoration passed. Runtime scan found no
fatal, ANR, Flutter exception or crash exit, and post-device source remained
exact.

The unchanged SurfaceFlinger gate failed: p50 16.701 ms, p90 32.947 ms, p95
33.368 ms, p99 49.367 ms, max 50.415 ms, six intervals above 33.333 ms and one
above 50 ms. Required limits are p95 at most 33.333 ms and zero intervals above
50 or 100 ms.

The replay also failed exact cycle integrity. Setup proved an empty Cart and
the final target-detail capture showed Paracetamol at zero with only the ₹37
Fresh tomatoes background item. Before cleanup, Cart contained four items /
₹121; after removing Fresh tomatoes it exposed three Paracetamol units / ₹84.
Those target units appeared after the final zero capture. Root cause is not yet
established. All three were removed through the real Cart UI, returning to the
empty Medicine root.

Founder approval was explicitly subject to OPPO testing and therefore is not
satisfied. FIX6 is not approved or protected. Exact rejection:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix6-20260803-136/135-fix6-oppo-performance-and-cycle-rejection.md`.

Do not rerun or rebuild FIX6 and do not start R58.7 on top of it. Any R59
successor requires a separate pre-runtime registration and must root-cause the
residual/delayed quantity state before repeating the full qualification machine.

## Founder remediation directive; FIX7 registered

The founder directed that a failing regression must be investigated and solved
through a production-grade root-cause loop rather than treated as a terminal
stop. The failed FIX6 evidence and disposition remain immutable; no failed
sample may be replaced by a rerun.

Successor `BUY-R59-PRODUCT-DETAIL-COMPACT-ACTION-FIX7`, planned profile
`1.0.0-r59.7` (`2026080401`), is registered before runtime write from the exact
FIX6 2,423-file source SHA-256
`8CB4F2E00922E341AD6A3D4047D83ADF9EEE1FCC42BD6C329B321841D41C85F5`.

Its first bounded hypothesis is that the performance harness selected x=592,
the centre of the normal Add owner and simultaneously the left boundary of the
replacement `Add one` owner. A stale/reverse-missed fixed-coordinate event can
therefore become an increment. This is only a hypothesis until a state- and
owner-instrumented replay proves it. Runtime code may change only if evidence
demonstrates an app/session defect; otherwise the qualification harness is the
proper correction.

FIX7 must preserve the founder-reviewed settled design and all approved owners,
prove every `0 -> 1 -> 0` cycle and Cart total before the next event, retain
the unchanged performance thresholds and complete the entire host/machine/OPPO
qualification sequence.

Registration and contracts:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix7-20260804-137`.

## FIX7 performance rejection; FIX8 registered

FIX7 proved and corrected the predecessor's event-owner defect. On the exact
checksum-matched OPPO install, a state-owned Add point completed ten exact
`0 -> 1 -> 0` cycles with exact Cart totals, a three-second drain, zero target
residual and final empty Cart. Direct Shop/Wholesale/Medicine ownership, Back,
Rx/lifecycle/process, accessibility, visible reduced motion and final `1/1/1`
restoration passed. Post-device source remained 2,423 files / SHA-256
`041257E7B8C171C25AA8DD8A4107BBF2D0B2F02A2B697367B76BBB74E517D857`.

The unchanged SurfaceFlinger gate still failed: p95 33.413 ms, max 50.284 ms,
eight intervals above 33.333 ms and two above 50 ms. Shader/compile matches
were zero. FIX7 is rejected and immutable; exact rejection:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix7-20260804-137/129-fix7-oppo-performance-rejection.md`.

Successor `BUY-R59-PRODUCT-DETAIL-COMPACT-ACTION-FIX8`, planned profile
`1.0.0-r59.8` (`2026080402`), is registered before runtime write from that
exact source. Geometry stability, outgoing-tree removal and event integrity are
already proven, leaving the compact action's incoming opacity compositing layer
as the bounded runtime hypothesis. FIX8 may replace only that fade with one
finite transform-only fractional slide whose hit testing remains settled;
reduced motion stays static and every other owner/visual remains protected.
Registration:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix8-20260804-138`.

## FIX8 technically and device qualified

FIX8 replaced only the remaining compact-action incoming opacity layer with a
finite transform-only 0.025-to-zero horizontal arrival. Hit testing stays at
the settled owner, the outgoing child is still removed immediately and reduced
motion stays static. All settled responsive captures are byte-identical to
FIX7.

Host qualification passed: focused 5/5, related 82/82, responsive 3/3,
format/analysis, two full Buy regressions at 317 active passes plus 15
established skips each, all positive/HTML gates and exact protected fail-closed
classification. Final source is 2,423 files / SHA-256
`A68B20102D9922BA25E013EF8F8F6E0EDF7F71D87FB7E3EB3EEE257830C63DFA`.

The wrapper APK/profile `1.0.0-r59.8` (`2026080402`) is 134,115,809 bytes,
SHA-256 `0B6FC4D4500B85B0B744C283902C0BEFF22DD98ADEA4FC7D2CB64C0202DC0A91`.
The OPPO install/pull matched exactly. Direct Shop/Wholesale/Medicine, Back,
Rx semantics/lifecycle/process recreation, visible reduced motion and final
`1/1/1`, ten exact cycles with zero residual, cleanup and failure scan passed.

Performance passed: p95 33.105 ms, max 33.869 ms and zero intervals above 50
or 100 ms. The controlled change from FIX7 confirms the incoming opacity
compositing layer as the remaining performance root cause; the transform-only
arrival is the production correction.

State is technically/device qualified. Founder observation points remain before
any protected-baseline update:
`artifacts/quality/buy-product-detail-compact-action-r59-1-fix8-20260804-138/130-founder-oppo-observation-points.md`.
