# C33B REG-2304 status/result inexact document anchor

The first attempt to mark REG-2304 resolved and append its result was
atomically rejected. The registry anchor was exact, but the document hunk used
one unwrapped sentence while the file stores that sentence across two lines.
No target changed.

REG-2305 must be registered before retry. The registry status and document
result will be patched separately with their independently read exact anchors.
