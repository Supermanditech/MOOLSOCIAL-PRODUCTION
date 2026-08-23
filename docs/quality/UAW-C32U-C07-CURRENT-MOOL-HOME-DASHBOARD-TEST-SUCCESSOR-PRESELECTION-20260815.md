# C32U C07 current Mool Home dashboard test successor preselection

C32R reproduced C07 as one pass and four failures. The failures require removed
root-rail owners such as `mool-root-selected`, `mool-root-main-actions` and
`mool-home-primary-actions`. Current R03, C24B2, C26D and C27D tests qualify the
fixed dashboard and `mool-home-family-*` menu instead.

C32U permits migration of only the C07 test owner. Runtime Home/navigation
source, routes, keys, semantics, geometry and copy remain read-only. The new
test contract must keep Social-to-connected-menu, direct-route Home, all six
families and exact platform Back behavior. All live and release authorities
remain closed.
