# C31E photo reply test fake tuple patch placement — 15 August 2026

The patch that added optional reply continuity to photo messages used a
repeated parameter-list anchor in `service.test.ts`. It inserted
`replyToMessageId` twice into the existing text-message fake while leaving the
photo input tuple at its old arity. TypeScript then correctly reported duplicate
identifiers, tuple length mismatch and shifted field types.

The failure is isolated to the test double; no compiled output or external
state changed. The correction must read the exact fake field and both method
signatures, remove the duplicate from `sendMessage`, and add one optional reply
slot only to `sendPhotoInput` and `sendPhotoMessage`.

The duplicate parameter was removed and the photo method now carries exactly
one optional reply ID. The complete backend typecheck passes.
