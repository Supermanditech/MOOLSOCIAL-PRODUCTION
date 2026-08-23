# C23E1 same-path page-key collapse rejection

Origin-aware replacement alone did not preserve `sub=medicine`. The new target
and older Buy page still shared the path-derived `state.pageKey`, so navigation
collapsed onto `/app/buy`. C23E1 therefore also binds shared main-destination
page identity to the complete URI. No host cycle or APK authority passed.
