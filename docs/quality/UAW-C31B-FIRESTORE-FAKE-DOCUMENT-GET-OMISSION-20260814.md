# C31B Firestore fake document get omission

Date: 2026-08-14
Registry ID: `REG-20260814-2131-C31B-FIRESTORE-FAKE-DOCUMENT-GET-OMISSION`

The first C31B backend repository run reached `threadForParticipant`, whose real contract calls `DocumentReference.get()`. The bounded fake implemented transaction reads and collection queries but not that direct read, so two tests failed with `TypeError`.

The correction adds the exact fake document-read method before recompilation. The failed run is zero qualification evidence; no live Firestore or deployment was involved.
