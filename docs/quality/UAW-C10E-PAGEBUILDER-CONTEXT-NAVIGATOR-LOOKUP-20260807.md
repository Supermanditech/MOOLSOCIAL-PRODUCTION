# C10E page-builder context Navigator lookup

Date: 2026-08-07

Ticket: `UAW-PERSONAL-MVP-GLOBAL-NAVIGATION-MOTION-CONTAINMENT-OPPO-FIX1-C10E`

The first C10E focused journey exposed a real system-Back defect after Social
opened Mool. The Mool route's `pageBuilder` callback captured a context above
the Navigator, but `leaveMool` called `Navigator.of(context).canPop()`. System
Back therefore threw instead of restoring Social.

The route callback must use GoRouter's context extension for `canPop` and
`pop`, which is valid from the page-builder context. The same correction
applies to the action-choice fallback closure. The dedicated C10E
Social → Mool → Social → Mool journey remains the prevention gate.
