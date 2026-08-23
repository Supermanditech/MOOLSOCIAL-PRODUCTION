# C30Q Google account Add link pointer-interception rejection

Date: 2026-08-12

## Mistake

The iframe-scoped locator found the exact visible Google `Add account` link, but the account-card overlay intercepted the semantic pointer event and the click rejected.

## Impact

- No account or authentication state changed.
- No password, MFA code, credential, tester enrolment, installation, provider, repository, or device state changed.

## Permanent prevention

Do not repeat the intercepted click. Use the exact visible `AddSession` URL already exposed by the account-switcher DOM, navigate the tester tab once to that URL, and stop for founder interaction at any password or MFA prompt.
