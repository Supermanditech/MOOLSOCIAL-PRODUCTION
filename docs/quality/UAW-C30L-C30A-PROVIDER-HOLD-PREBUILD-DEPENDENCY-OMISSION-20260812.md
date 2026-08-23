# C30L C30A provider-hold prebuild dependency omission

The C30L prebuild audit proved the post-r60.38 C30I/C30J/C30K source/data and
the new content runtime, but it failed to stop on C30A's older machine state:
`source_complete_real_shorts_provider_deployment_held`. That source fix is a
mandatory runtime dependency for the Shorts journey and should have prevented
the single build from opening until its exact live revision was reconciled.

Future candidate audits must enumerate every active Social ticket containing a
deployment/runtime/provider hold, not only the newest source delta. C30L's one
build and one install are consumed; neither may be repeated.
