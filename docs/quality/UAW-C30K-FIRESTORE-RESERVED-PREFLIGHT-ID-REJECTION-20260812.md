# C30K Firestore reserved preflight identifier rejection

## Finding

The second apply attempt stopped during the new read-only service preflight with `service_read_preflight_grpc_3`. It performed no Auth, Firestore or Storage mutation. The Firestore probe document used the reserved `__.*__` identifier pattern.

## Disposition

Rejected and registered as `REG-20260812-1409-C30K-FIRESTORE-RESERVED-PREFLIGHT-ID-REJECTION`.

## Permanent prevention

Use the ordinary stable identifier `c30k-read-probe` for the bounded Firestore read and keep the preflight ahead of persona or post mutation. Stage-specific error codes remain required.
