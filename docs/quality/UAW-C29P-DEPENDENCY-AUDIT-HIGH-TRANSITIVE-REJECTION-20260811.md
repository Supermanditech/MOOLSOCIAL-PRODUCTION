# C29P dependency audit high transitive rejection

The rules-test dependency install surfaced one high transitive brace-expansion advisory. A safe patch override to 5.0.9 removed all high and critical findings. Seven moderate advisories remain in the current Firebase Admin Cloud Storage lineage; npm proposes an unsafe major downgrade rather than a compatible fix. They are recorded for contextual re-review before any Dev deploy.
