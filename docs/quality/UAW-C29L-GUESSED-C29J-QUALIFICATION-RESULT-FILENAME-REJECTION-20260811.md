# C29L guessed C29J qualification-result filename rejection

A C29L host-qualification audit listed the three actual C29J evidence files, but its precomposed second read assumed an additional `00-qualification-result.json` file. That filename is absent, so the command exited with a path error after the authoritative listing was printed.

The permanent prevention is to separate directory inventory from content reads and read only exact names returned by the inventory. No source, build, device, provider or protected runtime changed.
