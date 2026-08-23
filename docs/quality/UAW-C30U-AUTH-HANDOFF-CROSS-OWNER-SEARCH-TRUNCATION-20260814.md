# C30U auth-handoff cross-owner search truncation

The locked Screen 03 investigation formatted matches from six owners in one
command. Long Dart lines and wrapped absolute paths caused output truncation,
so none of that combined result is used as implementation evidence.

Recovery now reads only narrow exact regions around already located symbols,
one owner at a time. No source or release mutation occurred from the search.
