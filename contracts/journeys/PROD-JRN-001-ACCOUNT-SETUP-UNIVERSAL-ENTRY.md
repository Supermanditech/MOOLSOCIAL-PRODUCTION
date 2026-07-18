# PROD-JRN-001: Account setup and universal entry

## User outcome

From a Play Store install or a deep link, the person reaches the requested
MoolSocial product with a valid session. Mool remains one tap away and returns
the person to the previously focused product.

## Canonical path

`Install → Open → boot checks → language/area → one sign-in method → optional
OTP/provider handoff → restore returnTo → Social → Mool → chosen product`

## Launch UI routes

| Route | Purpose | Exit |
| --- | --- | --- |
| `/boot` | version, config, session, network and return route | automatic |
| `/setup` | detected language and optional service area | `/sign-in` |
| `/sign-in` | one authentication method | `/verify` or provider callback |
| `/verify` | OTP autofill/manual verification | retained `returnTo` |
| `/app/social` | default authenticated product | product route |
| `/app/mool` | universal action root | chosen product route |

Loading, offline, timeout, provider-cancelled, invalid, expired, duplicate
account, permission-denied and retry are states of these routes, not new routes.

## State machine

```text
installed
  -> booting
  -> setup_required | authentication_required | ready
setup_required
  -> authentication_required
authentication_required
  -> otp_pending | provider_pending
otp_pending
  -> authentication_required | ready
ready
  -> requested_route
```

No transition skips required consent. No failed provider callback loses
language, area, attribution or `returnTo`.

## Data

- App user keyed by Firebase Auth UID.
- Language and area preference.
- Versioned consent receipts.
- Device installation and push-token lifecycle.
- Pending protected route with expiry and consumed timestamp.
- Authentication events contain method and result, never OTP or token content.

## Acceptance

- Fresh install and returning session choose the correct route.
- A protected deep link survives setup and sign-in.
- Current location is requested only after an explicit tap.
- Manual area and Skip do not trigger location permission.
- Invalid/expired OTP is recoverable; resend is rate-limited.
- Repeated Verify cannot create duplicate account/profile records.
- Provider cancellation returns to the method screen with state preserved.
- Offline boot/setup/sign-in explains what is retained and what requires
  connectivity.
- Mool is reachable in one tap from every authenticated primary route.
- Closing Mool returns to the prior focused route.
- Sign-out clears private caches and preserves only permitted setup choices.

## Definition of done

Real Flutter app, Firebase staging Auth, SQL Connect staging records, emulator
tests, Test Lab pass, connected Android pass, App Distribution build, original
prototype replay and clean-state full regression.
