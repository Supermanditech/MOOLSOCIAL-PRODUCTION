# UAW C33I FIX1 approved-prototype structure restoration qualification

State: `SOURCE_PARITY_QUALIFIED_FOUNDER_VISUAL_REVIEW_REQUIRED`

Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

Founder correction: use the login screen exactly as it appeared in the approved Screen 03 prototype and change only the unsupported Email OTP path to passwordless email-link authentication.

## Corrected proposal

Path:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\03-login-account-handoff-v5-passwordless-email-link.html`

SHA-256:

`1E4DB8FA47E42FD065E8A404D78C17DA2A0023D39F724C6A55A1562467F1A6AB`

The choose-method state now restores the approved Screen 03 structure:

- 360-pixel phone frame, 32-pixel status row and original left-aligned MoolSocial header;
- `India Ka Socio Commerce App`, `Sign in` and `Choose one method to continue.`;
- `Social account` with six providers in exact order: Google, YouTube, Apple, X, Instagram, Facebook;
- the original compact email and mobile method-row structure, icon proportions, helper-copy placement and chevrons;
- `Mobile OTP` / `Use mobile number` unchanged; and
- the email row changed only to `Email link` / `Use any email address`, opening the already-scoped passwordless email-link states.

The rejected proposal's added `Welcome` eyebrow, centered compact header, widened 390-pixel frame and rewritten method-row copy are absent from the corrected choose state.

## Verification

- Regression memory passed after each registered retry: `2456` entries, `1521` applicable implementation entries at the last pre-document check.
- Approved UI lock passed before correction.
- Six exact provider controls were counted and their source order was verified from lines 899–926 of the corrected proposal.
- Exact title, instruction, email-link row, Mobile OTP row, tagline and dynamic state-binding anchors were verified by serial exit-zero `rg` checks.
- The unexpected `<p class="eyebrow">Welcome</p>` anchor was explicitly absent.
- Accepted Screen 03 v2 remains byte-exact at `C8B58BED63B6616F83D06C7D95FAA335DB537B3C6DF37593D601D19037ECDFEF`.

The in-app browser blocked model-driven navigation to the local `file://` URL. No bypass or alternate browser-control surface was used. Therefore the earlier rendered matrix and `-fix1.png` screenshots apply only to the founder-rejected first proposal and are not current visual evidence. Founder-controlled refresh/review of the already open local file remains required.

## Boundaries

This is still an additive `PROPOSAL_NOT_FINAL`. No accepted reference, Flutter/runtime source, Firebase, Hosting, provider, email, AAB, Play or OPPO action occurred. Founder `FINAL` remains required before freeze or native implementation.

## Additive final freeze record

The founder subsequently supplied exact `FINAL` and four final reference captures. The accepted source and original screenshot bytes are now frozen under `approved-references/screens/03-login-account-handoff/v5/`; the historical proposal boundary above is preserved as chronological evidence and is superseded by this record. Native parity is isolated under successor `UAW-C33J-SCREEN03-PASSWORDLESS-EMAIL-LINK-NATIVE-PARITY` so this reference and the locked v4 implementation remain unchanged.
