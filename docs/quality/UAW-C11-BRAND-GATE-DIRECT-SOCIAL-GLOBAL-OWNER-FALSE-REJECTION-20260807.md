# C11 brand gate direct Social global-owner false rejection

- Regression: `REG-20260807-253-C11-BRAND-GATE-DIRECT-SOCIAL-GLOBAL-OWNER-FALSE-REJECTION`
- Ticket: `UAW-PERSONAL-MVP-CONTEXTUAL-SUBACTION-THUMB-SHELF-FIX1-C11`
- Date: 2026-08-07 IST

## Observation

After the C10E composition gate passed, brand integrity rejected Social because
it still searched the Social source for a direct global-rail call. The
canonical Mool launcher remained present in the unchanged global owner, now
reached through the shared C11 contextual shelf.

## Permanent correction

Brand integrity now proves all three links independently: Social uses the
shared destination-navigation owner, that owner terminates in the global rail,
and the global rail renders `MoolBrand.moolLauncherIcon`. This preserves the
brand invariant without coupling it to an obsolete direct call site.
