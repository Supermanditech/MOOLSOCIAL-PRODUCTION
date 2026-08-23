# C31E first backend typecheck union and fake contract gaps — 15 August 2026

The first C31E `tsc --noEmit` run rejected two bounded compile issues:

1. `photoFromDocument` validated the three allowed MIME strings, but the local
   returned object widened `contentType` back to `string` rather than retaining
   `ChatPhotoContentType`.
2. `FakeChatRepository` still implemented the predecessor interface and lacked
   the newly required `preparePhotoUpload` and `sendPhotoMessage` methods.

No compiled output, dependency, device, backend or external state changed.
The retry is blocked until the normalized result has an explicit union type and
the existing fake repository implements and tests the complete new contract.

The normalized result is now explicitly typed, the fake captures both photo
operations, focused service assertions were added, and `tsc --noEmit` passes.
