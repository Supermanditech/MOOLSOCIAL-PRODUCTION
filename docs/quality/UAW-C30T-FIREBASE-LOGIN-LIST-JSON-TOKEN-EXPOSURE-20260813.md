# C30T Firebase CLI JSON token exposure

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1882-C30T-FIREBASE-LOGIN-LIST-JSON-TOKEN-EXPOSURE`
- Severity: credential exposure; external writes blocked pending revocation and reauthentication

## Observation

An identity reconciliation command invoked Firebase CLI `login:list` with JSON output. Firebase CLI 15.5.1 returned the signed-in account metadata together with live OAuth access, refresh and ID token fields in the transient tool output.

No token value is copied into this evidence, repository state, chat response or deployment material. No provider or Hosting deployment occurred after the exposure.

## Required recovery

1. Revoke the current Firebase CLI session so its refresh token is invalidated.
2. Complete a fresh interactive Firebase CLI authentication as `hello@moolsocial.com`.
3. Verify access through a bounded authenticated project read that cannot emit credential fields.
4. Run the regression-memory and deployment gates again before any external write.

## Permanent prevention

- Never run `firebase login:list --json`.
- Never print, inspect, parse or persist Firebase credential/token objects.
- Use redacted human identity output or a bounded authenticated project read only.
- Treat any credential serialization as a failed gate requiring revocation and reauthentication.

## External effect

No Firebase, Google Cloud, Hosting, AAB, Play, OPPO, IAM, Gmail or quota mutation occurred. The only effect was disclosure in transient tool output, which requires credential invalidation before deployment.

## Recovery completed

The founder revoked the prior Firebase CLI session and completed a fresh interactive Firebase CLI login as `hello@moolsocial.com`. Authentication was then verified only through a bounded Android-app listing for `moolsocial-dev-503018`, which returned the expected single Firebase Android app and no credential fields. External writes remain subject to all normal C30T gates.
