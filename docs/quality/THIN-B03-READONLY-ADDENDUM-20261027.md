# THIN-B03 exact original Profile gateway admission addendum
The source audit demonstrated AccountProfileGateway.read() can call reconcile/save for an existing user-confirmed pending journal. This original manual recovery behaviour remains unchanged.
AI preparation and source revalidation require a true read-only refresh. Admit exactly one additional existing runtime owner:
apps/mobile/lib/features/journey01/account_profile_gateway.dart
Add readForPreparation(): use the existing owner/current-account credentials, serialisation, response acceptance and monotonic revision checks; if a pending journal exists, report the existing uncertain outcome instead of reconcile/save/replay. Otherwise call only the existing read endpoint. Do not clear the journal, mutate server data, invent a new transport or change manual read/save recovery.
Tests belong in the already admitted assistant_profile_context_test.dart; no additional test owner. Cover no Save/reconcile/journal-clear during pending capture, exact read-only request, foreign-owner/access denial, busy and stale account rejection.
One additional local metadata-only admission commit may record this exact29th owner and addendum; all original source-commit/push/cloud/model/domain/APK exclusions remain. Existing accepted CONTRACT.md bytes stay unchanged.
