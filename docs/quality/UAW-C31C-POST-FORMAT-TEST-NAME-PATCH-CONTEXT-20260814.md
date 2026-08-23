# UAW C31C post-format test-name patch context

## Incident

The first combined registration and source-correction patch expected the
pre-format one-line test declaration. Dart format had split that declaration,
so `apply_patch` rejected the complete multi-file patch atomically.

## Impact and prevention

The rejected patch made zero mutation. The exact formatted 10-line region was
then reread. Future post-format repairs use only immediately observed context,
and atomic rejection is verified before retry.
