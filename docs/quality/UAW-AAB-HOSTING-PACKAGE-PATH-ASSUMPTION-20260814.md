# AAB qualification Hosting package-path assumption

Date: 2026-08-14
Incident: `REG-20260814-2165-AAB-HOSTING-PACKAGE-PATH-ASSUMPTION`
State: registered before retry

A cycle-preparation read assumed `hosting/package.json`. That path does not
exist. The failed read ran no Hosting test and changed no source, manifest,
candidate, authority, artifact, Play or device state.

The next attempt must resolve the exact package owner from a bounded repository
inventory and reuse that literal path in both qualification cycles.

## Resolution

A bounded `rg --files -g package.json` inventory identified
`apps/web/package.json` as the unique MoolSocial web/Hosting package. Its exact
test owners are `apps/web/tests/firebase-public-site.test.mjs` and
`apps/web/tests/rendered-html.test.mjs`. Both cycles use this literal package
and test set.
