# C16B exact-patch terminal-newline synthetic-blank rejection

## Incident

The byte-derived legacy block and its boundary tokens were correct, but the
deletion-hunk generator split a newline-terminated substring and treated the
synthetic final empty array element as another real blank line. Apply-patch
therefore expected one more blank line before `@immutable` and rejected the
hunk atomically.

## Root cause and prevention

String-split representation was mistaken for source line representation at a
terminal newline. The retry drops exactly one synthetic terminal element when
the decoded block ends in newline, preserves the real blank source line, and
uses the following immutable marker as unchanged context.
