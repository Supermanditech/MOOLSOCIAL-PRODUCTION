# Buy V2 r15 founder-rejection UI/UX audit

Date: 29 July 2026

Status: r15 remains founder-rejected. Native Flutter remediation candidate r17
has been implemented and replayed on the OPPO; founder acceptance remains
pending.

## Integrity and evidence boundary

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Rejected installed candidate: version code `2026072915`
- Candidate/installed SHA-256:
  `7D51A72EBD80F222244F7608989787D56E8B75B7F2A38E75C89365E436BB2916`
- Exact r15 OPPO evidence:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-05`
- Earlier unchanged deep-journey OPPO evidence:
  `artifacts/quality/buy-flutter-v2-oppo-20260729-01` and
  `artifacts/quality/buy-flutter-v2-reiteration-oppo-20260729-02`
- New append-only audit/remediation evidence:
  `artifacts/quality/buy-flutter-founder-remediation-oppo-20260729-06`
- Tested remediation candidate: version `1.0.0` (`versionCode 2026072917`)
- Candidate/pulled installed-base SHA-256:
  `600203DF3D3A2E77B9E44E92E5042F7CBD060251F419378E5DC5800DE1659342`

The OPPO disconnected from ADB at the beginning of the audit and later
reconnected. The original r15 frames remain the rejection baseline. The exact
r17 candidate was then installed, its installed base APK was pulled back and
checksum-matched, and the primary, subaction and tertiary Buy journeys were
recaptured. This evidence is candidate verification, not founder acceptance.

## Founder-requested live market hierarchy references

The OPPO reconnected later in the remediation pass. At the founder's request,
the live installed Blinkit and Zepto home screens were captured as positional
inspiration only:

- Blinkit:
  `artifacts/quality/buy-flutter-founder-remediation-oppo-20260729-06/01-blinkit-home-inspiration-oppo.png`
- Zepto:
  `artifacts/quality/buy-flutter-founder-remediation-oppo-20260729-06/03-zepto-home-inspiration-oppo.png`

The accompanying UI hierarchies and SHA-256 evidence are stored beside each
image. On the 720×1612 OPPO, Blinkit places its closing-status control at
`[360,141][488,170]`, money at `[528,126][600,198]`, Profile at
`[624,126][696,198]`, and the Search band below at
`[40,257][696,353]`. Zepto places delivery time at `[72,104][248,148]`,
address at `[32,152][454,180]`, Account at `[634,117][688,167]`, and Search
below at approximately physical y=317–393.

The applicable hierarchy lesson is:

1. keep delivery/status and Account in the very top identity region;
2. place Search directly below that region rather than competing with the
   wordmark, address and Account in one row;
3. keep product/category discovery immediately below Search.

The competitor promotion walls, store tabs, oversized headers and late product
starts are explicitly not copied because they conflict with the founder's
content-first Buy direction. Blinkit Money, Zepto-specific stores and any
unapproved "coming soon" action are also not invented in MoolSocial: the
founder-final Buy authority contains no such Buy action. The current approved
equivalents remain delivery/business/pharmacy context, active Orders, Cart,
Saved products, prescriptions and the existing account owner.

## Measured r15 defects

### Shared shell

- At 360 logical pixels the app bar allocates 88 pixels to the wordmark, one
  flexible context chip and three separate 44-pixel circles for Search, Scanner
  and DC. The row has no remaining breathing room and visibly truncates context.
- A second 48-pixel catalogue toolbar adds a wide category control plus three
  or four 44-pixel icon buttons. Badges compete with icons and the toolbar reads
  as another navigation bar.
- Customer-visible metadata is reduced to 6–9 logical pixels in multiple cards
  and header contexts. The layout technically fits by becoming hard to read.

### Catalogue viewport

- On the 720×1612 OPPO the first r15 product row begins at approximately
  physical y=292 and the dock begins around y=1368.
- The unobscured catalogue region is therefore about 1,076 physical pixels,
  roughly 67% of the full device screen, not the founder-directed 80–90%.
- The grid adds 118 logical pixels of bottom padding because the 72-pixel dock
  is absolutely positioned over the view.
- Opening categories adds an 82-logical-pixel layout row and pushes the first
  product to approximately physical y=454.

### Product cards

- Three-column cards are fixed at 246 logical pixels. Only about two complete
  rows fit above the dock.
- `Spacer` separates pack from price, creating large blank interiors.
- Badge, product glyph and Save control compete in the same 66-pixel visual.
- Badge, delivery, seller and visual labels truncate. `NOTEBO` is a visible
  placeholder-style truncation.
- The 44-pixel Save hit target visually overlaps artwork and badge content.

### Catalogue tools

- Search uses a modal bottom sheet rather than a compact browse-state control.
- The category picker changes page geometry instead of opening as an anchored
  transient selector.
- Saved still uses `showModalBottomSheet` and covers the product grid. Moving
  its launcher down one row did not satisfy the founder's contextual-use
  requirement.
- Filter, household basket and prescription flows use additional sheets,
  causing repeated context switches.

### Bottom navigation and state stability

- The dock is a floating 72-pixel `Positioned` overlay with animated item
  containers.
- It changes from six Buy items to seven Mool items in the same width.
- Exact OPPO captures after some taps contain temporarily absent labels/icons.
  Even when the later stable frame renders, a production rail must not expose
  such transitional blank states.
- Long destination labels are scaled down rather than given stable information
  architecture.

### Product and purchase flow

- Product detail begins with an oversized visual and 25-pixel title; the
  purchase action is below extensive fact panels.
- Cart repeats large header and family summary regions, then reserves a large
  CTA/white region above the dock.
- Checkout uses an oversized title and stacked cards, leaving limited
  fulfilment visibility before the sticky action.
- Address and payment sheets use large headings and rows and occupy most of the
  remaining viewport.
- Confirmation uses a large success billboard and leaves substantial empty
  space before the dock.

### Orders, tracking and support

- Orders requires summary and tab regions before the first order card.
- Order cards repeat two large buttons and expose only about two cards.
- Tracking uses 26-pixel titles and tall promise, fulfilment and timeline
  panels; Get help can sit at the lower viewport edge.
- Assist uses an oversized page heading, large suggestion chips and unused
  vertical gaps.

### Scanner

- The native camera is now real, but the bottom instruction/action card remains
  visually heavy.
- Manual code entry plus keyboard covers most of the device and breaks the
  continuous scan context.
- Scanner state is not integrated into a compact catalogue discovery bar.

## Responsive and device-fitment risks

- The current width rule forces three columns at 300 logical pixels unless text
  scale exceeds 1.25. At narrow widths that leaves cards too small for readable
  decision facts.
- At 140% text the grid changes to two columns, but fixed heights grow to 552
  logical pixels in some states, creating severe vertical inefficiency.
- Multiple fixed heights, absolute bottom offsets and modal sheets are
  sensitive to short iPhone/Android viewports, landscape, keyboard and gesture
  safe areas.
- A widget test proving “no overflow” is insufficient; the new gate must also
  prove readable text, content-start position, visible row count and unobscured
  actions.

## Registered remediation tickets

The audit registered `BUY-FV2-032` through `BUY-FV2-041` in
`docs/delivery/BUY-FLUTTER-V2-PRODUCTION-TICKETS-20260729.md` and reopened
`BUY-FV2-023` through `BUY-FV2-031`. R17 implements the shared compact shell,
stable reserved rail, contextual catalogue tools, dense cards, account access,
native scanner, inline Saved mode and compact deep-commerce states covered by
those tickets.

## R17 remediation evidence

The r17 physical-device replay covers:

- Shop, Wholesale, Medicine and Orders;
- stable Mool/Buy bottom-rail switching;
- anchored category selection and inline Search/Saved states;
- live camera scanner and keyboard-safe manual fallback;
- account access from Shop, tracking and product detail;
- product quantity, Cart, Checkout, address, payment and confirmation;
- Orders, tracking and Mool Assist;
- prescription selection, non-matching prescription safety behavior and a
  matching prescription add;
- mixed Medicine/Wholesale Cart and Checkout state.

The authoritative settled OPPO frames run from
`10-r17-shop-oppo.png` through
`51-r17-multi-scope-checkout-third-capture-oppo.png` in the append-only
remediation evidence directory. A few immediately captured frames omit
unchanged composited glyph layers; later settled captures are retained beside
them and are the visual authority. No app crash, Flutter error, RenderFlex
overflow or unhandled exception was found in the app-scoped replay log.

The local responsive matrix contains 58 screenshots across 320×568, 360×800,
390×844 and 430×932 Android/iOS-size profiles, including 140% text critical
states. Two complete affected regressions pass 76/76 independently. Analysis,
founder-reference, user-copy, interaction-contract, approved-lock, brand and
Social-protected gates pass; the Social tree remains
`54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`.

The scanner's primary physical-device path is proven, but a complete
permission-denial/settings/camera-unavailable/unsupported/no-match physical
device matrix remains pending and is not represented as accepted.

No commit, push, deployment or publication is authorized. The approved HTML
screenbook, locked Screens 01–03 and frozen Social/YouTube source remain
unchanged.
