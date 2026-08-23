# Full Chat UI V2 directory guess rejection

Date: 2026-08-14
Registry ID: `REG-20260814-2118-FULL-CHAT-UI-V2-DIRECTORY-GUESS-REJECTION`

The first Chat Dart-owner inventory supplied a guessed `apps/mobile/lib/ui_v2/chat` path. That path does not exist; current Chat presentation and state owners live under `apps/mobile/lib/features/chat` and are reached through shared V2 navigation.

The retry enumerates only existing `apps/mobile/lib` and `apps/mobile/test` roots and filters their returned Dart paths. No Chat source, test, reference or machine state was changed.
