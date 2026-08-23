# UAW C31E first static gate used an over-specific photo-forward pattern

Date: 2026-08-15
Ticket: `UAW-C31E-PERSONAL-MVP-CHAT-PHOTO-ATTACHMENT-CONTINUITY`

## Rejected gate attempt

The first C31E static gate failed its combined membership/finalize/reply/
forward/dispatch assertion. A bounded projection proved every condition true
except the assumed literal `sourceMessageData.photo`.

The existing C31C Firestore forward owner calls the record `sourceData`, reads
its authoritative `messageType`, and rejects unless that type is exactly
`text`. This already excludes photo messages and is covered by the retained
text-only error and backend regression.

## Permanent correction

The C31E gate binds the real message-type extraction, `messageType !== "text"`
rejection and customer error together. It does not add a redundant product
branch solely to satisfy a guessed static pattern. The failed gate remains zero
qualification evidence and was registered before retry.
