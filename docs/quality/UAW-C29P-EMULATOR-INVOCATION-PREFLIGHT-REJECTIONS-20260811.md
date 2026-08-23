# C29P emulator invocation preflight rejections

An unquoted PowerShell `--only` value and a JAVA_HOME-only attempt were rejected before startup. The accepted command quotes `firestore,storage`, exposes Android Studio's bundled JDK only inside the child process, restores PATH and uses `moolsocial-c29p-local`. The local Firestore and Storage denial tests then passed 2 of 2 without cloud writes.
