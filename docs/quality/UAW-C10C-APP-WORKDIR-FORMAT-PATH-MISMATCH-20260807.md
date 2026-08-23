# C10C app-workdir format path mismatch

The formatter ran from `apps/mobile` while its operands still began with `apps/mobile/`. It therefore formatted nothing and reported both paths missing. Commands rooted in `apps/mobile` now use `lib/...` and `test/...` operands.
