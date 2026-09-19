import 'package:flutter/material.dart';

import '../work_models.dart';

/// Selects identity only. Store prices, stock and visibility are edited next.
class StoreAddProductSheet extends StatefulWidget {
  const StoreAddProductSheet({
    super.key,
    required this.catalogue,
    required this.ownedProducts,
    required this.createProduct,
    required this.scanBarcode,
  });

  final List<WorkspaceCatalogueItem> catalogue;
  final List<WorkspaceCatalogueItem> ownedProducts;
  final WorkspaceCatalogueItem Function(String barcode) createProduct;
  final Future<String?> Function() scanBarcode;

  @override
  State<StoreAddProductSheet> createState() => _StoreAddProductSheetState();
}

class _StoreAddProductSheetState extends State<StoreAddProductSheet> {
  final _search = TextEditingController();
  bool _scanning = false;
  String _barcode = '';
  String? _scanError;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _scanning = true;
      _scanError = null;
    });
    try {
      final code = await widget.scanBarcode();
      if (!mounted || code == null || code.trim().isEmpty) return;
      setState(() {
        _barcode = code.trim();
        _search.text = _barcode;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _scanError =
              'Could not scan. Search or enter the product instead.',
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  WorkspaceCatalogueItem? _owned(WorkspaceCatalogueItem product) {
    for (final item in widget.ownedProducts) {
      if (item.id == product.id ||
          (item.canonicalId == product.canonicalId &&
              item.variant == product.variant &&
              item.pack == product.pack &&
              item.barcode == product.barcode)) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final entries =
        [
              ...widget.ownedProducts,
              ...widget.catalogue.where((product) => _owned(product) == null),
            ]
            .where(
              (item) =>
                  query.isEmpty ||
                  '${item.title} ${item.brand} ${item.variant} ${item.pack} ${item.sku} ${item.barcode}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList(growable: false);
    return Scaffold(
      key: const Key('work-add-products-picker'),
      appBar: AppBar(title: const Text('Add products')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    key: const Key('work-add-products-search'),
                    controller: _search,
                    onChanged: (_) => setState(() => _barcode = ''),
                    decoration: InputDecoration(
                      labelText: 'Search name, brand or barcode',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        key: const Key('work-add-products-scan'),
                        tooltip: 'Scan barcode',
                        onPressed: _scanning ? null : _scan,
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                    ),
                  ),
                ),
                if (_scanError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _scanError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No matching product. You can add its details below.',
                            ),
                          ),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final product = entries[index];
                            final owned = _owned(product);
                            return ListTile(
                              key: Key('work-add-product-${product.id}'),
                              title: Text(product.title),
                              subtitle: Text(
                                '${product.brand} · ${product.pack}${owned == null ? '' : '\nAlready in your store · Edit details'}',
                              ),
                              trailing: Icon(
                                owned == null
                                    ? Icons.chevron_right
                                    : Icons.edit_outlined,
                              ),
                              onTap: () => Navigator.pop(
                                context,
                                owned ??
                                    product.copyWith(
                                      purchasePrice: 0,
                                      sellingPrice: 0,
                                      stock: 0,
                                      unitPrice: '',
                                      available: false,
                                      publicListing: false,
                                    ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('work-add-product-manual'),
                      onPressed: () => Navigator.pop(
                        context,
                        widget.createProduct(_barcode),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Enter a new product'),
                    ),
                  ),
                ),
              ],
            );
            if (constraints.maxHeight < 280) {
              return SingleChildScrollView(
                child: SizedBox(height: 360, child: content),
              );
            }
            return content;
          },
        ),
      ),
    );
  }
}
