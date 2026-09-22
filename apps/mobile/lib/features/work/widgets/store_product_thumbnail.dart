import 'package:flutter/material.dart';

import '../../../ui_v2/buy/buy_v2_design.dart';
import '../work_models.dart';

/// Store presentation of the same identity-bound media used by Buy.
/// Square bounds prevent a narrow list slot from shrinking a complete pack.
/// Buy retains ownership of photo admission, contain fitting, illustrations,
/// disclosure and loading/error fallbacks; no crop or alternate SKU is invented.
class StoreProductThumbnail extends StatelessWidget {
  const StoreProductThumbnail({
    super.key,
    required this.product,
    required this.extent,
  });

  final WorkspaceCatalogueItem product;
  final double extent;

  static double gridExtent(double cardWidth) =>
      (cardWidth - 14).clamp(56.0, 64.0);

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: extent,
    child: BuyV2ProductPackshot(
      product: product.toCataloguePreviewProduct(),
      borderRadius: extent >= 70 ? 8 : 4,
    ),
  );
}
