import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:moolsocial/features/work/work_stock_export.dart';
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
    seller: const WorkspaceInvoiceSeller(
      storeId: 'review-store',
      legalName: 'Annapurna Grocery and Household Supplies Private Limited',
      storeAddress:
          '42 Market Road, Near Central Market, Jaipur, Rajasthan, 302001',
      billingAddress:
          'Unit 12, First Floor, Wholesale Market Complex, Civil Lines, Jaipur, Rajasthan, 302006',
    ),
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

class PrintSource extends Source implements WorkInvoicePrintSource {
  PrintSource() : super(() async => document());
  @override
  Future<WorkInvoicePdfDocument> forPrint(
    WorkInvoicePdfRequest request,
    PdfPageFormat paper,
    List<int>? pages,
  ) async => document();
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
  testWidgets(
    'PRINT UI explicit paper suggestions and cancellation do not issue jobs prematurely',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final widths = <double>[];
      messenger.setMockMethodCallHandler(StoreDocumentPrinter.channel, (
        call,
      ) async {
        if (call.method == 'print') {
          widths.add(((call.arguments as Map)['width'] as num).toDouble());
        }
        return 'cancelled';
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          StoreDocumentPrinter.channel,
          null,
        ),
      );
      await open(tester, PrintSource());
      await tester.pumpAndSettle();
      await tap(tester, 'invoice-pdf-print');
      await tester.pumpAndSettle();
      expect(widths, isEmpty);
      await tester.tapAt(const Offset(5, 400));
      await tester.pumpAndSettle();
      expect(widths, isEmpty);
      for (final choice in StorePrintPaper.values) {
        await tap(tester, 'invoice-pdf-print');
        await tester.pumpAndSettle();
        await tap(tester, 'store-print-paper-${choice.name}');
        await tester.pumpAndSettle();
        expect(widths.last, closeTo(choice.initialFormat.width, .01));
        expect(find.text('Printing cancelled.'), findsOneWidget);
      }
      expect(widths.length, 4);
    },
  );
  group('PRINT native contract', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    Future<Object?> nativeRender(String id, Map<String, Object?> args) {
      final response = Completer<Object?>();
      const codec = StandardMethodCodec();
      ServicesBinding.instance.channelBuffers.push(
        'com.moolsocial.app/store_document_print/$id',
        codec.encodeMethodCall(MethodCall('render', {'id': id, ...args})),
        (reply) {
          try {
            response.complete(codec.decodeEnvelope(reply!));
          } catch (error, stack) {
            response.completeError(error, stack);
          }
        },
      );
      return response.future;
    }

    Map<String, Object?> paper(double width) => {
      'width': width,
      'height': 567.0,
      'left': 0.0,
      'top': 0.0,
      'right': 0.0,
      'bottom': 0.0,
      'pages': null,
    };
    tearDown(
      () => messenger.setMockMethodCallHandler(
        StoreDocumentPrinter.channel,
        null,
      ),
    );
    test(
      'printer media changes and selected pages reach the same renderer',
      () async {
        final changes = ChangeNotifier();
        addTearDown(changes.dispose);
        final widths = <double>[];
        final selections = <List<int>?>[];
        messenger.setMockMethodCallHandler(StoreDocumentPrinter.channel, (
          call,
        ) async {
          final id = (call.arguments as Map)['id'] as String;
          for (final width in [164.4, 226.8, 595.0]) {
            expect(await nativeRender(id, paper(width)), isA<Uint8List>());
          }
          await nativeRender(id, {
            ...paper(226.8),
            'pages': [2, 0, 2],
          });
          return 'submitted';
        });
        final state = await StoreDocumentPrinter.print(
          name: 'invoice.pdf',
          isCurrent: () => true,
          scopeChanges: changes,
          render: (format, pages) async {
            widths.add(format.width);
            selections.add(pages);
            return document().bytes;
          },
        );
        expect(state, StorePrintState.submitted);
        expect(widths, [164.4, 226.8, 595.0, 226.8]);
        expect(selections.last, [0, 2]);
      },
    );
    test(
      'invalid printable area never invokes the document renderer',
      () async {
        final changes = ChangeNotifier();
        addTearDown(changes.dispose);
        var renders = 0;
        messenger.setMockMethodCallHandler(StoreDocumentPrinter.channel, (
          call,
        ) async {
          final id = (call.arguments as Map)['id'] as String;
          await expectLater(
            nativeRender(id, {...paper(164.4), 'left': 100.0}),
            throwsA(isA<PlatformException>()),
          );
          return 'failed';
        });
        expect(
          await StoreDocumentPrinter.print(
            name: 'invoice.pdf',
            isCurrent: () => true,
            scopeChanges: changes,
            render: (_, _) async {
              renders++;
              return document().bytes;
            },
          ),
          StorePrintState.failed,
        );
        expect(renders, 0);
      },
    );
    test('scope change cancels and rejects generated document bytes', () async {
      final changes = ChangeNotifier();
      addTearDown(changes.dispose);
      var current = true, cancelled = false;
      messenger.setMockMethodCallHandler(StoreDocumentPrinter.channel, (
        call,
      ) async {
        if (call.method == 'cancel') {
          cancelled = true;
          return null;
        }
        final id = (call.arguments as Map)['id'] as String;
        await expectLater(
          nativeRender(id, paper(164.4)),
          throwsA(isA<PlatformException>()),
        );
        return 'completed';
      });
      expect(
        await StoreDocumentPrinter.print(
          name: 'invoice.pdf',
          isCurrent: () => current,
          scopeChanges: changes,
          render: (_, _) async {
            current = false;
            changes.notifyListeners();
            return document().bytes;
          },
        ),
        StorePrintState.cancelled,
      );
      expect(cancelled, isTrue);
    });
    test(
      'terminal and unknown native outcomes never imply completion',
      () async {
        final changes = ChangeNotifier();
        addTearDown(changes.dispose);
        for (final state in StorePrintState.values) {
          messenger.setMockMethodCallHandler(
            StoreDocumentPrinter.channel,
            (_) async => state.name,
          );
          expect(
            await StoreDocumentPrinter.print(
              name: 'invoice.pdf',
              isCurrent: () => true,
              scopeChanges: changes,
              render: (_, _) async => document().bytes,
            ),
            state,
          );
        }
        messenger.setMockMethodCallHandler(
          StoreDocumentPrinter.channel,
          (_) async => 'not-a-state',
        );
        expect(
          await StoreDocumentPrinter.print(
            name: 'invoice.pdf',
            isCurrent: () => true,
            scopeChanges: changes,
            render: (_, _) async => document().bytes,
          ),
          StorePrintState.unknown,
        );
      },
    );
    test(
      'malformed native reply cancels uncertain job and releases busy state',
      () async {
        final changes = ChangeNotifier();
        addTearDown(changes.dispose);
        var cancels = 0;
        messenger.setMockMethodCallHandler(StoreDocumentPrinter.channel, (
          call,
        ) async {
          if (call.method == 'cancel') {
            cancels++;
            return null;
          }
          return 42;
        });
        Future<StorePrintState> start() => StoreDocumentPrinter.print(
          name: 'invoice.pdf',
          isCurrent: () => true,
          scopeChanges: changes,
          render: (_, _) async => document().bytes,
        );
        expect(await start(), StorePrintState.unknown);
        expect(cancels, 1);
        messenger.setMockMethodCallHandler(
          StoreDocumentPrinter.channel,
          (_) async => 'cancelled',
        );
        expect(await start(), StorePrintState.cancelled);
      },
    );
  });
  test('SELLER-SNAPSHOT codec, legacy absence and private field exclusion', () {
    final invoice = request().invoice;
    final restored = WorkspaceCustomerInvoice.fromLedgerJson(
      invoice.toLedgerJson(),
    );
    expect(restored.seller!.toJson(), invoice.seller!.toJson());
    expect(
      restored.copyWith(sharedChannels: {'Chat'}).seller,
      same(restored.seller),
    );
    expect(restored.seller!.invoiceAddress, invoice.seller!.billingAddress);
    expect(
      restored.seller!.toJson().keys,
      unorderedEquals([
        'storeId',
        'legalName',
        'storeAddress',
        'billingAddress',
      ]),
    );
    final legacy = invoice.toLedgerJson()..remove('seller');
    expect(WorkspaceCustomerInvoice.fromLedgerJson(legacy).seller, isNull);
    expect(
      const WorkspaceInvoiceSeller(
        storeId: 's',
        storeAddress: 'Store address',
      ).invoiceAddress,
      'Store address',
    );
    expect(const WorkspaceInvoiceSeller(storeId: 's').detailLines, isEmpty);
    for (final data in [
      <String, Object?>{},
      {...invoice.seller!.toJson(), 'storeId': ''},
      {...invoice.seller!.toJson(), 'legalName': 12},
      {
        ...invoice.seller!.toJson(),
        'billingAddress': List.filled(2001, 'x').join(),
      },
    ]) {
      expect(
        () => WorkspaceInvoiceSeller.fromJson(data),
        throwsFormatException,
      );
    }
  });
  test('SELLER-SNAPSHOT PDF refuses another Store identity', () async {
    final base = request();
    await expectLater(
      const LocalReviewWorkInvoicePdfSource().load(
        WorkInvoicePdfRequest(
          accountId: base.accountId,
          storeId: 'other-store',
          invoice: base.invoice,
          items: base.items,
          paymentStatus: base.paymentStatus,
        ),
      ),
      throwsA(isA<WorkInvoicePdfException>()),
    );
  });
  test(
    'COUNTERDISCOUNT PDF accepts precise bill and rejects mismatched lines',
    () async {
      final invoice = WorkspaceCustomerInvoice(
        id: 'INV-DISCOUNT',
        orderId: 'order-discount',
        customer: 'Rakesh',
        sellerName: 'Store',
        items: 'Rice',
        amount: 94,
        remainderPaise: 50,
        discount: const WorkspaceBillDiscount.percentage(1000),
        discountMinor: 1050,
        payment: 'Cash',
        issuedAt: DateTime.utc(2026, 9, 19),
      );
      WorkInvoicePdfRequest discounted(int net) => WorkInvoicePdfRequest(
        accountId: 'review-account',
        storeId: 'review-store',
        invoice: invoice,
        items: [
          WorkspaceOrderItemSnapshot(
            productId: 'rice',
            name: 'Rice',
            pack: '1 kg',
            quantity: 1,
            unitPricePaise: 10500,
            lineTotalPaise: net,
          ),
        ],
        paymentStatus: 'Payment due: ₹94.50',
      );
      const source = LocalReviewWorkInvoicePdfSource();
      final document = await source.load(discounted(9450));
      expect(document.reviewOnly, isTrue);
      expect(String.fromCharCodes(document.bytes.take(5)), '%PDF-');
      expect(document.bytes.length, greaterThan(1000));
      await expectLater(
        source.load(discounted(10500)),
        throwsA(isA<WorkInvoicePdfException>()),
      );
    },
  );

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
  testWidgets(
    'manual PDF sharing is absent and never implies automatic delivery',
    (tester) async {
      final actions = Actions();
      await open(tester, Source(() async => document()), actions: actions);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('invoice-pdf-share')), findsNothing);
      expect(find.byTooltip('Share PDF'), findsNothing);
      expect(find.text('Share PDF'), findsNothing);
      expect(actions.shares, 0);
      expect(find.byKey(const Key('invoice-pdf-save')), findsOneWidget);
      expect(find.byKey(const Key('invoice-pdf-print')), findsOneWidget);
      expect(request().invoice.sharedChannels, isEmpty);
    },
  );
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
