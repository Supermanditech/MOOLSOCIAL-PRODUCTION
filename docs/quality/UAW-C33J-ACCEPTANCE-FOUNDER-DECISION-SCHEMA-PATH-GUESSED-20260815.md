# UAW C33J acceptance founder-decision schema-path regression

- Regression: `REG-20260815-2494-C33J-ACCEPTANCE-FOUNDER-DECISION-SCHEMA-PATH-GUESSED`
- Failure: strict mode stopped the first C33J gate because it queried `acceptance.approval.founderDecision`; the immutable acceptance owner stores the field at `acceptance.verification.founderDecision`.
- Impact: zero gate pass evidence and no source-runtime, provider, email, build, Play or device mutation.
- Prevention: bind only exact parsed schema paths from the frozen owner; do not infer sibling placement from field meaning.
