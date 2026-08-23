# C29P full backend output truncation rejection

An unbounded full npm test invocation produced output too large to admit. The suite was rerun with captured output, immediate exit-status preservation and a bounded totals tail; that rerun passed 481 of 481 tests before later hardening changes required fresh qualification.
