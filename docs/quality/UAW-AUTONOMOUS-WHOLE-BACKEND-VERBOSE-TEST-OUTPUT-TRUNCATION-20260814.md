# Autonomous whole-backend verbose test-output truncation

Date: 2026-08-14
Registry ID: `REG-20260814-2116-AUTONOMOUS-WHOLE-BACKEND-VERBOSE-TEST-OUTPUT-TRUNCATION`

The read-only full compiled backend unit corpus used Node's verbose default reporter. More than five hundred individual result lines overflowed the tool response, so the run is not accepted as durable qualification even though its visible final process summary was successful.

The retry captures output in memory and emits only the exit and exact aggregate counters, with a bounded diagnostic tail only if the process fails. No backend compilation, generated-file deletion or source mutation occurred.
