# C16D Eat table large-text overflow rejection

The first focused C16D run reached Book Table at 320px and 140% text and
truthfully failed: each fixed-height horizontal restaurant card overflowed its
vertical content by 12px. The fault was in the existing Eat content owner, not
the new shared sub-action rail.

The bounded correction makes only the restaurant lane height respond to the
active `TextScaler`, retaining the same horizontal restaurant inventory,
184px card width, content, order, callbacks and selected state. The C16D gate
and focused replay require that adaptive owner before qualification.
