# UAW C30T YouTube upload production-reachability lock — 2026-08-13

The upload implementation is retained behind `uploadCapabilityAuthorized`,
which defaults false and is set true only by explicit upload tests. Production
`/app/creator/youtube-connect` uses the default read-only mode, and the current
Social Create owner passes no `onCreateYouTubeShort` callback.

Because the compliance declaration excludes upload and keeps it separately
gated, a permanent source test now locks those three facts. This is regression
prevention only: no runtime, provider, OAuth, scope, UI, build, device or
external state changes.

The source lock plus complete Create/publication and Screen 04 conformance
files passed 61 tests with SHA-256
`8F381942F9EC6ABFA1BCC387CB5A053F3BE9A7D729EC076A109B805DCD2119B4`.
