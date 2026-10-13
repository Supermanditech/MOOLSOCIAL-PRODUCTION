# Cursor pending tickets — local founder review

Baseline: `c4365373f2c34af0f240377c6a91726ffb8097dc` on `work/cursor-ui/redmi-v6-audit-20260913`.

This review is limited to SKU-M05-C04, C06 and C07. It does not close founder/device acceptance, perform integration, or change policy/checker files.

- **C04:** Qualified the preserved whole-grid swipe draft. Actual positions of all three columns are checked while the pointer remains down; forward/backward paging and reduced motion pass. Store, Supplier and published Offers use the same tested movement. The six existing swipe tests also pass, including boundaries, delayed requests, failures/retry, vertical scrolling and 200% text.
- **C06:** Product search now observes the existing Store pager and displays one loading line while either request is pending. Store and product result/error owners remain separate. Tests exercise both completion orders. The delivery shortcut is unchanged.
- **C07:** A local test reproduced an in-progress launcher gesture opening Mool after rotation. The launcher now cancels its active pointers when display metrics change. A fresh tap still opens it. The actual Buy router preserves Shop, search and category through three portrait/landscape cycles. This establishes the tested touch-interruption correction, not the original physical Redmi trigger; confirm that on OPPO after founder approval.

## Results

| Check | Result |
|---|---|
| New ticket-focused tests | 11 passed |
| Existing swipe/recovery tests | 6 passed |
| Connected search, Buy router and global navigation suite | 47 passed; 5 failed |
| Five C27B layout failures against baseline navigation source | Same 5 failures reproduced |
| Analysis of both changed runtime owners and new tests | No issues |

The five pre-existing C27B assertions concern icon size, compact row widths and bottom-inset geometry. They were not changed or counted as passing. The baseline comparison uses the original navigation owner from Git, relocating only its two relative imports for an isolated test outside the application tree.

## Review

Open `cursor-pending-review.html` for actual local Flutter screenshots, including before/during/after swipe frames. The screenshots use synthetic catalogue data, actual app fonts and decoded illustration assets. They are not OPPO captures or proof of live catalogue publication.

Next: founder visual approval, then the separately requested OPPO qualification. No OPPO command, APK installation or integration was performed in this local-review scope.
