# Buy V2 market-hierarchy design audit — 2026-07-30

## Authority and scope

This audit records the founder's 2026-07-30 OPPO review and the resulting
production acceptance criteria for the native Flutter Buy shell. It applies to
Shop, Wholesale, Medicine and Orders. It does not authorize changes to the
approved HTML screenbook, Screens 01–03, Social, backend contracts, inventory,
pricing, fulfilment or payment rules.

The market screenshots are layout references only. MoolSocial must retain its
own brand, colours, components, copy, catalogue data and behaviour; no
competitor trade dress, artwork, promotion, product data or business rule may
be copied.

## Preserved OPPO evidence

Current captures are preserved without replacing earlier evidence under:

`artifacts/quality/buy-market-layout-inspiration-oppo-20260730-18`

Authoritative current references:

- `07-flipkart-home-authority-oppo.png` and its UI XML. The foreground proof
  records `com.flipkart.android`; the clean capture is the Flipkart authority.
- `02-amazon-home-clean-oppo.png` and its UI XML. An OPPO environmental-risk
  dialog obscures the middle of the screen, but the search and address bands
  remain measurable. The founder instructed that the warning be ignored
  because interacting with it would interrupt USB debugging.

Preserved earlier references:

- Blinkit:
  `artifacts/quality/buy-flutter-founder-remediation-oppo-20260729-06/01-blinkit-home-inspiration-oppo.png`
- Zepto:
  `artifacts/quality/buy-flutter-founder-remediation-oppo-20260729-06/03-zepto-home-inspiration-oppo.png`

Explicit exclusions:

- `04-flipkart-home-settled-oppo.png` is a launcher capture after Flipkart
  left the foreground; it is preserved but is not a design authority.
- `06-zepto-home-current-oppo.png` is a launcher capture because the currently
  archived Zepto package has no launchable activity; it is preserved but is
  not a design authority. The earlier verified Zepto capture remains the
  reference.

## Measured hierarchy

All OPPO captures are 720 physical pixels wide.

| Reference | Address / identity | Search | Categories | Promotion | Account / cart |
| --- | --- | --- | --- | --- | --- |
| Flipkart | Address band `656 × 56` at `y=202` | Search band approximately `656 × 96` at `y=282`, with camera and scanner at the trailing edge | Horizontal rail approximately `128` high below search | Large rounded hero followed by secondary horizontal cards | Both are explicit destinations in the bottom rail |
| Zepto | Delivery promise, saved location and account occupy one readable top identity region | Search `467 × 78`, paired with a `197 × 78` contextual card | Horizontal category rail approximately `109` high | Promotions follow categories and scroll with content | A prominent rounded conversion bar floats above the bottom rail |
| Blinkit | Delivery / location / account precede search | Search approximately `656 × 96` | Categories follow search | Promotions follow categories | Prominent green cart floats above the bottom dock |
| Amazon | Address is a distinct shallow band | Wide search approximately `88` high | Service categories are separate from search | Promotion begins below address | Account and cart are stable bottom destinations |

The measurements establish hierarchy and touch-target intent, not pixel values
to copy.

## Proven current MoolSocial defects

The current 360 × 800 Flutter/OPPO catalogue compresses Category, Search,
Scanner, Saved and More into a single 48-logical-pixel toolbar. On the OPPO,
the search text occupies only about 292 of 720 physical pixels while four
independent controls compete on the same line. This causes:

1. Search to read as a secondary tool instead of the primary discovery action.
2. The compact MoolSocial wordmark, address, destination context and account
   control to visually merge into one crowded header.
3. Saved and More to compete with search and scanner instead of being
   contextual product-grid actions.
4. No MoolSocial-owned discovery or service promotion between category
   selection and product content.
5. A cart bar that is visually quiet, contains no destination context and is
   absent from Orders even when the user has items to complete.
6. Different information hierarchies between catalogues and Orders, despite
   address, search, account and cart needing stable placement throughout Buy.

The current UI remains functional and its three-column grid is preserved, but
its hierarchy does not meet the founder's production-design review.

## Shared production blueprint

### Identity and search

- Use a compact, distinct MoolSocial brand mark rather than a wide wordmark
  block. Preserve the full `MoolSocial` semantic label.
- Give delivery / business / pharmacy / orders context a readable address line
  and keep the account control at the trailing edge.
- Put search in its own rounded band with a minimum 48 logical-pixel target.
  Scanner remains inside the trailing edge of search; search must not share its
  horizontal budget with Category, Saved and More.
- Keep address, search and account in the same visual order across Shop,
  Wholesale, Medicine and Orders.

### Discovery and promotion

- Replace the isolated Category popup trigger with a shallow, horizontally
  scrolling discovery strip. The selected category remains obvious and
  category selection must still update the existing catalogue query.
- Saved and filter / sort actions become compact contextual actions in the
  discovery strip, not search competitors.
- Add compact MoolSocial-owned promotion cards that invoke only established
  native destinations or actions. Promotion must scroll away with catalogue or
  orders content so it cannot permanently reduce the product / order viewport.
- Shop, Wholesale and Medicine remain independently configured. Orders puts
  active-order content before promotional continuation actions.

### Cart

- Restyle the non-empty cart affordance as a rounded, high-contrast conversion
  card above the bottom dock with item count, destination context, total and a
  clear `View cart` action.
- Keep it reachable from Shop, Wholesale, Medicine and Orders whenever the
  existing cart contains items. Do not expose it on checkout, account or
  tertiary screens where it would compete with the active task.

### Responsive and accessibility limits

- Support widths 320, 360, 390 and 430 logical pixels, Android and iOS safe
  areas, and 140% text scaling without overflow or clipped controls.
- Search receives the dominant width at every supported size.
- At least one complete product row or one complete order card remains visible
  on the 320 × 568 catalogue / Orders entry state.
- Interactive controls retain at least a 44 logical-pixel hit target, with
  search and primary cart action at least 48.
- Promotions and category content must use horizontal scrolling or adaptive
  wrapping; they must not force a vertical category rail or reduce the existing
  three-column grid.
- Every action keeps the existing honest acknowledgement and navigation
  behaviour. No fake loading, unavailable advertisement service or invented
  backend state is permitted.

## Delivery split

- `BUY-FV2-060`: shared brand, address, account and dedicated search hierarchy.
- `BUY-FV2-061`: responsive discovery strip and MoolSocial-owned promotion
  cards.
- `BUY-FV2-062`: prominent destination-aware cart card and Orders reachability.

Each ticket must pass focused verification before the next begins. The complete
candidate still requires two same-source Buy regressions, protected-reference,
copy, brand and Social-integrity gates, checksum-matched OPPO installation and
journey replay. Passing tests alone is not founder acceptance.
