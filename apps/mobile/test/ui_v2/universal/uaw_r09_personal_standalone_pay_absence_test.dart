import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/universal/mvp_action_choice_root_v2.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  test('Personal launcher has no standalone Pay and matches R09 contract', () {
    final contract =
        jsonDecode(
              File.fromUri(
                Directory.current.uri.resolve(
                  '../../config/mvp-personal-standalone-pay-absence-v1.json',
                ),
              ).readAsStringSync(),
            )
            as Map;
    final projection =
        jsonDecode(
              File.fromUri(
                Directory.current.uri.resolve(
                  '../../config/mvp-personal-action-projection-v1.json',
                ),
              ).readAsStringSync(),
            )
            as Map;

    final visibleMainActionIds = personalMoolRootActions
        .map((action) => action.id)
        .toList();
    expect(visibleMainActionIds, contract['visibleMainActions']);
    expect(
      personalMoolRootActions.map((action) => action.route),
      everyElement(isNot(startsWith('/app/pay'))),
    );

    final verticalRoutes = personalMvpActionChoiceRoots.values
        .expand((root) => root.actions)
        .map((action) => action.route);
    expect(verticalRoutes, everyElement(isNot(startsWith('/app/pay'))));

    final removedActions = (projection['removedActions'] as List).cast<Map>();
    final removedPay = removedActions.singleWhere(
      (action) => action['id'] == 'pay',
    );
    expect(removedPay['disposition'], 'removed_from_universal');
    expect(
      removedPay['recovery'],
      'open_transaction_owned_payment_or_truthful_unavailable',
    );
    expect(contract['implementationDisposition'], 'test_only_acceptance');
    expect(contract['newRuntimeOwners'], 0);
    expect(contract['newRouteOwners'], 0);
    expect(contract['newBackendOwners'], 0);
  });
}
