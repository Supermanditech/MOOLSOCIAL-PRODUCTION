# UAW C31E first mobile analyzer picker and gateway-promotion failure

Date: 2026-08-15
Ticket: `UAW-C31E-PERSONAL-MVP-CHAT-PHOTO-ATTACHMENT-CONTINUITY`

## Rejected attempt

The first targeted analyzer run over the four changed Chat mobile owners ended
with two issues: `prefer_initializing_formals` for the optional review picker,
and an `unchecked_use_of_nullable_value` rejection where `sendPhoto` was called
after relying on implicit promotion of a nullable `ChatGateway` local to the
separate `ChatPhotoGateway` interface. This run is zero qualification evidence.

## Root cause and prevention

The constructor used a redundant initializer assignment, while the send path
relied on an inferred nullable intersection type. The correction uses an
initializing formal and resolves the capability to an explicitly typed
`ChatPhotoGateway?`, then fails closed before the call unless it is non-null.
The incident was registered before the analyzer retry. It did not build,
deploy, install, access a provider, or mutate the connected OPPO.
