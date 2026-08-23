# UAW C30T registrant regex metacharacter false zero — 2026-08-13

A supplemental registrant count used `flutterEngine.getPlugins().add` as an
unescaped regular expression. The parentheses were interpreted as an empty
regex group rather than the literal Java call, producing a false count of
zero. The static readiness gate had already authoritatively passed with 15
plugins. The corrected supplemental count escapes the Java punctuation and
must agree with that gate.
