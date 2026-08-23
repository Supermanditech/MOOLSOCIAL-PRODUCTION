# C29P broad regression evidence search timeout

A repository-wide search for a known regression ID timed out even though its exact evidence owner was already resolved by the registry. Future evidence reads use the literal registry path and never repeat a broad search when the target is known.
