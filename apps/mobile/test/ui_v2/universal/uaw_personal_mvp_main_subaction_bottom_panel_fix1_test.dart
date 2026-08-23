import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejected bottom-panel candidate remains historically traceable', () {
    final contract =
        jsonDecode(
              File.fromUri(
                Directory.current.uri.resolve(
                  '../../config/mvp-personal-main-subaction-bottom-panel-fix1.json',
                ),
              ).readAsStringSync(),
            )
            as Map;
    expect(
      contract['ticketId'],
      'UAW-PERSONAL-MVP-MAIN-SUBACTION-BOTTOM-PANEL-FIX1',
    );
    expect(
      (contract['implementationOwners'] as Map)['panelPrimitive'],
      'showModalBottomSheet',
    );

    final rejection = File.fromUri(
      Directory.current.uri.resolve(
        '../../artifacts/quality/'
        'uaw-personal-mvp-main-subaction-bottom-panel-fix1-20260806-01/'
        '60-r60.6-device-rejection.md',
      ),
    );
    expect(rejection.existsSync(), isTrue);
    final evidence = rejection.readAsStringSync();
    expect(evidence, contains('INSTALLED_DEVICE_REJECTED_PRESERVED'));
    expect(evidence, contains('opened Social'));
    expect(evidence, contains('No second build or install was'));
    expect(evidence, contains('performed.'));
  });
}
