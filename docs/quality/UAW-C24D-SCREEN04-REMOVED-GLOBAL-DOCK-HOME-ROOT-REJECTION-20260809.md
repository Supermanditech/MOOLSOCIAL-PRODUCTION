# C24D Screen04 removed global-dock/Home-root rejection — 2026-08-09

Screen04 content tests still navigated through `mool-root-selected`,
`mool-root-chat` and `personal-mool-root-v2`. Those controls were removed by
the connected single-launcher shell.

The durable feed, create, watch, profile and exact-return contracts remain.
Navigation assertions move to the connected MoolSocial chooser and current
Chat entry without reintroducing Home detours.
