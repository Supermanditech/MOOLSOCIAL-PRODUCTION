# C24C Eat discovery Home completion — 2026-08-09

## Outcome

Order Food and Book Table now use one professional, adaptive, native-Flutter
Eat discovery language. Both start with current location and search, use quiet
white surfaces with one restrained Eat accent, and show truthful rating, time,
distance, starting price and availability before the existing direct outcome.
The horizontal restaurant/promo treatment, large tinted blocking fills,
redundant filler actions and postponed Tiffin exposure are absent.

Order Food exposes compact cuisine filters and vertical restaurant cards that
open the existing menu in one tap. Book Table exposes vertical restaurant
availability, compact people/time/table choices and the existing booking
action. Back, connected MoolSocial navigation, reduced motion, failure/recovery
state and existing order/table domain behavior remain intact.

## Evidence

- OPPO-class renders:
  `apps/mobile/test/ui_v2/eat/candidate_captures/eat-discovery-home-c24c-oppo-360x800.png`
  and
  `apps/mobile/test/ui_v2/eat/candidate_captures/eat-book-table-c24c-oppo-360x800.png`.
- C24C focused discovery tests: 5 passed, 2 retained captures skipped.
- Recombined affected compatibility group: 117 passed, 3 retained captures
  skipped; corrected C16D owner: 2 passed; total applicable tests: 119 passed.
- Eat and Ride vertical slices, universal intents, direct-default routing,
  connected-navigation, R06, Fix1, Fix2 and C10E owners all pass.
- Affected source/test analysis: 16 owners, no issues.
- C24C Eat machine gate: passed for 320/390/430, 1.4 text scale, 44–48px
  targets, truthful metadata, direct actions, absent horizontal rail and hidden
  Tiffin.
- Regression memory: passed with 668 entries; MVP scope, delivery discipline,
  approved UI, brand, interaction and placement gates pass.

REG638–REG668 retain all C24C implementation, visual, routing, lifecycle,
evidence, command and stale-acceptance rejections. The connected-navigation
dependency now also covers cyclic route switching and active Ride lifecycle
guarding.

## Boundary

No APK was built or installed. OPPO r60.22 and checksum identity
`778C9338DAFDEC3693337D54410946C75F9B6B1BB5977D822DF2CF7E38D9D850`
remain preserved.
