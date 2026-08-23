# C30W adjacent Dart copy static-gate false failure

The first C30W source-gate run rejected a complete safe-fallback sentence
because Dart stored it as adjacent wrapped string literals. The widget renders
the complete sentence; the rejected static assertion incorrectly required the
source bytes to be contiguous.

The static gate now checks stable literal fragments, while the widget test owns
the fully rendered customer copy. No build, upload, install, service action,
device mutation or secret access occurred.
