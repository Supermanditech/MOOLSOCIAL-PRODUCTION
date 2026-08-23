# C24F protected Social exact-delta correction — 2026-08-09

The initial REG722 cause was too broad. Reading the Social gate confirms that
`journey_router.dart` is not in its 178-owner inventory, so the Bus route did
not change this protected tree. Exact comparison with the retained C24B3/C24D
manifest proves one changed owner only:

- `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart`
- predecessor portable SHA-256: `e3e0ca42908b6bc7c3dafa2c25043e582c0ec944ef4e1066d9a975e34ad8456b`
- current portable SHA-256: `10cdf9d8fa5e458f0f9371003a8e4e71fa1a45423f25370ffc6cccf638f9db09`

That delta changes connected main-action switching from route replacement to
history-preserving navigation so system Back restores the visible Social
source. The predecessor manifest contains 178 valid entries with no malformed
lines. The successor remains blocked until the complete protected
Social/YouTube suite qualifies.
