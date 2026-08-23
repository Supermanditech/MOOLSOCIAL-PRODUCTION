# Post-seal C20E center offset misread as panel height

The initial REG-2297 evidence described expected `160` versus actual `76/116`
as panel heights. Source-line inspection shows the failing assertion is line
222, comparing `cluster.center.dx` with `rail.center.dx`.

The correct observation is that the historical test expects centered compact
clusters at x=160, while current two/three-action clusters are left anchored
with centers at x=76 and x=116. The separate reduced-motion failure still
casts the current `SizedBox` selection owner to `AnimatedContainer`.

REG-2299 must be registered before correcting REG-2297 and its evidence. This
interpretation error does not change the native test output or authorize a
retry or runtime mutation.
