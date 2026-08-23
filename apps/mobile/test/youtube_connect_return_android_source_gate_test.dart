import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android YouTube return is isolated from the accepted app host', () {
    final mainActivity = File(
      'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
    ).readAsStringSync();
    final returnActivity = File(
      'android/app/src/main/kotlin/com/moolsocial/app/'
      'YouTubeConnectReturnActivity.kt',
    ).readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      mainActivity,
      isNot(contains('getInitialRoute')),
      reason: 'The accepted first-setup Android host must remain untouched.',
    );
    expect(returnActivity, contains('Intent.makeRestartActivityTask'));
    expect(
      returnActivity,
      contains('const val FLUTTER_INITIAL_ROUTE = "route"'),
    );
    expect(returnActivity, contains('putExtra(FLUTTER_INITIAL_ROUTE, route)'));
    expect(returnActivity, contains('data.queryParameterNames == setOf('));
    expect(returnActivity, contains('data.fragment == null'));
    expect(returnActivity, contains('result == "complete"'));
    expect(returnActivity, contains('result == "failed"'));
    expect(returnActivity, isNot(contains('code')));
    expect(returnActivity, isNot(contains('access_token')));
    expect(returnActivity, isNot(contains('refresh_token')));

    final mainStart = manifest.indexOf('android:name=".MainActivity"');
    final returnStart = manifest.indexOf(
      'android:name=".YouTubeConnectReturnActivity"',
    );
    expect(mainStart, greaterThanOrEqualTo(0));
    expect(returnStart, greaterThan(mainStart));
    final mainBlock = manifest.substring(mainStart, returnStart);
    final returnBlock = manifest.substring(returnStart);
    expect(mainBlock, isNot(contains('android:host="app"')));
    expect(
      mainBlock,
      isNot(contains('android:path="/creator/youtube-connect"')),
    );
    expect(returnBlock, contains('android:scheme="moolsocial"'));
    expect(returnBlock, contains('android:host="app"'));
    expect(returnBlock, contains('android:path="/creator/youtube-connect"'));
  });
}
