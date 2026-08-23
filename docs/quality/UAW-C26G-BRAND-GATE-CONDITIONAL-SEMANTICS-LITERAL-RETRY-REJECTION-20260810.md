# C26G brand gate conditional-semantics literal retry rejection

The first brand-gate migration looked for `label: 'Open MoolSocial main menu'` as one contiguous source token. The runtime correctly owns a conditional expanded/collapsed label, so the `label:` property and open-string literal are separated across lines.

The brand gate now asserts the exact open-string literal without formatting-specific adjacency. The C26C widget tests retain semantic-label and tap-action proof.
