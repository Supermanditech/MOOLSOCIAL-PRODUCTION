# REG-20260817-2734: C34L registry append context retype mismatch

## Truthful event

The first patch intended to append REG2733 to the regression registry was
atomically rejected because its large context retyped the existing REG2732
mistake sentence differently from the current file. The patch applied no
registry mutation.

No candidate state, source seal, cycle, AAB, device, Google Play, credential,
secret, deployment, or external state changed.

## Root cause

The append patch used a manually retyped complete prior entry instead of the
smallest exact current tail anchor.

## Prevention

- Read the exact current registry tail immediately before the append.
- Anchor only on the final unchanged evidence line and closing braces.
- Append both pending entries in one bounded tail replacement, then parse the
  complete registry and verify the exact final ID, count, and SHA-256.

## Candidate consequence

C34L remains selection-only at zero release actions. The rejected patch
changed no state or qualification evidence.
