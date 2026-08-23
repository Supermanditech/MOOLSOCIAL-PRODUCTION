# UAW C33E FIX2 Google auth live-provider readiness hard-gate qualification

Date: 2026-08-15

Ticket: `UAW-C33E-FIX2-GOOGLE-AUTH-LIVE-PROVIDER-READINESS-HARD-GATE`

## Outcome

The non-secret Google authentication readiness hard gate is implemented and
source-qualified. It runs before the visible founder launcher can request any
hidden input and again inside the authoritative AAB wrapper before build
authority can be consumed.

The current state remains deliberately blocked with `0/4` live-readiness facts
qualified. This is a truthful implementation qualification only. It is not a
Google sign-in success, release-candidate qualification, AAB authority, Play
authority, OPPO acceptance or YouTube reviewer-readiness claim.

The installed historical candidate remains failed:

- version: `1.0.0-r60.48+2026081348`
- machine state: `acceptance_failed_r60_48_social_auth_and_action_journey_defects_successor_required`
- build/upload/install counts: `1/1/1`
- C30Z source repair contained in that installed candidate: `false`

## Required live facts

All four must receive separate sanitized, non-secret evidence before the gate's
build phase can pass:

1. The Firebase Android app lists the Play app-signing certificate fingerprint.
2. Firebase Authentication shows the Google provider enabled for the exact Dev
   project.
3. An Android OAuth relationship matches `com.moolsocial.app` and the Play
   app-signing certificate.
4. The mobile runtime's server-side Google relationship is the qualified Web
   application relationship for the exact Dev project.

No API-key value, OAuth identifier value, token, nonce, private verdict,
private key, attestation payload, private account identifier or Firebase debug
log was read or persisted.

## Verification

- PowerShell 7 behavioral contract: passed
- Windows PowerShell 5.1 behavioral contract: passed
- pending state implementation phase: passed
- pending state build phase: rejected as required
- fully qualified sanitized fixture: passed
- missing-fact negative cases: 4 passed
- failed-fact negative case: passed
- authority-drift negative case: passed
- private-value-property negative case: passed
- scope-drift negative case: passed
- C30Z source gate under the exact FIX2 lifecycle: passed
- C30X generated-preflight/authority/AAB ordering contract: passed
- C30Y mutation-safe preflight transaction contract: passed
- C30V single-AAB wrapper contract: passed
- temporary fixture residue: 0
- new build/upload/install actions: `0/0/0`

## Bound owners

- readiness state SHA-256:
  `5C7B0CAFF119AC0BDF4B18666FBE0DF8D11F1B6197F8AA66650C92ABA523C1D0`
- readiness gate SHA-256:
  `300425BAABF900E9EE4EC116C1798CD2932C0220F78D5DF057CEBB37B002F9F5`
- behavioral checker SHA-256:
  `978809F152A6A6CECAB9A861F975764B5C09F80EE7A5611A2B6C1E103C7AEC80`
- lifecycle-safe C30Z gate SHA-256:
  `B733A9D1AEA09DBB608BE70F89D4E507E2BA186668F851003F743D090E304D3F`
- authoritative AAB wrapper SHA-256:
  `CFDF4FB6538277CF317ED704D785934C45BE26A7B8BE4E5F095EDB44DED0473F`
- visible founder launcher SHA-256:
  `B308736DD2700E331BDB5CCF4A57BBE5522BDF90279D6E05946F02B44C0F48F6`

## Exact next approval boundary

The founder may provide only the four sanitized console yes/no confirmations
above, without copying any identifier or credential value. If all four are
truthfully confirmed, a later evidence-only ticket may qualify this state.
That still does not authorize a build. One exact successor candidate and its
separate AAB, Internal Testing and in-place OPPO Play-update authorities remain
required before repaired login can be tested on device.

YouTube quota submission and email remain held until the Play-installed
successor proves Google login, consent, reviewer access and the complete
YouTube review journey.
