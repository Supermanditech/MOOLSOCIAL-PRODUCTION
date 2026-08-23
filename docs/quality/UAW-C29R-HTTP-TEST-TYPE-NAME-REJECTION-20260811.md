# C29R HTTP test type-name rejection

Date: 2026-08-11

The first focused C29R TypeScript compile rejected the new client test because
it imported nonexistent `HttpRequest` and `HttpResponse` names. The existing
transport contract exports `HttpTransportRequest` and
`HttpTransportResponse` from `backend/functions/src/youtube/types.ts`.

The test must use those literal repository-owned types and pass strict
typecheck before any behavior result is accepted. No runtime, device,
deployment or external-service action occurred.
