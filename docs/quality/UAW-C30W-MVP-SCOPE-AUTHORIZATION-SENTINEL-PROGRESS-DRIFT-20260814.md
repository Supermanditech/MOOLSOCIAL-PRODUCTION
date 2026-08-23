# C30W MVP scope authorization sentinel progress drift

The final C30W scope replay failed closed because the top-level exact
`ticket_disclosed_and_authorized` authorization sentinel had been replaced by a
source-qualification progress label. That field is contractual; progress is
owned by the selected assessment, checkpoint, provider and ticket state.

The exact authorization sentinel is restored while all build, upload, install,
device, deployment and secret-value authorities remain false. No prohibited
action occurred.
