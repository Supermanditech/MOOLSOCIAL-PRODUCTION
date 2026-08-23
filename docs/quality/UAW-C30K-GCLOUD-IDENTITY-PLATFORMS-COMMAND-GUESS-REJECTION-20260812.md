# C30K gcloud Identity Platform command guess rejection

## Finding

The read-only Auth provisioning audit invoked a guessed `gcloud identity platforms` namespace. The installed CLI reported that the command group does not exist.

## Disposition

Rejected and registered as `REG-20260812-1401-C30K-GCLOUD-IDENTITY-PLATFORMS-COMMAND-GUESS-REJECTION`.

## Permanent prevention

Discover the installed CLI surface with bounded help or use an already documented owner. Never infer an identity-management command group from Google Cloud product naming.
