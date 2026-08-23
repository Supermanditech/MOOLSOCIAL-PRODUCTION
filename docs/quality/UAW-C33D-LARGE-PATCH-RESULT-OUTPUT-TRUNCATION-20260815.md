# C33D large-patch result output truncation

Date: 2026-08-15

## Incident

One `apply_patch` added the C33D state, contract, qualification and gate, but
its returned result exceeded the available model context and was truncated.
The interruption therefore preserved an unknown mutation result and no retry
was permitted from transcript memory alone.

## Verified recovery

Before any retry or qualification run, all four intended paths were checked
independently. Each exists, is non-empty and is readable; bounded head and tail
inspection confirmed the intended C33D identity and complete file endings.
Their SHA-256 values at recovery were:

- State: `8A609C0011959EFC545AC00ED304751969E2C38FBFE688E176CE044EBA7B561C`
- Contract: `9BC90116AD31678161449FEC40709B9C9921A04CE7E89F5F608303E4A16ACB0F`
- Qualification: `1B93AED5D1889BD72F21598B558DFCAB83359854A7B91F79A398ABB133016A13`
- Gate: `A8B9431524116BD2FC0B3AA80DC32FBE6F877C8A7DE5F4D40E8DD53EBC9677C1`

The original patch had landed. It was not retried and none of the four files
was overwritten during recovery.

## Prevention

Future multi-file mutations must use bounded patches with immediate
verification. Any truncated mutation result remains unknown until every target
is checked explicitly; transcript inference is never accepted as evidence.

No build, Play action, OPPO mutation, credential access, backend/provider
deployment, email, quota submission or other external action occurred.
