import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  await integrationDriver(
    timeout: const Duration(minutes: 40),
    responseDataCallback: (data) => writeResponseData(
      data,
      testOutputFilename: 'youtube_private_dev_supervised_proof',
    ),
    writeResponseOnFailure: true,
  );
}
