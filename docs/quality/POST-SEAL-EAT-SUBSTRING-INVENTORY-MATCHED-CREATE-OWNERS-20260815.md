# Post-seal Eat substring inventory matched Create owners

The first successful whole-lib Eat filename regex searched for the unbounded
substring `eat`. That substring also occurs in `create`, so the output mixed
the real `features/eat` owners with unrelated Creator, Social Create and
YouTube files.

The noisy list is not an Eat manifest. REG-2296 must be registered before
retry. The exact inventory will require the literal `features/eat/` path
segment; imported shared app, journey and universal owners will be listed
separately from exact test imports.
