# C30T continuous audit: superseded C23/C24 Social Home contracts

Date: 2026-08-13
Evidence log: `apps/mobile/tmp/c30t-continuous-expanded-in-scope-10.log`

The first 10-file continuous expansion produced `51` passes, `1` intentional skip and `5` failures. The failures are confined to four historical files:

- `mool_home_direct_routing_c23e_test.dart`
- `mool_home_motion_accessibility_polish_c23f_test.dart`
- `mool_home_six_family_hub_c23d_test.dart`
- `uaw_personal_mvp_action_wording_wiring_navigation_fix1_test.dart`

Their failing assertions require in-place main-family selection, the retired `mool-home-social-videos` key, or the old `Shorts / Videos / Feed / Create` Social projection. Current accepted Social owners expose `Home / Shorts / Create / Feed`, use the specialized `screen04-rail-*` keys, and route top-level domain selection directly. These contracts are mutually exclusive.

The files remain preserved and unchanged. C30T release qualification uses the later passing owners: C25 main-only menu, C26 service/care/work navigation, FIX2 exact-owner navigation, plus the existing C27 and C29/C30 Social owners. The iOS player containment source gate also passed and is added. No product regression was hidden and no app/provider/device/external state changed.
