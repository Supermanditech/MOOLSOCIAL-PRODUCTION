# C17C Social stale 44px wrapper rejection

Date: 2026-08-08

The C17C predecessor audit found that `Screen04ContextTabs` retained a
hard-coded 44px `SizedBox` around the successor 52px shared rail. This family
wrapper can clip the 48px action-control composition even though the standalone
C17B owner is correct. C17C must bind that wrapper to
`MoolLocalNavigationTokens.railHeight` and directly measure all four Social
targets before Social conformance can pass.
