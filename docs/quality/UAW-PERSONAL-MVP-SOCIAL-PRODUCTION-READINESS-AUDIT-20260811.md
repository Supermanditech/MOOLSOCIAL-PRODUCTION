# Personal Social production-readiness audit

Date: 2026-08-11
Branch: `remediation/prototype-conformance-2026-07-20`
HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`

## Founder outcome

Audit every Social action and subaction before deployment, register every real
gap without duplicating an existing owner, implement one ticket at a time, and
keep YouTube advertising and future recommendation work within the YouTube API
approval boundary.

## Protected boundary

- Installed OPPO identity remains `1.0.0-r60.34` / `2026081134`, serial
  `2b3e0f71`, APK SHA-256
  `96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29`.
- C28D and C29K evidence remains immutable.
- No build, install, uninstall, clear-data, downgrade, deploy, Production write,
  provider message, credential read/copy or protected-runtime mutation belongs
  to this audit.
- The HTML screenbook remains read-only and is not an implementation owner.

## Tap-by-tap inventory

| Start | Tap | Current destination/effect | Ownership | Audit disposition |
|---|---|---|---|---|
| Social | Mool, left edge | Shared main-action chooser | MoolSocial global | Reuse; white surface, 44dp compact minimum and left-edge position are protected. |
| Social | Home | YouTube-attributed catalogue, topic strip, Shorts shelf and videos | YouTube data inside MoolSocial | Reuse layout; correct misleading personalization/search copy and quota path. |
| Home | Search | Filters only the already-loaded catalogue | MoolSocial local control | Rename as a filter; it must not imply a new YouTube API search. |
| Home | Short card / Shorts | Full-height vertical official-player journey | YouTube | Reuse; no MoolSocial overlays, ads, reactions or metadata over the player. |
| Home | Video | Inline watch, provider metadata, channel, actions and more videos | YouTube plus separate MoolSocial actions | Remove in-memory Save and fake Discuss success; keep only truthful provider/details/share actions. |
| Watch | Share | Generic MoolSocial sheet | Mixed | Replace with canonical YouTube URL copy for YouTube items; never fabricate a MoolSocial URL. |
| Social | Create | One-tap YouTube Short and six MoolSocial format intents | Split owner | Reuse C29N gateway; retain host labels and direct format selection. |
| Create | YouTube Short | Creator connect/private upload journey | YouTube owner via MoolSocial | Reuse C29L; remain fail-closed until C29M provider qualification. |
| Create | Text/Image/Carousel/Image Poll/Quick Poll/Quiz | Keyboard-safe workbench and media picker | MoolSocial | UI is reusable, but default publish owner is review-only in-memory state; real persistence is C29P. |
| Social | Feed | Published MoolSocial items or empty/retry state | MoolSocial | UI is reusable; read, reaction, vote, share and post truth require C29P. |
| Social | Chat, right edge | Shared Chat route with Social return state | MoolSocial global | Reuse; white surface, 44dp compact minimum and right-edge position are protected. |

## Design and accessibility findings

- Global edges and Social middle destinations follow the accepted C29N order:
  Mool | Home | Shorts | Create | Feed | Chat.
- YouTube Home uses a dark YouTube-owned visual system; Feed and Create use the
  light MoolSocial system. This ownership separation is correct and protected.
- Shorts uses the official player without a MoolSocial overlay. The dock remains
  outside the player stage and is not an ad or player control.
- The Social root currently clamps system text to 1.0 at widths up to 340, 1.1
  up to 375, 1.2 up to 412 and 1.3 up to 430. Consequently the existing
  320/390 at 140% tests do not exercise actual 140% Social text. This is a
  launch-blocking accessibility gap.
- Visible tap targets must remain at least 44 logical pixels and exported
  semantic bounds must remain within the physical viewport.
- Customer UI may not contain internal commentary, quota reasoning, ticket
  language, provider configuration details or simulated success.

## State and action-truth findings

- `SharedSession()` is the production default and constructs
  `ReviewSharedGateway()`. MoolSocial Social publishes, reads, likes, saves,
  votes, replies, shares and reposts are process-local. A 24ms review delay is
  currently presented as completed publication. This cannot ship as a real
  public feed.
- YouTube watch Save is a local boolean reset on navigation. Discuss accepts
  text and reports `Comment posted on MoolSocial` without storing or sending a
  comment. Both are false-success paths.
- YouTube share offers `Copy MoolSocial link` without a real published
  MoolSocial resource owner. YouTube content instead has a truthful canonical
  provider URL.
- The YouTube Home loading phrase `Finding videos for you` implies
  personalization that is not implemented. The current search field only
  filters loaded results.

## API, auth, quota and wiring findings

- Public catalogue and creator upload reuse the real private-Dev client,
  HTTPS allowlisted provider route, Firebase Auth, App Check and limited-use
  replay protection on sensitive mutations.
- YouTube creator connection uses PKCE, state, incremental scopes and encrypted
  reusable credentials. Private upload is idempotent, resumable, private-only,
  reconciled and fail-closed. C29M deployment/runtime proof remains pending.
- Videos use `videos.list(chart=mostPopular)` with a five-minute shared cache.
  Shorts use `search.list` for `India news #Shorts`, up to four pages, on every
  app catalogue load; explicit search is intentionally uncached. This automatic
  use of the high-cost search bucket cannot scale as a production refresh path.
- The provider has atomic quota ledgers and lower private-Dev caps, but no
  production shared Shorts catalogue refresh owner exists.
- There is no official public `isShort` field in the current contract. The
  admitted result is creator-declared Shorts content, duration at most 180
  seconds, public, processed, embeddable and region-eligible.

## Advertising compliance decision

- No MoolSocial ad may overlay, frame, obscure, replace or appear inside the
  YouTube player or its controls.
- No sold promotion is enabled on a YouTube-only Home, Shorts or watch screen.
  Those screens do not yet contain enough independently valuable non-YouTube
  content to justify advertising if the YouTube API data were removed.
- A future adjacent placement is admissible only after a real MoolSocial
  campaign object links a creator/video/product outcome, carries clear
  `Promoted on MoolSocial` disclosure, remains outside the player, does not buy
  or incentivize YouTube engagement, passes legal/API review and has a remote
  kill switch. Until then the placement policy returns `deny` and renders
  nothing.

## Quota-purpose decision

The truthful quota purpose is: eligible public discovery, official YouTube
playback, explicit user search, connected-channel identity and one user-directed
private upload/reconciliation workflow. MoolSocial supplies independent value
through its own Feed/Create/Chat/work/commerce workflows; it does not claim to
replace YouTube, expose YouTube history, or provide a native YouTube
recommendation service.

## Future recommender boundary

The founder-requested history-aware Shorts/video recommender is registered but
not implemented. It starts only after quota and compliance approval, explicit
privacy/consent and deletion contracts, an allowed-data review, a measured
refresh budget and a kill switch. It must use disclosed MoolSocial interaction
signals, must not claim access to YouTube Watch History/Watch Later, must not
derive or expose unofficial YouTube metrics, and must not poll per user.

## Ticket order

1. C29O — action truth and real 140% accessibility; selected now.
2. C29T — last-successful YouTube catalogue continuity; founder-added launch blocker.
3. C29P — authenticated persistent MoolSocial Feed/Create; new necessary work.
4. C29Q — fail-closed YouTube-adjacent promotion policy; no visible ad yet.
5. C29R — quota-purpose evidence and shared low-frequency catalogue refresh.
6. C29S — post-approval recommender; beyond-MVP and dependency-held.

### Founder-added catalogue continuity finding

The Videos and Shorts results live only in `SocialUniversalV2` widget state.
Reopening Social reconstructs empty lists and shows the loading surface even
when the process just fetched the same eligible provider catalogue. C29T adds a
short-TTL, last-successful process snapshot, immediate reopen hydration and a
background refresh that does not replace visible content with a loading popup.
It does not add filler, long-term storage, per-user polling or recommendation.
The installed r60.34 distinction between loading and provider-access gate still
requires the pending read-only OPPO audit.

## Installed-APK cross-comparison state

The founder requested a read-only cross-comparison against installed r60.34.
`adb devices -l` returned no connected device on 2026-08-11, so no installed
screen, semantic tree or tap path was admitted as new evidence. The comparison
remains pending and may add a ticket only after serial `2b3e0f71` is separately
present and host-qualified. Source implementation may continue; protected APK
identity and evidence remain unchanged.
