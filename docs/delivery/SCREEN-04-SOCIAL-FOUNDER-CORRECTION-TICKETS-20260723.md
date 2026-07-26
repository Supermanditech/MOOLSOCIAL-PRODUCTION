# Screen 04 Social founder-correction tickets — 23 July 2026

Status: **ACTIVE — HTML founder-correction intake; no founder `FINAL`, freeze,
Flutter authority or production promotion**

These tickets record the founder's latest Screen 04 Social correction before
any new product implementation. They supersede the current v8 interaction
ownership only for the editable v9 candidate. Immutable reference v8, its
checksums, native APK and retained evidence remain unchanged as history.

## Authority and preservation boundary

- Branch: `remediation/prototype-conformance-2026-07-20`.
- Preserved immutable HTML authority:
  `approved-references/screens/04-universal-focus-shell/v8`.
- Preserved v8 HTML SHA-256:
  `0997F3AD7ADAAD76EB3FD7F5A96CF63C1D691413DA92F368FC4EC005E0D86410`.
- Preserved v8 native APK SHA-256:
  `37F8E3718E4E7A53D1DB8949B4D1A14D3C6D77039DB5841442F020CBB07C09A1`.
- Screens 01–03, v8, earlier Screen 04 references, approved assets,
  checksums, tests and evidence remain read-only.
- The editable Screen 04 HTML must be corrected and presented for founder
  review before a new reference can be frozen or native Flutter can change.

Founder-supplied interaction references inspected for this ticket set:

- `codex-clipboard-d410102b-7062-402e-8e78-6a4036503c9f.png`;
- `codex-clipboard-ed531902-f3bb-4e15-adeb-0042e91b90f9.png`;
- `codex-clipboard-b00dfe3d-8b6b-4912-9de7-76337b18cf3d.png`;
- `codex-clipboard-255c355b-7f09-4bd6-b980-e285f537f366.png`;
- `codex-clipboard-b07c27cc-4cb6-4efa-9543-a1111e2a66aa.png`; and
- `codex-clipboard-45100f3b-4937-43c5-b327-616d4f40f063.png`.

The Instagram and X screenshots are behavioral references only. MoolSocial
must not clone their exact composition, trade dress, wordmarks, proprietary
icons, colours or trademarks. Provider permission dialogs and provider-only
mode selectors shown in those screenshots are not MoolSocial product
requirements.

### Founder screenshot decision register

| Founder reference | Behavior retained for MoolSocial | Explicit non-requirement |
| --- | --- | --- |
| `codex-clipboard-d410102b-7062-402e-8e78-6a4036503c9f.png` | A selected Reel opens one immediate vertical editor with Audio, Text, Overlay, Filter, Edit and Ratio/Crop controls plus one `Next` action | Instagram wordmark, colours, suggested-audio treatment and notification prompt are not copied |
| `codex-clipboard-ed531902-f3bb-4e15-adeb-0042e91b90f9.png` | Reel creation starts with Camera and recent media immediately available; multi-select and album access remain one tap away | Instagram's `POST / STORY / REEL / LIVE` mode selector is not reproduced |
| `codex-clipboard-b00dfe3d-8b6b-4912-9de7-76337b18cf3d.png` | The contextual Reel create action is discoverable on the Reel surface itself without opening another Social sub-action | Instagram navigation, stories row, provider marks and proprietary icons are not copied |
| `codex-clipboard-255c355b-7f09-4bd6-b980-e285f537f366.png` | Feed remains content-first and exposes a persistent lower-thumb-zone create action | X wordmark, trade dress, subscription treatment, colours and advertising layout are not copied |
| `codex-clipboard-b07c27cc-4cb6-4efa-9543-a1111e2a66aa.png` | One tap opens a keyboard-ready post composer with media, GIF, poll and audience/reply controls in the same state | X-specific feature names, location/flag controls and proprietary icons are not copied |
| `codex-clipboard-45100f3b-4937-43c5-b327-616d4f40f063.png` | A focused public post preserves complete text, media, metrics, engagement and a bottom reply composer; Back restores the prior Feed state | The source provider's exact post chrome, typography, colours and branding are not copied |

## Founder ownership override

The v9 candidate uses the following single-owner model:

| User intent | Visible owner | Required result |
| --- | --- | --- |
| Find a Reel or creator | `Reels` | Compact top-left search expands in place and returns Reels and creator accounts |
| Create a Reel | contextual `+` in `Reels` | Camera/gallery selection opens directly, followed by the same Reel editor |
| Publish a short update | contextual `+` in `Feed` | Keyboard-ready direct composer opens without a format landing page |
| Add media to a Feed post | Feed composer | Photo/GIF, Carousel or `Your Reel` attaches in place |
| Ask or test audience response | Feed composer | Image Poll, Quick Poll and Quiz expand in the same composer |
| Watch owned long-form video | Not offered | MoolSocial does not add a general owned long-form Feed/video upload |

`Create` is therefore a removal candidate, not an approved removal. It may
disappear from the visible Social sub-action rail only after every responsibility
and existing entry path has a mapped owner, compatibility handling and passing
navigation proof. Internal routes, stored state and shared non-UI owners must
remain compatible.

## Ticket register

| Order | Ticket | Scope | Status |
| --- | --- | --- | --- |
| 1 | `FND-U04-REEL-009` | Move contextual Reel creation into Reels and implement the direct capture/gallery/editor journey in HTML | Implemented in editable v9 HTML — verification pending |
| 2 | `FND-U04-FEED-010` | Make Feed content-first and place the direct composer plus inline post formats in the thumb zone | Implemented in editable v9 HTML — verification pending |
| 3 | `FND-U04-CREATE-011` | Prove responsibility migration and determine whether the visible Create sub-action can be removed safely | Implemented in editable v9 HTML — compatibility proof pending |
| 4 | `FND-U04-SEARCH-012` | Add compact top-left expandable Reel/creator search with complete focus and Back behavior | Implemented in editable v9 HTML — verification pending |
| 5 | `FND-U04-QA-013` | Audit the v9 HTML interaction, copy, fitment, compatibility and navigation contract | In progress — founder-review evidence pending |
| 6 | `FND-NATIVE-014` | Freeze founder-final v9 and implement/verify isolated native Flutter parity | Blocked by explicit founder `FINAL` |

## `FND-U04-REEL-009` — Reels owns Reel creation

### Required HTML behavior

- Replace the old Create-owned Reel entry with one contextual `+` action on
  the MoolSocial Reels surface.
- Keep the search entry at the top-left; place the create action separately so
  the two controls never compete or overlap.
- One tap on Reel `+` opens the real creation state directly. Do not show a
  decorative `Create a Reel` landing page or a second format chooser.
- The first creation state exposes Camera and recent media immediately, with
  album selection, close and a clear continuation action.
- Selecting Camera requests only required system permissions and proceeds to a
  vertical capture surface. A denied permission has an owned recovery path.
- Selecting media proceeds to the same Reel editor. Incompatible media uses
  crop/fit inside the standard Reel canvas; it does not create arbitrary output
  ratios.
- The editor provides direct actions for Audio, Text, Overlay, Filter,
  Trim/Edit and Crop/Fit, plus add/replace/remove clip or audio where applicable.
- The preview remains unobstructed and the only primary continuation is
  `Next`, leading to caption, audience, commerce disclosure and publication.
- Cancel, system Back and interrupted-return paths restore the exact prior Reel
  or editor state without losing a valid draft silently.

### Acceptance

- Reel creation is discoverable from Reels without visiting another Social
  sub-action.
- Every visible control has a real state/result and a minimum 44×44 logical
  touch target.
- No provider name, provider-only `Post/Story/Reel` selector, sample copy,
  design note or permission commentary appears in MoolSocial UI.
- Published owned Reel returns to the MoolSocial Reel sequence and is
  attributable to the authenticated Social account/session owner.

### Required creation-state matrix

| State | Required result |
| --- | --- |
| Camera idle / requesting / ready | One owned capture surface, honest progress and a usable capture action |
| Camera denied / settings return | Recovery preserves the draft and returns to the same capture state |
| Camera unavailable | Gallery remains available and retry does not create a dead end |
| Call, lock, app switch or interruption | Camera stops safely; return restores an explicit interrupted state and the valid draft |
| Album return / cancellation | Selected media returns to the editor; cancellation returns to the unchanged capture state |
| Incompatible source ratio | Crop/Fit keeps the standard vertical Reel canvas |
| Clip add / replace / remove | The clip list, preview and count update together without an invalid empty publication |
| Audio select / replace / remove | The selected audio state remains visible and reversible |
| Text / Overlay / Filter / Edit-Trim / Crop-Fit | Each tool exposes its real control and visibly persists the selected result |
| Caption / audience / commerce | Validation is owned in the same publication state |
| Publication | The newly authored Reel is the immediate public result in the MoolSocial Reel sequence |

### Named Reel creation and recovery states

The editable v9 candidate and later native parity must use the following named
states in verification evidence. The names are test/evidence identifiers and
must never appear as customer-facing copy.

| State ID | Entry or trigger | Required customer-visible result | Recovery or exit |
| --- | --- | --- | --- |
| `reel.home.ready` | Reels opens | Current Reel, compact search and separate create `+` are visible | Back returns to the prior Universal owner |
| `reel.search.open` | Tap compact search | Search expands without covering create, Reel content or the Universal rail | Close/Back returns to the exact Reel, filter and sequence index |
| `reel.create.source` | Tap Reel `+` | Camera and recent media are immediately actionable | Close returns to `reel.home.ready` |
| `reel.camera.requesting` | Choose Camera | Honest permission/progress state; no false ready preview | Denial moves to `reel.camera.denied`; success moves to `reel.camera.ready` |
| `reel.camera.ready` | Permission granted and camera available | Live vertical capture, gallery alternative and close action are usable | Capture enters `reel.camera.recording`; gallery enters picker |
| `reel.camera.recording` | Start capture | Recording state and stop action are unambiguous | Stop creates a real clip and enters `reel.editor.ready` |
| `reel.camera.denied` | Permission denied | Camera is unavailable without blaming connectivity; gallery remains usable | `Try camera again` retries; native settings return restores the same draft |
| `reel.camera.unavailable` | No usable camera or capture failure | Owned unavailable message, retry and gallery alternative | Retry cannot duplicate streams or lose selected media |
| `reel.camera.interrupted` | Call, lock, app switch, track end or recorder error | Capture stops safely and the valid draft remains intact | Return presents explicit resume/retry and restores the exact creation origin |
| `reel.gallery.open` | Choose recent media/album | Native picker opens with the supported media contract | Picker cancellation returns to the unchanged source state |
| `reel.gallery.selected` | Select one or more valid clips | Selected clips, order and count are visible | Continue enters `reel.editor.ready`; replace/remove remain reversible |
| `reel.source.invalid` | Select unsupported or unreadable media | Customer-safe correction identifies the required action | Choose again returns to the same picker origin without clearing valid clips |
| `reel.editor.ready` | Capture or gallery selection succeeds | Standard vertical Reel canvas and the complete direct editing toolset are visible | Close/Back preserves a valid draft and restores its origin |
| `reel.editor.tool` | Open Audio, Text, Overlay, Filter, Edit/Trim or Crop/Fit | Selected tool changes the real preview and persists its result | Done returns to `reel.editor.ready`; cancel restores the pre-tool result |
| `reel.publish.ready` | Tap `Next` with valid media | Caption, audience and commerce disclosure are editable in one publication state | Back returns to the exact editor state |
| `reel.publish.invalid` | Required publication value is missing/invalid | Publish remains unavailable and the relevant field owns its correction | Correcting the value returns to `reel.publish.ready` |
| `reel.publish.submitting` | Tap enabled publish | Single honest in-progress state prevents duplicate publication | Success enters `reel.public.result`; recoverable failure retains the entire draft |
| `reel.public.result` | Publication succeeds | Authored Reel appears immediately in the owned MoolSocial Reel sequence | Engagement and `More`/`Less` work; Back follows normal Reel navigation |

## `FND-U04-FEED-010` — Feed owns direct public publishing

### Required HTML behavior

- Feed opens content-first. Do not reserve the top of the feed for a large
  composer card.
- Provide a persistent contextual `+` in the lower thumb zone above the
  Universal rail. It must not cover post actions, the rail or safe-area content.
- One tap on `+` opens the composer with keyboard focus and cursor ready.
  There is no intermediate Create/format screen.
- The composer owns `Photo/GIF`, `Carousel`, `Your Reel`, `Image Poll`,
  `Quick Poll` and `Quiz` as inline actions.
- `Your Reel` may select only a Reel created or owned by the authenticated
  current MoolSocial account/session. Another creator's Reel is never attachable
  as the user's own post, and this action does not upload another general video
  file.
- `Photo/GIF` and Carousel use the native media picker. Carousel enforces its
  supported item count before publication.
- Image Poll, Quick Poll and Quiz expand their complete answer/options,
  validation and remove/add controls inside the same composer.
- Audience and reply permissions are editable in place. Publish stays disabled
  until the selected format is valid.
- Successful publication dismisses the keyboard, clears only the submitted
  draft and places the owned item in the visible Feed.
- A focused post detail uses native Back, persistent complete text/media,
  engagement actions and a bottom reply composer. An attached Reel opens the
  Reel experience and returns to the exact post state.

### Content boundary

- General MoolSocial-owned long-form video upload is absent.
- X video layouts are references for media-card density and direct interaction
  only. MoolSocial Feed supports Photo/GIF, Carousel and an existing MoolSocial
  Reel under this contract.

### Acceptance

- A user can start and complete each supported format without navigating to a
  separate product page.
- Feed cards keep identity, time, complete/expandable text, media, engagement,
  save/share and reply behavior readable at supported sizes.
- No action is duplicated between a top composer and the contextual `+`.

### Exact owned-Reel customer-copy contract

The following strings are the approved candidate wording for the Feed-owned
Reel attachment path. Internal ownership/session terminology must not leak into
the rendered interface.

| Context | Exact visible wording |
| --- | --- |
| Inline Feed composer action | `Your Reel` |
| Owned-Reel selection heading | `Choose Your Reel` |
| Empty owned-Reel state | `Create a Reel first` |
| Attached confirmation | `Reel added` |
| Replace action | `Change Reel` |
| Remove action | `Remove Reel` |
| Ownership recovery | `Choose a Reel from your account` |

The UI must not label this action `Video`, `Existing Reel`, `Owned Reel`,
`Session Reel`, `Select asset`, `Upload media` or any other internal,
provider-like or general-video term. `Create a Reel first` returns to the
Reels-owned direct creation journey; successful creation returns to the exact
Feed composer with its authored text, audience, reply setting and compatible
draft intact.

### Public-output acceptance matrix

| Authored format | Required public result | Required nested proof |
| --- | --- | --- |
| Created Reel | Authenticated identity, authored caption, real selected media and applicable commerce destination appear as the first owned Reel result | Play/pause, sound, `More`/`Less`, engagement and sequence continuation work |
| Plain Post | Authored text, identity, audience and time appear as the newest Feed item | Expand/collapse, like, reply, share, save and focused-detail Back work |
| Photo/GIF Post | Authored text and the exact selected Photo/GIF appear together | Media opens without losing Feed position and Back restores the exact card |
| Carousel | Every selected item appears in the authored order with an honest position indicator | Previous/next and swipe reach every item; focused-detail Back restores the exact item |
| Post containing `Your Reel` | The exact Reel selected from the authenticated account appears inside the post | Opening it enters that Reel, not another creator/index; Back restores the exact post and Feed position |
| Image Poll | Question and every valid image choice render with no missing media | One vote updates and persists the result; Back/return does not permit a duplicate local vote |
| Quick Poll | Question and every valid text choice render | One vote updates and persists the result; all added choices remain reachable at 140% text |
| Quiz | Question, all answers and the explicit submitted/correct-result treatment render | Selection is required before publication; submitted result persists after Back/return |
| Focused post detail | Complete text/media, identity, time and engagement remain visible with a bottom reply composer | Reply, like, share, save, attached-Reel open and exact Back restoration all work |

Every row must use customer-authored session data, produce a visible public
result, replay its nested actions, pass at 320×568 with 140% text and contain
zero placeholder, dummy, sample or internal-state result copy.

Selecting Photo/GIF, Carousel, `Your Reel`, Image Poll, Quick Poll or Quiz
must never leave two incompatible formats active. Switching formats must ask
before discarding a valid incompatible draft or retain the compatible draft.

### Format-switching and draft-preservation matrix

Codes used below:

- `K`: keep the active format and all values; selecting it again may close only
  its optional panel, never erase its valid content;
- `R`: retain written post text, audience and reply setting; ask before replacing
  the incompatible attachment/format; a dismissed confirmation changes nothing;
- `P`: open a native picker or Reels-owned journey while preserving the complete
  current composer snapshot; cancellation/Back restores that snapshot exactly.

| Current composer state → new action | Plain Post | Photo/GIF | Carousel | `Your Reel` | Image Poll | Quick Poll | Quiz |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Plain Post | `K` | `P` | `P` | `P` | `R` | `R` | `R` |
| Photo/GIF | `R` | `K` | `R + P` | `R + P` | `R` | `R` | `R` |
| Carousel | `R` | `R + P` | `K` | `R + P` | `R` | `R` | `R` |
| `Your Reel` | `R` | `R + P` | `R + P` | `K` | `R` | `R` | `R` |
| Image Poll | `R` | `R + P` | `R + P` | `R + P` | `K` | `R` | `R` |
| Quick Poll | `R` | `R + P` | `R + P` | `R + P` | `R` | `K` | `R` |
| Quiz | `R` | `R + P` | `R + P` | `R + P` | `R` | `R` | `K` |

For every `R` or `R + P` transition, accepting replacement clears only the
incompatible attachment/format after the next destination is available.
Picker cancellation, permission denial, Reel-creation cancellation, system
Back, app interruption or failed media decoding restores the pre-switch
composer snapshot. Successful publication clears only the submitted draft.

## `FND-U04-CREATE-011` — visible Create removal assessment

The design recommendation is to remove visible `Create` after its work is
successfully reassigned:

- Reel creation belongs to Reels;
- Post, Photo/GIF, Carousel, `Your Reel`, Image Poll, Quick Poll and Quiz
  belong to Feed; and
- Creator Studio, connected-channel distribution, campaign and business tools
  remain under their separately governed account/workspace owners.

Removal acceptance requires:

1. no supported format remains exclusive to Create;
2. old `social=create`, `compose=*`, saved-draft and notification/deep-link
   entries resolve to the correct new owner without a dead end;
3. internal models, session state, routes and business owners remain
   backward-compatible;
4. Back/forward restores the exact originating Reels or Feed state;
5. the visible Social sub-action rail has no dead `Create` label, hidden gap or
   stale selected state; and
6. customer-copy, semantics and automated inventories contain no obsolete
   visible Create action for the v9 presentation.

Until those conditions pass and the founder marks the v9 HTML `FINAL`, v8's
visible Create remains preserved in the immutable reference and native history.

### Legacy Create-entry compatibility matrix

| Existing entry | New owner | Back destination and retained state |
| --- | --- | --- |
| `social=create` | Feed | Normalize to Feed home with no visible Create selection; restore the originating scroll/post state |
| `social=create&compose=reel` or `compose=reel` | Reels | Open `reel.create.source`; Back restores current Reel/filter/index and a valid Reel draft |
| `social=create&compose=post` or `compose=post` | Feed | Open the keyboard-ready direct composer; restore authored text, audience and reply setting |
| `compose=carousel` | Feed | Feed composer; restore selected carousel items and order |
| `compose=image-poll` | Feed | Feed composer; restore question, media and options |
| `compose=quick-poll` | Feed | Feed composer; restore question and options |
| `compose=quiz` | Feed | Feed composer; restore question, answers and correct answer |
| `compose=draft` or `compose=drafts` | Reels or Feed by saved draft owner | Open the exact saved stage/format; Back restores the originating Social state |
| Unknown or retired `compose=*` | Feed | Safe Feed home fallback with no dead Create state, false success or discarded recognized draft |
| Saved Reel draft | Reels | Exact capture/editor/publish stage |
| Saved Feed draft | Feed | Exact composer format and authored values |
| Notification or deep link | Reels or Feed by content type | Native Back returns to the exact source state |

Compatibility verification must exercise direct address load, in-app legacy
navigation, browser Back/forward, retained-session relaunch and notification/
deep-link entry for every row. A normalized route must use one canonical Social
URL, must not add duplicate query separators/parameters and must never flash or
announce a visible Create tab.

## `FND-U04-SEARCH-012` — compact Reel and creator search

### Required HTML behavior

- Reels has a compact top-left search affordance that expands in place.
- Search covers public/eligible MoolSocial Reels and creator accounts only
  within this first contract.
- Query, loading, results, empty, retry and unavailable states are owned.
- Results distinguish a creator account from a Reel without relying on copied
  provider marks.
- Selecting a Reel opens it in the current Reel sequence; selecting a creator
  opens the MoolSocial profile/content surface.
- Closing or system Back collapses search and restores the exact Reel,
  scroll/sequence position and filter. Clearing a query does not unexpectedly
  leave Reels.
- Keyboard, voice/accessibility focus and large-text layout do not obscure the
  create `+`, content or Universal rail.

## `FND-U04-QA-013` — HTML correction and founder gate

Before founder review:

- run the Screens 01–03 lock before and after the correction;
- verify all visible taps, nested taps, Back, forward, cancellation, permission,
  picker return, keyboard return, draft return and interruption states;
- verify every supported viewport at 100% and 140% text, safe-area handling,
  keyboard inset, orientation and accessibility semantics;
- compare the corrected HTML with the supplied interaction principles without
  copying provider trade dress;
- run the rendered customer-copy gate over all reachable v9 states;
- prove the automatic main/sub-action rail reveal after any accepted visible
  Create removal;
- prove compatibility for every former Create entry path; and
- issue an exact URL, complete interaction inventory, screenshots, report and
  SHA-256 for founder review.

### Required viewport and regression matrix

| Viewport | Text scale | Required pass checkpoints |
| --- | --- | --- |
| 320×568 | 100% | All named Reels/Feed states, keyboard inset, safe areas, semantic focus order, 44×44 targets, no page overflow or action-label clipping |
| 320×568 | 140% | All named Reels/Feed states and public outputs; no hidden primary action, horizontal overflow, clipped copy or unreachable option |
| 360×640 | 100% | All named Reels/Feed states, keyboard inset, safe areas, semantic focus order, 44×44 targets, no page overflow or action-label clipping |
| 360×640 | 140% | All named Reels/Feed states and public outputs; no hidden primary action, horizontal overflow, clipped copy or unreachable option |
| 360×720 | 100% | All named Reels/Feed states, keyboard inset, safe areas, semantic focus order, 44×44 targets, no page overflow or action-label clipping |
| 360×720 | 140% | All named Reels/Feed states and public outputs; no hidden primary action, horizontal overflow, clipped copy or unreachable option |
| 375×667 | 100% | All named Reels/Feed states, keyboard inset, safe areas, semantic focus order, 44×44 targets, no page overflow or action-label clipping |
| 375×667 | 140% | All named Reels/Feed states and public outputs; no hidden primary action, horizontal overflow, clipped copy or unreachable option |
| 390×844 | 100% | All named Reels/Feed states, keyboard inset, safe areas, semantic focus order, 44×44 targets, no page overflow or action-label clipping |
| 390×844 | 140% | All named Reels/Feed states and public outputs; no hidden primary action, horizontal overflow, clipped copy or unreachable option |
| 412×915 | 100% | All named Reels/Feed states, keyboard inset, safe areas, semantic focus order, 44×44 targets, no page overflow or action-label clipping |
| 412×915 | 140% | All named Reels/Feed states and public outputs; no hidden primary action, horizontal overflow, clipped copy or unreachable option |
| 430×932 | 100% | All named Reels/Feed states, keyboard inset, safe areas, semantic focus order, 44×44 targets, no page overflow or action-label clipping |
| 430×932 | 140% | All named Reels/Feed states and public outputs; no hidden primary action, horizontal overflow, clipped copy or unreachable option |

The 14 rows are independent gates. A pass at one viewport or text scale cannot
substitute for another. Portrait is the required baseline; rotation/return must
also restore the exact content, draft and navigation state without making a
landscape layout a release requirement.

No-regression proof must include:

- Videos discovery → watch → Description → channel → exact Back restoration;
- Reels swipe/filter progression and persistent `More` / `Less`;
- the accepted Universal bottom rail, automatic active/next-action reveal,
  manual swipe and Chat return;
- the joined MoolSocial wordmark, approved tricolour line, navy `#000080`,
  saffron `#FF9933` and green `#138808`; and
- Screens 01–03 approved locks before and after the v9 HTML correction.

### Immutable v8 no-regression acceptance rows

| Preserved v8 contract | Required v9 proof |
| --- | --- |
| Universal header ownership outside focused creation | MoolSocial wordmark, account, notification and approved Universal ownership remain unchanged; focused creation hides only the chrome explicitly covered by the v9 interaction contract |
| Reels watch sequence | Vertical swipe/next progression, filter changes, play/pause, sound and exact current-index restoration remain operational |
| Reels information | Caption and creator details remain readable; `More` stays open until the user closes it with `Less` or leaves the Reel |
| Videos discovery | The accepted discovery surface, topic selection and video-card metadata remain unchanged by Reels/Feed ownership changes |
| Videos progressive detail | Watch → Description → channel details retains complete provider-supported metadata and exact Back restoration at every layer |
| Feed public consumption | Existing Feed cards, detail, complete text/media, engagement and bottom reply behavior remain reachable and readable |
| Social sub-action rail | Reels, Videos and Feed are visible/reachable with no Create gap, stale Create selection or hidden next action |
| Universal bottom rail | Approved Mool, active context and Chat composition, animation/haptic contract, automatic active/next-action reveal, manual swipe and Chat return remain unchanged |
| Universal navigation history | Main action, sub-action, focused detail and sub-to-sub action Back/forward restore the exact prior owner and state |
| Brand system | Joined MoolSocial wordmark, approved tricolour line, navy `#000080`, saffron `#FF9933` and green `#138808` are unchanged; no unapproved product colour is introduced |
| Customer-copy machine gate | Every reachable v9 and preserved v8-visible state contains zero example, dummy, commentary, planning, route/state or internal diagnostic copy |
| Screens 01–03 lock | Approved lock script and immutable reference/checksum comparison pass before and after the v9 correction |

Passing automation does not mark v9 `FINAL`. Only an explicit founder `FINAL`
authorizes freezing a new immutable reference.

## `FND-NATIVE-014` — native parity after founder `FINAL`

This ticket is blocked. After explicit founder `FINAL` and a new immutable v9
reference:

1. implement the matching isolated native Flutter UI V2 without modifying the
   legacy presentation or embedding MoolSocial HTML;
2. preserve existing models, sessions/controllers, services, API adapters,
   authentication, Firebase/native configuration, identity and business logic;
3. compare HTML and Flutter at identical viewport, state and text scale;
4. replay every affected route, tap, nested tap, Back/forward, permission,
   picker, keyboard, interruption and relaunch path on the connected OPPO;
5. run affected journeys, approved locks and two complete regressions from the
   exact installed APK; and
6. wait for founder `Accepted` or `Rejected` before preserving a native
   checkpoint or advancing provider work.

## Non-authority statement

Creating or updating these tickets does **not** claim:

- a completed HTML correction;
- a new HTML checksum;
- founder `FINAL`;
- a frozen v9 reference or manifest update;
- authority to modify Flutter, tests or approved evidence;
- founder acceptance of any native candidate; or
- permission to commit, push, merge, promote or start production-cloud work.
