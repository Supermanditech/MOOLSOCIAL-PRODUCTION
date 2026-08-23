# UAW C10C exact vertical Buy page scroll owner regression

- Registry: `REG-20260807-201-BUY-EXACT-PAGE-SCROLL-FINDER-ALSO-MATCHED-NESTED-RAILS`
- State: resolved; exact vertical-owner gate active
- Trigger: the first REG-199 repair changed `No element` into `Too many elements` for a product journey.
- Root cause: the exact product owner contains its vertical page plus legitimate horizontal gallery and recommendation rails.
- Durable rule: an exact journey scroll owner is identified by keyed page containment and vertical axis together.
- Proof: the focused product journey and full 69-test Buy screen suite pass, followed by the 82-test combined C10C batch.
