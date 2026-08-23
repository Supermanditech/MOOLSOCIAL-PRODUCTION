import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/platform/mool_system_ui_viewport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('C28E Android requests the mandatory edge-to-edge mode', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await configureMoolSystemUiViewport();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'SystemChrome.setEnabledSystemUIMode');
    expect(calls.single.arguments, 'SystemUiMode.edgeToEdge');
  });

  test(
    'C28E non-Android platforms keep their native viewport policy',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await configureMoolSystemUiViewport();

      expect(calls, isEmpty);
    },
  );
}
