# C30U Screen 03 acceptance multiversion path concatenation

The first acceptance lookup returned both superseded v2 and current v3, then
treated their paths as one scalar. The read failed and supplied no evidence.

The retry selects the single production-accepted version explicitly. No source
or release mutation occurred.
