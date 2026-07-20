import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/review_journey_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'review email OTP writes the shared process-restart auth marker',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final gateway = SharedPreferencesReviewEmailOtpGateway(preferences);

      await gateway.requestCode('person@example.com');
      expect(await gateway.reviewCodeFor('person@example.com'), '123456');
      expect(await gateway.verifyCode('123456'), 'review-email-user');

      expect(
        preferences.getString(reviewAuthenticatedUserPreferenceKey),
        'review-email-user',
      );
    },
  );

  test('review email OTP rejects verification before a request', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final gateway = SharedPreferencesReviewEmailOtpGateway(preferences);

    await expectLater(gateway.verifyCode('123456'), throwsA(isA<Exception>()));
    expect(preferences.getString(reviewAuthenticatedUserPreferenceKey), isNull);
  });
}
