# C29L guessed customer-copy config path rejection

A C29L customer-copy audit successfully read the focused Flutter gate, then also tried to read an assumed `config/social-customer-visible-commentary-regression-gate.json` file. That path does not exist, so the combined read exited with a path error.

The permanent prevention is to resolve any companion gate through `rg --files` before reading it, and to treat the already confirmed Flutter gate as the authority when no separate machine-state file is indexed. No source, provider, build, device or protected runtime changed.
