# REG2870 — C34L transition FIX2 sessionId privacy-exemption scope

- Status: registered final-review production defect before handoff.
- Scope: transition evidence privacy validation.
- Defect: `Assert-C34LEvidencePrivacy` approved a session-ID value by leaf name alone. Exact parent schemas protect known evidence owners, but arbitrary capture-artifact JSON is privacy-scanned without an exact schema; a root `sessionId` matching the approved grammar could therefore receive the exemption outside approved attestation/capture positions.
- Root cause: REG2849's phone-pattern false-positive correction was implemented as a global leaf-name exemption instead of a position-specific schema exemption.
- Detection: final bounded transition readback after all semantic suites passed.
- Prevention: allow the approved session grammar only at source-attestation/capture-manifest root or exact nested `sourceAttestation.sessionId`; reject it in arbitrary capture artifacts and retain a dedicated negative. Because transition bytes change, rerun lifecycle and journal suites on PowerShell 7 and Windows PowerShell.
- External impact: no real state, build, browser, Play, OPPO, device, private, secret, or external action occurred.
