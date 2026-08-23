# C22C Mool/Chat endpoint resize expectation rejection

The six middle main actions passed the exact 72 × 48 measurement. The test then incorrectly expected the separately protected Mool and Chat endpoints to resize from their existing 44 × 44 minimum. C22C preserves those endpoints and corrects the assertion to `MoolMetrics.minimumTapTarget`.
