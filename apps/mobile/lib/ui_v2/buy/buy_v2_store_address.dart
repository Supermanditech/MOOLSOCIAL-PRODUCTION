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

class BuyV2StoreAddress extends StatelessWidget {
  const BuyV2StoreAddress({
    super.key,
    required this.store,
    this.openMap,
    this.showAddress = true,
  });

  final BuyV2StoreListing store;
  final Future<bool> Function(Uri)? openMap;
  final bool showAddress;

  Future<void> _open(BuildContext context, Uri uri) async {
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
    return Row(
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
    );
  }
}
