# REG-20260812-1390 — C30I MVP checkpoint disposition property guess rejection

- Phase: C30I schema repair
- Failure: The lookup guessed a root property named `allowedImplementationDispositions`, but the checkpoint JSON has no such root property.
- Permanent prevention: Inventory the checkpoint's bounded root and nested property names first, then read only an actually discovered property path. Do not infer schema paths from validation messages.
- Protected state: Read-only failure; no ticket repair, source, build, install or deployment followed it.
