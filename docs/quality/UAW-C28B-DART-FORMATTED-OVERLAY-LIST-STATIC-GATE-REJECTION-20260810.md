# C28B Dart-formatted overlay list static-gate rejection

- Date: 2026-08-10
- Phase: focused implementation qualification
- Mutation before failure: source and tests were formatted; no build/install
- Rejection: the C28B static gate required both overlay strings on one line,
  but `dart format` legally expanded the list.
- Root cause: a source gate depended on Dart formatting adjacency rather than
  checking the two independent behavioral tokens; this repeated the durable
  REG922 pattern.
- Prevention: static gates check distinctive overlay tokens independently;
  the method-channel test proves exact ordered arguments.
