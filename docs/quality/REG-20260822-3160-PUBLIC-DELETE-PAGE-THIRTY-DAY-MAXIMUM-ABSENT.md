# REG3160 - Public delete page 30-day maximum absent

## Classification

Registered initial false absence corrected with zero Hosting mutation.

## Evidence

An unauthenticated GET of `https://moolsocial.com/delete-account/` returned HTTP 200. The initial matcher required `30` immediately followed by `days` and returned false for both live content and current source, proving that the matcher—not Hosting—caused the result. No Hosting deployment or other external write occurred.

## Prevention

Prove compliance-wording matchers against current source before applying them live. Allow bounded intervening text and never infer a deployment requirement from an unproven matcher.
