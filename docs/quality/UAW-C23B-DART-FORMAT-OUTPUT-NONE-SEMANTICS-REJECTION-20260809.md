# C23B dart format output-none semantics rejection

- Date: 2026-08-09
- Runtime semantic change: none

The repeated no-diff gate again reported both new Dart files would change. This
proved the earlier report was wrong: `--output=none` does not normalize files,
even though the formatter prints `Changed` for files that differ from canonical
formatting.

The accepted sequence is plain `dart format` for the mechanical write, followed
by a separate no-output/no-diff check, analysis and tests.
