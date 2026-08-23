# C30U locked-test reverse-patch whitespace miss

The first platform-test reverse patch removed the semantic additions but did
not restore the approved byte hash. A remaining whitespace-only difference was
therefore still rejected by the immutable lock gate.

Locked restores now require both zero Git diff and the exact approved SHA-256.
No release mutation occurred.
