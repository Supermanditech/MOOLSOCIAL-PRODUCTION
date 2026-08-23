# C30U regression gate and format command combined recurrence

The regression-memory gate and Dart formatter were issued in one shell call
after the separate-process rule was documented. Both passed, but the command
shape was still unsafe.

Release work now uses one authoritative gate or native action per shell call.
No release mutation occurred.
