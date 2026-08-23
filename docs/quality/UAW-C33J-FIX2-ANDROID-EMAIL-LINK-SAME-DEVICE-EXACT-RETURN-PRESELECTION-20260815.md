# UAW C33J FIX2 Android email-link same-device exact return preselection

## Founder request

After the user receives the passwordless email link, tapping it on the same
phone must open MoolSocial and return to the same page/action that requested
authentication.

## Reuse and gap

C33J already owns Firebase email-link validation, Screen 03 completion and
cold-start delivery. FIX1 owns foreground delivery and exact pending-route
return. `MainActivity` is already `singleTop` and has an auto-verified HTTPS
filter for `moolsocial.com/app`, but it does not catch Firebase Hosting email
action links under `/__/auth/links`.

Firebase's current Android email-link guide requires an auto-verified HTTPS
intent filter for the selected Hosting domain and `/__/auth/links`:
<https://firebase.google.com/docs/auth/android/email-link-auth>.

The smallest source change adds that missing platform entry point for the known
default project domain and the existing custom MoolSocial domain, plus one
non-secret host-parity policy. The existing C33J/FIX1 state owners remain the
only completion path.

## Held scope

No Firebase, Hosting, authorized-domain, provider, live email, AAB, Play, OPPO,
device or secret action is authorized by this ticket. Live verified-link proof
remains a separate gate.

## Selection

- Ticket: `UAW-C33J-FIX2-ANDROID-EMAIL-LINK-SAME-DEVICE-EXACT-RETURN`
- Classification: `mvp_required`
- Manifest SHA-256:
  `2944938B936BFE8E5D53313F5D7F4AC45DF4C41FB1C9D55BEA773669DF847683`
- New screens/routes/backend owners: zero.
