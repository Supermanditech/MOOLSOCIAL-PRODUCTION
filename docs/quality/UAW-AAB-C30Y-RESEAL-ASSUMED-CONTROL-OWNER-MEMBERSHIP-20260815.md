# UAW AAB C30Y reseal assumed control-owner membership

Date: 2026-08-15
Regression: `REG-20260815-2199-AAB-C30Y-RESEAL-ASSUMED-CONTROL-OWNER-MEMBERSHIP`
Status: registered before retry

## Finding

The first post-FIX5 reseal preflight proved the immutable post-FIX4 manifest
still had exactly 1,132 rows and SHA-256
`8CE80E747500DCA4AFDB4A00492A24FFF782134290B5018EBE6A35591857CC2F`.
It then assumed `config/codex-development-regression-registry.json` was an
existing member. The exact membership assertion rejected that assumption, and
no provisional manifest was created.

## Prevention

- Start from the exact sealed path list.
- Emit one labeled present-or-absent result for every candidate owner before
  asserting membership.
- Rehash exact existing members and add only explicitly approved new FIX5
  source owners.
- Never infer manifest membership from an owner's release importance.

## Resolution

The corrected audit classified every candidate owner before assertion. The old
manifest had exactly two changed existing members—the authoritative Flutter
runner and existing evidence binder—zero missing owners, and none of the three
approved FIX5 owners. The current provisional post-FIX5 manifest adds exactly
those three owners, contains 1,135 unique ordinally sorted rows, and has
SHA-256 `54645062FBAA0233759B0F3C6F5C1C4C539D1A322DE7E7FA14629ECF3EDCDED4`.

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/source-manifest-c30y-post-fix5-provisional-attempt-01.txt`
