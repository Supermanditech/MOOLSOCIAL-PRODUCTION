# C22B native failures masked by later gates rejection

The first combined verification emitted a failed Flutter test and three analyzer errors, then continued through successful policy gates and returned outer exit code 0. The run is rejected. The retry asserts every native exit code immediately and stops before later gates on any nonzero result.
