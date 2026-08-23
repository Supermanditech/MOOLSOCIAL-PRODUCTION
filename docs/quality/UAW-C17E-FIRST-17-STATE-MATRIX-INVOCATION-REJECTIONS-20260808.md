# C17E first 17-state matrix invocation rejections

Date: 2026-08-08

The first C17E matrix invocation did not load the test.

1. Repository `config/...` paths were read from the `apps/mobile` working
   directory, so both JSON reads failed. The command also aggregated JSON,
   formatting and tests under one final status. JSON must be validated
   independently from repository root.
2. The matrix accessed nonexistent `AnimatedContainer.width` and `.height`
   getters. Those constructor arguments are represented internally through
   constraints; the focused test must measure the rendered indicator with
   `tester.getSize` and separately inspect the duration widget.

No C17E test result or host-cycle progress was admitted.
