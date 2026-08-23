# C25F Journey01 legacy-root routing assumption rejection

- Date: 2026-08-09
- Status: registered before retry

The first Journey01 migration assumed that selecting Social from the main-only menu while inside the retained universal action-choice owner would navigate to Screen04. That owner intentionally handles main-family switching in place, so it remained on `section-social`; the other ten tests passed.

The correction preserves that retained owner: it asserts the in-place Social section, then uses the same main-only launcher to switch to Buy and retains the existing one-tap legacy Chat/exact-return outcome. No runtime change is required.
