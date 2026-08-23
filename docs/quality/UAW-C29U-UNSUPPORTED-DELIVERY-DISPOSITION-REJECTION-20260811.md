# C29U unsupported delivery disposition rejection

Date: 2026-08-11

The first C29U selection assessment used `deployment_only` as an
`implementationDisposition`. The founder-locked delivery gate rejected that
invented value. Its supported vocabulary includes `configuration`, which is
the exact disposition for deploying already sealed owners.

C29U now uses `reuse`, `configuration` and `test_only_acceptance`. The outcome,
environment, authority and exclusions are unchanged. No cloud, runtime, build
or device mutation occurred before this rejection.
