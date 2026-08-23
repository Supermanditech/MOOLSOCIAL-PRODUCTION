# C16B tool-isolate TextDecoder unavailable exact-patch rejection

## Incident

The explicit Base64 decoder produced the exact legacy-block bytes, but the
minimal tool isolate also lacks `TextDecoder`. The workflow stopped before
apply-patch, leaving the Social source unchanged.

## Root cause and prevention

A second web-runtime global was assumed. The bounded legacy Dart block is
ASCII-only, so the retry converts validated bytes to characters in small chunks
without external globals, verifies both legacy class boundary tokens, and only
then calls apply-patch.
