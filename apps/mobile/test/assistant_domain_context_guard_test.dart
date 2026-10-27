import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/assistant/profile_context.dart';

class _SearchNative implements MoolAssistantNativeAdapter {
  @override String get actionId => 'AI-ACT-001';
  int version = 1, opens = 0;
  bool permitted = true;
  MoolAssistantProposal? reviewed;
  @override Set<String> get allowedFields => {'query'};
  @override String? validateFields(Map<String, Object?> fields) =>
    fields.length == 1 && fields['query'] is String ? null : 'Use the original query field.';
  @override Future<MoolAssistantNativeSnapshot?> snapshot(MoolAssistantContext c, String? entity) async =>
    MoolAssistantNativeSnapshot(binding: c.binding, entityId: entity,
      sourceRevision: 'original-search:$version', permitted: permitted);
  @override Future<MoolAssistantReviewResult> openReview(MoolAssistantProposal p, bool Function() current) async {
    if (!current() || p.sourceRevision != 'original-search:$version') return MoolAssistantReviewResult.stale;
    opens++; reviewed = p; return MoolAssistantReviewResult.opened;
  }
}
class _Fixture {
  _Fixture({bool register = true}) {
    guard = AssistantProfileContextGuard(readContext: () => owner.value, ownerChanges: owner,
      nativeAdapters: [native], clock: () => now,
      canonicalActions: register ? {'AI-ACT-001'} : null,
      recoverableActions: register ? {'AI-ACT-001'} : null,
      readCanonical: (context, current) async {
        await pending?.future;
        if (!current()) throw const AssistantModelFailure('stale_preparation');
        onRead?.call(++reads);
        return AssistantCanonicalContextSnapshot(binding: context.binding,
          revisions: {('AI-ACT-001', null): revision}, validUntil: now.add(const Duration(seconds: 60)),
          catalogueListingIds: listingIds);
      });
  }
  final owner = ValueNotifier(const MoolAssistantContext(accountScope: 'host-owner', authenticationRevision: 1));
  final native = _SearchNative();
  final now = DateTime.utc(2026, 10, 28, 8);
  String revision = 'catalogue-search:one';
  List<String>? listingIds;
  int reads = 0;
  void Function(int)? onRead;
  Completer<void>? pending;
  late final AssistantProfileContextGuard guard;
  MoolAssistantNativeAdapter get adapter => guard.adapters.single;
  Future<void> capture() => guard.capture(owner.value, () => true);
  MoolAssistantProposal proposal({bool recovered = false, String? originalRevision, Map<String, Object?>? fields}) =>
    MoolAssistantProposal(id: 'host-search-proposal', actionId: native.actionId, binding: owner.value.binding,
      requestRevision: 1, entitlementRevision: 'host-paid-revision', validUntil: now.add(const Duration(seconds: 60)),
      sourceRevision: originalRevision ?? revision, title: 'Review product search', summary: 'Host fixture only',
      fields: fields ?? {'query': 'चावल 5 kg'}, recovered: recovered,
      preparationRequestId: recovered ? 'original-host-preparation' : null,
      preparationSourceRevision: recovered ? originalRevision ?? revision : null);
  void dispose() {guard.dispose(); owner.dispose();}
}
void main() {
  test('Native readiness hints expose only admitted permitted captured anchors and retire with their owner', () async {
    final f = _Fixture(); addTearDown(f.dispose); await f.capture();
    expect(f.guard.nativeTargets, [(actionId: 'AI-ACT-001', entityId: null)]);
    expect(() => f.guard.nativeTargets!.clear(), throwsUnsupportedError);
    f.guard.retire(); expect(f.guard.nativeTargets, isNull);
    final denied = _Fixture()..native.permitted = false; addTearDown(denied.dispose); await denied.capture();
    expect(denied.guard.nativeTargets, isEmpty);
    final unregistered = _Fixture(register: false); addTearDown(unregistered.dispose); await unregistered.capture();
    expect(unregistered.guard.nativeTargets, isEmpty);
  });
  test('Original listing selection is captured immutably and retired with its owner', () async {
    final f = _Fixture(); addTearDown(f.dispose);
    final id = 'listing-${List.filled(64, 'a').join()}';
    f.listingIds = [id]; await f.capture(); f.listingIds!.clear();
    expect(f.guard.catalogueListingIds, [id]);
    f.guard.retire(); expect(f.guard.catalogueListingIds, isNull);
  });
  test('Changed listing selection during capture rejects even an unchanged source revision', () async {
    final f = _Fixture(); addTearDown(f.dispose);
    f.listingIds = ['listing-${List.filled(64, 'a').join()}'];
    f.onRead = (n) {if (n == 2) f.listingIds = ['listing-${List.filled(64, 'b').join()}'];};
    await expectLater(f.capture(), throwsA(isA<AssistantModelFailure>()));
    expect(f.guard.current, false); expect(f.native.opens, 0);
  });
  test('Domain canonical guard reviews exact original native source and supplied query', () async {
    final f = _Fixture(); addTearDown(f.dispose); await f.capture();
    expect((await f.adapter.snapshot(f.owner.value, null))!.sourceRevision, f.revision);
    expect(await f.adapter.openReview(f.proposal(), () => true), MoolAssistantReviewResult.opened);
    expect(f.native.opens, 1); expect(f.native.reviewed!.sourceRevision, 'original-search:1');
    expect(f.native.reviewed!.fields, {'query': 'चावल 5 kg'});
  });
  test('Domain stale server revision cannot be relabelled with a fresh native token', () async {
    final f = _Fixture(); addTearDown(f.dispose); await f.capture(); final original = f.proposal();
    f.revision = 'catalogue-search:two';
    expect(await f.adapter.openReview(original, () => true), MoolAssistantReviewResult.stale); expect(f.native.opens, 0);
  });
  test('Domain original native edit or withdrawn permission retires review', () async {
    for (final withdraw in [false, true]) {
      final f = _Fixture(); addTearDown(f.dispose); await f.capture(); final p = f.proposal();
      if (withdraw) {f.native.permitted = false;} else {f.native.version++;}
      expect(await f.adapter.openReview(p, () => true), MoolAssistantReviewResult.stale); expect(f.native.opens, 0);
    }
  });
  test('Domain unknown native fields cannot open the original form', () async {
    final f = _Fixture(); addTearDown(f.dispose); await f.capture();
    expect(await f.adapter.openReview(f.proposal(fields: {'query': 'rice', 'admin': true}), () => true), MoolAssistantReviewResult.unavailable);
    expect(f.native.opens, 0);
  });
  test('Domain account switch across canonical read retires all old anchors', () async {
    final f = _Fixture(); addTearDown(f.dispose); f.pending = Completer<void>(); final capture = f.capture();
    f.owner.value = const MoolAssistantContext(accountScope: 'other-owner', authenticationRevision: 2); f.pending!.complete();
    await expectLater(capture, throwsA(anything)); expect(f.guard.current, false); expect(f.native.opens, 0);
  });
  test('Domain explicitly recovered preparation requires the same fresh original source revision', () async {
    final f = _Fixture(); addTearDown(f.dispose);
    final p = f.proposal(recovered: true); await f.guard.captureRecoveredReview(f.owner.value, p, () => true);
    expect(await f.adapter.openReview(p, () => true), MoolAssistantReviewResult.opened);
    f.revision = 'catalogue-search:two';
    await expectLater(f.guard.captureRecoveredReview(f.owner.value, p, () => true), throwsA(anything));
    expect(f.native.opens, 1);
  });
  test('Domain registration does not broaden the original default Profile recovery set', () async {
    final f = _Fixture(register: false); addTearDown(f.dispose);
    await expectLater(f.guard.captureRecoveredReview(f.owner.value, f.proposal(recovered: true), () => true), throwsA(anything));
    expect(f.native.opens, 0);
  });
}
