# C22B dart format output-none nonwriting rejection

The second formatter check repeated the same change because `dart format --output=none` does not write formatted content. The prior evidence is corrected: write mode must run without `--output=none`, followed by a separate check-only invocation that reports zero changes.
