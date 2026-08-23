# REG2816 — C34L FIX2 duplicate-journal expected literal

Date: 17 August 2026
State: registered first PS7 journal exact-class fixture failure; zero writes

## Mistake

After lifecycle fixtures passed on both hosts, the first PS7 journal run reached
the duplicate-chain negative. The transition correctly rejected
`transaction journal has duplicate sequence or transaction identity`, but the
checker expected a transcribed phrase, `transaction journal sequence has a
duplicate`. The intended failure class and no-write behavior were correct; no
retry or mutation followed.

## Prevention

Bind exact-class fixture expectations to the authoritative transition error
constant/literal read directly from the owner. Do not rephrase or manually
transcribe rejection text in the checker.
