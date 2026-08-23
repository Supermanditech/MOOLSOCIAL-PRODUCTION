# C25B guessed Flutter package import — rejection

Date: 2026-08-09

The first focused C25B test did not compile because it imported `package:moolsocial_mobile/...`, an inferred package identifier that Flutter could not resolve. No test assertion executed and the run is rejected.

The correction must bind the import to the exact `name` in `apps/mobile/pubspec.yaml` or an existing adjacent test import, then rerun the permanent regression gate before retrying the focused test.
