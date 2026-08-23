# C30S Play release-note locale-tag layout rejection — 2026-08-13

## Bounded event

The first Internal Testing release-note value placed the `<en-GB>` opening tag, truthful note text and `</en-GB>` closing tag on one line. Google Play Console reported the locale tag as unclosed and kept **Next** disabled.

The accepted r60.44 AAB remained present and unchanged as version code `2026081244`. No second upload, build, release or track mutation occurred.

## Retry gate

- Keep the release-note scope truthful and limited to the startup recovery.
- Put `<en-GB>` alone on line 1.
- Put the note text alone on line 2.
- Put `</en-GB>` alone on line 3.
- Continue only if Play reports release notes for one language and enables **Next**.

## Resolution

The corrected three-line value was accepted as one `en-GB` language. Play enabled **Next**, the review page reproduced the exact note without tags, and release publication remained confined to Internal Testing.
