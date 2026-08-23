# UAW C31E Chat session retained a fixed-length production message list

Date: 2026-08-15
Ticket: `UAW-C31E-PERSONAL-MVP-CHAT-PHOTO-ATTACHMENT-CONTINUITY`

## Escaped defect

`ChatSession.loadMessages` assigned the list returned by `ChatGateway`
directly to local state. `AuthenticatedChatGateway.listMessages` returns a
fixed-length list. Any later session-owned append—including the existing text
optimistic message and the C31E authoritative delivered photo—can therefore
throw `UnsupportedError` after messages have loaded.

The C31E test fake returned a `const` list and exposed the same production
contract mismatch. Diagnostic state proved both photo requests reached the
gateway before the append failed.

## Permanent correction

The session takes a new growable copy of every gateway message result before
storing it. The fixed-length fake is retained to prove the ownership boundary;
the gateway's immutable response contract is not weakened. This source repair
does not deploy a backend, build an app, update Play or mutate the OPPO.
