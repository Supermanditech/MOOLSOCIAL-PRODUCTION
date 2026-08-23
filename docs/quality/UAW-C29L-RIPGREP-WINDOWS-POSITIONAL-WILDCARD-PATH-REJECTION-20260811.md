# C29L ripgrep Windows positional wildcard-path rejection

A bounded C29L source audit passed `backend/functions/src/youtube/upload*.ts` as a positional ripgrep path. On Windows the wildcard was not expanded as a filesystem input and ripgrep reported an invalid filename, although its other confirmed path searches completed.

The permanent prevention is to use ripgrep's `-g` include filters against a confirmed directory, or resolve exact files through `rg --files`, instead of passing wildcard filenames as positional Windows paths. No source, provider, build, device or protected runtime changed.
