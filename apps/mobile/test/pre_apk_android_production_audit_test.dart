import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android pre-APK production owners remain explicit and private', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final ignore = File('android/.gitignore').readAsStringSync();
    final backupRules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(manifest, contains('android.hardware.camera'));
    expect(manifest, contains('android:required="false"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    expect(manifest, contains('com.facebook.sdk.ApplicationId'));
    expect(manifest, contains('com.facebook.sdk.ClientToken'));
    expect(manifest, contains('com.facebook.katana.provider.PlatformProvider'));
    expect(
      manifest,
      isNot(contains('android:name="com.facebook.FacebookActivity"')),
    );
    expect(
      manifest,
      isNot(contains('android:name="com.facebook.CustomTabActivity"')),
    );
    expect(manifest, contains('android:host="app"'));
    expect(manifest, contains('android:path="/creator/youtube-connect"'));
    expect(pubspec, contains('flutter_facebook_auth:'));

    expect(gradle, contains('sanitizeReleaseGeneratedPluginRegistrant'));
    expect(gradle, contains('FlutterFirebaseCorePlugin'));
    expect(gradle, contains('IntegrationTestPlugin'));
    expect(ignore, contains('GeneratedPluginRegistrant.java'));
    expect(
      ignore,
      isNot(
        contains(
          '!app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        ),
      ),
    );

    expect('<exclude '.allMatches(backupRules).length, 10);
    expect(backupRules, contains('<cloud-backup>'));
    expect(backupRules, contains('<device-transfer>'));
  });

  test('release lint normalizes Flutter-managed Windows properties', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('normalizeLocalPropertiesForLint'));
    expect(gradle, contains('rootProject.file("local.properties")'));
    expect(gradle, contains('key != "flutter.sdk" && key != "sdk.dir"'));
    expect(gradle, contains('it.name.startsWith("lint")'));
    expect(gradle, contains('it.name.contains("Release")'));
    expect(gradle, contains('dependsOn(normalizeLocalPropertiesForLint)'));
  });
}
