import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

void main() {
  final query = BuyV2CatalogueQuery(
    destination: BuyV2Destination.shop,
    regionId: 'jodhpur',
  );
  BuyV2CataloguePage<String> page(
    BuyV2CatalogueQuery q,
    String? cursor, {
    String snapshot = 'v1',
  }) {
    final start = int.parse(cursor ?? '0');
    return BuyV2CataloguePage(
      queryKey: q.key,
      snapshotId: snapshot,
      startIndex: start,
      totalCount: 400,
      previousCursor: start == 0 ? null : '${start - 40}',
      nextCursor: start == 360 ? null : '${start + 40}',
      items: List.generate(40, (i) => '${q.key}-${start + i}'),
    );
  }

  test(
    'C04 preview keeps visible page and scroll, then promotes without another request',
    () async {
      var requests = 0;
      final pager = BuyV2CataloguePager<String>(
        identityOf: (v) => v,
        load: (q, {cursor, required pageSize}) async {
          requests++;
          return page(q, cursor);
        },
      );
      addTearDown(pager.dispose);
      await pager.open(query);
      pager.scrollOffset = 120;
      await pager.prefetchAdjacent();
      expect(requests, 2);
      expect(pager.page!.startIndex, 0);
      expect(pager.scrollOffset, 120);
      expect(pager.loading, false);
      expect(pager.adjacentPage(forward: true)!.startIndex, 40);
      await pager.next();
      expect(requests, 2);
      expect(pager.page!.startIndex, 40);
      for (var i = 0; i < 7; i++) {
        await pager.prefetchAdjacent();
        expect(pager.cachedPageCount, lessThanOrEqualTo(3));
        expect(pager.retainedItemCount, lessThanOrEqualTo(120));
        await pager.next();
      }
    },
  );
  test('C04 slow preview is shared with a committed swipe', () async {
    final pending = Completer<BuyV2CataloguePage<String>>();
    var requests = 0;
    final pager = BuyV2CataloguePager<String>(
      identityOf: (v) => v,
      load: (q, {cursor, required pageSize}) async {
        requests++;
        return cursor == null ? page(q, cursor) : pending.future;
      },
    );
    addTearDown(pager.dispose);
    await pager.open(query);
    final preview = pager.prefetchAdjacent();
    await Future<void>.delayed(Duration.zero);
    final next = pager.next();
    expect(pager.page!.startIndex, 0);
    expect(pager.loading, true);
    pending.complete(page(query, '40'));
    await preview;
    await next;
    expect(requests, 2);
    expect(pager.page!.startIndex, 40);
  });
  test('C04 obsolete preview is discarded after search changes', () async {
    final pending = Completer<BuyV2CataloguePage<String>>();
    final pager = BuyV2CataloguePager<String>(
      identityOf: (v) => v,
      load: (q, {cursor, required pageSize}) async {
        return cursor == null ? page(q, cursor) : pending.future;
      },
    );
    addTearDown(pager.dispose);
    await pager.open(query);
    final preview = pager.prefetchAdjacent();
    await Future<void>.delayed(Duration.zero);
    final other = BuyV2CatalogueQuery(
      destination: BuyV2Destination.shop,
      regionId: 'mumbai',
    );
    await pager.open(other);
    pending.complete(page(query, '40'));
    await preview;
    expect(pager.query, other);
    expect(pager.cachedPageCount, 1);
    expect(pager.adjacentPage(forward: true), isNull);
  });
  test(
    'C04 invalid preview never displays and failed navigation retains retry',
    () async {
      var invalid = true;
      final pager = BuyV2CataloguePager<String>(
        identityOf: (v) => v,
        load: (q, {cursor, required pageSize}) async {
          return page(
            q,
            cursor,
            snapshot: cursor != null && invalid ? 'wrong' : 'v1',
          );
        },
      );
      addTearDown(pager.dispose);
      await pager.open(query);
      await pager.prefetchAdjacent();
      expect(pager.message, isNull);
      expect(pager.adjacentPage(forward: true), isNull);
      await pager.next();
      expect(pager.page!.startIndex, 0);
      expect(pager.message, isNotNull);
      invalid = false;
      await pager.retry();
      expect(pager.page!.startIndex, 40);
      expect(pager.message, isNull);
    },
  );
}
