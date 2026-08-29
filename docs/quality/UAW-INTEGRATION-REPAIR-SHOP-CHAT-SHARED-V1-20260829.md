# UAW-INTEGRATION-REPAIR-SHOP-CHAT-SHARED-V1-20260829

State: `premerge_ready_exact_three_owner_resolution`

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

Backend, Firebase, Android configuration, OPPO and
`com.moolsocial.app.runtime` remain excluded.
