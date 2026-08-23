# UAW C31C historical regression-name literal drift

## Incident

C31C added a forward-action assertion to the existing C31B read-message widget
test. Its first edit also removed the exact `read outbound message keeps reply
and reaction actions` phrase required by the sealed C31B contract gate.

## Detection and impact

Bounded review of the predecessor gate caught the drift before execution. The
test behavior passed, but the historical gate would have rejected the renamed
owner. No runtime, backend, device or external state was affected.

## Prevention

Successor coverage preserves predecessor test-name literals as exact prefixes
and appends only the new scope. C31A and C31B static gates are replayed before
C31C source qualification.
