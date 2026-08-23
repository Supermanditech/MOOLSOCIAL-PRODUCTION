# C24B3 tap-height multifile patch scope rejection — 2026-08-09

The first REG630 correction patch was atomically rejected because the final connected-navigator test hunk remained under the shared source-file section. No registry, evidence, runtime or test mutation occurred.

The retry is separated into explicit registry/evidence, source and test patches so each owner has an unambiguous file marker and literal context.
