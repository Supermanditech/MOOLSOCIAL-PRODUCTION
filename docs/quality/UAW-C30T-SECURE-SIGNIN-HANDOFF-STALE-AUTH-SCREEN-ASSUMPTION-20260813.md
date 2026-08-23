# UAW C30T secure sign-in handoff stale auth-screen assumption — 13 August 2026

## Observation

The intended Google sign-in semantic was selected from an earlier MoolSocial authentication screenshot/hierarchy. The exact semantic helper captured a newer pre-tap hierarchy, found zero matches and stopped before input. No Google account chooser opened.

## Permanent prevention

- Inspect a fresh immediately current MoolSocial hierarchy before any authentication or external-consent handoff.
- Prove exactly one current semantic and act from that same state without an intervening assumption.
- After the handoff, do not inspect, capture, automate or log account identities, passwords, MFA, OAuth credentials, tokens, nonces or consent payloads; pause for founder interaction.

## Safety result

No tap, account chooser, credential access, OAuth action, external write, Create write or Chat send occurred.
