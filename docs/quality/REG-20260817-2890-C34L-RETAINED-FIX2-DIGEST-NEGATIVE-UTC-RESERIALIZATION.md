# REG2890 — C34L retained FIX2 digest negative UTC reserialization

- Status: registered first unexpected PowerShell 7 fixture failure after REG2889 alignment.
- Failure: the wrong-digest-value fixture expected digest rejection but reached raw `producedUtc` canonical-wire rejection first.
- Root cause: the fixture rewrote the attestation through JSON object conversion/serialization to change a digest, and PowerShell date coercion changed the otherwise valid raw UTC token.
- Prevention: mutate only the exact digest value with cardinality-checked raw token substitution, preserving byte-for-byte UTC spelling and every other field; statically replace the same object-reserialization pattern in all remaining attestation/capture negatives before retry.
- Containment: no diagnosis, retry, WinPS, recovery, release, private, device, or external action followed.
