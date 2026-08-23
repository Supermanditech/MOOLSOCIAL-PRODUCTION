# C30U Node 22 spec summary prefix assumption

Cycle 1 backend verification completed 516 tests with process exit zero. Node
22 emitted its counted summary with the information-symbol prefix rather than
the older hash prefix, so the qualifier rejected the run before source sealing.

The parser now accepts only those two exact summary prefixes and still requires
the explicit expected pass/fail totals and zero process exit.

No AAB, upload, install or device mutation occurred.
