# C30U immutable platform-configuration test hash escape

The approved UI gate found the shared platform configuration test changed after
the two direct Screen 03 owners were restored. Its current hash did not match
the immutable Screen 03 checkpoint.

The locked test will be restored exactly. Successor release, plugin and
Firebase configuration checks remain in C30U-specific non-locked machine gates.
No AAB, upload or OPPO mutation occurred.
