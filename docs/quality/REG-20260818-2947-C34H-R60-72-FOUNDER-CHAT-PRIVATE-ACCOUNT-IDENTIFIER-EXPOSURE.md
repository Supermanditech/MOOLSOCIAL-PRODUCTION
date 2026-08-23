# REG2947 — C34H r60.72 founder-chat private account identifier exposure

## Observed event

While reporting the repeated Google sign-in failure on the already rejected Play-installed r60.72 candidate, the founder included two private account identifiers in chat. The identifiers are intentionally omitted from this record and must not be repeated, logged, copied, hashed, inferred, or used by Codex.

## Device truth

Two founder-controlled account attempts independently returned the same public generic Google completion failure. This is sanitized evidence that the r60.72 failure is not resolved by simply choosing another account; it is not proof of the exact provider/configuration cause.

## Mandatory prevention

1. Founder reports only `completed`, `cancelled`, or the public MoolSocial error class—never an email, account name, phone, OTP, link, or screenshot of a private surface.
2. Codex never repeats or persists private identifiers and stops all further r60.72 provider retries.
3. The successor must expose only a sanitized enumerated Google failure class, verify exact server-client/signing/provider configuration, and qualify a new Play-installed candidate before another founder account attempt.
