# UAW-R08 Personal Book exposure interaction and navigation contract V1

1. Tap **Book** on Mool to push `/app/book`.
2. Book shows exactly **Doctor** and **Salon**.
3. Tap **Doctor** to push `/app/book/doctor`.
4. Tap **Salon** to push `/app/book/salon`.
5. The existing Doctor and Salon owners remain responsible for their bounded
   booking decisions, validation, completion and recovery.
6. Visible/system Back restores the prior surface, falling back to
   `/app/mool?from=book` on direct entry.
7. Mool opens `/app/mool?from=book`; global Chat opens
   `/app/chat/inbox?return=/app/book`.

The shared native surface owns presentation, finite/reduced motion, semantics,
tap targets and responsive behavior. Get It Done, Clinic, Hospital and home
beauty are absent. This ticket does not promise a booking, diagnosis, payment,
provider outcome or service completion.
