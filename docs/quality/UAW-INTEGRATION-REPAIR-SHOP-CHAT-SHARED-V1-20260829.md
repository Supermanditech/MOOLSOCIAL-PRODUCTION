# UAW-INTEGRATION-REPAIR-SHOP-CHAT-SHARED-V1-20260829

State: `combined_regression_passed_candidate_gate_pending`

- First parent: tested Buy adapter and cumulative Shop evidence
  `e5720cb86bd2119afc3d84a83d3116018f17f9a3`.
- Second parent: authoritative shared Chat
  `30f4614574aae3c315d586944636a35ba314873d`.
- Merge base: `369bb45599366de8a8d95a9f0824c8cb961d0692`.
- Work ID: `shop-chat-shared-v1-20260829`.
- Repair continuation baseline:
  `011fd09d1d94fce02d0bbc9c7b94c90f742624e6`.

The retained merge-tree audit proves exactly three conflicts:

- `apps/mobile/lib/ui_v2/profile/global_profile_panel_v2.dart`;
- `config/codex-development-regression-registry.json`;
- `config/codex-subagent-coordination-policy.json`.

Resolution contract:

- preserve the tested Buy-side global profile blob exactly;
- preserve the cumulative repair-side registry and policy;
- make no manual change to any other owner;
- produce one exact two-parent repair merge;
- run shared Chat and Buy regressions before any APK or Redmi action.

Pre-merge readiness:

- clean repair task start passed at the declared continuation bootstrap;
- the tested Buy adapter remains `e5720cb86bd2119afc3d84a83d3116018f17f9a3`;
- authoritative shared Chat remains
  `30f4614574aae3c315d586944636a35ba314873d`;
- no source owner is authorized before the two-parent merge.

Repair result:

- merge commit: `fc3019ea483ee725f168957ef17b98daf7ff0517`;
- second parent: `30f4614574aae3c315d586944636a35ba314873d`;
- approved profile blob preserved exactly:
  `427571d774eada83ea642e8811ee31ec3aa2db44`;
- unmerged owners: registry and coordination policy;
- authoritative resolution owners: profile, registry, policy and checker.

Combined-test result:

- focused analysis of 16 shared Chat and Buy owners passed cleanly;
- the first five-suite shared Chat run stopped at compilation because the
  cumulative tip lacks the authoritative `share_plus` dependency ancestry and
  the preserved profile blob lacks helper APIs required by later shared profile
  destinations;
- no APK, install or device action was attempted;
- no speculative source or dependency fix is authorized before exact local
  supporting-commit ancestry is identified.

Supporting-ancestry audit:

- `share_plus: 13.3.0` and its lock entries already exist on both parents; the
  failed run incorrectly used `--no-pub` after guarded support restoration;
- profile Back/return helpers originate from existing approved commits
  `941cf41d1af080ca75b19fea85f4c82a64f9fa61` and
  `d27306378df51d6523c2608ad47a86e2bfa24b43`;
- the exact Git auto-merged cumulative profile blob
  `335a0d7af0a23650f9fba687070b049d2c7a0cb8` is restored, combining the Buy
  profile with those shared helpers without a new design implementation;
- the next test run must hydrate dependencies and compile in the same guarded
  invocation.

Final verification:

- focused shared Chat, Buy and profile analysis: clean;
- authoritative shared Chat suites: `55` passed, `0` failed;
- complete Buy Shop Chat suite: `38` passed, `0` failed;
- complete Buy screen regression: `78` passed, `0` failed;
- complete Buy directory: `469` passed, `28` intentional skips, `0` failed;
- full Buy JSON `done.success`: `true`;
- full Buy JSON SHA-256:
  `9EDB1DDA12F1A1681D902BF2E6B473B06AC7F150D85EB099700DEB09F081A0EC`;
- OPPO, runtime package, backend, Firebase and Android configuration: untouched.

Redmi r61.7 disposition:

- installed package/version and cold launch passed on Redmi
  `TG8HCYTGGQT885OF`;
- founder visual handoff rejected before presentation because the Shop Orders
  filter displayed the Food-only `Rasoi Kitchen Order`;
- r61.7 is retained as rejected technical evidence and must not be approved;
- Shop now owns the shared thread set `shop-order`, `shop-partner` and
  `shop-offers`, while global and Food Chat retain their prior conversations;
- final shared plus Buy Shop Chat regression after the context correction:
  `95` passed, `0` failed;
- next device candidate must be monotonic r61.8.

Final device qualification:

- r61.8 preflight passed but its one build attempt failed at
  `mergeDebugNativeLibs` because disk space was exhausted; no APK or install
  occurred and the candidate is preserved as consumed failed;
- after generated-cache cleanup raised free space above 6 GiB, monotonic r61.9
  preflight and build passed;
- installed Redmi identity: `com.moolsocial.app.cursorreview`,
  `1.0.0-r61.9-cursorreview`, code `2026082811`;
- built and installed APK bytes: `206453947`;
- built and installed SHA-256:
  `5262CE6011FB15F0D21EB3F8DCA8BDAFB2372914684C02AC2D3AF66F7A377CBB`;
- cold launch passed;
- device visuals passed for Shop/Orders `Fresh Basket Order`, Wholesale/Business
  `Metro Wholesale Partner`, Offers/Support `Shop Offers Support`, and exact
  Android Back recovery;
- Redmi is left on the main Shop Chat screen for founder visual approval;
- OPPO, `com.moolsocial.app.runtime`, Android configuration, Firebase and
  backend remain untouched.

Remote implementation binding:

- the original Codex shared Chat branch advanced with later closure evidence;
- immutable shared implementation commit `30f46145` is therefore bound to
  remote branch
  `work/codex-ui/global-contextual-chat-shell-v1-implementation-20260829`;
- the advanced Codex branch remains preserved without force-push or rewrite.

Backend, Firebase, Android configuration, OPPO and
`com.moolsocial.app.runtime` remain excluded.
