# C32S C22F current navigation visual contract test successor qualification

C32S migrated only the historical C22F test owner. It now distinguishes the
accepted 58-pixel local destination cell from the 48-pixel legacy dock capsule,
checks the local selected indicator and press scale, rejects removed local inner
chroma, and retains dock-only family chroma, timing, clipping and reduced-motion
coverage.

Post-migration results: C22F 9/9, C27B 5/5, C27D 1/1, focused analyzer clean,
and the C32S gate passed on PowerShell 7 and Windows PowerShell. The production
design owner remains SHA-256
`D66C9A8E34E49FF58DF25EF6DC0694B22DB91E5C33B6A04CA5CD7A63C7F76BFE`.
No runtime, backend, build, Play, OPPO, provider, external or secret action was
performed.
