# C32U Social Mool direct-Home assumption

Regression: `REG-20260815-2284-C32U-SOCIAL-MOOL-DIRECT-HOME-ASSUMPTION`

The initial C32U wording inherited C07's assumption that tapping Mool from a
Social destination navigates directly to `/app/mool`. A pre-mutation read of
`MoolGlobalNavigationV2` showed the accepted behavior: the launcher toggles the
connected six-family menu; direct Mool Home remains a separate route.

C32U is corrected before any C07 test edit. It must verify Social-to-connected
menu, direct-route Home, family routing and Back independently. No compatibility
behavior is added to runtime source.
