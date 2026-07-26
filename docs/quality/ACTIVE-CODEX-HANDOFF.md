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
