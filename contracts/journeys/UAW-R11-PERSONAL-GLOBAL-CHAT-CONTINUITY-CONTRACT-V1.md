# UAW-R11 Personal global Chat continuity contract V1

1. Personal Mool exposes one global **Chat** entry.
2. Each shared Eat, Ride, Book and Work root exposes the same global Chat
   entry; Chat is not duplicated as a main action tile.
3. Mool pushes `/app/chat/inbox?return=/app/mool`.
4. Each shared action root pushes
   `/app/chat/inbox?return=/app/{exact-action}`.
5. The existing Chat inbox is the authoritative in-app conversation owner.
6. Chat Back returns to the exact permitted origin; thread Back returns to the
   inbox before the same origin.
7. A non-`/app/` return target falls back safely under the existing Chat owner.

Existing direct and journey-context Chat entry remains owned by its parent
vertical contracts. This ticket changes no message, thread, attachment,
notification, presence, call, support or backend behavior. WhatsApp or any
external messenger is not an authoritative MoolSocial record.
