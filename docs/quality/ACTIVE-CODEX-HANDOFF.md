# Active Codex handoff

Snapshot date: 20 July 2026
Purpose: durable context bootstrap for Codex in Android Studio and other Codex
surfaces.

This file does not replace the approved-reference manifest, product-design
memory, QA records or release gates. It points new agents to those authorities
and records the current checkpoint so a missing chat transcript cannot erase
project decisions.

## Workspace boundary

- Authorized workspace: `C:\GUARANTEED OUTCOME`
- Production repository:
  `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Approved HTML screenbook:
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook`
- Folders outside `C:\GUARANTEED OUTCOME` are unrelated and out of scope.

Android Studio Codex was configured with:

- Codex CLI `0.144.6`
- `sandbox_mode = "workspace-write"`
- sole additional writable root `C:\GUARANTEED OUTCOME`
- `openaiDeveloperDocs` MCP
- `moolsocial-workspace` filesystem MCP rooted only at
  `C:\GUARANTEED OUTCOME`

Authentication secrets and desktop-session MCP bridges were not copied.
Android Studio uses its isolated Codex home at
`C:\Users\jisal\AppData\Local\Google\AndroidStudio2026.1.2\aia\codex`.
When validating its MCP list from a terminal, set `CODEX_HOME` to that exact
directory first. Otherwise the executable inherits the desktop Codex profile
and may display unrelated desktop-only connectors that are not part of this
project setup.

## Observed Git state

At this snapshot:

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `b2839b82f5d2164e60df3d89e5ca39e1419acf86`
- Remote branch was two commits behind local HEAD.
- `main`: `ed2a44d`
- Rollback tag: `baseline-ui-before-conformance-2026-07-20`
- Numerous untracked files under `artifacts/quality/**` are retained test
  evidence and must not be cleaned or deleted.

Every new task must verify live Git state rather than assuming this snapshot is
still current.

## Accepted production checkpoint

Founder acceptance evidence:

`artifacts/quality/screen01-screen03-copy-fitment-20260720/FOUNDER-REVIEW-EVIDENCE.md`

Immutable accepted references:

- Screen 01 `v3`
- Screen 02 `v4`
- Screen 03 `v2`

Exact accepted OPPO candidate and installed APK SHA-256:

`76c40d1a3dead71358a72afb77db940f0e9f88751b4a48d958368451d2330ed0`

The accepted journey is:

`Screen 01 → Screen 02 location consent/result → Screen 03 provider or OTP
sign-in → Universal`

Both mobile OTP and email OTP reached Universal. Mobile OTP passed after ADB
reverse mappings were deliberately absent. Authenticated killed-process
relaunch restored Universal.

Screens 01–03 are immutable during development of the next isolated UI set.

## Cloud environment authority

Before any Google Cloud, Firebase, authentication, maps, API, credential or
distribution action, read:

`docs/delivery/ENVIRONMENT-PROMOTION-BOUNDARY.md`

Founder-locked order:

- local Firebase emulators: zero-cost first testing boundary;
- `moolsocial-dev-503018`: separate real-service Trial;
- Firebase App Distribution tester group inside Dev: screenwise Preview;
- `moolsocial-staging-503018`: clean staging for promoted candidates only;
- Production project: created later and never used for experimentation.

Preview is not a fourth backend. An installed client cannot switch
environments at runtime.

Provisioning checkpoint observed 21 July 2026:

- Firebase CLI reauthentication succeeded.
- Billing exists, but Google reports that the completed prepayment may take up
  to 24 hours to be credited.
- The authoritative organisation ID is `1067591230270`; the earlier
  transposed value `1067591730370` must never be reused.
- Direct Organisation Administrator and Project Creator roles are verified for
  the MoolSocial admin principal.
- `moolsocial-dev-503018` now exists inside `moolsocial.com` as Firebase project
  `MoolSocial Dev Trial`, project number `760290687711`, state `ACTIVE`.
- The immediate CLI Firebase attachment returned `403`; project IAM verified
  Owner access, and Firebase console completion then reported the project
  ready. The final state was independently rechecked with Firebase CLI.
- Staging and Production have not been created. Billing and billable APIs have
  not been attached to Dev/Trial.
- Do not create the project outside the organisation as a workaround.
- Do not enable APIs merely because they appear free.
- Do not register Firebase apps or create API/OAuth credentials without the
  applicable action-time confirmation and restriction plan.

## Regression history authorities

Permanent regression decisions are recorded in:

- `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`
- `docs/quality/QA-024-APPROVED-PROTOTYPE-CONFORMANCE.md`
- `docs/quality/CUSTOMER-COPY-MACHINE-GATE.md`
- `docs/quality/FIRST-OPEN-REAL-USER-STATE-MATRIX.md`
- `docs/quality/RELEASE-GATES.md`

They include the following non-negotiable incidents:

- duplicate/too-fast launch presentation;
- Screen 01 bypassing required Screen 02 after retained state or relaunch;
- incomplete connected-screen testing and regressive founder handoffs;
- opening Screen 02 when the founder requested the exact Screen 03 page;
- customer-visible implementation/example language in OTP and slow-start
  states;
- default-state-only copy tests missing reachable OTP states;
- falsely diagnosing the customer as offline when the device review route
  failed;
- dependency on volatile ADB reverse mappings for mobile OTP.

## Evidence inventory

Retain and consult these directories:

- `artifacts/quality/screen01-oppo-one-visible-final`
- `artifacts/quality/screen01-screen02-oppo-20260720`
- `artifacts/quality/screen01-screen03-copy-fitment-20260720`
- `artifacts/quality/screen02-oppo-interactions-20260720`
- `artifacts/quality/screen02-oppo-v4-20260720-test-candidate`
- `artifacts/quality/screen02-oppo-v4-interruption-matrix-20260720`
- `artifacts/quality/screen02-screen03-combined-20260720`
- `artifacts/quality/screen02-v5-exact-apk-oppo-20260720`

Evidence types include Markdown reports, candidate manifests, PNG captures,
Android XML accessibility trees, filtered logcat, Flutter regression logs,
build logs, PIDs, debug APKs and installed-base APKs. Binary artifacts should
be verified by checksum and appropriate inspection tools, never interpreted as
plain text.

The accepted checkpoint reports:

- HTML customer-copy gate: 9 states passed.
- Phone fitment:
  `320×568`, `360×640`, `360×720`, `375×667`, `390×844`, `412×915`,
  `430×932`, plus compact layout at `140%` text.
- Flutter analyzer: no issues.
- Full regression 1: `375/375`.
- Full regression 2: `375/375`.
- `git diff --check`: passed.
- Physical device: OPPO CPH2375, Android 13, serial `2b3e0f71`.

## Plans

Read and reconcile work against:

- `docs/delivery/45-DAY-GO-LIVE-PLAN.md`
- `docs/delivery/UNIVERSAL-INTENT-PRODUCTION-BACKLOG.md`
- `docs/quality/PRODUCTION-ONLY-SCREEN-READINESS.csv`
- `docs/quality/SCREEN-BY-SCREEN-READINESS.csv`
- `docs/quality/APPROVED-TAP-INVENTORY.csv`

Do not mark a plan item complete from conversation memory. Require repository
evidence and the applicable founder acceptance gate.

## Context reconstruction procedure

At the start of a new Android Studio Codex task:

1. Read `C:\GUARANTEED OUTCOME\AGENTS.md` and the repository `AGENTS.md`.
2. Verify MCP and filesystem access without changing product files.
3. Capture live Git branch, HEAD, status and recent decorated history.
4. Read every required authority listed in the repository `AGENTS.md`.
5. Validate the approved-reference manifest and locked UI script.
6. Inventory existing quality evidence before producing a work plan.
7. Report a context-integrity summary and stop if any branch, checksum,
   reference status or lock differs.

Raw private chat/tool-call transcripts are not automatically shared between
Codex surfaces. Any founder decision that is not already represented in the
repository must be added to the appropriate durable memory, QA, manifest,
evidence or plan file before it can be treated as permanent project history.

## Next founder-authorized UI scope

Founder direction recorded after the context-integrity audit on 20 July 2026:

- Begin the revision/remake of HTML Screen 04,
  `04-universal-focus-shell.html`.
- The authorization covers the Screen 04 HTML review workflow only.
- Inspect every visible state, control, action, sub-action, nested tap and
  connected destination before presenting the corrected HTML.
- Do not modify the production Flutter Screen 04 implementation yet.
- Do not modify locked Screens 01–03 or their accepted references.
- Flutter V2 implementation may begin only after the founder explicitly marks
  the corrected Screen 04 HTML state `FINAL`.

## Screen 04 HTML founder-review candidate — rejected

Durable checkpoint recorded 20 July 2026:

- The founder-authorized Screen 04 HTML remake is present only at
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\04-universal-focus-shell.html`.
- Founder-rejected candidate SHA-256:
  `9d4bbc76104cb5208f54fdfd83603d89ee563bf0a0cdbb724249f1c27fcd9b86`.
- Exact review URL:
  `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1`.
- Exact loaded pathname:
  `/screens/04-universal-focus-shell.html`.
- Page heading: `Universal`.
- Customer heading: `What would you like to do?`.
- Default focus: `Social` / `Stay close to what matters.`.
- Visible Universal entries: Social, Buy, Eat, Ride, Book, Pay, Work and Chat.
- `world` focus restoration and `openMool=1` return handling passed.
- Search, scan, voice, notifications, account, permanent serviceable-area and
  Chat return paths were exercised.
- Twenty-six explicit loading, empty, denied, unavailable, failure, retry and
  result moments were mounted and inspected.
- All direct and nested HTML destinations returned HTTP `200`.
- Default and nested controls had no unnamed, dead or sub-44 px control.
- Fitment passed at `320×568`, `390×844`, `430×932` and `390×844` at
  `140%` text with no horizontal overflow or clipped action label.
- Browser console and page-exception lists were empty.
- Screen 04 `git diff --check` and inline JavaScript syntax checks passed.
- The Screen 01–03 approved lock script passed after verification.
- Shared CSS/runtime, Flutter product files, Screens 01–03 and Screens 05 onward
  remain unmodified by the Screen 04 work.

Detailed evidence and the complete control/destination inventory:

`artifacts/quality/screen04-html-founder-review-20260720/SCREEN-04-HTML-FOUNDER-REVIEW-WORKLOG.md`

Current authorization boundary:

- Screen 04 is rejected and authorized for another HTML correction cycle.
- Restore conformance with the approved Universal focus-shell architecture,
  action/sub-action placement, bottom Mool/context/Chat rail and branding.
- Remove visible example, commentary, review, preview and engineering language
  from the entire founder-review page, not only from the simulated phone.
- Read the new permanent regression record in
  `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`,
  `docs/quality/CUSTOMER-COPY-MACHINE-GATE.md` and issue
  `UI-CONFORMANCE-003` in QA-024 before changing Screen 04 again.
- Do not freeze the candidate or change the approved-reference manifest.
- Do not begin Flutter Screen 04 implementation.
- Do not begin Screen 05.

## Founder-ready Universal navigation and Buy tickets

Founder inputs recorded 21 July 2026 are translated into the sequenced ticket
pack:

`docs/delivery/FOUNDER-UNIVERSAL-NAVIGATION-BUY-TICKETS-20260721.md`

`FND-U04-RAIL-001` was executed after the founder said `continue`. The founder
selected the capability-ribbon direction for correction. `FND-U04-RAIL-002`
then revised that direction so one main-action tap immediately reveals its
sub-actions, Mool returns to all main actions, and mouse controls, keyboard
arrows, swipe, Back and Forward share the same navigation state. After founder
review, the oversized mouse-arrow tiles and later oval cues were replaced by
bare `6×6` chevron hints while retaining `44×52` pointer/tap targets. No
downstream action screen was changed.

Current capability-revision evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-rail-001/FND-U04-RAIL-002-SUBTLE-HINT-REVISION-20260721.md`

The founder accepted the capability bottom rail on 21 July 2026 and authorized
`FND-U04-ACTION-003`. The active HTML slice is the Social main-action surface;
do not redesign the accepted rail, edit Flutter, freeze Screen 04 or touch
Screens 01–03.

The founder then made the production gate stricter: the accepted rail must
remain unchanged, and native Universal implementation cannot start after
Social alone. The first-layer HTML for Social, Buy, Eat, Ride, Book, Pay and
Work must all be designed and explicitly founder-approved first. The active
scope remains Social HTML only.

Social must open as an immersive media-first consumer surface. `Shorts`,
`Videos`, `Feed` and `Create` stay in the accepted bottom rail. Do not repeat
them above content. The superseding public discovery modes are `For You`,
`Following`, `Nearby` and `Promoted`, all owned by MoolSocial. Do not expose
`YouTube`, `Facebook`, `Instagram` or `X` as public consumer-feed buttons;
social sign-in never implies full external-feed access.

Founder correction on 21 July 2026 supersedes the earlier public
`Publish`/`Promote`/`Sell`/`Earn` launchpad. Creator campaigns, products to
promote, connected channels, earnings and advertiser funding belong behind a
Creator or Business account under Profile/Work. Personal Create provides
`Post`, `Short`, `Video` and `Drafts`; Creator-account setup remains under
Profile/account. `Promoted` provides one-tap
consumer access to paid MoolSocial reels; sponsor and commission disclosure is
mandatory. Cross-network extension belongs in Business Promotions and may use
only eligible YouTube channels, Facebook Pages, Instagram professional accounts
or future provider-permitted connectors that the account owner connected and
approved.
Like/Comment/Share/Remix controls belong to each content item and cannot remain
as a fixed page-level rail. Every visible control must have a concrete state or
destination, with no example, review, prototype, design or engineering copy in
the customer viewport.

Creator commerce is founder approved as a core Social/Create capability. Read
`docs/decisions/ADR-0003-CREATOR-COMMERCE-ATTRIBUTION-AND-PAYOUT.md` before
changing Social, Create, connected YouTube/product journeys, order attribution
or creator payout. The approved model pays from eligible delivered MoolSocial
sales, records attribution per order line and never rewards YouTube engagement
metrics.

The earlier Social main-action founder-review candidate with SHA-256
`A20E3437ACDA343C113D31B936DD38D6BEADCF9062A73FD7DA785D512F1AD87B`
is superseded by the founder's account-boundary correction. Historical evidence:
`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-SOCIAL-FIRST-LAYER-FOUNDER-REVIEW-20260721.md`.
The corrected HTML must receive new verification and founder visual approval.

The corrected consumer/creator-boundary candidate with SHA-256
`E67716227B93A2CE5B993A2F8E243A8582AE9FBAFCCA9B30077CB419277C30D3`
is superseded by the native Social Exchange correction. Historical evidence:
`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-SOCIAL-ACCOUNT-BOUNDARY-CORRECTION-20260721.md`.

The active founder-review candidate SHA-256 is
`5CCF93809231815F69E3B46C35E33E4717E73AAF1859CE781B60E4A5F69757F2`.
Evidence:
`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/screen04-social-native-exchange-audit-20260721-02.json`.
Social checks passed `14/14` fitment rows, `15/15` affected interactions and
`9/9` declared destinations with zero console errors; the accepted rail CSS,
markup and navigation-runtime slices remained byte-identical. ActivityPub/AT
Protocol work is later adapter work, not an MVP public control. No protocol
licence or per-call charge is assumed, but infrastructure, moderation, abuse,
privacy and operational costs remain before any live connector.

Open observation: the accepted rail's transparent previous/next chevron hit
regions overlap the centre of visible `Shorts` and `Create` at `390×844`. This
predates the Social correction and was not changed because the rail is
founder-locked. Direct-tap acceptance remains open unless the founder authorizes
a hitbox-only correction or explicitly accepts the overlap. Do not hide this
observation or claim all direct rail taps passed.

## Creator distribution and analytics HTML revision

Founder direction recorded 21 July 2026:

- WhatsApp Business access is available, but it remains an opt-in customer
  messaging, order and support channel rather than a public-feed publisher.
- TikTok is excluded from the India MVP.
- Direct-API destinations with practical launch paths are designed first;
  partner-only networks remain hidden until separately approved and live.
- The six-part connector proof inventory was founder accepted at this point in
  the history. The later cost-first full-stack contract supersedes its delivery
  sequence: YouTube, Instagram and Facebook are launch proof; later connectors
  prove individually before their feature flags can be enabled.
- Paid MoolSocial Reels remain the owned core. Reel/Short is one format, Posts
  include carousel, and long-form Video remains separate.
- Creator publishing, connected channels, analytics, commission and payouts
  remain under Profile → Creator account. The public Social feed remains
  consumer/media-first.

The Screen 04 founder-review HTML now includes those states without changing
the accepted rail. Current SHA-256:

`C815CEF2574A9BB7D2596DBE156BFE8549B8C3869DE5E2994B072668FAA8F855`

Automated evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/screen04-social-distribution-audit-20260721-01.json`

Results: `14/14` viewport/text-scale rows, `10/10` focused interactions and
`8/8` mounted customer-copy/fitment states passed with zero console errors.
The accepted bottom-rail CSS, markup and navigation-runtime hashes remained
byte-identical. Screen 04 and its Social layer are still awaiting founder
visual review; they are not `FINAL`, frozen, in Flutter or promoted.

## External reach and Creator Studio full-stack contract

Founder direction recorded 21 July 2026 is now durable at:

`docs/delivery/SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md`

Read it with ADR-0003 and ADR-0004 before any Social, embedded-media, creator
connection, publishing, analytics, attribution or payout work. Its current
authority is:

- native MoolSocial Social plus official inline YouTube playback is the
  cost-first stay-and-discover experience;
- this requires a native paginated choice of many eligible YouTube items, not
  one fixed embedded video; scrolling/swiping and selecting another item must
  replace the active player without leaving MoolSocial;
- the product may use connected creator uploads, approved playlists, regional
  popular video and deliberate filtered search, but cannot claim YouTube's
  personalized Home feed, watch history or Watch Later;
- the provider-owned YouTube player is the sole narrow MVP WebView exception;
  no MoolSocial HTML/UI may be rendered in a WebView;
- external publishing begins with MoolSocial, YouTube, Instagram Professional
  accounts and Facebook Pages;
- WhatsApp Business remains opt-in messaging; X remains cost-gated and off;
  later connectors remain feature-flagged until individual proof;
- destination-first preparation is the default;
- optional `Standard Publish` uploads one controlled master but still creates,
  previews and tracks a separate compliant payload per destination;
- public YouTube upload/quota expansion remains subject to the accepted
  MoolSocial API-project compliance audit and current provider approval;
- external audience engagement becomes attributable MoolSocial sales through
  tracked links; commission never derives from external engagement metrics.

No Screen 04 HTML, accepted rail, Flutter file, cloud resource, credential,
API or approved reference was changed by recording this decision. Screen 04
and Social remain awaiting founder visual approval and are not `FINAL`.

## Screen 04 YouTube Shorts and long-form correction

Founder direction recorded 21 July 2026 supersedes earlier owned-video wording:

- MoolSocial owns Reel/Short and Post/Carousel at MVP; it does not host owned
  long-form video.
- `Shorts` mixes MoolSocial Reels with only positively verified YouTube Shorts.
  Duration under four minutes is not sufficient Shorts classification.
- `Videos` is the eligible public YouTube long-form library with native
  Discover, Popular, Topics, Channels and paginated choices around one
  user-initiated official provider player.
- Public YouTube actions are source-correct. There is no false YouTube Like,
  Comment, Follow or Remix mutation from the public unauthenticated surface.
- Generic public YouTube video does not receive a fabricated MoolSocial
  product link. Commerce requires a real campaign-attribution record and
  disclosure.
- Personal Create contains Reel, Post/Carousel and Drafts. Connected-channel
  long-form publishing stays under Profile -> Creator account.

Current founder-review HTML SHA-256:

`4FBAC2609FC8787AFC86E6932855E72AED73FD3879FE75C2B2418CF4DD788B40`

Evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/screen04-youtube-format-contract-audit-20260721-01.json`

Results: accepted bottom-rail CSS/markup/runtime hashes unchanged; `56/56`
fitment rows; `11/11` affected interactions; zero console errors. Screen 04 and
Social remain awaiting founder visual approval and are not `FINAL`, frozen,
implemented in Flutter or promoted.

## Screen 04 YouTube metadata and MoolSocial commerce revision

Founder direction recorded 21 July 2026 adds the production-realistic detail
and revenue boundary to the Social `Videos` state:

- show useful public YouTube metadata supported by the current contract;
- keep only the required source/player identity while the surrounding discovery
  and actions retain MoolSocial branding;
- prompt the customer to connect YouTube before Like, Comment or Subscribe;
- keep MoolSocial Save, Discuss, Share and Details distinct from YouTube
  mutations;
- show campaign commerce only when a real attribution record exists; and
- allow a separately disclosed `Promoted on MoolSocial` placement outside the
  provider player.

Current founder-review HTML SHA-256:

`F386EE4DAE39172D89D65741A9000D678823FC5C5D7D0F082120D7438FCD89B3`

Evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/screen04-youtube-metadata-commerce-audit-20260721-01.json`

Results: `56/56` Social fitment states, `42/42` Details/Connect/Comment sheet
fitment states, `13/13` interaction assertions, zero console errors and
byte-identical accepted bottom-rail CSS/markup/navigation-runtime slices.

Screen 04 and Social remain awaiting founder visual approval. They are not
`FINAL`, frozen, implemented in Flutter or promoted.

### Required native fitment work after HTML approval

The `56/56` Screen 04 HTML result proves only the representative phone
prototype matrix. When Flutter implementation is later authorized, native
acceptance requires the same seven phone viewports at 100% and 140% text plus
supported larger accessibility text, landscape, Android/iOS safe areas and
cutouts, keyboard/IME, display zoom, system-navigation insets,
interruption/resume, tablet portrait/landscape and split view, and foldable
cover/unfolded/hinge states. The official YouTube player must remain usable,
unobscured and correctly sized in every supported state. Browser evidence
cannot substitute for Flutter widget and device evidence. Read the permanent
gate in `docs/quality/RELEASE-GATES.md` before implementing or accepting native
Screen 04.

## Latest Screen 04 Social candidate — 21 July 2026

The current HTML candidate supersedes the two earlier Social hashes recorded
above. Exact SHA-256:

`D9444962A2E74D4F8A05E1DBF6929C5BD6D0C7A6D577E5C03B31797641DEE697`

Founder-requested changes now represented:

- a continuous vertical MoolSocial Reel plus eligible YouTube Short sequence;
- MoolSocial owned/paid priority without hiding source or sponsor disclosure;
- entry-visible reel controls that auto-hide and return on content tap;
- functional For You, Following, Nearby and Promoted content states;
- a native MoolSocial video discovery home followed by a selected in-app
  official player watch state;
- compact adjacent YouTube attribution instead of the large source pill; and
- MoolSocial promotion/commerce separated from YouTube results and player.

Evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-SOCIAL-SWIPE-VIDEO-DISCOVERY-FOUNDER-REVIEW-20260721.md`

Targeted automated result: 56/56 fitment rows and 24/24 interaction assertions,
zero console errors, zero failures. Approved UI locks and customer-copy gates
pass. Accepted bottom-rail CSS, markup and navigation-runtime hashes are
byte-identical. No Flutter/API/cloud work occurred. Screen 04 remains pending
founder visual approval and is not `FINAL`, frozen or promoted.

## Screen 04 YouTube content-fitment correction — 21 July 2026

The previous `D944...` candidate is superseded after the founder identified
that the YouTube Short metadata extended behind the accepted rail. Root cause:
the YouTube article's intrinsic height exceeded the actual Social content
stage, while the earlier audit checked horizontal overflow but not vertical
player/context/rail containment.

Current HTML SHA-256:

`A5307EB077E136B09064B40BB015C1856EE0B4A407F13CEA359B6303C75268B1`

The corrected Short uses a compact immersive header, a non-cropping bounded
provider player, a separate scrollable metadata region and a full Details
sheet. Player, metadata and rail do not overlap. Channel/title are visible on
entry; description, public statistics, topics, MoolSocial actions, attributable
commerce and disclosure are reachable without leaving the Short.

Evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-YOUTUBE-CONTENT-FITMENT-CORRECTION-20260721.md`

Results: 28/28 targeted fitment states, 16/16 metadata interactions, 56/56
broader responsive states, 24/24 broader interactions, zero console errors and
zero failures. Approved locks and customer-copy gates pass; accepted rail
hashes remain byte-identical. Initial failure evidence is retained. No Flutter,
backend, cloud, API, accepted-reference or Screen 01-03 work occurred. Founder
visual approval is still pending.

## Social Shorts/Videos approval and active Feed/Create review — 21 July 2026

The founder approved the Social `Shorts` and `Videos` HTML states from the
`A5307EB0...` Screen 04 candidate and explicitly prohibited Flutter work at
this point. The immutable scoped reference is now:

`approved-references/screens/04-universal-social-shorts-videos/v1`

It is indexed in `approved-references/manifest.json` and contains the accepted
HTML snapshot, shared CSS, used media asset, reference images, interaction
contract, founder-acceptance record and checksums. The scoped approval does not
mark Feed, Create, all of Screen 04 or Universal native implementation final.

Active founder-review URLs:

- Feed:
  `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability&social=feed`
- Create:
  `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability&social=create`

Current HTML SHA-256:
`1A0F35A26527C02B402C4B88B96384C74C858DCAE72FB81C253E0A022CC1DDC7`.

Feed now changes the actual MoolSocial Post/Carousel content for For You,
Following, Nearby and Promoted, keeps engagement item-contextual and limits
commerce to eligible linked content. Personal Create contains precise Reel,
Post, Carousel and Draft routes only; professional Creator/Business tools stay
behind their account boundaries.

Automated result: 28/28 new content-fitment rows, 14/14 interactions, 2/2
focused copy/account-boundary checks, zero console errors. The accepted
Shorts/Videos audits remain green and the rail hashes remain byte-identical.
The protected rail remains visibly crowded near Create at `320×568 / 140%`;
that inherited observation is open and may not be changed without founder
authorization. Feed and Create still need founder visual approval.

## Feed/Create first-layer approval and deeper review — 22 July 2026

The founder approved the Social Feed first-layer presentation and personal
Create landing represented by source SHA-256
`1A0F35A26527C02B402C4B88B96384C74C858DCAE72FB81C253E0A022CC1DDC7`.
The immutable scoped package is:

`approved-references/screens/04-universal-social-feed-create/v1`

It is indexed in `approved-references/manifest.json`. The approval excludes
deeper Feed/Create states, remaining Universal first-layer actions and all
Flutter/backend/provider/cloud work. Do not broaden it.

The active HTML candidate now supplies low-effort same-screen deeper states:
Feed comments, Like/Save, Repost/Undo, quoted sharing, Post with photo/poll/
connected follow-up/audience/scheduling, camera-to-Reel progression, 2–10
photo Carousel editing, Draft resume and precise publish confirmations.
Personal Create does not expose Creator Studio, campaign, external-channel,
analytics, commission or payout controls.

Candidate SHA-256:
`A38AD64A05425DD36BB0ED89679BADFD14276ED805E33B71C3C907F9260C1B7F`.

Verification:

- deeper Feed/Create fitment: `182/182`;
- deeper journeys: `20/20`;
- focused customer-copy/account-boundary check: `1/1`;
- Shorts/Video discovery regression: `56/56` fitment and `24/24` interactions;
- YouTube content/fitment regression: `28/28` fitment and `16/16` interactions;
- console/page errors: `0`; and
- approved bottom-rail hashes: byte-identical.

Exact founder-review URLs:

- Feed: `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability&social=feed`
- Post: `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability&social=create&compose=post`
- Reel: `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability&social=create&compose=reel`
- Carousel: `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability&social=create&compose=carousel`
- Drafts: `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability&social=create&compose=drafts`

This exact deeper candidate was subsequently founder-approved and frozen as
scoped reference `v2`. The accepted rail remains protected.

## Founder continuous Social batch — 22 July 2026

The founder approved the exact deeper Feed/Create candidate SHA-256
`A38AD64A05425DD36BB0ED89679BADFD14276ED805E33B71C3C907F9260C1B7F`.
It is now immutable scoped reference
`approved-references/screens/04-universal-social-feed-create/v2`. The earlier
`v1` and Shorts/Videos `v1` packages remain untouched.

The founder authorized the remaining Social HTML, isolated native Flutter V2,
automated tests, connected-OPPO replay, fixes and final regressions as one
continuous batch without intermediate founder approval stops. Do not mark
remaining candidate screens founder-approved before the final decision.

The approved plan architecture is Free, Creator Pro, Business Pro, Commerce
Pro and Enterprise. Exact launch-access expiry is mandatory; it cannot silently
start paid renewal. Subscription fees, campaign funding and Creator
Memberships remain separate.

Execution authority and ticket order:
`docs/delivery/SOCIAL-CONTINUOUS-BATCH-EXECUTION-20260722.md`.
Subscription/promotion product contract:
`docs/decisions/ADR-0005-MOOLSOCIAL-PLANS-LAUNCH-ACCESS-AND-SOCIAL-PROMOTION.md`.

No production-cloud enablement, credential work, commit, push, `main` merge or
partial promotion is authorized by this batch.

## Social native V2 candidate handoff — 22 July 2026

The continuous Social batch has reached founder-review handoff. Native Flutter
V2 now covers Social Shorts, Videos, Feed and Create; Creator owners 124–132;
YouTube Connect; plans/access; subscription management; and Social promotion.
The isolated code is under `apps/mobile/lib/ui_v2/social/` and reuses existing
Journey, Creator, Retailer and Shared sessions.

Exact connected-OPPO candidate:

- APK: `artifacts/quality/social-continuous-batch-20260722/oppo/moolsocial-social-v2-device-review-r15.apk`;
- SHA-256:
  `D60945E0E70F4D2B63B7471808E776F59AA3D929357B8A0E789B47FF6EC62475`;
- pulled installed-base hash: identical;
- device: OPPO CPH2375, Android 13, serial `2b3e0f71`; and
- review services: local Firebase emulators with verified ADB reverse and no
  authentication bypass.

The OPPO found and drove correction of Feed production-theme layout, nested
video-detail navigation, the two-layer Creator → YouTube global-rail return,
route-query state reuse, icon accessibility and publishing-failure recovery.
The expanded r14 replay covered every Social/Creator/plan/promotion owner,
Pay handoff, interruption and authenticated process-death return. Final r15
proves that a missing-rights publish failure returns to editable content and
then publishes exactly once.

Final focused gates:

- Social V2 behavior, 69-state parity, fitment and copy: `42/42`;
- first-layer responsive viewport/text-scale matrix: `56/56`;
- locked Screens 01–03: `38/38`;
- approved UI lock: passed;
- analyzer: no issues;
- `git diff --check`: passed; and
- full regressions 1 and 2: each `417/417`, passed.

The initial diagnostic regressions exposed 38 displaced old UI tests and
goldens. They now run against the untouched legacy presentation through an
explicit test-only router mode; production continues to default to V2 and was
confirmed on r15. Do not update those goldens before founder acceptance. Do
not mark this candidate approved, freeze new Flutter references, commit, push
or merge. Exact evidence is in
`artifacts/quality/social-continuous-batch-20260722/SOCIAL-V2-IMPLEMENTATION-AND-OPPO-EVIDENCE.md`.

Complete state and device evidence:
`artifacts/quality/social-continuous-batch-20260722/NATIVE-SOCIAL-69-STATE-PARITY-20260722.md`.

Next founder action: review the installed r15 Social candidate on the OPPO and
state **Accepted** or **Rejected**. Live YouTube Data API/player/publishing is
not claimed by this candidate; the current connected-video flow uses the
review gateway and keeps provider playback separate from MoolSocial commerce.
Creator workspace and plan activation remain owner-session states, not live
server-authoritative subscription or entitlement activation.

## Current override — Screen 04 Social HTML reopened on 22 July 2026

The founder did not accept the r15 native candidate as the final Screen 04
result. New visual and navigation corrections reopened the editable Screen 04
HTML. This section supersedes the previous “next founder action” above.

Current gate:

- edit only
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\04-universal-focus-shell.html`;
- preserve immutable Screen 04 references v1, v2 and v3 and all accepted
  Screens 01–03 files;
- do not change Flutter again until the corrected HTML is shown to the founder
  and explicitly marked `FINAL`;
- the revised Social HTML must keep the approved bottom-rail architecture,
  normalize type and play-control geometry, use supported YouTube metadata and
  unobscured official-player boundaries, and keep Feed posting directly inside
  Feed without another screen; and
- Feed owns the quick update/photo/poll composer; Create owns Reel, carousel,
  detailed-post, draft, audience and scheduling work. All authenticated
  accounts can use both. Creator/Business activation gates only monetisation,
  promotion, attribution, campaigns and external distribution; and
- Shorts creator/content details must remain visible until explicit dismissal;
  long captions expand in place with `More` and collapse with `Less`, without
  advancing the Short or opening another route; and
- MoolSocial Chat direction is recorded in
  `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`. It requires familiar
  full messaging/calling/media/business capabilities in an independent
  MoolSocial design; do not copy WhatsApp trademarks or exact trade dress.

Use the latest UI-CONFORMANCE-003 row in
`docs/quality/QA-024-APPROVED-PROTOTYPE-CONFORMANCE.md` for status. The previous
APK and OPPO evidence remain preserved diagnostic history, not current founder
acceptance.

Current founder-review HTML SHA-256 is
`5C18839F19DCB21982453A908BA96B75986B7ABCD963346F85BF765A44429A8D`.

## Current override — Screen 04 Gate 0 v5 accepted on 22 July 2026

This section supersedes the earlier reopened/pending Screen 04 instructions.

- Founder-approved immutable authority:
  `approved-references/screens/04-universal-focus-shell/v5`.
- Exact accepted HTML SHA-256:
  `B4A7F6B91A1F488EC5BA78D2A84379316EE9FD918264715C0BE1ED11F78A459A`.
- The founder explicitly authorized isolated native Flutter V2 implementation.
- The accepted Create surface owns Reel, Carousel and Post. Post owns Image,
  Image Poll, Quick Poll and Quiz. Owned long-form Video remains excluded.
- Native Flutter must use existing non-UI Social, Creator and shared-session
  owners. Do not import or modify legacy presentation and do not touch accepted
  Screens 01–03.
- Each published Reel, Carousel, Post, Image Poll, Quick Poll and Quiz must
  render as a complete public item built from customer-authored session data;
  blank or hard-coded result cards are not acceptable.
- Native acceptance is still pending identical-viewport comparison, complete
  interaction replay, exact installed-APK evidence and founder review on the
  connected OPPO.
- Real YouTube integration remains Gate 3 and begins in Dev/Trial only after
  the native Gate 2 founder acceptance.

## Current native correction — direct Create composer on 22 July 2026

The founder directed an additive Flutter-only Create interaction correction
during OPPO review. Preserve all earlier Gate 0 v5 and public-publication work.

- Remove the preliminary Reel/Carousel/Post selector from the visible Create
  surface.
- Keep one immediately writable public composer with Image, Carousel, Image
  Poll, Quick Poll, Reel and Quiz actions.
- Image and Carousel invoke their native pickers directly. Polls and Quiz edit
  inline. Reel exposes Camera and Gallery inline, without a replacement page.
- Keep all six published public states session-owned and data-driven.
- Keep all four Social rail choices visible without broken words; do not show
  an empty content-library placeholder.
- Re-run analyzer, public-publication tests, named-state parity, Screen 04
  navigation, copy, 100%/140% fitment and connected-OPPO evidence before
  requesting founder acceptance.

## Current HTML gate — progressive Social Videos, 22 July 2026

The founder supplied an additive current-mobile behavioral reference for
Social Videos. The editable Screen 04 HTML now contains discovery → watch →
Description → channel progression. It passed 337/337 checks across the seven
required viewports at 100% and 140% text with no overflow, clipped action,
undersized target or console/page error.

Exact founder-review URL:
`http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability&social=videos`

Current editable HTML SHA-256:
`A3447563C99153041FED783ADEF5210B990B638710D8658371204C15796D3724`

Evidence:
`artifacts/quality/screen04-video-progressive-html-20260722/FOUNDER-REVIEW-EVIDENCE.md`

Do not freeze this Videos revision or change Flutter Videos until the founder
marks this exact HTML state `FINAL`. The earlier native Create/publication work
remains intact. The latest direct-Create APK is built but was not installed
after the OPPO disconnected; do not claim otherwise.

## Current pending correction — Social Videos navigation and mobile parity, 23 July 2026

The founder rejected the visible `← Videos` page pill and stated that the
current Videos candidate does not yet match the low-effort mobile behavior in
the supplied YouTube references. Add this to the active pending list; it
supersedes any reading that the progressive Videos HTML is ready for `FINAL`.

Required next HTML revision:

- remove the visible Videos back pill;
- use native Back/gesture and contextual close behavior with exact discovery,
  watch, Description and channel state restoration;
- keep search/topic discovery and video choices immediately available;
- open the selected video in one tap, then progressively reveal the supported
  public details and channel record without additional decorative pages;
- preserve required YouTube attribution and the unobscured official-player
  boundary while using independent MoolSocial branding rather than copying
  YouTube trademarks, proprietary icons or exact trade dress;
- preserve all accepted Screen 04 rail, Shorts, Feed, direct Create and public
  publication behavior; and
- repeat the Social type-scale, broken-word, clipping, blank-space, navigation,
  fitment and customer-copy audits before Flutter parity work resumes.

No new HTML checksum is approved, frozen or authorized for Flutter by this
record.

## Current override — Screen 04 Social v7 native candidate, 23 July 2026

This section supersedes the pending Screen 04 correction immediately above.

- Immutable HTML authority:
  `approved-references/screens/04-universal-focus-shell/v7`.
- HTML SHA-256:
  `DBD9C3D20F230533E8513536E6BA2B4BDDBBB4AECF509C77265187FFDFF5E72F`.
- HTML audit: 897/897 across seven phone viewports at 100% and 140% text.
- Native Screen 04 Social r2 is implemented and verified on the connected OPPO
  CPH2375. It is awaiting founder `Accepted` or `Rejected`; do not describe it
  as founder-accepted.
- Exact review APK:
  `artifacts/quality/screen04-social-final-mission-20260723/moolsocial-screen04-social-v7-device-review-r2.apk`.
- Exact candidate and OPPO-installed-base SHA-256:
  `70A596D24D9DA659CAC51A5452A96C6A739C5B0BBBEA5BAE84E4D8F91A7CFF4C`.
- Affected Social tests: 73/73 passed.
- Full regression 1: 448 passed, two historical capture jobs skipped.
- Full regression 2: 448 passed, the same two jobs skipped.
- `flutter analyze`: no issues.
- Approved Screens 01–03 lock: passed after the final correction.
- Complete evidence:
  `artifacts/quality/screen04-social-final-mission-20260723/FINAL-NATIVE-CANDIDATE-EVIDENCE.md`.

The OPPO replay covers Shorts persistence/progression/filters; Videos discovery,
watch, Description, channel and exact Back restoration; Feed filters and
session-owned posting; direct Camera/Gallery/Carousel picker returns; Image
Poll, Quick Poll and Quiz; truthful library tabs; Chat return; all main-action
rail progression; deep sub-action Back/forward; app-switch/resume; and
authenticated force-stop/restart.

Do not merge or partially promote this checkpoint to `main`. The next product
decision is founder review of the installed r2 candidate. Live YouTube provider
integration remains Gate 3 in `moolsocial-dev-503018` after native acceptance.

## Current override — Screen 04 Social v8 final native candidate, 23 July 2026

This section supersedes the v7 candidate record immediately above. Preserve v7
as immutable rejected history; do not overwrite or delete it.

- Branch: `remediation/prototype-conformance-2026-07-20`.
- Verification HEAD: `725c84607a3ec532bf3eb653e93ee55c78693cdc`.
- Immutable HTML authority:
  `approved-references/screens/04-universal-focus-shell/v8`.
- HTML SHA-256:
  `0997F3AD7ADAAD76EB3FD7F5A96CF63C1D691413DA92F368FC4EC005E0D86410`.
- HTML audit: 1023/1023 across seven phone viewports at 100% and 140% text.
- Final native review APK:
  `artifacts/quality/screen04-social-v8-mission-20260723/moolsocial-screen04-social-v8-final-device-review.apk`.
- Exact candidate and OPPO-installed-base SHA-256:
  `37F8E3718E4E7A53D1DB8949B4D1A14D3C6D77039DB5841442F020CBB07C09A1`.
- Both APK files are 208,494,800 bytes and byte-identical.
- Affected Social suite: 91/91 passed.
- Full regression 1: 448 passed, three superseded capture jobs skipped.
- Full regression 2: 448 passed, the same three jobs skipped.
- `flutter analyze`: no issues.
- Approved Screens 01–03 lock, 153-route interaction gate, Social copy gate
  and HTML copy gate passed.
- Complete evidence:
  `artifacts/quality/screen04-social-v8-mission-20260723/FINAL-NATIVE-CANDIDATE-EVIDENCE.md`.

The final OPPO replay covers compact Videos search; filtered discovery; Watch,
Description and channel progression; exact three-step Back without a keyboard
or extra Back; normalized channel metrics; thumb-zone Feed posting and keyboard
dismissal; direct Create and system-picker returns; persistent Shorts details,
swipe and all four filters; Chat return; automatic main/sub-action rail reveal;
app switch/resume; and authenticated force-stop/restart.

The exact final APK is installed on OPPO CPH2375 and left on Social Videos for
founder review. This is a verified native candidate, not founder native
acceptance. Await explicit `Accepted` or `Rejected`. Do not merge, commit, push
or partially promote to `main`. The founder deferred points 10–18 until the
next review. Live YouTube/provider work remains Gate 3 Dev/Trial work after
native acceptance.

## Current override — Screen 04 Social v9 founder correction, 23 July 2026

The founder reopened Screen 04 Social before accepting the installed v8 native
candidate. Preserve immutable HTML v8, the byte-identical installed APK and all
existing evidence; none is overwritten or deleted. v8 is no longer the active
acceptance candidate while the v9 correction is open.

Active authority:

- ticket pack:
  `docs/delivery/SCREEN-04-SOCIAL-FOUNDER-CORRECTION-TICKETS-20260723.md`;
- Reels owns a compact top-left expandable Reel/creator search and a separate
  contextual `+` that opens direct Camera/gallery creation and editing;
- Feed owns the lower thumb-zone `+` and direct composer for Photo/GIF,
  Carousel, Existing Reel, Image Poll, Quick Poll and Quiz;
- no general Feed or MoolSocial-owned long-form video upload is added;
- visible Create is removed only after all responsibilities, old entries and
  state/navigation contracts have compatible owners and passing proof; and
- Instagram/X screenshots are interaction references only. Do not clone
  provider trade dress, marks, icons, colours or exact layouts.

Current gate: write and verify a new editable HTML candidate, then present its
exact URL and checksum for explicit founder `FINAL`. Do not update approved
references or the manifest, and do not modify Flutter or native tests under
this ticket intake. `FND-NATIVE-014` remains blocked until the new HTML is
founder-final and frozen as a separate immutable version.

## Current override — YouTube API-first provider proof, 23 July 2026

This section supersedes only the immediate next action in the v9 correction
record above.

- Stop Screen 04 HTML and Flutter work. Keep v9 `DRAFT / HOLD`.
- Perform YouTube provider analysis and Dev/Trial proof before revising the
  Shorts/Videos HTML again.
- Governing decision:
  `docs/decisions/ADR-0006-YOUTUBE-API-FIRST-SOCIAL-INTEGRATION.md`.
- Capability authority:
  `docs/delivery/YOUTUBE-API-CAPABILITY-AND-ENDPOINT-MATRIX-20260723.md`.
- Execution backlog:
  `docs/delivery/YOUTUBE-INTEGRATION-PREPARATORY-TICKETS-20260723.md`.
- Do not alter immutable v8, the approved manifest, Screens 01–03, Flutter UI
  or native acceptance evidence during the provider spike.
- Live service target is `moolsocial-dev-503018` only.
- The founder authenticated Google Cloud Console and enabled only
  `youtube.googleapis.com` and `youtubeanalytics.googleapis.com` in
  `moolsocial-dev-503018` on 23 July 2026. Successful operation:
  `operations/acat.p2-760290687711-a9ca0f31-b826-4955-8486-7e66dc423ca2`.
- `youtubereporting.googleapis.com` remains deferred. No API key, OAuth client
  or refresh token has been created. Local Firebase CLI still requires
  reauthentication only if that CLI becomes necessary.
- Never receive a password, OTP, recovery code, API key or OAuth secret from
  the founder. Leave Google's own verification surface for founder entry.

After provider proof: revise the editable Screen 04 HTML to the observed API
contract, obtain explicit founder `FINAL`, freeze a new immutable version, then
resume native parity and OPPO acceptance. Do not bypass that order.

Cost gate:

- durable authority:
  `docs/delivery/YOUTUBE-MOOLSOCIAL-PRODUCT-AND-COST-MAP-20260723.md`;
- official YouTube playback/direct upload are selected to avoid MoolSocial
  video storage, transcode and delivery cost;
- the integration still has backend, OAuth/token-security, analytics,
  monitoring, moderation, support and compliance cost;
- public YouTube watching is never paywalled;
- charge only for independent MoolSocial campaign, commerce, workflow,
  analytics, payout, team or explicitly selected managed-media value; and
- keep Google Ads, managed media and every other external/material-spend
  feature disabled until a named payer, price, budget and automatic cutoff are
  approved.

## Deferred Workspace Google integrations — 23 July 2026

Research only; not current execution:

- Merchant API and Google Ads Demand Gen belong under a selected verified
  Creator/Business Workspace, not Screen 04 or public Social.
- Durable decision:
  `docs/decisions/ADR-0007-GOOGLE-COMMERCE-AND-PAID-GROWTH-WORKSPACE-BOUNDARY.md`.
- Future backlog:
  `docs/delivery/GOOGLE-COMMERCE-AND-DEMAND-GEN-WORKSPACE-BACKLOG-20260723.md`.
- Merchant API, Google Ads API, provider credentials, advanced-account
  requests, developer-token access and media spend remain untouched.
- The active next action remains the private Dev YouTube provider proof.

The YouTube compliance/quota proposal is prepared at
`docs/delivery/YOUTUBE-API-COMPLIANCE-QUOTA-VALUE-PROPOSAL-20260723.md`.
Submit it only after truthful private Dev evidence exists; the official route
is YouTube's API Services Audit and Quota Extension Form, not an ordinary
email.

## Local YouTube provider foundation checkpoint — 23 July 2026

- Privileged Functions provider, provider-only Data Connect ownership,
  encrypted token/session custody, OAuth PKCE, public metadata client,
  private-only resumable upload initialization, owner Analytics, redaction,
  cache and atomic quota guards are implemented.
- `npm run verify` passed with 50/50 tests.
- The non-UI Flutter private-Dev provider client passed targeted analysis and
  23/23 platform/provider tests. Its App Check activation is compile-time
  gated to `moolsocial-dev-503018`; no Screen 01–04 UI or route changed.
- A fresh isolated Data Connect generation run passed against the current
  connection-gated publication mutations:
  `artifacts/quality/youtube-provider-schema-validation-20260723-05/SCHEMA-VALIDATION-EVIDENCE.md`.
- Local Functions, Authentication and Data Connect emulators started
  together.
- `capabilities` returned all provider capabilities disabled.
- `publicMostPopular` returned HTTP 503 `capability_disabled` before service
  construction or provider quota use.
- Evidence:
  `artifacts/quality/youtube-provider-private-dev-20260723-02/LOCAL-PROVIDER-FOUNDATION-EVIDENCE-02.md`.
- No live credential, OAuth grant, API result, upload or Analytics result is
  claimed.
- Google Cloud reauthentication and read-only inventory are complete.
- The Dev project is ACTIVE, has no billing account attached, and contained
  only a Firebase Browser key restricted to Firebase APIs. The fixed Android
  app `com.moolsocial.app` is now registered. The App Check and Play Integrity
  APIs are enabled.
- The founder accepted Google's terms and Play Integrity is registered for the
  verified Dev APK signing fingerprint. The remaining server services could
  not be enabled because billing is not attached; the failed request created
  no workload.
- The founder explicitly authorized Dev billing attachment under the recorded
  cost controls. The intended organisation billing account is visible, but a
  direct Cloud Billing describe reports `open: false`; the console states that
  its required prepayment can take up to 24 hours to be credited. Link only
  after Google reports the account open.
- Cloud evidence:
  `artifacts/quality/youtube-private-dev-cloud-bootstrap-20260723-01/CLOUD-BOOTSTRAP-EVIDENCE.md`.
- Next action: wait until Google reports the authorised organisation billing
  account `open: true`; it currently remains closed while the required
  prepayment credit is pending. Then link **only**
  `moolsocial-dev-503018`, establish project-scoped budget/cost guardrails,
  enable the minimum server prerequisites and deploy with every YouTube
  capability flag still off. Blaze linkage has no fixed subscription fee, but
  the eligible SQL Connect trial is limited to three months and the underlying
  Cloud SQL database is the eventual cost floor. Restricted credentials and
  the supervised public-data, official-player, owner-OAuth, private-upload,
  Analytics, revoke/delete and quota-stop proofs follow as separately gated
  steps.
- Do not resume Screen 04 HTML or Flutter work until the provider-observed
  contract has been recorded and founder-review sequencing resumes.

## Private Dev readiness hardening — 24 July 2026

- The founder authorized billing attachment for **only**
  `moolsocial-dev-503018` under the recorded controls.
- Google still reports the intended organization billing account
  `open: false`; the Dev project remains unlinked and no paid workload,
  credential or deployment was created.
- Both isolated provider Functions now explicitly use `minInstances: 0`,
  `maxInstances: 1` and `concurrency: 1`.
- Capability flags can activate only under the explicit Dev profile in the
  exact Dev project. Dev quota overrides may lower, but cannot exceed,
  search/upload/batch-stats/general ceilings of `20/10/500/2000`.
- The non-UI Flutter client now fails closed outside the explicit private-Dev
  proof gate, validates the exact Dev endpoint, hardens resumable-session URLs
  and confirms a final full-range `308` before declaring completion.
- Backend verification passed 56/56 tests. Targeted Flutter analysis passed
  and the private-Dev client passed 22/22 tests. Fresh isolated Data Connect
  generation, approved UI locks, credential scanning and diff hygiene passed.
- No Screen 01–04 UI, route or accepted reference changed.
- Machine gate:
  `scripts/check-youtube-private-dev-preflight.ps1`.
- Durable audit:
  `artifacts/quality/youtube-private-dev-readiness-20260724-01/PRIVATE-DEV-READINESS-AUDIT.md`.
- Do not link billing until Google reports the authorized account open. Then
  link only Dev, create project-scoped budget controls, enable minimum server
  prerequisites and deploy with every capability still off.

## Current override — cost-first Firestore YouTube control plane, 24 July 2026

This is the active private-Dev architecture and supersedes earlier handoff
language that identified Data Connect/Cloud SQL as the YouTube provider's live
deployment target.

- Active persistence is one Cloud Firestore Standard edition, Native mode
  `(default)` database in `asia-south1`.
- Delete protection is on. PITR, TTL policies, backups, backup schedules and
  direct mobile/web provider-record access are off.
- Firestore stores only encrypted connection/control state, idempotency,
  quota and redacted audit records. It never receives YouTube video bytes.
- YouTube serves embedded playback. The Dev upload path sends phone media
  directly to Google's resumable-upload URL.
- Data Connect/Cloud SQL adapters remain preserved for later relational
  product domains, but `firebasedataconnect.googleapis.com` and
  `sqladmin.googleapis.com` remain disabled and no Cloud SQL instance is
  provisioned by this proof.
- Firestore's free quota removes an always-on database cost floor for a small
  controlled proof, but is not a zero-cost guarantee. Functions, Firestore,
  secrets, artifacts, logs, App Check and operations remain metered after
  their allowances.
- MoolSocial-owned long-form video storage and native Reel media hosting are
  not part of this private MVP deployment.
- Deploy only `functions:provider:youtubeProvider` and
  `functions:provider:youtubeOAuthCallback`; both use
  `youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com`.
- The runtime identity receives only Datastore User, App Check token verifier
  and accessor on each exact provider secret. The deployer separately needs
  `iam.serviceAccounts.actAs` on that identity.
- All capability flags remain false. `20/10/500/2000`
  search/upload/batch-stats/general provider caps, one maximum Function
  instance and one-day Functions artifact retention remain required. Those
  caps are not a global Cloud Billing limit.
- Enable governance APIs and verify the exact monthly project budget before
  workload APIs. A first Functions deployment is expected to create its
  source bucket, Cloud Build execution, `gcf-artifacts` repository and
  Eventarc/Pub/Sub identities only in the exact Dev project/region.
- If `(default)` Firestore already exists with the wrong location, mode,
  edition or protection, stop. Never delete/recreate it or create a second
  database under this workflow.
- Screen 04 remains `DRAFT / HOLD`; no UI, route, approved reference or locked
  Screen 01–03 artifact changes.

Physical OPPO proof has an unresolved App Check gate. The client uses
`AndroidPlayIntegrityProvider`; a USB/sideloaded APK is not Play-licensed or
`PLAY_RECOGNIZED` by default. Before claiming OPPO readiness, the exact Dev
registration must use `allowUnrecognizedVersion=true`,
`requireLicensed=false` and
`minDeviceRecognitionLevel=MEETS_DEVICE_INTEGRITY`, with the expected Dev
SHA-256 registered and no App Check debug token present. A debug-provider
build/token is deferred and not implemented. Fingerprint registration alone
is not proof.

Exact decision and sequence:

- `docs/decisions/ADR-0008-YOUTUBE-PRIVATE-DEV-FIRESTORE-COST-FIRST-CONTROL-PLANE.md`
- `docs/delivery/YOUTUBE-PRIVATE-DEV-POST-PAYMENT-EXECUTION-20260724.md`
- `docs/delivery/YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md`

Next external action: wait until billing account
`01F9D3-44031C-B5E225` reports `open: true`, then follow the exact post-payment
sequence for only `moolsocial-dev-503018`. Do not resume Screen 04 UI work from
this backend checkpoint.

## Current override — Dev billing linked; security-first deployment gate, 24 July 2026

This section supersedes the billing and deployment-next-action language above.
It does not alter the Screen 04 `DRAFT / HOLD` boundary.

- Billing account `01F9D3-44031C-B5E225` now reports open and is linked only to
  `moolsocial-dev-503018`.
- The exact founder-approved `INR 1,000` monthly project-scoped alert is live
  with 50%, 80% and 100% thresholds. It is not a hard spending cap;
  application-side hard stops remain mandatory.
- The local Windows environment has no `gcloud`. Use the
  founder-authenticated Google Cloud Shell for required cloud inventory or
  mutation; never copy its credentials/session material into the repository.
- Run the read-only
  `scripts/check-youtube-private-dev-security-prerequisites.ps1` gate before
  any cloud mutation. There is no App Check debug-token exception.
- The runtime service account is keyless and must retain zero user-managed
  keys. Its exact IAM grants remain mandatory because Firestore Rules do not
  constrain Admin SDK/privileged server access.
- Firestore provisioning must report `freeTier: true`. Stop otherwise.
- Enable `firebaserules.googleapis.com`. The only three deployment targets are
  `functions:provider:youtubeProvider`,
  `functions:provider:youtubeOAuthCallback` and `firestore:rules`.
- `backend/firestore/youtube-private-dev.rules` is the sole rules source and
  denies every client read/write. Post-deploy verification must fetch the
  active `cloud.firestore` release and referenced ruleset through the Firebase
  Rules REST API and prove the active sole source exactly matches that file.
- Current YouTube project/day buckets are 100 `search.list`, 100
  `videos.insert`, 10,000 `videos.batchGetStats` and 10,000 general Data API
  units. Private-Dev application caps remain 20/10/500/2000 for
  search/upload/batch-stats/general.
- Later connected comment/rate/subscribe/playlist writes generally cost 50
  general units and require `youtube.force-ssl` plus explicit in-context
  consent. They are not in the current readonly/upload/analytics proof.
- The approved API contract does not expose personalized YouTube Home/native
  recommendations, watch history, Watch Later or an authoritative public
  Shorts resource/`isShort` field. Do not clone or claim them.
- The official YouTube IFrame Player inside the isolated OS
  WebView/WKWebView is the sole compliant playback route. MoolSocial UI remains
  native and outside the player.
- Private uploads remain private. Public or unlisted publication is forbidden
  until the applicable YouTube compliance audit/approval.

Current execution order: complete founder-owned OAuth consent/legal/test-user
inputs and the Web OAuth client; pass preflight and security-prerequisite
gates; deploy exactly the two provider Functions plus `firestore:rules` with
every capability off; verify the active Rules release/ruleset; then enter the
supervised provider gates in the authoritative private-Dev runbook. Budget,
prerequisite services, the keyless runtime identity, Firestore, the restricted
server key and both encryption-key secrets are already verified.

## Current override — YouTube-centred Screen 04 authorized, 24 July 2026

The founder supplied evidence of a successful INR 3,000 Google Cloud payment
and authorized Screen 04 Social to be materially adapted, after provider proof,
so that YouTube becomes a primary MoolSocial engagement centre.

- Cloud Shell already reports billing account `01F9D3-44031C-B5E225` open and
  linked only to `moolsocial-dev-503018`.
- The payment is not the monthly Dev budget alert. On 24 July 2026 the founder
  separately approved a monthly private-Dev alert of `INR 1,000`, with the
  reviewed 50%, 80% and 100% current-spend thresholds. This is an alert, not a
  hard cloud spending cap.
- The matching project-scoped live budget now exists as the only budget on the
  authorized billing account. Evidence:
  `artifacts/quality/youtube-private-dev-budget-20260724-04/LIVE-BUDGET-EVIDENCE.md`.
- The reviewed prerequisite/provider APIs are enabled and the deferred Data
  Connect, Cloud SQL Admin and YouTube Reporting APIs remain disabled.
  Evidence:
  `artifacts/quality/youtube-private-dev-api-prerequisites-20260724-05/LIVE-API-PREREQUISITE-EVIDENCE.md`.
- Finish permitted backend/provider contracts and private Dev proof first.
- Then revise the editable Screen 04 HTML from observed API behavior and
  present it for founder review.
- The founder has removed prior editable Screen 04 layout constraints for this
  next candidate. Provider proof may justify changing the earlier rail,
  hierarchy, entry state or sub-action placement, provided Mool, Chat,
  YouTube-centred Videos/Shorts and MoolSocial Feed/Create remain discoverable
  and the whole changed journey returns for founder `FINAL`.
- Do not freeze a new Screen 04 reference or change Flutter presentation until
  the founder marks that exact HTML state `FINAL`.
- Preserve Screens 01–03 and all immutable Screen 04 checkpoints.
- Do not claim personalized YouTube Home, YouTube ranking, Watch History,
  Watch Later or an authoritative public Shorts feed.
- Keep YouTube identity, unmodified metadata, player controls, ads and required
  links visible. MoolSocial-native Feed, commerce, attribution, campaigns,
  earning and workspace tools supply the independent product value.

The authorized workspace now has a verified portable Google Cloud CLI at
`C:\GUARANTEED OUTCOME\.tools\google-cloud-sdk` and an isolated unauthenticated
configuration at `C:\GUARANTEED OUTCOME\.gcloud-moolsocial`. Never use the
unrelated default Windows gcloud configuration or copy Cloud Shell
credentials. Continue cloud administration through the authenticated Cloud
Shell unless the founder performs a fresh provider-owned login into the
isolated configuration.

## Current override — Dev App Check off-Play contract applied, 24 July 2026

The founder-authenticated Cloud Shell read and corrected the exact Firebase
App Check Play Integrity configuration for Android app
`1:760290687711:android:4202409fd3ab38f6ce076a`.

- token TTL is `3600s`;
- `appIntegrity.allowUnrecognizedVersion = true`;
- `deviceIntegrity.minDeviceRecognitionLevel = MEETS_DEVICE_INTEGRITY`;
- `accountDetails.requireLicensed` is absent and therefore remains the
  documented effective default `false`;
- a paginated REST inventory reports exactly zero App Check debug tokens and
  no next page; and
- the paginated service inventory contains only
  `identitytoolkit.googleapis.com`, with baseline protection `UNENFORCED` and
  replay protection off; no Firestore service configuration was returned; and
- App Check enforcement has not been enabled by this configuration patch.

The initial live read exposed `NO_INTEGRITY`; that value is superseded by the
verified patched response. Physical OPPO attestation, missing/invalid/expired
token rejection, replay protection and endpoint enforcement are still pending.
Do not describe registration or this configuration patch alone as complete
App Check proof.

The comprehensive provider gap audit is durable at
`docs/delivery/YOUTUBE-COMPREHENSIVE-CAPABILITY-GAP-AUDIT-20260724.md`.
It confirms that the implemented public catalogue and owner P1 contracts remain
the correct order. The next two provider contracts are the official embedded
player runtime and WebSub refresh for approved channels. Personalized YouTube
Home, native Shorts, Watch History, Watch Later and the provider notification
inbox remain unsupported.
The binding contracts are
`docs/delivery/YOUTUBE-EMBEDDED-PLAYER-RUNTIME-CONTRACT-20260724.md` and
`docs/delivery/YOUTUBE-WEBSUB-APPROVED-CHANNEL-REFRESH-CONTRACT-20260724.md`.

The founder also authorized Screen 04 to become YouTube-centred without a
layout-preservation constraint. The provider and policy constraints remain
mandatory. The durable next-candidate contract is
`docs/delivery/SCREEN-04-YOUTUBE-CENTRED-INTERACTION-CONTRACT-20260724.md`.
Screen 04 v9 remains `DRAFT / HOLD`; no new freeze or Flutter presentation
change is authorized until provider proof, revised HTML review and founder
`FINAL`.

The corrected public-catalogue and owner P1 server contracts independently
pass `116/116` backend tests and the full private-Dev package gate. Evidence is
at
`artifacts/quality/youtube-provider-schema-validation-20260724-08/PUBLIC-OWNER-P1-VERIFICATION-EVIDENCE.md`.
This is local contract proof only; live cloud/provider, player, WebSub, revised
HTML, Flutter and OPPO gates remain open.

The read-only Dev cloud inventory is at
`artifacts/quality/youtube-private-dev-readiness-20260724-03/READ-ONLY-CLOUD-INVENTORY.md`.
It confirms billing is linked and the live YouTube quotas are present, but
Firestore, workload APIs, provider secrets and the dedicated runtime identity
remain absent. No cloud service was enabled.

## Current override — local player and WebSub foundations verified, 24 July 2026

The next two API-first contracts now have disabled, isolated local
implementations:

- official-player typed contract/bootstrap/controller with one exact-origin
  transferred `MessagePort`, one-player lifecycle and no unsafe JavaScript
  object bridge; and
- approved-channel WebSub contract/security/Atom libraries with exact raw-body
  HMAC, bounded fail-closed XML parsing, idempotency, lease planning and an
  isolated refresh-quota reservation plan.

Independent results:

- Flutter player plus private-Dev client: `47/47`;
- backend including `37` WebSub cases: `153/153`;
- player analysis: no issues;
- forbidden runtime bridge scan: zero matches;
- WebSub export/activation scan: zero matches;
- `git diff --check`, package gate and Screens 01–03 locks: passed.

Evidence:

- `artifacts/quality/youtube-embedded-player-local-20260724-01/LOCAL-PLAYER-FOUNDATION-EVIDENCE.md`
- `artifacts/quality/youtube-websub-local-20260724-01/LOCAL-WEBSUB-FOUNDATION-EVIDENCE.md`

Neither result is live provider proof. No Android/iOS player adapter, WebSub
endpoint, cloud activation, Screen 04 revision, Flutter presentation change or
OPPO provider acceptance is claimed. The founder-approved monthly Dev alert is
`INR 1,000`; its exact live budget is created and verified. The approved WebSub
channel registry remains separately required before WebSub activation.

## Current override — keyless YouTube runtime identity verified, 24 July 2026

The dedicated private-Dev runtime identity now exists in
`moolsocial-dev-503018`. A fresh live inventory returned only
`roles/datastore.user` and `roles/firebaseappcheck.tokenVerifier` for that
identity, zero user-managed keys, and one service-account-scoped
`roles/iam.serviceAccountUser` binding for the reviewed founder-domain
deployer. No broad project role or key-file shortcut was used.

Evidence:
`artifacts/quality/youtube-private-dev-runtime-identity-20260724-06/LIVE-RUNTIME-IDENTITY-EVIDENCE.md`.

This is an IAM prerequisite, not a deployed or activated provider. Firestore,
secrets, restricted credentials, disabled Functions, live player/provider
proof, revised Screen 04 HTML, Flutter presentation and OPPO acceptance remain
open.

## Current override — cost-first Firestore boundary live, 24 July 2026

The exact Dev project now contains one Firestore Standard Native `(default)`
database in `asia-south1`. It is free-tier eligible, delete-protected, has PITR
disabled, and has zero TTL policies, backup schedules and retained backups.
It is reserved for encrypted provider control state and never stores video
bytes.

Evidence:
`artifacts/quality/youtube-private-dev-firestore-20260724-07/LIVE-FIRESTORE-EVIDENCE.md`.

No `cloud.firestore` Rules release existed immediately after creation. The
exact repository deny-all source and active release/ruleset verification remain
mandatory before any endpoint or capability activation. Functions, secrets,
restricted credentials and live provider proof remain open.

## Current override — restricted server and encryption secrets live, 24 July 2026

The exact-name inventory returned one private-Dev server API key, UID
`08aabcbf-8716-4974-adf9-62de98c9e125`, restricted only to
`youtube.googleapis.com`. Its value was transferred directly inside Cloud
Shell to `YOUTUBE_SERVER_API_KEY`; the secret has one enabled version and one
runtime-identity accessor binding.

Two distinct 32-byte cryptographically random token-encryption values were
generated inside Cloud Shell, length- and inequality-checked, and transferred
without display to `YOUTUBE_TOKEN_ENCRYPTION_KEY_V1` and
`YOUTUBE_TOKEN_ENCRYPTION_KEY_V2`. Each secret has one enabled version and one
runtime-identity accessor binding.

The founder's `INR 1,000` monthly budget alert was re-read unchanged with
50%, 80% and 100% thresholds. It remains an alert, not a hard spend cap.

Evidence:
`artifacts/quality/youtube-private-dev-restricted-secrets-20260724-08/LIVE-RESTRICTED-SECRETS-EVIDENCE.md`.

OAuth is still blocked: `YOUTUBE_OAUTH_CLIENT_ID` and
`YOUTUBE_OAUTH_CLIENT_SECRET` remain absent and no placeholder exists. The
founder-owned consent/legal/support URLs, exact test users, dedicated Dev
YouTube channel and Google-created Web OAuth client are required next.
Firestore deny-all Rules, Functions, Cloud Run, provider capabilities,
revised Screen 04 HTML, Flutter presentation and OPPO provider proof remain
undeployed.

## Active execution override — OPPO public-viewing proof first, 25 July 2026

The immediate acceptance target is now deliberately smaller than the complete
YouTube integration:

- keep the accepted Screen 04 native presentation unchanged;
- install the exact Dev APK on OPPO serial `2b3e0f71`;
- prove genuine Play Integrity-backed Firebase App Check with zero debug
  tokens;
- enable only `PublicData` for one short-lived supervised proof;
- prove real eligible public YouTube catalogue data and official embedded
  playback on the physical OPPO; and
- automatically return all seven proof profiles to disabled and preserve the
  rollback evidence.

Do not activate or expose `OwnerConnect`, `OwnerActions`, `CreatorAssets`,
`Live`, `PrivateUpload` or `OwnerAnalytics` during this milestone. Creator
connect, publishing, Analytics/Reporting and upload resume only after founder
acceptance of the OPPO public-viewing proof. `PrivateUpload` also remains
independently blocked until a server-revocable upload gateway replaces the raw
resumable-session URL boundary.

Before removing hard containment or activating `PublicData`, fix and prove the
warm-instance expiry defect: a Functions instance that was created while the
proof profile was valid must re-read capability state on every subsequent
request and fail closed at or after the exact proof expiry.

## Latest override — OPPO public-viewing proof passed, 25 July 2026

The deliberately narrow OPPO public-viewing milestone is complete.

- Valid candidate: `youtube-public-oppo-20260725-04`
- APK and installed-base SHA-256:
  `0A00252A6616C80B5C1147933D2A13FEE5A0F6B5BBE7AA5567C6120D1C3402B4`
- Device: OPPO serial `2b3e0f71`
- App Check: genuine Play Integrity; guarded provider requests accepted
- Active profile: only `PublicData`
- Customer proof: real eligible public catalogue plus official embedded
  YouTube playback in the accepted Screen 04 presentation
- Completion signal: `2026-07-25T15:24:56.9833541Z`
- Automatic Disabled rollback verified:
  `2026-07-25T15:30:12.8308625Z`

Run 10 passed all `267` backend tests, the `120`-file content gate, deployment
package checks, Disabled preflight, PublicData verification, and the final
Disabled post-deployment verification. The post-rollback app launch again
showed the safe-unavailable Videos state while the guarded Disabled revision
accepted App Check with HTTP `200`.

Durable evidence and hashes:
`artifacts/quality/youtube-private-dev-oppo-public-viewing-20260725-01/PUBLIC-DATA-PLAYBACK-PROOF-10.md`.

All seven private-Dev proof profiles are disabled. Do not reactivate another
profile or resume creator connect, publishing, Analytics/Reporting or upload
without the next explicit founder decision. The next decision is founder
acceptance or rejection of this physical-device public-viewing proof.

## Latest override — persistent public Videos + YouTube Shorts live, 25 July 2026

The founder accepted continuous private-Dev public viewing and explicitly
authorized the Screen 04 changes needed to expose both YouTube Videos and
YouTube Shorts in MoolSocial.

The persistent fail-closed `PublicDataReview` profile is live:

- Dev project: `moolsocial-dev-503018`
- revision: `youtubeprovider-00024-dol`
- `YOUTUBE_PUBLIC_DATA_REVIEW_MODE=accepted`
- `YOUTUBE_PUBLIC_DATA_ENABLED=true`
- Owner Connect, Owner Actions, Creator Assets, Live, Private Upload and Owner
  Analytics: false
- timed proof profile/expiry: absent
- post-deployment verifier: passed, including the App Check guard

Candidate `youtube-shorts-oppo-20260725-06` is installed on founder-authorized
OPPO serial `2b3e0f71`. APK SHA-256:
`5C2E72C6805F40E6A1E574A3543CDE77D816E47FBEB48F7748880C952BC4E31B`.

Physical-device results:

- the real public Videos catalogue remains available;
- Screen 04 Shorts now puts admitted real YouTube Shorts first in `For You`
  and exposes a dedicated `YouTube` filter;
- the YouTube-only filter returned eight real provider items;
- the official portrait player exposed provider controls and
  `Watch on YouTube`;
- explicit playback passed on the first item;
- a vertical swipe loaded the second real Short; and
- the visible-page-only player correction eliminated adjacent player
  lifecycle exceptions.

Admission is not based on duration alone. A YouTube result must have a positive
creator `Short`/`Shorts` declaration in current provider metadata, a duration
of 1–180 seconds, and current public/processed/embeddable/India-available
status. Owner Analytics `creatorContentType=SHORTS` remains the stronger future
classifier for connected creator-owned inventory.

Verification:

- focused public runtime, Screen 04 and official-player tests: `63/63`
- changed Flutter analysis: no issues
- backend suite from the persistent deployment source: `269/269`
- latest twenty app/provider POST requests: HTTP `200`
- deliberate unauthenticated App Check guard probe: HTTP `401`
- Staging and Production: unchanged

The app was deliberately left open on the live YouTube-only Shorts lane for
continued founder play. Durable proof:
`artifacts/quality/youtube-private-dev-oppo-public-viewing-20260725-01/LIVE-PUBLIC-VIDEOS-SHORTS-PROOF.md`.

The editable screenbook founder-review draft is on
`founder-review/youtube-screen04-2026-07-25`; `approved-final` is unchanged.
The private-Dev live Flutter result does not admit a Staging or Production
release. Connected actions, creator assets/upload, Analytics/Reporting and Live
remain behind their separate OAuth, eligibility, consent and provider-proof
gates.

## Latest override — YouTube submission readiness prepared, 25 July 2026

The existing YouTube API compliance/quota proposal is reconciled with the
successful private-Dev public-data, official-player and YouTube Shorts proof.
The exact readiness register is:

`artifacts/quality/youtube-api-submission-readiness-20260725-01/SUBMISSION-READINESS-AUDIT.md`.

Current determination: **prepared but not ready to submit**.

- Public-data access, physical-OPPO official playback, App Check and the bounded
  real Videos/Shorts surfaces are verified.
- Owner OAuth/channel reconciliation, private upload, owner
  Analytics/Reporting, revocation/deletion, real search/category/pagination,
  live approved-channel WebSub delivery and quota-stop evidence remain open.
- A 14–30 complete-day Preview measurement, numerical quota request,
  reviewer-accessible build/account, public legal/support URLs and
  founder/legal answers/attestations remain mandatory.
- The current dossier targets Dev project number `760290687711`. Because
  YouTube's upload audit is project-specific and MoolSocial will use a separate
  later Production project, no Dev verification/audit/quota decision may be
  represented as Production approval without explicit written
  YouTube/Google treatment.
- Recent eligible uploads may be surfaced through approved-channel upload
  playlists, later live WebSub notifications and bounded
  `search.list(order=date, publishedAfter=...)` topic refreshes. This is
  MoolSocial-selected discovery, not YouTube recommendations, and it cannot
  guarantee every upload or one-minute availability.

No YouTube form, OAuth verification or quota extension was submitted. No cloud
resource, credential, runtime profile, accepted reference, Staging or
Production environment changed.

## Latest founder gate — bounded YouTube audit slice authorized, 25 July 2026

The founder authorized MoolSocial to proceed only with the smallest truthful
YouTube audit-readiness slice using the founder-controlled VetoNews channel.
Comprehensive YouTube development remains prohibited until the exact later
Production project receives written Google OAuth verification, YouTube API
audit and initial quota decisions.

Founder-supplied owner-proof identity:

- channel: `VetoNews`
- handle: `@VetoNewslive`
- canonical channel ID: `UC7rn0BIzhULpyw1NYXh-mWQ`
- owner/test-user Google account: `vetonewslive@gmail.com`

MoolSocial remains the API client. VetoNews is the controlled test publisher,
not a MoolSocial master channel. The authorized slice is owner connection,
exact channel reconciliation, one private upload, minimum owner Analytics,
disconnect/revocation/deletion and bounded quota measurement, in addition to
the already accepted public discovery/player proof. Owner actions,
creator-asset management, Live, monetary Analytics, partner-only operations,
derived metrics and public/unlisted uploads remain excluded.

Durable founder authorization:
`artifacts/quality/youtube-api-submission-readiness-20260725-01/FOUNDER-AUDIT-SLICE-AUTHORIZATION.md`.

Fresh read-only checks made while recording this gate found:

- the two exact Dev Functions active;
- persistent `PublicDataReview` still live;
- every owner/write/analytics capability still false;
- the OAuth client ID and secret attached from Secret Manager without exposing
  either value;
- no connected ADB device;
- the default Firebase Hosting site and `/privacy`, `/terms`, `/support`
  returning HTTP 404; and
- `https://moolsocial.com/` returning HTTP 500.

Therefore no owner profile was activated. The next provider mutation remains a
supervised `OwnerConnect` proof only after founder/legal-approved public URLs,
the allowed OAuth test user, a connected OPPO, and a verified restore path for
the persistent public-review baseline are all present. No Production project,
OAuth verification, YouTube audit or quota form was created or submitted.

## Latest override — VetoNews OAuth test audience prepared, 25 July 2026

The founder reconnected the exact OPPO `2b3e0f71`. The installed
`com.moolsocial.app` base APK SHA-256 is
`5C2E72C6805F40E6A1E574A3543CDE77D816E47FBEB48F7748880C952BC4E31B`,
an exact match to the retained Videos/Shorts candidate.

In Google Auth Platform for `moolsocial-dev-503018`:

- app name: MoolSocial;
- user type/status: External/Testing;
- existing test user: `hello@moolsocial.com`;
- newly authorized test user: `vetonewslive@gmail.com`;
- only configured sensitive scope: `youtube.readonly`;
- public product, Privacy and Terms URLs: absent; and
- verification submission: not started.

Both existing Web OAuth clients use the exact callback. One contains two
enabled secret records and the other contains one. No secret was displayed,
rotated, disabled or deleted. The Secret Manager client ID must be compared in
place before proof so no client is guessed.

Local verification passed:

- static OwnerConnect activation contract;
- static PublicDataReview deployment verifier; and
- targeted Flutter owner/proof/client tests: `48/48`.

Persistent `PublicDataReview` remained live. No owner profile or OAuth flow was
activated. The local workspace Cloud SDK is available, but its only active
credential belongs to unrelated `supermanditech@gmail.com`; the authorized
`hello@moolsocial.com` deployer must explicitly authenticate before any
gcloud-backed proof mutation.

Sanitized evidence:
`artifacts/quality/youtube-api-submission-readiness-20260725-01/LIVE-OAUTH-TEST-CONFIGURATION.md`.

## Latest override — OwnerConnect reached authenticated-app gate, 26 July 2026

The authorized VetoNews OwnerConnect audit slice was attempted on the exact
OPPO after the founder completed fresh `hello@moolsocial.com` Cloud and
Firebase CLI authentication.

Preconditions passed:

- the configured Secret Manager OAuth client matched
  `MoolSocial Dev YouTube Backend 20260725` in place;
- only `youtube.readonly` was configured;
- VetoNews remained an OAuth test user;
- the proof APK built with SHA-256
  `6C69F71DAEA3778B1E98165163BB0629E3C71A773A24669A2DA4DCED363F3462`;
- the APK signing certificate matched the registered Android/App Check
  SHA-256;
- `PublicDataReview` passed its complete verifier;
- the all-disabled baseline passed; and
- the server-expiring `OwnerConnect`-only profile deployed and verified.

The OPPO proof then stopped with `authentication_required` before a
Google/YouTube consent page was launched. A read-only Identity Toolkit request
returned `HTTP 404 CONFIGURATION_NOT_FOUND`, verifying that Firebase
Authentication has not been initialized in the Dev project. The backend's
Firebase-ID-token requirement worked correctly and was not weakened.

The Dev Firebase Android app has zero registered SHA-1 certificates and one
registered SHA-256 certificate. The retained/proof build's signing SHA-1 is
`1E4345AA0707C8A4C74F5485B47B14E911923B46`. Outside review mode, the existing
Flutter gateway already maps Google and YouTube login to
`GoogleAuthProvider` and invokes Firebase `signInWithProvider`, so the
recommended next path is Dev Firebase Auth initialization, registration of
this existing SHA-1, Google-provider enablement and OPPO verification rather
than a new Screen 04 design.

No YouTube OAuth grant, refresh token, exact-channel reconciliation, upload or
Analytics request occurred. The completion signal triggered the automatic
all-disabled rollback, which passed. Persistent `PublicDataReview` was then
redeployed and passed its full verifier. Owner Connect, Owner Actions, Creator
Assets, Live, Private Upload and Owner Analytics are all disabled.

The retained r6 Videos/Shorts APK was reinstalled on OPPO `2b3e0f71`; its
installed SHA-256 again matches
`5C2E72C6805F40E6A1E574A3543CDE77D816E47FBEB48F7748880C952BC4E31B`.
`com.moolsocial.app/.MainActivity` is foreground and the live Videos feed is
visibly populated for founder play.

Durable evidence:
`artifacts/quality/youtube-api-submission-readiness-20260725-01/OWNER-CONNECT-ATTEMPT-20260726.md`.

The next attempt requires a new explicit founder decision: initialize Dev
Firebase Authentication, register the existing signing SHA-1 and enable only
Google sign-in for the intended real MoolSocial path (recommended), or
authorize a temporary self-cleaning anonymous audit provider that
disconnects/revokes YouTube, deletes the anonymous user and is disabled after
proof. Do not bypass Firebase Auth, and do not begin comprehensive YouTube,
Production, OAuth verification, YouTube audit or quota submission work.

## Founder correction — public website motion and customer copy, 26 July 2026

The public MoolSocial website must implement product motion visually and must
never narrate, label or explain that motion to customers. The founder rejected
customer-visible wording including `Motion shows what happens after every
action`, `Choose an action`, `One tap`, motion/example/demo labels, concept
disclaimers and planned/not-final presentation notes.

The rejected explanatory journey section was removed rather than reworded.
The hero service universe, service nodes, action rail, MoolSocial screen
movement and tap indicators now carry the visual behavior without adjacent
implementation commentary. The reduced-motion treatment may slow and soften
these non-flashing product demonstrations, but it must not globally cancel
every website animation and leave the founder-facing page static.

The Firebase public-site regression test now extracts customer-visible text
and semantic attributes from the company page and rejects prototype, concept,
preview, example, demo, implementation and related internal wording. It also
permanently rejects the exact founder-reported phrases and verifies that the
tap motion is not hidden by the reduced-motion stylesheet.

## Founder correction — official marketing website hierarchy, 26 July 2026

The public MoolSocial website is an official company and launch marketing
surface, not a product-feature directory. Its primary navigation must express
the public story—MoolSocial, its vision, launch, participation and contact—not
expose app-feature categories or place Privacy and Support in the primary
marketing navigation. Compliance and account-management destinations remain
available from the footer and their dedicated public pages.

App UI supports the MoolSocial story but must not dominate it. The founder
rejected the crowded six-card `Inside MoolSocial` presentation and duplicated
action ticker. The accepted direction is one foreground MoolSocial screen at a
time inside a cinematic rotating experience, with concise benefit-led copy.

Motion is a page-wide brand behavior. The hero universe, marketing cards,
MoolSocial screen, launch panel, opportunity cards, social cards, buttons,
ambient light and contact band must carry visible depth and movement without
customer-facing motion labels or explanations. Reduced-motion treatment may
slow and soften this behavior, but it must not make the whole founder-review
website static.

## Founder correction — public click ownership and provider prominence, 26 July 2026

Provider-specific account controls are compliance utilities, not MoolSocial
marketing propositions. `Manage connected services` and `Delete account or
data` must not appear in the public marketing footer or primary navigation.
The legally necessary disconnection and deletion controls remain reachable
from Privacy and Support. The disconnection surface is provider-neutral at the
top level; Google and YouTube appear only where their specific authorization
and revocation requirements must be explained.

Every customer-visible contact surface must own a real result. Marketing
buttons, the hero service universe, audience cards, the MoolSocial experience,
career and partnership actions, social-profile cards, header Contact and
footer Contact all open a purpose-specific email to `hello@moolsocial.com`.
No empty, script-only or decorative customer tap may be presented as a working
contact action. Internal marketing navigation remains valid only when it moves
to the exact named section.

The public logo and tricolour identity line carry continuous three-dimensional
depth across the company, Privacy, Terms, Support, connected-account and
deletion pages. Legal-page titles, navigation, notices, request steps and
ambient geometry extend the same motion system without changing the
professional legal meaning or adding customer-facing motion commentary.

The official-profile contact group includes X, YouTube, Instagram, Facebook
and LinkedIn. Each network uses its recognizable brand glyph, retains a
purpose-specific `hello@moolsocial.com` email action until a verified
MoolSocial profile URL is published, and carries the same subtle 3D depth as
the wider marketing surface.

## Founder correction — multi-screen website motion and responsive density, 26 July 2026

The public website's MoolSocial experience must not repeat one isolated phone
screen at a time. It now presents two rotating product scenes, each containing
three different real MoolSocial screen assets: Social, Universal and For You;
then Buy and Deliver, Create and Earn, and Work and Grow. The six screens stay
inside one real `hello@moolsocial.com` contact action and retain concise product
labels without customer-facing animation explanations.

The scene uses foreground, left and right phone depth, independent motion,
moving tricolour light, an orbital field, screen glints and visible tap
indicators. The hero action universe now carries three separately moving
tricolour points, colour-changing orbital rings, changing node depth and a
moving tricolour identity line. Motion is smooth and non-flashing. The
reduced-motion path slows these movements and preserves complementary scene
timing; it does not leave the page static or create an empty interval between
the two screen groups.

Public website spacing is intentionally denser: hero and section padding,
heading separation and the experience-stage height are reduced while retaining
clear hierarchy. Responsive layout owners cover wide screens, standard
laptops, tablets, compact phones and a dedicated `420px` compact boundary.
The three-screen composition remains visible on compact devices with scaled
centre and side phones, and no public-page horizontal overflow is accepted.

## Founder correction — first-viewport hierarchy and visual cross-device proof, 26 July 2026

The company page must open with `Designed across platforms` and `MoolSocial
moves with you.` in the first viewport. `One connected experience, built
around real life.` belongs with the multi-screen product showcase below. This
hierarchy is required on desktop and compact mobile layouts without horizontal
overflow.

Device support is communicated through the product graphics, not through
customer-facing hardware or operating-system labels. The showcase uses two
distinct three-dimensional phone-shell geometries—a rounded notched frame and
an edge-profile frame with a centred camera treatment—while captions name only
the MoolSocial experience shown: Social, MoolSocial, For You, Buy and Deliver,
Create and Earn, and Work and Grow.

Primary navigation remains the official public story: Our story, Our vision,
Launch, Join us and Contact. It is a compact glass-depth control with continuous
non-flashing tricolour motion, clear hover/focus response and a real
purpose-specific `hello@moolsocial.com` contact destination. Section density is
reduced across marketing and legal pages without weakening legal substance or
removing required controls.

Verification passed with the production web build and all four automated site
tests. Live browser proof covered a `1280 x 720` desktop viewport and a
`390 x 844` mobile viewport. The required first-view headline was visible
without scrolling in both, navigation/phone/orbit transforms changed over
time, all six public routes had no horizontal overflow, no empty links were
present, and no device-brand names appeared in customer-visible page text.

## Founder correction — phone-led opening view, hardware-only distinction and launch countdown, 26 July 2026

The rotating three-phone MoolSocial product scene now leads the opening
viewport. The abstract service-universe graphic moves to the later connected
experience section and must remain a compact navy/tricolour branded panel,
never a stretched grey or unbranded surface.

The opening product scene has no visible outer box and no captions beneath the
screens. `Social`, `MoolSocial`, `For You`, `Buy and Deliver`, `Create and Earn`
and `Work and Grow` must not be repeated as labels below the three simultaneous
screens. Screen identity comes from the actual product UI. Device variety is
shown only through hardware geometry: one rounded frame uses a pronounced pill
camera, metallic rail and separate side controls; the outer frames use flatter
corners, punch-hole cameras and different rails and controls. No customer copy
names a phone or operating-system brand.

All phone images use their complete source aspect ratio with containment rather
than cropping. The screen animation changes brightness, depth, horizontal
position and hardware angle without scaling the bitmap beyond its frame. The
fan/orbit motion keeps the full top, bottom and side hardware visible.

The hero includes a live countdown to `24 October 2026` in four requested
units—months, days, hours and seconds—and updates once per second. The fixed
date remains visible beside the countdown. Static Firebase HTML/JavaScript and
the dynamic web mirror share the same hierarchy and countdown behavior.

Verification passed with the production web build and all four automated site
tests. Structural checks confirm one hero showcase, six eager-loaded phone
screens, zero figcaptions, four countdown units, distinct hardware-control
pseudo-elements and the branded lower service universe.

### Comfort-motion amendment

The founder rejected phone groups that appeared to jump backward and suddenly
return to the foreground. The opening showcase now keeps all three phones on
one stable grid plane. Phone movement is limited to slow, small vertical
translation and gentle side-to-side hardware tilt; depth remains nearly
constant. The two three-screen groups exchange through a long linear dissolve
over a 24-second cycle, with no set-level scaling, rotation or backward
translation.

Complete-frame visibility takes priority over dramatic perspective. The
centre and outer phone widths are capped, all three figures are relatively
positioned inside the stage grid, and image animation applies no scale. The
rounded pill-camera frame, flatter punch-hole frames, metallic rails and side
controls must remain visible throughout the cycle.

## Founder-approved public web release, 26 July 2026

The founder identified `http://127.0.0.1:4174/` as the approved public website.
Its durable, canonical source is `apps/web/public`; no second repository or
parallel public-web copy may replace it. The exact 19-file static source was
deployed to Firebase Hosting project `moolsocial-dev-503018` and made public at
`https://moolsocial.com/`.

The first public deployment exposed a browser-cache mismatch: existing browser
tabs could receive the new HTML while retaining an older one-hour cached
`site.css`, producing oversized, clipped product screens. Release
`20260726-2` corrects this by versioning the CSS and JavaScript request URLs.
After redeployment, all 19 local canonical files matched the public domain
byte-for-byte.

The final countdown uses five units—months, days, hours, minutes and
two-digit seconds. This supersedes the earlier four-unit note in this handoff.
The expanded web release suite passes 5/5 and now covers duplicate marketing
copy, real click destinations, one title and H1 per page, unique IDs, image
dimensions and alternative text, local asset existence, the Hosting source
directory and the script-compatible Content Security Policy.

The permanent release record and SHA-256 manifest are in
`docs/quality/MOOLSOCIAL-PUBLIC-WEB-RELEASE-20260726.md`.

## Latest founder decision — provider hold, Social protection and Buy sequence, 26 July 2026

The YouTube API Services quota/compliance form has been submitted and its
provider receipt received. Comprehensive YouTube development, production
rollout and additional capability activation are now on provider-review hold.
The founder-controlled VetoNews audit slice remains dormant unless Google asks
for reviewer proof or additional information.

The active product sequence is:

1. protect the existing Social module and its private-Dev public Videos/Shorts
   evidence;
2. establish repository and CI non-regression gates;
3. settle the shared UI/UX and Buy operating model;
4. prepare and verify the connected Buy HTML;
5. stop for founder `FINAL`;
6. freeze the exact accepted Buy reference;
7. implement an isolated native Flutter V2 slice;
8. replay Social plus Buy regression on the physical OPPO; and
9. request a separate founder decision before any Dev deployment trial.

The deployed Social evidence remains:

- persistent Dev profile: `PublicDataReview`;
- last recorded Cloud Run revision: `youtubeprovider-00024-dol`;
- current active Firebase Functions source hash:
  `8a3afd8e81e30322f1d64f13e3d79f6360516aab`;
- retained OPPO candidate:
  `youtube-return-oppo-20260726-10`; and
- APK SHA-256:
  `4B69C0F284B9AA1AACF80C764F2B3497996CEA2E1728F068B896F0D6DF8798E9`.

The APK pulled read-only from OPPO serial `2b3e0f71` matched the retained r10
artifact byte-for-byte. The current source is separately identified and is not
claimed as byte-identical to r10.

The YouTube return route is now isolated in
`YouTubeConnectReturnActivity.kt`, so the accepted Screens 01–03 host file
remains byte-identical to its lock. The approved-reference, customer-copy,
interaction-contract and protected-Social gates pass. The protected Social
source inventory is 119 files with portable tree SHA-256
`927BA8662457D64640EF3A3A97B2B53120CA53E26E80F761A937EE35BAD92851`.
The traceable layer-by-layer record is
`artifacts/quality/social-protected-baseline-20260726-01/`.

The proposed unified Buy catalogue, offer, workspace and PIN-code fulfilment
model is recorded at
`docs/decisions/ADR-0009-UNIFIED-BUY-CATALOGUE-OFFERS-AND-FULFILMENT.md`.
It requires separate founder approval before it becomes the HTML design
authority.

## Latest founder decision — Buy HTML authority approved, 27 July 2026

The founder approved ADR-0009 as the information-architecture authority for a
new Buy HTML UI/UX candidate and explicitly reserved final product approval
until that interactive HTML is reviewed.

The active boundary is:

1. preserve the protected Social baseline, the accepted Screen 04 v8 HTML and
   the OPPO/Dev trial evidence;
2. leave every approved-final screenbook file unchanged;
3. revise only the editable Buy HTML and its isolated review/audit support;
4. demonstrate Personal Buy, verified Business Buy, canonical products,
   context-specific offers, seller comparison, PIN-code serviceability and
   truthful price/stock recovery;
5. present the exact interactive HTML for founder `FINAL`; and
6. do not change Flutter, freeze an immutable Buy reference or begin a Dev
   deployment trial before that decision.

### Buy HTML review draft prepared

- Editable review source:
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\09-buy.html`
- Isolated Buy styling:
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\shared\moolsocial-buy-v2.css`
- Isolated Buy interaction model:
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\shared\moolsocial-buy-v2.js`
- Founder-review evidence:
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\quality\BUY-HTML-FOUNDER-REVIEW-20260727.md`
- Saved screenbook commit:
  `fab6eab5823de83533e0516c53a065ea6756e7a7`
- After-restart review launcher:
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\START-BUY-HTML-REVIEW.cmd`
- Personal review URL:
  `http://127.0.0.1:8765/screens/09-buy.html`
- Business review URL:
  `http://127.0.0.1:8765/screens/09-buy.html?context=business`

The draft covers the approved unified catalogue/offers/fulfilment model,
Personal and Business contexts, per-pack MOQ, seller comparison, saved baskets,
medicine, serviceability, recovery, checkout, consent, confirmation and native
order tracking. It remains an editable founder-review draft. No approved-final
reference, Flutter implementation or deployment is authorized at this stage.

## Latest founder refinement — Buy customer navigation, 27 July 2026

The editable Buy HTML now uses the founder-selected customer hierarchy:

- Buy remains the Universal main action.
- Buy and Orders are the durable bottom destinations. Mool and Chat remain the
  shared edge actions.
- Retail and Wholesale are in-page pack/price/quantity modes, not bottom
  destinations. They are directly tappable and support horizontal
  swipe-changing with best-effort device haptics.
- Retail and Wholesale use separate category/search states over the canonical
  catalogue.
- Both modes now expose an independently scrollable, complete FMCG department
  taxonomy; existing sample products were remapped to their canonical
  departments without duplicating product records.
- Retail cards reveal eligible Wholesale price and MOQ and open the matching Wholesale
  product decision.
- Retail uses Basket; Wholesale uses Bulk order and then purchase orders.
- Buy again remains in saved/past-order controls, not the bottom rail.
- Medicine is a Buy product category with its specialist pharmacy flow.

The corrected editable review remains at
`http://127.0.0.1:8765/screens/09-buy.html`. Syntax, balanced-container,
responsive overflow, 44 px tap-target, Retail/Wholesale tap, two-way swipe,
separate discovery state, Bulk preview, Basket/Bulk order terminology,
Medicine category, Buy destination and Orders destination checks passed.
Founder `FINAL` is still required before reference freeze, Flutter
implementation or any Dev deployment trial.

## Latest founder refinement — Universal Mool route ownership, 27 July 2026

The founder reported that returning through Mool reopened the legacy route
state and legacy action rail. The editable HTML review now has one
context-aware navigation contract:

- Screen 04 honours `world=social` and `world=buy` when Mool is opened.
- Social is owned by the current dedicated HTML screens: Shorts 05, Videos 06,
  Feed 07 and Create 08.
- Buy is owned by the current Screen 09 HTML: Retail, Wholesale, Orders and
  Medicine deep-link to the matching Screen 09 state.
- Social and Buy both return to
  `04-universal-focus-shell.html?openMool=1&world=<context>&rail=capability`.
- The Buy Orders deep link is `09-buy.html?sheet=orders`; closing the sheet
  removes that transient URL state.
- Mool main actions and Social/Buy sub-actions no longer route into the legacy
  embedded Social/Buy destinations.

Browser verification passed for Social → Mool, Mool → Videos, Mool → Create,
Social Mool → Buy, Mool → Retail, Mool → Wholesale, Mool → Medicine and
Mool → Orders. JavaScript syntax, route-target existence, malformed-query scan
and diff checks passed. Approved-reference and protected-Social production
gates remain unchanged. This is still editable founder-review HTML: no
approved-final freeze, Flutter implementation, commit, deployment trial or
public deployment is authorized by this refinement.

## Latest founder lock — app-wide brand integrity, 27 July 2026

The founder directed that MoolSocial identity remain consistent across every
editable HTML screen, native Flutter screen and cloud trial artifact, with a
permanent regression control. The website is recorded as pending and is not
changed under this decision.

The locked app identity is:

- exact `MoolSocial` wordmark;
- navy `#000080`, saffron `#FF9933`, white `#FFFFFF` and green `#138808`;
- saffron → white → green identity-line order; and
- one Mool service-launcher symbol: a two-by-two grid. Mool is navigation, not
  an alternate company logo.

The Buy-only custom M artwork was removed from the editable Screen 09 header
and dock. The header now uses the same wordmark plus identity line, while the
Buy Mool action uses the same grid as accepted Social. Shared Flutter identity
now exposes `MoolBrand`, the shared outcome dock and Chat render its canonical
grid, and existing vertical call sites reference the same constant. Protected
Social source was not changed.

Durable controls:

- `docs/design/MOOLSOCIAL-BRAND-INTEGRITY-CONTRACT.md`
- `config/brand-integrity.json`
- `scripts/check-brand-integrity.ps1`

The gate is part of local `scripts/check.ps1`, pull-request product contracts
and release gates. Buy remains an editable founder-review HTML candidate:
brand correction does not grant Buy `FINAL`, authorize new Flutter Buy
implementation, or authorize a Dev/cloud deployment trial.

## Latest founder refinement — populated Retail and Wholesale range, 27 July 2026

The founder directed that every Retail and Wholesale category contain an
actual product range rather than a complete category rail backed by only six
sample products.

The editable Buy HTML now contains 42 canonical founder-review products:

- all 20 Retail catalogue departments have at least two products;
- all 21 Wholesale catalogue departments have at least two products;
- HoReCa and retail-supply Wholesale departments reuse the same canonical
  underlying products exposed in the relevant Retail departments;
- every added product carries Retail pack, delivered price, seller, stock,
  delivery and return information;
- every added product carries Wholesale pack, MOQ, landed price, price breaks,
  supplier, tax, freight, payment, credit and dispatch information; and
- search includes product names, brands and common customer terms while
  retaining separate Retail and Wholesale discovery state.

Rendered browser verification opened every department. The minimum result was
two products with no empty department. Retail `pyaz` search resolved Fresh red
onions, Wholesale `haldi` search resolved Turmeric powder, and switching modes
preserved each query independently. Turmeric Wholesale details exposed two
packs, three price breaks, four terms, two supplier choices and the Bulk order
action. A runtime assertion now blocks the HTML candidate if any ordinary
Retail or Wholesale department drops below two products.

This remains an editable HTML founder-review candidate. No approved-final
reference was frozen, no native Buy implementation began, and no Dev/cloud
deployment trial was performed.

## Latest founder refinement — precise Retail and Wholesale taxonomy, 27 July 2026

The founder directed that category taps expose a wider and more precise product
range in both Retail and Wholesale, without duplicate product identities or
ambiguous category ownership. This supersedes the earlier two-products-per-
department review threshold.

The editable Buy HTML now contains 84 canonical founder-review products:

- all 20 ordinary Retail departments and all 21 ordinary Wholesale departments
  have at least four products;
- tapping a primary department shows all matching products immediately, while
  optional count-labelled subcategory chips provide a second, precise filter;
- Retail and Wholesale keep independent primary-category, subcategory and
  search state;
- entering a search clears an older narrow category/subcategory filter and
  searches globally inside the current Retail or Wholesale context;
- tapping a department clears an older search so its complete four-or-more
  product range is visible immediately;
- every product has one Retail category/subcategory and one Wholesale
  category/subcategory;
- different cross-context mappings are limited to an explicit allowlist:
  kitchen/disposable products become HoReCa supplies and relevant store
  consumables become Retail supplies for Wholesale discovery; and
- runtime assertions reject duplicate product IDs, undeclared category or
  subcategory mappings, unapproved cross-context mappings, empty
  subcategories and departments below the four-product minimum.

Rendered proof reported 84 products, Retail minimum 4, Wholesale minimum 4,
zero duplicate identities, zero taxonomy conflicts and zero empty
subcategories. Retail Fruits & vegetables opened four products and Fruits
narrowed to Fresh bananas. Wholesale Retail supplies opened POS rolls, price
labels, barcode labels and reusable carry bags. A Wholesale carry-bag product
decision exposed two packs, three price breaks, four commercial terms and the
Bulk order action. Responsive checks at 320 × 568, 390 × 844 and 430 × 932
found no horizontal overflow, no clipped category label and no sub-44 px
category or subcategory target.

This is still an editable founder-review HTML candidate. The change does not
grant Buy `FINAL`, freeze an approved reference, authorize native Flutter Buy
implementation, or authorize a Dev/cloud deployment trial.

## Latest founder refinement — definitive Buy main-category rails, 27 July 2026

The founder clarified that the left customer rail itself must contain more
definitive main categories; adding product tiles below broad departments was
not sufficient. The editable Buy HTML now replaces the earlier 20 Retail and
21 Wholesale broad departments with 34 primary purchase categories in each
mode.

- Combined departments were separated where customer purchase intent differs:
  Eggs & poultry / Meat & seafood; Flour, rice & grains / Dals & staples;
  Ground spices / Whole spices; Breakfast & cereals / Instant foods; Biscuits
  & chocolate / Namkeen & chips; and equivalent precise personal care, home
  care, baby, pet, packaging and business-supply categories.
- Retail has dedicated Food storage & packs, Cups & tissues, School & office
  and Shop supplies categories.
- Wholesale has dedicated HoReCa food packs, HoReCa tableware, Retail supplies
  and Stationery & office categories.
- All 84 canonical products have exactly one Retail primary category and one
  Wholesale primary category. Retail and Wholesale offers may differ, but the
  product identity is not copied and no product repeats across categories
  inside either mode.
- Every primary category opens its matching purchasable products on the first
  tap. A subcategory row appears only when it adds a meaningful further choice.
- Runtime gates reject missing assignments, duplicate context assignments,
  duplicate product identities, undeclared taxonomy mappings, empty
  subcategories and categories below two products.

Rendered direct-route proof opened all 34 Retail and all 34 Wholesale
categories. Each context covered all 84 products exactly once; no route was
empty and no route repeated a product. Retail Eggs & poultry showed eggs and
chicken, Retail Ground spices showed turmeric and red chilli, Wholesale
HoReCa food packs showed aluminium foil and takeaway containers, and Wholesale
Retail supplies showed the four intended store-consumable products. Runtime
data reported zero duplicate assignments and zero taxonomy conflicts.

This remains an editable founder-review HTML candidate. No Buy `FINAL`,
approved-reference freeze, native Flutter Buy implementation, Git commit,
deployment trial or public deployment is authorized by this refinement.

## Latest founder refinement — complete category discovery, 27 July 2026

The founder observed that the 34-category expansion was not visibly
discoverable: the narrow rail showed only a few entries while the rest were
hidden inside its independent scroll, and Retail and Wholesale appeared to
start with the same categories.

The editable Buy HTML now uses the rail’s first control as a persistent
`All 34` entry. It opens a complete three-column category panel containing all
34 context-specific categories and their product counts, plus direct access to
all products and Medicine. Choosing any panel category closes the panel and
shows its purchasable products immediately.

Retail keeps the consumer-first order. Wholesale now visibly starts with
Retail supplies, HoReCa food packs, HoReCa tableware and Stationery & office,
then continues through the shared FMCG product families. The underlying
canonical product identity remains shared only where appropriate; Retail and
Wholesale pack, price, MOQ and commercial offers remain context-specific.

Rendered proof confirmed:

- 34 cards in the Retail complete-category panel;
- 34 cards in the Wholesale complete-category panel;
- accurate product counts and zero horizontal overflow at the live review
  viewport;
- effective panel targets of at least 68 px;
- Wholesale HoReCa tableware opened only paper cups and paper tissues; and
- Retail Ground spices opened only turmeric and red chilli.

The full-product-universe scope remains the founder-approved FMCG Buy
catalogue. No unrelated marketplace department was silently added. This is
still editable founder-review HTML and does not grant Buy `FINAL`, freeze an
approved reference, authorize Flutter implementation, or authorize a Dev/
cloud deployment trial.

## Latest founder refinement — categories directly visible in both rails, 27 July 2026

The founder clarified that the complete Retail and Wholesale category sets
must be directly present in the left rail. A short rail with hidden internal
scrolling, even when accompanied by an `All 34` panel, did not meet that
requirement.

The editable Buy HTML now renders a compact, full-height rail in each mode.
The rail participates in the normal page scroll and has no nested vertical
scroll. Retail and Wholesale each contain 36 direct controls: `All`, all 34
context-specific product categories and `Medicine`. The existing `All 34`
panel remains only an optional discovery shortcut; it is not required to
reach any category.

Rendered verification confirmed:

- 36 direct rail entries in Retail and 36 in Wholesale;
- `overflow-y: visible` and equal client/scroll heights for both category
  containers, proving that no rail entry is hidden in an internal scroll;
- 16 Retail and 15 Wholesale categories simultaneously visible beside product
  cards at normal page position `scrollY = 1200`;
- final Retail rail entry `Shop supplies` and final Wholesale rail entry
  `Cat care`;
- direct Retail `Shop supplies` selection opened POS thermal paper rolls,
  self-adhesive price labels and barcode label rolls; and
- zero horizontal overflow in both rendered review routes.

This supersedes the earlier independently scrollable rail behavior. The
complete-category panel, taxonomy, canonical 84-product catalogue and
Retail/Wholesale offer separation remain intact. This is still an editable
founder-review HTML candidate; no Buy `FINAL`, approved-reference freeze,
native Flutter Buy implementation, Git commit, deployment trial or public
deployment is authorized.

## Latest founder refinement — compact expandable category rail, 27 July 2026

The founder then observed that permanently rendering the complete rail beside
a category with only two or three matching products left a long category
column and an empty product area. The direct full-height rail is therefore
superseded by a compact in-rail disclosure pattern.

Retail and Wholesale now show five context-priority/selected category entries
plus a `More` control. Tapping `More` expands all 36 direct entries inside the
same left rail and changes the control to `Less`; it does not open another page
and does not introduce nested scrolling. Choosing a category immediately
returns the rail to its compact state and keeps the selected category in the
final compact slot, even when that category is normally farther down the
taxonomy.

Rendered verification confirmed:

- five compact category entries and `More 31` in both Retail and Wholesale;
- the selected deep category remains visible in the compact rail;
- `More 31` expands all 36 direct rail entries and `Less` collapses them;
- selecting Wholesale `Dog care` from the expanded rail restored the compact
  rail and opened Adult dog food and Chicken dog treats;
- direct Retail `Shop supplies` preserved the compact rail and opened its
  three matching purchasable products;
- the compact Wholesale `Namkeen & chips` rail measured 355 px beside its
  258 px two-product row, eliminating the earlier full-height empty-column
  effect; and
- zero horizontal overflow in both Retail and Wholesale review routes.

The optional `All 34` panel, complete taxonomy, canonical 84-product catalogue
and separate Retail/Wholesale category order remain intact. This is still an
editable founder-review HTML candidate; no Buy `FINAL`, approved-reference
freeze, native Flutter Buy implementation, Git commit, deployment trial or
public deployment is authorized.

## Latest founder refinement — fixed rail, category drawer and balanced results, 27 July 2026

The founder found that even the temporary in-page rail expansion could remain
much taller than a two- or four-product category, creating a large empty
product column. The inline `More`/`Less` expansion is superseded.

The editable Buy HTML now keeps the left rail permanently compact. It contains
the `All` result control, five context-priority/selected category entries and
`More`. `More` opens the existing complete 34-category drawer over the
catalogue without changing document height. Selecting a drawer category closes
the overlay, preserves the compact rail and pins the selected category when it
is outside the priority set.

Short result sets are balanced without corrupting taxonomy:

- the category result count and first grid contain only exact category
  matches;
- categories with fewer than four exact matches add two separately labelled
  complementary products beneath the exact grid;
- Retail uses `You may also need`;
- Wholesale uses `Commonly ordered together`; and
- categories with four or more exact products, filtered/search results and the
  all-products result do not show this recommendation section.

Rendered verification confirmed:

- fixed 355 px rail height in Retail and Wholesale;
- five rail categories plus `More`, with no in-page category expansion;
- 34 context categories and accurate counts in each drawer;
- drawer selection closes the overlay and keeps the active category visible;
- Wholesale `Meat & seafood`: two exact products plus two separately labelled
  complementary products;
- Retail `Shop supplies`: three exact products plus two separately labelled
  nearby recommendations;
- Wholesale `Stationery & office`: four exact products and no recommendation
  section;
- top `All`: 84 exact products, active/pressed treatment and no recommendation
  section; and
- zero horizontal overflow in every tested state.

The complete taxonomy, canonical 84-product catalogue, exact Retail/Wholesale
offer separation and optional Medicine entry remain intact. This is still an
editable founder-review HTML candidate; no Buy `FINAL`, approved-reference
freeze, native Flutter Buy implementation, Git commit, deployment trial or
public deployment is authorized.

## Latest founder refinement — uninterrupted in-rail shopping and card quantity controls, 27 July 2026

The founder rejected the complete-category modal because its dimmed backdrop
and detached sheet interrupted the direct shopping path. The modal-based
`More` interaction is superseded.

`More` now reveals all 34 context product categories plus Medicine inside the
left rail itself. The rail uses a fixed 420 px internal scroll viewport, so it
does not grow through the page or displace the product result. Exact and
complementary products remain visible and actionable beside category
discovery. Selecting a category updates products immediately, collapses the
rail to five entries and pins the new selection. No modal, backdrop or
detached category page is used.

Product cards now support direct basket control:

- `ADD` changes in place to `− quantity +`;
- Retail starts at one pack;
- Wholesale starts at the selected pack's MOQ;
- `+` and `−` update basket/bulk-order count and total immediately;
- decreasing below the permitted minimum removes the line and restores
  `ADD`; and
- each decrement/increment target is 44 × 44 px.

Rendered verification confirmed:

- Wholesale expanded rail: 35 direct choices, 420 px client height, 1,642 px
  scroll height, 544 px total rail height, `overflow-y: auto`, zero modal and
  zero horizontal overflow;
- selecting Wholesale `Cat care` restored a 356 px compact rail and immediately
  opened Adult cat food and Clumping cat litter beside it;
- selecting Retail `Ground spices` restored the compact rail, opened Turmeric
  powder and Red chilli powder and preserved the existing basket;
- Wholesale Adult cat food respected MOQ 2, incremented to 3, decremented to 2
  and removed/restored `ADD` on the next decrement;
- Retail Fresh boneless fish fillets incremented 1 → 2 and decremented 2 → 1;
  and
- all card stepper buttons measured 44 × 44 px.

The separately labelled recommendations for short exact result sets remain,
but they never alter category counts. The canonical 84-product catalogue,
Retail/Wholesale taxonomy and context-specific offers remain intact. This is
still editable founder-review HTML; no Buy `FINAL`, reference freeze, native
Flutter Buy implementation, Git commit, deployment trial or public deployment
is authorized.

## Latest founder approval — Buy catalogue slice frozen, 27 July 2026

The founder explicitly approved the Retail and Wholesale category rail,
product grid and bottom rail and directed that this exact slice be recorded as
founder approved before the next Buy sub-tap set.

The immutable partial reference is:

`approved-references/screens/09-buy-catalogue/v1`

It freezes:

- the 34-category Retail taxonomy and 34-category Wholesale taxonomy over one
  canonical 84-product catalogue;
- compact context-priority rails with `All`, five category entries and
  `More`;
- all 34 context categories plus Medicine revealed inside the fixed-height
  rail, with no modal, backdrop or detached page;
- same-screen exact product results and separately labelled complementary
  recommendations;
- context-specific Retail and Wholesale pack, price, seller and fulfilment
  presentation;
- direct `ADD` to `− quantity +`, including Retail quantity one and Wholesale
  selected-pack MOQ;
- immediate basket or bulk-order pill updates; and
- fixed Mool, Buy, Orders and Chat bottom navigation.

The frozen source HTML SHA-256 is
`7D73CDFF4EC2E91F405837A3DD215B1F4AC52EB0573C5C444E0E5D57FD4E093F`.
The package includes exact HTML and shared assets, an interaction contract,
founder acceptance, SHA-256 sums, verification evidence and four 390 × 844
reference images.

The approval is deliberately limited. Product detail, pack selection, seller
comparison, basket/bulk-order review, checkout, payment, confirmation,
tracking, Medicine, native Flutter and deployment are not approved by this
decision.

The next founder-review set is the product-decision path:

1. open a Retail or Wholesale product without losing catalogue context;
2. compare pack and seller choices;
3. preserve final delivered-price or landed-cost clarity;
4. add Retail quantity to Basket or Wholesale MOQ quantity to Bulk order; and
5. return to the exact category, scroll and quantity state.

Native Buy implementation remains blocked until the complete connected Buy
HTML reference required for implementation is founder approved and frozen.
No Git commit, push, Flutter implementation, Firebase/GCP deployment or public
deployment was authorized.

## Latest Buy HTML review slice — product decision, 27 July 2026

After freezing the approved catalogue slice, the editable screenbook advanced
to product decisions without altering the immutable
`screens/09-buy-catalogue/v1` package.

The next founder-review slice now provides:

- product detail entered from the approved Retail or Wholesale grid;
- two pack choices for every product, with selected-pack pricing;
- Retail final delivered price and Wholesale landed price kept explicit;
- seller comparison priced for the currently selected pack rather than the
  default pack;
- a visible selected-seller treatment and updated seller, delivery, badge,
  unit cost and call-to-action after selection;
- Wholesale pack-dependent MOQ, landed cost and price-break scaling;
- Retail quantity in packs and Wholesale quantity in trade packs;
- `Add to basket` or `Add to bulk order` changing to `Update basket` or
  `Update bulk order` once the line exists;
- reopening an existing line at its saved pack and quantity; and
- Back restoring the exact context, category, catalogue scroll position,
  selected pack display, quantity control and basket/bulk-order pill.

The runtime product-decision integrity gate covered all 84 products, 168
Retail/Wholesale offers, 336 pack choices and 344 seller choices. Every choice
resolved to a positive price. Browser checks passed the Retail and Wholesale
detail routes at 320 × 568, 390 × 844 and 430 × 932 with two visible pack
choices, no target below 44 px, zero horizontal overflow and no console error
or warning.

Connected verification also confirmed:

- Retail 1,000 g fish changed seller prices from ₹595 to ₹618 and updated the
  selected delivered price and unit price;
- Wholesale double-carton POS rolls changed landed price to ₹4,200, MOQ to one
  and scaled price breaks, while the alternate supplier changed the landed
  price to ₹4,326 and the unit cost to ₹10.82 per roll;
- Wholesale Barcode label rolls preserved a 395 px catalogue position,
  selected double carton, quantity two and the compact Retail supplies rail
  after product Back; and
- the frozen catalogue regression still passed its 356 px compact rails,
  35-choice/420 px in-rail expansion, exact product grids, MOQ stepper,
  Mool/Buy/Orders/Chat bottom navigation and zero-overflow checks.

Founder-review routes:

- Retail:
  `http://127.0.0.1:8765/screens/09-buy.html?category=meat-seafood&product=fish-fillet&view=product`
- Wholesale:
  `http://127.0.0.1:8765/screens/09-buy.html?context=business&category=retail-supplies&product=thermal-rolls&view=product`

This product-decision slice is editable and awaiting founder review. It has not
been added to the immutable manifest and does not authorize Flutter,
deployment, commit, push or merge.

## Latest Buy HTML review slice — rich purchase facts and direct order review

The editable Screen 09 candidate now carries complete customer buying facts
from product decision into Basket or supplier-grouped Bulk order without
adding another product-information route.

Every Retail and Wholesale product shows variant, selected pack, net quantity,
unit price, minimum quantity/MOQ, available stock, seller and return terms.
Every pack/seller combination also derives a current dated commitment with
supplier origin, destination PIN, order cut-off, dispatch date, delivery
window and seller confirmation. Late orders roll forward from the current
order date. Runtime coverage is 84 products, 168 context offers, 336 pack
choices, 344 seller choices and 688 pack/seller delivery commitments with zero
missing purchase facts.

After Add/Update, product detail exposes a direct `View basket` or
`View bulk order` action. Retail Basket keeps inline quantity, net quantity,
seller and delivery detail. Wholesale Bulk order groups lines by supplier,
shows origin/confirmation/dispatch and keeps an MOQ-aware inline stepper.
Checkout, confirmation and tracking use the same commitment summary rather
than a generic conflicting delivery date.

Browser verification mounted 16 direct states and 10 sheets/recovery surfaces.
All had zero prohibited customer copy, zero horizontal overflow and no target
below 44 px. Retail product, Wholesale product, Retail basket and Wholesale
Bulk order passed at 320 × 568, 390 × 844 and 430 × 932. The full Retail and
Wholesale order paths retained their delivery date through checkout,
confirmation and tracking. Wholesale `+` recalculated landed totals and net
quantity; decrement below MOQ removed the line.

Founder-review routes:

- Retail product:
  `http://127.0.0.1:8765/screens/09-buy.html?category=meat-seafood&product=fish-fillet&view=product`
- Wholesale product:
  `http://127.0.0.1:8765/screens/09-buy.html?context=business&category=retail-supplies&product=thermal-rolls&view=product`
- Retail basket:
  `http://127.0.0.1:8765/screens/09-buy.html?seed=1&view=basket`
- Wholesale Bulk order:
  `http://127.0.0.1:8765/screens/09-buy.html?context=business&seed=1&view=basket`

The immutable Buy catalogue `v1` remains unchanged and checksum-clean. This
new set is editable and awaiting founder approval. No new reference freeze,
Flutter work, Firebase/GCP action, deployment, commit, push or merge is
authorized.

## Latest Buy HTML review slice — Cart and retailer Household Basket

The editable Screen 09 candidate now uses `Cart` for the customer's temporary
Retail product selection. `Household Basket` is reserved for a retailer-created
multi-product offer, such as a 30-day household essentials combination.

The first inline Retail offer contains 12 products and lets the customer scale
calculated pack quantities, regular value, Basket price and saving for 2–8
household members. It shows the retailer and dated delivery commitment, expands
to the exact product list on the catalogue, and enters Cart as one Basket line.
Cart may contain that Basket and individual products together. Wholesale
continues to use supplier-grouped `Bulk order`.

This design adds no new screen, route or bottom-navigation destination. Browser
checks passed at 320 × 568 and 390 × 844 with zero horizontal overflow, zero
effective targets below 44 px, zero missing purchase facts and zero prohibited
customer-facing commentary. Member scaling, inline expansion, add to Cart,
Cart-side member updates and mixed Cart totals were verified.

The immutable Buy catalogue `v1` remains unchanged and checksum-clean. This
Cart/Household Basket clarification remains editable and awaits founder
approval. No new reference freeze, Flutter work, Firebase/GCP action,
deployment, commit, push or merge is authorized.

## Latest Buy HTML review slice — reduced-tap connected commerce

The editable Screen 09 candidate now uses this connected customer path:

`catalogue → product or direct ADD → Cart/Bulk order → Pay/Place purchase order
→ confirmation with order progress`.

Product detail uses a compact non-catalogue header and a fixed quantity/Add
control above the Buy dock. The opening viewport carries the product, pack,
final delivered/landed price and seller decision; all variant, pack, unit,
stock, returns, origin, destination, cut-off, dispatch, delivery, price-break
and Wholesale terms remain on the same page.

Retail Cart and Wholesale Bulk order now own editable quantities, address,
dated delivery, payment, totals and the final action. The separate checkout
step is no longer reachable; an older `view=checkout` link resolves to the
order review. Confirmation includes order progress without another tap.

Orders exposes active tracking and delivered purchases. Delivered Retail and
Wholesale orders can be reordered into editable Cart/Bulk order lines or added
to the catalogue as a retained order while the customer adds new products.
Existing quantities may be increased, decreased or removed before payment.

Browser verification covered 11 direct Retail/Wholesale states with zero
horizontal overflow, zero missing purchase facts and zero prohibited customer
copy. Effective targets passed the 44 px rule. The 320 × 568 Retail Cart/
payment/confirmation path and 390 × 844 Wholesale product path passed. The
Wholesale product → order → payment/terms → confirmation and delivered →
reorder → edit → add-products journeys were replayed.

The immutable Buy catalogue `v1` remains unchanged and checksum-clean. This
reduced-tap journey remains editable and awaits founder approval. No new
reference freeze, Flutter work, Firebase/GCP action, deployment, commit, push
or merge is authorized.

## Latest Buy HTML refinement — back-free Buy subviews

The founder clarified that removing visible back navigation must not remove
any Buy screen or its content. The editable Screen 09 candidate therefore
removes only the circular back-arrow controls from the current Product,
Medicine, Cart/Bulk order, legacy-checkout and Tracking toolbars.

All views and buying information remain intact. Product, Medicine, Cart/Bulk
order and Tracking return through the persistent Buy destination; Orders
remains available throughout; Cart/Bulk order keeps Add products;
confirmation keeps Add more products and View all orders; delivered tracking
keeps Reorder and Add products. Native phone/browser Back history remains
unchanged.

Browser verification mounted Retail Product, Wholesale Product, Medicine,
Retail Cart, Wholesale Bulk order, the legacy checkout redirect, active
Tracking and delivered Tracking. Each retained its expected content, Buy and
Orders destinations and zero visible or semantic back-arrow controls. A
Wholesale product opened from the catalogue also returned to the exact prior
catalogue route through browser Back.

The immutable Buy catalogue `v1` remains unchanged and checksum-clean. This
back-free toolbar refinement remains editable and awaits founder approval. No
Flutter work, Firebase/GCP action, deployment, commit, push or merge is
authorized.

## Latest Buy HTML trial — Product-detail return cue

The editable Wholesale Product-detail route alone now demonstrates a subtle
return affordance for founder review:

- a 360 ms right-to-left Product-detail entry;
- a word-free left-edge chevron that pulses for 5.6 seconds and then remains
  faintly visible;
- a matching temporary halo on the persistent visible `Buy` destination; and
- Product-only accessible naming of `Buy` as `Return to Buy catalogue`.

The decorative edge cue is `aria-hidden`, accepts no pointer events and does
not replace navigation. Tapping `Buy` returns to the exact catalogue context;
native phone/browser Back remains unchanged. Medicine, Cart/Bulk order and
Tracking have no active cue and were not changed by this trial.

Runtime verification retained all seven Buy views, zero visible back arrows,
zero horizontal overflow and exact return to Wholesale `Retail supplies`.
This one-screen trial awaits explicit founder approval before any broader
rollout. The frozen Buy catalogue `v1` remains unchanged. No Flutter work,
Firebase/GCP action, deployment, commit, push or merge is authorized.

## Latest Buy HTML approval — return cues across former back-arrow views

The founder approved the one-screen Product-detail trial and directed its
rollout to each Buy view whose circular back arrow had been removed.

The editable HTML now applies the same word-free left-edge cue and 360 ms
entry transition to Product, Medicine, Retail Cart, Wholesale Bulk order,
legacy order review and Tracking. Product, Medicine and order review
temporarily highlight the persistent `Buy` destination with the accessible
name `Return to Buy catalogue`. Tracking highlights the context-correct
`Orders` destination with `Return to Orders`.

Catalogue and confirmation have no cue because they did not own the removed
back arrow. All cues are decorative, `aria-hidden` and non-interactive. Native
phone/browser Back remains unchanged.

Runtime replay covered both Retail and Wholesale variants of every affected
state. Each retained all seven Buy views, zero visible back arrows, the correct
return destination and zero horizontal overflow. Product, Medicine and Bulk
order returned to their catalogue context; Tracking opened Orders; browser
Back restored the exact Wholesale Product route.

The frozen Buy catalogue `v1` remains unchanged and checksum-clean. This
founder approval is limited to the return affordance and is not a complete Buy
HTML `FINAL`. No Flutter work, Firebase/GCP action, deployment, commit, push or
merge is authorized.

## Latest Buy HTML acceptance — Wholesale Bulk order

The founder explicitly accepted the connected Wholesale Bulk order shown after
adding POS thermal paper rolls from Product details.

The accepted screenwise checkpoint carries the product, variant, selected
pack, landed unit price and total; MOQ-aware quantity controls; supplier,
origin, destination, confirmation, dispatch and dated delivery; payment and
business-delivery choices; purchase-order terms; `Place purchase order`; add
products; and the approved word-free return cue.

The reviewed state contained one Rajasthan Retail Supply supplier group at
₹4,200 for two trade packs and 400 rolls, with zero visible back arrows and
zero horizontal overflow.

This is an accepted editable-HTML screen checkpoint, not the complete Buy HTML
`FINAL`. No new immutable reference, Flutter implementation, Firebase/GCP
action, deployment, commit, push or merge is authorized.

## Latest Buy HTML candidate — unified Cart

The editable Screen 09 Cart now supports Retail, Wholesale and combined
shopping in one destination:

- Retail keeps personal delivery, individual products and retailer-created
  Household Baskets;
- Wholesale keeps verified-workspace packs, supplier grouping, MOQ, landed
  price and purchase-order terms; and
- All shows both as two clearly separated order groups with one combined Cart
  total.

Combined checkout preserves separate Retail delivery and Wholesale supplier
commitments. It confirms the two resulting orders separately rather than
merging consumer and business terms. Retail and Wholesale quantities remain
independently editable from the combined Cart.

Founder-review routes:

- Retail:
  `http://127.0.0.1:8765/screens/09-buy.html?seed=retail-cart&view=basket&cart=retail`
- Wholesale:
  `http://127.0.0.1:8765/screens/09-buy.html?context=business&seed=1&view=basket&cart=wholesale`
- Combined:
  `http://127.0.0.1:8765/screens/09-buy.html?seed=combined-cart&view=basket&cart=all`

Runtime replay passed mode switching, independent quantity changes, totals,
combined consent, two-order confirmation and canonical-width horizontal
fitment. The existing missing normal-product Cart identifier was corrected so
Cart steppers now update the intended Retail or Wholesale line.

This unified Cart remains an editable founder-review candidate. It does not
change the immutable Buy catalogue `v1` and does not authorize Flutter,
deployment, commit, push or merge.

## Latest Buy HTML refinement — compact unified Cart

The unified Cart candidate has been compacted consistently in its `All`,
`Retail` and `Wholesale` modes. The duplicate global fulfilment card was
removed; its dated information remains available in the order header and each
product row. Header, mode switch, order grouping, product rows, supplier
groups, checkout choices, totals and add-products spacing are now denser while
all visible controls retain 44px minimum touch targets.

The Cart still supports all three intended purchase states: Retail-only,
Wholesale-only and a combined Cart containing products from both catalogues.
The combined mode keeps separate fulfilment commitments and produces separate
Retail and Wholesale order identifiers.

Browser replay passed the three mode switches, independent quantity changes,
combined two-order confirmation, horizontal fitment and touch-target checks.
The frozen Buy catalogue `v1` remains unchanged. The compact Cart remains an
editable founder-review candidate and does not authorize Flutter, deployment,
commit, push or merge.

## Latest Buy HTML candidate — professional commerce Cart redesign

Founder feedback rejected the spacing-only compact pass. The editable Screen
09 Cart has now been restructured into a flatter professional commerce
hierarchy: one concise header, one Retail/Wholesale/All switch, slim order
headers, dense line items, inline quantity controls, accessible icon removal,
flat supplier groups, compact checkout, a compact total and one final
two-action purchase bar.

Standard Retail and Wholesale product rows measure approximately 109–111px at
the canonical review width while retaining complete product, pack, unit,
seller or supplier, route, delivery, quantity and price information. The
Household Basket alone retains a taller row for its directly expandable
product manifest. All controls remain at least 44px.

Cart counts are now consistent product counts. When both Retail and Wholesale
contain products, the catalogue exposes one combined Cart entry with the
combined total; it opens `All` directly and the same Cart still exposes the
two individual modes. Combined checkout continues to create separate Retail
and Wholesale order identifiers and preserves their respective fulfilment
terms.

Browser replay passed catalogue return, combined entry, all three modes,
independent quantity changes, accessible removal, two-order confirmation,
horizontal fitment and touch-target checks. This remains an editable
founder-review candidate. The frozen Buy catalogue `v1` is unchanged; Flutter,
deployment, commit, push and merge remain unauthorized.

## Latest founder approval — professional unified Cart HTML

On 28 July 2026 the founder explicitly approved the professional Screen 09
Cart redesign after rejecting the earlier spacing-only compact pass. The
approval covers the Retail-only, Wholesale-only and combined Retail +
Wholesale states, the unified catalogue Cart entry, inline quantity/removal
controls, separate fulfilment terms and two-order combined confirmation.

This is an approved editable-HTML screen checkpoint. It has not yet been
frozen as a new immutable Buy reference because the complete Buy HTML has not
received founder `FINAL`. The existing frozen Buy catalogue `v1` remains
unchanged. Flutter, deployment, commit, push and merge remain unauthorized.

## Latest founder clarification — approved Buy screen count

On 28 July 2026 the founder clarified that the current Buy approval must be
reported as three screen families: Retail catalogue, Wholesale catalogue and
Cart. Retail and Wholesale include the approved shared bottom navigation and
compact/expanded left category rail. Cart includes the Retail-only,
Wholesale-only and combined Retail + Wholesale states.

This equals five approved visible review states when the three Cart modes are
counted separately. The rails are approved components, not extra screens.
Product-detail content, Medicine, Order confirmation and Orders/Tracking
remain pending full content approval. The approved word-free return cue is a
navigation-treatment approval only. Complete Buy HTML `FINAL`, a new immutable
complete-Buy reference, Flutter implementation, Firebase/GCP action,
deployment, commit, push and merge remain unauthorized.

## Latest Buy HTML delivery — complete end-to-end founder-review candidate

On 28 July 2026 the remaining Buy HTML journey was completed in the editable
screenbook without changing Screens 01–03 or implementing Flutter.

The founder-review candidate now covers Product details, Medicine and
prescription review, Retail/Wholesale/combined confirmation, first-class
Orders, Retail/Wholesale tracking, delivered-order reorder and price, stock,
service-area, payment, network and delivery-delay recovery. The previously
approved Retail catalogue, Wholesale catalogue and professional Cart remain
the accepted baseline.

Connected browser replay passed Product -> Cart -> payment -> confirmation ->
Orders -> tracking; combined Retail + Wholesale ordering; delivered Retail
reorder; Wholesale reorder-plus-add with refresh-stable business context; and
prescription -> pharmacist review -> precise quote -> Cart. Direct-route and
responsive audits covered 320 x 568, 390 x 844 and 430 x 932 with zero
horizontal overflow, no visible target below 44px and no internal/prototype
wording.

Founder review board:

`http://127.0.0.1:8765/quality/BUY-END-TO-END-FOUNDER-REVIEW-20260728.html`

Audit evidence:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\quality\generated\buy-end-to-end-audit-20260728.json`

The immutable approved Cart checkpoint is stored at
`approved-references/screens/09-buy-cart/v1` and all 11 checksum entries pass.
The immutable catalogue checkpoint remains unchanged.

State: `READY_FOR_COMPLETE_BUY_HTML_FOUNDER_REVIEW`. This is not complete Buy
HTML `FINAL`; it does not authorize Flutter, Firebase/GCP trial deployment,
commit, push or merge.

## Latest Buy HTML refinement — one Reorder and saved delivery addresses

On 28 July 2026 the editable Buy founder-review candidate replaced the
delivered-order `Reorder` plus `Reorder + add` pair with one Reorder action.
Shop, Wholesale and Medicine Reorder now open their existing editable Cart,
where quantity, remove and Add products remain available. Medicine Add
products returns to Medicine.

Cart delivery addressing now includes saved Home, Work, business, warehouse
and recipient choices; Add/Edit address; current-area prefill with manual
correction; and a recipient-address request choice for WhatsApp, MoolSocial
and the system share surface. A mixed Cart keeps separate Shop/Medicine and
Wholesale destinations.

Payment and purchase-order placement now open one compact address confirmation.
Changing either mixed-Cart destination returns directly to the same
confirmation, and confirmation is invalidated after an address change or a new
repeat purchase.

Direct browser replay passed:

- three delivered-order families with exactly one Reorder action each;
- Shop Reorder -> editable Cart with `−`, `+`, remove and Add products;
- Medicine Reorder -> editable Medicine Cart -> retained Medicine catalogue;
- saved Work selection and Cart refresh;
- automatic area prefill and editable address fields;
- recipient request through the WhatsApp choice;
- mixed Cart consent -> personal/business address confirmation -> business
  address change -> direct confirmation return -> two-order confirmation; and
- targeted manual fitment for compact 320 x 568 at 100% and 140% text,
  current iPhone, large Android, phone landscape and unfolded foldable states.

Founder review remains:

`http://127.0.0.1:8765/quality/BUY-END-TO-END-FOUNDER-REVIEW-20260728.html`

Targeted audit evidence:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\quality\generated\buy-reorder-address-audit-20260728.json`

State: `READY_FOR_REORDER_AND_ADDRESS_FOUNDER_REVIEW`. This extends the
complete Buy HTML candidate but is not complete Buy HTML `FINAL`; it does not
authorize Flutter, production messaging/location integration, Firebase/GCP
trial deployment, commit, push or merge.

## Latest Buy HTML refinement — exact Medicine approval and four-scope Cart

On 28 July 2026 the editable Screen 09 founder-review candidate closed the
prescription-product Cart gap. Every Medicine card now opens a rich product
detail state. A prescription medicine retains its exact product identity while
a saved or new prescription is reviewed; after the approval result, the same
medicine exposes Add to Cart and enters the Medicine Cart with its pharmacy and
delivery commitment.

The unified Cart now exposes four precise scopes: All, Shop, Wholesale and
Medicine. Every available scope carries its own product count and total and
isolates its order group. All preserves the three purchase families as
separate Shop, Medicine and Wholesale orders inside one Cart.

Delivery-address entry now carries recipient phone, house/building/street,
area, six-digit PIN and landmark; current-location, map-pin and Google Maps
choices; and recipient request choices for WhatsApp, MoolSocial and the device
share surface. The previous vague `Any app` label is absent.

Targeted connected-browser replay passed:

- Telmisartan 40 mg -> saved prescription -> pharmacist review -> verified
  product detail -> Add to Cart -> Medicine Cart;
- mixed Cart All -> Shop, Medicine and Wholesale scope isolation with
  independent counts and totals;
- address form, map-pin and named share-fallback states;
- Medicine fitment at 320 x 568, 360 x 800, 390 x 844 and 430 x 932;
- two-column Medicine fallback at 320 and three columns from 360 upward;
- zero horizontal overflow, zero clipped Medicine decision text and zero
  browser console errors in the tested states.

Founder review board:

`http://127.0.0.1:8765/quality/BUY-END-TO-END-FOUNDER-REVIEW-20260728.html`

Targeted evidence:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\quality\generated\buy-medicine-cart-address-audit-20260728.json`

State: `READY_FOR_MEDICINE_AND_UNIFIED_CART_FOUNDER_REVIEW`. This is still an
editable HTML candidate. It does not grant complete Buy HTML `FINAL`, freeze a
new immutable complete-Buy reference, authorize Flutter implementation,
Firebase/GCP deployment, commit, push or merge.

## Latest Buy HTML refinement — one Rx, ₹ Total and destination types

On 28 July 2026 the editable Screen 09 candidate replaced repeated
medicine-by-medicine prescription upload with prescription-level coverage.
Selecting the Heart & BP saved prescription links Telmisartan 40 mg and
Atorvastatin 10 mg into one pharmacist review. Approval enables Add to Cart on
both matched medicines; unrelated prescription medicines remain locked and
still require a matching prescription.

The review UI lists every linked medicine, shows a compact animated
linked/verified state and returns to the verified prescription catalogue in
one tap. This is an HTML interaction demonstration. Flutter/backend must
persist one prescription parent record plus server-authoritative medicine-line
matches, strength/form/quantity approval, expiry and audit records.

The combined Cart's customer-facing `All` tab is now **₹ Total**, carrying the
total product count and amount. Shop, Wholesale and Medicine remain separate
scopes. Delivery-address classification is now Home, Work, Third party and
Other place. Receiving person or business and receiving contact are separate,
required fields for every destination type.

Connected-browser replay passed:

- Telmisartan review displaying two linked medicines;
- one approval enabling Telmisartan and Atorvastatin Add-to-Cart;
- five unrelated prescription medicines remaining on Use Rx;
- ₹ Total displaying 4 products and ₹4,318 in the mixed Cart;
- Home, Work, Third party and Other place plus receiving-contact fields at
  320 x 780;
- the verified two-medicine summary at 390 x 844; and
- zero browser console errors in the replayed states.

Founder review board:

`http://127.0.0.1:8765/quality/BUY-END-TO-END-FOUNDER-REVIEW-20260728.html`

Targeted evidence:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\quality\generated\buy-rx-total-destination-audit-20260728.json`

State: `READY_FOR_RX_TOTAL_DESTINATION_FOUNDER_REVIEW`. This remains an
editable HTML candidate and does not authorize complete Buy HTML `FINAL`,
Flutter implementation, backend/clinical integration, Firebase/GCP
deployment, commit, push or merge.

## Latest Buy HTML refinement — bottom purchase controls and compact address

On 29 July 2026 the editable Screen 09 candidate standardized the product-card
hierarchy across Shop, Wholesale and Medicine. Product identity, variant,
pack, price, delivery commitment, named fulfilment partner and route now
precede the purchase action. `ADD`, `Use Rx` and quantity steppers occupy the
true bottom of their cards instead of interrupting decision information.

The three catalogue families now share one card type scale for kicker, title,
variant/composition, pack, price, delivery and fulfilment information. The
saved delivery-address control was reduced to its content width so the
chevron remains beside the address rather than consuming the complete header.

Focused browser verification passed Shop, Wholesale and Medicine at 320 × 568
with 100% and 140% text and at 390 × 844 with 100% text. Shop, Wholesale and
Medicine `ADD` interactions each changed to a quantity stepper while retaining
the bottom action position. JavaScript syntax, diff hygiene, approved UI locks,
the protected Social baseline and app brand integrity passed.

Editable source checksums:

- `screens/09-buy.html`:
  `084374AAE08EAF272A7E9E9832E0822602642467772AAFFB2D3B12E1CD072E42`
- `shared/moolsocial-buy-v2.css`:
  `2DA8DBB06A7B57386C50B0D8C33EC4BB41BECAC959610EB9FCFDC63E447470E8`
- `shared/moolsocial-buy-v2.js`:
  `790BD591A3D89738CAD2B7F1257A43888E8ACECE40C0097690217468BB914A95`

State: `READY_FOR_TILE_ALIGNMENT_FOUNDER_REVIEW`. This remains an editable HTML
candidate. It does not authorize complete Buy HTML `FINAL`, immutable freeze,
Flutter implementation, deployment, commit, push or merge.

## Latest Buy HTML refinement — context-specific Mool filter

On 29 July 2026 the editable Screen 09 candidate replaced the generic
single-choice ecommerce filter with a MoolSocial decision lens. The new
surface combines one delivery priority, one price priority and one
fulfilment/terms priority without leaving the product catalogue. It uses the
MoolSocial navy, saffron and green visual system, live result counts, subtle
motion and a compact result action.

Shop, Wholesale and Medicine now have isolated filter state, vocabulary,
matching and search scope:

- Shop: Anytime, Fast delivery, Today, Lowest delivered, Nearby sellers and
  Easy returns.
- Wholesale: Any schedule, Fastest delivery, Within 2 days, Lowest wholesale,
  Freight included, Flexible MOQ and Manufacturer.
- Medicine: Anytime, Fast delivery, Today, Lowest delivered, Without Rx,
  Nearby pharmacy and Manufacturer.

Direct browser replay verified combined selections in every catalogue,
separate restoration of Shop and Wholesale filter state, no Shop/Medicine
search leakage and no cross-surface option leakage. Shop, Wholesale and
Medicine filter sheets passed at 320 × 568 with 140% text: zero horizontal
overflow, zero clipped filter controls and zero effective targets below
44 px. Browser console output remained clean.

Editable source checksums:

- `screens/09-buy.html`:
  `C0E007651E9DBFC69B68DAF284FB8AE577DAE6ECE1E1725911BA4D5F84CCCF04`
- `shared/moolsocial-buy-v2.css`:
  `534CC8E241AE911313625233E007C6A085EB13A3EA4365AEBBEAE1A9A564ED6D`
- `shared/moolsocial-buy-v2.js`:
  `8984D3903BF694FB7F8093D2FE1086D996D17B333CB9E2D725CC6076EAD03BAF`

Evidence:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\quality\generated\buy-final-adversarial-ux-audit-20260729.json`

State: `READY_FOR_CONTEXT_FILTER_FOUNDER_REVIEW`. This remains an editable HTML
candidate. It does not authorize complete Buy HTML `FINAL`, immutable freeze,
Flutter implementation, deployment, commit, push or merge.

## Latest Buy HTML refinement — compact live Cart indicator

On 29 July 2026 the editable Screen 09 candidate replaced the full-width Cart
banner above the Buy dock with a compact floating control across Shop,
Wholesale and Medicine. Its resting state is 154 × 44 px and keeps the Cart
icon, total quantity and payable total visible while leaving the product grid
available for continued shopping.

After an Add action, the control expands to 270 × 44 px for 2.6 seconds to
identify the added product, then contracts automatically. Add feedback is no
longer duplicated in a separate toast. The mixed Cart preserves Shop,
Medicine and Wholesale together and opens directly from the same compact
control.

Connected-browser replay verified:

- Shop, Wholesale and Medicine Add actions;
- the temporary product-name state and automatic compact resting state;
- total-quantity and payable-total updates;
- mixed Cart scope and total after opening the indicator;
- 320 × 568 at 140% text, 390 × 844, 430 × 932 and 568 × 320;
- no horizontal overflow in the compact Cart cases; and
- zero direct Buy-screen console errors.

Editable source checksums:

- `screens/09-buy.html`:
  `90422D3FAC31967F3C8F7F4FA89930FA502FE6FC7B9A953CB55134C3C100200D`
- `shared/moolsocial-buy-v2.css`:
  `0B6167E2489DE016F4C90D4A2EF23CF83992EAFA0638353BE47CDE2B1B099FAE`
- `shared/moolsocial-buy-v2.js`:
  `CF7486659C548FC61E8657E36B51148EE7796765F4EEBF47B64A6AFA5C11A851`

Evidence:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\quality\generated\buy-final-adversarial-ux-audit-20260729.json`

State: `READY_FOR_COMPACT_CART_FOUNDER_REVIEW`. This remains an editable HTML
candidate. It does not authorize complete Buy HTML `FINAL`, immutable freeze,
Flutter implementation, deployment, commit, push or merge.

## Latest Buy HTML correction — always-visible purchase dock

On 29 July 2026 the founder rejected the temporary centred-Cart/paged-dock
experiment. The editable Screen 09 candidate now keeps Shop, Wholesale,
Medicine and Orders visible together at all times. Switching a catalogue,
opening Orders and vertical scrolling do not hide, replace or page any of the
four Buy subactions.

Cart has returned to the previously reviewed compact floating position above
the dock. It rests at 154 × 44 px with total quantity and payable total,
expands to 270 × 44 px for 2.6 seconds to identify an added product, and then
contracts without disappearing while products remain. The rejected centred
Cart action, pager, hidden subactions, swipe-page logic and related styling
are absent.

Connected-browser replay verified:

- all four Buy subactions visible before and after Shop, Wholesale, Medicine
  and Orders taps;
- all four subactions still visible after scrolling each catalogue and Orders;
- Shop, Wholesale and Medicine Add feedback plus persistent compact Cart;
- mixed Shop + Wholesale + Medicine totals in the same Cart indicator;
- Compact phone at 320 × 568 with 140% text, iPhone current at 390 × 844 and
  Compact landscape at 568 × 320; and
- zero horizontal overflow in the tested fitment cases.

Editable source checksums:

- `screens/09-buy.html`:
  `408A095C038DD88113FBE2F901291A9BDFDCD4DC7A4C2414A27BC51B05172341`
- `shared/moolsocial-buy-v2.css`:
  `0B6167E2489DE016F4C90D4A2EF23CF83992EAFA0638353BE47CDE2B1B099FAE`
- `shared/moolsocial-buy-v2.js`:
  `D380A5E50F50346C999D12824649C10094AF10D3CEB6F9B2A749ABC223E38026`
- `quality/BUY-DEVICE-FITMENT-20260728.html`:
  `C87562EF39318417C6339A2EFE44976D996940419A9FB4D81429ADEC74D9411B`

Evidence:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\quality\generated\buy-final-adversarial-ux-audit-20260729.json`

State: `READY_FOR_ALWAYS_VISIBLE_DOCK_AND_COMPACT_CART_FOUNDER_REVIEW`. This
supersedes the temporary centred-Cart experiment and remains an editable HTML
candidate. It does not authorize complete Buy HTML `FINAL`, immutable freeze,
Flutter implementation, deployment, commit, push or merge.

## Founder FINAL — complete Buy module permanently locked, 29 July 2026

The founder declared the entire Buy module approved and directed that it be
locked permanently and never touched without founder approval.

The immutable production authority is:

`approved-references/screens/09-buy-complete/v1`

Frozen source:

- `html/screens/09-buy.html`
  `408A095C038DD88113FBE2F901291A9BDFDCD4DC7A4C2414A27BC51B05172341`
- `html/shared/moolsocial-buy-v2.css`
  `0B6167E2489DE016F4C90D4A2EF23CF83992EAFA0638353BE47CDE2B1B099FAE`
- `html/shared/moolsocial-buy-v2.js`
  `D380A5E50F50346C999D12824649C10094AF10D3CEB6F9B2A749ABC223E38026`
- `quality/BUY-END-TO-END-FOUNDER-REVIEW-20260728.html`
  `DEB0034D3BE39B5BB2727E9EE40040D20E69A66324264105FA855D11219545CE`
- `quality/BUY-DEVICE-FITMENT-20260728.html`
  `C87562EF39318417C6339A2EFE44976D996940419A9FB4D81429ADEC74D9411B`

The reference contains the complete interaction contract, founder acceptance,
25-file checksum list, responsive/adversarial audit evidence and ten current
visual route captures. The earlier catalogue and Cart v1 references remain
unchanged historical checkpoints.

State: `FOUNDER_FINAL_HTML_LOCKED_NATIVE_FLUTTER_V2_AUTHORIZED`.

Native Flutter is authorized only as an isolated V2 presentation using
existing non-UI owners. The accepted HTML and legacy Flutter Buy presentation
are read-only. Flutter is not accepted and no deployment is authorized until
exact parity, affected tests, two full regressions, device fitment, exact APK
checksum verification on the connected OPPO and founder acceptance pass.

## Latest native Buy checkpoint — R19 device-verified founder-review baseline

On 30 July 2026 the broad R18 OPPO replay completed the native Shop,
Wholesale, Medicine, prescription, Cart, Checkout, address, payment, Orders,
tracking, scanner, account and navigation checks. That replay proved one
remaining defect: Save feedback was correctly near the product interaction but
was still too wide. The R18 evidence was preserved and the smallest correction
was verified as R19.

The exact R19 candidate and pulled installed OPPO base APK share SHA-256:

`99D2032A4D173E13471ABACFD54BE36262F11552D99B8B882CB407723DB183BE`

R19 passed Flutter analysis, two independent 83/83 affected regressions, 64
responsive Android/iOS-size and 140%-text captures, the 154-route interaction
contract, customer-copy, brand, Screens 01–03, founder-FINAL Buy reference and
exact protected-Social-tree gates. The protected Social tree remains:

`54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

Durable handoff:

`docs/quality/BUY-V2-R19-BASELINE-HANDOFF-20260730.md`

Durable candidate and baseline manifest:

`artifacts/quality/buy-flutter-r19-founder-remediation-oppo-20260730-09`

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_BASELINE`. Founder acceptance, commit,
push, deployment, publication and production release remain pending. Until
founder review, make no further subjective Buy UI/UX, visual, layout, brand,
colour, motion or animation changes.

## Overnight post-R19 hardening and resumed handoff — 30 July 2026

Post-baseline Tickets `BUY-FV2-053` through `BUY-FV2-059` are complete with
focused verification, two same-source affected regressions per ticket,
protected gates and checksum-matched OPPO evidence. They add fail-closed
external identifiers, independent vertical contracts, congruent order-card
actions, safe prescription IDs, atomic vertical-safe reorder restoration,
checkout/order projection coverage and a payment-method allowlist.

Latest installed candidate: R25 versionCode `2026073025`; candidate and
device-computed installed SHA-256:

`2CF071BB363D477908649C52835692BEE5403838C71A07690E203175670E8DB5`

The protected Social tree remains:

`54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

Full handoff:

`docs/quality/BUY-OVERNIGHT-HANDOFF-20260730.md`

Complete final repository status and gates:

`artifacts/quality/buy-overnight-handoff-20260730-17`

The founder subsequently requested Amazon/Flipkart comparison captures and a
new cross-vertical layout proposal informed by Blinkit/Zepto. Existing
Blinkit/Zepto captures were inspected, but the OPPO disconnected before fresh
Amazon/Flipkart capture. No subjective UI code was changed. Resume with device
reconnection and founder-review proposal before modifying the R19 visual
baseline.

At 10:19 IST the founder explicitly canceled the earlier 07:30/08:00 cutoff
and shutdown instructions and resumed work. No Windows shutdown is pending.

## Latest native Buy checkpoint — R27 market hierarchy and brand correction

On 30 July 2026 the founder authorized a new shared Buy hierarchy informed by
the preserved Zepto, Blinkit, Flipkart and Amazon layout observations. Tickets
`BUY-FV2-060` through `BUY-FV2-062` now separate the compact brand/context/
account row from search, add shallow vertical-specific discovery and
MoolSocial-owned continuation cards, and make the active cart a prominent
destination-aware conversion action.

The first R26 candidate is preserved as rejected evidence because its compact
brand treatment clipped to `MoolSo` on the connected OPPO. R27 uses the compact
M watermark and visibly names the product in the shared context:
`MoolSocial · Deliver to`, `MoolSocial · Buying for`,
`MoolSocial · Licensed pharmacy`, `MoolSocial · Purchases` and
`MoolSocial · Your account`.

R27 source fingerprint:

`DBB4BBA084FC5522E30B7AF51952A9A3BE637378DD7897D5D9B15D772EBE22EC`

The exact R27 candidate and pulled installed OPPO base share SHA-256:

`8192B002A7F0372CC3A10872A26C498D0DC4E28FA3AF5531453A0B0528679BFF`

R27 passed full Flutter analysis, the focused 38/38 screen suite, two
same-source 102/102 affected regressions, the 64-image responsive matrix,
founder-FINAL Buy reference, customer-copy, 154-route interaction, approved
lock, brand and protected Social gates. The protected Social tree remains:

`54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

The checksum-matched OPPO replay verified settled Shop, category, promotion,
search, scanner, account, Wholesale, Medicine, Orders, Shop cart, aggregate
cart and live order tracking. Final startup diagnostic reports candidate id
`BUY-R27-MARKET-BRAND`; no app fatal exception, ANR, `E/flutter` or unhandled
Flutter exception was found.

Durable handoff:

`docs/quality/BUY-V2-R27-MARKET-BRAND-HANDOFF-20260730.md`

Durable evidence:

`artifacts/quality/buy-flutter-r27-market-brand-oppo-20260730-20`

State: `FOUNDER_REJECTED_SUPERSEDED_BY_R28`. The founder's OPPO review found
the compact M squeezed/corrupted and the horizontal category rail too costly
to traverse. Preserve R27 evidence; do not treat it as an accepted baseline.

## Latest native Buy checkpoint — R28 brand proportion and category discovery

On 30 July 2026 Tickets `BUY-FV2-063` through `BUY-FV2-065` corrected the
founder-proven R27 defects without changing HTML, Screens 01–03, Social,
category identifiers, product filters or vertical contracts.

R28 keeps the unchanged 50 × 44 brand tile but paints the M into a balanced
landscape `32 × 24` box. Shop, Wholesale and Medicine no longer expose a long
horizontal category rail. One stable current-category control opens a
vertically scrolling, locally searchable two/three-column panel; one category
tap selects and closes it. The final tiles use an icon-above-centred-label
composition so the real OPPO shows complete category names. Opening Saved
after a category selection resets that vertical to its complete Saved lens.

The first R28 device artifact is preserved as unaccepted evidence because the
horizontal tile composition still truncated category labels. The corrected
final candidate uses:

- Source fingerprint:
  `E080C090A18C97800D89381D93AC25815027E9EE2CF15160FE8DD493C32A31FD`
- Candidate id: `BUY-R28-BRAND-CATEGORY-TILE-FIX`
- Version code: `2026073028`
- Candidate, device-computed package and pulled installed APK SHA-256:
  `D3813583A90D102B51C9001AC15638710D93E727EA1A4337023EFF3919E95A8F`

Final verification passed full Flutter analysis, the focused 39/39 screen
suite, 65 responsive Android/iOS-size and 140%-text captures, two same-source
103/103 affected regressions, the 154-route interaction contract, customer
copy, founder-FINAL reference, approved UI locks, brand integrity and the exact
protected Social tree:

`54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

The checksum-matched OPPO replay verified the corrected M; Shop, Wholesale and
Medicine category panels; late-category search and selection; and complete
Saved recovery. Startup diagnostics identify the exact candidate. No app
fatal exception, ANR, `E/flutter` or unhandled Flutter exception was found.

Durable handoff:

`docs/quality/BUY-V2-R28-BRAND-CATEGORY-HANDOFF-20260730.md`

Durable evidence:

`artifacts/quality/buy-flutter-r28-brand-mark-proportion-oppo-20260730-21`

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`. Founder visual acceptance,
commit, push, deployment, publication and production release remain pending.

## Latest native Buy checkpoint — R29 compact commerce and stable depth transitions

On 30 July 2026 Tickets `BUY-FV2-066` through `BUY-FV2-073` completed the
founder-authorized compact-commerce correction across Shop, Wholesale,
Medicine, Orders, Cart and Buy Chat.

R29 provides one compact category action, a dock-anchored searchable glass
category owner with semantic icons, adaptive shared search, product and Cart
quantity steppers, repeat-tap return for Account and Buy Chat, and a
high-contrast shared MoolSocial mark. It preserves the established vertical
identifiers, cart/session logic, backend contracts and protected Social tree.

The OPPO replay also proved and corrected one native rendering defect during
heavy Buy depth changes. The final staged transition paints the complete
branded header with honest progress, prebuilds the destination and then
reveals it. Captured Wholesale, Medicine and MoolSocial Assist opening frames
show the complete header; Chat repeat returns to the exact live tracking
state.

Final R29 identities:

- Source fingerprint:
  `B7911CDD3D770F3E7260C18B7B2388E92C59819A266147CBF4D70E248E54CCCB`
- Candidate id: `BUY-R29-COMPACT-COMMERCE`
- Version code: `2026073029`
- Candidate and pulled installed OPPO APK SHA-256:
  `3136A7CFA4EB1C3A001422F18C8C49CF1CE775F673EA68EFF71BC1D4956918CD`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

Final verification passed full Flutter analysis, the corrected focused `84/84`
suite, 73 responsive Android/iOS-size and 140%-text captures, two unchanged-
source `113/113` complete regressions, the 154-route interaction contract,
customer-copy Flutter and nine-state HTML gates, founder-FINAL reference,
approved UI locks, brand integrity, Git-diff hygiene and the exact protected
Social baseline. The installed checksum matched, startup reached authenticated
`stage=ready`, and the runtime audit found no app fatal exception, package ANR,
`E/flutter` or unhandled Flutter exception.

Durable handoff:

`docs/quality/BUY-V2-R29-COMPACT-COMMERCE-HANDOFF-20260730.md`

Durable evidence:

`artifacts/quality/buy-flutter-r29-compact-commerce-oppo-20260730-22`

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`. The OPPO is left on Shop
with the category glass open. Founder visual acceptance, commit, push, deploy,
publication and production release remain pending.

## Founder review after R29 — approved iteration baseline with open R30 backlog

On 30 July 2026 the founder reviewed R29 on the connected OPPO and approved it
as the current Buy UI/UX iteration baseline, subject to further UI/UX changes.
This is not immutable final-reference acceptance, production release
acceptance, backend-start authorization, commit, push, deploy or publication.

One P0 functional defect remains open:

- Shop Cart entry appears separate from Wholesale and Medicine after product
  addition. Ticket `BUY-FV2-074` requires one aggregate Cart entry while
  retaining explicit family-specific fulfilment, prescription and checkout
  sections.

The founder also directed:

- remove customer-visible `Verified` wording and establish a stronger
  role-based Mool partner/fulfilment vocabulary;
- add honest motion and action acknowledgement across all Buy states;
- introduce responsive themes based on vertical and screen type;
- create an unmistakable animated MoolSocial identity with a more accurate
  Indian-tricolour relationship;
- introduce restrained 3D commerce motion and greater liveliness;
- keep real changing product information active inside stable product tiles;
- add first-party MoolSocial promotions, sponsored/other ad cards and safe
  inline video-ad formats; and
- finish the connected R30 founder review before Buy backend implementation
  begins.

Tickets `BUY-FV2-075` through `BUY-FV2-085` record the terminology, motion,
theme, identity, 3D, live-product, promotion, advertising, accessibility,
performance and sequence gates. No R30 ticket was implemented in this
registration turn.

The Buy inventory already contains 103 `Verified` match lines across six
production files. The final glossary requires a founder decision because
commercial role, fulfilment role and real regulatory facts such as licensed
pharmacy must remain distinct. Protected Social stays frozen.

Durable decision:

`docs/quality/BUY-V2-R29-FOUNDER-ITERATION-APPROVAL-AND-R30-DIRECTION-20260730.md`

State:
`FOUNDER_APPROVED_ITERATION_BASELINE_WITH_OPEN_R30_UIUX_BACKLOG`.

## R30 implementation authorized — product detail, trust, reviews and tap repair

The founder authorized R30 implementation and added connected-device findings:

- some deeper Buy screens/taps do not respond correctly;
- Shop, Wholesale, Medicine and Orders need professional, role-aware product
  detail;
- product pages must show original product imagery, the named Mool partner,
  meaningful trust/service factors, detailed product facts, customer reviews
  and issue reporting; and
- small original product imagery is required in the three-column grid.

Tickets `BUY-FV2-086` through `BUY-FV2-092` now cover the tap audit,
role-aware detail, evidence-based trust, review/report owner, original imagery,
order-time item detail and cross-role acceptance gate.

Six Amazon Bazaar screenshots captured by the founder in OPPO Photos were
pulled into the additive R30 evidence directory. They are inspiration only for
information hierarchy: image first, delivery/partner/trust, specifications,
reporting, reviews and stable purchase actions. No Amazon image, component,
brand treatment, copy or production logic may be copied.

R30 evidence:

`artifacts/quality/buy-flutter-r30-motion-product-detail-oppo-20260730-23`

State: `R30_IMPLEMENTATION_AUTHORIZED_IN_PROGRESS`.

## Latest native Buy checkpoint — R32 media-first discovery and motion foundation

On 30 July 2026 the founder authorized the Zepto-inspired product-media
hierarchy and the compatible motion foundation to proceed together. R32 uses
only the useful information hierarchy; no Zepto branding, asset, copy,
component styling or business behaviour was copied.

Default Shop, Wholesale and Medicine landings now show first-party promotions,
one horizontal image-led product collection and then the dense three-column
catalogue. Search, category and Saved states retain the direct dense-grid
workflow. Product detail uses a responsive dominant gallery. Shared press and
quantity-state feedback is tokenized and reduced-motion aware, with no fake
waiting or perpetual animation.

Final R32 identities:

- Source fingerprint:
  `B8D6AC0DD111F31652F171709C6FC827E98BF383FE7D4F142A78A2B850D01B73`
- Candidate id: `BUY-R32-DISCOVERY-MOTION`
- Version: `1.0.0-r32` (`versionCode 2026073037`)
- Candidate and pulled installed OPPO APK SHA-256:
  `A79E01076114B99EAB8CA76B6C3104DB6DA2BC28514018EA871B54F2A1268BB8`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

Final verification passed full Flutter analysis, the focused `56/56` screen
suite, 73 responsive Android/iOS-size and 140%-text captures, two unchanged-
source Buy regressions of `95` passed and `2` intentionally skipped, the
154-route interaction contract, customer-copy Flutter and nine-state HTML
gates, founder-FINAL reference, approved UI locks, brand integrity, Git-diff
hygiene and the exact protected Social baseline. The installed checksum
matched again after replay. Startup reached authenticated `stage=ready`; the
complete replay audit found no app fatal exception, package ANR, `E/flutter`
or unhandled Flutter exception.

The limited two-frame Android graphics sample is not broad performance proof.
The inherited 75 unrelated stale repository goldens were not overwritten or
accepted, so R32 does not claim a full repository golden pass.

Durable handoff:

`docs/quality/BUY-V2-R32-DISCOVERY-MOTION-HANDOFF-20260730.md`

Durable evidence:

`artifacts/quality/buy-flutter-r32-discovery-motion-oppo-20260730-24`

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`. Ticket `BUY-FV2-093` is
implemented and device verified. Tickets `BUY-FV2-076`, `BUY-FV2-079` and
`BUY-FV2-084` have a verified foundation but remain open for the heavier
motion, 3D, theme, advertising and performance scope. Founder visual
acceptance, commit, push, deploy, publication and production release remain
pending.

## Latest native Buy checkpoint — R33 responsive search, media, account and independent lanes

On 30 July 2026 the founder authorized the R33 functional and presentation
repairs in tickets `BUY-FV2-094` through `BUY-FV2-104`. The latest refinement
replaced the boxed active search with one compact, responsive search surface:
no Back arrow, no nested outline, a query-dependent clear action, a compact
finish action, retained query, Android Back support and reduced-motion
behavior. Shop, Wholesale, Medicine and Orders use the same interaction while
retaining their independent search contracts.

Final R33 identities:

- Source fingerprint:
  `7B293FB7D81F840BE42902A6C9F8221953D17FAA516D2656C7A11B2C5862145F`
- Candidate id:
  `BUY-R33-SEARCH-MEDIA-ACCOUNT-INDEPENDENT-LANES-RESPONSIVE-SEARCH-DEVICE`
- Version: `1.0.0-r33.4` (`versionCode 2026073042`)
- Candidate and pulled installed OPPO APK SHA-256:
  `9DC65FC11EA5DD3CE086457AE85ED034D396F9E8953E2E2B7B36E019E2709A15`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

Final verification passed full Flutter analysis, focused responsive-search
tests, two unchanged-source Buy regressions of `104` passed and `3` opt-in
capture generators skipped, responsive Android/iOS-size and 140-percent-text
review, the 154-route interaction contract, customer-copy Flutter and
nine-state HTML gates, founder-FINAL reference, approved UI locks, brand
integrity and the exact protected Social baseline.

The checksum-matched OPPO replay covered responsive search in all four
destinations, Android keyboard/Back precedence, background/resume, search to
Account state ownership, Account/Orders routing and independent upper/lower
lane movement in Shop and Wholesale. Medicine exposes separate upper/lower
lane owners; its current remaining fixture has one card in each lane, while
the earlier checksum-matched R33 multi-result replay records their independent
movement using the unchanged implementation. The final runtime audit found no
fatal Flutter exception, `RenderFlex`, overflow or disposed-state callback.

The earlier `1.0.0-r33.3` build is preserved as rejected diagnostic evidence
because of an inconsistent device-review flag combination. It is not the
review candidate.

Durable handoff:

`docs/quality/BUY-V2-R33-RESPONSIVE-SEARCH-MEDIA-ACCOUNT-LANES-HANDOFF-20260730.md`

Durable evidence:

`artifacts/quality/buy-flutter-r33-search-media-chat-oppo-20260730-25`

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`. The exact R33.4 APK is
installed on the connected OPPO and the app is left on Shop. Founder visual
acceptance, production baseline promotion, commit, push, deploy, publication
and production release remain pending.

## Latest native Buy checkpoint — R34 automatic vertical search suggestions

After the R33.4 handoff, the founder directed expanded search to reveal useful
searches automatically while keeping Shop, Wholesale and Medicine in separate
buckets. Ticket `BUY-FV2-105` is implemented.

The final UI shows `Shop suggestions`, `Wholesale suggestions` or
`Medicine suggestions` immediately below the empty focused field. The
founder-rejected `Try...` / `Tap...` instruction copy is absent. Each bucket
contains up to four real product titles from the active destination,
category/filter selection. Tap and typing share the same existing query owner.
No recent, popular, trending, recommendation, personalization or backend
behavior is claimed.

Final R34 identities:

- Source fingerprint:
  `8C8028A9ADB7665E7047D4B80B5B5CDFD09920A23402338837F3B9ADE6023AF2`
- Candidate id: `BUY-R34-VERTICAL-SEARCH-SUGGESTIONS-DEVICE`
- Version: `1.0.0-r34` (`versionCode 2026073043`)
- Candidate and pulled installed OPPO APK SHA-256:
  `9010320F14F228DFC70B60431BE06D1F3E2BDD978AA80BA2B84213F510D926A2`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

Full Flutter analysis, focused tests, the `91/91` affected suite, 12 final
responsive Android/iOS-size captures, two same-source `106/106` Buy
regressions with four opt-in capture generators skipped, protected reference,
copy, brand, Social and 154-route gates all passed.

The checksum-matched OPPO replay proved Shop 500 g versus Wholesale 10 kg
results from the same visible suggestion term, Medicine suggestion selection,
direct `pain` typing, clear-to-suggestions and hot resume. The final runtime
audit was clean. The app is left on the expanded empty Shop search with all
four Shop suggestions visible.

Durable handoff:

`docs/quality/BUY-V2-R34-VERTICAL-SEARCH-SUGGESTIONS-HANDOFF-20260730.md`

Additive evidence:

`artifacts/quality/buy-flutter-r33-search-media-chat-oppo-20260730-25`

State: `FOUNDER_APPROVED_PROTECTED_BUY_BASELINE`. On 31 July 2026 the founder
approved the checksum-matched R35.1 OPPO candidate and authorized a scoped
local baseline commit. Push, deployment, publication and production release
remain separate and unauthorized.

## Latest nonvisual Buy checkpoint — R35.1 protected runtime gate

Founder-approved R35.1 is committed locally at
`34045d33869e13ac17b03d59c2625f2d91a1fb92`. Ticket `BUY-FV2-107`
machine-protects its exact 28-file native Buy runtime tree:

`f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`

The new `scripts/check-buy-protected-baseline.ps1` gate passes the real
repository and an isolated exact copy, rejects an isolated source mutation,
and rejects an added runtime file. It is wired into `scripts/check.ps1`
alongside the existing protected Social gate.

Full Flutter analysis, two `106/106` Buy regressions and all protected
reference, copy, brand, Social, Buy and 154-route gates passed. Four opt-in
capture generators were skipped in each normal regression run. No Flutter
runtime, approved HTML or protected Social file changed, so no APK rebuild or
OPPO reinstall was required.

Durable handoff:

`docs/quality/BUY-V2-R35-1-PROTECTED-BASELINE-GATE-HANDOFF-20260731.md`

Additive evidence:

`artifacts/quality/buy-protected-baseline-r35-1-20260731-28`

Future runtime, motion, UI, routing or protected-media changes require founder
review and a new additive baseline. Tests, documentation and read-only
analysis may advance while the protected runtime tree remains exact.

## Latest native Buy checkpoint — R35.1 dense flat autocomplete

Ticket `BUY-FV2-106` is implemented and checksum-matched on OPPO. R35 removed
the founder-rejected suggestion heading, count, scope/instruction text,
decorated card, gradient and oversized icon, but its first device replay
proved that 48-pixel rows remained too open. The founder then directed denser
rows.

R35.1 uses the accessibility-safe 44-logical-pixel target, no top list padding
and only 8 pixels of trailing padding. Each row contains only a truthful search
icon and catalogue-derived term. Shop, Wholesale and Medicine remain separate;
Orders retains its established order-search behavior.

Final R35.1 identities:

- Source fingerprint:
  `2158C38B2F9905C0C76EB2C1528F654BCAB1E25A7B090FB78837F9E749DD9A74`
- Candidate id:
  `BUY-R35-1-DENSE-FLAT-SEARCH-SUGGESTIONS-DEVICE`
- Version: `1.0.0-r35.1` (`versionCode 2026073045`)
- Candidate and pulled installed OPPO APK SHA-256:
  `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

Focused and full analysis, 12 new Android/iOS-size captures, two same-source
`106/106` Buy regressions with four opt-in capture generators skipped,
protected references, copy, brand, Social and 154-route gates all passed.

The OPPO replay measured all rows at 88 physical pixels on the device's 2.0
density, proved Shop 500 g versus Wholesale 10 kg separation, Medicine tap and
direct typing, clear and empty focused Shop hot resume. The final runtime audit
was clean. The app is left on the dense empty Shop search list.

Durable handoff:

`docs/quality/BUY-V2-R35-1-DENSE-FLAT-SEARCH-SUGGESTIONS-HANDOFF-20260731.md`

Additive evidence:

`artifacts/quality/buy-flutter-r35-1-dense-flat-search-suggestions-oppo-20260731-27`

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`. Founder visual acceptance,
production baseline promotion, commit, push, deploy, publication and
production release remain pending.
