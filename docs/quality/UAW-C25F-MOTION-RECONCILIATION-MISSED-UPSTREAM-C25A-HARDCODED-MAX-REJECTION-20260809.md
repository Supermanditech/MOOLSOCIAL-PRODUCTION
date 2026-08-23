# C25F transitive C25A motion-gate rejection

Date: 2026-08-09

After the projection maximum was corrected to the established 320ms ceiling,
the C25F gate invoked C25A and rejected because C25A still hardcoded 220ms.
The active contract, C25A gate and C25F runtime cross-check must all use the
same 180-320ms interval containing the retained 240ms standard.
