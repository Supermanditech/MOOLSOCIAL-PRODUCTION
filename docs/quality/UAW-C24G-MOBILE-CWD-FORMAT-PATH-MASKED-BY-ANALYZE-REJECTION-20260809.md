# C24G mobile-CWD format path masked by analyze rejection — 2026-08-09

The first C24G format/analyze command ran from `apps/mobile` but passed three
repository-root-prefixed paths to `dart format`. The formatter reported that
all three paths were absent. A later successful analyzer command determined the
compound shell exit code, so exit zero did not mean formatting ran.

The retry uses paths relative to the actual `apps/mobile` working directory and
format/analyze results are checked independently. An analyzer pass is not
accepted as evidence for a formatter invocation.
