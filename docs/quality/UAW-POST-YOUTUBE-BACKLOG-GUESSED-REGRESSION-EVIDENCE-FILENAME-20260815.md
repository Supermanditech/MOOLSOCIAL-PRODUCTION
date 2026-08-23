# Post-YouTube backlog guessed regression evidence filename

Date: 15 August 2026
Registry: `REG-20260815-2245-POST-YOUTUBE-BACKLOG-GUESSED-REGRESSION-EVIDENCE-FILENAME`

The follow-up inspection correctly read the last registry entry but then tried
an inferred evidence filename containing an extra `C31E` prefix. The file did
not exist and the combined command exited nonzero. The valid path was already
stored in the entry's `evidence` array.

No repository mutation other than this permanent registration, and no device,
provider, release or external action, occurred. Future evidence reads first use
the exact registry property, validate its literal path and then read it in a
separate command. Mixed metadata and guessed-path output is not evidence.
