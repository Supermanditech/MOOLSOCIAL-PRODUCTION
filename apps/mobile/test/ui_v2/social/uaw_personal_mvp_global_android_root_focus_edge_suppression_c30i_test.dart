import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C30I API 26 NormalTheme suppresses only the Android root fallback', () {
    final light = File(
      'android/app/src/main/res/values-v26/styles.xml',
    ).readAsStringSync();
    final dark = File(
      'android/app/src/main/res/values-night-v26/styles.xml',
    ).readAsStringSync();

    expect(
      light,
      contains(
        '<style name="NormalTheme" '
        'parent="@android:style/Theme.Light.NoTitleBar">',
      ),
    );
    expect(
      dark,
      contains(
        '<style name="NormalTheme" '
        'parent="@android:style/Theme.Black.NoTitleBar">',
      ),
    );

    for (final source in [light, dark]) {
      expect(source, isNot(contains('<style name="LaunchTheme"')));
      expect(
        RegExp(
          '<item name="android:defaultFocusHighlightEnabled">false</item>',
        ).allMatches(source),
        hasLength(1),
      );
      expect(
        RegExp(
          '<item name="android:windowBackground">@color/mool_navy</item>',
        ).allMatches(source),
        hasLength(1),
      );
    }
  });

  test('C30I preserves pre-26 and launch-theme resource contracts', () {
    final owners = <String, String>{
      'base': File(
        'android/app/src/main/res/values/styles.xml',
      ).readAsStringSync(),
      'base-night': File(
        'android/app/src/main/res/values-night/styles.xml',
      ).readAsStringSync(),
      'launch-v31': File(
        'android/app/src/main/res/values-v31/styles.xml',
      ).readAsStringSync(),
      'launch-night-v31': File(
        'android/app/src/main/res/values-night-v31/styles.xml',
      ).readAsStringSync(),
    };

    for (final entry in owners.entries) {
      expect(
        entry.value,
        isNot(contains('android:defaultFocusHighlightEnabled')),
        reason: entry.key,
      );
    }
    expect(owners['base'], contains('<style name="NormalTheme"'));
    expect(owners['base-night'], contains('<style name="NormalTheme"'));
    expect(owners['launch-v31'], contains('<style name="LaunchTheme"'));
    expect(owners['launch-night-v31'], contains('<style name="LaunchTheme"'));
  });
}
