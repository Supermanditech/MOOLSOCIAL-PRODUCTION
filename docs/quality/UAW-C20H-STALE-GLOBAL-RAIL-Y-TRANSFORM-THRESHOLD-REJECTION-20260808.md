# C20H stale global-rail y-transform threshold rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

The predecessor capture helper transformed only semantics starting at y≥1432.
In r60.19, `Previous main actions` begins at y=1428, so the first helper tap used
the clipped semantic center y=1435 instead of the measured physical rail center
y=1480. The selected state remained Buy/Shop and the exposure inventory did not
change. No evidence was mislabeled.

## Prevention

The C20H evidence helper maps all global-rail nodes starting at y≥1428 to
physical y=1480. Scroll-arrow operations must prove that the visible action
inventory changed before a family tap is attempted.
