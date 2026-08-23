# UAW C31C predecessor-golden successor versioning

## Incident

The first combined C31C Chat test run failed the three existing provider-screen
goldens. The new Forward action is intentionally visible on settled messages,
so the current shared message bubble no longer matches the sealed C31A/C31B
PNG expectations.

## Boundary and prevention

The predecessor PNGs are preserved and are not regenerated or overwritten.
Each affected visual case receives a new absent C31C-named path. Only those
successor files may be generated. C31A and C31B static gates continue to prove
their historical artifacts exist, while C31C owns the current visual contract.

The failed run performed no build, deployment, device mutation or live write.
