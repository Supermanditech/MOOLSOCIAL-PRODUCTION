# C23G Home to Buy Medicine router-query divergence

The isolated Buy continuity test reached the Medicine experience through the
new C23 Home action, but `GoRouter.routeInformationProvider.value.uri` reported
`/app/buy` without `sub=medicine`. This is not accepted as a host pass because
visible state, current URI and retained return context must agree. C23G remains
unqualified and build/install authority remains closed while the shared
main-destination page-key/router behavior is diagnosed.

## C23E1 successor correction

The bounded route-owner trace proved that the original assertion read the
underlying base route. The visible Buy page's `GoRouterState` truthfully owned
`/app/buy?sub=medicine` before and after refresh. REG-20260809-591 retains the
corrected permanent test owner; this original rejection remains preserved.
