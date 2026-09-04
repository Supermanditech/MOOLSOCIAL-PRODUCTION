# Store-Buy replacement pre-integration reconciliation

- Shared historical baseline: `21118db8c061b085fe60ac419d52ee0fd83fcde2`
- Corrected Store-descended input: `300f4247165a097d82624f4b40c9c2d611c7bc48`
- Cursor Buy input: `fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d`
- Failed repair retained only as evidence: `c48e4ecc5c3ccc7a3079d3f64988437599cc78de`
- Serialized diagnostic evidence retained: `58af65f0bb566aaf275c3a856d02d11dba3df822`

The corrected Store input contains Store-Live, prior Work UI/Core ancestry and the qualified Universal navigation accessibility child. Cursor remains unchanged. Their only expected conflicts are the registry, coordination policy and coordination checker; all product and test owners must merge automatically.

The replacement repair must verify the exact corrected Universal source/test blobs and every authoritative Cursor Buy/UAT-BUY-073 blob before qualification. Full combined analysis and regressions run only after both inputs are present.
