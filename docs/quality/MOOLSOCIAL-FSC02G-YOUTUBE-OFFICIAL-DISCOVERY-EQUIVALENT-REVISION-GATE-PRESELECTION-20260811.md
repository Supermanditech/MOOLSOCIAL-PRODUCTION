# FSC02G equivalent official Discovery revision gate preselection — 11 August 2026

Three credential-free, mutation-free samples of the allowlisted official Google Discovery documents produced this exact sequence:

- Data: `20260810`, then `20260806`, then `20260806`; each response contained 83 methods and contract SHA-256 `824A7F7B832BA2FB13A8242E679465FACAB785450C9D360A5234D20126325C2A`.
- Analytics: `20260809` in all rounds, 8 methods, contract SHA-256 `1C6B5D58FB58239AB38DD13CF89FC86EDA36E3C59BFA0CF3FD4D6CA8676F177D`.
- Reporting: `20260809` in all rounds, 8 methods, contract SHA-256 `9B6E214C4B637A91C26258FEFA2D787F07BFF3A67922866526126E9D332023C6`.

The current exact-single-revision gate is therefore nondeterministic against Google's cache/backend behavior even when the entire method contract is unchanged. FSC02G may add only a finite explicit accepted-revision set: Data `{20260806, 20260810}`, Analytics `{20260809}`, Reporting `{20260809}`. The canonical registry revisions and all method classification metadata remain unchanged.

Acceptance of a revision never replaces drift checking. Every response must still pass the complete method ID, count, HTTP operation, scope, classification and provider-operation comparison. Unknown revisions, wildcards, ranges and retry-until-pass behavior are forbidden. Negative tests must prove unknown revisions and method drift fail closed before three live verifier runs may pass.

No credential, token, key or cookie is sent to Google. FSC02G authorizes no cloud write, APK build, install or OPPO mutation. C29C remains paused and must restart both host cycles after this gate is qualified.
