import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/buy/buy_v2_content_contracts.dart';
import 'buy_v2_design.dart';

/// Uses the selected Store record, never a product origin or buyer address.
Uri? buyV2StoreMapUri(BuyV2StoreListing store) {
  if (store.id.trim().isEmpty || store.address.trim().isEmpty) return null;
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': [
      buyV2CustomerStoreName(store.name, store.id).trim(),
      store.address.trim(),
    ].where((part) => part.isNotEmpty).join(', '),
  });
}

/// Opens the platform phone application; it never places or confirms a call.
Future<bool> buyV2OpenStoreContact(Uri uri) async => uri.scheme == 'tel' &&
  await launchUrl(uri, mode: LaunchMode.externalApplication);

class BuyV2StoreAddress extends StatelessWidget {
  const BuyV2StoreAddress({
    super.key,
    required this.store,
    this.openMap,
    this.showAddress = true, this.showContactAction = false, this.openContact, this.contactCurrent,
  });

  final BuyV2StoreListing store;
  final Future<bool> Function(Uri)? openMap;
  final bool showAddress;
  final bool showContactAction;
  final Future<bool> Function(Uri)? openContact;
  final bool Function()? contactCurrent;

  Future<void> _contact(BuildContext context) async {
    final phone = store.publicContactPhone?.trim();
    if (phone == null || phone.isEmpty || contactCurrent?.call() == false) return;
    final uri = Uri(scheme: 'tel', path: phone);
    var opened = false;
    try { opened = await (openContact?.call(uri) ?? buyV2OpenStoreContact(uri)).timeout(const Duration(seconds: 15)); }
    on Object { opened = false; }
    if (!opened && context.mounted && contactCurrent?.call() != false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the phone app. Please try again.')));
    }
  }
  Future<void> _open(BuildContext context, Uri uri) async {
    if (contactCurrent?.call() == false) return;
    var opened = false;
    try {
      opened =
          await (openMap?.call(uri) ??
                  launchUrl(uri, mode: LaunchMode.externalApplication))
              .timeout(const Duration(seconds: 15));
    } on Object {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = buyV2StoreMapUri(store);
    if (!showAddress && uri == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                !showAddress
                    ? 'Google Maps'
                    : store.address.trim().isEmpty
                    ? 'Store address unavailable'
                    : store.address.trim(),
                style: context.buyMeta.copyWith(fontSize: 12, height: 1.25),
              ),
            ),
            if (uri != null)
              IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                key: ValueKey('buy-store-map-${store.id}'),
                tooltip: 'Open store in Google Maps',
                onPressed: () => _open(context, uri),
                icon: const Icon(Icons.location_on_outlined, size: 20),
              ),
          ],
        ),
        if (showAddress && store.publicContactPhone?.trim().isNotEmpty == true)
          Text(
            'Contact: ${store.publicContactPhone!.trim()}',
            key: ValueKey('buy-store-contact-${store.id}'),
            style: context.buyMeta.copyWith(fontSize: 12, height: 1.25),
          ),
        if (showContactAction && store.publicContactPhone?.trim().isNotEmpty == true)
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(
            key: ValueKey('buy-store-call-${store.id}'), onPressed: () => _contact(context),
            icon: const Icon(Icons.phone_outlined), label: const Text('Call store / supplier'))),
        if (showAddress && store.openingHoursLabel?.trim().isNotEmpty == true)
          Text(
            'Hours: ${store.openingHoursLabel!.trim()}',
            key: ValueKey('buy-store-hours-${store.id}'),
            style: context.buyMeta.copyWith(fontSize: 12, height: 1.25),
          ),
      ],
    );
  }
}
