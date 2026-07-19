import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final cycle = Platform.environment['MOOL_REPLAY_CYCLE'] ?? 'device';
  await integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, Object?>? args,
        ]) async {
          final image = File(
            '../../artifacts/quality/shared/'
            'oppo-$cycle-$screenshotName.png',
          );
          image.parent.createSync(recursive: true);
          image.writeAsBytesSync(screenshotBytes);
          return true;
        },
    writeResponseOnFailure: true,
  );
}
