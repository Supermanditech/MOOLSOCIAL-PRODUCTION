# REG-20260818-2963 C34P X duplicate manual SHA-256 implementation

Date: 18 August 2026 (IST)
State: registered before cryptographic-owner reuse correction

## Incident

After the strengthened X suite passed 12/12, primary bounded source review found
that `x_oauth2_pkce.dart` contains a complete hand-written SHA-256
implementation for PKCE and state digests. The mobile package already pins the
maintained `crypto` dependency. The manual primitive therefore duplicates an
existing tested owner, adds roughly two hundred security-critical lines and was
not necessary to satisfy the dependency-free provider/network boundary.

No external, provider, browser, device, private, account or build action
occurred.

## Root cause

The X subtask interpreted dependency-free as no package imports at all instead
of no new provider SDK or network dependency, and reimplemented a standard
cryptographic primitive already available in the application.

## Prevention

Import the existing `package:crypto/crypto.dart` owner and derive SHA-256 bytes
through its maintained digest implementation. Remove the complete manual
round/constants implementation, retain RFC 7636 known-vector coverage, format
and clean-analyze both X owners, then run one new serialized focused test. New
security-sensitive code must inventory and reuse pinned cryptographic owners
before implementing a primitive.

## Retained evidence

- `apps/mobile/pubspec.yaml`
- `apps/mobile/lib/core/auth/x_oauth2_pkce.dart`
- `apps/mobile/test/uaw_c34p_x_oauth2_pkce_test.dart`
- `config/codex-development-regression-registry.json`
- this incident record
