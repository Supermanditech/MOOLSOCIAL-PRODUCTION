# C29L ripgrep nonexistent-owner-path rejection

A read-only C29L duplicate-owner search passed assumed top-level `functions` and `services` paths to ripgrep. Those paths do not exist in this repository, so ripgrep returned an operating-system path error and the combined audit stopped. No repository, cloud, device or runtime state changed.

The successor search first obtains exact repository paths from `rg --files`, then searches only confirmed owners. Missing optional directories are never supplied as positional inputs to a fail-closed combined command.
