# C30C Social YouTube full-page Search, IME and copy preselection

## Founder finding

Two OPPO screenshots prove that Search currently opens a bottom sheet headed
`Filter loaded videos`, exposes implementation-oriented loaded-catalogue copy,
and leaves the keyboard covering the usable action area. The founder requires
a full-page YouTube search journey and no downward popup.

## MVP and reuse decision

- Classification: `mvp_required`.
- Existing route/screen owner reused: `SocialUniversalV2`.
- Existing real API client reused: `YouTubePrivateDevClient.search`.
- Existing backend operation reused: `publicSearch` ->
  `YouTubeProviderService.publicSearch` -> `search.list.explicit`.
- New backend owner, database owner, migration or route: none.
- Necessary new presentation state: one contained full-page Search state inside
  Screen 04 because the existing sheet has no truthful or keyboard-safe
  production successor.

## Provider policy decision

The official YouTube branding rules require every displayed YouTube logo to be
clickable and link to YouTube content or a YouTube component. Therefore the
top header logo will be removed rather than made non-interactive. Clickable
content-level YouTube attribution remains. Official search results will not be
intermixed, rewritten or replaced.

- Branding: https://developers.google.com/youtube/terms/branding-guidelines
- Developer policies: https://developers.google.com/youtube/terms/developer-policies
- Search API: https://developers.google.com/youtube/v3/docs/search/list

## Smallest complete outcome

Home and Watch enter one full-page Search state. Back restores the exact source
surface. A nonempty explicit user submission invokes the existing real
`publicSearch` operation. Loading, empty, error, retry, clear, keyboard and
result-selection states are finished and source-tested. No fake result,
cached-list filter, voice/scanner, recommendation system or deployment is in
scope.

## Evidence and delivery fit

- Founder screenshots:
  `artifacts/quality/post-c30b-social-youtube-search-reference-20260811-01/`
- Full long-path worktree inventory:
  `artifacts/quality/post-c30b-workspace-reconciliation-20260811-01/git-status-porcelain-v1-longpaths.txt`
- Estimated impact: one day, within the founder-locked 60-75 day window.
- Deployment remains held. A successor build/install requires its own fresh
  machine state and may occur only after two identical Social source cycles.
