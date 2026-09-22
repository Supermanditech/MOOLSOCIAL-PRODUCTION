import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/shared/commerce/commerce_downloads.dart';
import 'package:moolsocial/shared/commerce/commerce_downloads_screen.dart';

const owner = CommerceDownloadScope('test-account', store: 'test-store');
const customer = CommerceDownloadScope('test-account');
Uint8List pdfBytes() => Uint8List.fromList(utf8.encode('%PDF-1.7\nfixture'));
CommerceDownloadFile file(String id, {CommerceDownloadScope scope = owner}) =>
    CommerceDownloadFile(
      scope: scope,
      id: id,
      bytes: pdfBytes(),
      fileName: commerceDownloadName(id),
    );
CommerceDownloadItem item(
  String id, {
  CommerceDownloadScope scope = owner,
  CommerceDownloadKind kind = CommerceDownloadKind.invoice,
  DateTime? date,
  Future<CommerceDownloadFile> Function()? load,
}) => CommerceDownloadItem(
  scope: scope,
  id: id,
  kind: kind,
  title: switch (kind) {
    CommerceDownloadKind.invoice => 'Sales invoice',
    CommerceDownloadKind.platformFee => 'MoolSocial fee invoice',
    CommerceDownloadKind.summary => 'Order summary',
  },
  reference: id,
  party: 'Sunrise Grocery',
  date: date ?? DateTime(2026, 9, 22),
  notice: 'Preview · not issued',
  load: load ?? () async => file(id, scope: scope),
);

class Source implements CommerceDownloadSource {
  Source(this.callback);
  final Future<CommerceDownloadPage> Function(CommerceDownloadQuery, String?)
  callback;
  final queries = <CommerceDownloadQuery>[];
  @override
  Future<CommerceDownloadPage> load(
    CommerceDownloadQuery query, {
    String? cursor,
  }) {
    queries.add(query);
    return callback(query, cursor);
  }
}

Source records(List<CommerceDownloadItem> items) => Source(
  (q, c) async => CommerceDownloadPage(
    queryKey: q.key,
    items: items.where(q.matches).toList(),
  ),
);

Future<void> mount(
  WidgetTester tester,
  CommerceDownloadSource source, {
  CommerceDownloadScope scope = owner,
  ValueNotifier<bool>? active,
  Future<bool> Function(CommerceDownloadFile)? save,
  VoidCallback? stock,
  WidgetBuilder? stockBuilder,
  double scale = 1,
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final current = active ?? ValueNotifier(true);
  if (active == null) addTearDown(current.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RepaintBoundary(
        key: const Key('capture'),
        child: CommerceDownloadsScreen(
          scope: scope,
          source: source,
          scopeChanges: current,
          isCurrent: () => current.value,
          title: scope.store == null ? 'Downloads' : 'Reports & Downloads',
          ownerLabel: scope.store == null
              ? 'Your purchase documents'
              : 'Annapurna Stores',
          onExit: () {},
          onStockStatement: stock,
          stockStatementBuilder: stockBuilder,
          save: save ?? (_) async => true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  const output = String.fromEnvironment('COMMERCE_DOWNLOADS_OUTPUT');
  if (output.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(output).create(recursive: true);
    await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> choosePeriod(WidgetTester tester, String period) async {
  final toggle = find.byKey(const Key('downloads-period-toggle'));
  await tester.ensureVisible(toggle);
  await tester.tap(toggle);
  await tester.pumpAndSettle();
  final option = find.text(period).last;
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });
  test(
    'scope, file name, PDF signature and immutable bytes protect direct save',
    () {
      expect(owner.key, isNot(customer.key));
      expect(const CommerceDownloadScope('').valid, isFalse);
      expect(const CommerceDownloadScope('a', store: '').valid, isFalse);
      final bytes = pdfBytes();
      final document = CommerceDownloadFile(
        scope: owner,
        id: 'i',
        bytes: bytes,
        fileName: commerceDownloadName('../unsafe / invoice'),
      );
      bytes[0] = 0;
      expect(document.valid, isTrue);
      expect(() => document.bytes[0] = 0, throwsUnsupportedError);
      for (final name in [
        '../a.pdf',
        '/a.pdf',
        'commerce-document-a.csv',
        'commerce-document-.pdf',
      ]) {
        expect(
          CommerceDownloadFile(
            scope: owner,
            id: 'i',
            bytes: pdfBytes(),
            fileName: name,
          ).valid,
          isFalse,
        );
      }
      expect(
        CommerceDownloadFile(
          scope: owner,
          id: 'i',
          bytes: Uint8List(12),
          fileName: commerceDownloadName('i'),
        ).valid,
        isFalse,
      );
    },
  );
  test('native call sends original PDF bytes once without a picker', () async {
    const channel = MethodChannel('com.moolsocial.app/store_stock_download');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    expect(await saveCommerceDownloadFile(file('i')), isTrue);
    expect(calls.single.method, 'save');
    expect(calls.single.arguments['bytes'], pdfBytes());
    expect(calls.single.arguments['mimeType'], 'application/pdf');
  });
  testWidgets(
    'one tap downloads selected record and stock link is contextual',
    (tester) async {
      var saves = 0, stock = 0;
      final pending = Completer<bool>();
      await mount(
        tester,
        records([item('INV-001')]),
        stock: () => stock++,
        save: (f) {
          expect(f.id, 'INV-001');
          saves++;
          return pending.future;
        },
      );
      await tester.tap(find.byKey(const ValueKey('download-INV-001')));
      await tester.pump();
      expect(saves, 1);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('PDF'), findsNothing);
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Saved to Downloads / MoolSocial.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('downloads-stock-statement')));
      expect(stock, 1);
    },
  );
  testWidgets('stock panel stays in Downloads and is removed on scope loss', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    await mount(
      tester,
      records([]),
      active: active,
      stockBuilder: (_) => const Text('Scoped stock report'),
    );
    await tester.tap(find.byKey(const Key('downloads-stock-statement')));
    await tester.pumpAndSettle();
    expect(find.text('Reports & Downloads'), findsOneWidget);
    expect(find.text('Scoped stock report'), findsOneWidget);
    expect(find.byKey(const Key('downloads-search')), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    active.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Scoped stock report'), findsNothing);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('downloads-stock-statement')),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets('customer Downloads cannot show a supplied Store stock panel', (
    tester,
  ) async {
    await mount(
      tester,
      records([]),
      scope: customer,
      stockBuilder: (_) => const Text('Private Store stock'),
    );
    expect(find.byKey(const Key('downloads-stock-statement')), findsNothing);
    expect(find.text('Private Store stock'), findsNothing);
  });
  testWidgets('search and kinds filter without mixing scopes', (tester) async {
    final source = records([
      item('INV-001'),
      item('FEE-001', kind: CommerceDownloadKind.platformFee),
      item('private', scope: customer),
    ]);
    await mount(tester, source);
    expect(find.textContaining('private'), findsNothing);
    await tester.tap(find.byKey(const Key('downloads-kind-toggle')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('MoolSocial fees'));
    await tester.tap(find.text('MoolSocial fees'));
    await tester.pumpAndSettle();
    expect(find.text('MoolSocial fee invoice'), findsOneWidget);
    expect(find.text('Sales invoice'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('downloads-search')),
      'not-found',
    );
    await tester.pumpAndSettle();
    expect(find.text('No documents match these filters.'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('downloads-search')),
    );
    expect(field.decoration!.border, InputBorder.none);
    final effective = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byKey(const Key('downloads-search')),
        matching: find.byType(InputDecorator),
      ),
    );
    expect(effective.decoration.enabledBorder, InputBorder.none);
    expect(effective.decoration.focusedBorder, InputBorder.none);
  });
  testWidgets('custom dates validate, include end day and invalidate on edit', (
    tester,
  ) async {
    final source = records([item('INV-001')]);
    await mount(tester, source);
    await choosePeriod(tester, 'Custom');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('downloads-date-from')),
      '31/02/2026',
    );
    await tester.enterText(
      find.byKey(const Key('downloads-date-to')),
      '22/09/2026',
    );
    await tester.ensureVisible(find.text('Apply dates'));
    await tester.tap(find.text('Apply dates'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter valid dates with To on or after From.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('downloads-date-from')),
      '22/09/2026',
    );
    await tester.tap(find.text('Apply dates'));
    await tester.pumpAndSettle();
    expect(source.queries.last.from, DateTime(2026, 9, 22));
    expect(source.queries.last.until, DateTime(2026, 9, 23));
    await tester.ensureVisible(
      find.byKey(const Key('downloads-period-toggle')),
    );
    await tester.tap(find.byKey(const Key('downloads-period-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('downloads-date-to')),
      '23/09/2026',
    );
    await tester.pumpAndSettle();
    expect(find.text('Sales invoice'), findsNothing);
  });
  testWidgets('account change rejects a pending PDF before any native write', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    final pending = Completer<CommerceDownloadFile>();
    var saves = 0;
    await mount(
      tester,
      records([item('i', load: () => pending.future)]),
      active: active,
      save: (_) async {
        saves++;
        return true;
      },
    );
    await tester.tap(find.text('PDF'));
    await tester.pump();
    active.value = false;
    await tester.pump();
    active.value = true;
    pending.complete(file('i'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.text('Sales invoice'), findsNothing);
    expect(
      find.textContaining('Your account or Store changed'),
      findsOneWidget,
    );
  });
  for (final bad in ['scope', 'identity', 'bytes']) {
    testWidgets('rejects mismatched downloaded $bad', (tester) async {
      var saves = 0;
      await mount(
        tester,
        records([
          item(
            'i',
            load: () async => bad == 'bytes'
                ? CommerceDownloadFile(
                    scope: owner,
                    id: 'i',
                    bytes: Uint8List(12),
                    fileName: commerceDownloadName('i'),
                  )
                : file(
                    bad == 'identity' ? 'wrong' : 'i',
                    scope: bad == 'scope' ? customer : owner,
                  ),
          ),
        ]),
        save: (_) async {
          saves++;
          return true;
        },
      );
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();
      expect(saves, 0);
      expect(
        find.textContaining('does not match this account'),
        findsOneWidget,
      );
    });
  }
  testWidgets('late old search response cannot replace current results', (
    tester,
  ) async {
    final old = Completer<CommerceDownloadPage>();
    CommerceDownloadQuery? initial;
    final source = Source((q, c) {
      if (q.search.isEmpty) {
        initial = q;
        return old.future;
      }
      return Future.value(
        CommerceDownloadPage(queryKey: q.key, items: [item('new')]),
      );
    });
    // Mount without settling an intentionally pending request.
    final boot = records([]);
    await mount(tester, boot);
    final widget = tester.widget<CommerceDownloadsScreen>(
      find.byType(CommerceDownloadsScreen),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: CommerceDownloadsScreen(
          scope: owner,
          source: source,
          scopeChanges: widget.scopeChanges,
          isCurrent: () => true,
          title: 'Downloads',
          ownerLabel: 'Store',
          onExit: () {},
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('downloads-search')), 'new');
    await tester.pumpAndSettle();
    old.complete(
      CommerceDownloadPage(queryKey: initial!.key, items: [item('old')]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('download-new')), findsOneWidget);
    expect(find.byKey(const ValueKey('download-old')), findsNothing);
  });
  testWidgets('pagination retains records and blocks repeating cursor', (
    tester,
  ) async {
    final source = Source(
      (q, c) async => CommerceDownloadPage(
        queryKey: q.key,
        items: [item(c == null ? 'one' : 'two')],
        nextCursor: 'repeat',
      ),
    );
    await mount(tester, source);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be verified'), findsOneWidget);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be verified'), findsNothing);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('Load more'), findsOneWidget);
  });
  testWidgets('wrong-scope pages are not displayed', (tester) async {
    final source = Source(
      (q, c) async => CommerceDownloadPage(
        queryKey: q.key,
        items: [item('hidden', scope: customer)],
      ),
    );
    await mount(tester, source);
    expect(find.textContaining('could not be verified'), findsOneWidget);
    expect(find.textContaining('hidden'), findsNothing);
  });
  testWidgets('failure retry and save failure allow a deliberate retry', (
    tester,
  ) async {
    var calls = 0, saves = 0;
    final source = Source((q, c) async {
      if (calls++ == 0) throw StateError('offline');
      return CommerceDownloadPage(queryKey: q.key, items: [item('i')]);
    });
    await mount(
      tester,
      source,
      save: (_) async {
        if (saves++ == 0) throw StateError('disk');
        return true;
      },
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tap PDF to retry'), findsOneWidget);
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    expect(saves, 2);
    expect(find.text('Saved to Downloads / MoolSocial.'), findsOneWidget);
  });
  for (final scale in [1.0, 2.0]) {
    // Same implementation used for both account and business scopes.
    testWidgets('actual shared Store downloads render at $scale', (
      tester,
    ) async {
      await mount(
        tester,
        records([
          item('INV-2026-0012'),
          item('INV-2026-0011'),
          item('INV-2026-0010'),
        ]),
        stock: () {},
        scale: scale,
        width: scale == 1 ? 360 : 320,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'store-downloads-$scale');
      await choosePeriod(tester, 'Custom');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'store-downloads-dates-$scale');
    });
  }
  testWidgets(
    'customer route unavailable state does not invent purchase records',
    (tester) async {
      await mount(
        tester,
        const UnavailableCommerceDownloadSource(),
        scope: customer,
      );
      expect(find.textContaining('not available yet'), findsOneWidget);
      expect(find.text('PDF'), findsNothing);
      expect(find.byKey(const Key('downloads-stock-statement')), findsNothing);
      await capture(tester, 'customer-downloads-unavailable');
    },
  );
  testWidgets('valid paging appends unique records and terminates', (
    tester,
  ) async {
    final source = Source(
      (q, c) async => CommerceDownloadPage(
        queryKey: q.key,
        items: [item(c == null ? 'first' : 'second')],
        nextCursor: c == null ? 'page2' : null,
      ),
    );
    await mount(tester, source);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
  });
  testWidgets('native save timeout remains uncertain and does not auto-retry', (
    tester,
  ) async {
    const channel = MethodChannel('com.moolsocial.app/store_stock_download');
    final reply = Completer<bool>();
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) {
          calls++;
          return reply.future;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final operation = saveCommerceDownloadFile(file('slow'));
    final expectation = expectLater(
      operation,
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Check Downloads before retrying'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    await expectation;
    expect(calls, 1);
    reply.complete(true);
    await tester.pump();
    expect(calls, 1);
  });
  testWidgets('duplicate IDs fail closed', (tester) async {
    await mount(
      tester,
      Source(
        (q, c) async => CommerceDownloadPage(
          queryKey: q.key,
          items: [item('dup'), item('dup')],
        ),
      ),
    );
    expect(find.textContaining('could not be verified'), findsOneWidget);
    expect(find.text('Sales invoice'), findsNothing);
  });
  testWidgets(
    'uncertain native save is not reported as success or cancellation',
    (tester) async {
      await mount(tester, records([item('i')]), save: (_) async => false);
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Check Downloads before retrying'),
        findsOneWidget,
      );
      expect(find.textContaining('Saved to'), findsNothing);
    },
  );
  testWidgets('period presets use actual boundaries', (tester) async {
    final source = records([]);
    await mount(tester, source);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final period in ['Today', 'This week', 'This month', 'All time']) {
      await choosePeriod(tester, period);
      await tester.pumpAndSettle();
      expect(source.queries.last.from, switch (period) {
        'Today' => today,
        'This week' => today.subtract(Duration(days: today.weekday - 1)),
        'This month' => DateTime(now.year, now.month),
        _ => null,
      });
      expect(
        source.queries.last.until,
        period == 'All time' ? null : today.add(const Duration(days: 1)),
      );
    }
  });
}
