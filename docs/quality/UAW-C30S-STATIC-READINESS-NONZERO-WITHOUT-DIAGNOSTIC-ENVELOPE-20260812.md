# C30S static readiness nonzero without diagnostic envelope

Date: 2026-08-12

The first complete static-readiness process exited nonzero, but its exception
text was not returned by the shell integration. No build, APK, AAB, device or
external state changed.

During gate development, top-level invocations now use a concise explicit
exception envelope. The permanent qualifier captures all gate streams in an
evidence log so assertion failures cannot be silent.
