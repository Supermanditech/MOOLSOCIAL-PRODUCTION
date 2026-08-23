# C30S qualifier shell-timeout termination

Date: 2026-08-12

The first cycle-1 invocation used a one-second shell timeout while expecting a
resumable yield. The shell terminated the qualifier. It did not reach an APK
or AAB build and cannot count as qualification evidence. Its attempt directory
is preserved.

Long cycles now run in a hidden PowerShell 7 child process with explicit
stdout, stderr, PID and exit-code evidence files. The parent polls those files
at intervals shorter than 60 seconds. Only a complete zero-exit cycle with its
fixed success JSON can count.
