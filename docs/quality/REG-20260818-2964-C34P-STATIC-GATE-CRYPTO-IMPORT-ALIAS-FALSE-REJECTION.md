# REG-20260818-2964 C34P static-gate crypto import alias false rejection

Date: 18 August 2026 (IST)
State: registered before gate-oracle correction

## Incident

The first C34P shared-gateway static gate run rejected the X source because it
searched for `import 'package:crypto/crypto.dart';`. The qualified source
correctly imports the same package with `as crypto` to make the digest owner
explicit. The gate's formatter-sensitive exact import token was stale; all
product sources and tests remained unchanged by the rejected gate.

## Root cause

The gate asserted one interchangeable Dart import spelling instead of the
actual freshly read declaring line or a stable package URI token.

## Prevention

Bind the gate to the exact current formatter-stable import including
`as crypto`, while separately retaining the no-manual-round-constants and RFC
7636 behavior assertions. Parse and run the corrected gate independently on
PowerShell 7 and Windows PowerShell 5.1 before acceptance.

## Retained evidence

- `scripts/check-uaw-c34p-public-authentication-shared-gateway.ps1`
- `apps/mobile/lib/core/auth/x_oauth2_pkce.dart`
- `config/codex-development-regression-registry.json`
- this incident record
