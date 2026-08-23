# FSC03A native MoolSocial Feed preselection

- Ticket: `MOOLSOCIAL-FSC03A-NATIVE-MOOLSOCIAL-FEED-OWNERSHIP`
- Founder direction: HTML work is stopped; proceed sequentially in native Flutter toward OPPO founder review.
- Classification: `mvp_required`
- Outcome: the Feed is unmistakably MoolSocial-owned, professional and CTA-ready, while showing only authoritative text, image or carousel items or truthful loading, empty, unavailable and recovery states.

## Reuse, duplicate and authority assessment

The existing Social Feed destination, accepted rail, Create destination and
future authoritative-item renderer are sufficient. No new screen, route,
backend, Feed API, repository or state owner is necessary or authorized.

`SharedSession.socialPublishedItems` is populated only after
`ReviewSharedGateway.execute` and exists in memory for review flows. It is not
an authenticated durable Feed read owner and cannot support a production
publication or readback claim. The current hard-coded `_FeedData` records,
grocery image, invented people, engagement, promotion and commerce actions are
also ineligible. Therefore the smallest complete lawful implementation is an
empty-state-first native Feed with future authoritative item bindings retained
outside the visible production path.

## Smallest complete native scope

1. Remove every representative Feed record, fixture image, filter and commerce path.
2. Remove the inline quick-publish surface from Feed; Create remains the one MoolSocial posting owner.
3. Build a clean MoolSocial visual hierarchy distinct from YouTube, informed by low-effort feed patterns without copying X trade dress.
4. Provide honest loading, empty, unavailable, error and retry states.
5. Give the empty state one prominent `Create a post` CTA that opens the existing Create destination in one tap.
6. Preserve the Mool switcher, accepted global navigation, one-handed reach, compact fitment and 44-by-44 targets.
7. Add focused source, widget, navigation, copy and fitment tests before any APK work.

## Exclusions and gates

- No fabricated person, post, image, carousel, engagement, promotion, commerce or social-graph data.
- No YouTube ownership, X trade-dress clone or provider action.
- No publish, persistence, delivery, ranking or readback success claim.
- No FSC04 Create redesign and no new backend owner.
- A visible content state remains held until an authorized authenticated persistent Feed read owner exists.
- Publication success remains held until FSC04 has a durable authenticated idempotent posting gateway and readback.
- No build, candidate registration or OPPO mutation before fresh host qualification.
- Protected CPH2375 r60.28 and all C28D/C28F evidence remain untouched.
