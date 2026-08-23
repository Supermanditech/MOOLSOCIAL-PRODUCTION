# C30T main Chat import omission

## Observation

The product entrypoint was updated to pass `ChatSession.production()` into `MoolSocialApp`, but the initial edit omitted the corresponding `chat_session.dart` import. The omission was found by reviewing the bounded file header before compilation.

## Root cause

The edit focused on runtime ownership and disposal without checking whether the newly referenced concrete type was already in scope.

## Permanent prevention

- Inspect the file header whenever an edit introduces a new concrete Dart type.
- Add the exact package-relative import in the same patch.
- Preserve the bounded pre-compile source-header review before analyzer execution.
