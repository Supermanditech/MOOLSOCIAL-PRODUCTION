# C26H untracked-all long-path dirty inventory rejection

The first C26H dirty probe used leaf-level `--untracked-files=all`. Historical browser-profile evidence expanded to 53,292 records and Git emitted Windows filename-too-long warnings. That result is rejected and is not release evidence.

The established warning-free path-safe inventory uses `--untracked-files=normal`: tracked dirty files remain individual records, while each untracked owner directory is one record without recursively opening preserved historical evidence. No file is deleted, moved or ignored.
