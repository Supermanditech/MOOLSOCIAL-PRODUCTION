import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/work/widgets/store_publication_settings.dart';
import 'package:moolsocial/features/work/widgets/store_settings_widgets.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_publication.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'fixtures/store_public_handoff_v1.dart';

void main() {
  testWidgets('LF16 secure writes remain ordered after a caller timeout', (tester) async {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final gate = Completer<void>();
    final values = <String, String>{};
    var writes = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final args = Map<String, Object?>.from(call.arguments as Map);
      if (call.method == 'write') {
        writes++;
        if (writes == 1) await gate.future;
        values[args['key'] as String] = args['value'] as String;
        return null;
      }
      if (call.method == 'read') return values[args['key']];
      throw StateError('Unexpected secure operation ${call.method}');
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final storage = _Lf16SecurePrefsStore('timeout');
    var timedOut = false;
    unawaited(storage.save('lf16-host', {'value': 'old'}).catchError((Object _) { timedOut = true; }));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    expect(timedOut, isTrue);
    final second = storage.save('lf16-host', {'value': 'new'});
    final read = _Lf16SecurePrefsStore('timeout').read('lf16-host');
    await tester.pump();
    expect(writes, 1, reason: 'Caller timeout must not release a live platform write');
    gate.complete();
    await tester.pump();
    await second;
    expect(await read, {'value': 'new'});
    expect(writes, 2);
  });

  test('LF16 actual pickup save recovers in a new session', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({}); // Host plugin fixture only.
    const store = WorkWorkspace(id: 'lf16-private-pickup', name: 'Host Store',
      profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Pune', verified: true);
    WorkSession create(ReviewWorkGateway gateway) => WorkSession(gateway: gateway,
      contactDraftStore: _Lf16SecurePrefsStore('host-contact'),
      pickupPreferencesStoreFactory: (id) => _Lf16SecurePrefsStore(id))..activeWorkspace = store;
    final first = create(ReviewWorkGateway());
    for (var i = 0; i < 5; i++) { await Future<void>.delayed(Duration.zero); }
    expect(first.saveWorkspaceDeliverySettings(city: 'Pune', area: 'Host pickup lane',
      pincode: '411001', pickupEnabled: false), isTrue);
    for (var i = 0; i < 5; i++) { await Future<void>.delayed(Duration.zero); }
    first.dispose();
    final gateway = ReviewWorkGateway();
    final restored = create(gateway);
    addTearDown(restored.dispose);
    for (var i = 0; i < 5; i++) { await Future<void>.delayed(Duration.zero); }
    expect(restored.workspaceDeliveryCity, 'Pune');
    expect(restored.workspaceDeliveryArea, 'Host pickup lane');
    expect(restored.workspaceDeliveryPincode, '411001');
    expect(restored.workspacePickupEnabled, isFalse);
    expect(gateway.operationalSaveCalls, 0, reason: 'Recovery must not resend operations');
    expect(restored.workspaceOrders, isEmpty);
    expect(restored.workspaceInvoices, isEmpty);
    expect(restored.workspaceCatalogueItems, isEmpty);
  });

  testWidgets('LF18 Store owner defaults survive a new session', (tester) async {
    FlutterSecureStorage.setMockInitialValues({}); // Isolated host plugin fixture.
    WorkSession create() => WorkSession(gateway: ReviewWorkGateway(),
      contactDraftStore: _Lf16SecurePrefsStore('host-contact'),
      publicationPreferencesStoreFactory: (id) => _Lf18SecureDefaultsStore(id))
      ..activeWorkspace = _lf16Store('lf18-defaults');
    Future<void> open(WorkSession work) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: StorePublicationSettings(session: work)))));
      await tester.pumpAndSettle();
    }
    final first = create();
    await open(first);
    expect(first.saveWorkspacePublicationDetails(const WorkspaceStorePublicationDetails(
      legalName: 'Host owner business', returnSummary: 'Return unopened goods',
      returnWindowDays: 7, dispatchDays: 2), expectedStoreId: 'lf18-defaults'), isTrue);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    first.dispose();
    final second = create();
    addTearDown(second.dispose);
    await open(second);
    expect(second.workspacePublicationDetails.legalName, 'Host owner business');
    expect(second.workspacePublicationDetails.returnWindowDays, 7);
    expect(second.workspacePublicationDetails.dispatchDays, 2);
    expect(second.workspaceVisibleToCustomers, isFalse);
    expect((second.gateway as ReviewWorkGateway).operationalSaveCalls, 0);
    expect(second.workspaceOrders, isEmpty);
    expect(second.workspaceInvoices, isEmpty);
    expect(second.workspaceCatalogueItems, isEmpty);
  });

  for (final invalid in ['version', 'store', 'missing', 'extra', 'type', 'pin', 'nested', 'location', 'customer', 'fraction']) {
    test('LF18 invalid saved $invalid stays intact and cannot overwrite inputs', () async {
      final f = await _lf18Prepared();
      final row = Map<String, Object?>.from(jsonDecode(f.rows[f.key('lf18-a')]!) as Map);
      final fields = row['fields'] as Map;
      if (invalid == 'version') row['schemaVersion'] = 2;
      if (invalid == 'store') row['storeId'] = 'other-store';
      if (invalid == 'missing') fields.remove('legalName');
      if (invalid == 'extra') fields['orders'] = [];
      if (invalid == 'type') fields['retailChannelEnabled'] = 'true';
      if (invalid == 'pin') fields['pinCode'] = 'bad';
      if (invalid == 'nested') (fields['wholesalePaymentTerms'] as List).first['authority'] = true;
      if (invalid == 'location') fields['shoppingArea'] = {'regionId': 'invented'};
      if (invalid == 'customer') fields['customerPaymentTerms'] = {'private-id': []};
      if (invalid == 'fraction') fields['dispatchDays'] = 1.5;
      final encoded = jsonEncode(row);
      f.rows[f.key('lf18-a')] = encoded;
      final work = f.work();
      addTearDown(work.dispose);
      expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isFalse);
      expect(work.workspacePublicationDetails.legalName, isEmpty);
      expect(work.workspacePublicationPreferencesError, isNotNull);
      expect(work.saveWorkspacePublicationDetails(_lf18Details(), expectedStoreId: 'lf18-a'), isFalse);
      expect(f.rows[f.key('lf18-a')], encoded);
    });
  }

  test('LF18 saved defaults exclude authority and private customer exceptions', () async {
    final f = _Lf18Storage();
    final first = f.work();
    await first.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a');
    final input = WorkspaceStorePublicationDetails.fromJson({..._lf18Details().toJson(),
      'shoppingArea': {'regionId': 'host-region', 'googlePlaceId': 'host-place',
        'label': 'Host area', 'countryCode': 'IN', 'postalCode': '411001'},
      'openingTime': '08:00', 'closingTime': '22:00',
      'retailPaymentMethods': ['PhonePe'],
      'customerPaymentTerms': {'host-private-id': []}});
    expect(first.saveWorkspacePublicationDetails(input), isTrue);
    expect(await first.workspacePublicationPreferencesWrite, isTrue);
    final fields = (jsonDecode(f.rows[f.key('lf18-a')]!) as Map)['fields'] as Map;
    for (final key in ['shoppingArea', 'customerPaymentTerms', 'openingTime', 'closingTime', 'retailPaymentMethods']) {
      expect(fields.containsKey(key), isFalse);
    }
    first.dispose();
    final second = f.work();
    addTearDown(second.dispose);
    expect(await second.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isTrue);
    expect(second.workspacePublicationDetails.legalName, 'Host default business');
    expect(second.workspacePublicationDetails.wholesalePaymentTerms.single.advancePercent, 25);
    expect(second.workspacePublicationDetails.customerPaymentTerms, isEmpty);
    expect(second.workspacePublicationDetails.shoppingArea, isNull);
    expect(second.workspacePublicStoreDetails!.regionId, isEmpty);
    expect(second.workspacePublicationDetails.openingTime, isEmpty);
    expect(second.workspacePublicationDetails.retailPaymentMethods, isEmpty);
    expect(second.workspaceVisibleToCustomers, isFalse);
    expect((second.gateway as ReviewWorkGateway).operationalSaveCalls, 0);
  });

  test('LF18 read failure retries without erasing the record', () async {
    final f = (await _lf18Prepared())..failRead = true;
    final saved = Map.of(f.rows);
    final work = f.work();
    addTearDown(work.dispose);
    expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isFalse);
    expect(f.rows, saved);
    f.failRead = false;
    expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isTrue);
    expect(work.workspacePublicationDetails.legalName, 'Host default business');
  });

  test('LF18 failed write keeps current input and same-value retry can save', () async {
    final f = _Lf18Storage()..failWrite = true;
    final work = f.work();
    addTearDown(work.dispose);
    await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a');
    expect(work.saveWorkspacePublicationDetails(_lf18Details()), isTrue);
    expect(await work.workspacePublicationPreferencesWrite, isFalse);
    expect(work.workspacePublicationDetails.legalName, 'Host default business');
    expect(work.workspacePublicationPreferencesSaved, isFalse);
    expect(work.workspacePublicationPreferencesError, isNotNull);
    f.failWrite = false;
    expect(work.saveWorkspacePublicationDetails(_lf18Details()), isTrue);
    expect(await work.workspacePublicationPreferencesWrite, isTrue);
    expect(work.workspacePublicationPreferencesSaved, isTrue);
    expect(work.workspacePublicationPreferencesError, isNull);
  });

  test('LF18 busy writes reject duplicate edits without replacing current inputs', () async {
    final f = _Lf18Storage()..writeGate = Completer<void>();
    final work = f.work();
    addTearDown(work.dispose);
    await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a');
    expect(work.saveWorkspacePublicationDetails(_lf18Details()), isTrue);
    expect(work.workspacePublicationPreferencesSaving, isTrue);
    expect(work.saveWorkspacePublicationDetails(const WorkspaceStorePublicationDetails(legalName: 'Newer attempt')), isFalse);
    expect(work.workspacePublicationDetails.legalName, 'Host default business');
    f.writeGate!.complete();
    expect(await work.workspacePublicationPreferencesWrite, isTrue);
    expect(work.workspacePublicationPreferencesSaving, isFalse);
    expect(f.writes, 1);
  });

  for (final aba in [false, true]) {
    test('LF18 delayed read rejects Store change ABA=$aba', () async {
      final f = await _lf18Prepared();
      f.readGate = Completer<void>();
      final work = f.work();
      addTearDown(work.dispose);
      final read = work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a');
      await Future<void>.delayed(Duration.zero);
      work.activeWorkspace = _lf16Store('lf18-b');
      if (aba) work.activeWorkspace = _lf16Store('lf18-a');
      f.readGate!.complete();
      expect(await read, isFalse);
      expect(work.workspacePublicationDetails.legalName, isEmpty);
    });
  }

  test('LF18 observed account ABA and disposal cannot apply old defaults', () async {
    final f = await _lf18Prepared();
    f.readGate = Completer<void>();
    final work = f.work();
    final read = work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a');
    await Future<void>.delayed(Duration.zero);
    f.account = 'host-b'; work.showNotice('Host account changed');
    f.account = 'lf16-host'; work.showNotice('Host account returned');
    f.readGate!.complete();
    expect(await read, isFalse);
    expect(work.workspacePublicationDetails.legalName, isEmpty);
    work.dispose();
    expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isFalse);
  });

  test('LF18 account caches keep each owners inputs separate', () async {
    final f = await _lf18Prepared();
    final work = f.work();
    addTearDown(work.dispose);
    expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isTrue);
    f.account = 'host-b';
    expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isTrue);
    expect(work.workspacePublicationDetails.legalName, isEmpty);
    expect(work.saveWorkspacePublicationDetails(const WorkspaceStorePublicationDetails(legalName: 'Owner B')), isTrue);
    expect(await work.workspacePublicationPreferencesWrite, isTrue);
    f.account = 'lf16-host';
    expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isTrue);
    expect(work.workspacePublicationDetails.legalName, 'Host default business');
    expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'other-store'), isFalse);
  });

  test('LF18 customer exception before load cannot overwrite unread defaults', () async {
    final f = await _lf18Prepared();
    final encoded = f.rows[f.key('lf18-a')];
    final writes = f.writes;
    final work = f.work();
    addTearDown(work.dispose);
    // Separately labelled host customer/order, not native evaluation data.
    work.workspaceOrders.add(WorkspaceOrderRecord(id: 'host-lf18-order',
      customer: 'Host buyer · 9000091991', items: 'Host item × 1',
      quantities: const {'host-item': 1}, amount: 1, source: 'App',
      fulfilment: 'Pickup', payment: 'Paid online', address: '', stage: 'Completed',
      needsDelivery: false, createdAt: DateTime.now()));
    final customerId = work.workspaceCustomerBook.single.id;
    expect(work.saveWorkspaceCustomerPaymentTerms(expectedStoreId: 'lf18-a',
      customerId: customerId, terms: []), isTrue);
    expect(work.workspacePublicationPreferencesSaved, isFalse);
    expect(f.rows[f.key('lf18-a')], encoded);
    expect(f.writes, writes);
    expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isTrue);
    expect(work.workspacePublicationDetails.legalName, 'Host default business');
    expect(work.workspacePublicationDetails.customerPaymentTerms[customerId], isEmpty);
    expect(f.rows[f.key('lf18-a')], encoded);
  });

  test('LF18 recovered inputs cannot inherit contact or location confirmation', () async {
    final f = await _lf18Prepared();
    final row = jsonDecode(f.rows[f.key('lf18-a')]!) as Map;
    (row['fields'] as Map)['publicContactPhone'] = '9000091991';
    f.rows[f.key('lf18-a')] = jsonEncode(row);
    f.contactAvailable = false; // Existing session-only setup before a scoped reader exists.
    final work = f.work();
    addTearDown(work.dispose);
    work.primaryMobile = '9000091000';
    work.primaryMobileVerified = true;
    final identity = work.activeWorkspace;
    expect(work.saveWorkspacePublicationDetails(WorkspaceStorePublicationDetails.fromJson({
      ..._lf18Details().toJson(), 'street': 'Old input lane', 'publicContactPhone': '9000091000',
      'shoppingArea': {'regionId': 'host-old-region', 'googlePlaceId': 'host-old-place',
        'label': 'Host old area', 'countryCode': 'IN', 'postalCode': '411001'},
      'customerPaymentTerms': {'private-current-customer': []},
      'openingTime': '09:00', 'closingTime': '18:00'})), isTrue);
    f.contactAvailable = true;
    expect(await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a'), isTrue);
    expect(work.workspacePublicationDetails.street, 'Host default lane');
    expect(work.workspacePublicationDetails.publicContactPhone, '9000091991');
    expect(work.primaryMobile, '9000091000');
    expect(work.primaryMobileVerified, isTrue, reason: 'Verification stays bound to the unchanged account contact');
    expect(work.activeWorkspace, same(identity));
    expect(work.workspacePublicationDetails.shoppingArea, isNull);
    expect(work.workspacePublicStoreDetails!.regionId, isEmpty);
    expect(work.workspacePublicStoreDetails!.collection, isNull);
    expect(work.workspacePublicationDetails.customerPaymentTerms.keys, ['private-current-customer']);
    expect(work.workspacePublicationDetails.openingTime, '09:00');
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('LF18 editor retains failed-save inputs and disables pending save $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = await _lf18Prepared();
      final work = f.work();
      addTearDown(work.dispose);
      await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: Scaffold(body: SingleChildScrollView(child: StorePublicationSettings(session: work)))));
      await tester.pumpAndSettle();
      final section = find.byKey(const PageStorageKey('work-publication-address-section'));
      await tester.ensureVisible(section);
      await tester.tap(section);
      await tester.pumpAndSettle();
      final street = find.byKey(const Key('work-publication-street'));
      expect(tester.widget<TextFormField>(street).controller!.text, 'Host default lane');
      await tester.ensureVisible(street);
      await tester.enterText(street, 'Edited host lane');
      final save = find.byKey(const Key('work-publication-save-address'));
      f.failWrite = true;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(work.workspacePublicationPreferencesSaved, isFalse);
      expect(work.workspacePublicationPreferencesError, isNotNull);
      expect(tester.widget<TextFormField>(street).controller!.text, 'Edited host lane');
      f.failWrite = false;
      f.writeGate = Completer<void>();
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      f.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(work.workspacePublicationPreferencesSaved, isTrue);
      final status = find.byKey(const Key('work-publication-device-status'));
      await tester.ensureVisible(status);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(status).data, contains('Saved on this device'));
      expect(work.workspacePublicationDetails.street, 'Edited host lane');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('LF18 unreadable editor gates fields and retries without discarding saved data', (tester) async {
    final f = (await _lf18Prepared())..failRead = true;
    final work = f.work();
    addTearDown(work.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: StorePublicationSettings(session: work)))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-publication-business-type')), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    f.failRead = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-publication-business-type')), findsOneWidget);
    expect(work.workspacePublicationDetails.legalName, 'Host default business');
    expect(tester.takeException(), isNull);
  });

  for (final invalid in ['version', 'store', 'missing', 'extra', 'type', 'pin']) {
    test('LF16 invalid saved $invalid preserves entries and original record', () async {
      final fixture = _Lf16Storage();
      final row = fixture.valid();
      if (invalid == 'version') row['schemaVersion'] = 2;
      if (invalid == 'store') row['storeId'] = 'another-store';
      final fields = row['fields'] as Map<String, Object?>;
      if (invalid == 'missing') fields.remove('pickupEnabled');
      if (invalid == 'extra') fields['orders'] = [];
      if (invalid == 'type') fields['pickupEnabled'] = 'true';
      if (invalid == 'pin') fields['pincode'] = 'bad';
      final encoded = jsonEncode(row);
      fixture.rows[fixture.key('lf16-a')] = encoded;
      final work = fixture.work();
      addTearDown(work.dispose);
      work.workspaceDeliveryCity = 'Newer input';
      expect(await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a'), isFalse);
      expect(work.workspaceDeliveryCity, 'Newer input');
      expect(work.workspacePickupPreferencesError, isNotNull);
      expect(fixture.rows[fixture.key('lf16-a')], encoded);
      expect(fixture.writes, 0);
      expect(work.saveWorkspaceDeliverySettings(city: 'Pune', area: 'lane', pincode: '411001'), isFalse);
    });
  }

  test('LF16 read failure is retryable without discarding entries', () async {
    final fixture = _Lf16Storage()..failRead = true;
    final work = fixture.work();
    addTearDown(work.dispose);
    work.workspaceDeliveryArea = 'Unsaved address';
    expect(await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a'), isFalse);
    fixture.failRead = false;
    expect(await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a'), isTrue);
    expect(work.workspaceDeliveryArea, 'Unsaved address');
    expect(work.workspacePickupPreferencesSaved, isFalse);
  });

  for (final aba in [false, true]) {
    test('LF16 delayed Store read rejects changed scope ABA=$aba', () async {
      final fixture = _Lf16Storage()..readGate = Completer<void>();
      fixture.rows[fixture.key('lf16-a')] = jsonEncode(fixture.valid());
      final work = fixture.work();
      addTearDown(work.dispose);
      final read = work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a');
      await Future<void>.delayed(Duration.zero);
      work.activeWorkspace = _lf16Store('lf16-b');
      if (aba) work.activeWorkspace = _lf16Store('lf16-a');
      fixture.readGate!.complete();
      expect(await read, isFalse);
      expect(work.workspaceDeliveryCity, isEmpty);
    });
  }

  test('LF16 account change and observed ABA cannot publish a delayed read', () async {
    final fixture = _Lf16Storage()..readGate = Completer<void>();
    fixture.rows[fixture.key('lf16-a')] = jsonEncode(fixture.valid());
    final work = fixture.work();
    addTearDown(work.dispose);
    final read = work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a');
    await Future<void>.delayed(Duration.zero);
    fixture.account = 'other-owner';
    work.showNotice('Host account changed');
    fixture.account = 'lf16-host';
    work.showNotice('Host account returned');
    fixture.readGate!.complete();
    expect(await read, isFalse);
    expect(work.workspaceDeliveryCity, isEmpty);
  });

  test('LF16 late read preserves newer input and disposed session', () async {
    final fixture = _Lf16Storage()..readGate = Completer<void>();
    fixture.rows[fixture.key('lf16-a')] = jsonEncode(fixture.valid());
    final work = fixture.work();
    final read = work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a');
    await Future<void>.delayed(Duration.zero);
    work.workspaceDeliveryCity = 'Newer city';
    fixture.readGate!.complete();
    expect(await read, isTrue);
    expect(work.workspaceDeliveryCity, 'Newer city');
    expect(work.workspacePickupPreferencesSaved, isFalse);
    expect(await work.loadWorkspacePickupPreferences(expectedStoreId: 'wrong-store'), isFalse);
    work.dispose();
    expect(await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a'), isFalse);
  });

  test('LF16 owner caches do not expose another owner pickup inputs', () async {
    final fixture = _Lf16Storage();
    fixture.rows[fixture.key('lf16-a')] = jsonEncode(fixture.valid());
    final work = fixture.work();
    addTearDown(work.dispose);
    expect(await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a'), isTrue);
    expect(work.workspaceDeliveryCity, 'Pune');
    fixture.account = 'owner-b';
    expect(await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a'), isTrue);
    expect(work.workspaceDeliveryCity, isEmpty);
    fixture.account = 'lf16-host';
    expect(await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a'), isTrue);
    expect(work.workspaceDeliveryCity, 'Pune');
  });

  test('LF16 write failure preserves input and recovery can retry', () async {
    final fixture = _Lf16Storage();
    final work = fixture.work();
    addTearDown(work.dispose);
    await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a');
    fixture.failWrite = true;
    expect(work.saveWorkspaceDeliverySettings(city: 'Pune', area: 'Kept lane', pincode: '411001'), isTrue);
    for (var i = 0; i < 5; i++) { await Future<void>.delayed(Duration.zero); }
    expect(work.workspacePickupPreferencesSaving, isFalse);
    expect(work.workspacePickupPreferencesSaved, isFalse);
    expect(work.workspacePickupPreferencesError, contains('could not be confirmed'));
    expect(work.workspaceDeliveryArea, 'Kept lane');
    fixture.failWrite = false;
    expect(work.saveWorkspaceDeliverySettings(), isTrue);
    for (var i = 0; i < 5; i++) { await Future<void>.delayed(Duration.zero); }
    expect(work.workspacePickupPreferencesSaved, isTrue);
    expect(work.workspacePickupPreferencesError, isNull);
    expect(jsonDecode(fixture.rows[fixture.key('lf16-a')]!)['fields']['area'], 'Kept lane');
  });

  test('LF16 consecutive saves finish in order and keep latest fields', () async {
    final fixture = _Lf16Storage();
    final work = fixture.work();
    addTearDown(work.dispose);
    await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a');
    fixture.writeGate = Completer<void>();
    work.saveWorkspaceDeliverySettings(city: 'First', area: 'Lane', pincode: '411001');
    await Future<void>.delayed(Duration.zero);
    work.saveWorkspaceDeliverySettings(city: 'Latest', area: 'Lane', pincode: '411001');
    await Future<void>.delayed(Duration.zero);
    expect(fixture.writes, 1);
    expect(work.workspacePickupPreferencesSaving, isTrue);
    fixture.writeGate!.complete();
    for (var i = 0; i < 8; i++) { await Future<void>.delayed(Duration.zero); }
    expect(fixture.writes, 2);
    expect(work.workspacePickupPreferencesSaving, isFalse);
    expect(work.workspacePickupPreferencesSaved, isTrue);
    expect(jsonDecode(fixture.rows[fixture.key('lf16-a')]!)['fields']['city'], 'Latest');
  });

  testWidgets('LF16 busy settings save is visibly disabled', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StoreSettingsForm(
      title: 'Host settings', detail: 'Host fixture', fields: const [],
      saveKey: 'lf16-save', saveLabel: 'Saving…', saveEnabled: false,
      onSave: () { calls++; },
    ))));
    final button = tester.widget<FilledButton>(find.byKey(const Key('lf16-save')));
    expect(button.onPressed, isNull);
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  test('LF16 newer successful save clears an older queued failure', () async {
    final fixture = _Lf16Storage();
    final work = fixture.work();
    addTearDown(work.dispose);
    await work.loadWorkspacePickupPreferences(expectedStoreId: 'lf16-a');
    fixture.failWritesRemaining = 1;
    work.saveWorkspaceDeliverySettings(city: 'Old', area: 'Lane', pincode: '411001');
    work.saveWorkspaceDeliverySettings(city: 'Latest', area: 'Lane', pincode: '411001');
    for (var i = 0; i < 8; i++) { await Future<void>.delayed(Duration.zero); }
    expect(work.workspacePickupPreferencesSaved, isTrue);
    expect(work.workspacePickupPreferencesError, isNull);
  });

  test('LF06 new Store location is unknown rather than fabricated', () {
    final work = WorkSession(gateway: ReviewWorkGateway());
    addTearDown(work.dispose);
    expect(work.workspaceDeliveryCity, isEmpty);
    expect(work.workspaceDeliveryArea, isEmpty);
    expect(work.workspaceDeliveryPincode, isEmpty);
    expect(work.workspacePublicStoreDetails, isNull);
  });
  test('LF06 stale and ABA readiness saves cannot mutate another settings scope', () {
    final gateway = ReviewWorkGateway();
    final work = WorkSession(gateway: gateway);
    addTearDown(work.dispose);
    const a = WorkWorkspace(id: 'host-lf06-a', name: 'Host A', profileId: 'retailer-grocery',
      profileLabel: 'Grocery', area: 'Jaipur', verified: true);
    const b = WorkWorkspace(id: 'host-lf06-b', name: 'Host B', profileId: 'retailer-grocery',
      profileLabel: 'Grocery', area: 'Delhi', verified: true);
    work.activeWorkspace = a;
    final revision = work.navigationScopeRevision;
    work.activeWorkspace = b;
    for (final target in [b, a]) {
      work.activeWorkspace = target;
      final before = (work.workspaceAcceptingOrders, work.workspaceBusyMinutes,
        work.workspaceOpeningTime, work.workspaceDeliveryCity, gateway.operationalSaveCalls);
      expect(work.saveWorkspaceAvailability(acceptingOrders: false,
        fulfilmentMode: 'Pickup', busyMinutes: 10, reopensAt: '',
        expectedStoreId: a.id, expectedNavigationRevision: revision), isFalse);
      expect(work.saveWorkspaceTradingControls(openingTime: '09:00', closingTime: '20:00',
        maximumActiveOrders: 12, alertSound: false, alertVibration: false,
        expectedStoreId: a.id, expectedNavigationRevision: revision), isFalse);
      expect(work.saveWorkspaceDeliverySettings(city: 'Jaipur', area: 'Host lane',
        pincode: '302001', expectedStoreId: a.id,
        expectedNavigationRevision: revision), isFalse);
      expect((work.workspaceAcceptingOrders, work.workspaceBusyMinutes,
        work.workspaceOpeningTime, work.workspaceDeliveryCity, gateway.operationalSaveCalls), before);
    }
    expect(work.saveWorkspaceAvailability(acceptingOrders: false,
      fulfilmentMode: 'Pickup', busyMinutes: -1, reopensAt: ''), isFalse);
    expect(work.workspaceAcceptingOrders, isFalse);
    expect(work.saveWorkspaceAvailability(acceptingOrders: true,
      fulfilmentMode: 'Pickup', busyMinutes: 10, reopensAt: '', expectedStoreId: a.id,
      expectedNavigationRevision: work.navigationScopeRevision), isTrue);
    expect(work.workspaceBusyMinutes, 10);
    expect(handoffStock().toBuyPublicFacts(storeName: 'Host A', sourceId: 'host-local',
      storeVisible: true, acceptingOrders: true, observedAt: DateTime.utc(2026,10,15)).fulfilmentMode, isNull);
    expect(handoffStock().toBuyPublicFacts(storeName: 'Host A', sourceId: 'host-local',
      storeVisible: true, acceptingOrders: true, observedAt: DateTime.utc(2026,10,15)).eligibility, isNull);
  });
  for (final aba in [false, true]) {
    testWidgets('LF06 publication form captures original scope eagerly ABA$aba', (tester) async {
      final work = WorkSession(gateway: ReviewWorkGateway());
      addTearDown(work.dispose);
      const a = WorkWorkspace(id: 'lf06-form-a', name: 'Host A', profileId: 'retailer-grocery',
        profileLabel: 'Grocery', area: 'Jaipur', verified: true);
      work.activeWorkspace = a;
      work.saveWorkspacePublicationDetails(handoffStoreDetails());
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: StorePublicationSettings(session: work)))));
      await tester.tap(find.byKey(const PageStorageKey('work-publication-address-section')));
      await tester.pumpAndSettle();
      work.activeWorkspace = const WorkWorkspace(id: 'lf06-form-b', name: 'Host B',
        profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Delhi', verified: true);
      if (aba) work.activeWorkspace = a;
      final before = work.workspacePublicationDetails.toJson();
      final save = find.byKey(const Key('work-publication-save-address'));
      await Scrollable.ensureVisible(tester.element(save), alignment: .3);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(work.workspacePublicationDetails.toJson(), before);
      expect(find.textContaining('Your Store changed.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'LF02 public contact and explicit hours round trip without private fields',
    () {
      final details = WorkspaceStorePublicationDetails.fromJson({
        'publicContactPhone': '+91 98765 43210',
        'openingTime': '22:00',
        'closingTime': '06:00',
        'pan': 'PRIVATE-PAN',
        'signatory': 'Private signatory',
        'billingAddress': 'Private billing address',
      });
      final saved = details.toJson();
      expect(saved['publicContactPhone'], '+91 98765 43210');
      expect(saved['openingTime'], '22:00');
      expect(saved['closingTime'], '06:00');
      expect(WorkspaceStorePublicationDetails.fromJson(saved).toJson(), saved);
      final public = details.toPublicStore(
        id: 'host-a',
        name: 'Host Store',
        area: 'Jaipur',
      );
      expect(public.publicContactPhone, '+91 98765 43210');
      expect(public.openingHoursLabel, '22:00 – 06:00');
      expect(
        const WorkspaceStorePublicationDetails(publicContactPhone: 'invalid')
            .toPublicStore(id: 'host-a', name: 'Host Store', area: 'Jaipur')
            .publicContactPhone,
        isNull,
      );
      for (final patch in <Map<String, Object?>>[
        {'publicContactPhone': 'call my login'},
        {'publicContactPhone': '+123'},
        {'publicContactPhone': 9876543210},
        {'openingTime': '25:00', 'closingTime': '18:00'},
        {'openingTime': '08:00', 'closingTime': ''},
      ]) {
        expect(
          () => WorkspaceStorePublicationDetails.fromJson(patch),
          throwsFormatException,
        );
      }
    },
  );

  test('LF02 public hours stay absent until explicitly saved', () {
    final work = WorkSession(gateway: ReviewWorkGateway())
      ..activeWorkspace = const WorkWorkspace(
        id: 'lf02-host-store',
        name: 'Host fixture Store',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jaipur',
        verified: true,
      );
    addTearDown(work.dispose);
    expect(
      work.workspacePublicationDetails.toJson().containsKey('openingTime'),
      isFalse,
    );
    expect(work.workspacePublicStoreDetails!.openingHoursLabel, isNull);
    expect(work.workspacePublicStoreDetails!.publicContactPhone, isNull);
    work.saveWorkspaceTradingControls(
      openingTime: '22:00',
      closingTime: '06:00',
      maximumActiveOrders: 0,
      alertSound: true,
      alertVibration: false,
    );
    expect(work.workspacePublicationDetails.toJson()['openingTime'], '22:00');
    expect(work.workspacePublicationDetails.toJson()['closingTime'], '06:00');
    expect(
      work.workspacePublicStoreDetails!.openingHoursLabel,
      '22:00 – 06:00',
    );
    work.activeWorkspace = const WorkWorkspace(
      id: 'lf02-host-store-b',
      name: 'Other host Store',
      profileId: 'retailer-grocery',
      profileLabel: 'Grocery',
      area: 'Delhi',
      verified: true,
    );
    expect(work.workspacePublicStoreDetails!.openingHoursLabel, isNull);
    expect(work.workspacePublicStoreDetails!.publicContactPhone, isNull);
  });

  testWidgets('LF02 existing Store form validates and saves public contact', (
    tester,
  ) async {
    final work = WorkSession(gateway: ReviewWorkGateway())
      ..activeWorkspace = const WorkWorkspace(
        id: 'lf02-host-form',
        name: 'Host fixture Store',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jaipur',
        verified: true,
      );
    addTearDown(work.dispose);
    work.saveWorkspacePublicationDetails(handoffStoreDetails());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StorePublicationSettings(session: work),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const PageStorageKey('work-publication-address-section')),
    );
    await tester.pumpAndSettle();
    final contact = find.byKey(
      const Key('work-publication-publicContactPhone'),
    );
    await tester.ensureVisible(contact);
    await tester.enterText(contact, 'not a number');
    final save = find.byKey(const Key('work-publication-save-address'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid customer contact number.'), findsOneWidget);
    expect(work.workspacePublicationDetails.publicContactPhone, isEmpty);
    await tester.ensureVisible(contact);
    await tester.enterText(contact, '+91 98765 43210');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      work.workspacePublicStoreDetails!.publicContactPhone,
      '+91 98765 43210',
    );
    work.saveWorkspaceTradingControls(
      openingTime: '09:30',
      closingTime: '18:45',
      maximumActiveOrders: 0,
      alertSound: true,
      alertVibration: false,
    );
    final beforeInvalid = work.workspacePublicationDetails.toJson();
    work.saveWorkspaceTradingControls(
      openingTime: 'invalid',
      closingTime: '06:00',
      maximumActiveOrders: 10,
      alertSound: false,
      alertVibration: true,
    );
    expect(work.workspacePublicationDetails.toJson(), beforeInvalid);
    expect(work.workspaceOpeningTime, '09:30');
    expect(work.workspaceMaximumActiveOrders, 0);
    await tester.ensureVisible(contact);
    await tester.enterText(contact, '');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(work.workspacePublicStoreDetails!.publicContactPhone, isNull);
    expect(
      work.workspacePublicStoreDetails!.openingHoursLabel,
      '09:30 – 18:45',
    );
    final restored = WorkspaceStorePublicationDetails.fromJson(
      work.workspacePublicationDetails.toJson(),
    );
    expect(restored.publicContactPhone, isEmpty);
    expect(restored.openingTime, '09:30');
    expect(restored.closingTime, '18:45');
    expect(
      work.workspacePublicationDetails.signatory,
      handoffStoreDetails().signatory,
    );
    expect(work.workspaceVisibleToCustomers, isFalse);
    expect(tester.takeException(), isNull);
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  test('PAYMENT-TERMS canonical kinds round trip and invalid terms reject', () {
    for (final kind in WorkspacePaymentTerm.wholesaleKinds) {
      final term = WorkspacePaymentTerm(
        kind,
        advancePercent: WorkspacePaymentTerm(kind).needsAdvance ? 25 : null,
        netDays: kind == BuyV2CommercialPaymentTermKind.supplierCredit
            ? 30
            : null,
      );
      expect(term.valid, isTrue);
      expect(
        WorkspacePaymentTerm.fromJson(term.toJson()).toJson(),
        term.toJson(),
      );
    }
    for (final data in [
      {'kind': 'regulatedCredit'},
      {'kind': 'retailAdvance'},
      {'kind': 'supplierCredit', 'netDays': 0},
      {'kind': 'supplierCredit', 'netDays': 366},
      {'kind': 'supplierCredit', 'netDays': '30'},
      {'kind': 'bookingBalanceBeforeDispatch', 'advancePercent': 100},
      {'kind': 'bookingBalanceOnDelivery', 'advancePercent': 0},
      {'kind': 'paymentOnDelivery', 'netDays': 30},
    ]) {
      expect(() => WorkspacePaymentTerm.fromJson(data), throwsFormatException);
    }
    expect(
      () => WorkspacePaymentTerm.decodeList([
        {'kind': 'wholesaleAdvance'},
        {'kind': 'wholesaleAdvance'},
      ]),
      throwsFormatException,
    );
  });
  test(
    'PAYMENT-TERMS customer overrides never change other customers or retail',
    () {
      final d = WorkspaceStorePublicationDetails.fromJson({
        'wholesalePaymentTerms': [
          {'kind': 'wholesaleAdvance'},
        ],
        'customerPaymentTerms': {
          'customer-a': [
            {'kind': 'paymentOnDelivery'},
            {'kind': 'supplierCredit', 'netDays': 30, 'advancePercent': 20},
          ],
          'customer-blocked': <Object?>[],
        },
      });
      expect(
        d
            .paymentTermsFor(
              channel: BuyV2Destination.wholesale,
              customerId: 'customer-a',
            )
            .length,
        2,
      );
      expect(
        d
            .paymentTermsFor(
              channel: BuyV2Destination.wholesale,
              customerId: 'customer-b',
            )
            .single
            .kind,
        BuyV2CommercialPaymentTermKind.wholesaleAdvance,
      );
      expect(
        d.paymentTermsFor(
          channel: BuyV2Destination.wholesale,
          customerId: 'customer-blocked',
        ),
        isEmpty,
      );
      expect(
        d
            .paymentTermsFor(
              channel: BuyV2Destination.shop,
              customerId: 'customer-a',
            )
            .single
            .kind,
        BuyV2CommercialPaymentTermKind.retailAdvance,
      );
      expect(
        WorkspaceStorePublicationDetails.fromJson(d.toJson()).toJson(),
        d.toJson(),
      );
      expect(
        () => d.customerPaymentTerms['other'] = [],
        throwsUnsupportedError,
      );
      expect(
        () => d.customerPaymentTerms['customer-a']!.clear(),
        throwsUnsupportedError,
      );
      final public = handoffStock().toBuyPublicProduct(
        storeId: 'a',
        storeName: 'Store A',
        storeDetails: d,
      );
      expect(
        WorkspacePublicationContract.publicProductValues(public).toString(),
        isNot(contains('customer-a')),
      );
    },
  );
  test('LF05 invalid preferences preserve defaults and reject stale Store saves', () {
    final work = WorkSession(gateway: ReviewWorkGateway());
    addTearDown(work.dispose);
    const storeA = WorkWorkspace(id: 'host-lf05-a', name: 'Host A',
      profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Jaipur', verified: true);
    const storeB = WorkWorkspace(id: 'host-lf05-b', name: 'Host B',
      profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Delhi', verified: true);
    work.activeWorkspace = storeA;
    const defaults = WorkspaceStorePublicationDetails(returnSummary: 'Host return defaults',
      wholesalePaymentTerms: [WorkspacePaymentTerm(BuyV2CommercialPaymentTermKind.wholesaleAdvance)]);
    expect(work.saveWorkspacePublicationDetails(defaults, expectedStoreId: storeA.id), isTrue);
    expect(work.saveWorkspacePublicationDetails(const WorkspaceStorePublicationDetails(
      returnSummary: 'Must not replace saved terms', wholesalePaymentTerms: [
        WorkspacePaymentTerm(BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch,
          advancePercent: 100)]), expectedStoreId: storeA.id), isFalse);
    expect(work.workspacePublicationDetails.toJson(), defaults.toJson());
    work.activeWorkspace = storeB;
    expect(work.saveWorkspacePublicationDetails(defaults, expectedStoreId: storeA.id), isFalse);
    expect(work.workspacePublicationDetails.returnSummary, isEmpty);
    work.activeWorkspace = storeA;
    expect(work.workspacePublicationDetails.toJson(), defaults.toJson());
  });
  WorkspaceStorePublicationDetails details() =>
      WorkspaceStorePublicationDetails.fromJson({
        ...handoffStoreDetails().toJson(),
        'returnWindowDays': 7,
        'returnConditions': 'Keep the invoice and original pack.',
        'returnRemedies': ['Replacement', 'Refund'],
      });
  test(
    'STORE-SETTINGS one-time details round trip without inventing confirmation',
    () {
      final d = details();
      final decoded = WorkspaceStorePublicationDetails.fromJson(d.toJson());
      expect(decoded.toJson(), d.toJson());
      expect(decoded.issues, isEmpty);
      final public = decoded.toPublicStore(
        id: 'store-a',
        name: 'Test Store',
        area: 'Jaipur',
      );
      expect(public.address, '1 Test Lane, Jaipur, Rajasthan, 302001');
      expect(public.regionId, 'fixture-region-jaipur');
      expect(public.collection, isNull);
      final protection = decoded.protectionFor(null)!;
      expect(protection.windowLabel, '7 days from delivery');
      expect(protection.remedies, ['Refund', 'Replacement']);
      expect(protection.verificationLabel, isNull);
      expect(protection.refundTimelineLabel, isNull);
      expect(protection.approvalLabel, isNull);
    },
  );
  test(
    'STORE-SETTINGS product overrides do not inherit contradictory windows/remedies',
    () {
      final protection = details().protectionFor(
        'Replacement only within 2 days.',
      )!;
      expect(protection.summary, 'Replacement only within 2 days.');
      expect(protection.windowLabel, isNull);
      expect(protection.remedies, isEmpty);
    },
  );
  test(
    'STORE-SETTINGS channel/provider/customer payment intersection never enables unsupported methods',
    () {
      final d = details();
      expect(
        d.eligiblePaymentMethods(
          channel: BuyV2Destination.shop,
          providerSupported: {'PhonePe'},
          customerSupported: {'PhonePe', 'Paytm'},
        ),
        {'PhonePe'},
      );
      expect(
        d.eligiblePaymentMethods(
          channel: BuyV2Destination.shop,
          providerSupported: {},
          customerSupported: {'PhonePe'},
        ),
        isEmpty,
      );
      expect(
        d.eligiblePaymentMethods(
          channel: BuyV2Destination.wholesale,
          providerSupported: {'Bank transfer'},
          customerSupported: {'PhonePe'},
        ),
        isEmpty,
      );
      expect(
        d.eligiblePaymentMethods(
          channel: BuyV2Destination.wholesale,
          providerSupported: {'Bank transfer'},
          customerSupported: {'Bank transfer'},
        ),
        {'Bank transfer'},
      );
    },
  );
  test(
    'STORE-SETTINGS Shop and Wholesale inherit terms without repeating SKU entry',
    () {
      final d = details();
      final p = handoffStock().copyWith(returnPolicy: '');
      for (final channel in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        final terms = channel == BuyV2Destination.wholesale
            ? handoffSellingTerms(p, 'store-a') : null;
        final public = p.toBuyPublicProduct(
          storeId: 'store-a',
          storeName: 'Test Store',
          channel: channel,
          storeDetails: d,
          publicPackTerms: terms,
        );
        expect(public.returnPolicy, d.returnSummary);
        expect(public.purchaseProtection!.windowLabel, '7 days from delivery');
        expect(
          WorkspacePublicationContract.productIssues(
            p,
            storeId: 'store-a',
            storeName: 'Test Store',
            channel: channel,
            storeDetails: d,
            publicPackTerms: terms,
          ),
          isEmpty,
        );
        expect(
          WorkspacePublicationContract.productIssues(
            p,
            storeId: 'store-a',
            storeName: 'Test Store',
            channel: channel,
            storeDetails: d,
            publicPackTerms: terms,
            projected: public.copyWith(
              purchaseProtection: const BuyV2PurchaseProtection(
                summary: 'Wrong terms',
              ),
            ),
          ),
          isNotEmpty,
        );
      }
      expect(
        p.returnPolicy,
        '',
      ); // No copies of one-time defaults written into stock.
    },
  );
  test(
    'STORE-SETTINGS invalid fields cannot pass serialization or publication',
    () {
      for (final patch in <Map<String, Object?>>[
        {'pinCode': '000000'},
        {'dispatchDays': -1},
        {'returnWindowDays': 366},
        {
          'retailPaymentMethods': ['Unknown gateway'],
        },
        {
          'wholesalePaymentMethods': ['Made up'],
        },
        {
          'returnRemedies': ['Automatic approval'],
        },
        {
          'shoppingArea': {'regionId': 1},
        },
        {'returnWindowDays': 'seven'},
      ]) {
        expect(
          () => WorkspaceStorePublicationDetails.fromJson({
            ...details().toJson(),
            ...patch,
          }),
          throwsFormatException,
        );
      }
      final noLocation = WorkspaceStorePublicationDetails.fromJson({
        ...details().toJson(),
        'shoppingArea': null,
      });
      expect(
        noLocation.issues,
        contains('Confirm the Store location before publishing.'),
      );
    },
  );
  test(
    'STORE-SETTINGS save is Store-scoped immutable and cannot publish or change stock',
    () async {
      const a = WorkWorkspace(
        id: 'a',
        name: 'Store A',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jaipur',
        verified: true,
      );
      const b = WorkWorkspace(
        id: 'b',
        name: 'Store B',
        profileId: 'retailer-grocery',
        profileLabel: 'Grocery',
        area: 'Jaipur',
        verified: true,
      );
      final gateway = ReviewWorkGateway();
      final work = WorkSession(gateway: gateway)..activeWorkspace = a;
      addTearDown(work.dispose);
      final product = handoffStock();
      work.workspaceCatalogueItems.add(product);
      expect(
        work.saveWorkspacePublicationDetails(details(), expectedStoreId: 'a'),
        isTrue,
      );
      expect(work.workspaceVisibleToCustomers, isFalse);
      expect(work.workspaceCatalogueItems.single, same(product));
      expect(work.workspacePublicStoreDetails!.id, 'a');
      expect(work.workspacePublicStoreDetails!.name, 'Store A');
      expect(work.workspacePublicStoreDetails!.address, details().address);
      work.activeWorkspace = b;
      expect(work.workspacePublicStoreDetails!.id, 'b');
      expect(work.workspacePublicStoreDetails!.address, isEmpty);
      expect(work.workspacePublicationDetails.legalName, isEmpty);
      expect(
        work.saveWorkspacePublicationDetails(details(), expectedStoreId: 'a'),
        isFalse,
      );
      expect(work.workspacePublicationDetails.legalName, isEmpty);
      work.activeWorkspace = a;
      expect(work.workspacePublicationDetails.toJson(), details().toJson());
      expect(
        () =>
            work.workspacePublicationDetails.retailPaymentMethods.add('Paytm'),
        throwsUnsupportedError,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        gateway.lastOperationalSnapshot!.state['publicationDetails'],
        details().toJson(),
      );
    },
  );
}

// Isolated host storage/identity fixtures, never runtime evaluation records.
class _Lf16SecurePrefsStore extends SecureWorkPendingProofStore {
  _Lf16SecurePrefsStore(super.storeId) : super.pickupPreferences();
  @override
  String get accountScope => 'lf16-host';
}

WorkWorkspace _lf16Store(String id) => WorkWorkspace(id: id, name: 'Host Store',
  profileId: 'retailer-grocery', profileLabel: 'Grocery', area: 'Pune', verified: true);

class _Lf16Storage {
  String account = 'lf16-host';
  final rows = <String, String>{};
  bool failRead = false, failWrite = false;
  int writes = 0;
  int failWritesRemaining = 0;
  Completer<void>? readGate, writeGate;
  String key(String id, [String? owner]) => jsonEncode([owner ?? account, id]);
  Map<String, Object?> valid() => {'schemaVersion': 1, 'storeId': 'lf16-a',
    'fields': <String, Object?>{'city': 'Pune', 'area': 'Saved lane', 'pincode': '411001', 'pickupEnabled': false}};
  WorkSession work() => WorkSession(gateway: ReviewWorkGateway(),
    contactDraftStore: _Lf16MemoryStore(this, 'contact'),
    pickupPreferencesStoreFactory: (id) => _Lf16MemoryStore(this, id))
      ..activeWorkspace = _lf16Store('lf16-a');
}

class _Lf16MemoryStore implements WorkPendingProofStore {
  _Lf16MemoryStore(this.storage, this.id);
  final _Lf16Storage storage;
  final String id;
  @override
  String get accountScope => storage.account;
  @override
  Future<Map<String, Object?>?> read(String scope) async {
    final row = storage.rows[storage.key(id, scope)];
    await storage.readGate?.future;
    if (storage.failRead) throw StateError('Host read failure');
    return row == null ? null : Map<String, Object?>.from(jsonDecode(row) as Map);
  }
  @override
  Future<void> save(String scope, Map<String, Object?> data) async {
    storage.writes++;
    final frozen = jsonEncode(data);
    await storage.writeGate?.future;
    if (storage.failWrite || storage.failWritesRemaining > 0) {
      if (storage.failWritesRemaining > 0) storage.failWritesRemaining--;
      throw StateError('Host write failure');
    }
    storage.rows[storage.key(id, scope)] = frozen;
  }
  @override
  Future<void> clear(String scope) async => throw StateError('Recovery must not delete');
}

class _Lf18SecureDefaultsStore extends SecureWorkPendingProofStore {
  _Lf18SecureDefaultsStore(super.storeId) : super.publicationPreferences();
  @override
  String get accountScope => 'lf16-host';
}

class _Lf18Storage extends _Lf16Storage {
  bool contactAvailable = true;
  @override
  WorkSession work() => WorkSession(gateway: ReviewWorkGateway(),
    contactDraftStore: _Lf18ContactStore(this),
    publicationPreferencesStoreFactory: (id) => _Lf16MemoryStore(this, id))
      ..activeWorkspace = _lf16Store('lf18-a');
}

class _Lf18ContactStore implements WorkPendingProofStore {
  _Lf18ContactStore(this.storage);
  final _Lf18Storage storage;
  @override
  String? get accountScope => storage.contactAvailable ? storage.account : null;
  @override
  Future<Map<String, Object?>?> read(String scope) async => null;
  @override
  Future<void> save(String scope, Map<String, Object?> data) async {}
  @override
  Future<void> clear(String scope) async => throw StateError('Host contact must not clear');
}

WorkspaceStorePublicationDetails _lf18Details() => const WorkspaceStorePublicationDetails(
  legalName: 'Host default business', street: 'Host default lane', city: 'Pune',
  state: 'Maharashtra', pinCode: '411001', retailChannelEnabled: true,
  wholesaleChannelEnabled: true, returnSummary: 'Return unopened goods',
  returnWindowDays: 7, dispatchDays: 2, returnRemedies: {'Replacement'},
  wholesalePaymentTerms: [WorkspacePaymentTerm(
    BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery, advancePercent: 25)],
);

Future<_Lf18Storage> _lf18Prepared() async {
  final f = _Lf18Storage();
  final work = f.work();
  await work.loadWorkspacePublicationPreferences(expectedStoreId: 'lf18-a');
  expect(work.saveWorkspacePublicationDetails(_lf18Details()), isTrue);
  expect(await work.workspacePublicationPreferencesWrite, isTrue);
  work.dispose();
  return f;
}
