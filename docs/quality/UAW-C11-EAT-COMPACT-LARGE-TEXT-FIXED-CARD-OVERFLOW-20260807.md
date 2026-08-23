# C11 Eat compact large-text fixed-card overflow

Date: 2026-08-07

Regression ID:
`REG-20260807-247-C11-EAT-COMPACT-LARGE-TEXT-FIXED-CARD-OVERFLOW`

After the Social shelf fitment correction, the C11 320x568/140% matrix reached
Eat and exposed six vertical overflows in the four context choices and the
restaurant cards. Both owners used fixed heights derived from 100% text.

This is relevant to the shelf ticket because the new persistent lower shelf
must leave the remaining destination content truthfully scrollable at the
required compact/large-text boundary; hiding or accepting body overflow would
make the navigation correction non-production-grade.

Permanent prevention: fixed-height Eat decision rows derive their vertical
extent from the effective text scale, while the outer page remains scrollable.
The C11 matrix mounts the complete destination at 320x568/140% and rejects any
render exception instead of testing the shelf in isolation.
