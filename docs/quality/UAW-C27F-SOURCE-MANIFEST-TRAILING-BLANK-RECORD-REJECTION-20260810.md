# C27F source-manifest trailing blank record rejection

The first C27F aggregate manifest contained the 12 intended records plus one
trailing blank record. Its line-count audit returned 13, so the manifest was
not sealed and build authority remained closed.

Versioned source manifests must contain exactly the declared nonblank records
before their checksum is registered in APK machine state.
