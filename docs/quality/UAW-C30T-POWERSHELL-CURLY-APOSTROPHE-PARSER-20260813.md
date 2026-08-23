# C30T PowerShell curly-apostrophe parser rejection

- Date: 2026-08-13
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Google Play Internal Testing `1.0.0-r60.44 (2026081244)`
- Scope: navigation-only Feed CTA reproduction

The proposed Feed navigation command embedded the exact UI copy `We couldn’t refresh your Feed` in a single-quoted PowerShell expression. The typographic apostrophe caused a parser error before execution began. No hierarchy was dumped, no tap occurred and the OPPO remains on Social Home.

The retry must use an ASCII-safe semantic predicate while requiring a unique Feed error node, preserving the full Unicode copy only in durable evidence.
