# C25E Ride projection patch used pre-format context — rejection

Date: 2026-08-09

The first C25E Travel/Bus source patch did not apply. Its Previous/Next hunk used line wrapping captured before the most recent Dart format, so `apply_patch` could not verify the current block. No partial hunk or runtime change was applied.

The correction must reread the exact bounded Ride blocks and apply smaller hunks against current formatted context.
