# C24G C11 source-owner key guess rejection — 2026-08-09

Before running the rewritten C11 connected-chooser coverage, literal source
inventory found that its guessed Social `screen04-feed-list` and Buy
`buy-v2-root` keys do not exist. The rewrite had not yet been executed, so no
test result was misrepresented.

The accepted current owners are `screen04-feed-thumb-composer` from the
protected Social matrix and `buy-v2-screen` from the Buy production root. The
test is corrected to those literal keys before its first run.
