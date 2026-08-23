# C24 reference route inventory unbounded-search rejection

Date: 2026-08-09

The first reference-to-production owner inventory combined a failed family-list
anchor with an overbroad multi-root route/token search. The blank anchor caused
an unrelated opening source range to print, while the 1,184-match route search
was truncated. The output is rejected and cannot support ticket selection,
reuse proof or duplicate absence.

The corrected audit discovers exact declaration line numbers first and runs
separate bounded searches for Eat, Ride, Book, Work, Medicine and Bus. Each
search reports its own count and only the exact owner snippets required for the
decision; zero-result Bus discovery is handled explicitly.
