# REG3168 - FIX8 stable source manifest owner-list inference mismatch

## Classification

Registered in-memory fingerprint mismatch with zero manifest write.

## Evidence

An inferred 13-path list was hashed using the preserved manifest line format with and without a terminal LF. Neither result matched the sealed FIX8 aggregate `DC284B6D...`. No file was created and the inferred list is rejected.

## Prevention

Regenerate the successor build manifest from the exact preserved r60.80 manifest path inventory, rehash every live file, then independently verify the manifest count and checksum. Do not infer qualification-owner lists.
