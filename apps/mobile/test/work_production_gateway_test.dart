import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/scan_and_pick_contract.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_workspace_benefits.dart';
import 'package:moolsocial/features/work/work_document_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('r6614 workspace contact mobile format', () {
    WorkSession contacts(ReviewWorkGateway gateway) =>
        WorkSession(gateway: gateway)
          ..selectFamily('products-trade')
          ..selectProfile('retailer-grocery')
          ..primaryMobile = '9000000012'
          ..primaryMobileVerified = true
          ..contactEmail = 'qa@example.test'
          ..contactEmailVerified = true;

    for (final channel in [
      WorkContactChannel.primaryMobile,
      WorkContactChannel.alternateMobile,
    ]) {
      Future<bool> send(WorkSession work, String value) =>
          channel == WorkContactChannel.primaryMobile
          ? work.sendPrimaryMobileOtp(value)
          : work.sendAlternateOtp(value);
      final instruction = channel == WorkContactChannel.primaryMobile
          ? 'Enter a valid 10-digit phone number.'
          : 'Enter a valid 10-digit alternate mobile number.';

      for (final invalid in [
        '1111111111',
        '1213131313',
        '5000000013',
        '900000013',
        '90000000013',
        '9000000013abc',
        '90000/00013',
        '+449000000013',
      ]) {
        test(
          '$channel rejects $invalid before sending or continuing',
          () async {
            final gateway = ReviewWorkGateway();
            final work = contacts(gateway);
            addTearDown(work.dispose);
            work.editWorkspaceContact(channel, invalid);
            final retained = work.workspaceContactValue(channel);
            expect(await send(work, invalid), isFalse);
            expect(work.errorMessage, instruction);
            expect(work.workspaceContactValue(channel), retained);
            expect(work.workspaceContactVerified(channel), isFalse);
            expect(work.workspaceContactsReady, isFalse);
            expect(work.continueToProof(), isFalse);
            expect(work.errorMessage, instruction);
            expect(gateway.otpCalls, 0);
            expect(gateway.otpVerificationCalls, 0);
            expect(work.contactEmailVerified, isTrue);
            if (channel == WorkContactChannel.alternateMobile) {
              expect(work.primaryMobileVerified, isTrue);
            }
          },
        );
      }

      test('$channel correction still requires its own server code', () async {
        final gateway = ReviewWorkGateway();
        final work = contacts(gateway);
        addTearDown(work.dispose);
        work.editWorkspaceContact(channel, '1111111111');
        expect(await send(work, '1111111111'), isFalse);
        expect(await send(work, '+91 90000-00013'), isTrue);
        expect(work.workspaceContactValue(channel), '9000000013');
        expect(work.workspaceContactVerified(channel), isFalse);
        expect(work.workspaceContactsReady, isFalse);
        expect(gateway.otpCalls, 1);
        Future<bool> verify(String code) =>
            channel == WorkContactChannel.primaryMobile
            ? work.verifyPrimaryMobileOtp(code)
            : work.verifyAlternateOtp(code);
        expect(await verify('000000'), isFalse);
        expect(work.workspaceContactVerified(channel), isFalse);
        expect(await verify('123456'), isTrue);
        expect(gateway.otpVerificationCalls, 2);
        expect(work.workspaceContactsReady, isTrue);
        expect(work.continueToProof(), isTrue);
      });
    }

    test('formatted primary cannot be reused as the alternate', () async {
      final gateway = ReviewWorkGateway();
      final work = contacts(gateway)..primaryMobile = '+91 90000-00012';
      addTearDown(work.dispose);
      expect(await work.sendAlternateOtp('9000000012'), isFalse);
      expect(
        work.errorMessage,
        'This is already the number customers can reach you on.',
      );
      expect(gateway.otpCalls, 0);
    });

    test('saved confirmation flags cannot make malformed contacts ready', () {
      final work = contacts(ReviewWorkGateway());
      addTearDown(work.dispose);
      work.primaryMobile = '1111111111';
      expect(work.workspaceContactsReady, isFalse);
      expect(work.continueToProof(), isFalse);
      work.primaryMobile = '9000000012';
      work.alternateMobile = '1213131313';
      work.alternateVerified = true;
      expect(work.workspaceContactsReady, isFalse);
      expect(work.continueToProof(), isFalse);
      work.removeAlternateMobile();
      expect(work.workspaceContactsReady, isTrue);
      work.contactEmail = 'not-an-email';
      expect(work.workspaceContactsReady, isFalse);
      expect(work.continueToProof(), isFalse);
      expect(work.errorMessage, 'Enter a valid email address.');
    });
  });
  group('r66.8 local PDF preview', () {
    const channel = MethodChannel('com.moolsocial.app/work_document_preview');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4\nQA fixture'));
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a7WQAAAAASUVORK5CYII=',
    );
    Map<String, Object?> page(int index) => {
      'bytes': png,
      'page': index,
      'pages': 2,
      'width': 1,
      'height': 1,
    };
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('renders only the requested page and bounded local bytes', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return page((call.arguments as Map)['page'] as int);
      });
      final preview = WorkPdfPreview();
      addTearDown(preview.dispose);
      for (final index in [0, 1, 0]) {
        final result = await preview.render(pdfBytes, page: index);
        expect(result.index, index);
        expect(result.pageCount, 2);
        expect(result.bytes, png);
        expect(result.width * result.height, 1);
      }
      expect(calls, hasLength(3));
      final ids = <String>{};
      for (final call in calls) {
        expect(call.method, 'renderPage');
        final args = call.arguments as Map;
        expect(
          args.keys,
          unorderedEquals(['bytes', 'page', 'width', 'requestId']),
        );
        expect(args['bytes'], pdfBytes);
        expect(args['width'], 1280);
        ids.add(args['requestId'] as String);
      }
      expect(ids, hasLength(3));
    });

    test(
      'invalid document and page bounds never enter native renderer',
      () async {
        var calls = 0;
        messenger.setMockMethodCallHandler(channel, (_) async {
          calls++;
          return page(0);
        });
        final preview = WorkPdfPreview();
        addTearDown(preview.dispose);
        for (final bytes in [
          Uint8List(0),
          Uint8List(10 * 1024 * 1024 + 1),
          Uint8List.fromList([1, 2, 3, 4, 5]),
        ]) {
          await expectLater(
            preview.render(bytes, page: 0),
            throwsA(isA<WorkPdfPreviewException>()),
          );
        }
        for (final index in [-1, 500]) {
          await expectLater(
            preview.render(pdfBytes, page: index),
            throwsA(isA<WorkPdfPreviewException>()),
          );
        }
        expect(calls, 0);
      },
    );

    test(
      'rejects wrong page, count, dimensions and malformed PNG responses',
      () async {
        for (final change in <Map<String, Object?>>[
          {'page': 1},
          {'pages': 0},
          {'pages': 501},
          {'width': 1281},
          {'height': 2049},
          {'width': 2},
          {'bytes': Uint8List(24)},
          {'bytes': Uint8List.fromList(png.take(8).toList())},
        ]) {
          messenger.setMockMethodCallHandler(
            channel,
            (_) async => {...page(0), ...change},
          );
          final preview = WorkPdfPreview();
          await expectLater(
            preview.render(pdfBytes, page: 0),
            throwsA(isA<WorkPdfPreviewException>()),
          );
          preview.dispose();
        }
      },
    );

    for (final code in ['protected_pdf', 'invalid_pdf', 'preview_timeout']) {
      test(
        '$code is recoverable and does not expose platform details',
        () async {
          var fail = true;
          messenger.setMockMethodCallHandler(channel, (_) async {
            if (fail) {
              throw PlatformException(
                code: code,
                message: 'private/path/secret',
              );
            }
            return page(0);
          });
          final preview = WorkPdfPreview();
          addTearDown(preview.dispose);
          await expectLater(
            preview.render(pdfBytes, page: 0),
            throwsA(
              isA<WorkPdfPreviewException>().having(
                (e) => e.message,
                'safe copy',
                isNot(contains('private')),
              ),
            ),
          );
          fail = false;
          expect((await preview.render(pdfBytes, page: 0)).index, 0);
        },
      );
    }

    test('missing renderer is honest and replace remains possible', () async {
      final preview = WorkPdfPreview();
      addTearDown(preview.dispose);
      await expectLater(
        preview.render(pdfBytes, page: 0),
        throwsA(
          isA<WorkPdfPreviewException>().having(
            (e) => e.message,
            'copy',
            contains('unavailable on this device'),
          ),
        ),
      );
    });

    test(
      'malformed native envelope becomes a safe recoverable error',
      () async {
        messenger.setMockMethodCallHandler(channel, (_) async => 'not-a-page');
        final preview = WorkPdfPreview();
        addTearDown(preview.dispose);
        await expectLater(
          preview.render(pdfBytes, page: 0),
          throwsA(isA<WorkPdfPreviewException>()),
        );
        messenger.setMockMethodCallHandler(channel, (_) async => page(0));
        expect((await preview.render(pdfBytes, page: 0)).index, 0);
      },
    );

    test(
      'duplicate render is blocked and disposal cancels exact late request',
      () async {
        final response = Completer<Map<String, Object?>>();
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'cancel' ? null : response.future;
        });
        final preview = WorkPdfPreview();
        final pending = preview.render(pdfBytes, page: 0);
        final rejected = expectLater(
          pending,
          throwsA(isA<WorkPdfPreviewException>()),
        );
        await Future<void>.delayed(Duration.zero);
        await expectLater(
          preview.render(pdfBytes, page: 1),
          throwsA(isA<WorkPdfPreviewException>()),
        );
        preview.dispose();
        await Future<void>.delayed(Duration.zero);
        response.complete(page(0));
        await rejected;
        expect(calls.map((c) => c.method), ['renderPage', 'cancel']);
        expect(
          (calls[0].arguments as Map)['requestId'],
          (calls[1].arguments as Map)['requestId'],
        );
        await expectLater(
          preview.render(pdfBytes, page: 0),
          throwsA(isA<WorkPdfPreviewException>()),
        );
        expect(calls, hasLength(2));
      },
    );
  });
  group('ScanPick v1 contract', () {
    test('published request and result examples use the same v1 boundary', () {
      final document = File(
        'lib/features/work/SCAN-AND-PICK-CONTRACT-V1.md',
      ).readAsStringSync();
      final blocks = RegExp(r'```json\s*([\s\S]*?)```')
          .allMatches(document)
          .map((match) => jsonDecode(match.group(1)!))
          .toList();
      expect(blocks, hasLength(3));
      final requests = blocks[0] as List;
      expect(
        requests.map((r) => (r as Map)['operation']),
        ScanPickOperation.values.map((operation) => operation.name),
      );
      for (final request in requests.cast<Map>()) {
        expect(request['protocolVersion'], scanPickProtocolVersion);
        expect(request['purpose'], scanPickPurpose);
      }
      final issued = ScanPickResult.fromJson(blocks[1] as Map<String, Object?>);
      issued.validateFor(
        ScanPickRequest.issueChallenge(
          requestId: 'issue-1',
          operationId: 'op-issue',
          orderId: 'order-1',
          storeId: 'store-1',
          expectedRevision: 'revision-1',
        ),
        client: ScanPickClient.retailer,
      );
      expect(issued.snapshot!.challenge!.qrPayload, 'opaque-example-token');
      final errors = (blocks[2] as List)
          .map(
            (value) => ScanPickResult.fromJson(value as Map<String, Object?>),
          )
          .toList();
      expect(errors[0].outcome, ScanPickOutcome.unknown);
      expect(errors[1].error, ScanPickError.challengeExpired);
    });

    Map<String, Object?> wire({String state = 'matched'}) => {
      'protocolVersion': 1,
      'operation': 'read',
      'requestId': 'read-1',
      'outcome': 'snapshot',
      'snapshot': <String, Object?>{
        'purpose': 'customerCollection',
        'orderId': 'order-1',
        'storeId': 'store-1',
        'purchaserAccountId': 'customer-1',
        'customerName': 'Test customer',
        'storeName': 'Test store',
        'revision': 'revision-3',
        'serverTime': '2026-09-07T10:00:00Z',
        'state': state,
        'payment': 'paid',
        'readiness': 'ready',
        'currency': 'INR',
        'totalMinor': 100000000000000,
        'lines': [
          <String, Object?>{
            'lineId': 'line-1',
            'productId': 'product-1',
            'skuId': 'rice-5kg-sku-1',
            'name': 'Purchased rice',
            'pack': '5 kg bag',
            'quantity': '2',
            'amountMinor': 100000000000000,
          },
        ],
        if (state == 'awaitingCustomer')
          'challenge': <String, Object?>{
            'id': 'challenge-1',
            'expiresAt': '2026-09-07T10:01:00Z',
          },
        if (state == 'matched')
          'approval': <String, Object?>{
            'id': 'approval-1',
            'expiresAt': '2026-09-07T10:01:00Z',
          },
        if (state == 'collected')
          'receipt': <String, Object?>{
            'id': 'receipt-1',
            'collectedAt': '2026-09-07T09:59:55Z',
            'invoiceReference': 'invoice-1',
          },
      },
    };

    Map<String, Object?> snapshot(Map<String, Object?> value) =>
        value['snapshot']! as Map<String, Object?>;

    ScanPickRequest read({String requestId = 'read-1'}) => ScanPickRequest.read(
      requestId: requestId,
      orderId: 'order-1',
      storeId: 'store-1',
    );

    test(
      'five operation payloads exclude client authority and verbal codes',
      () {
        final requests = [
          read(),
          ScanPickRequest.issueChallenge(
            requestId: 'issue-1',
            operationId: 'op-issue',
            orderId: 'order-1',
            storeId: 'store-1',
            expectedRevision: 'revision-1',
          ),
          ScanPickRequest.authorise(
            requestId: 'scan-1',
            operationId: 'op-scan',
            orderId: 'order-1',
            storeId: 'store-1',
            expectedRevision: 'revision-2',
            qrPayload: 'opaque-test-only-token',
          ),
          ScanPickRequest.handOver(
            requestId: 'hand-1',
            operationId: 'op-hand',
            orderId: 'order-1',
            storeId: 'store-1',
            expectedRevision: 'revision-3',
            approvalId: 'approval-1',
          ),
          ScanPickRequest.reconcile(
            requestId: 'reconcile-1',
            operationId: 'op-hand',
            orderId: 'order-1',
            storeId: 'store-1',
          ),
        ];
        expect(
          requests.map((r) => r.operation).toSet(),
          ScanPickOperation.values.toSet(),
        );
        for (final request in requests) {
          final json = request.toJson();
          expect(json['protocolVersion'], 1);
          expect(json['purpose'], 'customerCollection');
          expect(json['orderId'], 'order-1');
          expect(json['storeId'], 'store-1');
          for (final forbidden in [
            'approved',
            'matched',
            'paid',
            'ready',
            'otp',
            'verbalCode',
            'purchaserAccountId',
            'merchantCredentials',
          ]) {
            expect(json.containsKey(forbidden), isFalse, reason: forbidden);
          }
        }
        expect(requests[2].toJson()['qrPayload'], 'opaque-test-only-token');
        expect(requests[3].toJson().containsKey('qrPayload'), isFalse);
        expect(requests[4].operationId, requests[3].operationId);
        expect(requests[4].requestId, isNot(requests[3].requestId));
      },
    );

    test('missing identity and authority references fail before transport', () {
      expect(() => read(requestId: ' '), throwsFormatException);
      expect(
        () => ScanPickRequest.handOver(
          requestId: 'r',
          operationId: '',
          orderId: 'o',
          storeId: 's',
          expectedRevision: 'v',
          approvalId: 'a',
        ),
        throwsFormatException,
      );
      expect(
        () => ScanPickRequest.handOver(
          requestId: 'r',
          operationId: 'op',
          orderId: 'o',
          storeId: 's',
          expectedRevision: '',
          approvalId: 'a',
        ),
        throwsFormatException,
      );
      expect(
        () => ScanPickRequest.authorise(
          requestId: 'r',
          operationId: 'op',
          orderId: 'o',
          storeId: 's',
          expectedRevision: 'v',
          qrPayload: '',
        ),
        throwsFormatException,
      );
    });

    test(
      'matched is not completed; exact amount and purchased lines survive',
      () {
        final result = ScanPickResult.fromJson(wire());
        result.validateFor(
          read(),
          client: ScanPickClient.consumer,
          purchaserAccountId: 'customer-1',
        );
        final value = result.snapshot!;
        expect(value.totalMinor, 100000000000000);
        expect(value.lines.single.skuId, 'rice-5kg-sku-1');
        expect(value.lines.single.pack, '5 kg bag');
        expect(value.lines.single.quantity, '2');
        expect(value.receipt, isNull);
        expect(() => value.lines.clear(), throwsUnsupportedError);
        expect(
          result.canRequestHandOver(
            read(),
            DateTime.parse('2026-09-07T10:00:30Z'),
          ),
          isTrue,
        );
        expect(
          result.canRequestHandOver(
            read(),
            DateTime.parse('2026-09-07T10:01:00Z'),
          ),
          isFalse,
        );
        expect(
          result.canRequestHandOver(
            read(),
            DateTime.parse('2026-09-07T09:59:59Z'),
          ),
          isFalse,
        );
      },
    );

    for (final state in ScanPickState.values.where(
      (s) => s != ScanPickState.matched,
    )) {
      test('${state.name} cannot enable Hand Over', () {
        final result = ScanPickResult.fromJson(wire(state: state.name));
        expect(
          result.canRequestHandOver(
            read(),
            DateTime.parse('2026-09-07T10:00:30Z'),
          ),
          isFalse,
        );
      });
    }

    for (final field in [
      'purpose',
      'payment',
      'readiness',
      'state',
      'approval',
      'lines',
      'totalMinor',
      'serverTime',
    ]) {
      test('invalid $field fails closed', () {
        final json = wire();
        snapshot(json)[field] = switch (field) {
          'purpose' => 'bikerDelivery',
          'payment' => 'unpaid',
          'readiness' => 'preparing',
          'state' => 'future-state',
          'approval' => null,
          'lines' => <Object?>[],
          'totalMinor' => 1.5,
          'serverTime' => '2026-09-07T10:00:00',
          _ => null,
        };
        expect(() => ScanPickResult.fromJson(json), throwsFormatException);
      });
    }

    test('unknown version, error and false-success envelope are rejected', () {
      final future = wire()..['protocolVersion'] = 2;
      expect(() => ScanPickResult.fromJson(future), throwsFormatException);
      final failure = wire()
        ..['outcome'] = 'rejected'
        ..['error'] = 'futureError';
      expect(() => ScanPickResult.fromJson(failure), throwsFormatException);
      final empty = wire()..remove('snapshot');
      expect(() => ScanPickResult.fromJson(empty), throwsFormatException);
      final falseReceipt = wire();
      snapshot(falseReceipt)['receipt'] = {
        'id': 'r',
        'collectedAt': '2026-09-07T10:00:00Z',
      };
      expect(
        () => ScanPickResult.fromJson(falseReceipt),
        throwsFormatException,
      );
    });

    for (final key in ['orderId', 'storeId', 'purchaserAccountId']) {
      test('wrong $key reply cannot replace selected consumer order', () {
        final json = wire();
        snapshot(json)[key] = 'different';
        final result = ScanPickResult.fromJson(json);
        expect(
          () => result.validateFor(
            read(),
            client: ScanPickClient.consumer,
            purchaserAccountId: 'customer-1',
          ),
          throwsFormatException,
        );
      });
    }

    test(
      'old attempt, accountless consumer and merchant authorisation rejected',
      () {
        final result = ScanPickResult.fromJson(wire());
        expect(
          () => result.validateFor(
            read(requestId: 'read-2'),
            client: ScanPickClient.retailer,
          ),
          throwsFormatException,
        );
        expect(
          () => result.validateFor(read(), client: ScanPickClient.consumer),
          throwsFormatException,
        );
        final request = ScanPickRequest.authorise(
          requestId: 'a',
          operationId: 'op-a',
          orderId: 'order-1',
          storeId: 'store-1',
          expectedRevision: 'v',
          qrPayload: 'opaque-test-token',
        );
        final json = wire()
          ..['operation'] = 'authorise'
          ..['operationId'] = 'op-a'
          ..['requestId'] = 'a';
        expect(
          () => ScanPickResult.fromJson(
            json,
          ).validateFor(request, client: ScanPickClient.retailer),
          throwsFormatException,
        );
      },
    );

    test('consumer status never exposes retailer QR security payload', () {
      final json = wire(state: 'awaitingCustomer');
      (snapshot(json)['challenge']! as Map<String, Object?>)['qrPayload'] =
          'opaque-test-token';
      final result = ScanPickResult.fromJson(json);
      result.validateFor(read(), client: ScanPickClient.retailer);
      expect(
        () => result.validateFor(
          read(),
          client: ScanPickClient.consumer,
          purchaserAccountId: 'customer-1',
        ),
        throwsFormatException,
      );
      (snapshot(json)['challenge']! as Map<String, Object?>).remove(
        'qrPayload',
      );
      ScanPickResult.fromJson(json).validateFor(
        read(),
        client: ScanPickClient.consumer,
        purchaserAccountId: 'customer-1',
      );
    });

    for (final code in ScanPickError.values) {
      test('explicit ${code.name} rejection is not local success', () {
        final json = wire(state: 'collected')
          ..['outcome'] = 'rejected'
          ..['error'] = code.name;
        if (code != ScanPickError.alreadyCollected) json.remove('snapshot');
        final result = ScanPickResult.fromJson(json);
        expect(result.outcome, ScanPickOutcome.rejected);
        expect(result.error, code);
        expect(
          result.canRequestHandOver(
            read(),
            DateTime.parse('2026-09-07T10:00:30Z'),
          ),
          isFalse,
        );
      });
    }

    test(
      'uncertain mutation correlates reconciliation without new success',
      () {
        final request = ScanPickRequest.reconcile(
          requestId: 'reconcile-1',
          operationId: 'op-hand',
          orderId: 'order-1',
          storeId: 'store-1',
        );
        final result = ScanPickResult.fromJson({
          'protocolVersion': 1,
          'operation': 'reconcile',
          'requestId': 'reconcile-1',
          'operationId': 'op-hand',
          'outcome': 'unknown',
        });
        result.validateFor(request, client: ScanPickClient.retailer);
        expect(result.snapshot, isNull);
        expect(result.outcome, ScanPickOutcome.unknown);
        final different = ScanPickRequest.reconcile(
          requestId: 'reconcile-1',
          operationId: 'different-op',
          orderId: 'order-1',
          storeId: 'store-1',
        );
        expect(
          () => result.validateFor(different, client: ScanPickClient.retailer),
          throwsFormatException,
        );
      },
    );

    test(
      'terminal receipt survives later refund without enabling second handover',
      () {
        final json = wire(state: 'collected');
        snapshot(json)['payment'] = 'refunded';
        final result = ScanPickResult.fromJson(json);
        expect(result.snapshot!.receipt!.id, 'receipt-1');
        expect(result.snapshot!.receipt!.invoiceReference, 'invoice-1');
        expect(
          result.canRequestHandOver(
            read(),
            DateTime.parse('2026-09-07T10:00:30Z'),
          ),
          isFalse,
        );
      },
    );

    test(
      'purchased SKU is required independently of generic product identity',
      () {
        final json = wire();
        final line =
            (snapshot(json)['lines']! as List).single as Map<String, Object?>;
        line.remove('skuId');
        expect(() => ScanPickResult.fromJson(json), throwsFormatException);
        line['skuId'] = ' ';
        expect(() => ScanPickResult.fromJson(json), throwsFormatException);
        line['skuId'] = 'rice-10kg-sku-2';
        line['pack'] = '10 kg bag';
        final value = ScanPickResult.fromJson(json).snapshot!.lines.single;
        expect(value.productId, 'product-1');
        expect(value.skuId, 'rice-10kg-sku-2');
        expect(value.pack, '10 kg bag');
      },
    );

    test('rejected Matched recovery never enables Hand Over', () {
      final json = wire()
        ..['outcome'] = 'rejected'
        ..['error'] = 'revisionConflict';
      final result = ScanPickResult.fromJson(json);
      expect(result.snapshot!.state, ScanPickState.matched);
      expect(
        result.canRequestHandOver(
          read(),
          DateTime.parse('2026-09-07T10:00:30Z'),
        ),
        isFalse,
      );
      final success = ScanPickResult.fromJson(wire());
      expect(
        () => success.canRequestHandOver(
          read(requestId: 'read-2'),
          DateTime.parse('2026-09-07T10:00:30Z'),
        ),
        throwsFormatException,
      );
    });

    test('QR transport bound measures bytes without truncating payload', () {
      ScanPickRequest authorise(String token) => ScanPickRequest.authorise(
        requestId: 'scan-1',
        operationId: 'op-scan',
        orderId: 'order-1',
        storeId: 'store-1',
        expectedRevision: 'v',
        qrPayload: token,
      );
      final exact = 'a' * scanPickMaxQrPayloadBytes;
      expect(authorise(exact).qrPayload, exact);
      expect(() => authorise('${exact}a'), throwsFormatException);
      final multibyte = 'é' * (scanPickMaxQrPayloadBytes ~/ 2);
      expect(authorise(multibyte).qrPayload, multibyte);
      expect(() => authorise('$multibyteé'), throwsFormatException);
      final json = wire(state: 'awaitingCustomer');
      final challenge = snapshot(json)['challenge']! as Map<String, Object?>;
      challenge['qrPayload'] = exact;
      expect(
        ScanPickResult.fromJson(json).snapshot!.challenge!.qrPayload,
        exact,
      );
      challenge['qrPayload'] = '${exact}a';
      expect(() => ScanPickResult.fromJson(json), throwsFormatException);
    });

    for (final time in [
      '2026-02-30T10:00:00Z',
      '2026-13-07T10:00:00Z',
      '2026-09-07T24:00:00Z',
      '2026-09-07T10:60:00Z',
      '2026-09-07T10:00:60Z',
      '2026-09-07T10:00:00+00:00',
      '20260907T100000Z',
      '2026-09-07T10:00:00.1234567Z',
    ]) {
      test('malformed or normalized UTC is rejected: $time', () {
        for (final field in ['serverTime', 'expiresAt', 'collectedAt']) {
          final json = wire(
            state: field == 'collectedAt' ? 'collected' : 'matched',
          );
          if (field == 'serverTime') {
            snapshot(json)[field] = time;
          } else {
            (snapshot(json)[field == 'expiresAt' ? 'approval' : 'receipt']!
                    as Map<String, Object?>)[field] =
                time;
          }
          expect(
            () => ScanPickResult.fromJson(json),
            throwsFormatException,
            reason: field,
          );
        }
      });
    }

    test(
      'paid collection order has no booking-age or delivery-target cutoff',
      () {
        final json = wire(state: 'ready');
        snapshot(json)['serverTime'] = '2027-02-28T10:00:00.123456Z';
        // Older purchase metadata is not an authority or a client expiry rule.
        snapshot(json)['orderedAt'] = '2026-09-07T10:00:00Z';
        final value = ScanPickResult.fromJson(json).snapshot!;
        expect(value.state, ScanPickState.ready);
        expect(value.payment, ScanPickPayment.paid);
        expect(value.serverTime.microsecond, 456);
        final expiredCode = wire(state: 'awaitingCustomer');
        snapshot(expiredCode)['serverTime'] = '2026-09-08T10:00:00Z';
        final waiting = ScanPickResult.fromJson(expiredCode).snapshot!;
        expect(
          waiting.challenge!.expiresAt.isBefore(waiting.serverTime),
          isTrue,
        );
        expect(waiting.state, ScanPickState.awaitingCustomer);
        expect(waiting.payment, ScanPickPayment.paid);
        expect(waiting.receipt, isNull);
        // Expired code is refreshable; it cannot imply cancellation or collection.
      },
    );

    test(
      'exact fractional quantity allowed; zero, duplicate line and oversized amount rejected',
      () {
        final json = wire();
        final lines = snapshot(json)['lines']! as List;
        final line = lines.single as Map<String, Object?>;
        line['quantity'] = '1.25';
        expect(
          ScanPickResult.fromJson(json).snapshot!.lines.single.quantity,
          '1.25',
        );
        line['quantity'] = '0.00';
        expect(() => ScanPickResult.fromJson(json), throwsFormatException);
        line['quantity'] = '2';
        lines.add(Map<String, Object?>.from(line));
        expect(() => ScanPickResult.fromJson(json), throwsFormatException);
        lines.removeLast();
        snapshot(json)['totalMinor'] = 9007199254740992;
        expect(() => ScanPickResult.fromJson(json), throwsFormatException);
      },
    );
  });

  test('S09 setup draft cannot create or mutate a catalogue listing', () {
    final work = WorkSession();
    addTearDown(work.dispose);
    work.saveRetailerProduct(quantity: 10, buyPrice: 40, sellPrice: 50);
    expect(work.workspaceCatalogueItems, isEmpty);
    expect(work.retailerProductAdded, isFalse);
    work.addRetailerProduct();
    final product = work.workspaceCatalogueItems.single;
    expect(product.publicListing, isFalse);
    work.saveRetailerProduct(
      quantity: 20,
      buyPrice: 45,
      sellPrice: 60,
      updateCatalogue: false,
    );
    expect(work.workspaceCatalogueItems.single, same(product));
    expect(work.retailerQuantity, 20);
    expect(work.retailerBuyPrice, 45);
    expect(work.retailerSellPrice, 60);
    work.saveRetailerProduct(quantity: 20, buyPrice: 45, sellPrice: 60);
    expect(work.workspaceCatalogueItems.single.stock, 20);
    expect(work.workspaceCatalogueItems.single.sellingPrice, 60);
    expect(work.workspaceCatalogueItems.single.publicListing, isFalse);
  });

  for (final publish in [false, true]) {
    test(
      'S09 setup publication requires explicit choice and successful save $publish',
      () async {
        final gateway = ReviewWorkGateway()..failSetup = true;
        final work = WorkSession(gateway: gateway)
          ..selectProfile('retailer-grocery')
          ..reviewCaseId = 'case-store';
        addTearDown(work.dispose);
        expect(await work.checkReview(), isTrue);
        work.addRetailerProduct();
        work.saveRetailerProduct(quantity: 10, buyPrice: 40, sellPrice: 50);
        work.setRetailerFulfilment(homeDelivery: true, storeCollection: false);
        work.setRetailerPublishAfterSetup(publish);
        expect(await work.finishRetailerSetup(), isFalse);
        expect(work.workspaceCatalogueItems.single.publicListing, isFalse);
        expect(work.workspaceVisibleToCustomers, isFalse);
        expect(await work.finishRetailerSetup(), isTrue);
        expect(work.workspaceCatalogueItems.single.publicListing, publish);
        expect(work.workspaceVisibleToCustomers, publish);
        expect(work.workspaceAcceptingOrders, publish);
      },
    );
  }

  WorkSession application({
    WorkGateway? gateway,
    WorkPendingProofStore? store,
  }) => WorkSession(gateway: gateway, contactDraftStore: store)
    ..selectProfile('retailer-grocery')
    ..workName = 'Sharma Stores'
    ..workArea = 'Jaipur'
    ..primaryActivity = 'Groceries'
    ..authorizedPersonName = 'Asha Sharma'
    ..businessRelationship = 'Owner'
    ..primaryMobile = '9829012321'
    ..contactEmail = 'asha@example.com'
    ..primaryMobileVerified = true
    ..contactEmailVerified = true
    ..declarationAccepted = true;

  Future<String> addWorkspaceApplication(
    WorkSession work,
    String name, {
    String profile = 'retailer-grocery',
  }) async {
    expect(work.startAnotherWork(), isTrue);
    work.selectProfile(profile);
    work.saveDetails(name: name, area: '302001', activity: 'Retail trade');
    work.authorizedPersonName = 'Asha Sharma';
    work.businessRelationship = 'Owner';
    work.primaryMobile = '9829012321';
    work.contactEmail = 'asha@example.com';
    work.primaryMobileVerified = work.contactEmailVerified = true;
    expect(await work.addProof('personal-kyc', WorkProofSource.upload), isTrue);
    work.declarationAccepted = true;
    expect(await work.submitProfile(), isTrue);
    return work.savedWorkspaceApplications
        .singleWhere((entry) => entry.name == name)
        .id;
  }

  const existingStore = WorkWorkspace(
    id: 'existing-store',
    name: 'Existing Kirana',
    profileId: 'retailer-grocery',
    profileLabel: 'Grocery / Kirana Shop',
    area: '302001',
    verified: true,
  );

  for (final profile in ['retailer-grocery', 'retailer-speciality', 'salon']) {
    test(
      'R669 separate applications retain exact business and documents $profile',
      () async {
        final gateway = ReviewWorkGateway(
          initialReviewStatus: WorkRemoteReviewStatus.pending,
        );
        final work = WorkSession(gateway: gateway)
          ..activeWorkspace = existingStore;
        addTearDown(work.dispose);
        work.workspaceSettlementBalance = 98765;
        final first = await addWorkspaceApplication(work, 'First shop');
        final firstCase = work.reviewCaseId;
        final firstSubmission = work.submittedProfile;
        final firstProof = work.addedProofs['personal-kyc'];
        final firstFile = work.pickedProofs['personal-kyc'];
        expect(work.startAnotherWork(), isTrue);
        expect(work.addedProofs, isEmpty);
        expect(work.pickedProofs, isEmpty);
        expect(work.submittedProfile, isNull);
        expect(work.reviewCaseId, isNull);
        final second = await addWorkspaceApplication(
          work,
          'Second business',
          profile: profile,
        );
        final secondCase = work.reviewCaseId;
        final secondProof = work.addedProofs['personal-kyc'];
        expect(second, isNot(first));
        expect(work.savedWorkspaceApplications, hasLength(2));
        expect(work.resumeWorkspaceApplication(first), isTrue);
        expect(work.workName, 'First shop');
        expect(work.selectedProfile?.id, 'retailer-grocery');
        expect(work.reviewCaseId, firstCase);
        expect(work.submittedProfile, same(firstSubmission));
        expect(work.addedProofs['personal-kyc'], firstProof);
        expect(work.pickedProofs['personal-kyc'], same(firstFile));
        expect(work.resumeWorkspaceApplication(second), isTrue);
        expect(work.workName, 'Second business');
        expect(work.selectedProfile?.id, profile);
        expect(work.reviewCaseId, secondCase);
        expect(work.addedProofs['personal-kyc'], secondProof);
        expect(work.activeWorkspace, same(existingStore));
        expect(work.workspaceSettlementBalance, 98765);
        expect(gateway.submissionCalls, 2);
      },
    );
  }

  for (final status in [
    WorkRemoteReviewStatus.pending,
    WorkRemoteReviewStatus.rejected,
    WorkRemoteReviewStatus.suspended,
  ]) {
    test(
      'R669 separate application keeps exact review decision $status',
      () async {
        final gateway = ReviewWorkGateway(initialReviewStatus: status)
          ..reviewResultReason = 'Please confirm the business address.';
        final work = WorkSession(gateway: gateway)
          ..activeWorkspace = existingStore;
        addTearDown(work.dispose);
        final id = await addWorkspaceApplication(work, 'Review Kirana');
        final caseId = work.reviewCaseId;
        expect(await work.checkReview(), isFalse);
        expect(work.startAnotherWork(), isTrue);
        expect(work.resumeWorkspaceApplication(id), isTrue);
        expect(work.reviewCaseId, caseId);
        expect(work.remoteReviewStatus, status);
        expect(work.reviewReason, gateway.reviewResultReason);
        expect(work.reviewStatusNeedsRefresh, isFalse);
        expect(work.activeWorkspace, same(existingStore));
      },
    );
  }

  for (final cacheState in ['present', 'changed', 'missing']) {
    test(
      'R6617 document preview restart $cacheState stays application scoped',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'mool-proof-recovery-',
        );
        addTearDown(() => root.delete(recursive: true));
        final firstFile = File(
          '${root.path}${Platform.pathSeparator}first.pdf',
        );
        final secondFile = File(
          '${root.path}${Platform.pathSeparator}second.pdf',
        );
        await firstFile.writeAsString('%PDF-1.4\nFirst test document');
        await secondFile.writeAsString('%PDF-1.4\nSecond test document');
        var selectedFile = firstFile;
        final picker = NativeWorkProofPicker(
          documentPicker: () async => XFile(selectedFile.path),
          temporaryDirectory: () async => root,
        );
        final memory = _PendingProofMemory();
        final gateway = ReviewWorkGateway(
          initialReviewStatus: WorkRemoteReviewStatus.pending,
        );
        final work = WorkSession(
          gateway: gateway,
          proofPicker: picker,
          contactDraftStore: memory,
        );
        await work.recoverPendingProof(accountReady: true);
        work.activeWorkspace = existingStore;
        final first = await addWorkspaceApplication(work, 'First Kirana');
        final firstBytes = work.pickedProofs['personal-kyc']!.bytes;
        final firstReference = work.addedProofs['personal-kyc'];
        selectedFile = secondFile;
        final second = await addWorkspaceApplication(work, 'Second Kirana');
        await work.flushContactDraft();
        work.dispose();
        if (cacheState == 'changed') {
          await firstFile.writeAsString('%PDF-1.4\nChanged document');
        }
        if (cacheState == 'missing') await firstFile.delete();
        final restored = WorkSession(
          gateway: gateway,
          proofPicker: picker,
          contactDraftStore: memory,
        );
        addTearDown(restored.dispose);
        await restored.recoverPendingProof(accountReady: true);
        expect(restored.resumeWorkspaceApplication(first), isTrue);
        expect(restored.addedProofs['personal-kyc'], firstReference);
        if (cacheState == 'present') {
          expect(restored.pickedProofs['personal-kyc']!.fileName, 'first.pdf');
          expect(
            restored.pickedProofs['personal-kyc']!.bytes,
            orderedEquals(firstBytes),
          );
        } else {
          expect(restored.pickedProofs, isEmpty);
          expect(
            restored.documentRecoveryMessage,
            contains('could not be reopened'),
          );
        }
        expect(restored.hasVerifiedWorkspace, isFalse);
        expect(restored.workspaceContactsReady, isFalse);
        expect(restored.declarationAccepted, isFalse);
        expect(restored.resumeWorkspaceApplication(second), isTrue);
        expect(restored.pickedProofs['personal-kyc']!.fileName, 'second.pdf');
        expect(restored.documentRecoveryMessage, isNull);
        await restored.flushContactDraft();
        final again = WorkSession(
          gateway: gateway,
          proofPicker: picker,
          contactDraftStore: memory,
        );
        addTearDown(again.dispose);
        await again.recoverPendingProof(accountReady: true);
        expect(again.resumeWorkspaceApplication(first), isTrue);
        expect(again.addedProofs['personal-kyc'], firstReference);
        if (cacheState != 'present') {
          expect(again.pickedProofs, isEmpty);
          expect(
            again.documentRecoveryMessage,
            contains('could not be reopened'),
          );
        }
        memory.accountScope = 'different-account';
        await restored.recoverPendingProof(accountReady: true);
        expect(restored.pickedProofs, isEmpty);
        expect(restored.savedWorkspaceApplications, isEmpty);
      },
    );
  }

  test(
    'R6617 recorded preview rejects paths outside private cache and altered metadata',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'mool-proof-boundary-',
      );
      addTearDown(() => root.delete(recursive: true));
      final private = await Directory('${root.path}/private').create();
      final outside = File('${root.path}/outside.pdf');
      await outside.writeAsString('%PDF-1.4\nOutside test document');
      final picker = NativeWorkProofPicker(
        documentPicker: () async => XFile(outside.path),
        temporaryDirectory: () async => private,
      );
      final picked = (await picker.pick(WorkProofSource.upload))!;
      expect(await picker.restoreRecorded(picked.recoveryRecord!), isNull);
      final inside = await outside.copy('${private.path}/inside.pdf');
      final record = {...picked.recoveryRecord!, 'path': inside.path};
      expect(await picker.restoreRecorded(record), isNotNull);
      for (final corrupt in [
        {...record, 'size': 0},
        {...record, 'size': 10 * 1024 * 1024 + 1},
        {...record, 'sha256': 'invalid'},
        {...record, 'contentType': 'image/png'},
        {...record, 'name': 'not-a-pdf.exe'},
      ]) {
        expect(await picker.restoreRecorded(corrupt), isNull);
      }
    },
  );

  test(
    'R669 separate applications survive restart without cached authority or document bytes',
    () async {
      final memory = _PendingProofMemory();
      final gateway = ReviewWorkGateway(
        initialReviewStatus: WorkRemoteReviewStatus.pending,
      );
      final work = WorkSession(gateway: gateway, contactDraftStore: memory);
      await work.recoverPendingProof(accountReady: true);
      work.activeWorkspace = existingStore;
      final first = await addWorkspaceApplication(work, 'First Kirana');
      final firstCase = work.reviewCaseId;
      final proof = work.addedProofs['personal-kyc'];
      await addWorkspaceApplication(work, 'Second Kirana');
      await work.flushContactDraft();
      work.dispose();
      final restored = WorkSession(gateway: gateway, contactDraftStore: memory);
      addTearDown(restored.dispose);
      await restored.recoverPendingProof(accountReady: true);
      expect(restored.hasVerifiedWorkspace, isFalse);
      expect(restored.savedWorkspaceApplications, hasLength(2));
      expect(restored.resumeWorkspaceApplication(first), isTrue);
      expect(restored.reviewCaseId, firstCase);
      expect(restored.workName, 'First Kirana');
      expect(restored.submittedProfile?.name, 'First Kirana');
      expect(restored.addedProofs['personal-kyc'], proof);
      expect(restored.pickedProofs, isEmpty);
      expect(restored.workspaceContactsReady, isFalse);
      expect(restored.primaryMobileOtpSent, isFalse);
      expect(restored.declarationAccepted, isFalse);
      expect(restored.remoteReviewStatus, isNull);
      expect(restored.reviewStatusNeedsRefresh, isTrue);
      expect(restored.beginReviewCorrection(), isFalse);
      expect(await restored.checkReview(), isFalse);
      expect(restored.reviewStatusNeedsRefresh, isFalse);
      expect(restored.remoteReviewStatus, WorkRemoteReviewStatus.pending);
      expect(restored.hasVerifiedWorkspace, isFalse);
      await restored.flushContactDraft();
      memory.accountScope = 'another-account';
      await restored.recoverPendingProof(accountReady: true);
      expect(restored.savedWorkspaceApplications, isEmpty);
      expect(restored.workName, isEmpty);
      expect(restored.addedProofs, isEmpty);
      expect(restored.resumeWorkspaceApplication(first), isFalse);
    },
  );

  test(
    'R669 approval promotes only the reviewed application and retains existing Store',
    () async {
      final gateway = ReviewWorkGateway(
        initialReviewStatus: WorkRemoteReviewStatus.pending,
      );
      final work = WorkSession(gateway: gateway)
        ..activeWorkspace = existingStore;
      addTearDown(work.dispose);
      await addWorkspaceApplication(work, 'New Kirana');
      gateway.reviewResultStatus = WorkRemoteReviewStatus.approved;
      expect(await work.checkReview(), isTrue);
      final approved = work.activeWorkspace!;
      expect(approved.id, isNot(existingStore.id));
      expect(approved.name, 'New Kirana');
      expect(work.savedWorkspaceApplications, isEmpty);
      expect(work.otherWorkspaces.single, existingStore);
      work.activateWorkspace(existingStore);
      expect(work.activeWorkspace, existingStore);
      expect(work.savedWorkspaceApplications, isEmpty);
      work.activateWorkspace(approved);
      expect(work.activeWorkspace, approved);
    },
  );

  test('R669 application and approved Store switching stay separate', () async {
    final work = WorkSession(
      gateway: ReviewWorkGateway(
        initialReviewStatus: WorkRemoteReviewStatus.pending,
      ),
    )..activeWorkspace = existingStore;
    addTearDown(work.dispose);
    const other = WorkWorkspace(
      id: 'other-store',
      name: 'Other shop',
      profileId: 'retailer-speciality',
      profileLabel: 'Speciality Retail Shop',
      area: '302002',
      verified: true,
    );
    work.otherWorkspaces.add(other);
    final id = await addWorkspaceApplication(work, 'Pending Kirana');
    final caseId = work.reviewCaseId;
    work.activateWorkspace(other);
    expect(work.workName, 'Other shop');
    expect(work.reviewCaseId, isNull);
    expect(work.addedProofs, isEmpty);
    expect(work.resumeWorkspaceApplication(id), isTrue);
    expect(work.workName, 'Pending Kirana');
    expect(work.reviewCaseId, caseId);
    expect(work.activeWorkspace, other);
  });

  test('R669 application context cannot change during submission', () async {
    final gateway = _DeferredSubmissionGateway();
    final work = application(gateway: gateway)..activeWorkspace = existingStore;
    addTearDown(work.dispose);
    final sending = work.submitProfile();
    expect(work.busy, isTrue);
    expect(work.startAnotherWork(), isFalse);
    expect(work.workName, 'Sharma Stores');
    gateway.result.complete(
      const WorkReviewResult(
        caseId: 'new-case',
        status: WorkRemoteReviewStatus.pending,
        plan: 'free',
      ),
    );
    expect(await sending, isTrue);
    expect(work.reviewCaseId, 'new-case');
    expect(work.savedWorkspaceApplications.single.name, 'Sharma Stores');
  });

  test(
    'R669 application feed retains pending documents alongside an approved Store',
    () async {
      final gateway = _ApplicationFeedGateway();
      final work = WorkSession(gateway: gateway)
        ..activeWorkspace = existingStore;
      addTearDown(work.dispose);
      final id = await addWorkspaceApplication(work, 'Pending Kirana');
      final caseId = work.reviewCaseId!;
      final submitted = work.submittedProfile;
      final proofs = Map.of(work.addedProofs);
      gateway.records = [
        const WorkReviewResult(
          caseId: 'existing-case',
          status: WorkRemoteReviewStatus.live,
          plan: 'free',
          workspaceId: 'existing-store',
          profileId: 'retailer-grocery',
          name: 'Existing Kirana',
          area: '302001',
        ),
        WorkReviewResult(
          caseId: caseId,
          status: WorkRemoteReviewStatus.pending,
          plan: 'free',
          profileId: 'retailer-grocery',
          name: 'Pending Kirana',
          area: '302002',
          reason: 'Please clarify the address.',
        ),
      ];
      await work.refreshFeed();
      expect(work.activeWorkspace?.id, existingStore.id);
      expect(work.reviewCaseId, caseId);
      expect(work.workName, 'Pending Kirana');
      expect(work.submittedProfile, same(submitted));
      expect(work.addedProofs, proofs);
      expect(work.reviewReason, 'Please clarify the address.');
      expect(work.startAnotherWork(), isTrue);
      await work.refreshFeed();
      expect(work.savedWorkspaceApplications.single.id, id);
      expect(work.resumeWorkspaceApplication(id), isTrue);
      expect(work.addedProofs, proofs);
      expect(work.submittedProfile, same(submitted));
    },
  );

  test(
    'R669 application feed recovers every case of the same type without approval from cache',
    () async {
      final gateway = _ApplicationFeedGateway()
        ..records = const [
          WorkReviewResult(
            caseId: 'existing-case',
            status: WorkRemoteReviewStatus.live,
            plan: 'free',
            workspaceId: 'existing-store',
            profileId: 'retailer-grocery',
            name: 'Existing Kirana',
            area: '302001',
          ),
          WorkReviewResult(
            caseId: 'case-a',
            status: WorkRemoteReviewStatus.pending,
            plan: 'free',
            profileId: 'retailer-grocery',
            name: 'First application',
            area: '302002',
          ),
          WorkReviewResult(
            caseId: 'case-b',
            status: WorkRemoteReviewStatus.rejected,
            plan: 'free',
            profileId: 'retailer-grocery',
            name: 'Second application',
            area: '302003',
            reason: 'The address could not be verified.',
          ),
        ];
      final work = WorkSession(gateway: gateway);
      addTearDown(work.dispose);
      await work.refreshFeed();
      expect(work.activeWorkspace?.id, 'existing-store');
      expect(work.savedWorkspaceApplications, hasLength(2));
      final first = work.savedWorkspaceApplications.singleWhere(
        (entry) => entry.name == 'First application',
      );
      final second = work.savedWorkspaceApplications.singleWhere(
        (entry) => entry.name == 'Second application',
      );
      expect(work.resumeWorkspaceApplication(first.id), isTrue);
      expect(work.reviewCaseId, 'case-a');
      expect(work.resumeWorkspaceApplication(second.id), isTrue);
      expect(work.reviewCaseId, 'case-b');
      expect(work.remoteReviewStatus, WorkRemoteReviewStatus.rejected);
      expect(work.reviewReason, 'The address could not be verified.');
      expect(work.addedProofs, isEmpty);
      expect(work.primaryMobileVerified, isFalse);
      expect(work.activeWorkspace?.id, 'existing-store');
    },
  );

  test(
    'R669 correction cue tracks actual changes until acknowledgement',
    () async {
      final gateway = ReviewWorkGateway();
      final work = application(gateway: gateway);
      addTearDown(work.dispose);
      expect(await work.submitProfile(), isTrue);
      final original = work.submittedProfile!;
      work.reviewReason = 'Please confirm your business details.';
      expect(work.beginReviewCorrection(), isTrue);
      expect(work.hasUnsubmittedReviewChanges, isFalse);
      final changes = <VoidCallback>[
        () => work.workName = 'Corrected Stores',
        () => work.authorizedPersonName = 'Another representative',
        () => work.businessRelationship = 'Manager',
        () => work.workArea = 'Jodhpur',
        () => work.primaryActivity = 'Household essentials',
        () => work.primaryMobile = '9123456780',
        () => work.contactEmail = 'changed@example.com',
        () => work.alternateMobile = '9123456780',
        () => work.addedProofs['shop-front'] = 'replacement-proof',
      ];
      for (final change in changes) {
        change();
        expect(work.hasUnsubmittedReviewChanges, isTrue);
        expect(work.submittedProfile, same(original));
        work.workName = original.name;
        work.authorizedPersonName = original.authorizedPersonName;
        work.businessRelationship = original.businessRelationship;
        work.workArea = original.area;
        work.primaryActivity = original.primaryActivity;
        work.primaryMobile = original.primaryMobile;
        work.contactEmail = original.email;
        work.alternateMobile = original.alternateMobile;
        work.addedProofs
          ..clear()
          ..addAll(original.proofReferences);
        expect(work.hasUnsubmittedReviewChanges, isFalse);
      }
      work.workName = 'Corrected Stores';
      work.declarationAccepted = true;
      gateway.failSubmission = true;
      expect(await work.submitProfile(), isFalse);
      expect(work.hasUnsubmittedReviewChanges, isTrue);
      expect(work.submittedProfile, same(original));
      expect(await work.submitProfile(), isTrue);
      expect(work.hasUnsubmittedReviewChanges, isFalse);
      expect(work.submittedProfile!.name, 'Corrected Stores');
    },
  );

  test(
    'S07 device review defaults pending without changing ordinary fixtures',
    () {
      const deviceReview =
          bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
          bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY');
      expect(
        ReviewWorkGateway().reviewResultStatus,
        deviceReview
            ? WorkRemoteReviewStatus.pending
            : WorkRemoteReviewStatus.approved,
      );
    },
  );

  group('r66.8 review state isolation', () {
    const enabled =
        bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
        bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY');

    test(
      'R669 device review identities survive separate gateway lifetimes',
      () async {
        final caseIds = <String>{};
        final workspaceIds = <String>{};
        for (var instance = 0; instance < 2; instance++) {
          final gateway = _DeviceReviewIdentityGateway();
          final work = application(gateway: gateway);
          addTearDown(work.dispose);
          expect(await work.submitProfile(), isTrue);
          final caseId = work.reviewCaseId!;
          expect(caseIds.add(caseId), isTrue);
          expect(caseId, isNot('WP-240701'));
          expect(gateway.canSelectDeviceReviewCase(caseId), isTrue);
          gateway.selectDeviceReviewCase(caseId, WorkReviewTestCase.approved);
          final result = await gateway.checkReview(caseId);
          expect(workspaceIds.add(result.workspaceId!), isTrue);
          expect(
            (await gateway.checkReview(caseId)).workspaceId,
            result.workspaceId,
          );
          expect(
            (await gateway.checkReview('unknown-case')).workspaceId,
            isNull,
          );
        }
      },
    );

    test('requires both flags and refuses unknown application IDs', () {
      final gateway = ReviewWorkGateway();
      expect(gateway.deviceReviewControlsEnabled, enabled);
      expect(gateway.canSelectDeviceReviewCase('unrelated-case'), isFalse);
      for (final scenario in WorkReviewTestCase.values) {
        expect(
          () => gateway.selectDeviceReviewCase('unrelated-case', scenario),
          throwsA(isA<WorkGatewayException>()),
        );
      }
    });

    test('selection is explicit and confined to its submitted case', () async {
      final gateway = ReviewWorkGateway(
        initialReviewStatus: WorkRemoteReviewStatus.pending,
      );
      final work = application(gateway: gateway);
      addTearDown(work.dispose);
      expect(await work.submitProfile(), isTrue);
      final caseId = work.reviewCaseId!;
      expect(
        (await gateway.checkReview(caseId)).status,
        WorkRemoteReviewStatus.pending,
      );
      expect(gateway.canSelectDeviceReviewCase(caseId), enabled);
      if (!enabled) {
        expect(
          () => gateway.selectDeviceReviewCase(
            caseId,
            WorkReviewTestCase.approved,
          ),
          throwsA(isA<WorkGatewayException>()),
        );
        expect((await gateway.checkReview(caseId)).workspaceId, isNull);
        return;
      }
      for (final scenario in WorkReviewTestCase.values) {
        gateway.selectDeviceReviewCase(caseId, scenario);
        final response = await gateway.checkReview(caseId);
        expect(response.caseId, caseId);
        expect(response.status, switch (scenario) {
          WorkReviewTestCase.pending ||
          WorkReviewTestCase.clarification => WorkRemoteReviewStatus.pending,
          WorkReviewTestCase.rejected => WorkRemoteReviewStatus.rejected,
          WorkReviewTestCase.approved => WorkRemoteReviewStatus.approved,
        });
        expect(
          response.reason != null,
          scenario == WorkReviewTestCase.clarification ||
              scenario == WorkReviewTestCase.rejected,
        );
        expect(
          response.workspaceId != null,
          scenario == WorkReviewTestCase.approved,
        );
        expect(
          (await gateway.checkReview('other-case')).status,
          WorkRemoteReviewStatus.pending,
        );
        expect((await gateway.checkReview('other-case')).workspaceId, isNull);
      }
      final first = (await gateway.checkReview(caseId)).workspaceId;
      expect((await gateway.checkReview(caseId)).workspaceId, first);
      expect(gateway.submissionCalls, 1);
    });

    test(
      'correction clears the selected scenario and failed submit grants none',
      () async {
        final gateway = ReviewWorkGateway(
          initialReviewStatus: WorkRemoteReviewStatus.pending,
        );
        final work = application(gateway: gateway);
        addTearDown(work.dispose);
        expect(await work.submitProfile(), isTrue);
        final caseId = work.reviewCaseId!;
        if (enabled) {
          gateway.selectDeviceReviewCase(
            caseId,
            WorkReviewTestCase.clarification,
          );
        }
        await gateway.submitCorrection(caseId, gateway.lastSubmission!);
        final response = await gateway.checkReview(caseId);
        expect(response.status, WorkRemoteReviewStatus.pending);
        expect(response.reason, isNull);
        gateway.failSubmission = true;
        await expectLater(
          gateway.submitProfile(gateway.lastSubmission!),
          throwsA(isA<WorkGatewayException>()),
        );
        expect(gateway.canSelectDeviceReviewCase('WP-240702'), isFalse);
      },
    );
  });

  test(
    'S07 pending fixture stays pending and approval keeps one Workspace per case',
    () async {
      final gateway = ReviewWorkGateway(
        initialReviewStatus: WorkRemoteReviewStatus.pending,
      );
      for (var attempt = 0; attempt < 3; attempt++) {
        final result = await gateway.checkReview('case-a');
        expect(result.status, WorkRemoteReviewStatus.pending);
        expect(result.workspaceId, isNull);
      }
      gateway.reviewResultStatus = WorkRemoteReviewStatus.approved;
      final first = await gateway.checkReview('case-a');
      expect(
        (await gateway.checkReview('case-a')).workspaceId,
        first.workspaceId,
      );
      expect(
        (await gateway.checkReview('case-b')).workspaceId,
        isNot(first.workspaceId),
      );
    },
  );

  for (final changed in ['account', 'case', 'business']) {
    test('S07 delayed approval cannot replace another $changed', () async {
      final gateway = _DeferredReviewGateway();
      final store = _PendingProofMemory();
      final work = application(gateway: gateway, store: store)
        ..reviewCaseId = 'case-a'
        ..remoteReviewStatus = WorkRemoteReviewStatus.pending;
      addTearDown(work.dispose);
      final pending = work.checkReview();
      switch (changed) {
        case 'account':
          store.accountScope = 'another-account';
        case 'case':
          work.reviewCaseId = 'case-b';
        case 'business':
          work.selectProfile('retailer-speciality');
          expect(work.selectedProfile?.id, 'retailer-grocery');
          // UI switching is blocked while busy. Simulate an external rebind
          // separately so the stale-response identity guard remains covered.
          work.selectedProfile = workProfiles.firstWhere(
            (profile) => profile.id == 'retailer-speciality',
          );
      }
      gateway.result.complete(
        const WorkReviewResult(
          caseId: 'case-a',
          status: WorkRemoteReviewStatus.approved,
          workspaceId: 'workspace-a',
          plan: 'free',
        ),
      );
      expect(await pending, isFalse);
      expect(work.activeWorkspace, isNull);
      expect(work.remoteReviewStatus, WorkRemoteReviewStatus.pending);
      expect(work.takeWorkspaceApprovalWelcome(), isFalse);
      expect(work.noticeMessage, isNull);
    });
  }

  test('S07 delayed submission cannot acknowledge another account', () async {
    final gateway = _DeferredSubmissionGateway();
    final store = _PendingProofMemory();
    final work = application(gateway: gateway, store: store);
    addTearDown(work.dispose);
    final pending = work.submitProfile();
    store.accountScope = 'another-account';
    gateway.result.complete(
      const WorkReviewResult(
        caseId: 'case-a',
        status: WorkRemoteReviewStatus.pending,
        plan: 'free',
      ),
    );
    expect(await pending, isFalse);
    expect(work.submittedProfile, isNull);
    expect(work.reviewCaseId, isNull);
    expect(work.noticeMessage, isNull);
  });

  test(
    'S07 mismatched correction preserves the acknowledged submission',
    () async {
      final gateway = _DeferredSubmissionGateway();
      final work = application(gateway: gateway);
      addTearDown(work.dispose);
      gateway.result.complete(
        const WorkReviewResult(
          caseId: 'case-a',
          status: WorkRemoteReviewStatus.pending,
          plan: 'free',
        ),
      );
      expect(await work.submitProfile(), isTrue);
      final acknowledged = work.submittedProfile;
      work.reviewReason = 'Please confirm the registered business name.';
      expect(work.beginReviewCorrection(), isTrue);
      work.workName = 'Corrected Stores';
      work.declarationAccepted = true;
      gateway.result = Completer<WorkReviewResult>();
      final correction = work.submitProfile();
      gateway.result.complete(
        const WorkReviewResult(
          caseId: 'different-case',
          status: WorkRemoteReviewStatus.pending,
          plan: 'free',
        ),
      );
      expect(await correction, isFalse);
      expect(work.submittedProfile, same(acknowledged));
      expect(work.reviewCaseId, 'case-a');
      expect(work.reviewCorrectionDraft, isTrue);
      expect(work.errorMessage, contains('could not be matched'));
      gateway.result = Completer<WorkReviewResult>();
      final retry = work.submitProfile();
      gateway.result.complete(
        const WorkReviewResult(
          caseId: 'case-a',
          status: WorkRemoteReviewStatus.pending,
          plan: 'free',
        ),
      );
      expect(await retry, isTrue);
      expect(work.submittedProfile?.name, 'Corrected Stores');
      expect(work.reviewCaseId, 'case-a');
      expect(work.reviewCorrectionDraft, isFalse);
    },
  );

  test(
    'S07 malformed approval cannot replace the last valid pending decision',
    () async {
      final gateway = _DeferredReviewGateway();
      final work = application(gateway: gateway)
        ..reviewCaseId = 'case-a'
        ..remoteReviewStatus = WorkRemoteReviewStatus.pending;
      addTearDown(work.dispose);
      final pending = work.checkReview();
      gateway.result.complete(
        const WorkReviewResult(
          caseId: 'case-a',
          status: WorkRemoteReviewStatus.approved,
          workspaceId: '  ',
          plan: 'free',
        ),
      );
      expect(await pending, isFalse);
      expect(work.remoteReviewStatus, WorkRemoteReviewStatus.pending);
      expect(work.activeWorkspace, isNull);
      expect(work.errorMessage, contains('without a Workspace'));
    },
  );

  test(
    'S07 restored clarification retains its exact service request',
    () async {
      final gateway = _DeferredFeedGateway();
      final work = WorkSession(gateway: gateway);
      addTearDown(work.dispose);
      final pending = work.refreshFeed();
      gateway.result.complete(const [
        WorkReviewResult(
          caseId: 'case-a',
          status: WorkRemoteReviewStatus.pending,
          plan: 'free',
          profileId: 'retailer-grocery',
          reason: 'Please resend the readable bank document.',
        ),
      ]);
      await pending;
      expect(work.reviewReason, 'Please resend the readable bank document.');
      expect(work.reviewCaseId, 'case-a');
      expect(work.hasVerifiedWorkspace, isFalse);
    },
  );

  test(
    'R669 unsubmitted business is not replaced by a same-type server case',
    () async {
      final gateway = _ApplicationFeedGateway()
        ..records = const [
          WorkReviewResult(
            caseId: 'other-case',
            status: WorkRemoteReviewStatus.pending,
            plan: 'free',
            profileId: 'retailer-grocery',
            name: 'Other business',
            area: '302002',
            reason: 'Please clarify the address.',
          ),
        ];
      final work = application(gateway: gateway);
      addTearDown(work.dispose);
      await work.refreshFeed();
      expect(work.workName, 'Sharma Stores');
      expect(work.reviewCaseId, isNull);
      expect(work.reviewReason, isNull);
      expect(work.savedWorkspaceApplications, hasLength(2));
      final other = work.savedWorkspaceApplications.singleWhere(
        (entry) => entry.name == 'Other business',
      );
      expect(work.resumeWorkspaceApplication(other.id), isTrue);
      expect(work.reviewCaseId, 'other-case');
      expect(work.reviewReason, 'Please clarify the address.');
    },
  );

  test(
    'S07 late account feed cannot restore or announce another application',
    () async {
      final gateway = _DeferredFeedGateway();
      final store = _PendingProofMemory();
      final work = application(gateway: gateway, store: store);
      addTearDown(work.dispose);
      final pending = work.refreshFeed();
      store.accountScope = 'another-account';
      gateway.result.complete(const [
        WorkReviewResult(
          caseId: 'case-a',
          status: WorkRemoteReviewStatus.approved,
          plan: 'free',
          profileId: 'retailer-grocery',
          workspaceId: 'workspace-a',
          name: 'Other Stores',
          area: 'Jaipur',
        ),
      ]);
      await pending;
      expect(work.hasVerifiedWorkspace, isFalse);
      expect(work.initialWorkspaceStateLoaded, isFalse);
      expect(work.noticeMessage, isNull);
    },
  );

  test(
    'S08 welcome is once per matching approval and survives account-scoped restart',
    () async {
      final store = _PendingProofMemory();
      final work = application(store: store);
      await work.recoverPendingProof(accountReady: true);
      work.reviewCaseId = 'case-a';
      expect(work.takeWorkspaceApprovalWelcome(), isFalse);
      expect(await work.checkReview(), isTrue);
      expect(work.takeWorkspaceApprovalWelcome(), isTrue);
      expect(work.takeWorkspaceApprovalWelcome(), isFalse);
      expect(work.workspaceVisibleToCustomers, isFalse);
      expect(work.workspaceAcceptingOrders, isFalse);
      await work.flushContactDraft();
      work.dispose();
      final restored = WorkSession(contactDraftStore: store);
      addTearDown(restored.dispose);
      await restored.recoverPendingProof(accountReady: true);
      expect(restored.hasVerifiedWorkspace, isFalse);
      expect(restored.takeWorkspaceApprovalWelcome(), isFalse);
      restored.reviewCaseId = 'case-a';
      expect(await restored.checkReview(), isTrue);
      expect(restored.takeWorkspaceApprovalWelcome(), isFalse);
      restored.reviewCaseId = 'case-b';
      expect(await restored.checkReview(), isTrue);
      expect(restored.takeWorkspaceApprovalWelcome(), isTrue);
      await restored.flushContactDraft();
      store.accountScope = 'different-account';
      await restored.recoverPendingProof(accountReady: true);
      expect(restored.activeWorkspace, isNull);
      expect(restored.otherWorkspaces, isEmpty);
      expect(restored.initialWorkspaceStateLoaded, isFalse);
      expect(restored.takeWorkspaceApprovalWelcome(), isFalse);
    },
  );

  test(
    'Store scope account change clears current and cached operational data',
    () async {
      final memory = _PendingProofMemory();
      final work = WorkSession(contactDraftStore: memory);
      addTearDown(work.dispose);
      await work.recoverPendingProof(accountReady: true);
      const first = WorkWorkspace(
        id: 'store-a',
        name: 'First store',
        profileLabel: 'Grocery / Kirana Shop',
        profileId: 'retailer-grocery',
        area: 'Jodhpur',
        verified: true,
      );
      const second = WorkWorkspace(
        id: 'store-b',
        name: 'Second store',
        profileLabel: 'Speciality Retail Shop',
        profileId: 'retailer-speciality',
        area: 'Jaipur',
        verified: true,
      );
      work.activeWorkspace = first;
      work.workspaceId = first.id;
      work.otherWorkspaces.add(second);
      work.workspaceSettlementBalance = 500;
      work.workspaceOrderCustomer = 'First customer';
      work.workspaceOrderQuantities['first-sku'] = 2;
      work.activateWorkspace(second);
      work.workspaceSettlementBalance = 900;
      work.workspaceOrderCustomer = 'Second customer';
      memory.accountScope = 'new-account';
      await work.recoverPendingProof(accountReady: true);
      expect(work.activeWorkspace, isNull);
      expect(work.workspaceSettlementBalance, 0);
      expect(work.workspaceOrderCustomer, isEmpty);
      expect(work.workspaceOrderQuantities, isEmpty);
      work.activeWorkspace = first;
      work.workspaceId = first.id;
      expect(work.workspaceSettlementBalance, 0);
      work.activateWorkspace(second);
      expect(work.workspaceSettlementBalance, 0);
      expect(work.workspaceOrderCustomer, isEmpty);
    },
  );

  test(
    'Store scope old account settlement cannot finish the new account operation',
    () async {
      final memory = _PendingProofMemory();
      final gateway = _AccountSettlementGateway();
      final work = WorkSession(gateway: gateway, contactDraftStore: memory);
      addTearDown(work.dispose);
      await work.recoverPendingProof(accountReady: true);
      const store = WorkWorkspace(
        id: 'same-store',
        name: 'Store',
        profileLabel: 'Grocery / Kirana Shop',
        profileId: 'retailer-grocery',
        area: 'Jodhpur',
        verified: true,
      );
      work.activeWorkspace = store;
      work.workspaceId = store.id;
      work.workspaceSettlementBalance = 500;
      final old = work.requestWorkspaceSettlement(amount: 100);
      memory.accountScope = 'new-account';
      await work.recoverPendingProof(accountReady: true);
      work.activeWorkspace = store;
      work.workspaceId = store.id;
      work.workspaceSettlementBalance = 900;
      final current = work.requestWorkspaceSettlement(amount: 200);
      expect(gateway.results, hasLength(2));
      gateway.results.first.complete(
        const WorkSettlementResult(reference: 'old', acceptedAmount: 100),
      );
      await old;
      expect(work.busy, isTrue);
      expect(work.workspaceSettlementBalance, 900);
      expect(work.workspaceSettlementReference, isNull);
      gateway.results.last.complete(
        const WorkSettlementResult(reference: 'current', acceptedAmount: 200),
      );
      await current;
      expect(work.busy, isFalse);
      expect(work.workspaceSettlementBalance, 700);
      expect(work.workspaceSettlementReference, 'current');
    },
  );

  test(
    'Store scope feed refresh retains the selected approved store',
    () async {
      final work = WorkSession(gateway: _MultiStoreFeedGateway());
      addTearDown(work.dispose);
      await work.refreshFeed();
      expect(work.activeWorkspace?.id, 'store-b');
      work.workspaceSettlementBalance = 900;
      final first = work.otherWorkspaces.single;
      work.activateWorkspace(first);
      work.workspaceSettlementBalance = 100;
      await work.refreshFeed();
      expect(work.activeWorkspace?.id, 'store-a');
      expect(work.workspaceId, 'store-a');
      expect(work.workName, 'First store');
      expect(work.workspaceSettlementBalance, 100);
      work.activateWorkspace(work.otherWorkspaces.single);
      expect(work.workspaceSettlementBalance, 900);
    },
  );

  WorkSession removableProof({WorkPendingProofStore? store}) {
    final work = WorkSession(pendingProofStore: store)
      ..selectProfile('retailer-grocery');
    final id = work.selectedWorkspaceDocuments.first.id;
    work.addedProofs[id] = 'private-proof-reference';
    work.pickedProofs[id] = WorkPickedProof(
      fileName: 'business-identity.pdf',
      contentType: 'application/pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    return work;
  }

  test(
    'S05 Undo restores the exact removed document without upload or approval',
    () {
      final work = removableProof();
      addTearDown(work.dispose);
      final id = work.selectedWorkspaceDocuments.first.id;
      final file = work.pickedProofs[id];
      work.setDeclaration(true);
      work.removeProof(id);
      expect(work.addedProofs, isEmpty);
      expect(work.pickedProofs, isEmpty);
      expect(work.declarationAccepted, isFalse);
      expect(work.noticeMessage, isNull);
      expect(work.removedProofName(id), 'business-identity.pdf');
      expect(work.undoProofRemoval(id), isTrue);
      expect(work.addedProofs[id], 'private-proof-reference');
      expect(work.pickedProofs[id], same(file));
      expect(work.canUndoProofRemoval(id), isFalse);
      expect(work.undoProofRemoval(id), isFalse);
      expect((work.gateway as ReviewWorkGateway).proofCalls, 0);
      expect(work.hasVerifiedWorkspace, isFalse);
    },
  );

  test('S05 Undo cannot overwrite a replacement document', () async {
    final work = removableProof();
    addTearDown(work.dispose);
    final id = work.selectedWorkspaceDocuments.first.id;
    work.removeProof(id);
    expect(await work.addProof(id, WorkProofSource.upload), isTrue);
    final replacement = work.addedProofs[id];
    expect(replacement, isNot('private-proof-reference'));
    expect(work.undoProofRemoval(id), isFalse);
    expect(work.addedProofs[id], replacement);
  });

  test(
    'S05 Undo is disabled during a picker or after application submission',
    () {
      final work = removableProof();
      addTearDown(work.dispose);
      final id = work.selectedWorkspaceDocuments.first.id;
      work.removeProof(id);
      work.busy = true;
      expect(work.undoProofRemoval(id), isFalse);
      work.busy = false;
      work.reviewCaseId = 'REVIEW-CASE';
      expect(work.undoProofRemoval(id), isFalse);
      expect(work.addedProofs, isEmpty);
      work.reviewCorrectionDraft = true;
      expect(work.undoProofRemoval(id), isTrue);
    },
  );

  test('S05 Undo cannot restore another account or business selection', () {
    final store = _PendingProofMemory();
    final work = removableProof(store: store);
    addTearDown(work.dispose);
    final id = work.selectedWorkspaceDocuments.first.id;
    work.removeProof(id);
    store.accountScope = 'second-account';
    expect(work.undoProofRemoval(id), isFalse);
    store.accountScope = 'review-account';
    work.selectProfile('retailer-speciality');
    expect(work.undoProofRemoval(id), isFalse);
    expect(work.addedProofs, isEmpty);
  });

  test(
    'S03 draft serial writes retain the latest edit while storage is busy',
    () async {
      final store = _SlowWriteDraftMemory();
      final work = WorkSession(contactDraftStore: store);
      await work.recoverPendingProof(accountReady: true);
      work.savePersonName('A');
      work.savePersonName('Asha');
      work.savePersonName('Asha Sharma');
      final flush = work.flushContactDraft();
      expect(store.writes, 1);
      store.firstWrite.complete();
      await flush;
      expect(store.writes, 2);
      expect(store.draft!['personName'], 'Asha Sharma');
      work.dispose();
    },
  );

  test('S03 draft late read from a signed-out account is discarded', () async {
    final store = _DelayedDraftMemory();
    final work = WorkSession(contactDraftStore: store);
    addTearDown(work.dispose);
    final reading = work.recoverPendingProof(accountReady: true);
    store.accountScope = null;
    await work.recoverPendingProof(accountReady: false);
    store.readResult.complete({
      'version': 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'personName': 'Previous account',
    });
    await reading;
    expect(work.authorizedPersonName, isEmpty);
    expect(work.primaryMobileVerified, isFalse);
  });

  test(
    'S03 draft restores incomplete inputs without OTP or approval claims',
    () async {
      final store = _PendingProofMemory();
      final work = WorkSession(contactDraftStore: store);
      await work.recoverPendingProof(accountReady: true);
      work.selectProfile('retailer-grocery');
      work.savePersonName('Asha Sharma');
      work.saveBusinessRelationship('Owner');
      work.editWorkspaceContact(WorkContactChannel.primaryMobile, '9829');
      work.editWorkspaceContact(WorkContactChannel.email, 'asha@');
      work.editWorkspaceContact(WorkContactChannel.alternateMobile, '9876');
      work.saveDetails(
        name: 'Sharma Stores',
        area: 'Jaipur',
        activity: 'Groceries',
      );
      await work.flushContactDraft();
      work.dispose();
      final restored = WorkSession(contactDraftStore: store);
      addTearDown(restored.dispose);
      expect(await restored.recoverPendingProof(accountReady: true), isFalse);
      expect(restored.selectedProfile?.id, 'retailer-grocery');
      expect(restored.authorizedPersonName, 'Asha Sharma');
      expect(restored.businessRelationship, 'Owner');
      expect(restored.primaryMobile, '9829');
      expect(restored.contactEmail, 'asha@');
      expect(restored.alternateMobile, '9876');
      expect(restored.workName, 'Sharma Stores');
      expect(restored.workArea, 'Jaipur');
      expect(restored.primaryActivity, 'Groceries');
      expect(restored.workspaceContactsReady, isFalse);
      expect(restored.primaryMobileOtpSent, isFalse);
      expect(restored.declarationAccepted, isFalse);
      expect(restored.reviewCaseId, isNull);
      expect(
        store.draft!.keys.any(
          (key) => RegExp(
            'otp|token|confirmed|approval',
            caseSensitive: false,
          ).hasMatch(key),
        ),
        isFalse,
      );
    },
  );

  test(
    'S03 draft retains deliberate clears through late hydration and restart',
    () async {
      const snapshot = WorkAccountSnapshot(
        displayName: 'Asha',
        email: 'asha@example.com',
        mobile: '+919829012321',
        mobileConfirmed: true,
        emailConfirmed: true,
      );
      final store = _PendingProofMemory();
      final work = WorkSession(contactDraftStore: store);
      await work.recoverPendingProof(accountReady: true);
      work.hydrateAccountSnapshot(snapshot);
      work.savePersonName('');
      work.editWorkspaceContact(WorkContactChannel.primaryMobile, '');
      work.editWorkspaceContact(WorkContactChannel.email, '');
      work.hydrateAccountSnapshot(snapshot);
      expect(work.authorizedPersonName, isEmpty);
      expect(work.primaryMobile, isEmpty);
      expect(work.contactEmail, isEmpty);
      await work.flushContactDraft();
      work.dispose();
      final restored = WorkSession(contactDraftStore: store);
      addTearDown(restored.dispose);
      await restored.recoverPendingProof(accountReady: true);
      restored.hydrateAccountSnapshot(snapshot);
      expect(restored.authorizedPersonName, isEmpty);
      expect(restored.primaryMobile, isEmpty);
      expect(restored.contactEmail, isEmpty);
      expect(restored.workspaceContactsReady, isFalse);
    },
  );

  test(
    'S03 draft reconciles only exact authoritative contact confirmations',
    () async {
      final store = _PendingProofMemory();
      final work = WorkSession(contactDraftStore: store);
      await work.recoverPendingProof(accountReady: true);
      work.editWorkspaceContact(WorkContactChannel.primaryMobile, '9829012321');
      work.editWorkspaceContact(WorkContactChannel.email, 'asha@example.com');
      await work.flushContactDraft();
      work.dispose();
      // Even tampered flags cannot grant confirmation.
      store.draft!['phoneConfirmed'] = true;
      store.draft!['emailConfirmed'] = true;
      final restored = WorkSession(contactDraftStore: store);
      addTearDown(restored.dispose);
      await restored.recoverPendingProof(accountReady: true);
      expect(restored.workspaceContactsReady, isFalse);
      restored.hydrateAccountSnapshot(
        const WorkAccountSnapshot(
          mobile: '+919829012321',
          mobileConfirmed: true,
          email: 'another@example.com',
          emailConfirmed: true,
        ),
      );
      expect(restored.primaryMobileVerified, isTrue);
      expect(restored.contactEmailVerified, isFalse);
      restored.hydrateAccountSnapshot(
        const WorkAccountSnapshot(
          email: 'ASHA@example.com',
          emailConfirmed: true,
        ),
      );
      expect(restored.workspaceContactsReady, isTrue);
    },
  );

  test(
    'S03 draft account switch clears edited inputs and pending confirmation',
    () async {
      final store = _PendingProofMemory();
      final work = WorkSession(contactDraftStore: store);
      addTearDown(work.dispose);
      await work.recoverPendingProof(accountReady: true);
      work.savePersonName('First account');
      work.selectProfile('retailer-grocery');
      work.editWorkspaceContact(WorkContactChannel.primaryMobile, '9829012321');
      work.primaryMobileVerified = true;
      work.beginWorkspaceContactEdit(WorkContactChannel.primaryMobile);
      await work.flushContactDraft();
      store.accountScope = 'second-account';
      await work.recoverPendingProof(accountReady: true);
      work.cancelWorkspaceContactEdit(WorkContactChannel.primaryMobile);
      expect(work.authorizedPersonName, isEmpty);
      expect(work.primaryMobile, isEmpty);
      expect(work.primaryMobileVerified, isFalse);
      expect(work.selectedProfile, isNull);
      expect(
        work.isEditingWorkspaceContact(WorkContactChannel.primaryMobile),
        isFalse,
      );
    },
  );

  test('S03 draft delayed read cannot overwrite typing', () async {
    final store = _DelayedDraftMemory();
    final work = WorkSession(contactDraftStore: store);
    addTearDown(work.dispose);
    final recovery = work.recoverPendingProof(accountReady: true);
    work.savePersonName('Current typing');
    store.readResult.complete({
      'version': 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'personName': 'Old draft',
    });
    await recovery;
    expect(work.authorizedPersonName, 'Current typing');
    await work.flushContactDraft();
  });

  test(
    'S03 draft unavailable storage is honest and leaves typing usable',
    () async {
      final store = _FailedDraftMemory();
      final work = WorkSession(contactDraftStore: store);
      addTearDown(work.dispose);
      await work.recoverPendingProof(accountReady: true);
      work.savePersonName('Asha');
      work.savePersonName('Asha Sharma');
      await work.flushContactDraft();
      expect(work.authorizedPersonName, 'Asha Sharma');
      expect(work.contactDraftMessage, contains('could not be saved'));
      expect(work.busy, isFalse);
    },
  );

  test('S03 draft does not consume the document picker checkpoint', () async {
    final contacts = _PendingProofMemory();
    final proof = _PendingProofMemory()..draft = _cameraDraft();
    final work = WorkSession(
      contactDraftStore: contacts,
      pendingProofStore: proof,
      proofPicker: _RecoveryPicker(),
    );
    addTearDown(work.dispose);
    expect(await work.recoverPendingProof(accountReady: true), isTrue);
    expect(work.authorizedPersonName, _cameraDraft()['personName']);
    expect(proof.draft, isNull);
    expect(work.recoveredDocumentStep, isTrue);
  });

  test(
    'S03 production document recovery cannot trust saved confirmation flags',
    () async {
      final proof = _PendingProofMemory()..draft = _cameraDraft();
      final work = WorkSession(
        gateway: UnavailableWorkGateway(),
        pendingProofStore: proof,
        proofPicker: ReviewWorkProofPicker(),
      );
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: true), isTrue);
      expect(work.primaryMobileVerified, isFalse);
      expect(work.contactEmailVerified, isFalse);
      expect(work.alternateVerified, isFalse);
    },
  );

  for (final channel in WorkContactChannel.values) {
    String replacement() => channel == WorkContactChannel.email
        ? 'replacement@example.com'
        : '9123456780';
    WorkSession contacts({
      ReviewWorkGateway? gateway,
      WorkPendingProofStore? store,
    }) => WorkSession(gateway: gateway, pendingProofStore: store)
      ..primaryMobile = '9829012321'
      ..primaryMobileVerified = true
      ..contactEmail = 'asha@example.com'
      ..contactEmailVerified = true
      ..alternateMobile = '9876543210'
      ..alternateVerified = true;
    Future<bool> send(WorkSession work, String value) => switch (channel) {
      WorkContactChannel.primaryMobile => work.sendPrimaryMobileOtp(value),
      WorkContactChannel.email => work.sendContactEmailOtp(value),
      WorkContactChannel.alternateMobile => work.sendAlternateOtp(value),
    };
    Future<bool> verify(WorkSession work, String code) => switch (channel) {
      WorkContactChannel.primaryMobile => work.verifyPrimaryMobileOtp(code),
      WorkContactChannel.email => work.verifyContactEmailOtp(code),
      WorkContactChannel.alternateMobile => work.verifyAlternateOtp(code),
    };

    test('S03 contact Change and Cancel retain exact confirmed $channel', () {
      final gateway = ReviewWorkGateway();
      final work = contacts(gateway: gateway);
      addTearDown(work.dispose);
      final original = work.workspaceContactValue(channel);
      work.beginWorkspaceContactEdit(channel);
      expect(work.workspaceContactValue(channel), original);
      expect(work.workspaceContactVerified(channel), isTrue);
      work.cancelWorkspaceContactEdit(channel);
      expect(work.workspaceContactsReady, isTrue);
      work.beginWorkspaceContactEdit(channel);
      work.setDeclaration(true);
      work.editWorkspaceContact(channel, replacement());
      expect(work.workspaceContactVerified(channel), isFalse);
      expect(work.workspaceContactsReady, isFalse);
      for (final other in WorkContactChannel.values.where(
        (c) => c != channel,
      )) {
        expect(work.workspaceContactVerified(other), isTrue);
      }
      work.cancelWorkspaceContactEdit(channel);
      expect(work.workspaceContactValue(channel), original);
      expect(work.workspaceContactsReady, isTrue);
      expect(work.isEditingWorkspaceContact(channel), isFalse);
      expect(work.declarationAccepted, isFalse);
      expect(gateway.otpCalls, 0);
      expect(gateway.otpVerificationCalls, 0);
    });

    test(
      'S03 contact replacement needs its own successful code $channel',
      () async {
        final gateway = ReviewWorkGateway();
        final work = contacts(gateway: gateway);
        addTearDown(work.dispose);
        work.beginWorkspaceContactEdit(channel);
        work.editWorkspaceContact(channel, replacement());
        expect(await verify(work, '123456'), isFalse);
        expect(gateway.otpVerificationCalls, 0);
        expect(await send(work, replacement()), isTrue);
        expect(await verify(work, '000000'), isFalse);
        expect(work.workspaceContactVerified(channel), isFalse);
        expect(work.isEditingWorkspaceContact(channel), isTrue);
        expect(await verify(work, '123456'), isTrue);
        expect(gateway.lastOtpValue, replacement());
        expect(work.workspaceContactsReady, isTrue);
        expect(work.isEditingWorkspaceContact(channel), isFalse);
        work.cancelWorkspaceContactEdit(channel);
        expect(work.workspaceContactValue(channel), replacement());
      },
    );

    for (final operation in ['send', 'verify']) {
      test(
        'S03 contact Cancel rejects stale $operation result $channel',
        () async {
          final work = contacts();
          addTearDown(work.dispose);
          final original = work.workspaceContactValue(channel);
          work.beginWorkspaceContactEdit(channel);
          work.editWorkspaceContact(channel, replacement());
          if (operation == 'verify') await send(work, replacement());
          final pending = operation == 'send'
              ? send(work, replacement())
              : verify(work, '123456');
          work.cancelWorkspaceContactEdit(channel);
          expect(await pending, isFalse);
          expect(work.workspaceContactValue(channel), original);
          expect(work.workspaceContactsReady, isTrue);
          expect(work.primaryMobileOtpSent, isFalse);
          expect(work.contactEmailOtpSent, isFalse);
          expect(work.alternateOtpSent, isFalse);
        },
      );
    }

    test(
      'S03 contact cannot restore another account or accept its code $channel',
      () async {
        final store = _PendingProofMemory();
        final work = contacts(store: store);
        addTearDown(work.dispose);
        work.beginWorkspaceContactEdit(channel);
        work.editWorkspaceContact(channel, replacement());
        await send(work, replacement());
        final pending = verify(work, '123456');
        store.accountScope = 'another-account';
        expect(await pending, isFalse);
        work.cancelWorkspaceContactEdit(channel);
        expect(work.workspaceContactValue(channel), isEmpty);
        expect(work.workspaceContactVerified(channel), isFalse);
        expect(store.draft, isNull);
      },
    );

    test(
      'S03 contact busy request cannot change the sent value $channel',
      () async {
        final gateway = ReviewWorkGateway();
        final work = contacts(gateway: gateway);
        addTearDown(work.dispose);
        final original = work.workspaceContactValue(channel);
        final pending = send(work, original);
        expect(await send(work, replacement()), isFalse);
        expect(await pending, isTrue);
        expect(work.workspaceContactValue(channel), original);
        expect(gateway.lastOtpValue, original);
        expect(gateway.otpCalls, 1);
      },
    );

    test(
      'S03 contact Cancel never confirms an unverified original $channel',
      () {
        final work = contacts();
        addTearDown(work.dispose);
        work.editWorkspaceContact(channel, replacement());
        work.beginWorkspaceContactEdit(channel);
        work.editWorkspaceContact(channel, '');
        work.cancelWorkspaceContactEdit(channel);
        expect(work.workspaceContactValue(channel), replacement());
        expect(work.workspaceContactVerified(channel), isFalse);
      },
    );
  }

  test('S03 contact Continue commits optional backup removal', () {
    final work = WorkSession()
      ..selectProfile('retailer-grocery')
      ..primaryMobile = '9829012321'
      ..primaryMobileVerified = true
      ..contactEmail = 'asha@example.com'
      ..contactEmailVerified = true
      ..alternateMobile = '9876543210'
      ..alternateVerified = true;
    addTearDown(work.dispose);
    work.beginWorkspaceContactEdit(WorkContactChannel.alternateMobile);
    work.editWorkspaceContact(WorkContactChannel.alternateMobile, '');
    expect(work.continueToProof(), isTrue);
    work.cancelWorkspaceContactEdit(WorkContactChannel.alternateMobile);
    expect(work.alternateMobile, isEmpty);
    expect(work.workspaceContactsReady, isTrue);
  });

  for (final area in [
    'Jodhpur',
    'Sardarpura, Jodhpur',
    'Sector 12, New Delhi',
    'जयपुर',
    'சென்னை',
    '342001',
    '342 001',
  ]) {
    test('Workspace Details accepts city or PIN syntax $area', () {
      final work = WorkSession()
        ..selectProfile('retailer-grocery')
        ..saveDetails(
          name: 'Mahadev Traders',
          area: area,
          activity: 'Grocery retail',
        );
      addTearDown(work.dispose);
      expect(work.detailsAreaError, isNull);
      expect(work.validateDetails(), isTrue);
      expect(work.workArea, area);
      expect(work.reviewCaseId, isNull);
      expect(work.hasVerifiedWorkspace, isFalse);
    });
  }
  for (final area in ['', '12', '123', '000000', '1234567', '---', '!!!']) {
    test('Workspace Details rejects incomplete location $area', () {
      final work = WorkSession()
        ..saveDetails(
          name: 'Mahadev Traders',
          area: area,
          activity: 'Grocery retail',
        );
      addTearDown(work.dispose);
      expect(work.detailsAreaError, isNotNull);
      expect(work.errorMessage, isNull);
      expect(work.validateDetails(), isFalse);
      expect(work.errorMessage, work.detailsAreaError);
      expect(work.workArea, area);
      expect(work.reviewCaseId, isNull);
    });
  }
  for (final source in [WorkProofSource.upload, WorkProofSource.cloudDrive]) {
    for (final extension in ['pdf', 'jpg', 'jpeg', 'png', 'webp']) {
      test(
        'native $source preserves selected $extension bytes and name',
        () async {
          // Picker signature fixture only; this is not a renderable PDF.
          final bytes = extension == 'pdf'
              ? Uint8List.fromList(utf8.encode('%PDF-1.7\nQA picker fixture'))
              : Uint8List.fromList([1, 2, 3, 4]);
          final picker = NativeWorkProofPicker(
            documentPicker: () async =>
                XFile.fromData(bytes, path: 'business-proof.$extension'),
          );
          final proof = await picker.pick(source);
          expect(proof!.fileName, 'business-proof.$extension');
          expect(proof.bytes, orderedEquals(bytes));
          expect(proof.contentType, switch (extension) {
            'pdf' => 'application/pdf',
            'jpg' || 'jpeg' => 'image/jpeg',
            _ => 'image/$extension',
          });
        },
      );
    }
    test('native $source cancellation leaves no document', () async {
      final picker = NativeWorkProofPicker(documentPicker: () async => null);
      expect(await picker.pick(source), isNull);
    });
  }
  for (final length in [0, 10 * 1024 * 1024 + 1]) {
    test(
      'native document rejects size $length before opening its stream',
      () async {
        final file = _BoundedProofFile(length: length);
        final picker = NativeWorkProofPicker(documentPicker: () async => file);
        await expectLater(
          picker.pick(WorkProofSource.upload),
          throwsA(
            isA<WorkGatewayException>().having(
              (error) => error.message,
              'message',
              contains('10 MB'),
            ),
          ),
        );
        expect(file.opens, 0);
      },
    );
  }
  for (final source in [WorkProofSource.upload, WorkProofSource.cloudDrive]) {
    for (final invalid in [
      'text renamed as pdf',
      '%PDF',
      ' %PDF-1.7',
      '\uFEFF%PDF-1.7',
    ]) {
      test(
        'REG4552 $source rejects unsupported PDF signature $invalid',
        () async {
          final picker = NativeWorkProofPicker(
            documentPicker: () async => XFile.fromData(
              Uint8List.fromList(utf8.encode(invalid)),
              path: 'QA-NOT-A-DOCUMENT.PDF',
            ),
          );
          await expectLater(
            picker.pick(source),
            throwsA(
              isA<WorkGatewayException>().having(
                (error) => error.message,
                'same guidance as Preview',
                'This PDF could not be opened. Choose another copy.',
              ),
            ),
          );
        },
      );
    }
    test('REG4552 $source accepts exact10MB with PDF signature', () async {
      final bytes = Uint8List(10 * 1024 * 1024)
        ..setRange(0, 5, ascii.encode('%PDF-'));
      final picker = NativeWorkProofPicker(
        documentPicker: () async => XFile.fromData(bytes, path: 'QA-LIMIT.PDF'),
      );
      final proof = await picker.pick(source);
      expect(proof!.bytes, orderedEquals(bytes));
      expect(proof.fileName, 'QA-LIMIT.PDF');
      expect(proof.contentType, 'application/pdf');
    });
  }
  test(
    'REG4552 failed replacement and cancellation preserve the original until valid save',
    () async {
      XFile? selected = XFile.fromData(
        Uint8List.fromList(ascii.encode('Not a PDF')),
        path: 'QA-INVALID.pdf',
      );
      final gateway = _PdfReplacementGateway();
      final work = WorkSession(
        gateway: gateway,
        proofPicker: NativeWorkProofPicker(
          documentPicker: () async => selected,
        ),
      )..selectProfile('retailer-grocery');
      addTearDown(work.dispose);
      final original = _cameraProof();
      work.addedProofs['shop-front'] = 'original-reference';
      work.pickedProofs['shop-front'] = original;
      work.declarationAccepted = true;

      expect(
        await work.addProof('shop-front', WorkProofSource.upload),
        isFalse,
      );
      expect(gateway.saves, 0);
      expect(work.addedProofs['shop-front'], 'original-reference');
      expect(work.pickedProofs['shop-front'], same(original));
      expect(work.declarationAccepted, isTrue);
      expect(
        work.errorMessage,
        'This PDF could not be opened. Choose another copy.',
      );

      selected = null;
      expect(
        await work.addProof('shop-front', WorkProofSource.cloudDrive),
        isFalse,
      );
      expect(gateway.saves, 0);
      expect(work.pickedProofs['shop-front'], same(original));
      expect(work.declarationAccepted, isTrue);

      final replacement = Uint8List.fromList(
        ascii.encode('%PDF-1.7\nQA fixture'),
      );
      selected = XFile.fromData(replacement, path: 'QA-REPLACEMENT.pdf');
      final pending = work.addProof('shop-front', WorkProofSource.upload);
      await gateway.started.future.timeout(const Duration(seconds: 3));
      expect(gateway.saves, 1);
      expect(work.addedProofs['shop-front'], 'original-reference');
      expect(work.pickedProofs['shop-front'], same(original));
      expect(work.declarationAccepted, isTrue);
      expect(work.busy, isTrue);
      gateway.result.complete('replacement-reference');
      expect(await pending, isTrue);
      expect(work.addedProofs['shop-front'], 'replacement-reference');
      expect(
        work.pickedProofs['shop-front']!.bytes,
        orderedEquals(replacement),
      );
      expect(work.pickedProofs['shop-front']!.fileName, 'QA-REPLACEMENT.pdf');
      expect(work.declarationAccepted, isFalse);
      expect(work.errorMessage, isNull);
    },
  );
  test(
    'native document stops a growing or misreported stream at10MB',
    () async {
      final file = _BoundedProofFile(
        length: 1,
        chunks: [
          Uint8List(6 * 1024 * 1024),
          Uint8List(6 * 1024 * 1024),
          Uint8List(1),
        ],
      );
      final picker = NativeWorkProofPicker(documentPicker: () async => file);
      await expectLater(
        picker.pick(WorkProofSource.cloudDrive),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(file.emitted, 2);
    },
  );
  test('native document read failure returns retry guidance', () async {
    final file = _BoundedProofFile(length: 1, failRead: true);
    final picker = NativeWorkProofPicker(documentPicker: () async => file);
    await expectLater(
      picker.pick(WorkProofSource.cloudDrive),
      throwsA(
        isA<WorkGatewayException>().having(
          (error) => error.message,
          'message',
          contains('could not be read'),
        ),
      ),
    );
  });
  test(
    'interrupted camera restores only the account-scoped document draft once',
    () async {
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final picker = _RecoveryPicker();
      final work = WorkSession(pendingProofStore: store, proofPicker: picker);
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: true), isTrue);
      expect(work.selectedProfile?.id, 'retailer-grocery');
      expect(work.workName, 'Review Kirana');
      expect(work.authorizedPersonName, 'Review Owner');
      expect(work.primaryMobileVerified, isTrue);
      expect(work.contactEmailVerified, isTrue);
      expect(work.primaryMobileOtpSent, isFalse);
      expect(work.declarationAccepted, isFalse);
      expect(work.hasVerifiedWorkspace, isFalse);
      expect(work.activeWorkspace, isNull);
      expect(work.pickedProofs['shop-front']?.fileName, 'Camera photo.jpg');
      expect(work.addedProofs.keys, contains('shop-front'));
      expect(work.addedProofs.keys, isNot(contains('unrelated-proof')));
      expect(work.recoveredDocumentStep, isTrue);
      expect(store.draft, isNull);
      expect(await work.recoverPendingProof(accountReady: true), isFalse);
      expect(picker.recoveries, 1);
      work.recoveredDocumentStep = false;
      store.accountScope = 'another-account';
      expect(await work.recoverPendingProof(accountReady: true), isFalse);
      expect(work.workName, isEmpty);
      expect(work.pickedProofs, isEmpty);
      expect(work.primaryMobileVerified, isFalse);
    },
  );

  test(
    'guest and different-account recovery never read or attach a proof',
    () async {
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final picker = _RecoveryPicker();
      final work = WorkSession(pendingProofStore: store, proofPicker: picker);
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: false), isFalse);
      expect(store.reads, 0);
      store.accountScope = 'another-account';
      expect(await work.recoverPendingProof(accountReady: true), isFalse);
      expect(work.selectedProfile, isNull);
      expect(picker.recoveries, 0);
      expect(store.draft, isNotNull);
    },
  );

  test(
    'empty lost-photo result keeps a named retry until the document is added',
    () async {
      final empty = Completer<WorkPickedProof?>()..complete(null);
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final picker = _RecoveryPicker(delayedRecovery: empty);
      final work = WorkSession(pendingProofStore: store, proofPicker: picker);
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: true), isTrue);
      expect(work.workName, 'Review Kirana');
      expect(work.documentRecoveryMessage, contains('Shop address document'));
      expect(work.documentRecoveryMessage, contains('again'));
      expect(work.noticeMessage, isNull);
      expect(work.pickedProofs, isEmpty);
      expect(work.hasVerifiedWorkspace, isFalse);
      work.dismissMessages();
      expect(work.documentRecoveryMessage, isNotNull);
      expect(
        await work.addProof('shop-front', WorkProofSource.camera),
        isFalse,
      );
      expect(work.documentRecoveryMessage, isNotNull);
      picker.nextPick = _cameraProof();
      expect(await work.addProof('shop-front', WorkProofSource.camera), isTrue);
      expect(work.documentRecoveryMessage, isNull);
      expect(work.pickedProofs['shop-front']?.fileName, 'Camera photo.jpg');
    },
  );

  for (final change in ['account', 'workspace']) {
    test('recovery retry guidance cannot leak into another $change', () async {
      final empty = Completer<WorkPickedProof?>()..complete(null);
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final work = WorkSession(
        pendingProofStore: store,
        proofPicker: _RecoveryPicker(delayedRecovery: empty),
      );
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: true), isTrue);
      expect(work.documentRecoveryMessage, isNotNull);
      if (change == 'account') {
        store.accountScope = 'another-account';
        expect(await work.recoverPendingProof(accountReady: true), isFalse);
      } else {
        work.startAnotherWork();
      }
      expect(work.documentRecoveryMessage, isNull);
    });
  }

  test('expired camera checkpoint cannot restore an old application', () async {
    final store = _PendingProofMemory()
      ..draft = _cameraDraft()
      ..draft!['savedAt'] = DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String();
    final picker = _RecoveryPicker();
    final work = WorkSession(pendingProofStore: store, proofPicker: picker);
    addTearDown(work.dispose);
    expect(await work.recoverPendingProof(accountReady: true), isFalse);
    expect(work.selectedProfile, isNull);
    expect(picker.recoveries, 0);
    expect(store.draft, isNull);
  });

  test(
    'camera recovery failure preserves details and asks for a real replacement',
    () async {
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final work = WorkSession(
        pendingProofStore: store,
        proofPicker: _RecoveryPicker(failRecovery: true),
      );
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: true), isTrue);
      expect(work.workName, 'Review Kirana');
      expect(work.errorMessage, contains('add it again'));
      expect(work.pickedProofs, isEmpty);
      expect(work.hasVerifiedWorkspace, isFalse);
    },
  );

  test(
    'account switch during lost-image recovery discards the old result',
    () async {
      final result = Completer<WorkPickedProof?>();
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final picker = _RecoveryPicker(delayedRecovery: result);
      final work = WorkSession(pendingProofStore: store, proofPicker: picker);
      addTearDown(work.dispose);
      final recovery = work.recoverPendingProof(accountReady: true);
      await Future<void>.delayed(Duration.zero);
      store.accountScope = 'another-account';
      expect(await work.recoverPendingProof(accountReady: true), isFalse);
      result.complete(_cameraProof());
      expect(await recovery, isFalse);
      expect(work.pickedProofs, isEmpty);
      expect(work.workName, isEmpty);
      expect(work.activeWorkspace, isNull);
    },
  );

  test(
    'document launch checkpoints before opening camera and cancellation clears it',
    () async {
      final store = _PendingProofMemory();
      final result = Completer<WorkPickedProof?>();
      final picker = _RecoveryPicker(pendingPick: result);
      final work = WorkSession(pendingProofStore: store, proofPicker: picker)
        ..selectProfile('retailer-grocery')
        ..workName = 'Review Kirana'
        ..authorizedPersonName = 'Review Owner';
      addTearDown(work.dispose);
      final upload = work.addProof('shop-front', WorkProofSource.camera);
      await Future<void>.delayed(Duration.zero);
      expect(store.draft?['name'], 'Review Kirana');
      expect(store.draft?['proofId'], 'shop-front');
      expect(
        store.draft?.keys.any(
          (key) =>
              key.toLowerCase().contains('token') ||
              key.toLowerCase().contains('otp') ||
              key == 'bytes',
        ),
        isFalse,
      );
      expect(picker.picks, 1);
      result.complete(null);
      expect(await upload, isFalse);
      expect(store.draft, isNull);
      expect(work.addedProofs, isEmpty);
    },
  );

  test('first approval retains the submitted legal business name', () async {
    final gateway = ReviewWorkGateway()
      ..reviewResultStatus = WorkRemoteReviewStatus.approved;
    final work = WorkSession(gateway: gateway)
      ..selectProfile('retailer-grocery')
      ..workName = 'Review Kirana'
      ..reviewCaseId = 'review-case';
    addTearDown(work.dispose);
    expect(await work.checkReview(), isTrue);
    expect(work.activeWorkspace?.name, 'Review Kirana');
  });
  test(
    'order selection preserves packing and rider state without advancing another order',
    () {
      final session = WorkSession()..seedVerifiedWorkspace();
      addTearDown(session.dispose);
      WorkspaceOrderRecord order(String id, String stage) =>
          WorkspaceOrderRecord(
            id: id,
            customer: '$id customer',
            items: 'Atta × 1',
            quantities: const {},
            amount: 100,
            payment: 'Paid online',
            source: 'App',
            fulfilment: 'Mool delivery',
            address: '$id Market Road',
            stage: stage,
            needsDelivery: true,
            createdAt: DateTime(2026, 9, 6),
            actionDeadline: DateTime(2026, 9, 6, 10),
          );
      session.workspaceOrders.addAll([
        order('A', 'Preparing'),
        order('B', 'Confirmed'),
      ]);
      expect(session.selectWorkspaceOrder('A'), isTrue);
      session.setWorkspacePackingLine('summary-0', true);
      session.workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
        orderId: 'A',
        partnerName: 'Assigned rider',
        vehicleLabel: 'Bike',
        eta: DateTime(2026, 9, 6, 10),
        stage: 'Accepted',
      );
      expect(session.selectWorkspaceOrder('B'), isTrue);
      expect(session.currentWorkspaceOrderId, 'B');
      expect(session.workspaceOrderStage, 'Confirmed');
      expect(session.workspaceOrderAddress, 'B Market Road');
      expect(session.workspaceDeliveryAssignment, isNull);
      expect(session.workspacePackedProductIds, isEmpty);
      expect(session.workspaceOrders.first.stage, 'Preparing');
      expect(session.selectWorkspaceOrder('A'), isTrue);
      expect(session.workspacePackedProductIds, {'summary-0'});
      expect(session.workspaceDeliveryAssignment?.orderId, 'A');
      session.startNewWorkspaceOrder();
      expect(session.selectWorkspaceOrder('A'), isTrue);
      expect(session.workspacePackedProductIds, {'summary-0'});
      session.workspaceHandoverBusy = true;
      expect(session.selectWorkspaceOrder('B'), isFalse);
      expect(session.currentWorkspaceOrderId, 'A');
      session.workspaceHandoverBusy = false;
      session.startNewWorkspaceOrder();
      session.workspaceOrderQuantities['atta'] = 2;
      expect(session.selectWorkspaceOrder('B'), isFalse);
      expect(session.workspaceOrderQuantities, {'atta': 2});
      expect(session.currentWorkspaceOrderId, isNull);
    },
  );
  for (final channel in WorkContactChannel.values) {
    test('changed $channel invalidates an in-flight OTP and consent', () async {
      final work = WorkSession(gateway: ReviewWorkGateway());
      addTearDown(work.dispose);
      await switch (channel) {
        WorkContactChannel.primaryMobile => work.sendPrimaryMobileOtp(
          '9829012321',
        ),
        WorkContactChannel.email => work.sendContactEmailOtp(
          'asha@example.com',
        ),
        WorkContactChannel.alternateMobile => work.sendAlternateOtp(
          '9876543210',
        ),
      };
      work.setDeclaration(true);
      final confirmation = switch (channel) {
        WorkContactChannel.primaryMobile => work.verifyPrimaryMobileOtp(
          '123456',
        ),
        WorkContactChannel.email => work.verifyContactEmailOtp('123456'),
        WorkContactChannel.alternateMobile => work.verifyAlternateOtp('123456'),
      };
      work.editWorkspaceContact(
        channel,
        channel == WorkContactChannel.email
            ? 'changed@example.com'
            : '9123456789',
      );
      expect(await confirmation, isFalse);
      expect(switch (channel) {
        WorkContactChannel.primaryMobile => work.primaryMobileVerified,
        WorkContactChannel.email => work.contactEmailVerified,
        WorkContactChannel.alternateMobile => work.alternateVerified,
      }, isFalse);
      expect(work.declarationAccepted, isFalse);
      expect(work.errorMessage, contains('Contact changed'));
    });
  }

  test('identity prefill never creates documentary verification', () {
    final work = WorkSession()
      ..hydrateAccountSnapshot(
        const WorkAccountSnapshot(
          displayName: 'Asha Sharma',
          email: 'asha@example.com',
          mobile: '9829012321',
          providerLabel: 'Google',
        ),
      );
    addTearDown(work.dispose);
    expect(work.authorizedPersonName, 'Asha Sharma');
    expect(work.primaryMobileVerified, isFalse);
    expect(work.contactEmailVerified, isFalse);
    expect(work.addedProofs, isEmpty);
    work.savePersonName('Edited name');
    work.hydrateAccountSnapshot(
      const WorkAccountSnapshot(displayName: 'Old name'),
    );
    expect(work.authorizedPersonName, 'Edited name');
    work.setDeclaration(true);
    work.saveBusinessRelationship('Authorized representative');
    expect(work.declarationAccepted, isFalse);
  });

  test(
    'unsupported production request stays a draft without acknowledgement',
    () async {
      final work = WorkSession.production(gateway: UnavailableWorkGateway());
      addTearDown(work.dispose);
      expect(
        await work.sendUnsupportedRequest(
          workspace: 'Furniture repair',
          family: 'Other',
          area: 'Jodhpur',
          otherActivity: 'Furniture repairs',
        ),
        isFalse,
      );
      expect(work.unsupportedRequestSent, isFalse);
      expect(work.unsupportedWorkspace, 'Furniture repair');
      expect(work.noticeMessage, isNull);
      expect(work.errorMessage, contains('cannot be sent yet'));
      expect(work.errorMessage, contains('Your details are still here.'));
      expect(work.errorMessage, isNot(contains('saved on this device')));
      expect(work.unsupportedFamily, 'Other');
      expect(work.unsupportedArea, 'Jodhpur');
      expect(work.unsupportedOtherActivity, 'Furniture repairs');
    },
  );
  test('production offer cannot claim publication without acknowledgement', () {
    final work = WorkSession.production(gateway: UnavailableWorkGateway());
    addTearDown(work.dispose);
    work.addWorkspaceOffer(
      title: 'Monthly essentials',
      detail: 'Save on selected groceries.',
      validUntil: DateTime.now().add(const Duration(days: 7)),
      productId: 'oil-fortune-1l',
      orderCap: 50,
    );
    expect(work.workspaceOffers, isEmpty);
    expect(work.noticeMessage, isNull);
    expect(work.errorMessage, contains('not available yet'));
  });

  test('release app defaults to the fail-closed production Work session', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('workSession: WorkSession.production(),'));
  });

  test('freelance fixtures expose complete funded role and poster data', () {
    const requiredIds = {
      'quick-delivery-biker',
      'user-acquisition-onboarding',
      'sales-specialist',
      'content-creator',
      'social-content-creator',
      'retailer-onboarding-specialist',
      'manufacturer-onboarding-specialist',
      'wholesaler-onboarding-specialist',
      'rider-onboarding-specialist',
      'taxi-operator-onboarding-specialist',
      'bike-rider-onboarding-specialist',
      'bus-operator-onboarding-specialist',
      'doctor-onboarding-specialist',
      'wholesale-sales-specialist',
      'bulk-sales-specialist',
    };

    expect(workOpportunities.map((item) => item.id), containsAll(requiredIds));
    expect(
      workOpportunities.map((item) => item.posterType).toSet(),
      containsAll(WorkOpportunityPosterType.values),
    );
    for (final opportunity in workOpportunities) {
      expect(opportunity.kind, contains('Freelance'));
      expect(opportunity.publisher, isNotEmpty);
      expect(opportunity.publisherType, isNotEmpty);
      expect(opportunity.qualificationHeadline, isNotEmpty);
      expect(opportunity.city, isNotEmpty);
      expect(opportunity.area, isNotEmpty);
      expect(opportunity.paymentAmount, isNotEmpty);
      expect(opportunity.monthlyPayment, isNotEmpty);
      expect(opportunity.aboutRole, isNotEmpty);
      expect(opportunity.whatYoullDo, isNotEmpty);
      expect(opportunity.whoYouAre, isNotEmpty);
      expect(opportunity.niceToHave, isNotEmpty);
      expect(opportunity.whyJoin, isNotEmpty);
      expect(opportunity.funded, isTrue);
      expect(opportunity.peopleNeeded, greaterThan(0));
      expect(opportunity.peopleJoined, greaterThanOrEqualTo(0));
      expect(opportunity.applicationsInProgress, greaterThanOrEqualTo(0));
      expect(
        opportunity.peopleJoined + opportunity.applicationsInProgress,
        lessThanOrEqualTo(opportunity.peopleNeeded),
      );
      expect(
        opportunity.positionsRemaining,
        opportunity.peopleNeeded -
            opportunity.peopleJoined -
            opportunity.applicationsInProgress,
      );
      expect(
        opportunity.finalDeadline,
        matches(RegExp(r'^\d{2} \w{3} \d{4}$')),
      );
    }
  });

  test('Workspace chooser covers the current business and work choices', () {
    expect(
      workProfiles.map((profile) => profile.label),
      containsAll(const [
        'Grocery / Kirana Shop',
        'Speciality Retail Shop',
        'Wholesaler / Distributor',
        'Manufacturer / Supplier',
        'Restaurant / Café',
        'Cloud Kitchen / Tiffin',
        'Clinic / Doctor',
        'Pharmacy',
        'Salon / Wellness',
        'Bike Travel Provider',
        'Auto Travel Provider',
        'Cab Travel Provider',
        'Bus Travel Provider',
        'Quick Delivery Biker',
        'Wholesale Fleet Delivery',
        'Bulk Delivery Fleet',
        'Creator',
        'Freelancer / Job Seeker',
      ]),
    );
    expect(
      workProfiles.map((profile) => profile.id),
      isNot(containsAll(const ['service-provider', 'captain', 'fleet'])),
    );
    expect(
      workProfiles
          .where((profile) => profile.familyId == 'travel')
          .map((profile) => profile.label),
      [
        'Bike Travel Provider',
        'Auto Travel Provider',
        'Cab Travel Provider',
        'Bus Travel Provider',
      ],
    );
    expect(
      workProfiles
          .where((profile) => profile.familyId == 'delivery')
          .map((profile) => profile.label),
      [
        'Quick Delivery Biker',
        'Wholesale Fleet Delivery',
        'Bulk Delivery Fleet',
      ],
    );
    expect(
      workProfiles.map((profile) => profile.gstMatchCategory).toSet(),
      containsAll(WorkGstMatchCategory.values),
    );
    for (final profile in workProfiles) {
      expect(profile.verificationDocuments, isNotEmpty);
      expect(
        profile.verificationDocuments.any(
          (document) => document.importance == WorkDocumentImportance.required,
        ),
        isTrue,
      );
      final gst = profile.verificationDocuments.singleWhere(
        (document) => document.title == 'GST registration certificate',
      );
      final payoutBank = profile.verificationDocuments.singleWhere(
        (document) => document.title == 'Payout bank account proof',
      );
      expect(payoutBank.importance, WorkDocumentImportance.required);
      expect(payoutBank.detail, contains('cancelled cheque'));
      expect(payoutBank.detail, contains('bank statement PDF'));
      expect(gst.importance, WorkDocumentImportance.ifApplicable);
      expect(gst.detail, contains('Required when GST registration applies'));
      expect(gst.detail.toLowerCase(), isNot(contains('turnover')));
      expect(gst.detail, isNot(matches(RegExp(r'₹|lakh|crore'))));
      expect(
        profile.verificationDocuments.map((document) => document.title).toSet(),
        hasLength(profile.verificationDocuments.length),
      );

      final session = WorkSession()
        ..selectFamily(profile.familyId)
        ..selectProfile(profile.id);
      addTearDown(session.dispose);
      expect(session.selectedGstMatchCategory, profile.gstMatchCategory);
      expect(
        session.selectedGstChecklistItem?.importance,
        WorkDocumentImportance.ifApplicable,
      );
      expect(
        session.selectedWorkspaceDocuments.map((document) => document.label),
        profile.verificationDocuments.map((document) => document.title),
      );
      expect(
        session.selectedWorkspaceDocuments.map((document) => document.label),
        contains('Payout bank account proof'),
      );
      expect(
        session.selectedWorkspaceDocuments
            .singleWhere(
              (document) => document.label == 'Payout bank account proof',
            )
            .id,
        'payout-bank-account',
      );
    }
    final gstProof = workProofs.singleWhere((proof) => proof.id == 'gst');
    expect(gstProof.importance, WorkDocumentImportance.ifApplicable);
    expect(gstProof.required, isFalse);

    expect(
      workWorkspaceBenefits.keys.toSet(),
      workProfiles.map((profile) => profile.id).toSet(),
    );
    for (final profileId in workWorkspaceBenefits.keys) {
      final content = workWorkspaceBenefitFor(profileId);
      expect(content.problem.trim(), isNotEmpty);
      expect(content.preview.trim(), isNotEmpty);
      final expectedCount = switch (profileId) {
        'retailer-grocery' || 'retailer-speciality' => 25,
        'wholesaler' || 'manufacturer' => 12,
        _ => 4,
      };
      expect(content.benefits, hasLength(expectedCount), reason: profileId);
      if (content.hasTopics) {
        expect(content.subtitle, isNotEmpty);
        expect(
          content.benefits.map((point) => point.action).toSet(),
          hasLength(expectedCount),
        );
        expect(
          content.benefits.map((point) => point.group).toSet(),
          workWorkspaceGrowthTopics.toSet(),
        );
      }
      expect(content.difference.trim(), isNotEmpty);
      final visibleCopy = [
        content.problem,
        content.preview,
        content.difference,
        ...content.benefits.expand(
          (benefit) => [
            benefit.title,
            benefit.detail,
            benefit.action,
            benefit.group,
          ],
        ),
      ].join(' ').toLowerCase();
      expect(visibleCopy, isNot(matches(RegExp(r'\bactor\b'))));
      expect(visibleCopy, isNot(contains('user type')));
      expect(visibleCopy, isNot(contains('internal')));
    }
    const expectedRetailActions = {
      'Publish products',
      'Send store link',
      'Collect at store',
      'Promote store',
      'Create basket',
      'Send offers',
      'Clear stock',
      'Send bill',
      'Restock',
      'Buy Direct',
      'Group Bulk Buying',
      'Track stock',
      'Receive goods',
      'Request stock',
      'Collect dues',
      'View statement',
      'Settle',
      'Get tax help',
      'Check eligibility',
      'Add products',
      'Pack orders',
      'Arrange delivery',
      'Post requirement',
      'Review returns',
      'Check earnings',
    };
    for (final id in ['retailer-grocery', 'retailer-speciality']) {
      expect(
        workWorkspaceBenefitFor(
          id,
        ).benefits.map((point) => point.action).toSet(),
        expectedRetailActions,
      );
    }
    expect(
      workWorkspaceBenefitFor(
        'retailer-speciality',
      ).benefits.singleWhere((point) => point.action == 'Create basket').detail,
      contains('product bundle'),
    );
    expect(
      workWorkspaceBenefitFor(
        'manufacturer',
      ).benefits.singleWhere((point) => point.action == 'Create Offer').detail,
      contains('disclosed service charges'),
    );
  });

  test('opportunity filters combine city, area and exact six-digit PIN', () {
    final session = WorkSession();
    addTearDown(session.dispose);

    session.setOpportunityLocationFilters(
      city: 'Jodhpur',
      area: 'Sardarpura',
      pincode: '342003',
    );
    expect(session.activeOpportunityFilterCount, 3);
    expect(session.filteredOpportunities.map((item) => item.id), [
      'quick-delivery-biker',
      'user-acquisition-onboarding',
    ]);

    session.setOpportunityLocationFilters(pincode: '34200');
    expect(session.filteredOpportunities, isEmpty);
    session.clearOpportunityFilters();
    expect(session.activeOpportunityFilterCount, 0);
    expect(session.filteredOpportunities, isNotEmpty);
  });

  test(
    'application and withdrawal remain bound to the exact opportunity',
    () async {
      final gateway = ReviewWorkGateway();
      final session = WorkSession(gateway: gateway);
      addTearDown(session.dispose);

      session.openOpportunity('content-creator');
      expect(await session.applySelectedOpportunity(), isTrue);
      final contentApplicationId = session.applicationId;
      expect(contentApplicationId, contains('CONTENT-CREATOR'));
      expect(session.appliedOpportunityId, 'content-creator');

      session.openOpportunity('social-content-creator');
      expect(session.applicationId, isNull);
      expect(await session.applySelectedOpportunity(), isTrue);
      final socialApplicationId = session.applicationId;
      expect(socialApplicationId, isNot(contentApplicationId));

      session.openOpportunity('content-creator');
      expect(session.applicationId, contentApplicationId);
      expect(await session.withdrawSelectedOpportunity(), isTrue);
      expect(session.withdrawnApplicationId, contentApplicationId);
      expect(session.applicationId, isNull);
      expect(
        session.applicationIdsByOpportunity['social-content-creator'],
        socialApplicationId,
      );
      expect(gateway.withdrawalCalls, 1);
    },
  );

  test(
    'failed withdrawal remains active and gives a retryable truth',
    () async {
      final gateway = ReviewWorkGateway()..failWithdrawal = true;
      final session = WorkSession(gateway: gateway);
      addTearDown(session.dispose);

      session.openOpportunity('content-creator');
      expect(await session.applySelectedOpportunity(), isTrue);
      final applicationId = session.applicationId;
      expect(await session.withdrawSelectedOpportunity(), isFalse);
      expect(session.applicationId, applicationId);
      expect(session.errorMessage, contains('remains active'));
      expect(await session.withdrawSelectedOpportunity(), isTrue);
      expect(gateway.withdrawalCalls, 2);
    },
  );

  test(
    'authenticated Workspace operations use exact bodies and App Check modes',
    () async {
      final transport = _RecordingTransport([
        _ok(const {}),
        _ok(const {}),
        _ok({'caseId': 'wp-1', 'status': 'pending', 'plan': 'free'}),
        _ok({
          'caseId': 'wp-1',
          'status': 'approved',
          'plan': 'free',
          'workspaceId': 'workspace-1',
        }),
        _ok({'gstReference': 'gst-1'}),
        _ok({'workspaceId': 'workspace-1', 'status': 'live', 'plan': 'free'}),
      ]);
      final credentials = _RecordingCredentials();
      final gateway = AuthenticatedWorkGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        credentials: credentials,
        transport: transport,
        random: Random(1),
      );

      await gateway.sendContactOtp(
        channel: WorkContactChannel.primaryMobile,
        value: '9829012321',
      );
      await gateway.verifyContactOtp(
        channel: WorkContactChannel.primaryMobile,
        value: '9829012321',
        code: '123456',
      );

      const profileSubmission = WorkProfileSubmission(
        familyId: 'products-trade',
        profileId: 'retailer-grocery',
        name: 'Mahadev Fresh Mart',
        area: 'Sardarpura, Jodhpur',
        primaryActivity: 'Grocery and household products',
        proofReferences: {
          'personal-kyc': 'account-kyc',
          'shop-front': 'proof-shop',
          'owner-authority': 'proof-owner',
        },
        primaryMobile: '9829012321',
        email: 'asha@example.com',
        connectedProvider: 'Google',
        connectedProviderAccount: 'asha@example.com',
        alternateMobileVerified: false,
        idempotencyKey: 'work-submit-001',
      );
      final submitted = await gateway.submitProfile(profileSubmission);
      final reviewed = await gateway.checkReview('wp-1');
      expect(
        await gateway.submitGst('wp-1', '08ABCDE1234F1Z5', 'proof-gst-1'),
        'gst-1',
      );
      await gateway.finishSetup(
        workspaceId: 'workspace-1',
        quantity: 24,
        buyPrice: 48,
        sellPrice: 55,
        homeDelivery: true,
        storeCollection: false,
      );

      expect(submitted.status, WorkRemoteReviewStatus.pending);
      expect(submitted.plan, 'free');
      expect(reviewed.status, WorkRemoteReviewStatus.approved);
      expect(reviewed.workspaceId, 'workspace-1');
      expect(transport.bodies.map((body) => body['operation']), [
        'sendWorkspaceContactOtp',
        'verifyWorkspaceContactOtp',
        'submitProfile',
        'reviewStatus',
        'submitGst',
        'finishRetailerSetup',
      ]);
      expect(transport.bodies.first, containsPair('channel', 'primary_mobile'));
      expect(transport.bodies[1], containsPair('code', '123456'));
      expect(transport.bodies[2]['idempotencyKey'], 'work-submit-001');
      expect(transport.bodies[2], containsPair('email', 'asha@example.com'));
      expect(transport.bodies.last, containsPair('quantity', 24));
      expect(credentials.modes, [
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.standard,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
      ]);
    },
  );

  test(
    'production correction fails closed until backend support exists',
    () async {
      final transport = _RecordingTransport([]);
      final gateway = AuthenticatedWorkGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        credentials: _RecordingCredentials(),
        transport: transport,
        random: Random(11),
      );

      await expectLater(
        gateway.submitCorrection(
          'wp-1',
          const WorkProfileSubmission(
            familyId: 'products-trade',
            profileId: 'retailer-grocery',
            name: 'Mahadev Fresh Mart',
            area: 'Jodhpur',
            primaryActivity: 'Grocery retail',
            proofReferences: {'personal-kyc': 'account-kyc'},
            primaryMobile: '9829012321',
            email: 'asha@example.com',
            connectedProvider: 'Google',
            connectedProviderAccount: 'asha@example.com',
            alternateMobileVerified: false,
            idempotencyKey: 'work-submit-001',
          ),
        ),
        throwsA(
          isA<WorkGatewayException>().having(
            (error) => error.message,
            'message',
            contains('not available yet'),
          ),
        ),
      );
      expect(transport.bodies, isEmpty);
    },
  );

  test(
    'authenticated withdrawal sends both exact identities as a mutation',
    () async {
      final transport = _RecordingTransport([_ok(const {})]);
      final credentials = _RecordingCredentials();
      final gateway = AuthenticatedWorkGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        credentials: credentials,
        transport: transport,
        random: Random(7),
      );

      await gateway.withdraw('application-42', 'content-creator');

      expect(transport.bodies.single, {
        'operation': 'withdrawOpportunity',
        'applicationId': 'application-42',
        'opportunityId': 'content-creator',
      });
      expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse]);
    },
  );

  test('store operations use exact authenticated mutation contracts', () async {
    final transport = _RecordingTransport([
      _ok(const {}),
      _ok({'paymentReference': 'PAY-GROUP-1'}),
      _ok({'reference': 'WORK-1'}),
      _ok({'reference': 'SET-1', 'acceptedAmount': 800}),
      _ok(const {}),
      _ok({
        'partnerName': 'Mool Delivery Partner',
        'vehicleLabel': 'RJ19 AB 1234',
        'eta': '2026-09-03T12:15:00.000Z',
        'stage': 'Assigned',
      }),
    ]);
    final credentials = _RecordingCredentials();
    final gateway = AuthenticatedWorkGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
      ),
      credentials: credentials,
      transport: transport,
      random: Random(19),
    );

    await gateway.saveOperationalState(
      const WorkOperationalSnapshot(
        workspaceId: 'workspace-1',
        reason: 'catalogue-updated',
        state: {
          'storeState': 'open',
          'catalogue': [
            {'sku': 'ATTA-5KG', 'sellingPrice': 275, 'stock': 10},
          ],
        },
        idempotencyKey: 'OPS-1',
      ),
    );
    expect(
      await gateway.createGroupBuy(
        const WorkGroupBuySubmission(
          workspaceId: 'workspace-1',
          values: {
            'productName': 'Premium red onion',
            'targetQuantity': 1000,
            'confirmationAmount': 3920,
          },
          idempotencyKey: 'GROUP-1',
        ),
      ),
      'PAY-GROUP-1',
    );
    expect(
      await gateway.createPaidRequirement(
        const WorkPaidRequirementSubmission(
          workspaceId: 'workspace-1',
          values: {
            'position': 'Evening packing assistant',
            'peopleNeeded': 2,
            'paymentAmount': 600,
          },
          idempotencyKey: 'WORK-1',
        ),
      ),
      'WORK-1',
    );
    final settlement = await gateway.requestSettlement(
      workspaceId: 'workspace-1',
      amount: 800,
      idempotencyKey: 'SETTLEMENT-1',
    );
    await gateway.verifyOrderHandover(
      workspaceId: 'workspace-1',
      orderId: 'order-1',
      otp: '123456',
      idempotencyKey: 'HANDOVER-1',
    );
    final delivery = await gateway.requestDeliveryAssignment(
      workspaceId: 'workspace-1',
      orderId: 'order-1',
      address: '21 Residency Road, Jodhpur',
      idempotencyKey: 'DELIVERY-1',
    );

    expect(settlement.reference, 'SET-1');
    expect(settlement.acceptedAmount, 800);
    expect(delivery.partnerName, 'Mool Delivery Partner');
    expect(delivery.eta.toUtc().toIso8601String(), '2026-09-03T12:15:00.000Z');
    expect(transport.bodies.map((body) => body['operation']), [
      'saveWorkspaceOperations',
      'createWorkspaceGroupBuy',
      'createWorkspacePaidRequirement',
      'requestWorkspaceSettlement',
      'verifyWorkspaceOrderHandover',
      'requestWorkspaceDelivery',
    ]);
    expect(transport.bodies.first['state'], isA<Map<String, Object?>>());
    expect(transport.bodies[1]['values'], containsPair('targetQuantity', 1000));
    expect(
      transport.bodies[2]['values'],
      containsPair('position', 'Evening packing assistant'),
    );
    expect(transport.bodies[3], containsPair('amount', 800));
    expect(transport.bodies[4], containsPair('otp', '123456'));
    expect(
      transport.bodies.last,
      containsPair('address', '21 Residency Road, Jodhpur'),
    );
    expect(
      credentials.modes,
      List<SocialAppCheckTokenMode>.filled(
        6,
        SocialAppCheckTokenMode.limitedUse,
      ),
    );
  });

  test(
    'proof document is privately uploaded and confirmed before acceptance',
    () async {
      final transport = _RecordingTransport([
        _ok({
          'uploadId': '00000000-0000-4000-8000-000000000001',
          'uploadUrl': 'https://storage.googleapis.com/private-upload',
          'expiresAt': '2099-08-29T09:05:00.000Z',
          'requiredHeaders': {
            'content-type': 'application/pdf',
            'content-length': '8',
          },
        }),
        _ok({'proofReference': 'proof-confirmed-1'}),
      ]);
      final upload = _RecordingProofUpload();
      final gateway = AuthenticatedWorkGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        credentials: _RecordingCredentials(),
        transport: transport,
        proofUploadTransport: upload,
        random: Random(2),
      );
      final proof = WorkPickedProof(
        fileName: 'shop-front.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List.fromList('%PDF-1.7'.codeUnits),
      );

      expect(await gateway.saveProof('shop-front', proof), 'proof-confirmed-1');
      expect(transport.bodies.map((body) => body['operation']), [
        'prepareProofUpload',
        'confirmProofUpload',
      ]);
      expect(upload.puts, 1);
      expect(upload.bytes, proof.bytes);
      expect(
        transport.bodies.last['uploadId'],
        '00000000-0000-4000-8000-000000000001',
      );
    },
  );

  test('pending review never invents a verified Workspace', () async {
    final session = WorkSession.production(gateway: _PendingGateway())
      ..selectedProfile = workProfiles.first
      ..workName = 'Mahadev Fresh Mart'
      ..workArea = 'Sardarpura, Jodhpur'
      ..reviewCaseId = 'wp-1'
      ..reviewStage = WorkReviewStage.gstPending;
    addTearDown(session.dispose);

    expect(await session.checkReview(), isFalse);
    expect(session.reviewStage, WorkReviewStage.gstPending);
    expect(session.activeWorkspace, isNull);
    expect(session.noticeMessage, isNull);
    expect(session.remoteReviewStatus, WorkRemoteReviewStatus.pending);
  });

  test('rejected review cannot silently erase or restart its case', () async {
    final session = WorkSession.production(gateway: _RejectedGateway())
      ..selectedProfile = workProfiles.first
      ..selectedFamilyId = workProfiles.first.familyId
      ..workName = 'Mahadev Fresh Mart'
      ..workArea = 'Sardarpura, Jodhpur'
      ..primaryActivity = 'Grocery retail'
      ..reviewCaseId = 'wp-rejected'
      ..reviewStage = WorkReviewStage.gstPending;
    addTearDown(session.dispose);

    expect(await session.checkReview(), isFalse);
    expect(session.remoteReviewStatus, WorkRemoteReviewStatus.rejected);
    expect(session.reviewReason, 'Shop-front proof is unclear.');
    expect(session.activeWorkspace, isNull);

    session.reviseRejectedProfile();
    expect(session.reviewCaseId, 'wp-rejected');
    expect(session.reviewStage, WorkReviewStage.gstPending);
    expect(session.remoteReviewStatus, WorkRemoteReviewStatus.rejected);
    expect(session.reviewReason, 'Shop-front proof is unclear.');
    expect(session.beginReviewCorrection(), isFalse);
    expect(session.workName, 'Mahadev Fresh Mart');
    expect(session.workArea, 'Sardarpura, Jodhpur');
  });

  test(
    'authoritative Workspace state is restored after a fresh app session',
    () async {
      final session = WorkSession.production(gateway: _LoadedGateway());
      addTearDown(session.dispose);

      await session.loadInitialWorkspaceState();

      expect(session.activeWorkspace?.id, 'workspace-1');
      expect(session.activeWorkspace?.name, 'Mahadev Fresh Mart');
      expect(session.activeWorkspace?.profileLabel, 'Grocery / Kirana Shop');
      expect(session.reviewStage, WorkReviewStage.live);
      expect(session.subscriptionPlan, 'free');
    },
  );

  test('missing production endpoint fails truthfully', () async {
    final gateway = buildWorkGateway();
    expect(gateway, isA<UnavailableWorkGateway>());
    await expectLater(
      gateway.loadFeed(),
      throwsA(
        isA<WorkGatewayException>().having(
          (error) => error.retryable,
          'retryable',
          isTrue,
        ),
      ),
    );
  });
}

Map<String, Object?> _cameraDraft() => {
  'version': 1,
  'savedAt': DateTime.now().toUtc().toIso8601String(),
  'profileId': 'retailer-grocery',
  'proofId': 'shop-front',
  'source': 'camera',
  'personName': 'Review Owner',
  'relationship': 'Owner',
  'name': 'Review Kirana',
  'area': 'Review market',
  'activity': 'Groceries',
  'phone': '9876543210',
  'email': 'review@example.com',
  'phoneConfirmed': true,
  'emailConfirmed': true,
  'proofs': {'unrelated-proof': 'must-not-restore'},
};

WorkPickedProof _cameraProof() => WorkPickedProof(
  fileName: 'Camera photo.jpg',
  contentType: 'image/jpeg',
  bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
);

class _PdfReplacementGateway extends ReviewWorkGateway {
  int saves = 0;
  final started = Completer<void>();
  final result = Completer<String>();

  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) {
    saves++;
    if (!started.isCompleted) started.complete();
    return result.future;
  }
}

class _DeferredReviewGateway extends ReviewWorkGateway {
  final result = Completer<WorkReviewResult>();
  @override
  Future<WorkReviewResult> checkReview(String caseId) => result.future;
}

class _DeferredSubmissionGateway extends ReviewWorkGateway {
  Completer<WorkReviewResult> result = Completer<WorkReviewResult>();
  @override
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission profile) =>
      result.future;
  @override
  Future<WorkReviewResult> submitCorrection(
    String caseId,
    WorkProfileSubmission profile,
  ) => result.future;
}

class _AccountSettlementGateway extends ReviewWorkGateway {
  final results = <Completer<WorkSettlementResult>>[];
  @override
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  }) {
    final pending = Completer<WorkSettlementResult>();
    results.add(pending);
    return pending.future;
  }
}

class _ApplicationFeedGateway extends ReviewWorkGateway {
  _ApplicationFeedGateway()
    : super(initialReviewStatus: WorkRemoteReviewStatus.pending);
  List<WorkReviewResult> records = [];
  @override
  Future<List<WorkReviewResult>> loadFeed() async => List.unmodifiable(records);
}

class _MultiStoreFeedGateway extends ReviewWorkGateway {
  @override
  Future<List<WorkReviewResult>> loadFeed() async => const [
    WorkReviewResult(
      caseId: 'a',
      status: WorkRemoteReviewStatus.live,
      plan: 'free',
      workspaceId: 'store-a',
      profileId: 'retailer-grocery',
      name: 'First store',
      area: 'Jodhpur',
    ),
    WorkReviewResult(
      caseId: 'b',
      status: WorkRemoteReviewStatus.live,
      plan: 'free',
      workspaceId: 'store-b',
      profileId: 'retailer-speciality',
      name: 'Second store',
      area: 'Jaipur',
    ),
  ];
}

class _DeferredFeedGateway extends ReviewWorkGateway {
  final result = Completer<List<WorkReviewResult>>();
  @override
  Future<List<WorkReviewResult>> loadFeed() => result.future;
}

class _PendingProofMemory implements WorkPendingProofStore {
  @override
  String? accountScope = 'review-account';
  String? savedScope = 'review-account';
  Map<String, Object?>? draft;
  int reads = 0;
  @override
  Future<Map<String, Object?>?> read(String scope) async {
    reads++;
    return scope == accountScope && scope == savedScope ? draft : null;
  }

  @override
  Future<void> save(String scope, Map<String, Object?> value) async {
    savedScope = scope;
    draft = Map.of(value);
  }

  @override
  Future<void> clear(String scope) async {
    if (scope == savedScope && scope == accountScope) draft = null;
  }
}

class _DelayedDraftMemory extends _PendingProofMemory {
  final readResult = Completer<Map<String, Object?>?>();
  @override
  Future<Map<String, Object?>?> read(String scope) => readResult.future;
}

class _SlowWriteDraftMemory extends _PendingProofMemory {
  final firstWrite = Completer<void>();
  int writes = 0;
  @override
  Future<void> save(String scope, Map<String, Object?> value) async {
    writes++;
    if (writes == 1) await firstWrite.future;
    await super.save(scope, value);
  }
}

class _FailedDraftMemory extends _PendingProofMemory {
  @override
  Future<void> save(String scope, Map<String, Object?> value) async =>
      throw StateError('Storage unavailable');
}

class _BoundedProofFile extends XFile {
  _BoundedProofFile({
    required int length,
    this.chunks = const [],
    this.failRead = false,
  }) : reportedLength = length,
       super('business-proof.pdf');
  final int reportedLength;
  final List<Uint8List> chunks;
  final bool failRead;
  int opens = 0, emitted = 0;
  @override
  String get name => 'business-proof.pdf';
  @override
  Future<int> length() async => reportedLength;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) async* {
    opens++;
    if (failRead) {
      throw const FileSystemException('Could not read selected file');
    }
    for (final chunk in chunks) {
      emitted++;
      yield chunk;
    }
  }

  @override
  Future<Uint8List> readAsBytes() =>
      throw StateError('Unbounded read must not run');
}

class _RecoveryPicker implements WorkRecoverableProofPicker {
  _RecoveryPicker({
    this.failRecovery = false,
    this.pendingPick,
    this.delayedRecovery,
  });
  final bool failRecovery;
  final Completer<WorkPickedProof?>? pendingPick, delayedRecovery;
  WorkPickedProof? nextPick;
  int recoveries = 0, picks = 0;
  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) async {
    picks++;
    return pendingPick == null ? nextPick : await pendingPick!.future;
  }

  @override
  Future<WorkPickedProof?> recover(WorkProofSource source) async {
    recoveries++;
    if (failRecovery) throw const WorkGatewayException('Please add it again.');
    return delayedRecovery == null
        ? _cameraProof()
        : await delayedRecovery!.future;
  }
}

class _PendingGateway extends ReviewWorkGateway {
  @override
  Future<WorkReviewResult> checkReview(String caseId) async => WorkReviewResult(
    caseId: caseId,
    status: WorkRemoteReviewStatus.pending,
    plan: 'free',
  );
}

class _RejectedGateway extends ReviewWorkGateway {
  @override
  Future<WorkReviewResult> checkReview(String caseId) async => WorkReviewResult(
    caseId: caseId,
    status: WorkRemoteReviewStatus.rejected,
    plan: 'free',
    reason: 'Shop-front proof is unclear.',
  );
}

class _LoadedGateway extends ReviewWorkGateway {
  @override
  Future<List<WorkReviewResult>> loadFeed() async => const [
    WorkReviewResult(
      caseId: 'wp-1',
      status: WorkRemoteReviewStatus.live,
      plan: 'free',
      workspaceId: 'workspace-1',
      profileId: 'retailer-grocery',
      name: 'Mahadev Fresh Mart',
      area: 'Sardarpura, Jodhpur',
      primaryActivity: 'Grocery and household products',
    ),
  ];
}

class _RecordingCredentials implements SocialContentCredentials {
  final List<SocialAppCheckTokenMode> modes = [];

  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'app-check-test';
  }

  @override
  Future<String> firebaseIdToken() async => 'firebase-id-test';
}

class _RecordingTransport implements SocialContentTransport {
  _RecordingTransport(this.responses);

  final List<SocialContentResponse> responses;
  final List<Map<String, Object?>> bodies = [];

  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    expect(endpoint.path, '/moolSocialWorkspace');
    expect(headers['authorization'], 'Bearer firebase-id-test');
    bodies.add(Map<String, Object?>.from(body));
    return responses.removeAt(0);
  }
}

class _RecordingProofUpload implements WorkProofUploadTransport {
  int puts = 0;
  Uint8List? bytes;

  @override
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  }) async {
    puts += 1;
    this.bytes = bytes;
    expect(url.host, 'storage.googleapis.com');
    expect(headers['content-type'], 'application/pdf');
  }
}

class _DeviceReviewIdentityGateway extends ReviewWorkGateway {
  _DeviceReviewIdentityGateway()
    : super(initialReviewStatus: WorkRemoteReviewStatus.pending);

  @override
  bool get deviceReviewControlsEnabled => true;
}

SocialContentResponse _ok(Object? data) => SocialContentResponse(
  statusCode: 200,
  body: jsonEncode({'ok': true, 'data': data}),
);
