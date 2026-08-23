# FSC06 global Windows PowerShell compatibility pre-existing rejection

The repository-wide `scripts/check-windows-powershell-compatibility.ps1` static
sweep rejected existing scripts outside FSC06 for use of
`[IO.Path]::GetRelativePath` and `[Convert]::ToHexString`.

Named examples include the pre-existing C28D/C26H device-matrix gates and
C17E/C20G/C21G/C22G/C23G/C24H/C25G/C26G/C27E/C28C historical qualification
scripts. FSC06 did not modify those owners, and repairing them would expand the
selected Shop navigation ticket.

The FSC06-changed gate is only
`scripts/check-buy-protected-baseline.ps1`; it uses neither banned API. It must
be executed directly under Windows PowerShell 5.1 as the bounded compatibility
evidence. The global sweep remains a separately disclosed repository blocker.
