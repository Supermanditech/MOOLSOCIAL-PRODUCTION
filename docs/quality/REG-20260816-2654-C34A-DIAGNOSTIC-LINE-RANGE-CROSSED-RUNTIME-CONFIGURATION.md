# REG2654 — C34A diagnostic line range crossed runtime configuration

Date: 2026-08-16 IST

After REG2653 was registered, a numbered-line read intended to inspect C34A
lifecycle and rejection fields extended into the adjacent
`runtimeConfiguration` block. It again printed non-secret runtime metadata
outside the required boolean comparison scope.

No password, API-key value, OAuth client ID, token, nonce, private key, private
account identifier or private link was read or printed. The repeated overbroad
output is nevertheless a registered pre-seal diagnostic mistake.

No C34A gate or source seal is counted. All further state inspection must select
exact named non-secret lifecycle properties. Runtime configuration inspection is
limited to explicit boolean labels and values; raw ranges and parent-object
serialization are forbidden.
