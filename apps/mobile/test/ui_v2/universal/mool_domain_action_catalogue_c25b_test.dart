import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  test(
    'Medicine aliases retain Care ownership and explicit Buy precedence',
    () {
      for (final value in const ['medicine', 'rx']) {
        for (final key in const ['sub', 'view', 'context', 'scope']) {
          expect(moolActionFamilyIdForRoute('/app/buy?$key=$value'), 'book');
        }
        expect(
          moolActionFamilyIdForRoute('/app/buy?sub=orders&scope=$value'),
          'book',
        );
        for (final sub in const ['shop', 'wholesale', 'business', 'orders']) {
          expect(
            moolActionFamilyIdForRoute('/app/buy?sub=$sub&view=$value'),
            'buy',
          );
        }
      }
      expect(moolActionFamilyIdForRoute('/app/buy/medicine?view=cart'), 'book');
      expect(
        moolActionFamilyIdForRoute('/app/book/medicine?view=product'),
        'book',
      );
      expect(moolActionFamilyIdForRoute('/app/buy?view=product'), 'buy');
    },
  );

  test('C25B exposes the exact six-domain main catalogue', () {
    expect(
      moolActionFamilies.map((family) => '${family.id}:${family.label}'),
      const [
        'social:Social',
        'buy:Shop',
        'eat:Food',
        'ride:Travel',
        'book:Care',
        'work:Work',
      ],
    );
    expect(moolActionFamilies.map((family) => family.route), const [
      '/app/social',
      '/app/buy?sub=shop',
      '/app/eat/home',
      '/app/ride/book?type=bike',
      '/app/book/doctor',
      '/app/work/earn',
    ]);
    expect(personalMoolRootActions.length, 6);
  });

  test('C25B exposes exact destination-local actions without fillers', () {
    final catalogue = {
      for (final family in moolActionFamilies)
        family.label: family.actions.map((action) => action.label).toList(),
    };
    expect(catalogue, const {
      'Social': ['Home', 'Shorts', 'Create', 'Feed'],
      'Shop': ['Wholesale', 'Orders'],
      'Food': ['Order Food', 'Book Table'],
      'Travel': ['Bike', 'Auto', 'Cab', 'Bus'],
      'Care': ['Doctor', 'Medicine', 'Salon'],
      'Work': ['Earn Today', 'Workspace'],
    });
    expect(moolActionFamilies.expand((family) => family.actions).length, 17);
    expect(
      moolActionFamilyById('buy').actions.any(
        (action) => action.id == 'shop' || action.label == 'Products',
      ),
      isFalse,
    );
    expect(
      moolActionFamilies
          .expand((family) => family.actions)
          .any((action) => action.id == 'offers' || action.label == 'Offers'),
      isFalse,
    );
  });

  test('C25B resolves cross-owned Medicine and Bus by presentation domain', () {
    expect(moolActionFamilyIdForRoute('/app/buy?sub=medicine'), 'book');
    expect(moolActionFamilyIdForRoute('/app/book/bus'), 'ride');
    expect(moolActionFamilyIdForRoute('/app/buy?sub=shop'), 'buy');
    expect(moolActionFamilyIdForRoute('/app/book/doctor'), 'book');
    expect(moolActionFamilyIdForRoute('/app/ride/book?type=cab'), 'ride');
  });

  test('C25B keeps Medicine and Bus singular with existing route owners', () {
    final occurrences = <String, List<String>>{};
    for (final family in moolActionFamilies) {
      for (final action in family.actions) {
        occurrences.putIfAbsent(action.id, () => <String>[]).add(family.id);
      }
    }
    expect(occurrences['medicine'], const ['book']);
    expect(occurrences['bus'], const ['ride']);
    expect(
      moolActionFamilyById(
        'book',
      ).actions.singleWhere((action) => action.id == 'medicine').route,
      '/app/book/medicine',
    );
    expect(
      moolActionFamilyById(
        'ride',
      ).actions.singleWhere((action) => action.id == 'bus').route,
      '/app/book/bus',
    );
  });
}
