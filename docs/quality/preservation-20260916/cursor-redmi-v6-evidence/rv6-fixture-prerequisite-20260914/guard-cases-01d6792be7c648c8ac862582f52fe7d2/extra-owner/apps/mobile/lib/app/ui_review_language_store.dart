import 'package:shared_preferences/shared_preferences.dart';

import '../features/journey01/journey_services.dart';

/// Review-only language durability. Other journey data stays in memory.
class UiReviewLanguageStore implements JourneyStore {
  UiReviewLanguageStore({
    required JourneySnapshot seed,
    Future<SharedPreferences> Function()? preferences,
  }) : _snapshot = seed,
       _preferences = preferences ?? SharedPreferences.getInstance;

  static const languageKey = 'moolsocial.ui_review.language.v1';
  final Future<SharedPreferences> Function() _preferences;
  JourneySnapshot _snapshot;
  bool _restored = false;

  @override
  Future<JourneySnapshot?> read() async {
    if (!_restored) {
      final preferences = await _preferences();
      final stored = preferences.get(languageKey);
      final language = stored == 'hi' || stored == 'en'
          ? stored as String
          : _snapshot.languageCode;
      final seed = _snapshot;
      _snapshot = JourneySnapshot(
        languageCode: language,
        areaMode: seed.areaMode,
        setupComplete: seed.setupComplete,
        areaLabel: seed.areaLabel,
        currentAreaLabel: seed.currentAreaLabel,
        homeOrWorkAreaLabel: seed.homeOrWorkAreaLabel,
        profileDisplayName: seed.profileDisplayName,
        pendingRoute: seed.pendingRoute,
        pendingAuthenticationCancelRoute: seed.pendingAuthenticationCancelRoute,
        pendingAuthenticationPurpose: seed.pendingAuthenticationPurpose,
        lastReadyRoute: seed.lastReadyRoute,
        setupExperienceVersion: seed.setupExperienceVersion,
      );
      _restored = true;
    }
    return _snapshot;
  }

  @override
  Future<void> write(JourneySnapshot snapshot) async {
    if (snapshot.languageCode != 'en' && snapshot.languageCode != 'hi') {
      throw ArgumentError.value(snapshot.languageCode, 'languageCode');
    }
    final preferences = await _preferences();
    if (!await preferences.setString(languageKey, snapshot.languageCode)) {
      throw StateError('Review language preference could not be saved.');
    }
    _snapshot = snapshot;
    _restored = true;
  }
}
