# UAW-CODEX-BUY-INVOICE-DOWNLOAD-RUNTIME-20260824

Status: implementation and focused local verification complete; OPPO runtime acceptance pending.

Objective: save the exact placed-order invoice as a genuine PDF chosen by the customer on Android.

Required behavior:

- Generate a real PDF from the persisted order and exact order lines.
- Use Android's system document picker with `application/pdf`.
- Report success only after the selected output stream is written and flushed.
- Report cancellation, unavailable platform and write failure truthfully.
- Request no broad or legacy external-storage permission.
- Keep in-app invoice viewing available independently of saving.

Focused evidence:

- Dart payload and outcome tests pass.
- Android source-containment test passes.
- Focused Dart analysis passes.
- Android release Kotlin compilation passes.

Runtime acceptance:

- Open a placed order invoice on OPPO.
- Choose Download invoice and select a customer-controlled destination.
- Verify the PDF exists, opens, and contains the exact order ID, lines and total.
- Cancel a second save and verify the app does not claim success.
