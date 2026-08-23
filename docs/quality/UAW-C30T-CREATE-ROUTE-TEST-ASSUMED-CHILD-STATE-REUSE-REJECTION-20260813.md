# C30T Create route-test assumed child-State reuse rejection — 2026-08-13

## Rejection

The first explicit Create tool-route test assumed the workbench would receive
`didUpdateWidget`. The parent content key includes `_createView`, so the tool
route change remounted the child before that lifecycle method could run. The
expected Quiz owner was therefore absent.

## Prevention

The correction now traces and fixes the parent key owner: Create tool changes
reuse the workbench State, while real tab changes still use distinct keyed
subtrees and the shared draft. Release configuration was immediately restored
after the failed test to the exact 15-plugin/no-APK state. No external action
occurred.
