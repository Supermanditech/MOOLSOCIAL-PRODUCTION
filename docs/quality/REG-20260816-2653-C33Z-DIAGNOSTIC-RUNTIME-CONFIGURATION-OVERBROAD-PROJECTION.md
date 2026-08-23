# REG2653 — C33Z diagnostic runtime-configuration overbroad projection

Date: 2026-08-16 IST

During read-only isolation of the C33Z pre-prompt rejection, the first bounded
comparison correctly output labels and booleans only. A follow-up diagnostic
then serialized the complete `runtimeConfiguration` parent object instead of
projecting only the three intended boolean fields. This printed non-secret
runtime metadata beyond the required comparison scope.

No password, API-key value, OAuth client ID, token, nonce, private key, private
account identifier or private link was read or printed. The command was still
overbroad and is registered before further release work.

Future diagnostics must use an explicit allowlist of property names and emit
only labels plus boolean values. Never serialize secret-adjacent parent objects.
