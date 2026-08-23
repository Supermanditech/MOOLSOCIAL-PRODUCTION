# C21G raw-pixel capture fake-async hang rejection — 2026-08-08

The first C21G rendered-pixel proxy did not complete within the bounded tool window and was terminated. The harness awaited `RenderRepaintBoundary.toImage` directly under the widget test fake-async clock rather than using `WidgetTester.runAsync` for image and byte conversion.

The terminated run is rejected and cannot count as optical-delta or host-cycle evidence. REG-20260808-490 requires `runAsync`, image disposal and a complete bounded pass before the proxy can enter a gate. No runtime, build, install or OPPO state changed.
