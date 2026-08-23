# Temporary navigation prototype unverified action-signature recurrence

## Observation

The first action-count correction still returned zero because it introduced `eyebrow` as a supposedly stable owner key without verifying the prototype source. The direct action records actually use the ordered keys `id`, `label`, `icon` and `title`.

## Cause

The retry was based on an inferred field name rather than a bounded inspection of the exact JavaScript data owner.

## Permanent prevention

- Inspect one exact, bounded source-owner block before changing a structural assertion.
- Use the source's verified `{ id, label, icon, title }` direct-action record shape for this temporary prototype.
- Keep validator implementation details out of permanent prevention text until the owner has been observed directly.

## Resolution evidence

The next source-contract run must report all eighteen direct-action records from the verified object shape before browser review begins.
