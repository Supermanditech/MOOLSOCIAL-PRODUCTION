# C29L guessed findings patch anchor rejection

The first least-privilege correction patch referenced an `Authority boundary`
heading that is not present in the C29L findings document. `apply_patch`
rejected the complete atomic patch, so none of its code, test, script or prose
changes were applied.

The exact heading inventory was then read. Future multi-file patches use only
confirmed anchors, and optional prose updates are separated from product-code
changes. No provider, build, device, credential or secret state changed.
