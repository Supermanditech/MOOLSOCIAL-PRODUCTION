# UAW C30T r60.45 Feed normal-entry stale shared-post error — 13 August 2026

After a retained-data relaunch, the exact normal Social rail action `Open Feed, MoolSocial` loaded public Feed content but also rendered `This shared post is not available`. No shared link was opened during the current session. The banner is therefore stale retained route/error state, not truthful current navigation context.

The successor must scope unavailable shared-post state to the explicit shared-link route, clear it on normal Feed entry/return, preserve Feed pagination and refresh, and prove retained-data relaunch without uninstall or data clear. No second AAB/upload/install is authorized.

## Pre-selection robustness and reuse assessment

- Classification: `mvp_required`; an unrelated retained link error makes normal
  public Feed browsing materially untruthful.
- Confirmed source gap: unavailable-link state is compared to immutable
  `widget.initialItem`, but switching away and back through the local Social
  rail does not change that input, so the old banner can reappear.
- Reuse: the existing Social consumer owns both explicit shared-link resolution
  and local Feed selection. One ephemeral active-link context and current-owner
  tests are sufficient.
- Minimum correction: keep the banner for the actual unresolved shared route;
  cancel and clear only link-resolution presentation on normal Feed selection;
  preserve loaded posts, pagination, refresh and future new shared links.
- New screens, routes and backend owners: none.
- Exclusions: no uninstall/data clear, hidden real link failure, build, AAB,
  upload, install, deployment or external write.

The ticket is selected for source-only implementation with all successor AAB
authority false.

## Source implementation result — 2026-08-13

Shared-link resolution and its unavailable notice are now bound to one
ephemeral active-link presentation context. An actual explicit missing link
still shows `This shared post is not available` while keeping the remaining
public Feed visible.

Selecting Feed through the normal local rail now increments the link request
identity and clears only resolved/unavailable link presentation state. It does
not clear loaded posts, pagination, refresh state or SharedSession data. If an
older lookup finishes after that normal entry, its result may contribute normal
loaded public data but cannot reorder the card list or restore the stale notice.
A later new explicit shared link still creates a fresh active context and
supersedes any older resolution.

Qualification completed without an AAB, upload, install, device write,
deployment or external action:

- Feed/Create publication partition: 25 passed;
- C30T guest/auth/feed partition: 15 passed;
- analyzer: both exact runtime/test owners clean.

State is
`source_implemented_focused_tests_passed_live_Play_acceptance_pending`.
Retained-data OPPO relaunch and normal-rail proof require a future separately
authorized Play candidate. No uninstall, data clear or successor AAB is
authorized by this result.
