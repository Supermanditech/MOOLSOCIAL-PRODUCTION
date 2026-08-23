# C29L gcloud config-list positional syntax rejection

The first C29L read-only CLI context command passed `account project` as two
positional arguments to `gcloud config list`. The installed CLI rejected the
syntax locally before any cloud metadata was read.

The retry uses no positional property list and projects only the non-secret
active account and project fields. No access token, credential value, secret,
cloud resource, provider, build or device state was read or mutated by the
failed command.
