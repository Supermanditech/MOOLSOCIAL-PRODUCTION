# UAW C30T secure sign-in multiline semantic normalization false diagnosis — 13 August 2026

## Correction

The retained pre-tap hierarchy proves the Google authentication screen was current and owned by `com.moolsocial.app`. Its exact accessibility description contains a line break between the two Google labels. A diagnostic table normalized that line break to a space; the normalized display string was then passed to an exact-match tap helper and produced zero matches.

The earlier stale-screen diagnosis is therefore not the root cause. It remains preserved as the original diagnosis record; this entry is the permanent correction.

## Permanent prevention

- Never reuse whitespace-normalized diagnostic output as an exact accessibility selector.
- Use the raw `content-desc`, or select one exact node and calculate asserted integer bounds from that same current hierarchy.
- Diagnose zero matches from retained raw XML before attributing them to route state.
- Continue to pause for the founder after any secure handoff without inspecting account identities or credentials.

## Safety result

No tap, account chooser, credential access, OAuth action, external write, Create write or Chat send occurred.
