import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/config/email_link_runtime_configuration.dart';

void main() {
  test('runtime email-link domain and continue URL fail closed', () {
    for (final linkDomain in const [
      '',
      customMoolSocialEmailLinkDomain,
      'MOOLSOCIAL.COM',
    ]) {
      expect(
        isQualifiedEmailLinkRuntimeConfiguration(
          continueUrl: 'https://moolsocial.com/app/social',
          linkDomain: linkDomain,
        ),
        isTrue,
        reason: linkDomain,
      );
    }

    for (final rejected in const [
      ('http://moolsocial.com/app/social', ''),
      ('https://example.com/app/social', ''),
      ('https://moolsocial.com/sign-in', ''),
      ('https://user@moolsocial.com/app/social', ''),
      ('https://moolsocial.com:444/app/social', ''),
      ('https://moolsocial.com/app/social#email', ''),
      ('https://moolsocial.com/app/social', 'example.com'),
      ('https://moolsocial.com/app/social', 'https://moolsocial.com'),
      ('https://moolsocial.com/app/social', 'moolsocial.com/path'),
      ('https://moolsocial.com/app/social', defaultFirebaseEmailLinkDomain),
    ]) {
      expect(
        isQualifiedEmailLinkRuntimeConfiguration(
          continueUrl: rejected.$1,
          linkDomain: rejected.$2,
        ),
        isFalse,
        reason: rejected.toString(),
      );
    }
  });

  test('Android manifest catches exact Firebase email action links', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      _hasExactAppLinkFilter(
        manifest,
        host: defaultFirebaseEmailLinkDomain,
        pathPrefix: '/__/auth/links',
      ),
      isTrue,
    );
    expect(
      _hasExactAppLinkFilter(
        manifest,
        host: customMoolSocialEmailLinkDomain,
        pathPrefix: '/__/auth/links',
      ),
      isTrue,
    );
  });

  test('existing Social App Link and singleTop activity stay preserved', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:launchMode="singleTop"'));
    expect(
      _hasExactAppLinkFilter(
        manifest,
        host: customMoolSocialEmailLinkDomain,
        pathPrefix: '/app',
      ),
      isTrue,
    );
  });
}

bool _hasExactAppLinkFilter(
  String manifest, {
  required String host,
  required String pathPrefix,
}) {
  final filters = RegExp(
    r'<intent-filter android:autoVerify="true">[\s\S]*?</intent-filter>',
  ).allMatches(manifest);
  return filters.any((match) {
    final filter = match.group(0)!;
    return filter.contains('android:scheme="https"') &&
        filter.contains('android:host="$host"') &&
        filter.contains('android:pathPrefix="$pathPrefix"');
  });
}
