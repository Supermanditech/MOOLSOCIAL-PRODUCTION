# UAW C33G FIX3 Social home cancel-route assumption

The first focused widget run showed that Social `home` initializes the canonical Videos tab. Create therefore preserves `/app/social?sub=videos` as its cancellation origin, not the unnormalized `sub=home` alias assumed by the test.

The corrected matrix binds each constructor origin to its accepted canonical cancellation route.
