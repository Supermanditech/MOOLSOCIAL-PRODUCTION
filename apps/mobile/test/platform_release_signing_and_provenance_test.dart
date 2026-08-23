import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release builds require founder-controlled upload signing', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
    expect(gradle, contains('MOOLSOCIAL_UPLOAD_STORE_FILE'));
    expect(gradle, contains('MOOLSOCIAL_UPLOAD_STORE_PASSWORD'));
    expect(gradle, contains('MOOLSOCIAL_UPLOAD_KEY_ALIAS'));
    expect(gradle, contains('MOOLSOCIAL_UPLOAD_KEY_PASSWORD'));
    expect(
      gradle,
      contains('releasePackagingTaskRequested && !uploadSigningConfigured'),
    );
    expect(
      gradle,
      contains('(assemble|bundle|package|install|validateSigning).*release.*'),
      reason: 'Read-only release dependency audits must not require secrets.',
    );
    expect(gradle, contains('signingConfigs.findByName("release")'));
  });
}
