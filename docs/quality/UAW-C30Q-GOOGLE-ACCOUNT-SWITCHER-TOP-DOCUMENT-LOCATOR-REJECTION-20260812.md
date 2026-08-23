# C30Q Google account switcher top-document locator rejection

Date: 2026-08-12

## Mistake

The first attempt to open `Add account` from Google's account switcher used a top-document role locator even though the DOM snapshot showed the control inside the active account iframe. The locator found no match and rejected.

## Impact

- No account was added or changed.
- No password, MFA code, credential, tester enrolment, installation, repository, provider, or device state changed.

## Permanent prevention

Scope account-switcher controls through the visible iframe locator proven by the current DOM snapshot. Stop at any password or MFA page and hand the visible browser to the founder.
