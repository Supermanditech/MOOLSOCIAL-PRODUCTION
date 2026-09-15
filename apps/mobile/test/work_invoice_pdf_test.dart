import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_document_preview.dart';
import 'package:moolsocial/features/work/work_invoice_pdf.dart';
import 'package:moolsocial/features/work/screens/work_invoice_pdf_screen.dart';

WorkInvoicePdfRequest request({int count = 2}) => WorkInvoicePdfRequest(
  accountId: 'review-account',
  storeId: 'review-store',
  invoice: WorkspaceCustomerInvoice(
    id: 'INV-2026-0012',
    orderId: 'order-review',
    customer: '9000000000',
    sellerName: 'Annapurna Stores',
    billingDetails: const WorkspaceBillingDetails(
      business: true,
      businessName: 'Sunrise Cafe',
      name: 'Asha',
      address: '12 Market Road',
    ),
    items: '$count products',
    amount: count * 120,
    payment: 'Cash',
    issuedAt: DateTime(2026, 9, 15),
  ),
  items: List.generate(
    count,
    (i) => WorkspaceOrderItemSnapshot(
      productId: 'product-$i',
      name: i.isEven ? 'Basmati rice' : 'Whole wheat flour',
      pack: '1 kg',
      quantity: 2,
      unitPricePaise: 6000,
      lineTotalPaise: 12000,
    ),
  ),
  paymentStatus: 'Payment: Cash (review data)',
);
WorkInvoicePdfDocument document({String? identity}) => WorkInvoicePdfDocument(
  identity: identity ?? request().identity,
  fileName: request().invoice.pdfFileName,
  bytes: Uint8List.fromList(utf8.encode('%PDF-1.7\nfixture')),
  reviewOnly: true,
);

class Source implements WorkInvoicePdfSource {
  Source(this.callback);
  final Future<WorkInvoicePdfDocument> Function() callback;
  int calls = 0;
  @override
  Future<WorkInvoicePdfDocument> load(WorkInvoicePdfRequest request) {
    calls++;
    return callback();
  }
}

class Actions implements WorkInvoicePdfActions {
  int saves = 0, shares = 0;
  WorkInvoicePdfDocument? received;
  Future<WorkPdfActionResult> Function() result = () async =>
      WorkPdfActionResult.completed;
  @override
  Future<WorkPdfActionResult> save(WorkInvoicePdfDocument document) {
    saves++;
    received = document;
    return result();
  }

  @override
  Future<WorkPdfActionResult> share(
    WorkInvoicePdfDocument document,
    Rect origin,
  ) {
    shares++;
    received = document;
    return result();
  }
}

Future<WorkPdfPage> page(
  WorkInvoicePdfDocument doc,
  int index,
) async => WorkPdfPage(
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=',
  ),
  index: index,
  pageCount: 2,
  width: 1,
  height: 1,
);
Future<void> open(
  WidgetTester tester,
  WorkInvoicePdfSource source, {
  Actions? actions,
  ValueNotifier<bool>? scope,
  bool failRender = false,
}) async {
  final current = scope ?? ValueNotifier(true);
  if (scope == null) addTearDown(current.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: WorkInvoicePdfScreen(
        request: request(),
        source: source,
        actions: actions ?? Actions(),
        isCurrent: () => current.value,
        scopeChanges: current,
        renderPage: failRender
            ? (_, _) async => throw Exception('renderer')
            : page,
      ),
    ),
  );
  await tester.pump();
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('APK source selection exposes only the requested review mode', (
    tester,
  ) async {
    final source = createWorkInvoicePdfSource();
    if (const bool.fromEnvironment('EXPECT_REVIEW_PDF')) {
      final result = await tester.runAsync(() => source.load(request()));
      expect(result, isNotNull);
      expect(result!.reviewOnly, isTrue);
      expect(result.fileName, request().invoice.pdfFileName);
    } else {
      await expectLater(
        source.load(request()),
        throwsA(isA<WorkInvoicePdfException>()),
      );
    }
  });
  testWidgets(
    'unsupported text fails clearly rather than losing customer characters',
    (tester) async {
      final base = request();
      final unsupported = WorkInvoicePdfRequest(
        accountId: base.accountId,
        storeId: base.storeId,
        invoice: base.invoice,
        items: base.items,
        paymentStatus: 'नमस्ते',
      );
      await tester.runAsync(() async {
        await expectLater(
          const LocalReviewWorkInvoicePdfSource().load(unsupported),
          throwsA(
            isA<WorkInvoicePdfException>().having(
              (e) => e.message,
              'message',
              contains('cannot display some invoice characters'),
            ),
          ),
        );
      });
    },
  );
  test(
    'local generator produces bounded single and multipage review PDFs',
    () async {
      for (final count in [2, 80]) {
        final result = await const LocalReviewWorkInvoicePdfSource().load(
          request(count: count),
        );
        expect(result.reviewOnly, isTrue);
        expect(
          result.fileName,
          'Annapurna-Stores_Sunrise-Cafe_INV-2026-0012.pdf',
        );
        expect(result.bytes.length, greaterThan(1000));
        expect(() => result.bytes[0] = 0, throwsUnsupportedError);
        const output = String.fromEnvironment('PDF_REVIEW_OUTPUT');
        if (output.isNotEmpty) {
          final dir = Directory(output)..createSync(recursive: true);
          File(
            '${dir.path}/${count == 2 ? result.fileName : 'multipage-review.pdf'}',
          ).writeAsBytesSync(result.bytes);
        }
      }
    },
  );
  test('rejects invalid file bytes and unsafe filenames', () {
    expect(
      () => WorkInvoicePdfDocument(
        identity: 'x',
        fileName: '../x.pdf',
        bytes: document().bytes,
        reviewOnly: false,
      ),
      throwsA(isA<WorkInvoicePdfException>()),
    );
    expect(
      () => WorkInvoicePdfDocument(
        identity: 'x',
        fileName: 'x.pdf',
        bytes: Uint8List(12),
        reviewOnly: false,
      ),
      throwsA(isA<WorkInvoicePdfException>()),
    );
  });
  testWidgets('cancel ignores late result and retry loads cleanly', (
    tester,
  ) async {
    final delayed = Completer<WorkInvoicePdfDocument>();
    var retry = false;
    final source = Source(
      () => retry ? Future.value(document()) : delayed.future,
    );
    await open(tester, source);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    delayed.complete(document());
    await tester.pump();
    expect(find.byKey(const Key('invoice-pdf-page')), findsNothing);
    expect(find.text('Preview cancelled.'), findsOneWidget);
    retry = true;
    await tap(tester, 'invoice-pdf-retry');
    await tester.pumpAndSettle();
    expect(source.calls, 2);
    expect(find.byKey(const Key('invoice-pdf-page')), findsOneWidget);
  });
  testWidgets('failed and unavailable sources expose retry without actions', (
    tester,
  ) async {
    await open(tester, const UnavailableWorkInvoicePdfSource());
    expect(find.byKey(const Key('invoice-pdf-retry')), findsOneWidget);
    expect(find.byKey(const Key('invoice-pdf-save')), findsNothing);
  });
  testWidgets('wrong scoped document is never previewed or shared', (
    tester,
  ) async {
    await open(
      tester,
      Source(() async => document(identity: 'other/store/invoice')),
    );
    expect(
      find.text('The returned file does not match this invoice.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('invoice-pdf-share')), findsNothing);
  });
  testWidgets('scope change discards open document and late responses', (
    tester,
  ) async {
    final scope = ValueNotifier(true);
    addTearDown(scope.dispose);
    final delayed = Completer<WorkInvoicePdfDocument>();
    await open(tester, Source(() => delayed.future), scope: scope);
    scope.value = false;
    await tester.pump();
    delayed.complete(document());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoice-pdf-page')), findsNothing);
    expect(find.byKey(const Key('invoice-pdf-retry')), findsNothing);
    expect(find.byKey(const Key('invoice-pdf-share')), findsNothing);
  });
  testWidgets('timeout permits retry and ignores late completion', (
    tester,
  ) async {
    final delayed = Completer<WorkInvoicePdfDocument>();
    await open(tester, Source(() => delayed.future));
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.byKey(const Key('invoice-pdf-retry')), findsOneWidget);
    delayed.complete(document());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoice-pdf-page')), findsNothing);
  });
  testWidgets(
    'native renderer failure still permits PDF save with same bytes',
    (tester) async {
      final actions = Actions();
      final doc = document();
      await open(
        tester,
        Source(() async => doc),
        actions: actions,
        failRender: true,
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Preview could not open. Retry, or save the PDF to view it.'),
        findsOneWidget,
      );
      await tap(tester, 'invoice-pdf-save');
      expect(actions.received, same(doc));
      expect(actions.saves, 1);
      expect(find.text('Invoice saved.'), findsOneWidget);
    },
  );
  testWidgets('share cancellation failure and handoff never imply delivery', (
    tester,
  ) async {
    final actions = Actions();
    await open(tester, Source(() async => document()), actions: actions);
    await tester.pumpAndSettle();
    actions.result = () async => WorkPdfActionResult.cancelled;
    await tap(tester, 'invoice-pdf-share');
    expect(find.text('Sharing cancelled.'), findsOneWidget);
    actions.result = () async => throw Exception('share');
    await tap(tester, 'invoice-pdf-share');
    expect(
      find.text('Could not share the PDF. Please try again.'),
      findsOneWidget,
    );
    actions.result = () async => WorkPdfActionResult.completed;
    await tap(tester, 'invoice-pdf-share');
    expect(find.text('File handed to the selected app.'), findsOneWidget);
    expect(request().invoice.sharedChannels, isEmpty);
  });
  testWidgets('pending actions prevent duplicates and pagination works', (
    tester,
  ) async {
    final actions = Actions();
    final delayed = Completer<WorkPdfActionResult>();
    await open(tester, Source(() async => document()), actions: actions);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Next page'));
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    actions.result = () => delayed.future;
    await tap(tester, 'invoice-pdf-save');
    await tap(tester, 'invoice-pdf-save');
    expect(actions.saves, 1);
    delayed.complete(WorkPdfActionResult.cancelled);
    await tester.pumpAndSettle();
    expect(find.text('Save cancelled.'), findsOneWidget);
  });
  testWidgets('compact large text errors and actions remain scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, Source(() async => document()), failRender: true);
    await tester.pumpAndSettle();
    await tap(tester, 'invoice-pdf-save');
    expect(tester.takeException(), isNull);
    expect(find.text('Invoice saved.'), findsOneWidget);
  });
}
