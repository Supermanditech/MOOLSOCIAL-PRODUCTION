import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moolsocial/app/ui_review_language_store.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

const seed = JourneySnapshot(
  languageCode: 'en',
  areaMode: 'current',
  areaLabel: 'Jodhpur, Rajasthan',
  setupComplete: true,
  pendingRoute: '/app/buy',
  lastReadyRoute: '/app/buy',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'fresh review keeps seed and does not create authentication state',
    () async {
      final snapshot = await UiReviewLanguageStore(seed: seed).read();
      expect(snapshot!.languageCode, 'en');
      expect(snapshot.pendingRoute, '/app/buy');
      expect(snapshot.areaLabel, seed.areaLabel);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );

  test(
    'new store restores Hindi then subsequent English without other keys',
    () async {
      final first = UiReviewLanguageStore(seed: seed);
      await first.write(
        const JourneySnapshot(
          languageCode: 'hi',
          areaMode: 'manual',
          setupComplete: true,
          pendingRoute: '/app/other',
          areaLabel: 'temporary review area',
        ),
      );
      final second = UiReviewLanguageStore(seed: seed);
      final restored = await second.read();
      expect(restored!.languageCode, 'hi');
      expect(restored.pendingRoute, '/app/buy');
      expect(restored.areaLabel, seed.areaLabel);
      await second.write(seed);
      expect(
        (await UiReviewLanguageStore(seed: seed).read())!.languageCode,
        'en',
      );
      expect((await SharedPreferences.getInstance()).getKeys(), {
        UiReviewLanguageStore.languageKey,
      });
    },
  );

  test(
    'unrelated production preference and route keys remain untouched',
    () async {
      SharedPreferences.setMockInitialValues({
        'journey01.language': 'hi',
        'journey01.pending_route': '/app/orders',
        'journey01.review_authenticated_user': true,
      });
      final before = await SharedPreferences.getInstance();
      final values = {for (final key in before.getKeys()) key: before.get(key)};
      await UiReviewLanguageStore(seed: seed).write(seed);
      for (final entry in values.entries) {
        expect(before.get(entry.key), entry.value);
      }
    },
  );

  for (final invalid in <Object>['unknown', 42, true]) {
    test('invalid stored value $invalid safely retains seed', () async {
      SharedPreferences.setMockInitialValues({
        UiReviewLanguageStore.languageKey: invalid,
      });
      expect(
        (await UiReviewLanguageStore(seed: seed).read())!.languageCode,
        'en',
      );
    });
  }

  test(
    'failed save rolls session preference back with an honest error',
    () async {
      final session = JourneySession(
        store: UiReviewLanguageStore(
          seed: seed,
          preferences: () async {
            throw StateError('storage unavailable');
          },
        ),
        allowGuestReady: true,
      );
      addTearDown(session.dispose);
      expect(await session.updateLanguage('hi'), isFalse);
      expect(session.languageCode, 'en');
      expect(session.errorMessage, 'Language could not be saved. Try again.');
    },
  );

  test('new session restores saved language using the review store', () async {
    final first = JourneySession(
      store: UiReviewLanguageStore(seed: seed),
      allowGuestReady: true,
    );
    addTearDown(first.dispose);
    expect(await first.updateLanguage('hi'), isTrue);
    final second = JourneySession(
      store: UiReviewLanguageStore(seed: seed),
      allowGuestReady: true,
    );
    addTearDown(second.dispose);
    await second.start();
    expect(second.languageCode, 'hi');
  });
}

// negative fixture
