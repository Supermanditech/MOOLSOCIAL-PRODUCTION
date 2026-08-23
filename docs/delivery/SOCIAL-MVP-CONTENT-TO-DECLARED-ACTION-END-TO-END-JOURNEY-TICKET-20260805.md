# Social MVP content-to-declared-action end-to-end journey ticket

Prepared: 5 August 2026
State: **PARENT JOURNEY PLANNING COMPLETE — PROPOSED — NOT PREAUTHORIZED — NOT EXECUTING**
Parent ticket:
`SOCIAL-MVP-CONTENT-TO-DECLARED-ACTION-END-TO-END-JOURNEY`
Child portfolio:
`SOCIAL-MVP-CONTENT-TO-DECLARED-ACTION-PORTFOLIO-20260805`
Child manifest SHA-256:
`AB87CC9CF743E4B558A2EA03C15807AD421A2830C85F891180ADA14221CBE6C4`

## Parent customer outcome

A user can open a native text/image or eligible YouTube-connected Social post,
understand exactly one truthful MoolSocial action, enter the already-authorized
Buy or Work journey, complete the declared server-owned outcome and return to
the same content with an accurate state. Creators, businesses, reviewers and
Admins can publish, fund, control, correct, moderate, pause and audit that
journey without disguising external engagement as a paid MoolSocial outcome.

The 42 portfolio tickets are bounded child execution units of this complete
parent acceptance ticket.

## MVP classification and reason

Classification: `mvp_required`.

The authoritative 45-day go-live plan assigns Days 28–34 to Social and names
the required native post, YouTube Connect, attributed action, campaign
duration, moderation, rights and feature-flag capabilities. Its exact exit is:
**content opens and its declared commerce/Work action completes**.

## Exact operating promise

`truthful content -> one explicit action -> current destination decision ->
authoritative downstream event -> durable return and attribution`

- A post view or action tap is never a purchase, Work application, fulfilled
  outcome, commission or payout.
- The action card is outside the YouTube player and never rewards or requires
  YouTube views, likes, comments, shares, subscriptions or watch time.
- One post has at most one declared MoolSocial action.
- An action label is available only when its accepted destination adapter is
  registered and enabled.
- At launch, destinations are bounded to accepted Buy and Work routes. A
  generic Book/service label is not implemented by this parent.
- The server rechecks content, action, destination, availability, geography,
  eligibility, campaign and feature state at open and tap time.
- The action's `declaredCompletionEvent` is visible before the tap and comes
  from the accepted destination contract. Examples are **order fulfilled** for
  a Buy/Order promise or **application recorded** for an Apply promise.
- Only that downstream server event completes the declared action. A retained
  fulfilled outcome is tracked separately from an open, click, cart, payment,
  application or other intermediate state.
- No client clock, cached card, provider metric or AI result creates the
  authoritative state.

Functional labels below describe required taps and results. Exact layout and
final customer copy remain governed by the accepted HTML reference gate.

## Roles and what each sees

| Role | Initial Social view | Extra decision surface | Authority boundary |
| --- | --- | --- | --- |
| Normal viewer | Organic/public posts allowed by creator visibility and viewer controls | One action card with label, destination, reason shown and completion promise | Can open, act, engage, report and recover; cannot create eligibility or Admin targeting |
| Target viewer | Eligible campaign placement with **Why shown** | Same destination truth plus paid/sponsored disclosure | Targeting uses approved profile/geography/consent/readiness rules, never a raw exported list or hidden phone activity |
| Native creator | Personal Create for text/image content | Visibility, rights, disclosure and one optional registered action | Ordinary posting remains separate from Creator/Business campaign authority |
| YouTube-connected creator | Paste one public link or connect read-only channel | Eligible item selection, separate action and official-player preview | Cannot upload/mutate YouTube, hide attribution or promise unavailable content |
| Campaign creator | Versioned funded brief and deliverable state | Disclosure, action, duration and attribution terms | Cannot accept hidden terms or earn for external engagement |
| Verified business/funder | Governed campaign configuration and outcome reporting | Registered destination, eligible audience, duration, funding/approval state | Cannot invent a route, silently target individuals or rewrite active terms |
| Trust and Safety reviewer | Risk-ranked report/rights/disclosure queue | Evidence, policy, containment, correction, decision and appeal | Automation may prioritize/contain; important final action remains accountable |
| Configuration Admin | Registered capability/action/campaign and launch controls | Audience, approval, canary, health, expand/pause/stop | Cannot override consent, waive dependencies or mutate Production without release authority |

## Journey 1 — common viewer tap-to-tap journey

1. User signs in with one personal account and taps **Social**.
2. Social restores the last valid surface and position; the user may tap
   **Feed**, **Shorts** or **Videos**.
3. The server returns only content allowed by current visibility, block/mute,
   moderation, geography, consent, capability and campaign rules.
4. If a post is promoted, **Sponsored / Paid partnership** and **Why shown**
   appear before the action. Organic and promoted ranking are not disguised.
5. The user taps one text/image or YouTube-connected card.
6. **Post detail** opens with creator identity, time, visibility context,
   content, rights/disclosure labels needed by policy and current availability.
7. For YouTube content, the official embedded player is visibly YouTube-hosted.
   Playback is user initiated and the MoolSocial action remains outside it.
8. When a declared action exists, one action card shows its verb, exact
   product/opportunity or bounded destination, truthful context and what event
   counts as completion.
9. The user may tap an information control to see **Why this action is
   available**, source/campaign disclosure and destination terms summary.
10. The user taps the single declared action.
11. The server rechecks that the post is usable, the action version is current,
    its destination is registered/enabled and the user may enter that route.
12. If usable, the exact Buy or Work decision opens; no generic menu or
    invented service page is inserted.
13. If setup, eligibility or verification is required, the original post and
    action intent are saved before the exact downstream gate opens.
14. The user reviews the complete authoritative downstream terms and chooses
    whether to proceed. Merely opening them records an attributable open, not
    completion.
15. The user completes, abandons or fails the exact Buy/Work flow. Duplicate
    taps and callbacks resolve to one downstream identity.
16. The destination emits a signed/server-owned intermediate or terminal
    receipt. Social cannot manufacture or upgrade it.
17. The user taps **Back to post**, system Back, or the destination's
    completion return.
18. Social restores the same post and feed position, then shows **Available**,
    **In progress**, **Completed**, **Failed**, **Cancelled**, **Reversed** or
    **Unavailable** according to the latest authoritative receipt.
19. If the post/action/campaign changed during the journey, the user sees the
    current state plus the snapshotted version used for their decision.
20. The user may use permitted **Like**, **Comment**, **Share**, **Save**,
    **Profile**, **Report**, **Not interested** or creator-control actions.
21. A failed or nonterminal result always offers the exact next action,
    **Support** or **MoolChat**, without asking the user to repeat a completed
    order/application.

## Journey 2 — native text/image creator tap-to-tap journey

1. Signed-in user taps **Social**, then **Create**.
2. The app opens the personal Create surface. Creator or Business conversion
   is not required for an ordinary permitted post.
3. User taps **Text post** or **Photo post**.
4. A durable draft ID is created once. The composer shows **Saved locally / on
   server / retrying** truth rather than pretending every keystroke is synced.
5. For a photo, user taps **Add image**.
6. The app explains the image purpose and requests the minimum current-device
   permission only when required.
7. On allow, the user selects one allowed image and sees upload/processing
   state. On deny, the text draft remains usable with **Try again** and
   **Continue without image**.
8. User previews, replaces or removes the image and enters alt text where the
   accepted accessibility policy requires it.
9. User taps the audience control and selects an allowed post visibility.
   Public discoverability, profile discoverability, message permission and
   campaign targeting stay separate.
10. User optionally taps **Add MoolSocial action**.
11. The chooser lists only Admin-enabled registered Buy/Work destinations the
    current role may attach. Unsupported **Book** or service paths do not
    appear as fake choices.
12. User selects exactly one destination and reviews its action label,
    truthful context, current availability and declared completion event.
13. User records the content-rights basis. If funded, sponsored, affiliate or
    outcome-linked, the required disclosure is selected and previewed.
14. User taps **Review post**.
15. Review shows the final content, visibility, disclosure, source attribution,
    separate action card and any campaign facts.
16. Preflight checks missing content, media processing, rights, disclosure,
    blocked claims, action destination and role/capability state.
17. A correctable failure returns to the exact field with retained valid work.
    A policy block shows its reason and permitted support/review route.
18. User taps **Publish post** once.
19. Server idempotently returns **Published**, **Processing**, **Needs
    correction**, **Held for review** or **Failed** with a post/draft reference.
20. **View post** opens the exact published detail. **Content Library** restores
    the same item after app close, restart or network recovery.
21. The creator can later use allowed **Edit disclosure/action context**,
    **Pause action**, **Change future visibility**, **Delete/unpublish** or
    **View decision** controls. Material action changes create a new version;
    they do not rewrite prior user decisions or attribution.

## Journey 3 — YouTube-connected creator tap-to-tap journey

1. Eligible creator taps **Profile**, **Creator account**, **Create**, then
   **YouTube Connect**; an accepted equivalent shortcut from Social Create may
   open the same route.
2. Screen explains: video stays on YouTube; MoolSocial publishes only the
   validated connection, context and independent MoolSocial action.
3. Creator chooses **Paste YouTube link** or **Connect my channel**.
4. For a pasted link, creator enters one public video/Short URL and taps
   **Validate link**.
5. Server checks identifier, visibility, availability, embedding and provider
   policy. It returns **Eligible** or the exact **Private**, **Unavailable**,
   **Embedding disabled**, **Invalid** or **Provider unavailable** recovery.
6. For channel connection, creator taps **Review Google authorization**.
7. The consent sheet lists only read-only content access, purpose, data use,
   expiry/revocation and the separate personal-account boundary.
8. Creator continues through provider authorization or cancels back to the
   intact draft. No Google permission is requested before this decision.
9. On success, MoolSocial stores the connection server-side and shows the
   connected channel plus **Connection controls / Revoke**.
10. Creator selects one currently eligible public item. Private or
    unembeddable items remain visibly blocked with corrective guidance.
11. Creator taps **Continue with selected video**.
12. **Mool action** requires exactly one registered Buy/Work destination,
    customer-facing context and declared completion event.
13. Creator records rights/control of the MoolSocial context and confirms that
    destination price, availability, evidence, refund or opportunity terms are
    truthful.
14. If a funded campaign is eligible, creator may link it and select an allowed
    one-to-seven-day placement. Otherwise the post stays organic.
15. Creator taps **Preview post**.
16. Review visibly separates the official YouTube player, YouTube-provided
    metrics, MoolSocial action card, MoolSocial outcome metrics and campaign
    disclosure/duration.
17. System revalidates source, connection if used, destination, disclosure,
    campaign approval/funding and capability flag.
18. Creator taps **Publish connected post** once.
19. Server returns one connected-post reference and exact **Published**,
    **Processing**, **Held**, **Needs correction** or **Failed** state.
20. Creator taps **View post** or **Content Library**. On future opens, source
    eligibility is rechecked; a now-private/removed/unembeddable video produces
    recovery, never a hidden replacement player.
21. Creator may revoke the channel connection. Existing posts retain their
    recorded source/reference state and follow provider-policy recovery; the
    personal MoolSocial account remains available.

## Journey 4 — declared Buy or Work action completion

### A. Buy / Order promise

1. Viewer taps a post's **Buy** or accepted **Order** action.
2. Server verifies the exact product/seller/cart decision is still registered,
   enabled, serviceable and permitted for the viewer's selected address/area.
3. Exact product detail or pre-scoped cart opens with current price,
   availability, delivery promise, seller/fulfillment identity and refund
   terms; Social teaser copy is not treated as price or stock authority.
4. Viewer taps **Add to cart**, reviews the cart, selects address/delivery and
   taps **Pay / Place order** through the accepted Buy journey.
5. Payment success alone is not delivery. The order follows the authoritative
   seller acceptance, any approved non-acceptance escalation/fallback,
   fulfillment, tracking, support, cancellation/refund and delivery proof
   contracts already owned by Buy.
6. The declared Social action is terminal only at the completion event shown
   before tap. For the launch **Buy/Order delivered** promise, that event is an
   authoritative delivered/served receipt; intermediate **Paid**, **Accepted**
   or **Out for delivery** remains **In progress**.
7. Cancellation, return, refund or reversal updates attribution and the post's
   action state without deleting the original decision history.

### B. Apply / Do this Work promise

1. Viewer taps **Apply** or an accepted **Do this Work** action.
2. Exact Work opportunity opens with its truthful teaser or full terms based
   on workspace state; Social targeting does not create Work eligibility.
3. User creates/reuses the required Work workspace if necessary, reviews the
   complete terms, meets verification and taps **Apply** only in the Work
   journey.
4. For an **Apply** promise, one authoritative `Applied`, `Waitlisted`,
   `Approved`, `Rejected` or `Expired` application result completes the
   declared action according to the shown contract; opening terms does not.
5. For a stronger **Complete this Work** campaign promise, the action remains
   in progress through assignment, proof, decision and the exact Work outcome
   named before tap. Social cannot shorten or replace the Work contract.
6. Rework, rejection, appeal, payable/payout and reassignment remain owned by
   the accepted Work journey and are reflected only through authoritative
   receipts.

### C. Cross-route return

1. The destination preserves source post, action version, creator/campaign and
   one opaque attribution identity without leaking unrelated personal data.
2. Back, app restart or terminal return restores the same content.
3. Social fetches the latest receipt and shows the correct intermediate,
   terminal or reversed state.
4. Duplicate deep links, callbacks or retries return the original identities
   and do not duplicate cart, order, application, work, attribution or credit.

## Journey 5 — funded campaign creator and business tap-to-tap journey

1. Authorized business/funder taps **Profile**, **Business account**, then
   **Social campaigns**.
2. Business taps **Create campaign** and selects one approved objective tied
   to a registered Buy or Work outcome—not external engagement.
3. Business selects an accepted destination. The system shows its exact
   completion event, service geography, current capability state and required
   customer terms.
4. Business chooses an Admin-allowed audience by profile, geography, consent,
   readiness and eligibility rules; no raw recipient list is shown or exported.
5. Business sets bounded funding/capacity and selects an allowed duration from
   24 through 168 hours.
6. Campaign review shows content/creator requirements, disclosure, action,
   destination, audience reason, duration, funding, outcome attribution,
   cancellation/make-good and no-auto-renewal terms.
7. Business taps **Submit for approval**. No placement time starts.
8. Maker-checker/product, Finance, Trust and Safety or Operations approval is
   obtained where required. A rejection or correction shows reason and retains
   valid inputs.
9. Eligible creator sees the funded brief, payout/outcome basis, rights,
   disclosure, action, duration and cancellation terms before **Accept**.
10. Creator accepts the exact version and creates or connects the required
    content through Journey 2 or 3.
11. Content/action passes preflight and any required review.
12. Successful placement activation records one authoritative start timestamp;
    only then does purchased duration begin.
13. During the active window, eligible viewers see **Sponsored / Paid
    partnership**, **Why shown** and the one action.
14. Admin/business can see separate delivery health, YouTube-provided metrics,
    MoolSocial opens, downstream intermediate events and retained outcomes.
15. Pause stops future distribution but preserves existing user cases and
    funded obligations. Resume behavior follows the accepted terms; time is not
    silently extended.
16. At the exact end timestamp, the campaign expires once. It does not renew or
    charge again automatically.
17. Any creator commission/payability is calculated only from the accepted
    funded deliverable or retained downstream outcome contract. External
    engagement never creates payable money.
18. Cancellation, return or reversal updates outcome attribution and any held
    amount through the appropriate ledger; it never rewrites provider metrics.

## Journey 6 — viewer and creator Social controls

1. User taps **Profile**, **Settings**, then **Social controls**.
2. User reviews feed preference, comments, mentions/tags, requests, nearby,
   campaign invites, autoplay/data saver, language/accessibility, blocks,
   mutes, restrictions and ad/campaign personalization controls.
3. User changes one control and taps **Save** where confirmation is required.
4. Server records the control version and effective state. Unsupported or
   conflicting combinations explain the exact rule.
5. Feed refresh respects the new state without losing the user's place where
   possible.
6. Withdrawal of optional targeting or campaign consent stops future eligible
   targeting; it does not erase necessary order, Work, payment, report or
   legal/audit records.
7. Creator opens a post and taps **Post controls**.
8. Creator may adjust future visibility, comments, mentions, action pause or
   allowed correction. A material published edit creates a new version.
9. Admin cannot silently re-enable a user-withdrawn optional promotion or
   change a creator's public visibility choice.
10. Admin may pause a capability for safety with an audited reason and expiry;
    affected users see an explicit service state and recovery.

## Journey 7 — report, correction, enforcement and appeal

1. Viewer taps **More**, then **Report** on the exact post/action/comment.
2. A short governed reason list appears; high-risk reasons surface urgent help
   where applicable.
3. Viewer chooses a reason, optionally adds the minimum permitted context and
   taps **Submit report** once.
4. Server returns one case reference. The viewer can block/mute immediately
   without waiting for the moderation result.
5. Risk ranking may limit distribution for a high-harm case pending qualified
   review, but it cannot silently create a final verdict.
6. Creator receives a safe notice when policy permits, with affected item,
   temporary state, reason category and next action; reporter identity remains
   protected.
7. For correctable missing disclosure, broken action or rights evidence,
   creator taps **Review issue**, updates only the required field and submits
   one correction version.
8. Reviewer evaluates original evidence, creator response, policy/jurisdiction,
   reach/harm and any specialist input.
9. Decision records **Restore**, **Label**, **Limit distribution**, **Disable
   action**, **Request correction**, **Remove**, **Hold outcome/commission** or
   another accepted proportionate action with evidence, policy version, scope,
   duration and reason.
10. Creator opens **Decision details** and sees what changed, evidence basis,
    duration, effect on content/action/campaign and whether appeal is allowed.
11. If allowed, creator taps **Appeal**, supplies bounded grounds/evidence and
    submits once.
12. An independent reviewer decides **Uphold**, **Modify** or **Reverse** and
    records the new reason and effective state.
13. Viewer, creator, business and Admin surfaces converge on the latest state
    while preserving prior decisions and financial/attribution adjustments.

## Journey 8 — Admin Trust and Safety tap-to-tap journey

1. Authorized reviewer signs into the separate Admin surface and taps
   **Content / Trust & Safety**.
2. Dashboard shows role, open reports, high-harm queue, automated limitations
   awaiting human review and appeals due.
3. Reviewer taps a filter such as **High harm**, **Rights**, **Paid content**,
   **Spam** or **Appeals**.
4. Reviewer taps one queue item. The case shows content/action/campaign
   identity, reach, reports, existing containment, creator notice, prior
   decisions and protected reporter/evidence access appropriate to role.
5. For a high-harm claim, reviewer verifies containment and taps **Open
   specialist review** when qualified expertise is required.
6. For a rights match, reviewer reviews claimant/creator evidence and
   exceptions; automated matching alone cannot remove content or transfer
   revenue.
7. For missing paid disclosure, reviewer taps **Send correction request** when
   correction is sufficient; linked campaign outcome/commission may remain
   held according to policy.
8. Reviewer selects a permitted decision and enters the evidence basis,
   policy/jurisdiction version, scope, duration, reason and appeal route.
9. A high-impact decision requiring maker-checker is submitted for second
   approval; the initiating reviewer cannot self-approve.
10. Reviewer taps **Apply decision** only after required approvals. Server
    idempotently updates distribution/content/action/campaign state and records
    the complete audit event.
11. System sends role-safe notices to creator/business and updates support and
    appeal deadlines.
12. Reviewer taps **Close case**, **Monitor** or **Escalate**. Closure requires
    all promised correction, restoration, hold/release and notice actions to
    reconcile.
13. Reviewer opens **Appeals** and assigns an independent permitted reviewer.
14. Appeal result updates the case without erasing the original action.
15. Aggregate health is available to Admin; raw reporter or audience lists are
    not exported.

## Journey 9 — Admin configuration and launch tap-to-tap journey

1. Authorized configuration Admin taps **Configuration**, then **Social
   content and actions**.
2. Admin sees registered capabilities and their **Draft**, **Approval**,
   **Canary**, **Active**, **Paused**, **Stopped** or **Retired** state.
3. Admin taps **Configure action** and selects an existing registered Buy or
   Work destination adapter.
4. Admin sets customer-facing label/context rules, allowed creator roles,
   visibility, geography, eligibility recheck, completion event and recovery.
5. The system blocks save if route, current terms, completion receipt or
   recovery contract is missing. Admin cannot create an unimplemented route by
   typing a new label.
6. Admin taps **Campaign policy** and configures the allowed duration/default,
   funding/capacity bounds, disclosures, attribution window, stop rules and
   no-auto-renewal rule. Launch range is 24–168 hours.
7. Admin taps **Audience** and composes permitted profile, geography, consent,
   readiness, app-version and capability rules. The server resolves recipients
   at use time; no raw list is exported.
8. Admin taps **Preview experience** and reviews normal viewer, target viewer,
   creator, unavailable destination, permission denial, moderation and expiry
   states at supported sizes.
9. Admin taps **Submit for approval**. Product, Trust and Safety, Privacy,
   Finance, Operations/provider and reference owners approve only their exact
   responsibilities.
10. Maker-checker records the policy/configuration version, effective date,
    audience, owner, dependencies and rollback/stop criteria.
11. Admin taps **Start canary** for the approved percentage/geography. This
    action remains environment/release-gated; planning authority cannot mutate
    Production.
12. Health view separates publication errors, provider quota/cost, action-open
    failures, downstream completion, reports, reversals and user-control
    impact.
13. If thresholds pass, Admin taps **Request expansion**, obtains the required
    approval and expands only the approved scope.
14. If a stop rule fires, authorized Admin taps **Pause new distribution** or
    the automatic safety control performs its preapproved containment. Existing
    posts, purchases, Work cases, appeals and funded obligations remain
    protected.
15. Admin enters reason, scope and expiry, then taps **Confirm pause**.
16. After correction and evidence, Admin taps **Resume canary** or **Retire
    version**. A material policy change creates a new version and repeats
    approval; it never rewrites active campaigns or prior user decisions.

## Journey 10 — interruption, unavailable state and support recovery

1. Draft autosave, upload, validation, publication, action handoff, downstream
   completion, attribution, campaign and moderation operations each use stable
   request identities.
2. Network loss keeps the current screen and valid inputs, labels the state
   **Waiting for connection** and offers one bounded retry.
3. App close/restart restores the authoritative draft/post/action/destination
   identity instead of creating a replacement.
4. Repeated publish/action/report/approval taps return the original result.
5. Private, removed, unavailable or unembeddable YouTube content shows source
   ownership, reason and allowed **Choose another video / Fix on YouTube /
   Revalidate** action; no unofficial playback appears.
6. A closed product, seller, geography or Work opportunity disables the action
   with **Unavailable** and the exact accepted alternative or return path. It
   does not silently substitute another item/opportunity.
7. Provider quota/cost/circuit-breaker state uses cached metadata only where
   policy permits and never claims fresh eligibility or completion.
8. If payment/order/application/work succeeded but the return callback failed,
   Social queries the authoritative receipt before offering another attempt.
9. A removed or moderated post preserves necessary order/Work/support access
   outside the content surface.
10. Campaign activation failure consumes no purchased time. Partial placement
    and make-good follow the accepted versioned terms.
11. User taps **Support** or **MoolChat** from any nonterminal/failure state and
    receives a case containing opaque content/action/destination identifiers,
    current state and permitted diagnostic context—not hidden private content
    or unrelated device data.
12. Support can explain, retry a safe operation, route a correction or escalate;
    it cannot manufacture publication, moderation, order, Work, attribution or
    payout truth.

## Journey-to-child traceability

| Journey | Primary child ticket orders |
| --- | --- |
| 1. Common viewer | 3, 6, 11, 12, 16–24, 30, 31, 35, 38–42 |
| 2. Native creator | 2–12, 17–19, 28, 30, 32, 35, 38, 40–42 |
| 3. YouTube-connected creator | 1–3, 7–10, 13–19, 25–30, 32, 35, 38–42 |
| 4. Buy/Work completion | 17–24, 30, 35, 38, 40–42 |
| 5. Funded campaign | 3, 6–9, 17–19, 23–30, 32–38, 40–42 |
| 6. Social controls | 3, 6, 11, 12, 30, 31, 35, 38, 40–42 |
| 7. Report/correction/appeal | 7–9, 11, 24, 28–35, 38, 40–42 |
| 8. Admin Trust & Safety | 3, 7–9, 24, 30–36, 38, 40–42 |
| 9. Admin configuration/launch | 2, 3, 6, 8, 17–19, 23–27, 29, 30, 35, 37–42 |
| 10. Recovery/support | 2, 4, 5, 10, 11, 13–16, 18–24, 27–35, 38–42 |

## Reference authority and unresolved gates

- Protected native Social/YouTube authority:
  `artifacts/quality/social-protected-baseline-20260729-02/BASELINE.json`.
- Approved route/reference inputs include Screens 05–08, 124–131 and 153.
- Screen 166 is an approved-directory reference but its embedded binding still
  says founder UI/UX review pending. It is a required final-reference gate for
  this new exact journey.
- Screen 156's base is approved, while offering-provisioning review remains
  pending. Its Social configuration delta requires final review.
- Screen 170 Social Promotion exists only in the mutable working screen set,
  not `approved-final`; it is not implementation authority.
- The HTML screenbook remains read-only unless the founder separately
  authorizes the founder-review workflow.

## Dependencies and approvals

1. Founder accepts this exact parent outcome, 42-ticket manifest and tap
   journeys, or requests edits.
2. Founder separately accepts the final responsive reference batch for Screen
   166, campaign placement and Screen 156 configuration delta.
3. Buy and Work owners expose accepted destination, eligibility, terms,
   completion, reversal and return contracts.
4. Identity, Privacy, Security, Trust and Safety, Rights, Finance, Campaign,
   Attribution, Admin, SRE and YouTube-provider owners approve their held
   responsibilities.
5. Live credentials, funding, provider scopes, environment or Production
   actions require their own exact approvals.
6. One child is explicitly activated and recorded before implementation.
7. Before the first runtime/backend write or build,
   `scripts/check-mvp-scope-gate-state.ps1 -RequireExecutionAuthorized` must
   pass.
8. Commit, push, deploy, promote and Production remain separately prohibited.

## Parent acceptance evidence plan

The parent is accepted only when:

1. every child has exact positive, negative, interruption and recovery
   evidence or a documented external dependency disposition;
2. protected Social tree identity is sealed before and after work;
3. native text/image and YouTube-link/read-only-channel creation journeys pass;
4. official-player, provider attribution and no-paid-engagement rules pass;
5. exactly-one-action, destination registry, terms/eligibility preflight,
   deep-link, authoritative completion, reversal and return continuity pass;
6. 24–168-hour campaign boundaries, approval/activation clock, expiry and no
   auto-renewal pass;
7. reports, correction, enforcement, appeal, Admin trust/safety and Admin
   configuration journeys pass with role and audit evidence;
8. privacy, permission, retention, revocation, egress, provider quota/cost,
   offline/retry, accessibility, performance and abuse matrices pass;
9. the exact native/backend source passes focused and full tests plus Social and
   cross-module Buy/Work regressions twice with unchanged source identity;
10. the scope gate passes before build and source/APK/install identities are
    recorded;
11. checksum-matched OPPO CPH2375 captures prove every material tap path and
    failure recovery; and
12. founder receives an indexed dossier and makes the separate acceptance and
    release decisions.

## Authorization state

This parent and portfolio are proposed only. They do not record founder
preauthorization and do not activate implementation, build or OPPO testing.
The MVP scope gate remains closed with no active Social child.
