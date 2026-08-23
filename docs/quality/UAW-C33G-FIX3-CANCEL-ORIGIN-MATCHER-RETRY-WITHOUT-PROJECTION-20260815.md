# UAW C33G FIX3 cancel-origin matcher retry without projection

The second C33G FIX3 gate run repeated the same cancellation-origin rejection after a matcher rewrite. The full retry occurred before independently projecting the exact raw-source occurrence count.

Every later matcher correction must first prove the sanitized needle length and occurrence count in one bounded diagnostic. The complete gate may be retried only after that projection matches the intended contract.
