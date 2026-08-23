# Full Chat regression gate parameter mismatch

Date: 2026-08-14
Registry ID: `REG-20260814-2121-FULL-CHAT-REGRESSION-GATE-PARAMETER-MISMATCH`

The first full-Chat implementation regression gate invocation used the unsupported `-Mode implementation` parameter. The script rejected that parameter before executing its registry checks. Its declared contract uses `-Phase implementation`.

The corrected invocation must use the declared `-Phase` parameter from the script's bounded parameter block. The rejected invocation is zero gate evidence. No Chat source, backend, test, reference or machine state was changed by the failed command.
